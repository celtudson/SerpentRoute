import js.Browser.window;
import SnakeLevel.SnakePart;
import aps.Counter;
import aps.Types;
import aps.render.TiledLayer;
import kha.Assets;
import kha.Color;
import kha.audio1.Audio;
import kha.audio1.AudioChannel;
import kha.graphics2.Graphics;

typedef LbLeaderBoard = {
	userRank:Int,
	entries:Array<LbUserScore>
}

typedef LbUserScore = {
	score:Int,
	rank:Int,
	player:{
		publicName:String
	},
	formattedScore:String
}

class Meal {
	public final pos:Vec2Int;
	public var color:Int;

	public function new(_x:Int, _y:Int, _color:Int) {
		pos = {x: _x, y: _y};
		color = _color;
	}
}

class SnakeGame {
	public final renderAreaSize:Vec2Int = {x: 0, y: 0};
	public var isGaming(default, null):Bool = false;
	public var isPaused:Bool = true;
	public var score(default, null):Int;
	public final audioBgm:AudioChannel;

	final tileset:Tileset;
	final tilemap:TiledLayer;
	final level:SnakeLevel;
	final movementDelta:Vec2Int = {x: 0, y: 0};
	final movementTimer:Counter;

	final audioGoal:AudioChannel;
	final audioExplosion:AudioChannel;

	public function new() {
		tileset = new Tileset(Assets.images.tiles, 16, 16);
		tilemap = new TiledLayer(tileset, Loader.atlas);
		level = new SnakeLevel();
		audioExplosion = Audio.play(Assets.sounds.explosion);
		audioExplosion.stop();
		audioGoal = Audio.play(Assets.sounds.goal);
		audioGoal.stop();
		audioBgm = Audio.play(Assets.sounds.Diet, true);
		audioBgm.volume = 0.8;
		audioBgm.stop();

		minSnakeSpeed = Math.ceil(spawnSnakeEndSpeed / 3);
		maxSnakeSpeed = Math.ceil(spawnSnakeEndSpeed / 12);
		spawnSnakeEndTimer = new Counter(spawnSnakeEndSpeed, (_counter) -> {
			_counter.reset();
			level.addPartToSnakeEnd(getRandomColor());
			recalcSnakeSpeed();
		});
		movementTimer = new Counter(minSnakeSpeed, movementTimerTick);

		lbLeaderBoard = {userRank: -1, entries: []};
			(window : Dynamic).updateLeaderboardEntries(lbLeaderBoard);
	}

	var lbLeaderBoard:LbLeaderBoard;

	/**/
	final spawnSnakeEndSpeed:Int = 90;
	final spawnSnakeEndTimer:Counter;
	final minSnakeSpeed:Int;
	final maxSnakeSpeed:Int;
	final minSnakeLength = 5;
	final maxSnakeLength = 32;

	/**/
	var speedometerColor:Int = 0xFFFFFFFF;

	function recalcSnakeSpeed():Void {
		var ratio = 1 - (level.snake.length - minSnakeLength) / maxSnakeLength;
		if (ratio > 1) ratio = 1;
		else if (ratio < 0) ratio = 0;
		movementTimer.max = Math.ceil(maxSnakeSpeed + (minSnakeSpeed - maxSnakeSpeed) * ratio);
		speedometerColor = colorLerp(ratio, 0xFFFF0000, 0xFF00FF00);
		// if (Main.isDebug) trace(level.snake.length, ratio, movementTimer.max);
	}

	function resetSnake(_parts:Array<SnakePart>):Void {
		level.resetSnake(_parts);
		movementDelta.x = 0;
		movementDelta.y = 0;
		snakeHeadDir = 2;
		recalcSnakeSpeed();
	}

	var stepCount:Int;
	var phase:Int;
	final destinationPoints:Array<Meal> = [];
	final meals:Array<Meal> = [];
	final passagesThroughSnake:Array<SnakePart> = [];

	public function resetLevel(isUserRestart:Bool, _w:Int = -1, _h:Int = -1):Void {
		if (isUserRestart) {
			if (isGaming) return;
			if (audioBgm != null) audioBgm.play();
		}

		if (_h < 1) _h = _w;
		if (_w < 1) {
			_w = level.pathFinderMap.mapW;
			_h = level.pathFinderMap.mapH;
		}

		level.resetLevel(_w, _h);
		renderAreaSize.x = level.pathFinderMap.mapW * tileset.tsizeW;
		renderAreaSize.y = level.pathFinderMap.mapH * tileset.tsizeH;
		resetSnake([
			for (i in 0...minSnakeLength) new SnakePart(0, 0, getRandomColor())
		]);
		switch (snakeHeadDir) {
			case 0:
				movementDelta.x = -1;
			case 1:
				movementDelta.y = -1;
			case 2:
				movementDelta.x = 1;
			case 3:
				movementDelta.y = 1;
		}
		// trace(movementDelta);

		stepCount = 0;

		destinationPoints.resize(0);
		meals.resize(0);
		passagesThroughSnake.resize(0);

		score = 0;
		phase = -1;
		movementTimer.value = 0;
		movementTimer.max = minSnakeSpeed;
		spawnSnakeEndTimer.value = 0;
		isGaming = true;
	}

	public function update():Void {
		if (!(GameDisplay.keysPollingDir.x == 0 && GameDisplay.keysPollingDir.y == 0)) {
			movementDelta.x = GameDisplay.keysPollingDir.x;
			movementDelta.y = GameDisplay.keysPollingDir.y;
		}

		final allowReversePause = false;
		if (movementDelta.x < 0 && level.lastSnakeDeltaX > 0) movementDelta.x = allowReversePause ? 0 : 1;
		else if (movementDelta.x > 0 && level.lastSnakeDeltaX < 0) movementDelta.x = allowReversePause ? 0 : -1;
		if (movementDelta.y < 0 && level.lastSnakeDeltaY > 0) movementDelta.y = allowReversePause ? 0 : 1;
		else if (movementDelta.y > 0 && level.lastSnakeDeltaY < 0) movementDelta.y = allowReversePause ? 0 : -1;

		if (!isPaused && isGaming) {
			movementTimer.tick();
			spawnSnakeEndTimer.tick();
		}
	}

	function movementTimerTick(_t:Counter):Void {
		_t.reset();
		/*final head = level.snake[0];
			for (meal in meals.copy()) {
				if (head.pos.x == meal.pos.x && head.pos.y == meal.pos.y) {
					meals.remove(meal);
					level.addPartToSnakeEnd(meal.color);
				}
		}*/

		for (passage in passagesThroughSnake.copy()) {
			var isNotIntersectWithSnake = true;
			for (partI => part in level.snake) {
				if (partI == 0) continue; // avoid snake head
				if (part.pos.x == passage.prevTickPos.x && part.pos.y == passage.prevTickPos.y) {
					isNotIntersectWithSnake = false;
					break;
				}
			}
			if (isNotIntersectWithSnake) passagesThroughSnake.remove(passage);
		}

		for (partI => part in level.snake.copy()) {
			if (partI == 0) continue; // avoid snake head
			for (destination in destinationPoints.copy()) {
				if (part.color == destination.color && part.pos.x == destination.pos.x && part.pos.y == destination.pos.y) {
					level.snake.remove(part);
					destinationPoints.remove(destination);
					if (partI < level.snake.length - 1) passagesThroughSnake.push(part); // All but the last cell leave behind a portal
					recalcSnakeSpeed();

					score++;
					audioGoal.stop();
					audioGoal.play();
				}
			}
		}

		if (!isGaming) return;

		if (level.trySnakeStep(movementDelta.x, movementDelta.y)) {} else {
			isGaming = false;
			trace("lb: ban! " + score);
			if (audioBgm != null) audioBgm.pause();
			#if kha_html5
			(window : Dynamic).trySetNewRecord(score, lbLeaderBoard);
			(window : Dynamic).showFullscreenAdv();
			#if debug
			if (lbLeaderBoard != null && lbLeaderBoard.entries != null) {
				trace("lb: " + lbLeaderBoard.userRank + " / " + lbLeaderBoard.entries);
			}
			#end
			#end
		}
		if (level.lastSnakeDeltaX != 0 || level.lastSnakeDeltaY != 0) {
			snakeHeadDir = level.lastSnakeDeltaX < 0 ? 0 : (level.lastSnakeDeltaX > 0 ? 2 : (level.lastSnakeDeltaY < 1 ? 1 : 3));
		}

		stepCount++;
		if (stepCount > 4) {
			stepCount = 0;

			/*audioStep.stop();
				audioStep = switch (Std.random(6)) {
					case 0: Audio.play(Assets.sounds.E);
					case 1: Audio.play(Assets.sounds.Gb);
					case 2: Audio.play(Assets.sounds.G);
					case 3: Audio.play(Assets.sounds.A);
					case 4: Audio.play(Assets.sounds.B);
					case 5: Audio.play(Assets.sounds.C);
					case 6: Audio.play(Assets.sounds.D);
					default: Audio.play(Assets.sounds.E);
				};
				audioStep.play(); */
		}

		if (!isGaming) {
			// audioStep.stop();
			audioExplosion.play();
		}

		if (destinationPoints.length < 1) {
			spawnThreeDestinationPoints();
			phase++;
		}
	}

	final colors:Array<Int> = [
		0xFFFF0000,
		0xFF00FF00,
		0xFF0000FF,
	];

	function getRandomColor():Int {
		return colors[Std.random(colors.length)];
	}

	function createMeal(_array:Array<Meal>, _x:Int, _y:Int, _color:Int):Meal {
		_array.push(new Meal(_x, _y, _color));
		return _array[_array.length - 1];
	}

	function spawnThreeDestinationPoints():Void {
		if (level.snake.length < 5) return;
		final head = level.snake[0];
		final mapW = level.pathFinderMap.mapW;
		final mapH = level.pathFinderMap.mapH;
		final minGap = 2;
		final x1 = Std.random(mapW - minGap);
		final x2 = x1 + minGap + Std.random(mapW - x1 - minGap);
		final y1 = Std.random(level.pathFinderMap.mapH - minGap);
		final y2 = y1 + minGap + Std.random(mapH - y1 - minGap);

		final snakeIndexes:Array<Int> = [];
		while (snakeIndexes.length < 4) {
			final index = Std.random(level.snake.length);
			if (index > 0 && !snakeIndexes.contains(index)) { // avoid snake head
				snakeIndexes.push(index);
			}
		}
		// trace(snakeIndexes);

		final newOnes:Array<Meal> = [
			createMeal(destinationPoints, x1, y1, level.snake[snakeIndexes[0]].color),
			createMeal(destinationPoints, x2, y1, level.snake[snakeIndexes[1]].color),
			createMeal(destinationPoints, x1, y2, level.snake[snakeIndexes[2]].color),
			createMeal(destinationPoints, x2, y2, level.snake[snakeIndexes[3]].color)
		];

		var isOneRemoved = false;
		for (meal in newOnes) {
			if (meal.pos.x == head.pos.x && meal.pos.y == head.pos.y) {
				isOneRemoved = true;
				destinationPoints.remove(meal);
				break;
			}
		}
		if (!isOneRemoved) {
			destinationPoints.remove(newOnes[Std.random(newOnes.length)]);
		}
	}

	var snakeHeadDir:Int;

	function lerpSineInOut(_ratio:Float):Float {
		return -0.5 * (Math.cos(Math.PI * _ratio) - 1);
	}

	function colorLerp(ratio:Float, c1:Color, c2:Color):Color {
		if (ratio < 0 || ratio > 1) throw 'ratio $ratio is out of 0-1 range';
		final c1:Int = c1;
		final c2:Int = c2;
		final a1 = c1 >>> 24;
		final r1 = (c1 >> 16) & 0xFF;
		final g1 = (c1 >> 8) & 0xFF;
		final b1 = c1 & 0xFF;
		final a2 = c2 >>> 24;
		final r2 = (c2 >> 16) & 0xFF;
		final g2 = (c2 >> 8) & 0xFF;
		final b2 = c2 & 0xFF;
		final a = Std.int(a1 * (1 - ratio) + a2 * ratio);
		final r = Std.int(r1 * (1 - ratio) + r2 * ratio);
		final g = Std.int(g1 * (1 - ratio) + g2 * ratio);
		final b = Std.int(b1 * (1 - ratio) + b2 * ratio);
		return Color.fromValue((a << 24) | (r << 16) | (g << 8) | b);
	}

	inline function getDeltaXY(_part:SnakePart):Vec2Int {
		return {
			x: _part.pos.x - _part.prevTickPos.x,
			y: _part.pos.y - _part.prevTickPos.y
		};
	}

	function getTweenedCellCoords(_part:SnakePart, _normalCellRatio:Float, _lerpedCellRatio:Float):Vec2 {
		final deltaXY = getDeltaXY(_part);
		final tweenedDeltaX = deltaXY.x * (Math.abs(deltaXY.x) > 1 ? _lerpedCellRatio : _normalCellRatio);
		final tweenedDeltaY = deltaXY.y * (Math.abs(deltaXY.y) > 1 ? _lerpedCellRatio : _normalCellRatio);
		return {
			x: (_part.prevTickPos.x + tweenedDeltaX) * tileset.tsizeW,
			y: (_part.prevTickPos.y + tweenedDeltaY) * tileset.tsizeH
		};
	}

	public function render(_g:Graphics, _camX:Float, _camY:Float):Void {
		_g.color = GameDisplay.middleColor;
		_g.fillRect(_camX, _camY, renderAreaSize.x, renderAreaSize.y);
		for (destination in destinationPoints) {
			_g.color = destination.color;
			_g.fillRect(
				_camX + destination.pos.x * tileset.tsizeW,
				_camY + destination.pos.y * tileset.tsizeH,
				tileset.tsizeW, tileset.tsizeH);
		}

		if (level.pathFinderMap != null) {
			_g.color = GameDisplay.blackColor;
			for (iy in 0...level.pathFinderMap.mapH) {
				final y = _camY + iy * tileset.tsizeH;
				_g.drawLine(_camX, y, _camX + level.pathFinderMap.mapW * tileset.tsizeW, y);
			}
			for (ix in 0...level.pathFinderMap.mapW) {
				final x = _camX + ix * tileset.tsizeW;
				_g.drawLine(x, _camY, x, _camY + level.pathFinderMap.mapH * tileset.tsizeH);
			}
		}

		_g.color = 0xFFFFFFFF;
		for (passage in passagesThroughSnake) {
			_g.fillRect(
				_camX + passage.pos.x * tileset.tsizeW,
				_camY + passage.pos.y * tileset.tsizeH,
				tileset.tsizeW, tileset.tsizeH);
			// _g.fillRect(
			// 	_camX + passage.prevTickPos.x * tileset.tsizeW,
			// 	_camY + passage.prevTickPos.y * tileset.tsizeH,
			// 	tileset.tsizeW, tileset.tsizeH);
		}

		final cellMovementRatio = /*isPaused ? 1 :*/ movementTimer.value / movementTimer.max;
		final lerped = lerpSineInOut(cellMovementRatio);
		_g.color = 0xFFFFFFFF;
		for (part in level.snake) {
			if (part.isBeyondEdge) continue;
			final tweened = getTweenedCellCoords(part, cellMovementRatio, lerped);
			tilemap.drawTile(_g, _camX + tweened.x, _camY + tweened.y, 0, 0, 0);
		}

		final offX = tileset.tsizeW * 0.245;
		final offY = tileset.tsizeH * 0.245;
		for (partI in 0...level.snake.length - 1) { // avoid snake head
			final part = level.snake[level.snake.length - 1 - partI];
			if (part.isBeyondEdge) continue;
			_g.color = part.color;
			final tweened = getTweenedCellCoords(part, cellMovementRatio, lerped);
			_g.fillRect(
				_camX + offX + tweened.x,
				_camY + offY + tweened.y,
				tileset.tsizeW - offX * 2, tileset.tsizeH - offY * 2);
		}

		final ratio = (movementTimer.max - maxSnakeLength) / (minSnakeLength - maxSnakeLength);
		_g.color = speedometerColor;
		_g.fillRect(_camX + 45, _camY + renderAreaSize.y + 2, 56 * ratio, 8);

		_g.color = 0xFFFFFFFF;
		if (level.snake.length > 0) {
			final head = level.snake[0];
			final headTweened = getTweenedCellCoords(head, cellMovementRatio, lerped);
			tilemap.drawTile(_g, _camX + headTweened.x, _camY + headTweened.y, 1 + snakeHeadDir, 0, 0);
		}

		final stateString = !isGaming ? "Проигрыш. Жми R (крестик)" : (isPaused ? "Пауза" : "");
		_g.drawString(stateString, _camX + 1, _camY - 17);
		_g.drawString("Скорость", _camX + 1, _camY + renderAreaSize.y - 6);
		final scoreString = "" + score;
		_g.drawString(scoreString, _camX + renderAreaSize.x - _g.font.width(_g.fontSize, scoreString), _camY +
			renderAreaSize.y - 6);

		if (!isGaming && lbLeaderBoard != null && lbLeaderBoard.entries != null) {
			final cellH = 11;
			final y2 = _camY + 11;
			_g.color = GameDisplay.blackColor;
			_g.fillRect(_camX, _camY, renderAreaSize.x, renderAreaSize.y);
			_g.color = 0xFFFFFFFF;
			_g.fillRect(_camX, y2 + 6.5 + (lbLeaderBoard.userRank - 1) * cellH, renderAreaSize.x, cellH);

			_g.drawString("ЗАЛ СЛАВЫ:", _camX + 1, _camY);
			for (i in 0...10) {
				if (i >= lbLeaderBoard.entries.length) return;
				final entry = lbLeaderBoard.entries[i];
				_g.color = lbLeaderBoard.userRank - 1 == i ? 0xFF000000 : 0xFFFFFFFF;
				_g.drawString(entry.rank + ". " + entry.score + " by " + entry.player.publicName, _camX + 4, y2 + i * cellH);
			}
		}
	}
}

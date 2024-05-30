import SnakeLevel.SnakePart;
import aps.Counter;
import aps.Types;
import aps.render.TiledLayer;
import kha.Assets;
import kha.audio1.Audio;
import kha.audio1.AudioChannel;
import kha.graphics2.Graphics;

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
	public var isPaused(default, null):Bool;
	public var isGaming(default, null):Bool;
	public var score(default, null):Int;

	final tileset:Tileset;
	final tilemap:TiledLayer;
	final level:SnakeLevel;
	final movementTimer:Counter;
	final movementDelta:Vec2Int = {x: 0, y: 0};
	final audioExplosion:AudioChannel;
	final audioGoal:AudioChannel;
	var audioStep:AudioChannel;

	public function new() {
		tileset = new Tileset(Assets.images.tiles, 16, 16);
		tilemap = new TiledLayer(tileset, Loader.atlas);
		level = new SnakeLevel();
		movementTimer = new Counter(15, movementTimerTick);
		audioExplosion = Audio.play(Assets.sounds.explosion);
		audioExplosion.stop();
		audioGoal = Audio.play(Assets.sounds.goal);
		audioGoal.stop();
		audioStep = Audio.play(Assets.sounds.E);
		audioStep.stop();
	}

	function resetSnake(_parts:Array<SnakePart>):Void {
		level.resetSnake(_parts);
		movementDelta.x = 0;
		movementDelta.y = 0;
		snakeHeadDir = 0;
	}

	var stepCount:Int;
	var phase:Int;
	final destinationPoints:Array<Meal> = [];
	final meals:Array<Meal> = [];
	final passagesThroughSnake:Array<SnakePart> = [];

	public function resetLevel(_w:Int = -1, _h:Int = -1):Void {
		if (_h < 1) _h = _w;
		if (_w < 1) {
			_w = level.pathFinderMap.mapW;
			_h = level.pathFinderMap.mapH;
		}
		isPaused = false;
		isGaming = false;
		score = 0;

		level.resetLevel(_w, _h);
		renderAreaSize.x = level.pathFinderMap.mapW * tileset.tsizeW;
		renderAreaSize.y = level.pathFinderMap.mapH * tileset.tsizeH;
		resetSnake([
			for (i in 0...5) new SnakePart(0, 0, getRandomColor())
		]);

		stepCount = 0;
		phase = -1;
		destinationPoints.resize(0);
		meals.resize(0);
		passagesThroughSnake.resize(0);
		isGaming = true;
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

	public function update():Void {
		if (!(GameDisplay.keysPollingDir.x == 0 && GameDisplay.keysPollingDir.y == 0)) {
			movementDelta.x = GameDisplay.keysPollingDir.x;
			movementDelta.y = GameDisplay.keysPollingDir.y;
		}
		movementTimer.tick();
	}

	var snakeHeadDir:Int;

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

					score++;
					audioGoal.stop();
					audioGoal.play();
				}
			}
		}

		if (!isGaming) return;
		if (movementDelta.x < 0 && level.lastSnakeDeltaX > 0) movementDelta.x = 0;
		else if (movementDelta.x > 0 && level.lastSnakeDeltaX < 0) movementDelta.x = 0;
		if (movementDelta.y < 0 && level.lastSnakeDeltaY > 0) movementDelta.y = 0;
		else if (movementDelta.y > 0 && level.lastSnakeDeltaY < 0) movementDelta.y = 0;
		isPaused = (movementDelta.x == 0 && movementDelta.y == 0);
		if (isPaused) return;

		if (level.trySnakeStep(movementDelta.x, movementDelta.y)) {} else {
			isGaming = false;
			trace("ban!");
		}
		snakeHeadDir = level.lastSnakeDeltaX < 0 ? 1 : (level.lastSnakeDeltaX > 0 ? 3 : (level.lastSnakeDeltaY < 0 ? 2 : 4));

		stepCount++;
		if (stepCount > 3) {
			stepCount = 0;
			level.addPartToSnakeEnd(getRandomColor());

			audioStep.stop();
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
			audioStep.play();
		}
		if (!isGaming) {
			audioStep.stop();
			audioExplosion.play();
		}

		if (destinationPoints.length < 1) {
			spawnThreeDestinationPoints();
			phase++;
		}
	}

	function lerpSineInOut(_ratio:Float):Float {
		return -0.5 * (Math.cos(Math.PI * _ratio) - 1);
	}

	function getTweenedCellCoords(_part:SnakePart, _normalCellRatio:Float, _lerpedCellRatio:Float):Vec2 {
		final deltaX = _part.pos.x - _part.prevTickPos.x;
		final deltaY = _part.pos.y - _part.prevTickPos.y;
		final tweenedDeltaX = deltaX * (Math.abs(deltaX) > 1 ? _lerpedCellRatio : _normalCellRatio);
		final tweenedDeltaY = deltaY * (Math.abs(deltaY) > 1 ? _lerpedCellRatio : _normalCellRatio);
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

		final cellMovementRatio = isPaused ? 1 : movementTimer.value / movementTimer.max;
		final lerped = lerpSineInOut(cellMovementRatio);
		_g.color = 0xFFFFFFFF;
		for (part in level.snake) {
			final tweened = getTweenedCellCoords(part, cellMovementRatio, lerped);
			tilemap.drawTile(_g, _camX + tweened.x, _camY + tweened.y, 0, 0, 0);
		}

		final offX = tileset.tsizeW * 0.25;
		final offY = tileset.tsizeH * 0.25;
		for (partI in 0...level.snake.length) {
			final part = level.snake[level.snake.length - 1 - partI];
			_g.color = part.color;
			final tweened = getTweenedCellCoords(part, cellMovementRatio, lerped);
			_g.fillRect(
				_camX + offX + tweened.x,
				_camY + offY + tweened.y,
				tileset.tsizeW - offX * 2, tileset.tsizeH - offY * 2);
		}

		if (level.snake.length > 0) {
			final head = level.snake[0];
			final headTweened = getTweenedCellCoords(head, cellMovementRatio, lerped);
			tilemap.drawTile(_g, _camX + headTweened.x, _camY + headTweened.y, snakeHeadDir, 0, 0);
		}

		_g.color = 0xFFFFFFFF;
		final stateString = !isGaming ? "Конец игры. Жми R (крестик)" : (isPaused ? "Пауза" : "");
		_g.drawString(stateString, _camX + 1, _camY - 17);
		final scoreString = "" + score;
		_g.drawString(scoreString, _camX + renderAreaSize.x - _g.font.width(_g.fontSize, scoreString), _camY +
			renderAreaSize.y - 6);
	}
}

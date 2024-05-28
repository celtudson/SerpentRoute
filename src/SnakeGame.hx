import SnakeLevel.SnakePart;
import aps.Counter;
import aps.Types;
import aps.render.TiledLayer;
import kha.Assets;
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
	public final renderAreaSize:Vec2 = {x: 0, y: 0};

	final tileset:Tileset;
	final tilemap:TiledLayer;
	final level:SnakeLevel;
	final movementTimer:Counter;
	final movementDelta:Vec2Int = {x: 0, y: 0};

	public function new() {
		tileset = new Tileset(Assets.images.tiles, 16, 16);
		tilemap = new TiledLayer(tileset, Loader.atlas);
		level = new SnakeLevel();
		movementTimer = new Counter(120, movementTimerTick);
	}

	function resetSnake(_parts:Array<SnakePart>):Void {
		level.resetSnake(_parts);
	}

	final destinationPoints:Array<Meal> = [];

	public function resetLevel(_w:Int, _h:Int):Void {
		level.resetLevel(_w, _h);
		renderAreaSize.x = level.pathFinderMap.mapW * tileset.tsizeW;
		renderAreaSize.y = level.pathFinderMap.mapH * tileset.tsizeH;
		resetSnake([
			for (i in 0...4) new SnakePart(0, 0, getRandomColor())
		]);

		destinationPoints.resize(0);
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
		if (level.snake.length < 1) return;
		final head = level.snake[0];
		final mapW = level.pathFinderMap.mapW;
		final mapH = level.pathFinderMap.mapH;
		final minGap = 2;
		final x1 = Std.random(mapW - minGap);
		final x2 = x1 + minGap + Std.random(mapW - x1 - minGap);
		final y1 = Std.random(level.pathFinderMap.mapH - minGap);
		final y2 = y1 + minGap + Std.random(mapH - y1 - minGap);
		final newOnes:Array<Meal> = [
			createMeal(destinationPoints, x1, y1, getRandomColor()),
			createMeal(destinationPoints, x2, y1, getRandomColor()),
			createMeal(destinationPoints, x1, y2, getRandomColor()),
			createMeal(destinationPoints, x2, y2, getRandomColor())
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

	var phase:Int = -1;
	var isPaused:Bool = false;
	var isGaming:Bool = false;

	public function update():Void {
		if (!(GameDisplay.keysPollingDir.x == 0 && GameDisplay.keysPollingDir.y == 0)) {
			movementDelta.x = GameDisplay.keysPollingDir.x;
			movementDelta.y = GameDisplay.keysPollingDir.y;
		}
		movementTimer.tick();
	}

	function movementTimerTick(_t:Counter):Void {
		_t.reset();

		final head = level.snake[0];
		for (meal in destinationPoints.copy()) {
			if (head.pos.x == meal.pos.x && head.pos.y == meal.pos.y) {
				destinationPoints.remove(meal);
				level.addPartToSnakeEnd(meal.color);
			}
		}
		if (destinationPoints.length < 1) {
			spawnThreeDestinationPoints();
			phase++;
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
		for (meal in destinationPoints) {
			_g.color = meal.color;
			_g.fillRect(
				_camX + meal.pos.x * tileset.tsizeW,
				_camY + meal.pos.y * tileset.tsizeH,
				tileset.tsizeW, tileset.tsizeH);
		}
		if (level != null && level.pathFinderMap != null) {
			_g.color = 0xFF000000;
			for (iy in 0...level.pathFinderMap.mapH) {
				final y = _camY + iy * tileset.tsizeH;
				_g.drawLine(_camX, y, _camX + level.pathFinderMap.mapW * tileset.tsizeW, y);
			}
			for (ix in 0...level.pathFinderMap.mapW) {
				final x = _camX + ix * tileset.tsizeW;
				_g.drawLine(x, _camY, x, _camY + level.pathFinderMap.mapH * tileset.tsizeH);
			}

			/*if (Main.isDebug) {
				final delimiter = 2;
				final scale = Main.scale / delimiter;
				// _g.transformation.setFrom(FastMatrix3.scale(scale, scale));
				_g.fontSize = 20;
				_g.color = 0x80FF0000;
				for (iy => row in level.pathFinderMap.spreadMap) {
					final y = _camY + (-2 + iy * tileset.tsizeH) * delimiter;
					for (ix => cell in row) {
						final x = _camX + (ix * tileset.tsizeW) * delimiter;
						final costing = level.pathFinderMap.costingMap[iy][ix];
						if (costing < 0) _g.fillRect(_camX + ix * tileset.tsizeW, _camY + iy * tileset.tsizeH,
							tileset.tsizeW, tileset.tsizeH);
						// _g.drawString("" + costing, x, y);
					}
				}
				// _g.transformation.setFrom(FastMatrix3.scale(Main.scale, Main.scale));
			}*/
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
			final tileId = level.lastSnakeDeltaX < 0 ? 1 : (level.lastSnakeDeltaX > 0 ? 3 : (level.lastSnakeDeltaY < 0 ? 2 : 4));
			final headTweened = getTweenedCellCoords(head, cellMovementRatio, lerped);
			tilemap.drawTile(_g, _camX + headTweened.x, _camY + headTweened.y, tileId, 0, 0);
		}

		_g.color = 0xFFFFFFFF;
		final stateString = !isGaming ? "Конец игры" : (isPaused ? "Пауза" : "");
		_g.drawString(stateString, 8, -1);
	}
}

package;

import aps.PathFinderMap;
import aps.Types;

class SnakePart {
	public final pos:Vec2Int;
	public final prevTickPos:Vec2Int;
	public var color:Int;

	public function new(_x:Int, _y:Int, _color:Int) {
		pos = {x: _x, y: _y};
		prevTickPos = {x: _x, y: _y};
		color = _color;
	}
}

class SnakeLevel {
	public final snake:Array<SnakePart> = [];
	public var lastSnakeHeadX(default, null):Int = 0;
	public var lastSnakeHeadY(default, null):Int = 0;
	public var lastSnakeDeltaX(default, null):Int = 0;
	public var lastSnakeDeltaY(default, null):Int = 0;

	public function resetSnake(_parts:Array<SnakePart>):Void {
		snake.resize(0);
		for (part in _parts) snake.push(part);
		if (snake.length < 1) return;
		lastSnakeHeadX = snake[0].pos.x;
		lastSnakeHeadY = snake[0].pos.y;
		updateCollideMap();
	}

	public function addPartToSnakeEnd(_color:Int):SnakePart {
		if (snake.length < 1) return null;
		final snakeEnd = snake[snake.length - 1];
		final part:SnakePart = new SnakePart(snakeEnd.pos.x, snakeEnd.pos.y, _color);
		snake.push(part);
		return part;
	}

	public var pathFinderMap:PathFinderMap;

	public function updateCollideMap():Void {
		if (pathFinderMap == null) return;
		for (iy => row in pathFinderMap.costingMap) {
			for (ix in 0...row.length) {
				row[ix] = 0;
			}
		}
		for (part in snake) {
			pathFinderMap.costingMap[part.pos.y][part.pos.x] = -1;
		}
		// trace(pathFinderMap.costingMap);
	}

	public function new() {}

	public function resetLevel(_w:Int, _h:Int):Void {
		final collideMap:Array<Array<Float>> = [
			for (iy in 0..._h) [
				for (ix in 0..._w) 0
			]
		];
		pathFinderMap = new PathFinderMap(collideMap);
		pathFinderMap.isPassabilityAlwaysEqualToOne = true;
		updateCollideMap();
	}

	public function trySnakeStep(_deltaX:Int, _deltaY:Int):Bool {
		if (pathFinderMap == null || snake.length < 1) return true;
		final snakeHead = snake[0];
		final next:Vec2Int = {
			x: snakeHead.pos.x + _deltaX,
			y: snakeHead.pos.y + _deltaY
		};
		for (part in snake) {
			part.prevTickPos.x = part.pos.x;
			part.prevTickPos.y = part.pos.y;
		}
		if (lastSnakeHeadX == next.x && lastSnakeHeadY == next.y) return true;
		lastSnakeDeltaX = _deltaX;
		lastSnakeDeltaY = _deltaY;

		// if (!(next.x > -1 && next.y > -1 && next.x < pathFinderMap.mapW && next.y < pathFinderMap.mapH)) return false;
		if (next.x == -1) next.x += pathFinderMap.mapW;
		else if (next.x == pathFinderMap.mapW) next.x -= pathFinderMap.mapW;
		if (next.y == -1) next.y += pathFinderMap.mapH;
		else if (next.y == pathFinderMap.mapH) next.y -= pathFinderMap.mapH;

		final snakeEnd = snake[snake.length - 1];
		if (pathFinderMap.costingMap[next.y][next.x] < 0 && !(snakeEnd.pos.x == next.x && snakeEnd.pos.y == next.y)) return false;

		final prevSnakePartPos:Vec2Int = {x: snakeHead.pos.x, y: snakeHead.pos.y};
		snakeHead.pos.x = lastSnakeHeadX = next.x;
		snakeHead.pos.y = lastSnakeHeadY = next.y;
		for (i in 1...snake.length) {
			final part = snake[i];
			final prevX = part.pos.x;
			final prevY = part.pos.y;
			part.pos.x = prevSnakePartPos.x;
			part.pos.y = prevSnakePartPos.y;
			prevSnakePartPos.x = part.prevTickPos.x = prevX;
			prevSnakePartPos.y = part.prevTickPos.y = prevY;
		}
		updateCollideMap();
		return true;
	}
}

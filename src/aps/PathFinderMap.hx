package aps;

import aps.Types;

typedef SpreadCell = {
	costing:Float,
	whereYouFrom:Vec2Int
}

class PathFinderMap {
	public final costingMap:Array<Array<Float>>;
	public final spreadMap:Array<Array<SpreadCell>>;
	public final mapW:Int;
	public final mapH:Int;

	public function isInside(_x:Int, _y:Int):Bool {
		return (_x >= 0 && _y >= 0 && _x < mapW && _y < spreadMap.length);
	}

	public var isHexagonal = false;
	public var isAllowDiagonalPassageInSquareBoard = false; // it will always be false if isHexagonal is true
	public var isPassabilityAlwaysEqualToOne = false; // in this case, the map values will be ignored

	public function new(_costingMap:Array<Array<Float>>) {
		costingMap = _costingMap;
		mapW = costingMap[0].length;
		for (row in costingMap) {
			if (row.length > mapW) mapW = row.length;
		}
		mapH = _costingMap.length;

		spreadMap = [
			for (iy in 0...mapH) [
				for (ix in 0...mapW) {
					costing: 69,
					whereYouFrom: null
				}
			]
		];
		clearSpreadMap();
	}

	function clearSpreadMap():Void {
		for (iy => row in spreadMap) {
			for (ix => cell in row) {
				// Any value less than zero is considered an obstacle
				cell.costing = costingMap[iy][ix] >= 0 ? Math.POSITIVE_INFINITY : -1;
				cell.whereYouFrom = null;
			}
		}
	}

	public function spreadMoves(_startX:Int, _startY:Int):Void {
		if (!isInside(_startX, _startY)) return;
		clearSpreadMap();
		spreadMap[_startY][_startX].costing = 0;
		final nextCellsForCheck:Array<Vec2Int> = [{x: _startX, y: _startY}];

		function spreadCell(_fromX:Int, _fromY:Int):Void {
			function set(currentX:Int, currentY:Int):Void {
				final current = spreadMap[currentY][currentX];
				if (isPassabilityAlwaysEqualToOne) {
					if (current.costing != Math.POSITIVE_INFINITY) return;
					current.costing = spreadMap[_fromY][_fromX].costing + 1;
				} else {
					final costing = costingMap[currentY][currentX] + spreadMap[_fromY][_fromX].costing;
					if (costing >= current.costing) return;
					current.costing = costing;
					// trace(costing);
				}
				current.whereYouFrom = {x: _fromX, y: _fromY};
				nextCellsForCheck.push({x: currentX, y: currentY});
			}

			final isDiagonal = !isHexagonal && isAllowDiagonalPassageInSquareBoard;
			if (_fromX > 0) {
				set(_fromX - 1, _fromY);
				if (isDiagonal && _fromY < mapH - 1) set(_fromX - 1, _fromY + 1);
			}
			if (_fromY < mapH - 1) {
				set(_fromX, _fromY + 1);
				if (isDiagonal && _fromX < mapW - 1) set(_fromX + 1, _fromY + 1);
			}
			if (_fromX < mapW - 1) {
				set(_fromX + 1, _fromY);
				if (isDiagonal && _fromY > 0) set(_fromX + 1, _fromY - 1);
			}
			if (_fromY > 0) {
				set(_fromX, _fromY - 1);
				if (isDiagonal && _fromX > 0) set(_fromX - 1, _fromY - 1);
			}
			if (isHexagonal) {
				if (_fromY % 2 == 0) {
					if (_fromX > 0) {
						if (_fromY > 0) set(_fromX - 1, _fromY - 1);
						if (_fromY < mapH - 1) set(_fromX - 1, _fromY + 1);
					}
				} else {
					if (_fromX < mapW - 1) {
						if (_fromY > 0) set(_fromX + 1, _fromY - 1);
						if (_fromY < mapH - 1) set(_fromX + 1, _fromY + 1);
					}
				}
			}
		}

		for (i in 0...mapH * mapW) {
			final currentCellsForCheck:Array<Vec2Int> = [];
			for (c in nextCellsForCheck)
				currentCellsForCheck.push({x: c.x, y: c.y});
			nextCellsForCheck.resize(0);

			if (currentCellsForCheck.length == 0) break;
			for (c in currentCellsForCheck) {
				if (costingMap[c.y][c.x] == null) continue;
				spreadCell(c.x, c.y);
			}
		}
		nextCellsForCheck.resize(0);
	}

	public function buildPath(_targetX:Int, _targetY:Int):Array<Vec2Int> {
		if (!isInside(_targetX, _targetY)) return [];

		final path:Array<Vec2Int> = [{x: _targetX, y: _targetY}];
		var from:Vec2Int = spreadMap[_targetY][_targetX].whereYouFrom;
		while (from != null) {
			path.unshift(from);
			from = spreadMap[from.y][from.x].whereYouFrom;
		}
		path.shift();
		return path;
	}
}

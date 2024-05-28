package aps;

typedef Vec2 = {
	x:Float,
	y:Float,
}

typedef Vec2Int = {
	x:Int,
	y:Int,
}

typedef RectInt = {
	w:Int,
	h:Int,
	x:Int,
	y:Int
}

typedef RectWithIntSize = {
	w:Int,
	h:Int,
	x:Float,
	y:Float
}

typedef DebugLine = {
	n:Int,
	text:String
}

class Array2D<T> {
	public var map(default, set):Array<Array<T>>;
	public var w:Int;
	public var h:Int;

	function set_map(newMap:Array<Array<T>>) {
		if (newMap == null) return null;
		w = newMap[0].length;
		h = newMap.length;
		return map = newMap;
	}

	public function new(w:Int, h:Int, ?initialValue:T) {
		map = [
			for (iy in 0...h) [
				for (ix in 0...w) initialValue
			]
		];
	}
}

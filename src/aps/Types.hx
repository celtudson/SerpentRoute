package aps;

typedef Vec2 = {
	x:Float,
	y:Float,
}

typedef Vec2Int = {
	x:Int,
	y:Int,
}

typedef Rect = {
	x:Float,
	y:Float,
	w:Float,
	h:Float
}

typedef RectInt = {
	x:Int,
	y:Int,
	w:Int,
	h:Int
}

typedef RectWithIntSize = {
	x:Float,
	y:Float,
	w:Int,
	h:Int
}

typedef DebugLine = {
	n:Int,
	text:String
}

class Array2D<T> {
	public var map(default, set):Array<Array<T>>;
	public var w:Int;
	public var h:Int;

	function set_map(_newMap:Array<Array<T>>):Array<Array<T>> {
		if (_newMap == null) return null;
		w = _newMap[0].length;
		h = _newMap.length;
		return map = _newMap;
	}

	public function new(_w:Int, _h:Int, ?_initialValue:T) {
		map = [
			for (iy in 0..._h) [
				for (ix in 0..._w) _initialValue
			]
		];
	}
}

class ChangableValue<T> {
	public var value(default, null):T;
	public var callback:T->Void;

	public function new(_callback:T->Void) {
		callback = _callback;
	}

	public function set(_value:T):Bool {
		if (value != _value) {
			value = _value;
			if (callback != null) callback(value);
			return true;
		}
		return false;
	}
}

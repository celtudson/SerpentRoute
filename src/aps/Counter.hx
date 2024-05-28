package aps;

class Counter {
	public var isActive:Bool = false;
	public var callback:Counter->Void;
	public var value(default, set):Int;
	public var max(default, set):Int;

	function set_value(_value:Int):Int {
		if (!isActive) return value;
		if (_value < 0) _value = 0;
		else if (_value > max) _value = max;
		value = _value;
		// trace(value);
		checkOnHitMax();
		return value;
	}

	function set_max(_max:Int):Int {
		if (_max < 1) {
			trace("Attempt to set the maximum to less than 1!");
			return max;
		}
		max = _max;
		checkOnHitMax();
		return max;
	}

	public function new(_max:Int, _callback:Counter->Void) {
		if (_max == null) throw "Counter.new: _max is null!";
		max = _max;
		callback = _callback;
		reset();
	}

	public function reset():Void {
		isActive = true;
		value = 0;
	}

	public function tick():Int {
		return value++;
	}

	function checkOnHitMax():Void {
		if (!isActive) return;
		// trace("" + value + " / " + max);
		if (value < max) return;
		// trace("max!");
		isActive = false;
		if (callback != null) callback(this);
	}
}

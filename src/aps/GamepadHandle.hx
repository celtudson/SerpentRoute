package aps;

import kha.graphics2.Graphics;
import kha.input.Gamepad;

class GamepadHandle {
	public var axisX:Float;
	public var axisY:Float;
	public var axisAngle:Float;
	public final keys:Array<Bool> = [];

	static var onDownListener:Int->Void;
	static var onUpListener:Int->Void;

	public function new(_onDownListener:Int->Void, _onUpListener:Int->Void) {
		Gamepad.get().notify(onGamepadAxis, onGamepadButtons);
		onDownListener = _onDownListener;
		onUpListener = _onUpListener;
		reset();
	}

	public function reset():Void {
		axisX = 0;
		axisY = 0;
		axisAngle = 0;
		for (key in keys) key = false;
	}

	function onGamepadAxis(_axis:Int, _value:Float):Void {
		final x = _axis == 0 ? _value : axisX;
		final y = _axis == 1 ? -_value : axisY;
		axisX = x > -0.15 && x < 0.15 ? 0 : x;
		axisY = y > -0.15 && y < 0.15 ? 0 : y;
		axisAngle = Math.atan2(axisY, axisX);
	}

	function onGamepadButtons(_key:Int, _state:Float):Void {
		if (_state == 0) {
			keys[_key] = false;
			onUpListener(_key);
		} else {
			keys[_key] = true;
			onDownListener(_key);
		}
	}

	public function render(_g:Graphics):Void {
		final prev = _g.color;
		_g.color = 0xFFFF0000;
		_g.drawString('${axisX}', 0, 0);
		_g.drawString('${axisY}', 0, 20);
		_g.fillRect(40 + axisX * 32, 40 + axisY * 32, 4, 4);
		_g.drawLine(40, 40, 40 + Math.cos(axisAngle) * 32, 40 + Math.sin(axisAngle) * 32);
		_g.color = prev;
	}
}

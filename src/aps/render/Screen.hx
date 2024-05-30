package aps.render;

import aps.Types;
import kha.Canvas;
import kha.Font;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.math.FastMatrix3;

private class Fps {
	public var fpsCount(default, null):Int = 0;

	var accumulatedTime = 0.0;
	var lastTime = 0.0;
	var accumulatedFrames = 0;

	public function new() {}

	public function update():Int {
		final realTime = Scheduler.realTime();
		final deltaTime = realTime - lastTime;
		lastTime = realTime;
		accumulatedTime += deltaTime;

		if (accumulatedTime >= 1) {
			accumulatedTime = 0;
			fpsCount = accumulatedFrames;
			accumulatedFrames = 0;
		}
		return fpsCount;
	}

	final baseFontSize = 20;

	public function render(_g:Graphics, _screen:Screen):Void {
		if (_screen.showFps) {
			_g.begin(false);
			_g.transformation.setFrom(FastMatrix3.identity());
			_g.font = Screen.systemfont;
			_g.fontSize = Std.int(baseFontSize * (_screen.isFpsScaled ? _screen.scale : 1));
			final windowW = System.windowWidth();
			final windowH = System.windowHeight();

			final txt = '$fpsCount | ${windowW}x${windowH} ${_screen.scale}x';
			final size = Screen.getSystemFontSize(_g.fontSize, txt);
			final x = windowW - size.x;
			_g.color = 0x80000000;
			_g.fillRect(x, 0, size.x, size.y);
			_g.color = 0xFFFFFFFF;
			_g.drawString(txt, x, -size.y);
			_g.end();
		}
		accumulatedFrames++;
	}
}

class Mouser {
	public final id:Int;
	public var scale:Float = 1.0;
	public var x:Int = 0;
	public var y:Int = 0;
	public var button:Int = 0;
	public var isDown:Bool = false;

	public function new(_id:Int):Void {
		id = _id;
	}

	public var moveStartX(default, null):Int = 0;
	public var moveStartY(default, null):Int = 0;
	public var moveX(default, null):Int = 0;
	public var moveY(default, null):Int = 0;

	public function pressButton(_button:Int, _x:Int, _y:Int):Void {
		isDown = true;
		button = _button;
		x = Std.int(_x / scale);
		y = Std.int(_y / scale);
		moveStartX = x;
		moveStartY = y;
	}

	public function move(_x:Int, _y:Int, _mx:Int, _my:Int):Void {
		x = Std.int(_x / scale);
		y = Std.int(_y / scale);
	}

	public function releaseButton(_button:Int, _x:Int, _y:Int):Void {
		if (!isDown) return;
		isDown = false;
		button = _button;
		x = Std.int(_x / scale);
		y = Std.int(_y / scale);
	}
}

class Screen {
	public static var systemfont:Font;

	public static function getSystemFontSize(_fontSize:Int, _txt:String):Vec2Int {
		if (systemfont == null) return null;
		final h = Math.ceil(systemfont.height(_fontSize) / 2.666);
		final w = Math.ceil(systemfont.width(_fontSize, _txt));
		return {
			x: w,
			y: h
		}
	}

	public var scale(default, null):Float = 1.0;
	public var contentW(default, null):Int = 0;
	public var contentH(default, null):Int = 0;
	public var showFps:Bool = false;
	public var isFpsScaled:Bool = false;
	public var isIntegerScale:Bool = false;
	public var renderW(default, null):Int = 0;
	public var renderH(default, null):Int = 0;

	public function setScale(_scale:Float):Void {
		if (isIntegerScale && _scale >= 1) _scale = Std.int(_scale);
		trace(_scale);
		scale = _scale;
		renderW = Std.int(System.windowWidth() / scale);
		renderH = Std.int(System.windowHeight() / scale);
		mouser.scale = scale;
	}

	public function new() {}

	static var taskId = -1;
	static final fps = new Fps();
	public static final mouser:Mouser = new Mouser(0);

	public function show():Void {
		final keyboard = Keyboard.get();
		final mouse = Mouse.get();
		if (taskId != -1) {
			Scheduler.removeTimeTask(taskId);
			System.removeFramesListener(_onRender);
			if (keyboard != null) keyboard.remove(_onKeyDown, _onKeyUp, /*onKeyPress*/ null);
			if (mouse != null) mouse.remove(_onMouseDown, _onMouseUp, _onMouseMove, onMouseWheel, /*onMouseLeave*/ null);
		}
		taskId = Scheduler.addTimeTask(() -> {
			_onUpdate();
		}, 0, 1 / 60);
		System.notifyOnFrames(_onRender);

		if (keyboard != null) keyboard.notify(_onKeyDown, _onKeyUp, /*onKeyPress*/ null);
		for (key in keys.keys()) keys[key] = false;
		if (mouse != null) mouse.notify(_onMouseDown, _onMouseUp, _onMouseMove, onMouseWheel, /*onMouseLeave*/ null);
		mouser.scale = scale;
	}

	var prevScreenW:Float;
	var prevScreenH:Float;

	function _onUpdate():Void {
		final w = System.windowWidth();
		final h = System.windowHeight();
		if (w != prevScreenW || h != prevScreenH) {
			prevScreenW = w;
			prevScreenH = h;
			setScale(Math.min(w / contentW, h / contentH));
			// trace("resized scale: " + scale);
			onResize(scale);
		}
		onUpdate();
		fps.update();
	}

	function _onRender(_frames:Array<Framebuffer>):Void {
		final frame = _frames[0];
		final g = frame.g2;
		g.transformation.setFrom(FastMatrix3.scale(scale, scale));
		onRender(frame);
		fps.render(g, this);
	}

	function _onMouseDown(_button:Int, _x:Int, _y:Int):Void {
		mouser.pressButton(_button, _x, _y);
		onMouseDown(mouser);
	}

	function _onMouseMove(_x:Int, _y:Int, _mx:Int, _my:Int):Void {
		mouser.move(_x, _y, _mx, _my);
		onMouseMove(mouser);
	}

	function _onMouseUp(_button:Int, _x:Int, _y:Int):Void {
		mouser.releaseButton(_button, _x, _y);
		onMouseUp(mouser);
	}

	///
	public static function getKeysDirection():Direction {
		var dir:Direction = None;
		final isLeft = Screen.keys[KeyCode.Left];
		final isUp = Screen.keys[KeyCode.Up];
		final isRight = Screen.keys[KeyCode.Right];
		final isDown = Screen.keys[KeyCode.Down];
		if (isLeft && !isUp && !isRight && !isDown) dir = Direction.Left;
		else if (isLeft && isUp && !isRight && !isDown) dir = Direction.LeftUp;
		else if (!isLeft && isUp && !isRight && !isDown) dir = Direction.Up;
		else if (!isLeft && isUp && isRight && !isDown) dir = Direction.RightUp;
		else if (!isLeft && !isUp && isRight && !isDown) dir = Direction.Right;
		else if (!isLeft && !isUp && isRight && isDown) dir = Direction.RightDown;
		else if (!isLeft && !isUp && !isRight && isDown) dir = Direction.Down;
		else if (isLeft && !isUp && !isRight && isDown) dir = Direction.LeftDown;
		return dir;
	}

	public static final keys:Map<KeyCode, Bool> = [];
	public static var keySynonyms:KeyboardSynonyms;

	function _onKeyDown(_key:KeyCode):Void {
		keys[_key] = true;
		if (keySynonyms != null) keySynonyms.applySynonymKey(_key);
		onKeyDown(_key);
	}

	function _onKeyUp(_key:KeyCode):Void {
		keys[_key] = false;
		if (keySynonyms != null) keySynonyms.applySynonymKey(_key);
		onKeyUp(_key);
	}

	// functions for override

	function onUpdate():Void {}

	function onRender(_frame:Canvas):Void {}

	function onResize(_newScale:Float):Void {}

	function onKeyDown(_key:KeyCode):Void {}

	function onKeyUp(_key:KeyCode):Void {}

	function onMouseDown(_m:Mouser):Void {}

	function onMouseMove(_m:Mouser):Void {}

	function onMouseUp(_m:Mouser):Void {}

	function onMouseWheel(_delta:Int):Void {}

	function onMouseLeave():Void {}
}

enum abstract Direction(Int) {
	final None = -1;
	final Left;
	final LeftUp;
	final Up;
	final RightUp;
	final Right;
	final RightDown;
	final Down;
	final LeftDown;
}

class KeyboardSynonyms {
	public function new() {}

	final keySynonyms:Map<KeyCode, Array<KeyCode>> = [];

	public function add(_key:KeyCode, _keySynonym:KeyCode):Void {
		if (keySynonyms[_key] == null) keySynonyms[_key] = [];
		if (!keySynonyms[_key].contains(_keySynonym)) keySynonyms[_key].push(_keySynonym);
		if (keySynonyms[_keySynonym] == null) keySynonyms[_keySynonym] = [];
		if (!keySynonyms[_keySynonym].contains(_key)) keySynonyms[_keySynonym].push(_key);
	}

	public function applySynonymKey(_key:KeyCode):Void {
		final synonyms = keySynonyms[_key];
		if (synonyms == null) return;
		for (synonymKey in synonyms) {
			Screen.keys[synonymKey] = Screen.keys[_key];
		}
	}

	public function isPressed(_key:KeyCode):Bool {
		if (Screen.keys[_key]) return true;
		final synonyms = keySynonyms[_key];
		if (synonyms == null) return false;
		for (synonymKey in synonyms) {
			if (Screen.keys[synonymKey]) return true;
		}
		return false;
	}

	public function isEqual(_key1:KeyCode, _key2:KeyCode):Bool {
		if (_key1 == _key2) return true;
		final key1Synonyms = keySynonyms[_key1];
		if (key1Synonyms != null) {
			for (synonym1 in key1Synonyms) {
				if (synonym1 == _key2) return true;
			}
		}
		// final key2Synonyms = keySynonyms[_key2];
		// if (key2Synonyms != null) {
		// 	for (synonym2 in key2Synonyms) {
		// 		if (_key1 == synonym2) return true;
		// 	}
		// }
		return false;
	}
}

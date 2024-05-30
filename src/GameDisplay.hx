import aps.GamepadHandle;
import aps.Types;
import aps.render.Screen;
import kha.Canvas;
import kha.System;
import kha.input.KeyCode;

class GameDisplay extends Screen {
	public static final blackColor:Int = 0xFF071821;
	public static final middleColor:Int = 0xFF306850;
	public static final keysPollingDir:Vec2Int = {x: 0, y: 0};
	public static var gamepadHandler:GamepadHandle;

	final snakeGame:SnakeGame;
	final guiHeight:Int = 20;

	public function new() {
		super();
		showFps = true;
		isFpsScaled = true;
		show();
		isFpsScaled = false;
		isIntegerScale = true;

		Screen.keySynonyms = new KeyboardSynonyms();
		Screen.keySynonyms.add(Left, A);
		Screen.keySynonyms.add(Up, W);
		Screen.keySynonyms.add(Right, D);
		Screen.keySynonyms.add(Down, S);
		gamepadHandler = new GamepadHandle((_key:Int) -> {
			switch (_key) {
				case 0: if (!snakeGame.isGaming) snakeGame.resetLevel();
				case 12: Screen.keys[Up] = true;
				case 13: Screen.keys[Down] = true;
				case 14: Screen.keys[Left] = true;
				case 15: Screen.keys[Right] = true;
			}
		}, (_key:Int) -> {
			switch (_key) {
				case 0:
				case 12: Screen.keys[Up] = false;
				case 13: Screen.keys[Down] = false;
				case 14: Screen.keys[Left] = false;
				case 15: Screen.keys[Right] = false;
			}
		});

		snakeGame = new SnakeGame();
		snakeGame.resetLevel(9, 8);
		contentW = snakeGame.renderAreaSize.x;
		contentH = snakeGame.renderAreaSize.y + guiHeight;
	}

	var lastPressedDir:KeyCode = null;

	override function onKeyDown(_key:KeyCode):Void {
		if (Screen.keySynonyms.isEqual(_key, Left)) lastPressedDir = Left;
		else if (Screen.keySynonyms.isEqual(_key, Up)) lastPressedDir = Up;
		else if (Screen.keySynonyms.isEqual(_key, Right)) lastPressedDir = Right;
		else if (Screen.keySynonyms.isEqual(_key, Down)) lastPressedDir = Down;
		else if (_key == R && !snakeGame.isGaming) snakeGame.resetLevel();
	}

	override function onUpdate():Void {
		keysPollingDir.x = 0;
		keysPollingDir.y = 0;
		if (Screen.keys[Left]) keysPollingDir.x = -1;
		if (Screen.keys[Up]) keysPollingDir.y = -1;
		if (Screen.keys[Right]) keysPollingDir.x = keysPollingDir.x == -1 ? 0 : 1;
		if (Screen.keys[Down]) keysPollingDir.y = keysPollingDir.y == -1 ? 0 : 1;
		if (keysPollingDir.x != 0 && keysPollingDir.y != 0) {
			if (!(lastPressedDir == Left || lastPressedDir == Right)) keysPollingDir.x = 0;
			if (!(lastPressedDir == Up || lastPressedDir == Down)) keysPollingDir.y = 0;
		}
		// trace(lastPressedDir, keysPollingDir.x, keysPollingDir.y);

		snakeGame.update();
	}

	override function onMouseDown(_m:Mouser):Void {}

	override function onMouseWheel(_delta:Int):Void {}

	override function onRender(_frame:Canvas):Void {
		final g = _frame.g2;
		g.begin();
		g.font = Screen.systemfont;
		g.fontSize = 20;
		g.color = blackColor;
		g.fillRect(0, 0, renderW, renderH);
		g.color = 0xFFFFFFFF;
		// g.drawString("" + Screen.keys[Left] + ", " + Screen.keys[Up] + ", " + Screen.keys[Right] + ", " + Screen.keys[Down], 0, -9);

		snakeGame.render(g,
			System.windowWidth() / scale / 2 - contentW / 2,
			System.windowHeight() / scale / 2 - contentH / 2 + guiHeight / 2);

		g.end();
	}
}

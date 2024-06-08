import aps.Counter;
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
	final gameOffset:Int = 2;

	public function new() {
		super();
		showFps = true;
		// isFpsScaled = true;
		show();

		Screen.keySynonyms.add(Left, A);
		Screen.keySynonyms.add(Up, W);
		Screen.keySynonyms.add(Right, D);
		Screen.keySynonyms.add(Down, S);
		gamepadHandler = new GamepadHandle((_key:Int) -> {
			switch (_key) {
				case 0: snakeGame.resetLevel(true);
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
		snakeGame.resetLevel(false, 8, 8);

		// resizer.isIntegerScale = true;
		resizer.contentW.set(snakeGame.renderAreaSize.x + gameOffset * 2);
		resizer.contentH.set(snakeGame.renderAreaSize.y + gameOffset * 2 + guiHeight);
	}

	function lerpSineInOut(_ratio:Float):Float {
		return -0.5 * (Math.cos(Math.PI * _ratio) - 1);
	}

	override function onRender(_frame:Canvas):Void {
		final g = _frame.g2;
		g.begin();
		g.font = Screen.systemfont;
		g.fontSize = 20;
		g.color = blackColor;
		g.fillRect(0, 0, resizer.w, resizer.h);
		g.color = 0xFFFFFFFF;
		// g.drawString("" + Screen.keys[Left] + ", " + Screen.keys[Up] + ", " + Screen.keys[Right] + ", " + Screen.keys[Down], 0, -9);

		final centerX = System.windowWidth() / Resizer.currentScale / 2;
		final centerY = System.windowHeight() / Resizer.currentScale / 2;
		snakeGame.render(g,
			centerX - resizer.contentW.value / 2 + gameOffset,
			centerY - resizer.contentH.value / 2 + guiHeight / 2 + gameOffset);

		if (snakeGame.isPaused) {
			final ratio = notFocusedWarningTimer.value / notFocusedWarningTimer.max;
			final barOffset = 16 * lerpSineInOut(1 - ratio);
			final string = "Нажми на экран!";
			final w = g.font.width(g.fontSize, string) + 10;
			final h = g.font.height(g.fontSize);
			g.color = 0xFF000000;
			g.fillRect(centerX - w / 2 - barOffset, centerY - h / 2 - barOffset, w + barOffset * 2, h + barOffset * 2);
			g.color = 0xFFFFFFFF;
			g.drawString(string, centerX - w / 2 + 5, centerY - h / 2 - 2);
		}

		g.end();
	}

	var lastPressedDir:KeyCode = null;

	override function onKeyDown(_key:KeyCode):Void {
		if (Screen.keySynonyms.isEqual(_key, Left)) lastPressedDir = Left;
		else if (Screen.keySynonyms.isEqual(_key, Up)) lastPressedDir = Up;
		else if (Screen.keySynonyms.isEqual(_key, Right)) lastPressedDir = Right;
		else if (Screen.keySynonyms.isEqual(_key, Down)) lastPressedDir = Down;
		else if (_key == R) snakeGame.resetLevel(true);
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

		notFocusedWarningTimer.tick();
	}

	final notFocusedWarningTimer:Counter = new Counter(90, (_counter) -> {
		_counter.reset();
	});

	var isStartupClickNeeded = true;

	override function onMouseDown(_m:Mouser) {
		if (isStartupClickNeeded) {
			isStartupClickNeeded = false;
			if (snakeGame.audioBgm != null) snakeGame.audioBgm.play();
		}
		snakeGame.isPaused = false;
	}

	override function onFocusIn():Void {
		if (!isStartupClickNeeded) {
			snakeGame.isPaused = false;
			if (snakeGame.isGaming && snakeGame.audioBgm != null) snakeGame.audioBgm.play();
		}
	}

	override function onFocusOut():Void {
		snakeGame.isPaused = true;
		notFocusedWarningTimer.reset();
		if (snakeGame.audioBgm != null) snakeGame.audioBgm.pause();
	}
}

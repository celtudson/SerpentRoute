import Achievements.Achievement;
import SnakeLevel.SnakePart;
import aps.Types;
import aps.render.Screen;
import kha.Canvas;
import kha.input.KeyCode;

class GameDisplay extends Screen {
	public static final blackColor:Int = 0xFF071821;
	public static final achievements:Achievements = new Achievements();
	public static final keysPollingDir:Vec2Int = {x: 0, y: 0};

	final snakeGame:SnakeGame;

	public function new() {
		super();
		showFps = true;
		isFpsScaled = true;
		show();
		setScale(Main.scale);

		Screen.keySynonyms = new KeyboardSynonyms();
		Screen.keySynonyms.add(Left, A);
		Screen.keySynonyms.add(Up, W);
		Screen.keySynonyms.add(Right, D);
		Screen.keySynonyms.add(Down, S);

		final anus = new Achievement(achievements, "anus", "for test");
		final anus2 = achievements.add("Только Смерть почему-то Судья не позвал...", "Не дропнуть игру до финала");
		// trace(achievements.achievedIds);
		// anus.achieve();
		// anus2.achieve();
		// anus.achieve();
		// anus2.achieve();
		// trace(achievements.achievedIds);

		snakeGame = new SnakeGame();
		snakeGame.resetLevel(9, 8);
	}

	var lastPressedDir:KeyCode = null;

	override function onKeyDown(_key:KeyCode):Void {
		if (Screen.keySynonyms.isEqual(_key, Left)) lastPressedDir = Left;
		else if (Screen.keySynonyms.isEqual(_key, Up)) lastPressedDir = Up;
		else if (Screen.keySynonyms.isEqual(_key, Right)) lastPressedDir = Right;
		else if (Screen.keySynonyms.isEqual(_key, Down)) lastPressedDir = Down;
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
		g.color = Main.isDebug ? 0x80FF00FF : blackColor;
		g.fillRect(0, 0, w, h);
		g.color = 0xFFFFFFFF;

		snakeGame.render(g,
			Main.gameW / 2 - snakeGame.renderAreaSize.x / 2,
			Main.gameH / 2 - snakeGame.renderAreaSize.y / 2);

		g.end();
	}
}

import aps.Counter;
import aps.render.Atlas;
import aps.render.Screen;
import haxe.Resource;
import kha.AssetError;
import kha.Assets;
import kha.Canvas;
import kha.Font;
import kha.System;
import kha.graphics2.Graphics;
#if kha_html5
import js.Browser.window;
#end

class Loader extends Screen {
	public static var atlas(default, null):Atlas;

	public function new() {
		super();
		trace("Inlined resources: " + Resource.listNames());
		Screen.systemfont = Font.fromBytes(Resource.getBytes("systemfont"));
		final fontGlyphs:Array<Int> = [];
		for (i in 32...256) fontGlyphs.push(i);
		for (i in 1024...1280) fontGlyphs.push(i);
		Graphics.fontGlyphs = fontGlyphs;

		Assets.loadEverything(() -> {
			trace(Assets.progress);
			atlas = new Atlas(256);
			atlas.initFromAllAssets();
			#if kha_html5
			(window : Dynamic).trackReady();
			#end

			new GameDisplay();
		}, null, null, (error:AssetError) -> {
			throw error;
		});

		resizer.contentH.set(100);
		show();

		secCounter = new Counter(ticksPerDot * 3, _counter -> {
			secCounter.reset();
		});
	}

	final secCounter:Counter;
	final ticksPerDot = 30;

	override function onUpdate() {
		resizer.contentW.set(System.windowWidth());
		secCounter.tick();
	}

	override function onRender(_frame:Canvas):Void {
		final g = _frame.g2;
		g.begin();
		g.font = Screen.systemfont;
		g.fontSize = Std.int(100 * Resizer.currentScale);

		g.color = 0xFFFFFFFF;
		trace(Assets.progress);
		final w = resizer.contentW.value; // * Assets.progress;
		final halfH = resizer.contentH.value * 0.2;
		final y = System.windowHeight() * 0.5 - halfH;
		g.fillRect(0, y, w, halfH * 2);

		final loadingString = "Загрузка";
		final loadingX = System.windowWidth() - 100 - g.font.width(g.fontSize, loadingString);
		final loadingY = y - g.font.height(g.fontSize) * 0.9;
		g.drawString(loadingString, loadingX, loadingY);
		var dotsString = "";
		for (i in 0...1 + Std.int(secCounter.value / ticksPerDot)) dotsString += ".";
		g.drawString(dotsString, loadingX + g.font.width(g.fontSize, loadingString), loadingY);

		g.end();
	}
}

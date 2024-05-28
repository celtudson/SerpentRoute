import aps.render.Atlas;
import aps.render.Screen;
import haxe.Resource;
import kha.AssetError;
import kha.Assets;
import kha.Font;
import kha.graphics2.Graphics;

class Loader {
	public static var atlas(default, null):Atlas;

	public function new() {
		trace("Inlined resources: " + Resource.listNames());
		Screen.systemfont = Font.fromBytes(Resource.getBytes("systemfont"));
		final fontGlyphs:Array<Int> = [];
		for (i in 32...256) fontGlyphs.push(i);
		for (i in 1024...1280) fontGlyphs.push(i);
		Graphics.fontGlyphs = fontGlyphs;

		Assets.loadEverything(() -> {
			atlas = new Atlas(256);
			atlas.initFromAllAssets();

			new GameDisplay();
		}, null, null, (error:AssetError) -> {
			throw error;
		});
	}
}

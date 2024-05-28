import kha.System;
import kha.WindowOptions;
#if kha_html5
import js.Browser.document;
import js.html.CanvasElement;
#end

class Main {
	public static final isDebug:Bool = true;
	public static final title:String = "SerpentRoute";
	public static final gameW:Int = 160;
	public static final gameH:Int = 160;
	public static var scale(default, null):Float = 2;
	public static final w:Int = isDebug ? gameW : gameW;
	public static final h:Int = isDebug ? gameH : gameH;

	static function main() {
		final windowW = Std.int(w * scale);
		final windowH = Std.int(h * scale);
		System.start(
			new SystemOptions(title, windowW, windowH, {
				windowFeatures: WindowFeatures.FeatureMinimizable
			}), (window) -> {
				#if kha_html5
				document.documentElement.style.padding = "0";
				document.documentElement.style.margin = "0";
				document.body.style.padding = "0";
				document.body.style.margin = "0";
				final canvas:CanvasElement = cast document.getElementById("khanvas");
				canvas.width = windowW;
				canvas.height = windowH;
				canvas.style.width = canvas.width + "px";
				canvas.style.height = canvas.height + "px";
				#end
				new Loader();
			});
	}
}

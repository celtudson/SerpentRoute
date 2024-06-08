import kha.System;
import kha.WindowOptions;
#if kha_html5
import js.Browser.document;
import js.Browser.window;
import js.html.CanvasElement;
#end

class Main {
	public static final isDebug:Bool = true;
	public static final title:String = "SerpentRoute";
	public static final gameW:Int = 160;
	public static final gameH:Int = 160;
	public static var gameScale(default, null):Float = 2;

	static final isFullscreenNeeded:Bool = true;

	static function main() {
		final canvas:CanvasElement = cast document.getElementById("khanvas");
		final windowW = Std.int(gameW * gameScale);
		final windowH = Std.int(gameH * gameScale);
		#if kha_html5
		canvas.style.display = "block";
		canvas.style.outline = "none";
		document.documentElement.style.padding = "0";
		document.documentElement.style.margin = "0";
		document.body.style.padding = "0";
		document.body.style.margin = "0";
		if (isFullscreenNeeded) {
			setFullWindowCanvas(canvas);
		} else {
			canvas.width = windowW;
			canvas.height = windowH;
			canvas.style.width = canvas.width + "px";
			canvas.style.height = canvas.height + "px";
		}
		#end

		System.start(
			new SystemOptions(title, windowW, windowH, {
				windowFeatures: WindowFeatures.FeatureMinimizable
			}), (window) -> {
				new Loader();
			});
	}

	static function setFullWindowCanvas(_canvas:CanvasElement):Void {
		#if kha_html5
		final resize = function() {
			var w = document.documentElement.clientWidth;
			var h = document.documentElement.clientHeight;
			if (w == 0 || h == 0) {
				w = window.innerWidth;
				h = window.innerHeight;
			}
			_canvas.width = Std.int(w * window.devicePixelRatio);
			_canvas.height = Std.int(h * window.devicePixelRatio);
			if (_canvas.style.width == "") {
				_canvas.style.width = "100%";
				_canvas.style.height = "100%";
			}
		}
		window.onresize = resize;
		resize();
		#end
	}
}

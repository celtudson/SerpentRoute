package aps.render;

import aps.Types.Vec2Int;
import kha.Assets;
import kha.Image;
import kha.graphics2.Graphics;

class AtlasPiece {
	public var img(default, null):Image;
	public var atlas(default, null):Atlas;
	public final off:Vec2Int = {x: 0, y: 0};
	public final size:Vec2Int = {x: 0, y: 0};

	public function new(_atlas:Atlas, _img:Image) {
		img = _img;
		atlas = _atlas;
		size.x = _img.width;
		size.y = _img.height;
	}
}

class PostInAtlasCall {
	public final piece:AtlasPiece;
	public final callback:(newData:AtlasPiece) -> Void;

	public function new(_piece:AtlasPiece, _callback:(_newData:AtlasPiece) -> Void) {
		piece = _piece;
		callback = _callback;
	}
}

class Atlas {
	final maxSize:Int;
	var composedTexture:Image;

	public function new(_maxSize:Int) {
		maxSize = _maxSize;
	}

	public final wholeImagesMap:Map<Image, AtlasPiece> = [];

	public function initFromAllAssets():Void {
		final keys = [];
		for (field in Reflect.fields(Assets.images)) {
			if (~/(Name|Description|Size|names)$/.match(field)) continue;
			keys.push(field);
		}
		initFromImages([
			for (key in keys) {
				Assets.images.get(key);
			}
		]);
	}

	final postedWholeImages:Array<Image> = [];
	final atlasPieces:Array<AtlasPiece> = [];

	public function initFromImages(_images:Array<Image>):Void {
		wholeImagesMap.clear();
		postedWholeImages.resize(0);

		final imagesData:Array<AtlasPiece> = [
			for (image in _images) {
				if (image == null) continue;
				if (postedWholeImages.contains(image)) {
					trace("Atlas.initFromImages: image already posted");
					continue;
				}
				postedWholeImages.push(image);
				new AtlasPiece(this, image);
			}
		];
		if (imagesData.length == 0) return;

		initValidated([
			for (_data in imagesData) new PostInAtlasCall(_data, (_newData:AtlasPiece) -> {
				wholeImagesMap[_data.img] = _newData;
			})
		]);
	}

	function initValidated(_calls:Array<PostInAtlasCall>):Void {
		_calls.sort(function(a, b) {
			final _size = a.piece.size.y;
			final _size2 = b.piece.size.y;
			if (_size > _size2) return -1;
			else if (_size < _size2) return 1;
			return 0;
		});

		composedTexture = Image.createRenderTarget(maxSize, maxSize);
		final g = composedTexture.g2;
		g.begin(true, 0x0);
		g.imageScaleQuality = High;

		var x = 0;
		var y = 0;
		var blockW = 0;
		var blockY = 0;
		var lineY = y;
		var lineH = 0;

		function postImage(_call:PostInAtlasCall):Void {
			final data = _call.piece;
			if (blockY + data.size.y < lineH) { // down
				y = lineY + blockY;
				if (blockW < data.size.x) blockW = data.size.x;
			} else { // right and up
				x += blockW; // + 1;
				y = lineY;
				blockW = data.size.x;
				blockY = 0;
			}
			// new line
			if (x + data.size.x >= maxSize) {
				lineY += lineH; // + 1;
				x = 0;
				y = lineY;
				blockW = data.size.x;
				blockY = 0;
				lineH = 0;
			}
			if (x + blockW > maxSize || y + data.size.y > maxSize) {
				trace("Atlas.postImage: out of bounds");
				return;
			}

			g.drawSubImage(data.img, x, y, data.off.x, data.off.y, data.size.x, data.size.y);
			final newInAtlasData = new AtlasPiece(this, data.img);
			newInAtlasData.off.x = x;
			newInAtlasData.off.y = y;
			atlasPieces.push(newInAtlasData);
			_call.callback(newInAtlasData);

			if (lineH < data.size.y) lineH = data.size.y;
			if (blockW < data.size.x) blockW = data.size.x;
			blockY += data.size.y; // + 1;
		}

		atlasPieces.resize(0);
		for (call in _calls) {
			postImage(call);
		}
		trace(atlasPieces.length);
		// trace([for (piece in _atlasPieces)
		// 	"off: " + piece.off + ", size: " + piece.size + "\n\n"
		// ], _atlasPieces.length);

		g.end();
	}

	public function isPieceBelongsTo(_piece:AtlasPiece):Bool {
		return _piece != null && _piece.atlas == this;
	}

	public function drawAtlas(_g:Graphics, _x:Float, _y:Float, _scale:Float = 1.0, _withPinkBg:Bool = false):Void {
		if (composedTexture == null) return;
		final scaledSize = maxSize * _scale;
		final prev = _g.color;
		if (_withPinkBg) {
			_g.color = 0xFFFF00FF;
			_g.fillRect(_x, _y, scaledSize, scaledSize);
		}
		_g.color = 0xFFFFFFFF;
		_g.drawScaledImage(composedTexture, _x, _y, scaledSize, scaledSize);
		_g.color = 0xFFFFFF00;
		_g.drawRect(_x, _y, scaledSize, scaledSize, 2 / Main.scale);
		for (_inAtlas in atlasPieces) {
			_g.drawRect(_x + _inAtlas.off.x * _scale, _y + _inAtlas.off.y * _scale,
				_inAtlas.size.x * _scale, _inAtlas.size.y * _scale, 2 / Main.scale);
		}
		_g.color = prev;
	}

	public function drawImage(_g:Graphics, _piece:AtlasPiece, _x:Float, _y:Float):Void {
		_g.drawSubImage(composedTexture, _x, _y,
			_piece.off.x, _piece.off.y, _piece.size.x, _piece.size.y
		);
	}

	// public function drawScaledImage(
	// 	_g:Graphics, _piece:AtlasPiece, _x:Float, _y:Float, _w:Float, _h:Float
	// ):Void {
	// 	_g.drawScaledSubImage(
	// 		composedTexture,
	// 		_piece.off.x, _piece.off.y, _piece.size.x, _piece.size.y,
	// 		_x, _y, _w, _h
	// 	);
	// }

	public function drawSubImage(
		_g:Graphics, _piece:AtlasPiece, _x:Float, _y:Float,
		_sx:Float, _sy:Float, _sw:Float, _sh:Float
	):Void {
		_g.drawSubImage(
			composedTexture, _x, _y,
			_piece.off.x + _sx, _piece.off.y + _sy, _sw, _sh
		);
	}

	public function drawScaledSubImage(
		_g:Graphics, _piece:AtlasPiece,
		_sx:Float, _sy:Float, _sw:Float, _sh:Float,
		_x:Float, _y:Float, _w:Float, _h:Float
	):Void {
		_g.drawScaledSubImage(
			composedTexture,
			_piece.off.x + _sx, _piece.off.y + _sy, _sw, _sh,
			_x, _y, _w, _h
		);
	}
}

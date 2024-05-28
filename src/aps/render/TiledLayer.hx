package aps.render;

import aps.Types;
import aps.render.Atlas.AtlasPiece;
import kha.Image;
import kha.graphics2.Graphics;

class Tileset {
	static final MAX_TILE_ID_VALUE = 65535; // FFFF

	public final img:Image;
	public final tsizeW:Int;
	public final tsizeH:Int;
	public final lengthW:Int;
	public final lengthH:Int;
	public final tilesCount:Int;

	public function new(_image:Image, _tileW:Int, ?_tileH:Int) {
		if (_image == null) throw "Tileset.new: _image is null";
		if (_tileH == null || _tileH < 1) {
			if (_tileW == null || _tileW < 1) {
				throw "Tileset.new: _tileW is null or less than 0";
			}
			_tileH = _tileW;
		}
		if (_image.width < _tileW || _image.height < _tileH) throw "Tileset.new: _image size is less than tileW/H";

		img = _image;
		tsizeW = _tileW;
		tsizeH = _tileH;
		lengthW = Std.int(_image.width / _tileW);
		lengthH = Std.int(_image.height / _tileH);
		tilesCount = lengthW * lengthH;
		// _tilesCount = Std.int(image.width * image.height / tileW / tileH);
		if (tilesCount > MAX_TILE_ID_VALUE) throw "Tileset.new: tilesCount > MAX_TILE_ID_VALUE";
	}

	public function getTilePosFromId(_id:Int):Vec2Int {
		if (_id >= 0 && _id < tilesCount) {
			return {
				x: _id % lengthW,
				y: Std.int(_id / lengthW)
			}
		}
		return null;
	}
}

class TiledLayer {
	static function getCompressedTileRowRepeatTimes(_id:Int):Int {
		if (_id == -1) return 0;
		return _id < 0 ? Std.int(Math.abs(_id)) - 1 : 1;
	}

	public static function unpackCompressedTileRow(_compressedTileRow:Array<Int>):Array<Int> {
		if (_compressedTileRow == null) return [];
		final uncompressed:Array<Int> = [];
		var currentTileId = 0;
		for (id in _compressedTileRow) {
			if (id > -1) {
				currentTileId = id;
				uncompressed.push(id);
			} else {
				final repeatTimes = getCompressedTileRowRepeatTimes(id);
				// trace(id, repeatTimes);
				if (repeatTimes > 0) {
					for (i in 0...repeatTimes) uncompressed.push(currentTileId);
				}
			}
		}
		return uncompressed;
	}

	public var tileset(default, set):Tileset;
	public var atlas(default, set):Atlas;

	public function new(_tileset:Tileset = null, _atlas:Atlas = null) {
		if (_tileset == null) return;
		tileset = _tileset;
		if (_atlas != null) atlas = _atlas;
	}

	public final originTilePos:Vec2 = {x: 0, y: 0};
	public var scale:Float = 1.0;
	public var tiles:Array<Array<Int>> = [];
	public var debug_isDrawTileList:Bool = false;

	function set_tileset(_tileset:Tileset):Tileset {
		final prev = tileset;
		tileset = _tileset;
		if (prev != _tileset) atlas = atlas;
		return tileset;
	}

	function set_atlas(_atlas:Atlas):Atlas {
		atlas = _atlas;
		if (atlas == null) return null;
		if (tileset == null) {
			trace("TiledLayer.assignAtlas: tileset is null");
			return atlas;
		}
		if (tileset.img == null) {
			trace("TiledLayer.assignAtlas: tileset.img is null");
			return atlas;
		}

		atlasPiece = atlas.wholeImagesMap[tileset.img];
		if (atlasPiece == null) {
			trace("TiledLayer.assignAtlas: failed to assign atlasPiece");
			return atlas;
		}
		return atlas;
	}

	var atlasPiece:AtlasPiece;

	public function render(_g:Graphics, _camX:Float, _camY:Float):Void {
		if (tileset != null && atlas != null && atlas.isPieceBelongsTo(atlasPiece)) {
			final clipY = getClippedDrawY();
			final clipW = getClippedDrawW();
			final clipH = getClippedDrawH();
			if (debug_isDrawTileList) {
				// trace(0, clipY, clipW, clipH);
				var id = clipY * clipW;
				for (iy in clipY...clipY + clipH) {
					for (ix in 0...clipW) {
						if (id != clickedTileId) drawTile(_g, _camX, _camY, id, ix, iy);
						id++;
					}
				}
			} else {
				final clipX = getClippedDrawX();
				// trace(clipX, clipY, clipW, clipH);
				for (iy in clipY...clipY + clipH) {
					if (iy >= tiles.length) break;
					final row = unpackCompressedTileRow(tiles[iy]);
					for (ix in clipX...clipX + clipW) {
						if (ix >= row.length) break;
						drawTile(_g, _camX, _camY, row[ix] - 1, ix, iy);
					}
				}
			}
		}
	}

	function getTileDrawCoords(_ix:Float, _iy:Float):Vec2 {
		return {
			x: (originTilePos.x + _ix) * tileset.tsizeW * scale,
			y: (originTilePos.y + _iy + (debug_isDrawTileList ? -clippingRect.y : 0)) * tileset.tsizeH * scale
		};
	}

	public function drawTile(_g:Graphics, _camX:Float, _camY:Float, _id:Int, _ix:Float, _iy:Float):Void {
		if (tileset == null) return;
		final tilePos = tileset.getTilePosFromId(_id);
		if (tilePos != null) {
			final drawPos = getTileDrawCoords(_ix, _iy);
			drawPos.x += _camX;
			drawPos.y += _camY;
			atlas.drawScaledSubImage(_g, atlasPiece,
				tilePos.x * tileset.tsizeW, tilePos.y * tileset.tsizeH,
				tileset.tsizeW, tileset.tsizeH,
				drawPos.x, drawPos.y, tileset.tsizeW * scale, tileset.tsizeH * scale
			);
		}
	}

	public function drawGuideLines(_g:Graphics, _camX:Float, _camY:Float, _bgColor:Int, _gridColor:Int, _clickecTileColor:Int):Void {
		if (tileset == null) return;
		final clipW = getClippedDrawW();
		final clipH = getClippedDrawH();
		final tsizeW:Float = tileset.tsizeW * scale;
		final tsizeH:Float = tileset.tsizeH * scale;
		final drawPos = getTileDrawCoords(0, 0);
		drawPos.x += _camX;
		drawPos.y += _camY;

		final width = clipW * tsizeW;
		final height = clipH * tsizeH;
		final clipX = getClippedDrawX();
		final clipY = getClippedDrawY();
		// trace(clipX, clipY, clipW, clipH);
		final drawX1 = drawPos.x + clipX * tsizeW;
		final drawY1 = drawPos.y + clipY * tsizeH;
		final prev = _g.color;
		if (_bgColor != null) {
			_g.color = _bgColor;
			_g.fillRect(drawX1, drawY1, width, height);
		}

		_g.color = _gridColor;
		var dotWidth = 2 * scale;
		if (dotWidth < 1) dotWidth = 1;
		for (iy in clipY...clipY + clipH) {
			final ty = drawPos.y + iy * tsizeH;
			if (iy > clipY) _g.drawLine(drawX1, ty, drawX1 + width, ty, dotWidth);
			for (ix in clipX + 1...clipX + clipW) {
				final tx = drawPos.x + ix * tsizeW;
				_g.drawLine(tx, drawY1, tx, drawY1 + height, dotWidth);
			}
		}
		// g.drawRect(pos.x, pos.y, width, height, dotWidth * 2);
		if (debug_isDrawTileList && clickedTileId > -1) {
			_g.color = _clickecTileColor;
			final ty = Std.int(clickedTileId / clippingRect.w);
			final tx = clickedTileId - ty * clippingRect.w;
			_g.fillRect(drawPos.x + tx * tsizeW, drawPos.y + ty * tsizeH, tsizeW, tsizeH);
		}
		_g.color = prev;
	}

	public var clickedTileId:Int = -1;

	public function getClickedTileId(relativeMouseX:Float, relativeMouseY:Float):Int {
		if (tileset == null) return clickedTileId;
		final tsizeW:Float = tileset.tsizeW * scale;
		final tsizeH:Float = tileset.tsizeH * scale;
		final tx = Math.floor(-originTilePos.x + relativeMouseX / tsizeW);
		var ty = Math.floor(-originTilePos.y + relativeMouseY / tsizeH);
		if (debug_isDrawTileList) ty += clippingRect.y;

		if (tx > -1 && ty > -1) {
			final clipX = getClippedDrawX();
			final clipY = getClippedDrawY();
			final clipW = getClippedDrawW();
			final clipH = getClippedDrawH();
			if (tx >= clipX && ty >= clipY && tx < clipX + clipW && ty < clipY + clipH) {
				final w = debug_isDrawTileList ? clippingRect.w : (biggestTilesWCount < 0 ? 0 : biggestTilesWCount);
				final potentialClickedTileId = ty * w + tx;
				if (potentialClickedTileId < tileset.tilesCount) {
					clickedTileId = potentialClickedTileId;
					// trace(tx, ty, clickedTileId);
				}
			}
		}
		return clickedTileId;
	}

	public final clippingRect:RectInt = {
		x: 0,
		y: 0,
		w: 1,
		h: 1
	};
	public var biggestTilesWCount(default, null):Int = -1;

	function getClippedDrawX():Int {
		return !debug_isDrawTileList && clippingRect.x > -1 ? clippingRect.x : 0;
	}

	function getClippedDrawW():Int {
		if (!debug_isDrawTileList) {
			var biggestW:Int = 0;
			for (row in tiles) {
				var rowLength = 0;
				for (id in row) {
					rowLength += getCompressedTileRowRepeatTimes(id);
				}
				if (rowLength > biggestW) biggestW = rowLength;
			}
			biggestTilesWCount = biggestW;
			var clippedW = clippingRect.x + clippingRect.w > biggestW ? biggestW - clippingRect.x : clippingRect.w;
			if (clippingRect.x < 0) clippedW += clippingRect.x;
			return clippedW > 0 ? clippedW : 0;
		} else return clippingRect.w > 0 ? clippingRect.w : 0;
	}

	function getClippedDrawY():Int {
		return !debug_isDrawTileList && clippingRect.y < 0 ? 0 : clippingRect.y;
	}

	function getClippedDrawH():Int {
		if (!debug_isDrawTileList) {
			var clippedH = clippingRect.y + clippingRect.h > tiles.length ? tiles.length - clippingRect.y : clippingRect.h;
			if (clippingRect.y < 0) clippedH += clippingRect.y;
			return clippedH > 0 ? clippedH : 0;
		} else return clippingRect.h;
	}
}

/*
Copyright 2011 Martin Jonasson, grapefrukt games. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY grapefrukt games "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL grapefrukt games OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of grapefrukt games.
 */
package com.grapefrukt.exporter.extractors
{
	import com.grapefrukt.exporter.debug.Logger;
	import com.grapefrukt.exporter.misc.Child;
	import com.grapefrukt.exporter.settings.Settings;
	import com.grapefrukt.exporter.textures.*;

	import com.grapefrukt.exporter.textures.BitmapTexture;
	import com.grapefrukt.exporter.textures.TextureBase;
	import com.grapefrukt.exporter.textures.TextureSheet;
	import flash.display.Sprite;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	/**
	 * ...
	 * @author Martin Jonasson, m@grapefrukt.com
	 */
	public class TextureExtractor extends ExtractorBase
	{
		/**
		 * Extracts the DisplayObjectContainers children into textures and animation sheets
		 * @param	target			The DisplayObjectContainer to extract from
		 * @param	ignore			An array of Strings that let's you ignore certain children
		 * @param	respectScale	If this is false all children will be extracted at 100%. Set to true to respect the scale of the children as they are in the parent.
		 * @param	returnClass		Ignore this. Used internally to return FontSheets when so needed. 
		 * @return	A TextureSheet containing the DisplayObjectContainers children
		 */
		public static function extract(sheet : DisplayObjectContainer, ignore : Array = null, respectScale : Boolean = false, returnClass : Class = null, convertPixelsToPoints : Boolean = true, scaleFactor : Number = 1, artDataClass : Class = null, fileSuffix : String = "") : TextureSheet
		{
			Logger.log("TextureExtractor", "extracting", ChildFinder.getName(sheet));
			if (returnClass == null) returnClass = TextureSheet;
			return childrenToSheet(sheet, getChildren(sheet, ignore), respectScale, returnClass, convertPixelsToPoints, scaleFactor, artDataClass, fileSuffix);
		}

		/**
		 * Convenience wrapper for extract(), supply with your desired sheet name and the classes (not instances!) you want in it
		 * @param	sheetName	The desired sheet name
		 * @param	...rest		A list of classes you want to parse into a sheet
		 * @return				A texture sheet containing the supplied classes
		 */
		public static function extractFromClasses(sheetName : String, ...rest) : TextureSheet
		{
			return extract(classesToSheetSprite(sheetName, rest));
		}

		private static function childrenToSheet(target : DisplayObjectContainer, children : Vector.<Child>, respectScale : Boolean, returnClass : Class, convertPixelsToPoints : Boolean, scaleFactor : Number, artDataClass : Class = null, fileSuffix : String = "") : TextureSheet
		{
			var sheet : TextureSheet = new returnClass(ChildFinder.getName(target));
			for each (var child:Child in children)
			{
				if (child.frame != 0) MovieClip(target).gotoAndStop(child.frame);

				// this one:
				var t : BitmapTexture = extractSingle(child.name, target.getChildByName(child.name), respectScale, convertPixelsToPoints, scaleFactor, artDataClass, fileSuffix);

				if (t)
					sheet.add(t);
			}
			return sheet;
		}

		private static function extractSingle(name : String, target : DisplayObject, respectScale : Boolean, convertPixelsToPoints : Boolean, scaleFactor : Number, artDataClass : Class = null, fileSuffix : String = "") : BitmapTexture
		{
			if (target as MovieClip && MovieClip(target).totalFrames > 1)
			{
				return getAsTextureMultiframe(name, MovieClip(target), respectScale, convertPixelsToPoints, scaleFactor, artDataClass, fileSuffix);
			}
			return getAsTextureSingle(name, target, respectScale, convertPixelsToPoints, scaleFactor, artDataClass, fileSuffix);
		}

		private static function getAsTextureMultiframe(name : String, target : MovieClip, respectScale : Boolean, convertPixelsToPoints : Boolean, scaleFactor : Number, artDataClass : Class = null, fileSuffix : String = "") : BitmapTexture
		{
			var frames : Vector.<BitmapTexture> = new Vector.<BitmapTexture>;
			for (var frameIndex : int = 1; frameIndex <= target.totalFrames; frameIndex++)
			{
				target.gotoAndStop(frameIndex);
				frames.push(getAsTextureSingle(name, target, respectScale, convertPixelsToPoints, scaleFactor, artDataClass, fileSuffix));
			}

			return MultiframeUtil.merge(frames);
		}

		public static function getAsTextureSingle(name : String, target : DisplayObject, respectScale : Boolean, convertPixelsToPoints : Boolean, scaleFactor : Number, artDataClass : Class = null, fileSuffix : String = "") : BitmapTexture
		{
			var bounds : Rectangle = target.getBounds(target);
			var compoundScale : Number = scaleFactor;
			var conversionFactor : Number = 1;

			if (respectScale) compoundScale *= target.scaleX;
			if (convertPixelsToPoints) conversionFactor = Settings.conversionFactor;

			bounds.x *= compoundScale;
			bounds.y *= compoundScale;
			bounds.width *= compoundScale;
			bounds.height *= compoundScale;

			bounds.x = Math.floor(bounds.x) - Settings.edgeMarginRender;
			bounds.y = Math.floor(bounds.y) - Settings.edgeMarginRender;
			bounds.height = Math.ceil(bounds.height) + Settings.edgeMarginRender * 2;
			bounds.width = Math.ceil(bounds.width) + Settings.edgeMarginRender * 2;

			if (Settings.tinyThreshold > 0 && bounds.width < Settings.tinyThreshold && bounds.height < Settings.tinyThreshold)
			{
				Logger.log("TextureExtractor", "skipping tiny texture in " + name, bounds.width + "x" + bounds.height, Logger.ERROR);
				return null;
			}

			// draws the object to the bitmap
			var bitmap : BitmapData = new BitmapData(bounds.width, bounds.height, true, 0x00000000);
			var matrix : Matrix = new Matrix();
			matrix.translate(-bounds.x / compoundScale, -bounds.y / compoundScale);
			matrix.scale(compoundScale, compoundScale);

			// alpha is stored in animations, so we normally don't want that in the spritesheet
			// to be safe the value is cached and then set back once the blitting is done
			var tmpAlpha : Number = target.alpha;
			target.alpha = 1;

			bitmap.draw(target, matrix, target.transform.colorTransform);

			// reset the alpha
			target.alpha = tmpAlpha;

			// find the non-transparent area of the texture, especially useful for textfields
			// they report a way bigger size than they actually take up
			var crop_rect : Rectangle = bitmap.getColorBoundsRect(0xffffffff, 0x00000000, false);

			if (crop_rect.width < 1 && crop_rect.height < 1)
			{
				Logger.log("TextureExtractor", "crop made tiny texture in " + name, "was: " + bounds + " became: " + crop_rect, Logger.ERROR);

				// returns the uncropped texture
				return new BitmapTexture(name, bitmap, bounds, zindex);
			}

			// add a margin to the edges to prevent wierd smoothing issues
			crop_rect.x -= Settings.edgeMarginOutput;
			crop_rect.y -= Settings.edgeMarginOutput;
			crop_rect.width += Settings.edgeMarginOutput * 2;
			crop_rect.height += Settings.edgeMarginOutput * 2;

			// crop out transparency from the edges
			var crop_bitmap : BitmapData = new BitmapData(crop_rect.width, crop_rect.height, true, 0x00000000);
			crop_bitmap.draw(bitmap, new Matrix(1, 0, 0, 1, -crop_rect.x, -crop_rect.y));

			// calculate the new registration point position after the crop
			bounds.x += crop_rect.x;
			bounds.y += crop_rect.y;
			bounds.width = crop_rect.width;
			bounds.height = crop_rect.height;

			// when converting pixels to points
			bounds.x *= conversionFactor;
			bounds.y *= conversionFactor;
			bounds.width *= conversionFactor;
			bounds.height *= conversionFactor;

			var zindex : uint = 0;
			if (target.parent) zindex = target.parent.getChildIndex(target);

            var isMask : Boolean = name.toLowerCase().indexOf('mask') == 0;

            if (artDataClass == null)
                artDataClass = BitmapTexture;

            var artData : BitmapTexture = new artDataClass(name, crop_bitmap, bounds, zindex, isMask);

            if (artData is FTCBitmapTexture && fileSuffix)
                FTCBitmapTexture(artData).fileSuffix = fileSuffix;

            return artData;
		}
		
		/**
		 * Due to some information being lost at compile time, movieclips can get multiple objects on the same z-index, this function detects and fixes that
		 * @param	sheet The TextureSheet to fix
		 */
		static public function fixDuplicateZIndices(sheet:TextureSheet):void {
			// first we need to sort the sheet by zIndex
			sheet.textures.sort(_sort_textures_zIndex);
			
			// start the loop at 0, the first texture is assumed to be correct since we have no baseline to compare it to
			// loop until the second last texture, as we're looking one "ahead" within the loop
			for (var i:int = 0; i < sheet.textures.length - 1; i++) {
				var currentTexture:TextureBase = sheet.textures[i];
				var nextTexture:TextureBase = sheet.textures[i + 1];
				
				// if these two textures have the same zIndex, bump up the "next" texture and all following one step
				if (currentTexture.zIndex == nextTexture.zIndex) {
					for (var j:int = i + 1; j < sheet.textures.length - 1; j++ ) sheet.textures[j].zIndex++;
				}
			}
		}
		
		static private function _sort_textures_zIndex(one:TextureBase, two:TextureBase):Number {
			// first sort on z-index
			if (one.zIndex > two.zIndex) return 1;
			if (one.zIndex < two.zIndex) return -1;
			
			// if z-index isn't available or identical, we sort on names
			if (one.name < two.name) return -1;
			if (one.name > two.name) return 1;
			
			return 0;
		}
	}
}
/**
 Copyright 2013 Zynga Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

package starling.textures {
	
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	/**
	 * This strategy uses the shelf first-fit bin first-fit packing algorithm.
	 * 
	 * It works by iterating over the possible bins (atlases), and checking each
	 * shelf (row) to see if there is room to add the given image. If there is
	 * no room in the existing shelves, but there is space to fit the image in a
	 * new shelf, one is created.
	 * 
	 * First-fit means it stops at the first valid location it finds, but
	 * iterates over all options at each step (as opposed to next-fit which
	 * gives up on existing bins and shelves whenever new ones are created).
	 */
	public class TextureAtlasPacker {

		// Minimum padding between images.
		private static const MIN_PADDING:int = 1;
		
		private static var sMatrix:Matrix = new Matrix();
		
		private static function doPackImages(atlasSize:int, bitmapInfo:Vector.<BitmapInfo>, atlases:Vector.<Atlas>, unpackedBitmaps:Vector.<String>):void {
			
			var i:int;
			var j:int;
			var atlas:Atlas;			
			
			bitmapInfo.sort(bitmapCompare);			
			
			// Add all frame items to atlases.
			for (i = 0; i < bitmapInfo.length; i++) {
				
				var bmName:String = bitmapInfo[i].name;
				var bmData:BitmapData = bitmapInfo[i].bitmap;
				
				var added:Boolean = false;
				
				// Try to add to existing atlases first.
				for (j = atlases.length - 1; j >= 0; j--) {
					if (tryAddBitmapToAtlas(atlases[j], bmName, bmData)) {
						added = true;
						break;
					}
				}
				
				// No?  Try a new atlas.
				if (!added) {
					// Atlases were full? Push a new atlas and try to add to it to that one.
					atlas = createNewAtlas(atlasSize);
					atlases.push(atlas);
					if (!tryAddBitmapToAtlas(atlas, bmName, bmData)) {
						unpackedBitmaps.push(bmName);
					}
				}
			}			
		}
		
		/**
		 * Returns a set of backed bitmaps and atlas json data given a set of source bitmaps to pack.
		 *  
		 * @param atlasSize				size of the atlas textures (must be an even multiple of 2 - 
		 * @param bitmapNames			names of the bitmaps to pack.
		 * @param bitmaps				the bitmaps to pack (must match the names array).
		 * @param packedAtlasBitmaps	the returned array of packed atlas bitmaps (used to create the Texture objects).
		 * @param packedAtlasJson		the returned array of packed atlas json data (used to instantiate Starling TextureAtlas objects).
		 * @param unpackedBitmaps		the returned array of any unpacked bitmaps that were not placed in an atlas.
		 */
		public static function packAtlases(atlasSize:int, bitmapNames:Vector.<String>, bitmaps:Vector.<BitmapData>, packedAtlasBitmaps:Vector.<BitmapData>, 
										   packedAtlasJson:Array, unpackedBitmaps:Vector.<String>):void {

			var i:int;
			var j:int;
			var atlas:Atlas;
			
			// Create bitmap info array
			var bitmapInfo:Vector.<BitmapInfo> = new Vector.<BitmapInfo>();
			for (i = 0; i < bitmaps.length; i++) {
				bitmapInfo.push(new BitmapInfo(bitmaps[i], bitmapNames[i]));
			}
			
			// Create atlases array
			var atlases:Vector.<Atlas> = new Vector.<Atlas>();
			
			// Add all frame items to atlases.
			doPackImages(atlasSize, bitmapInfo, atlases, unpackedBitmaps);
			
			// Check to see if we can reduce the size of the last atlas
			var lastIsSmallest:Boolean = false;
			var lastAtlasSize:int = atlasSize;
			while (!lastIsSmallest) {
				var lastAtlas:Atlas = atlases[atlases.length - 1];
				if (lastAtlas.maxY < lastAtlas.size / 2) {
					var repackedAtlases:Vector.<Atlas> = new Vector.<Atlas>();
					var repackedUnpackedBitmaps:Vector.<String> = new Vector.<String>();
					doPackImages(lastAtlasSize / 2, lastAtlas.bitmapInfo, repackedAtlases, repackedUnpackedBitmaps);
					if (repackedAtlases.length == 1 && repackedUnpackedBitmaps.length == 0) {
						atlases.pop();
						atlases.push(repackedAtlases[0]);
						lastAtlasSize = lastAtlasSize / 2;
					} else {
						lastIsSmallest = true;
					}
				} else {
					lastIsSmallest = true;
				}
			}
			
			// Draw all of the images to their atlas.
			for (i = 0; i < atlases.length; i++) {
				atlas = atlases[i];
				for (j = 0; j < atlas.images.length; j++) {
					var image:AtlasImage = atlas.images[j];
					sMatrix.tx = image.offsetX;
					sMatrix.ty = image.offsetY;
					atlas.bitmap.draw(image.bitmap, sMatrix, null, null, null, false);
				}
				packedAtlasBitmaps.push(atlas.bitmap);
				packedAtlasJson.push(atlas.json);
			}
		}
		
		// Orders using height, then width.
		private static function bitmapCompare(a:BitmapInfo, b:BitmapInfo):int {
			return (a.bitmap.height * 10000.0 + a.bitmap.width > b.bitmap.height * 10000.0 + b.bitmap.width) ? -1 : 1;
		}
		
		private static function createNewAtlas(atlasSize:int):Atlas {
			var atlas:Atlas = new Atlas();
			atlas.size = atlasSize;
			atlas.bitmap = new BitmapData(atlasSize, atlasSize, true, 0);
			atlas.json = { "scale":1.0, "subTexture":[] };
			return atlas;
		}
		
		private static function tryAddBitmapToAtlas(atlas:Atlas, bitmapName:String, bitmap:BitmapData):Boolean {
			
			// Width/height for this image.
			var width:int = bitmap.width;
			var height:int = bitmap.height;
			
			// Sanity check that this will fit anywhere.
			if (width > atlas.size || height > atlas.size) {
				return false;
			}
			
			// Determine how much padding is required for this image.
			var padding:int = MIN_PADDING;
			var widthPadding:int = padding;
			
			var numShelves:int = atlas.shelves.length;
			if (numShelves == 0) {
				atlas.shelves.push(new Shelf());
				numShelves++;
			}
			
			var chosenShelf:Shelf;
			var currentShelf:Shelf;
			for (var i:int = 0; i < numShelves; i++) {
				currentShelf = atlas.shelves[i];
				
				// Determine the max required padding between this image and the
				// one before it. No padding necessary for the first image on a
				// row.
				widthPadding = Math.max(padding, currentShelf.widthPadding);
				if (currentShelf.nextX == 0) {
					widthPadding = 0;
				}
				
				// Is there room on this shelf?
				if (currentShelf.nextX + widthPadding + width <= atlas.size) {
					if (height <= currentShelf.maxHeight) {
						// This fits under the current max height for the row.
						chosenShelf = currentShelf;
						break;
					} else if (i == numShelves - 1 && currentShelf.startY + height <= atlas.size) {
						// This is the last shelf, and we can grow it to fit.
						chosenShelf = currentShelf;
						break;
					}
				}
			}
			
			if (chosenShelf == null) {
				// Should we add a new shelf?
				if (currentShelf.startY + currentShelf.maxHeight + currentShelf.heightPadding + height <= atlas.size) {
					chosenShelf = new Shelf();
					chosenShelf.startY = currentShelf.startY + currentShelf.maxHeight + currentShelf.heightPadding;
					atlas.shelves.push(chosenShelf);
					widthPadding = 0;
				}
			}
			
			if (chosenShelf != null) {
				var image:AtlasImage = new AtlasImage();
				image.name = bitmapName;
				image.bitmap = bitmap;
				image.offsetX = chosenShelf.nextX + widthPadding;
				image.offsetY = chosenShelf.startY;
				chosenShelf.nextX = image.offsetX + width;
				chosenShelf.maxHeight = Math.max(height, chosenShelf.maxHeight);
				chosenShelf.heightPadding = Math.max(padding, chosenShelf.heightPadding);
				chosenShelf.widthPadding = padding;
				var json:Object = { "name":bitmapName, "x":image.offsetX, "y":image.offsetY, "width":width, "height":height };
				atlas.images.push(image);
				atlas.bitmapInfo.push(new BitmapInfo(bitmap, bitmapName));
				atlas.json.subTexture.push(json);
				atlas.maxY = Math.max(image.offsetY + bitmap.height);
				return true;
			}
			
			return false;
		}
	}
}

internal class BitmapInfo {
	
	public function BitmapInfo(bm:BitmapData, nm:String) { bitmap = bm; name = nm; }
	
	/** The bitmap */
	public var bitmap:BitmapData;

	/** The name of the bitmap */
	public var name:String;
}

internal class AtlasImage {
	
	public function AtlasImage() {}
	
	/** Bitmap name. */
	public var name:String;
	
	/** The bitmap data for this image. */
	public var bitmap:BitmapData;
	
	/** The x offset position for this image. */
	public var offsetX:int;
	
	/** The y offset position for this image. */
	public var offsetY:int;
	
}

internal class Shelf {
	
	public function Shelf() {}
	
	/** The next X-coordinate to place an item at. */
	public var nextX:int;
	
	/** The Y-coordinate to place items in this shelf at. */
	public var startY:int;
	
	/** The maximum height observed so far in this row. */
	public var maxHeight:int;
	
	/** The amount of width padding required for the previous image in this row. */
	public var widthPadding:int;
	
	/** The amount of height padding required below this row. */
	public var heightPadding:int;
}

import flash.display.BitmapData;

internal class Atlas {
	
	public function Atlas() {}
	
	/** Size of the atlas (with and height) */
	public var size:int;
	
	/** Total y space used in the atlas. */
	public var maxY:int;
	
	/** The texture atlas we are packing frames into. */
	public var bitmap:BitmapData;

	/** Atlas json data. */
	public var json:Object;
	
	/** Shelves info. */
	public var shelves:Vector.<Shelf> = new Vector.<Shelf>();
	
	/** Bitmap info added to this atlas. */
	public var bitmapInfo:Vector.<BitmapInfo> = new Vector.<BitmapInfo>();
	
	/** Altas image info. */
	public var images:Vector.<AtlasImage> = new Vector.<AtlasImage>();
}
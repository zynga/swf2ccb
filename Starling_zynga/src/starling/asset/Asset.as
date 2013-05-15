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

package starling.asset
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.PNGEncoderOptions;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filters.BevelFilter;
	import flash.filters.BitmapFilter;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.filters.GradientBevelFilter;
	import flash.filters.GradientGlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Transform;
	import flash.system.*;
	import flash.text.StaticText;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.getQualifiedClassName;
	
	import starling.core.starling_internal;
	import starling.display.AnimSprite;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.NineSliceImage;
	import starling.display.Sprite;
	import starling.display.TrackTarget;
	import starling.text.TextField;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.textures.TextureAtlasPacker;
	
	use namespace starling_internal;
	
	public class Asset extends EventDispatcher
	{
		// The asset file version.
		public static const ASSET_FILE_VER:int = 1;
		
		private var mName:String;
		private var mIsShared:Boolean;
		private var mContext:AssetContext;
		private var mRootObject:Object;
		private var mSymbols:Object = new Object();
		private var mBitmaps:Object = new Object();
		starling_internal var mBitmapData:Dictionary = new Dictionary();
		
		private var mLoadedFileVer:int = ASSET_FILE_VER; // If loaded from a file, what file version was it.
		
		private static var sImageCache:Dictionary = new Dictionary();
		private static var sUniqueId:int = 1;	
		
		private static var sMat:Matrix = new Matrix();
		
		// Filter callback method
		private static var sFilterCallback:Function;
		
		// Asset options..
		private static var sAutoAtlas:Boolean = false;
		private static var sAtlasSize:int = 1024;
		private static var sDrawScale:Number = 1;
		private static var sDecimationQuality:Number = 1; // this is the inverse of the quality level
		
		private var notSupportedAnimations:String = "";
		
		public function Asset(context:AssetContext = null) {
			mContext = context;
			if (mContext == null) {
				mContext = new AssetContext();
			}
		}
		
		/** Disposes resources allocated by this asset. */
		public function dispose():void {
			// Does nothing right now.  TODO: Make asset disposal release references to any shared items in shared content.
		}
		
		/** Should auto atlasing be enabled when building an asset from a swf resource. */
		public static function get autoAtlas():Boolean {
			return sAutoAtlas;
		}
		
		/** Should auto atlasing be enabled when building an asset from a swf resource. */
		public static function set autoAtlas(value:Boolean):void {
			sAutoAtlas = value;
		}
		
		/** Atlas size to use if auto atlasing is enabled (must be a multiple of 2). */
		public static function get atlasSize():int {
			return sAtlasSize;
		}
		
		/** Atlas size to use if auto atlasing is enabled (must be a multiple of 2). */
		public static function set atlasSize(value:int):void {
			sAtlasSize = value;
		}
		
		public static function set drawScale(value:Number):void {
			sDrawScale = value;
		}
		
		public static function get drawScale():Number {
			return sDrawScale;
		}
		
		public static function set quality(value:Number):void {
			sDecimationQuality = value;
		}
		
		public static function get quality():Number {
			return sDecimationQuality;
		}
		
		/** Returns the root symbol name for this asset (the symbol of the root object) if it has one. */
		public function get rootSymbolName():String {
			if (mRootObject != null && mRootObject.symbolName != null) {
				return mRootObject.symbolName;
			}
			return null;
		}
		
		/** 
		 * Filters certain display objects by name during display tree processing to provide custom behaviors. 
		 * 
		 * <p>Function must be of the form callback(asset, dispObj):Boolean where the 
		 * boolean value returned indicates whether the display object will be included or 
		 * excluded in the converted asset.</p>
		 */
		public static function setFilterCallback(filter:Function):void {
			sFilterCallback = filter;
		}
		
		private static function getClassName(cl:Class):String {
			if (cl == null) {
				return "";
			}
			var clName:String = flash.utils.getQualifiedClassName(cl);
			clName = clName.replace("::", ".");
			return clName;
		}
		
		/** The name of the asset. */
		public function get name():String {
			return mName;
		}
		
		/** True if the asset symbos/bitmaps are shared. (Symbols/bitmaps will be copied to the sharing context). */
		public function get isShared():Boolean {
			return mIsShared;
		}
		
		/** The sharing context for the asset. */
		public function get context():AssetContext {
			return mContext;
		}
		
		/** Returns an array containing the symbol names in this asset. */
		public function getSymbolNames():Array {
			var names:Array = new Array();
			for (var name:String in mSymbols) {
				names.push(name);
			}
			return names;
		}
		
		/** Returns an array containing the symbol names in this asset. */
		public function getBitmapNames():Array {
			var names:Array = new Array();
			for (var name:String in mBitmaps) {
				names.push(name);
			}
			return names;
		}
		
		/**
		 * Returns the symbol info object for a given symbol id. 
		 * 
		 * @param symbolId the symbol id.
		 * @return the symbol info json object or null if symbol not found.
		 */
		private function getSymbolInfo(symbolId:String):Object {
			var symbol:Object = mSymbols[symbolId];
			if (symbol == null) {
				symbol = mContext.sharedSymbols[symbolId];
			}
			return symbol;
		}
		
		/**
		 * Returns the bitmap info object for a given bitmap id.
		 *  
		 * @param bitmapId the bitmap id.
		 * @return the bitmap info json object or null if bitmap not found.
		 */
		private function getBitmapInfo(bitmapId:String):Object {
			var bitmap:Object = mBitmaps[bitmapId];
			if (bitmap == null) {
				bitmap = mContext.sharedBitmaps[bitmapId];
			}
			return bitmap;
		}
		
		/**
		 * Returns the bitmap data for a given bitmap id.
		 *  
		 * @param bitmapId the bitmap id.
		 * @return the bitmap data or null if bitmap not found.
		 */
		private function getBitmapData(bitmapId:String):BitmapData {
			var bitmapData:BitmapData = mBitmapData[bitmapId] as BitmapData;
			if (bitmapData == null) {
				bitmapData = mContext.sharedBitmapData[bitmapId] as BitmapData;
			}
			return bitmapData;
		}		
		
		/**
		 * Adds a bitmap to the bitmap dictionaries.
		 *  
		 * @param bmName	the bitmap name.
		 * @param bmData	the bitmap data.
		 */
		starling_internal function addBitmapData(bmName:String, bmData:BitmapData):void {
			mBitmapData[bmName] = bmData;
			if (mIsShared) {
				context.sharedBitmapData[bmName] = bmData;
			}
		}
		
		/**
		 * Creates a new asset from json data.
		 * 
		 * @param jsonData	the JSON data to create the asset from.
		 * @param bitmapData a dictionary of BitmapData objects by bitmap names (or null to use an empty bitmap data dictionary).
		 * @param context	an optional shared context for storing shared symbols, bitmaps.
		 * 
		 * @return the new asset.
		 */
		public static function fromJSON(jsonData:Object, bitmapData:Dictionary = null, context:AssetContext = null):Asset {
			
			var asset:Asset = new Asset(context);
			asset.mName = jsonData.name;
			asset.mIsShared = jsonData.isShared;
			asset.mRootObject = jsonData.rootObject;
			asset.mSymbols = jsonData.symbols;
			asset.mBitmaps = jsonData.bitmaps;
			if (bitmapData != null) 
				asset.mBitmapData = bitmapData;
			
			// Make sure we remember the file version of the file that we were loaded from.  This
			// could change how the serialization code works.
			if (jsonData.hasOwnProperty("fileVer")) {
				asset.mLoadedFileVer = jsonData.fileVer;
			}
			if (asset.mLoadedFileVer > ASSET_FILE_VER) {
				throw new Error("Invalid file version.");
			}
			
			// Copy shared items to context if this is a shared asset.
			context = asset.mContext;
			if (asset.mIsShared) {
				var key:String;
				var value:Object;
				var symbols:Object = asset.mSymbols;
				for (key in symbols) {
					value = symbols[key];
					context.sharedSymbols[key] = value;
				}
				var bitmaps:Object = asset.mBitmaps;
				for (key in bitmaps) {
					value = bitmaps[key];
					context.sharedBitmaps[key] = value;
				}
			}
			
			return asset;
		}
		
		/**
		 * Returns a JSON style object graph of this asset suitable for serializing to a file. 
		 * 
		 * @return json style object graph representing this asset.
		 */
		public function toJSON():Object {
			var jsonData:Object = {
				name: mName,
				fileVer: ASSET_FILE_VER,
				isShared: mIsShared,
				rootObject: mRootObject,
				symbols: mSymbols,
				bitmaps: mBitmaps
			};
			return jsonData;
		}
		
		/**
		 * Returns a BINARY buffer containing this asset and all of it's textures.
		 */ 
		public function toBinary():ByteArray {
			
			var buffer:ByteArray = new ByteArray();
			
			var json:String = JSON.stringify(toJSON());
			var jsonArray:ByteArray = new ByteArray();
			jsonArray.writeUTFBytes(json);
			jsonArray.deflate();
			
			var bitmaps:Vector.<String> = new Vector.<String>();
			for (var bmNm:String in mBitmapData) {
				bitmaps.push(bmNm);
			}
			
			buffer.clear();
			buffer.endian = Endian.LITTLE_ENDIAN;
			
			buffer.writeUTFBytes("STAR");
			
			// Write the version number (comes in handy if we need to change the file format).
			buffer.writeUnsignedInt(ASSET_FILE_VER);
			
			buffer.writeUnsignedInt(jsonArray.length);
			buffer.writeBytes(jsonArray);
			
			buffer.writeInt(bitmaps.length);
			
			var bmArray:ByteArray = new ByteArray();
			
			for (var i:int = 0; i < bitmaps.length; i++) {
				var bmName:String = bitmaps[i];
				var bmData:BitmapData = getBitmapData(bmName);
				buffer.writeUTF(bmName);
				buffer.writeInt(1); // Texture type 1=PNG
				bmArray.clear();
				bmData.encode(new Rectangle(0, 0, bmData.width, bmData.height), new flash.display.PNGEncoderOptions(), bmArray);
				buffer.writeUnsignedInt(bmArray.length);
				buffer.writeBytes(bmArray);
			}
			
			return buffer;
		}
		
		/**
		 * Writes this asset to a binary file at the given path.
		 *  
		 * @param path	the folder path to save the asset (the name will be the asset net + '.star' extension).
		 */
		public function saveBinary(path:String):void {
			var byteArray:ByteArray = toBinary();
			var filePath:String = path + mName + ".star";
			var fname:File = new File(filePath);
			var fstrm:FileStream = new FileStream();
			try {
				fstrm.open(fname, FileMode.WRITE);
				fstrm.writeBytes(byteArray);
				fstrm.close();
			} catch (e:Error) {
				trace("Unable to save binary asset file '" + filePath + "': " + e.message);
			}				
		}
		
		//
		// Methods for creating a json starling asset from a standard SWF Flash display object.
		//
		
		private static function isSymbolDispObj(dispObj:flash.display.DisplayObject):Object {
			var dispObjCl:Class = Object(dispObj).constructor as Class;
			return dispObjCl != null && getClassName(dispObjCl).indexOf("flash.") != 0;
		}
		
		private function getFilterHash(dispObj:flash.display.DisplayObject):uint {
			var h:uint = 0x1FE3247B;
			for (var i:int = 0; i < dispObj.filters.length; i++) {
				var f:BitmapFilter = dispObj.filters[i] as BitmapFilter;
				if (f is GlowFilter) {
					h += h * 131 + 381732;
					var glow:GlowFilter = f as GlowFilter;
					h += glow.blurX + h * 131;
					h += glow.blurY + h * 131;
					h += glow.color + h * 131;
					h += glow.strength + h * 131;
					h += glow.alpha * 255 + h * 131;
					h += glow.quality + h * 131;
				} else if (f is BevelFilter) {
					h += h * 131 + 62552;
					var bev:BevelFilter = f as BevelFilter;
					h += bev.blurX + h * 131;
					h += bev.blurY + h * 131;
					h += bev.strength + h * 131;
					h += bev.angle + h * 131;
					h += bev.highlightAlpha + h * 131;
					h += bev.highlightColor + h * 131;
					h += bev.distance + h * 131;
					h += bev.shadowAlpha + h * 131;
					h += bev.shadowColor + h * 131;
					h += bev.quality + h * 131;
				} else if (f is ColorMatrixFilter) {
					h += h * 131 + 84233;
					var col:ColorMatrixFilter = f as ColorMatrixFilter;
					for (var mi:int = 0; mi < col.matrix.length; mi++) {
						h += col.matrix[mi] * 1000.0 + h * 131;
					}
				} else if (f is BlurFilter) {
					h += h * 131 + 223373;
					var blur:BlurFilter = f as BlurFilter;
					h += blur.blurX + h * 131;
					h += blur.blurY + h * 131;
				} else if (f is DropShadowFilter) {
					h += h * 131 + 2313552;
					var shad:DropShadowFilter = f as DropShadowFilter;
					h += shad.blurX + h * 131;
					h += shad.blurY + h * 131;
					h += shad.strength + h * 131;
					h += shad.angle + h * 131;
					h += shad.color + h * 131;
					h += shad.alpha * 255.0 + h * 131;
					h += shad.distance + h * 131;
					h += shad.inner ? 4413 + h * 131 : h * 131;
					h += shad.knockout ? 2131 + h * 131 : h * 131;
					h += shad.hideObject ? 1521 + h * 131 : h * 131;
					h += shad.quality + h * 131;
				} else {
					// Don't handle other filters right now.
					h += h * 131 + 472155;
				}
			}
			return h;
		}
		
		private function makeBitmapName(id:int):String {
			return "bm" + mName + id.toString();
		}
		
		public function saveBitmap(name:String, path:String):void {
			
			var bmData:BitmapData = getBitmapData(name);
			if (bmData == null) 
				throw new Error("No bitmap image info for bitmap '" + name + "' was found.  Couldn't save bitmap");
			
			// Save the bitmap to the current directory.
			var byteArray:ByteArray = new ByteArray();
			bmData.encode(new Rectangle(0, 0, bmData.width, bmData.height), new flash.display.PNGEncoderOptions(), byteArray);
			var filePath:String = path + name + ".png";
			var fname:File = new File(filePath);
			var fstrm:FileStream = new FileStream();
			try {
				fstrm.open(fname, FileMode.WRITE);
				fstrm.writeBytes(byteArray);
				fstrm.close();
			} catch (e:Error) {
				trace("Unable to save bitmap file '" + filePath + "': " + e.message);
			}			
		}
		
		public function saveAllBitmaps(path:String):void {
			for (var name:String in mBitmapData) {
				saveBitmap(name, path);
			}
		}
		
		public function saveJson(path:String):void {
			var json:String = JSON.stringify(toJSON());
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeUTFBytes(json);
			var filePath:String = path + mName + ".json";
			var fname:File = new File(filePath);
			var fstrm:FileStream = new FileStream();
			try {
				fstrm.open(fname, FileMode.WRITE);
				fstrm.writeBytes(byteArray);
				fstrm.close();
			} catch (e:Error) {
				trace("Unable to save json file '" + filePath + "': " + e.message);
			}			
		}
		
		private function getSymbolName(dispObj:flash.display.DisplayObject):String {
			var dispObjCl:Class = Object(dispObj).constructor as Class;
			var clName:String = getClassName(dispObjCl);
			if (clName != "" && clName.indexOf("flash.") != 0) {
				// If filters are applied to this display object, we have to specialize the symbol by the hash of the actual properties of the filters used.
				// This gives us a unique symbol id for each compbination of base symbol plus filters applied that we can use to identify this symbol/filter pair.
				//				if (dispObj.filters != null && dispObj.filters.length > 0 && dispObj.name != null && dispObj.name.indexOf("instance") != 0) {
				//					var dblUnder:int = clName.indexOf("__");
				//					if (dblUnder >= 0) {
				//						// If we have a class name following a double underscore, make sure the filter hash is prepended before it.
				//						clName = clName.substr(0, dblUnder) + "_" + getFilterHash(dispObj).toString(16).toUpperCase() + clName.substr(dblUnder);
				//					} else {
				//						clName = clName + "_" + getFilterHash(dispObj).toString(16).toUpperCase();
				//					}
				//				}
				return clName;
			}
			return null;
		}
		
		private function findSymbolInfoForDispObj(dispObj:flash.display.DisplayObject):Object {
			var symName:String = getSymbolName(dispObj);
			if (symName != null) {
				var symbol:Object = this.getSymbolInfo(symName);
				return symbol;
			}
			return null;
		}
		
		private function createNewSymbolInfoForDispObj(dispObj:flash.display.DisplayObject, symbolType:String):Object {
			var symName:String = getSymbolName(dispObj);
			if (symName != null) {
				var symbol:Object = { name:symName, type:symbolType };
				mSymbols[symbol.name] = symbol;
				if (mIsShared) {
					mContext.sharedSymbols[symbol.name] = symbol;
				}
				return symbol;
			}
			throw new Error("Not a valid symbol display object");
		}
		
		private function copyBasicDispObjInfoToJson(dispObj:flash.display.DisplayObject, obj:Object, useSize:Boolean = false):void {
			useSize = false;
			obj.name = dispObj.name;
			if (dispObj.x != 0 || dispObj.y != 0) {
				obj.x = dispObj.x;
				obj.y = dispObj.y;
			}
			if (useSize) {
				obj.width = dispObj.width;
				obj.height = dispObj.height;
			} else {
				if (obj.type == "image") {
					obj.scaleX = dispObj.scaleX/sDrawScale;
					obj.scaleY = dispObj.scaleY/sDrawScale;
				}
				else {
					obj.scaleX = dispObj.scaleX;
					obj.scaleY = dispObj.scaleY;
				}
			}
			if (dispObj.visible != true)
				obj.visible = dispObj.visible;
			if (dispObj.alpha != 1.0)
				obj.alpha = dispObj.alpha;
			
			var matrix:Matrix = dispObj.transform.matrix;
			var aNorm:Number = matrix.a/Math.sqrt(matrix.a*matrix.a+matrix.b*matrix.b);
			var bNorm:Number = matrix.b/Math.sqrt(matrix.a*matrix.a+matrix.b*matrix.b);
			var cNorm:Number = matrix.c/Math.sqrt(matrix.c*matrix.c+matrix.d*matrix.d);
			var dNorm:Number = matrix.d/Math.sqrt(matrix.c*matrix.c+matrix.d*matrix.d);
			
			var angle:Number = Math.atan2(dNorm,cNorm) - Math.atan2(bNorm,aNorm);
			
			while (angle < -Math.PI) angle += Math.PI * 2.0;
			while (angle >  Math.PI) angle -= Math.PI * 2.0;
			
			var skewX:Number = angle - Math.PI/2 + Math.atan2(matrix.b, matrix.a);
			
			if (skewX != 0) {
				obj.skewX = skewX;
			}
			
			var skewY:Number = Math.atan2(matrix.b, matrix.a);
			if (skewY != 0) {
				obj.skewY = skewY;
			}
		}
		
		private function createImageJsonFromDispObj(dispObj:flash.display.DisplayObject):Object {
			
			var bmName:String;
			var bmInfo:Object;			
			var pivotX:Number = 0;
			var pivotY:Number = 0;
			var scale9Grid:Rectangle = null;
			var useSize:Boolean = false;
			
			var symbol:Object = findSymbolInfoForDispObj(dispObj);
			
			if (symbol == null) {
				
				// If we don't have a symbol, we have to take a snapshot of our display object and get bitmap data..
				
				var saveParent:flash.display.DisplayObjectContainer;
				var saveParentIndex:int;
				if (dispObj.parent) {
					saveParentIndex = dispObj.parent.getChildIndex(dispObj);
					saveParent = dispObj.parent;
				}
				var saveX:Number = dispObj.x;
				var saveY:Number = dispObj.y;
				var saveScaleX:Number = dispObj.scaleX;
				var saveScaleY:Number = dispObj.scaleY;
				var saveRotation:Number = dispObj.rotation;
				var saveVisible:Boolean = dispObj.visible;
				var saveAlpha:Number = dispObj.alpha;
				
				//				var restoreData:Object = {};
				//				hideSubObjects(dispObj, restoreData);
				
				// Set to have no scale, rotation, etc.
				if (dispObj.parent)
					dispObj.parent.removeChild(dispObj);
				dispObj.x = dispObj.y = dispObj.rotation = 0;
				dispObj.scaleX = dispObj.scaleY = 1;
				dispObj.visible = true;
				dispObj.alpha = 1.0;
				
				// Get bounds
				var r:Rectangle = dispObj.getBounds(dispObj);
				var inflateSize:int = 0;
				//				if (dispObj.filters != null && dispObj.filters.length > 0) {
				//					for (var fIdx:int = 0; fIdx < dispObj.filters.length; fIdx++) {
				//						var f:BitmapFilter = dispObj.filters[fIdx] as BitmapFilter;
				//						if (f is GlowFilter) {
				//							var glowFilter:GlowFilter = f as GlowFilter;
				//							inflateSize += Math.max(glowFilter.blurX, glowFilter.blurY) + 1.1;
				//						} else if (f is DropShadowFilter) {
				//							var shadowFilter:DropShadowFilter = f as DropShadowFilter;
				//							inflateSize += Math.max(shadowFilter.blurX, shadowFilter.blurY) * 1.1;
				//						} else if (f is BevelFilter) {
				//							var bevelFilter:BevelFilter = f as BevelFilter;
				//							inflateSize += bevelFilter.distance * 1.1;
				//						}
				//					}
				//				}
				r.inflate(inflateSize, inflateSize);
				r.left = Math.floor(r.left) * sDrawScale;
				r.top = Math.floor(r.top) * sDrawScale;
				r.right = Math.ceil(r.right + 1.0) * sDrawScale;    // + 1.0 -- Always make sure left/right pixels 
				r.bottom = Math.ceil(r.bottom + 1.0) * sDrawScale;  // have one empty pixel between to avoid bleed.
				
				// Pivot
				pivotX = -r.left;
				pivotY = -r.top;
				
				// Is this image a scale9?
				if (dispObj is flash.display.Sprite) {
					var sprite:flash.display.Sprite = dispObj as flash.display.Sprite;
					if (sprite.scale9Grid != null) {
						scale9Grid = sprite.scale9Grid;
						scale9Grid.offset(-r.left, -r.top);
						useSize = true;
					}
				}
				
				sMat.identity();
				sMat.scale(sDrawScale, sDrawScale);
				sMat.translate(-r.left, -r.top);
				
				var bmData:BitmapData = new BitmapData(r.width, r.height, true, 0);
				bmData.draw(dispObj, sMat, null, null, null, false);
				
				
				// Restore back to previous scale, rotation, etc.
				dispObj.visible = saveVisible;
				dispObj.alpha = saveAlpha;
				dispObj.x = saveX;
				dispObj.y = saveY;
				dispObj.scaleX = saveScaleX;
				dispObj.scaleY = saveScaleY;
				dispObj.rotation = saveRotation;
				if (saveParent) {
					if (saveParentIndex < saveParent.numChildren)
						saveParent.addChildAt(dispObj, saveParentIndex);
					else
						saveParent.addChild(dispObj);
				}
				
				bmName = makeBitmapName(sUniqueId);
				sUniqueId++;
				
				bmInfo = new Object();
				
				bmInfo.name = bmName;
				bmInfo.width = r.width as Number;
				bmInfo.height = r.height as Number;
				
				mBitmaps[bmName] = bmInfo;
				if (mIsShared) {
					mContext.sharedBitmaps[bmName] = bmInfo;
				}
				
				mBitmapData[bmName] = bmData;
				if (mIsShared) {
					mContext.sharedBitmapData[bmName] = bmData;
				}
				
				// Optionally create a new symbol and store it..
				if (isSymbolDispObj(dispObj)) {
					symbol = createNewSymbolInfoForDispObj(dispObj, "image");
					symbol.bitmapName = bmName;
					if (pivotX != 0 || pivotY != 0) {
						symbol.pivotX = pivotX;
						symbol.pivotY = pivotY;
					}
					if (scale9Grid != null)
						symbol.scale9Grid = { left:scale9Grid.left, top:scale9Grid.top, right:scale9Grid.right, bottom:scale9Grid.bottom };
				}
				
			} else {
				
				// We already have a symbol.. that means we know our bitmap, and our pivot..
				
				bmName = symbol.bitmapName;
				pivotX = symbol.pivotX;
				pivotY = symbol.pivotY;
				if (symbol.hasOwnProperty("scale9Grid"))
					useSize = true;
				
			}
			
			// Create the new image object
			var image:Object = new Object();
			image.type = "image";
			if (symbol == null) {
				image.bitmapName = bmName;
				if (pivotX != 0)
					image.pivotX = pivotX;
				if (pivotY != 0)
					image.pivotY = pivotY;
				if (scale9Grid != null)
					symbol.scale9Grid = { left:scale9Grid.left, top:scale9Grid.top, right:scale9Grid.right, bottom:scale9Grid.bottom };
			} else {
				image.symbolName = symbol.name;
			}
			
			copyBasicDispObjInfoToJson(dispObj, image, useSize);
			
			return image;
		}
		
		private static var trackProps:Array = [ "x", "y", "z", "rotation", "scaleX", "scaleY", "alpha", "visible", "skewX", "skewY"];
		
		private function createAnimSpriteJsonFromMovieClip(movieClip:flash.display.MovieClip):Object {
			var anims:Array = [];
			var prop:String;
			var curValue:Number;
			var curStartValues:Array = new Array();
			var curEndValues:Array = new Array();
			var curStartFrames:Array = new Array();
			var curEndFrames:Array = new Array();
			var child:flash.display.DisplayObject;
			var transform:Transform;
			var matrix:Matrix;
			var tracks:Array = new Array();
			
			var curChildren:Vector.<flash.display.DisplayObject> = new Vector.<flash.display.DisplayObject>();
			var allChildren:Vector.<flash.display.DisplayObject> = new Vector.<flash.display.DisplayObject>();
			var children:Array;
			
			var curFrame:int;
			var childIndex:int;
			var i:int;
			var animSprite:Object;
			var initialLoop:Boolean = false;
//			var adjustments:Object = new Array();
			
			for (var k:int = 0; k < movieClip.numChildren; k++) {
				var kid:flash.display.DisplayObject = movieClip.getChildAt(k);
				
				if (kid is flash.display.Shape) {
					initialLoop = true;
				}
			}

			// hack to get the initial scale value of flash shapes
			if (initialLoop && movieClip.totalFrames > 1) {
				for (var f:int=1; f <= 2; f++) {
					movieClip.gotoAndStop(f);
				}
				movieClip.gotoAndStop(1);
			}
			
			var mcSprite:Object = createSpriteJsonFromDispObjCont(movieClip);
			
			if (mcSprite.symbolName) {
				children = getSymbolInfo(mcSprite.symbolName).children;
				
				if (getSymbolInfo(mcSprite.symbolName).anims) {
					anims = getSymbolInfo(mcSprite.symbolName).anims;
					
					animSprite = createSpriteJsonFromDispObjCont(movieClip);
					animSprite.type = "anim";
					
					animSprite.anims = anims;
					
					animSprite.totalFrames = movieClip.totalFrames;
					
					
					if (children.length < anims.length) {
						trace("");
					}
					
					return animSprite;
				}
			}
			else {
				children = new Array();
			}
			
			for (i=0; i < movieClip.numChildren; i++) {
				var toKeep:Boolean = false;
				
				child = movieClip.getChildAt(i);
				
				if (allChildren.indexOf(child) == -1) {
					allChildren.push(child);
					curChildren.push(child);
					
					childIndex = allChildren.indexOf(child);
					
					curStartValues.push({});
					curStartFrames.push({});
					
					curEndValues.push({});
					curEndFrames.push({});
//					adjustments.push({});
					
					tracks.push({});
				}
				
				for each (prop in trackProps) {
					
					transform = Object(child)["transform"] as Transform;
					matrix = transform.matrix;
					
					curValue = processProp(child, prop, matrix);
					
//					if (children[i][prop] && Math.abs(children[i][prop] / curValue) > 1.5 || Math.abs(children[i][prop] / curValue) < 0.75) {
//						adjustments[i][prop] = children[i][prop] / curValue;
//						curValue = children[i][prop];
//					}
					
					curStartValues[childIndex][prop] = curValue;
					curStartFrames[childIndex][prop] = 1;
					
					if (curFrame+1 > movieClip.totalFrames) {
						tracks[childIndex][prop] = { start: { frames:[curFrame], values:[curValue] }, end:{frames:[curFrame], values:[curValue]}};
					}
					else {
						tracks[childIndex][prop] = { start: { frames:[curFrame], values:[curValue] }, end:{frames:[], values:[]}};
					}
					
					curEndValues[childIndex][prop] = curValue;
					curEndFrames[childIndex][prop] = curFrame;
				}
				
				curStartValues[childIndex]["label"] = movieClip.currentLabel;
				tracks[childIndex]["label"] = { start: { frames:[1], values:[movieClip.currentLabel] }, end:{frames:[], values:[]}};
			}
			
			if (children.length < tracks.length) {
				trace("");
			}
			
			for (curFrame = 2; curFrame <= movieClip.totalFrames; curFrame++) {
				movieClip.gotoAndStop(curFrame);
				
				//check if current children are there
				for (var curChild:int=0; curChild < curChildren.length; ) {
					
					try {
						movieClip.getChildIndex(curChildren[curChild]);
						curChild++;
					}
					catch (e:Error) {
						childIndex = allChildren.indexOf(curChildren[curChild]);

						for each (prop in trackProps) {
							if (tracks[childIndex][prop]["end"]["frames"].length != tracks[childIndex][prop]["start"]["frames"].length) {
								tracks[childIndex][prop]["end"]["frames"].push(curFrame-1);
								tracks[childIndex][prop]["end"]["values"].push(curEndValues[childIndex][prop]);
							}
							if (prop == "visible") {
								tracks[childIndex][prop]["start"]["frames"].push(curFrame);
								tracks[childIndex][prop]["start"]["values"].push(0);
								tracks[childIndex][prop]["end"]["frames"].push(movieClip.totalFrames);
								tracks[childIndex][prop]["end"]["values"].push(0);
							}
							else {
								tracks[childIndex][prop]["start"]["frames"].push(curFrame);
								tracks[childIndex][prop]["start"]["values"].push(curEndValues[childIndex][prop]);
								tracks[childIndex][prop]["end"]["frames"].push(movieClip.totalFrames);
								tracks[childIndex][prop]["end"]["values"].push(curEndValues[childIndex][prop]);
							}
						}
						
						curChildren.splice(curChild, 1);
					}
				}
				
				// go through all children
				for (var c:int=0; c < movieClip.numChildren; c++) {
					child = movieClip.getChildAt(c);
					
					transform = Object(child)["transform"] as Transform;
					matrix = transform.matrix;
					
					// check for new children
					if (allChildren.indexOf(child) == -1) {
						var frame:int;
						
						if (c == 0){ 
							childIndex = 0;
						}
						else {
							childIndex = allChildren.indexOf(movieClip.getChildAt(c-1))+1;
						}
						
						var origIndex:int = childIndex;
						
						if (childIndex >= allChildren.length) {
							allChildren.push(child);
							curChildren.push(child);
							
							curStartValues.push({});
							curStartFrames.push({});
							
							curEndValues.push({});
							curEndFrames.push({});
							
							tracks.push({});
	//						adjustments.push({});
							
							origIndex = -1;
						}
						else {
							allChildren.splice(childIndex, 0, child);
							curChildren.splice(childIndex, 0, child);
							
							curStartValues.splice(childIndex, 0, {});
							curStartFrames.splice(childIndex, 0, {});
							
							curEndValues.splice(childIndex, 0, {});
							curEndFrames.splice(childIndex, 0, {});
							
							tracks.splice(childIndex, 0, {});
						}
						
						childIndex = allChildren.indexOf(child);
						
						for each (prop in trackProps) {
							if (prop != "visible") {
								curValue = processProp(child, prop, matrix);
								tracks[childIndex][prop] = { start: { frames:[1], values:[curValue] }, end:{frames:[curFrame - 1], values:[curValue]}};
							}
							else {
								tracks[childIndex][prop] = { start: { frames:[1], values:[0] }, end:{frames:[curFrame - 1], values:[0]}};
							}
								
							curValue = processProp(child, prop, matrix);
							
//							if (adjustments[childIndex][prop]) {
//								curValue *= adjustments[childIndex][prop];
//							}
							
							curStartValues[childIndex][prop] = curValue;
							curStartFrames[childIndex][prop] = 1;
							
							tracks[childIndex][prop]["start"]["frames"].push(curFrame);
							tracks[childIndex][prop]["start"]["values"].push(curValue);
							
							if (curFrame+1 >= movieClip.totalFrames) {
								tracks[childIndex][prop]["end"]["frames"].push(movieClip.totalFrames);
								tracks[childIndex][prop]["end"]["values"].push(curValue);
							}
							curEndValues[childIndex][prop] = curValue;
							curEndFrames[childIndex][prop] = curFrame;
							
							curStartValues[childIndex]["label"] = movieClip.currentLabel;
							tracks[childIndex]["label"] = { start: { frames:[1], values:[movieClip.currentLabel] }, end:{frames:[], values:[]}};
						}
						
						processChildren(child, movieClip, children, origIndex);
					}
					else {
						childIndex = allChildren.indexOf(child);
					
						// check each child for data changes
						transform = Object(child)["transform"] as Transform;
						matrix = transform.matrix;
						
						for each (prop in trackProps) {
							curValue = processProp(child, prop, matrix);
							
//							if (adjustments[childIndex][prop]) {
//								curValue *= adjustments[childIndex][prop];
//							}
							
							var diff:Number = Math.abs((curEndValues[childIndex][prop] - curValue) / (curEndFrames[childIndex][prop] - curFrame) - 
								(curStartValues[childIndex][prop] - curEndValues[childIndex][prop]) / (curStartFrames[childIndex][prop] - curEndFrames[childIndex][prop]));
							var absDiff:Number = Math.abs(curValue - curStartValues[childIndex][prop]);
							if ((prop =="x" || prop == "y" || prop == "z") && diff > 0.1*quality || diff > 0.01*quality || absDiff > Math.PI/2) {
								curStartValues[childIndex][prop] = curValue;
								curStartFrames[childIndex][prop] = curFrame;
								tracks[childIndex][prop]["start"]["frames"].push(curFrame);
								tracks[childIndex][prop]["start"]["values"].push(curValue);
								tracks[childIndex][prop]["end"]["frames"].push(curEndFrames[childIndex][prop]);
								tracks[childIndex][prop]["end"]["values"].push(curEndValues[childIndex][prop]);
								curEndValues[childIndex][prop] = curValue;
								curEndFrames[childIndex][prop] = curFrame;
							}
							else {
								curEndValues[childIndex][prop] = curValue;
								curEndFrames[childIndex][prop] = curFrame;
							}
							
							if (curFrame == movieClip.totalFrames) {
								tracks[childIndex][prop]["end"]["frames"].push(movieClip.totalFrames);
								tracks[childIndex][prop]["end"]["values"].push(curValue);
							}
						}
						
						if (curStartValues[childIndex]["label"] != movieClip.currentLabel) {
							curStartValues[childIndex]["label"] = movieClip.currentLabel
							tracks[childIndex]["label"]["start"]["frames"].push(curFrame);
							tracks[childIndex]["label"]["start"]["values"].push(movieClip.currentLabel);
						}
					}
				}
				
			}
			
			// recurse through the children and set up all of the child movieclips correctly
			var addons:Boolean;
			var origLen:int;
			if (anims.length != 0) {
				addons = true;
				origLen = anims.length;
			}
			
			for (i=0; i < allChildren.length; i++) {
								
				for each (prop in trackProps) {
					if (tracks[i][prop]["start"]["frames"].length >= 1) {
						toKeep = true;
					}
					
					if (tracks[i][prop]["start"]["frames"].length > tracks[i][prop]["end"]["frames"].length) {
						toKeep = false;
					}
				}
				
				if (tracks[i]["label"]["start"]["frames"].length > 1) {
					toKeep = true;
				}
				
				if (toKeep) {
					if (addons) {
						anims.push({ "child": (origLen + i), "tracks": tracks[i]});
					}
					else {
						anims.push({ "child": i, "tracks": tracks[i]});
					}
				}
				
			}
			// play so that it's moving if placed somewhere
			movieClip.play();
			
			animSprite = createSpriteJsonFromDispObjCont(movieClip);
			animSprite.type = "anim";
			
			mSymbols[mcSprite.symbolName].type = "anim"; 
			
			animSprite.anims = anims;
			
			mSymbols[animSprite.symbolName].anims = anims;
			
			animSprite.totalFrames = movieClip.totalFrames;
			
			if (children.length < anims.length) {
				trace("");
			}
			
			return animSprite;
		}
		
		private function processProp(child:flash.display.DisplayObject, prop:String, matrix:Matrix):Number {
			var curValue:Number;
			
			if (prop == "rotation") {
				curValue = 0;
			}
			else if (prop == "skewX") {
				var aNorm:Number = matrix.a/Math.sqrt(matrix.a*matrix.a+matrix.b*matrix.b);
				var bNorm:Number = matrix.b/Math.sqrt(matrix.a*matrix.a+matrix.b*matrix.b);
				var cNorm:Number = matrix.c/Math.sqrt(matrix.c*matrix.c+matrix.d*matrix.d);
				var dNorm:Number = matrix.d/Math.sqrt(matrix.c*matrix.c+matrix.d*matrix.d);
				
				var angle:Number = Math.atan2(dNorm,cNorm) - Math.atan2(bNorm,aNorm);
				
				while (angle < -Math.PI) angle += Math.PI * 2.0;
				while (angle >  Math.PI) angle -= Math.PI * 2.0;
				
				curValue = angle - Math.PI/2 + Object(child)["rotation"]*Math.PI/180.0;
			}
			else if (prop == "skewY") {
				curValue = Object(child)["rotation"]*Math.PI/180.0;
			}
			else
			{
				curValue = Object(child)[prop];
			}
			
			return curValue;
		}
		
		private function createTextJsonFromDispObj(dispObj:flash.display.DisplayObject):Object {
			
			var textField:flash.text.TextField = dispObj as flash.text.TextField;
			var tf:TextFormat = textField.defaultTextFormat;
			
			var saveFilters:Array;
			if (textField.filters != null && textField.filters.length > 0) {
				saveFilters = textField.filters;
				textField.filters = new Array();
			}
			
			var text:Object = new Object();
			text.type = "text";
			text.text = textField.text;
			text.color = tf.color;
			text.width = textField.width;
			text.height = textField.height;
			if (tf.font != null)
				text.fontName = tf.font;
			if (tf.size != null) 
				text.fontSize = tf.size;
			if (tf.bold != false)
				text.bold = tf.bold;
			if (tf.italic != false)
				text.italic = tf.italic;
			if (tf.underline != false)
				text.underline = tf.underline;
			if (tf.kerning != false)
				text.kerning = tf.kerning;
			if (tf.align != "left")
				text.align = tf.align;
			if (textField.multiline != false)
				text.multiline = textField.multiline;
			if (textField.wordWrap != false)
				text.wordWrap = textField.wordWrap;
			if (saveFilters != null && saveFilters.length > 0) {
				text.nativeFilters = JSON.parse(JSON.stringify(saveFilters));
				for (var i:int = saveFilters.length - 1; i >= 0; i--) {
					var src:Object = saveFilters[i];
					var dst:Object = text.nativeFilters[i];
					if (src is DropShadowFilter) {
						dst.filterType = "dropShadow";
					} else if (src is GlowFilter) {
						dst.filterType = "glow";
					} else if (src is ColorMatrixFilter) {
						dst.filterType = "colorMatrix";
					} else if (src is BevelFilter) {
						dst.filterType = "bevel";
					} else if (src is BlurFilter) {
						dst.filterType = "blur";
					} else if (src is GradientBevelFilter) {
						dst.filterType = "gradientBevel";
					} else if (src is GradientGlowFilter) {
						dst.filterType = "gradientGlow";
					} else {
						// Other filters are not supported.
						text.nativeFilters.splice(i, 1);
					}
				}
			}
			
			copyBasicDispObjInfoToJson(dispObj, text, true);			
			
			if (saveFilters != null) {
				textField.filters = saveFilters;
			}
			
			return text;
		}
		
		private function createSpriteJsonFromDispObjCont(cont:flash.display.DisplayObjectContainer):Object {
			
			var children:Array;
			
			var symbol:Object = findSymbolInfoForDispObj(cont);
			
			// Compile symbol info for all children..
			if (symbol == null) {
				
				var len:int = cont.numChildren;
				
				children = new Array();
				
				for (var i:int = 0; i < len; i++) {
					var child:flash.display.DisplayObject;
						child = cont.getChildAt(i);
					
					processChildren(child, cont, children);
				}
			}
			
			// Create a new sprite symbol with all child info.
			if (symbol == null && isSymbolDispObj(cont)) {
				symbol = createNewSymbolInfoForDispObj(cont, "sprite");
				symbol.children = children;
			}
			
			var sprite:Object = new Object();
			sprite.type = "sprite";
			if (symbol == null) {
				sprite.children = children;
			} else {
				sprite.symbolName = symbol.name;
			}
			
			copyBasicDispObjInfoToJson(cont, sprite);
			
			return sprite;
		}
		
		private function processChildren(child:flash.display.DisplayObject, parent:flash.display.DisplayObjectContainer, children:Array, index:int=-1):void {
			// Potentially filter object if callback is set.
			var includeObj:Boolean = true;
			if (sFilterCallback != null) {
				includeObj = sFilterCallback(this, child);
			}
			
			if (includeObj) {
				var childSprite:Object;
				var origLength:int = children.length;
				
				if (isImageDispObj(child)) {
					var childImage:Object = createImageJsonFromDispObj(child);
					if (index == -1) {
						children.push(childImage);
					}
					else {
						children.splice(index, 0, childImage);
					}
				} else if (isTextDispObj(child)) {
					var childText:Object = createTextJsonFromDispObj(child);
					if (index == -1) {
						children.push(childText);
					}
					else {
						children.splice(index, 0, childText);
					}
				} else if (child is flash.display.MovieClip && flash.display.MovieClip(child).totalFrames > 1) {
					var childAnimSprite:Object = createAnimSpriteJsonFromMovieClip(child as flash.display.MovieClip);
					if (index == -1) {
						children.push(childAnimSprite);
					}
					else {
						children.splice(index, 0, childAnimSprite);
					}
				} else if (child is flash.display.DisplayObjectContainer) {
					childSprite = createSpriteJsonFromDispObjCont(child as flash.display.DisplayObjectContainer);
					if (index == -1) {
						children.push(childSprite);
					}
					else {
						children.splice(index, 0, childSprite);
					}
				} else if (parent is flash.display.MovieClip) { // HACK: for movie clips, need all children present to make animations correct
					var childSymbol:Object = findSymbolInfoForDispObj(child);
					if (childSymbol == null && isSymbolDispObj(child)) {
						childSymbol = createNewSymbolInfoForDispObj(child, "sprite");
					}
					childSprite = new Object();
					childSprite.type = "sprite";
					childSprite.children = new Array();
					if (index == -1) {
						children.push(childSprite);
					}
					else {
						children.splice(index, 0, childSprite);
					}
				}
				
				if(child.mask) {
					notSupportedAnimations += child.name + "has a mask which isn't supported";
				}
				
				if (child.filters.length > 0) {
					for (var i:int = 0; i < child.filters.length; i++) {
						notSupportedAnimations += child + " has a " + child.filters[i] + " filter which isn't supported.\n";
					}
				}
			}
		}
		
		private static function hasNonStaticChildren(cont:flash.display.DisplayObjectContainer):Boolean {
			var len:int = cont.numChildren;
			for (var i:int = 0; i < len; i++) {
				var child:flash.display.DisplayObject = cont.getChildAt(i);
				// This is some sort of control we want to access directly.
				if (child.name != null && child.name.indexOf("instance") != 0) {
					return true;
				}
				// This is a movie clip with animated frames.
				if (child is flash.display.MovieClip && flash.display.MovieClip(child).totalFrames > 1) {
					return true;
				}
				// This is a sub-symbol.
				var cl:Class = Object(child).constructor;
				if (cl != null && getClassName(cl).indexOf("flash.") != 0) {
					return true;
				}
				
				var childCont:flash.display.DisplayObjectContainer = child as flash.display.DisplayObjectContainer;
				if (childCont != null) {
					var childNonStatic:Boolean = hasNonStaticChildren(childCont);
					if (childNonStatic) {
						return true;
					}
				}
			}
			
			return false;
		}
		
		private static function isImageDispObj(dispObj:flash.display.DisplayObject):Boolean {
			if (dispObj is flash.display.MovieClip) {
				return false;
			}
			if (dispObj is flash.display.Shape || dispObj is flash.display.Bitmap || dispObj is flash.text.StaticText) {
				return true;
			}
			if (dispObj is flash.display.Sprite && flash.display.Sprite(dispObj).scale9Grid != null) {
				return true;
			}
			if (dispObj is flash.text.TextField || dispObj) {
				return false;
			}
			var cl:Class = Object(dispObj).constructor;			
			if (getClassName(cl).indexOf("flash.") != 0) {
				return false;
			}
			var cont:flash.display.DisplayObjectContainer = dispObj as flash.display.DisplayObjectContainer;
			if (cont != null) {
				return !hasNonStaticChildren(cont);
			} else {
				return false;
			}
		}
		
		private static function isTextDispObj(dispObj:flash.display.DisplayObject):Boolean {
			return dispObj is flash.text.TextField;
		}		
		
		//
		// Atlasing system
		//
		
		private function findAtlas(bmName:String, atlasJson:Array):int {
			for (var i:int = 0; i < atlasJson.length; i++) {
				var json:Object = atlasJson[i];
				for each (var subTex:Object in json.subTexture) {
					if (subTex.name == bmName) {
						return i;
					}
				}
			}
			return -1;
		}
		
		private function atlasTextures():void {
			
			var bitmapNames:Vector.<String> = new Vector.<String>();
			var bitmaps:Vector.<BitmapData> = new Vector.<BitmapData>();
			
			var bitmapInfo:Object;
			var bmName:String;
			var bmData:BitmapData;			
			
			for each (bitmapInfo in mBitmaps) {
				bmName = bitmapInfo.name;
				bmData = getBitmapData(bmName);
				bitmapNames.push(bmName);
				bitmaps.push(bmData);
			}
			
			if (bitmaps.length == 0)
				return;
			
			var packedAtlasBitmaps:Vector.<BitmapData> = new Vector.<BitmapData>();
			var packedAtlasJson:Array = new Array();
			var unpackedBitmaps:Vector.<String> = new Vector.<String>();
			
			TextureAtlasPacker.packAtlases(sAtlasSize, bitmapNames, bitmaps, packedAtlasBitmaps, packedAtlasJson, unpackedBitmaps);
			
			var firstAtlas:int = sUniqueId;
			sUniqueId += packedAtlasBitmaps.length;			
			
			// Redirect existing bitmaps to point to their atlas info.
			for each (bitmapInfo in mBitmaps) {
				bmName = bitmapInfo.name;
				bmData = getBitmapData(bmName);
				
				if (unpackedBitmaps.indexOf(bmName) == -1) {
					
					// Set the source of this bitmap to the atlas bitmap
					var atlasId:int = findAtlas(bmName, packedAtlasJson);
					var atlasSource:String = makeBitmapName(firstAtlas + atlasId);
					bitmapInfo.source = atlasSource;
					
					// Delete the original bitmap data (we have the atlas now).
					delete mBitmapData[bmName];
					if (mContext.sharedBitmapData[bmName] != null) {
						delete mContext.sharedBitmapData[bmName];
					}
				}
			}
			
			// Add atlas bitmaps.
			for (var i:int = 0; i < packedAtlasBitmaps.length; i++) {
				
				bmName = makeBitmapName(firstAtlas + i);
				var atlasInfo:Object = {
					"name": bmName,
					"width": sAtlasSize,
					"height": sAtlasSize,
					"atlas": packedAtlasJson[i]
				}
				
				mBitmaps[bmName] = atlasInfo;
				if (mIsShared) {
					mContext.sharedBitmaps[bmName] = atlasInfo;
				}
				
				mBitmapData[bmName] = packedAtlasBitmaps[i];
				if (mIsShared) {
					mContext.sharedBitmapData[bmName] = packedAtlasBitmaps[i];
				}
			}
			
		}
		
		private static function makeName(name:String):String {
			return name.replace(" ", "_").replace(".", "_").replace("/", "_");
		}
		
		private static function makeRootJsonObject(asset:Asset, dispObj:flash.display.DisplayObject):Object {
			var obj:Object;
			if (isImageDispObj(dispObj)) {
				obj = asset.createImageJsonFromDispObj(dispObj);
			} else if (dispObj is flash.display.DisplayObjectContainer) {
				obj = asset.createSpriteJsonFromDispObjCont(dispObj as flash.display.DisplayObjectContainer);
			} else {
				throw new Error("Display object must be either an image or a sprite");
			}
			return obj;
		}
		
		/**
		 * Creates a starling display asset from an existing display object.
		 * 
		 * <p>Recursively creates textures for all display object visuals, text fields for any dynamic text, and
		 * automatically detects symbols and shared assets.</p>
		 * 
		 * <p>Asset then stores the json data required to create a new set of starling display elements in the
		 * same way that a flash SWF class can be used to create a new flash display image.</p>
		 *  
		 * @param dispObj	display object to build
		 * @param name		name of the asset (optional, defaults to "asset") NOTE: all spaces, slashes, and periods are converted to underscores.
		 * @param context	context for any shared symbols or information (optional, defaults to null).
		 * @param isShared	if true, will share all bitmaps and symbols in this asset with other assets.
		 * @param autoAtlas	automatically creates texture atlases if true.
		 * @return the new asset.
		 */
		public static function fromDisplayObject(dispObj:flash.display.DisplayObject, 
												 name:String = "asset", context:AssetContext = null, isShared:Boolean = false, autoAtlas:Boolean = true):Asset {
			
			// Make a valid name compatible with file systems.
			name = makeName(name);
			
			var asset:Asset = new Asset(context);
			asset.mName = name;
			asset.mIsShared = isShared;
			
			asset.mRootObject = makeRootJsonObject(asset, dispObj);
			
			if (autoAtlas) {
				asset.atlasTextures();
			}
			
			trace(JSON.stringify(asset.toJSON()));
			
			//			var dumpPath:String = File.documentsDirectory.nativePath + "/radDump/";
			//			asset.saveAllBitmaps(dumpPath);
			//			asset.saveJson(dumpPath);
			//			asset.saveBinary(dumpPath);
			
			return asset;
		}
		
		//
		// Methods for creating new starling objects from this asset.
		//
		
		private function setStarlingBasicDispObjDataFromJson(obj:Object, dispObj:starling.display.DisplayObject):void {
			
			for (var key:String in obj) {
				switch (key) {
					case "name": dispObj.name = obj.name; break;
					case "x": dispObj.x = obj.x; break;
					case "y": dispObj.y = obj.y; break;
					case "scaleX": dispObj.scaleX = obj.scaleX; break;
					case "scaleY": dispObj.scaleY = obj.scaleY; break;
					case "width": dispObj.width = obj.width; break;
					case "height": dispObj.height = obj.height; break;
					case "rotation": dispObj.rotation = obj.rotation; break;
					case "visible": dispObj.visible = obj.visible; break;
					case "alpha": dispObj.alpha = obj.alpha; break;
					case "skewX": dispObj.skewX = obj.skewX; break;
					case "skewY": dispObj.skewY = obj.skewY; break;
				} 
			}		
		}
		
		private function createStarlingImageFromJsonData(obj:Object, context:AssetCreateContext):starling.display.DisplayObject {
			
			var pivotX:Number;
			var pivotY:Number;
			var bmName:String;
			var scale9Grid:Object;
			
			var symbolName:String = obj.symbolName;
			if (symbolName) {
				var symbol:Object = getSymbolInfo(symbolName);
				if (symbol == null) {
					throw new Error("Missing image symbol " + symbolName);
				}
				if (symbol.hasOwnProperty("pivotX"))
					pivotX = symbol.pivotX;
				else
					pivotX = 0;
				if (symbol.hasOwnProperty("pivotY"))
					pivotY = symbol.pivotY;
				else
					pivotY = 0;
				bmName = symbol.bitmapName;
				if (symbol.hasOwnProperty("scale9Grid"))
					scale9Grid = symbol.scale9Grid;
			} else {
				if (obj.hasOwnProperty("pivotX"))
					pivotX = obj.pivotX;
				else
					pivotX = 0;
				if (obj.hasOwnProperty("pivotY"))
					pivotY = obj.pivotY;
				else
					pivotY = 0;
				if (obj.hasOwnProperty("scale9Grid"))
					scale9Grid = obj.scale9Grid;
				bmName = obj.bitmapName;
			}
			
			var bmInfo:Object = getBitmapInfo(bmName);
			if (bmInfo == null) 
				throw new Error("Unable to find bitmap '" + bmName + "' when building starling asset.");
			
			var bmWidth:Number = bmInfo.width;
			var bmHeight:Number = bmInfo.height;
			
			var texture:Texture = context.textureCache[bmName];
			
			// Is a sub texture of an atlas..
			if (texture == null) {
				
				if (bmInfo.hasOwnProperty("source")) {
					
					var sourceName:String = bmInfo.source;
					
					var atlas:TextureAtlas;
					var atlasTexture:Texture 
					
					atlasTexture = context.textureCache[sourceName];
					
					if (atlasTexture == null) {
						
						// Make a new atlas texture and add it to the cache
						var atlasInfo:Object = getBitmapInfo(sourceName);
						var atlasBm:BitmapData = getBitmapData(sourceName);
						if (atlasBm == null) {
							throw new Error("Missing atlas bitmap data for bitmap " + sourceName);
						}
						
						atlasTexture = Texture.fromBitmapData(atlasBm, false, false, 1);
						
						// Make a new texture atlas
						atlas = new TextureAtlas(atlasTexture, atlasInfo.atlas);
						
						// Add to context
						context.textureCache[sourceName] = atlasTexture;
						context.referencedTextures[sourceName] = atlasTexture;
						
					} else {
						
						// Use the atlas texture to find our subtexture
						atlas = atlasTexture.textureAtlas;
						
					}
					
					if (atlas == null) {
						throw new Error("Texture " + bmName + " is not an atlas.");
					}
					
					texture = atlas.getTexture(bmName);
					
					if (texture == null) {
						throw new Error("Unable to find atlas subtexture " + bmName);
					}
					
				} else {
					
					var bitmapData:BitmapData = getBitmapData(bmName);
					if (bitmapData == null) {
						throw new Error("Missing bitmap data for bitmap " + bmName);
					}
					
					texture = starling.textures.Texture.fromBitmapData(bitmapData, false); 
					
					context.textureCache[bmName] = texture;
					context.referencedTextures[bmName] = texture;
				}
			}
			
			if (texture.textureAtlas == null && scale9Grid) {
				
				var sx1:Number = scale9Grid.left;
				var sy1:Number = scale9Grid.top;
				var sx2:Number = scale9Grid.right;
				var sy2:Number = scale9Grid.bottom;
				var sw1:Number = sx2 - sx1;
				var sw2:Number = bmWidth - sx2;
				var sh1:Number = sy2 - sy1;
				var sh2:Number = bmHeight - sy2;
				var scale9Tex:TextureAtlas = new TextureAtlas(texture as starling.textures.Texture, 
					{
						scale:1,
						subTexture:[
							{ name:bmName+"_tl", x:0,   y:0,   width:sx1, height:sy1 },
							{ name:bmName+"_tm", x:sx1, y:0,   width:sw1, height:sy1 },
							{ name:bmName+"_tr", x:sx2, y:0,   width:sw2, height:sy1 },
							{ name:bmName+"_ml", x:0,   y:sy1, width:sx1, height:sh1 },
							{ name:bmName+"_mm", x:sx1, y:sy1, width:sw1, height:sh1 },
							{ name:bmName+"_mr", x:sx2, y:sy1, width:sw2, height:sh1 },
							{ name:bmName+"_bl", x:0,   y:sy2, width:sx1, height:sh2 },
							{ name:bmName+"_bm", x:sx1, y:sy2, width:sw1, height:sh2 },
							{ name:bmName+"_br", x:sx2, y:sy2, width:sw2, height:sh2 }
						]
					});
				if (scale9Tex == null) {
					throw new Error("Invalid texture atlas!");
				}
			}
			
			var image:starling.display.DisplayObject;
			
			if (scale9Grid != null) {
				if (texture.textureAtlas == null) {
					throw new Error("Nine slice image requires a texture with a texture atlas.");
				}
				var scale9Image:starling.display.NineSliceImage = new starling.display.NineSliceImage(texture.textureAtlas, bmName);
				image = scale9Image;
			} else {
				image = new starling.display.Image(texture as starling.textures.Texture);
			}
			
			image.pivotX = pivotX;
			image.pivotY = pivotY;
			
			image.symbolName = symbolName;			
			
			setStarlingBasicDispObjDataFromJson(obj, image);
			
			return image;
		}
		
		private static var trackIds:Object = { x:TrackTarget.X, y:TrackTarget.Y, rotation:TrackTarget.ROTATION, scaleX:TrackTarget.SCALEX,
			scaleY:TrackTarget.SCALEY, alpha:TrackTarget.ALPHA, visible:TrackTarget.VISIBLE, skewX:TrackTarget.SKEWX, skewY:TrackTarget.SKEWY,
			label:TrackTarget.LABEL };
		
		private function createStarlingAnimSpriteFromJsonData(obj:Object, context:AssetCreateContext):starling.display.DisplayObject {
			var animSprite:AnimSprite = createStarlingSpriteFromJsonData(obj, context, AnimSprite) as AnimSprite;
			
			var anims:Object = obj.anims;
			
			animSprite.initFrames(obj.totalFrames);
			
			for (var i:int = 0; i < anims.length; i++) {
				var anim:Object = anims[i];
				var child:Object = animSprite.getChildAt(anim["child"]);
				var tracks:Object = anim["tracks"];
				
				for (var prop:String in tracks) {
					if (tracks[prop] != null && tracks[prop]["start"]["frames"].length >= 1) {
						animSprite.addTrack(trackIds[prop], tracks[prop]["start"]["frames"], tracks[prop]["start"]["values"], 
							tracks[prop]["end"]["frames"], tracks[prop]["end"]["values"], child as starling.display.DisplayObject);
					}
				}
			}
			
			return animSprite;
		}
		
		private function createStarlingSpriteFromJsonData(obj:Object, context:AssetCreateContext, cl:Class = null):starling.display.DisplayObject {
			
			var children:Array;
			
			var symbolName:String = obj.symbolName;
			if (symbolName) {
				var symbol:Object = getSymbolInfo(symbolName);
				if (symbol == null) {
					throw new Error("Missing sprite symbol " + symbolName);
				}
				children = symbol.children as Array;
			} else {
				children = obj.children as Array;
			}
			
			var sprite:starling.display.Sprite;
			if (cl != null) {
				sprite = new cl();
			} else {
				sprite = new starling.display.Sprite();
			}
			sprite.symbolName = symbolName;
			
			setStarlingBasicDispObjDataFromJson(obj, sprite);
			
			var len:int = children.length;
			for (var i:int = 0; i < len; i++) {
				var child:Object = children[i];
				var childDispObj:starling.display.DisplayObject = createStarlingObjectFromJsonData(child, context);
				sprite.addChild(childDispObj);
			}
			
			return sprite;
		}
		
		private function createNativeFiltersFromJsonData(filters:Array, textField:starling.text.TextField, context:AssetCreateContext):Array {
			var nativeFilters:Array = new Array();
			var i:int;
			for each (var filter:Object in filters) {
				if (filter.filterType == "glow") {
					var glow:GlowFilter = new GlowFilter();
					glow.alpha = filter.alpha;
					glow.blurX = filter.blurX;
					glow.blurY = filter.blurY;
					glow.color = filter.color;
					glow.inner = filter.inner;
					glow.knockout = filter.knockout;
					glow.quality = filter.quality;
					glow.strength = filter.strength;
					nativeFilters.push(glow);
				} else if (filter.filterType == "bevel") {
					var bev:BevelFilter = new BevelFilter();
					bev.angle = filter.angle;
					bev.blurX = filter.blurX;
					bev.blurY = filter.blurY;
					bev.distance = filter.distance;
					bev.highlightAlpha = filter.highlightAlpha;
					bev.highlightColor = filter.highlightColor;
					bev.quality = filter.quality;
					bev.shadowAlpha = filter.shadowAlpha;
					bev.shadowColor = filter.shadowColor;
					bev.strength = filter.strength;
					bev.type = filter.type;
					nativeFilters.push(bev);
				} else if (filter.filterType == "colorMatrix") {
					var col:ColorMatrixFilter = new ColorMatrixFilter();
					for (var mi:int = 0; mi < filter.matrix.length; mi++) {
						col.matrix[mi] = filter.matrix[mi];
					}
					nativeFilters.push(col);
				} else if (filter.filterType == "blur") {
					var blur:BlurFilter = new BlurFilter();
					blur.blurX = filter.blurX;
					blur.blurY = filter.blurY;
					blur.quality = filter.quality;
					nativeFilters.push(blur);
				} else if (filter.filterType == "dropShadow") {
					var shad:DropShadowFilter = new DropShadowFilter();
					shad.alpha = filter.alpha;
					shad.angle = filter.angle;
					shad.blurX = filter.blurX;
					shad.blurY = filter.blurY;
					shad.color = filter.color;
					shad.distance = filter.distance;
					shad.hideObject = filter.hideObject;
					shad.inner = filter.inner;
					shad.knockout = filter.knockout;
					shad.quality = filter.quality;
					shad.strength = filter.strength;
					nativeFilters.push(shad);
				} else if (filter.filterType == "gradientGlow") {
					var grGlow:GradientGlowFilter = new GradientGlowFilter();
					if (filter.colors != null) {
						var colors:Array = [];
						for (i = 0; i < filter.colors.length; i++) {
							colors.push(filter.colors[i]);
						}
						grGlow.colors = colors;
					}
					if (filter.alphas != null) {
						var alphas:Array = [];
						for (i = 0; i < filter.alphas.length; i++) {
							alphas.push(filter.alphas[i]);
						}
						grGlow.alphas = alphas;
					}
					if (filter.ratios != null) {
						var ratios:Array = [];
						for (i = 0; i < filter.ratios.length; i++) {
							ratios.push(filter.ratios[i]);
						}
						grGlow.ratios = ratios;
					}
					grGlow.angle = filter.angle;
					grGlow.blurX = filter.blurX;
					grGlow.blurY = filter.blurY;
					grGlow.distance = filter.distance;
					grGlow.knockout = filter.knockout;
					grGlow.quality = filter.quality;
					grGlow.strength = filter.strength;
					grGlow.type = filter.type;
					nativeFilters.push(grGlow);
				} else if (filter.filterType == "gradientBevel") {
					var grBev:GradientBevelFilter = new GradientBevelFilter();
					if (filter.colors != null) {
						var colors2:Array = [];
						for (i = 0; i < filter.colors.length; i++) {
							colors2.push(filter.colors[i]);
						}
						grBev.colors = colors2;
					}
					if (filter.alphas != null) {
						var alphas2:Array = [];
						for (i = 0; i < filter.alphas.length; i++) {
							alphas2.push(filter.alphas[i]);
						}
						grBev.alphas = alphas2;
					}
					if (filter.ratios != null) {
						var ratios2:Array = [];
						for (i = 0; i < filter.ratios.length; i++) {
							ratios2.push(filter.ratios[i]);
						}
						grBev.ratios = ratios2;
					}
					grBev.angle = filter.angle;
					grBev.blurX = filter.blurX;
					grBev.blurY = filter.blurY;
					grBev.distance = filter.distance;
					grBev.knockout = filter.knockout;
					grBev.quality = filter.quality;
					grBev.strength = filter.strength;
					grBev.type = filter.type;
					nativeFilters.push(grBev);
				} else {
					// Unknown
				}
			}
			
			return nativeFilters;
		}
		
		private function createStarlingTextFromJsonData(obj:Object, context:AssetCreateContext):starling.display.DisplayObject {
			
			var textField:starling.text.TextField = new starling.text.TextField(10, 10, "");
			
			var setAlign:Boolean = false;
			
			var key:String;
			for (key in obj) {
				switch (key) {
					case "text": textField.text = obj.text; break;
					case "align": textField.hAlign = obj.align; setAlign = true; break;
					case "fontName": textField.fontName = obj.fontName; break;
					case "fontSize": textField.fontSize = obj.fontSize; break;
					case "color": textField.color = obj.color; break;
					case "bold": textField.bold = obj.bold; break;
					case "italic": textField.italic = obj.italic; break;
					case "underline": textField.underline = obj.underline; break;
					case "kerning": textField.kerning = obj.kerning; break;
					case "multiline": textField.multiline = obj.multiline; break;
					case "wordWrap": textField.wordWrap = obj.wordWrap; break;
					case "nativeFilters": textField.nativeFilters = createNativeFiltersFromJsonData(obj.nativeFilters, textField, context); break;
				}
			}
			
			if (!setAlign) 
				textField.hAlign = "left";
			
			setStarlingBasicDispObjDataFromJson(obj, textField);
			
			return textField;
		}		
		
		private function createStarlingObjectFromJsonData(obj:Object, context:AssetCreateContext):starling.display.DisplayObject {
			
			var objType:String = obj.type;
			var dispObj:starling.display.DisplayObject;
			
			switch (objType) {
				case "sprite":
					dispObj = createStarlingSpriteFromJsonData(obj, context);
					break;
				case "image":
					dispObj = createStarlingImageFromJsonData(obj, context);
					break;
				case "text":
					dispObj = createStarlingTextFromJsonData(obj, context);
					break;
				case "anim":
					dispObj = createStarlingAnimSpriteFromJsonData(obj, context);
					break;
			}
			
			if (dispObj == null) {
				throw new Error("Unknown object type: " + objType);
			}
			
			return dispObj;
		}
		
		/**
		 * Generates a new starling display graph instance of this asset.
		 *  
		 * <p>This method can be called any number of times to create a new starling display object graph.  This is directly equivalent to
		 * calling a new EmbeddedDisplayObjClass() with the old flash display system.</p>
		 * 
		 * @param symbolName			the symbol in this asset to create an instance of (or the "@root" root symbol by default).
		 * @param textureCache 			a cache dictionary for textures that are shared between multiple assets.
		 * 
		 * @return a new starling display graph for this asset.
		 */
		public function createInstance(symbolName:String = "@root", textureCache:Dictionary = null):starling.display.DisplayObject {
			
			var context:AssetCreateContext = new AssetCreateContext();
			context.fileVer = mLoadedFileVer;
			context.textureCache = textureCache != null ? textureCache : new Dictionary();
			context.referencedTextures = new Dictionary();
			
			var symObj:Object;
			if (symbolName == "@root") {
				symObj = mRootObject;
			} else {
				symObj = getSymbolInfo(symbolName);
				if (symObj == null) {
					throw new Error("No symbol named '" + symbolName + "' exists in asset '" + mName + "'");
				}
			}
			
			var dispObj:starling.display.DisplayObject = createStarlingObjectFromJsonData(symObj, context);
			
			var refTextures:Vector.<Texture> = new Vector.<Texture>();
			
			for each (var texture:starling.textures.Texture in context.referencedTextures) {
				texture.incRefCount();
				refTextures.push(texture);
			}
			
			dispObj.referencedTextures = refTextures;
			
			return dispObj;
		}
		
		/**
		 * Returns the animations that aren't supported
		 */
		public function getNotSupported():String {
			return notSupportedAnimations;
		}
		
	}
}

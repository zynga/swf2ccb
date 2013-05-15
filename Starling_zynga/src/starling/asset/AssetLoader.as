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
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	
	import starling.core.starling_internal;

	use namespace starling_internal;
	
	/**
	 * Class for loading assets.
	 */
	public class AssetLoader extends EventDispatcher
	{
		starling_internal var mAsset:Asset;
		starling_internal var mName:String;
		starling_internal var mAssetContext:AssetContext;
		starling_internal var mIsShared:Boolean = false;
		starling_internal var mAutoAtlas:Boolean = false;
		starling_internal var mSymbol:String;
		
		starling_internal var mLoadersActive:int;
		starling_internal var mLoadFailed:Boolean = false;
		
		starling_internal var mLoaderContext:LoaderContext;
		
		starling_internal static var sAssetPath:String = "app:/";
		
		public function AssetLoader()
		{
		}
		
		/** The current base asset path. */
		public function get assetPath():String {
			return sAssetPath;
		}
		
		/** The current base asset path. */
		public function set assetPath(value:String):void {
			sAssetPath = value;
		}
		
		/** The loader context used with this asset loader. */
		public function get loaderContext():LoaderContext {
			if (mLoaderContext == null) {
				mLoaderContext = new LoaderContext();
			}
			return mLoaderContext;
		}
		
		/** The loader context used with this asset loader. */
		public function set loaderContext(value:LoaderContext):void {
			mLoaderContext = value;
		}
		
		/** The asset context used when loading the asset. */
		public function get assetContext():AssetContext {
			return mAssetContext;
		}
		
		/** The asset context used when loading the asset. */
		public function set assetContext(value:AssetContext):void {
			mAssetContext = value;
		}
		
		/** True to place the loaded asset and it's textures in the shared assets cache in the asset context. */
		public function get isShared():Boolean {
			return mIsShared;
		}
		
		/** True to place the loaded asset and it's textures in the shared assets cache in the asset context.. */
		public function set isShared(value:Boolean):void {
			mIsShared = value;
		}
		
		/** True to cause images created from swf symbols to be automatically atlased. */
		public function get autoAtlas():Boolean {
			return mAutoAtlas;
		}
		
		/** True to cause images created from swf symbols to be automatically atlased. */
		public function set autoAtlas(value:Boolean):void {
			mAutoAtlas = value;
		}
		
		/** True if the loader is currently loading an asset. */
		public function get isLoading():Boolean {
			return mLoadersActive > 0;
		}
		
		private function makeUrl(baseUrl:String):String {
			if (baseUrl.indexOf("http:") == 0 || baseUrl.indexOf("file:") == 0) {
				return baseUrl;
			} else {
				return sAssetPath + baseUrl;
			}
		}
		
		private function makeName(url:String):String {
			var p1:int = url.lastIndexOf("/");
			if (p1 < 0)
				p1 = 0;
			else 
				p1++;
			var p2:int = url.indexOf(".", p1);
			if (p2 < 0)
				p2 = url.length;
			return url.substr(p1, p2 - p1);
		}
		
		/**
		 * Loads an asset from a swf asset file.
		 *  
		 * @param url		the url from which to load the asset.
		 * @param symbol	an optional symbol class name in the swf to load (defaults to the top level stage)
		 */
		public function loadSwf(url:String, symbol:String = null):void {
			
			mName = makeName(url);
			mSymbol = symbol;
			
			var loader:Loader = new Loader();
			
			var realUrl:String = makeUrl(url);
			
			loader.load(new URLRequest(realUrl), mLoaderContext);

			var l:LoadItem = new LoadItem(this, "swf", null, loader, loader.loaderInfo);
			mLoadersActive++;
		}		
		
		/**
		 * Loads an asset from a binary asset file.
		 *  
		 * @param url	the url from which to load the asset.
		 */
		public function loadBinary(url:String):void {
			
			mName = makeName(url);			
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			var realUrl:String = makeUrl(url);
			
			urlLoader.load(new URLRequest(realUrl));
			
			var l:LoadItem = new LoadItem(this, "binary", urlLoader, null, null);
			mLoadersActive++;
		}

		
		/**
		 * Loads an asset from a json asset file.
		 * 
		 * @param url	the url from which to load the asset.
		 */
		public function loadJson(url:String):void {

			mName = makeName(url);			
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			var realUrl:String = makeUrl(url);
			
			urlLoader.load(new URLRequest(realUrl));
			
			var l:LoadItem = new LoadItem(this, "json", urlLoader, null, null);
			mLoadersActive++;		
		}
		
		/**
		 * Load an asset from json data (causes all bitmaps referenced to be loaded).
		 *  
		 * @param jsonData the json data object to load.
		 */
		public function loadJsonData(jsonData:Object):void {

			// Check file version and flag error if it's invalid.
			if (jsonData.hasOwnProperty("fileVer") && jsonData.fileVer > Asset.ASSET_FILE_VER) {
				mLoadFailed = true;				
				this.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Invalid JSON file version"));
				return;
			}			
			
			var asset:Asset = Asset.fromJSON(jsonData, new Dictionary(), mAssetContext);
			
			var bitmaps:Object = jsonData.bitmaps;
			for (var bmName:String in bitmaps) {

				var bmInfo:Object = bitmaps[bmName];
				
				// Load any bitmap who's source is not another atlas texture.
				if (!bmInfo.hasOwnProperty("source")) {
					
					var loader:Loader = new Loader();
					var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
					
					var realUrl:String = makeUrl(bmInfo.name + ".png");
					
					loader.load(new URLRequest(realUrl), mLoaderContext);
					
					var pngLoadItem:PngBytesLoadItem = new PngBytesLoadItem(this, loader, loaderInfo, asset, bmInfo.name);
					mLoadersActive++;
				}
				
			}
			
			// No bitmaps to load.. we're done.
			if (mLoadersActive == 0 && !mLoadFailed) {
				mAsset = asset;
				this.dispatchEvent(new Event(Event.COMPLETE));
			}			
			
		}
		
		/**
		 * Loads an asset of any given type based on it's file extension (.swf, .star, or .json).
		 *  
		 * @param url		the url to load.
		 * @param symbol	for swf loading, an optional symbol class name in the swf to load (defaults to the top level stage).
		 */
		public function load(url:String, symbol:String = null):void {
			if (url.lastIndexOf(".swf") == url.length - 4)
				loadSwf(url, symbol);
			else if (url.lastIndexOf(".star") == url.length - 5)
				loadBinary(url);
			else if (url.lastIndexOf(".json") == url.length - 5)
				loadJson(url);
			else 
				throw new Error("Unknown asset file type for url '" + url + "'");
		}
		
		/**
		 * Loads a binary asset from a byte array.
		 *  
		 * @param bytes	the byte array from which to load the asset.
		 */
		public function loadBytes(buffer:ByteArray):void {
			
			buffer.endian = Endian.LITTLE_ENDIAN;
			
			buffer.position = 0;

			if (buffer.readByte() != 'S'.charCodeAt(0) ||
				buffer.readByte() != 'T'.charCodeAt(0) ||
				buffer.readByte() != 'A'.charCodeAt(0) ||
				buffer.readByte() != 'R'.charCodeAt(0)) {
				mLoadFailed = true;				
				this.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Not a STAR file"));
				return;
			}
			
			// Get the file version number (should be 1 right now).
			var version:uint = buffer.readUnsignedInt();
			if (version > Asset.ASSET_FILE_VER) {
				mLoadFailed = true;				
				this.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Invalid STAR file version"));
				return;
			}
			
			var jsonLen:uint = buffer.readUnsignedInt();
			
			// Get compressed json data
			var jsonArray:ByteArray = new ByteArray();
			jsonArray.writeBytes(buffer, buffer.position, jsonLen);
			buffer.position += jsonLen;
			
			jsonArray.inflate();
			var json:String = jsonArray.toString();
			
			var asset:Asset = Asset.fromJSON(JSON.parse(json), null, mAssetContext);
			
			var bmArray:ByteArray = new ByteArray();
			
			// Queue bitmaps for loading..
			var numBitmaps:int = buffer.readInt();
			for (var i:int = 0; i < numBitmaps; i++) {
				var bmName:String = buffer.readUTF();
				var bmType:int = buffer.readUnsignedInt(); // This will be 1 for png right now..  can add more types later.
				var bmSize:uint = buffer.readUnsignedInt();
				
				bmArray.clear();
				bmArray.writeBytes(buffer, buffer.position, bmSize);
				buffer.position += bmSize;
				
				var loader:Loader = new Loader();
				var loaderInfo:LoaderInfo = loader.contentLoaderInfo;				
				var loaderContext:LoaderContext = new LoaderContext();
				
				loader.loadBytes(bmArray, loaderContext);

				var pngLoadItem:PngBytesLoadItem = new PngBytesLoadItem(this, loader, loaderInfo, asset, bmName);
				mLoadersActive++;
				
			}			
			
			// No bitmaps to load.. we're done.
			if (mLoadersActive == 0 && !mLoadFailed) {
				mAsset = asset;
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
			
		}
		
		/** The asset that was loaded (if loading was successful). */
		public function get asset():Asset {
			return mAsset;
		}
	}
}

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.system.LoaderContext;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import org.osmf.events.LoaderEvent;

import starling.asset.Asset;
import starling.asset.AssetLoader;
import starling.core.starling_internal;

use namespace starling_internal;

internal class LoadItem {

	public var assetLoader:AssetLoader;
	public var loadType:String;
	public var asset:Asset;
	public var urlLoader:URLLoader;
	public var loader:Loader;
	public var loaderInfo:LoaderInfo;
	public var symbol:String;
	
	public function LoadItem(assetLoader:AssetLoader, loadType:String, urlLoader:URLLoader, loader:Loader, loaderInfo:LoaderInfo) {
		this.assetLoader = assetLoader;
		this.loadType = loadType;
		this.asset = asset;
		this.urlLoader = urlLoader;
		this.loader = loader;
		this.loaderInfo = loaderInfo
		
		if (urlLoader) {
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);		
			urlLoader.addEventListener(Event.COMPLETE, onLoadComplete);
		} else {
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
			loaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
		}
	}
	
	public function removeListeners():void {
		if (urlLoader) {
			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
			urlLoader.removeEventListener(Event.COMPLETE, onLoadComplete);
		} else {
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
			loaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);
		}
		assetLoader.mLoadersActive--;
	}	
	
	public function onLoadError(ev:Event):void {
		
		removeListeners();
		
		assetLoader.mLoadFailed = true;
		assetLoader.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Failed to load " + loadType));
	}
	
	public function onLoadComplete(ev:Event):void {

		removeListeners();
		
		if (loadType == "binary") {
		
			var bytes:ByteArray = ByteArray(ev.target.data);			
			assetLoader.loadBytes(bytes);
		
		} else if (loadType == "json") {
		
			var jsonBytes:ByteArray = ByteArray(ev.target.data);			
			var jsonStr:String = jsonBytes.toString();
			var jsonObj:Object = JSON.parse(jsonStr);
			
			assetLoader.loadJsonData(jsonObj);
		
		} else if (loadType == "swf") {
			
			var dispObj:DisplayObject = null;
			
			if (assetLoader.mSymbol != null) {
				try {
					var cl:Class = loaderInfo.applicationDomain.getDefinition(assetLoader.mSymbol) as Class;
					dispObj = new cl();
				} catch (e:Error) {
				}
			} else {
				dispObj = loaderInfo.content;
			}

			try {
				assetLoader.mAsset = Asset.fromDisplayObject(dispObj, assetLoader.mName, assetLoader.mAssetContext, assetLoader.mIsShared, assetLoader.mAutoAtlas);
				loader.unloadAndStop(true);
			} catch (e:Error) {
			}
			
			if (assetLoader.mAsset != null && !assetLoader.mLoadFailed) {
				assetLoader.dispatchEvent(new Event(Event.COMPLETE));
			} else {
				assetLoader.mLoadFailed = true;
				assetLoader.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
			}
		}
		
	}
	
}

internal class PngBytesLoadItem {
	
	public var assetLoader:AssetLoader;
	public var loader:Loader;
	public var loaderInfo:LoaderInfo;
	public var asset:Asset;
	public var bmName:String;
	public var bitmaps:Dictionary;
	
	public function PngBytesLoadItem(assetLoader:AssetLoader, loader:Loader, loaderInfo:LoaderInfo, asset:Asset, bmName:String) {
		this.assetLoader = assetLoader;
		this.loader = loader;
		this.loaderInfo = loaderInfo;
		this.asset = asset;
		this.bmName = bmName;
		loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
		loaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);		
	}
	
	public function removeListeners():void {
		loader.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadError);
		loaderInfo.removeEventListener(Event.COMPLETE, onLoadComplete);		
		assetLoader.mLoadersActive--;
	}
	
	public function onLoadError(ev:Event):void {
		
		removeListeners();

		assetLoader.mLoadFailed = true;
		assetLoader.dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, "Failed to load image " + bmName));
	}
	
	public function onLoadComplete(ev:Event):void {
		
		const loaderInfo:LoaderInfo = LoaderInfo(ev.target);

		removeListeners();
		
		var bitmap:Bitmap = loaderInfo.content as Bitmap;
		var bmData:BitmapData = bitmap.bitmapData;
		asset.addBitmapData(bmName, bmData);
		if (assetLoader.mLoadersActive == 0 && !assetLoader.mLoadFailed) {
			assetLoader.mAsset = asset;
			assetLoader.dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}

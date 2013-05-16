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

package
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.utils.ByteArray;

	public class CCBWriter
	{
		private static var ipodHeight:int = 320;
		
		private static var templateCCBStart:String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n" + 
			"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> \n" + 
			"<plist version=\"1.0\"> \n" + 
			"<dict> \n" + 
			"	<key>centeredOrigin</key> \n" + 
			"	<false/> \n" + 
			"	<key>currentResolution</key> \n" + 
			"	<integer>0</integer> \n" + 
			"	<key>fileType</key> \n" + 
			"	<string>CocosBuilder</string> \n" + 
			"	<key>fileVersion</key> \n" + 
			"	<integer>4</integer> \n" + 
			"	<key>guides</key> \n" + 
			"	<array/> \n" + 
			"	<key>nodeGraph</key> \n" + 
			"	<dict> \n" + 
			"		<key>baseClass</key> \n" + 
			"		<string>CCNode</string> \n" + 
			"		<key>children</key> \n";
		
		private static var customClass:String = "\n		<key>customClass</key> \n" + 
			"		<string></string> \n" + 
			"		<key>displayName</key> \n" + 
			"		<string>CCNode</string> \n" + 
			"		<key>memberVarAssignmentName</key> \n" + 
			"		<string></string> \n" + 
			"		<key>memberVarAssignmentType</key> \n" + 
			"		<integer>0</integer> \n" + 
			"		<key>properties</key> \n" + 
			"		<array> \n" + 
			"			<dict> \n" + 
			"				<key>name</key> \n" +
			"				<string>anchorPoint</string> \n" + 
			"				<key>type</key> \n" + 
			"				<string>Point</string> \n" + 
			"				<key>value</key> \n" + 
			"				<array> \n" + 
			"					<real>0.0</real> \n" + 
			"					<real>0.0</real> \n" + 
			"				</array> \n" + 
			"			</dict> \n" + 
			"			<dict> \n" + 
			"				<key>name</key> \n" + 
			"				<string>scale</string> \n" + 
			"				<key>type</key> \n" + 
			"				<string>ScaleLock</string> \n" + 
			"				<key>value</key> \n" + 
			"				<array> \n" + 
			"					<real>1</real> \n" + 
			"					<real>1</real> \n" + 
			"					<false/> \n" + 
			"					<integer>0</integer> \n" + 
			"				</array> \n" + 
			"			</dict> \n" + 
			"			<dict> \n" + 
			"				<key>name</key> \n" + 
			"				<string>ignoreAnchorPointForPosition</string> \n" + 
			"				<key>type</key> \n" + 
			"				<string>Check</string> \n" + 
			"				<key>value</key> \n" + 
			"				<false/> \n" + 
			"			</dict> \n" + 
			"		</array> \n" + 
			"	</dict> \n" + 
			"	<key>notes</key> \n" + 
			"	<array/> \n" + 
			"	<key>resolutions</key> \n" + 
			"	<array> \n" + 
			"		<dict> \n" + 
			"			<key>centeredOrigin</key> \n" + 
			"			<false/> \n" + 
			"			<key>ext</key> \n" + 
			"			<string> </string> \n" + 
			"			<key>height</key> \n" + 
			"			<integer>0</integer> \n" + 
			"			<key>name</key> \n" + 
			"			<string>iPhone</string> \n" + 
			"			<key>scale</key> \n" + 
			"			<real>1</real> \n" + 
			"			<key>width</key> \n" + 
			"			<integer>0</integer> \n" + 
			"		</dict> \n" + 
			"	</array> \n" + 
			"	<key>sequences</key>\n" +
			"	<array>\n" +
			"		<dict>\n" +
			"			<key>autoPlay</key>\n" +
			"			<true/>\n" +
			"			<key>chainedSequenceId</key>\n" +
			"			<integer>-1</integer>\n" +
			"			<key>length</key>\n			<real>";
		private static var b4TimelineName:String = "</real>\n			<key>name</key>\n			<string>";
		private static var templateCCBEnd:String = "</string>\n" +
			"			<key>offset</key>\n" +
			"			<real>0.0</real>\n" +
			"			<key>position</key>\n" +
			"			<real>0.0</real>\n" +
			"			<key>resolution</key>\n" +
			"			<real>30</real>\n" +
			"			<key>scale</key>\n" +
			"			<real>128</real>\n" +
			"			<key>sequenceId</key>\n" +
			"			<integer>0</integer>\n" +
			"		</dict>\n" +
			"	</array>\n" + 
			"	<key>stageBorder</key> \n" + 
			"	<integer>3</integer> \n" +
			"</dict> \n" + 
			"</plist> ";
		
		private static var templateSpriteChildStartList:String = "	<array>\n "; 
		private static var templateSpriteChildStart:String =  "		<dict>\n ";
		private static var templateSpriteChildAfterAnimation:String = "			<key>baseClass</key>\n				<string>";
		private static var templateSpriteChildAfterType:String = "</string>\n				<key>children</key>\n"; 
			 
		private static var templateSpriteChildB4DisplayName:String = "			<key>customClass</key>\n		<string></string>\n " + 
			"		<key>displayName</key>\n " + 
			"		<string>";
		private static var templateSpriteChildB4Properties:String = "</string>\n " + 
			"		<key>memberVarAssignmentName</key>\n " + 
			"		<string></string>\n " + 
			"		<key>memberVarAssignmentType</key>\n " + 
			"		<integer>0</integer>\n " + 
			"		<key>usesFlashSkew</key>\n" +
			"		<true/>\n" + 
			"		<key>properties</key>\n " + 
			"		<array>\n ";
		
		private static var propertyEntryStart:String = "			<dict>\n ";
		private static var propertyB4BaseVal:String = "				<key>baseValue</key>\n ";
		private static var propertyBeforeName:String = "				<key>name</key>\n " + 
			"				<string>";
		private static var propertyAfterPropName:String = "</string>\n " + 
			"				<key>type</key>\n " + 
			"				<string>";
		private static var propertyAfterPropType:String = "</string>\n " + 
			"				<key>value</key>\n ";
		private static var propertyEntryEnd:String = "			</dict>\n "; 
		private static var templateSpriteChildB4AnchorPoint:String = "			<dict>\n " + 
			"				<key>name</key>\n " + 
			"				<string>anchorPoint</string>\n " + 
			"				<key>type</key>\n " + 
			"				<string>Point</string>\n " + 
			"				<key>value</key>\n " + 
			"				<array>\n " + 
			"					<real>";
		private static var templateSpriteChildEndAnchorPoint:String = "</real>\n				</array>\n " + 
			"			</dict>\n ";
		private static var templateSpriteChildIgnoreAnchor:String = "			<dict>\n " + 
			"				<key>name</key>\n " + 
			"				<string>ignoreAnchorPointForPosition</string>\n " + 
			"				<key>type</key>\n " + 
			"				<string>Check</string>\n " + 
			"				<key>value</key>\n " + 
			"				<false/>\n " + 
			"			</dict>\n ";
		private static var defaultScale:String = "			<dict>\n " + 
			"				<key>name</key>\n " + 
			"				<string>scale</string>\n " + 
			"				<key>type</key>\n " + 
			"				<string>ScaleLock</string>\n " + 
			"				<key>value</key>\n " + 
			"				<array>\n " + 
			"					<real>1</real>\n " + 
			"					<real>1</real>\n " + 
			"					<false/>\n " + 
			"					<integer>0</integer>\n " + 
			"				</array>\n " + 
			"			</dict>\n ";
		private static var defaultSkew:String = "			<dict>\n " + 
			"				<key>name</key>\n " + 
			"				<string>skew</string>\n " + 
			"				<key>type</key>\n " + 
			"				<string>FloatXY</string>\n " + 
			"				<key>value</key>\n " + 
			"				<array>\n " + 
			"					<real>0.0</real>\n " + 
			"					<real>0.0</real>\n " + 
			"				</array>\n " + 
			"			</dict>\n ";
		private static var templateSpriteChildB4Bitmap:String = "			<dict>\n " + 
			"				<key>name</key>\n " + 
			"				<string>displayFrame</string>\n " + 
			"				<key>type</key>\n " + 
			"				<string>SpriteFrame</string>\n " + 
			"				<key>value</key>\n " + 
			"				<array>\n " + 
			"					<string></string>\n " + 
			"					<string>";
		
		private static var templateSpriteChildAfterBitmap:String = "</string>\n " + 
			"				</array>\n " + 
			"			</dict>\n ";
		
		private static var templateSpriteChildEnd:String = "		</array>\n " + 
			"		<key>selected</key>\n " + 
			"		<true/>\n " + 
			"	</dict>\n ";
		
		private static var templateSpriteChildEndList:String = "</array>";
		
		private static var noChildren:String = "			<array/> \n";
		
		private static var animsStart:String = "<key>animatedProperties</key> \n" + 
			"<dict> \n" + 
			"	<key>0</key> \n" + 
			"	<dict> \n";
		private static var animB4Key:String = "		<key>";
		private static var animAfterKey:String = "</key> \n" + 
			"		<dict> \n" + 
			"			<key>keyframes</key> \n";
		private static var animStartArray:String = "			<array> \n";
		private static var animFrameStart:String = "				<dict> \n" + 
			"					<key>easing</key> \n" + 
			"					<dict> \n" + 
			"						<key>type</key> \n" + 
			"						<integer>1</integer> \n" + 
			"					</dict> \n" + 
			"					<key>name</key> \n" + 
			"					<string>";
		private static var animFrameBeforeTime:String = "</string> \n" + 
			"					<key>time</key> \n" + 
			"					<real>";
		private static var animFrameAfterTime:String = "</real> \n" + 
			"					<key>type</key> \n" + 
			"					<integer>";
		private static var animFrameAfterTypeNum:String = "</integer> \n" + 
			"					<key>value</key> \n";
		
		private static var b4Real:String = "						<real>";
		private static var afterReal:String = "</real> \n";
		private static var b4Int:String = "						<integer>";
		private static var afterInt:String = "</integer> \n";
		private static var b4RealArray:String = "					<array> \n" + 
			"						<real>";
		private static var afterArray:String = "					</array> \n";
		private static var animFrameEnd:String = "				</dict> \n";
		private static var animB4Type:String = "			</array> \n" + 
			"			<key>name</key> \n" + 
			"			<string>";
		private static var animAfterType:String = "</string> \n" + 
			"			<key>type</key> \n" + 
			"			<integer>";
		private static var animTypeEnd:String = "</integer> \n		</dict> \n";
		private static var animEnd:String = "	</dict>\n</dict>";
		
		private static var betweenRealVals:String = "</real>\n 					<real>";
		private static var posType:String = "<integer>5</integer> \n";
		private static var symbols:Object;
		private static var bitmaps:Object;
		private static var xOrigin:int = 0;
		private static var yOrigin:int = 0;
		private static var curTotalFrames:int = 0;
		private static var mBMPath:String;
		private static var mScaleAll:Number;
		private static var mBitmapScale:Number;
		private static var mFps:Number = 30.0;
		
		public static function writeCCB(json:Object, filename:String, basePath:String, bmPath:String, bitmapScale:Number, smallestSize:Number):void {
			var byteArray:ByteArray = new ByteArray();
			
			symbols = json.symbols;
			bitmaps = json.bitmaps;
			mBMPath = bmPath;
			mScaleAll = smallestSize;
			mBitmapScale = bitmapScale;
			
			var rootSymbol:Object = symbols[filename];
			var outputCCB:String = templateCCBStart.slice();
			
			if (rootSymbol) {
				for (var i:int = 0; i < rootSymbol.children.length; i++) {
					var child:Object = rootSymbol.children[i];
					writeCCB4Symbols(child, basePath);
				}
			}
			else {
				outputCCB += noChildren;
			
				outputCCB += templateCCBEnd;
				
				byteArray.writeUTFBytes(outputCCB);
				var filePath:String = basePath + filename + ".ccb";
				var fname:File = new File(filePath);
				var fstrm:FileStream = new FileStream();
				try {
					fstrm.open(fname, FileMode.WRITE);
					fstrm.writeBytes(byteArray);
					fstrm.close();
				} catch (e:Error) {
					trace("Unable to save ccb file '" + filePath + "': " + e.message);
				}
			}
			
		}
		
		private static var curFile:String;
		
		private static function writeCCB4Symbols(symbol:Object, basePath:String):void {
			var byteArray:ByteArray = new ByteArray();
			var outputCCB:String = templateCCBStart.slice();
			var fileName:String;
			
			curTotalFrames = symbol.totalFrames;
			fileName = symbol.symbolName;
			curFile = fileName;
			symbol.x = xOrigin;
			symbol.y = yOrigin;
			
			outputCCB += templateSpriteChildStartList;
			outputCCB += dfsTraverse(symbol, basePath, null, true);
			outputCCB += templateSpriteChildEndList;
			
			outputCCB += customClass;
			if (curTotalFrames > 0) {
				outputCCB += (curTotalFrames+1)/30;
			}
			else {
				outputCCB += 10;
			}
			outputCCB += b4TimelineName;
			outputCCB += fileName;
			outputCCB += templateCCBEnd;
			byteArray.writeUTFBytes(outputCCB);
			var filePath:String;
			
			if (symbol.symbolName) {
				filePath = basePath + symbol.symbolName + ".ccb";
			}
			else {
				filePath = basePath + symbol.name + ".ccb";
			}
			
			var fname:File = new File(filePath);
			var fstrm:FileStream = new FileStream();
			try {
				fstrm.open(fname, FileMode.WRITE);
				fstrm.writeBytes(byteArray);
				fstrm.close();
			} catch (e:Error) {
				trace("Unable to save ccb file '" + filePath + "': " + e.message);
			}			
		}
		
		private static function dfsTraverse(obj:Object, basePath:String, anims:Object = null, useBottomLeft:Boolean=false):String {
			var ret:String = templateSpriteChildStart.slice();
			var childAnims:Object = obj.anims;
			var x:Number;
			var y:Number;
			var skewX:Number;
			var skewY:Number;
			var scaleX:Number;
			var scaleY:Number;
			var childBMName:String;
			var childPivotX:Number;
			var childPivotY:Number;
			
			var bmName:String;
			var pivotX:Number;
			var pivotY:Number;
			var origCurFrames:int;
			var isFile:Boolean = false;
			var flipYPivot:Boolean = false;
			
			if (obj.totalFrames && (obj.totalFrames != curTotalFrames && obj.totalFrames > 1) && obj.symbolName && obj.symbolName != curFile) {
				origCurFrames = curTotalFrames;
				writeCCB4Symbols(obj, basePath);
				curTotalFrames = origCurFrames;
				isFile = true;
			}
			
			if (obj.symbolName && symbols[obj.symbolName].children && symbols[obj.symbolName].children.length == 1) {
				childBMName = symbols[obj.symbolName].children[0].bitmapName;
				
				if (!symbols[obj.symbolName].children[0].x && symbols[obj.symbolName].children[0].pivotX) {
					childPivotX = symbols[obj.symbolName].children[0].pivotX;
				}
				
				if (!symbols[obj.symbolName].children[0].y && symbols[obj.symbolName].children[0].pivotY) {
					childPivotY = symbols[obj.symbolName].children[0].pivotY;
				}
				else if (!symbols[obj.symbolName].children[0].x && symbols[obj.symbolName].children[0].pivotY) {
					childPivotY = symbols[obj.symbolName].children[0].pivotY;
					
					flipYPivot = true;
				}
			}
			else if (obj.children && obj.children.length == 1) {
				childBMName = obj.children[0].bitmapName;
				
				if (!obj.children[0].x && obj.children[0].pivotX) {
					childPivotX = obj.children[0].pivotX;
				}
				
				if (!obj.children[0].y && obj.children[0].pivotY) {
					childPivotY = obj.children[0].pivotY;
				}
				else if (!obj.children[0].x && obj.children[0].pivotY) {
					childPivotY = obj.children[0].pivotY;
					flipYPivot = true;
				}
			}
			
			if (obj.x) {
				x = obj.x;
			}
			else {
				x = 0;
			}
			
			if (obj.y) {
				y = obj.y;
			}
			else {
				y = 0;
			}
			
			if (obj.skewX) {
				skewX = obj.skewX;
			}
			else {
				skewX = 0;
			}
			
			if (obj.skewY) {
				skewY = obj.skewY;
			}
			else {
				skewY = 0;
			}
			
			if (obj.scaleX) {
				scaleX = obj.scaleX;
			}
			else {
				scaleX = 0;
			}
			
			if (obj.scaleY) {
				scaleY = obj.scaleY;
			}
			else {
				scaleY = 0;
			}
			
			var CCType:String;
			if (childBMName) {
				CCType = "CCSprite";
			}
			else if (obj.symbolName && symbols[obj.symbolName].bitmapName) {
				bmName = symbols[obj.symbolName].bitmapName;
				
				if (symbols[obj.symbolName].pivotX) {
					pivotX = symbols[obj.symbolName].pivotX;
				}
				
				if (symbols[obj.symbolName].pivotY) {
					pivotY = symbols[obj.symbolName].pivotY;
				}
				
				CCType = "CCSprite";
			}
			else if (obj.bitmapName) {
				bmName = obj.bitmapName;
				
				if (obj.pivotX) {
					pivotX = obj.pivotX;
				}
				
				if (obj.pivotY) {
					pivotY = obj.pivotY;
				}
				
				CCType = "CCSprite";
			}
			else if (isFile) {
				CCType = "CCBFile";
			}
			else {
				CCType = "CCNode";
				childBMName = "";
			}
			
//			if (CCType == "CCSprite" && !anims) {
//				return "";
//			}
			
			if (childBMName && anims == null && obj.anims) {
				anims = obj.anims[0]["tracks"];
			}
			
			var animString:String = getAnimString(anims, CCType);
			ret += animString + templateSpriteChildAfterAnimation + CCType + templateSpriteChildAfterType;
			
			var animIndex:int = 0;
			
			if (obj.symbolName) {
				obj = symbols[obj.symbolName];
			}
			
			if (obj.children && obj.children.length > 0 && childBMName == "" && CCType != "CCBFile") {
				ret += templateSpriteChildStartList;
				for (var i:int = 0; i < obj.children.length; i++) {
					var child:Object = obj.children[i];
					if (childAnims && childAnims[animIndex] && childAnims[animIndex]["child"] == i) {
						ret += dfsTraverse(child, basePath, childAnims[animIndex]["tracks"]);
						animIndex++;
					}
					else {
						ret += dfsTraverse(child, basePath);
					}
				}
				
				ret += templateSpriteChildEndList;
			}
			else {
				ret += noChildren;
			}
			
			if (!obj.name) {
				trace("");
			}
			
			ret += templateSpriteChildB4DisplayName + obj.name;
			ret += templateSpriteChildB4Properties + getPropString(anims, x, y, scaleX, scaleY, skewX, skewY, CCType, useBottomLeft);
			
			if (CCType != "CCBFile") {
				ret += templateSpriteChildB4AnchorPoint;
			
				if (childBMName) {
					if (childPivotX) {
						ret += childPivotX/bitmaps[childBMName]["width"] + betweenRealVals;
					}
					else {
						ret += 0.0 + betweenRealVals;
					}
					
					if (childPivotY) {
						if (flipYPivot) {
							ret += childPivotY/bitmaps[childBMName]["height"];
						}
						else {
							ret += (1- childPivotY/bitmaps[childBMName]["height"]);
						}
					}
					else { 
						ret += 1.0;
					}
				}
				else if (bmName) {
					if (pivotX) {
						ret += pivotX/bitmaps[bmName]["width"] + betweenRealVals;
					}
					else {
						ret += 0.0 + betweenRealVals;
					}
					
					if (pivotY) {
						ret += (1- pivotY/bitmaps[bmName]["height"]);
					}
					else { 
						ret += 1.0;
					}
				}
				else {
					ret += 0.0 + betweenRealVals + 1.0;
				}
				ret += templateSpriteChildEndAnchorPoint;
				ret += templateSpriteChildIgnoreAnchor;
			}
			
			if (CCType == "CCSprite") {
				if (childBMName) {
					if (mBMPath) {
						childBMName = mBMPath + childBMName + ".png";
					}
					else {
						childBMName = childBMName + ".png";
					}
					
					ret += templateSpriteChildB4Bitmap + childBMName + templateSpriteChildAfterBitmap;
				}
				else {
					if (mBMPath) {
						bmName = mBMPath + bmName + ".png";
					}
					else {
						bmName = bmName + ".png";
					}
					
					ret += templateSpriteChildB4Bitmap + bmName + templateSpriteChildAfterBitmap;
				}
			}
			
			if (CCType == "CCBFile") {
				ret += importFile;
				ret += obj.name;
				ret += endFileEntry;
			}
			
			ret += templateSpriteChildEnd;
			
			return ret;
		}
		
		private static var importFile:String = "					<dict> \n"+
			"						<key>name</key> \n"+
			"						<string>ccbFile</string> \n"+
			"						<key>type</key> \n"+
			"						<string>CCBFile</string> \n"+
			"						<key>value</key> \n"+
			"						<string>";
		private static var endFileEntry:String = ".ccb</string> \n					</dict>";
		
		private static function getPropString(anims:Object, x:Number, y:Number, scaleX:Number, scaleY:Number, skewX:Number, skewY:Number, CCType:String, isRootSymbol:Boolean=false):String {
			var ret:String = propertyEntryStart.slice();
			if (anims) {
				ret += propertyB4BaseVal;
				ret += b4RealArray;
				ret += anims["x"]["start"]["values"][0] + betweenRealVals + (-1*anims["y"]["start"]["values"][0]);
				ret += afterReal + posType + afterArray;
				ret += propertyBeforeName;
				ret += "position";
				ret += propertyAfterPropName;
				ret += "Position";
				ret += propertyAfterPropType;
				ret += b4RealArray;
				ret += anims["x"]["start"]["values"][0] + betweenRealVals + (-1*anims["y"]["start"]["values"][0]);
				ret += afterReal + posType + afterArray;
				ret += propertyEntryEnd;
				
				ret += propertyEntryStart;
				ret += propertyB4BaseVal;
				ret += b4RealArray;
				if (CCType == "CCSprite") {
					ret += mBitmapScale*anims["scaleX"]["start"]["values"][0] + betweenRealVals + mBitmapScale*anims["scaleY"]["start"]["values"][0];
					ret += afterReal + "<false/> \n" + afterArray;
				}
				else {
					ret += anims["scaleX"]["start"]["values"][0] + betweenRealVals + anims["scaleY"]["start"]["values"][0];
					ret += afterReal  + "<false/> \n" + afterArray;
				}
				ret += propertyBeforeName;
				ret += "scale";
				ret += propertyAfterPropName;
				ret += "ScaleLock";
				ret += propertyAfterPropType;
				ret += b4RealArray;
				if (CCType == "CCSprite") {
					ret += mBitmapScale*anims["scaleX"]["start"]["values"][0] + betweenRealVals + mBitmapScale*anims["scaleY"]["start"]["values"][0];
					ret += afterReal + "<false/> \n" + afterArray;
				}
				else {
					ret += anims["scaleX"]["start"]["values"][0] + betweenRealVals + anims["scaleY"]["start"]["values"][0];
					ret += afterReal  + "<false/> \n" + afterArray;
				}
				ret += propertyEntryEnd;
				
				ret += propertyEntryStart;
				ret += propertyBeforeName;
				ret += "visible";
				ret += propertyAfterPropName;
				ret += "Check";
				ret += propertyAfterPropType;
				if (anims["visible"]["start"]["values"][0]) {
					ret += "						<true/>\n";
				}
				else {
					ret += "						<false/>\n";
				}
				ret += propertyEntryEnd;
				
				ret += propertyEntryStart;
				ret += propertyB4BaseVal;
				ret += b4Real;
				ret += anims["skewX"]["start"]["values"][0] * 180.0/Math.PI;
				ret += afterReal;
				ret += propertyBeforeName;
				ret += "rotationX";
				ret += propertyAfterPropName;
				ret += "Degrees";
				ret += propertyAfterPropType;
				ret += b4Real;
				ret += anims["skewX"]["start"]["values"][0] * 180.0/Math.PI;
				ret += afterReal;
				ret += propertyEntryEnd;
				
				ret += propertyEntryStart;
				ret += propertyB4BaseVal;
				ret += b4Real;
				ret += anims["skewY"]["start"]["values"][0] * 180.0/Math.PI;
				ret += afterReal;
				ret += propertyBeforeName;
				ret += "rotationY";
				ret += propertyAfterPropName;
				ret += "Degrees";
				ret += propertyAfterPropType;
				ret += b4Real;
				ret += anims["skewY"]["start"]["values"][0] * 180.0/Math.PI;
				ret += afterReal;
				ret += propertyEntryEnd;
				
				if (CCType == "CCSprite") {
					ret += propertyEntryStart;
					ret += propertyB4BaseVal;
					ret += b4Real;
					if (anims["alpha"]["start"]["values"][0] == 0) {
						ret += 0;
					}
					else {
						ret += anims["alpha"]["start"]["values"][0]*256-1;
					}
					ret += afterReal;
					ret += propertyBeforeName;
					ret += "opacity";
					ret += propertyAfterPropName;
					ret += "Byte";
					ret += propertyAfterPropType;
					ret += b4Real;
					if (anims["alpha"]["start"]["values"][0] == 0) {
						ret += 0;
					}
					else {
						ret += anims["alpha"]["start"]["values"][0]*256-1;
					}
					ret += afterReal;
					ret += propertyEntryEnd;
				}
			}
			else {
				ret += propertyBeforeName;
				ret += "position";
				ret += propertyAfterPropName;
				ret += "Position";
				ret += propertyAfterPropType;
				ret += b4RealArray;
				if (CCType && CCType == "CCSprite") {
					ret += x + betweenRealVals + (-1*y);
				}
				else {
					ret += x + betweenRealVals + y;
				}
				if (isRootSymbol) {
					ret += afterReal +  "<integer>0</integer> \n" + afterArray;
				}
				else {
					ret += afterReal +  posType + afterArray;
				}
				ret += propertyEntryEnd
				
				ret += "			<dict>\n " + 
					"				<key>name</key>\n " + 
					"				<string>scale</string>\n " + 
					"				<key>type</key>\n " + 
					"				<string>ScaleLock</string>\n " + 
					"				<key>value</key>\n " + 
					"				<array>\n " + 
					"					<real>";
				if (CCType == "CCSprite") {
					ret += scaleX*mBitmapScale + "</real>\n " +
						"					<real>" + scaleY*mBitmapScale;
				}
				else if (isRootSymbol) {
					ret += 1/mScaleAll + "</real>\n " +
						"					<real>" + 1/mScaleAll;
				}
				else if (CCType == "CCBFile") {
					ret += 1 + "</real>\n " +
						"					<real>" + 1;
				}
				else {
					ret += scaleX + "</real>\n " +
						"					<real>" + scaleY;
				}
				ret += "</real>\n " + 
				"					<false/>\n " + 
				"					<integer>0</integer>\n " + 
				"				</array>\n " + 
				"			</dict>\n ";
				
				ret += propertyEntryStart;
				ret += propertyB4BaseVal;
				ret += b4Real;
				ret += skewX * 180.0/Math.PI;
				ret += afterReal;
				ret += propertyBeforeName;
				ret += "rotationX";
				ret += propertyAfterPropName;
				ret += "Degrees";
				ret += propertyAfterPropType;
				ret += b4Real;
				ret += skewX * 180.0/Math.PI;
				ret += afterReal;
				ret += propertyEntryEnd;
				
				ret += propertyEntryStart;
				ret += propertyB4BaseVal;
				ret += b4Real;
				ret += skewY * 180.0/Math.PI;
				ret += afterReal;
				ret += propertyBeforeName;
				ret += "rotationY";
				ret += propertyAfterPropName;
				ret += "Degrees";
				ret += propertyAfterPropType;
				ret += b4Real;
				ret += skewY* 180.0/Math.PI;
				ret += afterReal;
				ret += propertyEntryEnd;
			}
			
			return ret;
		}
		
		private static function getAnimString(anims:Object, CCType:String):String {
			if (anims) {
				var ret:String = animsStart.slice();
				
				if (CCType == "CCSprite") {
					ret += opacityAnimString(anims["alpha"]);
				}
				
				ret += getXYAnimString(anims["x"], anims["y"], "position", CCType);

				ret += skewAnimString(anims["skewX"], "x");
				
				ret += skewAnimString(anims["skewY"], "y");
				
				ret += getXYAnimString(anims["scaleX"], anims["scaleY"], "scale", CCType);
				
				ret += visibleAnimString(anims["visible"]);
				
				ret += animEnd;
				
				return ret;
			}
			else {
				return "";
			}
		}
		
		private static function opacityAnimString(tracks:Object):String {
			var ret:String = "";
			
			ret += animB4Key;
			ret += "opacity";
			ret += animAfterKey ;
			ret += animStartArray;
			
			ret += animFrameStart;
			ret += "opacity";
			ret += animFrameBeforeTime;
			ret += "0.0";
			ret += animFrameAfterTime;
			ret += "5";
			ret += animFrameAfterTypeNum;
			ret += b4Int;
			if (tracks["end"]["values"][i] == 0) {
				ret += 0;
			}
			else {
				ret += tracks["end"]["values"][i]*256-1;
			}
			ret += afterInt;
			ret += animFrameEnd;
			
			for (var i:int = 0; i < tracks["start"]["values"].length; i++) {
				
				ret += animFrameStart;
				ret += "opacity";
				ret += animFrameBeforeTime;
				
				if (tracks["end"]["frames"][i] > curTotalFrames) {
					ret += "" + (curTotalFrames+1) / mFps;
				}
				else {
					ret += "" + (tracks["end"]["frames"][i]-1) / mFps;
				}
				ret += animFrameAfterTime;
				ret += "5";
				ret += animFrameAfterTypeNum;
				ret += b4Int;
				if (tracks["end"]["values"][i] == 0) {
					ret += 0;
				}
				else {
					ret += tracks["end"]["values"][i]*256-1;
				}
				ret += afterInt;
				ret += animFrameEnd;
				
				if (tracks["end"]["frames"][i] > curTotalFrames) {
					break;
				}
			}
			
			ret += animB4Type;
			ret += "opacity";
			ret += animAfterType;
			ret += "5";
			ret += animTypeEnd;
			
			return ret;
		}
		
		private static var typeNums:Object = {position: 3, scale: 4};
		
		private static function getXYAnimString(xTracks:Object, yTracks:Object, type:String, CCType:String=null):String {
			
			var xIndex:int = 0;
			var yIndex:int = 0;
			var curStartFrame:int = 0;
			var curEndFrame:int = 0;
			
			var prevX:int = xTracks["start"]["values"][0];
			var prevY:int = yTracks["start"]["values"][0];
			
			var ret:String = "";
			
			var frames:Vector.<int> = new Vector.<int>();
			
			ret += animB4Key;
			ret += type;
			ret += animAfterKey ;
			ret += animStartArray;
			
			ret += animFrameStart;
			ret += type;
			ret += animFrameBeforeTime;
			ret += "0.0";
			ret += animFrameAfterTime;
			ret += typeNums[type]
			ret += animFrameAfterTypeNum;
			ret += b4RealArray;
			if (type == "position") {
				ret += xTracks["start"]["values"][0] + betweenRealVals + (-1*yTracks["start"]["values"][0]);
			}
			else {
				if (CCType && CCType == "CCSprite") {
					ret += mBitmapScale*xTracks["start"]["values"][0] + betweenRealVals + mBitmapScale*yTracks["start"]["values"][0];
				}
				else {
					ret += xTracks["start"]["values"][0] + betweenRealVals + yTracks["start"]["values"][0];
				}
			}
			
			if (type == "position") {
				ret += afterReal + posType + afterArray;
			}
			else {
				ret += afterReal + afterArray;
			}
			ret += animFrameEnd;
			
			while( xIndex < xTracks["start"]["values"].length || yIndex < yTracks["start"]["values"].length) {
				
				var curX:Number;
				var curY:Number;
				var nextX:Number;
				var nextY:Number;
				
				var valXPrevFrame:Number;
				var valYPrevFrame:Number;
				
				if (xTracks["end"]["frames"][xIndex] == yTracks["end"]["frames"][yIndex]) {
					curEndFrame = yTracks["end"]["frames"][yIndex];
					curY = yTracks["end"]["values"][yIndex];
					curX = xTracks["end"]["values"][xIndex];
					
					if (curEndFrame == xTracks["start"]["frames"][xIndex]) {
						valXPrevFrame = xTracks["end"]["values"][yIndex-1];
					}
					else {
						valXPrevFrame = xTracks["start"]["values"][xIndex] + (xTracks["end"]["values"][xIndex] - xTracks["start"]["values"][xIndex]) / (xTracks["end"]["frames"][xIndex] - xTracks["start"]["frames"][xIndex]) * (curEndFrame - 1 - xTracks["start"]["frames"][xIndex]);
					}
					
					if (curEndFrame == yTracks["start"]["frames"][yIndex]) {
						valYPrevFrame = yTracks["end"]["values"][yIndex-1];
					}
					else {
						valYPrevFrame = yTracks["start"]["values"][yIndex] + (yTracks["end"]["values"][yIndex] - yTracks["start"]["values"][yIndex]) / (yTracks["end"]["frames"][yIndex] - yTracks["start"]["frames"][yIndex]) * (curEndFrame - 1 - yTracks["start"]["frames"][yIndex]);
					}
					
					yIndex++;
					xIndex++;
					if (xIndex < xTracks["start"]["values"].length) {
						nextX = xTracks["start"]["values"][xIndex];
					}
					else {
						nextX = xTracks["end"]["values"][xIndex-1];
					}
					if(yIndex < yTracks["start"]["values"].length) {
						nextY = yTracks["start"]["values"][yIndex];
					}
					else {
						nextY = yTracks["end"]["values"][yIndex-1];
					}
				}
				else if (xIndex == xTracks["start"]["values"].length || xTracks["end"]["frames"][xIndex] > yTracks["end"]["frames"][yIndex]) {
					curEndFrame = yTracks["end"]["frames"][yIndex];
					curY = yTracks["end"]["values"][yIndex];
					
					if (curEndFrame == yTracks["start"]["frames"][yIndex]) {
						valYPrevFrame = yTracks["end"]["values"][yIndex-1];
					}
					else {
						valYPrevFrame = yTracks["start"]["values"][yIndex] + (yTracks["end"]["values"][yIndex] - yTracks["start"]["values"][yIndex]) / (yTracks["end"]["frames"][yIndex] - yTracks["start"]["frames"][yIndex]) * (curEndFrame - 1 - yTracks["start"]["frames"][yIndex]);
					}
					
					if (xIndex == xTracks["start"]["values"].length) {
						curX = xTracks["end"]["values"][xIndex-1];
						valXPrevFrame = curX;
					}
					else if (xTracks["end"]["frames"][xIndex] == xTracks["start"]["frames"][xIndex]) {
						curX = xTracks["start"]["values"][xIndex];
						valXPrevFrame = xTracks["end"]["values"][xIndex-1];
					}
					else {
						curX = xTracks["start"]["values"][xIndex] + (xTracks["end"]["values"][xIndex] - xTracks["start"]["values"][xIndex]) / (xTracks["end"]["frames"][xIndex] - xTracks["start"]["frames"][xIndex]) * (curEndFrame - xTracks["start"]["frames"][xIndex]);
						
						if (curEndFrame == xTracks["start"]["frames"][xIndex]) {
							valXPrevFrame = xTracks["end"]["values"][yIndex-1];
						}
						else {
							valXPrevFrame = xTracks["start"]["values"][xIndex] + (xTracks["end"]["values"][xIndex] - xTracks["start"]["values"][xIndex]) / (xTracks["end"]["frames"][xIndex] - xTracks["start"]["frames"][xIndex]) * (curEndFrame - 1 - xTracks["start"]["frames"][xIndex]);
						}
					}
					yIndex++;
					
					if (xIndex < xTracks["start"]["values"].length) {
						nextX = xTracks["start"]["values"][xIndex] + (xTracks["end"]["values"][xIndex] - xTracks["start"]["values"][xIndex]) / (xTracks["end"]["frames"][xIndex] - xTracks["start"]["frames"][xIndex]) * (curEndFrame+1 - xTracks["start"]["frames"][xIndex]);
					}
					else {
						nextX = xTracks["end"]["values"][xIndex-1];
					}
					if(yIndex < yTracks["start"]["values"].length) {
						nextY = yTracks["start"]["values"][yIndex];
					}
					else {
						nextX = yTracks["end"]["values"][yIndex-1];
					}
				}
				else {
					curEndFrame = xTracks["end"]["frames"][xIndex];
					curX = xTracks["end"]["values"][xIndex];
					
					if (curEndFrame == xTracks["start"]["frames"][xIndex]) {
						valXPrevFrame = xTracks["end"]["values"][xIndex-1];
					}
					else {
						valXPrevFrame = xTracks["start"]["values"][xIndex] + (xTracks["end"]["values"][xIndex] - xTracks["start"]["values"][xIndex]) / (xTracks["end"]["frames"][xIndex] - xTracks["start"]["frames"][xIndex]) * (curEndFrame - 1 - xTracks["start"]["frames"][xIndex]);
					}
					
					if (yIndex == yTracks["start"]["values"].length) {
						curY = yTracks["end"]["values"][yIndex-1];
						valYPrevFrame = curY;
					}
					else if (yTracks["end"]["frames"][yIndex] == yTracks["start"]["frames"][yIndex]) {
						curY = yTracks["start"]["values"][xIndex];
						valYPrevFrame = yTracks["end"]["values"][yIndex-1];
					}
					else {
						curY = yTracks["start"]["values"][yIndex] + (yTracks["end"]["values"][yIndex] - yTracks["start"]["values"][yIndex]) / (yTracks["end"]["frames"][yIndex] - yTracks["start"]["frames"][yIndex]) * (curEndFrame - yTracks["start"]["frames"][yIndex]);
						
						if (curEndFrame == yTracks["start"]["frames"][yIndex]) {
							valYPrevFrame = yTracks["end"]["values"][yIndex-1];
						}
						else {
							valYPrevFrame = yTracks["start"]["values"][yIndex] + (yTracks["end"]["values"][yIndex] - yTracks["start"]["values"][yIndex]) / (yTracks["end"]["frames"][yIndex] - yTracks["start"]["frames"][yIndex]) * (curEndFrame - 1 - yTracks["start"]["frames"][yIndex]);
						}
					}
					xIndex++;
					
					if (xIndex < xTracks["start"]["values"].length) {
						nextX = xTracks["start"]["values"][xIndex];
					}
					else {
						nextX = xTracks["end"]["values"][xIndex-1];
					}
					if(yIndex < yTracks["start"]["values"].length) {
						nextY = yTracks["start"]["values"][yIndex] + (yTracks["end"]["values"][yIndex] - yTracks["start"]["values"][yIndex]) / (yTracks["end"]["frames"][yIndex] - yTracks["start"]["frames"][yIndex]) * (curEndFrame+1 - yTracks["start"]["frames"][yIndex]);
					}
					else {
						nextX = yTracks["end"]["values"][yIndex-1];
					}
				}
				
				var diffPrev1:Number = prevX - curX;
				var diffPrev2:Number = prevY - curY;
				var absDiffPrev:Number = Math.sqrt(diffPrev1*diffPrev1 + diffPrev2*diffPrev2);
				
				var diffNext1:Number = curX - nextX;
				var diffNext2:Number = curY - nextY;
				var absDiffNext:Number = Math.sqrt(diffNext1*diffNext1 + diffNext2*diffNext2);
				
				var diffEnds1:Number = valXPrevFrame - curX;
				var diffEnds2:Number = valYPrevFrame - curY;
				var absDiffEnds:Number = Math.sqrt(diffEnds1*diffEnds1 + diffEnds2*diffEnds2);
				
				if (absDiffEnds > 5 && frames.indexOf(curEndFrame-1) == -1) {
					ret += animFrameStart;
					ret += type;
					ret += animFrameBeforeTime;
					ret += "" + (curEndFrame-2) / mFps;
					ret += animFrameAfterTime;
					ret += typeNums[type]
					ret += animFrameAfterTypeNum;
					ret += b4RealArray;
					
					if (type == "position") {
						ret += valXPrevFrame + betweenRealVals;
						ret += -1*valYPrevFrame;
					}
					else {
						if (CCType && CCType == "CCSprite") {
							ret += mBitmapScale*valXPrevFrame + betweenRealVals;
							ret += mBitmapScale*valYPrevFrame;
						}
						else {
							ret += valXPrevFrame + betweenRealVals;
							ret += valYPrevFrame;
						}
					}
					
					if (type == "position") {
						ret += afterReal + posType + afterArray;
					}
					else {
						ret += afterReal + afterArray;
					}
					
					ret += animFrameEnd;
					
					frames.push(curEndFrame-1);
				}
				
				// if the previous one is too close, don't put in another frame. if the next frame is too far,
				// or if the current frames is beyond the length of the animation though, put in a frame
				if (absDiffPrev >= 0.01 || curEndFrame > curTotalFrames || xIndex == xTracks["start"]["values"].length && yIndex == yTracks["start"]["values"].length || absDiffNext > 1) {
					if (frames.indexOf(curEndFrame) == -1) {
						ret += animFrameStart;
						ret += type;
						ret += animFrameBeforeTime;
						
						if (curEndFrame > curTotalFrames) {
							ret += "" + (curTotalFrames+1) / mFps;
						}
						else {
							ret += "" + (curEndFrame-1) / mFps;
						}
						ret += animFrameAfterTime;
						ret += typeNums[type]
						ret += animFrameAfterTypeNum;
						ret += b4RealArray;
						
						if (type == "position") {
							ret += curX + betweenRealVals;
							ret += -1*curY;
						}
						else {
							if (CCType && CCType == "CCSprite") {
								ret += mBitmapScale*curX + betweenRealVals;
								ret += mBitmapScale*curY;
							}
							else {
								ret += curX + betweenRealVals;
								ret += curY;
							}
						}
						
						if (type == "position") {
							ret += afterReal + posType + afterArray;
						}
						else {
							ret += afterReal + afterArray;
						}
						
						ret += animFrameEnd;
						
						frames.push(curEndFrame);
					}
					
					// if next frame is too far, need to add another frame
					if (absDiffNext > 1) {
						ret += animFrameStart;
						ret += type;
						ret += animFrameBeforeTime;
						ret += "" + (curEndFrame) / mFps;
						ret += animFrameAfterTime;
						ret += typeNums[type]
						ret += animFrameAfterTypeNum;
						ret += b4RealArray;
						
						if (type == "position") {
							ret += nextX + betweenRealVals;
							ret += -1*nextY;
						}
						else {
							if (CCType && CCType == "CCSprite") {
								ret += mBitmapScale*nextX + betweenRealVals;
								ret += mBitmapScale*nextY;
							}
							else {
								ret += nextX + betweenRealVals;
								ret += nextY;
							}
						}
						
						if (type == "position") {
							ret += afterReal + posType + afterArray;
						}
						else {
							ret += afterReal + afterArray;
						}
						
						ret += animFrameEnd;
						
						frames.push(curEndFrame+1);
					}
				}
				
				if (curEndFrame > curTotalFrames) {
					break;
				}
				
				prevX = curX;
				prevY = curY;
			}
			
			ret += animB4Type;
			ret += type;
			ret += animAfterType;
			ret += typeNums[type]
			ret += animTypeEnd;
			
			return ret;
		}
		
		private static function skewAnimString(tracks:Object, xy:String):String {
			var ret:String = "";
			var prevVal:Number;
			var frames:Vector.<Number> = new Vector.<Number>();
			
			ret += animB4Key;
			
			if (xy == "x") {
				ret += "rotationX";
			}
			else {
				ret += "rotationY";
			}
			
			ret += animAfterKey ;
			ret += animStartArray;
			
			ret += animFrameStart;
			
			if (xy == "x") {
				ret += "rotationX";
			}
			else {
				ret += "rotationY";
			}
			
			ret += animFrameBeforeTime;
			ret += "0.0";
			ret += animFrameAfterTime;
			ret += "2";
			ret += animFrameAfterTypeNum;
			ret += b4Real;
			ret += tracks["start"]["values"][0]*180.0/Math.PI;
			ret += afterReal;
			ret += animFrameEnd;
			
			prevVal = tracks["start"]["values"][0]*180.0/Math.PI;
			
			for (var i:int = 0; i < tracks["start"]["values"].length; i++) {
				
				if (frames.indexOf(tracks["end"]["frames"][i]) == -1) {
					ret += animFrameStart;
					
					if (xy == "x") {
						ret += "rotationX";
					}
					else {
						ret += "rotationY";
					}
					
					ret += animFrameBeforeTime;
					
					if (tracks["end"]["frames"][i] > curTotalFrames) {
						ret += "" + (curTotalFrames+1) / mFps;
					}
					else {
						ret += "" + (tracks["end"]["frames"][i]-1) / mFps;
					}
					ret += animFrameAfterTime;
					ret += "2";
					ret += animFrameAfterTypeNum;
					ret += b4Real;
					var curVal:Number = tracks["end"]["values"][i]*180.0/Math.PI;
					
					if (Math.abs(prevVal - curVal) > Math.abs(prevVal - (curVal+360))) {
						while (Math.abs(prevVal - curVal) > Math.abs(prevVal - (curVal+360))) {
							curVal += 360;
						}
					}
					else if (Math.abs(prevVal - curVal) > Math.abs(prevVal - (curVal-360))) {
						while (Math.abs(prevVal - curVal) > Math.abs(prevVal - (curVal-360))) {
							curVal -= 360;
						}
					}
					
					ret += curVal;
					ret += afterReal;
					ret += animFrameEnd;
					
					prevVal = curVal;
					
					frames.push(curVal);
					
					var nextVal:Number = tracks["start"]["values"][i+1]*180.0/Math.PI;
					
					if (Math.abs(curVal - nextVal) > 1) {
						
						if (Math.abs(curVal - nextVal) > Math.abs(curVal - (nextVal+360))) {
							while (Math.abs(curVal - nextVal) > Math.abs(curVal - (nextVal+360))) {
								nextVal += 360;
							}
						}
						else if (Math.abs(curVal - nextVal) > Math.abs(curVal - (nextVal-360))) {
							while (Math.abs(curVal - nextVal) > Math.abs(curVal - (nextVal-360))) {
								nextVal -= 360;
							}
						}
						
						ret += animFrameStart;
						
						if (xy == "x") {
							ret += "rotationX";
						}
						else {
							ret += "rotationY";
						}
						
						ret += animFrameBeforeTime;
						ret += "" + (tracks["start"]["frames"][i+1]-1) / mFps;
						ret += animFrameAfterTime;
						ret += "2";
						ret += animFrameAfterTypeNum;
						ret += b4Real;
						ret += nextVal;
						ret += afterReal;
						ret += animFrameEnd;
						
						prevVal = nextVal;
						frames.push(nextVal);
					}
				}
				
				if (tracks["end"]["frames"][i] > curTotalFrames) {
					break;
				}
			}
			
			ret += animB4Type;
			
			if (xy == "x") {
				ret += "rotationX";
			}
			else {
				ret += "rotationY";
			}
			
			ret += animAfterType;
			ret += "2";
			ret += animTypeEnd;
			
			return ret;
		}
		
		private static function visibleAnimString(tracks:Object):String {
			var ret:String = "";
			
			ret += animB4Key;
			ret += "visible";
			ret += animAfterKey ;
			ret += animStartArray;
			
			if (tracks["start"]["values"][0]) {
				ret += animFrameStart;
				ret += "visible";
				ret += animFrameBeforeTime;
				ret += "0.0";
				ret += animFrameAfterTime;
				ret += "1";
				ret += animFrameAfterTypeNum;
				if (tracks["start"]["values"][0]) {
					ret += "						<true/>\n";
				}
				
				ret += animFrameEnd;
			}
			
			for (var i:int = 1; i < tracks["start"]["values"].length; i++) {
				
				ret += animFrameStart;
				ret += "visible";
				ret += animFrameBeforeTime;
				
				if (tracks["start"]["frames"][i] > curTotalFrames) {
					ret += "" + (curTotalFrames+1)/ mFps;
				}
				else {
					ret += "" + (tracks["start"]["frames"][i]-1) / mFps;
				}
				ret += animFrameAfterTime;
				ret += "1";
				ret += animFrameAfterTypeNum;
				if (tracks["start"]["values"][i]) {
					ret += "						<true/>\n";
				}
				else {
					ret += "						<false/>\n";
				}
				
				ret += animFrameEnd;
				
				if (tracks["start"]["frames"][i] > curTotalFrames) {
					break;
				}
			}
			
			ret += animB4Type;
			ret += "visible";
			ret += animAfterType;
			ret += "1";
			ret += animTypeEnd;
			
			return ret;
		}
	}
}
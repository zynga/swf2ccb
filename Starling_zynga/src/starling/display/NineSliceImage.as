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

package starling.display
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import starling.core.starling_internal;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	use namespace starling_internal;

	public class NineSliceImage extends Sprite{
		
		private var _imagesLib:Dictionary = new Dictionary();
		private var _images:Vector.<Image>;
		private var _realWidth:uint = 0;
		private var _realHeight:uint = 0;
		private var _curWidth:uint = 0;
		private var _curHeight:uint = 0;
		private var _curScaleX:Number = 1;
		private var _curScaleY:Number = 1;
		private var _topHeight:Number = 0;
		private var _bottomHeight:Number = 0;
		private var _rightWidth:Number = 0;
		private var _leftWidth:Number = 0;
		
		/** 
		 * Class constructor
		 * @param pPieces the pieces you want to use. Expects a TextureAtlas with at least 9 textures, named as 
		 * 		  following: [pID_tl, pId_tm, pId_tr, pID_ml, pID_mm, pID_mr, pID_bl, pID_bm, pID_br]
		 * @param pID the prefix ID for the pieces.
		 */ 
		public function NineSliceImage(pPieces:TextureAtlas, pID:String = "image"){
			setImages(pPieces, pID);
		}
		
		/** 
		 * Sets a new 9 slice image set
		 * @param pPieces the pieces you want to use. Expects a TextureAtlas with at least 9 textures, named as 
		 * 		  following: [pID_tl, pId_tm, pId_tr, pID_ml, pID_mm, pID_mr, pID_bl, pID_bm, pID_br]
		 * @param pID the prefix ID for the pieces.
		 */ 
		public function setImages(pPieces:TextureAtlas, pID:String):void{
			
			_images = _imagesLib[pID];
			
			if(!_images){
				_images = new Vector.<Image>();
				var textures:Vector.<Texture> = new Vector.<Texture>;
				textures.push(pPieces.getTexture(pID + "_tl"));
				textures.push(pPieces.getTexture(pID + "_tm"));
				textures.push(pPieces.getTexture(pID + "_tr"));
				textures.push(pPieces.getTexture(pID + "_ml"));
				textures.push(pPieces.getTexture(pID + "_mm"));
				textures.push(pPieces.getTexture(pID + "_mr"));
				textures.push(pPieces.getTexture(pID + "_bl"));
				textures.push(pPieces.getTexture(pID + "_bm"));
				textures.push(pPieces.getTexture(pID + "_br"));
				for each(var texture:Texture in textures){
					var img:Image = new Image(texture);
					_images.push(img);
				}
				_imagesLib[pID] = _images;
			}
			
			for(var i:uint = 0; i < numChildren; i++){
				removeChildAt(i);
				i --;
			}
			for each(img in _images){
				addChildAt(img, 0);
			}
			
			_leftWidth = _images[0].width;
			_rightWidth = _images[2].width;
			_topHeight = _images[0].height;
			_bottomHeight = _images[6].height;
			
			_realWidth = _rightWidth + _images[1].width + _leftWidth;
			if (_realWidth < 1)
				_realWidth = 1;
			if (_curWidth == 0)
				_curWidth = _realWidth;
			_realHeight = _topHeight + _images[3].height + _bottomHeight;
			if (_realHeight < 1)
				_realHeight = 1;
			if (_curHeight == 0)
				_curHeight = _realHeight;
			
			_images[1].x = _images[4].x = _images[7].x = _images[0].width;
			_images[2].x = _images[5].x = _images[8].x = _images[0].width + _images[1].width;
			_images[3].y = _images[4].y = _images[5].y = _images[0].height;
			_images[6].y = _images[7].y = _images[8].y = _images[0].height + _images[3].height;
			
			if(_curWidth != _realWidth) updateWidth();
			if(_curHeight != _realHeight) updateHeight();
		}
		
		/** The width */ 
		public override function set width(pWidth:Number):void{
			if (pWidth == 16.3) {
				pWidth = pWidth;
			}
			_curWidth = pWidth;
			_curScaleX = Number(_curWidth) / Number(_realWidth);			
			updateWidth();
		}
		
		/** The width */ 
		public override function get width():Number { 
			return _curWidth;
		}

		/** The height */
		public override function set height(pHeight:Number):void{
			_curHeight = pHeight;
			_curScaleY = Number(_curHeight) / Number(_realHeight);
			updateHeight();
		}

		/** The height */
		public override function get height():Number {
			return _curHeight;
		}
		
		/** Scale X */
		public override function set scaleX(pScale:Number):void{
			_curScaleX = pScale;
			_curWidth = _realWidth * pScale;
			updateWidth();
		}
		
		/** Scale X */
		public override function get scaleX():Number {
			return _curScaleX;
		}
		
		/** Scale Y */
		public override function set scaleY(pScale:Number):void{
			_curScaleY = pScale;
			_curHeight = _realHeight * pScale;
			updateHeight();
		}
		
		/** Scale Y */
		public override function get scaleY():Number {
			return _curScaleY;
		}
		
		private function updateWidth():void{
			var centerWidth:Number = _curWidth - (_leftWidth + _rightWidth);
			if (centerWidth >= 0) {
				_images[0].width = _images[3].width = _images[6].width = _leftWidth;
				_images[1].width = _images[4].width = _images[7].width = centerWidth;
				_images[2].width = _images[5].width = _images[8].width = _rightWidth;
			} else {
				_images[0].width = _images[3].width = _images[6].width = _leftWidth * _curWidth / (_leftWidth + _rightWidth);
				_images[1].width = _images[4].width = _images[7].width = 0;
				_images[2].width = _images[5].width = _images[8].width = _rightWidth * _curWidth / (_leftWidth + _rightWidth);
			}
			_images[1].x = _images[4].x = _images[7].x = _images[0].width;
			_images[2].x = _images[5].x = _images[8].x = _images[0].width + _images[1].width;
		}
		
		private function updateHeight():void{
			var centerHeight:Number = _curHeight - (_topHeight + _bottomHeight);
			if (centerHeight >= 0) {
				_images[0].height = _images[1].height = _images[2].height = _topHeight;
				_images[3].height = _images[4].height = _images[5].height = centerHeight;
				_images[6].height = _images[7].height = _images[8].height = _bottomHeight;				
			} else {
				_images[0].height = _images[1].height = _images[2].height = _topHeight * _curHeight / (_topHeight + _bottomHeight);
				_images[3].height = _images[4].height = _images[5].height = 0;
				_images[6].height = _images[7].height = _images[8].height = _bottomHeight * _curHeight / (_topHeight + _bottomHeight);				
			}
			_images[3].y = _images[4].y = _images[5].y = _images[0].height;
			_images[6].y = _images[7].y = _images[8].y = _images[0].height + _images[3].height;					
		}
		
		/** 
		 * @override
		 */ 
		public override function dispose():void{
			if (!mIsDisposed) {
				for each(var img:Image in _images){
					removeChild(img);
				}
				_images = null;
				_imagesLib = null;
				super.dispose();
			}
		}
	}
}
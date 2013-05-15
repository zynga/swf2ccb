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

/**
 * Track Class
 * Keeps track of what values on the given display object need to be changed 
 * 
 */
package starling.display
{
	import flash.display.MovieClip;
	
	import starling.core.Starling;
	import starling.core.starling_internal;
	
	use namespace starling_internal;
	
	public class Track
	{
		public var mAttr:int;
		protected var mStartFrames:Vector.<int>;
		protected var mStartVals:Array;
		protected var mEndFrames:Vector.<int>;
		protected var mEndVals:Array;
		public var mCurrentValue:Number;
		
		starling_internal var mTarget:DisplayObject;
		
		public function Track(attr:int, startFrames:Array, startValues:Array, endFrames:Array, endValues:Array)
		{
			var i:int;
			mAttr = attr;
			mStartFrames = new Vector.<int>;
			for (i = 0; i < startFrames.length; i++ )
			{
				mStartFrames.push(startFrames[i]);
			}
			mStartVals = startValues.slice();
			
			mEndFrames = new Vector.<int>;
			for (i = 0; i < endFrames.length; i++ )
			{
				mEndFrames.push(endFrames[i]);
			}
			mEndVals = endValues.slice();
		}
		
		// Does a binary search through the values to pick the right one, then, set it
		public function setFrame(frame:uint):void
		{
				var b:int = 0;
				var t:int = mStartFrames.length-1;
				var index:uint;
				
				if (mAttr == TrackTarget.VISIBLE) {
					var x:int = 0;
					x = 1;
				}
				
				while (b <= t)
				{
					index = (b+t)/2;
					
					if (mStartFrames[index] == frame)
					{
						break;
					}
					else if (mStartFrames[index] < frame)
					{
						b = index+1;
					}
					else
					{
						t = index-1;
					}
				}
				
				if (mStartFrames[index] > frame) {
					if (index != 0) {
						index--;
					}
					else {
						index = mStartFrames.length - 1;
					}
				}
				
				var tempValue:Number;
				if (mEndFrames[index] != mStartFrames[index]) {
					tempValue = mStartVals[index] + (mEndVals[index] - mStartVals[index]) / (mEndFrames[index] - mStartFrames[index]) * (frame - mStartFrames[index]);
				}
				else {
					tempValue = mStartVals[index];
				}
				
				// if different, set it
				if (mCurrentValue != tempValue) {
					mCurrentValue = tempValue;
				
					// pseudo-binary search
					if (mAttr <= TrackTarget.ROTATION) {
						if (mAttr == TrackTarget.X) {
							mTarget.x = mCurrentValue;
						} else if (mAttr == TrackTarget.Y) {
							mTarget.y = mCurrentValue;
						}
						else {
							mTarget.rotation = mCurrentValue;
						}
					} else if (mAttr < TrackTarget.ALPHA) {
						if (mAttr == TrackTarget.SCALEX) {
							mTarget.scaleX = mCurrentValue;
						} else {
							mTarget.scaleY = mCurrentValue;
						}
					}
					else if (mAttr < TrackTarget.SKEWX) {
						if (mAttr == TrackTarget.ALPHA) {
							mTarget.alpha = mCurrentValue;
						}
						else {
							mTarget.visible = (mCurrentValue == 1);
						}
					}
					else if (mAttr == TrackTarget.SKEWX) {
						mTarget.skewX = mCurrentValue;
					}
					else if (mAttr == TrackTarget.SKEWY) {
						mTarget.skewY = mCurrentValue;
					}
				}
		}
	}
}
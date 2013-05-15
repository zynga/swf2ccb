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

package starling.events
{
	import flash.geom.Point;


	public class MouseEvent extends Event
	{
		public static const ROLL_OVER:String = "rollOver";
		public static const ROLL_OUT:String = "rollOut";
		public static const MOUSE_OVER:String = "mouseOver";
		public static const MOUSE_OUT:String = "mouseOut";
		public static const MOUSE_DOWN:String = "mouseDown";
		public static const MOUSE_UP:String = "mouseUp";
		public static const MOUSE_MOVE:String = "mouseMove";
		public static const CLICK:String = "Click";
		
		private var mLocalX:Number;
		private var mLocalY:Number;
		
		private static var sPoint:Point = new Point();
		
		public function MouseEvent(type:String, bubbles:Boolean = false, localX:Number = 0, localY:Number = 0)
		{
			super(type, bubbles, null);
			mLocalX = localX;
			mLocalY = localY;
		}
		
		public function get localX():Number {
			return mLocalX;
		}
		
		public function get localY():Number {
			return mLocalY;
		}
	}
}
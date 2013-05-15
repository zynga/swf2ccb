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
	import flash.utils.Dictionary;
	import starling.core.starling_internal;

	public class AssetContext
	{
		/** Shared symbol info for all assets in this context. */
		public var sharedSymbols:Dictionary = new Dictionary();
		
		/** Shared bitmaps for all assets in this context. */
		public var sharedBitmaps:Dictionary = new Dictionary();

		/** Shared bitmap data for all assets in this context. */
		starling_internal var sharedBitmapData:Dictionary = new Dictionary();

		/** Constructor. */
		public function AssetContext() {
		}
	}
}
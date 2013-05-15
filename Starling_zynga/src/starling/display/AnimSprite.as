/**
 * AnimSprite - the Starling implemntation of the flash MovieClip
 */
package starling.display
{
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.utils.Dictionary;
	
	import starling.animation.IAnimatable;
	import starling.core.Starling;
	import starling.core.starling_internal;

	public class AnimSprite extends Sprite implements IAnimatable
	{
		private var mCurrentFrame:int;
		private var mCurrentFrameLabel:String;
		private var mCurrentLabel:String;
		private var mCurrentLabels:Array;
		private var mFramesLoaded:int;
		private var mTotalFrames:int;
		private var mTracks:Vector.<Track>;
		
		private var mLabels:Array;
		private var mStartFramesForLabels:Array;
		private var mPlaying:Boolean;
		
		private static var sDefaultFrameRate:uint = 24;
		
		private var mFrameRate:uint = sDefaultFrameRate;
		
		public var enabled:Boolean;
		public var trackAsMenu:Boolean;
		
		public function AnimSprite()
		{
			super();
			Starling.juggler.add(this);
			mPlaying = true;
			mTracks = new Vector.<Track>;
		}
		
		public function initFrames(total:int):void
		{
			if (mTotalFrames <= 0) {
				mTotalFrames = total;
				mFramesLoaded = total;
			}
		}
		
		public function gotoAndPlay(frame:Object, scene:String = null):void
		{
			if (frame is String)
			{
				mCurrentLabel = frame as String;
				mCurrentFrameLabel = frame as String;
				resetFrameNums();
			}
			else if (frame is Number)
			{
				var frameNum:int = frame as Number;
				if (frameNum < 0 || frameNum >= mTotalFrames)
				{
					throw new Error("frame number out of range!");
				}
				
				mCurrentFrame = frameNum;
				resetLabels();
			}
			
			play();
		}
		
		public function gotoAndStop(frame:Object, scene:String = null):void
		{
			if (frame is String)
			{
				mCurrentLabel = frame as String;
				mCurrentFrameLabel = frame as String;
				resetFrameNums();
			}
			else if (frame is Number)
			{
				var frameNum:int = frame as Number;
				if (frameNum < 0 || frameNum >= mTotalFrames)
				{
					throw new Error("frame number out of range!");
				}
				
				mCurrentFrame = frameNum;
				resetLabels();
			}
			
			stop();
		}

		public function nextFrame():void
		{
			mCurrentFrame++;
			
			if (mCurrentFrame > mTotalFrames - 1)
			{
				mCurrentFrame = 0;
			}
			
			resetLabels();
			stop();
		}
		
		/**
		 * Not implemented
		 */
		public function nextScene():void
		{
			throw new Error("nextScene NOT IMPLEMENTED");
		}
		
		public function play():void
		{
			if (mPlaying == false) {
				mPlaying = true;
				
				Starling.juggler.add(this);
			}
		}
		
		public function prevFrame():void
		{
			mCurrentFrame--;
			
			if (mCurrentFrame < 0)
			{
				mCurrentFrame = mTotalFrames - 1;
			}
			
			resetLabels();
			stop();
		}
		
		/**
		 * Not implemented
		 */
		public function prevScene():void
		{
			throw new Error("prevScene NOT IMPLEMENTED");
		}
		
		public function stop():void
		{
			if (mPlaying == true) {
				mPlaying = false;
				
				Starling.juggler.remove(this);
			}
		}
		
		public function advanceTime(passedTime:Number):void
		{
			if (mPlaying)
			{
				var framesPassed:int = passedTime*fps;
//				var framesPassed:int = 1;
				mCurrentFrame = ((mCurrentFrame + framesPassed) % mTotalFrames);
				if (mCurrentFrame == 0) {
					mCurrentFrame = mTotalFrames;
				}
				resetLabels();
				
				for each (var track:Track in mTracks)
				{
					track.setFrame(mCurrentFrame);
				}
			}
		}
		
		// After the frame number is updated, the label needs to be as well
		private function resetLabels():void
		{
			if (mStartFramesForLabels == null) {
				return;
			}
			
			var fLabelStart:int = bsearch();
			mCurrentLabel = mLabels[mStartFramesForLabels.indexOf(fLabelStart)];
			
			if (fLabelStart == mCurrentFrame)
			{
				mCurrentFrameLabel = mCurrentLabel;
			}
			else
			{
				mCurrentFrameLabel = null;
			}
		}
		
		// After the label is updated, the frame number needs to be as well
		private function resetFrameNums():void
		{
			if (mLabels.indexOf(mCurrentLabel) == -1)
			{
				throw new Error("Invalid frame label");
			}
			else
			{
				mCurrentFrame = Number(mLabels.indexOf(mCurrentLabel));
			}
		}
		
		public function get currentFrame():int
		{
			return mCurrentFrame;
		}
		
		public function get currentFrameLabel():String
		{
			return mCurrentFrameLabel;
		}
		
		public function get currentLabel():String
		{
			return mCurrentLabel;
		}
		
		public function get currentLabels():Array
		{
			return mCurrentLabels;
		}
		
		public function get framesLoaded():int
		{
			return mFramesLoaded;
		}
		
		public function get totalFrames():int
		{
			return mTotalFrames;
		}
		
		public function get fps():uint
		{
			return mFrameRate;
		}
		
		public function set fps(rate:uint):void
		{
			mFrameRate = rate;
		}
		
		// Adds the Track object to track. Only add if there is some attribute that needs to be tracked
		public function addTrack(prop:int, startFrames:Array, startValues:Array, endFrames:Array, endValues:Array, target:DisplayObject):void
		{
			if (startFrames != null) {
				if (prop == TrackTarget.LABEL) {
					mStartFramesForLabels = startFrames.slice();
					mLabels = startValues.slice();
				}
				else {
					var newTrack:Track = new Track(prop, startFrames, startValues, endFrames, endValues);
					newTrack.starling_internal::mTarget = target;
					mTracks.push(newTrack);
				}
			}
		}
		
		// Does a binary search through the labels to pick the right one
		private function bsearch():int
		{
			var b:int = 0;
			var t:int = mStartFramesForLabels.length-1;
			var index:uint;
			
			while (b <= t)
			{
				index = (b+t)/2;
				
				if (mStartFramesForLabels[index] == mCurrentFrame)
				{
					break;
				}
				else if (mStartFramesForLabels[index] < mCurrentFrame)
				{
					b = index+1;
				}
				else
				{
					t = index-1;
				}
			}
			
			if (mStartFramesForLabels[index] > mCurrentFrame) {
				index--;
			}
			return mStartFramesForLabels[index];
		}
	}
}
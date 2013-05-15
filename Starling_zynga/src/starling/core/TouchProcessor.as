// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core
{
    import flash.geom.Point;
    import flash.utils.getDefinitionByName;
    
    import starling.display.DisplayObject;
    import starling.display.Stage;
    import starling.events.KeyboardEvent;
    import starling.events.MouseEvent;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;

    use namespace starling_internal;
    
    /** @private
     *  The TouchProcessor is used internally to convert mouse and touch events of the conventional
     *  Flash stage to Starling's TouchEvents. */
    internal class TouchProcessor
    {
        private static const MULTITAP_TIME:Number = 0.3;
        private static const MULTITAP_DISTANCE:Number = 25;
        
        private var mStage:Stage;
        private var mElapsedTime:Number;
        private var mTouchMarker:TouchMarker;
        
        private var mCurrentTouches:Vector.<Touch>;
        private var mQueue:Vector.<Array>;
        private var mLastTaps:Vector.<Touch>;
        
        private var mShiftDown:Boolean = false;
        private var mCtrlDown:Boolean = false;
        
        /** Helper objects. */
        private static var sProcessedTouchIDs:Vector.<int> = new <int>[];
        private static var sHoveringTouchData:Vector.<Object> = new <Object>[];

		/** Set to true to enable mouse events in starling. */
		private static var sEnableMouseEvents:Boolean = true;
		
        public function TouchProcessor(stage:Stage)
        {
            mStage = stage;
            mElapsedTime = 0.0;
            mCurrentTouches = new <Touch>[];
            mQueue = new <Array>[];
            mLastTaps = new <Touch>[];
            
            mStage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.addEventListener(KeyboardEvent.KEY_UP,   onKey);
            monitorInterruptions(true);
        }

        public function dispose():void
        {
            monitorInterruptions(false);
            mStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.removeEventListener(KeyboardEvent.KEY_UP,   onKey);
            if (mTouchMarker) mTouchMarker.dispose();
        }
        
        public function advanceTime(passedTime:Number):void
        {
            var i:int;
            var touchID:int;
            var touch:Touch;
            
            mElapsedTime += passedTime;
            
            // remove old taps
            if (mLastTaps.length > 0)
            {
                for (i=mLastTaps.length-1; i>=0; --i)
                    if (mElapsedTime - mLastTaps[i].timestamp > MULTITAP_TIME)
                        mLastTaps.splice(i, 1);
            }
            
            while (mQueue.length > 0)
            {
                sProcessedTouchIDs.length = sHoveringTouchData.length = 0;
                
                // set touches that were new or moving to phase 'stationary'
                for each (touch in mCurrentTouches)
                    if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED)
                        touch.setPhase(TouchPhase.STATIONARY);
                
                // process new touches, but each ID only once
                while (mQueue.length > 0 && 
                    sProcessedTouchIDs.indexOf(mQueue[mQueue.length-1][0]) == -1)
                {
                    var touchArgs:Array = mQueue.pop();
                    touchID = touchArgs[0] as int;
                    touch = getCurrentTouch(touchID);
                    
                    // hovering touches need special handling (see below)
                    if (touch && touch.phase == TouchPhase.HOVER && touch.target)
                        sHoveringTouchData.push({ 
                            touch: touch, 
                            target: touch.target, 
                            bubbleChain: touch.bubbleChain 
                        });
                    
                    processTouch.apply(this, touchArgs);
                    sProcessedTouchIDs.push(touchID);
                }
                
                // the same touch event will be dispatched to all targets; 
                // the 'dispatch' method will make sure each bubble target is visited only once.
                var touchEvent:TouchEvent = 
                    new TouchEvent(TouchEvent.TOUCH, mCurrentTouches, mShiftDown, mCtrlDown); 
                
                // if the target of a hovering touch changed, we dispatch the event to the previous
                // target to notify it that it's no longer being hovered over.
                for each (var touchData:Object in sHoveringTouchData) {
                    if (touchData.touch.target != touchData.target) {
                        touchEvent.dispatch(touchData.bubbleChain);
						if (sEnableMouseEvents) 
							mouseTouchTargetChanged(touch, touchData.touch.target);
					}
				}

                // dispatch events
                for each (touchID in sProcessedTouchIDs)
                    getCurrentTouch(touchID).dispatchEvent(touchEvent);

				// send any mouse events
				if (mCurrentTouches.length > 0 && sEnableMouseEvents) {
					dispatchMouseEvents(mCurrentTouches[0], touchEvent);
				}
					
                // remove ended touches
                for (i=mCurrentTouches.length-1; i>=0; --i)
                    if (mCurrentTouches[i].phase == TouchPhase.ENDED)
                        mCurrentTouches.splice(i, 1);
            }
        }
        
        public function enqueue(touchID:int, phase:String, globalX:Number, globalY:Number,
                                pressure:Number=1.0, width:Number=1.0, height:Number=1.0):void
        {
            mQueue.unshift(arguments);
            
            // multitouch simulation (only with mouse)
            if (mCtrlDown && simulateMultitouch && touchID == 0) 
            {
                mTouchMarker.moveMarker(globalX, globalY, mShiftDown);
                mQueue.unshift([1, phase, mTouchMarker.mockX, mTouchMarker.mockY]);
            }
        }
        
        private function processTouch(touchID:int, phase:String, globalX:Number, globalY:Number,
                                      pressure:Number=1.0, width:Number=1.0, height:Number=1.0):void
        {
            var position:Point = new Point(globalX, globalY);
            var touch:Touch = getCurrentTouch(touchID);
            
            if (touch == null)
            {
                touch = new Touch(touchID, globalX, globalY, phase, null);
                addCurrentTouch(touch);
            }
            
            touch.setPosition(globalX, globalY);
            touch.setPhase(phase);
            touch.setTimestamp(mElapsedTime);
            touch.setPressure(pressure);
            touch.setSize(width, height);
            
            if (phase == TouchPhase.HOVER || phase == TouchPhase.BEGAN)
                touch.setTarget(mStage.hitTest(position, true));
            
            if (phase == TouchPhase.BEGAN)
                processTap(touch);
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            if (event.keyCode == 17 || event.keyCode == 15) // ctrl or cmd key
            {
                var wasCtrlDown:Boolean = mCtrlDown;
                mCtrlDown = event.type == KeyboardEvent.KEY_DOWN;
                
                if (simulateMultitouch && wasCtrlDown != mCtrlDown)
                {
                    mTouchMarker.visible = mCtrlDown;
                    mTouchMarker.moveCenter(mStage.stageWidth/2, mStage.stageHeight/2);
                    
                    var mouseTouch:Touch = getCurrentTouch(0);
                    var mockedTouch:Touch = getCurrentTouch(1);
                    
                    if (mouseTouch)
                        mTouchMarker.moveMarker(mouseTouch.globalX, mouseTouch.globalY);
                    
                    // end active touch ...
                    if (wasCtrlDown && mockedTouch && mockedTouch.phase != TouchPhase.ENDED)
                        mQueue.unshift([1, TouchPhase.ENDED, mockedTouch.globalX, mockedTouch.globalY]);
                    // ... or start new one
                    else if (mCtrlDown && mouseTouch)
                    {
                        if (mouseTouch.phase == TouchPhase.BEGAN || mouseTouch.phase == TouchPhase.MOVED)
                            mQueue.unshift([1, TouchPhase.BEGAN, mTouchMarker.mockX, mTouchMarker.mockY]);
                        else
                            mQueue.unshift([1, TouchPhase.HOVER, mTouchMarker.mockX, mTouchMarker.mockY]);
                    }
                }
            }
            else if (event.keyCode == 16) // shift key 
            {
                mShiftDown = event.type == KeyboardEvent.KEY_DOWN;
            }
        }
        
        private function processTap(touch:Touch):void
        {
            var nearbyTap:Touch = null;
            var minSqDist:Number = MULTITAP_DISTANCE * MULTITAP_DISTANCE;
            
            for each (var tap:Touch in mLastTaps)
            {
                var sqDist:Number = Math.pow(tap.globalX - touch.globalX, 2) +
                                    Math.pow(tap.globalY - touch.globalY, 2);
                if (sqDist <= minSqDist)
                {
                    nearbyTap = tap;
                    break;
                }
            }
            
            if (nearbyTap)
            {
                touch.setTapCount(nearbyTap.tapCount + 1);
                mLastTaps.splice(mLastTaps.indexOf(nearbyTap), 1);
            }
            else
            {
                touch.setTapCount(1);
            }
            
            mLastTaps.push(touch.clone());
        }
        
        private function addCurrentTouch(touch:Touch):void
        {
            for (var i:int=mCurrentTouches.length-1; i>=0; --i)
                if (mCurrentTouches[i].id == touch.id)
                    mCurrentTouches.splice(i, 1);
            
            mCurrentTouches.push(touch);
        }
        
        private function getCurrentTouch(touchID:int):Touch
        {
            for each (var touch:Touch in mCurrentTouches)
                if (touch.id == touchID) return touch;
            return null;
        }
        
        public function get simulateMultitouch():Boolean { return mTouchMarker != null; }
        public function set simulateMultitouch(value:Boolean):void
        { 
            if (simulateMultitouch == value) return; // no change
            if (value)
            {
                mTouchMarker = new TouchMarker();
                mTouchMarker.visible = false;
                mStage.addChild(mTouchMarker);
            }
            else
            {                
                mTouchMarker.removeFromParent(true);
                mTouchMarker = null;
            }
        }
        
        // interruption handling
        
        private function monitorInterruptions(enable:Boolean):void
        {
            // if the application moves into the background or is interrupted (e.g. through
            // an incoming phone call), we need to abort all touches.
            
            try
            {
                var nativeAppClass:Object = getDefinitionByName("flash.desktop::NativeApplication");
                var nativeApp:Object = nativeAppClass["nativeApplication"];
                
                if (enable)
                    nativeApp.addEventListener("deactivate", onInterruption, false, 0, true);
                else
                    nativeApp.removeEventListener("activate", onInterruption);
            }
            catch (e:Error) {} // we're not running in AIR
        }
        
        private function onInterruption(event:Object):void
        {
            var touch:Touch;
            var phase:String;
            
            // abort touches
            for each (touch in mCurrentTouches)
            {
                if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED ||
                    touch.phase == TouchPhase.STATIONARY)
                {
                    touch.setPhase(TouchPhase.ENDED);
                }
            }
            
            // dispatch events
            var touchEvent:TouchEvent = 
                new TouchEvent(TouchEvent.TOUCH, mCurrentTouches, mShiftDown, mCtrlDown);
            
            for each (touch in mCurrentTouches)
                touch.dispatchEvent(touchEvent);
            
            // purge touches
            mCurrentTouches.length = 0;
        }
        		
		//
		// Mouse event simulation support (for compatibility with Flash api's)
		//
		
		private static var sPt:Point = new Point();
		
		private var mMouseCurrentTarget:DisplayObject;
		
		/** Mouse events will be generated and dispatched if this is true. */
		public function get enableMouseEvents():Boolean {
			return sEnableMouseEvents;
		}
		
		/** Mouse events will be generated and dispatched if this is true. */
		public function set enableMouseEvents(enabled:Boolean):void {
			sEnableMouseEvents = enabled;
		}
		
		/**
		 * Called when touch target's change to generate mouse in, mouse leave events.
		 * 
		 * @param touch			the touch object.
		 * @param newTarget		the new target.
		 */
		private function mouseTouchTargetChanged(touch:Touch, newTarget:DisplayObject):void {
			
			// Mouse over/out events..
			if (newTarget != mMouseCurrentTarget) {
				if (mMouseCurrentTarget != null && mMouseCurrentTarget.stage != null) {
					sPt.x = touch.globalX; sPt.y = touch.globalY;
					mMouseCurrentTarget.globalToLocal(sPt);
					mMouseCurrentTarget.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT, true, sPt.x, sPt.y));
					mMouseCurrentTarget.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT, true, sPt.x, sPt.y));
				}

				mMouseCurrentTarget = newTarget;
				
				if (mMouseCurrentTarget != null && mMouseCurrentTarget.stage != null) {
					sPt.x = touch.globalX; sPt.y = touch.globalY;
					mMouseCurrentTarget.globalToLocal(sPt);					
					mMouseCurrentTarget.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER, true, sPt.x, sPt.y));
					mMouseCurrentTarget.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER, true, sPt.x, sPt.y));
				}
			}
			
		}
		
		/**
		 * Called to dispatch any mouse events for a given touch event.
		 *  
		 * @param touch			the touch object.
		 * @param touchEvent	the touch event for which mouse events will be generated.
		 */
		private function dispatchMouseEvents(touch:Touch, touchEvent:TouchEvent):void {
			
			var target:DisplayObject = touch.target;
			
			// Mouse events..
			if (target && touchEvent.touches.length > 0) {
				var touch:Touch = touch;
				sPt.x = touch.globalX; sPt.y = touch.globalY;
				target.globalToLocal(sPt);					
				if (touch.phase == TouchPhase.HOVER || touch.phase == TouchPhase.MOVED) {
					target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_MOVE, true, sPt.x, sPt.y));
				} else if (touch.phase == TouchPhase.BEGAN) {
					target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, sPt.x, sPt.y));
					target.dispatchEvent(new MouseEvent(MouseEvent.CLICK, true, sPt.x, sPt.y));
				} else if (touch.phase == TouchPhase.ENDED) {
					target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, sPt.x, sPt.y));

				}
			}
		}
    }
}

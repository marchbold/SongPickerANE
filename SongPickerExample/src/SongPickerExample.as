//
//  SongPickerExample.as
//  Native Extension Test
//
//  Created by Richard Lovejoy (rich@newpixel.com) on 2/2/13.
//  Copyright (c) 2013 Richard Lovejoy. All rights reserved.
//
/*
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
/*
	The SongPicker Air Native Extension lets you choose a song from your music library on your iOS or Android device, and play it back.
	The extension uses the native media picker of the device to allow the song to be picked.

	Notes:
		- You must include the following line in the Android manifest section of your app config xml file:
<application>
<activity android:name="com.newpixel.songpicker.PickSongActivity" android:theme="@android:style/Theme.Translucent.NoTitleBar"></activity>
</application>			    			    

		- You must specify the iOS SDK to build against when packaging an app for iOS. (ActionScript Build Packaging > Apple iOS > Native Extensions)

		- On iOS it seems to intermittently crash if you try to init the SongPicker too soon after the app starts running. Try waiting for user interaction.

*/
package
{
	import com.newpixel.air.nativeextensions.SongPicker;
	import com.newpixel.air.nativeextensions.SongPickerEvent;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	
	public class SongPickerExample extends Sprite
	{
		private var _buttons:ControlButtons;
		private var _chosenSongID:String;
		private var _timeStart:int;
		private var _volume:Number;		// 0 - 1
		
		private var _started:Boolean = false;
		
		public function SongPickerExample()
		{
			super();
			
			// support autoOrients
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			
			
			
		}
		
		protected function addedToStageHandler(event:Event):void
		{
			// setup ui
			_buttons = new ControlButtons();
			_buttons.x = 20;
			_buttons.y = 20;

			_buttons.playSong.visible = false;
			_buttons.stopSong.visible = false;
			_buttons.fadeOutSong.visible = false;
			
			// check for song picker
			var canPick:Boolean = SongPicker.instance.isNativeMediaPickerAvailable();
			if (!canPick)
			{
				// quick and dirty
				_buttons.pickSong.visible = false;
				_buttons.info.text = "A song picker is not available on this device.";
				
				_buttons.volDown.visible = false;
				_buttons.volUp.visible = false;
			}
			else
			{
				_buttons.pickSong.btn.addEventListener(MouseEvent.CLICK, pickSongButtonHandler);
				_buttons.playSong.btn.addEventListener(MouseEvent.CLICK, playSongButtonHandler);
				_buttons.stopSong.btn.addEventListener(MouseEvent.CLICK, stopSongButtonHandler);
				_buttons.fadeOutSong.btn.addEventListener(MouseEvent.CLICK, fadeOutSongButtonHandler);
				
				_buttons.info.text = "Pick a song on your iOS or Android device...";
				
				_buttons.volDown.btn.addEventListener(MouseEvent.CLICK, volumeDownButtonHandler);
				_buttons.volUp.btn.addEventListener(MouseEvent.CLICK, volumeUpButtonHandler);
				setVolumeText();
				
			}
			
			addChild(_buttons);
						
		}
				
		protected function playSongButtonHandler(event:MouseEvent):void
		{
			SongPicker.instance.addEventListener(SongPickerEvent.SONG_FINISHED, songFinishedHandler);
			if (_started)
			{
				// can use this to resume from a pause
				trace("resume song");
				SongPicker.instance.playSong();
			}
			else
			{
				SongPicker.instance.playSong(_chosenSongID);	
			}
			
			
			_volume = SongPicker.instance.getVolume();
			
			_buttons.playSong.visible = false;
			_buttons.stopSong.visible = true;
			
			_buttons.fadeOutSong.alpha = 1.0;
			_buttons.fadeOutSong.visible = true;
			_buttons.fadeOutSong.enabled = true;
			
			//_started = true;
			// for playhead position
			addEventListener(Event.ENTER_FRAME, checkPlayhead);
		}

		protected function stopSongButtonHandler(event:MouseEvent):void
		{
			SongPicker.instance.stopSong();
			trace("stop song");
			songFinishedHandler(null);
		}

		protected function fadeOutSongButtonHandler(event:MouseEvent):void
		{
			if (!_buttons.fadeOutSong.enabled)
				return;
			
			SongPicker.instance.removeEventListener(SongPickerEvent.SONG_FINISHED, songFinishedHandler);
			SongPicker.instance.fadeOutSong(2.0);

			
			_buttons.fadeOutSong.enabled = false;
			
			_timeStart = getTimer();
			addEventListener(Event.ENTER_FRAME, fadeDown);
			
		}
		
		protected function fadeDown(event:Event):void
		{
			// fade out button
			var passed:Number = (getTimer() - _timeStart) / 1000;
			if (passed >= 2)
			{
				_buttons.playSong.visible = true;
				_buttons.stopSong.visible = false;
				_buttons.fadeOutSong.visible = false;
				
				removeEventListener(Event.ENTER_FRAME, fadeDown);
			}
			else
			{
				_buttons.fadeOutSong.alpha = (2-passed) / 2;
			}
			
		}
		
		protected function pickSongButtonHandler(event:MouseEvent):void
		{
			// setup song picker - initializing the native extension is sometimes tempermental so it's best to do this
			// some time after the app has started running
			SongPicker.instance.addEventListener(SongPickerEvent.SONG_CHOSEN, songChooseHandler);
			SongPicker.instance.addEventListener(SongPickerEvent.CANCELLED_SONG_PICKER, cancelPickHandler);
			
			
			trace("pickSong...");
			SongPicker.instance.pickSong();
			
		}
		
		protected function volumeDownButtonHandler(event:MouseEvent):void
		{
			if (_volume > 0)
			{
				_volume -= 0.1;
				SongPicker.instance.setVolume(_volume);
				setVolumeText();
			}
			
		}

		protected function volumeUpButtonHandler(event:MouseEvent):void
		{
			if (_volume < 1)
			{
				_volume += 0.1;
				SongPicker.instance.setVolume(_volume);
				setVolumeText();
			}
			
		}
		
		protected function setVolumeText():void
		{
			var volume:Number = SongPicker.instance.getVolume();
			_buttons.volumeTxt.text = "Volume: "+Math.ceil(volume*100)/100;
			trace("Current volume: ", volume);
		}
		
		protected function checkPlayhead(e:Event):void
		{
			_buttons.playheadTxt.text = "Playhead: "+Math.round(SongPicker.instance.getPlayheadTime()*100)/100;
		}
		
		// SongPicker event handlers
		protected function songChooseHandler(event:SongPickerEvent):void
		{
			// show song info
			var duration:Number = event.duration;
			var minutes:int = duration / 60;
			var seconds:int = duration % 60;
			
			var msg:String = "ID: "+event.ID+"\n";
			msg += "title: "+event.title+"\n";
			//msg += "artist: "+event.artist+"\n";
			//msg += "albumTitle: "+event.albumTitle+"\n";
			//msg += "duration: ("+minutes+":"+((seconds < 10) ? "0"+seconds : seconds)+")\n";
			msg += "url: "+event.url;
			
			_buttons.info.text = msg; 
			_chosenSongID = event.ID;
			
			_buttons.playSong.visible = true;
			_started = false;
			
			removeHandlers();
		}
		
		protected function cancelPickHandler(event:Event):void
		{
			removeHandlers();		
		}
		
		protected function songFinishedHandler(event:Event):void
		{
			SongPicker.instance.removeEventListener(SongPickerEvent.SONG_FINISHED, songFinishedHandler);
		
			_buttons.playSong.visible = true;
			_buttons.stopSong.visible = false;
			_buttons.fadeOutSong.visible = false;
		
			removeEventListener(Event.ENTER_FRAME, checkPlayhead);	
		}
		
		private function removeHandlers():void
		{
			SongPicker.instance.removeEventListener(SongPickerEvent.SONG_CHOSEN, songChooseHandler);
			SongPicker.instance.removeEventListener(SongPickerEvent.CANCELLED_SONG_PICKER, cancelPickHandler);
		}
	}
}
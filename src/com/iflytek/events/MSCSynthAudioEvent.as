package com.iflytek.events 
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class MSCSynthAudioEvent extends Event 
	{
		// 公共常量
		public static const AUDIO_GET:String = "audioGet";
		
		// 变量
		private var __data:ByteArray = new ByteArray();
		private var __audioInfo:String = new String();
		private var __synthStatus:int = 0;

		public function MSCSynthAudioEvent(type:String
									  , bubbles:Boolean = false
									  , cancelable:Boolean = false
									  , thedata:ByteArray = null
									  , theaudioInfo:String = ""
									  , thesynthStatus:int = 0) 
		{
			// constructor code
			super(type, bubbles, cancelable);
			
			if(null != thedata)
			{
				thedata.position = 0;
				__data.writeBytes(thedata);
			}
			__audioInfo = theaudioInfo;
			__synthStatus = thesynthStatus;
		}
		
		/*
		 * ****************************************************************
		 * SETTERS/GETTERS
		 * ****************************************************************
		 */
		public function get data():ByteArray
		{
			__data.position = 0;
			
			return __data;
		}
		
		public function get audioInfo():String
		{
			return __audioInfo;
		}
		
		public function get synthStatus():int
		{
			return __synthStatus;
		}
		
				/*
		 * ********************************************************
		 * PUBLIC METHODS
		 * ********************************************************
		 */
		override public function clone():Event
		{
			return this;
		}
		
		override public function toString():String
		{
			var str:String = new String();
			
			str = "[MSCSynthAudioEvent ";
			str += "type=" + type + " ";
			str += "bubbles=" + String(bubbles) + " ";
			str += "cancelable=" + String(cancelable) + " ";
			str += "theaudioInfo=" + __audioInfo + " ";
			str += "thesynthStatus=" + String(__synthStatus);
			str += "data=" + String(__data) + "]";
			
			return str;
		}

	}
	
}

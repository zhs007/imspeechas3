package com.iflytek.events 
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class MSCRecordAudioEvent extends Event
	{
		//公共常量
		public static const AUDIO_ARRIVED:String = "audioArrived";
		
		private var __data:ByteArray = new ByteArray();   //音频数据
		private var __volume:Number = 0;  				  //音量
		
		public function MSCRecordAudioEvent(type:String
									  , bubbles:Boolean = false
									  , cancelable:Boolean = false
									  , thedata:ByteArray = null
									  , thevolume:Number = 0) 
		{
			super(type, bubbles, cancelable);
			if(null != thedata)
			{
				thedata.position = 0;
				__data.writeBytes(thedata);
			}
			__volume = thevolume;
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
		
		public function get volume():Number
		{
			return __volume;
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
			
			str = "[MSCRecordAudioEvent ";
			str += "type=" + type + " ";
			str += "bubbles=" + String(bubbles) + " ";
			str += "cancelable=" + String(cancelable) + " ";
			str += "volume=" + String(__volume) + " ";
			str += "data=" + String(__data) + "]";
			
			return str;
		}

	}
	
}

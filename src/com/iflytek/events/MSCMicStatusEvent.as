package com.iflytek.events 
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class MSCMicStatusEvent extends Event 
	{
		//公共常量
		public static const STATUS:String = "status";
		
		private var __code:String = new String();
		private var __level:String = new String(); 
		
		public function MSCMicStatusEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, thecode:String = "", thelevel:String = "") 
		{
			super(type, bubbles, cancelable);
			
			__code = thecode;
			__level = thelevel;
		}
		
		/*
		 * ****************************************************************
		 * SETTERS/GETTERS
		 * ****************************************************************
		 */
		public function get code():String
		{
			return __code;
		}
		
		public function get level():String
		{
			return __level;
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
			
			str = "[MSCMicStatusEvent ";
			str += "type=" + type + " ";
			str += "bubbles=" + String(bubbles) + " ";
			str += "cancelable=" + String(cancelable) + " ";
			str += "code=" + String(__code) + " ";
			str += "level=" + String(__level) + "]";
			
			return str;
		}

	}
	
}

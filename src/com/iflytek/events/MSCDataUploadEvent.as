package com.iflytek.events 
{
	import flash.events.Event;
	
	public class MSCDataUploadEvent extends Event 
	{
		//公共常量
		public static const EXTEND_ID:String = "extendID";
		
		private var __extendID:String = new String();

		public function MSCDataUploadEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, id:String = "") 
		{
			super(type, bubbles, cancelable);
			__extendID = id;
		}
		
		/*
		 * *********************************************************************************
		 * SETTIERS/GETTERS
		 * *********************************************************************************
		 */
		public function get extendID():String
		{
			return __extendID;
		}
		
		/*
		 * *********************************************************************************
		 * PUBLIC METHODS
		 * *********************************************************************************
		 */
		override public function clone():Event
		{
			return this;
		}
		
		override public function toString():String
		{
			var str:String = new String();
			
			str = "[MSCResultEvent ";
			str += "type=" + type + " ";
			str += "bubbles=" + String(bubbles) + " ";
			str += "cancelable=" + String(cancelable) + " ";
			str += "extendID=" + __extendID + "]";
			
			return str;
		}

	}
	
}

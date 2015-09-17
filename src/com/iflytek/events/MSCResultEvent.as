package com.iflytek.events 
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class MSCResultEvent extends Event 
	{
		//公共常量
		public static const RESULT_GET:String = "resultGet";
		
		private var __result:ByteArray = new ByteArray();
		private var __rsltStatus:int = 0; 
		
		public function MSCResultEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, rslt:ByteArray = null, rsltStatus:int = 0) 
		{
			super(type, bubbles, cancelable);
			
			if( null != rslt && rslt.length > 0 )
			{
				rslt.position = 0;
				__result.writeBytes(rslt);
			}
			__rsltStatus = rsltStatus;
		}
		
		/*
		 * ****************************************************************
		 * SETTERS/GETTERS
		 * ****************************************************************
		 */
		public function get result():ByteArray
		{
			__result.position = 0;
			return __result;
		}
		
		public function get rsltStatus():int
		{
			return __rsltStatus;
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
			
			str = "[MSCResultEvent ";
			str += "type=" + type + " ";
			str += "bubbles=" + String(bubbles) + " ";
			str += "cancelable=" + String(cancelable) + " ";
			str += "result=" + __result + "]";
			
			return str;
		}

	}
	
}

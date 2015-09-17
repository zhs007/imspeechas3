package com.iflytek.msc 
{
	import flash.utils.ByteArray;
	
	public class QISEParseMessageReturns 
	{
		private var out:Array = new Array;

		public function QISEParseMessageReturns(theout:Array) 
		{
			out = theout;
		}
		
		/*
		 * **********************************************************
		 * SETTERS/GETTERS
		 * **********************************************************
		 */
		public function get ret():int
		{
			return int(out[0]);
		}
		
		public function get rslt():String
		{
			return out[1].toString();
		}

	}
	
}
package com.iflytek.msc
{
	
	public class QISESessionBeginReturns 
	{

		private var out:Array = new Array;

		public function QISESessionBeginReturns(theout:Array) 
		{
			out = theout;
		}
		
		/*
		 * *******************************************************
		 * SETTERS/GETTERS
		 * *******************************************************
		 */
		public function get sessionID():String
		{
			return out[0].toString();
		}
		
		public function get ret():int
		{
			return int(out[1]);
		}

	}
	
}

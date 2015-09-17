package com.iflytek.msc  
{
	 
	public class QISRSessionBeginReturns 
	{
		private var out:Array = new Array;

		public function QISRSessionBeginReturns(theout:Array) 
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

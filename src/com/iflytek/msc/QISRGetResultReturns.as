package com.iflytek.msc 
{
	import flash.utils.ByteArray;
	
	public class QISRGetResultReturns 
	{
		private var out:Array = new Array;

		public function QISRGetResultReturns(theout:Array) 
		{
			out = theout;
		}
		
		/*
		 * **********************************************************
		 * SETTERS/GETTERS
		 * **********************************************************
		 */
		public function get rsltStatus():int
		{
			return int(out[0]);
		}
		
		public function get ret():int
		{
			return int(out[1]);
		}
		
		public function get rsltRequestMessage():String
		{
			return out[2].toString();
		}
		
		public function get messageLen():int
		{
			return int(out[3]);
		}

	}
	
}

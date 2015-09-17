package com.iflytek.msc  
{
	import flash.utils.ByteArray;
	
	public class QISEAudioWriteReturns 
	{
		private var out:Array = new Array;
		
		public function QISEAudioWriteReturns(theout:Array) 
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
		
		public function get epStatus():int
		{
			return int(out[1]);
		}
		
		public function get evaluStatus():int
		{
			return out[2];
		}

	}
	
}

package com.iflytek.msc 
{
	import flash.utils.ByteArray;
	
	public class QTTSAudioGetReturns 
	{
		private var out:Array = new Array(4);
		
		public function QTTSAudioGetReturns(theout:Array) 
		{
			if( null != theout && 4 == theout.length )
			{
				out = theout;
			}
		}
		
		/*
		 * *******************************************************
		 * SETTERS/GETTERS
		 * *******************************************************
		 */
		public function get synthStatus():int
		{
			return int(out[0]);
		}
		
		public function get ret():int
		{
			return int(out[1]);
		}
		
		public function get audioDataFetchMsg():ByteArray
		{
			var msg:ByteArray = new ByteArray;
			var len:int = 0;
			
			len = int(out[3]);
			if(len > 0)
			{
				msg.writeMultiByte(out[2].toString(), "GBK");
			}
			
			return msg;
		}

	}
	
}

package com.iflytek.msc 
{
	import flash.utils.ByteArray;
	
	public class QTTSSessionBeginReturns 
	{
		private var out:Array = new Array(4);
		
		public function QTTSSessionBeginReturns(theout:Array) 
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
		public function get sessionID():String
		{
			return out[0].toString();
		}
		
		public function get ret():int
		{
			return int(out[1]);
		}
		
		public function get sessionBeginMsg():ByteArray
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

﻿package com.iflytek.msc 
{
	import flash.utils.ByteArray;
	
	public class QISRParseMessageReturns 
	{
		private var out:Array = new Array;

		public function QISRParseMessageReturns(theout:Array) 
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

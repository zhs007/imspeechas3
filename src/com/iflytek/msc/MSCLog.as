package com.iflytek.msc
{
	import flash.utils.ByteArray;
	import flash.net.FileReference;
	
	public class MSCLog 
	{
		public const MAXLOGLEN:uint = 5 * 1024 * 1024;
		
		public var msclog:ByteArray = new ByteArray;
		public var output:Boolean = false;
		
		public function MSCLog() 
		{
			
		}
		
		/*
		 * **********************************************************
		 * PUBLI METHODS
		 * **********************************************************
		 */
		public function logDBG(info:String):void
		{
			var str:String = new String();
			
			if(!output)
			{
				return;
			}
			
			str = logCurTime();
			str += "[VBS]";        // 日志等级
			str += "[flash   ]";   // 主题信息
			str += "[Px0001] ";     // 模块id
			
			str += info;
			str += "\n";
			
			msclog.writeMultiByte(str, "GBK");
		}
		
		public function logSave():void
		{
			var fileRefenrence:FileReference = new FileReference();
			fileRefenrence.save( msclog, "msc.log" );
			msclog.clear();
		}
		
		/*
		 * **********************************************************
		 * PRIVATE METHODS
		 * **********************************************************
		 */
		private function logCurTime():String
		{
			var curDate:Date = new Date();
			var str:String = new String();
			
			var curYear:String = String(curDate.getUTCFullYear());  // 返回四位数字的本地年份
			
			str = "[";
			str += curYear.slice(2, 4);
			str += "/";
			str += convertNumToStr(curDate.getUTCMonth() + 1, 10);
			str += "/";
			str += convertNumToStr(curDate.getUTCDate(), 10);
			str += "-";
			str += convertNumToStr(curDate.getUTCHours(), 10);
			str += ":";
			str += convertNumToStr(curDate.getUTCMinutes(), 10);
			str += ":";
			str += convertNumToStr(curDate.getUTCSeconds(), 10);
			str += " ";
			str += convertNumToStr(curDate.getUTCMilliseconds(), 100);
			str += "]";
			
			return str;
		}
		
		private function convertNumToStr(num:Number, numOfDigit:int):String
		{
			var str:String = new String();
			
			// 1034及其以前的版本时间不注意对齐
//			if(10 == numOfDigit && num < 10 && num >= 0)
//			{
//				str = "0";
//			}
//			else if(100 == numOfDigit && num < 100 && num >= 0)
//			{
//				if(num < 10)
//				{
//					str = "00"
//				}
//				else
//				{
//					str = "0"
//				}
//			}
			str += String(num);
			
			return str;
		}

	}
	
}

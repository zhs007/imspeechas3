package com.xfan.amras3
{
	import com.xfan.amras3.flascc.CModule;
	import com.xfan.amras3.flascc.amras3_decodeex;
	import com.xfan.amras3.flascc.amras3_encodeex;
	import com.xfan.amras3.flascc.ram;
	
	import flash.utils.ByteArray;
	
	public class Codec
	{
		static public function encode(src:ByteArray):ByteArray
		{
			src.position = 0;
			var srcram:int = CModule.malloc(src.length);
			CModule.writeBytes(srcram, src.length, src);
			
			var destram:int = CModule.malloc(src.length);
			
			var len:int = amras3_encodeex(srcram, src.length, destram);
			var buff:ByteArray = new ByteArray;
			CModule.readBytes(destram, len, buff);
			
			CModule.free(srcram);
			CModule.free(destram);
			
			return buff;
		}
		
		static public function decode(src:ByteArray):ByteArray
		{
			src.position = 0;
			var srcram:int = CModule.malloc(src.length);
			CModule.writeBytes(srcram, src.length, src);
			
			var valram:int = CModule.malloc(8);
			
			amras3_decodeex(srcram, src.length, valram);
			var destram:int = CModule.read32(valram);
			var destlen:int = CModule.read32(valram + 4);
			
			var buff:ByteArray = new ByteArray;
			CModule.readBytes(destram, destlen, buff);
			
			CModule.free(srcram);
			CModule.free(destram);
			CModule.free(valram);
			
			return buff;
		}
	}
}
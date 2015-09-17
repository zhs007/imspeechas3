package nslm2.nets.imsdk
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class IMUtil
	{
		public static function createByteArray():ByteArray
		{
			var ba:ByteArray = new ByteArray();
			ba.endian = Endian.BIG_ENDIAN;
			return ba;	
		}
	}
}
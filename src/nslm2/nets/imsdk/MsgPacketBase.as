package nslm2.nets.imsdk
{
	import flash.utils.ByteArray;

	public interface MsgPacketBase
	{	
		// 处理接收到的数据
		function procRecvBuffer(socket:IMSocket, buff:ByteArray, msgbegin:int):void;
		// 发送消息
		function sendMsgPacket(socket:IMSocket, msgid:String, buff:String):void;
	}
}
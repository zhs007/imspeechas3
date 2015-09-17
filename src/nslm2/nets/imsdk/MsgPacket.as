package nslm2.nets.imsdk
{
	import flash.utils.ByteArray;
	
	public class MsgPacket implements MsgPacketBase
	{
		private var _bufHeader:ByteArray;
		private var _needheadlen:int;
		private var _needbuflen:int;
		private var _msgbuf:ByteArray;
		
		private static var _msgver:String = "0.01";
		
		public function MsgPacket()
		{
			_bufHeader = IMUtil.createByteArray();
			_needheadlen = 10;
			_needbuflen = 0;
		}
		
		public function onRecvHeader(buf:ByteArray):MsgHeader
		{	
			var header:MsgHeader = new MsgHeader();
			
			buf.position = 0;
			
			header.buffLen = buf.readInt() - 6;
			
			var bymsgid:ByteArray = new ByteArray();
			var bymsgver:ByteArray = new ByteArray();
			
			buf.readBytes(bymsgid, 0, 2);
			buf.readBytes(bymsgver, 0, 4);
			
			header.msgid = bymsgid.toString();
			header.msgver = bymsgver.toString();
			
			_needheadlen = 0;
			_needbuflen = header.buffLen;
			_msgbuf = IMUtil.createByteArray();
			
			return header;
		}
		
		public function procRecvBuffer(socket:IMSocket, buff:ByteArray, msgbegin:int):void 
		{
			var msgindex:int = msgbegin;
			
			if (_needheadlen > 0) {
				if (_needheadlen <= buff.length - msgindex) {
					buff.readBytes(_bufHeader, 0, _needheadlen);
					msgindex += _needheadlen;
					_needheadlen = 0;
					
					var header:MsgHeader = onRecvHeader(_bufHeader);
					
					if (_needbuflen == 0) {
						socket.onMessage(header, _msgbuf);
					}
					
					if (msgindex == buff.length) {
						return ;
					}
				}
				else {
					buff.readBytes(_bufHeader, 0, 0);
					_needheadlen -= buff.length;
					
					return ;
				}
			}
			
			if (_needbuflen <= buff.length - msgindex) {
				buff.readBytes(_msgbuf, 0, _needbuflen);
				
				msgindex += _needbuflen;
				_needbuflen = 0;
				
				_needheadlen = 10;
				
				socket.onMessage(header, _msgbuf);
				
				if (msgindex == buff.length) {
					return ;
				}
				
				procRecvBuffer(socket, buff, msgindex);
			}
			else {
				buff.readBytes(_msgbuf, 0, 0);
				_needheadlen -= (buff.length - msgindex);
			}
		}
		
		public function sendMsgPacket(socket:IMSocket, msgid:String, buff:String):void {
			var msg:ByteArray = IMUtil.createByteArray();
			
			// 取字符串的字节长度，最好换个正常算法吧......
			var buftmp:ByteArray = IMUtil.createByteArray();
			buftmp.writeMultiByte(buff, 'utf-8');
			
			msg.writeInt(buftmp.length + 6);
			msg.writeUTFBytes(msgid);
			msg.writeUTFBytes(_msgver);
			msg.writeMultiByte(buff, 'utf-8');
			
			socket.sendBuff(msg);
			
		}
	}
}
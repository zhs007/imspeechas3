package nslm2.nets.imsdk
{    
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	[Event(name="onPack", type="nslm2.nets.imsdk.IMEvent")]
	[Event(name="onConnect", type="nslm2.nets.imsdk.IMEvent")]
	[Event(name="onDisconnect", type="nslm2.nets.imsdk.IMEvent")]
	public class IMSocket extends EventDispatcher
	{
		// 因为一个客户端可能有多个socket连接，所以这个类不是 singleton 的
		
		private var _socket:Socket = null;					// socket
		
		private var _host:String;							// 服务器ip
		private var _port:uint;								// 服务器端口
		
		private var _packet:MsgPacketBase = null;			// 消息封包解包模块，以后改这个模块就可以适应不同的服务器了
		
		private var _retryId:int = 0;						// 重连的回调ID，停止延时用
		private var _reconnNums:uint = 0;					// 重连次数
		
		// 构造函数
		public function IMSocket()
		{
		}
		
		// 初始化
		public function init(host:String, port:uint, msgpacket:MsgPacketBase = null):void
		{
			// 如果没有传入一个合理的 MsgPacketBase，就新建一个 MsgPacket
			if (msgpacket == null) {
				_packet = new MsgPacket;
			}
			else {
				_packet = msgpacket;
			}
			
			// 记录服务器连接数据，重连用
			_host = host;
			_port = port;

			// 初始化 socket
			_socket = new Socket();
			
			// 绑定一组必须处理的 Event
			_socket.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			_socket.addEventListener(Event.CLOSE, onClose);
			_socket.addEventListener(Event.CONNECT, onConn);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, onData);
			
			// 连接
			tryConnect();
		}
		// 主动断开连接
		public function disconnect():void
		{
			if (_socket != null) {
				_socket.close();
			}
		}
		
		// 重新连接
		private function reconnect():void
		{
			if (_retryId != 0) {
				clearTimeout(_retryId);
			}
			
			_retryId = setTimeout(tryConnect, _reconnNums * 1000);
		}
		// IO错误
		private function onIoError(evt:IOErrorEvent):void
		{
			reconnect();
		}	
		// 安全沙箱错误
		private function onSecurityError(evt:SecurityErrorEvent):void
		{
			reconnect();
		}
		// 断开连接，这时不要主动重连，把决定权交给上层逻辑
		private function onClose(evt:Event):void
		{
			dispatchEvent(new IMEvent(IMEvent.ON_DISCONNECT));
		}
		// 连接成功以后调用，通知上层逻辑
		private function onConn(evt:Event):void
		{
			dispatchEvent(new IMEvent(IMEvent.ON_CONNECT));
		}
		// 尝试连接
		public function tryConnect():void {
			_reconnNums++;

			// 连接
			try {
				_socket.connect(_host, _port);	
			}
			catch(err:Error) {
				onSecurityError(null);
			}
		};
		// 接收数据处理，这里是字节数据流
		private function onData(evt:ProgressEvent):void
		{
			var buff:ByteArray = IMUtil.createByteArray();
			_socket.readBytes(buff, 0, 0);
			_packet.procRecvBuffer(this, buff, 0);
		}
		// 解析完成以后的回调，这里就已经是单独的消息通知了
		public function onMessage(header:MsgHeader, buff:ByteArray):void
		{
			var e:IMEvent = new IMEvent(IMEvent.ON_PACK);
			
			e.header = header;
			e.msg = buff.toString();
			
			trace('onMessage ' + header.msgid + ' ' + e.msg);
			
			dispatchEvent(e);
		}
		// 最底层的发送接口，发送数据流，这个接口给msgpacket调用的
		public function sendBuff(buff:ByteArray):void
		{
			_socket.writeBytes(buff);
			_socket.flush();
		}
		// 消息层的封装，其实这里只支持字符串数据了，后面可能需要字节流的
		public function sendMsg(msgid:String, msg:String):void
		{
			trace('sendMsg ' + msgid + ' ' + msg);
			_packet.sendMsgPacket(this, msgid, msg);
		}
	}
}
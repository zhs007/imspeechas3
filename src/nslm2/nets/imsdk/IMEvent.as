package nslm2.nets.imsdk
{
	import flash.events.Event;
	
	public class IMEvent extends Event
	{
		public static const ON_PACK:String = "onPack";
		public static const ON_CONNECT:String = "onConnect";
		public static const ON_DISCONNECT:String = "onDisconnect";
		public static const ON_CHATMESSAGE:String = "onChatMessage";
		public static const ON_LOGIN_SUCCESS:String = "onLoginSuccess";
		
		public var header:MsgHeader;
		public var msg:String;
		
		public var chat:ChatMessage;
		
		public function IMEvent(type:String)
		{
			super(type);
		}
	}
}
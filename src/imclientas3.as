package
{
	import com.iflytek.msc.Recognizer;
	
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import nslm2.nets.imsdk.IMClient;
	import nslm2.nets.imsdk.IMEvent;
	import nslm2.nets.imsdk.IMSpeechOpenApi;
	import nslm2.nets.imsdk.IMSpeech;
	
	public class imclientas3 extends Sprite
	{
		public var lstClient:Vector.<IMClient> = new Vector.<IMClient>;
		
		private var recog:Recognizer = null;
		private const configs:String 	= "appid=55c055cd,timeout=2000";
		private var isLogPrepared:Boolean = false;
		private var _state:String = '';
		private var recording_data:ByteArray = new ByteArray;
		
		private var sprAT:AudioChat;
		
		public function imclientas3()
		{
//			sprAT = new SampleIAT(stage);
//			sprAT.x = 0;
//			sprAT.y = 0;
//			addChild(sprAT);
			
			sprAT = new AudioChat();
			sprAT.x = 0;
			sprAT.y = 0;
			addChild(sprAT);
			
			for (var i:int = 0; i < 2; ++i)
			{
				var client:IMClient = new IMClient;
				
				client.setBaseConfig('g003', 'UwICslqH');
				client.setMyUserInfo('s01', 'u1001' + i);
				client.addChannel('s01', 'world', '123', 'rw', '001');
				client.addChannel('s01', 'guid', '456', 'rw', '002');
				client.init('10.1.1.149', 8999);
				
				client.addEventListener(IMEvent.ON_CHATMESSAGE, onChatMessage);
				
				lstClient.push(client);
			}
			
			setTimeout(onPrivateChat, 500);
			setTimeout(onChannelChat, 500);
			
			IMSpeechOpenApi.getIMClient().setBaseConfig('g003', 'UwICslqH');
			IMSpeechOpenApi.getIMClient().setMyUserInfo('s01', 'u1001' + i);
			IMSpeechOpenApi.getIMClient().addChannel('s01', 'world', '123', 'rw', '001');
			IMSpeechOpenApi.getIMClient().addChannel('s01', 'guid', '456', 'rw', '002');
			IMSpeechOpenApi.init(IMSpeech.MODESDK_BAIDU, "55c055cd", "dev.voicecloud.cn", '10.1.1.149', 8999);
			//setInterval(onChannelChat, 500);
		}
		
		public function onPrivateChat():void
		{
			var max:int = lstClient.length;
			for (var i:int = 0; i < 2; ++i)
			{	
				var nexti:int = i + 1;
				if (nexti >= max)
				{
					nexti = 0;
				}
				
				//lstClient[i].requestPrivatechat('s01', 'u1001' + nexti, 'text', '哈哈我是中文聊天！' + Math.random() * 10000, '', onChatCallback);
			}
		}
		
		public function onChannelChat():void
		{
			var max:int = lstClient.length;
			for (var i:int = 0; i < 2; ++i)
			{	
				var nexti:int = i + 1;
				if (nexti >= max)
				{
					nexti = 0;
				}
				
				//lstClient[i].requestGroupchat('s01', '123', 'text', '哈哈我是中文聊天！' + Math.random() * 10000, '', onChatCallback);
			}
		}
		
		private function onChatMessage(e:IMEvent):void
		{
			trace('imclientas3 onChatMessage ' + JSON.stringify(e.chat));
		}
		
		private function onChatCallback(msgid:String, msg:Object, isok:Boolean, err:String):void
		{
			trace('imclientas3 onChatCallback ' + msgid + ' ' + isok + ' ' + err);
		}
	}
}
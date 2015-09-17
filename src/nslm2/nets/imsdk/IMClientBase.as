package nslm2.nets.imsdk
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	public class IMClientBase extends EventDispatcher
	{
		protected var socket:IMSocket = new IMSocket;
		public var myuserinfo:UserInfo = new UserInfo;
		public var config:nslm2.nets.imsdk.Config = new nslm2.nets.imsdk.Config;
		private var dictMsgProc:Dictionary = new Dictionary;
		private var lstChatRequest:Vector.<ChatRequest> = new Vector.<ChatRequest>;
		
		public function IMClientBase()
		{
			socket.addEventListener(IMEvent.ON_PACK, onPack);
		}
		
		private function onPack(e:IMEvent):void
		{
			onMsgProc(e.header.msgid, e.msg);
		}
		
		// proc(msgid, msg)
		protected function addMsgProc(msgid:String, proc:Function):void
		{
			dictMsgProc[msgid] = proc;
		}
		
		protected function onMsgProc(msgid:String, msg:String):void
		{
			if (dictMsgProc[msgid])
			{
				dictMsgProc[msgid].call(this, msgid, msg);
			}
		}
		
		// 设置gid和md5key
		public function setBaseConfig(gid:String, md5key:String):void
		{
			config.gid = gid;
			config.md5key = md5key;
		}
		
		// 设置服务器id和用户id
		public function setMyUserInfo(sid:String, rid:String):void
		{
			myuserinfo.sid = sid;
			myuserinfo.rid = rid;
		}
		
		public function init(host:String, port:uint):void
		{
			socket.init(host, port);
		}
		
		public function disconnect():void
		{
			socket.disconnect();
		}
		
		// 增加侦听的频道
		public function addChannel(sid:String, type:String, id:String, perm:String, code:String):void 
		{
			var ci:ChannelInfo = new ChannelInfo;
			
			ci.sid = sid;
			ci.type = type;
			ci.id = id;
			ci.perm = perm;
			ci.code = code;
			
			myuserinfo.lstChannel.push(ci);
		}
		
		// 查找侦听的频道
		public function findChannel(sid:String, id:String):ChannelInfo 
		{
			for (var i:int = 0; i < myuserinfo.lstChannel.length; ++i) 
			{
				if (myuserinfo.lstChannel[i].sid == sid && myuserinfo.lstChannel[i].id == id) 
				{
					return myuserinfo.lstChannel[i];
				}
			}
			
			return null;
		}
		
		// 取消侦听的频道
		public function removeChannel(sid:String, id:String):void 
		{
			for (var i:int = 0; i < myuserinfo.lstChannel.length; ++i) 
			{
				if (myuserinfo.lstChannel[i].sid == sid && myuserinfo.lstChannel[i].id == id) 
				{
					myuserinfo.lstChannel.splice(i, 1);
					
					break;
				}
			}
		}
		// 处理SI消息的gps
		protected function procSI_gps(obj:Object):String 
		{
			var gps:Array = new Array;
			
			for (var i:int = 0; i < myuserinfo.lstChannel.length; ++i) 
			{
				var ci:ChannelInfo = new ChannelInfo();
				
				ci.sid = myuserinfo.lstChannel[i].sid;
				ci.id = myuserinfo.lstChannel[i].id;
				ci.type = myuserinfo.lstChannel[i].type;
				ci.perm = myuserinfo.lstChannel[i].perm;
				ci.code = myuserinfo.lstChannel[i].code;
				
				gps.push(ci);
			}
			
			var str:String = JSON.stringify(gps);
			return Base64.encode(str);
		}
		// 处理SI消息的sign
		protected function procSI_sign(obj:Object):String 
		{
			var str:String = obj.gid + obj.gps + obj.rid + obj.sid + config.md5key;
			
			return MD5.hash(str);
		}
		// 处理SP SG消息的seq
		protected function procSPSG_seq(obj:Object):String 
		{
			myuserinfo.curseq++;
			return myuserinfo.curseq.toString();
		}
		// 处理SG消息的seq
		protected function procSG_gpType(obj:Object):String 
		{
			for (var i:int = 0; i < myuserinfo.lstChannel.length; ++i) 
			{
				if (myuserinfo.lstChannel[i].sid == obj.toSid && myuserinfo.lstChannel[i].id == obj.gpid) 
				{
					return myuserinfo.lstChannel[i].type;
				}
			}
			
			return "";
		}
		
		protected function onChatMessage(obj:Object):void
		{
			var chatmsg:ChatMessage = new ChatMessage;
			
			chatmsg.content = obj.msg.content;
			chatmsg.id = obj.msg.id;
			chatmsg.rid = obj.msg.rid;
			chatmsg.tag = obj.msg.tag;
			chatmsg.ts = obj.msg.ts;
			chatmsg.type = obj.msg.type;
			chatmsg.seq = obj.seq;
			chatmsg.sid = obj.sid;
			chatmsg.url = obj.msg.url;
			chatmsg.ext = obj.msg.ext;
			
			if (obj.gpSid)
			{
				chatmsg.sid = obj.gpSid;
			}
			
			if (obj.gpType)
			{
				chatmsg.gpType = obj.gpType;
			}
			
			if (obj.gpid)
			{
				chatmsg.gpid = obj.gpid;
			}
			
			var e:IMEvent = new IMEvent(IMEvent.ON_CHATMESSAGE);
			e.chat = chatmsg;
			
			trace('onChatMessage ' + JSON.stringify(chatmsg));
			
			dispatchEvent(e);
		}
		
		protected function onMyChatMessage(mymsg:Object, retmsg:Object):void
		{
			var chatmsg:ChatMessage = new ChatMessage;
			
			chatmsg.content = mymsg.msg.content;
			chatmsg.id = retmsg.mid;
			chatmsg.rid = myuserinfo.rid;
			chatmsg.tag = mymsg.msg.tag;
			//chatmsg.ts = obj.msg.ts;
			chatmsg.type = mymsg.msg.type;
			chatmsg.seq = retmsg.seq;
			chatmsg.sid = mymsg.sid;
			chatmsg.url = mymsg.url;
			chatmsg.ext= mymsg.msg.ext;
			
			if (mymsg.gpType)
			{
				chatmsg.gpType = mymsg.gpType;
			}
			
			if (mymsg.gpid)
			{
				chatmsg.gpid = mymsg.gpid;
			}
			
			var e:IMEvent = new IMEvent(IMEvent.ON_CHATMESSAGE);
			e.chat = chatmsg;
			
			trace('onMyChatMessage ' + JSON.stringify(chatmsg));
			
			dispatchEvent(e);
		}
		
		// 自己的聊天数据需要自己通知下去
		protected function onChatRequest(msgid:String, msg:Object):void
		{
			for (var i:int = 0; i < lstChatRequest.length; ++i)
			{
				if (msgid == lstChatRequest[i].msgid && msg.seq == lstChatRequest[i].msg.seq)
				{
					if (msg.code == "00")
					{
						onMyChatMessage(lstChatRequest[i].msg, msg);
						
						if (lstChatRequest[i].func) 
						{
							lstChatRequest[i].func(lstChatRequest[i].msgid, lstChatRequest[i].msg, true, '');
						}
						else
						{
							lstChatRequest[i].func(lstChatRequest[i].msgid, lstChatRequest[i].msg, false, msg.desc);
						}
					}
					
					lstChatRequest.splice(i, 1);
					
					break;
				}
			}
		}
		
		// callback(msgid, msg, isok, err)
		protected function addChatRequest(msgid:String, msg:Object, callback:Function):void
		{
			var request:ChatRequest = new ChatRequest;
			
			request.msgid = msgid;
			request.msg = msg;
			request.func = callback;
			
			lstChatRequest.push(request);
		}
	}
}
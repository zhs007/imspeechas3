package nslm2.nets.imsdk
{
	public class IMClient extends IMClientBase
	{
		public function IMClient()
		{
			super();
			socket.addEventListener(IMEvent.ON_CONNECT, onConnect);
			addMsgProc("SI", onMsg_loginret);
			addMsgProc("TP", onMsg_privatechat);
			addMsgProc("TG", onMsg_groupchat);
			addMsgProc("SP", onMsg_privatechatret);
			addMsgProc("SG", onMsg_groupchatret);
			addMsgProc("FP", onMsg_getofflinemsgret);
			addMsgProc("FG", onMsg_getgroupofflinemsgret);
			addMsgProc("KO", onMsg_ko);
		}
		
		// 
		public function onMsg_loginret(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
				config.servts = objmsg.ts;
				if(objmsg.code == "00"){
					var e:IMEvent = new IMEvent(IMEvent.ON_LOGIN_SUCCESS);
					dispatchEvent(e);
				}
			}
		}
		
		// 
		public function onMsg_privatechat(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
				onChatMessage(objmsg);
			}
		}
		
		// 
		public function onMsg_groupchat(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
				onChatMessage(objmsg);
			}
		}
		
		// 
		public function onMsg_privatechatret(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
				onChatRequest(msgid, objmsg);
			}
		}
		
		// 
		public function onMsg_groupchatret(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
				onChatRequest(msgid, objmsg);
			}
		}
		
		// 
		public function onMsg_getofflinemsgret(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
			}
		}
		
		// 
		public function onMsg_getgroupofflinemsgret(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
			}
		}
		
		// 
		public function onMsg_ko(msgid:String, msg:String):void
		{
			if (msg.length > 0)
			{
				var objmsg:Object = JSON.parse(msg);
			}
		}
		
		private function onConnect(e:IMEvent):void
		{
			requestLogin();
		}
		
		
		//
		public function requestLogin():void
		{
			var obj:Object = new Object;
			obj.gid = config.gid;
			obj.sid = myuserinfo.sid;
			obj.rid = myuserinfo.rid;
			obj.gps = procSI_gps(obj);
			obj.sign = procSI_sign(obj);
			var strsend:String = JSON.stringify(obj);
			socket.sendMsg('SI', strsend);
		}
		
		//
		public function requestPrivatechat(sid:String, rid:String, type:String, content:String, tag:String, url:String, ext:Object, callback:Function):void
		{
			var obj:Object = new Object;
			obj.toSid = sid;
			obj.toRid = rid;
			obj.msg = new Object;
			obj.msg.type = type;
			obj.msg.content = content;
			obj.msg.tag = tag;
			obj.msg.ext = ext;
			obj.msg.url = url;
			obj.seq = procSPSG_seq(obj);
			var strsend:String = JSON.stringify(obj);
			addChatRequest('SP', obj, callback);
			socket.sendMsg('SP', strsend);
		}
		
		//
		public function requestGroupchat(sid:String, gpid:String, type:String, content:String, tag:String, url:String, ext:Object, callback:Function):void
		{
			var obj:Object = new Object;
			obj.toSid = sid;
			obj.gpid = gpid;
			obj.msg = new Object;
			obj.msg.type = type;
			obj.msg.content = content;
			obj.msg.tag = tag;
			obj.msg.ext = ext;
			obj.msg.url = url;
			obj.seq = procSPSG_seq(obj);
			obj.gpType = procSG_gpType(obj);
			var strsend:String = JSON.stringify(obj);
			addChatRequest('SG', obj, callback);
			socket.sendMsg('SG', strsend);
		}
		
		public function requestGroupOffLine(type:String, id:String, index:int, count:int):void{
			var obj:Object = new Object;
			obj.type = type;
			obj.id = id;
			obj.index = index;
			obj.count = count;
			var strsend:String = JSON.stringify([obj]);
			socket.sendMsg('FG', strsend);		
		}
		
	}
}
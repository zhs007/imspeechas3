package nslm2.nets.imsdk
{
//	import com.iflytek.define.RATE;
//	import com.iflytek.events.MSCErrorEvent;
//	import com.iflytek.events.MSCEvent;
//	import com.iflytek.events.MSCMicStatusEvent;
//	import com.iflytek.events.MSCRecordAudioEvent;
//	import com.iflytek.events.MSCResultEvent;
//	import com.iflytek.msc.Recognizer;
//	
//	import flash.utils.ByteArray;
	
	public class IMSpeechOpenApi
	{
		
		static public function init(sdkmode:int, xfappid:String, xfhost:String, host:String, port:int):void
		{
			IMSpeech.getInstance().setSDKMode(sdkmode);
			IMSpeech.getInstance().init(xfappid, xfhost, host, port);
		}
		
		// 开始录音
		// callback(state:int, buff:ByteArray, result:String, url:String)
		static public function startRecord(callback:Function):void
		{
			IMSpeech.getInstance().startRecord(callback);
		}
		
		// 停止录音
		static public function stopRecord():void
		{
			IMSpeech.getInstance().stopRecord();
		}
		
		// 播放声音，理论上支持混音，就是同时放多个
		static public function playSound(url:String):void
		{
			IMSpeech.getInstance().playSound(url);
		}
		
		// 发送私聊消息
		static public function sendPersonalMsg(sid:String, rid:String, type:String, content:String, tag:String, url:String, ext:Object, callback:Function):void
		{
			IMSpeech.getInstance().sendPersonalMsg(sid, rid, type, content, tag, url, ext, callback);
		}
		
		// 发送群组消息
		static public function sendGroupMsg(sid:String, gpid:String, type:String, content:String, tag:String, url:String, ext:Object, callback:Function):void
		{
			IMSpeech.getInstance().sendGroupMsg(sid, gpid, type, content, tag, url, ext, callback);
		}
		
		// 获取离线群组消息
		static public function receiveGroupMsg(type:String, id:String, index:int, count:int):void
		{
			IMSpeech.getInstance().receiveGroupMsg(type, id, index, count);
		}
		
		// 获得IMClient
		static public function getIMClient():IMClient
		{
			return IMSpeech.getInstance().client;
		}
	}
}
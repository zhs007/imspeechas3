package nslm2.nets.imsdk
{
	import com.adobe.audio.IRecordListener;
	import com.adobe.audio.record;
	import com.adobe.audio.format.WAVWriter;
	import com.iflytek.define.RATE;
	import com.iflytek.events.MSCErrorEvent;
	import com.iflytek.events.MSCEvent;
	import com.iflytek.events.MSCMicStatusEvent;
	import com.iflytek.events.MSCRecordAudioEvent;
	import com.iflytek.events.MSCResultEvent;
	import com.iflytek.msc.MSCLog;
	import com.iflytek.msc.Recognizer;
	import com.jonas.net.Multipart;
	import com.ru.etcs.media.WaveSound;
	import com.xfan.amras3.Codec;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.StatusEvent;
	import flash.media.Sound;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import fr.kikko.lab.ShineMP3Encoder;

	public class IMSpeech implements IRecordListener
	{
		private static var _instance:IMSpeech = null;						// singleton 实例
		private static var _allowInstantiation:Boolean = false;				// 因为 as3 没办法让构造函数私有
																			// 所以这个用来禁止非法的实例化
		
		public static const STATE_FREE:int = 0;								// 未初始化
		public static const STATE_INIT:int = 1;								// 初始化
		public static const STATE_RECORDING:int = 2;						// 录音中
		public static const STATE_STOPRECORDING:int = 3;					// 停止录音中
		public static const STATE_ENDIAT:int = 4;							// 语音识别结束
		public static const STATE_MP3ENCODEING:int = 5;						// mp3
		public static const STATE_UPLOADING:int = 6;						// uploading
		public static const STATE_COMPLETE:int = 7;							// complete
		public static const STATE_IATERR:int = 8;							// 语音解析错误
		public static const STATE_MP3ERR:int = 9;							// mp3解码错误
		public static const STATE_UPLOADERR:int = 10;						// 上传错误
		
		public static const MODESDK_IFLYTEK:int = 1;						// 训飞库
		public static const MODESDK_BAIDU:int = 2;							// 百度库
		
		// 讯飞的配置
		//private static const _XFCONFIG:String = "appid=55c055cd,timeout=2000";
		
		// 平台的配置
		private static const _UPLOADURL:String = "http://imsdk.youzu.com/file/upload.json";
		private static const _DOWNLOADURL:String = "http://imsdk.youzu.com/file/download?fileId=";
		private static const _POSTAMRURL:String = "http://imsdk.youzu.com/file/uploadAndTrans.json";
		
		private var _recog:Recognizer = null;								// 讯飞的主实例
		private var _curState:int = STATE_FREE;								// 当前状态
		private var _recording_data:ByteArray = null;						// 录音音频数据
		private var _result:String = '';									// 语音识别结果
		private var _url:String = '';										// url
		
		private var _record:record = null;									// record
		
		private var _mp3Encoder:ShineMP3Encoder;							// mp3 encoder
		
		private var _curCallback:Function;									// 当前录音状态改变时调用
		
		private var _client:IMClient = new IMClient;						// socket client
		
		private var _modeSDK:int = MODESDK_IFLYTEK;							// 默认用训飞SDK 
		
		private var _buffAMR:ByteArray = null;								// 
		private var _urlloaderAMR:URLLoader = null;
		
		// getter client
		public function get client():IMClient 
		{
			return _client;
		}
		
		// getSingleton
		public static function getInstance():IMSpeech 
		{
			if (_instance == null) {
				_allowInstantiation = true;
				_instance = new IMSpeech();
				_allowInstantiation = false;
			}
			
			return _instance;
		}
		
		// 构造函数
		public function IMSpeech()
		{
			if (!_allowInstantiation) {
				throw new Error("Error: Instantiation failed: Use IMSpeech.getInstance() instead of new.");
			}
		}
		
		// IRecordListener
		public function recordStatus(e:StatusEvent):void
		{
			trace("recordStatus:" + e);
		}
		// IRecordListener
		public function sampleDataProcess(sampleData:ByteArray, volume:int):void
		{
			trace("sampleDataProcess");
			
			if(sampleData.length > 0)
			{
				// 把64位音频转化为32位的
				var wavWrite:WAVWriter = new WAVWriter();
				var wav:ByteArray = new ByteArray();
				
				wavWrite.numOfChannels = 1;        // 单声道
				wavWrite.sampleBitRate = 16;       // 单点数据存储位数
				wavWrite.samplingRate = 8000;
				
				wavWrite.processSamples(wav, sampleData, 8000, 1);
				
				_recording_data.writeBytes(wav);
				
				wav.clear();
			}
		}
		// IRecordListener
		public function recordError(id:int, text:String):void
		{
			trace("onError " + id + " " + text);
			
			_recog.recogStop();
			
			chgState(STATE_IATERR);
		}
		
		// 设置SDK模式，必须在初始化以前调用
		public function setSDKMode(mode:int):void
		{
			if (_curState != STATE_FREE) {
				throw new Error("Error: IMSpeech already init.");
			}
			
			_modeSDK = mode;
		}
		
		private function postAMR():void 
		{	
			var form:Multipart = new Multipart(_POSTAMRURL);
			
			form.addFile("file", _buffAMR, "application/octet-stream", "tmp.amr");
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onPostAMRComplete);
			loader.load(form.request);
			
			chgState(STATE_UPLOADING);
		}
		
		private function onPostAMRComplete(evt:Event):void 
		{
			var loader:URLLoader = URLLoader(evt.target);
			
			//{"code":"00","desc":"成功","fileId":"group2/M00/03/02/CgNGCVXSr7KAFDdJAAAv9GuhhwI217.mp3"}
			trace("completeHandler: " + loader.data);
			var ret:Object = JSON.parse(loader.data);
			if (ret.code == '00') {
				_url = ret.fileId;
			}
			
			_result = ret.content;
			
			chgState(STATE_COMPLETE);
			
			//			if (_curCallback != null) {
			//				_curCallback(_mp3Encoder.mp3Data, _result);
			//			}
		}
		
		// 改变状态时调用
		private function chgState(state:int):void
		{
			_curState = state;
			
			if (_curCallback != null) {
				if (_curState == STATE_COMPLETE) {
					if (_modeSDK == MODESDK_IFLYTEK) {
						_curCallback(state, _mp3Encoder.mp3Data, _result, _url);
					}
					else if (_modeSDK == MODESDK_BAIDU) {
						_curCallback(state, _buffAMR, _result, _url);
					}
				}
				else if (_curState == STATE_ENDIAT) {
					_curCallback(state, _recording_data, _result, '');
				}
				else {
					_curCallback(state, null, '', '');
				}
			}
		}
		// 初始化
		public function init(xfappid:String, xfhost:String, host:String, port:int):void
		{
			release();
			
			_client.init(host, port);
			
			_recording_data = new ByteArray;
			
			if (_modeSDK == MODESDK_IFLYTEK) {
				_recog = new Recognizer("appid=" + xfappid + ",timeout=2000", "dev.voicecloud.cn", 7);
				
				_recog.addEventListener(MSCMicStatusEvent.STATUS, onMicrophoneStatus);
				_recog.addEventListener(MSCRecordAudioEvent.AUDIO_ARRIVED, onRecording);
				_recog.addEventListener(MSCErrorEvent.ERROR, onError);
				_recog.addEventListener(MSCResultEvent.RESULT_GET, onGettingResult);
				_recog.addEventListener(MSCEvent.RECOG_COMPLETED, onComplete);
			}
			else if (_modeSDK == MODESDK_BAIDU) {
				_record = new record(8, this, new MSCLog);
			}
			
			chgState(STATE_INIT);
		}
		// 释放
		public function release():void
		{
			if (_client != null) {
				_client.disconnect();
			}
			
			if (_record != null) {
				_record = null;
			}
			
			if (_recog != null) {
				_recog.dispose();
				
				_recog = null;
			}
			
			_recording_data = null;
			
			chgState(STATE_FREE);
		}
		
		// callback(state:int, buff:ByteArray, result:String, url:String)
		public function startRecord(callback:Function):void
		{
			_result = '';
			_url = '';
			_curCallback = callback;
			
			_recording_data.clear();
			
			if (_modeSDK == MODESDK_IFLYTEK) {
				var strGrammar:String = "builtin:grammar/../search/location.abnf?language=zh-cn";
				var grammar:ByteArray = new ByteArray();
				grammar.writeMultiByte(strGrammar, "UTF-8" );
				
				_recog.recogStart(RATE.rate16k, grammar, "sub=iat, aue=speex;7, auf=audio/L16;rate=16000, ent=sms16k, rst=plain");	
			}
			else if (_modeSDK == MODESDK_BAIDU) {
				_record.startRecording();
			}
			
			chgState(STATE_RECORDING);
		}
		// 停止录音
		public function stopRecord():void
		{
			if (_modeSDK == MODESDK_IFLYTEK) {
				_recog.recordStop();
			}
			else if (_modeSDK == MODESDK_BAIDU) {
				_record.stopAndEncodeRecording();
				
				trace("stopRecord MODESDK_BAIDU");
				
				_buffAMR = Codec.encode(_recording_data);
				
				postAMR();
				
//				var bufWav:ByteArray = Codec.decode(_buffAMR);
//				_recording_data = bufWav;
			}
			
			chgState(STATE_STOPRECORDING);
		}
		
		public function getAMRData():ByteArray
		{
			return _buffAMR;
		}
		
		public function getWAVData():ByteArray
		{
			//_record.getWAV();
			var buf:ByteArray = procWav(_recording_data, 2, 32000);
			return buf;
		}
		
		public function getMP3Data():ByteArray
		{
			//_record.getWAV();
			//var buf:ByteArray = procWav(_recording_data, 2, 32000);
			return _mp3Encoder.mp3Data;
		}
		
		// 播放url声音
		public function playSound(url:String):void
		{
			var czm:String = url.slice(url.length - 3);
	
			if (czm == "mp3") {
				var s:Sound = new Sound();
				s.addEventListener(Event.COMPLETE, onSoundLoaded);
				var req:URLRequest = new URLRequest(_DOWNLOADURL + url);
				s.load(req);
			}
			else if (czm == "amr") {
				_urlloaderAMR = new URLLoader;
				_urlloaderAMR.dataFormat = URLLoaderDataFormat.BINARY;
				_urlloaderAMR.addEventListener(Event.COMPLETE, onCompleteAMR);
				var req:URLRequest = new URLRequest(_DOWNLOADURL + url);
				_urlloaderAMR.load(req);
			}
		}
		
		private function onCompleteAMR(e:Event):void 
		{
			var amrbuff:ByteArray = _urlloaderAMR.data as ByteArray;
			var bufWav:ByteArray = Codec.decode(amrbuff);
			
			var buf1:ByteArray = procSample8k(bufWav);
//			var buf1:ByteArray = procSample2Float(bufWav, 16);
//			
//			var wavWrite:WAVWriter = new WAVWriter();
//			var wav:ByteArray = new ByteArray();
//			
//			wavWrite.numOfChannels = 2;        // 单声道
//			wavWrite.sampleBitRate = 16;       // 单点数据存储位数
//			wavWrite.samplingRate = 8000;
//			
//			buf1.position = 0;
//			wavWrite.processSamples(wav, buf1, 8000, 1);
//			
//			var buf2:ByteArray = procSample2NoFloat(wav, 16);
			
			var buf:ByteArray = procWav(buf1, 2, 32000);
			_recording_data = buf1;
			//var ws:WaveSound = new WaveSound(buf);
			//ws.play(0, 0, null);
			
			buf.position = 0;
			
			_mp3Encoder = new ShineMP3Encoder(buf);
			_mp3Encoder.addEventListener(Event.COMPLETE, onMP3EncodeCompleteAMR);
			//_mp3Encoder.addEventListener(ProgressEvent.PROGRESS, onMP3EncodeProgress);
			//_mp3Encoder.addEventListener(ErrorEvent.ERROR, onMP3EncodeError);
			_mp3Encoder.start();
			
			//chgState(STATE_MP3ENCODEING);
		}
		
		private function onMP3EncodeCompleteAMR(event:Event):void 
		{	
			var s:Sound = new Sound();
			//s.addEventListener(Event.COMPLETE, onSoundLoaded);
			_mp3Encoder.mp3Data.position = 0;
			s.loadCompressedDataFromByteArray(_mp3Encoder.mp3Data, _mp3Encoder.mp3Data.length);
			s.play();
			//var form:Multipart = new Multipart(_UPLOADURL);
			
			//form.addFile("file", _mp3Encoder.mp3Data, "application/octet-stream", "tmp.mp3");
//			
//			var loader:URLLoader = new URLLoader();
//			loader.addEventListener(Event.COMPLETE, onUploadComplete);
//			loader.load(form.request);
//			
//			chgState(STATE_UPLOADING);
		}
		
		// 发送私聊消息
		public function sendPersonalMsg(sid:String, rid:String, type:String, content:String, tag:String, url:String, ext:Object, callback:Function):void
		{
			_client.requestPrivatechat(sid, rid, type, content, tag, url, ext, callback);
		}
		
		// 发送群组消息
		public function sendGroupMsg(sid:String, gpid:String, type:String, content:String, tag:String, url:String, ext:Object, callback:Function):void
		{
			_client.requestGroupchat(sid, gpid, type, content, tag, url, ext, callback);
		}
		
		// 发送群组消息
		public function receiveGroupMsg(type:String, id:String, index:int, count:int):void
		{
			_client.requestGroupOffLine(type, id, index, count);
		}
		
		private function onSoundLoaded(event:Event):void
		{
			var localSound:Sound = event.target as Sound;
			localSound.play();
		}
		
		private function onMicrophoneStatus(e:MSCMicStatusEvent):void
		{
			trace("onMicrophoneStatus:" + e);
		}
		
		private function onRecording(e:MSCRecordAudioEvent):void
		{
			trace("onRecording");

			_recording_data.writeBytes(e.data);
		}
		
		private function onGettingResult(e:MSCResultEvent):void
		{
			var strRslt:String = new String();
			strRslt = e.result.readMultiByte(e.result.bytesAvailable, "GBK")
			_result += strRslt;
			
			if (strRslt.length > 0)
			{
				trace("onGettingResult " + strRslt);
			}
		}
		
		private function onComplete(e:MSCEvent):void
		{
			chgState(STATE_ENDIAT);
			
			trace("onComplete");
			
			var wav32k:ByteArray = procSample16k(_recording_data);
			var wavbuff:ByteArray = procWav(wav32k, 2, 32000);
			
			wavbuff.position = 0;
			
			_mp3Encoder = new ShineMP3Encoder(wavbuff);
			_mp3Encoder.addEventListener(Event.COMPLETE, onMP3EncodeComplete);
			_mp3Encoder.addEventListener(ProgressEvent.PROGRESS, onMP3EncodeProgress);
			_mp3Encoder.addEventListener(ErrorEvent.ERROR, onMP3EncodeError);
			_mp3Encoder.start();
			
			chgState(STATE_MP3ENCODEING);
		}
		
		private function onError(e:MSCErrorEvent):void
		{
			trace("onError " + e.message);
			
			_recog.recogStop();
			
			chgState(STATE_IATERR);
		}
		
		private function onMP3EncodeProgress(event:ProgressEvent):void 
		{
		}
		
		private function onMP3EncodeError(event:ErrorEvent):void 
		{
			trace("onMP3EncodeError " + event.text);
			
			chgState(STATE_MP3ERR);
		}
		
		private function onMP3EncodeComplete(event:Event):void 
		{	
			var form:Multipart = new Multipart(_UPLOADURL);
			
			form.addFile("file", _mp3Encoder.mp3Data, "application/octet-stream", "tmp.mp3");
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onUploadComplete);
			loader.load(form.request);
			
			chgState(STATE_UPLOADING);
		}
		
		private function onUploadComplete(evt:Event):void 
		{
			var loader:URLLoader = URLLoader(evt.target);
			
			//{"code":"00","desc":"成功","fileId":"group2/M00/03/02/CgNGCVXSr7KAFDdJAAAv9GuhhwI217.mp3"}
			trace("completeHandler: " + loader.data);
			var ret:Object = JSON.parse(loader.data);
			if (ret.code == '00') {
				_url = ret.fileId;
			}
			
			chgState(STATE_COMPLETE);
			
//			if (_curCallback != null) {
//				_curCallback(_mp3Encoder.mp3Data, _result);
//			}
		}
		
		private function procWav(buff:ByteArray, channel:int, rate:int, nBitsPerSample:int = 16):ByteArray
		{
			buff.position = 0;
			
			var wavbuf:ByteArray = new ByteArray;
			wavbuf.endian = Endian.LITTLE_ENDIAN;
			
			wavbuf.writeUTFBytes("RIFF");
			var len:int = 4 + 8 + 8 + 16 + 12 + buff.length - 8;
			wavbuf.writeInt(len);
			wavbuf.writeUTFBytes("WAVE");
			
			wavbuf.writeUTFBytes("fmt ");
			wavbuf.writeInt(16);
			
			wavbuf.writeShort(1); //nFormatTag
			wavbuf.writeShort(channel); //nChannels
			wavbuf.writeInt(rate); //nSamplesPerSec
			wavbuf.writeInt(rate * channel * Math.ceil(nBitsPerSample / 8)); //nAvgBytesPerSec
			wavbuf.writeShort(2); //nBlockAlign
			wavbuf.writeShort(nBitsPerSample); //nBitsPerSample
			
			wavbuf.writeUTFBytes("data");
			wavbuf.writeInt(4 + 8 + 8 + 16 + 12 + buff.length - 44);
			
			wavbuf.writeBytes(buff);
			
			return wavbuf;
		}
		
		private function procSample2Float(src:ByteArray, bps:int) : ByteArray
		{
			src.position = 0;
			var buff:ByteArray = new ByteArray;
			buff.endian = src.endian;
			
			var sampleSize:int = Math.ceil(bps / 8);
			if (sampleSize == 0) throw "Unsupported BPS";
			var divisor:int = 1 << (bps-1);
			var shift:int = 1 << bps;
			
			for (var i:int = 0; i < src.length / 2; ++i) {
				var s:int = src.readShort();
				if (s > divisor) s -= shift;
				
				buff.writeFloat(s / divisor);
			}
			
			return buff;
		}
		
		private function procSample2NoFloat(src:ByteArray, bps:int) : ByteArray
		{
			src.position = 0;
			var buff:ByteArray = new ByteArray;
			buff.endian = src.endian;
			
			var sampleSize:int = Math.ceil(bps / 8);
			if (sampleSize == 0) throw "Unsupported BPS";
			var divisor:int = 1 << (bps-1);
			var shift:int = 1 << bps;
			
			for (var i:int = 0; i < src.length / 4; ++i) {
				var f:Number = src.readShort();
				var s:int = Math.ceil(f * divisor);
				buff.writeShort(s);
			}
			
			return buff;
		}
		
		private function procSample16k(src:ByteArray) : ByteArray 
		{
			src.position = 0;
			
			var buff:ByteArray = new ByteArray;
			buff.endian = src.endian;
			
			src.position = 0;
			var srclen:int = src.length / 2;
			var last:int = 0;
			var cur:int = 0;
			for (var i:int = 0; i < srclen - 1; ++i) {
				if (i == 0) {
					cur = src.readShort();
					last = src.readShort();
					
					buff.writeShort(cur);
					buff.writeShort(cur);
					
					buff.writeShort(cur);
					buff.writeShort(cur);
				}
				else {
					cur = last;
					last = src.readShort();
				}
				
				buff.writeShort(cur);
				buff.writeShort(cur);
				
				//var dat:int = (cur + last) / 2;
				
				buff.writeShort(cur);
				buff.writeShort(cur);
			}
			
			return buff;
		}
		
		private function procSample8k(src:ByteArray) : ByteArray 
		{
			src.position = 0;
			
			var buff:ByteArray = new ByteArray;
			buff.endian = src.endian;
			
			src.position = 0;
			var srclen:int = src.length / 2;
			var last:int = 0;
			var cur:int = 0;
			for (var i:int = 0; i < srclen - 1; ++i) {
				if (i == 0) {
					cur = src.readShort();
					last = src.readShort();
					
					buff.writeShort(cur);
					buff.writeShort(cur);
					
					buff.writeShort(cur);
					buff.writeShort(cur);
					
					buff.writeShort(cur);
					buff.writeShort(cur);
					
					buff.writeShort(cur);
					buff.writeShort(cur);
				}
				else {
					cur = last;
					last = src.readShort();
				}
				
				buff.writeShort(cur);
				buff.writeShort(cur);
				
				//var dat:int = (cur + last) / 2;
				
				buff.writeShort(cur);
				buff.writeShort(cur);
				
				buff.writeShort(cur);
				buff.writeShort(cur);
				
				buff.writeShort(cur);
				buff.writeShort(cur);
			}
			
			return buff;
		}
	}
}
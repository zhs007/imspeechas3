package com.iflytek.msc
{
	import cmodule.flash_msc.CLibInit;
	import com.adobe.socket.msc_socket;
	import com.iflytek.msc.ISynthesizerListener;
	import com.iflytek.msc.MSCLog;
	
	import com.iflytek.msc.QTTSSessionBeginReturns;
	import com.iflytek.msc.QTTSAudioGetReturns;
	
	//import com.ru.etcs.events.WaveSoundEvent;
	//import com.ru.etcs.media.PCMFormat;
	import com.ru.etcs.media.WaveSound;
	
	import com.iflytek.events.MSCEvent;
	import com.iflytek.events.MSCErrorEvent;
	import com.iflytek.events.MSCSynthAudioEvent;
	
	import com.iflytek.define.ErrorCode;
	import com.iflytek.define.MessageType;
	import com.iflytek.define.SynthStatus;
	import com.iflytek.define.PlayState;
	import com.iflytek.define.WaveSoundState;
	
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import flash.utils.Endian;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.SampleDataEvent;

	public class Synthesizer extends EventDispatcher implements ISynthesizerListener 
	{
		// ---------------------------------------------
		// 常量
		// ---------------------------------------------
		private const SocketDetectIntervalTime:int 		= 5;   // 网络检测时间间隔
		//private const SocketDetectMaxFrequency:int 	= 20;  // 网络检测最大次数
		private const ResultGetIntervalTime:int			= 300; // 获取结果时间间隔
		//private const ResultGetMaxFrequency:int		= 20;  // 结果获取最大轮询次数
		private const MESSAGE_NOT_COMPLETE:int			= 1;   // 消息不完整
		private const PreSoundBufferSize:uint			= 50 * 1024; // 播放之前，音频缓冲数据大小
		
		// ---------------------------------------------
		// 私有变量
		// ---------------------------------------------
		private var errorCode:int 			= 0; 
		private var __state:String			= new String();
		private var clog:MSCLog				= new MSCLog();
		private var log:ByteArray			= clog.msclog;
		private var timeout:int				= 30000;        // 等待时间
		
		// 库加载
		private var mscLib:Object			= null;  // msc lib库
		
		// 跟socket相关的变量
		private var __serverURL:String		= new String();
		private var __serverPort:int		= 80;
		private var __socket:msc_socket		= null;
		private var socketDetectTimer:Timer	= null;
		private var isSocketDetect:Boolean	= false;
		private var msgType:int 			= MessageType.Msg_Session_Begin;
		
		// 跟合成相关的变量
		private var sessionID:String        = new String();  // 会话ID
		private var __text:String			= null;  // 一路会话的合成文本
		private var __params:String 		= null;  // 本次合成的语法
		private var isSessionEnd:Boolean	= false;
		private var synthStatus:int			= SynthStatus.MSP_TTS_FLAG_STILL_HAVE_DATA;
		private var requestRsltTimer:Timer  = null;
		private var sessSynthData:ByteArray	= new ByteArray();
		
		// 播放
		private var waveSound1:WaveSound	= null;
		private var wsState1:int			= WaveSoundState.INIT;
		private var waveSound2:WaveSound	= null;
		private var wsState2:int  			= WaveSoundState.INIT;
		private var waveSound:WaveSound		= null;
		private var sound:Sound				= null;
		private var sampleDataSize:int		= 8192;       // 提供给 SampleDataEvent对象的data属性的样本的数目,在2048到8192之间
		private var playState:String		= PlayState.BUFFERING;
		private var channel:SoundChannel	= null;      // 声道
		private var pausePosition:Number 	= 0;         // 暂停位置
		private var soundBuffer:ByteArray	= new ByteArray();
		private var isEnablePlay:Boolean	= false;
		private var isCmdToPlay:Boolean		= false;          // 用户点击播放
		private var isPlayInSynth:Boolean	= false;          // 是否在合成未完毕之时播放
		
		// 性能
		private var dateTextPut:Date		= new Date;
		private var dateSynthEnd:Date			= new Date;
		private var fr_lr:Number			= 0;
		
		public function Synthesizer(configs:String = "", serverURL:String = "dev.voicecloud.cn:80", logLevel:int = 0) 
		{
			clog.output = true;
			
			clog.logDBG("Synthesizer| enter, configs = " + configs + ", serverURL = " + serverURL );
		    
			// 库加载
			try
			{
				var loader:CLibInit = new cmodule.flash_msc.CLibInit();
				if(null != loader)
				{
					mscLib = loader.init();
				}
				else
				{
					errorCode = ErrorCode.MSP_ERROR_FLASH_LOAD_LIB;
				}
				
				if(null != mscLib)
				{
					errorCode = QTTSInit(configs, logLevel);
				}
				else
				{
					errorCode = ErrorCode.MSP_ERROR_FLASH_LIB;
				}
			}
			catch(error:Error)
			{
				clog.logDBG("Synthesizer| message = " + error.message + "errorID = " + String(error.errorID));
			}
			
			// 获取timeout值
			var searchStr:String = "timeout=";
			var strTemp:String = "";
			var strResult:String = "";
			var posBegin:int = 0;
			var posEnd:int = 0;
			
			posBegin = configs.search( searchStr );   // 若找不到则返回-1
			if( -1 != posBegin )
			{
				// 去除timeou之前的字符串
				posEnd = configs.length;
				strTemp = configs.slice(posBegin, posEnd);
				
				posBegin = searchStr.length;
				searchStr = ",";
				posEnd = strTemp.search( searchStr );
				if( -1 == posEnd )   // 没有找到“,”,"timeout"在最后
				{
					clog.logDBG("Synthesizer| configs.length=" + String( configs.length ));
					
					posEnd = strTemp.length;
				}
				strResult = strTemp.slice( posBegin, posEnd );
				
				clog.logDBG("Synthesizer| timeout = " + strResult);
				
				timeout = int( strResult );
				
				if(0 == timeout)
				{
					timeout = 30000;
				}
			}
			else
			{
				clog.logDBG("Synthesizer| not find timeout set, use deault timeout!");
				
				timeout = 30000;
			}

			// 通信
			// 若后带端口号，则需解析
			strResult = "";
			posBegin = 0;
			searchStr = ":";
			posEnd = serverURL.search( searchStr );
			if( -1 != posEnd )
			{
				__serverURL = serverURL.slice( posBegin, posEnd );
				
				clog.logDBG("Synthesizer| URL = " + __serverURL);
				
				posBegin = posEnd + 1;
				posEnd = serverURL.length;
				
				strResult = serverURL.slice( posBegin, posEnd );
				
				clog.logDBG("Synthesizer| port = " + strResult);
				
				__serverPort = int(strResult);
			}
			else
			{
				__serverURL = serverURL;
				__serverPort = 80;
			}
			
			// 通信
//			__socket = new msc_socket(this, clog);
//			__socket.connectServer(__serverURL, __serverPort);
			
			__state = 'init';
			
			clog.logDBG("Synthesizer| leave ok.");
		}
	
	/* 
	 * ***********************************************************************
	 * PUBLIC METHODS
	 * ***********************************************************************
	 */
	/**
	 * @fn		synthStart
	 * @brief
	 * 
	 * 开始语音合成一路回话。
	 *
	 * @author	jfyuan
 	 * @date	2012-2-24
 	 * @return	No return value.
	 * @params	text:String — 合成文本
	 * @params	params:String — 本次TTS合成使用的参数
	 * @see
	 */
	public function synthStart(text:String = "", params:String = ""):int
	{
		clog.logDBG("synthStart| enter, params = " + params + ", text = " + text);
		
		if('init' != __state && 'end' != __state)
		{
			clog.logDBG("synthStart| leave ok, calling function sequence error.");
			return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
		}
		__state = 'synthStart';
		
		// 检查初始化是否成功
		if(ErrorCode.MSP_ERROR_FLASH_LOAD_LIB == errorCode)
		{

			clog.logDBG("synthStart| leave, loading lib failed!!");
			
			__state = 'end';
			
			return errorCode;
		}
		else if(ErrorCode.MSP_ERROR_FLASH_LIB == errorCode)
		{
			clog.logDBG("synthStart | leave, lib has errors!");
			
			__state = 'end';
			
			return errorCode;
		}
		else if(0 != errorCode)
		{
			clog.logDBG("synthStart | leave, QTTSInit failed!ret = " + String(errorCode) );
			
			__state = 'end';
			
			return errorCode;
		}
		
		// 初始化变量
		sessSynthData.clear();         // 清空上次会话产生的合成音频
		soundBuffer.clear();
		synthStatus	= SynthStatus.MSP_TTS_FLAG_STILL_HAVE_DATA;      // 合成状态
		wsState1 = WaveSoundState.INIT;
		wsState2 = WaveSoundState.INIT;
		isEnablePlay = false;
		playState = PlayState.BUFFERING;   // 播放状态
		isCmdToPlay = false;
		sound = null;
		if(playState == PlayState.PLAYING || playState == PlayState.PAUSE)
		{
			if(null != null)
			{
				channel.stop();
				channel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
			}
		}
		if(null != waveSound)
		{
			waveSound.close();
			waveSound = null;
		}
		
		isCmdToPlay = false;
		
		// 检查通信是否成功
		__text = text;
		__params = params;
		if(null == __socket || !__socket.connected)
		{
			__socket = new msc_socket(this, clog);
			__socket.connectServer(__serverURL, __serverPort);
			socketDetectTimer = new Timer( SocketDetectIntervalTime, timeout / SocketDetectIntervalTime );
//			socketDetectTimer.addEventListener( TimerEvent.TIMER, onConnectServer );
			socketDetectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onConnectComplete );
			socketDetectTimer.start();
			isSocketDetect = true;
			clog.logDBG("synthStart | leave ok, connect server ....");
			return 0;
		}
		
		if(0 != sessionBegin())
		{
			__state = 'end';
		}
		
		clog.logDBG("synthStart| leave ok.");
		
		return 0;
	}
	
	/**
	 * @fn		synthStop
	 *
	 * @brief
	 *
	 * 取消本次合成
	 *
	 * @author 	jfyuan
	 * @date	2012-02-29
	 * @return 	No return values
	 * @see
	 */
	public function synthStop():int
	{
		clog.logDBG("synthStop | enter.");
		
		if('synthStart' != __state)
		{
			clog.logDBG("synthStop| leave ok, calling function sequence error.");
			
			return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
		}
		__state = 'synthStop';
		
		sessionEnd("Stop");
		
		clog.logDBG("synthStop| leave ok.");
		
		return 0;
	}
	
	/**
	 * @fn		Play
	 * @brief
	 *
	 * 音频播放
	 * @authoe	jfyuan
	 * @date	2012-06-18
	 * @return	int
	 */
	public function Play():int
	{
		clog.logDBG("Play| enter , synthStatus:" + String(synthStatus));
		
		if(!isEnablePlay)
		{
			clog.logDBG("Play| leave, there is no enough data to play.");
			
			return ErrorCode.MSP_ERROR_FLASH_PLAYER_NODATA;
		}
		else if(playState == PlayState.PLAYING)
		{
			clog.logDBG("Play| leave, the player has existed.");
			
			return ErrorCode.MSP_ERROR_FLASH_PLAYER_EXIST;
		}
		
		isCmdToPlay = true;
		
		if(synthStatus	== SynthStatus.MSP_TTS_FLAG_STILL_HAVE_DATA 
		   || (isPlayInSynth && playState == PlayState.PAUSE ))        // 合成音频没有获取完毕时播放
		{
			clog.logDBG("Play| play the synthesied audio data when receiving audio data from server imcompletely.");
			
			isPlayInSynth = true;
			
			if(playState == PlayState.PAUSE)
			{
				if(null != channel)
				{
					channel = sound.play(pausePosition);
					channel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
				}
			}
		}
		else if( synthStatus == SynthStatus.MSP_TTS_FLAG_DATA_END || isSessionEnd )
		{
			if(null == waveSound)  // 合成音频获取完毕后，将所有音频一次性转变为waveSound
			{
				var temp:ByteArray = new ByteArray();
				
				clog.logDBG("Play| compile all synthesied audio data.");
				
				if(0 == sessSynthData.length)
				{
					clog.logDBG("Play| leave, no data to play!");
					
					return ErrorCode.MSP_ERROR_FLASH_PLAYER_NODATA;
				}
				
				addWaveHeader(temp, sessSynthData);
				waveSound = new WaveSound(temp);
				playState = PlayState.BUFFERING;
				waveSound.addEventListener(Event.COMPLETE, onCplWaveSndCompleted);
			}
			else
			{
				if(playState == PlayState.PAUSE)
				{
					channel = sound.play(pausePosition);
				}
				else
				{
					channel = sound.play();
				}
				
				channel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
				playState = PlayState.PLAYING;
			}
		}
		
		clog.logDBG("Play| leave.");
		
		return 0;
	}
	
	/**
	 * @fn		Pause
	 * @brief
	 *
	 * 音频播放暂停
	 * @authoe	jfyuan
	 * @date	2012-06-20
	 * @return	int
	 */
	public function Pause():void
	{
		clog.logDBG("Pause| enter.");
		
		if(null == channel) 
		{
			clog.logDBG("Pause| leave, channel is null!");
			
			return;
		}
		isCmdToPlay = false;
		pausePosition = channel.position;
		
		clog.logDBG("Pause| pausePosition = " + String(pausePosition));
		
		channel.stop();
		channel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
		playState = PlayState.PAUSE;
		
		clog.logDBG("Pause| leave ok, playState = " + playState);
	}
	
	/**
	 * @fn		Stop
	 * @brief
	 *
	 * 停止音频播放
	 * @authoe	jfyuan
	 * @date	2012-06-20
	 * @return	int
	 */
	public function Stop():void
	{
		clog.logDBG("Stop| enter.");
		
		if(null == channel) 
		{
			clog.logDBG("Stop| leave, channel is null!");
			
			return;
		}
		isCmdToPlay = false;
		pausePosition = 0;
		
		channel.stop();
		channel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
		playState = PlayState.PLAYED;
		
		clog.logDBG("Stop| leave ok, playState = " + playState);
	}
	
	/**
	 * @fn		logSave
	 * @brief
	 *
	 * 保存日志
	 *
	 * @author	jfyuan
	 * @date	2012-02-29
	 * @return	No reurn values
	 * @see
	 */
	public function logSave():void
	{
		clog.logSave();
	}
							
	/**
	 * @fn		dispose
	 * @brief	
	 * 
	 * 释放资源
	 * 
	 * @author	yjyuaun
	 * @date	2012-02-29
	 * @return	No return values
	 * @see
	 */
	public function dispose():void
	{
		clog.logDBG("dispose | enter.");
		
		var ret:int = QTTSFini();
		if(0 != ret)
		{
			clog.logDBG("dispose | leave, ret of QISRFini = " + String(ret));
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QTTSFini", ret);
			return;
		}
		
		clog.logDBG("dispose | leave ok.");
	}
	
	/*
	 * ***********************************************************************
	 * PRIVATE METHODS
	 * ***********************************************************************
	 */
	private function sessionBegin():int
	{
		clog.logDBG("sessionBegin| enter, params = " + __params);
		
		var returnValues:QTTSSessionBeginReturns = null;
		returnValues = QTTSSessionBegin(__params);
		clog.logDBG("sessionBegin| sessionID = " + returnValues.sessionID + ", ret = " + String(returnValues.ret) 
					+ ", message = \n" + String(returnValues.sessionBeginMsg));
		
		if(null == returnValues.sessionID || "" == returnValues.sessionID)
		{
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QTTSSessionBegin", ErrorCode.MSP_ERROR_INVALID_HANDLE );
			clog.logDBG("sessionBegin| leave, sessionID is null!");
			return -1;
		}
		else if(0 != returnValues.ret)
		{
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QTTSSessionBegin", returnValues.ret );
			clog.logDBG("sessionBegin| leave.");
			return -1;
		}
		if(0 == returnValues.sessionBeginMsg.length)
		{
//			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QTTSSessionBegin", ErrorCode.MSP_ERROR_MSG_BUILD_ERROR );
			clog.logDBG("sessionBegin| leave, built message is null!");
//			return -1;
		}
		sessionID = returnValues.sessionID;
		isSessionEnd = false;
//		__socket.sendData(returnValues.sessionBeginMsg);
		returnValues.sessionBeginMsg.clear();
		msgType = MessageType.Msg_Session_Begin;  // 告知服务器将要接受的消息为session_begin消息
		clog.logDBG("sessionBegin| ok.");
		
			var textMsg:ByteArray = new ByteArray;
			var textArr:ByteArray = new ByteArray;
			var ret:int = 0;
			if(0 == __text.length)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSTextPut", ErrorCode.MSP_ERROR_TTS_TEXT_EMPTY);
				clog.logDBG("getResponseMsg| leave, text is empty!");
				return -1;
			}
			textArr.writeMultiByte(__text, "GBK");
			ret = QTTSTextPut( sessionID, textArr, null, textMsg );
			if(0 != ret)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSTextPut", ret);
				clog.logDBG("getResponseMsg| leave, ret of QTTSTextPut = " + String(ret));
				sessionEnd("Error");
				return -1;
			}
			else if(textMsg.length == 0)
			{
//				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSTextPut", ErrorCode.MSP_ERROR_MSG_BUILD_ERROR);
				clog.logDBG("getResponseMsg| leave, building message failed!");
//				sessionEnd("Error");
//				return -1;
			}
//			__socket.sendData(textMsg);
			msgType = MessageType.Msg_Back_To_Result;
			
			// 启动定时获取合成结果的时钟
			requestRsltTimer = new Timer(ResultGetIntervalTime, timeout / ResultGetIntervalTime); 
			requestRsltTimer.addEventListener( TimerEvent.TIMER, onGetSynthResult );
			requestRsltTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onGetSynthResultComplete);
			requestRsltTimer.start();
			
			dateTextPut = new Date();
		clog.logDBG("sessionBegin| leave ok.");
		return 0;
	}
	
	private function sessionEnd(hints:String = ""):void
	{
		clog.logDBG("sessionEnd| enter, hints = " + hints);
		
		if(isSessionEnd)
		{
			clog.logDBG("sessionEnd| leave, session has ended!");
				
			return;
		}
		
		__state = 'end'; 
		
		// 当发生错误致使会话结束时，将合成器状态强制改为音频获取结束标识
		if(synthStatus != SynthStatus.MSP_TTS_FLAG_DATA_END)
		{
			synthStatus = SynthStatus.MSP_TTS_FLAG_DATA_END;
		}
		clog.logDBG("synthStatus:" + String(synthStatus));
		
		// 检查获取音频的始终是否还在运行
		if(null!= requestRsltTimer && requestRsltTimer.running)
		{
			clog.logDBG("sessionEnd| stop requestRsltTimer.");
			requestRsltTimer.stop();
			requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetSynthResult);
			requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetSynthResultComplete);
		}
		
		//  结束本次合成会话
		if(!isSessionEnd)
		{
			var ret:int = QTTSSessionEnd(sessionID, hints);
		
			if(0 != ret)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSSessionEnd", ret);
				clog.logDBG("sessionEnd| leave, ret of QTTSSessionEnd = " + String(ret));
			}
			
			// 关闭socket
			__socket.disConnect();
			
			// 表示会话结束
			isSessionEnd = true;
		}

		dispatchMSCEvent(MSCEvent.SYNTH_COMPLETED, false, false);
		
		clog.logDBG("sessionEnd| leave ok.");
	}
	
	// 添加wav头
	public function addWaveHeader(dataOutput:ByteArray, dataInput:ByteArray):void
	{
		var fileSize:uint = 0;
		var compressionCode:int = 1;
		var numOfChannels:int = 1;
		var samplingRate:int = 11025;
		var sampleBitRate:int = 16;
		var dataByteLength:uint = 0;
		
		dataInput.position = 0;
		dataByteLength = dataInput.bytesAvailable;
		clog.logDBG( "addWaveHeader | dataByteLength=" + dataByteLength );
		if( !dataOutput || dataInput.bytesAvailable <= 0  )
		{
			throw new Error("No audio data");
		}
		
		dataOutput.endian = Endian.LITTLE_ENDIAN;
			
		fileSize = 36 + 8 + dataByteLength;
			
		dataOutput.writeUTFBytes("RIFF");
		dataOutput.writeInt(uint(fileSize)); // Size of whole file
		dataOutput.writeUTFBytes("WAVE");
		// WAVE Chunk
		dataOutput.writeUTFBytes("fmt ");	// Chunk ID
		dataOutput.writeInt(uint(16));	// Header Chunk Data Size
		dataOutput.writeShort(uint(compressionCode)); // Compression code - 1 = PCM
		dataOutput.writeShort(uint(numOfChannels)); // Number of channels
		dataOutput.writeInt(samplingRate); // Sample rate
		dataOutput.writeInt(uint(samplingRate * numOfChannels * (sampleBitRate >> 3))); // Byte Rate == SampleRate * NumChannels * BitsPerSample/8		
		dataOutput.writeShort(uint(numOfChannels * (sampleBitRate >> 3))); // Block align == NumChannels * BitsPerSample/8
		dataOutput.writeShort(sampleBitRate); // Bits Per Sample
		// Data Chunk Header
		dataOutput.writeUTFBytes("data");
		dataOutput.writeInt(dataByteLength); // Size of whole file
		
		dataOutput.writeBytes(dataInput);
		dataOutput.position = 0;
	}
	
	// 将音频转化成
	private function compileWaveSound( index:int ):void
	{
		var wav:ByteArray = new ByteArray();
		
		clog.logDBG("compileWaveSound| enter.");
		
		// Add wave header
		soundBuffer.position = 0;
		if(	soundBuffer.bytesAvailable == 0  ) return;
		addWaveHeader( wav, soundBuffer );
		soundBuffer.clear();
			
		switch( index )
		{
			case 1:
				clog.logDBG("compileWaveSound| prepare the first Wave Sound.");
				waveSound1 = new WaveSound( wav );
				wsState1 = WaveSoundState.COMPILING;
				waveSound1.addEventListener(Event.COMPLETE, onCplWaveSndCompleted);
				break;
			case 2:
				clog.logDBG("compileWaveSound| prepare the second Wave Sound.");
				waveSound2 = new WaveSound( wav );
				wsState2 = WaveSoundState.COMPILING;
				waveSound2.addEventListener(Event.COMPLETE, onCplWaveSndCompleted);
				break;
		}
		
		clog.logDBG("compileWaveSound| leave ok.");
	}
	
	/*
	 * ************************************************************************
	 * Do things when the event is dispatched
 	 * ************************************************************************
	 */
	private function onConnectServer(e:TimerEvent):void
	{
		clog.logDBG("onConnectServer | try to connectServer ...");
		__socket.connectServer(__serverURL, __serverPort);
	}
		
	private function onConnectComplete(e:TimerEvent):void
	{
		clog.logDBG("onConnectComplete | enter.");
			
		if(!__socket.connected)
		{
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:onConnectComplete", ErrorCode.MSP_ERROR_NET_CONNECTSOCK );
			isSocketDetect = false;
			socketDetectTimer.stop();
			socketDetectTimer.removeEventListener(TimerEvent.TIMER, onConnectServer);
			socketDetectTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onConnectComplete);
		}
			
		clog.logDBG("onConnectComplete | leave ok.");
	}
	
	private function onGetSynthResult(e:TimerEvent):void
	{
		clog.logDBG("onGetSynthResult| enter, count = " + String(e.target.currentCount) + ".");
		
		var returnValues:QTTSAudioGetReturns = null;
		var synthAudioData:ByteArray = new ByteArray;
		
		if(isSessionEnd)
		{
			clog.logDBG("onGetSynthResult| leave, session has ended!");
			
			return;
		}
		
		returnValues = QTTSAudioGet(sessionID, synthAudioData);
		if(0 != returnValues.ret)
		{
			sessionEnd("Error");
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QTTSAudioGet", returnValues.ret );
			clog.logDBG("onGetSynthResult | leave, ret of onGetSynthResult = " + String(returnValues.ret));
			return;
		}
		
		synthStatus = returnValues.synthStatus;
		clog.logDBG("onGetSynthResult| synthStatus = " + String(synthStatus));

		// 发送音频获取请求消息
		if(returnValues.audioDataFetchMsg.length > 0 && SynthStatus.MSP_TTS_FLAG_STILL_HAVE_DATA == synthStatus)
		{
			__socket.sendData(returnValues.audioDataFetchMsg);
		}
		
		// 获取合成音频信息
		var audioInfo:String = new String();
		audioInfo = QTTSAudioInfo( sessionID );
		
		// 发布音频获取事件
		dispatchMSCSynthAudioEvent(MSCSynthAudioEvent.AUDIO_GET, false, false, synthAudioData, audioInfo, returnValues.synthStatus);
		
		soundBuffer.writeBytes(synthAudioData);
		sessSynthData.writeBytes(synthAudioData);
		
		if(soundBuffer.length > PreSoundBufferSize && !isEnablePlay)
		{
			clog.logDBG("onGetSynthResult| enable to play.");
				
			isEnablePlay = true;
			dispatchMSCEvent(MSCEvent.SYNTH_READY_TO_PLAY, false, false );
		}
			
		if(isCmdToPlay)
		{
			clog.logDBG("onGetSynthResult| wsState1 = " + String(wsState1) + ", wsState2 = " + String(wsState2));
			
			//  为下一个播放音频段准备
			if( (wsState1 == WaveSoundState.INIT && soundBuffer.length > PreSoundBufferSize )
				|| (wsState1 == WaveSoundState.PLAYED && wsState2 == WaveSoundState.PLAYING)      // waveSound1 播放结束，waveSound1正在播放       
			    || (wsState1 == WaveSoundState.PLAYED && wsState2 == WaveSoundState.PLAYED) )  // waveSound1和waveSound2都播放完毕
			{
				clog.logDBG("compileWaveSound(1)");
				compileWaveSound(1);
			}
			else if(wsState1 == WaveSoundState.PLAYING 
				&& (wsState2 == WaveSoundState.INIT || wsState2 == WaveSoundState.PLAYED))  // waveSound1正在播放，waveSound2初始化过或者播放完毕
			{
				clog.logDBG("compileWaveSound(2)");
				compileWaveSound(2);
			}
		}
		
		if(SynthStatus.MSP_TTS_FLAG_DATA_END == synthStatus)
		{
			dateSynthEnd = new Date();
			fr_lr = dateSynthEnd.getTime() - dateTextPut.getTime();
			clog.logDBG("onGetSynthResult| fr_lr(文本送入到获取最后音频) = " + String(fr_lr));
			
			// 当音频较短时
			if(!isEnablePlay)
			{
				isEnablePlay = true;
				dispatchMSCEvent(MSCEvent.SYNTH_READY_TO_PLAY, false, false );
			}
			
			sessionEnd("Normal");
		}
		
		clog.logDBG("onGetSynthResult| leave ok.");
	}
	
	private function onGetSynthResultComplete(e:TimerEvent):void
	{
		clog.logDBG("onGetSynthResultComplete| enter.");
		synthStatus = SynthStatus.MSP_TTS_FLAG_DATA_END;
		sessionEnd("Enforce");
	}
	
	// pcm音频数据转waveSound完毕
	private function onCplWaveSndCompleted(e:Event):void 
	{
		clog.logDBG("onCplWaveSndCompleted| enter.");
		
		if(wsState1 == WaveSoundState.COMPILING)
		{
			wsState1 = WaveSoundState.COMPILED;
		}
		else if(wsState2 == WaveSoundState.COMPILING)
		{
			wsState2 = WaveSoundState.COMPILED;
		}
		
		// stream play
		if( null == sound && SynthStatus.MSP_TTS_FLAG_STILL_HAVE_DATA == synthStatus )
		{ 
			sound = new Sound();
			sound.addEventListener( SampleDataEvent.SAMPLE_DATA, onProcessSound );
			if(isCmdToPlay)
			{
				channel = sound.play();
				clog.logDBG( "channel:" + channel.position );
				channel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
			}
		}
		else if(SynthStatus.MSP_TTS_FLAG_DATA_END == synthStatus && (null != waveSound && waveSound.isLoad))
		{
			clog.logDBG("onCplWaveSndCompleted| all synthesize audio data compiled.");
			
			if(isCmdToPlay)
			{
				clog.logDBG("onCplWaveSndCompleted| play.");
				
				sound = waveSound.customSound;
				channel = sound.play();
				channel.addEventListener(Event.SOUND_COMPLETE, onSoundCompleted);		
			}
		}
			
		playState = PlayState.PLAYING;
		
		clog.logDBG("onCplWaveSndCompleted| leave.");
	}
	
	// 播放时请求音频数据
	private function onProcessSound(e:SampleDataEvent):void
	{
		clog.logDBG( "processSound!" );
		var byteArray:ByteArray = new ByteArray();
		var gettedNum:Number = 0;
		clog.logDBG("wsState1 = " + String(wsState1) + ", wsState2 = " + String(wsState2));
		if((wsState1 == WaveSoundState.COMPILED || wsState1 == WaveSoundState.PLAYING) && wsState2 != WaveSoundState.PLAYING )
		{
			waveSound1.removeEventListener( Event.COMPLETE, onCplWaveSndCompleted );
			wsState1 = WaveSoundState.PLAYING;
			gettedNum = waveSound1.extract( byteArray, sampleDataSize );
			clog.logDBG( "waveSound1 of gettedNum:" + gettedNum );
			if( byteArray.length < sampleDataSize * 8 )
			{
				wsState1 = WaveSoundState.PLAYED;
				waveSound1.close();
				waveSound1 = null;
				clog.logDBG( "lastLen:" + byteArray.length );
				if( wsState2 == WaveSoundState.COMPILED )
				{
					wsState2 =  WaveSoundState.PLAYING;
					waveSound2.extract( byteArray, sampleDataSize - byteArray.length / 8 );
				}
						
				// 当waveSound2准备完毕至waveSound1播放完毕过程当中，合成音频取完，也就是说有部分音频还留在soundBuffer当中
				if( SynthStatus.MSP_TTS_FLAG_DATA_END == synthStatus && soundBuffer.length > 0  )
				{
					compileWaveSound( 1 );
				}
			 }
		  }
		else if( (wsState2 == WaveSoundState.COMPILED || wsState2 == WaveSoundState.PLAYING) && wsState1 != WaveSoundState.PLAYING )
		{
			clog.logDBG( "waveSound2" );
			waveSound2.removeEventListener( Event.COMPLETE, onCplWaveSndCompleted );
			wsState2 = WaveSoundState.PLAYING;
			gettedNum = waveSound2.extract( byteArray, sampleDataSize );
			clog.logDBG( "waveSound2 of gettedNum:" + gettedNum );
			if( byteArray.length < sampleDataSize * 8 )
			{
				wsState2 = WaveSoundState.PLAYED;
				waveSound2.close();
				waveSound2 = null;
				clog.logDBG( "lastLen:" + byteArray.length );
				if( wsState1 == WaveSoundState.COMPILED )
				{
					wsState1 = WaveSoundState.PLAYING;
					waveSound1.extract( byteArray, sampleDataSize - byteArray.length / 8 );
				}
				
				// 当sound1准备完毕至sound0播放完毕过程当中，合成音频取完，也就是说有部分音频还留在audio_buffer当中
				if( SynthStatus.MSP_TTS_FLAG_DATA_END == synthStatus && soundBuffer.length > 0  )
				{
					compileWaveSound( 2 );
				}
			}
			
		}
		
		if( SynthStatus.MSP_TTS_FLAG_STILL_HAVE_DATA == synthStatus && byteArray.length < sampleDataSize * 8 )
		{
			clog.logDBG("TTS_FLAG_STILL_DATA == systhStatus");
			playState = PlayState.PAUSE;
			pausePosition = channel.position;
			channel.stop();
			channel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
			dispatchMSCEvent(MSCEvent.SYNTH_PLAY_WAITDATA, false, false );
			return;
		}
			
		clog.logDBG( "byteArray_last:" + byteArray.length );
		e.data.writeBytes(  byteArray );
	}
	
	// 当音频播放完毕时触发
	private function onSoundCompleted(e:Event):void
	{
		clog.logDBG("onSoundCompleted|　Play Completed!");
		
		playState = PlayState.PLAYED;
		isCmdToPlay = false;
		if(isPlayInSynth)
		{
			isPlayInSynth = false;
			if(waveSound1)
			{
				waveSound1.close();
				waveSound1 = null;
			}
			if(waveSound2)
			{
				waveSound2.close();
				waveSound2 = null;
			}
		}
		channel.removeEventListener(Event.SOUND_COMPLETE, onSoundCompleted);
		dispatchMSCEvent(MSCEvent.SYNTH_PLAY_COMPLETED, false, false );
	}
	
	/*
	 * *************************************************************************
	 * Impletement the interface
	 * *************************************************************************
     */
	public function notifyConnectSuccess():void
	{
		clog.logDBG("notifyConnectSuccess| enter.");
			
		if( isSocketDetect )
		{
			clog.logDBG("notifyConnectSuccess| socket connection is successful!");
				
			isSocketDetect = false;
			socketDetectTimer.stop();
			socketDetectTimer.removeEventListener(TimerEvent.TIMER, onConnectServer);
			socketDetectTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onConnectComplete);
			if(0 != sessionBegin())
			{
				__state = 'end';
			}
			else
			{
				__state = 'synthStart';
			}
		}
			
		clog.logDBG("notifyConnectSuccess| leave ok.");
	}
		
	public function getIOError( socketError:IOErrorEvent ):void
	{
		dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "", ErrorCode.MSP_ERROR_FLASH_SOCKET_IO_ERROR);
	}
		
	public function getSecurityError( socketError:SecurityErrorEvent ):void
	{
		dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "", ErrorCode.MSP_ERROR_FLASH_SOCKET_SECURITY_ERROR);
	}
	
	public function getResponseMsg(msg:ByteArray):void
	{
		clog.logDBG("getResponseMsg| enter.");
		if(isSessionEnd)
		{
			clog.logDBG("getResponseMsg| leave, session has ended.");
			return;
		}
		else if(0 == msg.length)
		{
			clog.logDBG("getResponseMsg| recieved message is null!");
			return;
		}
		
		var ret:int = QTTSParseMessage(sessionID, msg);
		if(MESSAGE_NOT_COMPLETE == ret)
		{
			clog.logDBG("getResponseMsg| leave, recieved message is not complete.");
			return;
		
		}
		else if(0 != ret)
		{
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSParseMessage", ret);
			clog.logDBG("getResponseMsg| leave, ret of QTTSParseMessage = " + String(ret));
			sessionEnd("Error");
			return;
		}
		
		if(msgType == MessageType.Msg_Session_Begin)
		{
			var textMsg:ByteArray = new ByteArray;
			var textArr:ByteArray = new ByteArray;
			if(0 == __text.length)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSTextPut", ErrorCode.MSP_ERROR_TTS_TEXT_EMPTY);
				clog.logDBG("getResponseMsg| leave, text is empty!");
				return;
			}
			textArr.writeMultiByte(__text, "GBK");
			ret = QTTSTextPut( sessionID, textArr, null, textMsg );
			if(0 != ret)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSTextPut", ret);
				clog.logDBG("getResponseMsg| leave, ret of QTTSTextPut = " + String(ret));
				sessionEnd("Error");
				return;
			}
			else if(textMsg.length == 0)
			{
//				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QTTSTextPut", ErrorCode.MSP_ERROR_MSG_BUILD_ERROR);
				clog.logDBG("getResponseMsg| leave, building message failed!");
//				sessionEnd("Error");
//				return;
			}
//			__socket.sendData(textMsg);
			msgType = MessageType.Msg_Back_To_Result;
			
			// 启动定时获取合成结果的时钟
			requestRsltTimer = new Timer(ResultGetIntervalTime, timeout / ResultGetIntervalTime); 
			requestRsltTimer.addEventListener( TimerEvent.TIMER, onGetSynthResult );
			requestRsltTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onGetSynthResultComplete);
			
			dateTextPut = new Date();
		}
		requestRsltTimer.reset();
		requestRsltTimer.start();
		
		clog.logDBG("getResponseMsg| leave ok.");
	}
	
	/*
	 * *************************************************************************
	 * Dispatch events
	 * *************************************************************************
	 */
	private function dispatchMSCEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false):void
	{
		var e:MSCEvent = new MSCEvent(type, bubbles, cancelable);
		dispatchEvent(e);
	}
		
	private function dispatchMSCErrorEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, text:String = "", id:int = 0):void
	{
		var e:MSCErrorEvent = new MSCErrorEvent(type, bubbles, cancelable, text, id);
		dispatchEvent(e);
	}
		
	private function dispatchMSCSynthAudioEvent(type:String
									  , bubbles:Boolean = false
									  , cancelable:Boolean = false
									  , thedata:ByteArray = null
									  , theaudioInfo:String = ""
									  , thesynthStatus:int = 0):void
	{
		var e:MSCSynthAudioEvent = new MSCSynthAudioEvent(type
									  , bubbles
									  , cancelable
									  , thedata
								      , theaudioInfo
								      , thesynthStatus);
		dispatchEvent(e);
	}
	
	/*
	 * ***************************************************************************
	 * MSC QTTS BASE API
	 * ***************************************************************************
	 */
	protected function QTTSInit( configs:String, lvl:int ):int
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			var ret:int = mscLib.AS3_QTTSInit( configs, lvl );
			
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSInit| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}
			
		return ret;
	}
		
	protected function QTTSSessionBegin( params:String ):QTTSSessionBeginReturns
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			var out:Array = mscLib.AS3_QTTSSessionBegin( params );
			
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		
			var returnValues:QTTSSessionBeginReturns = new QTTSSessionBeginReturns(out);
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSSessionBegin| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}
				  
		return returnValues;
	}
		
	protected function QTTSTextPut( sessionID:String, textPut:ByteArray, params:String, textMsg:ByteArray ):int
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			var ret:int = mscLib.AS3_QTTSTextPut( sessionID, textPut, textPut.length, params, textMsg );
					
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		clog.logDBG("QTTSTextPut|length="+ textMsg.length +", textMsg=" + textMsg);
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSTextPut| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}
				  
		return ret;
	}
		
	protected function QTTSAudioGet( sessionID:String, audioData:ByteArray ):QTTSAudioGetReturns
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			var out:Array = mscLib.AS3_QTTSAudioGet( sessionID, audioData );
		
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		
			var returnValues:QTTSAudioGetReturns = new QTTSAudioGetReturns(out);
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSAudioGet| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}
		
		return returnValues;
	}
		
	protected function QTTSAudioInfo( sessionID:String ):String
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			var audioInfo:String = mscLib.AS3_QTTSAudioInfo( sessionID );
			
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSAudioInfo| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}
			
		return audioInfo;
	}
		
	protected function QTTSSessionEnd( sessionID:String, hints:String ):int
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			var ret:int = mscLib.AS3_QTTSSessionEnd( sessionID, hints );
			
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSSessionEnd| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}
			
		return ret;
	}
		
	protected function QTTSFini():int
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			var ret:int = mscLib.AS3_QTTSFini();
			
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSFini| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}

        return ret;
	}
		
	protected function QTTSParseMessage( sessionID:String, recvMessage:ByteArray ):int
	{
		try
		{
			var mscLog:ByteArray = new ByteArray;
			mscLib.AS3_fopen( mscLog );
			
			clog.logDBG("QTTSParseMessage| recvMessage = " + recvMessage + ", recvMessage.length = " + recvMessage.length);
			var ret:int = mscLib.AS3_QTTSParseMessage( sessionID, recvMessage, recvMessage.length );
			
			mscLib.AS3_fclose();
			log.writeBytes( mscLog );
			mscLog.clear();
		}
		catch(error:Error)
		{
			clog.logDBG("QTTSParseMessage| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
		}

        return ret;
	}
	
	}
}

package com.iflytek.msc
{
	import com.adobe.audio.record;
	import com.adobe.audio.format.WAVWriter;
	import com.adobe.socket.msc_socket;
	import com.iflytek.msc.IEvaluatorListener;
	import com.iflytek.msc.MSCLog;
	import com.iflytek.msc.QISE;
	
	import com.iflytek.events.MSCEvent;
	import com.iflytek.events.MSCErrorEvent;
	import com.iflytek.events.MSCRecordAudioEvent;
	import com.iflytek.events.MSCResultEvent;
	import com.iflytek.events.MSCMicStatusEvent;
		
	import com.iflytek.define.ErrorCode;
	import com.iflytek.define.RATE;
	import com.iflytek.define.AudioStatus;
	import com.iflytek.define.MessageType;
	import com.iflytek.define.RecogStatus;
	import com.iflytek.define.EPStatus;
	
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.net.FileReference;
	
	import flash.events.TimerEvent;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	public class Evaluator extends EventDispatcher implements IEvaluatorListener
	{
		// -------------------------------------------------------
		// 常量
		// -------------------------------------------------------
		private const SocketDetectIntervalTime:int 	= 50;   // 网络检测时间间隔
		private const ResultGetIntervalTime:int		= 300; // 获取结果时间间隔
		private const AudioDataSendIntervalTime:int	= 200; // 向服务器送音频的间隔
		private const MESSAGE_NOT_COMPLETE:int		= 1;   // 消息不完整
		private const MaxSendAudioDataLengh:uint	= 16 * 1024;    // 音频输送最大
		
		// -------------------------------------------------------
		// 私有变量
		// -------------------------------------------------------
		private var retOfInit:int 			= 0; 
		private var __state:String			= new String();
		private var clog:MSCLog				= new MSCLog();
		private var log:ByteArray			= clog.msclog;
		private var timeout:int				= 30000;        // 等待时间
		
		// 跟socket相关的变量
		private var __serverURL:String		= new String();
		private var __serverPort:int		= 80;
		private var __socket:msc_socket		= null;
		private var socketDetectTimer:Timer	= null;
		private var socketDetectMaxFrcy:int	= 0;        // socket反复连接最大次数
		private var isSocketDetect:Boolean	= false;
		private var msgType:int 			= MessageType.Msg_Session_Begin;
		
		// 跟音频相关的变量
		private var __record:record			= null;
		private var __rate:int				= 16000;
		private var curVolume:int			= 0;
		private var isEndRecord:Boolean		= false;
		private var audioDataBuff:ByteArray	= new ByteArray();  // 存储还没上传的音频
		private var audioSendTimer:Timer	= null;             // 上传音频数据时钟
		
		// 跟评测相关的变量
		private var qise:QISE				= null;
		private var sessionID:String        = new String();     // 会话ID
		private var ssbParams:String		= new String();     // 本次会话参数
		private var ssbUserModelID:String	= new String();     // 用户模型ID
		private var textContent:ByteArray	= new ByteArray();  // 本次评测文本
		private var textParams:String		= new String();     // 本次评测与文本对应的参数
		private var	isSBSuccess:Boolean 	= false;            // 会话是否成功
		private var isSessionEnd:Boolean	= true;
		private var requestRsltTimer:Timer  = null;
		private var resultGetMaxFrcy:int   	= 0;                // 获取结果最大轮询次数
		
		// 测试变量 
		private var isOpenRecorder:Boolean	= true;

		public function Evaluator(configs:String = "", serverURL:String = "dev.voicecloud.cn:80", logLevel:int = 0) 
		{
			clog.output = true;
			
			clog.logDBG("Evaluator| enter, configs = " + configs + ", serverURL = " + serverURL);
			
			qise = new QISE( clog );
			if( null == qise )
			{
				clog.logDBG("Evaluator| leave, QISE() intance failed!");
				return;
			}
			
			// 评测会话之前初始化
			retOfInit = qise.QISEInit(configs, logLevel);
			
			parseCfgParams(configs, serverURL);
			
			// 通信
//			__socket = new msc_socket(this, clog);
//			__socket.connectServer(__serverURL, __serverPort);
			
			// 录音
			__record = new record(16, this, clog);
			
			// 状态
			__state = 'init';
			
			clog.logDBG("Evaluator| leave ok.");
		}
		
		/*
		 * ***********************************************************************
		 * PUBLIC METHODS
		 * ***********************************************************************
		 */ 
		/**
		 * @brief	textPut
		 * 
		 * 送入评测文本
		 *
		 * @auther	jfyuan
		 * @date	2012-5-11
		 * @return	No return value.
		 * @params	text:String - 本次评测文本
		 * @params	params:String - 本次评测文本对应参数
		 * @see
		 */
		public function textPut(text:ByteArray, params:String = ""):void
		{
			clog.logDBG("textPut| enter, params = " + params + ", textLen = " + text.length);
			
			text.position = 0;
			textContent.clear();
			textContent.writeBytes(text);
			textParams = params;
			
			clog.logDBG("textPut| leave ok.");
		}
		 
		 
		 
		/** 
		 * @brief	evaluStart
 		 *
 		 *	开始一路识别会话，同时启动本地录音。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-2-21
 		 * @return	int - Return 0 in success, otherwise return error code.
		 * @params	rate:int — 录音采样率
		 * @params	params:String — 本次会话所用的参数
		 * @params	userModelID:String - 用户模型id
 		 * @see		
 		 */
		public function evaluStart(rate:int = RATE.rate16k, params:String = "", userModelID:String = ""):int
		{
			// 当日志大于5M,则清除先前的日志
			if(clog.msclog.length > clog.MAXLOGLEN)
			{
				clog.msclog.clear();
			}
			
			clog.logDBG("evaluStart| enter, rate = " + rate + "params = " + params + "userModelID = " + userModelID);
			
			if('init' != __state && 'end' != __state) 
			{
				clog.logDBG("evaluStart| leave ok, the session of recog exists.");
				
				return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
			}
			
			__state = 'evaluStart';
			
			// 参数检查
			if( rate != RATE.rate8k 
				 && rate != RATE.rate11k
				 && rate != RATE.rate16k
				 && rate != RATE.rate22k
				 && rate != RATE.rate44k )
			{
				clog.logDBG("recogStart| leave, check rate param.");
				
				__state = 'end';
				
				return ErrorCode.MSP_ERROR_INVALID_PARA_VALUE;
			}
			
			// 检查QISEInit()是否成功
			if(0 != retOfInit)
			{
				clog.logDBG("evaluStart| leave ok, QISEInit() failed!ret = " + String(retOfInit));
				
				__state = 'end';
				
				return retOfInit;			
			}
			
			// 会话是否成功标识
			isSBSuccess = false;
			
			// 初始化录音
			if(__rate != rate)
			{
				__rate = rate;
				__record = new record(convertToAbbrRate(rate), this, clog);
			}
					
			if(isOpenRecorder)
			{
				// 开始录音
				__record.startRecording();
				isEndRecord = false;
			}
			
			// 开始启动定时向服务器送音频的时钟
			audioSendTimer =  new Timer( AudioDataSendIntervalTime );
			audioSendTimer.addEventListener( TimerEvent.TIMER, onSendAudioData );
			audioSendTimer.start();
			
			// 检查通信是否连接成功
			if( null == __socket || !__socket.connected )
			{
				ssbParams = params;
				ssbUserModelID = userModelID;
				__socket = new msc_socket(this, clog);
				__socket.connectServer(__serverURL, __serverPort);
				socketDetectTimer = new Timer( SocketDetectIntervalTime, socketDetectMaxFrcy );
//				socketDetectTimer.addEventListener( TimerEvent.TIMER, onConnectServer );
				socketDetectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onConnectComplete );
				socketDetectTimer.start();
				isSocketDetect = true;
				
				clog.logDBG("evaluStart| leave, reconnect the socket.");
				
				return 0;
			}
			
			// 开始一路会话
			if(0 != sessionBegin(params, userModelID))
			{
				__state = 'end';
			}
			
			
			clog.logDBG("evaluStart| leave ok.");
			
			return 0;
		}
		
		/** 
		 * @brief	recordStop
 		 *
 		 *	停止本地录音。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-5-17
 		 * @return	int - Return 0 in success, otherwise return error code.
		 * @see		
 		 */
		public function recordStop():int
		{
			clog.logDBG("recordStop| enter.");
			
			if(__state != 'evaluStart')
			{
				clog.logDBG("recordStop| leave ok, calling function sequence error.");
				
				return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
			}
			__state = 'recordStop';
			
			// 停止录音
			__record.stopAndEncodeRecording();
			isEndRecord = true;
			dispatchMSCEvent(MSCEvent.RECORD_STOPPED, false, false);
			
			clog.logDBG("recordStop| leave ok.");
			
			return 0;
		}
		
		/** 
		 * @brief	evaluStop
 		 *
 		 *	手动终止本次评测。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-5-17
 		 * @return	int - Return 0 in success, otherwise return error code.
		 * @see		
 		 */
		public function evaluStop():int
		{
			clog.logDBG("evaluStop| enter.");
			
			if( __state == 'evaluStart' || __state == 'recordStop' )
			{
				clog.logDBG("recogStop| leave, calling function sequence error.");
				
				return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
			}
			
			__state = 'evaluStop';
			
			sessionEnd();
			
			clog.logDBG("recogStop| leave ok.");
			
			return 0;
		}
		
		/** 
		 * @brief	logSave
 		 *
 		 *	保存日志。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-5-17
 		 * @return	No return value.
		 * @see		
 		 */
		public function logSave():void
		{
			clog.logSave();
		}
		
		/** 
		 * @brief	dispose
 		 *
 		 *	资源释放。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-5-17
 		 * @return	int - Return 0 in success, otherwise return error code.
		 * @see		
 		 */
		public function dispose():void
		{
			clog.logDBG("dispose| enter.");
			
			textContent.clear();
			
			var ret:int = qise.QISEFini();
			if(0 != ret)
			{
				clog.logDBG("dispose| leave, ret of QISEFini = " + String(ret));
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QISEFini", ret);
				return;
			}
			
			clog.logDBG("dispose| leave ok.");
		}
		
		// 直接输入音频（测试使用）
		public function setAudioData(data:ByteArray):void
		{
			isOpenRecorder = false;
			
			audioDataBuff.writeBytes(data);
			
			isEndRecord = true;
		}
		 
		/*
		 * ************************************************************************
		 * Private Methods
		 * ************************************************************************
		 */
		/**
		 * 解析评测的配置参数以及语音云连接URL
		 */
		private function parseCfgParams(cfgs:String, url:String):void
		{
			// 获取timeout值
			var searchStr:String = "timeout=";
			var strTemp:String = "";
			var strResult:String = "";
			var posBegin:int = 0;
			var posEnd:int = 0;
			
			posBegin = cfgs.search( searchStr );   // 若找不到则返回-1
			if( -1 != posBegin )
			{
				// 去除timeou之前的字符串
				posEnd = cfgs.length;
				strTemp = cfgs.slice(posBegin, posEnd);
				
				posBegin = searchStr.length;
				searchStr = ",";
				posEnd = strTemp.search( searchStr );
				if( -1 == posEnd )   // 没有找到“,”,"timeout"在最后
				{
					clog.logDBG("parseCfgParams| cfgs.length=" + String( cfgs.length ));
					
					posEnd = strTemp.length;
				}
				strResult = strTemp.slice( posBegin, posEnd );
				
				clog.logDBG("parseCfgParams| timeout = " + strResult);
				
				timeout = int( strResult );
				
				if(0 == timeout)
				{
					timeout = 30000;
				}
			}
			else
			{
				clog.logDBG("parseCfgParams| not find timeout set, use deault timeout!");
				
				timeout = 30000;
			}
			// 计算socket尝试连接最大次数
			socketDetectMaxFrcy = int( timeout / SocketDetectIntervalTime );
			clog.logDBG( "socketDetectMaxFrcy = " + String( socketDetectMaxFrcy ) );
			if( 0 == socketDetectMaxFrcy )
			{
				socketDetectMaxFrcy = 1;
			}
			// 识别结果轮询最大次数
			resultGetMaxFrcy = int( timeout / ResultGetIntervalTime );
			clog.logDBG( "resultGetMaxFrcy = " + String( resultGetMaxFrcy ) );
			if( 0 == resultGetMaxFrcy )
			{
				resultGetMaxFrcy = 1;
			}

			// 通信
			// 若后带端口号，则需解析
			strResult = "";
			posBegin = 0;
			searchStr = ":";
			posEnd = url.search( searchStr );
			if( -1 != posEnd )   // 没有设置端口号
			{
				__serverURL = url.slice( posBegin, posEnd );
				
				clog.logDBG("parseCfgParams| URL = " + __serverURL);
				
				posBegin = posEnd + 1;
				posEnd = url.length;
				
				strResult = url.slice( posBegin, posEnd );
				
				clog.logDBG("parseCfgParams| port = " + strResult);
				
				__serverPort = int(strResult);
			}
			else
			{
				__serverURL = url;
				__serverPort = 80;
			}
		}
		 
		/**
		 * 将音频采样率转化为对应的缩写
		 */
		private function convertToAbbrRate(rate:int):int
		{
			var r:int = 0;
			
			switch( rate )
			{
				case 8000:
					r = 8;
					break;
				case 11000:
					r = 11;
					break;
				case 16000:
					r = 16;
					break;
				case 22000:
					r = 22;
					break;
				case 44000:
					r = 44;
					break;
				default:
					// set deault value
					__rate = 16000;
					r = 16;
					break;
			}
			
			return r;
		}
		
		private function sessionBegin(params:String = '', userModelID:String = ''):int
		{
			var returnValues:QISESessionBeginReturns = null;
			var sessionBeginMessage:ByteArray = new ByteArray;
			
			clog.logDBG("sessionBegin| enter.");
			
			returnValues = qise.QISESessionBegin( params, userModelID, sessionBeginMessage );
			
			clog.logDBG("sessionBegin| sessionID = " + returnValues.sessionID + ", ret = " + returnValues.ret);
			
			if(null == returnValues.sessionID || "" == returnValues.sessionID)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISESessionBegin", ErrorCode.MSP_ERROR_INVALID_HANDLE );
				clog.logDBG("sessionBegin| leave, sessionID is null!");
				return -1;
			}
			else if(0 != returnValues.ret)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISESessionBegin", returnValues.ret );
				clog.logDBG("sessionBegin| leave.");
				return -1;
			}
			if(0 == sessionBeginMessage.length)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISESessionBegin", ErrorCode.MSP_ERROR_MSG_BUILD_ERROR );
				clog.logDBG("sessionBegin| leave, built message is null!");
				return -1;
			}
			sessionID = returnValues.sessionID;
			isSessionEnd = false;
			msgType = MessageType.Msg_Session_Begin;
			__socket.sendData(sessionBeginMessage);
			sessionBeginMessage.clear();
			
			clog.logDBG("sessionBegin| leave ok.");
			
			return 0;
		}
		
		private function sendAudioMessage(audioData:ByteArray, audioStatus:int):void
		{
			clog.logDBG("sendAudioMessage| enter, audioData.length = " + String(audioData.length) + ", audioStatus = " + String(audioStatus));
			
			var audioMsg:ByteArray = new ByteArray();
			var returnValues:QISEAudioWriteReturns = null;
			
			audioData.position = 0;
			
			returnValues = qise.QISEAudioWrite( sessionID, audioData, audioStatus, audioMsg );
			
			audioData.clear();
			
			clog.logDBG("sendAudioMessage| ret = " + String(returnValues.ret) 
						+ ", epStatus = " + String(returnValues.epStatus) 
						+ ", evaluStatus = " + String(returnValues.evaluStatus));
			
			if( 0 != returnValues.ret )
			{
				clog.logDBG("sendAudioMessage| leave.");
				
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISEAudioWrite", returnValues.ret );
				sessionEnd("Error");
				
				clog.logDBG("sendAudioMessage| leave, ret of QISEAudioWrite = " + String(returnValues.ret));
				
				return;
			}
			else if(RecogStatus.MSP_REC_STATUS_SUCCESS == returnValues.evaluStatus)  // 识别成功，此时可以获取部分识别结果
			{
				var partRslt:ByteArray = new ByteArray();
				var returnsOfGetRslt:QISEGetResultReturns  = null;
				returnsOfGetRslt = qise.QISEGetResult( sessionID, partRslt );
				
				clog.logDBG("sendAudioMessage| ret = " + returnsOfGetRslt.ret 
							+ ", rsltStatus = " + returnsOfGetRslt.rsltStatus );
				
				if( 0 == returnsOfGetRslt.ret )
				{
					var strRslt:String = partRslt.readMultiByte( partRslt.bytesAvailable, "GBK" );
					
					clog.logDBG("sendAudioMessage| rslt = " + strRslt);
					
					dispatchMSCResultEvent(MSCResultEvent.RESULT_GET, false, false, partRslt, returnsOfGetRslt.rsltStatus);
				}
			}
			
			// send audioMessage
			if( audioMsg.length > 0 )
			{
				__socket.sendData( audioMsg );
			}
/*			else
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName: QISRAudioWrite", ErrorCode.MSP_ERROR_MSG_BUILD_EMPTY );
			}*/
			
			// 断点检测器所处的状态.
			if(  returnValues.epStatus == EPStatus.MSP_EP_AFTER_SPEECH     // 检测到音频的后端点,后续音频被忽略 
			   || returnValues.epStatus == EPStatus.MSP_EP_TIMEOUT         // 超时 
			   || returnValues.epStatus == EPStatus.MSP_EP_ERROR           // 出现错误
			   || returnValues.epStatus == EPStatus.MSP_EP_MAX_SPEECH )    // 音频过大
			{
				// 检查是否多次点击
				if( __state == 'recordStop' )
				{
					return;
				}
				
				__record.stopAndEncodeRecording();
				isEndRecord = true;
				dispatchMSCEvent(MSCEvent.RECORD_STOPPED, false, false);
			
				requestRsltTimer = new Timer( ResultGetIntervalTime, resultGetMaxFrcy );
				requestRsltTimer.addEventListener( TimerEvent.TIMER, onGetEvaluResult );
				requestRsltTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onGetEvaluResultComplete);
				requestRsltTimer.start();
				clog.logDBG("sendAudioMessage| requestRsltTimer.start.");
			
				__state = 'recordStop';
			}
			
			clog.logDBG("sendAudioMessage| leave ok.");
		}
		
		private function sessionEnd(hints:String = ""):void
		{
			clog.logDBG("sessionEnd| enter.");
			
			if(isSessionEnd)
			{
				clog.logDBG("sessionEnd| leave, session has ended!");
				
				return;
			}
			
			__state = 'end';
				
			// 检查录音是否关闭
			if(!isEndRecord)
			{
				clog.logDBG("sessionEnd| stop recording.");
				__record.stopAndEncodeRecording();
				isEndRecord = true;
			}
			
			// 送音频的时钟
			if(null != audioSendTimer && audioSendTimer.running)
			{
				clog.logDBG("sessionEnd| stop audioSendTimer.");
				audioSendTimer.stop();
				audioSendTimer.removeEventListener(TimerEvent.TIMER, onSendAudioData);
			}
			
			// 检查轮询获取评测结果的时钟是否还在运行
			if(null!= requestRsltTimer && requestRsltTimer.running)
			{
				clog.logDBG("sessionEnd| stop requestRsltTimer.");
				requestRsltTimer.stop();
				requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetEvaluResult);
				requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetEvaluResultComplete);
			}
			
			// 结束评测会话
			if(!isSessionEnd)
			{
				var ret:int = qise.QISESessionEnd(sessionID, hints);
				
				clog.logDBG("sessionEnd| ret of QISESessionEnd = " + String(ret));
				
				if(0 != ret)
				{
					dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QISESessionEnd", ret);
				}
				
				// 关闭socket
				__socket.disConnect();
				
				isSessionEnd = true;
			}
			
			dispatchMSCEvent(MSCEvent.EVALU_COMPLETED, false, false);
			
			clog.logDBG("sessionEnd| leave ok.");
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
		
		/**
		 * 每隔200ms向服务器送一次音频
		 */
		private function onSendAudioData( e:TimerEvent ):void
		{
			clog.logDBG("onSendAudioData| enter.");
			
			clog.logDBG("audioDataBuff.length = " + String(audioDataBuff.length));
			
			// 发送音频的先决条件：1、通信连接成功  2、sessionBegin成功
			if(__socket.connected && isSBSuccess)
			{
				audioDataBuff.position = 0;
				
				if(audioDataBuff.bytesAvailable >= MaxSendAudioDataLengh)
				{
					clog.logDBG("audioDataBuff.bytesAvailable = " + String(audioDataBuff.bytesAvailable));
					
					var temp:ByteArray = new ByteArray();
					audioDataBuff.readBytes(temp, 0, MaxSendAudioDataLengh);
					try
					{
						sendAudioMessage(temp, audioStatus);
					}catch(e:Error)
					{
						trace(e);
					}
					temp.clear();
					
					clog.logDBG("onSendAudioData| send audio data of MaxSendAudioDataLengh.");
					
					// 将audioDataBuff中的音频数据向前移动
					clog.logDBG("audioDataBuff.position = " + String(audioDataBuff.position));
					clog.logDBG("audioDataBuff.bytesAvailable = " + String(audioDataBuff.bytesAvailable) + "MaxSendAudioDataLengh = " + String(MaxSendAudioDataLengh));
					//audioDataBuff.readBytes(temp, audioDataBuff.position, audioDataBuff.bytesAvailable);
					temp.writeBytes(audioDataBuff, audioDataBuff.position, audioDataBuff.bytesAvailable);
					audioDataBuff.clear();
					audioDataBuff.writeBytes(temp);
					temp.clear();
				}
				else
				{
					var audioStatus:int = AudioStatus.MSP_AUDIO_SAMPLE_CONTINUE;
					
					if(isEndRecord)
					{
						audioStatus = AudioStatus.MSP_AUDIO_SAMPLE_LAST;
						
						if(0 == audioDataBuff.length)
						{
							audioDataBuff.writeByte(0);
							audioDataBuff.writeByte(0);
						}
					}
					
					if( audioDataBuff.length > 0 )
					{
						try
						{
							sendAudioMessage(audioDataBuff, audioStatus);
						}catch(e:Error)
						{
							trace(e);
						}
					}
					
					audioDataBuff.clear();
				}
			}
			else if(null == __socket || !__socket.connected)  // 通信连接失败，尝试连接
			{
				__socket = new msc_socket(this, clog);
				__socket.connectServer(__serverURL, __serverPort);
				socketDetectTimer = new Timer( SocketDetectIntervalTime, socketDetectMaxFrcy );
//				socketDetectTimer.addEventListener( TimerEvent.TIMER, onConnectServer );
				socketDetectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onConnectComplete );
				socketDetectTimer.start(); 
			}
			
			// 音频向服务器输送完毕
			if(isEndRecord && 0 == audioDataBuff.length)
			{
				audioSendTimer.stop();
				audioSendTimer.removeEventListener(TimerEvent.TIMER, onSendAudioData);
			
				requestRsltTimer = new Timer( ResultGetIntervalTime, resultGetMaxFrcy );
				requestRsltTimer.addEventListener( TimerEvent.TIMER, onGetEvaluResult );
				requestRsltTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onGetEvaluResultComplete);
				requestRsltTimer.start();
				
				clog.logDBG("onSendAudioData| requestRsltTimer start.");
			}
			
			clog.logDBG("onSendAudioData| leave ok.");
		}
		
		/**
		 * 每隔300ms，获取一次识别结果。最多轮询20次。
		 */
		private function onGetEvaluResult(e:TimerEvent):void
		{
			clog.logDBG("onGetEvaluResult| enter, getResultCount = " + String(e.target.currentCount));
			
			var returnValues:QISEGetResultReturns = null;
			var byteRslt:ByteArray = new ByteArray;
			var strRslt:String = new String();
			
			if(isSessionEnd)
			{
				requestRsltTimer.stop();
				requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetEvaluResult);
				requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetEvaluResultComplete);
				
				clog.logDBG("onGetEvaluResult| leave, session has ended.");
				return;
			}
			
			returnValues = qise.QISEGetResult(sessionID, byteRslt);
			
			strRslt = byteRslt.readMultiByte(byteRslt.bytesAvailable, "GBK");
			clog.logDBG("onGetEvaluResult| QISRGetResult:rslt = " + strRslt + ", " 
						+ "ret = " + String(returnValues.ret) + ", " 
						+ "rsltStatus = " + String(returnValues.rsltStatus) + ", "
						+ "rsltRequestMessage = " + returnValues.rsltRequestMessage);
			
			if(0 != returnValues.ret)
			{
				clog.logDBG("onGetEvaluResult| leave, an error occurred in QISEGetResult()!");
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funtionName:QISEGetResult", returnValues.ret);
				sessionEnd("Error");
				return;
			}
			
			if(byteRslt.length > 0)
			{
				dispatchMSCResultEvent(MSCResultEvent.RESULT_GET, false, false, byteRslt, returnValues.rsltStatus);
			}
			
			if(RecogStatus.MSP_REC_STATUS_COMPLETE == returnValues.rsltStatus)  // 识别结束
			{
				// 停止时钟
				requestRsltTimer.stop();
				requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetEvaluResult);
				requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetEvaluResultComplete);
				
				clog.logDBG("onGetEvaluResult| requestRsltTimer has stopped!");
				sessionEnd("Normal");
			}
			
			// 发送grs请求
			if(returnValues.messageLen > 0)
			{
				var grsMessage:ByteArray = new ByteArray();
				
				grsMessage.writeMultiByte(returnValues.rsltRequestMessage, "GBK");
				__socket.sendData( grsMessage );
				
				clog.logDBG("onGetEvaluResult| send grs message.");
			}
			
			clog.logDBG("onGetEvaluResult| leave ok.");
		}
		
		private function onGetEvaluResultComplete(e:TimerEvent):void
		{
			clog.logDBG("onGetEvaluResultComplete| enter.");
			
			// 停止时钟
			requestRsltTimer.stop();
			requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetEvaluResult);
			requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetEvaluResultComplete);
			
			// 会话结束
			sessionEnd("enforce");
			
			clog.logDBG("onGetEvaluResultComplete| leave ok.");
		}
		
		/*
		 * *************************************************************************
		 * Impletement the interface
		 * *************************************************************************
		 */
		public function recordStatus( e:StatusEvent ):void
		{
			dispatchMSCMicStatusEvent( MSCMicStatusEvent.STATUS, false, false, e.code, e.level );
		}
		
		public function sampleDataProcess( sampleData:ByteArray, volume:int ):void
		{
			clog.logDBG("sampleDataProcess| enter, buffer.length = " + String(sampleData.length) + ", volume = " + String(volume));
			
			curVolume = volume;
			if( sampleData.length > 0 )
			{
				// 把64位音频转化为32位的
				var wavWrite:WAVWriter = new WAVWriter();
				var wav:ByteArray = new ByteArray();
				
				wavWrite.numOfChannels = 1;        // 单声道
				wavWrite.sampleBitRate = 16;       // 单点数据存储位数
				wavWrite.samplingRate = __rate;
				
				clog.logDBG("sampleDataProcess| numOfChannels = 1, sampleBitRate = 16, rate = " + String(__rate));
				
				wavWrite.processSamples(wav, sampleData, __rate, 1);
				
				audioDataBuff.writeBytes(wav);
				
				clog.logDBG("sampleDataProcess| audioDataBuff.length = " + String(audioDataBuff.length));
				
				dispatchMSCRecordAudioEvent(MSCRecordAudioEvent.AUDIO_ARRIVED, false, false, wav, curVolume);
			 	wav.clear();
			}
			
			clog.logDBG("sampleDataProcess| leave ok.");
		}
		
		 public function recordError(id:int, text:String):void
		{
			sessionEnd("not get microphone");
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, text, id);
		}
		
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
				if(0 != sessionBegin(ssbParams, ssbUserModelID))
				{
					__state = 'end';
				}
				else
				{
					__state = 'evaluStart';
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
		
		public function getResponseMsg( msg:ByteArray ):void
		{
			clog.logDBG("getResponseMsg| enter.");
			// 如果本次会话已将结束，则关闭socke连接
			if(isSessionEnd)
			{
				clog.logDBG("getResponseMsg| the session is end!");
				__socket.disConnect();
				return;
			}
			else if(0 == msg.length)
			{
				clog.logDBG("getResponseMsg| recieved message is null!");
				return;
			}
			
			var ret:int = qise.QISEParseMessage( sessionID , msg );
			if(MESSAGE_NOT_COMPLETE == ret)
			{
				clog.logDBG("getResponseMsg| leave, recieved message is not complete.");
				return;
			}
			else if(0 != ret)
			{
				clog.logDBG("getResponseMsg| leave, ret = " + String(ret));
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "", ret);
				sessionEnd("Error");
				return;
			}
			
			if( msgType == MessageType.Msg_Session_Begin && 0 == ret )
			{
				if( textContent.length > 0 )  // 上传评测语法
				{
					var textPutMsg:ByteArray = new ByteArray();
					
					clog.logDBG("getResponseMsg| put the text to evaluate!");
					
					ret = qise.QISETextPut(sessionID, textContent, textParams, textPutMsg);
					
					if( 0 != ret )
					{
						clog.logDBG("getResponseMsg| leave, ret = " + String(ret));
						
						sessionEnd("Error");
						
						return;
					}
					
					if(textPutMsg.length > 0)
					{
						__socket.sendData(textPutMsg);
						textPutMsg.clear();
					}
				}
				
				isSBSuccess = true;
				
				msgType = MessageType.Msg_Back_To_Result;
			}
			
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
		
		private function dispatchMSCRecordAudioEvent(type:String
									  , bubbles:Boolean = false
									  , cancelable:Boolean = false
									  , thedata:ByteArray = null
									  , thevolume:Number = 0):void
		{
			var e:MSCRecordAudioEvent = new MSCRecordAudioEvent(type
									  , bubbles
									  , cancelable
									  , thedata
									  , thevolume);
			dispatchEvent(e);
		}
		
		private function dispatchMSCResultEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, rslt:ByteArray = null, rsltStatus:int = 0):void
		{
			var e:MSCResultEvent = new MSCResultEvent(type, bubbles, cancelable, rslt, rsltStatus);
			dispatchEvent(e);
		}
		
		private function dispatchMSCMicStatusEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, code:String = "", level:String = ""):void
		{
			var e:MSCMicStatusEvent = new MSCMicStatusEvent(type, bubbles, cancelable , code, level);
			dispatchEvent(e);
		}
		

	}
	
}

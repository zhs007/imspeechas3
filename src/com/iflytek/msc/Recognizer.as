package com.iflytek.msc
{
	import cmodule.flash_msc.CLibInit;
	import com.adobe.audio.record;
	import com.adobe.audio.format.WAVWriter;
	import com.adobe.socket.msc_socket;
	import com.iflytek.msc.IRecognizerListener;
	import com.iflytek.msc.MSCLog;
	
	import com.iflytek.msc.QISRSessionBeginReturns;
	import com.iflytek.msc.QISRAudioWriteReturns;
	import com.iflytek.msc.QISRGetResultReturns;
	import com.iflytek.msc.QISRParseMessageReturns;
	
	import com.iflytek.events.MSCEvent;
	import com.iflytek.events.MSCErrorEvent;
	import com.iflytek.events.MSCRecordAudioEvent;
	import com.iflytek.events.MSCResultEvent;
	import com.iflytek.events.MSCDataUploadEvent;
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
	
	public class Recognizer extends EventDispatcher implements IRecognizerListener
	{
		// -------------------------------------------------------
		// 常量
		// -------------------------------------------------------
		private const SocketDetectIntervalTime:int 	= 50;   		// 网络检测时间间隔
		 //private const SocketDetectMaxFrequency:int 	= 20;  		// 网络检测最大次数
		private const ResultGetIntervalTime:int		= 300; 			// 获取结果时间间隔
		//private const ResultGetMaxFrequency:int	= 20;  			// 结果获取最大轮询次数
		private const AudioDataSendIntervalTime:int	= 200;          // 向服务器送音频的间隔
		private const MESSAGE_NOT_COMPLETE:int		= 1;   			// 消息不完整
		private const MaxSendAudioDataLengh:uint	= 16 * 1024;    // 音频输送最大
		
		// -------------------------------------------------------
		// 私有变量
		// -------------------------------------------------------
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
		private var socketDetectMaxFrcy:int	= 0;        // socket反复连接最大次数
		private var isSocketDetect:Boolean	= false;
		private var msgType:int 			= MessageType.Msg_Session_Begin;
		
		// 跟音频相关的变量
		private var __record:record			= null;
		private var __rate:int				= 16000;
		private var curVolume:int			= 0;
		private var isEndRecord:Boolean		= false;   			// 关闭录音
		public var sampleDataBuff:ByteArray	= new ByteArray();  // 存储录音原始音频
		private var audioDataBuff:ByteArray	= new ByteArray();  // 存储还没上传的音频
		private var audioSendTimer:Timer	= null;             // 上传音频数据时钟
		
		// 跟识别相关的变量
		private var sessionID:String        = new String();     // 会话ID
		private var __grammarList:ByteArray = new ByteArray;
		private var __params:String			= new String();
		private var	isSBSuccess:Boolean 	= false;            // 会话是否成功
		private var isSessionEnd:Boolean	= true;
		private var requestRsltTimer:Timer  = null;
		private var resultGetMaxFrcy:int   	= 0;                // 获取结果最大轮询次数
		
		// 语法上传
		private var cgrammarArr:Array		= new Array();     // 待上传语法
		
		// 词汇列表上传
		private var isUploadData:Boolean	= false;
		private var uploadDataName:String	= new String();    // 数据名称
		private var uploadData:ByteArray	= new ByteArray;   // 待上传数据
		private var uploadParams:String		= new String();    // 关于上传数据的语法
		
		// 性能计算
		private var dateStopRecord:Date		= new Date;
		private var dateLastResponse:Date	= new Date;
		private var la_fr:Number			= 0;
		
		// 测试用的功能
		private var audioData:ByteArray		= new ByteArray();
		private var isOpenRecorder:Boolean	= true;
		
		public function Recognizer(configs:String = "", serverURL:String = "dev.voicecloud.cn:80", logLevel:int = 0)
		{
			clog.output = true;
			
			clog.logDBG("Recognizer| enter, configs = " + configs + ", serverURL = " + serverURL );
			
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
					errorCode = QISRInit(configs, logLevel);
				}
				else
				{
					errorCode = ErrorCode.MSP_ERROR_FLASH_LIB;
				}
			}
			catch(error:Error)
			{
				clog.logDBG("Recognizer| message = " + error.message + "errorID = " + String(error.errorID));
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
					clog.logDBG("Recognizer| configs.length=" + String( configs.length ));
					
					posEnd = strTemp.length;
				}
				strResult = strTemp.slice( posBegin, posEnd );
				
				clog.logDBG("Recognizer| timeout = " + strResult);
				
				timeout = int( strResult );
				
				if(0 == timeout)
				{
					timeout = 30000;
				}
			}
			else
			{
				clog.logDBG("Recognizer| not find timeout set, use deault timeout!");
				
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
			posEnd = serverURL.search( searchStr );
			if( -1 != posEnd )
			{
				__serverURL = serverURL.slice( posBegin, posEnd );
				
				clog.logDBG("Recognizer| URL = " + __serverURL);
				
				posBegin = posEnd + 1;
				posEnd = serverURL.length;
				
				strResult = serverURL.slice( posBegin, posEnd );
				
				clog.logDBG("Recognizer| port = " + strResult);
				
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
			
			// 录音
			__record = new record(16, this, clog);
			
			// 状态
			__state = 'init';
			
			clog.logDBG("Recognizer| leave ok.");
		}
		public function get _buffer():ByteArray {
			return __record._buffer;
		}
		/*
		 * ***********************************************************************
		 * PUBLIC METHODS
		 * ***********************************************************************
		 */
		/** 
		 * @brief	recogStart
 		 *
 		 *	开始一路识别会话，同时启动本地录音。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-2-21
 		 * @return	int - Return 0 in success, otherwise return error code.
		 * @params	rate:int — 录音采样率
		 * @params	grammarList:ByteArray — 可以是一个语法文件的的url或者一个引擎内置语法列表。多个语法之间以“，”隔开。
		 * @params	params:String — 本次会话所用的参数
 		 * @see		
 		 */
		public function recogStart(rate:int = RATE.rate16k, grammarList:ByteArray = null, params:String = ""):int
		{
			// 当日志大于5M,则清除先前的日志
			if(clog.msclog.length > clog.MAXLOGLEN)
			{
				clog.msclog.clear();
			}
			sampleDataBuff.clear();
			clog.logDBG("recogStart| enter, rate = " + String(rate) + ", grammarList = " + String(grammarList) + "params = " + params);
			
			if('init' != __state && 'end' != __state) 
			{
				clog.logDBG("recogStart| leave ok, calling function sequence error.");
				return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
			}
			__state = 'recogStart';
			
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
			
			// 检查初始化是否成功
			if(ErrorCode.MSP_ERROR_FLASH_LOAD_LIB == errorCode)
			{
				clog.logDBG("recogStart| leave ok, load lib error!");
				
				__state = 'end';
				
				return ErrorCode.MSP_ERROR_FLASH_LOAD_LIB;
			}
			else if(ErrorCode.MSP_ERROR_FLASH_LIB == errorCode)
			{
				clog.logDBG("recogStart| leave ok, lib error!");
				
				__state = 'end';
				
				return ErrorCode.MSP_ERROR_FLASH_LIB;
			}
			else if(0 != errorCode)
			{
				clog.logDBG("recogStart| leave ok, QISRInit() failed! ret = " + String(errorCode));
				
				__state = 'end';
				
				return errorCode;
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
				__params = params;
				if( null != grammarList )
				{
					__grammarList.writeBytes( grammarList );
					grammarList.clear();
				}
				else
				{
					__grammarList = null;
				}
				__socket = new msc_socket(this, clog);
				__socket.connectServer(__serverURL, __serverPort);
				socketDetectTimer = new Timer( SocketDetectIntervalTime, socketDetectMaxFrcy );
//				socketDetectTimer.addEventListener( TimerEvent.TIMER, onConnectServer );
				socketDetectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onConnectComplete );
				socketDetectTimer.start(); 
				isSocketDetect = true;
				
				clog.logDBG("recogStart| leave，socket not connected.");
				return 0;
			}
			
			// 开始一路回话
			if(0 != sessionBegin(grammarList, params))
			{
				__state = 'end';
			}
			
			if(null != grammarList)
			{
				grammarList.clear();
			}
			
			clog.logDBG("recogStart| leave ok.");
			
			return 0;
		}
		
		/** 
		 * @brief	recordStop
 		 *
 		 *	停止本地录音。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-2-23
 		 * @return	int - Return 0 in success, otherwise return error code.
		 * @see		
 		 */
		public function recordStop():int
		{
			clog.logDBG("recordStop| enter.");
			
			if(__state != 'recogStart')
			{
				clog.logDBG("recordStop| leave ok, calling function sequence error.");
				
				return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
			}
			__state == 'recordStop';
			
			// 停止录音
			__record.stopAndEncodeRecording();
			dispatchMSCEvent(MSCEvent.RECORD_STOPPED, false, false);
			isEndRecord = true;
			
			dateStopRecord = new Date();
			
			clog.logDBG("recordStop| leave ok.");
			
			return 0;
		}
		
		/** 
		 * @brief	recogStop
 		 *
 		 *	手动终止本次识别。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-2-23
 		 * @return	int - Return 0 in success, otherwise return error code.
		 * @see		
 		 */
		public function recogStop():int
		{
			clog.logDBG("recogStop| enter.");
			
			if(__state != 'recogStart' && __state != 'recordStop' )
			{
				clog.logDBG("recogStop| leave, calling function sequence error.");
				
				return ErrorCode.MSP_ERROR_FLASH_INVALID_SEQUENCE;
			}
			__state = 'recogStop';
			
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
 		 * @date	2012-2-23
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
 		 * @date	2012-2-23
 		 * @return	No return value.
		 * @see		
 		 */
		public function dispose():void
		{
			clog.logDBG("dispose| enter.");
			
			var ret:int = QISRFini();
			if(0 != ret)
			{
				clog.logDBG("dispose| leave, ret of QISRFini = " + String(ret));
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QISRFini", ret);
				return;
			}
			
			clog.logDBG("dispose| leave ok.");
		}
		
		/** 
		 * @brief	grammarSet
 		 *
 		 *	设置待上传的语法。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-2-23
 		 * @return	No return value.
		 * @pamrams	grammar — 语法字符串
		 * @params	type — 语法类型，可以是uri-list，abnf， xml等
		 * @params	weight - 传入语法的权重 
		 * @see		
 		 */
		public function grammarSet(grammar:ByteArray, type:String, weight:int):void
		{
			clog.logDBG("grammarSet| enter.");
			
			// check params
			if( grammar == null )
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:grammarSet", ErrorCode.MSP_ERROR_INVALID_PARA );
				clog.logDBG("grammarSet| leave, invalid params!");
				return;
			}
			
			if( "" == type )
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:grammarSet", ErrorCode.MSP_ERROR_INVALID_PARA_VALUE );
				
				clog.logDBG("grammarSet| leave, invalid param value!");
				return;
			}
			
			var myGrammar:CGrammar = new CGrammar( grammar, type, weight );
			cgrammarArr.push( myGrammar );
			
			clog.logDBG("grammarSet| leave ok.");
		}
		
		/** 
		 * @brief	dataUpload
 		 *
 		 *	设置待上传的语法。
 		 *
 		 * @author	jfyuan
 		 * @date	2012-2-24
 		 * @return	No return value.
		 * @pamrams	dataName — 数据名称，唯一区别于其他数据
		 * @params	data — 数据
		 * @params	params — 关于上传数据的语法 
		 * @see		
 		 */
		public function dataUpload(dataName:String, data:ByteArray, params:String):void
		{
			clog.logDBG("dataUpload| enter, dataName = " + dataName + ", "
						+ "params = " + params + ", "
						+  "data = \n" + String(data));
			
			//check params
			if( null == data )
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:dataUpload", ErrorCode.MSP_ERROR_INVALID_PARA );
				
				clog.logDBG("dataUpload| leave, invalid params!");
				return;
			}
			if( "" == dataName || "" == params )
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:dataUpload", ErrorCode.MSP_ERROR_INVALID_PARA_VALUE );
				
				clog.logDBG("dataUpload| leave, invalid param value!");
				return;
			}
			
			uploadDataName = dataName;
			uploadData.writeBytes(data);
			data.clear();
			uploadParams = params;
			
			isUploadData = true;
			
			// 开始一路会话
			__grammarList = null;
			__params = "ssm=1,sub=asr";
			if( null == __socket || !__socket.connected )
			{
				__socket = new msc_socket(this, clog);
				__socket.connectServer(__serverURL, __serverPort);
				socketDetectTimer = new Timer( SocketDetectIntervalTime, socketDetectMaxFrcy );
//				socketDetectTimer.addEventListener( TimerEvent.TIMER, onConnectServer );
				socketDetectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onConnectComplete );
				socketDetectTimer.start(); 
				isSocketDetect = true;
				
				clog.logDBG("dataUpload| leave, socket not connected!");
				return;
			}
			msgType = MessageType.Msg_Session_Begin;
			var ret:int = sessionBegin( __grammarList, __params );
			if( 0 != ret )
			{
				isUploadData = false;
				clog.logDBG("dataUpload| leave, ret = " + String(ret));
				return;
			}
			isUploadData = true;
			
			clog.logDBG("dataUpload| leave ok.");
		}
		
		public function audioDataSave():void
		{
			var fileRefenrence:FileReference = new FileReference();
			fileRefenrence.save( audioData, "data.pcm" );
			audioData.clear();
		}
		
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
		 * 将音频采样率转化为对应的缩写
		 */
		private function convertToAbbrRate( rate:int ):int
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
		
		private function sessionBegin(grammarList:ByteArray = null, params:String = ''):int
		{
			var returnValues:QISRSessionBeginReturns = null;
			var sessionBeginMessage:ByteArray = new ByteArray;
			
			clog.logDBG("sessionBegin| enter.");
			
			returnValues = QISRSessionBegin( grammarList, params, sessionBeginMessage );
			
			clog.logDBG("sessionBegin| sessionID = " + returnValues.sessionID + ", ret = " + returnValues.ret);
			
			if(null == returnValues.sessionID || "" == returnValues.sessionID)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISRSessionBegin", ErrorCode.MSP_ERROR_INVALID_HANDLE );
				clog.logDBG("sessionBegin| leave, sessionID is null!");
				return -1;
			}
			else if(0 != returnValues.ret)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISRSessionBegin", returnValues.ret );
				clog.logDBG("sessionBegin| leave, ret = " + String(returnValues.ret));
				return -1;
			}
			if(0 == sessionBeginMessage.length)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISRSessionBegin", ErrorCode.MSP_ERROR_MSG_BUILD_ERROR );
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
			var audioMsg:ByteArray = new ByteArray();
			var returnValues:QISRAudioWriteReturns = null;
			
			clog.logDBG("sendAudioMessage| enter, audioData.length = " + String(audioData.length) + ", audioStatus = " + String(audioStatus));
		
			returnValues = QISRAudioWrite( sessionID, audioData, audioStatus, audioMsg );
			audioData.clear();
			
			clog.logDBG("sendAudioMessage| ret = " + String(returnValues.ret) 
						+ ", epStatus = " + String(returnValues.epStatus) 
						+ ", recogStatus = " + String(returnValues.recogStatus));
			
			if( 0 != returnValues.ret )
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:QISRAudioWrite", returnValues.ret );
				
				clog.logDBG("sendAudioMessage| leave, ret of QISRAudioWrite = " + String(returnValues.ret));
				
				sessionEnd("Error");
				
				return;
			}
			else if(RecogStatus.MSP_REC_STATUS_SUCCESS == returnValues.recogStatus)  // 识别成功，此时可以获取部分识别结果
			{
				var partRslt:ByteArray = new ByteArray();
				var returnsOfGetRslt:QISRGetResultReturns  = null;
				returnsOfGetRslt = QISRGetResult( sessionID, partRslt );
				clog.logDBG("sendAudioMessage| ret = " + returnsOfGetRslt.ret 
							+ ", rsltStatus = " + returnsOfGetRslt.rsltStatus );
				if( 0 == returnsOfGetRslt.ret )
				{
					var strRslt:String = partRslt.readMultiByte( partRslt.bytesAvailable, "UTF-8" );
					clog.logDBG("sendAudioMessage| rslt = " + strRslt);
					dispatchMSCResultEvent(MSCResultEvent.RESULT_GET, false, false, partRslt, returnsOfGetRslt.rsltStatus);
				}
			}
			
			// send audioMessage
			clog.logDBG("audioMsg.length = " + String(audioMsg.length));
			if( audioMsg.length > 0 )
			{
				__socket.sendData( audioMsg );
			}
			
			// 断点检测器所处的状态.
			if(  returnValues.epStatus == EPStatus.MSP_EP_AFTER_SPEECH     // 检测到音频的后端点,后续音频被忽略 
			   || returnValues.epStatus == EPStatus.MSP_EP_TIMEOUT         // 超时 
			   || returnValues.epStatus == EPStatus.MSP_EP_ERROR           // 出现错误
			   || returnValues.epStatus == EPStatus.MSP_EP_MAX_SPEECH )    // 音频过大
			{
				// 检查是否多次点击
				if( __state == 'recordStop' )
				{
					clog.logDBG("sendAudioMessage| leave, recording stopped!");
					return;
				}
				
				__record.stopAndEncodeRecording();
				isEndRecord = true;
				dispatchMSCEvent(MSCEvent.RECORD_STOPPED, false, false);
				
				dateStopRecord = new Date();
				
				clog.logDBG("sendAudioMessage| record stop.");
			
				__state = 'recordStop';
			}
			
			clog.logDBG("sendAudioMessage| leave ok.");
		}
		
		private function sessionEnd(hints:String = ""):void
		{
			clog.logDBG("sessionEnd| enter.");
			
			if(isSessionEnd)
			{
				clog.logDBG("sessionEnd| leave, session has ended.");
				
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
			
			// 检查轮询获取识别结果的时钟是否还在运行
			if(null!= requestRsltTimer && requestRsltTimer.running)
			{
				clog.logDBG("sessionEnd| stop requestRsltTimer.");
				requestRsltTimer.stop();
				requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetRecogResult);
				requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetRecogResultComplete);
			}
			
			// 结束识别会话
			if(!isSessionEnd)
			{
				var ret:int = QISRSessionEnd(sessionID, hints);
				clog.logDBG("sessionEnd| ret of QISRSessionEnd = " + String(ret));
				if(0 != ret)
				{
					dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QISRSessionEnd", ret);
				}
				
				// 关闭socket
				__socket.disConnect();
				
				isSessionEnd = true;
			}
			
			dispatchMSCEvent(MSCEvent.RECOG_COMPLETED, false, false);
			
			clog.logDBG("sessionEnd| leave ok.");
		}
		
		/**
		 * 向服务器发送事先设置好的语法
		 */
		private function sendGrammarMessage( theGrammar:CGrammar ):int
		{
			clog.logDBG("sendGrammarMessage| enter.");
			
			var grammarMsg:ByteArray = new ByteArray();
			var ret:int = QISRGrammarActivate( sessionID, theGrammar.getGrammar(), theGrammar.getType(), theGrammar.getWeight(), grammarMsg );
			if( 0 != ret )
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName: QISRGrammarActivate", ret);
				clog.logDBG("sendGrammarMessage| leave, ret of QISRGrammarActivate = " + String(ret) + "!");
				return ret;
			}
			if( grammarMsg.length > 0 )
			{
				__socket.sendData( grammarMsg );
			}
			else
			{
				ret = -1;
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName: QISRGrammarActivate", ErrorCode.MSP_ERROR_MSG_BUILD_ERROR); 
				clog.logDBG("sendGrammarMessage| leave, building message failed!");
				return ret;
			}
			
			clog.logDBG("sendGrammarMessage| leav ok.");
			return ret;
		}
		
		/*
		 * ************************************************************************
		 * Do things when the event is dispatched
 		 * ************************************************************************
		 */
		private function onConnectServer(e:TimerEvent):void
		{
			clog.logDBG("onConnectServer| try to connectServer ...");
			__socket.connectServer(__serverURL, __serverPort);
		}
		
		private function onConnectComplete(e:TimerEvent):void
		{
			clog.logDBG("onConnectComplete| enter.");
			
			if(!__socket.connected)
			{
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funcName:onConnectComplete", ErrorCode.MSP_ERROR_NET_CONNECTSOCK );
				isSocketDetect = false;
				socketDetectTimer.stop();
				socketDetectTimer.removeEventListener(TimerEvent.TIMER, onConnectServer);
				socketDetectTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onConnectComplete);
			}
			
			clog.logDBG("onConnectComplete| leave ok.");
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
					var temp:ByteArray = new ByteArray();
					
					clog.logDBG("audioDataBuff.bytesAvailable = " + String(audioDataBuff.bytesAvailable));
					
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
/**
 * xlhou modify start ,because the socket have created, don't create again
 */
/*
			else if(null == __socket || !__socket.connected)  // 通信连接失败，尝试连接
			{
				__socket = new msc_socket(this, clog);
				__socket.connectServer(__serverURL, __serverPort);
				socketDetectTimer = new Timer( SocketDetectIntervalTime, socketDetectMaxFrcy );
//				socketDetectTimer.addEventListener( TimerEvent.TIMER, onConnectServer );
				socketDetectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onConnectComplete );
				socketDetectTimer.start(); 
			}
*/
			else if (null == __socket)	// exceptin handle , if the socket is null ,need to create and start monitor timer
			{
				__socket = new msc_socket(this, clog);
				__socket.connectServer(__serverURL, __serverPort);
				socketDetectTimer = new Timer( SocketDetectIntervalTime, socketDetectMaxFrcy );
//				socketDetectTimer.addEventListener( TimerEvent.TIMER, onConnectServer );
				socketDetectTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onConnectComplete );
				socketDetectTimer.start(); 
			}
/**
 *xlhou modify end
 */

			// 音频向服务器输送完毕
			if(isEndRecord && 0 == audioDataBuff.length)
			{
				audioSendTimer.stop();
				audioSendTimer.removeEventListener(TimerEvent.TIMER, onSendAudioData);
			
				requestRsltTimer = new Timer( ResultGetIntervalTime, resultGetMaxFrcy );
				requestRsltTimer.addEventListener( TimerEvent.TIMER, onGetRecogResult );
				requestRsltTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onGetRecogResultComplete);
				requestRsltTimer.start();
				
				clog.logDBG("onSendAudioData| requestRsltTimer start.");
			}
			
			clog.logDBG("onSendAudioData| leave ok.");
		}
		
		/**
		 * 每隔300ms，获取一次识别结果。
		 */
		private function onGetRecogResult(e:TimerEvent):void
		{
			clog.logDBG("onGetRecogResult| enter, getResultCount = " + String(e.target.currentCount));
			
			var returnValues:QISRGetResultReturns = null;
			var byteRslt:ByteArray = new ByteArray;
			var strRslt:String = new String();
			
			if(isSessionEnd)
			{
				clog.logDBG("onGetRecogResult| leave, session has ended.");
				
				return;
			}
			
			returnValues = QISRGetResult(sessionID, byteRslt);
			strRslt = byteRslt.readMultiByte(byteRslt.bytesAvailable, "GBK");// "UTF-8");
			clog.logDBG("onGetRecogResult| QISRGetResult:rslt = " + strRslt + ", " 
						+ "ret = " + String(returnValues.ret) + ", " 
						+ "rsltStatus = " + String(returnValues.rsltStatus) + ", "
						+ "rsltRequestMessage = " + returnValues.rsltRequestMessage);
			if(0 != returnValues.ret)
			{
				clog.logDBG("onGetRecogResult| leave, an error occurred in QISRGetResult()!");
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "funtionName:QISRGetResult", returnValues.ret);
				sessionEnd("Error");
				return;
			}
			
/*			if( returnValues.rsltRequestMessage )
			{
				var temp:ByteArray = new ByteArray();
				temp.writeMultiByte(returnValues.rsltRequestMessage,"UTF-8");
				__socket.sendData( temp );
			}*/
			if(strRslt.length > 0)
			{
				dispatchMSCResultEvent(MSCResultEvent.RESULT_GET, false, false, byteRslt, returnValues.rsltStatus);
			}
			
			if(RecogStatus.MSP_REC_STATUS_COMPLETE == returnValues.rsltStatus)  // 识别结束
			{
				// 停止时钟
				requestRsltTimer.stop();
				requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetRecogResult);
				requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetRecogResultComplete);
				
				dateLastResponse = new Date();
				la_fr = dateLastResponse.getTime() - dateStopRecord.getTime();
				clog.logDBG("onGetRecogResult| la_fr(录音结束到获取第一个结果) = " + String(la_fr));
				
				clog.logDBG("onGetRecogResult| requestRsltTimer has stopped!");
				sessionEnd("Normal");
			}
			
			clog.logDBG("onGetRecogResult| leave ok.");
		}
		
		private function onGetRecogResultComplete(e:TimerEvent):void
		{
			clog.logDBG("onGetRecogResultComplete| enter.");
			
			dateLastResponse = new Date();
			la_fr = dateLastResponse.getTime() - dateStopRecord.getTime();
			clog.logDBG("onGetRecogResult| la_fr(录音结束到获取第一个结果) = " + String(la_fr));
			
			// 停止时钟
			requestRsltTimer.stop();
			requestRsltTimer.removeEventListener(TimerEvent.TIMER, onGetRecogResult);
			requestRsltTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onGetRecogResultComplete);
			
			// 会话结束
			sessionEnd();
			
			clog.logDBG("onGetRecogResultComplete| leave ok.");
		}
		
		/*
		 * *************************************************************************
		 * Impletement the interface
		 * *************************************************************************
		 */
		public function recordStatus(e:StatusEvent):void
		{
			//this.dispatchEvent( e );
			dispatchMSCMicStatusEvent( MSCMicStatusEvent.STATUS, false, false, e.code, e.level );
		}
		
		public function sampleDataProcess(sampleData:ByteArray, volume:int):void
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
				
				clog.logDBG("sampleDataProcess| wav.length = " + String(wav.length));
				
				audioDataBuff.writeBytes(wav);
				// 保存音频
				audioData.writeBytes(wav);
				sampleDataBuff.writeBytes(sampleData);
				
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
				if(0 != sessionBegin(__grammarList, __params))
				{
					__state = 'end';
					
					// 上传词汇列表
					if(isUploadData)
					{
						isUploadData = false;
					}
				}
			}
			
			clog.logDBG("notifyConnectSuccess| leave ok.");
		}
		
		public function getIOError( socketError:IOErrorEvent ):void
		{
			dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "", ErrorCode.MSP_ERROR_FLASH_SOCKET_IO_ERROR);
			
			if(__state == 'recogStart' && __state == 'recordStop' )
			{
			clog.logDBG("getIOError| sessionEnd.");
				sessionEnd();
			}
			else
			{
				// 关闭socket
			clog.logDBG("getIOError| socket.disConnect.");
				__socket.disConnect();
			}
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
			
			var returnValues:QISRParseMessageReturns = QISRParseMessage( sessionID , msg, msgType );
			if(MESSAGE_NOT_COMPLETE == returnValues.ret)
			{
				clog.logDBG("getResponseMsg| leave, recieved message is not complete.");
				return;
			}
			else if(0 != returnValues.ret)
			{
				clog.logDBG("getResponseMsg| leave, ret = " + String(returnValues.ret));
				sessionEnd();
				dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QISRParseMessage", returnValues.ret);
				return;
			}
			
			if( msgType == MessageType.Msg_Session_Begin && 0 == returnValues.ret )
			{
				if( isUploadData )  // 上传语法数据
				{
					var uploadDataMsg:ByteArray = new ByteArray();
				
					var ret:int = QISRUploadData( sessionID, uploadDataName, uploadData, uploadParams, uploadDataMsg );
					clog.logDBG("getResponseMsg| ret of QISRUploadData = " + String(ret)) + ".";
					if( 0 != ret )
					{
						dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QISRUploadData", ret);
						isUploadData = false;
						sessionEnd();
						
						clog.logDBG("getResponseMsg| leave.");
						return;
					}
					else if( 0 == uploadDataMsg.length )
					{
						dispatchMSCErrorEvent(MSCErrorEvent.ERROR, false, false, "functionName:QISRUploadData", ErrorCode.MSP_ERROR_MSG_BUILD_ERROR);
						isUploadData = false;
						sessionEnd();
						clog.logDBG("getResponseMsg| leave, building message failed!");
						return;
					}
					__socket.sendData( uploadDataMsg );
					
					msgType = MessageType.Msg_QISR_Upload_Data;
					isUploadData = false;
					clog.logDBG("getResponseMsg| leave.");
					return;
				}
				
				// Active grammar
				while( cgrammarArr.length > 0 )
				{
					if( 0 != sendGrammarMessage( cgrammarArr.shift() ) )
					{
						clog.logDBG("getResponseMsg| leave, sending grammar message failed!");
						
						sessionEnd();
						return;
					}
				}
				
				isSBSuccess = true;
				
				msgType = MessageType.Msg_Back_To_Result;
			}
			else if( msgType == MessageType.Msg_QISR_Upload_Data && 0 == returnValues.ret )    // 获取上传语法后的应答消息
			{
				isUploadData = false;
				dispatchMSCDataUploadEvent(MSCDataUploadEvent.EXTEND_ID, false, false, returnValues.rslt);
				
				clog.logDBG("getResponseMsg| leave ok.");
				
				// 会话结束
				sessionEnd();
				
				return;
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
		
		private function dispatchMSCDataUploadEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, id:String = ""):void
		{
			var e:MSCDataUploadEvent = new MSCDataUploadEvent(type, bubbles, cancelable, id);
			dispatchEvent(e);
		}
		
		private function dispatchMSCMicStatusEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, code:String = "", level:String = ""):void
		{
			var e:MSCMicStatusEvent = new MSCMicStatusEvent(type, bubbles, cancelable , code, level);
			dispatchEvent(e);
		}
		
		/*
		 * ************************************************************************
		 * MSC QISR BASE API
		 * ************************************************************************
		 */
		// 初始化MSC的ISR部分
		protected function QISRInit( configs:String, lvl:int ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISRInit( configs, lvl );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISRInit| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		// 开始一次会话
		protected function QISRSessionBegin( grammarList:ByteArray, params:String, sessionBeginMsg:ByteArray ):QISRSessionBeginReturns
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var out:Array = new Array();
				if( null == grammarList )
				{
					out = mscLib.AS3_QISRSessionBegin( null, 0, params, sessionBeginMsg );
				}
				else
				{
					out = mscLib.AS3_QISRSessionBegin( grammarList, grammarList.length, params, sessionBeginMsg );
				}
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				var returnValues:QISRSessionBeginReturns = new QISRSessionBeginReturns(out);
			}
			catch(error:Error)
			{
				clog.logDBG("QISRSessionBegin| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return returnValues;
		}
		
		protected function QISRGrammarActivate( sessionID:String, grammar:ByteArray, type:String, weight:int, grammarMsg:ByteArray ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISRGrammarActivate( sessionID, grammar, grammar.length, type, weight, grammarMsg );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISRGrammarActivate| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		// 写入用来识别的语音
		protected function QISRAudioWrite( sessionID:String, audioData:ByteArray, audioStatus:int, audioMsg:ByteArray ):QISRAudioWriteReturns
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var out:Array = mscLib.AS3_QISRAudioWrite( sessionID, audioData, audioData.length, audioStatus, audioMsg );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				var returnValues:QISRAudioWriteReturns = new QISRAudioWriteReturns(out);
			}
			catch(error:Error)
			{
				clog.logDBG("QISRAudioWrite| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return returnValues;
		}
		
		// 获取识别结果
		protected function QISRGetResult( sessionID:String, rslt:ByteArray ):QISRGetResultReturns
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var out:Array = mscLib.AS3_QISRGetResult( sessionID, rslt );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				var returnValues:QISRGetResultReturns = new QISRGetResultReturns(out);
			}
			catch(error:Error)
			{
				clog.logDBG("QISRGetResult| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return returnValues;
		}
		
		// 上传语法文件
		protected function QISRUploadData( sessionID:String, dataName:String, data:ByteArray, params:String, loadDataMsg:ByteArray ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISRUploadData( sessionID, dataName, data, data.length, params, loadDataMsg );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISRUploadData| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		// 结束一路回话
		protected function QISRSessionEnd( sessionID:String, hints:String = "" ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISRSessionEnd( sessionID, hints );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISRSessionEnd| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		// 逆初始化MSC的ISR部分
		protected function QISRFini():int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISRFini();
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISRFini| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		// 响应消息解析
		protected function QISRParseMessage( sessionID:String ,rcvMsg:ByteArray, type:int = MessageType.Msg_Type_Unknown ):QISRParseMessageReturns
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var out:Array = mscLib.AS3_QISRParseMessage( sessionID , rcvMsg, rcvMsg.length, type );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				var returnValues:QISRParseMessageReturns = new QISRParseMessageReturns(out);
			}
			catch(error:Error)
			{
				clog.logDBG("QISRParseMessage| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return returnValues;
		}

	}
	
}

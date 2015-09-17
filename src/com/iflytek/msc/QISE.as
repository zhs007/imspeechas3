package com.iflytek.msc
{
	import cmodule.flash_msc.CLibInit;
	import cmodule.flash_msc.MemUser;
	import com.iflytek.define.ErrorCode;
	import com.iflytek.msc.MSCLog;
	
	import com.iflytek.msc.QISESessionBeginReturns;
	import com.iflytek.msc.QISEAudioWriteReturns;
	import com.iflytek.msc.QISEGetResultReturns;
	
	import flash.utils.ByteArray;
	
	public class QISE 
	{
		// 库加载
		private var mscLib:Object				= null;  
		private var mem:MemUser					= new MemUser();
		private var memAddr:int 				= 0;              // 内存块首地址
		
		
		// 日志记录
		private var clog:MSCLog				 	= new MSCLog();
		private var log:ByteArray			 	= clog.msclog;

		public function QISE(theclog:MSCLog = null) 
		{	
			if( null != theclog )
			{
				clog = theclog;
				log = clog.msclog;
			}
			clog.output = true;
			
			clog.logDBG("QISE| enter.");
			
			clog.logDBG("QISE| version: v1.3.0");
			
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
					clog.logDBG("QISE| CLibInit() return null.");
				}
				
				if(null == mscLib)
				{
					clog.logDBG("QISE| Init() return null.");
				}
			}
			catch(error:Error)
			{
				clog.logDBG("QISE| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			clog.logDBG("QISE| leave ok.");
		}
	
		/*
		 * ************************************************************************
	 	* MSC QISR BASE API
	 	* ************************************************************************
		 */
		/**
		 * @fn		QISEInit
		 * @brief	Initialize API
		 *
		 * Load API Module with sepecifid configuration
		 * 
		 * @return 	int				- Return 0 in success, otherwise return error code.
		 * @param	configs:String	- [in] configurations to initialize
		 * @param	logLevel:int	- [in] log level
		 * @see
		 */
		public function QISEInit( configs:String = "", logLevel:int = 0 ):int
		{
			var mscLog:ByteArray = new ByteArray;
			
			try
			{
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISEInit( configs, logLevel );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISEInit| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
	
		/**
		 * @fn		QISESessionBegin
		 * @brief	Begin a Evaluator Session
		 * 
		 * Create a Evaluator session to Evaluate audio data
		 *
		 * @return	QISESessionBeginReturns		- return sessionID and error code.
		 * @params	params:String				- [in] parameters when the session created.
		 * @params	userModelID:String  		- [in] user model id
		 * @params	sessionBeginMsg:ByteArray	- [out]the message of session begin
		 * @see
		 */
		public function QISESessionBegin( params:String, userModelID:String, sessionBeginMsg:ByteArray ):QISESessionBeginReturns
		{
			try
			{
				if(log.length > 5 * 1024 * 1024)
				{
					log.clear();
				}
				
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var out:Array = new Array();
				out = mscLib.AS3_QISESessionBegin( params, userModelID, sessionBeginMsg );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				var returnValues:QISESessionBeginReturns = new QISESessionBeginReturns(out);
			}
			catch(error:Error)
			{
				clog.logDBG("QISESessionBegin| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return returnValues;
		}
	
		/**
		 * @fn		QISETextPut
		 * @brief	Put Text
		 *
		 * Writing text to evaluator.
		 *
		 * @return 	int					- Return 0 in success, otherwise return error code.
		 * @param	sessionID:String	- [in] The seesion id returned by QISESessionBegin
		 * @param	text:Bytearray		- [in] Text buffer
	 	 * @param	params:String		- [in] Parameters decribing the text.
		 * @param	textPutMsg			- [out]The message of text put
		 * @see
		 */
		public function QISETextPut( sessionID:String, text:ByteArray, params:String, textPutMsg:ByteArray ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = 0;
				if( null == text || 0 == text.length )
				{
					return ErrorCode.MSP_ERROR_TTS_TEXT_EMPTY;
				}
				ret = mscLib.AS3_QISETextPut( sessionID, text, text.length, params, textPutMsg );
				//text.clear();
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISETextPut| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());

			}
			
			return ret;
		}
	
		/**
		 * @fn		QISEAudioWrite
		 * @brief	Write Audio
		 *
		 * Writing binary audio data to evaluator
		 *
		 * @return	QISEAudioWriteReturns		- return error Code, epStatus and evalStatus
		 * @param	sessionID:String			- [in] The seesion id returned by QISESessionBegin
		 * @param	audioData:ByteArray			- [in] Audio data to write
		 * @param	audioStatus:int				- [in] Audio status
		 * @param	audioMsg					- [out]the message of audio write
		 */
		public function QISEAudioWrite( sessionID:String, audioData:ByteArray, audioStatus:int, audioMsg:ByteArray ):QISEAudioWriteReturns
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
			
				clog.logDBG("QISEAudioWrite| sessionID = " + sessionID + ", length = " + String( audioData.length ) + ", audioStatus = " + String( audioStatus ));
			
				mscLib.AS3_fopen( mscLog );
			
				var out:Array = mscLib.AS3_QISEAudioWrite( sessionID, audioData, audioData.length, audioStatus, audioMsg );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				var returnValues:QISEAudioWriteReturns = new QISEAudioWriteReturns(out);
			}
			catch(error:Error)
			{
				clog.logDBG("QISEAudioWrite| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return returnValues;
		}
	
		/**
	 	* @fn		QISEResultInfo
	 	* @brief	Evaluate Info
		 * 
		 * Get evaluate extro info in Specified format.
		 *
		 * @return	int					- return error Code
		 * @param	sessionID:String	- [in] The seesion id returned by QISESessionBegin
		 * @param	extroInfo:ByteArray	- [out]Extro info,such as audio data to text pos
	 	* @see
		 */
		public function QISEResultInfo( sessionID:String, extroInfo:ByteArray ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISEResultInfo( sessionID, extroInfo );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
			}
			catch(error:Error)
			{
				clog.logDBG("QISEResultInfo| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
	
		/** 
		 * @fn		QISEGetResult
		 * @brief	Get Evaluate Result in Specified Format
		 * 
		 *  Get evaluate result in Specified format.
		 * 
		 * @return	QISEGetResultReturns	- Return return error code, status of recognition result and the message of result request message
		 * @param	sessionID:String		- [in] session id returned by session begin
	 	* @param	rslt:ByteArray			- [out]Evaluate result
		 * @see		
		 */
		public function QISEGetResult( sessionID:String, rslt:ByteArray ):QISEGetResultReturns
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var out:Array = mscLib.AS3_QISEGetResult( sessionID, rslt );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				var returnValues:QISEGetResultReturns = new QISEGetResultReturns(out);
			
				clog.logDBG("QISEGetResult| rslt.length=" + String(rslt.length));
			}
			catch(error:Error)
			{
				clog.logDBG("QISEGetResult| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			
			return returnValues;
		}
	
		/**
		 * @fn		QISESessionEnd
		 * @brief	End a ISE Session
		 *
		 * End a evaluation session, release all resource
		 *
		 * @return	int					- return error code
		 * @param	sessionID:String	- [in] session id returned by session begin
		 * @param	hints:String		- [in] Reason to end current session
		 * @see
		 */
		public function QISESessionEnd( sessionID:String, hints:String = "" ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISESessionEnd( sessionID, hints );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISESessionEnd| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		/**
		 * @fn		QISEFini
		 * @brief	Uninitialize API
		 *
		 * The last funciton to be called
		 *
		 * @return	int			- [in] return error code
		 * @see
		 */
		public function QISEFini():int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				var ret:int = mscLib.AS3_QISEFini();
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			}
			catch(error:Error)
			{
				clog.logDBG("QISEFini| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		/**
		 * @fn		QISEParseMessage
		 * @brief	Parse message
		 *	
		 *	Parse message from sever
		 *
		 * @return	int					- return error code
		 * @param	sessionID:String	- [in] session id returned by session begin
		 * @param	rcvMsg:ByteArray	- [in] the message recieved from server
		 * @see
		 */
		public function QISEParseMessage( sessionID:String ,rcvMsg:ByteArray ):int
		{
			try
			{
				var mscLog:ByteArray = new ByteArray;
				mscLib.AS3_fopen( mscLog );
			
				rcvMsg.position = 0; 
			
				var ret:int = mscLib.AS3_QISEParseMessage( sessionID, rcvMsg, rcvMsg.length );
			
				mscLib.AS3_fclose();
				log.writeBytes( mscLog );
				mscLog.clear();
			
				clog.logDBG("QISEParseMessage| ret = " + String(ret));
			}
			catch(error:Error)
			{
				clog.logDBG("QISEParseMessage| Exception, error detail: message = " + error.message + ", stack trace = " + error.getStackTrace());
			}
			
			return ret;
		}
		
		/**
		 * @fn		logSave
		 * @brief	Save msc log
 		 *
 		 *	Save ms log
 		 *
		 * @see		
 		 */
		public function logSave():void
		{
			clog.logSave();
		}
		
	}
	
}

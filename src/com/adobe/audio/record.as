package com.adobe.audio
{
	import com.adobe.audio.IRecordListener;
	import com.iflytek.msc.MSCLog;
	import com.iflytek.define.ErrorCode;
	
	import com.adobe.audio.format.WAVWriter;
	import flash.display.MovieClip;
	import flash.display.StageScaleMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.ProgressEvent;
	import flash.events.SampleDataEvent;
	import flash.events.StatusEvent;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.net.*;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	
	/**
	 * ...
	 * @author hbb
	 */
	public class record extends MovieClip 
	{
		private   var outListener:IRecordListener = null;
		
		private   var _mic:Microphone;
		private   var m_rate:int;
		private   var _voice:ByteArray;
		private   var buffer:ByteArray = new ByteArray;
		
		private var _state:String;
		private var clog:MSCLog = null;
		
		public var _buffer:ByteArray = new ByteArray();
		public function record( rate:int, listener:IRecordListener, theclog:MSCLog ):void 
		{
			clog = theclog;
			m_rate = rate;
			outListener = listener;
			
			clog.logDBG("record | enter, rate =" + String(rate) + ".");
			
				_buffer.length = 0;
			init();
			if (_mic.muted)
			{
				//Security.showSettings(SecurityPanel.MICROPHONE);
			}
			
//			if (stage) init();
//			else addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			clog.logDBG("record | leave ok.");
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			init();
		}
		
		private function init():void
		{
//			stage.scaleMode = StageScaleMode.NO_SCALE;
//			stage.stageFocusRect = false;
			
			if (!setupMicrophone()) return;
			
			_state = 'pre-recording';
		}
		
		private function setupMicrophone():Boolean
		{
			clog.logDBG("setupMicrophone | enter.");
			
			_mic = Microphone.getMicrophone();
			if (!_mic) 
			{ 
				clog.logDBG("setupMicrophone | leave, no michrophone!");
				outListener.recordError(ErrorCode.MSP_ERROR_FLASH_NOT_GET_MICROPHONE, "functionName:setupMicrophone");
				return false; 
			}
			
			_mic.rate = m_rate;
			_mic.setSilenceLevel(0, 1000);
			_mic.setUseEchoSuppression(true);
			_mic.setLoopBack(true); 
			_mic.setLoopBack(false); 
			_mic.addEventListener(StatusEvent.STATUS, onStatus);
			
			clog.logDBG("setupMicrophone | leave ok.rate="+ String(_mic.rate) + ".");
			
			return true;
		}

		public function startRecording():void
		{
			clog.logDBG("startRecording | enter.");
			
			if (_state != 'pre-recording' && _state != 'encoded') return;
		
			_state = 'pre-encoding';
			_voice = new ByteArray();
			_mic.addEventListener(SampleDataEvent.SAMPLE_DATA, onRecord);
			
			clog.logDBG("startRecording | leave ok.");
		}
		
		public function stopAndEncodeRecording():void
		{
			clog.logDBG("stopAndEncodeRecording | enter.");
			
			if (_state != 'pre-encoding') return;
			
			_state = 'encoding';
			_mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, onRecord);
			
			_voice.position = 0;
			
			//log('end recorded,press <key>"s" save recording');
			/*log('encode start...synchronous convert to a WAV first');
			
			convertToWAV();*/
			_state = 'encoded';
			
			clog.logDBG("stopAndEncodeRecording | leave ok.");
		}
		
		public function getWAV():ByteArray
		{
			var wavWrite:WAVWriter = new WAVWriter();
			wavWrite.numOfChannels = 1;
			wavWrite.sampleBitRate = 16;
			wavWrite.samplingRate = m_rate * 1000;
			
			var wav:ByteArray = new ByteArray();
			
			if( null == _voice || ( null != _voice &&  _voice.bytesAvailable == 0 ) )
			{
				return wav;
			}
			_voice.position = 0;
			clog.logDBG( "getWAV | _voice.bytesAvailable=" + _voice.bytesAvailable + ",rate=" + _mic.rate );
			wavWrite.processSamples(wav, _voice, m_rate * 1000, 1);
			wav.position = 0;
			
			clog.logDBG( "getWAV | wav.bytesAvailable=" + wav.bytesAvailable  );
			
			return wav;
		}
		
		private function onStatus(e:StatusEvent):void
		{
			 clog.logDBG("onStatus | " + "statusHandler: " + e);
			 outListener.recordStatus( e );
		}
		
		public function onRecord(e:SampleDataEvent):void 
		{
			clog.logDBG( "onRecord | enter, SampleData = " + e.data.length.toString() );
			
			_voice.writeBytes( e.data );
			e.data.position = 0;
			outListener.sampleDataProcess( e.data, _mic.activityLevel );
			
			e.data.position = 0;
			while(e.data.bytesAvailable > 0){
				_buffer.writeFloat(e.data.readFloat());
			}
			clog.logDBG("onRecord | leave ok.rate="+ String(_mic.rate) + ".");
		}
		
	}
	
}
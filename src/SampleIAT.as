package
{	
	import com.iflytek.define.RATE;
	import com.iflytek.events.MSCErrorEvent;
	import com.iflytek.events.MSCEvent;
	import com.iflytek.events.MSCMicStatusEvent;
	import com.iflytek.events.MSCRecordAudioEvent;
	import com.iflytek.events.MSCResultEvent;
	import com.iflytek.msc.Recognizer;
	import com.noteflight.standingwave3.filters.StandardizeFilter;
	import com.noteflight.standingwave3.formats.WaveFile;
	import com.noteflight.standingwave3.output.AudioPlayer;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.StatusEvent;
	import flash.media.SoundChannel;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import fr.kikko.lab.ShineMP3Encoder;
		
	public class SampleIAT extends Sprite
	{
		private var recog:Recognizer = null;
		private const configs:String 	= "appid=55c055cd,timeout=2000";
		private var isLogPrepared:Boolean = false;
		private var _state:String = '';
		private var recording_data:ByteArray = new ByteArray;
		
		[Embed(source="../img/btn_normal.png")]   //与下面的类关连
		private var BtnNormalClass:Class;
		
		[Embed(source="../img/btn_down.png")]   //与下面的类关连
		private var BtnDownClass:Class;
		
		private var btnStart:Sprite;
		private var btnStop:Sprite;
		private var btnSave:Sprite;
		private var btnWave:Sprite;
		private var btnMP3:Sprite;
		
		private var labState:TextField = new TextField;
		private var labInfo:TextField = new TextField;
		
		private var player:AudioPlayer;
		private var wavfile:FileReference;
		
		private var mp3Encoder:ShineMP3Encoder;
		
		//private var btnStart:Button = new Button;
		
		public function SampleIAT(stage:Stage) 
		{
			var btn:Bitmap = new BtnNormalClass() as Bitmap;
			//图片平滑
			btn.smoothing = true;
			//设置图片中心点为原点
			btn.x = -btn.width/2;
			btn.y = -btn.height/2;
			
			btnStart = new Sprite();
			btnStart.addChild(btn);
			
			btnStart.x = 100;
			btnStart.y = 100;
			
			addChild(btnStart);
			
			btn = new BtnDownClass() as Bitmap;
			//图片平滑
			btn.smoothing = true;
			//设置图片中心点为原点
			btn.x = -btn.width/2;
			btn.y = -btn.height/2;
			
			btnStop = new Sprite();
			btnStop.addChild(btn);
			
			btnStop.x = 300;
			btnStop.y = 100;
			
			addChild(btnStop);
			
			btn = new BtnDownClass() as Bitmap;
			//图片平滑
			btn.smoothing = true;
			//设置图片中心点为原点
			btn.x = -btn.width/2;
			btn.y = -btn.height/2;
			
			btnSave = new Sprite();
			btnSave.addChild(btn);
			
			btnSave.x = 300;
			btnSave.y = 300;
			
			addChild(btnSave);
			
			btn = new BtnDownClass() as Bitmap;
			//图片平滑
			btn.smoothing = true;
			//设置图片中心点为原点
			btn.x = -btn.width/2;
			btn.y = -btn.height/2;
			
			btnWave = new Sprite();
			btnWave.addChild(btn);
			
			btnWave.x = 100;
			btnWave.y = 300;
			
			addChild(btnWave);
			
			btn = new BtnDownClass() as Bitmap;
			//图片平滑
			btn.smoothing = true;
			//设置图片中心点为原点
			btn.x = -btn.width/2;
			btn.y = -btn.height/2;
			
			btnMP3 = new Sprite();
			btnMP3.addChild(btn);
			
			btnMP3.x = 300;
			btnMP3.y = 200;
			
			addChild(btnMP3);
			
			labState.text = "等待录音";
			addChild(labState);
			
			labInfo.text = "录音内容";
			labInfo.y = 50;
			addChild(labInfo);
			
			btnStart.addEventListener(MouseEvent.CLICK, onStart);
			btnStop.addEventListener(MouseEvent.CLICK, onStop);
			btnSave.addEventListener(MouseEvent.CLICK, onSave);
			btnWave.addEventListener(MouseEvent.CLICK, onWave);
			btnMP3.addEventListener(MouseEvent.CLICK, onMP3);
			
//			lblParams.width = 60;
//			lblParams.height = 30;
//			lblParams.move( 60, 110 );
//			
//			tptParams.width = 550;
//			tptParams.height = 30;
//			tptParams.move( 120, 110 );
//			
//			btnStart.width = 80;
//			btnStart.height = 30;
//			btnStart.label = "开 始";
//			btnStart.move( 60, 160 );
//			
//			btnStop.width = 80;
//			btnStop.height = 30;
//			btnStop.label = "停 止";
//			btnStop.move( 190, 160 );
//			
//			btnCancel.width = 80;
//			btnCancel.height = 30;
//			btnCancel.label = "取 消";
//			btnCancel.move( 320, 160 );
//			
//			btnRecPlayBack.width = 80;
//			btnRecPlayBack.height = 30;
//			btnRecPlayBack.label = "回 放";
//			btnRecPlayBack.move( 450, 160 );
//			
//			ttrResult.width = 400;
//			ttrResult.height = 200;
//			ttrResult.move( 100, 210 );
//			
//			lblStatus.width = 400;
//			lblStatus.move( 60, 430 );
//			
			addEventListener(Event.ADDED_TO_STAGE,onAddToStage);			
			//stage.addEventListener( KeyboardEvent.KEY_UP, commandHandler );
		}
		
//		private function onStart(e:MouseEvent){
//			spriteBg.alpha = 1;
//		}
		
		private function onAddToStage(event:Event):void 
		{
			init();
		}
		
		private function init():void
		{			
//			var tf:TextFormat = new TextFormat();
//			tf.size = 16;
//			tf.font = "宋体";
//			tf.bold = true;
//			
//			var tfContent:TextFormat = new TextFormat();
//			tfContent.size = 16;
//			tfContent.font = "宋体";
//			tfContent.bold = false;
			
//			lblParams.setStyle( "textFormat", tf );
//			tptParams.setStyle( "textFormat", tfContent );
//			btnStart.setStyle( "textFormat", tf );
//			btnStop.setStyle( "textFormat", tf );
//			btnCancel.setStyle( "textFormat", tf );
//			btnRecPlayBack.setStyle( "textFormat", tf );
//			ttrResult.setStyle( "textFormat", tfContent );
//			lblStatus.setStyle( "textFormat", tf );
//			tptParams.text = "ssm=1,sub=iat,aue=speex-wb;7,auf=audio/L16;rate=16000,ent=sms16k, rst=plain";
//			lblStatus.text = '';
			
			// iat
			recog = new Recognizer( configs, "dev.voicecloud.cn", 7 );	
			
//			btnStart.addEventListener( MouseEvent.CLICK, onStart );
//			btnStop.addEventListener( MouseEvent.CLICK, onStop );
//			btnCancel.addEventListener( MouseEvent.CLICK, onCancel );
			
			recog.addEventListener( MSCMicStatusEvent.STATUS, onMicrophoneStatus );
			recog.addEventListener( MSCRecordAudioEvent.AUDIO_ARRIVED, onRecording );
			recog.addEventListener( MSCErrorEvent.ERROR, onError );
			recog.addEventListener( MSCResultEvent.RESULT_GET, onGettingResult );
			recog.addEventListener( MSCEvent.RECOG_COMPLETED, onComplete );
			
			_state = 'init';
		}
					
		private function onStart( e:MouseEvent ):void
		{
			labState.text = "录音开始";
			
//			trace( "onStart" );
//			if( 'init' != _state ) return;			
//			
//			//ttrResult.text = '';
//			//recog.recogStart( RATE.rate16k, null, tptParams.text );
			var strGrammar:String = "builtin:grammar/../search/location.abnf?language=zh-cn";
			var grammar:ByteArray = new ByteArray();
			grammar.writeMultiByte(strGrammar, "UTF-8" );
			
			recog.recogStart( RATE.rate16k, grammar, "sub=iat, aue=speex;7, auf=audio/L16;rate=16000, ent=sms16k, rst=plain");//"ssm=1, aue=speex-wb;7, auf=audio/L16;rate=16000, ent=map, vad_speech_tail=900");
//			
//			_state = 'stop';
		}
		
		private function onStop( e:MouseEvent ):void
		{
			labState.text = "录音结束";
			
			if( 'stop' != _state ) return;			
			
			recog.recordStop();
			
			_state = 'end';
		}
		
		private function onSave( e:MouseEvent ):void
		{
			//var data_save:FileReference = new FileReference();
			//data_save.save(recording_data, "data.pcm");
			
			saveWav();
		}
		
		private function onWave( e:MouseEvent ):void
		{
			//var data_save:FileReference = new FileReference();
			//data_save.save(recording_data, "data.pcm");
			
			//saveWav();
			
			wavfile = new FileReference(); 
			wavfile.addEventListener(Event.SELECT, onSelectWave); 
			wavfile.addEventListener(Event.COMPLETE, onCompleteWave); 
			wavfile.browse([new FileFilter("wav文件","*.wav")]); 
		}
		
		private function onMP3( e:MouseEvent ):void
		{
			//var data_save:FileReference = new FileReference();
			//data_save.save(recording_data, "data.pcm");
			
			//saveWav();
			
//			wavfile = new FileReference(); 
//			wavfile.addEventListener(Event.SELECT, onSelectWave); 
//			wavfile.addEventListener(Event.COMPLETE, onCompleteWave); 
//			wavfile.browse([new FileFilter("mp3文件","*.mp3")]); 
			
			var data_save:FileReference = new FileReference();
			data_save.save(mp3Encoder.mp3Data, "data.mp3");
		}
		
		private function onSelectWave(e:Event):void
		{ 
			wavfile.load(); 
		} 
		
		
		
		private function onCompleteWave(e:Event):void
		{ 
//			player = new AudioPlayer(); 
//			var filter:StandardizeFilter = new StandardizeFilter(WaveFile.createSample(wavfile.data));
//			filter.getSample(filter.frameCount);
//
//			player.play(filter); 
			
						mp3Encoder = new ShineMP3Encoder(wavfile.data);
						mp3Encoder.addEventListener(Event.COMPLETE, mp3EncodeComplete);
						mp3Encoder.addEventListener(ProgressEvent.PROGRESS, mp3EncodeProgress);
						mp3Encoder.addEventListener(ErrorEvent.ERROR, mp3EncodeError);
						mp3Encoder.start();
		} 
		
		private function onCancel( e:MouseEvent ):void
		{
			if(  'end' != _state && 'stop' != _state ) return;
			
			recog.recogStop();
			
			_state = 'init';
		}
		
		private function onMicrophoneStatus( e:MSCMicStatusEvent ):void
		{
			trace( "status:" + e );
		}
		
		private function onRecording( e:MSCRecordAudioEvent ):void
		{
			trace("onRecording");
//			lblStatus.text = '';
//			var v:int = int( e.volume );
//			for( var i:int = 0; i < v; i++ )
//			{
//				lblStatus.text += '*';
//			}
//			
			recording_data.writeBytes(e.data);
		}
		
		private function onGettingResult( e:MSCResultEvent ):void
		{
			var strRslt:String = new String();
			strRslt = e.result.readMultiByte(e.result.bytesAvailable, "GBK")
			labInfo.text += strRslt;
			
			trace("onGettingResult " + strRslt);
			
			if (strRslt.length > 0)
			{
				trace("onGettingResult " + strRslt);
			}
		}
		
		private function onComplete( e:MSCEvent ):void
		{
			trace("onComplete");
			
//			_state = 'init';
//			isLogPrepared = true;
//			lblStatus.text = 'Press \'s\' to save log!';
		}
		
		private function onError( e:MSCErrorEvent ):void
		{
			labState.text = e.message;
			trace("onError " + e.message);
			
			recog.recogStop();
		}
		
		private function commandHandler( e:KeyboardEvent ):void
		{
//			if( isLogPrepared )
//			{
//				switch( String.fromCharCode( e.charCode ) )
//				{
//				case 's':
//				case 'S':
//					recog.logSave();
//					isLogPrepared = false;
////					lblStatus.text = '';
//					break;
//				case 'e':
//				case 'E':
//					var data_save:FileReference = new FileReference();
//					data_save.save(recording_data, "data.pcm");
//					break;
//				}
//			}
		}
		
		private function procWav(buff:ByteArray, channel:int, rate:int):ByteArray
		{
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
			wavbuf.writeInt(rate * channel * 2); //nAvgBytesPerSec
			wavbuf.writeShort(2); //nBlockAlign
			wavbuf.writeShort(16); //nBitsPerSample
			
			wavbuf.writeUTFBytes("data");
			wavbuf.writeInt(4 + 8 + 8 + 16 + 12 + buff.length - 44);
			
			wavbuf.writeBytes(buff);
			
			return wavbuf;
		}
		
		private function saveWav():void
		{
			var newbuff:ByteArray = procSample(recording_data);
			
			var wavbuf:ByteArray = procWav(newbuff, 2, 32000);//new ByteArray;
//			wavbuf.endian = Endian.LITTLE_ENDIAN;
//			
//			wavbuf.writeUTFBytes("RIFF");
//			var len:int = 4 + 8 + 8 + 16 + 12 + recording_data.length - 8;
//			wavbuf.writeInt(len);
//			wavbuf.writeUTFBytes("WAVE");
//			
//			wavbuf.writeUTFBytes("fmt ");
//			wavbuf.writeInt(16);
//			
//			wavbuf.writeShort(1); //nFormatTag
//			wavbuf.writeShort(2); //nChannels
//			wavbuf.writeInt(32000); //nSamplesPerSec
//			wavbuf.writeInt(128000); //nAvgBytesPerSec
//			wavbuf.writeShort(2); //nBlockAlign
//			wavbuf.writeShort(16); //nBitsPerSample
//			
//			wavbuf.writeUTFBytes("data");
//			wavbuf.writeInt(4 + 8 + 8 + 16 + 12 + recording_data.length - 44);
			
			//wavbuf.writeBytes(recording_data);
			
//			mp3Encoder = new ShineMP3Encoder(wavbuf);
//			mp3Encoder.addEventListener(Event.COMPLETE, mp3EncodeComplete);
//			mp3Encoder.addEventListener(ProgressEvent.PROGRESS, mp3EncodeProgress);
//			mp3Encoder.addEventListener(ErrorEvent.ERROR, mp3EncodeError);
//			mp3Encoder.start();
			
			var data_save:FileReference = new FileReference();
			data_save.save(wavbuf, "data.wav");
		}
		
		private function mp3EncodeProgress(event : ProgressEvent) : void {
		}
		
		private function mp3EncodeError(event : ErrorEvent) : void {
			trace("mp3EncodeError " + event.text);
		}
		
		private function mp3EncodeComplete(event : Event) : void {
		}
		
		private function upSample(src:ByteArray, bitsPerSample:int, srcRate:int, srcChannel:int, destRate:int, destChannel:int) : ByteArray {
			var buff:ByteArray = new ByteArray;
			
			var srclen:int = src.length;
			if (bitsPerSample == 16) {
				srclen /= 2;
			}
			
			srclen /= srcChannel;
			
			for (var i:int = 0; i < srclen; ++i) {
				
			}
			
			return buff;
		}
		
		private function procSample(src:ByteArray) : ByteArray {
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
	}
}

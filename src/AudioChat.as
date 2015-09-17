package
{
	import com.iflytek.define.RATE;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import nslm2.nets.imsdk.IMSpeech;
	import nslm2.nets.imsdk.IMSpeechOpenApi;
	
	public class AudioChat extends Sprite
	{
		[Embed(source="../img/btn_normal.png")]   //与下面的类关连
		private var BtnNormalClass:Class;
		
		[Embed(source="../img/btn_down.png")]   //与下面的类关连
		private var BtnDownClass:Class;
		
		private var btnStart:Sprite;
		private var btnStop:Sprite;
		private var btnPlay:Sprite;
		
		private var labState:TextField = new TextField;
		private var labInfo:TextField = new TextField;
		
		public function AudioChat()
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
			
			btnPlay = new Sprite();
			btnPlay.addChild(btn);
			
			btnPlay.x = 100;
			btnPlay.y = 300;
			
			addChild(btnPlay);
			
			labState.text = "等待录音";
			addChild(labState);
			
			labInfo.text = "录音内容";
			labInfo.y = 50;
			addChild(labInfo);
			
			btnStart.addEventListener(MouseEvent.CLICK, onStart);
			btnStop.addEventListener(MouseEvent.CLICK, onStop);
			btnPlay.addEventListener(MouseEvent.CLICK, onPlay);
		}
		
		private function onStart( e:MouseEvent ):void
		{
			labState.text = "录音开始";
			
			IMSpeechOpenApi.startRecord(onComplete);
			
//			//			trace( "onStart" );
//			//			if( 'init' != _state ) return;			
//			//			
//			//			//ttrResult.text = '';
//			//			//recog.recogStart( RATE.rate16k, null, tptParams.text );
//			var strGrammar:String = "builtin:grammar/../search/location.abnf?language=zh-cn";
//			var grammar:ByteArray = new ByteArray();
//			grammar.writeMultiByte(strGrammar, "UTF-8" );
//			
//			recog.recogStart( RATE.rate16k, grammar, "sub=iat, aue=speex;7, auf=audio/L16;rate=16000, ent=sms16k, rst=plain");//"ssm=1, aue=speex-wb;7, auf=audio/L16;rate=16000, ent=map, vad_speech_tail=900");
			//			
			//			_state = 'stop';
		}
		
		private function onStop( e:MouseEvent ):void
		{
			labState.text = "录音结束";
			
			IMSpeechOpenApi.stopRecord();
			
//			if( 'stop' != _state ) return;			
//			
//			recog.recordStop();
//			
//			_state = 'end';
		}
		
		private function onPlay( e:MouseEvent ):void
		{
			//labState.text = "录音结束";
			
			IMSpeechOpenApi.playSound('group2/M00/03/02/CgNGCVXSr7KAFDdJAAAv9GuhhwI217.mp3');
			
			var data_save:FileReference = new FileReference();
			//data_save.save(IMSpeechOpenApi.getWAVData(), "data.wav");
			data_save.save(IMSpeechOpenApi.getAMRData(), "data8.amr");
			
			//			if( 'stop' != _state ) return;			
			//			
			//			recog.recordStop();
			//			
			//			_state = 'end';
		}
		
		private function onComplete(state:int, buff:ByteArray, result:String, url:String):void
		{
			if (state == IMSpeech.STATE_COMPLETE) {
				trace("imsdk result is " + result + " url is " + url);
			}
		}
	}
}
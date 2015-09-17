package  com.iflytek.events
{
	import flash.events.Event;
	
	public class MSCEvent extends Event
	{
		//公共常量
		public static const RECOG_COMPLETED:String = "recogCompleted";
		public static const RECORD_STOPPED:String = "recordStopped";
		public static const SYNTH_COMPLETED:String = "synthCompleted";
		public static const SYNTH_READY_TO_PLAY:String = "synthReadyToPlay";
		public static const SYNTH_PLAY_WAITDATA:String = "synthPlayWaitData";
		public static const SYNTH_PLAY_COMPLETED:String = "synthPlayCompleted"; 
		public static const EVALU_COMPLETED:String = "evaluCompleted";

		public function MSCEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
		}

	}
	
}

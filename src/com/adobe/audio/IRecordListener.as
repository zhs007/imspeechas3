package  com.adobe.audio
{
	import flash.utils.ByteArray;
	import flash.events.StatusEvent;
	public interface IRecordListener 
	{
		function recordStatus( e:StatusEvent ):void;
		function sampleDataProcess( sampleData:ByteArray, volume:int ):void;
		function recordError(id:int, text:String):void;
	}
	
}

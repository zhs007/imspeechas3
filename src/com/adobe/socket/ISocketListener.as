package  com.adobe.socket
{
	import flash.utils.ByteArray;
	import flash.events.SecurityErrorEvent;
	import flash.events.IOErrorEvent;
	public interface ISocketListener 
	{
		function notifyConnectSuccess():void;
		function getIOError( socketError:IOErrorEvent ):void;
		function getSecurityError( socketError:SecurityErrorEvent ):void;
		function getResponseMsg( msg:ByteArray ):void;
	}
	
}

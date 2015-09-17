package com.adobe.socket {
	import com.adobe.socket.ISocketListener;
	import com.iflytek.msc.MSCLog;
	
	import flash.display.Sprite;
  	import flash.events.*;
  	import flash.net.Socket;
	import flash.system.Security;
  	import flash.utils.getQualifiedClassName;
  	import flash.utils.ByteArray;
	
	public class msc_socket {
		 public  var __connected:Boolean = false;	

		 private var socket:Socket = null;
		 private var outListener:ISocketListener;
		 private var host:String = new String();	
		 private var port:int = 80;
		 private var clog:MSCLog = null;
		
		public function msc_socket( listener:ISocketListener, theclog:MSCLog ) {
			// constructor code
			outListener = listener;
			clog = theclog;
			
			clog.logDBG("msc_socket| enter.");
			
			socket = new Socket();

             // Add an event listener to be notified when the connection is made
			socket.addEventListener( Event.CONNECT, onConnect );
			
			// Add an event listener to be notified when the closed is made
			socket.addEventListener( Event.CLOSE, onClose );

			// Add an event listener to be notified when IO error
			socket.addEventListener( IOErrorEvent.IO_ERROR,onIoError );
			
			// Add an event listener to be notified when safe policy error
			socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR,onSecurity );

            // Listen for when data is received from the socket server
			socket.addEventListener( ProgressEvent.SOCKET_DATA, onSocketData );
			
			clog.logDBG("msc_socket | leave ok.");
		}
		
		// 连接
		public function connectServer( serverURL:String, serverPort:int=80 ):void 
		{
			clog.logDBG("connectServer| enter, serverURL = " + serverURL
						+ ", serverPort = " + serverPort);
			
			if( !socket.connected )
			{
				host = serverURL;
				port = serverPort;
				socket.connect( serverURL, serverPort );
			}
			
			clog.logDBG("connectServer| leave ok.");
		}
		
		private function onConnect( e:Event ):void 
		{
			 clog.logDBG("onConnect| enter, The socket is now connected…");
				
			outListener.notifyConnectSuccess();
			__connected = socket.connected;
			
			clog.logDBG("onConnect| leave ok.");
    	}
		
		//IO错误  
       private function onIoError(e:IOErrorEvent):void 
       {  
			outListener.getIOError( e );
        }  

         //安全策略错误  
       private function onSecurity(e:SecurityErrorEvent):void 
       {  
			outListener.getSecurityError( e ); 
        }  
			
		// 关闭服务器
		private function onClose( e:Event ):void 
		{
			clog.logDBG("onClose| The socket is now closed…");
			__connected = false;
		}
			
		public function disConnect():void
		{
			socket.close();
			__connected = false;
		}
		
		public function sendData( presendData:ByteArray ):void 
		{  
			clog.logDBG("sendData| enter, sendData.length = " + String(presendData.length));
   			
			if( !socket.connected )
			{
				socket.connect( host, port );
				
				if(!socket.connected)
				{
					clog.logDBG("sendData| leave ok, the socket is not connect");
					return;
				}
			}
			presendData.position = 0;
			socket.writeBytes( presendData );
   			socket.flush();
  
  			clog.logDBG("sendData| leave ok.");
   		}
		
		private function onSocketData( eventrogressEvent:Object ):void {
 			clog.logDBG("onSocketData| enter, Socket received " + socket.bytesAvailable + "byte(s) of data:");
			clog.logDBG(String(responseMsg));
			var responseMsg:ByteArray = new ByteArray();
			socket.readBytes( responseMsg );
			outListener.getResponseMsg( responseMsg );
			
			clog.logDBG("onSocketData| leave ok.");
   		 }
		 
		/*
		 * ************************************************************************************
		 * SETTER/GETTERS
		 * ************************************************************************************
		 */
		public function get connected():Boolean
		{
			return __connected;
		}

	}
	
}

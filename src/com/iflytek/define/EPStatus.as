package  com.iflytek.define 
{
	public final class EPStatus 
	{
		/**
 		 * The enumeration MSPepState contains the current endpointer state
 		 *  MSP_EP_LOOKING_FOR_SPEECH	- Have not yet found the beginning of speech
 		 *  MSP_EP_IN_SPEECH			- Have found the beginning, but not the end of speech
 		 *  MSP_EP_AFTER_SPEECH			- Have found the beginning and end of speech
 		 *  MSP_EP_TIMEOUT				- Have not found any audio till timeout
 		 *  MSP_EP_ERROR				- The endpointer has encountered a serious error
 		 *  MSP_EP_MAX_SPEECH			- Have arrive the max size of speech
 		*/
		public static const MSP_EP_LOOKING_FOR_SPEECH:int = 0;  
		public static const MSP_EP_IN_SPEECH:int 		  = 1;
		public static const MSP_EP_AFTER_SPEECH:int 	  = 3;
		public static const MSP_EP_TIMEOUT:int 			  = 4;
		public static const MSP_EP_ERROR:int 			  = 5;
		public static const MSP_EP_MAX_SPEECH:int 		  = 6;
		public static const MSP_EP_IDLE:int 			  = 7;
	}
	
}

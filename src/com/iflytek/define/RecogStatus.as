package com.iflytek.define 
{
	
	public final class RecogStatus 
	{
		/**
		 *  The enumeration MSPRecognizerStatus contains the recognition status
 		 *  MSP_REC_STATUS_SUCCESS				- successful recognition with partial results
 		 *  MSP_REC_STATUS_NO_MATCH				- recognition rejected
 		 *  MSP_REC_STATUS_INCOMPLETE			- recognizer needs more time to compute results
 		 *  MSP_REC_STATUS_NON_SPEECH_DETECTED	- discard status, no more in use
 		 *  MSP_REC_STATUS_SPEECH_DETECTED		- recognizer has detected audio, this is delayed status
 		 *  MSP_REC_STATUS_COMPLETE				- recognizer has return all result
 		 *  MSP_REC_STATUS_MAX_CPU_TIME			- CPU time limit exceeded
 		 *  MSP_REC_STATUS_MAX_SPEECH			- maximum speech length exceeded, partial results may be returned
 		 *  MSP_REC_STATUS_STOPPED				- recognition was stopped
 		 *  MSP_REC_STATUS_REJECTED				- recognizer rejected due to low confidence
 		 *  MSP_REC_STATUS_NO_SPEECH_FOUND		- recognizer still found no audio, this is delayed status
 		 */
		public static const MSP_REC_STATUS_SUCCESS:int 					= 0;
		public static const MSP_REC_STATUS_NO_MATCH:int 				= 1;
		public static const MSP_REC_STATUS_INCOMPLETE:int 				= 2;
		public static const MSP_REC_STATUS_NON_SPEECH_DETECTED:int 		= 3;
		public static const MSP_REC_STATUS_SPEECH_DETECTED:int 			= 4;
		public static const MSP_REC_STATUS_COMPLETE:int 				= 5;
		public static const MSP_REC_STATUS_MAX_CPU_TIME:int 			= 6;
		public static const MSP_REC_STATUS_MAX_SPEECH:int 				= 7;
		public static const MSP_REC_STATUS_STOPPED:int 				    = 8;
		public static const MSP_REC_STATUS_REJECTED:int 				= 9;
		public static const MSP_REC_STATUS_NO_SPEECH_FOUND:int          = 10;
		//public static const MSP_REC_STATUS_FAILURE:int 					= 11;
	}
	
}

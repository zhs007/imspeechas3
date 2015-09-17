package com.iflytek.define  
{
	
	public final class MessageType 
	{
		// 消息类型, 数值必须要与MSC底层库中的msc_define.h保持一致
	    public static const Msg_Type_Unknown:int = 0;
	    public static const Msg_Session_Begin:int = 1;
	    public static const Msg_Back_To_Result:int = 2;
	    public static const Msg_QISR_Upload_Data:int = 3;

	    public static const Msg_MspLogin:int = 4;
		public static const Msg_MSPDownload:int = 5;
		public static const Msg_MSPGetResult:int = 6;
		public static const Msg_MspLogout:int = 7;

	}
	
}

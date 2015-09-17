package com.iflytek.define   
{
	
	public final class ErrorCode 
	{

		public static const MSP_SUCCESS:int								= 0;
		public static const MSP_ERROR_FAIL:int							= -1;
		public static const MSP_ERROR_EXCEPTION:int						= -2;

		/* General errors 10100(0x2774) */
		public static const MSP_ERROR_GENERAL:int						= 10100; 	/* 0x2774 */
		public static const MSP_ERROR_OUT_OF_MEMORY:int					= 10101; 	/* 0x2775 */
		public static const MSP_ERROR_FILE_NOT_FOUND:int				= 10102; 	/* 0x2776 */
		public static const MSP_ERROR_NOT_SUPPORT:int					= 10103; 	/* 0x2777 */
		public static const MSP_ERROR_NOT_IMPLEMENT:int					= 10104; 	/* 0x2778 */
		public static const MSP_ERROR_ACCESS:int						= 10105; 	/* 0x2779 */
		public static const MSP_ERROR_INVALID_PARA:int					= 10106; 	/* 0x277A */
		public static const MSP_ERROR_INVALID_PARA_VALUE:int			= 10107; 	/* 0x277B */
		public static const MSP_ERROR_INVALID_HANDLE:int				= 10108; 	/* 0x277C */
		public static const MSP_ERROR_INVALID_DATA:int					= 10109; 	/* 0x277D */
		public static const MSP_ERROR_NO_LICENSE:int					= 10110; 	/* 0x277E */
		public static const MSP_ERROR_NOT_INIT:int						= 10111; 	/* 0x277F */
		public static const MSP_ERROR_NULL_HANDLE:int					= 10112; 	/* 0x2780 */
		public static const MSP_ERROR_OVERFLOW:int						= 10113; 	/* 0x2781 */
		public static const MSP_ERROR_TIME_OUT:int						= 10114; 	/* 0x2782 */
		public static const MSP_ERROR_OPEN_FILE:int						= 10115; 	/* 0x2783 */
		public static const MSP_ERROR_NOT_FOUND:int						= 10116; 	/* 0x2784 */
		public static const MSP_ERROR_NO_ENOUGH_BUFFER:int				= 10117; 	/* 0x2785 */
		public static const MSP_ERROR_NO_DATA:int						= 10118; 	/* 0x2786 */
		public static const MSP_ERROR_NO_MORE_DATA:int					= 10119; 	/* 0x2787 */
		public static const MSP_ERROR_SKIPPED:int						= 10120; 	/* 0x2788 */
		public static const MSP_ERROR_ALREADY_EXIST:int					= 10121; 	/* 0x2789 */
		public static const MSP_ERROR_LOAD_MODULE:int					= 10122; 	/* 0x278A */
		public static const MSP_ERROR_BUSY:int							= 10123; 	/* 0x278B */
		public static const MSP_ERROR_INVALID_CONFIG:int				= 10124; 	/* 0x278C */
		public static const MSP_ERROR_VERSION_CHECK:int                 = 10125; 	/* 0x278D */
		public static const MSP_ERROR_CANCELED:int						= 10126; 	/* 0x278E */
		public static const MSP_ERROR_INVALID_MEDIA_TYPE:int			= 10127; 	/* 0x278F */
		public static const MSP_ERROR_CONFIG_INITIALIZE:int				= 10128; 	/* 0x2790 */
		public static const MSP_ERROR_CREATE_HANDLE:int					= 10129; 	/* 0x2791 */
		public static const MSP_ERROR_CODING_LIB_NOT_LOAD:int			= 10130; 	/* 0x2792 */

		/* Error codes of network 10200(0x27D8)*/
		public static const MSP_ERROR_NET_GENERAL:int					= 10200; 	/* 0x27D8 */
		public static const MSP_ERROR_NET_OPENSOCK:int         			= 10201; 	/* 0x27D9 */   /* Open socket */
		public static const MSP_ERROR_NET_CONNECTSOCK:int      			= 10202; 	/* 0x27DA */   /* Connect socket */
		public static const MSP_ERROR_NET_ACCEPTSOCK:int       			= 10203; 	/* 0x27DB */   /* Accept socket */
		public static const MSP_ERROR_NET_SENDSOCK:int         			= 10204; 	/* 0x27DC */   /* Send socket data */
		public static const MSP_ERROR_NET_RECVSOCK:int         			= 10205; 	/* 0x27DD */   /* Recv socket data */
		public static const MSP_ERROR_NET_INVALIDSOCK:int      			= 10206; 	/* 0x27DE */   /* Invalid socket handle */
		public static const MSP_ERROR_NET_BADADDRESS:int       			= 10207; 	/* 0x27EF */   /* Bad network address */
		public static const MSP_ERROR_NET_BINDSEQUENCE:int     			= 10208; 	/* 0x27E0 */   /* Bind after listen/connect */
		public static const MSP_ERROR_NET_NOTOPENSOCK:int      			= 10209; 	/* 0x27E1 */   /* Socket is not opened */
		public static const MSP_ERROR_NET_NOTBIND:int         			= 10210; 	/* 0x27E2 */   /* Socket is not bind to an address */
		public static const MSP_ERROR_NET_NOTLISTEN:int        			= 10211; 	/* 0x27E3 */   /* Socket is not listening */
		public static const MSP_ERROR_NET_CONNECTCLOSE:int     			= 10212; 	/* 0x27E4 */   /* The other side of connection is closed */
		public static const MSP_ERROR_NET_NOTDGRAMSOCK:int     			= 10213; 	/* 0x27E5 */   /* The socket is not datagram type */
		public static const MSP_ERROR_NET_DNS:int     					= 10214; 	/* 0x27E6 */   /* domain name is invalid or dns server does not function well */

		/* Error codes of mssp message 10300(0x283C) */
		public static const MSP_ERROR_MSG_GENERAL:int					= 10300; 	/* 0x283C */
		public static const MSP_ERROR_MSG_PARSE_ERROR:int				= 10301; 	/* 0x283D */
		public static const MSP_ERROR_MSG_BUILD_ERROR:int				= 10302; 	/* 0x283E */
		public static const MSP_ERROR_MSG_PARAM_ERROR:int				= 10303; 	/* 0x283F */
		public static const MSP_ERROR_MSG_CONTENT_EMPTY:int				= 10304; 	/* 0x2840 */
		public static const MSP_ERROR_MSG_INVALID_CONTENT_TYPE:int		= 10305; 	/* 0x2841 */
		public static const MSP_ERROR_MSG_INVALID_CONTENT_LENGTH:int	= 10306; 	/* 0x2842 */
		public static const MSP_ERROR_MSG_INVALID_CONTENT_ENCODE:int	= 10307; 	/* 0x2843 */
		public static const MSP_ERROR_MSG_INVALID_KEY:int				= 10308; 	/* 0x2844 */
		public static const MSP_ERROR_MSG_KEY_EMPTY:int					= 10309; 	/* 0x2845 */
		public static const MSP_ERROR_MSG_SESSION_ID_EMPTY:int			= 10310; 	/* 0x2846 */
		public static const MSP_ERROR_MSG_LOGIN_ID_EMPTY:int			= 10311; 	/* 0x2847 */
		public static const MSP_ERROR_MSG_SYNC_ID_EMPTY:int				= 10312; 	/* 0x2848 */
		public static const MSP_ERROR_MSG_APP_ID_EMPTY:int				= 10313; 	/* 0x2849 */
		public static const MSP_ERROR_MSG_EXTERN_ID_EMPTY:int			= 10314; 	/* 0x284A */
		public static const MSP_ERROR_MSG_INVALID_CMD:int				= 10315; 	/* 0x284B */
		public static const MSP_ERROR_MSG_INVALID_SUBJECT:int			= 10316; 	/* 0x284C */
		public static const MSP_ERROR_MSG_INVALID_VERSION:int			= 10317; 	/* 0x284D */
		public static const MSP_ERROR_MSG_NO_CMD:int					= 10318; 	/* 0x284E */
		public static const MSP_ERROR_MSG_NO_SUBJECT:int				= 10319; 	/* 0x284F */
		public static const MSP_ERROR_MSG_NO_VERSION:int				= 10320; 	/* 0x2850 */
		public static const MSP_ERROR_MSG_MSSP_EMPTY:int				= 10321; 	/* 0x2851 */
		public static const MSP_ERROR_MSG_NEW_RESPONSE:int				= 10322; 	/* 0x2852 */
		public static const MSP_ERROR_MSG_NEW_CONTENT:int				= 10323; 	/* 0x2853 */
		public static const MSP_ERROR_MSG_INVALID_SESSION_ID:int		= 10324; 	/* 0x2854 */

		/* Error codes of DataBase 10400(0x28A0)*/
		public static const MSP_ERROR_DB_GENERAL:int					= 10400; 	/* 0x28A0 */
		public static const MSP_ERROR_DB_EXCEPTION:int					= 10401; 	/* 0x28A1 */
		public static const MSP_ERROR_DB_NO_RESULT:int					= 10402; 	/* 0x28A2 */
		public static const MSP_ERROR_DB_INVALID_USER:int				= 10403; 	/* 0x28A3 */
		public static const MSP_ERROR_DB_INVALID_PWD:int				= 10404; 	/* 0x28A4 */
		public static const MSP_ERROR_DB_CONNECT:int					= 10405; 	/* 0x28A5 */
		public static const MSP_ERROR_DB_INVALID_SQL:int				= 10406; 	/* 0x28A6 */
		public static const MSP_ERROR_DB_INVALID_APPID:int				= 10407;	/* 0x28A7 */

		/* Error codes of Resource 10500(0x2904)*/
		public static const MSP_ERROR_RES_GENERAL:int					= 10500; 	/* 0x2904 */
		public static const MSP_ERROR_RES_LOAD:int          			= 10501; 	/* 0x2905 */   /* Load resource */
		public static const MSP_ERROR_RES_FREE:int          			= 10502; 	/* 0x2906 */   /* Free resource */
		public static const MSP_ERROR_RES_MISSING:int       			= 10503; 	/* 0x2907 */   /* Resource File Missing */
		public static const MSP_ERROR_RES_INVALID_NAME:int  			= 10504; 	/* 0x2908 */   /* Invalid resource file name */
		public static const MSP_ERROR_RES_INVALID_ID:int    			= 10505; 	/* 0x2909 */   /* Invalid resource ID */
		public static const MSP_ERROR_RES_INVALID_IMG:int   			= 10506; 	/* 0x290A */   /* Invalid resource image pointer */
		public static const MSP_ERROR_RES_WRITE:int         			= 10507; 	/* 0x290B */   /* Write read-only resource */
		public static const MSP_ERROR_RES_LEAK:int          			= 10508; 	/* 0x290C */   /* Resource leak out */
		public static const MSP_ERROR_RES_HEAD:int          			= 10509; 	/* 0x290D */   /* Resource head currupt */
		public static const MSP_ERROR_RES_DATA:int          			= 10510; 	/* 0x290E */   /* Resource data currupt */
		public static const MSP_ERROR_RES_SKIP:int          			= 10511; 	/* 0x290F */   /* Resource file skipped */

		/* Error codes of TTS 10600(0x2968)*/
		public static const MSP_ERROR_TTS_GENERAL:int					= 10600; 	/* 0x2968 */
		public static const MSP_ERROR_TTS_TEXTEND:int          			= 10601; 	/* 0x2969 */  /* Meet text end */
		public static const MSP_ERROR_TTS_TEXT_EMPTY:int				= 10602; 	/* 0x296A */  /* no synth text */

		/* Error codes of Recognizer 10700(0x29CC) */
		public static const MSP_ERROR_REC_GENERAL:int					= 10700; 	/* 0x29CC */
		public static const MSP_ERROR_REC_INACTIVE:int					= 10701; 	/* 0x29CD */
		public static const MSP_ERROR_REC_GRAMMAR_ERROR:int				= 10702; 	/* 0x29CE */
		public static const MSP_ERROR_REC_NO_ACTIVE_GRAMMARS:int		= 10703; 	/* 0x29CF */
		public static const MSP_ERROR_REC_DUPLICATE_GRAMMAR:int			= 10704; 	/* 0x29D0 */
		public static const MSP_ERROR_REC_INVALID_MEDIA_TYPE:int		= 10705; 	/* 0x29D1 */
		public static const MSP_ERROR_REC_INVALID_LANGUAGE:int			= 10706; 	/* 0x29D2 */
		public static const MSP_ERROR_REC_URI_NOT_FOUND:int				= 10707; 	/* 0x29D3 */
		public static const MSP_ERROR_REC_URI_TIMEOUT:int				= 10708; 	/* 0x29D4 */
		public static const MSP_ERROR_REC_URI_FETCH_ERROR:int			= 10709; 	/* 0x29D5 */

		/* Error codes of Speech Detector 10800(0x2A30) */
		public static const MSP_ERROR_EP_GENERAL:int					= 10800; 	/* 0x2A30 */
		public static const MSP_ERROR_EP_NO_SESSION_NAME:int            = 10801; 	/* 0x2A31 */
		public static const MSP_ERROR_EP_INACTIVE:int                   = 10802; 	/* 0x2A32 */
		public static const MSP_ERROR_EP_INITIALIZED:int                = 10803; 	/* 0x2A33 */

		/* Error codes of TUV */  
		public static const MSP_ERROR_TUV_GENERAL:int					= 10900; 	/* 0x2A94 */
		public static const MSP_ERROR_TUV_GETHIDPARAM:int        		= 10901; 	/* 0x2A95 */   /* Get Busin Param huanid*/
		public static const MSP_ERROR_TUV_TOKEN:int      				= 10902; 	/* 0x2A96 */   /* Get Token */
		public static const MSP_ERROR_TUV_CFGFILE:int					= 10903; 	/* 0x2A97 */   /* Open cfg file */ 
		public static const MSP_ERROR_TUV_RECV_CONTENT:int              = 10904; 	/* 0x2A98 */   /* received content is error */
		public static const MSP_ERROR_TUV_VERFAIL:int      			    = 10905; 	/* 0x2A99 */   /* Verify failure */

		/* Error codes of IMTV */
		public static const MSP_ERROR_LOGIN_SUCCESS:int					= 11000; 	/* 0x2AF8 */   /* 成功 */
		public static const MSP_ERROR_LOGIN_NO_LICENSE:int        	    = 11001; 	/* 0x2AF9 */   /* 试用次数结束，用户需要付费 */
		public static const MSP_ERROR_LOGIN_SESSIONID_INVALID:int		= 11002; 	/* 0x2AFA */   /* SessionId失效，需要重新登录通行证 */ 
		public static const MSP_ERROR_LOGIN_SESSIONID_ERROR:int			= 11003; 	/* 0x2AFB */   /* SessionId为空，或者非法 */
		public static const MSP_ERROR_LOGIN_UNLOGIN:int		  			= 11004; 	/* 0x2AFC */   /* 未登录通行证 */
		public static const MSP_ERROR_LOGIN_INVALID_USER:int	  		= 11005; 	/* 0x2AFD */   /* 用户ID无效 */
		public static const MSP_ERROR_LOGIN_INVALID_PWD:int		  		= 11006; 	/* 0x2AFE */   /* 用户密码无效 */
		public static const MSP_ERROR_LOGIN_SYSTEM_ERROR:int            = 11099; 	/* 0x2B5B */   /* 系统错误 */

		/* Error codes of HCR */
		public static const MSP_ERROR_HCR_GENERAL:int					= 11100;
		public static const MSP_ERROR_HCR_RESOURCE_NOT_EXIST:int		= 11101;
		public static const MSP_ERROR_HCR_CREATE:int					= 11102;
		public static const MSP_ERROR_HCR_DESTROY:int					= 11103;
		public static const MSP_ERROR_HCR_START:int						= 11104;
		public static const MSP_ERROR_HCR_APPEND_STROKES:int			= 11105;
		public static const MSP_ERROR_HCR_GET_RESULT:int				= 11106;
		public static const MSP_ERROR_HCR_SET_PREDICT_DATA:int			= 11107;
		public static const MSP_ERROR_HCR_GET_PREDICT_RESULT:int		= 11108;
		
		/* Error codes of HTTP */
		public static const MSP_ERROR_HTTP_BASE:int						= 12000;	/* 0x2EE0 */
		
		/* Error codes of flash */
		public static const MSP_ERROR_FLASH_BASE:int					= 120100;    /* 0x1D524 */    /* flash错误基码 */
		public static const MSP_ERROR_FLASH_LOAD_LIB:int				= 120101;    /* 0x1D525 */    /* 加载swc库文件失败 */
		public static const MSP_ERROR_FLASH_LIB:int						= 120102;    /* 0x1D526 */    /* swc库内部有错误 */
		public static const MSP_ERROR_FLASH_NOT_GET_MICROPHONE:int		= 120103;	/* 0x1D527 */    /* 没有获取到麦克风 */
		public static const MSP_ERROR_FLASH_INVALID_SEQUENCE:int		= 120104;    /* 0x1D528 */    /* 函数调用顺序错误 */
		public static const MSP_ERROR_FLASH_SOCKET_IO_ERROR:int			= 120105;    /* 0x1D529 */    /* 通信IO错误 */
		public static const MSP_ERROR_FLASH_SOCKET_SECURITY_ERROR:int	= 120106;    /* 0x1D52A */    /* 通信沙箱安全错误 */
		public static const MSP_ERROR_FLASH_PLAYER_NODATA:int			= 120107;    /* 0x1D52B */    /* 没有足够的音频来播放 */
		public static const MSP_ERROR_FLASH_PLAYER_EXIST:int			= 120108;	/* 0x1D52C */     /* 播放实例已经存在 */
		public static const MSP_ERROR_MESSAGE_NOT_COMPLETE:int			= 120109;	/* 0x1D52D */     /* 播放实例已经存在 */
		
	}
	
}

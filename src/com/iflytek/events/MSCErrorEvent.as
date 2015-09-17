package  com.iflytek.events
{
	import flash.events.ErrorEvent;
	
	public class MSCErrorEvent extends ErrorEvent
	{
		//公共常量
		public static const ERROR:String = "error";
		
		private var __message:String = "";

		public function MSCErrorEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, text:String = "", id:int = 0) 
		{
			var addInfo:String = infoToErrorID(id);
			if("" == addInfo)
			{
				//__message = text;
				__message = "Error #" + String(id) + "。";
			}
			else
			{
				__message = "Error #" + String(id) + ":" + addInfo + "。";
			}
			
			super(type, bubbles, cancelable, __message, id);
		}
		
		/*
		 * ***************************************************************************
		 * SETTING/GETTING
		 * ***************************************************************************
		 */
		 /*
		  * Retruns the error Info
		  */
		 public function get message():String
		 {
			  return __message;
		 }
		
		/*
		 * ***************************************************************************
		 * PRIVATE METHODS
		 * ****************************************************************************
		 */
		private function infoToErrorID(id:int):String
		{
			var str:String = new String();
			
			switch(id)
			{
				case 0:
					str = "函数执行成功";
					break;
				case -1:
					str = "失败";
					break;
				case -2:
					str = "异常";
					break;
				case 10100:
					str = "基码";
					break;
				case 10101:
					str = "内存越界";
					break;
				case 10102:
					str = "文件没有发现";
					break;
				case 10103:
					str = "不支持";
					break;
				case 10104:
					str = "没有发现";
					break;
				case 10105:
					str = "没有权限";
					break;
				case 10106:
					str = "无效的参数";
					break;
				case 10107:
					str = "无效的参数值";
					break;
				case 10108:
					str = "无效的句柄";
					break;
				case 10109:
					str = "无效的数据";
					break;
				case 10110:
					str = "没有授权许可";
					break;
				case 10111:
					str = "没有初始化";
					break;
				case 10112:
					str = "空句柄";
					break;
				case 10113:
					str = "溢出";
					break;
				case 10114:
					str = "超时";
					break;
				case 10115:
					str = "打开文件出错";
					break;
				case 10116:
					str = "没有发现";
					break;
				case 10117:
					str = "没有足够的内存";
					break;
				case 10118:
					str = "没有数据";
					break;
				case 10119:
					str = "没有更多的数据";
					break;
				case 10120:
					str = "跳过";
					break;
				case 10121:
					str = "已经存在";
					break;
				case 10122:
					str = "加载模块失败";
					break;
				case 10123:
					str = "忙碌";
					break;
				case 10124:
					str = "无效的配置项";
					break;
				case 10125:
					str = "版本错误";
					break;
				case 10126:
					str = "取消";
					break;
				case 10127:
					str = "无效的媒体类型";
					break;
				case 10128:
					str = "初始化Config实例";
					break;
				case 10129:
					str = "建立句柄";
					break;
				case 10130:
					str = "编解码库未加载";
					break;
					
				case 10200:
					str = "网络一般错误";
					break;
				case 10201:
					str = "打开套接字";
					break;
				case 10202:
					str = "套接字连接";
					break;
				case 10203:
					str = "套接字接收";
					break;
				case 10204:
					str = "发送";
					break;
				case 10205:
					str = "接收";
					break;
				case 10206:
					str = "无效的套接字";
					break;
				case 10207:
					str = "无效的地址";
					break;
				case 10208:
					str = "绑定次序";
					break;
				case 10209:
					str = "套接字没有打开";
					break;
				case 10210:
					str = "没有绑定";
					break;
				case 10211:
					str = "没有监听";
					break;
				case 10212:
					str = "连接关闭";
					break;
				case 10213:
					str = "非数据报套接字";
					break;
				case 10214:
					str = "DNS解析错误";
					break;
					
				case 10300:
					str = "消息一般错误";
					break;
				case 10301:
					str = "解析";
					break;
				case 10302:
					str = "构建";
					break;
				case 10303:
					str = "参数出错";
					break;
				case 10304:
					str = "Content为空";
					break;
				case 10305:
					str = "Content类型无效";
					break;
				case 10306:
					str = "Content长度无效";
					break;
				case 10307:
					str = "Content编码无效";
					break;
				case 10308:
					str = "Key无效";
					break;
				case 10309:
					str = "Key为空";
					break;
				case 10310:
					str = "会话ID为空";
					break;
				case 10311:
					str = "登陆ID为空";
					break;
				case 10312:
					str = "同步ID为空";
					break;
				case 10313:
					str = "应用ID为空";
					break;
				case 10314:
					str = "扩展ID为空";
					break;
				case 10315:
					str = "无效的命令";
					break;
				case 10316:
					str = "无效的主题";
					break;
				case 10317:
					str = "无效的版本";
					break;
				case 10318:
					str = "没有命令";
					break;
				case 10319:
					str = "没有主题";
					break;
				case 10320:
					str = "没有版本号";
					break;
				case 10321:
					str = "消息为空";
					break;
				case 10322:
					str = "新建响应消息失败";
					break;
				case 10323:
					str = "新建Content失败";
					break;
				case 10324:
					str = "无效的会话ID";
					break;
					
				case 10400:
					str = "数据库一般错误";
					break;
				case 10401:
					str = "异常";
					break;
				case 10402:
					str = "没有结果";
					break;
				case 10403:
					str = "无效的用户";
					break;
				case 10404:
					str = "无效的密码";
					break;
				case 10405:
					str = "连接出错";
					break;
				case 10406:
					str = "无效的SQL";
					break;
					
				case 10500:
					str = "资源一般错误";
					break;
				case 10501:
					str = "没有加载";
					break;
				case 10502:
					str = "空闲";
					break;
				case 10503:
					str = "缺失";
					break;
				case 10504:
					str = "无效的名称";
					break;
				case 10505:
					str = "无效的ID";
					break;
				case 10506:
					str = "无效的映像";
					break;
				case 10507:
					str = "写操作";
					break;
				case 10508:
					str = "泄露";
					break;
				case 10509:
					str = "资源头部错误";
					break;
				case 10510:
					str = "数据出错";
					break;
				case 10511:
					str = "跳过";
					break;
					
				case 10600:
					str = "合成一般错误";
					break;
				case 10601:
					str = "文本结束";
					break;
				case 10602:
					str = "文本为空";
					break;
					
				case 10700:
					str = "一般错误";
					break;
				case 10701:
					str = "处于不活跃状态";
					break;
				case 10702:
					str = "语法错误";
					break;
				case 10703:
					str = "没有活跃的语法";
					break;
				case 10704:
					str = "语法重复";
					break;
				case 10705:
					str = "无效的媒体类型";
					break;
				case 10706:
					str = "无效的语言";
					break;
				case 10707:
					str = "没有对应的URI";
					break;
				case 10708:
					str = "获取URI内容超时";
					break;
				case 10709:
					str = "获取URI内容时出错";
					break;
					
				case 10800:
					str = "（EP）一般错误";
					break;
				case 10801:
					str = "（EP）连接没有名字";
					break;
				case 10802:
					str = "（EP）不活跃";
					break;
				case 10803:
					str = "（EP）初始化出错";
					break;
					
				case 11000:
					str = "登陆成功";
					break;
				case 11001:
					str = "无授权";
					break;
				case 11002:
					str = "无效的SessionID";
					break;
				case 11003:
					str = "错误的SessionID";
					break;
				case 11004:
					str = "未登陆";
					break;
				case 11005:
					str = "无效的用户";
					break;
				case 11006:
					str = "无效的密码";
					break;
				case 11099:
					str = "系统错误";
					break;
					
				case 12000:
					str = "HTTP错误基码";
					break;
					 
				// flash平台自定义错误码
				case 120100:
					str = "自定义错误码基码";
					break;
				case 120101:
					str = "加载库失败";
					break;
				case 120102:
					str = "库本身有问题";
					break;
				case 120103: 
					str = "没有获取到本地麦克风";
					break;
				case 120104:
					str = "函数调用顺序错误";
					break;
				case 120105:
					str = "通信IO错误";
					break;
				case 120106:
					str = "通信沙箱安全错误";
					break;
					
					
				default:
					str = "";
			}
			
			return str;
		}
		 

	}
	
}

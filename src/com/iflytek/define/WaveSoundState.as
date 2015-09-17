package com.iflytek.define
{
	
	public final class WaveSoundState 
	{
		public static const INIT:int = 0;      	   // 初始化
		public static const COMPILING:int = 1;     // 将PCM转换成WAV
		public static const COMPILED:int = 2;	   // 转换完毕
		public static const PLAYING:int = 3;	   // 正在播放
		public static const PLAYED:int = 4;        // 播放结束
	}
	
}

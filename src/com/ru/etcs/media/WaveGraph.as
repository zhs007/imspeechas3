/**
* WaveGraph by Denis Kolyako. May 28, 2007
* Visit http://dev.etcs.ru for documentation, updates and more free code.
*
* You may distribute this class freely, provided it is not modified in any way (including
* removing this header or changing the package path).
* 
*
* Please contact etc[at]mail.ru prior to distributing modified versions of this class.
*/
package com.ru.etcs.media {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import com.ru.etcs.media.PCMFormat;

	public class WaveGraph extends Sprite {
				
		/*
		* *********************************************************
		* CLASS PROPERTIES
		* *********************************************************
		*
		*/
		private var __data:ByteArray;
		private var __format:PCMFormat;
		private var __graphWidth:uint = 530;
		private var __graphHeight:uint = 200;		
		private var __position:Number = 0;
		private var __bmp:BitmapData;
		private var __bitmap:Bitmap;
		private var __line:Sprite;
		
		/**
		 * You can set these parameters at runtime to change WaveGraph look. You need to call redraw() method after changing.
		 */
		public var lineThickness:Number = 0;
		public var lineColor:uint = 0xFFFF00;
		public var lineAlpha:Number = 1;
		public var backgroundColor:uint = 0x000000;
		public var graphColor:uint = 0x00FF00;

		/*
		* *********************************************************
		* CONSTRUCTOR
		* *********************************************************
		*
		*/
		/**
		 * The WaveGraph class lets you visual draw wave form of WAVSound object.  
		 * 
		 * @param audioData:ByteArray — The wave-form data in ByteArray. See WAVSound.audioData property for details.
		 * @param audioFormat:PCMFormat — The information class of WAVSound. See WAVSound.audioFormat property for details.
		 */
		public function WaveGraph(audioData:ByteArray, audioFormat:PCMFormat) {
			super();
			__data = audioData;
			__format = audioFormat;
			__line = new Sprite();
			addChild(__line);
			redraw();
		}

		/*
		* *********************************************************
		* PUBLIC METHODS
		* *********************************************************
		*
		*/
		/**
		 * Redraws current graph immediately.
		 */
		public function redraw():void {
			var dataLength:uint = __data.length;
			var yCenter:uint = Math.floor(__graphHeight/2);
			var rect:Rectangle = new Rectangle(0,0,1,0);
			var peak:Number;
			var peakMax:uint = Math.pow(2,__format.bitsPerSample);
			var peakCenter:uint = peakMax/2;
			var averagePeaksCount:uint = Math.floor(dataLength/__graphWidth/2);
			var i:uint;

			if (__bitmap && __bmp) {
				removeChild(__bitmap);
				__bmp.dispose();
			}

			removeChild(__line);
			__bmp = new BitmapData(__graphWidth,__graphHeight,false,backgroundColor);
			__data.position = 0;			
			__line.graphics.clear();
			__line.graphics.lineStyle(lineThickness,lineColor,lineAlpha);
			__line.graphics.lineTo(0,__graphHeight);
			position = __position;

			if (__format.channels>1) {
				var isLeft:Boolean = true;
				var yLeftCenter:uint = Math.floor(__graphHeight/4);
				var yRightCenter:uint = 3*yLeftCenter;
				var h:uint = Math.floor(__graphHeight/2);
				var averageLeftMax:Number;
				var averageLeftMin:Number;
				var averageRightMax:Number;
				var averageRightMin:Number;
				
				while (__data.bytesAvailable) {
					averageLeftMax = -peakCenter;
					averageLeftMin = peakCenter;
					averageRightMax = -peakCenter;
					averageRightMin = peakCenter;

					for (i = 0;i<averagePeaksCount && __data.bytesAvailable;i++) {
						if (__format.bitsPerSample==16) {
							peak = __data.readShort();	
						} else {
							peak = __data.readUnsignedByte();
							peak -= peakCenter;
						}
						
						if (isLeft) {
							if (peak>averageLeftMax) {
								averageLeftMax = peak;
							}						
						
							if (peak<averageLeftMin) {
								averageLeftMin = peak;
							}
						} else {
							if (peak>averageRightMax) {
								averageRightMax = peak;
							}						
						
							if (peak<averageRightMin) {
								averageRightMin = peak;
							}
						}

						isLeft = !isLeft;
					}
					
					rect.x = Math.floor(__data.position/dataLength*__graphWidth);
					rect.height = Math.abs((averageLeftMax-averageLeftMin)/peakMax*h);			
					rect.height = rect.height < 1 ? 1 : rect.height;
					rect.y = h-Math.round(((averageLeftMax+peakCenter)/peakMax)*h);
					__bmp.fillRect(rect,graphColor);
					rect.height = Math.abs((averageRightMax-averageRightMin)/peakMax*h);			
					rect.height = rect.height < 1 ? 1 : rect.height;
					rect.y = __graphHeight-Math.round(((averageRightMax+peakCenter)/peakMax)*h);
					__bmp.fillRect(rect,graphColor);
				}
			} else {
				var averageMax:Number;
				var averageMin:Number;

				while (__data.bytesAvailable) {
					averageMax = -peakCenter;
					averageMin = peakCenter;

					for (i = 0;i<averagePeaksCount && __data.bytesAvailable;i++) {
						if (__format.bitsPerSample==16) {
							peak = __data.readShort();	
						} else {
							peak = __data.readUnsignedByte();
							peak -= peakCenter;
						}
										
						if (peak>averageMax) {
							averageMax = peak;
						}						
					
						if (peak<averageMin) {
							averageMin = peak;
						}
					}
					
					rect.x = Math.floor(__data.position/dataLength*__graphWidth);
					rect.height = Math.abs((averageMax-averageMin)/peakMax*__graphHeight);			
					rect.height = rect.height < 1 ? 1 : rect.height;
					rect.y = __graphHeight-Math.round(((averageMax+peakCenter)/peakMax)*__graphHeight);
					__bmp.fillRect(rect,graphColor);
				}
			}

			__bitmap = new Bitmap(__bmp);
			addChild(__bitmap);
			addChild(__line);
		}
		
		/*
		* *********************************************************
		* SETTERS/GETTERS
		* *********************************************************
		*
		*/
		/**
		 * Sets the position of current sound in percents.
		 */
		public function set position(value:Number):void {
			__line.x = value*__graphWidth;
			__position = value;
		}
		
		public function get position():Number {
			return __position;
		}
		
		/**
		 * Sets graph's width.
		 */
		public function set graphWidth(value:uint):void {
			__graphWidth = value;
			redraw();
		}
		
		public function get graphWidth():uint {
			return __graphWidth;
		}
		
		/**
		 * Sets graph's height.
		 */
		public function set graphHeight(value:uint):void {
			__graphHeight = value;
			redraw();
		}
		
		public function get graphHeight():uint {
			return __graphHeight;
		}
	}
}
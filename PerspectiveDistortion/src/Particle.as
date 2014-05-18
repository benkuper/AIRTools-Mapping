package  
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Elastic;
	import com.greensock.TweenLite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class Particle extends Sprite 
	{
		public var explosionFactor:Number = 70;
		
		public var lifeSpan:Number;
		public var lifeTimer:Timer;
		
		public var viscosity:Number = 0;
		
		public var speedX:Number;
		public var speedY:Number;
		private var speedFactor:Number = .1;
		
		private var bm:Bitmap;
		
		private var baseRadius:Number = 10;
		private var radiusScaleFactor:Number = 1;
		
		public var radius:Number;
		
		public var color:uint;
		
		public function Particle(color:uint,speedX:Number,speedY:Number,lifeSpan:Number = 1) 
		{
			this.color = color;
			//trace("new Particle ,", speedX, speedY);
			this.speedX = speedX*speedFactor;
			this.speedY = speedY*speedFactor;
			this.lifeSpan = lifeSpan;
			
			radius = baseRadius + (Math.abs(speedX) + Math.abs(speedY)) / 2 * radiusScaleFactor;
			if (radius == 0) radius = 5;
			if (radius > 200) radius = 200;
			graphics.beginFill(color);
			graphics.drawCircle(radius, radius, radius);
			graphics.endFill();
			
			
			var bd:BitmapData = new BitmapData(width, height, true,0x00000000);
			bd.draw(this);
			bm = new Bitmap();
			bm.bitmapData = bd;
			addChild(bm);
			bm.x = -bm.width / 2;
			bm.y = -bm.height / 2;
			
			graphics.clear();
			
			
			scaleX = 0;
			scaleY = 0;
			
			lifeTimer = new Timer(lifeSpan * 1000, 1);
			lifeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, lifeTimerComplete);
			lifeTimer.start();
			TweenLite.to(this, .8, { scaleX:1, scaleY:1, ease:Elastic.easeOut } );
			
			addEventListener(Event.ENTER_FRAME, enterFrame);
		}
		
		private function enterFrame(e:Event):void 
		{
			this.x += speedX;
			this.y += speedY;
			
			speedX = speedX - viscosity;
			speedY = speedY - viscosity;
		}
		
		private function lifeTimerComplete(e:TimerEvent):void 
		{
			explode();
		}
		
		public function explode():void
		{
			removeEventListener(Event.ENTER_FRAME, enterFrame);
			lifeTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,lifeTimerComplete);
			TweenLite.to(this, .6, { x:this.x + (Math.random()*2-1) * explosionFactor, y:this.y + (Math.random()*2-1) * explosionFactor, alpha:0, ease:Back.easeOut,onComplete:dispatchEvent,onCompleteParams:[new Event(Event.CUT)] });
		}
		
		public function freezeLife():void
		{
			lifeTimer.stop();
		}
		
	}

}
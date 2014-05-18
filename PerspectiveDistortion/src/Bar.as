package  
{
	import com.greensock.TweenLite;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import org.tuio.TuioContainer;
	import org.tuio.TuioTouchEvent;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class Bar extends Sprite 
	{
		private var bg:Shape;
		private var particles:Vector.<ParticleLine>;
		private var particleContainer:Sprite;
		private var exitDist:Number;
		public var touchPoints:Vector.<TuioContainer>;
		
		public var fixedWidth:Number = 2000;
		public var fixedHeight:Number = 380;
		
		public var exitPos:Point;
		
		public function Bar() 
		{
			bg = new Shape();
			bg.graphics.beginFill(0x000000);
			bg.graphics.drawRect(0, 0, 2000, 380);
			bg.graphics.endFill();
			addChild(bg);
			
			exitPos = new Point(950,120);
			exitDist = 50;
			
			particleContainer = new Sprite();
			addChild(particleContainer);
			
			touchPoints = new Vector.<TuioContainer>;
			particles = new Vector.<ParticleLine>;
			
			addEventListener(TuioTouchEvent.TOUCH_DOWN, touchDown);
			addEventListener(TuioTouchEvent.TOUCH_UP, touchUp);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
		
		private function touchUp(e:TuioTouchEvent):void 
		{
			var index:int = touchPoints.indexOf(e.tuioContainer);
			//trace("touch Up, remove Index", index);
			touchPoints.splice(index, 1);
			
			var particle:ParticleLine = particles[index];
			particles.splice(index, 1);
			particle.explode();
			particle.addEventListener("lineExplode", particleLineExplodeHandler);
			
			//if (touchPoints.length == 0)
			//{
				//removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			//}
			
		}
		
		private function particleLineExplodeHandler(e:Event):void 
		{
			particleContainer.removeChild(e.currentTarget as ParticleLine);
		}
		
		private function touchDown(e:TuioTouchEvent):void 
		{
			//trace("touchDOwn !", e.localX, e.localY);
			//particle.graphics.clear();
			
			touchPoints.push(e.tuioContainer);
			
			var particle:ParticleLine = createParticle();
			
			particleContainer.addChild(particle);
			particles.push(particle);

			
			//if (touchPoints.length == 1)
			//{
				//addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			//}	
		}
		
		private function enterFrameHandler(e:Event):void 
		{
			//trace("enterframe ,", touchPoints[0].x*width, touchPoints[0].y*height);
			for (var i:int = 0;i < touchPoints.length; i++)
			{
				particles[i].update(touchPoints[i].x * fixedWidth, touchPoints[i].y * fixedHeight);
			}
			
			
		}
		
		private function createParticle():ParticleLine
		{
			var p:ParticleLine = new ParticleLine();
			p.setExit(exitPos,exitDist);
			return p;
		}
		
	}

}
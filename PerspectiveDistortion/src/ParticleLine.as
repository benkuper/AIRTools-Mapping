package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class ParticleLine extends Sprite 
	{
		public var particles:Vector.<Particle>;
		
		private var numParticles:int = 150;
		private var pauseTime:Number = 1;
		private var randomness:Number = 0;
		private var explosionFactor:Number = 10;

		private var exitDist:Number;
		public var exitPos:Point;
		
		private var speedX:Number;
		private var speedY:Number;
		
		private var regenerate:Boolean;

		private var checkExit:Boolean;
		
		public function ParticleLine() 
		{
			particles = new Vector.<Particle>;
			speedX = 0;
			speedY = 0;
			regenerate = true;
			
			addEventListener(Event.ENTER_FRAME, enterFrame);
		}
		
		
		public function update(x:int,y:int):void
		{
			addParticle(x, y);
			//updateParticles();
		}
		
		private function enterFrame(e:Event):void 
		{
			updateParticles();
		}
		
		private function addParticle(x:Number, y:Number):void 
		{
			if (particles.length >= numParticles)
			{
				var oldParticle:Particle = particles.shift();
			}
			
			if (particles.length > 1)
			{
				speedX = x - particles[particles.length - 2].x;
				speedY = y - particles[particles.length - 2].y;
			}
			
			var p:Particle = new Particle(Math.random() * 0xffffff,speedX,speedY);
			particles.push(p);
			p.x = x;
			p.y = y;
			p.addEventListener(Event.CUT, particleExploded);
			addChild(p);
					
			
		}
		
		private function updateParticles():void 
		{
			//Si besoin
			if (checkExit)
			{
				for (var i:int = 0; i < particles.length; i++)
				{
					var p:Particle = particles[i];
					
					if (Point.distance(exitPos, new Point(p.x, p.y)) < exitDist)
					{
						p.explode();
						dispatchEvent(new ParticleEvent(ParticleEvent.PARTICLE_EXIT, p,true));
					}
				}
			}
		}
		
		private function particleExploded(e:Event):void 
		{
			if ((e.currentTarget as Particle).parent != null)
			{
				removeChild(e.currentTarget as Particle);
			}
			
			if (numChildren == 0)
			{
				dispatchEvent(new Event("lineExplode"));
			}
		}
		
		public function explode():void
		{
			//wait for particles to die
		}
		
		public function setExit(exitPos:Point, exitDist:Number):void 
		{
			//trace("set exit :", exitPos, exitDist);
			this.exitPos = exitPos;
			this.exitDist = exitDist;
			checkExit = true;
		}
		
	}

}
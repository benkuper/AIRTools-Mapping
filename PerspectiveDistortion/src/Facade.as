package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class Facade extends Sprite 
	{
		
		public var fixedWidth:Number = 1100;
		public var fixedHeight:Number = 210;
		
		public static var instance:Montant;
		
		public var maxSpeed:Number = 100;
		
		private var particles:Vector.<Particle>;
		private var particleContainer:Sprite;
		private var bg:Shape;
		
		public function Facade() 
		{
			
			bg = new Shape();
			bg.graphics.beginFill(0x000000);
			bg.graphics.drawRect(0, 0, fixedWidth, fixedHeight);
			bg.graphics.endFill();
			addChild(bg);
			
			particleContainer = new Sprite();
			addChild(particleContainer);
			
			particles = new Vector.<Particle>;
		}
		
		public function addParticle(p:Particle):void
		{
			
			//trace("Facade addParticle ",p.color);
			var particle:Particle = new Particle(p.color, Math.random() * maxSpeed, -Math.random() * maxSpeed , 5);
			particle.x = 0;
			particle.y = fixedHeight;
			particleContainer.addChild(particle);
			
			particle.addEventListener(Event.CUT, particleExploded);
			particles.push(particle);
		}
		
		private function particleExploded(e:Event):void 
		{
			
			particleContainer.removeChild(e.currentTarget as Particle);
			particles.splice(particles.indexOf(e.currentTarget as Particle), 1);
		}
		
	}

}
package  
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class Montant extends Sprite 
	{
		
		public var fixedWidth:Number = 60;
		public var fixedHeight:Number = 400;
		
		public static var instance:Montant;
		
		private var bg:Shape;
		
		private var shapes:Vector.<Shape>
		private var shapeContainer:Sprite;
		
		public function Montant() 
		{
			bg = new Shape();
			bg.graphics.beginFill(0x000000);
			bg.graphics.drawRect(0, 0, fixedWidth, fixedHeight);
			bg.graphics.endFill();
			addChild(bg);
			
			instance = this;
			
			shapeContainer = new Sprite();
			addChild(shapeContainer);
			
			shapes = new Vector.<Shape>;
		}
			
		
		public function addParticle(p:Particle):void
		{
			//trace("Montant addParticle ",p.color);
			var evt:ParticleEvent = new ParticleEvent(ParticleEvent.PARTICLE_EXIT, p);
			//TweenMax.fromTo(bg, .2, { colorMatrixFilter: { brightness:3,colorize:p.color }}, { colorMatrixFilter: { brightness:2 }} );
			
			
			
			var shape:Shape = createShape(p.color);
			shapeContainer.addChild(shape);
			shapes.push(shape);
			shape.y = fixedHeight;
			
			TweenLite.to(shape,1,{y:0,onComplete:exitParticle,onCompleteParams:[shape,p]});
		}
		
		private function exitParticle(s:Shape,p:Particle):void 
		{
			dispatchEvent(new ParticleEvent(ParticleEvent.PARTICLE_EXIT, p));
			shapeContainer.removeChild(s);
			shapes.splice(shapes.indexOf(s), 1);
		}
		
		public function createShape(color:uint):Shape
		{
			var s:Shape = new Shape();
			s.graphics.beginFill(color);
			s.graphics.drawRect(0, 0, fixedWidth, 20);
			s.graphics.endFill();
			return s;
		}
		

	}

}
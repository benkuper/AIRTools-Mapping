package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class ParticleEvent extends Event 
	{
		
		public static const PARTICLE_EXIT:String = "particleExit";
		
		public var particle:Particle;
		
		public function ParticleEvent(type:String, p:Particle = null, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			this.particle = p;
			
			

			
		} 
		
		public override function clone():Event 
		{ 
			return new ParticleEvent(type, particle, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ParticleEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}
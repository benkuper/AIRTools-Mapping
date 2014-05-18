package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class DistortEvent extends Event 
	{
		static public const HANDLER_UPDATE:String = "handlerUpdate";
		static public const SURFACES_LOADED:String = "surfacesLoaded";
		
		public var handler:Sprite;
		public var distortedSprite:DistortableSprite;
		
		public function DistortEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new DistortEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("DistortEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}
package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class HandleEvent extends Event 
	{
		
		static public const DRAGGING:String = "dragging";
		static public const DRAG_FINISH:String = "dragFinish";
		
		public function HandleEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new HandleEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("HandleEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}
package benkuper.metadata.components
{
	import com.bit101.components.Window;
	import flash.display.DisplayObjectContainer;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class MetaWindow extends Window 
	{
		public var target:Object;
		
		public function MetaWindow(target:Object, parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, title:String="Meta Window") 
		{
			super(parent, xpos, ypos, title);
			this.target = target;
		}
		
	}

}
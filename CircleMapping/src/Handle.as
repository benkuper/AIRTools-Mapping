package  
{
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import fonts.Fonts;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class Handle extends Sprite 
	{
		
		private var _selected:Boolean;
		private var _slave:Boolean;
		
		public function Handle(label:String) 
		{
			var tf:TextField = Fonts.createTF(label, Fonts.normalTF);
			addChild(tf);
			tf.x = 5;
			tf.y = 5;
			
			draw();
			addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
		}
		
		public function draw():void
		{
			graphics.clear();
			graphics.beginFill(selected?0xffff00:(slave?0xff00ff:0x666666));
			graphics.drawCircle(0, 0, 5);
			graphics.endFill();
		}
		
		private function mouseHandler(e:MouseEvent):void 
		{
			switch(e.type)
			{
				case MouseEvent.MOUSE_DOWN:
					stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					stage.addEventListener(Event.ENTER_FRAME, mouseEnterFrameHandler);
					selected = true;
					break;
					
				case MouseEvent.MOUSE_UP:
					stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					stage.removeEventListener(Event.ENTER_FRAME, mouseEnterFrameHandler);
					selected = false;
					dispatchEvent(new HandleEvent(HandleEvent.DRAG_FINISH));
					break;
			}
		}
		
		private function mouseEnterFrameHandler(e:Event):void 
		{
			this.x = stage.mouseX;
			this.y = stage.mouseY;
			dispatchEvent(new HandleEvent(HandleEvent.DRAGGING));
			//draw();
		}
		
		public function get selected():Boolean 
		{
			return _selected;
		}
		
		public function set selected(value:Boolean):void 
		{
			_selected = value;
			draw();
		}
		
		public function get slave():Boolean 
		{
			return _slave;
		}
		
		public function set slave(value:Boolean):void 
		{
			_slave = value;
			draw();
		}
		
		public function get point():Point
		{
			return new Point(x, y);
		}
		
	}
	
}
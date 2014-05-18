package  
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class DistortHandler extends Sprite 
	{
		
		static public const NORMAL:String = "normal";
		static public const HIGHLIGHTED:String = "highlighted";
		static public const SELECTED:String = "selected";
		
		public var target:Sprite;
		public var originalColor:uint;
		private var _curColor:uint;
		private var _state:String;
		
		public var linkLine:Sprite;
		private var _draggable:Boolean;
		
		public var oldMouse:Point;
		
		
		public function DistortHandler(color:uint) 
		{
			linkLine = new Sprite();
			addChild(linkLine);
			
			target = new Sprite();
			addChild(target);
			
			originalColor = color;
			curColor = originalColor;
			draw();
			
			
		}
		
		public function draw():void 
		{
			target.graphics.clear();
			target.graphics.beginFill(curColor,.6);
			target.graphics.lineStyle(1, 0xffffff,.3);
			target.graphics.drawCircle(0, 0, 10);
			target.graphics.endFill();
			
			target.graphics.beginFill(0xffffff, 0.05);
			target.graphics.lineStyle(1, 0xffffff,.05);
			target.graphics.drawCircle(0, 0, 20);
			target.graphics.endFill();
			
			//cross
			target.graphics.lineStyle(2, 0xffffff);
			target.graphics.moveTo( -5, 0);
			target.graphics.lineTo(5, 0);
			target.graphics.moveTo(0, -5);
			target.graphics.lineTo(0, 5);
		}
		
		public function drawLinkLine(globalPoint:Point = null):void
		{
			linkLine.graphics.clear();
			
			if (globalPoint == null) return;
			
			var localP:Point = globalToLocal(globalPoint);
			
			
			var angle:Number = Math.atan2(localP.y, localP.x) + Math.PI / 2;
			linkLine.graphics.beginFill(0xffff00,.4);
			linkLine.graphics.moveTo(localP.x, localP.y);
			linkLine.graphics.lineTo(Math.cos(angle) * 10, Math.sin(angle) * 10);
			linkLine.graphics.lineTo( -Math.cos(angle) * 10, -Math.sin(angle) * 10);

		}
		
		public function get state():String 
		{
			return _state;
		}
		
		public function set state(value:String):void 
		{
			if (_state == value) return;
			_state = value;
			switch(state)
			{
				case SELECTED:
					TweenMax.to(this, .2, {hexColors:{curColor:0xffff00 }} );
					break;
					
				case HIGHLIGHTED:
					TweenLite.to(target, .2, { scaleX:1.3, scaleY:1.3 } );
					break;
					
				case NORMAL:
					TweenLite.to(target, .2, { scaleX:1, scaleY:1 } );
					TweenMax.to(this,.2, {hexColors: { curColor:originalColor } } );
					drawLinkLine(null);
					break;
			}
		}
		
		public function get curColor():uint 
		{
			return _curColor;
		}
		
		public function set curColor(value:uint):void 
		{
			_curColor = value;
			draw();
		}
		
		public function get draggable():Boolean 
		{
			return _draggable;
		}
		
		public function set draggable(value:Boolean):void 
		{
			if (draggable == value) return;
			
			_draggable = value;
			if (value)
			{
				addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
				addEventListener(MouseEvent.MOUSE_OVER, mouseHandler);
				addEventListener(MouseEvent.MOUSE_OUT, mouseHandler);
			}else
			{
				removeEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
				removeEventListener(MouseEvent.MOUSE_OVER, mouseHandler);
				removeEventListener(MouseEvent.MOUSE_OUT, mouseHandler);
			}
		}
		
		private function mouseHandler(e:MouseEvent):void 
		{
			switch(e.type)
			{
				case MouseEvent.MOUSE_OVER:
					if (!e.buttonDown)
					{
						state = HIGHLIGHTED;
					}
					break;
					
				case MouseEvent.MOUSE_OUT:
					if (!e.buttonDown)
					{
						state = NORMAL;
					}
					break;
					
				case MouseEvent.MOUSE_DOWN:
					stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
					stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					oldMouse = new Point(stage.mouseX, stage.mouseY);
					state = SELECTED;
					break;
					
				case MouseEvent.MOUSE_UP:
					stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
					stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					state = HIGHLIGHTED;
					break;
					
			}
			
			e.stopImmediatePropagation();
		}
		
		private function enterFrameHandler(e:Event):void 
		{
			this.x += stage.mouseX - oldMouse.x;
			this.y += stage.mouseY - oldMouse.y;
			
			oldMouse.x = stage.mouseX;
			oldMouse.y = stage.mouseY;
			
			dispatchEvent(new DistortEvent(DistortEvent.HANDLER_UPDATE));
		}
		
	}

}
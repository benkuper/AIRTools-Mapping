package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import org.poly2tri.Sweep;
	import org.poly2tri.SweepContext;
	import org.poly2tri.Triangle;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class CutoutSprite extends Sprite 
	{
		static public const CREATION:String = "creation";
		static public const CALIBRATION:String = "calibration";
		static public const SHOW_ALL:String = "showAll";
		static public const DISTORTED_ONLY:String = "distortedOnly";
		
		public var originalSprite:Sprite;
		private var _showOriginal:Boolean;
		
		public var originalHandlers:Vector.<DistortHandler>;
		public var originalHandlerContainer:Sprite;
		
		public var distortedSprite:Sprite;
		public var distortedHandlers:Vector.<DistortHandler>;
		
		//Delaunay triangulation
		private var sweep:Sweep;
		private var sweepContext:SweepContext;
		
		private var _mode:String;
		private var distortedHandlerContainer:Sprite;
		
		private var _drawDebug:Boolean;
		public var oldMouse:Point;
		
		public function CutoutSprite(originalSprite:Sprite ) 
		{
			distortedSprite = new Sprite();
			addChild(distortedSprite);

			
			distortedHandlers = new Vector.<DistortHandler>;
			distortedHandlerContainer = new Sprite();
			
			this.originalSprite = originalSprite;
			
			originalHandlers = new Vector.<DistortHandler>;
			originalHandlerContainer = new Sprite();
			mode = CREATION;
			
			
			originalSprite.addEventListener(MouseEvent.RIGHT_CLICK, originalMouseHandler);
			originalSprite.addEventListener(MouseEvent.CLICK, originalMouseHandler);
			
			addEventListener(DistortEvent.HANDLER_UPDATE, handlerUpdate);
			
			distortedSprite.addEventListener(MouseEvent.MOUSE_DOWN, distortedMouseHandler);
		}
		
		private function distortedMouseHandler(e:MouseEvent):void 
		{
			switch(e.type)
			{
				case MouseEvent.MOUSE_DOWN:
					stage.addEventListener(MouseEvent.MOUSE_UP, distortedMouseHandler);
					stage.addEventListener(Event.ENTER_FRAME, distortedMouseEnterFrame);
					oldMouse = new Point(stage.mouseX, stage.mouseY);
					break;
					
				case MouseEvent.MOUSE_UP:
					stage.removeEventListener(MouseEvent.MOUSE_UP, distortedMouseHandler);
					stage.removeEventListener(Event.ENTER_FRAME, distortedMouseEnterFrame);
					break;
			}
		}
		
		
		
		private function originalMouseHandler(e:MouseEvent):void 
		{
			switch(e.type)
			{
				case MouseEvent.RIGHT_CLICK:
					var h:DistortHandler = addHandler(mouseX,mouseY);
					
					
					drawHandlerNetwork();
					break;
			}
		}
		
		private function distortedMouseEnterFrame(e:Event):void 
		{
			var offsetX:Number = stage.mouseX - oldMouse.x;
			var offsetY:Number = stage.mouseY - oldMouse.y;
			for each(var h:DistortHandler in distortedHandlers)
			{
				h.x += offsetX;
				h.y += offsetY;
			}
			
			oldMouse = new Point(stage.mouseX, stage.mouseY);
			
			drawDistortedSprite();
		}
		
		private function addHandler(tx:Number,ty:Number):DistortHandler 
		{
			//trace("3:Cutout Sprite :: Add Handler");
			var h:DistortHandler = new DistortHandler(originalHandlers.length == 0?0x00ff00:0xff0000);
			originalHandlerContainer.addChild(h);
			originalHandlers.push(h);
			h.draggable = true;
			h.addEventListener(MouseEvent.RIGHT_CLICK, deleteHandler);
			h.x = tx;
			h.y = ty;
			
			var dh:DistortHandler = new DistortHandler(distortedHandlers.length == 0?0x00ff00:0xff00ff);
			distortedHandlers.push(dh);
			distortedHandlerContainer.addChild(dh);
			dh.draggable = true;
			dh.x = tx;
			dh.y = ty;
			
			return h;
		}
		
		private function deleteHandler(e:MouseEvent):void 
		{
			var h:DistortHandler = e.currentTarget as DistortHandler;
			originalHandlerContainer.removeChild(h);
			h.removeEventListener(MouseEvent.RIGHT_CLICK, deleteHandler);
			h.draggable = false;
			var hIndex:int = originalHandlers.indexOf(h);
			originalHandlers.splice(hIndex, 1);
			
			
			var dh:DistortHandler = distortedHandlers[hIndex];
			distortedHandlerContainer.removeChild(dh);
			distortedHandlers.splice(hIndex, 1);
			dh.draggable = false;
			
			drawHandlerNetwork();
			
		}
		
		private function handlerUpdate(e:DistortEvent):void 
		{
			var h:DistortHandler = e.target as DistortHandler;
			if (h.parent == originalHandlerContainer)
			{
				drawHandlerNetwork();
			}else
			{
				drawDistortedSprite();
			}
		}
		
		private function drawHandlerNetwork():void
		{
			if (originalHandlers.length < 3) return;
			
			originalHandlerContainer.graphics.clear();
			
			if (drawDebug)
			{
				var points:Vector.<org.poly2tri.Point> = handlersToPoint(originalHandlers);
				var triangles:Vector.<Triangle> = getTrianglesForPoints(points);
				var cIndex:int = 1;
				
				for each(var t:Triangle in triangles)
				{
					var c:uint = 0x5433a6 * cIndex;
					cIndex++;
					
					originalHandlerContainer.graphics.beginFill(c, .5);
					originalHandlerContainer.graphics.moveTo(t.points[0].x, t.points[0].y);
					originalHandlerContainer.graphics.lineTo(t.points[1].x, t.points[1].y);
					originalHandlerContainer.graphics.lineTo(t.points[2].x, t.points[2].y);
					originalHandlerContainer.graphics.endFill();
					
					//trace("Point indices : " + points.indexOf(t.points[0]), points.indexOf(t.points[1]), points.indexOf(t.points[2]));
				}
			}
			
			originalHandlerContainer.graphics.lineStyle(1, 0xffff00);
			originalHandlerContainer.graphics.moveTo(originalHandlers[0].x, originalHandlers[0].y);
			for (var i:int = 1; i < originalHandlers.length;i++ )
			{
				originalHandlerContainer.graphics.lineTo(originalHandlers[i].x, originalHandlers[i].y);
			}
			originalHandlerContainer.graphics.lineTo(originalHandlers[0].x, originalHandlers[0].y);
			
			drawDistortedSprite();
		}
		
		[Shortcut (key="r")]
		public function resetHandlers(keepOrigins:Boolean = true):void
		{
			if (originalHandlers.length == 0) return;
			var offset:Point = new Point();
			if (keepOrigins)
			{
				offset.x = distortedHandlers[0].x - originalHandlers[0].x;
				offset.y = distortedHandlers[0].y - originalHandlers[0].y;
			}
			//trace("reset handlers !");
			for (var i:int = 1; i < originalHandlers.length;i++)
			{
				distortedHandlers[i].x = originalHandlers[i].x + offset.x;
				distortedHandlers[i].y = originalHandlers[i].y + offset.y;
			}
			drawDistortedSprite();
		}
		
		private function handlersToPoint(handlers:Vector.<DistortHandler>):Vector.<org.poly2tri.Point>
		{
			var points:Vector.<org.poly2tri.Point> = new Vector.<org.poly2tri.Point>;
			for each(var h:DistortHandler in handlers)
			{
				points.push(new org.poly2tri.Point(h.x, h.y));
			}
			
			return points;
		}
		
		private function getTrianglesForPoints(points:Vector.<org.poly2tri.Point>):Vector.<Triangle>
		{
			
			
			sweepContext = new SweepContext(points);
			sweep = new Sweep(sweepContext);
			sweep.triangulate();
			
			//for each(var t:Triangle in triangles)
			//{
				//trace("Triangle :" + t.points);
			//}
			
			return sweepContext.triangles;
			
		}
		
		private function drawDistortedSprite():void 
		{
			if (originalHandlers.length < 3) return;
			var uvtData:Vector.<Number> = new Vector.<Number>;
			var coords:Vector.<Number> = new Vector.<Number>;
			
		
			for (var i:int = 0; i < originalHandlers.length;i++)
			{
				var h:DistortHandler = originalHandlers[i];
				var dh:DistortHandler = distortedHandlers[i];
				
				coords.push(dh.x,dh.y);
				uvtData.push(h.x / originalSprite.width, h.y / originalSprite.height);
				
				
			}
			
			
			var indices:Vector.<int> = new Vector.<int>();// [0, 1, 2, 1, 3, 2]);
			var points:Vector.<org.poly2tri.Point> = handlersToPoint(originalHandlers);
			var triangles:Vector.<Triangle> = getTrianglesForPoints(points);
			
			
			
			for each(var t:Triangle in triangles)
			{
				indices.push(points.indexOf(t.points[0]), points.indexOf(t.points[1]), points.indexOf(t.points[2]));
			}
			
			var bd:BitmapData = new BitmapData(originalSprite.width, originalSprite.height, !drawDebug, 0xff00ff);
			bd.draw(originalSprite);
			
			
			distortedSprite.graphics.clear();
			distortedSprite.graphics.beginBitmapFill(bd, null, false, true);
			distortedSprite.graphics.drawTriangles(coords, indices, uvtData);
			distortedSprite.graphics.endFill();
			
			
			if (drawDebug)
			{
				for each(var dt:Triangle in triangles)
				{
					if (points.indexOf(dt.points[0]) >= 0 && points.indexOf(dt.points[1]) >= 0 && points.indexOf(dt.points[2]) >= 0)
					{
						var dh1:DistortHandler = distortedHandlers[points.indexOf(dt.points[0])];
						var dh2:DistortHandler = distortedHandlers[points.indexOf(dt.points[1])];
						var dh3:DistortHandler = distortedHandlers[points.indexOf(dt.points[2])];
						
						distortedSprite.graphics.lineStyle(1, 0xffff00,.8);
						distortedSprite.graphics.moveTo(dh1.x, dh1.y);
						distortedSprite.graphics.lineTo(dh2.x, dh2.y);
						distortedSprite.graphics.lineTo(dh3.x, dh3.y);
						distortedSprite.graphics.lineTo(dh1.x, dh1.y);
					}
				}
			}
			
			//trace("Num triangles :",triangles.length);
			
			
		}
		
		private function showDistorted(value:Boolean, showHandlers:Boolean):void 
		{
			
			if (value)
			{
				addChild(distortedSprite)
			}else if (distortedSprite.parent == this)
			{
				removeChild(distortedSprite);
			}
			
			if (showHandlers)
			{
				distortedSprite.addChild(distortedHandlerContainer);
			}else if(distortedHandlerContainer.parent == distortedSprite)
			{
				distortedSprite.removeChild(distortedHandlerContainer);
			}
		}
		
		public function get showOriginal():Boolean 
		{
			return _showOriginal;
		}
		
		public function set showOriginal(value:Boolean):void 
		{
			_showOriginal = value;
			if (value)
			{
				addChildAt(originalSprite, 0);
				addChild(originalHandlerContainer);
			}else
			{
				if (originalSprite.parent == this)
				{
					removeChild(originalSprite);
				}
				if (originalHandlerContainer.parent == this)
				{
					removeChild(originalHandlerContainer);
				}
			}
		}
		
		[Shortcut(key="1",value="creation")]
		[Shortcut(key="2",value="calibration")]
		[Shortcut(key="3",value="showAll")]
		[Shortcut(key = "4", value = "distortedOnly")]
		[Shortcut(key="&", keyMask="shift",value="creation")]
		[Shortcut(key="é", keyMask="shift",value="calibration")]
		[Shortcut(key="\"", keyMask="shift",value="showAll")]
		[Shortcut(key="'", keyMask="shift",value="distortedOnly")]
		public function get mode():String 
		{
			return _mode;
		}
		
		public function set mode(value:String):void 
		{
			_mode = value;
			
			switch(mode)
			{
				case CREATION:
					showOriginal = true;
					showDistorted(false,false);
					break;
					
				case CALIBRATION:
					showOriginal = false;
					showDistorted(true,true);
					break;
					
				case SHOW_ALL:
					showOriginal = true;
					showDistorted(true, true);
					break;
					
				case DISTORTED_ONLY:
					showOriginal = false;
					showDistorted(true, false);
					break;
			}
		}
		
		public function get drawDebug():Boolean 
		{
			return _drawDebug;
		}
		
		[Shortcut (key = "d")]
		public function set drawDebug(value:Boolean):void 
		{
			_drawDebug = value;
			drawHandlerNetwork();
		}
		
		
		
	}

}
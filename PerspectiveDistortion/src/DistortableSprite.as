package  
{
	import com.greensock.BlitMask;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class DistortableSprite extends Sprite
	{
		
		private var _originalSprite:DisplayObject;
		
		
		public var handlers:Vector.<DistortHandler>;
		public var handlerTL:DistortHandler;
		public var handlerTR:DistortHandler;
		public var handlerBR:DistortHandler;
		public var handlerBL:DistortHandler;
		
		public var curHandler:DistortHandler;
		public var curHandlerOffset:Point;
		
		private var _showHandlers:Boolean;
		public var showGrid:Boolean;
		
		private var grid:Sprite;
		private var gridMode:String;
		static public const GRID_RELATIVE:String = "gridRelative";
		static public const GRID_ABSOLUTE:String = "gridAbsolute";
		
		private var gridBMD:BitmapData;
		private var _gridSize:int;
		public var bmd:BitmapData;
		
		private var blitRect:Rectangle;
		
		private var _originalWidth:Number;
		private var _originalHeight:Number;
		
		private var xmlSurface:XML;
		
		public var id:String;
		
		public var oldMouse:Point;
		
		private var _autoRefresh:Boolean;
		
		[Shortcut (key="u")]
		public var autoUpdateBitmap:Boolean;
		
		[Shortcut (key="b")]
		public var smooth:Boolean;
		
		private var _useGPU:Boolean;
		
		
		public var enabled:Boolean;
		
		//TEMP !!!!!!!!!
		private var diagSprite:Sprite;
		
		
		public function DistortableSprite(id:String) 
		{
			//mouseChildren = false;
			
			//trace("new DistSprite", id, originalWidth, originalHeight);
			this.id = id;
			handlerTL = createHandler(0xff00ff);
			addChild(handlerTL);
			handlerTR = createHandler(0x00ff00);
			addChild(handlerTR);
			handlerBL = createHandler();
			addChild(handlerBL);
			handlerBR = createHandler(0x0000ff);
			addChild(handlerBR);
			
			
			handlers = new Vector.<DistortHandler>;
			handlers.push(handlerTL, handlerTR, handlerBL, handlerBR);
			
			grid = new Sprite();
			showGrid = false;
			_gridSize = 5;
			gridMode = GRID_RELATIVE;
			
			showHandlers = false;
			
			
			autoUpdateBitmap = true;
			
			addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
			addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, mouseHandler);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
			addEventListener(MouseEvent.ROLL_OUT, mouseHandler);
			
			bmd = new BitmapData(100,100, true, 0x00ff00ff);
			
			_autoRefresh = true;
			
			diagSprite = new Sprite();
			addChild(diagSprite);
			
			enabled = true;
		}
		
		private function computeDistortion(e:Event = null):Boolean
		{
			
			if (!enabled) return false;
			//trace("Compute Distortion, bitmapdata");
			if (autoUpdateBitmap)
			{
				if (!updateBitmapData()) return false;
			}
			
			//tmp gpu handling in main
			if (useGPU) 
			{
				if (showHandlers)
				{
					graphics.clear();
					graphics.beginFill(0xff00ff, 0);
					graphics.moveTo(handlerTL.x, handlerTL.y);
					graphics.lineTo(handlerTR.x, handlerTR.y);
					graphics.lineTo(handlerBR.x, handlerBR.y);
					graphics.lineTo(handlerBL.x, handlerBL.y);
					
				}
				return true;
			}
			
			//trace("> drawDistort");
			if (!drawDistortedSprite())
			{
				//trace("#error");
				drawErrorSprite();
				return false;
			}
			
			//trace("success");
			return true;
		}
		
		private function updateBitmapData():Boolean 
		{
			if (originalSprite == null || originalSprite.width == 0 || originalSprite.height == 0) return false;
			
			//trace("updateBitmapData,", originalSprite , originalWidth, originalHeight);
			
			if (originalWidth == 0 || originalHeight == 0)
			{
				trace("2:Problem with dimensions, not doing anything");
				return false;
			}
			
			bmd.lock();
			bmd.fillRect(blitRect, 0);
			bmd.draw(originalSprite, null, null, null, blitRect, smooth);
			
			if (showGrid)
			{
				bmd.copyPixels(gridBMD,blitRect,new Point(0,0),null,null,true);
			}
			
			bmd.unlock();
			
			//TEMP
			
			diagSprite.graphics.clear();
			if (showGrid)
			{
				diagSprite.graphics.lineStyle(2, 0xff00ff);
				diagSprite.graphics.moveTo(handlerTL.x, handlerTL.y);
				diagSprite.graphics.lineTo(handlerBR.x, handlerBR.y);
				diagSprite.graphics.moveTo(handlerTR.x, handlerTR.y);
				diagSprite.graphics.lineTo(handlerBL.x, handlerBL.y);
			}
			
			return true;
		}
		
		private function drawErrorSprite():void
		{
			graphics.clear();
			graphics.beginFill(0xaa3333, .5);
			graphics.moveTo(handlerTL.x, handlerTL.y);
			
			graphics.lineTo(handlerBR.x, handlerBR.y);
			graphics.lineTo(handlerTR.x, handlerTR.y);
			graphics.lineTo(handlerBL.x, handlerBL.y);
			graphics.lineTo(handlerTL.x, handlerTL.y);
			graphics.lineStyle(3, 0xff0000);
			graphics.moveTo(handlerTL.x, handlerTL.y);
			graphics.lineTo(handlerTR.x, handlerTR.y);
			graphics.moveTo(handlerBL.x, handlerBL.y);
			graphics.lineTo(handlerBR.x, handlerBR.y);
				
		}
		
		private function drawDistortedSprite():Boolean
		{
			
			graphics.clear();
			graphics.beginBitmapFill(bmd, null, false,smooth);
			
			var uvData:Vector.<Number> = getUVTData();
			if (!uvData) return false;
			
			graphics.drawTriangles(
				Vector.<Number>([handlerTL.x, handlerTL.y, handlerTR.x, handlerTR.y, handlerBL.x, handlerBL.y, handlerBR.x, handlerBR.y]),
				Vector.<int>([0,1,2, 1,3,2]),
				uvData); // Magic
				
			return true;
			
		}
		
		private function mouseHandler(e:MouseEvent):void 
		{
			var h:DistortHandler;
			if (!showHandlers) return;
			switch(e.type)
			{
				
				case MouseEvent.MOUSE_MOVE:
					
					if (!e.buttonDown)
					{
						var newHandler:DistortHandler = getClosestHandler(stage.mouseX, stage.mouseY);
						if (curHandler != newHandler)
						{
							if (curHandler != null) 
							{
								curHandler.state = DistortHandler.NORMAL;
								curHandler.drawLinkLine(null);
							}
							
						}
						
						curHandler = newHandler;
							curHandler.state = DistortHandler.HIGHLIGHTED;
						
						curHandler.drawLinkLine(new Point(stage.mouseX, stage.mouseY));
					}
					
					break;
					
				case MouseEvent.ROLL_OUT:
					
					if (!e.buttonDown)
					{
						if (curHandler != null)
						{
							curHandler.state = DistortHandler.NORMAL;
						//	curHandler.drawLinkLine(null);
						}
						
						curHandler = null;
					}
					break;
					
				case MouseEvent.MOUSE_DOWN:
					if (curHandler != null)
					{
						curHandler.state = DistortHandler.SELECTED;
						addEventListener(Event.ENTER_FRAME, mouseEnterFrame);
						stage.addEventListener(MouseEvent.MOUSE_UP, mouseHandler);
						oldMouse = new Point(stage.mouseX, stage.mouseY);
					}
					//curHandlerOffset = new Point(curHandler.mouseX, curHandler.mouseY);
					break;
					
				case MouseEvent.MOUSE_UP:
					if (curHandler != null)
					{
						curHandler.state = DistortHandler.NORMAL;
					}
					removeEventListener(Event.ENTER_FRAME, mouseEnterFrame);
					stage.removeEventListener(MouseEvent.MOUSE_UP, mouseHandler);
					break;
					
				case MouseEvent.RIGHT_MOUSE_DOWN:
					addEventListener(Event.ENTER_FRAME, rightMouseEnterFrame);
					stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, mouseHandler);
					oldMouse = new Point(stage.mouseX, stage.mouseY);
					
					for each(h in handlers)
					{
						h.state = DistortHandler.SELECTED;
						h.drawLinkLine(new Point(stage.mouseX, stage.mouseY));
					}
					break;
					
				case MouseEvent.RIGHT_MOUSE_UP:
					removeEventListener(Event.ENTER_FRAME, rightMouseEnterFrame);
					stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, mouseHandler);
					
					for each(h in handlers)
					{
						h.state = DistortHandler.NORMAL;
						h.drawLinkLine(null);
					}
					break;
					
			}
			
		}
		
		
		private function mouseEnterFrame(e:Event):void
		{
			if (curHandler == null) return;
			var curMouse:Point = new Point(stage.mouseX, stage.mouseY);
			
			var delta:Point = new Point(curMouse.x - oldMouse.x, curMouse.y - oldMouse.y);
			
			curHandler.x += delta.x;
			curHandler.y += delta.y;
			
			oldMouse = curMouse;
		}
	
		
		private function rightMouseEnterFrame(e:Event):void
		{
			var curMouse:Point = new Point(stage.mouseX, stage.mouseY);
			var delta:Point = new Point(curMouse.x - oldMouse.x, curMouse.y - oldMouse.y);
			for (var i:int = 0; i < handlers.length; i++)
			{
				handlers[i].x += delta.x;
				handlers[i].y += delta.y;
			}
			oldMouse = curMouse;
		}
		
		
		private function createHandler(color:uint = 0xffff00):DistortHandler
		{
			var h:DistortHandler = new DistortHandler(color);
			//h.addEventListener(MouseEvent.MOUSE_DOWN, handlerMouseHandler);
			return h;
		}
		
		private function getClosestHandler(tx:Number, ty:Number):DistortHandler 
		{
			var pDist:Point = new Point(tx, ty);
			
			var closestHandler:DistortHandler = handlers[0];
			var dDist:Point = new Point(closestHandler.x, closestHandler.y);
			
			var minDist:Number = Point.distance(pDist, dDist);
			for each(var h:DistortHandler in handlers)
			{
				dDist.x = h.x;
				dDist.y = h.y
				var curDist:Number = Point.distance(pDist, dDist);
				if (curDist < minDist)
				{
					closestHandler = h;
					minDist = curDist;
				}
			}
			
			return closestHandler;
		}
		
		
		public function getPoint(handler:Sprite):Point
		{
			return new Point(handler.x, handler.y);
		}
		
		public function get showHandlers():Boolean 
		{
			return _showHandlers;
		}
		
		public function set showHandlers(value:Boolean):void 
		{
			
			_showHandlers = value;
			if (value)
			{
				addChild(handlerTL);
				addChild(handlerTR);
				addChild(handlerBR);
				addChild(handlerBL);
			}else if(handlerTL.parent != null)
			{
				removeChild(handlerTL);
				removeChild(handlerTR);
				removeChild(handlerBR);
				removeChild(handlerBL);
			}
		}
		
		
		[Shortcut (key="r")]
		public function resetHandlers():void
		{
			if (originalSprite == null) return;
			
			handlerTL.x = 0;
			handlerTR.x = originalSprite.width;
			
			handlerBL.y = originalSprite.height;
			
			handlerBR.x = originalSprite.width;
			handlerBR.y = originalSprite.height;
		}
		
		public function setHandlers(points:XMLList):void 
		{
			//trace("set Handlers");
			handlerTL.x = points[0].@x;
			handlerTL.y = points[0].@y;
			handlerTR.x = points[1].@x;
			handlerTR.y = points[1].@y;
			handlerBL.x = points[2].@x;
			handlerBL.y = points[2].@y;
			handlerBR.x = points[3].@x;
			handlerBR.y = points[3].@y;
		}
		
		
		public function setOriginalSize(w:Number, h:Number):void
		{
			this._originalWidth = w;
			this._originalHeight = h;
			bmd = new BitmapData(this.originalWidth, this.originalHeight);
			
			blitRect = new Rectangle(0, 0, originalWidth, originalHeight)
			drawGrid();
			
		}
		
		public function drawGrid():void
		{
			var thickness:Number;
			//trace("drawGrid");
			
			switch(gridMode)
			{
				case GRID_ABSOLUTE:
					thickness = 4;
					grid.graphics.clear();
					grid.graphics.lineStyle(thickness, 0xffffff);
					//grid.graphics.beginFill(0xffffff, 0);
					//grid.graphics.drawRect(0, 0, 100,100);
					for (var tx:int = 0; tx <= originalWidth; tx+=gridSize)
					{
						grid.graphics.moveTo(tx, 0);
						grid.graphics.lineTo(tx, originalHeight);
						
					}
					
					for (var ty:int = 0; ty <= originalHeight; ty+=gridSize)
					{
						grid.graphics.moveTo(0,ty);
						grid.graphics.lineTo(originalWidth,ty);
						
					}
					break;
				
				case GRID_RELATIVE:
					thickness = 8;
					grid.graphics.clear();
					grid.graphics.lineStyle(thickness, 0xffffff);
					for (var i:int = 0; i < gridSize;i++ )
					{
						grid.graphics.moveTo(0, i / (gridSize-1) * originalHeight);
						grid.graphics.lineTo(originalWidth, i / (gridSize-1) * originalHeight);
						
						grid.graphics.moveTo(i / (gridSize-1) * originalWidth,0);
						grid.graphics.lineTo(i / (gridSize-1) * originalWidth, originalHeight);
						
					}
				break;
			}
			
			
			gridBMD = new BitmapData(originalWidth,originalHeight, true, 0xff000000);
			gridBMD.draw(grid,null,null,null,new Rectangle(0, 0, originalWidth, originalHeight),true);
			//grid.graphics.clear();
			
		}
		
		
		//UV
		
		public function getXYZData():Vector.<Number>
		{
			var pc:Point = getIntersection(); // Central point
			if (!Boolean(pc)) return null;
			
			// Lenghts of first diagonal		
			var ll1:Number = Point.distance(getPoint(handlerTL), pc);
			var ll2:Number = Point.distance(pc, getPoint(handlerBR));

			// Lengths of second diagonal		
			var lr1:Number = Point.distance(getPoint(handlerTR), pc);
			var lr2:Number = Point.distance(pc, getPoint(handlerBL));

			// Ratio between diagonals
			var f:Number = (ll1 + ll2) / (lr1 + lr2);
			
			return Vector.<Number>([
				((handlerTL.x/stage.stageWidth)-.5)*2, ((handlerTL.y/stage.stageHeight)-.5)*-2, (1 / ll2) * f, 	// - 1st vertex x,y,z,r,g,b 
				((handlerTR.x/stage.stageWidth)-.5)*2, ((handlerTR.y/stage.stageHeight)-.5)*-2, (1 / lr2), 	// - 2nd vertex x,y,z,r,g,b 
				((handlerBL.x/stage.stageWidth)-.5)*2, ((handlerBL.y/stage.stageHeight)-.5)*-2, (1 / lr1), 	// - 3rd vertex x,y,z,r,g,b
				((handlerBR.x/stage.stageWidth)-.5)*2, ((handlerBR.y/stage.stageHeight)-.5)*-2, (1 / ll1) * f
				]);
		}
		
		public function getUVTData():Vector.<Number>
		{
			//trace("getUVData");
			var pc:Point = getIntersection(); // Central point
			if (!Boolean(pc)) return null;
			
			// Lenghts of first diagonal		
			var ll1:Number = Point.distance(getPoint(handlerTL), pc);
			var ll2:Number = Point.distance(pc, getPoint(handlerBR));

			// Lengths of second diagonal		
			var lr1:Number = Point.distance(getPoint(handlerTR), pc);
			var lr2:Number = Point.distance(pc, getPoint(handlerBL));

			// Ratio between diagonals
			var f:Number = (ll1 + ll2) / (lr1 + lr2);
			
			return Vector.<Number>([0, 0, (1 / ll2) * f, 1, 0, (1 / lr2), 0, 1, (1 / lr1), 1, 1, (1 / ll1) * f]);
		}
		
		
		
		private function getIntersection(): Point {
			// Returns a point containing the intersection between two lines
			// http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
			// http://www.gamedev.pastebin.com/f49a054c1
			
			//not in order on purpose for cross calculation
			
			//trace("get Intersection");
			var p1:Point = getPoint(handlerTL);
			var p2:Point = getPoint(handlerBR);
			var p3:Point = getPoint(handlerTR);
			var p4:Point = getPoint(handlerBL);
			
			var a1:Number = p2.y - p1.y;
			var b1:Number = p1.x - p2.x;
			var a2:Number = p4.y - p3.y;
			var b2:Number = p3.x - p4.x;
				 
			var denom:Number = a1 * b2 - a2 * b1;
			if (denom == 0) return null;

			var c1:Number = p2.x * p1.y - p1.x * p2.y;
			var c2:Number = p4.x * p3.y - p3.x * p4.y;

			var p:Point = new Point((b1 * c2 - b2 * c1)/denom, (a2 * c1 - a1 * c2)/denom);
		 
			if (Point.distance(p, p2) > Point.distance(p1, p2)) return null;
			if (Point.distance(p, p1) > Point.distance(p1, p2)) return null;
			if (Point.distance(p, p4) > Point.distance(p3, p4)) return null;
			if (Point.distance(p, p3) > Point.distance(p3, p4)) return null;
			
			return p;
		}
				
				
		public function getXMLString():String
		{
			var xmlString:String = "	<surface id=\""+id+"\">"
			+"		<point x=\""+handlerTL.x+"\" y=\""+handlerTL.y+"\"/>"
			+"		<point x=\""+handlerTR.x+"\" y=\""+handlerTR.y+"\"/>"
			+"		<point x=\""+handlerBL.x+"\" y=\""+handlerBL.y+"\"/>"
			+"		<point x=\""+handlerBR.x+"\" y=\""+handlerBR.y+"\"/>"
			+"	</surface>";
			
			return xmlString;
			
		}
		
		
		
		public function get originalSprite():DisplayObject
		{
			return _originalSprite;
		}
		
		public function set originalSprite(value:DisplayObject):void 
		{
			if (originalSprite != null)
			{
				//this.removeChild(originalSprite);
			}
			
			_originalSprite = value;
			
			if (value != null)
			{
				//this.addChildAt(originalSprite,0);
				//originalSprite.x = 0;
				//originalSprite.y = 0;
				
				if (!hasEventListener(Event.ENTER_FRAME))
				{
					addEventListener(Event.ENTER_FRAME, computeDistortion);
				}
				
				
				//trace("generate graphics");
				
				resetHandlers();
				
				if (originalSprite.width > 0 && originalSprite.height > 0)
				{
					setOriginalSize(originalSprite.width, originalSprite.height);
				}
				
				computeDistortion();
			
			}else
			{
				removeEventListener(Event.ENTER_FRAME, computeDistortion);
			}
			
		}
		

		public function get gridSize():int 
		{
			return _gridSize;
		}
		
		
		
		[Shortcut(type = "add", key = "+")]
		[Shortcut(type = "subtract",key = "-")]
		public function set gridSize(value:int):void 
		{
			if (value < 1) return;
			_gridSize = value;
			drawGrid();
		}
		
		
		[Shortcut (key="a")]
		public function get autoRefresh():Boolean 
		{
			return _autoRefresh;
		}
		
		public function set autoRefresh(value:Boolean):void 
		{
			_autoRefresh = value;
			
			if (value)
			{
				if (!hasEventListener(Event.ENTER_FRAME) && originalSprite != null) addEventListener(Event.ENTER_FRAME, computeDistortion);
			}else
			{
				if (hasEventListener(Event.ENTER_FRAME)) removeEventListener(Event.ENTER_FRAME, computeDistortion);
			}
		}
		
		public function get originalWidth():Number 
		{
			return _originalWidth;
		}
		
		public function get originalHeight():Number 
		{
			return _originalHeight;
		}
		
		[Shortcut (key = "p")]
		public function get useGPU():Boolean 
		{
			return _useGPU;
		}
		
		public function set useGPU(value:Boolean):void 
		{
			_useGPU = value;
			graphics.clear();
		}
		
		
	}

}
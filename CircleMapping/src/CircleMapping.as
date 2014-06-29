package
{
	import benkuper.util.Shortcutter;
	import benkuper.util.StageUtil;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import fonts.Fonts;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class CircleMapping extends Sprite
	{
		
		private var center:Handle;
		private var rPoints:Vector.<Handle>; //4 radius point clockwise, each 90°
		private var squarePoints:Vector.<Point>;
		
		[Embed(source="calib.jpg")]
		public static var CALIB_BM:Class;
		private var calibBM:Bitmap;
		private var calibD:DistortableSprite;
		
		[Embed(source="calib_uv.jpg")]
		public static var UV_BM:Class;
		private var uvBM:Bitmap;
		private var uvD:DistortableSprite;
		
		
		//control
		private var elevation:Number; //just for feedback, used for persp calculation but the value doesn't matter
		private var _extendFactor:Number;
		
		
		public function CircleMapping():void
		{
			StageUtil.init(stage);
			StageUtil.setNoScale();
			
			Shortcutter.init(stage);
			Shortcutter.add(this);
			
			DistortManager.init();
			
			uvBM = new UV_BM() as Bitmap;
			uvD = DistortManager.addSurface("uv", uvBM);
			uvD.smooth = true;
			addChild(uvD);
			uvD.visible = false;
			//uvD.alpha = .3;
			
			calibBM = new CALIB_BM() as Bitmap;
			//calibBM.smoothing = true;
			calibD = DistortManager.addSurface("calib", calibBM);
			calibD.smooth = true;
			addChild(calibD);
			calibD.alpha = .5;
			
			//var d1:Number = Point.distance(new Point(), new Point(uvBM.width, uvBM.height));
			//var d2:Number = Point.distance(new Point(), new Point(calibBM.width, calibBM.height));
			//extendFactor = (d1 / d2)*(2/3);
			extendFactor = 1.2;
			
			elevation = 1; //arbitratry
			
			//Lucie je t'aime
			
			
			center = new Handle();
			center.x = stage.stageWidth / 2;
			center.y = stage.stageHeight / 2;
			addChild(center);
			
			rPoints = new Vector.<Handle>();
			squarePoints = new Vector.<Point>();
			
			for (var i:int = 0; i < 4; i++)
			{
				rPoints.push(new Handle());
				var angle:Number =(-(i / 4) * Math.PI * 2 * 3)+Math.PI;
				rPoints[i].x = center.x + Math.cos(angle) * 50 + (Math.random() - .5) * 10;
				rPoints[i].y = center.y + Math.sin(angle) * 50 + (Math.random() - .5) * 10;
				addChild(rPoints[i]);
				
				squarePoints.push(new Point());
			}
			
			addEventListener(HandleEvent.DRAGGING, handleDragging);
			addEventListener(HandleEvent.DRAG_FINISH, handleDragFinish);
			addEventListener(Event.ENTER_FRAME, enterFrame);
			
			ajdustHandleFromSource(rPoints[0]);
			ajdustHandleFromSource(rPoints[1]);
			
			Fonts.init();
			var tf:TextField = Fonts.createTF("Key shortcuts :\nE : toggle extended surface\n+ / - : change extend factor",Fonts.normalTF);
			addChild(tf);
			tf.x = 10;
			tf.y = 10;
		}
		
		private function handleDragFinish(e:HandleEvent):void
		{
			graphics.clear();
			for each (var h:Handle in rPoints)
				h.slave = false;
		}
		
		private function handleDragging(e:HandleEvent):void
		{
			
			//trace("dragging !");			
			this.ajdustHandleFromSource(e.target as Handle);
			//if (sourceHandle == center) return;
		
			//var targetHandle:Handle = 
		}
		
		private function ajdustHandleFromSource(source:Handle):void
		{
			if (source == center)
			{
				ajdustHandleFromSource(rPoints[0]);
				ajdustHandleFromSource(rPoints[1]);
				return;
			}
			;
			
			var target:Handle = getTargetHandleFromSource(source);
			
			var sAngle:Number = Math.atan2(source.y - center.y, source.x - center.x);
			var invAngle:Number = sAngle + Math.PI;
			var dDist:Number = Point.distance(new Point(target.x, target.y), new Point(center.x, center.y));
			
			target.x = center.x + Math.cos(invAngle) * dDist;
			target.y = center.y + Math.sin(invAngle) * dDist;
		
		}
		
		private function getTargetHandleFromSource(sourceHandle:Handle):Handle
		{
			return rPoints[(rPoints.indexOf(sourceHandle) + 2) % rPoints.length];
		}
		
		private function enterFrame(e:Event):void
		{
			if (rPoints[0].x == rPoints[2].x || rPoints[0].y == rPoints[2].y)
				return;
			if (rPoints[1].x == rPoints[3].x || rPoints[1].y == rPoints[3].y)
				return;
			
			graphics.clear();
			
			var h1:Point = getHorizon(rPoints[0], rPoints[2]);
			var h2:Point = getHorizon(rPoints[1], rPoints[3]);
			
			if (h1 == null || h2 == null)
				return;
			
			computeSquarePoints(h1, h2);
			
			extendSurface(h1,h2,extendFactor); //factor, arbitraty;
		}
		
		private function getHorizon(p1:Handle, p2:Handle):Point
		{
			var p1p:Point = new Point(p1.x, p1.y);
			var p2p:Point = new Point(p2.x, p2.y);
			var cp:Point = new Point(center.x, center.y);
			
			
			graphics.lineStyle(1, 0x888888);
			graphics.moveTo(p1.x, p1.y);
			graphics.lineTo(p2.x, p2.y);
			
			var up1:Point = new Point(p1.x, p1.y - elevation);
			graphics.moveTo(p1.x, p1.y);
			graphics.lineTo(up1.x, up1.y);
			
			graphics.moveTo(up1.x, up1.y);
			graphics.lineTo(p2.x, p2.y);
			
			var centerUp:Point = new Point(center.x, center.y - elevation);
			var centerMid:Point = findIntersection(up1, p2p, cp, centerUp);
			graphics.moveTo(center.x, center.y);
			graphics.lineTo(centerMid.x, centerMid.y);
			
			var up1Mid:Point = new Point(p1.x, p1.y - elevation / 2);
			var horizon:Point = findIntersection(up1Mid, centerMid, p1p, p2p);
			
			if (horizon == null)
				return null;
			
			graphics.moveTo(up1Mid.x,up1Mid.y);
			graphics.lineTo(horizon.x, horizon.y);
			
			graphics.lineStyle(1, 0x8888ee);
			graphics.moveTo(p1.x, p1.y);
			graphics.lineTo(horizon.x, horizon.y);
			
			return horizon;
		}
		
		private function computeSquarePoints(h1:Point, h2:Point):void
		{
			var p1p:Point = new Point(rPoints[0].x, rPoints[0].y);
			var p2p:Point = new Point(rPoints[1].x, rPoints[1].y);
			var p3p:Point = new Point(rPoints[2].x, rPoints[2].y);
			var p4p:Point = new Point(rPoints[3].x, rPoints[3].y);
			
			var i1:Point = findIntersection(h1, p2p, h2, p1p);
			var i2:Point = findIntersection(h1, p2p, h2, p3p);
			var i3:Point = findIntersection(h1, p4p, h2, p1p);
			var i4:Point = findIntersection(h1, p4p, h2, p3p);
			
			graphics.lineStyle(1, 0xaaaaaa);
			graphics.moveTo(i1.x, i1.y);
			graphics.lineTo(i2.x, i2.y);
			graphics.lineTo(i4.x, i4.y);
			graphics.lineTo(i3.x, i3.y);
			graphics.lineTo(i1.x, i1.y);
			
			calibD.handlerTL.x = i1.x;
			calibD.handlerTL.y = i1.y;
			
			calibD.handlerTR.x = i2.x;
			calibD.handlerTR.y = i2.y;
			
			calibD.handlerBL.x = i3.x;
			calibD.handlerBL.y = i3.y;
			
			calibD.handlerBR.x = i4.x;
			calibD.handlerBR.y = i4.y;
			
			squarePoints[0] = i1;
			squarePoints[1] = i2;
			squarePoints[2] = i3;
			squarePoints[3] = i4;
		}
		
		
		private function extendSurface(h1:Point, h2:Point, factor:Number = 2):void //factor is multiplicator to extend surface from diagonals length
			
		{
			
			var s1p:Point = new Point(squarePoints[0].x, squarePoints[0].y);
			var s2p:Point = new Point(squarePoints[1].x, squarePoints[1].y);
			var s3p:Point = new Point(squarePoints[2].x, squarePoints[2].y);
			var s4p:Point = new Point(squarePoints[3].x, squarePoints[3].y);
			
			
			var up2:Point = new Point(s2p.x, s2p.y - elevation);
			var up3:Point = new Point(s3p.x, s3p.y - elevation);
			var up4:Point = new Point(s4p.x, s4p.y - elevation);
			
			
			var diagH14:Point = findIntersection(h1, h2, s1p, s4p);
			var diagH23:Point = findIntersection(h1, h2, s2p, s3p);
			
			var ext1:Point = getExtPoint(s1p, s4p, diagH14,factor);
			var ext4:Point = getExtPoint(s4p, s1p, diagH14,factor);
			var ext2:Point = getExtPoint(s2p, s3p, diagH23,factor);
			var ext3:Point = getExtPoint(s3p, s2p, diagH23,factor);
			
			
			graphics.beginFill(0x55aa55);
			graphics.drawCircle(ext1.x, ext1.y, 5);
			graphics.drawCircle(ext2.x, ext2.y, 5);
			graphics.drawCircle(ext3.x, ext3.y, 5);
			graphics.drawCircle(ext4.x, ext4.y, 5);
			graphics.endFill();
			
			uvD.handlerTL.x = ext4.x;
			uvD.handlerTL.y = ext4.y;
			uvD.handlerTR.x = ext3.x;
			uvD.handlerTR.y = ext3.y;
			uvD.handlerBL.x = ext2.x;
			uvD.handlerBL.y = ext2.y;
			uvD.handlerBR.x = ext1.x;
			uvD.handlerBR.y = ext1.y;
			
			
		}
		
		private function getExtPoint(p1:Point, p2:Point, diagH:Point,factor:Number):Point //2 points, opposites
		{
			var up1:Point = new Point(p1.x, p1.y - elevation);
			var fElevation:Number = Math.max(elevation * (1 - (1 / factor)), 0);
			var up1Mid:Point = new Point(p1.x, p1.y - fElevation);
			var up2:Point = new Point(p2.x, p2.y - elevation);
			
			var p2PerspMid:Point = findIntersection(up1Mid, diagH, p2, up2);
			var ext:Point = findIntersection(up1, p2PerspMid, p1, p2);
			
			return ext;
		}
		
		
		[Shortcut(key="e")]
		public function toggleExtent():void
		{
			uvD.visible = !uvD.visible;
		}
		
		
		
		//utils
		
		public function findIntersection(A:Point, B:Point, E:Point, F:Point, as_seg:Boolean = false):Point
		{
			var ip:Point;
			var a1:Number;
			var a2:Number;
			var b1:Number;
			var b2:Number;
			var c1:Number;
			var c2:Number;
			
			a1 = B.y - A.y;
			b1 = A.x - B.x;
			c1 = B.x * A.y - A.x * B.y;
			a2 = F.y - E.y;
			b2 = E.x - F.x;
			c2 = F.x * E.y - E.x * F.y;
			
			var denom:Number = a1 * b2 - a2 * b1;
			if (denom == 0)
			{
				return null;
			}
			ip = new Point();
			ip.x = (b1 * c2 - b2 * c1) / denom;
			ip.y = (a2 * c1 - a1 * c2) / denom;
			
			//---------------------------------------------------
			//Do checks to see if intersection to endpoints
			//distance is longer than actual Segments.
			//Return null if it is with any.
			//---------------------------------------------------
			if (as_seg)
			{
				if (Math.pow(ip.x - B.x, 2) + Math.pow(ip.y - B.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
					return null;
				}
				if (Math.pow(ip.x - A.x, 2) + Math.pow(ip.y - A.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
					return null;
				}
				
				if (Math.pow(ip.x - F.x, 2) + Math.pow(ip.y - F.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
					return null;
				}
				if (Math.pow(ip.x - E.x, 2) + Math.pow(ip.y - E.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
					return null;
				}
			}
			return ip;
		}
		
		
		//Getter Setter
		
		public function get extendFactor():Number 
		{
			return _extendFactor;
		}
		
		[Shortcut(key="+",value="0.01")]
		[Shortcut(key="-",value="-0.01")]
		public function set extendFactor(value:Number):void 
		{
			value = Math.max(value, 1);
			_extendFactor = value;
		}
	
	}

}
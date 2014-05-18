package  
{
	import benkuper.metadata.Shortcutter;
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.net.URLRequest;
	import net.hires.debug.Stats;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class DistortManagerExample extends Sprite 
	{
		private var sD:DistortableSprite;
		private var s:Sprite;
		private var loader:Loader;
		private var ball:Sprite;
		
		public function DistortManagerExample() 
		{
			stage.nativeWindow.x = 0;
			stage.nativeWindow.y = 0;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			DistortManager.init("datas/surfaces_test.xml");
			
			Shortcutter.init(stage);
			Shortcutter.add(DistortManager);
			Shortcutter.add(this);
			
			loader = new Loader();
			loader.load(new URLRequest("image.jpg"));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderComplete);
			
			s = new Sprite();
			s.graphics.beginFill(0xff3548);
			s.graphics.drawRect(0, 0, 1200, 600);
			s.graphics.endFill();
			
			ball = new Sprite();
			ball.graphics.beginFill(0xff6321);
			ball.graphics.drawCircle(0, 0,  60);
			ball.graphics.endFill();
			ball.y = 100;
			ball.x = 100;
			
			addChild(new Stats());
		}
		
		
		private function loaderComplete(e:Event):void 
		{
			s.addChild(Bitmap(loader.content));
			s.addChild(ball);
			TweenMax.to(ball, 1, { x:s.width, yoyo:true, repeat: -1 } );
			
			for (var i:int = 0; i < 1; i++)
			{
				sD = DistortManager.addSurface("spriteTest", s, s.width);
				Shortcutter.add(sD);
				addChild(sD);
			}
		}
		
	}

}
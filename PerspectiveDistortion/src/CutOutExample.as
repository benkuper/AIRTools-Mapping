package  
{
	import benkuper.metadata.Shortcutter;
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class CutOutExample extends Sprite 
	{		
		private var cS:CutoutSprite;
		private var loader:Loader;
		private var sprite:Sprite;
		public function CutOutExample() 
		{
			
			Shortcutter.init(stage);
			
			stage.nativeWindow.x = 0;
			stage.nativeWindow.y = 0;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			loader = new Loader();
			loader.load(new URLRequest("rocher.png"));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderComplete);
			
			
		}
		
		private function loaderComplete(e:Event):void 
		{
			sprite = new Sprite();
			sprite.addChild(Bitmap(loader.content));
			
			cS = new CutoutSprite(sprite);
			cS.showOriginal = true;
			
			addChild(cS);
			
			Shortcutter.add(cS);
		}
		
	}

}
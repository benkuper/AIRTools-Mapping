package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	import org.tuio.connectors.UDPConnector;
	import org.tuio.debug.TuioDebug;
	import org.tuio.TuioClient;
	import org.tuio.TuioManager;
	import org.tuio.TuioTouchEvent;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class Main extends Sprite 
	{
		private var barSprite:DistortableSprite;
		private var montantSprite:DistortableSprite
		private var facadeSprite:DistortableSprite;
		private var xmlSurface:XML;
		
		private var tManager:TuioManager;
		private var tClient:TuioClient;
		
		public function Main():void 
		{
			
			barSprite = new DistortableSprite(2000, 380);
			addChild(barSprite);
			
			barSprite.originalSprite = new Bar();
			barSprite.originalSprite.addEventListener(ParticleEvent.PARTICLE_EXIT, barParticleExit);
			
			montantSprite = new DistortableSprite(60,400);
			addChild(montantSprite);
			
			montantSprite.originalSprite = new Montant();
			montantSprite.originalSprite.addEventListener(ParticleEvent.PARTICLE_EXIT, montantParticleExit);

			
			facadeSprite = new DistortableSprite(1100,210);
			addChild(facadeSprite);
			
			facadeSprite.originalSprite = new Facade();
			
			
			var surfaceLoader:URLLoader = new URLLoader();
			surfaceLoader.addEventListener(Event.COMPLETE, surfaceLoaderComplete);
			surfaceLoader.load(new URLRequest("datas/surfaces.xml"));
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			
			stage.nativeWindow.x = Screen.screens[1 % Screen.screens.length].bounds.x +100;
			stage.nativeWindow.y = Screen.screens[1 % Screen.screens.length].bounds.y;
			
			
			tClient = new TuioClient(new UDPConnector("127.0.0.1", 3333));
			
			tManager = TuioManager.init(stage,barSprite.originalSprite);
			tClient.addListener(tManager);
			tManager.dispatchMouseEvents = true;
			
			stage.addEventListener(TuioTouchEvent.TOUCH_DOWN, touchDownHandler);
		}
		
		
		
		private function barParticleExit(e:ParticleEvent):void 
		{
			Montant(montantSprite.originalSprite).addParticle(e.particle);
		}
		
		private function montantParticleExit(e:ParticleEvent):void 
		{
			Facade(facadeSprite.originalSprite).addParticle(e.particle);
		}
		
		private function touchDownHandler(e:TuioTouchEvent):void 
		{
			trace("touchDown !");
		}
		
		private function keyDownHandler(e:KeyboardEvent):void 
		{
			switch(e.keyCode)
			{
				case Keyboard.S:
					saveSurfacesConfig();
				break;
			}
		}
		
		private function saveSurfacesConfig():void 
		{
			var surfaces:Array = [ "bar", "montant", "facade" ];
			var sprites:Array = [barSprite, montantSprite, facadeSprite];
			
			trace("test :"+xmlSurface.surfaces.surface.(@id == "bar").point[0].@x);
			for (var i:int = 0; i < surfaces.length; i++)
			{
				
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[0].@x = sprites[i].handlerTL.x;
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[0].@y = sprites[i].handlerTL.y;
				
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[1].@x = sprites[i].handlerTR.x;
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[1].@y = sprites[i].handlerTR.y;
				
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[2].@x = sprites[i].handlerBL.x;
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[2].@y = sprites[i].handlerBL.y;
				
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[3].@x = sprites[i].handlerBR.x;
				xmlSurface.surfaces.surface.(@id == surfaces[i]).point[3].@y = sprites[i].handlerBR.y;
				
			}
			
			var fs:FileStream = new FileStream();
			fs.open(File.desktopDirectory.resolvePath(File.applicationDirectory.resolvePath("datas/surfaces.xml").nativePath), FileMode.WRITE);
			fs.writeUTFBytes(xmlSurface.toXMLString());
			fs.close();
			trace("File Saved !");
			//trace(xmlSurface.toXMLString());
		}
		
		private function surfaceLoaderComplete(e:Event):void 
		{
			xmlSurface = new XML(e.target.data);
			//trace(xmlSurface.surfaces.surface.(@id == "bar").children());
			barSprite.setHandlers(xmlSurface.surfaces.surface.(@id == "bar").children());
			montantSprite.setHandlers(xmlSurface.surfaces.surface.(@id == "montant").children());
			facadeSprite.setHandlers(xmlSurface.surfaces.surface.(@id == "facade").children());
			
		}
		
	}
	
}
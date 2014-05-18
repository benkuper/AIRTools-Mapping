package  
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class DistortManager extends EventDispatcher
	{
		
		public static var surfaces:Vector.<DistortableSprite>;
		public static var xmlSurfaces:XML;
		
		public static var filePath:String;
		
		public static var instance:DistortManager;
		static private var surfaceLoader:URLLoader;
		
		public function DistortManager() 
		{
			
		}
		
		public static function init(xmlPath:String = "data/surfaces.xml"):void
		{
			if (instance != null) return;
			
			instance = new DistortManager();
			
			filePath = xmlPath;
			
			surfaceLoader = new URLLoader();
			surfaceLoader.addEventListener(Event.COMPLETE, surfaceLoaderComplete);
			surfaceLoader.addEventListener(IOErrorEvent.IO_ERROR , loaderError);
			
			surfaces = new Vector.<DistortableSprite>;
			
			loadSurfaces();
			
		}
		
		[Shortcut (key="l")]
		static public function loadSurfaces():void
		{
			surfaceLoader.load(new URLRequest(filePath));
			
			xmlSurfaces = new XML(<data><surfaces></surfaces></data>);
		}
		
		static private function loaderError(e:IOErrorEvent):void 
		{
			trace("load Error on " + filePath);
			xmlSurfaces = new XML();
			saveSurfaceConfig();
			loadSurfaces();
		}
		
		public static function surfaceLoaderComplete(e:Event):void 
		{
			
			xmlSurfaces = new XML(e.target.data);
			var xmlSurfacesChildren:XMLList = xmlSurfaces.surfaces.children();
			var numChildren:int = xmlSurfacesChildren.length();
			
			trace("surface Load Complete :: numChildren :",numChildren);
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var targetSurface:DistortableSprite = getSurfaceByID(xmlSurfacesChildren[i].@id);
				if (targetSurface != null)
				{
					targetSurface.setHandlers(xmlSurfacesChildren[i].children());
				}
			}	
			
			instance.dispatchEvent(new DistortEvent(DistortEvent.SURFACES_LOADED));
			
		}
		
		
		public static function addSurface(id:String, originalSprite:DisplayObject, originalWidth:Number = 0, originalHeight:Number = 0):DistortableSprite
		{
			if (originalWidth == 0) originalWidth = originalSprite.width;
			if (originalHeight == 0) originalHeight = originalSprite.height;
			
			var distortedSprite:DistortableSprite = new DistortableSprite(id);
			
			distortedSprite.originalSprite = originalSprite;
			if (originalWidth > 0 && originalHeight > 0)
			{
				distortedSprite.setOriginalSize(originalWidth, originalHeight);
			}
			
			surfaces.push(distortedSprite);
			
			if (xmlSurfaces.surface != null)
			{
				trace(xmlSurfaces.surfaces.surface.(@id == id));
				if (xmlSurfaces.surfaces.surface.(@id == id).length() > 0)
				{
					trace("surface exists !");
					distortedSprite.setHandlers(xmlSurfaces.surfaces.surface.(@id == id).children());
				}
			}
			
			return distortedSprite;
		}
		
		
		[Shortcut (key = "h")]
		public static function toggleHandlers():void
		{
			for (var i:int = 0; i < surfaces.length; i++)
			{
				surfaces[i].showHandlers = !surfaces[i].showHandlers;
			}
		}
		
		[Shortcut (key="g")]
		public static function toggleGrids():void
		{
			for (var i:int = 0; i < surfaces.length; i++)
			{
				surfaces[i].showGrid = !surfaces[i].showGrid;
			}
		}
		
		static private function getSurfaceByID(id:String):DistortableSprite
		{
			for (var i:int = 0; i < surfaces.length; i++)
			{
				if (surfaces[i].id == id) return surfaces[i];
			}
			
			return null;
		}
		
		[Shortcut (key = "s")]
		public static function saveSurfaceConfig():void
		{
			var xmlString:String = "";
			
			trace("DistorManager :: Save ", surfaces.length,"surfaces");
			for (var i:int = 0; i < surfaces.length; i++)
			{
				xmlString += surfaces[i].getXMLString();
			}
			
			
			xmlSurfaces = new XML("<data><surfaces>"+xmlString+"</surfaces></data>");
			
			
			var fs:FileStream = new FileStream();
			fs.open(File.desktopDirectory.resolvePath(File.applicationDirectory.resolvePath(filePath).nativePath), FileMode.WRITE);
			fs.writeUTFBytes(xmlSurfaces.toXMLString());
			fs.close();
			
			trace("DistortManager :: Surface config file saved !");
		}
	}

}
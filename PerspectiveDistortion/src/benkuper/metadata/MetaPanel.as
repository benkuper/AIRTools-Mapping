package  benkuper.metadata
{
	import benkuper.metadata.components.MetaWindow;
	import com.bit101.components.Component;
	import com.bit101.components.HUISlider;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.bit101.components.Slider2D;
	import com.bit101.components.Text;
	import com.bit101.components.UISlider;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class MetaPanel extends Sprite 
	{
		public var windows:Vector.<MetaWindow>;
		
		public function MetaPanel() 
		{
			windows = new Vector.<MetaWindow>;
		}
		
		public function add(target:Object,windowTitle:String = "MetaPanel",windowWidth:Number = 200,windowHeight:Number = 200):void
		{
			
			if (getWindowForTarget(target) != null)
			{
				trace("2:Object " + target + " already added");
				return;
			}
			
			var window:MetaWindow = new MetaWindow(target,this, this.width,0,windowTitle);
			window.width = windowWidth;
			window.height = windowHeight;
			var mds:XMLList = describeType(target)..metadata.(@name == "Control");
			
			
			var componentPos:Point = new Point();
			
			for each(var md:XML in mds)
			{
				var item:XML = md.parent();	
				
				var itemType:String = item.name();
				var prop:String = item.@name;
				
				
				
				
				var controlType:String = getMDArg(md, "type");
				var controlLabel:String = getMDArg(md, "label");
				
				if (controlLabel == "") controlLabel = prop;
				
				
				
				switch(itemType)
				{
					
					case "accessor":
						trace("accessor !");
						
					case "variable":
						trace("process variable :", itemClass, prop);
						
						var itemClass:Class = getDefinitionByName(item.@type) as Class
						
						switch(itemClass)
						{
							case Boolean:
								
								var button:PushButton = new PushButton(window, componentPos.x, componentPos.y, controlLabel, variableHandler);
								button.targetProp = prop;
								button.toggle = true;
								break;
								
							case int:
							case Number:
								
								switch(controlType)
								{
									case "stepper":
										var stepper:NumericStepper = new NumericStepper(window, componentPos.x, componentPos.y, variableHandler);
										stepper.targetProp = prop;
										stepper.minimum = getMDArg(md, "min");
										stepper.maximum = getMDArg(md, "max");
										break;
										
										
									case "slider":
									default:
										var slider:HUISlider = new HUISlider(window, componentPos.x, componentPos.y, controlLabel, variableHandler);
										slider.targetProp = prop;
										var minArg:String = getMDArg(md, "min");
										var maxArg:String = getMDArg(md, "max");
										
										
										
										slider.minimum = (minArg != "")?Number(minArg):0;
										slider.maximum = (maxArg != "")?Number(maxArg):100;
										
										if (itemClass == int) slider.tick = 1;
										break;
								}
								
								break;
								
							case String:
								var input:Text = new Text(window, componentPos.x, componentPos.y, controlLabel);
								input.targetProp = prop;
								input.text = String(target[prop]);
								input.addEventListener(Event.CHANGE, variableHandler);
								
								var argHeight:String = getMDArg(md, "height");
								var argWidth:String = getMDArg(md, "width");
								input.height = (argWidth != "")?Number(argWidth):100;
								input.height = (argHeight != "")?Number(argHeight):20;
								break;
								
							case Point:
								var slider2D:Slider2D = new Slider2D(window, componentPos.x, componentPos.y, variableHandler);
								slider2D.targetProp = prop;
								componentPos.y += 100;
								window.height += 100;
								break;
						}
						
						break;
						
					case "method":
						var methodButton:PushButton = new PushButton(window, componentPos.x, componentPos.y, controlLabel, methodHandler);
						methodButton.targetProp = prop;
						break;
				}
				
				componentPos.y += 30;
			}
			
			windows.push(window);
			
		}
		
		public function variableHandler(e:Event):void 
		{
			var targetComponent:Component = e.currentTarget as Component;
			var targetWindow:MetaWindow = getWindowForComponent(targetComponent);
			
			
			if (targetComponent is PushButton)
			{
				targetWindow.target[targetComponent.targetProp] = (targetComponent as PushButton).selected;
			}else if (targetComponent is UISlider)
			{
				targetWindow.target[targetComponent.targetProp] = (targetComponent as UISlider).value;
			}else if (targetComponent is Text)
			{
				trace("update Text !");
				targetWindow.target[targetComponent.targetProp] = (targetComponent as Text).text;
			}else if (targetComponent is Slider2D)
			{
				var point:Point = targetWindow.target[targetComponent.targetProp] as Point;
				point.x = (targetComponent as Slider2D).valueX;
				point.y = (targetComponent as Slider2D).valueY;
			}else if (targetComponent is NumericStepper)
			{
				targetWindow.target[targetComponent.targetProp]  = (targetComponent as NumericStepper).value;
			}
		}
		
		public function methodHandler(e:Event):void
		{
			var targetComponent:Component = e.currentTarget as Component;
			var targetWindow:MetaWindow = getWindowForComponent(targetComponent);
			
			targetWindow.target[targetComponent.targetProp]();
		}
		
		private function getWindowForComponent(targetComponent:Component):MetaWindow
		{
			for each(var window:MetaWindow in windows)
			{
				if (window.contains(targetComponent)) return window;
			}
			
			return null;
		}
		
		private function getWindowForTarget(target:Object):MetaWindow
		{
			for each(var window:MetaWindow in windows)
			{
				if (window.target == target) return window;
			}
			
			return null;
		}
		
		public function getMDArg(metaData:XML, key:String):*
		{
			return metaData.arg.(@key == key).@value;
		}
		
	}

}
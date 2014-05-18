package  
{
	import benkuper.metadata.Shortcutter;
	import com.adobe.utils.AGALMiniAssembler;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Ben Kuper
	 */
	public class DistortManagerExampleGL extends Sprite 
	{
		private var sD:DistortableSprite;
		private var s:Sprite;
		private var loader:Loader;
		private var context:Context3D;
		
		//Stage3D
		private var vertexBuffer:VertexBuffer3D;
		private var indexBuffer:IndexBuffer3D;
		private var uvBuffer:VertexBuffer3D;
		
		private var program:Program3D;
		private var vertexShader:ByteArray;
		private var fragmentShader:ByteArray;
		private var texture:Texture;
		
		
		public function DistortManagerExampleGL() 
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
			loader.load(new URLRequest("image_too_big.jpg"));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderComplete);
			
			s = new Sprite();
			s.graphics.beginFill(0xff3548);
			s.graphics.drawRect(0, 0, 1200, 600);
			s.graphics.endFill();
			
			
			//Stage3D Handling
			trace(stage.stage3Ds.length);
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, contextCreateHandler);
			stage.stage3Ds[0].requestContext3D();
		}
		
		private function loaderComplete(e:Event):void 
		{
			sD = DistortManager.addSurface("spriteTest", Bitmap(loader.content));
			Shortcutter.add(sD);
			//sD.alpha = .3;
			
			addChild(sD);
			
		}
		
		
		
		
		
		
		//STAGE 3D
		
		/**
		 * Create and upload the texture
		 */
		private function __createAndUploadTexture():void {
			
			if (loader.width == 0 || loader.height == 0) return;
			
			if (!texture) {
				texture = context.createTexture(2048,2048, Context3DTextureFormat.BGRA, false);
			}
			
			
			
			texture.uploadFromBitmapData(sD.bmd);
			
			/*// MIPMAP GENERATION
			var bmd:BitmapData = text.bitmapData;
			var s:int = bmd.width;
			var miplevel:int = 0;
			while (s > 0) {
				texture.uploadFromBitmapData(getResizedBitmapData(bmd, s, s, true, (miplevel != 0 && _mipmapColor.selected) ? Math.random()*0xFFFFFF:0), miplevel);
				miplevel++;
				s = s * .5;
			}
			*/
			
			context.setTextureAt(0, texture);
		}
		
		private function contextCreateHandler(event:Event):void {
			// // // CREATE CONTEXT // //
			context = stage.stage3Ds[0].context3D;
			
			// By enabling the Error reporting, you can get some valuable information about errors in your shaders
			// But it also dramatically slows down your program.
			// context.enableErrorChecking=true;
			
			// Configure the back buffer, in width and height. You can also specify the antialiasing
			// The backbuffer is the memory space where your final image is rendered.
			context.configureBackBuffer(stage.stageWidth,stage.stageHeight, 4, false);
			
			
			// Allocation - program compilation
			__createBuffers();
			__createAndCompileProgram();
			
			// Upload program and buffers data
			__uploadProgram();
			__uploadBuffers();
			
			// Split chunk of data and set active program
			__splitAndMakeChunkOfDataAvailableToProgram();
			__setActiveProgram();
			
			// start the rendering loop
			addEventListener(Event.ENTER_FRAME, render);
		}
		
		/**
		 * Create the vertex and index buffers
		 */
		private function __createBuffers():void {
			// // // CREATE BUFFERS // //
			vertexBuffer = context.createVertexBuffer(4, 3);
			uvBuffer = context.createVertexBuffer(4, 2);
			
			indexBuffer = context.createIndexBuffer(6);
			
		}

		/**
		 * Upload some data to the vertex and index buffers
		 */
		private function __uploadBuffers():void {
			
			if (sD == null) return;
			//trace("upload Buffer ", (sD.handlerTL.x / stage.stageWidth) - .5);
			var vertexData:Vector.<Number> = sD.getXYZData();
			
			if (vertexData == null) return;
			
			//var uvData:Vector.<Number> = sD.getUVData();
			//if (uvData == null) return;

			//debug uvData
			var uvData:Vector.<Number> = Vector.<Number>([0, 0, 1.2, 0, 0, 1, 1, 1]);
			vertexBuffer.uploadFromVector(vertexData, 0, 4);
			indexBuffer.uploadFromVector(Vector.<uint>([0,1,2, 1,3,2]), 0, 6);
			uvBuffer.uploadFromVector(uvData, 0, 4);
		}
		
		/**
		 * Define how each Chunck of Data should be split and upload to fast access register for our AGAL program
		 * 
		 * @see __createAndCompileProgram
		 */
		private function __splitAndMakeChunkOfDataAvailableToProgram():void {
			// So here, basically, your telling your GPU that for each Vertex with a vertex being x,y,y,r,g,b
			// you will copy in register "0", from the buffer "vertexBuffer, starting from the postion "0" the FLOAT_3 next number
			context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // register "0" now contains x,y,z
			
			// Here, you will copy in register "1" from "vertexBuffer", starting from index "3", the next FLOAT_3 numbers
			context.setVertexBufferAt(1, uvBuffer,0, Context3DVertexBufferFormat.FLOAT_2); // register 1 now contains r,g,b
		}

		/**
		 * Create the program that will run in your GPU.
		 */
		private function __createAndCompileProgram() : void {
			// // // CREATE SHADER PROGRAM // //
			// When you call the createProgram method you are actually allocating some V-Ram space
			// for your shader program.
			program = context.createProgram();
			
			// Create an AGALMiniAssembler.
			// The MiniAssembler is an Adobe tool that uses a simple
			// Assembly-like language to write and compile your shader into bytecode
			var assembler:AGALMiniAssembler = new AGALMiniAssembler();
			
			// VERTEX SHADER
			var code:String = "";
			code += "mov op, va0\n"; // Move the Vertex Attribute 0 (va0), which is our Vertex Coordinate, to the Output Point
			code += "mov v0, va1\n"; // Move the Vertex Attribute 1 (va1), which is our Vertex Color, to the variable register v0
									 // Variable register are memory space shared between your Vertex Shader and your Fragment Shader
			
			// Compile our AGAL Code into ByteCode using the MiniAssembler 
			vertexShader = assembler.assemble(Context3DProgramType.VERTEX, code);
			
			
			//FRAGMENT SHADER
			var textOptions:String = "";
			
			//no mipmap for now
			//if (_useMipMap) {
				//textOptions = "<2d,linear, miplinear, repeat>";
			//} else {
				//textOptions = "<2d,linear, nomip, repeat>";
			//}
			
			textOptions = "<2d,linear, nomip, repeat>";
			code =  "text ft0 v0, fs0 " + textOptions + "\n";	// sample the texture (fs0) at the interpolated UV coordinates (v0) and put the color into ft0
			code += "mov oc, ft0\n"; // Move the Variable register 0 (v0) where we copied our Vertex Color, to the output color
			
			// Compile our AGAL Code into Bytecode using the MiniAssembler
			fragmentShader = assembler.assemble(Context3DProgramType.FRAGMENT, code);
		}
		
		/**
		 * Upload our two compiled shaders into the graphic card.
		 */
		private function __uploadProgram():void {
			// UPLOAD TO GPU PROGRAM
			program.upload(vertexShader, fragmentShader); // Upload the combined program to the video Ram
		}
		
		/**
		 * Define the active program to run on our GPU
		 */
		private function __setActiveProgram():void {
			// Set our program as the current active one
			context.setProgram(program);
		}

		/**
		 * Called each frame
		 * Render the scene
		 */
		private function render(event:Event):void {
			context.clear(1, 1, 1, 1); // Clear the backbuffer by filling it with the given color
			
			//realtime texture update
			__createAndUploadTexture();
			__uploadBuffers();
			
			
			context.drawTriangles(indexBuffer); // Draw the triangle according to the indexBuffer instructions into the backbuffer
			context.present(); // render the backbuffer on screen.
		}
	}

}
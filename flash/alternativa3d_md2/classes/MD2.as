package
{
	import alternativa.types.Point3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.geom.Point;

	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.WireMaterial;
	
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.types.Texture;

	/**
	* Alternativa3d compatible MD2 player.
	* 
	* @author Philippe Ajoux (philippe.ajoux@gmail.com)
	*/
	public class MD2 extends Mesh
	{
		/**
		* Creates MD2 player.
		*
		* @param name Mesh instance name.
		* @param data MD2 binary data.
		* @param scale Adjusts model scale.
		*/
		public function MD2 (name:String, data:ByteArray, scale:Number = 1 )
		{
			super (name); scaling = scale; generate (data); frame = 0;
		}

		/**
		 * @private Copy-pasted from Sandy :)
		 */
		public function generate (... arguments):void
		{
			var i:int, j:int;
			var uvs:Array = [], _faces:Array = [];

			// okay, let's read out header 1st
			var data:ByteArray = ByteArray (arguments [0]);
			data.endian = Endian.LITTLE_ENDIAN;

			ident = data.readInt();
			version = data.readInt();

			if (ident != 844121161 || version != 8)
				throw new Error("Error loading MD2 file: Not a valid MD2 file/bad version");

			skinwidth = data.readInt();
			skinheight = data.readInt();
			framesize = data.readInt();
			num_skins = data.readInt();
			num_vertices = data.readInt();
			num_st = data.readInt();
			num_tris = data.readInt();
			num_glcmds = data.readInt();
			num_frames = data.readInt();
			offset_skins = data.readInt();
			offset_st = data.readInt();
			offset_tris = data.readInt();
			offset_frames = data.readInt();
			offset_glcmds = data.readInt();
			offset_end = data.readInt();

			// Make vertices placeholders
			for (i = 0; i < num_vertices; i++)
				createVertex (0, 0, 0, i);

			// UV coordinates
			data.position = offset_st;
			for (i = 0; i < num_st; i++)
				uvs.push ({ u:data.readShort() / skinwidth, v:1-data.readShort() / skinheight });

			// Faces
			data.position = offset_tris;
			for (i = 0, j = 0; i < num_tris; i++, j+=3)
			{
				var a:int = data.readUnsignedShort();
				var b:int = data.readUnsignedShort();
				var c:int = data.readUnsignedShort();
				var ta:int = data.readUnsignedShort();
				var tb:int = data.readUnsignedShort();
				var tc:int = data.readUnsignedShort();

				var u0:Number = uvs [ta].u, v0:Number = uvs[ta].v;
				var u1:Number = uvs [tc].u, v1:Number = uvs[tc].v;
				var u2:Number = uvs [tb].u, v2:Number = uvs[tb].v;

				// we fix perpendicular projections here because the engine does not attempt to do so
				if( (u0 == u1 && v0 == v1) || (u0 == u2 && v0 == v2) )
				{
					u0 -= (u0 > 0.005)? 0.005 : -0.005;
					v0 -= (v0 > 0.007)? 0.007 : -0.007;
				}
				if( u2 == u1 && v2 == v1 )
				{
					u2 -= (u2 > 0.005)? 0.004 : -0.004;
					v2 -= (v2 > 0.006)? 0.006 : -0.006;
				}


				_faces.push (createFace ([a, c, b], i));
				setUVsToFace(new Point(/* a */ u0, v0), new Point(/* b */ u1, v1), new Point(/* c */ u2, v2), i);
			}

			// Default material (wireframe)
			createSurface(_faces, "md2"); setMaterialToSurface(new WireMaterial(1, 0xFF0000), "md2");

			// Frame animation data
			for (i = 0; i < num_frames; i++)
			{
				var sx:Number = data.readFloat();
				var sy:Number = data.readFloat();
				var sz:Number = data.readFloat();
				
				var tx:Number = data.readFloat();
				var ty:Number = data.readFloat();
				var tz:Number = data.readFloat();

				// store frame names as pointers to frame numbers
				var name:String = "", wasNotZero:Boolean = true;
				for (j = 0; j < 16; j++)
				{
					var char:int = data.readUnsignedByte ();
					wasNotZero &&= (char != 0);
					if (wasNotZero)
						name += String.fromCharCode (char);
				}
				frames [name] = i;

				// store vertices for every frame
				var vi:Array = []; vs [i] = vi;
				for (j = 0; j < num_vertices; j++)
				{
					var vec:Point3D = new Point3D;

					// order of assignment is important here because of data reads...
					vec.x = ((sx * data.readUnsignedByte()) + tx) * scaling;
					vec.y = ((sy * data.readUnsignedByte()) + ty) * scaling;
					vec.z = ((sz * data.readUnsignedByte()) + tz) * scaling;

					vi [j] = vec;

					// ignore "vertex normal index"
					data.readUnsignedByte ();
				}
			}

			return;
		}

		/**
		* Frames map. This maps frame names to frame numbers.
		*/
		public var frames:Array = [];

		/**
		* Frame number. You can tween this value to play MD2 animation.
		*/
		public function get frame ():Number { return t; }

		/**
		* @private (setter)
		*/
		public function set frame (value:Number):void
		{
			t = value;

			// interpolation frames
			var f1:Array = vs [int (t) % num_frames];
			var f2:Array = vs [(int (t) + 1) % num_frames];

			// interpolation coef-s
			var c2:Number = t - int (t), c1:Number = 1 - c2;

			// loop through vertices
			for (var i:int = 0; i < num_vertices; i++)
			{
				var v0:Vertex = Vertex (vertices [i]);
				var v1:Point3D = Point3D (f1 [i]);
				var v2:Point3D = Point3D (f2 [i]);

				// interpolate
				v0.x = v1.x * c1 + v2.x * c2;
				v0.y = v1.y * c1 + v2.y * c2;
				v0.z = v1.z * c1 + v2.z * c2;
			}
		}

		// animation "time" (frame number)
		private var t:Number;		

		// vertices list for every frame
		private var vs:Array = [];

		// original Philippe vars
		private var ident:int;
		private var version:int;
		private var skinwidth:int;
		private var skinheight:int;
		private var framesize:int;
		private var num_skins:int;
		private var num_vertices:int;
		private var num_st:int;
		private var num_tris:int;
		private var num_glcmds:int;
		private var num_frames:int;
		private var offset_skins:int;
		private var offset_st:int;
		private var offset_tris:int;
		private var offset_frames:int;
		private var offset_glcmds:int;
		private var offset_end:int;
		private var scaling:Number;


	}
}
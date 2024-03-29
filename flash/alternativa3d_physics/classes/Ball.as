﻿package  
{
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.physics.Collision;
	import alternativa.engine3d.physics.EllipsoidCollider;
	import alternativa.types.Point3D;
	import alternativa.types.Set;

	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Matrix;
	
	/**
	* Falling ball simulation.
	* @author makc
	*/
	public class Ball
	{
		private var _collider:EllipsoidCollider;
		public function set excludeSet (s:Set):void { _collider.collisionSet = s; }

		private var _collision:Collision;
		private var _doubleVelocityProjection:Point3D, _newPosition:Point3D;

		private var _radius:Number = 10;
		public function get radius ():Number { return _radius; }
		public function set radius (r:Number):void {
			_radius = r; _collider.radiusX = _collider.radiusY = _collider.radiusZ = r; _updateShape ();
		}

		public var damping:Number = 0.6;

		public var position:Point3D, velocity:Point3D, acceleration:Point3D;

		public function Ball (scene:Scene3D) 
		{
			_collider = new EllipsoidCollider (scene, 10, 10, 10);

			_collision = new Collision;
			_doubleVelocityProjection = new Point3D; _newPosition = new Point3D;

			position = new Point3D; velocity = new Point3D; acceleration = new Point3D;

			shape = new Shape; _texture = new _BallTexture; _matrix = new Matrix;
		}

		public function step ():void {
			// collide with other balls (TODO)


			// collide with scene
			velocity.add (acceleration);
			_collider.calculateDestination (position, velocity, _newPosition);
			if (_collider.getCollision (position, velocity, _collision)) {
				// deflect the speed
				_doubleVelocityProjection.copy (_collision.normal);
				_doubleVelocityProjection.multiply (2 * Point3D.dot (_doubleVelocityProjection, velocity));
				velocity.subtract (_doubleVelocityProjection);
				// slow down
				velocity.multiply (damping);
			}
			position.copy (_newPosition);
		}


		// the code below have nothing to do with physics

		public var shape:Shape;

		[Embed(source="ball.jpg")]
		private var _BallTexture:Class;

		private var _texture:Bitmap;
		private var _matrix:Matrix;

		private function _drawCircle (g:Graphics, x:Number, y:Number, r:Number):void { 
			// http://board.flashkit.com/board/showthread.php?t=369672
			g.moveTo(x+r, y); 
			g.curveTo(r+x,-0.4142*r+y,0.7071*r+x,-0.7071*r+y);
			g.curveTo(0.4142*r+x,-r+y,x,-r+y);
			g.curveTo(-0.4142*r+x,-r+y,-0.7071*r+x,-0.7071*r+y);
			g.curveTo(-r+x,-0.4142*r+y,-r+x, y);
			g.curveTo(-r+x,0.4142*r+y,-0.7071*r+x,0.7071*r+y);
			g.curveTo(-0.4142*r+x,r+y,x,r+y);
			g.curveTo(0.4142*r+x,r+y,0.7071*r+x,0.7071*r+y);
			g.curveTo(r+x,0.4142*r+y,r+x,y);
		}

		private function _updateShape ():void {
			_matrix.identity (); _matrix.translate ( -50, -50); _matrix.scale (radius / 50, radius / 50);
			shape.graphics.clear ();
			shape.graphics.beginBitmapFill (_texture.bitmapData, _matrix);
			_drawCircle (shape.graphics, 0, 0, radius);
			shape.graphics.endFill ();
		}
		
	}
	
}
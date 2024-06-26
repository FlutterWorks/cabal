part of '../physics.dart';

// TODO(johnmccutchan):
// - Implement missing native callbacks.
// - Expand exposed API.

enum MotionType {
  // Non movable.
  static,
  // Movable using velocities only, does not respond to forces.
  kinematic,
  // Responds to forces as a normal physics object.
  dynamic,
}

enum MotionQuality {
  // Update the body in discrete steps. Body will tunnel throuh thin objects if
  // its velocity is high enough. This is the cheapest way of simulating a body.
  discrete,
  // Update the body using linear casting.  When stepping the body, its
  // collision shape is cast from start to destination using the starting
  // rotation. The body will not be able to tunnel through thin objects at high
  // velocity, but tunneling is still possible if the body is long and thin and
  //has high angular velocity.
  linearCast,
}

class BodySettings {
  Shape shape;
  Vector3? position;
  Quaternion? rotation;
  MotionType motionType = MotionType.static;
  MotionQuality motionQuality = MotionQuality.discrete;

  BodySettings(this.shape);

  _copyToConfig(ffi.Pointer<jolt.BodyConfig> config) {
    config.ref.motion_type = motionType.index;
    config.ref.motion_quality = motionQuality.index;
    config.ref.shape = ffi.Pointer<jolt.CollisionShape>.fromAddress(
        shape._nativeShape.address);
    if (position != null) {
      config.ref.position[0] = position!.storage[0];
      config.ref.position[1] = position!.storage[1];
      config.ref.position[2] = position!.storage[2];
    } else {
      config.ref.position[0] = 0.0;
      config.ref.position[1] = 0.0;
      config.ref.position[2] = 0.0;
    }
    if (rotation != null) {
      config.ref.rotation[0] = rotation!.storage[0];
      config.ref.rotation[1] = rotation!.storage[1];
      config.ref.rotation[2] = rotation!.storage[2];
      config.ref.rotation[3] = rotation!.storage[3];
    } else {
      config.ref.rotation[0] = 0.0;
      config.ref.rotation[1] = 0.0;
      config.ref.rotation[2] = 0.0;
      config.ref.rotation[3] = 1.0;
    }
  }
}

class Body implements ffi.Finalizable {
  static final _finalizer =
      ffi.NativeFinalizer(jolt.bindings.addresses.destroy_body.cast());

  ffi.Pointer<jolt.WorldBody> _nativeBody;

  World _world;
  Shape _shape;
  MotionType _motionType = MotionType.static;
  MotionQuality _motionQuality = MotionQuality.discrete;

  final unwrappedPositionSetter = jolt.dylib.lookupFunction<
      ffi.Void Function(ffi.Pointer<jolt.WorldBody>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.WorldBody>,
          ffi.Pointer<ffi.Float>)>('body_set_position', isLeaf: true);

  set position(Vector3 position) {
    var p = calloc.call<ffi.Float>(3);
    p[0] = position.x;
    p[1] = position.y;
    p[2] = position.z;
    unwrappedPositionSetter(_nativeBody, p);
    calloc.free(p);
  }

  static final unwrappedPositionGetter = jolt.dylib.lookupFunction<
      ffi.Void Function(ffi.Pointer<jolt.WorldBody>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.WorldBody>,
          ffi.Pointer<ffi.Float>)>('body_get_position', isLeaf: true);

  Vector3 get position {
    Vector3 r = Vector3.zero();
    var p = calloc.call<ffi.Float>(3);
    unwrappedPositionGetter(_nativeBody, p);
    r.x = p[0];
    r.y = p[1];
    r.z = p[2];
    return r;
  }

  static final unwrappedRotationSetter = jolt.dylib.lookupFunction<
      ffi.Void Function(ffi.Pointer<jolt.WorldBody>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.WorldBody>,
          ffi.Pointer<ffi.Float>)>('body_set_rotation', isLeaf: true);

  set rotation(Quaternion rotation) {
    var p = calloc.call<ffi.Float>(4);
    p[0] = rotation.x;
    p[1] = rotation.y;
    p[2] = rotation.z;
    p[3] = rotation.w;
    unwrappedRotationSetter(_nativeBody, p);
    calloc.free(p);
  }

  static final unwrappedRotationGetter = jolt.dylib.lookupFunction<
      ffi.Void Function(ffi.Pointer<jolt.WorldBody>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.WorldBody>,
          ffi.Pointer<ffi.Float>)>('body_get_rotation', isLeaf: true);

  Quaternion get rotation {
    Quaternion q = Quaternion.identity();
    var p = calloc.call<ffi.Float>(4);
    unwrappedRotationGetter(_nativeBody, p);
    q.x = p[0];
    q.y = p[1];
    q.z = p[2];
    q.w = p[3];
    calloc.free(p);
    return q;
  }

  static final unwrappedWorldTransformGetter = jolt.dylib.lookupFunction<
      ffi.Void Function(ffi.Pointer<jolt.WorldBody>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.WorldBody>,
          ffi.Pointer<ffi.Float>)>('body_get_world_matrix', isLeaf: true);

  Matrix4 get worldTransform {
    Matrix4 m = new Matrix4.zero();
    var p = calloc.call<ffi.Float>(16);
    unwrappedWorldTransformGetter(_nativeBody, p);
    m[0] = p[0];
    m[1] = p[1];
    m[2] = p[2];
    m[3] = p[3];
    m[4] = p[4];
    m[5] = p[5];
    m[6] = p[6];
    m[7] = p[7];
    m[8] = p[8];
    m[9] = p[9];
    m[10] = p[10];
    m[11] = p[11];
    m[12] = p[12];
    m[13] = p[13];
    m[14] = p[14];
    m[15] = p[15];
    calloc.free(p);
    return m;
  }

  static final unwrapperCenterOfMassTransformGetter = jolt.dylib.lookupFunction<
      ffi.Void Function(ffi.Pointer<jolt.WorldBody>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.WorldBody>,
          ffi.Pointer<ffi.Float>)>('body_get_com_matrix', isLeaf: true);

  Matrix4 get centerOfMassTransform {
    Matrix4 m = new Matrix4.zero();
    var p = calloc.call<ffi.Float>(16);
    unwrapperCenterOfMassTransformGetter(_nativeBody, p);
    m[0] = p[0];
    m[1] = p[1];
    m[2] = p[2];
    m[3] = p[3];
    m[4] = p[4];
    m[5] = p[5];
    m[6] = p[6];
    m[7] = p[7];
    m[8] = p[8];
    m[9] = p[9];
    m[10] = p[10];
    m[11] = p[11];
    m[12] = p[12];
    m[13] = p[13];
    m[14] = p[14];
    m[15] = p[15];
    calloc.free(p);
    return m;
  }

  set shape(Shape shape) {
    _shape = shape;
    // TODO(johnmccutchan): Call to set.
  }

  Shape get shape {
    return _shape;
  }

  MotionQuality get motionQuality {
    return _motionQuality;
  }

  set motionQuality(MotionQuality mq) {
    _motionQuality = mq;
    // TODO(johnmccutchan): Call to set.
  }

  MotionType get motionType {
    return _motionType;
  }

  set motionType(MotionType mt) {
    _motionType = mt;
    // TODO(johnmccutchan): Call to set.
  }

  // Returns true if the body is active in the simulation.
  bool get active {
    return jolt.bindings.body_get_active(_nativeBody);
  }

  // Setting this to true will activate the body in the simulation.
  // Setting this to false will deactivate the body in the simulation.
  set active(bool activate) {
    jolt.bindings.body_set_active(_nativeBody, activate);
  }

  Body._(this._world, this._nativeBody, this._shape) {
    _finalizer.attach(this, _nativeBody.cast(), detach: this);
    jolt.bindings.set_body_dart_owner(_nativeBody, this);
    assert(identical(jolt.bindings.get_body_dart_owner(_nativeBody), this));
  }
}

class RigidBody extends Body {
  RigidBody._(World world, ffi.Pointer<jolt.WorldBody> nativeBody, Shape shape)
      : super._(world, nativeBody, shape);
}

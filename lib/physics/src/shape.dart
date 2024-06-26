part of '../physics.dart';

// TODO:
// - MutableCompoundShape.
// - HeightFieldShape.
// - Serialization.
// - Baked serialization.
// - plumb support for subshapeid.

class Shape implements ffi.Finalizable {
  static final _finalizer =
      ffi.NativeFinalizer(jolt.bindings.addresses.destroy_shape.cast());

  ffi.Pointer<jolt.CollisionShape> _nativeShape;

  Shape._(this._nativeShape) {
    _finalizer.attach(this, _nativeShape.cast(), detach: this);
    jolt.bindings.shape_set_dart_owner(_nativeShape, this);
    assert(identical(jolt.bindings.shape_get_dart_owner(_nativeShape), this));
  }

  static final unwrappedGetCenterOfMass = jolt.dylib.lookupFunction<
      ffi.Void Function(
          ffi.Pointer<jolt.CollisionShape>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.CollisionShape>,
          ffi.Pointer<ffi.Float>)>('shape_get_center_of_mass', isLeaf: true);

  Vector3 get centerOfMass {
    Vector3 r = Vector3.zero();
    var p = calloc.call<ffi.Float>(3);
    unwrappedGetCenterOfMass(_nativeShape, p);
    r.x = p[0];
    r.y = p[1];
    r.z = p[2];
    calloc.free(p);
    return r;
  }

  static final unwrappedGetLocalBounds = jolt.dylib.lookupFunction<
      ffi.Void Function(ffi.Pointer<jolt.CollisionShape>,
          ffi.Pointer<ffi.Float>, ffi.Pointer<ffi.Float>),
      void Function(ffi.Pointer<jolt.CollisionShape>, ffi.Pointer<ffi.Float>,
          ffi.Pointer<ffi.Float>)>('shape_get_local_bounds', isLeaf: true);

  Aabb3 get localBounds {
    Aabb3 r = Aabb3();
    var mi = calloc.call<ffi.Float>(3);
    var ma = calloc.call<ffi.Float>(3);
    unwrappedGetLocalBounds(_nativeShape, mi, ma);
    r.min.x = mi[0];
    r.min.y = mi[1];
    r.min.z = mi[2];
    r.max.x = ma[0];
    r.max.y = ma[1];
    r.max.z = ma[2];
    calloc.free(mi);
    calloc.free(ma);
    return r;
  }
}

class ConvexShapeSettings {
  // Uniform density of the interior of the convex object (kg / m^3)
  double density = 1000.0;

  _copyToConvexShapeConfig(
      ffi.Pointer<jolt.ConvexShapeConfig> convexShapeConfig) {
    convexShapeConfig.ref.density = density;
  }
}

class ConvexShape extends Shape {
  ConvexShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);
}

class BoxShapeSettings extends ConvexShapeSettings {
  BoxShapeSettings(this.halfExtents);

  // Box will be sized 2 * halfExtents centered at 0.
  Vector3 halfExtents;

  @override
  _copyToConvexShapeConfig(
      ffi.Pointer<jolt.ConvexShapeConfig> convexShapeConfig) {
    super._copyToConvexShapeConfig(convexShapeConfig);
    convexShapeConfig.ref.type = jolt.ConvexShapeConfigType.kBox;
    convexShapeConfig.ref.payload[0] = halfExtents[0];
    convexShapeConfig.ref.payload[1] = halfExtents[1];
    convexShapeConfig.ref.payload[2] = halfExtents[2];
  }
}

class BoxShape extends ConvexShape {
  BoxShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  factory BoxShape(BoxShapeSettings settings) {
    ffi.Pointer<jolt.ConvexShapeConfig> config =
        calloc.allocate(ffi.sizeOf<jolt.ConvexShapeConfig>());
    settings._copyToConvexShapeConfig(config);
    final nativeShape =
        jolt.bindings.create_convex_shape(config, ffi.nullptr, 0);
    calloc.free(config);
    return BoxShape._(nativeShape);
  }
}

class SphereShapeSettings extends ConvexShapeSettings {
  SphereShapeSettings(this.radius);

  // Radius of the sphere.
  double radius;

  @override
  _copyToConvexShapeConfig(
      ffi.Pointer<jolt.ConvexShapeConfig> convexShapeConfig) {
    super._copyToConvexShapeConfig(convexShapeConfig);
    convexShapeConfig.ref.type = jolt.ConvexShapeConfigType.kSphere;
    convexShapeConfig.ref.payload[0] = radius;
  }
}

class SphereShape extends ConvexShape {
  SphereShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  factory SphereShape(SphereShapeSettings settings) {
    ffi.Pointer<jolt.ConvexShapeConfig> config =
        calloc.allocate(ffi.sizeOf<jolt.ConvexShapeConfig>());
    settings._copyToConvexShapeConfig(config);
    final nativeShape =
        jolt.bindings.create_convex_shape(config, ffi.nullptr, 0);
    calloc.free(config);
    return SphereShape._(nativeShape);
  }
}

class CapsuleShapeSettings extends ConvexShapeSettings {
  // Radius is the same at the top and bottom of the capsule.
  CapsuleShapeSettings(this.halfHeight, this.topRadius)
      : bottomRadius = topRadius;

  // Radius is different at the top and bottom of the capsule.
  CapsuleShapeSettings.tapered(
      this.halfHeight, this.topRadius, this.bottomRadius);

  double halfHeight;
  double topRadius;
  double bottomRadius;

  @override
  _copyToConvexShapeConfig(
      ffi.Pointer<jolt.ConvexShapeConfig> convexShapeConfig) {
    super._copyToConvexShapeConfig(convexShapeConfig);
    convexShapeConfig.ref.type = jolt.ConvexShapeConfigType.kCapsule;
    convexShapeConfig.ref.payload[0] = halfHeight;
    convexShapeConfig.ref.payload[1] = topRadius;
    convexShapeConfig.ref.payload[2] = bottomRadius;
  }
}

class CapsuleShape extends ConvexShape {
  CapsuleShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  factory CapsuleShape(CapsuleShapeSettings settings) {
    ffi.Pointer<jolt.ConvexShapeConfig> config =
        calloc.allocate(ffi.sizeOf<jolt.ConvexShapeConfig>());
    settings._copyToConvexShapeConfig(config);
    final nativeShape =
        jolt.bindings.create_convex_shape(config, ffi.nullptr, 0);
    calloc.free(config);
    return CapsuleShape._(nativeShape);
  }
}

class ConvexHullShapeSettings extends ConvexShapeSettings {
  ConvexHullShapeSettings(this.points);

  @override
  _copyToConvexShapeConfig(
      ffi.Pointer<jolt.ConvexShapeConfig> convexShapeConfig) {
    super._copyToConvexShapeConfig(convexShapeConfig);
    convexShapeConfig.ref.type = jolt.ConvexShapeConfigType.kConvexHull;
  }

  Float32List points;
}

class ConvexHullShape extends ConvexShape {
  ConvexHullShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  static final unwrappedCreateConvexShape = jolt.dylib.lookupFunction<
      ffi.Pointer<jolt.CollisionShape> Function(
          ffi.Pointer<jolt.ConvexShapeConfig>, ffi.Pointer<ffi.Float>, ffi.Int),
      ffi.Pointer<jolt.CollisionShape> Function(
          ffi.Pointer<jolt.ConvexShapeConfig>,
          ffi.Pointer<ffi.Float>,
          int)>('create_convex_shape', isLeaf: true);

  factory ConvexHullShape(ConvexHullShapeSettings settings) {
    ffi.Pointer<jolt.ConvexShapeConfig> config =
        calloc.allocate(ffi.sizeOf<jolt.ConvexShapeConfig>());
    settings._copyToConvexShapeConfig(config);
    ffi.Pointer<ffi.Float> points =
        calloc.allocate<ffi.Float>(settings.points.length);
    for (int i = 0; i < settings.points.length; i++) {
      points[i] = settings.points[i];
    }
    final nativeShape =
        unwrappedCreateConvexShape(config, points, settings.points.length ~/ 3);
    calloc.free(config);
    calloc.free(points);
    return ConvexHullShape._(nativeShape);
  }
}

class CompoundShapeSettings {
  _copyToCompoundShapeConfig(
      List<ffi.Pointer<jolt.CompoundShapeConfig>> configs) {
    for (int i = 0; i < _shapes.length; i++) {
      configs[i].ref.position[0] = _positions[i].x;
      configs[i].ref.position[1] = _positions[i].y;
      configs[i].ref.position[2] = _positions[i].z;
      configs[i].ref.rotation[0] = _rotations[i].x;
      configs[i].ref.rotation[1] = _rotations[i].y;
      configs[i].ref.rotation[2] = _rotations[i].z;
      configs[i].ref.rotation[3] = _rotations[i].w;
      configs[i].ref.shape = _shapes[i]._nativeShape;
    }
  }

  final List<Shape> _shapes = [];
  final List<Vector3> _positions = [];
  final List<Quaternion> _rotations = [];

  int get length {
    return _shapes.length;
  }

  void addShape(Shape shape, Vector3 position, Quaternion rotation) {
    _shapes.add(shape);
    _positions.add(position);
    _rotations.add(rotation);
  }
}

class CompoundShape extends Shape {
  CompoundShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  factory CompoundShape(CompoundShapeSettings settings) {
    ffi.Pointer<jolt.CompoundShapeConfig> configs = calloc
        .allocate(ffi.sizeOf<jolt.CompoundShapeConfig>() * settings.length);
    int configsAddress = configs.address;
    List<ffi.Pointer<jolt.CompoundShapeConfig>> configs_array =
        List<ffi.Pointer<jolt.CompoundShapeConfig>>.filled(settings.length,
            ffi.Pointer<jolt.CompoundShapeConfig>.fromAddress(0));
    for (int i = 0; i < settings.length; i++) {
      configs_array[i] = ffi.Pointer<jolt.CompoundShapeConfig>.fromAddress(
          configsAddress + ffi.sizeOf<jolt.CompoundShapeConfig>() * i);
    }
    settings._copyToCompoundShapeConfig(configs_array);
    final nativeShape = jolt.bindings.create_compound_shape(
        ffi.Pointer<jolt.CompoundShapeConfig>.fromAddress(configsAddress),
        settings.length);
    calloc.free(configs);
    return CompoundShape._(nativeShape);
  }
}

final emptyUint32List = Uint32List(0);

class MeshShapeSettings {
  Float32List vertices;
  Uint32List indices;

  MeshShapeSettings(this.vertices, this.indices) {
    assert(vertices.length % 3 == 0);
    assert(indices.length % 3 == 0);
  }
}

class MeshShape extends Shape {
  MeshShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  static final unwrappedCreateMeshShape = jolt.dylib.lookupFunction<
      ffi.Pointer<jolt.CollisionShape> Function(
          ffi.Pointer<ffi.Float>, ffi.Int, ffi.Pointer<ffi.Uint32>, ffi.Int),
      ffi.Pointer<jolt.CollisionShape> Function(ffi.Pointer<ffi.Float>, int,
          ffi.Pointer<ffi.Uint32>, int)>('create_mesh_shape', isLeaf: true);

  factory MeshShape(MeshShapeSettings settings) {
    ffi.Pointer<ffi.Float> vertices =
        calloc.allocate<ffi.Float>(settings.vertices.length);
    ffi.Pointer<ffi.Uint32> indices =
        calloc.allocate<ffi.Uint32>(settings.indices.length);
    for (int i = 0; i < settings.vertices.length; i++) {
      vertices[i] = settings.vertices[i];
    }
    for (int i = 0; i < settings.indices.length; i++) {
      indices[i] = settings.indices[i];
    }
    final nativeShape = unwrappedCreateMeshShape(vertices,
        settings.vertices.length ~/ 3, indices, settings.indices.length ~/ 3);
    calloc.free(vertices);
    calloc.free(indices);
    return MeshShape._(nativeShape);
  }
}

class DecoratedShapeSettings {
  DecoratedShapeSettings(this.innerShape);

  Shape innerShape;

  _copyToDecoratedShapeConfig(ffi.Pointer<jolt.DecoratedShapeConfig> config) {
    config.ref.inner_shape = innerShape._nativeShape;
  }
}

class DecoratedShape extends Shape {
  DecoratedShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);
}

class ScaledShapeSettings extends DecoratedShapeSettings {
  ScaledShapeSettings(Shape innerShape, this.scale) : super(innerShape);

  Vector3 scale;
  @override
  _copyToDecoratedShapeConfig(ffi.Pointer<jolt.DecoratedShapeConfig> config) {
    super._copyToDecoratedShapeConfig(config);
    config.ref.type = jolt.DecoratedShapeConfigType.kScaled;
    config.ref.v3[0] = scale[0];
    config.ref.v3[1] = scale[1];
    config.ref.v3[2] = scale[2];
  }
}

class ScaledShape extends DecoratedShape {
  ScaledShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  factory ScaledShape(ScaledShapeSettings settings) {
    ffi.Pointer<jolt.DecoratedShapeConfig> config =
        calloc.allocate(ffi.sizeOf<jolt.DecoratedShapeConfig>());
    settings._copyToDecoratedShapeConfig(config);
    final nativeShape = jolt.bindings.create_decorated_shape(config);
    calloc.free(config);
    return ScaledShape._(nativeShape);
  }
}

class TransformedShapeSettings extends DecoratedShapeSettings {
  TransformedShapeSettings(Shape innerShape, this.position, this.rotation)
      : super(innerShape);

  Vector3 position;
  Quaternion rotation;

  @override
  _copyToDecoratedShapeConfig(ffi.Pointer<jolt.DecoratedShapeConfig> config) {
    super._copyToDecoratedShapeConfig(config);
    config.ref.type = jolt.DecoratedShapeConfigType.kTransformed;
    config.ref.v3[0] = position[0];
    config.ref.v3[1] = position[1];
    config.ref.v3[2] = position[2];
    config.ref.q4[0] = rotation[0];
    config.ref.q4[1] = rotation[1];
    config.ref.q4[2] = rotation[2];
    config.ref.q4[3] = rotation[3];
  }
}

class TransformedShape extends DecoratedShape {
  TransformedShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  factory TransformedShape(TransformedShapeSettings settings) {
    ffi.Pointer<jolt.DecoratedShapeConfig> config =
        calloc.allocate(ffi.sizeOf<jolt.DecoratedShapeConfig>());
    settings._copyToDecoratedShapeConfig(config);
    final nativeShape = jolt.bindings.create_decorated_shape(config);
    calloc.free(config);
    return TransformedShape._(nativeShape);
  }
}

class OffsetCenterOfMassShapeSettings extends DecoratedShapeSettings {
  OffsetCenterOfMassShapeSettings(super.innerShape, this.offset);

  Vector3 offset;

  @override
  _copyToDecoratedShapeConfig(ffi.Pointer<jolt.DecoratedShapeConfig> config) {
    super._copyToDecoratedShapeConfig(config);
    config.ref.type = jolt.DecoratedShapeConfigType.kOffsetCenterOfMass;
    config.ref.v3[0] = offset[0];
    config.ref.v3[1] = offset[1];
    config.ref.v3[2] = offset[2];
  }
}

class OffsetCenterOfMassShape extends DecoratedShape {
  OffsetCenterOfMassShape._(ffi.Pointer<jolt.CollisionShape> nativeShape)
      : super._(nativeShape);

  factory OffsetCenterOfMassShape(OffsetCenterOfMassShapeSettings settings) {
    ffi.Pointer<jolt.DecoratedShapeConfig> config =
        calloc.allocate(ffi.sizeOf<jolt.DecoratedShapeConfig>());
    settings._copyToDecoratedShapeConfig(config);
    final nativeShape = jolt.bindings.create_decorated_shape(config);
    calloc.free(config);
    return OffsetCenterOfMassShape._(nativeShape);
  }
}

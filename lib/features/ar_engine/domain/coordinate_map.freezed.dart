// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coordinate_map.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Anchor3D {

 String get id; double get x; double get y; double get z;
/// Create a copy of Anchor3D
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Anchor3DCopyWith<Anchor3D> get copyWith => _$Anchor3DCopyWithImpl<Anchor3D>(this as Anchor3D, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Anchor3D&&(identical(other.id, id) || other.id == id)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.z, z) || other.z == z));
}


@override
int get hashCode => Object.hash(runtimeType,id,x,y,z);

@override
String toString() {
  return 'Anchor3D(id: $id, x: $x, y: $y, z: $z)';
}


}

/// @nodoc
abstract mixin class $Anchor3DCopyWith<$Res>  {
  factory $Anchor3DCopyWith(Anchor3D value, $Res Function(Anchor3D) _then) = _$Anchor3DCopyWithImpl;
@useResult
$Res call({
 String id, double x, double y, double z
});




}
/// @nodoc
class _$Anchor3DCopyWithImpl<$Res>
    implements $Anchor3DCopyWith<$Res> {
  _$Anchor3DCopyWithImpl(this._self, this._then);

  final Anchor3D _self;
  final $Res Function(Anchor3D) _then;

/// Create a copy of Anchor3D
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? x = null,Object? y = null,Object? z = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,z: null == z ? _self.z : z // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Anchor3D].
extension Anchor3DPatterns on Anchor3D {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Anchor3D value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Anchor3D() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Anchor3D value)  $default,){
final _that = this;
switch (_that) {
case _Anchor3D():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Anchor3D value)?  $default,){
final _that = this;
switch (_that) {
case _Anchor3D() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double x,  double y,  double z)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Anchor3D() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.z);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double x,  double y,  double z)  $default,) {final _that = this;
switch (_that) {
case _Anchor3D():
return $default(_that.id,_that.x,_that.y,_that.z);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double x,  double y,  double z)?  $default,) {final _that = this;
switch (_that) {
case _Anchor3D() when $default != null:
return $default(_that.id,_that.x,_that.y,_that.z);case _:
  return null;

}
}

}

/// @nodoc


class _Anchor3D implements Anchor3D {
  const _Anchor3D({required this.id, required this.x, required this.y, required this.z});
  

@override final  String id;
@override final  double x;
@override final  double y;
@override final  double z;

/// Create a copy of Anchor3D
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Anchor3DCopyWith<_Anchor3D> get copyWith => __$Anchor3DCopyWithImpl<_Anchor3D>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Anchor3D&&(identical(other.id, id) || other.id == id)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.z, z) || other.z == z));
}


@override
int get hashCode => Object.hash(runtimeType,id,x,y,z);

@override
String toString() {
  return 'Anchor3D(id: $id, x: $x, y: $y, z: $z)';
}


}

/// @nodoc
abstract mixin class _$Anchor3DCopyWith<$Res> implements $Anchor3DCopyWith<$Res> {
  factory _$Anchor3DCopyWith(_Anchor3D value, $Res Function(_Anchor3D) _then) = __$Anchor3DCopyWithImpl;
@override @useResult
$Res call({
 String id, double x, double y, double z
});




}
/// @nodoc
class __$Anchor3DCopyWithImpl<$Res>
    implements _$Anchor3DCopyWith<$Res> {
  __$Anchor3DCopyWithImpl(this._self, this._then);

  final _Anchor3D _self;
  final $Res Function(_Anchor3D) _then;

/// Create a copy of Anchor3D
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? x = null,Object? y = null,Object? z = null,}) {
  return _then(_Anchor3D(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,z: null == z ? _self.z : z // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$CoordinateMap {

 BranchId get branch; DressCode get dressCode; Gender get gender; bool get isSikh; double get collarOffsetCm; Map<String, Anchor3D> get anchors;
/// Create a copy of CoordinateMap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoordinateMapCopyWith<CoordinateMap> get copyWith => _$CoordinateMapCopyWithImpl<CoordinateMap>(this as CoordinateMap, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoordinateMap&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.dressCode, dressCode) || other.dressCode == dressCode)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.isSikh, isSikh) || other.isSikh == isSikh)&&(identical(other.collarOffsetCm, collarOffsetCm) || other.collarOffsetCm == collarOffsetCm)&&const DeepCollectionEquality().equals(other.anchors, anchors));
}


@override
int get hashCode => Object.hash(runtimeType,branch,dressCode,gender,isSikh,collarOffsetCm,const DeepCollectionEquality().hash(anchors));

@override
String toString() {
  return 'CoordinateMap(branch: $branch, dressCode: $dressCode, gender: $gender, isSikh: $isSikh, collarOffsetCm: $collarOffsetCm, anchors: $anchors)';
}


}

/// @nodoc
abstract mixin class $CoordinateMapCopyWith<$Res>  {
  factory $CoordinateMapCopyWith(CoordinateMap value, $Res Function(CoordinateMap) _then) = _$CoordinateMapCopyWithImpl;
@useResult
$Res call({
 BranchId branch, DressCode dressCode, Gender gender, bool isSikh, double collarOffsetCm, Map<String, Anchor3D> anchors
});




}
/// @nodoc
class _$CoordinateMapCopyWithImpl<$Res>
    implements $CoordinateMapCopyWith<$Res> {
  _$CoordinateMapCopyWithImpl(this._self, this._then);

  final CoordinateMap _self;
  final $Res Function(CoordinateMap) _then;

/// Create a copy of CoordinateMap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branch = null,Object? dressCode = null,Object? gender = null,Object? isSikh = null,Object? collarOffsetCm = null,Object? anchors = null,}) {
  return _then(_self.copyWith(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as BranchId,dressCode: null == dressCode ? _self.dressCode : dressCode // ignore: cast_nullable_to_non_nullable
as DressCode,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,isSikh: null == isSikh ? _self.isSikh : isSikh // ignore: cast_nullable_to_non_nullable
as bool,collarOffsetCm: null == collarOffsetCm ? _self.collarOffsetCm : collarOffsetCm // ignore: cast_nullable_to_non_nullable
as double,anchors: null == anchors ? _self.anchors : anchors // ignore: cast_nullable_to_non_nullable
as Map<String, Anchor3D>,
  ));
}

}


/// Adds pattern-matching-related methods to [CoordinateMap].
extension CoordinateMapPatterns on CoordinateMap {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoordinateMap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoordinateMap() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoordinateMap value)  $default,){
final _that = this;
switch (_that) {
case _CoordinateMap():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoordinateMap value)?  $default,){
final _that = this;
switch (_that) {
case _CoordinateMap() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BranchId branch,  DressCode dressCode,  Gender gender,  bool isSikh,  double collarOffsetCm,  Map<String, Anchor3D> anchors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoordinateMap() when $default != null:
return $default(_that.branch,_that.dressCode,_that.gender,_that.isSikh,_that.collarOffsetCm,_that.anchors);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BranchId branch,  DressCode dressCode,  Gender gender,  bool isSikh,  double collarOffsetCm,  Map<String, Anchor3D> anchors)  $default,) {final _that = this;
switch (_that) {
case _CoordinateMap():
return $default(_that.branch,_that.dressCode,_that.gender,_that.isSikh,_that.collarOffsetCm,_that.anchors);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BranchId branch,  DressCode dressCode,  Gender gender,  bool isSikh,  double collarOffsetCm,  Map<String, Anchor3D> anchors)?  $default,) {final _that = this;
switch (_that) {
case _CoordinateMap() when $default != null:
return $default(_that.branch,_that.dressCode,_that.gender,_that.isSikh,_that.collarOffsetCm,_that.anchors);case _:
  return null;

}
}

}

/// @nodoc


class _CoordinateMap implements CoordinateMap {
  const _CoordinateMap({required this.branch, required this.dressCode, required this.gender, required this.isSikh, required this.collarOffsetCm, required final  Map<String, Anchor3D> anchors}): _anchors = anchors;
  

@override final  BranchId branch;
@override final  DressCode dressCode;
@override final  Gender gender;
@override final  bool isSikh;
@override final  double collarOffsetCm;
 final  Map<String, Anchor3D> _anchors;
@override Map<String, Anchor3D> get anchors {
  if (_anchors is EqualUnmodifiableMapView) return _anchors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_anchors);
}


/// Create a copy of CoordinateMap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoordinateMapCopyWith<_CoordinateMap> get copyWith => __$CoordinateMapCopyWithImpl<_CoordinateMap>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoordinateMap&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.dressCode, dressCode) || other.dressCode == dressCode)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.isSikh, isSikh) || other.isSikh == isSikh)&&(identical(other.collarOffsetCm, collarOffsetCm) || other.collarOffsetCm == collarOffsetCm)&&const DeepCollectionEquality().equals(other._anchors, _anchors));
}


@override
int get hashCode => Object.hash(runtimeType,branch,dressCode,gender,isSikh,collarOffsetCm,const DeepCollectionEquality().hash(_anchors));

@override
String toString() {
  return 'CoordinateMap(branch: $branch, dressCode: $dressCode, gender: $gender, isSikh: $isSikh, collarOffsetCm: $collarOffsetCm, anchors: $anchors)';
}


}

/// @nodoc
abstract mixin class _$CoordinateMapCopyWith<$Res> implements $CoordinateMapCopyWith<$Res> {
  factory _$CoordinateMapCopyWith(_CoordinateMap value, $Res Function(_CoordinateMap) _then) = __$CoordinateMapCopyWithImpl;
@override @useResult
$Res call({
 BranchId branch, DressCode dressCode, Gender gender, bool isSikh, double collarOffsetCm, Map<String, Anchor3D> anchors
});




}
/// @nodoc
class __$CoordinateMapCopyWithImpl<$Res>
    implements _$CoordinateMapCopyWith<$Res> {
  __$CoordinateMapCopyWithImpl(this._self, this._then);

  final _CoordinateMap _self;
  final $Res Function(_CoordinateMap) _then;

/// Create a copy of CoordinateMap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branch = null,Object? dressCode = null,Object? gender = null,Object? isSikh = null,Object? collarOffsetCm = null,Object? anchors = null,}) {
  return _then(_CoordinateMap(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as BranchId,dressCode: null == dressCode ? _self.dressCode : dressCode // ignore: cast_nullable_to_non_nullable
as DressCode,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,isSikh: null == isSikh ? _self.isSikh : isSikh // ignore: cast_nullable_to_non_nullable
as bool,collarOffsetCm: null == collarOffsetCm ? _self.collarOffsetCm : collarOffsetCm // ignore: cast_nullable_to_non_nullable
as double,anchors: null == anchors ? _self._anchors : anchors // ignore: cast_nullable_to_non_nullable
as Map<String, Anchor3D>,
  ));
}


}

// dart format on

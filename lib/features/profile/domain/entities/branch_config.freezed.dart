// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'branch_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MedalAnchor {

 String get anchor; AnchorOffset get offsetCm;
/// Create a copy of MedalAnchor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedalAnchorCopyWith<MedalAnchor> get copyWith => _$MedalAnchorCopyWithImpl<MedalAnchor>(this as MedalAnchor, _$identity);

  /// Serializes this MedalAnchor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedalAnchor&&(identical(other.anchor, anchor) || other.anchor == anchor)&&(identical(other.offsetCm, offsetCm) || other.offsetCm == offsetCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,anchor,offsetCm);

@override
String toString() {
  return 'MedalAnchor(anchor: $anchor, offsetCm: $offsetCm)';
}


}

/// @nodoc
abstract mixin class $MedalAnchorCopyWith<$Res>  {
  factory $MedalAnchorCopyWith(MedalAnchor value, $Res Function(MedalAnchor) _then) = _$MedalAnchorCopyWithImpl;
@useResult
$Res call({
 String anchor, AnchorOffset offsetCm
});


$AnchorOffsetCopyWith<$Res> get offsetCm;

}
/// @nodoc
class _$MedalAnchorCopyWithImpl<$Res>
    implements $MedalAnchorCopyWith<$Res> {
  _$MedalAnchorCopyWithImpl(this._self, this._then);

  final MedalAnchor _self;
  final $Res Function(MedalAnchor) _then;

/// Create a copy of MedalAnchor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? anchor = null,Object? offsetCm = null,}) {
  return _then(_self.copyWith(
anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as String,offsetCm: null == offsetCm ? _self.offsetCm : offsetCm // ignore: cast_nullable_to_non_nullable
as AnchorOffset,
  ));
}
/// Create a copy of MedalAnchor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorOffsetCopyWith<$Res> get offsetCm {
  
  return $AnchorOffsetCopyWith<$Res>(_self.offsetCm, (value) {
    return _then(_self.copyWith(offsetCm: value));
  });
}
}


/// Adds pattern-matching-related methods to [MedalAnchor].
extension MedalAnchorPatterns on MedalAnchor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedalAnchor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedalAnchor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedalAnchor value)  $default,){
final _that = this;
switch (_that) {
case _MedalAnchor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedalAnchor value)?  $default,){
final _that = this;
switch (_that) {
case _MedalAnchor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String anchor,  AnchorOffset offsetCm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedalAnchor() when $default != null:
return $default(_that.anchor,_that.offsetCm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String anchor,  AnchorOffset offsetCm)  $default,) {final _that = this;
switch (_that) {
case _MedalAnchor():
return $default(_that.anchor,_that.offsetCm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String anchor,  AnchorOffset offsetCm)?  $default,) {final _that = this;
switch (_that) {
case _MedalAnchor() when $default != null:
return $default(_that.anchor,_that.offsetCm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MedalAnchor implements MedalAnchor {
  const _MedalAnchor({required this.anchor, required this.offsetCm});
  factory _MedalAnchor.fromJson(Map<String, dynamic> json) => _$MedalAnchorFromJson(json);

@override final  String anchor;
@override final  AnchorOffset offsetCm;

/// Create a copy of MedalAnchor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedalAnchorCopyWith<_MedalAnchor> get copyWith => __$MedalAnchorCopyWithImpl<_MedalAnchor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedalAnchorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedalAnchor&&(identical(other.anchor, anchor) || other.anchor == anchor)&&(identical(other.offsetCm, offsetCm) || other.offsetCm == offsetCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,anchor,offsetCm);

@override
String toString() {
  return 'MedalAnchor(anchor: $anchor, offsetCm: $offsetCm)';
}


}

/// @nodoc
abstract mixin class _$MedalAnchorCopyWith<$Res> implements $MedalAnchorCopyWith<$Res> {
  factory _$MedalAnchorCopyWith(_MedalAnchor value, $Res Function(_MedalAnchor) _then) = __$MedalAnchorCopyWithImpl;
@override @useResult
$Res call({
 String anchor, AnchorOffset offsetCm
});


@override $AnchorOffsetCopyWith<$Res> get offsetCm;

}
/// @nodoc
class __$MedalAnchorCopyWithImpl<$Res>
    implements _$MedalAnchorCopyWith<$Res> {
  __$MedalAnchorCopyWithImpl(this._self, this._then);

  final _MedalAnchor _self;
  final $Res Function(_MedalAnchor) _then;

/// Create a copy of MedalAnchor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? anchor = null,Object? offsetCm = null,}) {
  return _then(_MedalAnchor(
anchor: null == anchor ? _self.anchor : anchor // ignore: cast_nullable_to_non_nullable
as String,offsetCm: null == offsetCm ? _self.offsetCm : offsetCm // ignore: cast_nullable_to_non_nullable
as AnchorOffset,
  ));
}

/// Create a copy of MedalAnchor
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnchorOffsetCopyWith<$Res> get offsetCm {
  
  return $AnchorOffsetCopyWith<$Res>(_self.offsetCm, (value) {
    return _then(_self.copyWith(offsetCm: value));
  });
}
}


/// @nodoc
mixin _$AnchorOffset {

 double get x; double get y;
/// Create a copy of AnchorOffset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnchorOffsetCopyWith<AnchorOffset> get copyWith => _$AnchorOffsetCopyWithImpl<AnchorOffset>(this as AnchorOffset, _$identity);

  /// Serializes this AnchorOffset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnchorOffset&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'AnchorOffset(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $AnchorOffsetCopyWith<$Res>  {
  factory $AnchorOffsetCopyWith(AnchorOffset value, $Res Function(AnchorOffset) _then) = _$AnchorOffsetCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$AnchorOffsetCopyWithImpl<$Res>
    implements $AnchorOffsetCopyWith<$Res> {
  _$AnchorOffsetCopyWithImpl(this._self, this._then);

  final AnchorOffset _self;
  final $Res Function(AnchorOffset) _then;

/// Create a copy of AnchorOffset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AnchorOffset].
extension AnchorOffsetPatterns on AnchorOffset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnchorOffset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnchorOffset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnchorOffset value)  $default,){
final _that = this;
switch (_that) {
case _AnchorOffset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnchorOffset value)?  $default,){
final _that = this;
switch (_that) {
case _AnchorOffset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnchorOffset() when $default != null:
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y)  $default,) {final _that = this;
switch (_that) {
case _AnchorOffset():
return $default(_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y)?  $default,) {final _that = this;
switch (_that) {
case _AnchorOffset() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnchorOffset implements AnchorOffset {
  const _AnchorOffset({required this.x, required this.y});
  factory _AnchorOffset.fromJson(Map<String, dynamic> json) => _$AnchorOffsetFromJson(json);

@override final  double x;
@override final  double y;

/// Create a copy of AnchorOffset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnchorOffsetCopyWith<_AnchorOffset> get copyWith => __$AnchorOffsetCopyWithImpl<_AnchorOffset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnchorOffsetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnchorOffset&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'AnchorOffset(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$AnchorOffsetCopyWith<$Res> implements $AnchorOffsetCopyWith<$Res> {
  factory _$AnchorOffsetCopyWith(_AnchorOffset value, $Res Function(_AnchorOffset) _then) = __$AnchorOffsetCopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$AnchorOffsetCopyWithImpl<$Res>
    implements _$AnchorOffsetCopyWith<$Res> {
  __$AnchorOffsetCopyWithImpl(this._self, this._then);

  final _AnchorOffset _self;
  final $Res Function(_AnchorOffset) _then;

/// Create a copy of AnchorOffset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_AnchorOffset(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$SikhTurbanLogic {

 bool get replacesHeadgear; String get color; String get alignmentOverride;
/// Create a copy of SikhTurbanLogic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SikhTurbanLogicCopyWith<SikhTurbanLogic> get copyWith => _$SikhTurbanLogicCopyWithImpl<SikhTurbanLogic>(this as SikhTurbanLogic, _$identity);

  /// Serializes this SikhTurbanLogic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SikhTurbanLogic&&(identical(other.replacesHeadgear, replacesHeadgear) || other.replacesHeadgear == replacesHeadgear)&&(identical(other.color, color) || other.color == color)&&(identical(other.alignmentOverride, alignmentOverride) || other.alignmentOverride == alignmentOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,replacesHeadgear,color,alignmentOverride);

@override
String toString() {
  return 'SikhTurbanLogic(replacesHeadgear: $replacesHeadgear, color: $color, alignmentOverride: $alignmentOverride)';
}


}

/// @nodoc
abstract mixin class $SikhTurbanLogicCopyWith<$Res>  {
  factory $SikhTurbanLogicCopyWith(SikhTurbanLogic value, $Res Function(SikhTurbanLogic) _then) = _$SikhTurbanLogicCopyWithImpl;
@useResult
$Res call({
 bool replacesHeadgear, String color, String alignmentOverride
});




}
/// @nodoc
class _$SikhTurbanLogicCopyWithImpl<$Res>
    implements $SikhTurbanLogicCopyWith<$Res> {
  _$SikhTurbanLogicCopyWithImpl(this._self, this._then);

  final SikhTurbanLogic _self;
  final $Res Function(SikhTurbanLogic) _then;

/// Create a copy of SikhTurbanLogic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? replacesHeadgear = null,Object? color = null,Object? alignmentOverride = null,}) {
  return _then(_self.copyWith(
replacesHeadgear: null == replacesHeadgear ? _self.replacesHeadgear : replacesHeadgear // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,alignmentOverride: null == alignmentOverride ? _self.alignmentOverride : alignmentOverride // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SikhTurbanLogic].
extension SikhTurbanLogicPatterns on SikhTurbanLogic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SikhTurbanLogic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SikhTurbanLogic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SikhTurbanLogic value)  $default,){
final _that = this;
switch (_that) {
case _SikhTurbanLogic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SikhTurbanLogic value)?  $default,){
final _that = this;
switch (_that) {
case _SikhTurbanLogic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool replacesHeadgear,  String color,  String alignmentOverride)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SikhTurbanLogic() when $default != null:
return $default(_that.replacesHeadgear,_that.color,_that.alignmentOverride);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool replacesHeadgear,  String color,  String alignmentOverride)  $default,) {final _that = this;
switch (_that) {
case _SikhTurbanLogic():
return $default(_that.replacesHeadgear,_that.color,_that.alignmentOverride);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool replacesHeadgear,  String color,  String alignmentOverride)?  $default,) {final _that = this;
switch (_that) {
case _SikhTurbanLogic() when $default != null:
return $default(_that.replacesHeadgear,_that.color,_that.alignmentOverride);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SikhTurbanLogic implements SikhTurbanLogic {
  const _SikhTurbanLogic({required this.replacesHeadgear, required this.color, required this.alignmentOverride});
  factory _SikhTurbanLogic.fromJson(Map<String, dynamic> json) => _$SikhTurbanLogicFromJson(json);

@override final  bool replacesHeadgear;
@override final  String color;
@override final  String alignmentOverride;

/// Create a copy of SikhTurbanLogic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SikhTurbanLogicCopyWith<_SikhTurbanLogic> get copyWith => __$SikhTurbanLogicCopyWithImpl<_SikhTurbanLogic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SikhTurbanLogicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SikhTurbanLogic&&(identical(other.replacesHeadgear, replacesHeadgear) || other.replacesHeadgear == replacesHeadgear)&&(identical(other.color, color) || other.color == color)&&(identical(other.alignmentOverride, alignmentOverride) || other.alignmentOverride == alignmentOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,replacesHeadgear,color,alignmentOverride);

@override
String toString() {
  return 'SikhTurbanLogic(replacesHeadgear: $replacesHeadgear, color: $color, alignmentOverride: $alignmentOverride)';
}


}

/// @nodoc
abstract mixin class _$SikhTurbanLogicCopyWith<$Res> implements $SikhTurbanLogicCopyWith<$Res> {
  factory _$SikhTurbanLogicCopyWith(_SikhTurbanLogic value, $Res Function(_SikhTurbanLogic) _then) = __$SikhTurbanLogicCopyWithImpl;
@override @useResult
$Res call({
 bool replacesHeadgear, String color, String alignmentOverride
});




}
/// @nodoc
class __$SikhTurbanLogicCopyWithImpl<$Res>
    implements _$SikhTurbanLogicCopyWith<$Res> {
  __$SikhTurbanLogicCopyWithImpl(this._self, this._then);

  final _SikhTurbanLogic _self;
  final $Res Function(_SikhTurbanLogic) _then;

/// Create a copy of SikhTurbanLogic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? replacesHeadgear = null,Object? color = null,Object? alignmentOverride = null,}) {
  return _then(_SikhTurbanLogic(
replacesHeadgear: null == replacesHeadgear ? _self.replacesHeadgear : replacesHeadgear // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,alignmentOverride: null == alignmentOverride ? _self.alignmentOverride : alignmentOverride // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BranchConfig {

 BranchId get branchId; String get displayName; double get collarOffsetCm; MedalAnchor get ladiesMedalAnchor; SikhTurbanLogic get sikhTurbanLogic; List<DressCode> get dressCodes; int get version;
/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchConfigCopyWith<BranchConfig> get copyWith => _$BranchConfigCopyWithImpl<BranchConfig>(this as BranchConfig, _$identity);

  /// Serializes this BranchConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchConfig&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.collarOffsetCm, collarOffsetCm) || other.collarOffsetCm == collarOffsetCm)&&(identical(other.ladiesMedalAnchor, ladiesMedalAnchor) || other.ladiesMedalAnchor == ladiesMedalAnchor)&&(identical(other.sikhTurbanLogic, sikhTurbanLogic) || other.sikhTurbanLogic == sikhTurbanLogic)&&const DeepCollectionEquality().equals(other.dressCodes, dressCodes)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,branchId,displayName,collarOffsetCm,ladiesMedalAnchor,sikhTurbanLogic,const DeepCollectionEquality().hash(dressCodes),version);

@override
String toString() {
  return 'BranchConfig(branchId: $branchId, displayName: $displayName, collarOffsetCm: $collarOffsetCm, ladiesMedalAnchor: $ladiesMedalAnchor, sikhTurbanLogic: $sikhTurbanLogic, dressCodes: $dressCodes, version: $version)';
}


}

/// @nodoc
abstract mixin class $BranchConfigCopyWith<$Res>  {
  factory $BranchConfigCopyWith(BranchConfig value, $Res Function(BranchConfig) _then) = _$BranchConfigCopyWithImpl;
@useResult
$Res call({
 BranchId branchId, String displayName, double collarOffsetCm, MedalAnchor ladiesMedalAnchor, SikhTurbanLogic sikhTurbanLogic, List<DressCode> dressCodes, int version
});


$MedalAnchorCopyWith<$Res> get ladiesMedalAnchor;$SikhTurbanLogicCopyWith<$Res> get sikhTurbanLogic;

}
/// @nodoc
class _$BranchConfigCopyWithImpl<$Res>
    implements $BranchConfigCopyWith<$Res> {
  _$BranchConfigCopyWithImpl(this._self, this._then);

  final BranchConfig _self;
  final $Res Function(BranchConfig) _then;

/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branchId = null,Object? displayName = null,Object? collarOffsetCm = null,Object? ladiesMedalAnchor = null,Object? sikhTurbanLogic = null,Object? dressCodes = null,Object? version = null,}) {
  return _then(_self.copyWith(
branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as BranchId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,collarOffsetCm: null == collarOffsetCm ? _self.collarOffsetCm : collarOffsetCm // ignore: cast_nullable_to_non_nullable
as double,ladiesMedalAnchor: null == ladiesMedalAnchor ? _self.ladiesMedalAnchor : ladiesMedalAnchor // ignore: cast_nullable_to_non_nullable
as MedalAnchor,sikhTurbanLogic: null == sikhTurbanLogic ? _self.sikhTurbanLogic : sikhTurbanLogic // ignore: cast_nullable_to_non_nullable
as SikhTurbanLogic,dressCodes: null == dressCodes ? _self.dressCodes : dressCodes // ignore: cast_nullable_to_non_nullable
as List<DressCode>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedalAnchorCopyWith<$Res> get ladiesMedalAnchor {
  
  return $MedalAnchorCopyWith<$Res>(_self.ladiesMedalAnchor, (value) {
    return _then(_self.copyWith(ladiesMedalAnchor: value));
  });
}/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SikhTurbanLogicCopyWith<$Res> get sikhTurbanLogic {
  
  return $SikhTurbanLogicCopyWith<$Res>(_self.sikhTurbanLogic, (value) {
    return _then(_self.copyWith(sikhTurbanLogic: value));
  });
}
}


/// Adds pattern-matching-related methods to [BranchConfig].
extension BranchConfigPatterns on BranchConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BranchConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BranchConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BranchConfig value)  $default,){
final _that = this;
switch (_that) {
case _BranchConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BranchConfig value)?  $default,){
final _that = this;
switch (_that) {
case _BranchConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BranchId branchId,  String displayName,  double collarOffsetCm,  MedalAnchor ladiesMedalAnchor,  SikhTurbanLogic sikhTurbanLogic,  List<DressCode> dressCodes,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BranchConfig() when $default != null:
return $default(_that.branchId,_that.displayName,_that.collarOffsetCm,_that.ladiesMedalAnchor,_that.sikhTurbanLogic,_that.dressCodes,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BranchId branchId,  String displayName,  double collarOffsetCm,  MedalAnchor ladiesMedalAnchor,  SikhTurbanLogic sikhTurbanLogic,  List<DressCode> dressCodes,  int version)  $default,) {final _that = this;
switch (_that) {
case _BranchConfig():
return $default(_that.branchId,_that.displayName,_that.collarOffsetCm,_that.ladiesMedalAnchor,_that.sikhTurbanLogic,_that.dressCodes,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BranchId branchId,  String displayName,  double collarOffsetCm,  MedalAnchor ladiesMedalAnchor,  SikhTurbanLogic sikhTurbanLogic,  List<DressCode> dressCodes,  int version)?  $default,) {final _that = this;
switch (_that) {
case _BranchConfig() when $default != null:
return $default(_that.branchId,_that.displayName,_that.collarOffsetCm,_that.ladiesMedalAnchor,_that.sikhTurbanLogic,_that.dressCodes,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BranchConfig implements BranchConfig {
  const _BranchConfig({required this.branchId, required this.displayName, required this.collarOffsetCm, required this.ladiesMedalAnchor, required this.sikhTurbanLogic, required final  List<DressCode> dressCodes, this.version = 1}): _dressCodes = dressCodes;
  factory _BranchConfig.fromJson(Map<String, dynamic> json) => _$BranchConfigFromJson(json);

@override final  BranchId branchId;
@override final  String displayName;
@override final  double collarOffsetCm;
@override final  MedalAnchor ladiesMedalAnchor;
@override final  SikhTurbanLogic sikhTurbanLogic;
 final  List<DressCode> _dressCodes;
@override List<DressCode> get dressCodes {
  if (_dressCodes is EqualUnmodifiableListView) return _dressCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dressCodes);
}

@override@JsonKey() final  int version;

/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BranchConfigCopyWith<_BranchConfig> get copyWith => __$BranchConfigCopyWithImpl<_BranchConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BranchConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BranchConfig&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.collarOffsetCm, collarOffsetCm) || other.collarOffsetCm == collarOffsetCm)&&(identical(other.ladiesMedalAnchor, ladiesMedalAnchor) || other.ladiesMedalAnchor == ladiesMedalAnchor)&&(identical(other.sikhTurbanLogic, sikhTurbanLogic) || other.sikhTurbanLogic == sikhTurbanLogic)&&const DeepCollectionEquality().equals(other._dressCodes, _dressCodes)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,branchId,displayName,collarOffsetCm,ladiesMedalAnchor,sikhTurbanLogic,const DeepCollectionEquality().hash(_dressCodes),version);

@override
String toString() {
  return 'BranchConfig(branchId: $branchId, displayName: $displayName, collarOffsetCm: $collarOffsetCm, ladiesMedalAnchor: $ladiesMedalAnchor, sikhTurbanLogic: $sikhTurbanLogic, dressCodes: $dressCodes, version: $version)';
}


}

/// @nodoc
abstract mixin class _$BranchConfigCopyWith<$Res> implements $BranchConfigCopyWith<$Res> {
  factory _$BranchConfigCopyWith(_BranchConfig value, $Res Function(_BranchConfig) _then) = __$BranchConfigCopyWithImpl;
@override @useResult
$Res call({
 BranchId branchId, String displayName, double collarOffsetCm, MedalAnchor ladiesMedalAnchor, SikhTurbanLogic sikhTurbanLogic, List<DressCode> dressCodes, int version
});


@override $MedalAnchorCopyWith<$Res> get ladiesMedalAnchor;@override $SikhTurbanLogicCopyWith<$Res> get sikhTurbanLogic;

}
/// @nodoc
class __$BranchConfigCopyWithImpl<$Res>
    implements _$BranchConfigCopyWith<$Res> {
  __$BranchConfigCopyWithImpl(this._self, this._then);

  final _BranchConfig _self;
  final $Res Function(_BranchConfig) _then;

/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branchId = null,Object? displayName = null,Object? collarOffsetCm = null,Object? ladiesMedalAnchor = null,Object? sikhTurbanLogic = null,Object? dressCodes = null,Object? version = null,}) {
  return _then(_BranchConfig(
branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as BranchId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,collarOffsetCm: null == collarOffsetCm ? _self.collarOffsetCm : collarOffsetCm // ignore: cast_nullable_to_non_nullable
as double,ladiesMedalAnchor: null == ladiesMedalAnchor ? _self.ladiesMedalAnchor : ladiesMedalAnchor // ignore: cast_nullable_to_non_nullable
as MedalAnchor,sikhTurbanLogic: null == sikhTurbanLogic ? _self.sikhTurbanLogic : sikhTurbanLogic // ignore: cast_nullable_to_non_nullable
as SikhTurbanLogic,dressCodes: null == dressCodes ? _self._dressCodes : dressCodes // ignore: cast_nullable_to_non_nullable
as List<DressCode>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MedalAnchorCopyWith<$Res> get ladiesMedalAnchor {
  
  return $MedalAnchorCopyWith<$Res>(_self.ladiesMedalAnchor, (value) {
    return _then(_self.copyWith(ladiesMedalAnchor: value));
  });
}/// Create a copy of BranchConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SikhTurbanLogicCopyWith<$Res> get sikhTurbanLogic {
  
  return $SikhTurbanLogicCopyWith<$Res>(_self.sikhTurbanLogic, (value) {
    return _then(_self.copyWith(sikhTurbanLogic: value));
  });
}
}

// dart format on

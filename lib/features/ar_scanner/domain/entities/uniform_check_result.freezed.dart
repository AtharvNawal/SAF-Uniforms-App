// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'uniform_check_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UniformCheckPoint {

 double get x; double get y;
/// Create a copy of UniformCheckPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniformCheckPointCopyWith<UniformCheckPoint> get copyWith => _$UniformCheckPointCopyWithImpl<UniformCheckPoint>(this as UniformCheckPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniformCheckPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'UniformCheckPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $UniformCheckPointCopyWith<$Res>  {
  factory $UniformCheckPointCopyWith(UniformCheckPoint value, $Res Function(UniformCheckPoint) _then) = _$UniformCheckPointCopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$UniformCheckPointCopyWithImpl<$Res>
    implements $UniformCheckPointCopyWith<$Res> {
  _$UniformCheckPointCopyWithImpl(this._self, this._then);

  final UniformCheckPoint _self;
  final $Res Function(UniformCheckPoint) _then;

/// Create a copy of UniformCheckPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UniformCheckPoint].
extension UniformCheckPointPatterns on UniformCheckPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UniformCheckPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UniformCheckPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UniformCheckPoint value)  $default,){
final _that = this;
switch (_that) {
case _UniformCheckPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UniformCheckPoint value)?  $default,){
final _that = this;
switch (_that) {
case _UniformCheckPoint() when $default != null:
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
case _UniformCheckPoint() when $default != null:
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
case _UniformCheckPoint():
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
case _UniformCheckPoint() when $default != null:
return $default(_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc


class _UniformCheckPoint implements UniformCheckPoint {
  const _UniformCheckPoint({required this.x, required this.y});
  

@override final  double x;
@override final  double y;

/// Create a copy of UniformCheckPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniformCheckPointCopyWith<_UniformCheckPoint> get copyWith => __$UniformCheckPointCopyWithImpl<_UniformCheckPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UniformCheckPoint&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}


@override
int get hashCode => Object.hash(runtimeType,x,y);

@override
String toString() {
  return 'UniformCheckPoint(x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$UniformCheckPointCopyWith<$Res> implements $UniformCheckPointCopyWith<$Res> {
  factory _$UniformCheckPointCopyWith(_UniformCheckPoint value, $Res Function(_UniformCheckPoint) _then) = __$UniformCheckPointCopyWithImpl;
@override @useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class __$UniformCheckPointCopyWithImpl<$Res>
    implements _$UniformCheckPointCopyWith<$Res> {
  __$UniformCheckPointCopyWithImpl(this._self, this._then);

  final _UniformCheckPoint _self;
  final $Res Function(_UniformCheckPoint) _then;

/// Create a copy of UniformCheckPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,}) {
  return _then(_UniformCheckPoint(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$UniformCheckBox {

 double get x; double get y; double get width; double get height;
/// Create a copy of UniformCheckBox
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniformCheckBoxCopyWith<UniformCheckBox> get copyWith => _$UniformCheckBoxCopyWithImpl<UniformCheckBox>(this as UniformCheckBox, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniformCheckBox&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'UniformCheckBox(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $UniformCheckBoxCopyWith<$Res>  {
  factory $UniformCheckBoxCopyWith(UniformCheckBox value, $Res Function(UniformCheckBox) _then) = _$UniformCheckBoxCopyWithImpl;
@useResult
$Res call({
 double x, double y, double width, double height
});




}
/// @nodoc
class _$UniformCheckBoxCopyWithImpl<$Res>
    implements $UniformCheckBoxCopyWith<$Res> {
  _$UniformCheckBoxCopyWithImpl(this._self, this._then);

  final UniformCheckBox _self;
  final $Res Function(UniformCheckBox) _then;

/// Create a copy of UniformCheckBox
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UniformCheckBox].
extension UniformCheckBoxPatterns on UniformCheckBox {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UniformCheckBox value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UniformCheckBox() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UniformCheckBox value)  $default,){
final _that = this;
switch (_that) {
case _UniformCheckBox():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UniformCheckBox value)?  $default,){
final _that = this;
switch (_that) {
case _UniformCheckBox() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y,  double width,  double height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UniformCheckBox() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y,  double width,  double height)  $default,) {final _that = this;
switch (_that) {
case _UniformCheckBox():
return $default(_that.x,_that.y,_that.width,_that.height);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y,  double width,  double height)?  $default,) {final _that = this;
switch (_that) {
case _UniformCheckBox() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc


class _UniformCheckBox implements UniformCheckBox {
  const _UniformCheckBox({required this.x, required this.y, required this.width, required this.height});
  

@override final  double x;
@override final  double y;
@override final  double width;
@override final  double height;

/// Create a copy of UniformCheckBox
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniformCheckBoxCopyWith<_UniformCheckBox> get copyWith => __$UniformCheckBoxCopyWithImpl<_UniformCheckBox>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UniformCheckBox&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'UniformCheckBox(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$UniformCheckBoxCopyWith<$Res> implements $UniformCheckBoxCopyWith<$Res> {
  factory _$UniformCheckBoxCopyWith(_UniformCheckBox value, $Res Function(_UniformCheckBox) _then) = __$UniformCheckBoxCopyWithImpl;
@override @useResult
$Res call({
 double x, double y, double width, double height
});




}
/// @nodoc
class __$UniformCheckBoxCopyWithImpl<$Res>
    implements _$UniformCheckBoxCopyWith<$Res> {
  __$UniformCheckBoxCopyWithImpl(this._self, this._then);

  final _UniformCheckBox _self;
  final $Res Function(_UniformCheckBox) _then;

/// Create a copy of UniformCheckBox
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_UniformCheckBox(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$UniformCheckAccessory {

 String get name;/// `true` present, `false` missing, `null` could not determine.
 bool? get present;/// `true` in tolerance, `false` out of tolerance, `null` n/a.
 bool? get positionCorrect; double? get confidence; UniformCheckStatus get status;/// `FULL` / `PARTIAL` / `NONE` — how much of the region was in frame.
 String get visibility; UniformCheckBox? get boundingBox; UniformCheckPoint? get expectedPosition; UniformCheckPoint? get detectedPosition;/// (dx, dy) pixel offset of detected from expected, when both known.
 UniformCheckPoint? get error; String get doctrineRef; String get message;/// What the wearer should do, in cm and their own left/right
/// (`cv-service/api/instructions.py`).
 String get instruction;/// Doctrine requires this item for the wearer's profile.
 bool get required;/// The service can detect this item at all — `false` for items with
/// no detector yet (checked by eye, never counted against coverage).
 bool get checkable;/// `trained` | `two_stage` | `zero_shot` — which detector found it.
 String? get detectionSource;/// Burst only — how many usable frames agreed, e.g. `2/3`.
 String? get frameAgreement;
/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniformCheckAccessoryCopyWith<UniformCheckAccessory> get copyWith => _$UniformCheckAccessoryCopyWithImpl<UniformCheckAccessory>(this as UniformCheckAccessory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniformCheckAccessory&&(identical(other.name, name) || other.name == name)&&(identical(other.present, present) || other.present == present)&&(identical(other.positionCorrect, positionCorrect) || other.positionCorrect == positionCorrect)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.boundingBox, boundingBox) || other.boundingBox == boundingBox)&&(identical(other.expectedPosition, expectedPosition) || other.expectedPosition == expectedPosition)&&(identical(other.detectedPosition, detectedPosition) || other.detectedPosition == detectedPosition)&&(identical(other.error, error) || other.error == error)&&(identical(other.doctrineRef, doctrineRef) || other.doctrineRef == doctrineRef)&&(identical(other.message, message) || other.message == message)&&(identical(other.instruction, instruction) || other.instruction == instruction)&&(identical(other.required, required) || other.required == required)&&(identical(other.checkable, checkable) || other.checkable == checkable)&&(identical(other.detectionSource, detectionSource) || other.detectionSource == detectionSource)&&(identical(other.frameAgreement, frameAgreement) || other.frameAgreement == frameAgreement));
}


@override
int get hashCode => Object.hash(runtimeType,name,present,positionCorrect,confidence,status,visibility,boundingBox,expectedPosition,detectedPosition,error,doctrineRef,message,instruction,required,checkable,detectionSource,frameAgreement);

@override
String toString() {
  return 'UniformCheckAccessory(name: $name, present: $present, positionCorrect: $positionCorrect, confidence: $confidence, status: $status, visibility: $visibility, boundingBox: $boundingBox, expectedPosition: $expectedPosition, detectedPosition: $detectedPosition, error: $error, doctrineRef: $doctrineRef, message: $message, instruction: $instruction, required: $required, checkable: $checkable, detectionSource: $detectionSource, frameAgreement: $frameAgreement)';
}


}

/// @nodoc
abstract mixin class $UniformCheckAccessoryCopyWith<$Res>  {
  factory $UniformCheckAccessoryCopyWith(UniformCheckAccessory value, $Res Function(UniformCheckAccessory) _then) = _$UniformCheckAccessoryCopyWithImpl;
@useResult
$Res call({
 String name, bool? present, bool? positionCorrect, double? confidence, UniformCheckStatus status, String visibility, UniformCheckBox? boundingBox, UniformCheckPoint? expectedPosition, UniformCheckPoint? detectedPosition, UniformCheckPoint? error, String doctrineRef, String message, String instruction, bool required, bool checkable, String? detectionSource, String? frameAgreement
});


$UniformCheckBoxCopyWith<$Res>? get boundingBox;$UniformCheckPointCopyWith<$Res>? get expectedPosition;$UniformCheckPointCopyWith<$Res>? get detectedPosition;$UniformCheckPointCopyWith<$Res>? get error;

}
/// @nodoc
class _$UniformCheckAccessoryCopyWithImpl<$Res>
    implements $UniformCheckAccessoryCopyWith<$Res> {
  _$UniformCheckAccessoryCopyWithImpl(this._self, this._then);

  final UniformCheckAccessory _self;
  final $Res Function(UniformCheckAccessory) _then;

/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? present = freezed,Object? positionCorrect = freezed,Object? confidence = freezed,Object? status = null,Object? visibility = null,Object? boundingBox = freezed,Object? expectedPosition = freezed,Object? detectedPosition = freezed,Object? error = freezed,Object? doctrineRef = null,Object? message = null,Object? instruction = null,Object? required = null,Object? checkable = null,Object? detectionSource = freezed,Object? frameAgreement = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,present: freezed == present ? _self.present : present // ignore: cast_nullable_to_non_nullable
as bool?,positionCorrect: freezed == positionCorrect ? _self.positionCorrect : positionCorrect // ignore: cast_nullable_to_non_nullable
as bool?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UniformCheckStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,boundingBox: freezed == boundingBox ? _self.boundingBox : boundingBox // ignore: cast_nullable_to_non_nullable
as UniformCheckBox?,expectedPosition: freezed == expectedPosition ? _self.expectedPosition : expectedPosition // ignore: cast_nullable_to_non_nullable
as UniformCheckPoint?,detectedPosition: freezed == detectedPosition ? _self.detectedPosition : detectedPosition // ignore: cast_nullable_to_non_nullable
as UniformCheckPoint?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as UniformCheckPoint?,doctrineRef: null == doctrineRef ? _self.doctrineRef : doctrineRef // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,checkable: null == checkable ? _self.checkable : checkable // ignore: cast_nullable_to_non_nullable
as bool,detectionSource: freezed == detectionSource ? _self.detectionSource : detectionSource // ignore: cast_nullable_to_non_nullable
as String?,frameAgreement: freezed == frameAgreement ? _self.frameAgreement : frameAgreement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckBoxCopyWith<$Res>? get boundingBox {
    if (_self.boundingBox == null) {
    return null;
  }

  return $UniformCheckBoxCopyWith<$Res>(_self.boundingBox!, (value) {
    return _then(_self.copyWith(boundingBox: value));
  });
}/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckPointCopyWith<$Res>? get expectedPosition {
    if (_self.expectedPosition == null) {
    return null;
  }

  return $UniformCheckPointCopyWith<$Res>(_self.expectedPosition!, (value) {
    return _then(_self.copyWith(expectedPosition: value));
  });
}/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckPointCopyWith<$Res>? get detectedPosition {
    if (_self.detectedPosition == null) {
    return null;
  }

  return $UniformCheckPointCopyWith<$Res>(_self.detectedPosition!, (value) {
    return _then(_self.copyWith(detectedPosition: value));
  });
}/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckPointCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $UniformCheckPointCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// Adds pattern-matching-related methods to [UniformCheckAccessory].
extension UniformCheckAccessoryPatterns on UniformCheckAccessory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UniformCheckAccessory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UniformCheckAccessory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UniformCheckAccessory value)  $default,){
final _that = this;
switch (_that) {
case _UniformCheckAccessory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UniformCheckAccessory value)?  $default,){
final _that = this;
switch (_that) {
case _UniformCheckAccessory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool? present,  bool? positionCorrect,  double? confidence,  UniformCheckStatus status,  String visibility,  UniformCheckBox? boundingBox,  UniformCheckPoint? expectedPosition,  UniformCheckPoint? detectedPosition,  UniformCheckPoint? error,  String doctrineRef,  String message,  String instruction,  bool required,  bool checkable,  String? detectionSource,  String? frameAgreement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UniformCheckAccessory() when $default != null:
return $default(_that.name,_that.present,_that.positionCorrect,_that.confidence,_that.status,_that.visibility,_that.boundingBox,_that.expectedPosition,_that.detectedPosition,_that.error,_that.doctrineRef,_that.message,_that.instruction,_that.required,_that.checkable,_that.detectionSource,_that.frameAgreement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool? present,  bool? positionCorrect,  double? confidence,  UniformCheckStatus status,  String visibility,  UniformCheckBox? boundingBox,  UniformCheckPoint? expectedPosition,  UniformCheckPoint? detectedPosition,  UniformCheckPoint? error,  String doctrineRef,  String message,  String instruction,  bool required,  bool checkable,  String? detectionSource,  String? frameAgreement)  $default,) {final _that = this;
switch (_that) {
case _UniformCheckAccessory():
return $default(_that.name,_that.present,_that.positionCorrect,_that.confidence,_that.status,_that.visibility,_that.boundingBox,_that.expectedPosition,_that.detectedPosition,_that.error,_that.doctrineRef,_that.message,_that.instruction,_that.required,_that.checkable,_that.detectionSource,_that.frameAgreement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool? present,  bool? positionCorrect,  double? confidence,  UniformCheckStatus status,  String visibility,  UniformCheckBox? boundingBox,  UniformCheckPoint? expectedPosition,  UniformCheckPoint? detectedPosition,  UniformCheckPoint? error,  String doctrineRef,  String message,  String instruction,  bool required,  bool checkable,  String? detectionSource,  String? frameAgreement)?  $default,) {final _that = this;
switch (_that) {
case _UniformCheckAccessory() when $default != null:
return $default(_that.name,_that.present,_that.positionCorrect,_that.confidence,_that.status,_that.visibility,_that.boundingBox,_that.expectedPosition,_that.detectedPosition,_that.error,_that.doctrineRef,_that.message,_that.instruction,_that.required,_that.checkable,_that.detectionSource,_that.frameAgreement);case _:
  return null;

}
}

}

/// @nodoc


class _UniformCheckAccessory extends UniformCheckAccessory {
  const _UniformCheckAccessory({required this.name, this.present, this.positionCorrect, this.confidence, required this.status, required this.visibility, this.boundingBox, this.expectedPosition, this.detectedPosition, this.error, this.doctrineRef = '', this.message = '', this.instruction = '', this.required = false, this.checkable = true, this.detectionSource, this.frameAgreement}): super._();
  

@override final  String name;
/// `true` present, `false` missing, `null` could not determine.
@override final  bool? present;
/// `true` in tolerance, `false` out of tolerance, `null` n/a.
@override final  bool? positionCorrect;
@override final  double? confidence;
@override final  UniformCheckStatus status;
/// `FULL` / `PARTIAL` / `NONE` — how much of the region was in frame.
@override final  String visibility;
@override final  UniformCheckBox? boundingBox;
@override final  UniformCheckPoint? expectedPosition;
@override final  UniformCheckPoint? detectedPosition;
/// (dx, dy) pixel offset of detected from expected, when both known.
@override final  UniformCheckPoint? error;
@override@JsonKey() final  String doctrineRef;
@override@JsonKey() final  String message;
/// What the wearer should do, in cm and their own left/right
/// (`cv-service/api/instructions.py`).
@override@JsonKey() final  String instruction;
/// Doctrine requires this item for the wearer's profile.
@override@JsonKey() final  bool required;
/// The service can detect this item at all — `false` for items with
/// no detector yet (checked by eye, never counted against coverage).
@override@JsonKey() final  bool checkable;
/// `trained` | `two_stage` | `zero_shot` — which detector found it.
@override final  String? detectionSource;
/// Burst only — how many usable frames agreed, e.g. `2/3`.
@override final  String? frameAgreement;

/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniformCheckAccessoryCopyWith<_UniformCheckAccessory> get copyWith => __$UniformCheckAccessoryCopyWithImpl<_UniformCheckAccessory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UniformCheckAccessory&&(identical(other.name, name) || other.name == name)&&(identical(other.present, present) || other.present == present)&&(identical(other.positionCorrect, positionCorrect) || other.positionCorrect == positionCorrect)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.status, status) || other.status == status)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.boundingBox, boundingBox) || other.boundingBox == boundingBox)&&(identical(other.expectedPosition, expectedPosition) || other.expectedPosition == expectedPosition)&&(identical(other.detectedPosition, detectedPosition) || other.detectedPosition == detectedPosition)&&(identical(other.error, error) || other.error == error)&&(identical(other.doctrineRef, doctrineRef) || other.doctrineRef == doctrineRef)&&(identical(other.message, message) || other.message == message)&&(identical(other.instruction, instruction) || other.instruction == instruction)&&(identical(other.required, required) || other.required == required)&&(identical(other.checkable, checkable) || other.checkable == checkable)&&(identical(other.detectionSource, detectionSource) || other.detectionSource == detectionSource)&&(identical(other.frameAgreement, frameAgreement) || other.frameAgreement == frameAgreement));
}


@override
int get hashCode => Object.hash(runtimeType,name,present,positionCorrect,confidence,status,visibility,boundingBox,expectedPosition,detectedPosition,error,doctrineRef,message,instruction,required,checkable,detectionSource,frameAgreement);

@override
String toString() {
  return 'UniformCheckAccessory(name: $name, present: $present, positionCorrect: $positionCorrect, confidence: $confidence, status: $status, visibility: $visibility, boundingBox: $boundingBox, expectedPosition: $expectedPosition, detectedPosition: $detectedPosition, error: $error, doctrineRef: $doctrineRef, message: $message, instruction: $instruction, required: $required, checkable: $checkable, detectionSource: $detectionSource, frameAgreement: $frameAgreement)';
}


}

/// @nodoc
abstract mixin class _$UniformCheckAccessoryCopyWith<$Res> implements $UniformCheckAccessoryCopyWith<$Res> {
  factory _$UniformCheckAccessoryCopyWith(_UniformCheckAccessory value, $Res Function(_UniformCheckAccessory) _then) = __$UniformCheckAccessoryCopyWithImpl;
@override @useResult
$Res call({
 String name, bool? present, bool? positionCorrect, double? confidence, UniformCheckStatus status, String visibility, UniformCheckBox? boundingBox, UniformCheckPoint? expectedPosition, UniformCheckPoint? detectedPosition, UniformCheckPoint? error, String doctrineRef, String message, String instruction, bool required, bool checkable, String? detectionSource, String? frameAgreement
});


@override $UniformCheckBoxCopyWith<$Res>? get boundingBox;@override $UniformCheckPointCopyWith<$Res>? get expectedPosition;@override $UniformCheckPointCopyWith<$Res>? get detectedPosition;@override $UniformCheckPointCopyWith<$Res>? get error;

}
/// @nodoc
class __$UniformCheckAccessoryCopyWithImpl<$Res>
    implements _$UniformCheckAccessoryCopyWith<$Res> {
  __$UniformCheckAccessoryCopyWithImpl(this._self, this._then);

  final _UniformCheckAccessory _self;
  final $Res Function(_UniformCheckAccessory) _then;

/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? present = freezed,Object? positionCorrect = freezed,Object? confidence = freezed,Object? status = null,Object? visibility = null,Object? boundingBox = freezed,Object? expectedPosition = freezed,Object? detectedPosition = freezed,Object? error = freezed,Object? doctrineRef = null,Object? message = null,Object? instruction = null,Object? required = null,Object? checkable = null,Object? detectionSource = freezed,Object? frameAgreement = freezed,}) {
  return _then(_UniformCheckAccessory(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,present: freezed == present ? _self.present : present // ignore: cast_nullable_to_non_nullable
as bool?,positionCorrect: freezed == positionCorrect ? _self.positionCorrect : positionCorrect // ignore: cast_nullable_to_non_nullable
as bool?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UniformCheckStatus,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,boundingBox: freezed == boundingBox ? _self.boundingBox : boundingBox // ignore: cast_nullable_to_non_nullable
as UniformCheckBox?,expectedPosition: freezed == expectedPosition ? _self.expectedPosition : expectedPosition // ignore: cast_nullable_to_non_nullable
as UniformCheckPoint?,detectedPosition: freezed == detectedPosition ? _self.detectedPosition : detectedPosition // ignore: cast_nullable_to_non_nullable
as UniformCheckPoint?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as UniformCheckPoint?,doctrineRef: null == doctrineRef ? _self.doctrineRef : doctrineRef // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,checkable: null == checkable ? _self.checkable : checkable // ignore: cast_nullable_to_non_nullable
as bool,detectionSource: freezed == detectionSource ? _self.detectionSource : detectionSource // ignore: cast_nullable_to_non_nullable
as String?,frameAgreement: freezed == frameAgreement ? _self.frameAgreement : frameAgreement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckBoxCopyWith<$Res>? get boundingBox {
    if (_self.boundingBox == null) {
    return null;
  }

  return $UniformCheckBoxCopyWith<$Res>(_self.boundingBox!, (value) {
    return _then(_self.copyWith(boundingBox: value));
  });
}/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckPointCopyWith<$Res>? get expectedPosition {
    if (_self.expectedPosition == null) {
    return null;
  }

  return $UniformCheckPointCopyWith<$Res>(_self.expectedPosition!, (value) {
    return _then(_self.copyWith(expectedPosition: value));
  });
}/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckPointCopyWith<$Res>? get detectedPosition {
    if (_self.detectedPosition == null) {
    return null;
  }

  return $UniformCheckPointCopyWith<$Res>(_self.detectedPosition!, (value) {
    return _then(_self.copyWith(detectedPosition: value));
  });
}/// Create a copy of UniformCheckAccessory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckPointCopyWith<$Res>? get error {
    if (_self.error == null) {
    return null;
  }

  return $UniformCheckPointCopyWith<$Res>(_self.error!, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

/// @nodoc
mixin _$UniformCheckSummary {

 int get detectedAccessories; int get correct; int get incorrect; int get slightlyMisaligned; int get missing; int get uncertain; int get requiredAccessories;
/// Create a copy of UniformCheckSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniformCheckSummaryCopyWith<UniformCheckSummary> get copyWith => _$UniformCheckSummaryCopyWithImpl<UniformCheckSummary>(this as UniformCheckSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniformCheckSummary&&(identical(other.detectedAccessories, detectedAccessories) || other.detectedAccessories == detectedAccessories)&&(identical(other.correct, correct) || other.correct == correct)&&(identical(other.incorrect, incorrect) || other.incorrect == incorrect)&&(identical(other.slightlyMisaligned, slightlyMisaligned) || other.slightlyMisaligned == slightlyMisaligned)&&(identical(other.missing, missing) || other.missing == missing)&&(identical(other.uncertain, uncertain) || other.uncertain == uncertain)&&(identical(other.requiredAccessories, requiredAccessories) || other.requiredAccessories == requiredAccessories));
}


@override
int get hashCode => Object.hash(runtimeType,detectedAccessories,correct,incorrect,slightlyMisaligned,missing,uncertain,requiredAccessories);

@override
String toString() {
  return 'UniformCheckSummary(detectedAccessories: $detectedAccessories, correct: $correct, incorrect: $incorrect, slightlyMisaligned: $slightlyMisaligned, missing: $missing, uncertain: $uncertain, requiredAccessories: $requiredAccessories)';
}


}

/// @nodoc
abstract mixin class $UniformCheckSummaryCopyWith<$Res>  {
  factory $UniformCheckSummaryCopyWith(UniformCheckSummary value, $Res Function(UniformCheckSummary) _then) = _$UniformCheckSummaryCopyWithImpl;
@useResult
$Res call({
 int detectedAccessories, int correct, int incorrect, int slightlyMisaligned, int missing, int uncertain, int requiredAccessories
});




}
/// @nodoc
class _$UniformCheckSummaryCopyWithImpl<$Res>
    implements $UniformCheckSummaryCopyWith<$Res> {
  _$UniformCheckSummaryCopyWithImpl(this._self, this._then);

  final UniformCheckSummary _self;
  final $Res Function(UniformCheckSummary) _then;

/// Create a copy of UniformCheckSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? detectedAccessories = null,Object? correct = null,Object? incorrect = null,Object? slightlyMisaligned = null,Object? missing = null,Object? uncertain = null,Object? requiredAccessories = null,}) {
  return _then(_self.copyWith(
detectedAccessories: null == detectedAccessories ? _self.detectedAccessories : detectedAccessories // ignore: cast_nullable_to_non_nullable
as int,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as int,incorrect: null == incorrect ? _self.incorrect : incorrect // ignore: cast_nullable_to_non_nullable
as int,slightlyMisaligned: null == slightlyMisaligned ? _self.slightlyMisaligned : slightlyMisaligned // ignore: cast_nullable_to_non_nullable
as int,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as int,uncertain: null == uncertain ? _self.uncertain : uncertain // ignore: cast_nullable_to_non_nullable
as int,requiredAccessories: null == requiredAccessories ? _self.requiredAccessories : requiredAccessories // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UniformCheckSummary].
extension UniformCheckSummaryPatterns on UniformCheckSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UniformCheckSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UniformCheckSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UniformCheckSummary value)  $default,){
final _that = this;
switch (_that) {
case _UniformCheckSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UniformCheckSummary value)?  $default,){
final _that = this;
switch (_that) {
case _UniformCheckSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int detectedAccessories,  int correct,  int incorrect,  int slightlyMisaligned,  int missing,  int uncertain,  int requiredAccessories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UniformCheckSummary() when $default != null:
return $default(_that.detectedAccessories,_that.correct,_that.incorrect,_that.slightlyMisaligned,_that.missing,_that.uncertain,_that.requiredAccessories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int detectedAccessories,  int correct,  int incorrect,  int slightlyMisaligned,  int missing,  int uncertain,  int requiredAccessories)  $default,) {final _that = this;
switch (_that) {
case _UniformCheckSummary():
return $default(_that.detectedAccessories,_that.correct,_that.incorrect,_that.slightlyMisaligned,_that.missing,_that.uncertain,_that.requiredAccessories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int detectedAccessories,  int correct,  int incorrect,  int slightlyMisaligned,  int missing,  int uncertain,  int requiredAccessories)?  $default,) {final _that = this;
switch (_that) {
case _UniformCheckSummary() when $default != null:
return $default(_that.detectedAccessories,_that.correct,_that.incorrect,_that.slightlyMisaligned,_that.missing,_that.uncertain,_that.requiredAccessories);case _:
  return null;

}
}

}

/// @nodoc


class _UniformCheckSummary implements UniformCheckSummary {
  const _UniformCheckSummary({this.detectedAccessories = 0, this.correct = 0, this.incorrect = 0, this.slightlyMisaligned = 0, this.missing = 0, this.uncertain = 0, this.requiredAccessories = 0});
  

@override@JsonKey() final  int detectedAccessories;
@override@JsonKey() final  int correct;
@override@JsonKey() final  int incorrect;
@override@JsonKey() final  int slightlyMisaligned;
@override@JsonKey() final  int missing;
@override@JsonKey() final  int uncertain;
@override@JsonKey() final  int requiredAccessories;

/// Create a copy of UniformCheckSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniformCheckSummaryCopyWith<_UniformCheckSummary> get copyWith => __$UniformCheckSummaryCopyWithImpl<_UniformCheckSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UniformCheckSummary&&(identical(other.detectedAccessories, detectedAccessories) || other.detectedAccessories == detectedAccessories)&&(identical(other.correct, correct) || other.correct == correct)&&(identical(other.incorrect, incorrect) || other.incorrect == incorrect)&&(identical(other.slightlyMisaligned, slightlyMisaligned) || other.slightlyMisaligned == slightlyMisaligned)&&(identical(other.missing, missing) || other.missing == missing)&&(identical(other.uncertain, uncertain) || other.uncertain == uncertain)&&(identical(other.requiredAccessories, requiredAccessories) || other.requiredAccessories == requiredAccessories));
}


@override
int get hashCode => Object.hash(runtimeType,detectedAccessories,correct,incorrect,slightlyMisaligned,missing,uncertain,requiredAccessories);

@override
String toString() {
  return 'UniformCheckSummary(detectedAccessories: $detectedAccessories, correct: $correct, incorrect: $incorrect, slightlyMisaligned: $slightlyMisaligned, missing: $missing, uncertain: $uncertain, requiredAccessories: $requiredAccessories)';
}


}

/// @nodoc
abstract mixin class _$UniformCheckSummaryCopyWith<$Res> implements $UniformCheckSummaryCopyWith<$Res> {
  factory _$UniformCheckSummaryCopyWith(_UniformCheckSummary value, $Res Function(_UniformCheckSummary) _then) = __$UniformCheckSummaryCopyWithImpl;
@override @useResult
$Res call({
 int detectedAccessories, int correct, int incorrect, int slightlyMisaligned, int missing, int uncertain, int requiredAccessories
});




}
/// @nodoc
class __$UniformCheckSummaryCopyWithImpl<$Res>
    implements _$UniformCheckSummaryCopyWith<$Res> {
  __$UniformCheckSummaryCopyWithImpl(this._self, this._then);

  final _UniformCheckSummary _self;
  final $Res Function(_UniformCheckSummary) _then;

/// Create a copy of UniformCheckSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? detectedAccessories = null,Object? correct = null,Object? incorrect = null,Object? slightlyMisaligned = null,Object? missing = null,Object? uncertain = null,Object? requiredAccessories = null,}) {
  return _then(_UniformCheckSummary(
detectedAccessories: null == detectedAccessories ? _self.detectedAccessories : detectedAccessories // ignore: cast_nullable_to_non_nullable
as int,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as int,incorrect: null == incorrect ? _self.incorrect : incorrect // ignore: cast_nullable_to_non_nullable
as int,slightlyMisaligned: null == slightlyMisaligned ? _self.slightlyMisaligned : slightlyMisaligned // ignore: cast_nullable_to_non_nullable
as int,missing: null == missing ? _self.missing : missing // ignore: cast_nullable_to_non_nullable
as int,uncertain: null == uncertain ? _self.uncertain : uncertain // ignore: cast_nullable_to_non_nullable
as int,requiredAccessories: null == requiredAccessories ? _self.requiredAccessories : requiredAccessories // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$UniformCheckResult {

 bool get success;/// `PASS` / `FAIL` / `INCOMPLETE` (too few checkable required items
/// could be verified from this photo to call it either way — see
/// `ChangeRequest/2026-09-28_cv-service-coverage-gate-and-matching.md`).
 String get overallStatus;/// 0–100, computed over required items only (unverifiable excluded).
 double get overallScore; bool get imageQualityUsable; double get imageQualityConfidence; bool get personDetected; double get personConfidence; List<UniformCheckAccessory> get accessories; UniformCheckSummary get summary;/// Required items the service can detect / of those, how many got a
/// definite verdict / required items it can't detect at all.
 int get checkableRequired; int get verifiedRequired; int get notCheckableRequired;/// PNG overlay (base64) of expected vs detected positions.
 String? get debugImageBase64;/// Burst only — frames sent / frames the service could use.
 int? get burstFrames; int? get burstUsableFrames;/// `exif_35mm` | `client` | `assumed` … — where the camera focal length
/// came from (`assumed` = less accurate distances).
 String? get focalSource;
/// Create a copy of UniformCheckResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniformCheckResultCopyWith<UniformCheckResult> get copyWith => _$UniformCheckResultCopyWithImpl<UniformCheckResult>(this as UniformCheckResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniformCheckResult&&(identical(other.success, success) || other.success == success)&&(identical(other.overallStatus, overallStatus) || other.overallStatus == overallStatus)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.imageQualityUsable, imageQualityUsable) || other.imageQualityUsable == imageQualityUsable)&&(identical(other.imageQualityConfidence, imageQualityConfidence) || other.imageQualityConfidence == imageQualityConfidence)&&(identical(other.personDetected, personDetected) || other.personDetected == personDetected)&&(identical(other.personConfidence, personConfidence) || other.personConfidence == personConfidence)&&const DeepCollectionEquality().equals(other.accessories, accessories)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.checkableRequired, checkableRequired) || other.checkableRequired == checkableRequired)&&(identical(other.verifiedRequired, verifiedRequired) || other.verifiedRequired == verifiedRequired)&&(identical(other.notCheckableRequired, notCheckableRequired) || other.notCheckableRequired == notCheckableRequired)&&(identical(other.debugImageBase64, debugImageBase64) || other.debugImageBase64 == debugImageBase64)&&(identical(other.burstFrames, burstFrames) || other.burstFrames == burstFrames)&&(identical(other.burstUsableFrames, burstUsableFrames) || other.burstUsableFrames == burstUsableFrames)&&(identical(other.focalSource, focalSource) || other.focalSource == focalSource));
}


@override
int get hashCode => Object.hash(runtimeType,success,overallStatus,overallScore,imageQualityUsable,imageQualityConfidence,personDetected,personConfidence,const DeepCollectionEquality().hash(accessories),summary,checkableRequired,verifiedRequired,notCheckableRequired,debugImageBase64,burstFrames,burstUsableFrames,focalSource);

@override
String toString() {
  return 'UniformCheckResult(success: $success, overallStatus: $overallStatus, overallScore: $overallScore, imageQualityUsable: $imageQualityUsable, imageQualityConfidence: $imageQualityConfidence, personDetected: $personDetected, personConfidence: $personConfidence, accessories: $accessories, summary: $summary, checkableRequired: $checkableRequired, verifiedRequired: $verifiedRequired, notCheckableRequired: $notCheckableRequired, debugImageBase64: $debugImageBase64, burstFrames: $burstFrames, burstUsableFrames: $burstUsableFrames, focalSource: $focalSource)';
}


}

/// @nodoc
abstract mixin class $UniformCheckResultCopyWith<$Res>  {
  factory $UniformCheckResultCopyWith(UniformCheckResult value, $Res Function(UniformCheckResult) _then) = _$UniformCheckResultCopyWithImpl;
@useResult
$Res call({
 bool success, String overallStatus, double overallScore, bool imageQualityUsable, double imageQualityConfidence, bool personDetected, double personConfidence, List<UniformCheckAccessory> accessories, UniformCheckSummary summary, int checkableRequired, int verifiedRequired, int notCheckableRequired, String? debugImageBase64, int? burstFrames, int? burstUsableFrames, String? focalSource
});


$UniformCheckSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$UniformCheckResultCopyWithImpl<$Res>
    implements $UniformCheckResultCopyWith<$Res> {
  _$UniformCheckResultCopyWithImpl(this._self, this._then);

  final UniformCheckResult _self;
  final $Res Function(UniformCheckResult) _then;

/// Create a copy of UniformCheckResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? overallStatus = null,Object? overallScore = null,Object? imageQualityUsable = null,Object? imageQualityConfidence = null,Object? personDetected = null,Object? personConfidence = null,Object? accessories = null,Object? summary = null,Object? checkableRequired = null,Object? verifiedRequired = null,Object? notCheckableRequired = null,Object? debugImageBase64 = freezed,Object? burstFrames = freezed,Object? burstUsableFrames = freezed,Object? focalSource = freezed,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,overallStatus: null == overallStatus ? _self.overallStatus : overallStatus // ignore: cast_nullable_to_non_nullable
as String,overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,imageQualityUsable: null == imageQualityUsable ? _self.imageQualityUsable : imageQualityUsable // ignore: cast_nullable_to_non_nullable
as bool,imageQualityConfidence: null == imageQualityConfidence ? _self.imageQualityConfidence : imageQualityConfidence // ignore: cast_nullable_to_non_nullable
as double,personDetected: null == personDetected ? _self.personDetected : personDetected // ignore: cast_nullable_to_non_nullable
as bool,personConfidence: null == personConfidence ? _self.personConfidence : personConfidence // ignore: cast_nullable_to_non_nullable
as double,accessories: null == accessories ? _self.accessories : accessories // ignore: cast_nullable_to_non_nullable
as List<UniformCheckAccessory>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as UniformCheckSummary,checkableRequired: null == checkableRequired ? _self.checkableRequired : checkableRequired // ignore: cast_nullable_to_non_nullable
as int,verifiedRequired: null == verifiedRequired ? _self.verifiedRequired : verifiedRequired // ignore: cast_nullable_to_non_nullable
as int,notCheckableRequired: null == notCheckableRequired ? _self.notCheckableRequired : notCheckableRequired // ignore: cast_nullable_to_non_nullable
as int,debugImageBase64: freezed == debugImageBase64 ? _self.debugImageBase64 : debugImageBase64 // ignore: cast_nullable_to_non_nullable
as String?,burstFrames: freezed == burstFrames ? _self.burstFrames : burstFrames // ignore: cast_nullable_to_non_nullable
as int?,burstUsableFrames: freezed == burstUsableFrames ? _self.burstUsableFrames : burstUsableFrames // ignore: cast_nullable_to_non_nullable
as int?,focalSource: freezed == focalSource ? _self.focalSource : focalSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of UniformCheckResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckSummaryCopyWith<$Res> get summary {
  
  return $UniformCheckSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [UniformCheckResult].
extension UniformCheckResultPatterns on UniformCheckResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UniformCheckResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UniformCheckResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UniformCheckResult value)  $default,){
final _that = this;
switch (_that) {
case _UniformCheckResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UniformCheckResult value)?  $default,){
final _that = this;
switch (_that) {
case _UniformCheckResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  String overallStatus,  double overallScore,  bool imageQualityUsable,  double imageQualityConfidence,  bool personDetected,  double personConfidence,  List<UniformCheckAccessory> accessories,  UniformCheckSummary summary,  int checkableRequired,  int verifiedRequired,  int notCheckableRequired,  String? debugImageBase64,  int? burstFrames,  int? burstUsableFrames,  String? focalSource)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UniformCheckResult() when $default != null:
return $default(_that.success,_that.overallStatus,_that.overallScore,_that.imageQualityUsable,_that.imageQualityConfidence,_that.personDetected,_that.personConfidence,_that.accessories,_that.summary,_that.checkableRequired,_that.verifiedRequired,_that.notCheckableRequired,_that.debugImageBase64,_that.burstFrames,_that.burstUsableFrames,_that.focalSource);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  String overallStatus,  double overallScore,  bool imageQualityUsable,  double imageQualityConfidence,  bool personDetected,  double personConfidence,  List<UniformCheckAccessory> accessories,  UniformCheckSummary summary,  int checkableRequired,  int verifiedRequired,  int notCheckableRequired,  String? debugImageBase64,  int? burstFrames,  int? burstUsableFrames,  String? focalSource)  $default,) {final _that = this;
switch (_that) {
case _UniformCheckResult():
return $default(_that.success,_that.overallStatus,_that.overallScore,_that.imageQualityUsable,_that.imageQualityConfidence,_that.personDetected,_that.personConfidence,_that.accessories,_that.summary,_that.checkableRequired,_that.verifiedRequired,_that.notCheckableRequired,_that.debugImageBase64,_that.burstFrames,_that.burstUsableFrames,_that.focalSource);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  String overallStatus,  double overallScore,  bool imageQualityUsable,  double imageQualityConfidence,  bool personDetected,  double personConfidence,  List<UniformCheckAccessory> accessories,  UniformCheckSummary summary,  int checkableRequired,  int verifiedRequired,  int notCheckableRequired,  String? debugImageBase64,  int? burstFrames,  int? burstUsableFrames,  String? focalSource)?  $default,) {final _that = this;
switch (_that) {
case _UniformCheckResult() when $default != null:
return $default(_that.success,_that.overallStatus,_that.overallScore,_that.imageQualityUsable,_that.imageQualityConfidence,_that.personDetected,_that.personConfidence,_that.accessories,_that.summary,_that.checkableRequired,_that.verifiedRequired,_that.notCheckableRequired,_that.debugImageBase64,_that.burstFrames,_that.burstUsableFrames,_that.focalSource);case _:
  return null;

}
}

}

/// @nodoc


class _UniformCheckResult extends UniformCheckResult {
  const _UniformCheckResult({required this.success, required this.overallStatus, required this.overallScore, required this.imageQualityUsable, required this.imageQualityConfidence, required this.personDetected, required this.personConfidence, required final  List<UniformCheckAccessory> accessories, required this.summary, this.checkableRequired = 0, this.verifiedRequired = 0, this.notCheckableRequired = 0, this.debugImageBase64, this.burstFrames, this.burstUsableFrames, this.focalSource}): _accessories = accessories,super._();
  

@override final  bool success;
/// `PASS` / `FAIL` / `INCOMPLETE` (too few checkable required items
/// could be verified from this photo to call it either way — see
/// `ChangeRequest/2026-09-28_cv-service-coverage-gate-and-matching.md`).
@override final  String overallStatus;
/// 0–100, computed over required items only (unverifiable excluded).
@override final  double overallScore;
@override final  bool imageQualityUsable;
@override final  double imageQualityConfidence;
@override final  bool personDetected;
@override final  double personConfidence;
 final  List<UniformCheckAccessory> _accessories;
@override List<UniformCheckAccessory> get accessories {
  if (_accessories is EqualUnmodifiableListView) return _accessories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accessories);
}

@override final  UniformCheckSummary summary;
/// Required items the service can detect / of those, how many got a
/// definite verdict / required items it can't detect at all.
@override@JsonKey() final  int checkableRequired;
@override@JsonKey() final  int verifiedRequired;
@override@JsonKey() final  int notCheckableRequired;
/// PNG overlay (base64) of expected vs detected positions.
@override final  String? debugImageBase64;
/// Burst only — frames sent / frames the service could use.
@override final  int? burstFrames;
@override final  int? burstUsableFrames;
/// `exif_35mm` | `client` | `assumed` … — where the camera focal length
/// came from (`assumed` = less accurate distances).
@override final  String? focalSource;

/// Create a copy of UniformCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniformCheckResultCopyWith<_UniformCheckResult> get copyWith => __$UniformCheckResultCopyWithImpl<_UniformCheckResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UniformCheckResult&&(identical(other.success, success) || other.success == success)&&(identical(other.overallStatus, overallStatus) || other.overallStatus == overallStatus)&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.imageQualityUsable, imageQualityUsable) || other.imageQualityUsable == imageQualityUsable)&&(identical(other.imageQualityConfidence, imageQualityConfidence) || other.imageQualityConfidence == imageQualityConfidence)&&(identical(other.personDetected, personDetected) || other.personDetected == personDetected)&&(identical(other.personConfidence, personConfidence) || other.personConfidence == personConfidence)&&const DeepCollectionEquality().equals(other._accessories, _accessories)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.checkableRequired, checkableRequired) || other.checkableRequired == checkableRequired)&&(identical(other.verifiedRequired, verifiedRequired) || other.verifiedRequired == verifiedRequired)&&(identical(other.notCheckableRequired, notCheckableRequired) || other.notCheckableRequired == notCheckableRequired)&&(identical(other.debugImageBase64, debugImageBase64) || other.debugImageBase64 == debugImageBase64)&&(identical(other.burstFrames, burstFrames) || other.burstFrames == burstFrames)&&(identical(other.burstUsableFrames, burstUsableFrames) || other.burstUsableFrames == burstUsableFrames)&&(identical(other.focalSource, focalSource) || other.focalSource == focalSource));
}


@override
int get hashCode => Object.hash(runtimeType,success,overallStatus,overallScore,imageQualityUsable,imageQualityConfidence,personDetected,personConfidence,const DeepCollectionEquality().hash(_accessories),summary,checkableRequired,verifiedRequired,notCheckableRequired,debugImageBase64,burstFrames,burstUsableFrames,focalSource);

@override
String toString() {
  return 'UniformCheckResult(success: $success, overallStatus: $overallStatus, overallScore: $overallScore, imageQualityUsable: $imageQualityUsable, imageQualityConfidence: $imageQualityConfidence, personDetected: $personDetected, personConfidence: $personConfidence, accessories: $accessories, summary: $summary, checkableRequired: $checkableRequired, verifiedRequired: $verifiedRequired, notCheckableRequired: $notCheckableRequired, debugImageBase64: $debugImageBase64, burstFrames: $burstFrames, burstUsableFrames: $burstUsableFrames, focalSource: $focalSource)';
}


}

/// @nodoc
abstract mixin class _$UniformCheckResultCopyWith<$Res> implements $UniformCheckResultCopyWith<$Res> {
  factory _$UniformCheckResultCopyWith(_UniformCheckResult value, $Res Function(_UniformCheckResult) _then) = __$UniformCheckResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, String overallStatus, double overallScore, bool imageQualityUsable, double imageQualityConfidence, bool personDetected, double personConfidence, List<UniformCheckAccessory> accessories, UniformCheckSummary summary, int checkableRequired, int verifiedRequired, int notCheckableRequired, String? debugImageBase64, int? burstFrames, int? burstUsableFrames, String? focalSource
});


@override $UniformCheckSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$UniformCheckResultCopyWithImpl<$Res>
    implements _$UniformCheckResultCopyWith<$Res> {
  __$UniformCheckResultCopyWithImpl(this._self, this._then);

  final _UniformCheckResult _self;
  final $Res Function(_UniformCheckResult) _then;

/// Create a copy of UniformCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? overallStatus = null,Object? overallScore = null,Object? imageQualityUsable = null,Object? imageQualityConfidence = null,Object? personDetected = null,Object? personConfidence = null,Object? accessories = null,Object? summary = null,Object? checkableRequired = null,Object? verifiedRequired = null,Object? notCheckableRequired = null,Object? debugImageBase64 = freezed,Object? burstFrames = freezed,Object? burstUsableFrames = freezed,Object? focalSource = freezed,}) {
  return _then(_UniformCheckResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,overallStatus: null == overallStatus ? _self.overallStatus : overallStatus // ignore: cast_nullable_to_non_nullable
as String,overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,imageQualityUsable: null == imageQualityUsable ? _self.imageQualityUsable : imageQualityUsable // ignore: cast_nullable_to_non_nullable
as bool,imageQualityConfidence: null == imageQualityConfidence ? _self.imageQualityConfidence : imageQualityConfidence // ignore: cast_nullable_to_non_nullable
as double,personDetected: null == personDetected ? _self.personDetected : personDetected // ignore: cast_nullable_to_non_nullable
as bool,personConfidence: null == personConfidence ? _self.personConfidence : personConfidence // ignore: cast_nullable_to_non_nullable
as double,accessories: null == accessories ? _self._accessories : accessories // ignore: cast_nullable_to_non_nullable
as List<UniformCheckAccessory>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as UniformCheckSummary,checkableRequired: null == checkableRequired ? _self.checkableRequired : checkableRequired // ignore: cast_nullable_to_non_nullable
as int,verifiedRequired: null == verifiedRequired ? _self.verifiedRequired : verifiedRequired // ignore: cast_nullable_to_non_nullable
as int,notCheckableRequired: null == notCheckableRequired ? _self.notCheckableRequired : notCheckableRequired // ignore: cast_nullable_to_non_nullable
as int,debugImageBase64: freezed == debugImageBase64 ? _self.debugImageBase64 : debugImageBase64 // ignore: cast_nullable_to_non_nullable
as String?,burstFrames: freezed == burstFrames ? _self.burstFrames : burstFrames // ignore: cast_nullable_to_non_nullable
as int?,burstUsableFrames: freezed == burstUsableFrames ? _self.burstUsableFrames : burstUsableFrames // ignore: cast_nullable_to_non_nullable
as int?,focalSource: freezed == focalSource ? _self.focalSource : focalSource // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of UniformCheckResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UniformCheckSummaryCopyWith<$Res> get summary {
  
  return $UniformCheckSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on

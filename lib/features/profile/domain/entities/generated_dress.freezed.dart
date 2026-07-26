// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generated_dress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GeneratedDress {

 DateTime get builtAt;/// Firebase Storage download URL for the composed GLB. Null while
/// the very first generation is in flight.
 String? get modelUrl;/// First 16 hex chars of the sha256 over the profile fields that
/// affect what the model looks like (branch, rank, gender, dress
/// code, isSikh, fullName, vocation, medalRowCount, sorted badge /
/// accessory IDs, dress checks, plus the bundle version constant).
/// See [profile_hash.dart](../../../ar_engine/data/profile_hash.dart).
 String? get profileHash;/// Bumps when the composition logic itself changes (asset layout,
/// socket bone names, compression settings). Forces a regeneration
/// for everyone even if the profile hash hasn't changed.
 int? get schemaVersion;/// Set optimistically by the client the moment the regeneration
/// callable fires. The CF clears it on success.
 DateTime? get generationStartedAt;/// Last failure reason — kept for one cycle so the UI can surface
/// it. Cleared on the next successful generation.
 String? get error;
/// Create a copy of GeneratedDress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeneratedDressCopyWith<GeneratedDress> get copyWith => _$GeneratedDressCopyWithImpl<GeneratedDress>(this as GeneratedDress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeneratedDress&&(identical(other.builtAt, builtAt) || other.builtAt == builtAt)&&(identical(other.modelUrl, modelUrl) || other.modelUrl == modelUrl)&&(identical(other.profileHash, profileHash) || other.profileHash == profileHash)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.generationStartedAt, generationStartedAt) || other.generationStartedAt == generationStartedAt)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,builtAt,modelUrl,profileHash,schemaVersion,generationStartedAt,error);

@override
String toString() {
  return 'GeneratedDress(builtAt: $builtAt, modelUrl: $modelUrl, profileHash: $profileHash, schemaVersion: $schemaVersion, generationStartedAt: $generationStartedAt, error: $error)';
}


}

/// @nodoc
abstract mixin class $GeneratedDressCopyWith<$Res>  {
  factory $GeneratedDressCopyWith(GeneratedDress value, $Res Function(GeneratedDress) _then) = _$GeneratedDressCopyWithImpl;
@useResult
$Res call({
 DateTime builtAt, String? modelUrl, String? profileHash, int? schemaVersion, DateTime? generationStartedAt, String? error
});




}
/// @nodoc
class _$GeneratedDressCopyWithImpl<$Res>
    implements $GeneratedDressCopyWith<$Res> {
  _$GeneratedDressCopyWithImpl(this._self, this._then);

  final GeneratedDress _self;
  final $Res Function(GeneratedDress) _then;

/// Create a copy of GeneratedDress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? builtAt = null,Object? modelUrl = freezed,Object? profileHash = freezed,Object? schemaVersion = freezed,Object? generationStartedAt = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
builtAt: null == builtAt ? _self.builtAt : builtAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelUrl: freezed == modelUrl ? _self.modelUrl : modelUrl // ignore: cast_nullable_to_non_nullable
as String?,profileHash: freezed == profileHash ? _self.profileHash : profileHash // ignore: cast_nullable_to_non_nullable
as String?,schemaVersion: freezed == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int?,generationStartedAt: freezed == generationStartedAt ? _self.generationStartedAt : generationStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GeneratedDress].
extension GeneratedDressPatterns on GeneratedDress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeneratedDress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeneratedDress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeneratedDress value)  $default,){
final _that = this;
switch (_that) {
case _GeneratedDress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeneratedDress value)?  $default,){
final _that = this;
switch (_that) {
case _GeneratedDress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime builtAt,  String? modelUrl,  String? profileHash,  int? schemaVersion,  DateTime? generationStartedAt,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeneratedDress() when $default != null:
return $default(_that.builtAt,_that.modelUrl,_that.profileHash,_that.schemaVersion,_that.generationStartedAt,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime builtAt,  String? modelUrl,  String? profileHash,  int? schemaVersion,  DateTime? generationStartedAt,  String? error)  $default,) {final _that = this;
switch (_that) {
case _GeneratedDress():
return $default(_that.builtAt,_that.modelUrl,_that.profileHash,_that.schemaVersion,_that.generationStartedAt,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime builtAt,  String? modelUrl,  String? profileHash,  int? schemaVersion,  DateTime? generationStartedAt,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _GeneratedDress() when $default != null:
return $default(_that.builtAt,_that.modelUrl,_that.profileHash,_that.schemaVersion,_that.generationStartedAt,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _GeneratedDress implements GeneratedDress {
  const _GeneratedDress({required this.builtAt, this.modelUrl, this.profileHash, this.schemaVersion, this.generationStartedAt, this.error});
  

@override final  DateTime builtAt;
/// Firebase Storage download URL for the composed GLB. Null while
/// the very first generation is in flight.
@override final  String? modelUrl;
/// First 16 hex chars of the sha256 over the profile fields that
/// affect what the model looks like (branch, rank, gender, dress
/// code, isSikh, fullName, vocation, medalRowCount, sorted badge /
/// accessory IDs, dress checks, plus the bundle version constant).
/// See [profile_hash.dart](../../../ar_engine/data/profile_hash.dart).
@override final  String? profileHash;
/// Bumps when the composition logic itself changes (asset layout,
/// socket bone names, compression settings). Forces a regeneration
/// for everyone even if the profile hash hasn't changed.
@override final  int? schemaVersion;
/// Set optimistically by the client the moment the regeneration
/// callable fires. The CF clears it on success.
@override final  DateTime? generationStartedAt;
/// Last failure reason — kept for one cycle so the UI can surface
/// it. Cleared on the next successful generation.
@override final  String? error;

/// Create a copy of GeneratedDress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeneratedDressCopyWith<_GeneratedDress> get copyWith => __$GeneratedDressCopyWithImpl<_GeneratedDress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeneratedDress&&(identical(other.builtAt, builtAt) || other.builtAt == builtAt)&&(identical(other.modelUrl, modelUrl) || other.modelUrl == modelUrl)&&(identical(other.profileHash, profileHash) || other.profileHash == profileHash)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.generationStartedAt, generationStartedAt) || other.generationStartedAt == generationStartedAt)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,builtAt,modelUrl,profileHash,schemaVersion,generationStartedAt,error);

@override
String toString() {
  return 'GeneratedDress(builtAt: $builtAt, modelUrl: $modelUrl, profileHash: $profileHash, schemaVersion: $schemaVersion, generationStartedAt: $generationStartedAt, error: $error)';
}


}

/// @nodoc
abstract mixin class _$GeneratedDressCopyWith<$Res> implements $GeneratedDressCopyWith<$Res> {
  factory _$GeneratedDressCopyWith(_GeneratedDress value, $Res Function(_GeneratedDress) _then) = __$GeneratedDressCopyWithImpl;
@override @useResult
$Res call({
 DateTime builtAt, String? modelUrl, String? profileHash, int? schemaVersion, DateTime? generationStartedAt, String? error
});




}
/// @nodoc
class __$GeneratedDressCopyWithImpl<$Res>
    implements _$GeneratedDressCopyWith<$Res> {
  __$GeneratedDressCopyWithImpl(this._self, this._then);

  final _GeneratedDress _self;
  final $Res Function(_GeneratedDress) _then;

/// Create a copy of GeneratedDress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? builtAt = null,Object? modelUrl = freezed,Object? profileHash = freezed,Object? schemaVersion = freezed,Object? generationStartedAt = freezed,Object? error = freezed,}) {
  return _then(_GeneratedDress(
builtAt: null == builtAt ? _self.builtAt : builtAt // ignore: cast_nullable_to_non_nullable
as DateTime,modelUrl: freezed == modelUrl ? _self.modelUrl : modelUrl // ignore: cast_nullable_to_non_nullable
as String?,profileHash: freezed == profileHash ? _self.profileHash : profileHash // ignore: cast_nullable_to_non_nullable
as String?,schemaVersion: freezed == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int?,generationStartedAt: freezed == generationStartedAt ? _self.generationStartedAt : generationStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

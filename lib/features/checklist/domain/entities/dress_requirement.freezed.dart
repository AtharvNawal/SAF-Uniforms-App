// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dress_requirement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DressRequirement {

 String get id; String get dressName; String get displayName; String get subtitle; List<Map<String, dynamic>> get mandatoryRules; Map<String, dynamic> get optionalLogic; Map<String, Map<String, dynamic>> get branchOverrides; int get version;
/// Create a copy of DressRequirement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DressRequirementCopyWith<DressRequirement> get copyWith => _$DressRequirementCopyWithImpl<DressRequirement>(this as DressRequirement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DressRequirement&&(identical(other.id, id) || other.id == id)&&(identical(other.dressName, dressName) || other.dressName == dressName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other.mandatoryRules, mandatoryRules)&&const DeepCollectionEquality().equals(other.optionalLogic, optionalLogic)&&const DeepCollectionEquality().equals(other.branchOverrides, branchOverrides)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,dressName,displayName,subtitle,const DeepCollectionEquality().hash(mandatoryRules),const DeepCollectionEquality().hash(optionalLogic),const DeepCollectionEquality().hash(branchOverrides),version);

@override
String toString() {
  return 'DressRequirement(id: $id, dressName: $dressName, displayName: $displayName, subtitle: $subtitle, mandatoryRules: $mandatoryRules, optionalLogic: $optionalLogic, branchOverrides: $branchOverrides, version: $version)';
}


}

/// @nodoc
abstract mixin class $DressRequirementCopyWith<$Res>  {
  factory $DressRequirementCopyWith(DressRequirement value, $Res Function(DressRequirement) _then) = _$DressRequirementCopyWithImpl;
@useResult
$Res call({
 String id, String dressName, String displayName, String subtitle, List<Map<String, dynamic>> mandatoryRules, Map<String, dynamic> optionalLogic, Map<String, Map<String, dynamic>> branchOverrides, int version
});




}
/// @nodoc
class _$DressRequirementCopyWithImpl<$Res>
    implements $DressRequirementCopyWith<$Res> {
  _$DressRequirementCopyWithImpl(this._self, this._then);

  final DressRequirement _self;
  final $Res Function(DressRequirement) _then;

/// Create a copy of DressRequirement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dressName = null,Object? displayName = null,Object? subtitle = null,Object? mandatoryRules = null,Object? optionalLogic = null,Object? branchOverrides = null,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dressName: null == dressName ? _self.dressName : dressName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,mandatoryRules: null == mandatoryRules ? _self.mandatoryRules : mandatoryRules // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,optionalLogic: null == optionalLogic ? _self.optionalLogic : optionalLogic // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,branchOverrides: null == branchOverrides ? _self.branchOverrides : branchOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, dynamic>>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DressRequirement].
extension DressRequirementPatterns on DressRequirement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DressRequirement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DressRequirement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DressRequirement value)  $default,){
final _that = this;
switch (_that) {
case _DressRequirement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DressRequirement value)?  $default,){
final _that = this;
switch (_that) {
case _DressRequirement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String dressName,  String displayName,  String subtitle,  List<Map<String, dynamic>> mandatoryRules,  Map<String, dynamic> optionalLogic,  Map<String, Map<String, dynamic>> branchOverrides,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DressRequirement() when $default != null:
return $default(_that.id,_that.dressName,_that.displayName,_that.subtitle,_that.mandatoryRules,_that.optionalLogic,_that.branchOverrides,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String dressName,  String displayName,  String subtitle,  List<Map<String, dynamic>> mandatoryRules,  Map<String, dynamic> optionalLogic,  Map<String, Map<String, dynamic>> branchOverrides,  int version)  $default,) {final _that = this;
switch (_that) {
case _DressRequirement():
return $default(_that.id,_that.dressName,_that.displayName,_that.subtitle,_that.mandatoryRules,_that.optionalLogic,_that.branchOverrides,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String dressName,  String displayName,  String subtitle,  List<Map<String, dynamic>> mandatoryRules,  Map<String, dynamic> optionalLogic,  Map<String, Map<String, dynamic>> branchOverrides,  int version)?  $default,) {final _that = this;
switch (_that) {
case _DressRequirement() when $default != null:
return $default(_that.id,_that.dressName,_that.displayName,_that.subtitle,_that.mandatoryRules,_that.optionalLogic,_that.branchOverrides,_that.version);case _:
  return null;

}
}

}

/// @nodoc


class _DressRequirement extends DressRequirement {
  const _DressRequirement({required this.id, required this.dressName, this.displayName = '', this.subtitle = '', final  List<Map<String, dynamic>> mandatoryRules = const <Map<String, dynamic>>[], final  Map<String, dynamic> optionalLogic = const <String, dynamic>{}, final  Map<String, Map<String, dynamic>> branchOverrides = const <String, Map<String, dynamic>>{}, this.version = 1}): _mandatoryRules = mandatoryRules,_optionalLogic = optionalLogic,_branchOverrides = branchOverrides,super._();
  

@override final  String id;
@override final  String dressName;
@override@JsonKey() final  String displayName;
@override@JsonKey() final  String subtitle;
 final  List<Map<String, dynamic>> _mandatoryRules;
@override@JsonKey() List<Map<String, dynamic>> get mandatoryRules {
  if (_mandatoryRules is EqualUnmodifiableListView) return _mandatoryRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mandatoryRules);
}

 final  Map<String, dynamic> _optionalLogic;
@override@JsonKey() Map<String, dynamic> get optionalLogic {
  if (_optionalLogic is EqualUnmodifiableMapView) return _optionalLogic;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_optionalLogic);
}

 final  Map<String, Map<String, dynamic>> _branchOverrides;
@override@JsonKey() Map<String, Map<String, dynamic>> get branchOverrides {
  if (_branchOverrides is EqualUnmodifiableMapView) return _branchOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_branchOverrides);
}

@override@JsonKey() final  int version;

/// Create a copy of DressRequirement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DressRequirementCopyWith<_DressRequirement> get copyWith => __$DressRequirementCopyWithImpl<_DressRequirement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DressRequirement&&(identical(other.id, id) || other.id == id)&&(identical(other.dressName, dressName) || other.dressName == dressName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other._mandatoryRules, _mandatoryRules)&&const DeepCollectionEquality().equals(other._optionalLogic, _optionalLogic)&&const DeepCollectionEquality().equals(other._branchOverrides, _branchOverrides)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,dressName,displayName,subtitle,const DeepCollectionEquality().hash(_mandatoryRules),const DeepCollectionEquality().hash(_optionalLogic),const DeepCollectionEquality().hash(_branchOverrides),version);

@override
String toString() {
  return 'DressRequirement(id: $id, dressName: $dressName, displayName: $displayName, subtitle: $subtitle, mandatoryRules: $mandatoryRules, optionalLogic: $optionalLogic, branchOverrides: $branchOverrides, version: $version)';
}


}

/// @nodoc
abstract mixin class _$DressRequirementCopyWith<$Res> implements $DressRequirementCopyWith<$Res> {
  factory _$DressRequirementCopyWith(_DressRequirement value, $Res Function(_DressRequirement) _then) = __$DressRequirementCopyWithImpl;
@override @useResult
$Res call({
 String id, String dressName, String displayName, String subtitle, List<Map<String, dynamic>> mandatoryRules, Map<String, dynamic> optionalLogic, Map<String, Map<String, dynamic>> branchOverrides, int version
});




}
/// @nodoc
class __$DressRequirementCopyWithImpl<$Res>
    implements _$DressRequirementCopyWith<$Res> {
  __$DressRequirementCopyWithImpl(this._self, this._then);

  final _DressRequirement _self;
  final $Res Function(_DressRequirement) _then;

/// Create a copy of DressRequirement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dressName = null,Object? displayName = null,Object? subtitle = null,Object? mandatoryRules = null,Object? optionalLogic = null,Object? branchOverrides = null,Object? version = null,}) {
  return _then(_DressRequirement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dressName: null == dressName ? _self.dressName : dressName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,mandatoryRules: null == mandatoryRules ? _self._mandatoryRules : mandatoryRules // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,optionalLogic: null == optionalLogic ? _self._optionalLogic : optionalLogic // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,branchOverrides: null == branchOverrides ? _self._branchOverrides : branchOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, dynamic>>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

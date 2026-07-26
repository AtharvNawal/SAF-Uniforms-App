// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medal_vertical_shift_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MedalVerticalShiftRule {

 int get minRows; double get verticalShiftCmPerExtraRow; int get version;
/// Create a copy of MedalVerticalShiftRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MedalVerticalShiftRuleCopyWith<MedalVerticalShiftRule> get copyWith => _$MedalVerticalShiftRuleCopyWithImpl<MedalVerticalShiftRule>(this as MedalVerticalShiftRule, _$identity);

  /// Serializes this MedalVerticalShiftRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MedalVerticalShiftRule&&(identical(other.minRows, minRows) || other.minRows == minRows)&&(identical(other.verticalShiftCmPerExtraRow, verticalShiftCmPerExtraRow) || other.verticalShiftCmPerExtraRow == verticalShiftCmPerExtraRow)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minRows,verticalShiftCmPerExtraRow,version);

@override
String toString() {
  return 'MedalVerticalShiftRule(minRows: $minRows, verticalShiftCmPerExtraRow: $verticalShiftCmPerExtraRow, version: $version)';
}


}

/// @nodoc
abstract mixin class $MedalVerticalShiftRuleCopyWith<$Res>  {
  factory $MedalVerticalShiftRuleCopyWith(MedalVerticalShiftRule value, $Res Function(MedalVerticalShiftRule) _then) = _$MedalVerticalShiftRuleCopyWithImpl;
@useResult
$Res call({
 int minRows, double verticalShiftCmPerExtraRow, int version
});




}
/// @nodoc
class _$MedalVerticalShiftRuleCopyWithImpl<$Res>
    implements $MedalVerticalShiftRuleCopyWith<$Res> {
  _$MedalVerticalShiftRuleCopyWithImpl(this._self, this._then);

  final MedalVerticalShiftRule _self;
  final $Res Function(MedalVerticalShiftRule) _then;

/// Create a copy of MedalVerticalShiftRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minRows = null,Object? verticalShiftCmPerExtraRow = null,Object? version = null,}) {
  return _then(_self.copyWith(
minRows: null == minRows ? _self.minRows : minRows // ignore: cast_nullable_to_non_nullable
as int,verticalShiftCmPerExtraRow: null == verticalShiftCmPerExtraRow ? _self.verticalShiftCmPerExtraRow : verticalShiftCmPerExtraRow // ignore: cast_nullable_to_non_nullable
as double,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MedalVerticalShiftRule].
extension MedalVerticalShiftRulePatterns on MedalVerticalShiftRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MedalVerticalShiftRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MedalVerticalShiftRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MedalVerticalShiftRule value)  $default,){
final _that = this;
switch (_that) {
case _MedalVerticalShiftRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MedalVerticalShiftRule value)?  $default,){
final _that = this;
switch (_that) {
case _MedalVerticalShiftRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minRows,  double verticalShiftCmPerExtraRow,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MedalVerticalShiftRule() when $default != null:
return $default(_that.minRows,_that.verticalShiftCmPerExtraRow,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minRows,  double verticalShiftCmPerExtraRow,  int version)  $default,) {final _that = this;
switch (_that) {
case _MedalVerticalShiftRule():
return $default(_that.minRows,_that.verticalShiftCmPerExtraRow,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minRows,  double verticalShiftCmPerExtraRow,  int version)?  $default,) {final _that = this;
switch (_that) {
case _MedalVerticalShiftRule() when $default != null:
return $default(_that.minRows,_that.verticalShiftCmPerExtraRow,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MedalVerticalShiftRule extends MedalVerticalShiftRule {
  const _MedalVerticalShiftRule({this.minRows = 3, this.verticalShiftCmPerExtraRow = 1.0, this.version = 1}): super._();
  factory _MedalVerticalShiftRule.fromJson(Map<String, dynamic> json) => _$MedalVerticalShiftRuleFromJson(json);

@override@JsonKey() final  int minRows;
@override@JsonKey() final  double verticalShiftCmPerExtraRow;
@override@JsonKey() final  int version;

/// Create a copy of MedalVerticalShiftRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MedalVerticalShiftRuleCopyWith<_MedalVerticalShiftRule> get copyWith => __$MedalVerticalShiftRuleCopyWithImpl<_MedalVerticalShiftRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MedalVerticalShiftRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MedalVerticalShiftRule&&(identical(other.minRows, minRows) || other.minRows == minRows)&&(identical(other.verticalShiftCmPerExtraRow, verticalShiftCmPerExtraRow) || other.verticalShiftCmPerExtraRow == verticalShiftCmPerExtraRow)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minRows,verticalShiftCmPerExtraRow,version);

@override
String toString() {
  return 'MedalVerticalShiftRule(minRows: $minRows, verticalShiftCmPerExtraRow: $verticalShiftCmPerExtraRow, version: $version)';
}


}

/// @nodoc
abstract mixin class _$MedalVerticalShiftRuleCopyWith<$Res> implements $MedalVerticalShiftRuleCopyWith<$Res> {
  factory _$MedalVerticalShiftRuleCopyWith(_MedalVerticalShiftRule value, $Res Function(_MedalVerticalShiftRule) _then) = __$MedalVerticalShiftRuleCopyWithImpl;
@override @useResult
$Res call({
 int minRows, double verticalShiftCmPerExtraRow, int version
});




}
/// @nodoc
class __$MedalVerticalShiftRuleCopyWithImpl<$Res>
    implements _$MedalVerticalShiftRuleCopyWith<$Res> {
  __$MedalVerticalShiftRuleCopyWithImpl(this._self, this._then);

  final _MedalVerticalShiftRule _self;
  final $Res Function(_MedalVerticalShiftRule) _then;

/// Create a copy of MedalVerticalShiftRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minRows = null,Object? verticalShiftCmPerExtraRow = null,Object? version = null,}) {
  return _then(_MedalVerticalShiftRule(
minRows: null == minRows ? _self.minRows : minRows // ignore: cast_nullable_to_non_nullable
as int,verticalShiftCmPerExtraRow: null == verticalShiftCmPerExtraRow ? _self.verticalShiftCmPerExtraRow : verticalShiftCmPerExtraRow // ignore: cast_nullable_to_non_nullable
as double,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

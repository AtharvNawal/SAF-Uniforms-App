// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accessory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Accessory {

 String get id; String get displayName; String get imageUrl; String get placementDiagramUrl; Map<String, dynamic> get rules; Map<String, dynamic> get renderLogic;/// Dress-specific pictures, keyed `no4` or `no4_<branch>` →
/// `{image_url, placement_diagram}` (e.g. the No.4 name tape for an
/// accessory shared with No.3). Resolved by `accessoryImagesFor`.
 Map<String, Map<String, String>> get dressImages; String? get branchId; String? get category; String? get gender; int get version;
/// Create a copy of Accessory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessoryCopyWith<Accessory> get copyWith => _$AccessoryCopyWithImpl<Accessory>(this as Accessory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Accessory&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.placementDiagramUrl, placementDiagramUrl) || other.placementDiagramUrl == placementDiagramUrl)&&const DeepCollectionEquality().equals(other.rules, rules)&&const DeepCollectionEquality().equals(other.renderLogic, renderLogic)&&const DeepCollectionEquality().equals(other.dressImages, dressImages)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.category, category) || other.category == category)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,imageUrl,placementDiagramUrl,const DeepCollectionEquality().hash(rules),const DeepCollectionEquality().hash(renderLogic),const DeepCollectionEquality().hash(dressImages),branchId,category,gender,version);

@override
String toString() {
  return 'Accessory(id: $id, displayName: $displayName, imageUrl: $imageUrl, placementDiagramUrl: $placementDiagramUrl, rules: $rules, renderLogic: $renderLogic, dressImages: $dressImages, branchId: $branchId, category: $category, gender: $gender, version: $version)';
}


}

/// @nodoc
abstract mixin class $AccessoryCopyWith<$Res>  {
  factory $AccessoryCopyWith(Accessory value, $Res Function(Accessory) _then) = _$AccessoryCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String imageUrl, String placementDiagramUrl, Map<String, dynamic> rules, Map<String, dynamic> renderLogic, Map<String, Map<String, String>> dressImages, String? branchId, String? category, String? gender, int version
});




}
/// @nodoc
class _$AccessoryCopyWithImpl<$Res>
    implements $AccessoryCopyWith<$Res> {
  _$AccessoryCopyWithImpl(this._self, this._then);

  final Accessory _self;
  final $Res Function(Accessory) _then;

/// Create a copy of Accessory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? imageUrl = null,Object? placementDiagramUrl = null,Object? rules = null,Object? renderLogic = null,Object? dressImages = null,Object? branchId = freezed,Object? category = freezed,Object? gender = freezed,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,placementDiagramUrl: null == placementDiagramUrl ? _self.placementDiagramUrl : placementDiagramUrl // ignore: cast_nullable_to_non_nullable
as String,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,renderLogic: null == renderLogic ? _self.renderLogic : renderLogic // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,dressImages: null == dressImages ? _self.dressImages : dressImages // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, String>>,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Accessory].
extension AccessoryPatterns on Accessory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Accessory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Accessory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Accessory value)  $default,){
final _that = this;
switch (_that) {
case _Accessory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Accessory value)?  $default,){
final _that = this;
switch (_that) {
case _Accessory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String imageUrl,  String placementDiagramUrl,  Map<String, dynamic> rules,  Map<String, dynamic> renderLogic,  Map<String, Map<String, String>> dressImages,  String? branchId,  String? category,  String? gender,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Accessory() when $default != null:
return $default(_that.id,_that.displayName,_that.imageUrl,_that.placementDiagramUrl,_that.rules,_that.renderLogic,_that.dressImages,_that.branchId,_that.category,_that.gender,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String imageUrl,  String placementDiagramUrl,  Map<String, dynamic> rules,  Map<String, dynamic> renderLogic,  Map<String, Map<String, String>> dressImages,  String? branchId,  String? category,  String? gender,  int version)  $default,) {final _that = this;
switch (_that) {
case _Accessory():
return $default(_that.id,_that.displayName,_that.imageUrl,_that.placementDiagramUrl,_that.rules,_that.renderLogic,_that.dressImages,_that.branchId,_that.category,_that.gender,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String imageUrl,  String placementDiagramUrl,  Map<String, dynamic> rules,  Map<String, dynamic> renderLogic,  Map<String, Map<String, String>> dressImages,  String? branchId,  String? category,  String? gender,  int version)?  $default,) {final _that = this;
switch (_that) {
case _Accessory() when $default != null:
return $default(_that.id,_that.displayName,_that.imageUrl,_that.placementDiagramUrl,_that.rules,_that.renderLogic,_that.dressImages,_that.branchId,_that.category,_that.gender,_that.version);case _:
  return null;

}
}

}

/// @nodoc


class _Accessory implements Accessory {
  const _Accessory({required this.id, required this.displayName, this.imageUrl = '', this.placementDiagramUrl = '', final  Map<String, dynamic> rules = const <String, dynamic>{}, final  Map<String, dynamic> renderLogic = const <String, dynamic>{}, final  Map<String, Map<String, String>> dressImages = const <String, Map<String, String>>{}, this.branchId, this.category, this.gender, this.version = 1}): _rules = rules,_renderLogic = renderLogic,_dressImages = dressImages;
  

@override final  String id;
@override final  String displayName;
@override@JsonKey() final  String imageUrl;
@override@JsonKey() final  String placementDiagramUrl;
 final  Map<String, dynamic> _rules;
@override@JsonKey() Map<String, dynamic> get rules {
  if (_rules is EqualUnmodifiableMapView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rules);
}

 final  Map<String, dynamic> _renderLogic;
@override@JsonKey() Map<String, dynamic> get renderLogic {
  if (_renderLogic is EqualUnmodifiableMapView) return _renderLogic;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_renderLogic);
}

/// Dress-specific pictures, keyed `no4` or `no4_<branch>` →
/// `{image_url, placement_diagram}` (e.g. the No.4 name tape for an
/// accessory shared with No.3). Resolved by `accessoryImagesFor`.
 final  Map<String, Map<String, String>> _dressImages;
/// Dress-specific pictures, keyed `no4` or `no4_<branch>` →
/// `{image_url, placement_diagram}` (e.g. the No.4 name tape for an
/// accessory shared with No.3). Resolved by `accessoryImagesFor`.
@override@JsonKey() Map<String, Map<String, String>> get dressImages {
  if (_dressImages is EqualUnmodifiableMapView) return _dressImages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dressImages);
}

@override final  String? branchId;
@override final  String? category;
@override final  String? gender;
@override@JsonKey() final  int version;

/// Create a copy of Accessory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessoryCopyWith<_Accessory> get copyWith => __$AccessoryCopyWithImpl<_Accessory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Accessory&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.placementDiagramUrl, placementDiagramUrl) || other.placementDiagramUrl == placementDiagramUrl)&&const DeepCollectionEquality().equals(other._rules, _rules)&&const DeepCollectionEquality().equals(other._renderLogic, _renderLogic)&&const DeepCollectionEquality().equals(other._dressImages, _dressImages)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.category, category) || other.category == category)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,imageUrl,placementDiagramUrl,const DeepCollectionEquality().hash(_rules),const DeepCollectionEquality().hash(_renderLogic),const DeepCollectionEquality().hash(_dressImages),branchId,category,gender,version);

@override
String toString() {
  return 'Accessory(id: $id, displayName: $displayName, imageUrl: $imageUrl, placementDiagramUrl: $placementDiagramUrl, rules: $rules, renderLogic: $renderLogic, dressImages: $dressImages, branchId: $branchId, category: $category, gender: $gender, version: $version)';
}


}

/// @nodoc
abstract mixin class _$AccessoryCopyWith<$Res> implements $AccessoryCopyWith<$Res> {
  factory _$AccessoryCopyWith(_Accessory value, $Res Function(_Accessory) _then) = __$AccessoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String imageUrl, String placementDiagramUrl, Map<String, dynamic> rules, Map<String, dynamic> renderLogic, Map<String, Map<String, String>> dressImages, String? branchId, String? category, String? gender, int version
});




}
/// @nodoc
class __$AccessoryCopyWithImpl<$Res>
    implements _$AccessoryCopyWith<$Res> {
  __$AccessoryCopyWithImpl(this._self, this._then);

  final _Accessory _self;
  final $Res Function(_Accessory) _then;

/// Create a copy of Accessory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? imageUrl = null,Object? placementDiagramUrl = null,Object? rules = null,Object? renderLogic = null,Object? dressImages = null,Object? branchId = freezed,Object? category = freezed,Object? gender = freezed,Object? version = null,}) {
  return _then(_Accessory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,placementDiagramUrl: null == placementDiagramUrl ? _self.placementDiagramUrl : placementDiagramUrl // ignore: cast_nullable_to_non_nullable
as String,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,renderLogic: null == renderLogic ? _self._renderLogic : renderLogic // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,dressImages: null == dressImages ? _self._dressImages : dressImages // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, String>>,branchId: freezed == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

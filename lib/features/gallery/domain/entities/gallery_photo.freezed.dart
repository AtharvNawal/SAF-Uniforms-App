// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_photo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GalleryPhoto {

 String get id; String get url; String get thumbnailUrl; DateTime get uploadedAt; String get dressCode;
/// Create a copy of GalleryPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryPhotoCopyWith<GalleryPhoto> get copyWith => _$GalleryPhotoCopyWithImpl<GalleryPhoto>(this as GalleryPhoto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.dressCode, dressCode) || other.dressCode == dressCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,url,thumbnailUrl,uploadedAt,dressCode);

@override
String toString() {
  return 'GalleryPhoto(id: $id, url: $url, thumbnailUrl: $thumbnailUrl, uploadedAt: $uploadedAt, dressCode: $dressCode)';
}


}

/// @nodoc
abstract mixin class $GalleryPhotoCopyWith<$Res>  {
  factory $GalleryPhotoCopyWith(GalleryPhoto value, $Res Function(GalleryPhoto) _then) = _$GalleryPhotoCopyWithImpl;
@useResult
$Res call({
 String id, String url, String thumbnailUrl, DateTime uploadedAt, String dressCode
});




}
/// @nodoc
class _$GalleryPhotoCopyWithImpl<$Res>
    implements $GalleryPhotoCopyWith<$Res> {
  _$GalleryPhotoCopyWithImpl(this._self, this._then);

  final GalleryPhoto _self;
  final $Res Function(GalleryPhoto) _then;

/// Create a copy of GalleryPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? thumbnailUrl = null,Object? uploadedAt = null,Object? dressCode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dressCode: null == dressCode ? _self.dressCode : dressCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GalleryPhoto].
extension GalleryPhotoPatterns on GalleryPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GalleryPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GalleryPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GalleryPhoto value)  $default,){
final _that = this;
switch (_that) {
case _GalleryPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GalleryPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _GalleryPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String url,  String thumbnailUrl,  DateTime uploadedAt,  String dressCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GalleryPhoto() when $default != null:
return $default(_that.id,_that.url,_that.thumbnailUrl,_that.uploadedAt,_that.dressCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String url,  String thumbnailUrl,  DateTime uploadedAt,  String dressCode)  $default,) {final _that = this;
switch (_that) {
case _GalleryPhoto():
return $default(_that.id,_that.url,_that.thumbnailUrl,_that.uploadedAt,_that.dressCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String url,  String thumbnailUrl,  DateTime uploadedAt,  String dressCode)?  $default,) {final _that = this;
switch (_that) {
case _GalleryPhoto() when $default != null:
return $default(_that.id,_that.url,_that.thumbnailUrl,_that.uploadedAt,_that.dressCode);case _:
  return null;

}
}

}

/// @nodoc


class _GalleryPhoto implements GalleryPhoto {
  const _GalleryPhoto({required this.id, required this.url, this.thumbnailUrl = '', required this.uploadedAt, this.dressCode = ''});
  

@override final  String id;
@override final  String url;
@override@JsonKey() final  String thumbnailUrl;
@override final  DateTime uploadedAt;
@override@JsonKey() final  String dressCode;

/// Create a copy of GalleryPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GalleryPhotoCopyWith<_GalleryPhoto> get copyWith => __$GalleryPhotoCopyWithImpl<_GalleryPhoto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GalleryPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.dressCode, dressCode) || other.dressCode == dressCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,url,thumbnailUrl,uploadedAt,dressCode);

@override
String toString() {
  return 'GalleryPhoto(id: $id, url: $url, thumbnailUrl: $thumbnailUrl, uploadedAt: $uploadedAt, dressCode: $dressCode)';
}


}

/// @nodoc
abstract mixin class _$GalleryPhotoCopyWith<$Res> implements $GalleryPhotoCopyWith<$Res> {
  factory _$GalleryPhotoCopyWith(_GalleryPhoto value, $Res Function(_GalleryPhoto) _then) = __$GalleryPhotoCopyWithImpl;
@override @useResult
$Res call({
 String id, String url, String thumbnailUrl, DateTime uploadedAt, String dressCode
});




}
/// @nodoc
class __$GalleryPhotoCopyWithImpl<$Res>
    implements _$GalleryPhotoCopyWith<$Res> {
  __$GalleryPhotoCopyWithImpl(this._self, this._then);

  final _GalleryPhoto _self;
  final $Res Function(_GalleryPhoto) _then;

/// Create a copy of GalleryPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? thumbnailUrl = null,Object? uploadedAt = null,Object? dressCode = null,}) {
  return _then(_GalleryPhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: null == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dressCode: null == dressCode ? _self.dressCode : dressCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

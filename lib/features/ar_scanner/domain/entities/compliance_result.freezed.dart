// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compliance_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ComplianceItem {

 String get accessoryId; String get displayName; ComplianceStatus get status; String get note;
/// Create a copy of ComplianceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComplianceItemCopyWith<ComplianceItem> get copyWith => _$ComplianceItemCopyWithImpl<ComplianceItem>(this as ComplianceItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComplianceItem&&(identical(other.accessoryId, accessoryId) || other.accessoryId == accessoryId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,accessoryId,displayName,status,note);

@override
String toString() {
  return 'ComplianceItem(accessoryId: $accessoryId, displayName: $displayName, status: $status, note: $note)';
}


}

/// @nodoc
abstract mixin class $ComplianceItemCopyWith<$Res>  {
  factory $ComplianceItemCopyWith(ComplianceItem value, $Res Function(ComplianceItem) _then) = _$ComplianceItemCopyWithImpl;
@useResult
$Res call({
 String accessoryId, String displayName, ComplianceStatus status, String note
});




}
/// @nodoc
class _$ComplianceItemCopyWithImpl<$Res>
    implements $ComplianceItemCopyWith<$Res> {
  _$ComplianceItemCopyWithImpl(this._self, this._then);

  final ComplianceItem _self;
  final $Res Function(ComplianceItem) _then;

/// Create a copy of ComplianceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessoryId = null,Object? displayName = null,Object? status = null,Object? note = null,}) {
  return _then(_self.copyWith(
accessoryId: null == accessoryId ? _self.accessoryId : accessoryId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ComplianceStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ComplianceItem].
extension ComplianceItemPatterns on ComplianceItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComplianceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComplianceItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComplianceItem value)  $default,){
final _that = this;
switch (_that) {
case _ComplianceItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComplianceItem value)?  $default,){
final _that = this;
switch (_that) {
case _ComplianceItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessoryId,  String displayName,  ComplianceStatus status,  String note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComplianceItem() when $default != null:
return $default(_that.accessoryId,_that.displayName,_that.status,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessoryId,  String displayName,  ComplianceStatus status,  String note)  $default,) {final _that = this;
switch (_that) {
case _ComplianceItem():
return $default(_that.accessoryId,_that.displayName,_that.status,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessoryId,  String displayName,  ComplianceStatus status,  String note)?  $default,) {final _that = this;
switch (_that) {
case _ComplianceItem() when $default != null:
return $default(_that.accessoryId,_that.displayName,_that.status,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _ComplianceItem implements ComplianceItem {
  const _ComplianceItem({required this.accessoryId, required this.displayName, required this.status, required this.note});
  

@override final  String accessoryId;
@override final  String displayName;
@override final  ComplianceStatus status;
@override final  String note;

/// Create a copy of ComplianceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComplianceItemCopyWith<_ComplianceItem> get copyWith => __$ComplianceItemCopyWithImpl<_ComplianceItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComplianceItem&&(identical(other.accessoryId, accessoryId) || other.accessoryId == accessoryId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,accessoryId,displayName,status,note);

@override
String toString() {
  return 'ComplianceItem(accessoryId: $accessoryId, displayName: $displayName, status: $status, note: $note)';
}


}

/// @nodoc
abstract mixin class _$ComplianceItemCopyWith<$Res> implements $ComplianceItemCopyWith<$Res> {
  factory _$ComplianceItemCopyWith(_ComplianceItem value, $Res Function(_ComplianceItem) _then) = __$ComplianceItemCopyWithImpl;
@override @useResult
$Res call({
 String accessoryId, String displayName, ComplianceStatus status, String note
});




}
/// @nodoc
class __$ComplianceItemCopyWithImpl<$Res>
    implements _$ComplianceItemCopyWith<$Res> {
  __$ComplianceItemCopyWithImpl(this._self, this._then);

  final _ComplianceItem _self;
  final $Res Function(_ComplianceItem) _then;

/// Create a copy of ComplianceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessoryId = null,Object? displayName = null,Object? status = null,Object? note = null,}) {
  return _then(_ComplianceItem(
accessoryId: null == accessoryId ? _self.accessoryId : accessoryId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ComplianceStatus,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ComplianceResult {

 int get overallScore; String get summary; List<ComplianceItem> get items;
/// Create a copy of ComplianceResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComplianceResultCopyWith<ComplianceResult> get copyWith => _$ComplianceResultCopyWithImpl<ComplianceResult>(this as ComplianceResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComplianceResult&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,overallScore,summary,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'ComplianceResult(overallScore: $overallScore, summary: $summary, items: $items)';
}


}

/// @nodoc
abstract mixin class $ComplianceResultCopyWith<$Res>  {
  factory $ComplianceResultCopyWith(ComplianceResult value, $Res Function(ComplianceResult) _then) = _$ComplianceResultCopyWithImpl;
@useResult
$Res call({
 int overallScore, String summary, List<ComplianceItem> items
});




}
/// @nodoc
class _$ComplianceResultCopyWithImpl<$Res>
    implements $ComplianceResultCopyWith<$Res> {
  _$ComplianceResultCopyWithImpl(this._self, this._then);

  final ComplianceResult _self;
  final $Res Function(ComplianceResult) _then;

/// Create a copy of ComplianceResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallScore = null,Object? summary = null,Object? items = null,}) {
  return _then(_self.copyWith(
overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as int,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ComplianceItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComplianceResult].
extension ComplianceResultPatterns on ComplianceResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComplianceResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComplianceResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComplianceResult value)  $default,){
final _that = this;
switch (_that) {
case _ComplianceResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComplianceResult value)?  $default,){
final _that = this;
switch (_that) {
case _ComplianceResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int overallScore,  String summary,  List<ComplianceItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComplianceResult() when $default != null:
return $default(_that.overallScore,_that.summary,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int overallScore,  String summary,  List<ComplianceItem> items)  $default,) {final _that = this;
switch (_that) {
case _ComplianceResult():
return $default(_that.overallScore,_that.summary,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int overallScore,  String summary,  List<ComplianceItem> items)?  $default,) {final _that = this;
switch (_that) {
case _ComplianceResult() when $default != null:
return $default(_that.overallScore,_that.summary,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _ComplianceResult extends ComplianceResult {
  const _ComplianceResult({required this.overallScore, required this.summary, required final  List<ComplianceItem> items}): _items = items,super._();
  

@override final  int overallScore;
@override final  String summary;
 final  List<ComplianceItem> _items;
@override List<ComplianceItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ComplianceResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComplianceResultCopyWith<_ComplianceResult> get copyWith => __$ComplianceResultCopyWithImpl<_ComplianceResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComplianceResult&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,overallScore,summary,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ComplianceResult(overallScore: $overallScore, summary: $summary, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ComplianceResultCopyWith<$Res> implements $ComplianceResultCopyWith<$Res> {
  factory _$ComplianceResultCopyWith(_ComplianceResult value, $Res Function(_ComplianceResult) _then) = __$ComplianceResultCopyWithImpl;
@override @useResult
$Res call({
 int overallScore, String summary, List<ComplianceItem> items
});




}
/// @nodoc
class __$ComplianceResultCopyWithImpl<$Res>
    implements _$ComplianceResultCopyWith<$Res> {
  __$ComplianceResultCopyWithImpl(this._self, this._then);

  final _ComplianceResult _self;
  final $Res Function(_ComplianceResult) _then;

/// Create a copy of ComplianceResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallScore = null,Object? summary = null,Object? items = null,}) {
  return _then(_ComplianceResult(
overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as int,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ComplianceItem>,
  ));
}


}

// dart format on

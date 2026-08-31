// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cv_inspection_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CvIssue {

 String get item; String get category; CvVerdict get problem; String get severity; double get confidence; String get doctrineRef; String get note; List<List<double>> get bbox;
/// Create a copy of CvIssue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CvIssueCopyWith<CvIssue> get copyWith => _$CvIssueCopyWithImpl<CvIssue>(this as CvIssue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CvIssue&&(identical(other.item, item) || other.item == item)&&(identical(other.category, category) || other.category == category)&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.doctrineRef, doctrineRef) || other.doctrineRef == doctrineRef)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.bbox, bbox));
}


@override
int get hashCode => Object.hash(runtimeType,item,category,problem,severity,confidence,doctrineRef,note,const DeepCollectionEquality().hash(bbox));

@override
String toString() {
  return 'CvIssue(item: $item, category: $category, problem: $problem, severity: $severity, confidence: $confidence, doctrineRef: $doctrineRef, note: $note, bbox: $bbox)';
}


}

/// @nodoc
abstract mixin class $CvIssueCopyWith<$Res>  {
  factory $CvIssueCopyWith(CvIssue value, $Res Function(CvIssue) _then) = _$CvIssueCopyWithImpl;
@useResult
$Res call({
 String item, String category, CvVerdict problem, String severity, double confidence, String doctrineRef, String note, List<List<double>> bbox
});




}
/// @nodoc
class _$CvIssueCopyWithImpl<$Res>
    implements $CvIssueCopyWith<$Res> {
  _$CvIssueCopyWithImpl(this._self, this._then);

  final CvIssue _self;
  final $Res Function(CvIssue) _then;

/// Create a copy of CvIssue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? category = null,Object? problem = null,Object? severity = null,Object? confidence = null,Object? doctrineRef = null,Object? note = null,Object? bbox = null,}) {
  return _then(_self.copyWith(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,problem: null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as CvVerdict,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,doctrineRef: null == doctrineRef ? _self.doctrineRef : doctrineRef // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,bbox: null == bbox ? _self.bbox : bbox // ignore: cast_nullable_to_non_nullable
as List<List<double>>,
  ));
}

}


/// Adds pattern-matching-related methods to [CvIssue].
extension CvIssuePatterns on CvIssue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CvIssue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CvIssue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CvIssue value)  $default,){
final _that = this;
switch (_that) {
case _CvIssue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CvIssue value)?  $default,){
final _that = this;
switch (_that) {
case _CvIssue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String item,  String category,  CvVerdict problem,  String severity,  double confidence,  String doctrineRef,  String note,  List<List<double>> bbox)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CvIssue() when $default != null:
return $default(_that.item,_that.category,_that.problem,_that.severity,_that.confidence,_that.doctrineRef,_that.note,_that.bbox);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String item,  String category,  CvVerdict problem,  String severity,  double confidence,  String doctrineRef,  String note,  List<List<double>> bbox)  $default,) {final _that = this;
switch (_that) {
case _CvIssue():
return $default(_that.item,_that.category,_that.problem,_that.severity,_that.confidence,_that.doctrineRef,_that.note,_that.bbox);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String item,  String category,  CvVerdict problem,  String severity,  double confidence,  String doctrineRef,  String note,  List<List<double>> bbox)?  $default,) {final _that = this;
switch (_that) {
case _CvIssue() when $default != null:
return $default(_that.item,_that.category,_that.problem,_that.severity,_that.confidence,_that.doctrineRef,_that.note,_that.bbox);case _:
  return null;

}
}

}

/// @nodoc


class _CvIssue implements CvIssue {
  const _CvIssue({required this.item, required this.category, required this.problem, required this.severity, required this.confidence, required this.doctrineRef, required this.note, required final  List<List<double>> bbox}): _bbox = bbox;
  

@override final  String item;
@override final  String category;
@override final  CvVerdict problem;
@override final  String severity;
@override final  double confidence;
@override final  String doctrineRef;
@override final  String note;
 final  List<List<double>> _bbox;
@override List<List<double>> get bbox {
  if (_bbox is EqualUnmodifiableListView) return _bbox;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bbox);
}


/// Create a copy of CvIssue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CvIssueCopyWith<_CvIssue> get copyWith => __$CvIssueCopyWithImpl<_CvIssue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CvIssue&&(identical(other.item, item) || other.item == item)&&(identical(other.category, category) || other.category == category)&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.doctrineRef, doctrineRef) || other.doctrineRef == doctrineRef)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other._bbox, _bbox));
}


@override
int get hashCode => Object.hash(runtimeType,item,category,problem,severity,confidence,doctrineRef,note,const DeepCollectionEquality().hash(_bbox));

@override
String toString() {
  return 'CvIssue(item: $item, category: $category, problem: $problem, severity: $severity, confidence: $confidence, doctrineRef: $doctrineRef, note: $note, bbox: $bbox)';
}


}

/// @nodoc
abstract mixin class _$CvIssueCopyWith<$Res> implements $CvIssueCopyWith<$Res> {
  factory _$CvIssueCopyWith(_CvIssue value, $Res Function(_CvIssue) _then) = __$CvIssueCopyWithImpl;
@override @useResult
$Res call({
 String item, String category, CvVerdict problem, String severity, double confidence, String doctrineRef, String note, List<List<double>> bbox
});




}
/// @nodoc
class __$CvIssueCopyWithImpl<$Res>
    implements _$CvIssueCopyWith<$Res> {
  __$CvIssueCopyWithImpl(this._self, this._then);

  final _CvIssue _self;
  final $Res Function(_CvIssue) _then;

/// Create a copy of CvIssue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? category = null,Object? problem = null,Object? severity = null,Object? confidence = null,Object? doctrineRef = null,Object? note = null,Object? bbox = null,}) {
  return _then(_CvIssue(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,problem: null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as CvVerdict,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,doctrineRef: null == doctrineRef ? _self.doctrineRef : doctrineRef // ignore: cast_nullable_to_non_nullable
as String,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,bbox: null == bbox ? _self._bbox : bbox // ignore: cast_nullable_to_non_nullable
as List<List<double>>,
  ));
}


}

/// @nodoc
mixin _$CvUncertainItem {

 String get item; String get reason; double get confidence;
/// Create a copy of CvUncertainItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CvUncertainItemCopyWith<CvUncertainItem> get copyWith => _$CvUncertainItemCopyWithImpl<CvUncertainItem>(this as CvUncertainItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CvUncertainItem&&(identical(other.item, item) || other.item == item)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,item,reason,confidence);

@override
String toString() {
  return 'CvUncertainItem(item: $item, reason: $reason, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $CvUncertainItemCopyWith<$Res>  {
  factory $CvUncertainItemCopyWith(CvUncertainItem value, $Res Function(CvUncertainItem) _then) = _$CvUncertainItemCopyWithImpl;
@useResult
$Res call({
 String item, String reason, double confidence
});




}
/// @nodoc
class _$CvUncertainItemCopyWithImpl<$Res>
    implements $CvUncertainItemCopyWith<$Res> {
  _$CvUncertainItemCopyWithImpl(this._self, this._then);

  final CvUncertainItem _self;
  final $Res Function(CvUncertainItem) _then;

/// Create a copy of CvUncertainItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? item = null,Object? reason = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CvUncertainItem].
extension CvUncertainItemPatterns on CvUncertainItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CvUncertainItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CvUncertainItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CvUncertainItem value)  $default,){
final _that = this;
switch (_that) {
case _CvUncertainItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CvUncertainItem value)?  $default,){
final _that = this;
switch (_that) {
case _CvUncertainItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String item,  String reason,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CvUncertainItem() when $default != null:
return $default(_that.item,_that.reason,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String item,  String reason,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _CvUncertainItem():
return $default(_that.item,_that.reason,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String item,  String reason,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _CvUncertainItem() when $default != null:
return $default(_that.item,_that.reason,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _CvUncertainItem implements CvUncertainItem {
  const _CvUncertainItem({required this.item, required this.reason, required this.confidence});
  

@override final  String item;
@override final  String reason;
@override final  double confidence;

/// Create a copy of CvUncertainItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CvUncertainItemCopyWith<_CvUncertainItem> get copyWith => __$CvUncertainItemCopyWithImpl<_CvUncertainItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CvUncertainItem&&(identical(other.item, item) || other.item == item)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,item,reason,confidence);

@override
String toString() {
  return 'CvUncertainItem(item: $item, reason: $reason, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$CvUncertainItemCopyWith<$Res> implements $CvUncertainItemCopyWith<$Res> {
  factory _$CvUncertainItemCopyWith(_CvUncertainItem value, $Res Function(_CvUncertainItem) _then) = __$CvUncertainItemCopyWithImpl;
@override @useResult
$Res call({
 String item, String reason, double confidence
});




}
/// @nodoc
class __$CvUncertainItemCopyWithImpl<$Res>
    implements _$CvUncertainItemCopyWith<$Res> {
  __$CvUncertainItemCopyWithImpl(this._self, this._then);

  final _CvUncertainItem _self;
  final $Res Function(_CvUncertainItem) _then;

/// Create a copy of CvUncertainItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? item = null,Object? reason = null,Object? confidence = null,}) {
  return _then(_CvUncertainItem(
item: null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$CvSubscores {

 double? get headwear; double? get chest; double? get collar; double? get sleeves; double? get waist; double? get lowerBody; double? get footwear; double? get appearance;
/// Create a copy of CvSubscores
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CvSubscoresCopyWith<CvSubscores> get copyWith => _$CvSubscoresCopyWithImpl<CvSubscores>(this as CvSubscores, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CvSubscores&&(identical(other.headwear, headwear) || other.headwear == headwear)&&(identical(other.chest, chest) || other.chest == chest)&&(identical(other.collar, collar) || other.collar == collar)&&(identical(other.sleeves, sleeves) || other.sleeves == sleeves)&&(identical(other.waist, waist) || other.waist == waist)&&(identical(other.lowerBody, lowerBody) || other.lowerBody == lowerBody)&&(identical(other.footwear, footwear) || other.footwear == footwear)&&(identical(other.appearance, appearance) || other.appearance == appearance));
}


@override
int get hashCode => Object.hash(runtimeType,headwear,chest,collar,sleeves,waist,lowerBody,footwear,appearance);

@override
String toString() {
  return 'CvSubscores(headwear: $headwear, chest: $chest, collar: $collar, sleeves: $sleeves, waist: $waist, lowerBody: $lowerBody, footwear: $footwear, appearance: $appearance)';
}


}

/// @nodoc
abstract mixin class $CvSubscoresCopyWith<$Res>  {
  factory $CvSubscoresCopyWith(CvSubscores value, $Res Function(CvSubscores) _then) = _$CvSubscoresCopyWithImpl;
@useResult
$Res call({
 double? headwear, double? chest, double? collar, double? sleeves, double? waist, double? lowerBody, double? footwear, double? appearance
});




}
/// @nodoc
class _$CvSubscoresCopyWithImpl<$Res>
    implements $CvSubscoresCopyWith<$Res> {
  _$CvSubscoresCopyWithImpl(this._self, this._then);

  final CvSubscores _self;
  final $Res Function(CvSubscores) _then;

/// Create a copy of CvSubscores
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? headwear = freezed,Object? chest = freezed,Object? collar = freezed,Object? sleeves = freezed,Object? waist = freezed,Object? lowerBody = freezed,Object? footwear = freezed,Object? appearance = freezed,}) {
  return _then(_self.copyWith(
headwear: freezed == headwear ? _self.headwear : headwear // ignore: cast_nullable_to_non_nullable
as double?,chest: freezed == chest ? _self.chest : chest // ignore: cast_nullable_to_non_nullable
as double?,collar: freezed == collar ? _self.collar : collar // ignore: cast_nullable_to_non_nullable
as double?,sleeves: freezed == sleeves ? _self.sleeves : sleeves // ignore: cast_nullable_to_non_nullable
as double?,waist: freezed == waist ? _self.waist : waist // ignore: cast_nullable_to_non_nullable
as double?,lowerBody: freezed == lowerBody ? _self.lowerBody : lowerBody // ignore: cast_nullable_to_non_nullable
as double?,footwear: freezed == footwear ? _self.footwear : footwear // ignore: cast_nullable_to_non_nullable
as double?,appearance: freezed == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [CvSubscores].
extension CvSubscoresPatterns on CvSubscores {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CvSubscores value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CvSubscores() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CvSubscores value)  $default,){
final _that = this;
switch (_that) {
case _CvSubscores():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CvSubscores value)?  $default,){
final _that = this;
switch (_that) {
case _CvSubscores() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? headwear,  double? chest,  double? collar,  double? sleeves,  double? waist,  double? lowerBody,  double? footwear,  double? appearance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CvSubscores() when $default != null:
return $default(_that.headwear,_that.chest,_that.collar,_that.sleeves,_that.waist,_that.lowerBody,_that.footwear,_that.appearance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? headwear,  double? chest,  double? collar,  double? sleeves,  double? waist,  double? lowerBody,  double? footwear,  double? appearance)  $default,) {final _that = this;
switch (_that) {
case _CvSubscores():
return $default(_that.headwear,_that.chest,_that.collar,_that.sleeves,_that.waist,_that.lowerBody,_that.footwear,_that.appearance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? headwear,  double? chest,  double? collar,  double? sleeves,  double? waist,  double? lowerBody,  double? footwear,  double? appearance)?  $default,) {final _that = this;
switch (_that) {
case _CvSubscores() when $default != null:
return $default(_that.headwear,_that.chest,_that.collar,_that.sleeves,_that.waist,_that.lowerBody,_that.footwear,_that.appearance);case _:
  return null;

}
}

}

/// @nodoc


class _CvSubscores implements CvSubscores {
  const _CvSubscores({this.headwear, this.chest, this.collar, this.sleeves, this.waist, this.lowerBody, this.footwear, this.appearance});
  

@override final  double? headwear;
@override final  double? chest;
@override final  double? collar;
@override final  double? sleeves;
@override final  double? waist;
@override final  double? lowerBody;
@override final  double? footwear;
@override final  double? appearance;

/// Create a copy of CvSubscores
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CvSubscoresCopyWith<_CvSubscores> get copyWith => __$CvSubscoresCopyWithImpl<_CvSubscores>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CvSubscores&&(identical(other.headwear, headwear) || other.headwear == headwear)&&(identical(other.chest, chest) || other.chest == chest)&&(identical(other.collar, collar) || other.collar == collar)&&(identical(other.sleeves, sleeves) || other.sleeves == sleeves)&&(identical(other.waist, waist) || other.waist == waist)&&(identical(other.lowerBody, lowerBody) || other.lowerBody == lowerBody)&&(identical(other.footwear, footwear) || other.footwear == footwear)&&(identical(other.appearance, appearance) || other.appearance == appearance));
}


@override
int get hashCode => Object.hash(runtimeType,headwear,chest,collar,sleeves,waist,lowerBody,footwear,appearance);

@override
String toString() {
  return 'CvSubscores(headwear: $headwear, chest: $chest, collar: $collar, sleeves: $sleeves, waist: $waist, lowerBody: $lowerBody, footwear: $footwear, appearance: $appearance)';
}


}

/// @nodoc
abstract mixin class _$CvSubscoresCopyWith<$Res> implements $CvSubscoresCopyWith<$Res> {
  factory _$CvSubscoresCopyWith(_CvSubscores value, $Res Function(_CvSubscores) _then) = __$CvSubscoresCopyWithImpl;
@override @useResult
$Res call({
 double? headwear, double? chest, double? collar, double? sleeves, double? waist, double? lowerBody, double? footwear, double? appearance
});




}
/// @nodoc
class __$CvSubscoresCopyWithImpl<$Res>
    implements _$CvSubscoresCopyWith<$Res> {
  __$CvSubscoresCopyWithImpl(this._self, this._then);

  final _CvSubscores _self;
  final $Res Function(_CvSubscores) _then;

/// Create a copy of CvSubscores
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? headwear = freezed,Object? chest = freezed,Object? collar = freezed,Object? sleeves = freezed,Object? waist = freezed,Object? lowerBody = freezed,Object? footwear = freezed,Object? appearance = freezed,}) {
  return _then(_CvSubscores(
headwear: freezed == headwear ? _self.headwear : headwear // ignore: cast_nullable_to_non_nullable
as double?,chest: freezed == chest ? _self.chest : chest // ignore: cast_nullable_to_non_nullable
as double?,collar: freezed == collar ? _self.collar : collar // ignore: cast_nullable_to_non_nullable
as double?,sleeves: freezed == sleeves ? _self.sleeves : sleeves // ignore: cast_nullable_to_non_nullable
as double?,waist: freezed == waist ? _self.waist : waist // ignore: cast_nullable_to_non_nullable
as double?,lowerBody: freezed == lowerBody ? _self.lowerBody : lowerBody // ignore: cast_nullable_to_non_nullable
as double?,footwear: freezed == footwear ? _self.footwear : footwear // ignore: cast_nullable_to_non_nullable
as double?,appearance: freezed == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$CvCameraDiagnostics {

 double get reprojectionErrorPx; int get correspondenceCount; double get cmPerPx;
/// Create a copy of CvCameraDiagnostics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CvCameraDiagnosticsCopyWith<CvCameraDiagnostics> get copyWith => _$CvCameraDiagnosticsCopyWithImpl<CvCameraDiagnostics>(this as CvCameraDiagnostics, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CvCameraDiagnostics&&(identical(other.reprojectionErrorPx, reprojectionErrorPx) || other.reprojectionErrorPx == reprojectionErrorPx)&&(identical(other.correspondenceCount, correspondenceCount) || other.correspondenceCount == correspondenceCount)&&(identical(other.cmPerPx, cmPerPx) || other.cmPerPx == cmPerPx));
}


@override
int get hashCode => Object.hash(runtimeType,reprojectionErrorPx,correspondenceCount,cmPerPx);

@override
String toString() {
  return 'CvCameraDiagnostics(reprojectionErrorPx: $reprojectionErrorPx, correspondenceCount: $correspondenceCount, cmPerPx: $cmPerPx)';
}


}

/// @nodoc
abstract mixin class $CvCameraDiagnosticsCopyWith<$Res>  {
  factory $CvCameraDiagnosticsCopyWith(CvCameraDiagnostics value, $Res Function(CvCameraDiagnostics) _then) = _$CvCameraDiagnosticsCopyWithImpl;
@useResult
$Res call({
 double reprojectionErrorPx, int correspondenceCount, double cmPerPx
});




}
/// @nodoc
class _$CvCameraDiagnosticsCopyWithImpl<$Res>
    implements $CvCameraDiagnosticsCopyWith<$Res> {
  _$CvCameraDiagnosticsCopyWithImpl(this._self, this._then);

  final CvCameraDiagnostics _self;
  final $Res Function(CvCameraDiagnostics) _then;

/// Create a copy of CvCameraDiagnostics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reprojectionErrorPx = null,Object? correspondenceCount = null,Object? cmPerPx = null,}) {
  return _then(_self.copyWith(
reprojectionErrorPx: null == reprojectionErrorPx ? _self.reprojectionErrorPx : reprojectionErrorPx // ignore: cast_nullable_to_non_nullable
as double,correspondenceCount: null == correspondenceCount ? _self.correspondenceCount : correspondenceCount // ignore: cast_nullable_to_non_nullable
as int,cmPerPx: null == cmPerPx ? _self.cmPerPx : cmPerPx // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CvCameraDiagnostics].
extension CvCameraDiagnosticsPatterns on CvCameraDiagnostics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CvCameraDiagnostics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CvCameraDiagnostics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CvCameraDiagnostics value)  $default,){
final _that = this;
switch (_that) {
case _CvCameraDiagnostics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CvCameraDiagnostics value)?  $default,){
final _that = this;
switch (_that) {
case _CvCameraDiagnostics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double reprojectionErrorPx,  int correspondenceCount,  double cmPerPx)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CvCameraDiagnostics() when $default != null:
return $default(_that.reprojectionErrorPx,_that.correspondenceCount,_that.cmPerPx);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double reprojectionErrorPx,  int correspondenceCount,  double cmPerPx)  $default,) {final _that = this;
switch (_that) {
case _CvCameraDiagnostics():
return $default(_that.reprojectionErrorPx,_that.correspondenceCount,_that.cmPerPx);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double reprojectionErrorPx,  int correspondenceCount,  double cmPerPx)?  $default,) {final _that = this;
switch (_that) {
case _CvCameraDiagnostics() when $default != null:
return $default(_that.reprojectionErrorPx,_that.correspondenceCount,_that.cmPerPx);case _:
  return null;

}
}

}

/// @nodoc


class _CvCameraDiagnostics implements CvCameraDiagnostics {
  const _CvCameraDiagnostics({required this.reprojectionErrorPx, required this.correspondenceCount, required this.cmPerPx});
  

@override final  double reprojectionErrorPx;
@override final  int correspondenceCount;
@override final  double cmPerPx;

/// Create a copy of CvCameraDiagnostics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CvCameraDiagnosticsCopyWith<_CvCameraDiagnostics> get copyWith => __$CvCameraDiagnosticsCopyWithImpl<_CvCameraDiagnostics>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CvCameraDiagnostics&&(identical(other.reprojectionErrorPx, reprojectionErrorPx) || other.reprojectionErrorPx == reprojectionErrorPx)&&(identical(other.correspondenceCount, correspondenceCount) || other.correspondenceCount == correspondenceCount)&&(identical(other.cmPerPx, cmPerPx) || other.cmPerPx == cmPerPx));
}


@override
int get hashCode => Object.hash(runtimeType,reprojectionErrorPx,correspondenceCount,cmPerPx);

@override
String toString() {
  return 'CvCameraDiagnostics(reprojectionErrorPx: $reprojectionErrorPx, correspondenceCount: $correspondenceCount, cmPerPx: $cmPerPx)';
}


}

/// @nodoc
abstract mixin class _$CvCameraDiagnosticsCopyWith<$Res> implements $CvCameraDiagnosticsCopyWith<$Res> {
  factory _$CvCameraDiagnosticsCopyWith(_CvCameraDiagnostics value, $Res Function(_CvCameraDiagnostics) _then) = __$CvCameraDiagnosticsCopyWithImpl;
@override @useResult
$Res call({
 double reprojectionErrorPx, int correspondenceCount, double cmPerPx
});




}
/// @nodoc
class __$CvCameraDiagnosticsCopyWithImpl<$Res>
    implements _$CvCameraDiagnosticsCopyWith<$Res> {
  __$CvCameraDiagnosticsCopyWithImpl(this._self, this._then);

  final _CvCameraDiagnostics _self;
  final $Res Function(_CvCameraDiagnostics) _then;

/// Create a copy of CvCameraDiagnostics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reprojectionErrorPx = null,Object? correspondenceCount = null,Object? cmPerPx = null,}) {
  return _then(_CvCameraDiagnostics(
reprojectionErrorPx: null == reprojectionErrorPx ? _self.reprojectionErrorPx : reprojectionErrorPx // ignore: cast_nullable_to_non_nullable
as double,correspondenceCount: null == correspondenceCount ? _self.correspondenceCount : correspondenceCount // ignore: cast_nullable_to_non_nullable
as int,cmPerPx: null == cmPerPx ? _self.cmPerPx : cmPerPx // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$GeometricVerdict {

 String get accessory; GeometricVerdictStatus get status; String get reason; String get doctrineRef;
/// Create a copy of GeometricVerdict
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeometricVerdictCopyWith<GeometricVerdict> get copyWith => _$GeometricVerdictCopyWithImpl<GeometricVerdict>(this as GeometricVerdict, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeometricVerdict&&(identical(other.accessory, accessory) || other.accessory == accessory)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.doctrineRef, doctrineRef) || other.doctrineRef == doctrineRef));
}


@override
int get hashCode => Object.hash(runtimeType,accessory,status,reason,doctrineRef);

@override
String toString() {
  return 'GeometricVerdict(accessory: $accessory, status: $status, reason: $reason, doctrineRef: $doctrineRef)';
}


}

/// @nodoc
abstract mixin class $GeometricVerdictCopyWith<$Res>  {
  factory $GeometricVerdictCopyWith(GeometricVerdict value, $Res Function(GeometricVerdict) _then) = _$GeometricVerdictCopyWithImpl;
@useResult
$Res call({
 String accessory, GeometricVerdictStatus status, String reason, String doctrineRef
});




}
/// @nodoc
class _$GeometricVerdictCopyWithImpl<$Res>
    implements $GeometricVerdictCopyWith<$Res> {
  _$GeometricVerdictCopyWithImpl(this._self, this._then);

  final GeometricVerdict _self;
  final $Res Function(GeometricVerdict) _then;

/// Create a copy of GeometricVerdict
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessory = null,Object? status = null,Object? reason = null,Object? doctrineRef = null,}) {
  return _then(_self.copyWith(
accessory: null == accessory ? _self.accessory : accessory // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GeometricVerdictStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,doctrineRef: null == doctrineRef ? _self.doctrineRef : doctrineRef // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GeometricVerdict].
extension GeometricVerdictPatterns on GeometricVerdict {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeometricVerdict value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeometricVerdict() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeometricVerdict value)  $default,){
final _that = this;
switch (_that) {
case _GeometricVerdict():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeometricVerdict value)?  $default,){
final _that = this;
switch (_that) {
case _GeometricVerdict() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessory,  GeometricVerdictStatus status,  String reason,  String doctrineRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeometricVerdict() when $default != null:
return $default(_that.accessory,_that.status,_that.reason,_that.doctrineRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessory,  GeometricVerdictStatus status,  String reason,  String doctrineRef)  $default,) {final _that = this;
switch (_that) {
case _GeometricVerdict():
return $default(_that.accessory,_that.status,_that.reason,_that.doctrineRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessory,  GeometricVerdictStatus status,  String reason,  String doctrineRef)?  $default,) {final _that = this;
switch (_that) {
case _GeometricVerdict() when $default != null:
return $default(_that.accessory,_that.status,_that.reason,_that.doctrineRef);case _:
  return null;

}
}

}

/// @nodoc


class _GeometricVerdict implements GeometricVerdict {
  const _GeometricVerdict({required this.accessory, required this.status, required this.reason, required this.doctrineRef});
  

@override final  String accessory;
@override final  GeometricVerdictStatus status;
@override final  String reason;
@override final  String doctrineRef;

/// Create a copy of GeometricVerdict
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeometricVerdictCopyWith<_GeometricVerdict> get copyWith => __$GeometricVerdictCopyWithImpl<_GeometricVerdict>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeometricVerdict&&(identical(other.accessory, accessory) || other.accessory == accessory)&&(identical(other.status, status) || other.status == status)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.doctrineRef, doctrineRef) || other.doctrineRef == doctrineRef));
}


@override
int get hashCode => Object.hash(runtimeType,accessory,status,reason,doctrineRef);

@override
String toString() {
  return 'GeometricVerdict(accessory: $accessory, status: $status, reason: $reason, doctrineRef: $doctrineRef)';
}


}

/// @nodoc
abstract mixin class _$GeometricVerdictCopyWith<$Res> implements $GeometricVerdictCopyWith<$Res> {
  factory _$GeometricVerdictCopyWith(_GeometricVerdict value, $Res Function(_GeometricVerdict) _then) = __$GeometricVerdictCopyWithImpl;
@override @useResult
$Res call({
 String accessory, GeometricVerdictStatus status, String reason, String doctrineRef
});




}
/// @nodoc
class __$GeometricVerdictCopyWithImpl<$Res>
    implements _$GeometricVerdictCopyWith<$Res> {
  __$GeometricVerdictCopyWithImpl(this._self, this._then);

  final _GeometricVerdict _self;
  final $Res Function(_GeometricVerdict) _then;

/// Create a copy of GeometricVerdict
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessory = null,Object? status = null,Object? reason = null,Object? doctrineRef = null,}) {
  return _then(_GeometricVerdict(
accessory: null == accessory ? _self.accessory : accessory // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GeometricVerdictStatus,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,doctrineRef: null == doctrineRef ? _self.doctrineRef : doctrineRef // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CvInspectionResult {

 double get overallScore; String get status; CvSubscores get subscores; List<CvIssue> get issues; List<CvUncertainItem> get uncertain; int get itemsEvaluated; CvCameraDiagnostics get cameraDiagnostics; List<GeometricVerdict> get geometricVerdicts; String? get annotatedImageBase64;
/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CvInspectionResultCopyWith<CvInspectionResult> get copyWith => _$CvInspectionResultCopyWithImpl<CvInspectionResult>(this as CvInspectionResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CvInspectionResult&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.status, status) || other.status == status)&&(identical(other.subscores, subscores) || other.subscores == subscores)&&const DeepCollectionEquality().equals(other.issues, issues)&&const DeepCollectionEquality().equals(other.uncertain, uncertain)&&(identical(other.itemsEvaluated, itemsEvaluated) || other.itemsEvaluated == itemsEvaluated)&&(identical(other.cameraDiagnostics, cameraDiagnostics) || other.cameraDiagnostics == cameraDiagnostics)&&const DeepCollectionEquality().equals(other.geometricVerdicts, geometricVerdicts)&&(identical(other.annotatedImageBase64, annotatedImageBase64) || other.annotatedImageBase64 == annotatedImageBase64));
}


@override
int get hashCode => Object.hash(runtimeType,overallScore,status,subscores,const DeepCollectionEquality().hash(issues),const DeepCollectionEquality().hash(uncertain),itemsEvaluated,cameraDiagnostics,const DeepCollectionEquality().hash(geometricVerdicts),annotatedImageBase64);

@override
String toString() {
  return 'CvInspectionResult(overallScore: $overallScore, status: $status, subscores: $subscores, issues: $issues, uncertain: $uncertain, itemsEvaluated: $itemsEvaluated, cameraDiagnostics: $cameraDiagnostics, geometricVerdicts: $geometricVerdicts, annotatedImageBase64: $annotatedImageBase64)';
}


}

/// @nodoc
abstract mixin class $CvInspectionResultCopyWith<$Res>  {
  factory $CvInspectionResultCopyWith(CvInspectionResult value, $Res Function(CvInspectionResult) _then) = _$CvInspectionResultCopyWithImpl;
@useResult
$Res call({
 double overallScore, String status, CvSubscores subscores, List<CvIssue> issues, List<CvUncertainItem> uncertain, int itemsEvaluated, CvCameraDiagnostics cameraDiagnostics, List<GeometricVerdict> geometricVerdicts, String? annotatedImageBase64
});


$CvSubscoresCopyWith<$Res> get subscores;$CvCameraDiagnosticsCopyWith<$Res> get cameraDiagnostics;

}
/// @nodoc
class _$CvInspectionResultCopyWithImpl<$Res>
    implements $CvInspectionResultCopyWith<$Res> {
  _$CvInspectionResultCopyWithImpl(this._self, this._then);

  final CvInspectionResult _self;
  final $Res Function(CvInspectionResult) _then;

/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallScore = null,Object? status = null,Object? subscores = null,Object? issues = null,Object? uncertain = null,Object? itemsEvaluated = null,Object? cameraDiagnostics = null,Object? geometricVerdicts = null,Object? annotatedImageBase64 = freezed,}) {
  return _then(_self.copyWith(
overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,subscores: null == subscores ? _self.subscores : subscores // ignore: cast_nullable_to_non_nullable
as CvSubscores,issues: null == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as List<CvIssue>,uncertain: null == uncertain ? _self.uncertain : uncertain // ignore: cast_nullable_to_non_nullable
as List<CvUncertainItem>,itemsEvaluated: null == itemsEvaluated ? _self.itemsEvaluated : itemsEvaluated // ignore: cast_nullable_to_non_nullable
as int,cameraDiagnostics: null == cameraDiagnostics ? _self.cameraDiagnostics : cameraDiagnostics // ignore: cast_nullable_to_non_nullable
as CvCameraDiagnostics,geometricVerdicts: null == geometricVerdicts ? _self.geometricVerdicts : geometricVerdicts // ignore: cast_nullable_to_non_nullable
as List<GeometricVerdict>,annotatedImageBase64: freezed == annotatedImageBase64 ? _self.annotatedImageBase64 : annotatedImageBase64 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CvSubscoresCopyWith<$Res> get subscores {
  
  return $CvSubscoresCopyWith<$Res>(_self.subscores, (value) {
    return _then(_self.copyWith(subscores: value));
  });
}/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CvCameraDiagnosticsCopyWith<$Res> get cameraDiagnostics {
  
  return $CvCameraDiagnosticsCopyWith<$Res>(_self.cameraDiagnostics, (value) {
    return _then(_self.copyWith(cameraDiagnostics: value));
  });
}
}


/// Adds pattern-matching-related methods to [CvInspectionResult].
extension CvInspectionResultPatterns on CvInspectionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CvInspectionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CvInspectionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CvInspectionResult value)  $default,){
final _that = this;
switch (_that) {
case _CvInspectionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CvInspectionResult value)?  $default,){
final _that = this;
switch (_that) {
case _CvInspectionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double overallScore,  String status,  CvSubscores subscores,  List<CvIssue> issues,  List<CvUncertainItem> uncertain,  int itemsEvaluated,  CvCameraDiagnostics cameraDiagnostics,  List<GeometricVerdict> geometricVerdicts,  String? annotatedImageBase64)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CvInspectionResult() when $default != null:
return $default(_that.overallScore,_that.status,_that.subscores,_that.issues,_that.uncertain,_that.itemsEvaluated,_that.cameraDiagnostics,_that.geometricVerdicts,_that.annotatedImageBase64);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double overallScore,  String status,  CvSubscores subscores,  List<CvIssue> issues,  List<CvUncertainItem> uncertain,  int itemsEvaluated,  CvCameraDiagnostics cameraDiagnostics,  List<GeometricVerdict> geometricVerdicts,  String? annotatedImageBase64)  $default,) {final _that = this;
switch (_that) {
case _CvInspectionResult():
return $default(_that.overallScore,_that.status,_that.subscores,_that.issues,_that.uncertain,_that.itemsEvaluated,_that.cameraDiagnostics,_that.geometricVerdicts,_that.annotatedImageBase64);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double overallScore,  String status,  CvSubscores subscores,  List<CvIssue> issues,  List<CvUncertainItem> uncertain,  int itemsEvaluated,  CvCameraDiagnostics cameraDiagnostics,  List<GeometricVerdict> geometricVerdicts,  String? annotatedImageBase64)?  $default,) {final _that = this;
switch (_that) {
case _CvInspectionResult() when $default != null:
return $default(_that.overallScore,_that.status,_that.subscores,_that.issues,_that.uncertain,_that.itemsEvaluated,_that.cameraDiagnostics,_that.geometricVerdicts,_that.annotatedImageBase64);case _:
  return null;

}
}

}

/// @nodoc


class _CvInspectionResult extends CvInspectionResult {
  const _CvInspectionResult({required this.overallScore, required this.status, required this.subscores, required final  List<CvIssue> issues, required final  List<CvUncertainItem> uncertain, required this.itemsEvaluated, required this.cameraDiagnostics, final  List<GeometricVerdict> geometricVerdicts = const [], this.annotatedImageBase64}): _issues = issues,_uncertain = uncertain,_geometricVerdicts = geometricVerdicts,super._();
  

@override final  double overallScore;
@override final  String status;
@override final  CvSubscores subscores;
 final  List<CvIssue> _issues;
@override List<CvIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}

 final  List<CvUncertainItem> _uncertain;
@override List<CvUncertainItem> get uncertain {
  if (_uncertain is EqualUnmodifiableListView) return _uncertain;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_uncertain);
}

@override final  int itemsEvaluated;
@override final  CvCameraDiagnostics cameraDiagnostics;
 final  List<GeometricVerdict> _geometricVerdicts;
@override@JsonKey() List<GeometricVerdict> get geometricVerdicts {
  if (_geometricVerdicts is EqualUnmodifiableListView) return _geometricVerdicts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_geometricVerdicts);
}

@override final  String? annotatedImageBase64;

/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CvInspectionResultCopyWith<_CvInspectionResult> get copyWith => __$CvInspectionResultCopyWithImpl<_CvInspectionResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CvInspectionResult&&(identical(other.overallScore, overallScore) || other.overallScore == overallScore)&&(identical(other.status, status) || other.status == status)&&(identical(other.subscores, subscores) || other.subscores == subscores)&&const DeepCollectionEquality().equals(other._issues, _issues)&&const DeepCollectionEquality().equals(other._uncertain, _uncertain)&&(identical(other.itemsEvaluated, itemsEvaluated) || other.itemsEvaluated == itemsEvaluated)&&(identical(other.cameraDiagnostics, cameraDiagnostics) || other.cameraDiagnostics == cameraDiagnostics)&&const DeepCollectionEquality().equals(other._geometricVerdicts, _geometricVerdicts)&&(identical(other.annotatedImageBase64, annotatedImageBase64) || other.annotatedImageBase64 == annotatedImageBase64));
}


@override
int get hashCode => Object.hash(runtimeType,overallScore,status,subscores,const DeepCollectionEquality().hash(_issues),const DeepCollectionEquality().hash(_uncertain),itemsEvaluated,cameraDiagnostics,const DeepCollectionEquality().hash(_geometricVerdicts),annotatedImageBase64);

@override
String toString() {
  return 'CvInspectionResult(overallScore: $overallScore, status: $status, subscores: $subscores, issues: $issues, uncertain: $uncertain, itemsEvaluated: $itemsEvaluated, cameraDiagnostics: $cameraDiagnostics, geometricVerdicts: $geometricVerdicts, annotatedImageBase64: $annotatedImageBase64)';
}


}

/// @nodoc
abstract mixin class _$CvInspectionResultCopyWith<$Res> implements $CvInspectionResultCopyWith<$Res> {
  factory _$CvInspectionResultCopyWith(_CvInspectionResult value, $Res Function(_CvInspectionResult) _then) = __$CvInspectionResultCopyWithImpl;
@override @useResult
$Res call({
 double overallScore, String status, CvSubscores subscores, List<CvIssue> issues, List<CvUncertainItem> uncertain, int itemsEvaluated, CvCameraDiagnostics cameraDiagnostics, List<GeometricVerdict> geometricVerdicts, String? annotatedImageBase64
});


@override $CvSubscoresCopyWith<$Res> get subscores;@override $CvCameraDiagnosticsCopyWith<$Res> get cameraDiagnostics;

}
/// @nodoc
class __$CvInspectionResultCopyWithImpl<$Res>
    implements _$CvInspectionResultCopyWith<$Res> {
  __$CvInspectionResultCopyWithImpl(this._self, this._then);

  final _CvInspectionResult _self;
  final $Res Function(_CvInspectionResult) _then;

/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallScore = null,Object? status = null,Object? subscores = null,Object? issues = null,Object? uncertain = null,Object? itemsEvaluated = null,Object? cameraDiagnostics = null,Object? geometricVerdicts = null,Object? annotatedImageBase64 = freezed,}) {
  return _then(_CvInspectionResult(
overallScore: null == overallScore ? _self.overallScore : overallScore // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,subscores: null == subscores ? _self.subscores : subscores // ignore: cast_nullable_to_non_nullable
as CvSubscores,issues: null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<CvIssue>,uncertain: null == uncertain ? _self._uncertain : uncertain // ignore: cast_nullable_to_non_nullable
as List<CvUncertainItem>,itemsEvaluated: null == itemsEvaluated ? _self.itemsEvaluated : itemsEvaluated // ignore: cast_nullable_to_non_nullable
as int,cameraDiagnostics: null == cameraDiagnostics ? _self.cameraDiagnostics : cameraDiagnostics // ignore: cast_nullable_to_non_nullable
as CvCameraDiagnostics,geometricVerdicts: null == geometricVerdicts ? _self._geometricVerdicts : geometricVerdicts // ignore: cast_nullable_to_non_nullable
as List<GeometricVerdict>,annotatedImageBase64: freezed == annotatedImageBase64 ? _self.annotatedImageBase64 : annotatedImageBase64 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CvSubscoresCopyWith<$Res> get subscores {
  
  return $CvSubscoresCopyWith<$Res>(_self.subscores, (value) {
    return _then(_self.copyWith(subscores: value));
  });
}/// Create a copy of CvInspectionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CvCameraDiagnosticsCopyWith<$Res> get cameraDiagnostics {
  
  return $CvCameraDiagnosticsCopyWith<$Res>(_self.cameraDiagnostics, (value) {
    return _then(_self.copyWith(cameraDiagnostics: value));
  });
}
}

// dart format on

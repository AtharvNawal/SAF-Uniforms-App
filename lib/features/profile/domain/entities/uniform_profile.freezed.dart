// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'uniform_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UniformProfile {

 BranchId get branch; Rank get rank; Gender get gender; DressCode get dressCode; bool get isSikh; String get fullName; String get vocation; int get medalRowCount;/// Standing height in cm, `0` = not given. Optional; sent to
/// `cv-service` so the reference body is scaled to the wearer, which
/// makes the uniform measurements more accurate (see
/// `ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`, D16).
/// Not part of the 3D-model profile hash.
 int get heightCm; Set<String> get selectedBadgeIds; Set<String> get selectedAccessoryIds; Map<String, Set<String>> get dressAccessoryChecks; Map<String, GeneratedDress> get generatedDresses;
/// Create a copy of UniformProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UniformProfileCopyWith<UniformProfile> get copyWith => _$UniformProfileCopyWithImpl<UniformProfile>(this as UniformProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UniformProfile&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dressCode, dressCode) || other.dressCode == dressCode)&&(identical(other.isSikh, isSikh) || other.isSikh == isSikh)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.vocation, vocation) || other.vocation == vocation)&&(identical(other.medalRowCount, medalRowCount) || other.medalRowCount == medalRowCount)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&const DeepCollectionEquality().equals(other.selectedBadgeIds, selectedBadgeIds)&&const DeepCollectionEquality().equals(other.selectedAccessoryIds, selectedAccessoryIds)&&const DeepCollectionEquality().equals(other.dressAccessoryChecks, dressAccessoryChecks)&&const DeepCollectionEquality().equals(other.generatedDresses, generatedDresses));
}


@override
int get hashCode => Object.hash(runtimeType,branch,rank,gender,dressCode,isSikh,fullName,vocation,medalRowCount,heightCm,const DeepCollectionEquality().hash(selectedBadgeIds),const DeepCollectionEquality().hash(selectedAccessoryIds),const DeepCollectionEquality().hash(dressAccessoryChecks),const DeepCollectionEquality().hash(generatedDresses));

@override
String toString() {
  return 'UniformProfile(branch: $branch, rank: $rank, gender: $gender, dressCode: $dressCode, isSikh: $isSikh, fullName: $fullName, vocation: $vocation, medalRowCount: $medalRowCount, heightCm: $heightCm, selectedBadgeIds: $selectedBadgeIds, selectedAccessoryIds: $selectedAccessoryIds, dressAccessoryChecks: $dressAccessoryChecks, generatedDresses: $generatedDresses)';
}


}

/// @nodoc
abstract mixin class $UniformProfileCopyWith<$Res>  {
  factory $UniformProfileCopyWith(UniformProfile value, $Res Function(UniformProfile) _then) = _$UniformProfileCopyWithImpl;
@useResult
$Res call({
 BranchId branch, Rank rank, Gender gender, DressCode dressCode, bool isSikh, String fullName, String vocation, int medalRowCount, int heightCm, Set<String> selectedBadgeIds, Set<String> selectedAccessoryIds, Map<String, Set<String>> dressAccessoryChecks, Map<String, GeneratedDress> generatedDresses
});




}
/// @nodoc
class _$UniformProfileCopyWithImpl<$Res>
    implements $UniformProfileCopyWith<$Res> {
  _$UniformProfileCopyWithImpl(this._self, this._then);

  final UniformProfile _self;
  final $Res Function(UniformProfile) _then;

/// Create a copy of UniformProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branch = null,Object? rank = null,Object? gender = null,Object? dressCode = null,Object? isSikh = null,Object? fullName = null,Object? vocation = null,Object? medalRowCount = null,Object? heightCm = null,Object? selectedBadgeIds = null,Object? selectedAccessoryIds = null,Object? dressAccessoryChecks = null,Object? generatedDresses = null,}) {
  return _then(_self.copyWith(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as BranchId,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as Rank,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,dressCode: null == dressCode ? _self.dressCode : dressCode // ignore: cast_nullable_to_non_nullable
as DressCode,isSikh: null == isSikh ? _self.isSikh : isSikh // ignore: cast_nullable_to_non_nullable
as bool,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,vocation: null == vocation ? _self.vocation : vocation // ignore: cast_nullable_to_non_nullable
as String,medalRowCount: null == medalRowCount ? _self.medalRowCount : medalRowCount // ignore: cast_nullable_to_non_nullable
as int,heightCm: null == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int,selectedBadgeIds: null == selectedBadgeIds ? _self.selectedBadgeIds : selectedBadgeIds // ignore: cast_nullable_to_non_nullable
as Set<String>,selectedAccessoryIds: null == selectedAccessoryIds ? _self.selectedAccessoryIds : selectedAccessoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,dressAccessoryChecks: null == dressAccessoryChecks ? _self.dressAccessoryChecks : dressAccessoryChecks // ignore: cast_nullable_to_non_nullable
as Map<String, Set<String>>,generatedDresses: null == generatedDresses ? _self.generatedDresses : generatedDresses // ignore: cast_nullable_to_non_nullable
as Map<String, GeneratedDress>,
  ));
}

}


/// Adds pattern-matching-related methods to [UniformProfile].
extension UniformProfilePatterns on UniformProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UniformProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UniformProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UniformProfile value)  $default,){
final _that = this;
switch (_that) {
case _UniformProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UniformProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UniformProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BranchId branch,  Rank rank,  Gender gender,  DressCode dressCode,  bool isSikh,  String fullName,  String vocation,  int medalRowCount,  int heightCm,  Set<String> selectedBadgeIds,  Set<String> selectedAccessoryIds,  Map<String, Set<String>> dressAccessoryChecks,  Map<String, GeneratedDress> generatedDresses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UniformProfile() when $default != null:
return $default(_that.branch,_that.rank,_that.gender,_that.dressCode,_that.isSikh,_that.fullName,_that.vocation,_that.medalRowCount,_that.heightCm,_that.selectedBadgeIds,_that.selectedAccessoryIds,_that.dressAccessoryChecks,_that.generatedDresses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BranchId branch,  Rank rank,  Gender gender,  DressCode dressCode,  bool isSikh,  String fullName,  String vocation,  int medalRowCount,  int heightCm,  Set<String> selectedBadgeIds,  Set<String> selectedAccessoryIds,  Map<String, Set<String>> dressAccessoryChecks,  Map<String, GeneratedDress> generatedDresses)  $default,) {final _that = this;
switch (_that) {
case _UniformProfile():
return $default(_that.branch,_that.rank,_that.gender,_that.dressCode,_that.isSikh,_that.fullName,_that.vocation,_that.medalRowCount,_that.heightCm,_that.selectedBadgeIds,_that.selectedAccessoryIds,_that.dressAccessoryChecks,_that.generatedDresses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BranchId branch,  Rank rank,  Gender gender,  DressCode dressCode,  bool isSikh,  String fullName,  String vocation,  int medalRowCount,  int heightCm,  Set<String> selectedBadgeIds,  Set<String> selectedAccessoryIds,  Map<String, Set<String>> dressAccessoryChecks,  Map<String, GeneratedDress> generatedDresses)?  $default,) {final _that = this;
switch (_that) {
case _UniformProfile() when $default != null:
return $default(_that.branch,_that.rank,_that.gender,_that.dressCode,_that.isSikh,_that.fullName,_that.vocation,_that.medalRowCount,_that.heightCm,_that.selectedBadgeIds,_that.selectedAccessoryIds,_that.dressAccessoryChecks,_that.generatedDresses);case _:
  return null;

}
}

}

/// @nodoc


class _UniformProfile implements UniformProfile {
  const _UniformProfile({this.branch = BranchId.army, this.rank = Rank.rec, this.gender = Gender.male, this.dressCode = DressCode.no3, this.isSikh = false, this.fullName = '', this.vocation = 'Infantry', this.medalRowCount = 0, this.heightCm = 0, final  Set<String> selectedBadgeIds = const <String>{}, final  Set<String> selectedAccessoryIds = const <String>{}, final  Map<String, Set<String>> dressAccessoryChecks = const <String, Set<String>>{}, final  Map<String, GeneratedDress> generatedDresses = const <String, GeneratedDress>{}}): _selectedBadgeIds = selectedBadgeIds,_selectedAccessoryIds = selectedAccessoryIds,_dressAccessoryChecks = dressAccessoryChecks,_generatedDresses = generatedDresses;
  

@override@JsonKey() final  BranchId branch;
@override@JsonKey() final  Rank rank;
@override@JsonKey() final  Gender gender;
@override@JsonKey() final  DressCode dressCode;
@override@JsonKey() final  bool isSikh;
@override@JsonKey() final  String fullName;
@override@JsonKey() final  String vocation;
@override@JsonKey() final  int medalRowCount;
/// Standing height in cm, `0` = not given. Optional; sent to
/// `cv-service` so the reference body is scaled to the wearer, which
/// makes the uniform measurements more accurate (see
/// `ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`, D16).
/// Not part of the 3D-model profile hash.
@override@JsonKey() final  int heightCm;
 final  Set<String> _selectedBadgeIds;
@override@JsonKey() Set<String> get selectedBadgeIds {
  if (_selectedBadgeIds is EqualUnmodifiableSetView) return _selectedBadgeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedBadgeIds);
}

 final  Set<String> _selectedAccessoryIds;
@override@JsonKey() Set<String> get selectedAccessoryIds {
  if (_selectedAccessoryIds is EqualUnmodifiableSetView) return _selectedAccessoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedAccessoryIds);
}

 final  Map<String, Set<String>> _dressAccessoryChecks;
@override@JsonKey() Map<String, Set<String>> get dressAccessoryChecks {
  if (_dressAccessoryChecks is EqualUnmodifiableMapView) return _dressAccessoryChecks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dressAccessoryChecks);
}

 final  Map<String, GeneratedDress> _generatedDresses;
@override@JsonKey() Map<String, GeneratedDress> get generatedDresses {
  if (_generatedDresses is EqualUnmodifiableMapView) return _generatedDresses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_generatedDresses);
}


/// Create a copy of UniformProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UniformProfileCopyWith<_UniformProfile> get copyWith => __$UniformProfileCopyWithImpl<_UniformProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UniformProfile&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dressCode, dressCode) || other.dressCode == dressCode)&&(identical(other.isSikh, isSikh) || other.isSikh == isSikh)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.vocation, vocation) || other.vocation == vocation)&&(identical(other.medalRowCount, medalRowCount) || other.medalRowCount == medalRowCount)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&const DeepCollectionEquality().equals(other._selectedBadgeIds, _selectedBadgeIds)&&const DeepCollectionEquality().equals(other._selectedAccessoryIds, _selectedAccessoryIds)&&const DeepCollectionEquality().equals(other._dressAccessoryChecks, _dressAccessoryChecks)&&const DeepCollectionEquality().equals(other._generatedDresses, _generatedDresses));
}


@override
int get hashCode => Object.hash(runtimeType,branch,rank,gender,dressCode,isSikh,fullName,vocation,medalRowCount,heightCm,const DeepCollectionEquality().hash(_selectedBadgeIds),const DeepCollectionEquality().hash(_selectedAccessoryIds),const DeepCollectionEquality().hash(_dressAccessoryChecks),const DeepCollectionEquality().hash(_generatedDresses));

@override
String toString() {
  return 'UniformProfile(branch: $branch, rank: $rank, gender: $gender, dressCode: $dressCode, isSikh: $isSikh, fullName: $fullName, vocation: $vocation, medalRowCount: $medalRowCount, heightCm: $heightCm, selectedBadgeIds: $selectedBadgeIds, selectedAccessoryIds: $selectedAccessoryIds, dressAccessoryChecks: $dressAccessoryChecks, generatedDresses: $generatedDresses)';
}


}

/// @nodoc
abstract mixin class _$UniformProfileCopyWith<$Res> implements $UniformProfileCopyWith<$Res> {
  factory _$UniformProfileCopyWith(_UniformProfile value, $Res Function(_UniformProfile) _then) = __$UniformProfileCopyWithImpl;
@override @useResult
$Res call({
 BranchId branch, Rank rank, Gender gender, DressCode dressCode, bool isSikh, String fullName, String vocation, int medalRowCount, int heightCm, Set<String> selectedBadgeIds, Set<String> selectedAccessoryIds, Map<String, Set<String>> dressAccessoryChecks, Map<String, GeneratedDress> generatedDresses
});




}
/// @nodoc
class __$UniformProfileCopyWithImpl<$Res>
    implements _$UniformProfileCopyWith<$Res> {
  __$UniformProfileCopyWithImpl(this._self, this._then);

  final _UniformProfile _self;
  final $Res Function(_UniformProfile) _then;

/// Create a copy of UniformProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branch = null,Object? rank = null,Object? gender = null,Object? dressCode = null,Object? isSikh = null,Object? fullName = null,Object? vocation = null,Object? medalRowCount = null,Object? heightCm = null,Object? selectedBadgeIds = null,Object? selectedAccessoryIds = null,Object? dressAccessoryChecks = null,Object? generatedDresses = null,}) {
  return _then(_UniformProfile(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as BranchId,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as Rank,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as Gender,dressCode: null == dressCode ? _self.dressCode : dressCode // ignore: cast_nullable_to_non_nullable
as DressCode,isSikh: null == isSikh ? _self.isSikh : isSikh // ignore: cast_nullable_to_non_nullable
as bool,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,vocation: null == vocation ? _self.vocation : vocation // ignore: cast_nullable_to_non_nullable
as String,medalRowCount: null == medalRowCount ? _self.medalRowCount : medalRowCount // ignore: cast_nullable_to_non_nullable
as int,heightCm: null == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int,selectedBadgeIds: null == selectedBadgeIds ? _self._selectedBadgeIds : selectedBadgeIds // ignore: cast_nullable_to_non_nullable
as Set<String>,selectedAccessoryIds: null == selectedAccessoryIds ? _self._selectedAccessoryIds : selectedAccessoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,dressAccessoryChecks: null == dressAccessoryChecks ? _self._dressAccessoryChecks : dressAccessoryChecks // ignore: cast_nullable_to_non_nullable
as Map<String, Set<String>>,generatedDresses: null == generatedDresses ? _self._generatedDresses : generatedDresses // ignore: cast_nullable_to_non_nullable
as Map<String, GeneratedDress>,
  ));
}


}

// dart format on

import 'package:freezed_annotation/freezed_annotation.dart';

import 'branch_id.dart';
import 'dress_code.dart';
import 'gender.dart';
import 'generated_dress.dart';
import 'rank.dart';

part 'uniform_profile.freezed.dart';

@freezed
abstract class UniformProfile with _$UniformProfile {
  const factory UniformProfile({
    @Default(BranchId.army) BranchId branch,
    @Default(Rank.rec) Rank rank,
    @Default(Gender.male) Gender gender,
    @Default(DressCode.no3) DressCode dressCode,
    @Default(false) bool isSikh,
    @Default('') String fullName,
    @Default('Infantry') String vocation,
    @Default(0) int medalRowCount,
    @Default(<String>{}) Set<String> selectedBadgeIds,
    @Default(<String>{}) Set<String> selectedAccessoryIds,
    @Default(<String, Set<String>>{})
    Map<String, Set<String>> dressAccessoryChecks,
    @Default(<String, GeneratedDress>{}) Map<String, GeneratedDress> generatedDresses,
  }) = _UniformProfile;
}

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

    /// Standing height in cm, `0` = not given. Optional; sent to
    /// `cv-service` so the reference body is scaled to the wearer, which
    /// makes the uniform measurements more accurate (see
    /// `ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`, D16).
    /// Not part of the 3D-model profile hash.
    @Default(0) int heightCm,
    @Default(<String>{}) Set<String> selectedBadgeIds,
    @Default(<String>{}) Set<String> selectedAccessoryIds,
    @Default(<String, Set<String>>{})
    Map<String, Set<String>> dressAccessoryChecks,
    @Default(<String, GeneratedDress>{}) Map<String, GeneratedDress> generatedDresses,
  }) = _UniformProfile;
}

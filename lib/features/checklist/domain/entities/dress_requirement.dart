import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../profile/domain/entities/branch_id.dart';

part 'dress_requirement.freezed.dart';

@freezed
abstract class DressRequirement with _$DressRequirement {
  const DressRequirement._();

  const factory DressRequirement({
    required String id,
    required String dressName,
    @Default('') String displayName,
    @Default('') String subtitle,
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> mandatoryRules,
    @Default(<String, dynamic>{}) Map<String, dynamic> optionalLogic,
    @Default(<String, Map<String, dynamic>>{})
    Map<String, Map<String, dynamic>> branchOverrides,
    @Default(1) int version,
  }) = _DressRequirement;

  /// Resolve the requirement for a specific branch by replacing top-level
  /// keys (`mandatory_rules`, `optional_logic`) with the branch override
  /// when one is present. Falls back to the base when no override exists.
  DressRequirement mergedFor(BranchId branch) {
    final override = branchOverrides[branch.wireName];
    if (override == null || override.isEmpty) return this;

    final overrideMandatory = override['mandatory_rules'];
    final overrideOptional = override['optional_logic'];

    return copyWith(
      mandatoryRules: overrideMandatory is List
          ? overrideMandatory
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(growable: false)
          : mandatoryRules,
      optionalLogic: overrideOptional is Map
          ? Map<String, dynamic>.from(overrideOptional)
          : optionalLogic,
    );
  }
}

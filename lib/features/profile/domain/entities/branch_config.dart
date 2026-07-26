import 'package:freezed_annotation/freezed_annotation.dart';

import 'branch_id.dart';
import 'dress_code.dart';

part 'branch_config.freezed.dart';
part 'branch_config.g.dart';

@freezed
abstract class MedalAnchor with _$MedalAnchor {
  const factory MedalAnchor({
    required String anchor,
    required AnchorOffset offsetCm,
  }) = _MedalAnchor;

  factory MedalAnchor.fromJson(Map<String, dynamic> json) =>
      _$MedalAnchorFromJson(json);
}

@freezed
abstract class AnchorOffset with _$AnchorOffset {
  const factory AnchorOffset({
    required double x,
    required double y,
  }) = _AnchorOffset;

  factory AnchorOffset.fromJson(Map<String, dynamic> json) =>
      _$AnchorOffsetFromJson(json);
}

@freezed
abstract class SikhTurbanLogic with _$SikhTurbanLogic {
  const factory SikhTurbanLogic({
    required bool replacesHeadgear,
    required String color,
    required String alignmentOverride,
  }) = _SikhTurbanLogic;

  factory SikhTurbanLogic.fromJson(Map<String, dynamic> json) =>
      _$SikhTurbanLogicFromJson(json);
}

@freezed
abstract class BranchConfig with _$BranchConfig {
  const factory BranchConfig({
    required BranchId branchId,
    required String displayName,
    required double collarOffsetCm,
    required MedalAnchor ladiesMedalAnchor,
    required SikhTurbanLogic sikhTurbanLogic,
    required List<DressCode> dressCodes,
    @Default(1) int version,
  }) = _BranchConfig;

  factory BranchConfig.fromJson(Map<String, dynamic> json) =>
      _$BranchConfigFromJson(json);
}

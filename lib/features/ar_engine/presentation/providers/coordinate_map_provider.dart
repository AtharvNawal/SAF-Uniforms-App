import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../profile/domain/entities/branch_config.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../../profile/domain/entities/medal_vertical_shift_rule.dart';
import '../../../profile/domain/entities/uniform_profile.dart';
import '../../../profile/presentation/providers/branch_config_provider.dart';
import '../../../profile/presentation/providers/global_rules_provider.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../../domain/coordinate_map.dart';

part 'coordinate_map_provider.g.dart';

/// Default chest-badge anchor in cm before any vertical-shift rule is
/// applied. Lives on the centerline, slightly above the medal anchor.
const double _chestBadgeBaseYCm = 2.5;

/// Pure derivation: `(profile, branchConfig, verticalShiftRule) -> CoordinateMap`.
///
/// Any change to any input causes Riverpod to re-evaluate, which triggers a
/// rebuild of the GhostModelView. Reactive bridge between profile state,
/// branch config, global rules, and the 3D renderer.
@Riverpod(keepAlive: true)
CoordinateMap coordinateMap(Ref ref) {
  final profile = ref.watch(uniformProfileProvider);
  final config = ref.watch(branchConfigForProvider(profile.branch));
  if (config == null) return CoordinateMap.empty;
  final shiftRule = ref.watch(medalVerticalShiftRuleProvider).maybeWhen(
        data: (rule) => rule,
        orElse: () => null,
      );
  return calculateCoordinateMap(profile, config, shiftRule);
}

/// Pure function — easy to unit-test without a 3D renderer.
///
/// Captures the topology (Army 3cm vs Navy 1cm collar offset) and applies
/// the cross-branch Vertical Shift rule for chest badges when the wearer
/// has [MedalVerticalShiftRule.minRows] rows of medals or more.
CoordinateMap calculateCoordinateMap(
  UniformProfile profile,
  BranchConfig config,
  MedalVerticalShiftRule? shiftRule,
) {
  final shiftCm = shiftRule?.shiftCmFor(profile.medalRowCount) ?? 0.0;

  final anchors = <String, Anchor3D>{
    'collar': Anchor3D(
      id: 'collar',
      x: 0.0,
      y: -config.collarOffsetCm / 100.0,
      z: 0.0,
    ),
    'chestBadge': Anchor3D(
      id: 'chestBadge',
      x: 0.0,
      // Y grows downward in screen-space; subtract the shift (a positive
      // shift means the badge moves further down to make room for medals).
      y: (_chestBadgeBaseYCm + shiftCm) / 100.0,
      z: 0.0,
    ),
  };

  if (profile.gender == Gender.female) {
    anchors['ladiesMedal'] = Anchor3D(
      id: 'ladiesMedal',
      x: config.ladiesMedalAnchor.offsetCm.x / 100.0,
      y: config.ladiesMedalAnchor.offsetCm.y / 100.0,
      z: 0.0,
    );
  }

  if (profile.isSikh && config.sikhTurbanLogic.replacesHeadgear) {
    anchors['turban'] = const Anchor3D(
      id: 'turban',
      x: 0.0,
      y: 0.0,
      z: 0.0,
    );
  }

  return CoordinateMap(
    branch: profile.branch,
    dressCode: profile.dressCode,
    gender: profile.gender,
    isSikh: profile.isSikh,
    collarOffsetCm: config.collarOffsetCm,
    anchors: anchors,
  );
}

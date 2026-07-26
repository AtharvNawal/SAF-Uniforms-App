import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_engine/presentation/providers/coordinate_map_provider.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_config.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';
import 'package:saf_uniforms/features/profile/domain/entities/medal_vertical_shift_rule.dart';
import 'package:saf_uniforms/features/profile/domain/entities/rank.dart';
import 'package:saf_uniforms/features/profile/domain/entities/uniform_profile.dart';

const _armyConfig = BranchConfig(
  branchId: BranchId.army,
  displayName: 'Singapore Army',
  collarOffsetCm: 3.0,
  ladiesMedalAnchor: MedalAnchor(
    anchor: 'leftLapelCenter',
    offsetCm: AnchorOffset(x: 0.0, y: 1.5),
  ),
  sikhTurbanLogic: SikhTurbanLogic(
    replacesHeadgear: true,
    color: 'matchUniform',
    alignmentOverride: 'turbanCenterline',
  ),
  dressCodes: [
    DressCode.no1,
    DressCode.no2,
    DressCode.no3,
    DressCode.no4,
    DressCode.no5,
  ],
);

const _shiftRule = MedalVerticalShiftRule(
  minRows: 3,
  verticalShiftCmPerExtraRow: 1.0,
);

UniformProfile _profile({int medalRowCount = 0}) {
  return UniformProfile(
    branch: BranchId.army,
    rank: Rank.rec,
    gender: Gender.male,
    dressCode: DressCode.no3,
    medalRowCount: medalRowCount,
  );
}

const double _baseChestBadgeCm = 2.5;

double _chestBadgeYCm(int rows) {
  final map = calculateCoordinateMap(
    _profile(medalRowCount: rows),
    _armyConfig,
    _shiftRule,
  );
  // Y is stored in metres; convert back to cm for assertions.
  return map.anchors['chestBadge']!.y * 100.0;
}

void main() {
  group('vertical shift rule', () {
    test('shiftCmFor returns 0 below minRows', () {
      expect(_shiftRule.shiftCmFor(0), 0.0);
      expect(_shiftRule.shiftCmFor(2), 0.0);
    });

    test('shiftCmFor returns 1cm at exactly minRows', () {
      expect(_shiftRule.shiftCmFor(3), 1.0);
    });

    test('shiftCmFor scales linearly past minRows', () {
      expect(_shiftRule.shiftCmFor(4), 2.0);
      expect(_shiftRule.shiftCmFor(5), 3.0);
    });
  });

  group('calculateCoordinateMap chest badge anchor', () {
    test('0 rows: badge at base position', () {
      expect(_chestBadgeYCm(0), closeTo(_baseChestBadgeCm, 1e-9));
    });

    test('2 rows (boundary): no shift applied', () {
      expect(_chestBadgeYCm(2), closeTo(_baseChestBadgeCm, 1e-9));
    });

    test('3 rows: badge shifts down by 1cm', () {
      expect(_chestBadgeYCm(3), closeTo(_baseChestBadgeCm + 1.0, 1e-9));
    });

    test('5 rows: badge shifts down by 3cm', () {
      expect(_chestBadgeYCm(5), closeTo(_baseChestBadgeCm + 3.0, 1e-9));
    });

    test('null rule disables shift entirely', () {
      final map = calculateCoordinateMap(
        _profile(medalRowCount: 5),
        _armyConfig,
        null,
      );
      expect(
        map.anchors['chestBadge']!.y * 100.0,
        closeTo(_baseChestBadgeCm, 1e-9),
      );
    });
  });
}

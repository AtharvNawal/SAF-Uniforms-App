import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/profile/data/dtos/uniform_profile_dto.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';
import 'package:saf_uniforms/features/profile/domain/entities/rank.dart';
import 'package:saf_uniforms/features/profile/domain/entities/uniform_profile.dart';

void main() {
  test('round-trip preserves fullName, vocation, medalRowCount, selectedBadgeIds',
      () {
    const original = UniformProfile(
      branch: BranchId.navy,
      rank: Rank.cpt,
      gender: Gender.female,
      dressCode: DressCode.no3,
      isSikh: false,
      fullName: 'CPT Lim',
      vocation: 'Signals',
      medalRowCount: 4,
      selectedBadgeIds: {'airborne', 'ippt'},
      selectedAccessoryIds: {'beret_standard'},
    );

    final json = UniformProfileDto.toFirestore(original);
    expect(json['fullName'], 'CPT Lim');
    expect(json['vocation'], 'Signals');
    expect(json['medalRowCount'], 4);
    expect(json['selectedBadgeIds'], unorderedEquals(['airborne', 'ippt']));

    final hydrated = UniformProfileDto.fromFirestore(json);
    expect(hydrated, original);
  });

  test('fromFirestore defaults missing new fields for legacy docs', () {
    final hydrated = UniformProfileDto.fromFirestore(<String, Object?>{
      'branch': 'army',
      'rank': 'REC',
      'gender': 'male',
      'dressCode': 'No3',
      'isSikh': false,
      'selectedAccessoryIds': <String>[],
      // intentionally missing: fullName, vocation, medalRowCount,
      // selectedBadgeIds, dressAccessoryChecks.
    });
    expect(hydrated.fullName, '');
    expect(hydrated.vocation, 'Infantry');
    expect(hydrated.medalRowCount, 0);
    expect(hydrated.selectedBadgeIds, isEmpty);
    expect(hydrated.dressAccessoryChecks, isEmpty);
  });

  group('dressAccessoryChecks round-trip', () {
    test('empty map round-trips losslessly', () {
      const original = UniformProfile(
        branch: BranchId.army,
        rank: Rank.rec,
        gender: Gender.male,
        dressCode: DressCode.no3,
      );
      final json = UniformProfileDto.toFirestore(original);
      expect(json['dressAccessoryChecks'], isEmpty);
      final hydrated = UniformProfileDto.fromFirestore(json);
      expect(hydrated.dressAccessoryChecks, isEmpty);
    });

    test('per-dress check sets round-trip', () {
      const original = UniformProfile(
        branch: BranchId.army,
        rank: Rank.rec,
        gender: Gender.male,
        dressCode: DressCode.no3,
        dressAccessoryChecks: {
          'no_3_dress_requirements': {'army_beret', 'army_cap_badge'},
          'no_5_dress_requirements': {'field_cap'},
        },
      );
      final json = UniformProfileDto.toFirestore(original);
      final raw = json['dressAccessoryChecks'] as Map;
      expect(raw['no_3_dress_requirements'], isA<List>());
      expect(
        (raw['no_3_dress_requirements'] as List).toSet(),
        {'army_beret', 'army_cap_badge'},
      );
      final hydrated = UniformProfileDto.fromFirestore(json);
      expect(hydrated.dressAccessoryChecks, {
        'no_3_dress_requirements': {'army_beret', 'army_cap_badge'},
        'no_5_dress_requirements': {'field_cap'},
      });
    });

    test('hydrates defensively from non-string list entries', () {
      final hydrated = UniformProfileDto.fromFirestore(<String, Object?>{
        'branch': 'army',
        'rank': 'REC',
        'gender': 'male',
        'dressCode': 'No3',
        'isSikh': false,
        'selectedAccessoryIds': <String>[],
        'dressAccessoryChecks': <String, Object?>{
          'no_3_dress_requirements': <Object?>['ok', 42, null, 'also_ok'],
          // garbage value type: skipped silently
          'no_5_dress_requirements': 'not_a_list',
        },
      });
      expect(hydrated.dressAccessoryChecks, {
        'no_3_dress_requirements': {'ok', 'also_ok'},
      });
    });
  });
}

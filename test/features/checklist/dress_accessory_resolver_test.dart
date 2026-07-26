import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/checklist/domain/entities/dress_requirement.dart';
import 'package:saf_uniforms/features/checklist/domain/services/dress_accessory_resolver.dart';
import 'package:saf_uniforms/features/profile/domain/entities/accessory.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';
import 'package:saf_uniforms/features/profile/domain/entities/rank.dart';
import 'package:saf_uniforms/features/profile/domain/entities/uniform_profile.dart';

Accessory _accessory(String id, {String? gender}) =>
    Accessory(id: id, displayName: id, gender: gender);

Accessory _legacy(String id) => Accessory(
      id: id,
      displayName: id,
      renderLogic: const {'legacy_placeholder': true},
    );

UniformProfile _profile({
  BranchId branch = BranchId.army,
  Rank rank = Rank.rec,
  Gender gender = Gender.male,
  bool isSikh = false,
}) =>
    UniformProfile(
      branch: branch,
      rank: rank,
      gender: gender,
      dressCode: DressCode.no3,
      isSikh: isSikh,
    );

DressRequirement _no3({
  required Map<String, Map<String, dynamic>> branchOverrides,
}) =>
    DressRequirement(
      id: 'no_3_dress_requirements',
      dressName: 'No. 3 Dress',
      branchOverrides: branchOverrides,
    );

void main() {
  const resolver = DressAccessoryResolver();

  group('DressAccessoryResolver — Army No.3', () {
    final library = [
      _accessory('army_beret'),
      _accessory('army_sikh_turban_standard'),
      _accessory('army_sikh_turban_col_me7_above'),
      _accessory('army_cap_badge_sltc_me6_below'),
      _accessory('army_cap_badge_col_me7'),
      _accessory('army_cap_badge_bg_me8_above'),
      _accessory('army_specialist_insignia'),
      _accessory('army_enlistee_insignia'),
      _accessory('army_lanyard_sa_ma'),
      _accessory('army_arms_badge'),
    ];

    final armyOverride = <String, Map<String, dynamic>>{
      'army': <String, dynamic>{
        'headdress': <String, dynamic>{
          'men': <String, dynamic>{
            'default': 'army_beret',
            'sikh': 'army_sikh_turban_standard',
            'sikh_col_me7_above': 'army_sikh_turban_col_me7_above',
          },
        },
        'cap_badge': <String, dynamic>{
          'sltc_me6_below': 'army_cap_badge_sltc_me6_below',
          'col_me7': 'army_cap_badge_col_me7',
          'bg_me8_above': 'army_cap_badge_bg_me8_above',
        },
        'rank_insignia_sleeve': <String, dynamic>{
          'specialist': 'army_specialist_insignia',
          'enlistee': 'army_enlistee_insignia',
        },
        'lanyard': 'army_lanyard_sa_ma',
        'arms_badge': 'army_arms_badge',
      },
    };

    test('REC enlistee man → beret + enlistee insignia + lanyard + arms', () {
      final ids = resolver
          .resolve(
            requirement: _no3(branchOverrides: armyOverride),
            profile: _profile(rank: Rank.rec),
            library: library,
          )
          .map((a) => a.id)
          .toSet();
      expect(ids, contains('army_beret'));
      expect(ids, contains('army_cap_badge_sltc_me6_below'));
      expect(ids, contains('army_enlistee_insignia'));
      expect(ids, contains('army_lanyard_sa_ma'));
      expect(ids, contains('army_arms_badge'));
      expect(ids, isNot(contains('army_specialist_insignia')));
      expect(ids, isNot(contains('army_sikh_turban_standard')));
    });

    test('Sikh COL → sikh_col_me7_above turban + col_me7 cap badge', () {
      final ids = resolver
          .resolve(
            requirement: _no3(branchOverrides: armyOverride),
            profile: _profile(rank: Rank.col, isSikh: true),
            library: library,
          )
          .map((a) => a.id)
          .toSet();
      expect(ids, contains('army_sikh_turban_col_me7_above'));
      expect(ids, contains('army_cap_badge_col_me7'));
      expect(ids, isNot(contains('army_beret')));
      expect(ids, isNot(contains('army_cap_badge_sltc_me6_below')));
    });

    test('BG → bg_me8_above cap badge', () {
      final ids = resolver
          .resolve(
            requirement: _no3(branchOverrides: armyOverride),
            profile: _profile(rank: Rank.bg),
            library: library,
          )
          .map((a) => a.id)
          .toSet();
      expect(ids, contains('army_cap_badge_bg_me8_above'));
      expect(ids, isNot(contains('army_cap_badge_col_me7')));
    });

    test('Specialist (3SG) → specialist insignia, not enlistee', () {
      final ids = resolver
          .resolve(
            requirement: _no3(branchOverrides: armyOverride),
            profile: _profile(rank: Rank.threeSg),
            library: library,
          )
          .map((a) => a.id)
          .toSet();
      expect(ids, contains('army_specialist_insignia'));
      expect(ids, isNot(contains('army_enlistee_insignia')));
    });
  });

  test('legacy placeholders are filtered out', () {
    final library = [
      _accessory('keep_me'),
      _legacy('drop_me'),
    ];
    final ids = resolver
        .resolve(
          requirement: _no3(branchOverrides: <String, Map<String, dynamic>>{
            'army': <String, dynamic>{
              'lanyard': 'keep_me',
              'arms_badge': 'drop_me',
            },
          }),
          profile: _profile(),
          library: library,
        )
        .map((a) => a.id)
        .toSet();
    expect(ids, contains('keep_me'));
    expect(ids, isNot(contains('drop_me')));
  });

  test('gender-typed accessories are filtered against profile gender', () {
    final library = [
      _accessory('female_only', gender: 'female'),
      _accessory('male_only', gender: 'male'),
      _accessory('unisex', gender: 'unisex'),
    ];
    final female = resolver
        .resolve(
          requirement: _no3(branchOverrides: <String, Map<String, dynamic>>{
            'army': <String, dynamic>{
              'lanyard': 'female_only',
              'arms_badge': 'male_only',
              'vocation_badge': 'unisex',
            },
          }),
          profile: _profile(gender: Gender.female),
          library: library,
        )
        .map((a) => a.id)
        .toSet();
    expect(female, containsAll(['female_only', 'unisex']));
    expect(female, isNot(contains('male_only')));
  });

  test('returns empty list when the profile branch has no override', () {
    final result = resolver.resolve(
      requirement: _no3(branchOverrides: const {}),
      profile: _profile(),
      library: [_accessory('anything')],
    );
    expect(result, isEmpty);
  });

  group('resolveSplit', () {
    test('classifies headdress / cap_badge / sleeve / epaulettes as mandatory '
        'and lanyard / arms_badge / vocation_badge as optional', () {
      final library = [
        _accessory('army_beret'),
        _accessory('army_cap_badge'),
        _accessory('army_specialist_insignia'),
        _accessory('army_lanyard_sa_ma'),
        _accessory('army_arms_badge'),
        _accessory('army_vocation_signals'),
      ];
      final override = <String, Map<String, dynamic>>{
        'army': <String, dynamic>{
          'headdress': <String, dynamic>{
            'men': <String, dynamic>{'default': 'army_beret'},
          },
          'cap_badge': 'army_cap_badge',
          'rank_insignia_sleeve': <String, dynamic>{
            'specialist': 'army_specialist_insignia',
          },
          'lanyard': 'army_lanyard_sa_ma',
          'arms_badge': 'army_arms_badge',
          'vocation_badge': 'army_vocation_signals',
        },
      };
      final split = resolver.resolveSplit(
        requirement: _no3(branchOverrides: override),
        profile: _profile(rank: Rank.threeSg),
        library: library,
      );
      final mandatoryIds = split.mandatory.map((a) => a.id).toSet();
      final optionalIds = split.optional.map((a) => a.id).toSet();
      expect(
        mandatoryIds,
        containsAll(<String>{
          'army_beret',
          'army_cap_badge',
          'army_specialist_insignia',
        }),
      );
      expect(mandatoryIds, isNot(contains('army_lanyard_sa_ma')));
      expect(mandatoryIds, isNot(contains('army_arms_badge')));
      expect(mandatoryIds, isNot(contains('army_vocation_signals')));
      expect(
        optionalIds,
        containsAll(<String>{
          'army_lanyard_sa_ma',
          'army_arms_badge',
          'army_vocation_signals',
        }),
      );
    });

    test('legacy placeholders are filtered from both mandatory and optional', () {
      final library = [
        _legacy('headdress_legacy'),
        _legacy('lanyard_legacy'),
      ];
      final split = resolver.resolveSplit(
        requirement: _no3(branchOverrides: <String, Map<String, dynamic>>{
          'army': <String, dynamic>{
            'headdress': <String, dynamic>{
              'men': <String, dynamic>{'default': 'headdress_legacy'},
            },
            'lanyard': 'lanyard_legacy',
          },
        }),
        profile: _profile(),
        library: library,
      );
      expect(split.mandatory, isEmpty);
      expect(split.optional, isEmpty);
    });

    test('resolve() concatenates resolveSplit() output (mandatory then optional)',
        () {
      final library = [
        _accessory('h_beret'),
        _accessory('lanyard_x'),
      ];
      final override = <String, Map<String, dynamic>>{
        'army': <String, dynamic>{
          'headdress': <String, dynamic>{
            'men': <String, dynamic>{'default': 'h_beret'},
          },
          'lanyard': 'lanyard_x',
        },
      };
      final flat = resolver
          .resolve(
            requirement: _no3(branchOverrides: override),
            profile: _profile(),
            library: library,
          )
          .map((a) => a.id)
          .toList();
      final split = resolver.resolveSplit(
        requirement: _no3(branchOverrides: override),
        profile: _profile(),
        library: library,
      );
      expect(
        flat,
        [
          ...split.mandatory.map((a) => a.id),
          ...split.optional.map((a) => a.id),
        ],
      );
    });
  });
}

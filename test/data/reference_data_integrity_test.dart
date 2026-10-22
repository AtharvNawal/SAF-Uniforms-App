import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_engine/data/dtos/accessory_firestore.dart';
import 'package:saf_uniforms/features/checklist/data/dtos/dress_requirement_firestore.dart';
import 'package:saf_uniforms/features/checklist/domain/entities/dress_requirement.dart';
import 'package:saf_uniforms/features/checklist/domain/services/dress_accessory_resolver.dart';
import 'package:saf_uniforms/features/profile/domain/entities/accessory.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';
import 'package:saf_uniforms/features/profile/domain/entities/rank.dart';
import 'package:saf_uniforms/features/profile/domain/entities/uniform_profile.dart';

/// Runs the resolver over the real seed snapshot in `assets/data/` — the
/// same JSON `tool/seed_firestore.dart` pushes to Firestore — so a typo'd
/// accessory id or a doctrine regression fails here, not on a device.

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

final List<Accessory> _library = [
  for (final raw in (_readJson('assets/data/accessory_library.v1.json')
      ['accessories'] as List))
    AccessoryFirestore.fromFirestore(
      docId: (raw as Map<String, dynamic>)['id'] as String,
      data: raw,
    ),
];

final Map<String, DressRequirement> _requirements = {
  for (final raw in (_readJson('assets/data/dress_requirements.v1.json')
      ['dressRequirements'] as List))
    (raw as Map<String, dynamic>)['id'] as String:
        DressRequirementFirestore.fromFirestore(
      docId: raw['id'] as String,
      data: raw,
    ),
};

/// Override keys whose values are (or contain) accessory ids.
const _idKeys = {
  'headdress',
  'cap_badge',
  'cap_embellishment',
  'rank_insignia_sleeve',
  'rank_epaulette',
  'epaulettes',
  'ladies_rank',
  'name_tag',
  'name_tag_protocol',
  'lanyard',
  'arms_badge',
  'vocation_badge',
  'belt',
  'socks',
  'footwear',
  'additional_mandatory',
  'additional_optional',
};

Iterable<String> _ids(Object? v) sync* {
  if (v is String) {
    yield v;
  } else if (v is List) {
    for (final x in v) {
      yield* _ids(x);
    }
  } else if (v is Map) {
    for (final x in v.values) {
      yield* _ids(x);
    }
  }
}

Set<String> _resolve(
  DressCode dress, {
  required BranchId branch,
  Rank rank = Rank.cpl,
  Gender gender = Gender.male,
  bool isSikh = false,
  bool mandatoryOnly = false,
}) {
  final split = const DressAccessoryResolver().resolveSplit(
    requirement: _requirements[dress.requirementDocId]!,
    profile: UniformProfile(
      branch: branch,
      rank: rank,
      gender: gender,
      dressCode: dress,
      isSikh: isSikh,
    ),
    library: _library,
  );
  return {
    ...split.mandatory.map((a) => a.id),
    if (!mandatoryOnly) ...split.optional.map((a) => a.id),
  };
}

void main() {
  test('every accessory id referenced by a dress requirement exists', () {
    final libraryIds = _library.map((a) => a.id).toSet();
    final missing = <String>[];
    for (final req in _requirements.values) {
      req.branchOverrides.forEach((branch, override) {
        for (final key in _idKeys) {
          for (final id in _ids(override[key])) {
            if (!libraryIds.contains(id)) missing.add('${req.id}/$branch/$key: $id');
          }
        }
      });
    }
    expect(missing, isEmpty);
  });

  test('accessory ids are unique', () {
    final ids = _library.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  group('No.4 — doctrine-aligned for every branch', () {
    for (final branch in BranchId.values) {
      test('${branch.wireName}: beret, cap badge, chest rank tab, tags, belt, '
          'socks, boots', () {
        final m = _resolve(DressCode.no4, branch: branch, mandatoryOnly: true);
        final byCategory = {
          for (final a in _library.where((a) => m.contains(a.id)))
            a.category: a.id,
        };
        expect(byCategory['headdress_beret'], '${branch.wireName}_beret');
        expect(byCategory['cap_badge'], isNotNull);
        expect(byCategory['rank_epaulette_chest'],
            '${branch.wireName}_no4_rank_epaulette');
        expect(m, containsAll(['name_tag_standard', 'singapore_tag']));
        expect(byCategory['belt'], isNotNull);
        expect(byCategory['socks'], isNotNull);
        // Exactly one footwear + one socks item is mandatory, so the 3D
        // model never stacks two boots / two socks on the same foot.
        expect(_library.where((a) => m.contains(a.id) && a.category == 'footwear'),
            hasLength(1));
        expect(_library.where((a) => m.contains(a.id) && a.category == 'socks'),
            hasLength(1));
        // No.4 wears no sleeve chevrons, collar pins or shoulder epaulettes.
        expect(byCategory.keys, isNot(contains('sleeve_rank_enlistee')));
        expect(byCategory.keys, isNot(contains('epaulette')));
      });

      test('${branch.wireName}: ladies also wear the beret', () {
        final m = _resolve(DressCode.no4,
            branch: branch, gender: Gender.female, mandatoryOnly: true);
        expect(m, contains('${branch.wireName}_beret'));
      });
    }

    test('Officer Cadet gets the cadet/trainee rank tab', () {
      final m = _resolve(DressCode.no4, branch: BranchId.army, rank: Rank.oct);
      expect(m, contains('army_no4_rank_epaulette_cadet_trainee'));
      expect(m, isNot(contains('army_no4_rank_epaulette')));
    });

    test('Army: olive belt, green or black socks, arms badge optional', () {
      final split = const DressAccessoryResolver().resolveSplit(
        requirement: _requirements['no_4_dress_requirements']!,
        profile: UniformProfile(
          branch: BranchId.army,
          rank: Rank.cpl,
          gender: Gender.male,
          dressCode: DressCode.no4,
        ),
        library: _library,
      );
      final mandatory = split.mandatory.map((a) => a.id).toSet();
      final optional = split.optional.map((a) => a.id).toSet();
      expect(mandatory, containsAll(['army_no4_belt', 'black_socks', 'combat_boots']));
      expect(optional, containsAll(
          ['green_socks', 'army_arms_badge', 'army_jockey_cap', 'army_jungle_hat']));
      expect(optional, isNot(contains('sikh_field_turban_green')));
    });

    test('Army Sikh COL: turban with col_me7 badge, field turban optional', () {
      final ids = _resolve(DressCode.no4,
          branch: BranchId.army, rank: Rank.col, isSikh: true);
      expect(ids, contains('army_sikh_turban_col_me7_above'));
      expect(ids, contains('army_cap_badge_col_me7'));
      expect(ids, contains('sikh_field_turban_green'));
      expect(ids, isNot(contains('army_beret')));
    });

    test('BG gets the BG+ cap badge in every branch that has one', () {
      expect(_resolve(DressCode.no4, branch: BranchId.rsaf, rank: Rank.bg),
          contains('rsaf_cap_badge_bg_me8_above_beret'));
      expect(_resolve(DressCode.no4, branch: BranchId.dis, rank: Rank.bg),
          contains('dis_cap_badge_bg_me8_radm_above'));
      expect(_resolve(DressCode.no4, branch: BranchId.navy, rank: Rank.bg),
          contains('navy_cap_badge_col_me7_above'));
    });

    test('Navy / RSAF / DIS: black belt + inner shirt; DIS service patch', () {
      expect(_resolve(DressCode.no4, branch: BranchId.navy, mandatoryOnly: true),
          containsAll(['no4_belt_black', 'navy_no4_inner_shirt_grey']));
      expect(_resolve(DressCode.no4, branch: BranchId.rsaf, mandatoryOnly: true),
          containsAll(['no4_belt_black', 'rsaf_no4_inner_tshirt',
              'rsaf_unit_patch']));
      expect(_resolve(DressCode.no4, branch: BranchId.dis, mandatoryOnly: true),
          containsAll(['no4_belt_black', 'dis_no4_inner_tshirt',
              'dis_service_patch']));
    });

    test('combat boots compulsory, safety boots optional (all services)', () {
      for (final b in BranchId.values) {
        final mandatory = _resolve(DressCode.no4, branch: b, mandatoryOnly: true);
        expect(mandatory, contains('combat_boots'), reason: b.wireName);
        expect(mandatory, isNot(contains('safety_boots')), reason: b.wireName);
        expect(mandatory, isNot(contains('safety_boots_mid_cut')),
            reason: b.wireName);
      }
      expect(_resolve(DressCode.no4, branch: BranchId.navy),
          containsAll(['safety_boots_mid_cut', 'safety_shoes_low_cut']));
      expect(_resolve(DressCode.no4, branch: BranchId.rsaf),
          contains('safety_boots'));
      expect(_resolve(DressCode.no4, branch: BranchId.dis),
          contains('safety_boots'));
    });
  });

  group('No.3 regression', () {
    test('DIS headdress (unisex beret) now resolves', () {
      expect(_resolve(DressCode.no3, branch: BranchId.dis), contains('dis_beret'));
      expect(_resolve(DressCode.no3, branch: BranchId.dis, isSikh: true),
          contains('dis_sikh_turban'));
    });

    test('Army No.3 man still gets beret + sleeve insignia, no No.4 items', () {
      final ids = _resolve(DressCode.no3, branch: BranchId.army);
      expect(ids, containsAll(['army_beret', 'army_enlistee_insignia', 'nylon_belt']));
      expect(ids, isNot(contains('singapore_tag')));
      expect(ids, isNot(contains('combat_boots')));
    });

    test('Army No.3 lady still gets the ladies service hat, not the beret', () {
      final ids = _resolve(DressCode.no3,
          branch: BranchId.army, gender: Gender.female);
      expect(ids, contains('army_ladies_hat_specialist_enlistee_me1_me2'));
      expect(ids, isNot(contains('army_beret')));
    });
  });
}

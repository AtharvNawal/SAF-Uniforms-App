import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_engine/data/dtos/accessory_firestore.dart';
import 'package:saf_uniforms/features/checklist/data/dtos/dress_requirement_firestore.dart';
import 'package:saf_uniforms/features/checklist/domain/entities/dress_requirement.dart';
import 'package:saf_uniforms/features/checklist/domain/services/accessory_presentation.dart';
import 'package:saf_uniforms/features/checklist/domain/services/dress_accessory_resolver.dart';
import 'package:saf_uniforms/features/profile/domain/entities/accessory.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/domain/entities/dress_code.dart';
import 'package:saf_uniforms/features/profile/domain/entities/gender.dart';
import 'package:saf_uniforms/features/profile/domain/entities/rank.dart';
import 'package:saf_uniforms/features/profile/domain/entities/uniform_profile.dart';

/// Every No.3 / No.4 combination (service × men / ladies / maternity ×
/// Sikh × rank) against the real seed data: the dress is complete and
/// every item has a picture. See
/// ChangeRequest/2026-10-19_no3-no4-full-coverage.md.
late final List<Accessory> _library;
late final Map<String, DressRequirement> _dresses;

AccessorySplit _split(UniformProfile p) =>
    const DressAccessoryResolver().resolveSplit(
      requirement: _dresses[p.dressCode.requirementDocId]!.mergedFor(p.branch),
      profile: p,
      library: _library,
    );

Set<String> _mandatoryIds(UniformProfile p) =>
    {for (final a in _split(p).mandatory) a.id};

Iterable<UniformProfile> _everyProfile() sync* {
  for (final dress in [DressCode.no3, DressCode.no4]) {
    for (final branch in BranchId.values) {
      for (final gender in Gender.values) {
        for (final sikh in [false, true]) {
          if (sikh && gender != Gender.male) continue;
          for (final rank in Rank.values) {
            yield UniformProfile(
              dressCode: dress,
              branch: branch,
              gender: gender,
              isSikh: sikh,
              rank: rank,
            );
          }
        }
      }
    }
  }
}

void main() {
  setUpAll(() {
    final lib = jsonDecode(
      File('assets/data/accessory_library.v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    _library = [
      for (final a in (lib['accessories'] as List).cast<Map<String, dynamic>>())
        AccessoryFirestore.fromFirestore(docId: a['id'] as String, data: a),
    ];
    final dr = jsonDecode(
      File('assets/data/dress_requirements.v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    _dresses = {
      for (final d
          in (dr['dressRequirements'] as List).cast<Map<String, dynamic>>())
        d['id'] as String: DressRequirementFirestore.fromFirestore(
          docId: d['id'] as String,
          data: d,
        ),
    };
  });

  test('every combination is complete and every item has a picture', () {
    const core = [
      'headdress',
      'cap_badge',
      'name_tag',
      'belt',
      'footwear',
      'socks',
    ];
    const rankCategories = [
      'sleeve_rank',
      'epaulette',
      'collar_rank_pin',
      'gorgette',
      'rank_epaulette_chest',
    ];
    final problems = <String>[];
    for (final p in _everyProfile()) {
      final split = _split(p);
      final cats = {for (final a in split.mandatory) a.category ?? ''};
      final label = '${p.dressCode.wireName} ${p.branch.wireName} '
          '${p.gender.wireName}${p.isSikh ? ' sikh' : ''} ${p.rank.code}';
      for (final c in core) {
        if (!cats.any((x) => x.startsWith(c))) problems.add('$label: no $c');
      }
      if (!cats.any((x) => rankCategories.any(x.startsWith))) {
        problems.add('$label: no rank item');
      }
      for (final a in [...split.mandatory, ...split.optional]) {
        final img = accessoryImagesFor(a, dress: p.dressCode, branch: p.branch);
        if (img.imageUrl.isEmpty && img.placementDiagramUrl.isEmpty) {
          problems.add('$label: ${a.id} has no picture');
        }
      }
    }
    expect(problems, isEmpty);
  });

  group('No.3 doctrine', () {
    test('maternity wears the ladies items', () {
      final ids = _mandatoryIds(const UniformProfile(
        branch: BranchId.army,
        gender: Gender.maternity,
        rank: Rank.cpl,
      ));
      expect(ids, containsAll(['leather_belt', 'court_shoes']));
      expect(ids, contains('army_ladies_hat_specialist_enlistee_me1_me2'));
      expect(ids, isNot(contains('army_beret')));
      expect(ids, isNot(contains('nylon_belt')));
    });

    test('Navy / RSAF lady specialists get their hat', () {
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.navy,
          gender: Gender.female,
          rank: Rank.threeSg,
        )),
        contains('navy_ladies_hat_specialist_rating_cadet_me_trainee'),
      );
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.rsaf,
          gender: Gender.female,
          rank: Rank.cpl,
        )),
        contains('rsaf_ladies_hat_specialist_me1_me2_cadet_me_trainee'),
      );
    });

    test('men wear epaulettes; lady officers collar pins; lady OCT gorgette',
        () {
      final manCpt = _mandatoryIds(const UniformProfile(rank: Rank.cpt));
      expect(manCpt, contains('epaulettes_standard'));
      expect(manCpt, isNot(contains('collar_rank_pins')));

      final manOct = _mandatoryIds(const UniformProfile(rank: Rank.oct));
      expect(manOct, contains('epaulettes_officer_cadet_me_trainee'));

      final ladyCpt = _mandatoryIds(
        const UniformProfile(gender: Gender.female, rank: Rank.cpt),
      );
      expect(ladyCpt, contains('collar_rank_pins'));
      expect(ladyCpt, isNot(contains('epaulettes_standard')));

      final ladyOct = _mandatoryIds(
        const UniformProfile(gender: Gender.female, rank: Rank.oct),
      );
      expect(ladyOct, contains('gorgette_lady_officer_cadet'));

      // DIS ladies: collar pins, not the DIS epaulettes.
      final disLady = _mandatoryIds(const UniformProfile(
        branch: BranchId.dis,
        gender: Gender.female,
        rank: Rank.oneWo,
      ));
      expect(disLady, contains('collar_rank_pins'));
      expect(disLady, isNot(contains('dis_epaulettes_standard')));
    });

    test('Navy Sikh 3WO and above wear the white turban', () {
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.navy,
          isSikh: true,
          rank: Rank.threeWo,
        )),
        contains('navy_sikh_turban_3wo_me3_above'),
      );
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.navy,
          isSikh: true,
          rank: Rank.cpl,
        )),
        contains('navy_sikh_turban_standard'),
      );
    });

    test('cap embellishment is on the ladies hat only, by rank tier', () {
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.navy,
          gender: Gender.female,
          rank: Rank.maj,
        )),
        contains('navy_cap_embellishment_maj_to_sltc_swo_to_cwo_me5_to_me6'),
      );
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.navy,
          rank: Rank.maj,
        )).where((id) => id.contains('embellishment')),
        isEmpty,
      );
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.rsaf,
          gender: Gender.female,
          rank: Rank.cpt,
        )).where((id) => id.contains('embellishment')),
        isEmpty,
      );
    });

    test('BG cap badges: DIS, RSAF beret vs service hat', () {
      expect(
        _mandatoryIds(const UniformProfile(branch: BranchId.dis, rank: Rank.bg)),
        contains('dis_cap_badge_bg_me8_radm_above'),
      );
      expect(
        _mandatoryIds(const UniformProfile(branch: BranchId.rsaf, rank: Rank.bg)),
        contains('rsaf_cap_badge_bg_me8_above_beret'),
      );
      expect(
        _mandatoryIds(const UniformProfile(
          branch: BranchId.rsaf,
          gender: Gender.female,
          rank: Rank.bg,
        )),
        containsAll([
          'rsaf_cap_badge_bg_me8_above_service_hat',
          'rsaf_ladies_hat_bg_me8_above',
        ]),
      );
    });

    test('badges and medal ribbons are optional No.3 items', () {
      final optional = {
        for (final a in _split(const UniformProfile()).optional) a.id,
      };
      expect(
        optional,
        containsAll([
          'medal_ribbons',
          'saf_badges_chest',
          'skill_tabs_sleeve',
          'skill_badges_sleeve',
          'foreign_badges',
        ]),
      );
    });
  });
}

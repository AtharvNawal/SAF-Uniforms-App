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
import 'package:saf_uniforms/features/wearing_guide/domain/wearing_steps.dart';

/// Runs against the real seed snapshot (`assets/data/*.v1.json`, the same
/// data `tool/seed_firestore.dart` pushes to Firestore), so a doctrine data
/// change that leaks No.3 items into No.4 fails here.
late final List<Accessory> _library;
late final Map<String, DressRequirement> _dresses;

/// Categories that exist only in No.3 dress.
const _no3OnlyCategories = {
  'sleeve_rank_specialist',
  'sleeve_rank_enlistee',
  'epaulette',
  'gorgette',
  'collar_rank_pin',
  'lanyard',
  'medal_ribbons',
};

List<WearingStep> _steps(UniformProfile p) {
  final requirement = _dresses[p.dressCode.requirementDocId]!;
  final split = const DressAccessoryResolver().resolveSplit(
    requirement: requirement.mergedFor(p.branch),
    profile: p,
    library: _library,
  );
  return buildWearingSteps(dressCode: p.dressCode, split: split, profile: p);
}

Set<String> _ids(List<WearingStep> steps) => {for (final s in steps) s.id};

Set<String?> _categories(List<WearingStep> steps) => {
  for (final s in steps) s.accessory?.category,
};

void main() {
  setUpAll(() {
    final lib =
        jsonDecode(
              File('assets/data/accessory_library.v1.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    _library = [
      for (final a in (lib['accessories'] as List).cast<Map<String, dynamic>>())
        AccessoryFirestore.fromFirestore(docId: a['id'] as String, data: a),
    ];
    final dr =
        jsonDecode(
              File('assets/data/dress_requirements.v1.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    _dresses = {
      for (final d
          in (dr['dressRequirements'] as List).cast<Map<String, dynamic>>())
        d['id'] as String: DressRequirementFirestore.fromFirestore(
          docId: d['id'] as String,
          data: d,
        ),
    };
  });

  group('No.4 wearing guide shows only No.4 items', () {
    for (final branch in BranchId.values) {
      for (final gender in [Gender.male, Gender.female]) {
        test('${branch.wireName} ${gender.name}', () {
          final steps = _steps(
            UniformProfile(
              branch: branch,
              gender: gender,
              rank: Rank.cpl,
              dressCode: DressCode.no4,
              medalRowCount: 3,
            ),
          );
          final ids = _ids(steps);
          final categories = _categories(steps);

          expect(categories.intersection(_no3OnlyCategories), isEmpty);
          expect(ids, isNot(contains('medals')));
          expect(ids, isNot(contains('nylon_belt')));
          expect(ids, isNot(contains('leather_shoes_low_cut')));
          expect(ids, contains('${branch.wireName}_no4_rank_epaulette'));
          expect(ids, contains('singapore_tag'));
          expect(ids, contains('name_tag_standard'));
          expect(categories, contains('footwear'));
          expect(categories, contains('belt'));
          // Headdress alternatives (jockey cap, jungle hat…) are optional
          // and not ticked, so they don't appear.
          expect(
            categories.where(
              (c) =>
                  c != null &&
                  c != 'headdress_beret' &&
                  c.startsWith('headdress'),
            ),
            isEmpty,
          );
        });
      }
    }
  });

  test('No.3 Army REC keeps its No.3 items, incl. medals when worn', () {
    final steps = _steps(
      const UniformProfile(
        branch: BranchId.army,
        rank: Rank.rec,
        dressCode: DressCode.no3,
        medalRowCount: 2,
      ),
    );
    final ids = _ids(steps);
    expect(
      ids,
      containsAll([
        'army_beret',
        'army_enlistee_insignia',
        'nylon_belt',
        'medals',
      ]),
    );
    expect(ids, isNot(contains('singapore_tag')));
    expect(_categories(steps), isNot(contains('rank_epaulette_chest')));
  });

  test('No.3 with no medal rows has no medals step', () {
    final steps = _steps(const UniformProfile(dressCode: DressCode.no3));
    expect(_ids(steps), isNot(contains('medals')));
  });

  test('optional items appear only when ticked for that dress', () {
    const base = UniformProfile(
      branch: BranchId.army,
      dressCode: DressCode.no4,
    );
    expect(_ids(_steps(base)), isNot(contains('army_jockey_cap')));

    final ticked = base.copyWith(
      dressAccessoryChecks: {
        'no_4_dress_requirements': {'army_jockey_cap'},
      },
    );
    expect(_ids(_steps(ticked)), contains('army_jockey_cap'));

    // A tick on No.3 doesn't leak into No.4.
    final otherDress = base.copyWith(
      dressAccessoryChecks: {
        'no_3_dress_requirements': {'army_jockey_cap'},
      },
    );
    expect(_ids(_steps(otherDress)), isNot(contains('army_jockey_cap')));
  });

  test('order: garments first, headdress + cap badge last', () {
    final steps = _steps(
      const UniformProfile(branch: BranchId.rsaf, dressCode: DressCode.no4),
    );
    final ids = steps.map((s) => s.id).toList();
    expect(ids.indexOf('trousers'), lessThan(ids.indexOf('shirt')));
    expect(
      ids.indexOf('shirt'),
      lessThan(ids.indexOf('rsaf_no4_rank_epaulette')),
    );
    expect(steps.last.zone, WearingZone.head);
    expect(
      ids.indexOf('rsaf_beret'),
      greaterThan(ids.indexOf('singapore_tag')),
    );
  });

  test('No.5 (doctrine pending) lists garments + base items only', () {
    final steps = _steps(const UniformProfile(dressCode: DressCode.no5));
    expect(
      _categories(steps).whereType<String>().toSet(),
      everyElement(isIn(['belt', 'socks', 'footwear'])),
    );
    expect(_ids(steps), containsAll(['trousers', 'shirt']));
  });

  group('badge steps', () {
    test('No.4 splits chest and sleeve badges', () {
      final steps = _steps(
        const UniformProfile(
          branch: BranchId.army,
          dressCode: DressCode.no4,
          selectedBadgeIds: {'airborne', 'marksman'},
        ),
      );
      final byId = {for (final s in steps) s.id: s};
      expect(byId['chest_badges']?.zone, WearingZone.leftChest);
      expect(byId['sleeve_badges']?.zone, WearingZone.sleeves);
      final ids = steps.map((s) => s.id).toList();
      expect(
        ids.indexOf('chest_badges'),
        greaterThan(ids.indexOf('singapore_tag')),
      );
    });

    test('No.4 with only sleeve badges has no chest step', () {
      final ids = _ids(
        _steps(
          const UniformProfile(
            dressCode: DressCode.no4,
            selectedBadgeIds: {'fitness'},
          ),
        ),
      );
      expect(ids, contains('sleeve_badges'));
      expect(ids, isNot(contains('chest_badges')));
    });

    test('No.3 keeps a single SAF badges step', () {
      final ids = _ids(
        _steps(
          const UniformProfile(
            dressCode: DressCode.no3,
            selectedBadgeIds: {'airborne', 'marksman'},
          ),
        ),
      );
      expect(ids, contains('chest_badges'));
      expect(ids, isNot(contains('sleeve_badges')));
    });

    test('no badges selected → no badge steps', () {
      final ids = _ids(_steps(const UniformProfile(dressCode: DressCode.no4)));
      expect(ids, isNot(contains('chest_badges')));
      expect(ids, isNot(contains('sleeve_badges')));
    });
  });

  test('ticked medal / badge items do not repeat the medal / badge steps', () {
    final steps = _steps(const UniformProfile(
      dressCode: DressCode.no3,
      medalRowCount: 2,
      selectedBadgeIds: {'airborne'},
      dressAccessoryChecks: {
        'no_3_dress_requirements': {'medal_ribbons', 'saf_badges_chest'},
      },
    ));
    final ids = steps.map((s) => s.id).toList();
    expect(ids.where((i) => i == 'medals'), hasLength(1));
    expect(ids, isNot(contains('medal_ribbons')));
    expect(ids, isNot(contains('saf_badges_chest')));
    expect(ids, contains('chest_badges'));
  });
}

import 'dart:developer';

import '../../checklist/domain/services/accessory_presentation.dart';
import '../../checklist/domain/services/dress_accessory_resolver.dart';
import '../../profile/domain/entities/accessory.dart';
import '../../profile/domain/entities/dress_code.dart';
import '../../profile/domain/entities/uniform_profile.dart';

/// Body region a wearing step applies to. Drives the silhouette highlight
/// and the step's sub-label. Front view: the wearer's right is drawn on
/// the viewer's left.
enum WearingZone {
  head,
  collar,
  shoulder,
  chestCentre,
  rightChest,
  leftChest,
  sleeves,
  torso,
  waist,
  legs,
  feet,
}

enum WearingStepKind {
  trousers,
  shirt,
  medals,

  /// SAF chest badges (airborne, dive, pilot…). On No.3 this one step
  /// covers every selected badge.
  chestBadges,

  /// Marksmanship / sniper / IPPT badges on the left sleeve (No.4 only).
  sleeveBadges,
  accessory,
}

/// Profile badge ids worn on the left sleeve in No.4 (SAF No.4 Dress PDF,
/// Army Pictures C-4..C-7). The rest are chest badges.
const Set<String> kSleeveBadgeIds = {'marksman', 'sniper', 'fitness'};

/// One step of the Wearing Guide. [accessory] is set for
/// [WearingStepKind.accessory]; [tip] is the doctrine sentence for that
/// accessory (null for the base-garment / medal steps, whose text is
/// localised in the presentation layer).
class WearingStep {
  const WearingStep({
    required this.id,
    required this.kind,
    required this.zone,
    this.accessory,
    this.tip,
  });

  final String id;
  final WearingStepKind kind;
  final WearingZone zone;
  final Accessory? accessory;
  final String? tip;
}

/// Dressing order + zone per accessory category. Lower order is put on
/// first; the headdress and cap badge always finish the guide.
const Map<String, (int, WearingZone)> _categoryOrder = {
  'inner_shirt': (0, WearingZone.torso),
  'socks': (2, WearingZone.feet),
  'belt': (4, WearingZone.waist),
  'footwear': (5, WearingZone.feet),
  'rank_epaulette_chest': (10, WearingZone.chestCentre),
  'epaulette': (11, WearingZone.shoulder),
  'gorgette': (12, WearingZone.collar),
  'collar_rank_pin': (12, WearingZone.collar),
  'sleeve_rank_specialist': (13, WearingZone.sleeves),
  'sleeve_rank_enlistee': (13, WearingZone.sleeves),
  'sleeve_patch': (14, WearingZone.sleeves),
  'name_tag': (20, WearingZone.rightChest),
  'country_tag': (21, WearingZone.leftChest),
  'medal_ribbons': (22, WearingZone.leftChest),
  'saf_badge': (23, WearingZone.leftChest),
  'foreign_badge': (24, WearingZone.rightChest),
  'skill_tab': (25, WearingZone.sleeves),
  'skill_badge': (25, WearingZone.sleeves),
  'vocation_badge': (26, WearingZone.collar),
  'arms_badge': (27, WearingZone.collar),
  'lanyard': (30, WearingZone.shoulder),
  'cap_badge': (41, WearingZone.head),
  'cap_embellishment': (42, WearingZone.head),
};

const int _trousersOrder = 1;
const int _shirtOrder = 3;
const int _medalsOrder = 22;
const int _chestBadgesOrder = 23;
const int _sleeveBadgesOrder = 25;
const int _unknownOrder = 35;
const int _headdressOrder = 40;

(int, WearingZone) _orderFor(String? category) {
  final c = category ?? '';
  if (c.startsWith('headdress')) return (_headdressOrder, WearingZone.head);
  return _categoryOrder[c] ?? (_unknownOrder, WearingZone.torso);
}

/// Builds the ordered Wearing Guide for [dressCode] from the accessories
/// resolved for that dress ([split], same source as the Wardrobe tab).
///
/// - Mandatory accessories are always included.
/// - Optional accessories only when ticked in the Wardrobe for this dress
///   (`profile.dressAccessoryChecks[dressDocId]`), matching what
///   `composeUniformModel` renders.
/// - The medal-ribbons step is No.3-only and needs `medalRowCount > 0`.
List<WearingStep> buildWearingSteps({
  required DressCode dressCode,
  required AccessorySplit split,
  required UniformProfile profile,
}) {
  final checked =
      profile.dressAccessoryChecks[dressCode.requirementDocId] ??
      const <String>{};
  final optionalTicked = split.optional
      .where((a) => checked.contains(a.id))
      .toList();

  final entries = <(int, int, WearingStep)>[];
  var seq = 0;
  void add(int order, WearingStep step) => entries.add((order, seq++, step));

  add(
    _trousersOrder,
    const WearingStep(
      id: 'trousers',
      kind: WearingStepKind.trousers,
      zone: WearingZone.legs,
    ),
  );
  add(
    _shirtOrder,
    const WearingStep(
      id: 'shirt',
      kind: WearingStepKind.shirt,
      zone: WearingZone.torso,
    ),
  );
  if (dressCode == DressCode.no3 && profile.medalRowCount > 0) {
    add(
      _medalsOrder,
      const WearingStep(
        id: 'medals',
        kind: WearingStepKind.medals,
        zone: WearingZone.leftChest,
      ),
    );
  }

  final badges = profile.selectedBadgeIds;
  if (dressCode == DressCode.no3 && badges.isNotEmpty) {
    add(
      _chestBadgesOrder,
      const WearingStep(
        id: 'chest_badges',
        kind: WearingStepKind.chestBadges,
        zone: WearingZone.leftChest,
      ),
    );
  }
  if (dressCode == DressCode.no4) {
    if (badges.any((b) => !kSleeveBadgeIds.contains(b))) {
      add(
        _chestBadgesOrder,
        const WearingStep(
          id: 'chest_badges',
          kind: WearingStepKind.chestBadges,
          zone: WearingZone.leftChest,
        ),
      );
    }
    if (badges.any(kSleeveBadgeIds.contains)) {
      add(
        _sleeveBadgesOrder,
        const WearingStep(
          id: 'sleeve_badges',
          kind: WearingStepKind.sleeveBadges,
          zone: WearingZone.sleeves,
        ),
      );
    }
  }

  // The medal / SAF-badge / sleeve-badge library entries are also
  // optional Wardrobe items; when the profile already produced that step,
  // a ticked entry would just repeat it.
  final covered = {
    for (final e in entries)
      ...switch (e.$3.kind) {
        WearingStepKind.medals => const ['medal_ribbons'],
        WearingStepKind.chestBadges => const ['saf_badge'],
        WearingStepKind.sleeveBadges => const ['skill_badge'],
        _ => const <String>[],
      },
  };
  for (final a in [...split.mandatory, ...optionalTicked]) {
    if (covered.contains(a.category)) continue;
    final (order, zone) = _orderFor(a.category);
    add(
      order,
      WearingStep(
        id: a.id,
        kind: WearingStepKind.accessory,
        zone: zone,
        accessory: a,
        tip: accessoryDoctrineText(
          a,
          gender: profile.gender,
          dress: dressCode,
          branch: profile.branch,
        ),
      ),
    );
  }

  entries.sort((x, y) {
    final byOrder = x.$1.compareTo(y.$1);
    return byOrder != 0 ? byOrder : x.$2.compareTo(y.$2);
  });
  final steps = [for (final e in entries) e.$3];
  log(
    'buildWearingSteps: dress=${dressCode.wireName} '
    'mandatory=${split.mandatory.length} '
    'optionalTicked=${optionalTicked.length} steps=${steps.length}',
    name: 'wearing_guide.steps',
    level: 500,
  );
  return steps;
}

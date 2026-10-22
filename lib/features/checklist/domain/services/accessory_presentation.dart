import '../../../profile/domain/entities/accessory.dart';
import '../../../profile/domain/entities/branch_id.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/domain/entities/gender.dart';

/// Which pictures and doctrine sentence to show for an accessory, given
/// the dress (and service) it is being viewed for. Pure; shared by the
/// Wardrobe detail sheet and the Wearing Guide.

typedef AccessoryImages = ({String imageUrl, String placementDiagramUrl});

/// `dress_images` variant keys to try, most specific first:
/// `no4_rsaf`, then `no4`.
List<String> _variantKeys(DressCode? dress, BranchId? branch) {
  if (dress == null) return const [];
  final d = dress.wireName.toLowerCase();
  return [if (branch != null) '${d}_${branch.wireName}', d];
}

/// The accessory's pictures for [dress] / [branch]. Each slot falls back
/// independently (`no4_<branch>` → `no4` → the base No.3-era picture), so
/// a variant that only overrides the placement keeps the base photo.
AccessoryImages accessoryImagesFor(
  Accessory accessory, {
  DressCode? dress,
  BranchId? branch,
}) {
  String pick(String key, String base) {
    for (final v in _variantKeys(dress, branch)) {
      final url = accessory.dressImages[v]?[key];
      if (url != null && url.isNotEmpty) return url;
    }
    return base;
  }

  return (
    imageUrl: pick('image_url', accessory.imageUrl),
    placementDiagramUrl: pick(
      'placement_diagram',
      accessory.placementDiagramUrl,
    ),
  );
}

/// The most useful doctrine sentence from the accessory's free-form
/// `rules` map, or null when it has none:
/// 1. dress-specific placement (`no4_rsaf_placement`, `no4_placement`) —
///    these win over the gendered No.3 text (the No.3 ladies name-tag rule
///    talks about blouse buttons, wrong for No.4);
/// 2. the gendered rule (`men` / `ladies`);
/// 3. where it goes, then what it is.
String? accessoryDoctrineText(
  Accessory accessory, {
  required Gender gender,
  DressCode? dress,
  BranchId? branch,
}) {
  final rules = accessory.rules;
  final genderKey = gender == Gender.male ? 'men' : 'ladies';
  final dressKeys = [
    for (final v in _variantKeys(dress, branch)) '${v}_placement',
  ];
  final dressApplicability = dress == null
      ? null
      : '${dress.wireName.toLowerCase()}_applicability';
  final isHeaddress = (accessory.category ?? '').startsWith('headdress');
  final keys = <String?>[
    ...dressKeys,
    genderKey,
    if (isHeaddress) ...[
      dressApplicability,
      'applicability',
      'standard',
      'placement',
    ] else ...[
      'placement_text',
      'placement',
      'position',
      'alignment',
      'standard',
      dressApplicability,
      'applicability',
      'length',
      'allowance_cm',
      'format',
    ],
  ];
  for (final k in keys) {
    if (k == null) continue;
    final v = rules[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

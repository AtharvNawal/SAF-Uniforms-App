import '../../../profile/domain/entities/accessory.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../../profile/domain/entities/rank.dart';
import '../../../profile/domain/entities/uniform_profile.dart';
import '../entities/dress_requirement.dart';

/// Mandatory + optional accessory split for a single dress. Mandatory
/// items are required for the dress to be regulation; optional items are
/// conditional in doctrine (e.g. lanyards depend on regiment, vocation
/// badges depend on the user's vocation, arms badges only apply to combat
/// arms).
typedef AccessorySplit = ({
  List<Accessory> mandatory,
  List<Accessory> optional,
});

/// Resolves the accessories applicable to a given [UniformProfile] from a
/// branch-merged [DressRequirement] document.
///
/// The No. 3 dress doctrine (the only fully-aligned dress code today, see
/// `assets/data/dress_requirements.v1.json` `branch_overrides`) splits each
/// per-branch override into structured keys whose values are either
/// accessory ids (strings) or nested selectors keyed by gender / rank tier
/// / sikh status. This resolver walks the override, picks the right
/// accessory id for the profile, and returns the matching [Accessory]
/// objects from the supplied library.
///
/// Accessories whose `render_logic.legacy_placeholder == true` (the
/// No.1/2/4/5 generic placeholders flagged "pending doctrine review" in
/// CLAUDE.md §8) are skipped — callers that consume the resolver output
/// will see only doctrine-aligned entries.
class DressAccessoryResolver {
  const DressAccessoryResolver();

  List<Accessory> resolve({
    required DressRequirement requirement,
    required UniformProfile profile,
    required List<Accessory> library,
  }) {
    final split = resolveSplit(
      requirement: requirement,
      profile: profile,
      library: library,
    );
    return [...split.mandatory, ...split.optional];
  }

  /// Returns mandatory and optional accessories separately so the UI can
  /// label rows. The classification is applied per structured override
  /// key, not per accessory id, which keeps it stable as new branches
  /// reuse the same library entries with different doctrine.
  AccessorySplit resolveSplit({
    required DressRequirement requirement,
    required UniformProfile profile,
    required List<Accessory> library,
  }) {
    final override = requirement.branchOverrides[profile.branch.wireName] ??
        const <String, dynamic>{};
    final libraryById = <String, Accessory>{
      for (final a in library) a.id: a,
    };

    final mandatoryIds = <String>{};
    final optionalIds = <String>{};

    void addMandatory(Object? raw) {
      if (raw is String && raw.isNotEmpty) mandatoryIds.add(raw);
    }

    void addOptional(Object? raw) {
      if (raw is String && raw.isNotEmpty) optionalIds.add(raw);
    }

    // headdress: { men: { default, sikh, sikh_col_me7_above },
    //              ladies: { officer_wo_me3_to_me8,
    //                        specialist_enlistee_me1_me2 } }
    final headdress = override['headdress'];
    if (headdress is Map) {
      addMandatory(_pickHeaddress(
        Map<String, dynamic>.from(headdress),
        profile,
      ));
    }

    // cap_badge: { sltc_me6_below, col_me7, col_me7_above,
    //              bg_me8_above, military_police }
    final capBadge = override['cap_badge'];
    if (capBadge is Map) {
      addMandatory(
        _pickByOfficerTier(Map<String, dynamic>.from(capBadge), profile),
      );
    } else {
      addMandatory(capBadge);
    }

    // cap_embellishment: same shape as cap_badge (Navy/RSAF only)
    final capEmbellishment = override['cap_embellishment'];
    if (capEmbellishment is Map) {
      addMandatory(_pickByOfficerTier(
        Map<String, dynamic>.from(capEmbellishment),
        profile,
      ));
    } else {
      addMandatory(capEmbellishment);
    }

    // rank_insignia_sleeve: { specialist, enlistee }
    final sleeve = override['rank_insignia_sleeve'];
    if (sleeve is Map) {
      final m = Map<String, dynamic>.from(sleeve);
      final tier = _enlisteeOrSpecialist(profile.rank);
      if (tier != null) addMandatory(m[tier]);
    } else {
      addMandatory(sleeve);
    }

    // epaulettes: string id, or nested by rank tier
    final epaulettes = override['epaulettes'];
    if (epaulettes is Map) {
      addMandatory(_pickByOfficerTier(
        Map<String, dynamic>.from(epaulettes),
        profile,
      ));
    } else {
      addMandatory(epaulettes);
    }

    // name_tag: mandatory for all branches. Rendered via texture bake in
    // the 3D pipeline (bakeNameTag in composeUniformModel); shown in the
    // Wardrobe checklist so the user can verify they are wearing it.
    addMandatory(override['name_tag']);

    // belt / socks / footwear: universal mandatory items shared by all
    // branches and dress codes; they live in `branch_overrides` so the
    // Wardrobe-facing resolver picks them up via the same code path as
    // every other mandatory accessory. Each value is one of:
    //
    //   - a bare id string                        — single canonical item
    //   - a list of ids                           — alternatives, all
    //                                                added to mandatory
    //                                                so the Wardrobe
    //                                                lists every option
    //   - a `{men, ladies}` selector              — gender-picked, where
    //                                                each side is itself
    //                                                one of the above
    //                                                shapes
    void addOne(Object? raw) {
      if (raw is String && raw.isNotEmpty) {
        addMandatory(raw);
      } else if (raw is List) {
        for (final item in raw) {
          if (item is String && item.isNotEmpty) addMandatory(item);
        }
      }
    }

    void addGenderedMandatory(Object? raw) {
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        final key = profile.gender == Gender.female ? 'ladies' : 'men';
        addOne(m[key]);
      } else {
        addOne(raw);
      }
    }

    addGenderedMandatory(override['belt']);
    addGenderedMandatory(override['socks']);
    addGenderedMandatory(override['footwear']);

    // lanyard / arms_badge / vocation_badge: conditional per regiment /
    // vocation / arm. Surfaced as optional in the UI.
    addOptional(override['lanyard']);
    addOptional(override['arms_badge']);
    addOptional(override['vocation_badge']);

    final mandatory = _hydrate(mandatoryIds, libraryById, profile.gender);
    final optional = _hydrate(
      optionalIds.difference(mandatoryIds),
      libraryById,
      profile.gender,
    );
    return (mandatory: mandatory, optional: optional);
  }

  List<Accessory> _hydrate(
    Iterable<String> ids,
    Map<String, Accessory> libraryById,
    Gender gender,
  ) {
    final resolved = <Accessory>[];
    for (final id in ids) {
      final a = libraryById[id];
      if (a == null) continue;
      if (a.renderLogic['legacy_placeholder'] == true) continue;
      if (!_genderMatches(a, gender)) continue;
      resolved.add(a);
    }
    return resolved;
  }

  String? _pickHeaddress(
    Map<String, dynamic> headdress,
    UniformProfile profile,
  ) {
    if (profile.gender == Gender.female) {
      final ladies = headdress['ladies'];
      if (ladies is Map) {
        final m = Map<String, dynamic>.from(ladies);
        final officerKey =
            _isOfficerOrWarrant(profile.rank) ? 'officer_wo_me3_to_me8' : null;
        final enlisteeKey = _isEnlistedOrSpecialist(profile.rank)
            ? 'specialist_enlistee_me1_me2'
            : null;
        return (m[officerKey] ?? m[enlisteeKey]) as String?;
      }
      return null;
    }

    final men = headdress['men'];
    if (men is! Map) return null;
    final m = Map<String, dynamic>.from(men);
    if (profile.isSikh) {
      if (_isColOrAboveMe7Plus(profile.rank) && m['sikh_col_me7_above'] is String) {
        return m['sikh_col_me7_above'] as String;
      }
      if (m['sikh'] is String) return m['sikh'] as String;
    }
    return m['default'] as String?;
  }

  String? _pickByOfficerTier(
    Map<String, dynamic> tiers,
    UniformProfile profile,
  ) {
    final r = profile.rank;
    if (_isBgOrAboveMe8Plus(r) && tiers['bg_me8_above'] is String) {
      return tiers['bg_me8_above'] as String;
    }
    if (r == Rank.col) {
      if (tiers['col_me7'] is String) return tiers['col_me7'] as String;
      if (tiers['col_me7_above'] is String) {
        return tiers['col_me7_above'] as String;
      }
    }
    if (_isColOrAboveMe7Plus(r) && tiers['col_me7_above'] is String) {
      return tiers['col_me7_above'] as String;
    }
    if (tiers['sltc_me6_below'] is String) {
      return tiers['sltc_me6_below'] as String;
    }
    return null;
  }

  bool _genderMatches(Accessory a, Gender g) {
    final raw = a.gender;
    if (raw == null || raw.isEmpty) return true;
    if (raw == 'unisex') return true;
    if (g == Gender.female) return raw == 'female' || raw == 'ladies';
    return raw == 'male' || raw == 'men';
  }

  bool _isEnlistedOrSpecialist(Rank r) {
    return _enlisteeOrSpecialist(r) != null;
  }

  String? _enlisteeOrSpecialist(Rank r) {
    switch (r) {
      case Rank.rec:
      case Rank.pte:
      case Rank.lcp:
      case Rank.cpl:
      case Rank.cfc:
        return 'enlistee';
      case Rank.threeSg:
      case Rank.twoSg:
      case Rank.oneSg:
      case Rank.ssg:
      case Rank.msg:
        return 'specialist';
      default:
        return null;
    }
  }

  bool _isOfficerOrWarrant(Rank r) {
    switch (r) {
      case Rank.threeWo:
      case Rank.twoWo:
      case Rank.oneWo:
      case Rank.mwo:
      case Rank.swo:
      case Rank.cwo:
      case Rank.oct:
      case Rank.twoLt:
      case Rank.lta:
      case Rank.cpt:
      case Rank.maj:
      case Rank.ltc:
      case Rank.sltc:
      case Rank.col:
      case Rank.bg:
      case Rank.mg:
      case Rank.ltg:
        return true;
      default:
        return false;
    }
  }

  bool _isColOrAboveMe7Plus(Rank r) {
    switch (r) {
      case Rank.col:
      case Rank.bg:
      case Rank.mg:
      case Rank.ltg:
        return true;
      default:
        return false;
    }
  }

  bool _isBgOrAboveMe8Plus(Rank r) {
    switch (r) {
      case Rank.bg:
      case Rank.mg:
      case Rank.ltg:
        return true;
      default:
        return false;
    }
  }
}

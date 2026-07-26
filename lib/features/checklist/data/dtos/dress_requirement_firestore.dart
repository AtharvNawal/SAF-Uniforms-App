import '../../domain/entities/dress_requirement.dart';

/// Adapter from a `dress_requirements/{dressId}` Firestore document into the
/// [DressRequirement] domain entity. The Firestore doc shape mirrors a
/// single entry in `assets/data/dress_requirements.v1.json` (the seeder
/// writes it verbatim) plus `version` + `updatedAt` server fields.
class DressRequirementFirestore {
  /// `docId` is the Firestore document id (the `id` field). Authoritative
  /// — falls back to `data['id']` only when `docId` is empty (defensive).
  static DressRequirement fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final id = docId.isNotEmpty ? docId : (data['id'] as String? ?? '');
    return DressRequirement(
      id: id,
      dressName: (data['dress_name'] as String?) ?? id,
      displayName: (data['display_name'] as String?) ?? '',
      subtitle: (data['subtitle'] as String?) ?? '',
      mandatoryRules: _decodeMandatoryRules(data['mandatory_rules']),
      optionalLogic: _decodeMap(data['optional_logic']),
      branchOverrides: _decodeBranchOverrides(data['branch_overrides']),
      version: (data['version'] as num?)?.toInt() ?? 1,
    );
  }

  static List<Map<String, dynamic>> _decodeMandatoryRules(Object? raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
  }

  static Map<String, dynamic> _decodeMap(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static Map<String, Map<String, dynamic>> _decodeBranchOverrides(Object? raw) {
    if (raw is! Map) return <String, Map<String, dynamic>>{};
    return raw.map<String, Map<String, dynamic>>(
      (key, value) => MapEntry(
        key as String,
        value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{},
      ),
    );
  }
}

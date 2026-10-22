import '../../../profile/domain/entities/accessory.dart';

/// Adapter from an `accessory_library/{accessoryId}` Firestore document into
/// the [Accessory] domain entity. Doc shape mirrors a single entry in
/// `assets/data/accessory_library.v1.json` (seeder writes verbatim) plus
/// `version` + `updatedAt` server fields.
class AccessoryFirestore {
  /// `docId` is the Firestore document id (the accessory id). Authoritative.
  static Accessory fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final id = docId.isNotEmpty ? docId : (data['id'] as String? ?? '');
    return Accessory(
      id: id,
      displayName: (data['display_name'] as String?) ?? id,
      imageUrl: (data['image_url'] as String?) ?? '',
      placementDiagramUrl: (data['placement_diagram'] as String?) ?? '',
      rules: _decodeMap(data['rules']),
      renderLogic: _decodeMap(data['render_logic']),
      dressImages: _decodeDressImages(data['dress_images']),
      branchId: data['branch_id'] as String?,
      category: data['category'] as String?,
      gender: data['gender'] as String?,
      version: (data['version'] as num?)?.toInt() ?? 1,
    );
  }

  /// `{variant: {image_url, placement_diagram}}`; non-string values and
  /// malformed variants are dropped rather than failing the whole doc.
  static Map<String, Map<String, String>> _decodeDressImages(Object? raw) {
    if (raw is! Map) return const <String, Map<String, String>>{};
    final out = <String, Map<String, String>>{};
    raw.forEach((key, value) {
      if (key is! String || value is! Map) return;
      final urls = <String, String>{
        for (final e in value.entries)
          if (e.key is String &&
              e.value is String &&
              (e.value as String).isNotEmpty)
            e.key as String: e.value as String,
      };
      if (urls.isNotEmpty) out[key] = urls;
    });
    return out;
  }

  static Map<String, dynamic> _decodeMap(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }
}

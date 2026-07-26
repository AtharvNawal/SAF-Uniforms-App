import '../../domain/entities/branch_id.dart';
import '../../domain/entities/dress_code.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/generated_dress.dart';
import '../../domain/entities/rank.dart';
import '../../domain/entities/uniform_profile.dart';

class UniformProfileDto {
  static Map<String, Object?> toFirestore(UniformProfile profile) {
    return <String, Object?>{
      'branch': profile.branch.wireName,
      'rank': profile.rank.code,
      'gender': profile.gender.wireName,
      'dressCode': profile.dressCode.wireName,
      'isSikh': profile.isSikh,
      'fullName': profile.fullName,
      'vocation': profile.vocation,
      'medalRowCount': profile.medalRowCount,
      'selectedBadgeIds': profile.selectedBadgeIds.toList(),
      'selectedAccessoryIds': profile.selectedAccessoryIds.toList(),
      'dressAccessoryChecks': profile.dressAccessoryChecks.map(
        (dressId, ids) => MapEntry(dressId, ids.toList()),
      ),
      'generatedDresses': profile.generatedDresses.map(
        (dressId, entry) => MapEntry(dressId, _generatedDressToMap(entry)),
      ),
    };
  }

  static UniformProfile fromFirestore(Map<String, Object?> json) {
    return UniformProfile(
      branch: BranchId.fromWireName(json['branch'] as String),
      rank: Rank.values.firstWhere((r) => r.code == json['rank']),
      gender: Gender.fromWireName(json['gender'] as String),
      dressCode: DressCode.fromWireName(json['dressCode'] as String),
      isSikh: (json['isSikh'] as bool?) ?? false,
      fullName: (json['fullName'] as String?) ?? '',
      vocation: (json['vocation'] as String?) ?? 'Infantry',
      medalRowCount: (json['medalRowCount'] as num?)?.toInt() ?? 0,
      selectedBadgeIds: ((json['selectedBadgeIds'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
      selectedAccessoryIds: ((json['selectedAccessoryIds'] as List?) ?? const [])
          .cast<String>()
          .toSet(),
      dressAccessoryChecks: _readDressAccessoryChecks(json['dressAccessoryChecks']),
      generatedDresses: _readGeneratedDresses(json['generatedDresses']),
    );
  }

  static const _wireNameToDressId = {
    'No1': 'no_1_dress_requirements',
    'No2': 'no_2_dress_requirements',
    'No3': 'no_3_dress_requirements',
    'No4': 'no_4_dress_requirements',
    'No5': 'no_5_dress_requirements',
  };

  static Map<String, Object?> _generatedDressToMap(GeneratedDress entry) {
    return <String, Object?>{
      'builtAt': entry.builtAt.millisecondsSinceEpoch,
      if (entry.modelUrl != null) 'modelUrl': entry.modelUrl,
      if (entry.profileHash != null) 'profileHash': entry.profileHash,
      if (entry.schemaVersion != null) 'schemaVersion': entry.schemaVersion,
      if (entry.generationStartedAt != null)
        'generationStartedAt':
            entry.generationStartedAt!.millisecondsSinceEpoch,
      if (entry.error != null) 'error': entry.error,
    };
  }

  static Map<String, GeneratedDress> _readGeneratedDresses(Object? raw) {
    if (raw is! Map) return <String, GeneratedDress>{};
    final out = <String, GeneratedDress>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      final dressId = _wireNameToDressId[key] ?? key;
      if (value is! Map) {
        // Legacy shape: the field was previously stored as a bare millis int.
        final ms = value is int ? value : (value as num?)?.toInt();
        if (ms == null) return;
        out[dressId] = GeneratedDress(
          builtAt: DateTime.fromMillisecondsSinceEpoch(ms),
        );
        return;
      }
      final builtMs = (value['builtAt'] as num?)?.toInt();
      if (builtMs == null) return;
      final startedMs = (value['generationStartedAt'] as num?)?.toInt();
      out[dressId] = GeneratedDress(
        builtAt: DateTime.fromMillisecondsSinceEpoch(builtMs),
        modelUrl: value['modelUrl'] as String?,
        profileHash: value['profileHash'] as String?,
        schemaVersion: (value['schemaVersion'] as num?)?.toInt(),
        generationStartedAt: startedMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(startedMs),
        error: value['error'] as String?,
      );
    });
    return out;
  }

  static Map<String, Set<String>> _readDressAccessoryChecks(Object? raw) {
    if (raw is! Map) return <String, Set<String>>{};
    final out = <String, Set<String>>{};
    raw.forEach((key, value) {
      if (key is! String || value is! List) return;
      out[key] = value.whereType<String>().toSet();
    });
    return out;
  }
}

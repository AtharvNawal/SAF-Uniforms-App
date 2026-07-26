import '../../domain/entities/branch_config.dart';
import '../../domain/entities/branch_id.dart';
import '../../domain/entities/dress_code.dart';

/// Adapter from a `branch_configs/{branchId}` Firestore document into the
/// [BranchConfig] domain entity. The Firestore doc shape is byte-identical
/// to a single entry in `assets/data/branch_configs.v1.json` (the seeder
/// writes it verbatim), with the added `version` and `updatedAt` server
/// fields.
class BranchConfigFirestore {
  /// `docId` is the Firestore document id (the branch wire name). It is
  /// authoritative — `data` may also contain a `branchId` field but the
  /// document id is what the collection is keyed on.
  static BranchConfig fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    return BranchConfig(
      branchId: BranchId.fromWireName(docId),
      displayName: data['displayName'] as String,
      collarOffsetCm: (data['collarOffsetCm'] as num).toDouble(),
      ladiesMedalAnchor: MedalAnchor.fromJson(
        Map<String, dynamic>.from(data['ladiesMedalAnchor'] as Map),
      ),
      sikhTurbanLogic: SikhTurbanLogic.fromJson(
        Map<String, dynamic>.from(data['sikhTurbanLogic'] as Map),
      ),
      dressCodes: (data['dressCodes'] as List<dynamic>)
          .cast<String>()
          .map(DressCode.fromWireName)
          .toList(growable: false),
      version: (data['version'] as num?)?.toInt() ?? 1,
    );
  }
}

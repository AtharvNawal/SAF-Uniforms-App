import 'package:freezed_annotation/freezed_annotation.dart';

part 'compliance_result.freezed.dart';

/// Wire values match the `status` enum in the `report_compliance` tool
/// schema the `checkUniformCompliance` Cloud Function forces the model
/// to use — see `functions/src/checkUniformCompliance.ts`.
enum ComplianceStatus {
  correct('correct'),
  missing('missing'),
  incorrect('incorrect'),
  uncertain('uncertain');

  const ComplianceStatus(this.wireName);

  final String wireName;

  static ComplianceStatus fromWireName(String value) {
    return ComplianceStatus.values.firstWhere(
      (s) => s.wireName == value,
      orElse: () => ComplianceStatus.uncertain,
    );
  }
}

@freezed
abstract class ComplianceItem with _$ComplianceItem {
  const factory ComplianceItem({
    required String accessoryId,
    required String displayName,
    required ComplianceStatus status,
    required String note,
  }) = _ComplianceItem;
}

/// Result of a single AI-vision uniform compliance check. Ephemeral —
/// held only in `UniformComplianceController` state, never written to
/// Firestore (see the plan's "persistence: ephemeral only" decision).
@freezed
abstract class ComplianceResult with _$ComplianceResult {
  const factory ComplianceResult({
    required int overallScore,
    required String summary,
    required List<ComplianceItem> items,
  }) = _ComplianceResult;

  const ComplianceResult._();

  List<ComplianceItem> get correctItems =>
      items.where((i) => i.status == ComplianceStatus.correct).toList();

  List<ComplianceItem> get issues => items
      .where((i) =>
          i.status == ComplianceStatus.missing ||
          i.status == ComplianceStatus.incorrect)
      .toList();

  List<ComplianceItem> get uncertainItems =>
      items.where((i) => i.status == ComplianceStatus.uncertain).toList();
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cv_inspection_result.freezed.dart';

/// Wire values match the 5-state verdict `cv-service`'s report emits —
/// see `cv-service/detectors/vision_crop_inspector.py`'s
/// `_REPORT_TOOL` schema and `cv-service/reporting/report.py`. This is
/// a strictly separate enum from [ComplianceStatus]
/// (`compliance_result.dart`), not a replacement for it: the Node
/// `checkUniformCompliance` path (Phase 1) still returns the older
/// 4-state shape and remains the shipped default / fallback. This
/// enum is the Phase-2 `cv-service` shape only.
enum CvVerdict {
  present('present'),
  missing('missing'),
  misaligned('misaligned'),
  wrongType('wrong_type'),
  lowConfidence('low_confidence');

  const CvVerdict(this.wireName);

  final String wireName;

  static CvVerdict fromWireName(String value) {
    return CvVerdict.values.firstWhere(
      (s) => s.wireName == value,
      orElse: () => CvVerdict.lowConfidence,
    );
  }
}

@freezed
abstract class CvIssue with _$CvIssue {
  const factory CvIssue({
    required String item,
    required String category,
    required CvVerdict problem,
    required String severity,
    required double confidence,
    required String doctrineRef,
    required String note,
    required List<List<double>> bbox,
  }) = _CvIssue;
}

@freezed
abstract class CvUncertainItem with _$CvUncertainItem {
  const factory CvUncertainItem({
    required String item,
    required String reason,
    required double confidence,
  }) = _CvUncertainItem;
}

@freezed
abstract class CvSubscores with _$CvSubscores {
  const factory CvSubscores({
    double? headwear,
    double? chest,
    double? collar,
    double? sleeves,
    double? waist,
    double? lowerBody,
    double? footwear,
    double? appearance,
  }) = _CvSubscores;
}

@freezed
abstract class CvCameraDiagnostics with _$CvCameraDiagnostics {
  const factory CvCameraDiagnostics({
    required double reprojectionErrorPx,
    required int correspondenceCount,
    required double cmPerPx,
  }) = _CvCameraDiagnostics;
}

/// Wire values match `rules/rule_engine.py`'s `evaluate_verdicts()` —
/// see `ChangeRequest/2026-08-11_cv-service-verdict-engine-army-no3-male.md`.
/// **Deliberately a separate enum from [CvVerdict]**, not folded into
/// it: [CvVerdict] is the vision-language crop-inspector's 5-state
/// judgment, this is the geometric verdict engine's 4-state one (mask
/// position/orientation vs. doctrine tolerance) — different judgment
/// mechanisms, different failure modes, same "documented, not unified"
/// posture every new judgment path in `cv-service` has had this session.
enum GeometricVerdictStatus {
  pass_('pass'),
  fail('fail'),
  missing('missing'),
  unverifiable('unverifiable');

  const GeometricVerdictStatus(this.wireName);

  final String wireName;

  static GeometricVerdictStatus fromWireName(String value) {
    return GeometricVerdictStatus.values.firstWhere(
      (s) => s.wireName == value,
      orElse: () => GeometricVerdictStatus.unverifiable,
    );
  }
}

/// One accessory's geometric verdict — see `GeometricVerdictStatus` doc.
/// `reason` is always human-readable prose explaining *why* (e.g. "no
/// segmentation class exists yet for doctrine category 'name_tag'"),
/// never just the bare status — the whole point of the `unverifiable`
/// status is that a caller can tell a checked-and-passed item from an
/// item the pipeline structurally cannot check yet.
@freezed
abstract class GeometricVerdict with _$GeometricVerdict {
  const factory GeometricVerdict({
    required String accessory,
    required GeometricVerdictStatus status,
    required String reason,
    required String doctrineRef,
  }) = _GeometricVerdict;
}

/// Result of a Phase-2 `cv-service` `/inspect` call. Ephemeral, same
/// persistence stance as [ComplianceResult] — held only in
/// `CvServiceInspectionController` state, never written to Firestore.
///
/// `cv-service` is a local, un-deployed dev service today (see
/// `cv-service/README.md`) — this model exists so the app can talk to
/// it during development, not because it is the production path yet.
@freezed
abstract class CvInspectionResult with _$CvInspectionResult {
  const factory CvInspectionResult({
    required double overallScore,
    required String status,
    required CvSubscores subscores,
    required List<CvIssue> issues,
    required List<CvUncertainItem> uncertain,
    required int itemsEvaluated,
    required CvCameraDiagnostics cameraDiagnostics,
    @Default([]) List<GeometricVerdict> geometricVerdicts,
    String? annotatedImageBase64,
  }) = _CvInspectionResult;

  const CvInspectionResult._();

  bool get hasHighSeverityIssue =>
      issues.any((i) => i.severity.toLowerCase() == 'high');
}

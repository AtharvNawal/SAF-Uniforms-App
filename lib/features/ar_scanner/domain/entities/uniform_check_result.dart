import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'uniform_check_result.freezed.dart';

/// Result of `cv-service`'s `POST /check_uniform` — the Anthropic-free
/// geometry path (pose → PnP camera-pose solve → physical-scale
/// recovery → trained garment segmentation → doctrine tolerance check,
/// all in pixel space). See `cv-service/api/response_schema.py` for the
/// wire contract and CLAUDE.md §5.10.
///
/// Deliberately a **separate** model from [CvInspectionResult]
/// (`cv_inspection_result.dart`, the `/inspect` shape) and
/// [ComplianceResult] (`compliance_result.dart`, the Phase-1
/// Node/Anthropic shape) — three endpoints, three report shapes, not
/// forced into one.
enum UniformCheckStatus {
  correct('CORRECT'),
  slightlyMisaligned('SLIGHTLY_MISALIGNED'),
  incorrect('INCORRECT'),
  missing('MISSING'),
  uncertain('UNCERTAIN');

  const UniformCheckStatus(this.wireName);

  final String wireName;

  static UniformCheckStatus fromWireName(String value) {
    return UniformCheckStatus.values.firstWhere(
      (s) => s.wireName == value,
      orElse: () => UniformCheckStatus.uncertain,
    );
  }
}

@freezed
abstract class UniformCheckPoint with _$UniformCheckPoint {
  const factory UniformCheckPoint({required double x, required double y}) =
      _UniformCheckPoint;
}

@freezed
abstract class UniformCheckBox with _$UniformCheckBox {
  const factory UniformCheckBox({
    required double x,
    required double y,
    required double width,
    required double height,
  }) = _UniformCheckBox;
}

@freezed
abstract class UniformCheckAccessory with _$UniformCheckAccessory {
  const factory UniformCheckAccessory({
    required String name,

    /// `true` present, `false` missing, `null` could not determine.
    bool? present,

    /// `true` in tolerance, `false` out of tolerance, `null` n/a.
    bool? positionCorrect,
    double? confidence,
    required UniformCheckStatus status,

    /// `FULL` / `PARTIAL` / `NONE` — how much of the region was in frame.
    required String visibility,
    UniformCheckBox? boundingBox,
    UniformCheckPoint? expectedPosition,
    UniformCheckPoint? detectedPosition,

    /// (dx, dy) pixel offset of detected from expected, when both known.
    UniformCheckPoint? error,
    @Default('') String doctrineRef,
    @Default('') String message,

    /// What the wearer should do, in cm and their own left/right
    /// (`cv-service/api/instructions.py`).
    @Default('') String instruction,

    /// Doctrine requires this item for the wearer's profile.
    @Default(false) bool required,

    /// The service can detect this item at all — `false` for items with
    /// no detector yet (checked by eye, never counted against coverage).
    @Default(true) bool checkable,

    /// `trained` | `two_stage` | `zero_shot` — which detector found it.
    String? detectionSource,

    /// Burst only — how many usable frames agreed, e.g. `2/3`.
    String? frameAgreement,
  }) = _UniformCheckAccessory;

  const UniformCheckAccessory._();

  /// Euclidean pixel distance of [detectedPosition] from
  /// [expectedPosition], or `null` when [error] wasn't reported.
  double? get errorMagnitudePx {
    final e = error;
    if (e == null) return null;
    return math.sqrt(e.x * e.x + e.y * e.y);
  }
}

@freezed
abstract class UniformCheckSummary with _$UniformCheckSummary {
  const factory UniformCheckSummary({
    @Default(0) int detectedAccessories,
    @Default(0) int correct,
    @Default(0) int incorrect,
    @Default(0) int slightlyMisaligned,
    @Default(0) int missing,
    @Default(0) int uncertain,
    @Default(0) int requiredAccessories,
  }) = _UniformCheckSummary;
}

@freezed
abstract class UniformCheckResult with _$UniformCheckResult {
  const factory UniformCheckResult({
    required bool success,

    /// `PASS` / `FAIL` / `INCOMPLETE` (too few checkable required items
    /// could be verified from this photo to call it either way — see
    /// `ChangeRequest/2026-09-28_cv-service-coverage-gate-and-matching.md`).
    required String overallStatus,

    /// 0–100, computed over required items only (unverifiable excluded).
    required double overallScore,
    required bool imageQualityUsable,
    required double imageQualityConfidence,
    required bool personDetected,
    required double personConfidence,
    required List<UniformCheckAccessory> accessories,
    required UniformCheckSummary summary,

    /// Required items the service can detect / of those, how many got a
    /// definite verdict / required items it can't detect at all.
    @Default(0) int checkableRequired,
    @Default(0) int verifiedRequired,
    @Default(0) int notCheckableRequired,

    /// PNG overlay (base64) of expected vs detected positions.
    String? debugImageBase64,

    /// Burst only — frames sent / frames the service could use.
    int? burstFrames,
    int? burstUsableFrames,

    /// `exif_35mm` | `client` | `assumed` … — where the camera focal length
    /// came from (`assumed` = less accurate distances).
    String? focalSource,
  }) = _UniformCheckResult;

  const UniformCheckResult._();

  bool get passed => overallStatus.toUpperCase() == 'PASS';

  bool get incomplete => overallStatus.toUpperCase() == 'INCOMPLETE';

  List<UniformCheckAccessory> get issues => accessories
      .where((a) =>
          a.status == UniformCheckStatus.incorrect ||
          a.status == UniformCheckStatus.missing ||
          a.status == UniformCheckStatus.slightlyMisaligned)
      .toList(growable: false);

  List<UniformCheckAccessory> get passes => accessories
      .where((a) => a.status == UniformCheckStatus.correct)
      .toList(growable: false);

  List<UniformCheckAccessory> get uncertain => accessories
      .where((a) => a.status == UniformCheckStatus.uncertain)
      .toList(growable: false);

  /// Items the service can detect but couldn't judge from this photo
  /// (out of frame, too close to the tolerance to call, …) — a retake may
  /// resolve these.
  List<UniformCheckAccessory> get couldNotCheck =>
      uncertain.where((a) => a.checkable).toList(growable: false);

  /// Items the service has no detector for yet — the wearer checks these
  /// by eye against the doctrine diagram.
  List<UniformCheckAccessory> get checkByEye =>
      uncertain.where((a) => !a.checkable).toList(growable: false);
}

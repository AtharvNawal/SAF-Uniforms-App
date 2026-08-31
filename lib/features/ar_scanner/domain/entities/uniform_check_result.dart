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
    @Default(0) int missing,
    @Default(0) int uncertain,
    @Default(0) int requiredAccessories,
  }) = _UniformCheckSummary;
}

@freezed
abstract class UniformCheckResult with _$UniformCheckResult {
  const factory UniformCheckResult({
    required bool success,

    /// `PASS` / `FAIL`.
    required String overallStatus,

    /// 0–100, computed over required items only (unverifiable excluded).
    required double overallScore,
    required bool imageQualityUsable,
    required double imageQualityConfidence,
    required bool personDetected,
    required double personConfidence,
    required List<UniformCheckAccessory> accessories,
    required UniformCheckSummary summary,
  }) = _UniformCheckResult;

  const UniformCheckResult._();

  bool get passed => overallStatus.toUpperCase() == 'PASS';

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
}

import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

const String _tag = 'arScanner.liveGuide';

/// What the person in frame (or whoever holds the phone) should fix next.
/// Ordered by priority — only the first failing check is shown.
enum CaptureHint {
  noPerson,
  notFullBody,
  tooFar,
  tooClose,
  notCentered,
  facingAway,
  turnedSideways,
  armsRaised,
  phoneTilted,
  holdStill,
  ready,
}

/// One pose landmark in the upright camera image, in pixels.
class GuideLandmark {
  const GuideLandmark(this.x, this.y, this.likelihood);
  final double x;
  final double y;
  final double likelihood;
}

/// D15 — the capture protocol as a pure, testable decision
/// (`ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`).
///
/// Mirrors what `cv-service` needs to measure accurately: the whole body in
/// frame (feet anchor the camera solve), filling enough of it (pixels per
/// cm), roughly centred, facing the camera square-on (the PnP solve assumes
/// a near-frontal view — `cv-service` rejects anything else as
/// POSE_UNRELIABLE), arms relaxed (sleeve insignia visible, A-pose), and
/// the phone upright and level.
class CaptureGuidance {
  const CaptureGuidance._();

  static const double minLikelihood = 0.5;
  static const double minBodyFraction = 0.55;
  static const double maxBodyFraction = 0.92;
  static const double maxCentreOffset = 0.2;
  static const double minShoulderToTorso = 0.45;
  static const double maxPitchDeg = 12;
  static const double maxRollDeg = 5;

  static CaptureHint assess({
    required Map<PoseLandmarkType, GuideLandmark> landmarks,
    required Size imageSize,
    double? pitchDeg,
    double? rollDeg,
  }) {
    GuideLandmark? lm(PoseLandmarkType t) {
      final l = landmarks[t];
      return (l != null && l.likelihood >= minLikelihood) ? l : null;
    }

    if (landmarks.isEmpty) return CaptureHint.noPerson;
    final nose = lm(PoseLandmarkType.nose);
    final ls = lm(PoseLandmarkType.leftShoulder);
    final rs = lm(PoseLandmarkType.rightShoulder);
    final lh = lm(PoseLandmarkType.leftHip);
    final rh = lm(PoseLandmarkType.rightHip);
    final la = lm(PoseLandmarkType.leftAnkle);
    final ra = lm(PoseLandmarkType.rightAnkle);
    if (nose == null || ls == null || rs == null || lh == null || rh == null || la == null || ra == null) {
      return CaptureHint.notFullBody;
    }

    final h = imageSize.height;
    final w = imageSize.width;
    // Head top sits roughly half a nose-to-shoulder span above the nose.
    final shoulderY = (ls.y + rs.y) / 2;
    final headTop = nose.y - 0.6 * (shoulderY - nose.y);
    final feet = la.y > ra.y ? la.y : ra.y;
    final bodyFraction = (feet - headTop) / h;
    if (headTop < 0 || feet > 0.98 * h || bodyFraction > maxBodyFraction) return CaptureHint.tooClose;
    if (bodyFraction < minBodyFraction) return CaptureHint.tooFar;

    final centreX = (ls.x + rs.x + lh.x + rh.x) / 4 / w;
    if ((centreX - 0.5).abs() > maxCentreOffset) return CaptureHint.notCentered;

    // Front view: the wearer's LEFT shoulder appears on image-RIGHT.
    if (ls.x < rs.x) return CaptureHint.facingAway;
    final shoulderWidth = ls.x - rs.x;
    final torsoLength = ((lh.y + rh.y) / 2 - shoulderY).abs();
    if (torsoLength <= 0 || shoulderWidth / torsoLength < minShoulderToTorso) return CaptureHint.turnedSideways;

    final lw = lm(PoseLandmarkType.leftWrist);
    final rw = lm(PoseLandmarkType.rightWrist);
    if ((lw != null && lw.y < shoulderY) || (rw != null && rw.y < shoulderY)) return CaptureHint.armsRaised;

    if ((pitchDeg != null && pitchDeg.abs() > maxPitchDeg) || (rollDeg != null && rollDeg.abs() > maxRollDeg)) {
      return CaptureHint.phoneTilted;
    }
    return CaptureHint.ready;
  }
}

/// Runs ML Kit pose detection on the live camera stream, throttled, and
/// reports a [CaptureHint] per processed frame. [CaptureHint.ready] is
/// only reported after the protocol has held for [stableFrames]
/// consecutive frames (a brief "hold still" window) so the burst captures
/// a settled pose.
class LivePoseGuide {
  LivePoseGuide({this.stableFrames = 3, this.minInterval = const Duration(milliseconds: 250)})
      : _detector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));

  final PoseDetector _detector;
  final int stableFrames;
  final Duration minInterval;
  bool _busy = false;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  int _readyStreak = 0;

  static const Map<DeviceOrientation, int> _orientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Processes one frame if the detector is free and the throttle allows;
  /// returns `null` when the frame was skipped.
  Future<CaptureHint?> process(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation, {
    double? pitchDeg,
    double? rollDeg,
  }) async {
    final now = DateTime.now();
    if (_busy || now.difference(_last) < minInterval) return null;
    _busy = true;
    _last = now;
    try {
      final input = _toInputImage(image, camera, deviceOrientation);
      if (input == null) return null;
      final poses = await _detector.processImage(input);
      final rotated = input.metadata!.rotation == InputImageRotation.rotation90deg ||
          input.metadata!.rotation == InputImageRotation.rotation270deg;
      final size = rotated
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());
      final landmarks = poses.isEmpty
          ? <PoseLandmarkType, GuideLandmark>{}
          : {
              for (final e in poses.first.landmarks.entries)
                e.key: GuideLandmark(e.value.x, e.value.y, e.value.likelihood),
            };
      final hint = CaptureGuidance.assess(landmarks: landmarks, imageSize: size, pitchDeg: pitchDeg, rollDeg: rollDeg);
      if (hint == CaptureHint.ready) {
        _readyStreak++;
        return _readyStreak >= stableFrames ? CaptureHint.ready : CaptureHint.holdStill;
      }
      _readyStreak = 0;
      return hint;
    } catch (e, st) {
      developer.log('process: failed', name: _tag, error: e, stackTrace: st, level: 1000);
      return null;
    } finally {
      _busy = false;
    }
  }

  /// Standard ML Kit bridge for `camera` stream frames. The controller must
  /// be created with `ImageFormatGroup.nv21` (Android) / `.bgra8888` (iOS)
  /// so each frame is a single plane ML Kit accepts as-is.
  InputImage? _toInputImage(CameraImage image, CameraDescription camera, DeviceOrientation deviceOrientation) {
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else if (Platform.isAndroid) {
      final device = _orientationDegrees[deviceOrientation] ?? 0;
      final compensation = camera.lensDirection == CameraLensDirection.front
          ? (camera.sensorOrientation + device) % 360
          : (camera.sensorOrientation - device + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (rotation == null || format == null || image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void reset() => _readyStreak = 0;

  Future<void> close() => _detector.close();
}

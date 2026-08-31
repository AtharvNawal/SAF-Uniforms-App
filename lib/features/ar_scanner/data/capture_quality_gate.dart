import 'dart:developer' as developer;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

const String _tag = 'arScanner.captureGate';

/// On-device capture-quality gate — Milestone 1 (client half) of the
/// Phase-2 CV pipeline described in the architecture memo's §0/§10:
/// reject a photo whose pose doesn't resemble a relaxed standing shot
/// (torso not visible, camera badly tilted) *before* it's ever sent
/// anywhere, rather than let a bad photo silently degrade whatever
/// backend judges it.
///
/// Scope note: even with the in-app live camera preview
/// (`ar_scanner_screen.dart`, migrated off `image_picker` — see
/// `ChangeRequest/2026-08-11_ar-scanner-live-camera-and-error-messaging.md`),
/// this gate still runs on the captured JPEG right after the shutter
/// fires, not on the live feed mid-preview — a real-time per-frame
/// pose check against the live feed would be a further milestone, not
/// built here.
///
/// Uses `google_mlkit_pose_detection`, which was already a declared
/// dependency doing nothing (`CLAUDE.md` §8 flagged it as unused) —
/// this is its first real caller.
class CaptureQualityGate {
  CaptureQualityGate()
      : _detector = PoseDetector(
          options: PoseDetectorOptions(
            model: PoseDetectionModel.accurate,
            mode: PoseDetectionMode.single,
          ),
        );

  final PoseDetector _detector;

  static const double _minLandmarkLikelihood = 0.5;
  static const double _maxShoulderTiltRatio = 0.35;

  Future<CaptureQualityResult> evaluate(String imagePath) async {
    developer.log('evaluate: start  path=$imagePath', name: _tag, level: 800);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final poses = await _detector.processImage(inputImage);

      if (poses.isEmpty) {
        developer.log('evaluate: no pose detected', name: _tag, level: 900);
        return const CaptureQualityResult(
          accepted: false,
          issue: CaptureQualityIssue.noPersonDetected,
        );
      }

      final landmarks = poses.first.landmarks;
      final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = landmarks[PoseLandmarkType.leftHip];
      final rightHip = landmarks[PoseLandmarkType.rightHip];

      final torsoLandmarks = [leftShoulder, rightShoulder, leftHip, rightHip];
      final torsoVisible = torsoLandmarks.every(
        (lm) => lm != null && lm.likelihood >= _minLandmarkLikelihood,
      );
      if (!torsoVisible) {
        developer.log('evaluate: torso not confidently visible',
            name: _tag, level: 900);
        return const CaptureQualityResult(
          accepted: false,
          issue: CaptureQualityIssue.torsoNotVisible,
        );
      }

      final shoulderWidth = (rightShoulder!.x - leftShoulder!.x).abs();
      final shoulderTilt = (leftShoulder.y - rightShoulder.y).abs();
      if (shoulderWidth > 0 &&
          shoulderTilt / shoulderWidth > _maxShoulderTiltRatio) {
        developer.log(
          'evaluate: shoulders not level  tilt=$shoulderTilt  width=$shoulderWidth',
          name: _tag,
          level: 900,
        );
        return const CaptureQualityResult(
          accepted: false,
          issue: CaptureQualityIssue.shouldersNotLevel,
        );
      }

      developer.log('evaluate: accepted', name: _tag, level: 800);
      return const CaptureQualityResult(accepted: true, issue: CaptureQualityIssue.none);
    } catch (e, st) {
      // On-device pose detection failing (model not downloaded yet,
      // platform channel error, etc.) should never block the user from
      // submitting a photo — degrade to "accept" rather than trap them.
      developer.log('evaluate: failed, accepting by default',
          name: _tag, error: e, stackTrace: st, level: 1000);
      return const CaptureQualityResult(accepted: true, issue: CaptureQualityIssue.none);
    }
  }

  Future<void> close() => _detector.close();
}

enum CaptureQualityIssue {
  none,
  noPersonDetected,
  torsoNotVisible,
  shouldersNotLevel,
}

class CaptureQualityResult {
  const CaptureQualityResult({required this.accepted, required this.issue});

  final bool accepted;
  final CaptureQualityIssue issue;
}

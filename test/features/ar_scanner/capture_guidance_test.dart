import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:saf_uniforms/features/ar_scanner/data/live_pose_guide.dart';

/// A relaxed, front-facing standing pose in a 1000×2000 portrait frame.
/// Front view: the wearer's LEFT side is on image-RIGHT.
Map<PoseLandmarkType, GuideLandmark> _pose({
  double scale = 1.0,
  double shiftX = 0,
  bool facingAway = false,
  bool sideways = false,
  bool armsUp = false,
  double likelihood = 0.9,
}) {
  GuideLandmark p(double x, double y) =>
      GuideLandmark(500 + (x - 500) * scale + shiftX, 1000 + (y - 1000) * scale, likelihood);
  final half = sideways ? 30.0 : 150.0;
  final l = facingAway ? -half : half;
  return {
    PoseLandmarkType.nose: p(500, 400),
    PoseLandmarkType.leftShoulder: p(500 + l, 550),
    PoseLandmarkType.rightShoulder: p(500 - l, 550),
    PoseLandmarkType.leftHip: p(500 + l * 0.7, 1000),
    PoseLandmarkType.rightHip: p(500 - l * 0.7, 1000),
    PoseLandmarkType.leftWrist: p(500 + l * 1.2, armsUp ? 300 : 1000),
    PoseLandmarkType.rightWrist: p(500 - l * 1.2, 1000),
    PoseLandmarkType.leftAnkle: p(500 + l * 0.5, 1700),
    PoseLandmarkType.rightAnkle: p(500 - l * 0.5, 1700),
  };
}

CaptureHint _assess(Map<PoseLandmarkType, GuideLandmark> lm, {double? pitch, double? roll}) =>
    CaptureGuidance.assess(landmarks: lm, imageSize: const Size(1000, 2000), pitchDeg: pitch, rollDeg: roll);

void main() {
  group('CaptureGuidance.assess', () {
    test('a good front-facing full-body shot is ready', () {
      expect(_assess(_pose(), pitch: 2, roll: 1), CaptureHint.ready);
    });

    test('nothing detected -> noPerson; low-confidence feet -> notFullBody', () {
      expect(_assess({}), CaptureHint.noPerson);
      final lm = _pose()..[PoseLandmarkType.leftAnkle] = const GuideLandmark(600, 1700, 0.1);
      expect(_assess(lm), CaptureHint.notFullBody);
    });

    test('distance', () {
      expect(_assess(_pose(scale: 0.5)), CaptureHint.tooFar);
      expect(_assess(_pose(scale: 1.35)), CaptureHint.tooClose);
    });

    test('off-centre', () {
      expect(_assess(_pose(shiftX: 300)), CaptureHint.notCentered);
    });

    test('back to the camera / turned sideways', () {
      expect(_assess(_pose(facingAway: true)), CaptureHint.facingAway);
      expect(_assess(_pose(sideways: true)), CaptureHint.turnedSideways);
    });

    test('raised arms', () {
      expect(_assess(_pose(armsUp: true)), CaptureHint.armsRaised);
    });

    test('phone tilt', () {
      expect(_assess(_pose(), pitch: 20), CaptureHint.phoneTilted);
      expect(_assess(_pose(), roll: -9), CaptureHint.phoneTilted);
      expect(_assess(_pose()), CaptureHint.ready); // no sensor reading -> not blocked
    });
  });
}

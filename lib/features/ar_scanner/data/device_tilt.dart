import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

const String _tag = 'arScanner.deviceTilt';

/// Phone orientation from the accelerometer (D16 in
/// `ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`).
///
/// Two uses:
///  - live capture guidance — "hold the phone level / upright";
///  - sent with the photo as `gravity_x/y/z`: world-up expressed in the
///    back camera's OpenCV frame (x right, y down, z forward), which
///    `cv-service` uses as a prior on the camera's pitch and roll. From a
///    near-frontal photo the body landmarks barely constrain camera pitch;
///    the phone measures it directly to about a degree.
///
/// Frame conversion. `sensors_plus` reports acceleration in the device
/// frame (x right, y toward the top of the screen, z out of the screen),
/// in the Android convention on both platforms: at rest the reading
/// points *up*, away from gravity. With the phone in portrait, the back
/// camera looks along device −z, image-right is device +x and image-down
/// is device −y, so world-up in camera coordinates is
/// `(ax, −ay, −az) / |a|`.
class DeviceTilt {
  DeviceTilt();

  StreamSubscription<AccelerometerEvent>? _sub;
  List<double>? _smoothed;

  /// Low-pass factor — the accelerometer also sees hand shake; gravity is
  /// the slow component.
  static const double _alpha = 0.15;

  void start() {
    developer.log('start', name: _tag, level: 800);
    try {
      _sub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) {
          final prev = _smoothed;
          _smoothed = prev == null
              ? [e.x, e.y, e.z]
              : [
                  prev[0] + _alpha * (e.x - prev[0]),
                  prev[1] + _alpha * (e.y - prev[1]),
                  prev[2] + _alpha * (e.z - prev[2]),
                ];
        },
        onError: (Object e, StackTrace st) => developer.log('stream error',
            name: _tag, error: e, stackTrace: st, level: 1000),
      );
    } catch (e, st) {
      developer.log('start: failed', name: _tag, error: e, stackTrace: st, level: 1000);
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// World-up in the back camera's OpenCV frame, unit length, or `null`
  /// before the first reading / when the phone is in free fall.
  List<double>? get gravityUpCamera {
    final a = _smoothed;
    if (a == null) return null;
    final norm = math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]);
    if (norm < 1e-3) return null;
    return [a[0] / norm, -a[1] / norm, -a[2] / norm];
  }

  /// Camera pitch in degrees: positive = camera tilted up, 0 = level.
  double? get pitchDeg {
    final up = gravityUpCamera;
    if (up == null) return null;
    // camera forward is +z in its own frame; pitch = elevation of forward
    return math.asin(up[2].clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  /// Camera roll in degrees: 0 = image upright.
  double? get rollDeg {
    final up = gravityUpCamera;
    if (up == null) return null;
    // world-up should point image-up (−y); roll is its angle off that
    return math.atan2(up[0], -up[1]) * 180 / math.pi;
  }
}

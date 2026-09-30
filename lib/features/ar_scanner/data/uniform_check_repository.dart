import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/utils/app_logger.dart';
import '../domain/entities/uniform_check_result.dart';
import 'cv_service_inspection_repository.dart' show kCvServiceBaseUrl;

const String _tag = 'arScanner.uniformCheck';

/// Client for `cv-service`'s `POST /check_uniform` — the Anthropic-free
/// geometry path (pose → PnP camera-pose solve → physical-scale
/// recovery → trained garment segmentation → doctrine tolerance check,
/// all in pixel space). See `cv-service/api/main.py` +
/// `cv-service/api/response_schema.py` and CLAUDE.md §5.10.
///
/// Reuses [kCvServiceBaseUrl] (default `http://localhost:8001`; override
/// per device with `--dart-define=CV_SERVICE_BASE_URL=...`). `cv-service`
/// has **no deployed instance** yet — an unreachable service surfaces as
/// a [UniformCheckException] with `statusCode == null`.
class UniformCheckRepository {
  UniformCheckRepository({
    required http.Client client,
    String baseUrl = kCvServiceBaseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// One photo → `POST /check_uniform`; several frames of the same pose
  /// → `POST /check_uniform_burst`, which combines them by per-item
  /// majority (D17). The optional inputs each make the measurement more
  /// accurate (`ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`):
  /// [wearerName] lets the service read and match the name tag,
  /// [heightCm] scales the reference body to the wearer, and
  /// [gravityUpCamera] (world-up in the back camera's frame, from
  /// `DeviceTilt`) constrains the camera's pitch and roll. The camera's
  /// focal length travels in the JPEG's own EXIF data.
  Future<UniformCheckResult> check({
    required List<Uint8List> photos,
    required String uniformType,
    required String rankTier,
    String gender = 'male',
    bool isSikh = false,
    int medalRowCount = 0,
    String bodyType = 'male',
    String? wearerName,
    int? heightCm,
    List<double>? gravityUpCamera,
    bool includeDebugImage = true,
  }) async {
    if (photos.isEmpty) {
      throw UniformCheckException('no photos to check', statusCode: null);
    }
    final burst = photos.length > 1;
    final path = burst ? 'check_uniform_burst' : 'check_uniform';
    AppLog.i(
      'check: POST /$path  uniform=$uniformType  rank=$rankTier  '
      'frames=${photos.length}  bytes=${photos.fold<int>(0, (n, p) => n + p.length)}  '
      'height=${heightCm ?? '-'}  gravity=${gravityUpCamera != null}  name=${wearerName?.isNotEmpty == true}',
      tag: _tag,
    );
    try {
      final uri = Uri.parse('$_baseUrl/$path');
      final request = http.MultipartRequest('POST', uri)
        ..fields['uniform_type'] = uniformType
        ..fields['rank_tier'] = rankTier
        ..fields['gender'] = gender
        ..fields['is_sikh'] = isSikh.toString()
        ..fields['medal_row_count'] = medalRowCount.toString()
        ..fields['body_type'] = bodyType
        ..fields['include_debug_image'] = includeDebugImage.toString();
      if (wearerName != null && wearerName.trim().isNotEmpty) {
        request.fields['wearer_name'] = wearerName.trim();
      }
      if (heightCm != null && heightCm > 0) {
        request.fields['height_cm'] = heightCm.toString();
      }
      if (gravityUpCamera != null && gravityUpCamera.length == 3) {
        request.fields['gravity_x'] = gravityUpCamera[0].toString();
        request.fields['gravity_y'] = gravityUpCamera[1].toString();
        request.fields['gravity_z'] = gravityUpCamera[2].toString();
      }
      for (var i = 0; i < photos.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          burst ? 'images' : 'image',
          photos[i],
          filename: 'frame_$i.jpg',
        ));
      }

      final streamed = await _client
          .send(request)
          .timeout(Duration(seconds: burst ? 180 : 90));
      final response = await http.Response.fromStream(streamed);
      // cv-service sends UTF-8 JSON without a charset parameter, and
      // `Response.body` then falls back to Latin-1 — which garbles every
      // "—" / "°" in the per-item instructions. Decode the bytes as UTF-8.
      final responseText = utf8.decode(response.bodyBytes, allowMalformed: true);

      if (response.statusCode != 200) {
        final body = _tryDecode(responseText);
        // The service returns its typed code under `status`
        // (`{"success": false, "status": "IMAGE_TOO_BLURRY", ...}`);
        // older/other handlers use `error`.
        final code = (body?['status'] ?? body?['error']) as String?;
        final message = body?['message'] as String? ??
            body?['detail'] as String? ??
            'http_${response.statusCode}';
        AppLog.e(
          'check: non-200  status=${response.statusCode}  code=$code',
          tag: _tag,
          error: message,
        );
        throw UniformCheckException(
          message,
          statusCode: response.statusCode,
          errorCode: code,
        );
      }

      final data = jsonDecode(responseText) as Map<String, dynamic>;
      final result = _parse(data);
      AppLog.i(
        'check: OK  status=${result.overallStatus}  score=${result.overallScore}  '
        'issues=${result.issues.length}  uncertain=${result.uncertain.length}',
        tag: _tag,
      );
      return result;
    } on UniformCheckException {
      rethrow;
    } catch (e, st) {
      AppLog.e('check: FAILED', tag: _tag, error: e, st: st);
      throw UniformCheckException('$_baseUrl — $e', statusCode: null);
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  UniformCheckResult _parse(Map<String, dynamic> data) {
    final imageQuality =
        Map<String, dynamic>.from(data['image_quality'] as Map? ?? const {});
    final person =
        Map<String, dynamic>.from(data['person'] as Map? ?? const {});
    final summary =
        Map<String, dynamic>.from(data['summary'] as Map? ?? const {});
    final coverage =
        Map<String, dynamic>.from(data['coverage'] as Map? ?? const {});
    final camera = Map<String, dynamic>.from(data['camera'] as Map? ?? const {});
    final burst = data['burst'] is Map ? Map<String, dynamic>.from(data['burst'] as Map) : null;

    return UniformCheckResult(
      success: data['success'] as bool? ?? false,
      overallStatus: data['overall_status'] as String? ?? 'FAIL',
      overallScore: (data['overall_score'] as num?)?.toDouble() ?? 0,
      imageQualityUsable: imageQuality['usable'] as bool? ?? false,
      imageQualityConfidence:
          (imageQuality['confidence'] as num?)?.toDouble() ?? 0,
      personDetected: person['detected'] as bool? ?? false,
      personConfidence: (person['confidence'] as num?)?.toDouble() ?? 0,
      accessories: (data['accessories'] as List<dynamic>? ?? const [])
          .map((raw) => _parseAccessory(Map<String, dynamic>.from(raw as Map)))
          .toList(growable: false),
      summary: UniformCheckSummary(
        detectedAccessories:
            (summary['detected_accessories'] as num?)?.toInt() ?? 0,
        correct: (summary['correct'] as num?)?.toInt() ?? 0,
        incorrect: (summary['incorrect'] as num?)?.toInt() ?? 0,
        slightlyMisaligned:
            (summary['slightly_misaligned'] as num?)?.toInt() ?? 0,
        missing: (summary['missing'] as num?)?.toInt() ?? 0,
        uncertain: (summary['uncertain'] as num?)?.toInt() ?? 0,
        requiredAccessories:
            (summary['required_accessories'] as num?)?.toInt() ?? 0,
      ),
      checkableRequired: (coverage['checkable_required'] as num?)?.toInt() ?? 0,
      verifiedRequired: (coverage['verified_required'] as num?)?.toInt() ?? 0,
      notCheckableRequired:
          (coverage['not_checkable_required'] as num?)?.toInt() ?? 0,
      debugImageBase64: data['debug_image_base64'] as String?,
      burstFrames: (burst?['frames'] as num?)?.toInt(),
      burstUsableFrames: (burst?['usable_frames'] as num?)?.toInt(),
      focalSource: camera['focal_source'] as String?,
    );
  }

  UniformCheckAccessory _parseAccessory(Map<String, dynamic> m) {
    return UniformCheckAccessory(
      name: m['name'] as String? ?? 'unknown',
      present: m['present'] as bool?,
      positionCorrect: m['position_correct'] as bool?,
      confidence: (m['confidence'] as num?)?.toDouble(),
      status: UniformCheckStatus.fromWireName(m['status'] as String? ?? ''),
      visibility: (m['visibility'] as String? ?? 'NONE').toUpperCase(),
      boundingBox: _parseBox(m['bounding_box']),
      expectedPosition: _parsePoint(m['expected_position']),
      detectedPosition: _parsePoint(m['detected_position']),
      error: _parsePoint(m['error']),
      doctrineRef: m['doctrine_ref'] as String? ?? '',
      message: m['message'] as String? ?? '',
      instruction: m['instruction'] as String? ?? '',
      required: m['required'] as bool? ?? false,
      checkable: m['checkable'] as bool? ?? true,
      detectionSource: m['detection_source'] as String?,
      frameAgreement: m['frame_agreement'] as String?,
    );
  }

  UniformCheckPoint? _parsePoint(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final x = (m['x'] as num?)?.toDouble();
    final y = (m['y'] as num?)?.toDouble();
    if (x == null || y == null) return null;
    return UniformCheckPoint(x: x, y: y);
  }

  UniformCheckBox? _parseBox(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final x = (m['x'] as num?)?.toDouble();
    final y = (m['y'] as num?)?.toDouble();
    final w = (m['width'] as num?)?.toDouble();
    final h = (m['height'] as num?)?.toDouble();
    if (x == null || y == null || w == null || h == null) return null;
    return UniformCheckBox(x: x, y: y, width: w, height: h);
  }
}

/// Thrown for any `/check_uniform` failure. `statusCode == null` means
/// the request never got a response — most likely `cv-service` isn't
/// reachable (not running / wrong `CV_SERVICE_BASE_URL` / device can't
/// route to the host). A non-null [errorCode] is the service's own
/// typed code (`NO_PERSON_DETECTED`, `POSE_UNRELIABLE`,
/// `SCALE_UNAVAILABLE`, `SEGMENTER_UNAVAILABLE`, `UNSUPPORTED_UNIFORM`,
/// the image-quality codes, …).
class UniformCheckException implements Exception {
  UniformCheckException(this.message, {this.statusCode, this.errorCode});

  final String message;
  final int? statusCode;
  final String? errorCode;

  @override
  String toString() =>
      'UniformCheckException($statusCode${errorCode == null ? '' : ' $errorCode'}: $message)';
}

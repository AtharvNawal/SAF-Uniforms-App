import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/utils/app_logger.dart';
import '../domain/entities/cv_inspection_result.dart';

const String _tag = 'arScanner.cvService';

/// Base URL for the `cv-service` FastAPI app (`cv-service/api/main.py`),
/// used by both `POST /inspect` and `POST /check_uniform`.
///
/// **Local dev only** — `cv-service` has no Cloud Run deployment (see
/// `cv-service/README.md`), so this points at a service the developer
/// runs themselves via `uvicorn --host 0.0.0.0 --port 8001`.
///
/// The default is this dev machine's LAN IP so a plain
/// `flutter build apk` produces an APK a physical phone (on the same
/// Wi-Fi, with the Mac running `deploy/run-cv-service-local.sh`) can
/// reach with no extra flags. When the Mac's IP changes, edit the line
/// below (find it with `ipconfig getifaddr en0`) and rebuild — or
/// override without editing:
///   - this phone, new IP:  `--dart-define=CV_SERVICE_BASE_URL=http://<ip>:8001`
///   - iOS simulator:       `--dart-define=CV_SERVICE_BASE_URL=http://localhost:8001`
///   - Android emulator:    `--dart-define=CV_SERVICE_BASE_URL=http://10.0.2.2:8001`
/// (Android cleartext to any host is already allowed for dev builds —
/// see `android/app/src/main/res/xml/network_security_config.xml`.)
const String kCvServiceBaseUrl = String.fromEnvironment(
  'CV_SERVICE_BASE_URL',
  defaultValue: 'http://192.168.1.144:8001',
);

/// Client-side wrapper around `cv-service`'s `POST /inspect` — the
/// Phase-2 pipeline (real human detection + pose estimation + PnP
/// camera-pose recovery + rule-engine geometry, with a vision-language
/// stand-in for the not-yet-trained accessory detector; see
/// `cv-service/README.md`). This is a parallel path to
/// [UniformComplianceRepository] (Phase 1, the shipped Node/Claude
/// flow), not a replacement — nothing here is wired into the default
/// capture flow.
class CvServiceInspectionRepository {
  CvServiceInspectionRepository({
    required http.Client client,
    String baseUrl = kCvServiceBaseUrl,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<CvInspectionResult> inspect({
    required Uint8List photoBytes,
    required String rankTier,
    String gender = 'male',
    bool isSikh = false,
    int medalRowCount = 0,
    String filename = 'photo.jpg',
  }) async {
    AppLog.i(
      'inspect: calling cv-service /inspect  rank=$rankTier  bytes=${photoBytes.length}',
      tag: _tag,
    );
    try {
      final uri = Uri.parse('$_baseUrl/inspect');
      final request = http.MultipartRequest('POST', uri)
        ..fields['rank_tier'] = rankTier
        ..fields['gender'] = gender
        ..fields['is_sikh'] = isSikh.toString()
        ..fields['medal_row_count'] = medalRowCount.toString()
        ..files.add(
          http.MultipartFile.fromBytes('photo', photoBytes, filename: filename),
        );

      final streamed = await _client.send(request).timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        final body = _tryDecode(response.body);
        final error = body?['error'] as String? ?? 'http_${response.statusCode}';
        AppLog.e(
          'inspect: non-200  status=${response.statusCode}  error=$error',
          tag: _tag,
          error: error,
        );
        throw CvServiceInspectionException(error, statusCode: response.statusCode);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = _parseResult(data);
      AppLog.i(
        'inspect: OK  score=${result.overallScore}  status=${result.status}  '
        'issues=${result.issues.length}  uncertain=${result.uncertain.length}',
        tag: _tag,
      );
      return result;
    } on CvServiceInspectionException {
      rethrow;
    } catch (e, st) {
      AppLog.e('inspect: FAILED', tag: _tag, error: e, st: st);
      rethrow;
    }
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  CvInspectionResult _parseResult(Map<String, dynamic> data) {
    final subscoresRaw = Map<String, dynamic>.from(
      data['subscores'] as Map? ?? {},
    );
    final camRaw = Map<String, dynamic>.from(
      data['camera_diagnostics'] as Map? ?? {},
    );

    return CvInspectionResult(
      overallScore: (data['overall_score'] as num).toDouble(),
      status: data['status'] as String,
      subscores: CvSubscores(
        headwear: (subscoresRaw['headwear'] as num?)?.toDouble(),
        chest: (subscoresRaw['chest'] as num?)?.toDouble(),
        collar: (subscoresRaw['collar'] as num?)?.toDouble(),
        sleeves: (subscoresRaw['sleeves'] as num?)?.toDouble(),
        waist: (subscoresRaw['waist'] as num?)?.toDouble(),
        lowerBody: (subscoresRaw['lower_body'] as num?)?.toDouble(),
        footwear: (subscoresRaw['footwear'] as num?)?.toDouble(),
        appearance: (subscoresRaw['appearance'] as num?)?.toDouble(),
      ),
      issues: (data['issues'] as List<dynamic>? ?? [])
          .map((raw) {
            final m = Map<String, dynamic>.from(raw as Map);
            return CvIssue(
              item: m['item'] as String,
              category: m['category'] as String? ?? '',
              problem: CvVerdict.fromWireName(m['problem'] as String),
              severity: m['severity'] as String? ?? 'Medium',
              confidence: (m['confidence'] as num).toDouble(),
              doctrineRef: m['doctrine_ref'] as String? ?? '',
              note: m['note'] as String? ?? '',
              bbox: (m['bbox'] as List<dynamic>? ?? [])
                  .map((box) => (box as List<dynamic>)
                      .map((v) => (v as num).toDouble())
                      .toList(growable: false))
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
      uncertain: (data['uncertain'] as List<dynamic>? ?? [])
          .map((raw) {
            final m = Map<String, dynamic>.from(raw as Map);
            return CvUncertainItem(
              item: m['item'] as String,
              reason: m['reason'] as String? ?? '',
              confidence: (m['confidence'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      itemsEvaluated: (data['items_evaluated'] as num?)?.toInt() ?? 0,
      cameraDiagnostics: CvCameraDiagnostics(
        reprojectionErrorPx: (camRaw['reprojection_error_px'] as num?)?.toDouble() ?? 0,
        correspondenceCount: (camRaw['correspondence_count'] as num?)?.toInt() ?? 0,
        cmPerPx: (camRaw['cm_per_px'] as num?)?.toDouble() ?? 0,
      ),
      geometricVerdicts: (data['geometric_verdicts'] as List<dynamic>? ?? [])
          .map((raw) {
            final m = Map<String, dynamic>.from(raw as Map);
            return GeometricVerdict(
              accessory: m['accessory'] as String,
              status: GeometricVerdictStatus.fromWireName(m['status'] as String),
              reason: m['reason'] as String? ?? '',
              doctrineRef: m['doctrine_ref'] as String? ?? '',
            );
          })
          .toList(growable: false),
      annotatedImageBase64: data['annotated_image_base64'] as String?,
    );
  }
}

class CvServiceInspectionException implements Exception {
  CvServiceInspectionException(this.reason, {this.statusCode});

  final String reason;
  final int? statusCode;

  @override
  String toString() => 'CvServiceInspectionException($statusCode: $reason)';
}

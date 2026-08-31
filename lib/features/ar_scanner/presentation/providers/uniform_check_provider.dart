import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../data/uniform_check_repository.dart';
import '../../domain/entities/uniform_check_result.dart';

part 'uniform_check_provider.g.dart';

const String _tag = 'arScanner.uniformCheck.ctl';

@Riverpod(keepAlive: true)
UniformCheckRepository uniformCheckRepository(Ref ref) {
  return UniformCheckRepository(client: http.Client());
}

/// Drives a single real (geometry/pixel) uniform check from
/// `ARScannerScreen`'s default capture button, via `cv-service`'s
/// `POST /check_uniform`. State is `AsyncValue<UniformCheckResult?>`:
/// `null` = no check has run yet, non-null = latest result. Nothing is
/// persisted — a fresh screen visit starts at `null` again.
///
/// This is the default capture path now (replacing the old fabricated
/// "100% match" stand-in). The Phase-1 Node/Anthropic
/// `checkUniformCompliance` path stays disabled — see
/// `ar_scanner_screen.dart` `_capture` and
/// `ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md`.
@riverpod
class UniformCheckController extends _$UniformCheckController {
  @override
  Future<UniformCheckResult?> build() async => null;

  Future<void> check({
    required Uint8List photoBytes,
    required String uniformType,
    required String rankTier,
    String gender = 'male',
    bool isSikh = false,
    int medalRowCount = 0,
    String bodyType = 'male',
  }) async {
    AppLog.i('check: start  uniform=$uniformType  rank=$rankTier', tag: _tag);
    state = const AsyncLoading<UniformCheckResult?>();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(uniformCheckRepositoryProvider);
      final result = await repo.check(
        photoBytes: photoBytes,
        uniformType: uniformType,
        rankTier: rankTier,
        gender: gender,
        isSikh: isSikh,
        medalRowCount: medalRowCount,
        bodyType: bodyType,
      );
      AppLog.i(
        'check: done  status=${result.overallStatus}  score=${result.overallScore}',
        tag: _tag,
      );
      return result;
    });
    if (state.hasError) {
      AppLog.e('check: failed', tag: _tag, error: state.error);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

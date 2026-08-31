import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../data/cv_service_inspection_repository.dart';
import '../../domain/entities/cv_inspection_result.dart';

part 'cv_service_inspection_provider.g.dart';

const String _tag = 'arScanner.cvService.ctl';

@Riverpod(keepAlive: true)
CvServiceInspectionRepository cvServiceInspectionRepository(Ref ref) {
  return CvServiceInspectionRepository(client: http.Client());
}

/// Drives a single Phase-2 `cv-service` inspection. Same shape as
/// `UniformComplianceController` (Phase 1) deliberately — state is
/// `AsyncValue<CvInspectionResult?>`, `null` means no check has run
/// yet, nothing is persisted. Kept as a fully separate controller
/// rather than merged into the Phase-1 one, since the two backends
/// return different report shapes and `cv-service` is dev-only today
/// (see `CvServiceInspectionRepository`'s `kCvServiceBaseUrl` doc).
@riverpod
class CvServiceInspectionController extends _$CvServiceInspectionController {
  @override
  Future<CvInspectionResult?> build() async => null;

  Future<void> inspect({
    required Uint8List photoBytes,
    required String rankTier,
    String gender = 'male',
    bool isSikh = false,
    int medalRowCount = 0,
  }) async {
    AppLog.i('inspect: start  rank=$rankTier', tag: _tag);
    state = const AsyncLoading<CvInspectionResult?>();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(cvServiceInspectionRepositoryProvider);
      final result = await repo.inspect(
        photoBytes: photoBytes,
        rankTier: rankTier,
        gender: gender,
        isSikh: isSikh,
        medalRowCount: medalRowCount,
      );
      AppLog.i(
        'inspect: done  score=${result.overallScore}  status=${result.status}',
        tag: _tag,
      );
      return result;
    });
    if (state.hasError) {
      AppLog.e('inspect: failed', tag: _tag, error: state.error);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

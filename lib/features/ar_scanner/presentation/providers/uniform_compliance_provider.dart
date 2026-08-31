// import 'dart:typed_data';

// import 'package:riverpod_annotation/riverpod_annotation.dart';

// import '../../../../core/utils/app_logger.dart';
// import '../../../auth/presentation/providers/auth_providers.dart';
// import '../../../profile/domain/entities/dress_code.dart';
// import '../../data/uniform_compliance_repository.dart';
// import '../../domain/entities/compliance_result.dart';

// part 'uniform_compliance_provider.g.dart';

// const String _tag = 'arScanner.compliance.ctl';

// @Riverpod(keepAlive: true)
// UniformComplianceRepository uniformComplianceRepository(Ref ref) {
//   return UniformComplianceRepository(
//     functions: ref.watch(firebaseFunctionsProvider),
//   );
// }

// /// Drives a single AI-vision compliance check from `ARScannerScreen`.
// /// State is `AsyncValue<ComplianceResult?>`: `null` data means no check
// /// has run yet; a non-null value is the most recent result. Nothing
// /// here is persisted — a fresh screen visit starts with `null` again.
// @riverpod
// class UniformComplianceController extends _$UniformComplianceController {
//   @override
//   Future<ComplianceResult?> build() async => null;

//   Future<void> check({
//     required DressCode dressCode,
//     required Uint8List photoBytes,
//   }) async {
//     AppLog.i('check: start  dress=${dressCode.wireName}', tag: _tag);
//     state = const AsyncLoading<ComplianceResult?>();
//     state = await AsyncValue.guard(() async {
//       final repo = ref.read(uniformComplianceRepositoryProvider);
//       final result = await repo.check(
//         dressCode: dressCode,
//         photoBytes: photoBytes,
//       );
//       AppLog.i('check: done  score=${result.overallScore}', tag: _tag);
//       return result;
//     });
//     if (state.hasError) {
//       AppLog.e('check: failed', tag: _tag, error: state.error);
//     }
//   }

//   /// Clears the result so the screen can go back to the capture phase.
//   void reset() {
//     state = const AsyncData(null);
//   }
// }

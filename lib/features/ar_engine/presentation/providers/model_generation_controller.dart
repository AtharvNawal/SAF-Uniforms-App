import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../../data/profile_hash.dart';
import 'generated_dress_provider.dart';

part 'model_generation_controller.g.dart';

const String _tag = 'ar.modelGen.ctl';

/// Imperative side of 3D model generation: triggers the
/// `composeUniformModel` Cloud Function and writes optimistic
/// in-flight state to the local profile so the UI reacts
/// immediately.
///
/// The actual `modelUrl` and authoritative `profileHash` are written
/// to Firestore by the Cloud Function; this notifier doesn't update
/// them locally — it relies on the existing profile-stream hydrate to
/// do that automatically.
@Riverpod(keepAlive: true)
class ModelGenerationController extends _$ModelGenerationController {
  @override
  void build() {
    // Stateless controller — all visible state lives on `UniformProfile`
    // via `generatedDresses`. This notifier is just a verb surface.
  }

  /// Fires `composeUniformModel` for the given dress. No-op (and not
  /// an error) if the model is already up-to-date or a generation is
  /// already in flight.
  Future<void> generate(DressCode dress) async {
    final profile = ref.read(uniformProfileProvider);
    final expectedHash = computeProfileHash(profile, dress);
    final existing = profile.generatedDresses[dress.requirementDocId];

    if (existing != null &&
        existing.profileHash == expectedHash &&
        existing.modelUrl != null) {
      AppLog.d(
        'generate: skip — already up to date  '
        'dress=${dress.wireName}  hash=$expectedHash',
        tag: _tag,
      );
      return;
    }

    if (existing?.generationStartedAt != null && existing?.modelUrl == null) {
      // Already generating — let the in-flight call finish. (Cheap
      // safety net; the CF itself is also idempotent on the server.)
      AppLog.d(
        'generate: skip — generation already in flight  '
        'dress=${dress.wireName}',
        tag: _tag,
      );
      return;
    }

    AppLog.i(
      'generate: dress=${dress.wireName}  hash=$expectedHash',
      tag: _tag,
    );

    // Optimistic flag so the UI swaps to a "generating" state right
    // away without waiting for the round-trip.
    ref
        .read(uniformProfileProvider.notifier)
        .markGenerationStarted(dress);

    try {
      final repo = ref.read(modelGenerationRepositoryProvider);
      await repo.compose(dressCode: dress, profileHash: expectedHash);
      // The CF wrote the new modelUrl + profileHash to Firestore;
      // the hydrated-profile stream will fold them into local state.
      AppLog.i(
        'generate: dispatched OK — Firestore stream will update state',
        tag: _tag,
      );
    } catch (e, st) {
      AppLog.e(
        'generate: FAILED  dress=${dress.wireName}',
        tag: _tag,
        error: e,
        st: st,
      );
      ref
          .read(uniformProfileProvider.notifier)
          .markGenerationFailed(dress, e.toString());
      rethrow;
    }
  }

  /// Convenience for "wait if needed; otherwise refresh in the
  /// background". UI uses this on `GhostScreen` mount: ready models
  /// render immediately, stale ones render the cached model and quietly
  /// regenerate, missing ones go through the await path.
  Future<void> ensureFresh(DressCode dress) async {
    final status = ref.read(modelStatusProvider(dress));
    switch (status) {
      case ModelStatus.ready:
      case ModelStatus.generating:
        return;
      case ModelStatus.stale:
        // ignore: discarded_futures
        generate(dress);
        return;
      case ModelStatus.needsGeneration:
      case ModelStatus.failed:
        await generate(dress);
        return;
    }
  }
}

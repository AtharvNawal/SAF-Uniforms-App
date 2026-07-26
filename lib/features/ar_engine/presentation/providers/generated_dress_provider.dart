import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/domain/entities/generated_dress.dart';
import '../../data/model_generation_repository.dart';
import '../../data/profile_hash.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';

part 'generated_dress_provider.g.dart';

/// Wraps the `composeUniformModel` callable so consumers can inject
/// the `FirebaseFunctions` instance via Riverpod overrides in tests.
@Riverpod(keepAlive: true)
ModelGenerationRepository modelGenerationRepository(Ref ref) {
  return ModelGenerationRepository(
    functions: ref.watch(firebaseFunctionsProvider),
  );
}

/// Reactive view of the current `GeneratedDress` for [dress] derived
/// from the live `UniformProfile`. Returns `null` when nothing has
/// been generated yet for that dress code.
@Riverpod(keepAlive: true)
GeneratedDress? generatedDress(Ref ref, DressCode dress) {
  final profile = ref.watch(uniformProfileProvider);
  return profile.generatedDresses[dress.requirementDocId];
}

/// Status of the 3D model for the active dress, viewed from the
/// client side. Drives the GhostScreen's loading / generate / ready
/// states.
enum ModelStatus {
  /// No model has ever been generated for this dress code, and no
  /// generation is currently in flight. UI should offer a CTA.
  needsGeneration,

  /// A generation is currently running (either just-fired by this
  /// client or kicked off elsewhere — `generationStartedAt` is set
  /// on the entry).
  generating,

  /// The cached `modelUrl` is valid for the current profile.
  ready,

  /// We have a cached `modelUrl` but the profile fields it was
  /// generated against have since changed. UI should kick off a
  /// background regeneration while still showing the stale model.
  stale,

  /// Last generation failed; UI should show the error and offer a
  /// retry.
  failed,
}

/// Folds [GeneratedDress] + freshly-computed [computeProfileHash]
/// into a single status the UI can switch on. Treats a missing
/// entry as `needsGeneration` and an entry whose `profileHash`
/// matches the current profile as `ready`.
@Riverpod(keepAlive: true)
ModelStatus modelStatus(Ref ref, DressCode dress) {
  final profile = ref.watch(uniformProfileProvider);
  final entry = ref.watch(generatedDressProvider(dress));
  if (entry == null) return ModelStatus.needsGeneration;
  if (entry.error != null && entry.modelUrl == null) {
    return ModelStatus.failed;
  }
  if (entry.generationStartedAt != null && entry.modelUrl == null) {
    return ModelStatus.generating;
  }
  if (entry.modelUrl == null) return ModelStatus.needsGeneration;
  final expected = computeProfileHash(profile, dress);
  if (entry.profileHash != expected) return ModelStatus.stale;
  return ModelStatus.ready;
}

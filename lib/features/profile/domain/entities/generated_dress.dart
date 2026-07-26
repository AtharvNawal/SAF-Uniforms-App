import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated_dress.freezed.dart';

/// State of the per-user 3D model for a single dress code.
///
/// Populated by the `composeUniformModel` Cloud Function: when a profile
/// change invalidates the previously composed GLB, the CF re-merges the
/// body / uniform / accessory GLBs from the asset library, uploads the
/// result to `user_models/{uid}/{dressCode}.glb`, and writes this entry
/// back to `users/{uid}/profile/current.generatedDresses[<dressDocId>]`.
///
/// The client uses [profileHash] to know whether the cached [modelUrl]
/// is still valid for the current [UniformProfile]: a mismatch triggers
/// a regeneration call.
@freezed
abstract class GeneratedDress with _$GeneratedDress {
  const factory GeneratedDress({
    required DateTime builtAt,

    /// Firebase Storage download URL for the composed GLB. Null while
    /// the very first generation is in flight.
    String? modelUrl,

    /// First 16 hex chars of the sha256 over the profile fields that
    /// affect what the model looks like (branch, rank, gender, dress
    /// code, isSikh, fullName, vocation, medalRowCount, sorted badge /
    /// accessory IDs, dress checks, plus the bundle version constant).
    /// See [profile_hash.dart](../../../ar_engine/data/profile_hash.dart).
    String? profileHash,

    /// Bumps when the composition logic itself changes (asset layout,
    /// socket bone names, compression settings). Forces a regeneration
    /// for everyone even if the profile hash hasn't changed.
    int? schemaVersion,

    /// Set optimistically by the client the moment the regeneration
    /// callable fires. The CF clears it on success.
    DateTime? generationStartedAt,

    /// Last failure reason — kept for one cycle so the UI can surface
    /// it. Cleared on the next successful generation.
    String? error,
  }) = _GeneratedDress;
}

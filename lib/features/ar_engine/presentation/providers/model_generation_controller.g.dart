// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_generation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Imperative side of 3D model generation: triggers the
/// `composeUniformModel` Cloud Function and writes optimistic
/// in-flight state to the local profile so the UI reacts
/// immediately.
///
/// The actual `modelUrl` and authoritative `profileHash` are written
/// to Firestore by the Cloud Function; this notifier doesn't update
/// them locally — it relies on the existing profile-stream hydrate to
/// do that automatically.

@ProviderFor(ModelGenerationController)
final modelGenerationControllerProvider = ModelGenerationControllerProvider._();

/// Imperative side of 3D model generation: triggers the
/// `composeUniformModel` Cloud Function and writes optimistic
/// in-flight state to the local profile so the UI reacts
/// immediately.
///
/// The actual `modelUrl` and authoritative `profileHash` are written
/// to Firestore by the Cloud Function; this notifier doesn't update
/// them locally — it relies on the existing profile-stream hydrate to
/// do that automatically.
final class ModelGenerationControllerProvider
    extends $NotifierProvider<ModelGenerationController, void> {
  /// Imperative side of 3D model generation: triggers the
  /// `composeUniformModel` Cloud Function and writes optimistic
  /// in-flight state to the local profile so the UI reacts
  /// immediately.
  ///
  /// The actual `modelUrl` and authoritative `profileHash` are written
  /// to Firestore by the Cloud Function; this notifier doesn't update
  /// them locally — it relies on the existing profile-stream hydrate to
  /// do that automatically.
  ModelGenerationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelGenerationControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelGenerationControllerHash();

  @$internal
  @override
  ModelGenerationController create() => ModelGenerationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$modelGenerationControllerHash() =>
    r'ba28b70b36cbb6208e240823dc2792f1c4f36886';

/// Imperative side of 3D model generation: triggers the
/// `composeUniformModel` Cloud Function and writes optimistic
/// in-flight state to the local profile so the UI reacts
/// immediately.
///
/// The actual `modelUrl` and authoritative `profileHash` are written
/// to Firestore by the Cloud Function; this notifier doesn't update
/// them locally — it relies on the existing profile-stream hydrate to
/// do that automatically.

abstract class _$ModelGenerationController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

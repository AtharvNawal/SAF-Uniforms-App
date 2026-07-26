// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uniform_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the global state of the user's current uniform profile:
/// branch, rank, gender, dress code, Sikh status, and selected accessories.
///
/// Every setter schedules a debounced Firestore upsert (see
/// [_scheduleSync]). Callers that need a guaranteed write (e.g. the
/// Configuration wizard's "Done" step) must `await` [persist] instead.

@ProviderFor(UniformProfileNotifier)
final uniformProfileProvider = UniformProfileNotifierProvider._();

/// Manages the global state of the user's current uniform profile:
/// branch, rank, gender, dress code, Sikh status, and selected accessories.
///
/// Every setter schedules a debounced Firestore upsert (see
/// [_scheduleSync]). Callers that need a guaranteed write (e.g. the
/// Configuration wizard's "Done" step) must `await` [persist] instead.
final class UniformProfileNotifierProvider
    extends $NotifierProvider<UniformProfileNotifier, UniformProfile> {
  /// Manages the global state of the user's current uniform profile:
  /// branch, rank, gender, dress code, Sikh status, and selected accessories.
  ///
  /// Every setter schedules a debounced Firestore upsert (see
  /// [_scheduleSync]). Callers that need a guaranteed write (e.g. the
  /// Configuration wizard's "Done" step) must `await` [persist] instead.
  UniformProfileNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uniformProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uniformProfileNotifierHash();

  @$internal
  @override
  UniformProfileNotifier create() => UniformProfileNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UniformProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UniformProfile>(value),
    );
  }
}

String _$uniformProfileNotifierHash() =>
    r'4b09cb5c643b8594fa8b122f8f197cccb637b54b';

/// Manages the global state of the user's current uniform profile:
/// branch, rank, gender, dress code, Sikh status, and selected accessories.
///
/// Every setter schedules a debounced Firestore upsert (see
/// [_scheduleSync]). Callers that need a guaranteed write (e.g. the
/// Configuration wizard's "Done" step) must `await` [persist] instead.

abstract class _$UniformProfileNotifier extends $Notifier<UniformProfile> {
  UniformProfile build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UniformProfile, UniformProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UniformProfile, UniformProfile>,
              UniformProfile,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The selected branch, exposed for theme + AR plumbing.

@ProviderFor(currentBranch)
final currentBranchProvider = CurrentBranchProvider._();

/// The selected branch, exposed for theme + AR plumbing.

final class CurrentBranchProvider
    extends $FunctionalProvider<BranchId, BranchId, BranchId>
    with $Provider<BranchId> {
  /// The selected branch, exposed for theme + AR plumbing.
  CurrentBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentBranchProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentBranchHash();

  @$internal
  @override
  $ProviderElement<BranchId> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BranchId create(Ref ref) {
    return currentBranch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BranchId value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BranchId>(value),
    );
  }
}

String _$currentBranchHash() => r'b72bdedcca1d50f15cd6c9a47a32f16e756c55d0';

@ProviderFor(_profileRepository)
final _profileRepositoryProvider = _ProfileRepositoryProvider._();

final class _ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  _ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return _profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$_profileRepositoryHash() =>
    r'6d6915b5291614bd249f1586ef9a4abf3f3a76c9';

/// One-shot hydration: when an auth session lands and we don't yet
/// have a profile loaded, fetch the persisted profile and seed
/// [UniformProfileNotifier]. Listened to in `app.dart`.

@ProviderFor(hydratedProfile)
final hydratedProfileProvider = HydratedProfileProvider._();

/// One-shot hydration: when an auth session lands and we don't yet
/// have a profile loaded, fetch the persisted profile and seed
/// [UniformProfileNotifier]. Listened to in `app.dart`.

final class HydratedProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UniformProfile?>,
          UniformProfile?,
          Stream<UniformProfile?>
        >
    with $FutureModifier<UniformProfile?>, $StreamProvider<UniformProfile?> {
  /// One-shot hydration: when an auth session lands and we don't yet
  /// have a profile loaded, fetch the persisted profile and seed
  /// [UniformProfileNotifier]. Listened to in `app.dart`.
  HydratedProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hydratedProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hydratedProfileHash();

  @$internal
  @override
  $StreamProviderElement<UniformProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UniformProfile?> create(Ref ref) {
    return hydratedProfile(ref);
  }
}

String _$hydratedProfileHash() => r'f413c31685afb5909e6b4a32cc8eda7de3e9649a';

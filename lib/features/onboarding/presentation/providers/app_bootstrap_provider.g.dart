// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_bootstrap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the full app startup pipeline. Runs once (keepAlive) and is
/// driven by the Welcome screen via `ref.watch`.
///
/// Steps:
///   1. `Firebase.initializeApp()` (idempotent).
///   2. Resolve the keychain-persisted `deviceId` UUID.
///   3. Read the cached `uid` + `profileComplete` from local storage
///      and seed `authSessionProvider` so the router's deep-link
///      guards relax immediately.
///   4. Call `claimDeviceIdentity` → `signInWithCustomToken` → write
///      back the freshest local-storage values → push the live
///      session into `authSessionProvider`. Bounded by
///      [_liveAuthTimeout]; on failure or timeout the cached session
///      stays in place and the pipeline still returns a useful
///      outcome.
///   5. Pick a [BootstrapOutcome] from whichever session is live.
///
/// Firebase init failure is treated as fatal — the future completes
/// with an error so Welcome can fall back to the CTA.

@ProviderFor(appBootstrap)
final appBootstrapProvider = AppBootstrapProvider._();

/// Owns the full app startup pipeline. Runs once (keepAlive) and is
/// driven by the Welcome screen via `ref.watch`.
///
/// Steps:
///   1. `Firebase.initializeApp()` (idempotent).
///   2. Resolve the keychain-persisted `deviceId` UUID.
///   3. Read the cached `uid` + `profileComplete` from local storage
///      and seed `authSessionProvider` so the router's deep-link
///      guards relax immediately.
///   4. Call `claimDeviceIdentity` → `signInWithCustomToken` → write
///      back the freshest local-storage values → push the live
///      session into `authSessionProvider`. Bounded by
///      [_liveAuthTimeout]; on failure or timeout the cached session
///      stays in place and the pipeline still returns a useful
///      outcome.
///   5. Pick a [BootstrapOutcome] from whichever session is live.
///
/// Firebase init failure is treated as fatal — the future completes
/// with an error so Welcome can fall back to the CTA.

final class AppBootstrapProvider
    extends
        $FunctionalProvider<
          AsyncValue<BootstrapOutcome>,
          BootstrapOutcome,
          FutureOr<BootstrapOutcome>
        >
    with $FutureModifier<BootstrapOutcome>, $FutureProvider<BootstrapOutcome> {
  /// Owns the full app startup pipeline. Runs once (keepAlive) and is
  /// driven by the Welcome screen via `ref.watch`.
  ///
  /// Steps:
  ///   1. `Firebase.initializeApp()` (idempotent).
  ///   2. Resolve the keychain-persisted `deviceId` UUID.
  ///   3. Read the cached `uid` + `profileComplete` from local storage
  ///      and seed `authSessionProvider` so the router's deep-link
  ///      guards relax immediately.
  ///   4. Call `claimDeviceIdentity` → `signInWithCustomToken` → write
  ///      back the freshest local-storage values → push the live
  ///      session into `authSessionProvider`. Bounded by
  ///      [_liveAuthTimeout]; on failure or timeout the cached session
  ///      stays in place and the pipeline still returns a useful
  ///      outcome.
  ///   5. Pick a [BootstrapOutcome] from whichever session is live.
  ///
  /// Firebase init failure is treated as fatal — the future completes
  /// with an error so Welcome can fall back to the CTA.
  AppBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appBootstrapHash();

  @$internal
  @override
  $FutureProviderElement<BootstrapOutcome> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BootstrapOutcome> create(Ref ref) {
    return appBootstrap(ref);
  }
}

String _$appBootstrapHash() => r'043c061758b73a1a2660e6def6b4dc66b06e97b6';

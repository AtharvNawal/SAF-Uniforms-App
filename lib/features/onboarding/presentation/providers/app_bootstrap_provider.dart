import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../firebase_options.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/device_identity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

part 'app_bootstrap_provider.g.dart';

const String _tag = 'app_bootstrap';

/// Hard cap on the live `claimDeviceIdentity` + `signInWithCustomToken`
/// round-trip. Past this, the bootstrap pipeline returns whatever
/// session it managed to establish (cached or none) so the Welcome
/// screen never hangs on a flaky network.
const Duration _liveAuthTimeout = Duration(seconds: 8);

/// Outcome the Welcome screen needs to decide what to do once the
/// bootstrap pipeline finishes.
enum BootstrapOutcome {
  /// Returning user with a completed profile — Welcome auto-routes
  /// to `/dashboard`.
  returningUser,

  /// Brand-new user, returning user with `profileComplete == false`,
  /// or auth-failed-without-cached-session — Welcome reveals the
  /// "Get Started" CTA, which navigates to `/config`.
  newUser,
}

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
@Riverpod(keepAlive: true)
Future<BootstrapOutcome> appBootstrap(Ref ref) async {
  AppLog.i('appBootstrap: START', tag: _tag);
  try {
    await _initFirebase();
    final identity = await _resolveIdentity(ref);
    final cachedSession = await _seedCachedSession(ref, identity);

    if (cachedSession != null && cachedSession.profileComplete) {
      // Returning user — navigation decision is already known from the cache.
      // Run live auth in the background to refresh the session without blocking.
      AppLog.i(
        'appBootstrap: returning user detected from cache — backgrounding live auth',
        tag: _tag,
      );
      unawaited(_runLiveAuth(ref, identity));
      AppLog.i('appBootstrap: DONE  outcome=returningUser (fast path)', tag: _tag);
      return BootstrapOutcome.returningUser;
    }

    await _runLiveAuth(ref, identity);
    final outcome = _pickOutcome(ref, cachedSession);
    AppLog.i('appBootstrap: DONE  outcome=$outcome', tag: _tag);
    return outcome;
  } catch (e, st) {
    AppLog.e('appBootstrap: FAILED', tag: _tag, error: e, st: st);
    rethrow;
  }
}

Future<void> _initFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    AppLog.d(
      'firebase already initialized (${Firebase.apps.length} app) — skipping',
      tag: _tag,
    );
    return;
  }
  AppLog.i('initializing Firebase...', tag: _tag);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLog.i('Firebase initialized', tag: _tag);
  } catch (e, st) {
    AppLog.e('Firebase.initializeApp failed', tag: _tag, error: e, st: st);
    rethrow;
  }
}

Future<DeviceIdentity> _resolveIdentity(Ref ref) async {
  AppLog.d('resolving deviceId...', tag: _tag);
  try {
    final identity = await ref.read(deviceIdentityServiceProvider).resolve();
    AppLog.d('deviceId=${identity.deviceId}', tag: _tag);
    return identity;
  } catch (e, st) {
    AppLog.e('resolveIdentity failed', tag: _tag, error: e, st: st);
    rethrow;
  }
}

/// Reads the cached uid + profileComplete and pushes a session into
/// `authSessionProvider` so the router can branch immediately. Returns
/// the cached session (or null) so the caller can fall back to it if
/// the live round-trip times out.
Future<AuthSession?> _seedCachedSession(
  Ref ref,
  DeviceIdentity identity,
) async {
  try {
    final storage = ref.read(localStorageServiceProvider);
    final cachedUid = await storage.readCachedUid();
    final cachedProfileComplete = await storage.readProfileComplete();
    if (cachedUid == null) {
      AppLog.i(
        'no cached session — fresh install or cleared storage',
        tag: _tag,
      );
      return null;
    }
    final session = AuthSession(
      uid: cachedUid,
      deviceId: identity.deviceId,
      profileComplete: cachedProfileComplete,
    );
    AppLog.i(
      'seeding cached session  uid=${session.uid}  '
      'profileComplete=${session.profileComplete}',
      tag: _tag,
    );
    ref.read(authSessionProvider.notifier).set(session);
    return session;
  } catch (e, st) {
    AppLog.e('seedCachedSession failed', tag: _tag, error: e, st: st);
    return null;
  }
}

/// Runs `claimDeviceIdentity` + `signInWithCustomToken` and updates
/// local storage + `authSessionProvider` with the live session.
/// Bounded by [_liveAuthTimeout]. Failures and timeouts are caught
/// and logged — the cached session (if any) stays in place.
Future<void> _runLiveAuth(Ref ref, DeviceIdentity identity) async {
  AppLog.i(
    'STEP 1 — calling claimDeviceIdentity  '
    'deviceId=${identity.deviceId}  platform=${identity.platform}',
    tag: _tag,
  );
  try {
    await _runLiveAuthInner(ref, identity).timeout(_liveAuthTimeout);
  } on TimeoutException {
    AppLog.w(
      'live auth timed out after ${_liveAuthTimeout.inSeconds}s — '
      'falling back to cached session (if any)',
      tag: _tag,
    );
  } catch (e, st) {
    AppLog.e(
      'live auth FAILED — authSessionProvider stays at cached value (if any). '
      'If user is on config screen they will wait 30s then see Welcome.',
      tag: _tag,
      error: e,
      st: st,
    );
  }
}

Future<void> _runLiveAuthInner(Ref ref, DeviceIdentity identity) async {
  // Belt-and-braces: DeviceIdentityService already guarantees a
  // non-empty, non-Nil deviceId, but we double-check before sending
  // it across the wire. A Nil deviceId would cause the Cloud Function
  // to write `device_registrations/00000000-…` and orphan the real
  // registration; better to surface a hard error than to corrupt state.
  const nilUuid = '00000000-0000-0000-0000-000000000000';
  if (identity.deviceId.isEmpty || identity.deviceId == nilUuid) {
    throw StateError(
      'Refusing to call claimDeviceIdentity with invalid '
      'deviceId="${identity.deviceId}".',
    );
  }

  final registry = ref.read(deviceRegistryServiceProvider);
  final claim = await registry.claim(identity);
  AppLog.i(
    'STEP 1 OK  uid=${claim.uid}  profileComplete=${claim.profileComplete}',
    tag: _tag,
  );

  AppLog.i('STEP 2 — signInWithCustomToken  uid=${claim.uid}', tag: _tag);
  final repo = ref.read(authRepositoryProvider);
  final session = await repo.signInWithClaim(claim: claim, identity: identity);
  AppLog.i('STEP 2 OK  uid=${session.uid}', tag: _tag);

  AppLog.d('STEP 3 — writing local storage', tag: _tag);
  final storage = ref.read(localStorageServiceProvider);
  await storage.writeCachedUid(session.uid);
  await storage.writeProfileComplete(session.profileComplete);
  AppLog.d(
    'STEP 3 OK  profileComplete=${session.profileComplete}',
    tag: _tag,
  );

  AppLog.i('STEP 4 — setting authSessionProvider', tag: _tag);
  ref.read(authSessionProvider.notifier).set(session);
  AppLog.i('STEP 4 OK — authSession live  uid=${session.uid}', tag: _tag);
}

BootstrapOutcome _pickOutcome(Ref ref, AuthSession? cachedSession) {
  // Prefer the live session if it landed; otherwise fall back to the
  // cached one we seeded earlier.
  final session = ref.read(authSessionProvider) ?? cachedSession;
  if (session != null && session.profileComplete) {
    return BootstrapOutcome.returningUser;
  }
  return BootstrapOutcome.newUser;
}

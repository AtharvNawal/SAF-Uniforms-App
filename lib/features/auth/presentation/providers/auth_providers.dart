import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/persistence/local_storage_service.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/device_identity_service.dart';
import '../../data/device_registry_service.dart';
import '../../domain/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@Riverpod(keepAlive: true)
FirebaseFirestore firebaseFirestore(Ref ref) => FirebaseFirestore.instance;

// TRIAL ONLY — opt-in Cloud Functions emulator redirect, off by default
// (production behavior is unchanged unless explicitly enabled). Used to
// trial the profile-completeness bypass in
// `functions/src/checkUniformCompliance.ts` without deploying to the
// live project. Enable via:
//   flutter run --dart-define=USE_FUNCTIONS_EMULATOR=true \
//     --dart-define=FUNCTIONS_EMULATOR_HOST=10.0.2.2  (Android emulator)
//     --dart-define=FUNCTIONS_EMULATOR_HOST=localhost  (iOS simulator)
// Start the emulator first: `cd functions && npm run serve`. Port 5501
// (not the Firebase default 5001) — see firebase.json's `emulators`
// block; 5001 was already occupied by an unrelated local process.
const bool kUseFunctionsEmulator = bool.fromEnvironment(
  'USE_FUNCTIONS_EMULATOR',
);
const String kFunctionsEmulatorHost = String.fromEnvironment(
  'FUNCTIONS_EMULATOR_HOST',
  defaultValue: 'localhost',
);

@Riverpod(keepAlive: true)
FirebaseFunctions firebaseFunctions(Ref ref) {
  final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  if (kUseFunctionsEmulator) {
    functions.useFunctionsEmulator(kFunctionsEmulatorHost, 5501);
  }
  return functions;
}

@Riverpod(keepAlive: true)
LocalStorageService localStorageService(Ref ref) => LocalStorageService();

@Riverpod(keepAlive: true)
DeviceIdentityService deviceIdentityService(Ref ref) {
  return DeviceIdentityService(
    storage: ref.watch(localStorageServiceProvider),
  );
}

@Riverpod(keepAlive: true)
DeviceRegistryService deviceRegistryService(Ref ref) {
  return DeviceRegistryService(
    functions: ref.watch(firebaseFunctionsProvider),
  );
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

/// The active auth session.
///
/// Starts as `null` so the UI can render before the background
/// `claimDeviceIdentity` round-trip completes. `appBootstrapProvider`
/// (driven by `WelcomeScreen`) calls `set(session)` first with the
/// cached session and then again with the live one once the custom
/// token sign-in resolves.
final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession?>(
  AuthSessionNotifier.new,
);

class AuthSessionNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => null;

  // ignore: use_setters_to_change_properties
  void set(AuthSession? session) => state = session;
}

@Riverpod(keepAlive: true)
Stream<AuthSession?> authSessionStream(Ref ref) {
  return ref.watch(authRepositoryProvider).watchSession();
}

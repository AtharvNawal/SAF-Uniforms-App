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

@Riverpod(keepAlive: true)
FirebaseFunctions firebaseFunctions(Ref ref) =>
    FirebaseFunctions.instanceFor(region: 'asia-southeast1');

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

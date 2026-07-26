import 'device_identity.dart';

abstract class AuthRepository {
  /// Signs in with a custom token issued by the `claimDeviceIdentity`
  /// Cloud Function and upserts `users/{uid}` with the stable
  /// [DeviceIdentity.deviceId].
  Future<AuthSession> signInWithClaim({
    required ClaimResult claim,
    required DeviceIdentity identity,
  });

  /// Returns the current cached session derived from
  /// `FirebaseAuth.currentUser`, or `null` if no user is signed in.
  AuthSession? currentSession();

  Stream<AuthSession?> watchSession();
  Future<void> signOut();
}

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.deviceId,
    required this.profileComplete,
  });

  final String uid;
  final String deviceId;

  /// Mirror of `device_registrations/{deviceId}.profileComplete` last
  /// observed by the client. Used by routing to skip the wizard.
  final bool profileComplete;

  AuthSession copyWith({String? uid, String? deviceId, bool? profileComplete}) {
    return AuthSession(
      uid: uid ?? this.uid,
      deviceId: deviceId ?? this.deviceId,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }
}

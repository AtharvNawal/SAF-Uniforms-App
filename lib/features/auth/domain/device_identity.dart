/// Stable per-device identity used to bind a Firebase uid across app
/// reinstalls.
///
/// On first launch, [DeviceIdentityService] generates a UUIDv4 and writes
/// it to platform secure storage (iOS keychain / Android encrypted
/// SharedPreferences). The keychain entry survives normal app uninstalls
/// on iOS; on Android the same is true if Auto Backup is enabled and the
/// user has Google Drive backup turned on.
class DeviceIdentity {
  const DeviceIdentity({required this.deviceId, required this.platform});

  /// UUIDv4 string. Persisted across app launches (and, where supported,
  /// across reinstalls) by [DeviceIdentityService].
  final String deviceId;

  /// `'ios'` or `'android'`.
  final String platform;
}

/// Result of calling the `claimDeviceIdentity` Cloud Function.
///
/// The client signs in with [customToken] to obtain (or recover) the
/// Firebase auth session for [uid].
class ClaimResult {
  const ClaimResult({
    required this.uid,
    required this.customToken,
    required this.profileComplete,
  });

  final String uid;
  final String customToken;

  /// Whether the user has previously finished the Configuration wizard.
  /// Drives Welcome → `/dashboard` vs `/config` routing.
  final bool profileComplete;
}

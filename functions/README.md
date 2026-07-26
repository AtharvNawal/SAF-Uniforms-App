# SAF Uniforms — Cloud Functions

Two HTTPS callables that back the device-bound identity flow described
in [`ChangeRequest/2026-05-02_device-bound-identity-and-profile-sync.md`](../ChangeRequest/2026-05-02_device-bound-identity-and-profile-sync.md).

## Functions

### `claimDeviceIdentity({ deviceId, platform })`

- Looks up `device_registrations/{deviceId}`.
- If found: returns the existing `uid` + `profileComplete` flag.
- If not: creates a Firebase Auth user via the Admin SDK and writes the
  mapping.
- Always returns a fresh **custom auth token** the client uses to
  `signInWithCustomToken`.
- Region: `asia-southeast1`.

### `markProfileComplete({ deviceId })`

- Verifies the caller is the registered owner of `deviceId`.
- Sets `device_registrations/{deviceId}.profileComplete = true` so
  subsequent installs skip the Configuration wizard.
- Region: `asia-southeast1`.

## Local development

```bash
cd functions
npm install
npm run build
firebase emulators:start --only functions,firestore
```

Point the Flutter client at the emulator by calling
`FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001)` in
debug builds.

## Deploy

```bash
firebase deploy --only functions,firestore:rules
```

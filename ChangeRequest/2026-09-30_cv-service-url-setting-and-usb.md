# In-app cv-service address setting + USB (adb reverse) connection

- **Date:** 2026-09-30
- **Author:** Claude (Opus 5.5) for Atharv Nawal
- **Status:** executed — `flutter analyze` clean, `flutter test` 133/133, release APK built; on-device check pending (user)

## 1. Goal
The AR Scanner can only reach `cv-service` at an address compiled into the
APK (`--dart-define=CV_SERVICE_BASE_URL`, default `http://192.168.1.144:8001`).
Every laptop IP change needs a rebuild + reinstall, and when the phone
can't reach the laptop over Wi-Fi there is no alternative. On a real device
the phone's browser reached `/health` but the installed app never
delivered a scan — the scan failure also hid which address was called.

Give the user two ways to connect without rebuilding:
1. **An editable "Analysis server" address in the app** (persisted), with a
   **Test connection** button that calls `GET /health` and shows the exact
   result/error.
2. **A one-tap "USB cable" preset** (`http://127.0.0.1:8001`) used with
   `adb reverse tcp:8001 tcp:8001` — the phone talks to the laptop over the
   cable, so Wi-Fi, firewall and IP address stop mattering.

## 2. Scope
- In: `LocalStorageService` key `saf.cvServiceUrl`; `cvServiceUrlProvider`
  (keepAlive notifier, compiled default + persisted override, URL
  normalisation); both cv-service repositories read the base URL from it;
  `CvServiceHealth` check; a `CvServerSettings` widget used in the Settings
  sheet and opened from the scanner's "Connection problem" screen; failure
  detail shows the URL actually called; `deploy/connect-phone-usb.sh`.
- Out: a public tunnel (sends photos through a third party — separate,
  user-confirmed decision), Cloud Run deploy.

## 3. Affected areas
`lib/core/persistence/local_storage_service.dart`,
`lib/features/ar_scanner/{data,presentation}/**`,
`lib/features/dashboard/presentation/widgets/settings_sheet.dart`,
ARB files (en/zh), `deploy/`, tests, CLAUDE.md §4/§5.4/§5.5.

## 4. Step-by-step plan
1. Storage key + read/write.
2. `cvServiceUrlProvider` + `normaliseCvServiceUrl` + `CvServiceHealth.check`.
3. Repository providers watch the URL provider.
4. `CvServerSettings` widget (field, Save, USB preset, Reset, Test).
5. Settings sheet section + "Server settings" button on the failure screen.
6. Exception messages include the URL called.
7. `deploy/connect-phone-usb.sh`.
8. Tests, analyze, build APK.

## 5. Risks & rollback
- A wrong saved URL breaks scanning until changed — mitigated by Reset
  (back to the compiled default) and the Test button.
- `127.0.0.1` works only while `adb reverse` is active (cable plugged in).
- Rollback: revert; the stored key is ignored by older builds.

## 6. Verification
`flutter analyze`, `flutter test`, `flutter build apk --release`; on-device
check by the user.

## 7. CLAUDE.md updates required
§4 ar_scanner entries, §5.4 local persistence table (`saf.cvServiceUrl`),
§5.5 cv-service deploy note.

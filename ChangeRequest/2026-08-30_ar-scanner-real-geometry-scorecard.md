# AR Scanner — real geometry/pixel scorecard via cv-service `/check_uniform`

**Status:** executed — code-complete + locally verified (`/check_uniform`
returns a real scored body against `tests/fixtures/rendered_army_no3_male_front.jpg`;
`flutter analyze` clean; `flutter test` green, 12 new tests). **Not
device-verified** end-to-end (no phone in the authoring environment).
cv-service runs locally only — `deploy/run-cv-service-local.sh`; the app
reaches it over the LAN (`kCvServiceBaseUrl` default = this dev machine's
IP). No hosted deployment (deliberately — operator declined paid cloud).

## Goal

Replace the AR Scanner's fabricated "100% perfect match" result (a local
stand-in built from the profile's expected-accessory list — it always
passed, even for a photo of someone in civilian clothes) with a real
compliance scorecard computed by `cv-service`'s `POST /check_uniform`
endpoint: pose estimation → PnP camera-pose solve → physical-scale
recovery → trained garment segmentation → doctrine tolerance check, all
in pixel space. **No Anthropic / vision-language call** — `/check_uniform`
is the Anthropic-free geometry path (see CLAUDE.md §5.10).

## Scope

Flutter app only. `cv-service` itself is unchanged — `/check_uniform`
already exists and is tested (built
`ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md`).

The Phase-1 `checkUniformCompliance` Cloud Function (Anthropic) stays
commented out / unused, per the user's "no compliance check, backend is
on trial" instruction — the trial-billed backend is the Node/Anthropic
one, not `cv-service`.

## Affected areas

- New `lib/features/ar_scanner/domain/entities/uniform_check_result.dart`
  — `@freezed` model mirroring the `/check_uniform` JSON contract
  (`api/response_schema.py`): `UniformCheckResult`,
  `UniformCheckAccessory`, `UniformCheckStatus` (5-state:
  correct / slightlyMisaligned / incorrect / missing / uncertain),
  `UniformCheckPoint` / `UniformCheckBox`.
- New `lib/features/ar_scanner/data/uniform_check_repository.dart` —
  `POST {kCvServiceBaseUrl}/check_uniform` multipart client; throws
  `UniformCheckException(message, {statusCode, errorCode})` with the
  service's typed error codes (`NO_PERSON_DETECTED`, `POSE_UNRELIABLE`,
  `SCALE_UNAVAILABLE`, `SEGMENTER_UNAVAILABLE`, `UNSUPPORTED_UNIFORM`,
  the five image-quality codes, …).
- New `lib/features/ar_scanner/presentation/providers/uniform_check_provider.dart`
  — `uniformCheckRepositoryProvider` + `UniformCheckController`
  (`@riverpod AsyncNotifier<UniformCheckResult?>`, not keepAlive,
  `check(...)` + `reset()`), same shape as `CvServiceInspectionController`.
- `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart` —
  `_capture()` now drives `UniformCheckController.check(...)` (was the
  fake `_buildResult()`); the fake `_buildResult` / `_captureResult` are
  deleted. New `_RealScorecard` widget renders the geometry result
  (overall status/score ring, per-accessory rows with status colour +
  expected-vs-detected pixel offset + doctrine ref, summary tallies).
  `_ArPhase.scorecard` renders it. The unused `_Scorecard`
  (Phase-1 `ComplianceResult`) widget + `compliance_result.dart` import
  are removed from this screen.
- `lib/features/ar_scanner/presentation/utils/capture_error_message.dart`
  — `describeCaptureError` handles `UniformCheckException` (unreachable
  vs. typed service error).
- `lib/core/l10n/arb/app_{en,zh}.arb` + generated — new strings for the
  real scorecard + the cv-service-unreachable error copy (reusing
  `arErrorCvUnreachableSub` where it fits).
- CLAUDE.md §5.10 + the `ar_scanner` source-tree entry.

## Step-by-step plan

1. Add `uniform_check_result.dart` (freezed model + status enum +
   `fromJson`-free manual parse helpers live in the repo).
2. Add `uniform_check_repository.dart` — multipart POST, 60s timeout,
   maps non-200 `{error, message}` bodies to `UniformCheckException`.
3. Add `uniform_check_provider.dart`.
4. `dart run build_runner build --delete-conflicting-outputs`.
5. Rewire `ar_scanner_screen.dart`: delete `_buildResult`/`_captureResult`
   + `_Scorecard`; `_capture()` → `UniformCheckController.check`;
   `ref.listen` transitions `analyzing → scorecard` on data, `→ failed`
   on error; add `_RealScorecard`.
6. `uniform_type` sent as `"${branch}_${dressCode}_${gender}"` (e.g.
   `army_no3_male`); a non-army/non-No3 profile gets the service's
   `UNSUPPORTED_UNIFORM` 422, surfaced verbatim (honest, not hidden).
7. Extend `describeCaptureError` + ARB strings.
8. Tests: `uniform_check_result_test.dart` (enum + getters),
   `uniform_check_repository_test.dart` (parse a sample 200 body + a
   422 error body using a mocked `http.Client`).
9. CLAUDE.md refresh.

## Risks & rollback

- **cv-service is not deployed** — with no reachable instance the scan
  now ends in a clear "analysis service unreachable" error instead of a
  (fake) pass. This is intended: an honest failure beats a fake success.
  Rollback = `git revert` this change set (restores the fake 100%).
- `kCvServiceBaseUrl` defaults to `http://localhost:8001`; a physical
  device needs `--dart-define=CV_SERVICE_BASE_URL=http://<mac-lan-ip>:8001`
  and the Mac running `uvicorn`. Android cleartext to a LAN IP also needs
  a `network_security_config` allowance (documented, not changed here —
  emulator `10.0.2.2` and iOS simulator `localhost` work without it).
- Model/enum drift vs. `api/response_schema.py` — covered by the parse
  test using a captured real response body.

## Verification

1. `flutter analyze` — clean.
2. `dart run build_runner build --delete-conflicting-outputs` — clean.
3. `flutter test` — all green, new tests included.
4. Device smoke test — **BLOCKED**: needs a reachable `cv-service`
   (`.venv-tools/bin/uvicorn cv-service.api.main:app --port 8001` +
   `--dart-define`). Left for the operator; plan stays `executed`, not
   `verified`, until then.

## CLAUDE.md sections to refresh

§5.10 (cv-service narrative — note the Flutter wiring of `/check_uniform`);
the `lib/features/ar_scanner/...` source-tree block (new files, fake
result removed).

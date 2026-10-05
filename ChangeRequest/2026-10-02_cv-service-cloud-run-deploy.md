# cv-service — deploy to Cloud Run (scanner reachable from anywhere)

- **Date:** 2026-10-02
- **Author:** Claude (Opus 5.5) for Atharv Nawal
- **Status:** executed — live and smoke-tested; device test pending (operator)

## 1. Goal
Today the AR Scanner only works when the phone is on the same Wi-Fi as the
Mac that runs `cv-service`. Deploy it to Google Cloud Run in `saf-uniforms`
(region `asia-southeast1`, same as the Cloud Functions). The app then
reaches it over HTTPS from any network, and only signed-in app users can
call it.

## 2. Scope
**In scope**

1. **Auth (`cv-service/api/auth.py`).** A FastAPI dependency that verifies
   a Firebase ID token, sent as `Authorization: Bearer <token>`, against
   the `saf-uniforms` project. It uses `google-auth`'s
   `verify_firebase_token`.
   - Enforced only when `CV_SERVICE_REQUIRE_AUTH=1`, which is set on
     Cloud Run. Local runs and the existing tests stay open.
   - Applies to `/inspect`, `/check_uniform` and `/check_uniform_burst`.
     `/health` stays open for the app's "Test connection".
2. **Image fixes (`cv-service/Dockerfile`, `.dockerignore`).**
   - Ship `segmentation_v2` (weights + `training_complete.json`). Today
     only v1 is whitelisted, so a container silently runs the older model
     (benchmark false alarms 32.9 % vs 5.5 %).
   - Copy `assets/accessories/*/image.png` (badge-variant references) and
     `assets/data/accessory_library.v1.json` (per-item instructions). Both
     are read at runtime and missing from the image.
   - Use CPU-only PyTorch. The default Linux wheel pulls about 3 GB of
     CUDA libraries that Cloud Run can't use.
   - Bake every lazily-downloaded model into the image with a build-time
     warm-up (`cv-service/models/warm_cache.py`): YOLOv8n, DINOv2-small
     (torch.hub), EasyOCR English, YOLO-World + its CLIP text encoder,
     SAM 2. Otherwise each cold start re-downloads them.
   - Listen on `$PORT` (Cloud Run sets 8080; local default stays 8001).
3. **Build/deploy (`deploy/deploy-cv-service-cloudrun.sh`,
   `deploy/cloudbuild.cv-service.yaml`, `.gcloudignore`).**
   - Cloud Build builds remotely, since Docker isn't installed locally,
     and pushes to Artifact Registry.
   - `gcloud run deploy` settings:
     - 4 vCPU, 8 GiB, 300 s timeout, concurrency 1 (the pipeline is
       CPU-bound)
     - min 0 / max 2 instances, as a cost cap
     - CPU boost on
   - Without a `.gcloudignore`, `gcloud builds submit` falls back to
     `.gitignore`, which drops the model weights. So I'm adding a
     `.gcloudignore` that ships them.
   - It excludes `cv-service/data/` (real-photo intake, privacy) and
     synthetic data.
4. **App.**
   - Both cv-service clients attach the current user's Firebase ID token.
     They take an optional token-provider callback, so tests don't need
     Firebase.
   - Release builds point at the Cloud Run URL through
     `--dart-define=CV_SERVICE_BASE_URL=…`. The in-app server setting
     still works.

**Out of scope**
- A GPU. CPU inference is slower but needs no quota request.
- `/inspect`'s Anthropic key. It's the long-press dev path, and no
  `ANTHROPIC_API_KEY` secret exists.
- `min-instances=1`. It would remove cold starts, but an always-on
  4 vCPU / 8 GiB instance costs roughly US$150+/month.

## 3. Affected areas
- `cv-service/api/auth.py` (new), `cv-service/api/main.py`,
  `cv-service/config.py`, `cv-service/requirements.txt`
- `cv-service/Dockerfile`, `.dockerignore`, `.gcloudignore` (new)
- `cv-service/models/warm_cache.py` (new)
- `cv-service/tests/test_auth.py` (new)
- `deploy/deploy-cv-service-cloudrun.sh`,
  `deploy/cloudbuild.cv-service.yaml` (new)
- `lib/features/ar_scanner/data/uniform_check_repository.dart`,
  `cv_service_inspection_repository.dart`, and the two providers
- `test/features/ar_scanner/uniform_check_repository_test.dart`
- `CLAUDE.md` §2 (`cv-service/`, `deploy/`), §5.5 (deploy targets), §4

## 4. Steps
1. Write the plan.
2. Add auth and its tests; run the cv-service tests.
3. Fix the image, add the warm-up script and the ignore files.
4. Add the deploy script; build with Cloud Build and deploy.
5. Smoke-test the live URL:
   - `/health` returns 200;
   - `/check_uniform` without a token returns 401;
   - `/check_uniform` with a real Firebase ID token runs the rendered
     fixture photo end to end.
6. Change the app (ID token header), run tests, build an APK against the
   URL.
7. Update CLAUDE.md and the plan status.

## 5. Risks & rollback
- **Cold start.** The first request after idle loads about 1 GB of
  models, which takes about 30–60 s, so the app's 120 s scan timeout
  has margin.
- **Cost.** Billed per request-second, with max 2 instances. Idle costs
  nothing apart from Artifact Registry storage (a few GB, about
  US$0.10/GB-month).
- **Rollback:**
  ```bash
  gcloud run services delete cv-service --region asia-southeast1
  ```
  Then point the app back at the LAN address in Settings.

## 6. Verification
- `.venv-tools/bin/pytest cv-service/tests/`
- `flutter analyze`, `flutter test`
- Live smoke tests (§4.5)
- Device test on the Android phone over mobile data

## 7. Execution notes (2026-10-02 / 03)

**Builds**
- **Build 1 failed** in `warm_cache.py`: MediaPipe needs `libEGL.so.1`.
  The warm-up caught it before anything shipped. Added
  `libegl1 libgles2` and pre-created the cache dirs.
- **Build 2 passed** (all 7 models load in the image) and deployed:
  `https://cv-service-612500938654.asia-southeast1.run.app`, revision
  `cv-service-00001`, `CV_SERVICE_REQUIRE_AUTH=1`.

**Blocker**
- `--allow-unauthenticated` failed: `run.services.setIamPolicy` was denied.
- Every account available is **Editor**: `nawalatharv@gmail.com` for
  gcloud and the Firebase CLI, plus the service accounts. The project
  Owners are `pmjere@gmail.com` and `sukalkar.datta@gmail.com`.
- So Cloud Run's front end answers 403 to everything, and the service is
  private.
- The operator asked not to bypass this (no `--no-invoker-iam-check`, no
  routing through existing public functions). App access waits for an
  Owner to either:
  - **(a)** grant `allUsers` → `roles/run.invoker` on `cv-service` only.
    In-service Firebase ID-token auth gates every analysis endpoint; or
  - **(b)** grant the compute service account `roles/run.invoker` on
    `cv-service`. A proxy function (to be built) then fronts it.

**Ready for the grant**
- `~/Desktop/SAF-Uniforms-cloud.apk` is built with
  `CV_SERVICE_BASE_URL` set to the Cloud Run URL; I checked that the URL
  is compiled into `libapp.so`.
- After the grant, the live smoke test checks health, no-token 401,
  forged-token 401, a real-token scan and a 3-frame burst.

**Tests**
- cv-service: 200 pass, plus 7 new auth tests. The 1 failure,
  `test_inspect_rejects_multi_person_photo`, was already failing before
  this change; `/inspect` is the dev path.
- Flutter: 151 + 4 new ID-token header tests; `flutter analyze` is clean.

## 8. Owner approval + live verification (2026-10-05)
An Owner opened access on `cv-service` only. Live smoke test against
`https://cv-service-612500938654.asia-southeast1.run.app`:
1. `/health` → 200.
2. `/check_uniform` with no token → 401 `UNAUTHENTICATED`.
3. `/check_uniform` with a forged token → 401 `UNAUTHENTICATED`.
4. `/check_uniform` with a real Firebase ID token (throwaway uid, deleted
   afterwards) → 200 in 33 s on a cold-ish instance. Scorecard of 13
   items, `FAIL`, which is expected: the fixture is a bare body with no
   accessories.
5. `/check_uniform_burst` with 3 frames → 200 in 14.6 s.

Remaining: install `SAF-Uniforms-cloud.apk` on the Android test phone
and scan over mobile data.

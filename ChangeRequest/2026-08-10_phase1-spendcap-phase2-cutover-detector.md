# Phase 1 spend cap, Phase 2 A/B harness + Docker fix, real accessory detector (M3 progress)

- **Date:** 2026-08-10
- **Author:** Claude
- **Status:** in-progress

## 1. Goal

Implement items 2, 3, 4 from the upgrade-priorities review of the AI
uniform-compliance work (Phase 1 `checkUniformCompliance` + Phase 2
`cv-service`):

2. **Phase 1 quick win:** bound Anthropic API cost with a per-user daily
   cap before this is ever deployed to real users.
3. **Phase 2 → production cutover path:** build the tooling needed to make
   an evidence-based cutover decision later (an A/B comparison harness),
   and fix a real bug found while reviewing the container path.
4. **The trained-detector gap (Milestone 3):** train a real YOLOv8n
   detection model on synthetic data — the same honest, synthetic-only
   approach that produced the segmentation model in
   `ChangeRequest/2026-08-05_cv-service-m2-synthetic-segmentation-model.md`
   — for the accessory classes segmentation is weakest on.

Each item is scoped to what's actually achievable in this environment.
Concrete infra checks done before writing this plan: no `docker` binary,
no `gcloud`, `firebase` CLI is present but deploying is a production
action outside this plan's scope. `torch` + Apple-Silicon `mps` IS
available (confirmed), which is what makes item 4 tractable.

## 2. Scope

**In scope:**

- `functions/src/checkUniformCompliance.ts`: per-user daily rate limit
  (Firestore-transaction-backed counter), rejecting with
  `HttpsError("resource-exhausted", ...)` once exceeded.
- `functions/src/checkUniformCompliance.test.ts`: tests for the new limit
  logic.
- `cv-service/evaluation/compare_phase1_phase2.py` (new): an offline
  harness that runs both a whole-photo Claude verdict (Phase-1 style) and
  the geometry-guided `cv-service` pipeline (Phase-2) against the same
  photo, and reports per-item agreement/disagreement. Runnable with a
  fake Anthropic client (zero credentials, like all other `cv-service`
  tests) or a real key.
- `cv-service/tests/test_compare_phase1_phase2.py`: test for the harness
  using the fake client.
- `.dockerignore` fix: stop excluding `cv-service/models/*/weights/*.pt`
  so a `docker build` run from a machine that has trained weights on disk
  actually ships them — today it silently never would, for segmentation
  OR the new detector below.
- `cv-service/README.md` + `cv-service/Dockerfile` comment: document the
  cutover decision's remaining operator-gated steps (Cloud Run deploy,
  GPU/CPU choice, secret wiring) since they can't be executed here.
- `cv-service/training/generate_detection_dataset.py` (new): synthetic
  bounding-box dataset generator, YOLO detection format, train/val split
  — mirrors `generate_segmentation_dataset.py`'s structure but reuses
  `generate_synthetic_dataset.py`'s box-projection math instead of mask
  polygons.
- `cv-service/training/train_detection.py` (new): trains YOLOv8n
  (detection) on that dataset, mirrors `train_segmentation.py`.
- `cv-service/detectors/detect_accessories.py` (new): Stage 5 inference
  wrapper, mirrors `segmentation/segment_uniform.py`'s pattern.
- `cv-service/api/main.py`: wire the trained detector in as an additional
  best-effort `detection` field (never blocks the report), alongside —
  not replacing — the existing Claude-based `vision_crop_inspector`
  judgment.
- `cv-service/tests/test_detection.py` (new).
- `cv-service/README.md` + `CLAUDE.md` §5.10: document the new detector
  with the same synthetic-only caveat already applied to segmentation.

**Out of scope (operator actions, not achievable in this environment):**

- Actually deploying `checkUniformCompliance` or provisioning
  `ANTHROPIC_API_KEY` in Secret Manager — no deploy credentials here.
- Running the A/B harness against a real Anthropic key or real photos —
  none available. The harness is built and tested with the fake client;
  a real run is an operator action documented in the README.
- `docker build` / Cloud Run deploy — no Docker or gcloud binary in this
  environment. The `.dockerignore` fix is reviewed by hand, not
  build-verified — flagged explicitly, same honesty bar as the existing
  Dockerfile's own header comment.
- Any claim that the new detector works on real photos — same
  synthetic-only caveat as segmentation. This is progress on M3's
  training-data-and-mechanism gap, not a finished, real-world-validated
  detector.

## 3. Step-by-step plan

1. **Rate limit:** add a `DAILY_CHECK_LIMIT` constant + a Firestore
   transaction against `users/{uid}/complianceUsage/{yyyy-mm-dd}` at the
   top of the handler (after auth, before the Anthropic call) that reads
   the current count, rejects if `>= DAILY_CHECK_LIMIT`, else increments
   atomically. Log `warn` on rejection. Add tests for the pure
   limit-check logic (extracted as a testable function, same pattern as
   `buildPromptText`).
2. **Fix `.dockerignore`:** narrow the `cv-service/models/` exclusion so
   `*/weights/*.pt` passes through but bulky training-run artifacts
   (plots, batch preview images, confusion matrices) stay excluded.
3. **A/B harness:** write `compare_phase1_phase2.py` — takes a photo +
   profile fields, resolves the same expected-accessory list `army_no3_male.json`
   encodes, runs (a) a whole-photo Claude call shaped like
   `checkUniformCompliance.ts`'s prompt/tool schema and (b) the existing
   `cv-service` pipeline, and prints a side-by-side per-item comparison
   table plus an agreement-rate summary. Both paths accept an injectable
   client for testing.
4. **Detection dataset generator:** write
   `generate_detection_dataset.py` reusing `ACCESSORY_SPECS`,
   `RenderCamera`, `_load_accessory_mesh`, `_place_accessory`,
   `load_anchors` from `generate_synthetic_dataset.py`, and the
   `_project`/`_camera_intrinsics` box-projection helpers, but with a
   train/val split and YOLO detection `.txt` label output (mirroring
   `generate_segmentation_dataset.py`'s output-structure conventions).
   Run a small batch first to sanity-check timing and box correctness
   before committing to the full run.
5. **Generate the dataset** at a scale meaningfully larger than
   segmentation's 180 images (bbox-only rendering is faster — no SEG
   double-pass) — target ~400 train / 80 val, run in the background.
6. **Train:** `train_detection.py`, YOLOv8n on `mps`, same
   epochs/patience pattern as `train_segmentation.py`. Record per-class
   box mAP50, compare directly against segmentation's weak classes
   (`belt`, `arms_badge`, `epaulette`, `sleeve_rank`).
7. **Inference wrapper + wiring:** `detect_accessories.py` +
   `api/main.py`'s best-effort `detection` field.
8. **Visual verification:** draw predicted boxes on the existing
   rendered fixture photo and inspect the image directly (not just "it
   returned JSON") — same verification habit the segmentation plan used
   to catch two real bugs.
9. **Tests:** `test_detection.py`, `test_compare_phase1_phase2.py`,
   `checkUniformCompliance.test.ts` additions. Run the full suites.
10. Update `cv-service/README.md` and `CLAUDE.md` §5.10, mark this plan
    `executed` then `verified`.

## 4. Risks & rollback

- **Rate limit risk:** a limit set too low blocks legitimate use; too
  high doesn't bound cost meaningfully. Chosen as a named constant so an
  operator can retune without a code review of the surrounding logic.
- **Detector risk — restated because it's the load-bearing caveat on
  every model this project trains:** zero real photos, synthetic-only
  validation. This must not be presented as "the AI detects accessories"
  without that caveat attached. It is additive/best-effort in the report,
  exactly like segmentation — it cannot cause the existing Claude-based
  verdict to regress, only add a new, clearly-labeled field.
- **`.dockerignore` fix risk:** none identified — narrowing an ignore
  pattern to let specific files through is low-risk and doesn't change
  runtime behavior of anything already working.
- **Rollback:** every new file is additive; the two edited files
  (`checkUniformCompliance.ts`, `api/main.py`, `.dockerignore`) have
  isolated, reviewable diffs. `git diff` / delete-the-new-files rollback,
  no data migrations.

## 5. Verification

(filled in as each step completes — see final status update)

## 6. CLAUDE.md updates required

- §5.5: note the new rate limit on `checkUniformCompliance`.
- §5.10: document the detection dataset generator, `train_detection.py`,
  `detect_accessories.py`, the `.dockerignore` fix, and the A/B
  comparison harness — same honest-caveat bar as every other `cv-service`
  entry in this section.

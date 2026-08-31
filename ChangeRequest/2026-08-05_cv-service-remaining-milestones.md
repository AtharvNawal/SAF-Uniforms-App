# cv-service remaining milestones — M1 client half, M6 container, M7 Flutter integration, M2/M3 dataset-gen prerequisite

- **Date:** 2026-08-05
- **Author:** Claude
- **Status:** verified

## 1. Goal

Close out every milestone from the architecture memo's §18 roadmap that
is actually achievable without trained models or a live deployment:
the Flutter-side capture-quality gate (M1's other half), a container
image for `cv-service` (M6), full Flutter wiring to the Phase-2 report
shape (M7), and — since M2/M3 (trained segmentation/detection) remain
hard-blocked on labeled training data no matter how much code gets
written — a real, verified synthetic-dataset generator that produces
that training data, which is genuine progress toward M2/M3 without
claiming to complete them.

## 2. Scope

- In scope:
  - `lib/features/ar_scanner/data/capture_quality_gate.dart` — on-device
    pose-quality check via `google_mlkit_pose_detection` (a previously
    unused dependency — see `CLAUDE.md` §8), run on the picked photo
    immediately after capture (this app has no live camera feed to
    gate mid-shutter — see the file's docstring for why that's a
    faithful adaptation, not a scope-down that hides a gap).
  - `lib/features/ar_scanner/domain/entities/cv_inspection_result.dart` —
    Dart models for `cv-service`'s report shape (5-state verdict,
    subscores, camera diagnostics, annotated image), strictly separate
    from the existing Phase-1 `ComplianceResult`/`ComplianceStatus`.
  - `lib/features/ar_scanner/data/cv_service_inspection_repository.dart` —
    HTTP multipart client for `cv-service`'s `POST /inspect`.
  - `lib/features/ar_scanner/presentation/providers/cv_service_inspection_provider.dart` —
    Riverpod controller, same shape as the existing
    `UniformComplianceController`.
  - `ar_scanner_screen.dart` — long-press-on-capture dev entry point
    into the Phase-2 path, plus a `_CvScorecard` widget rendering the
    richer report. Strictly additive: the default tap-to-capture flow
    is untouched.
  - `cv-service/Dockerfile` + root `.dockerignore` — container image
    for `cv-service`. **Not deployed, not run** — no Docker in this
    environment; built as code, not verified via `docker build`.
  - `cv-service/training/generate_synthetic_dataset.py` — renders the
    reference body + doctrine-anchored accessories from randomized
    cameras via `pyrender` (Blender isn't installed in this
    environment; same job, different renderer — see the script's
    docstring), deriving bounding boxes by projecting actual mesh
    vertices through the exact render camera, not guessing them.
- Out of scope, and why:
  - Any *trained* segmentation or accessory-detection model — the
    hard blocker restated in every prior conversation turn: no amount
    of engineering effort substitutes for labeled data + GPU training
    time that don't exist in this session. `generate_synthetic_dataset.py`
    produces the *input* to that future training run; it is not that
    run.
  - Deploying `cv-service` to Cloud Run, or flipping
    `checkUniformCompliance.ts` to call it — both are production
    infrastructure changes requiring explicit user authorization and
    (for Cloud Run) credentials/project access this session doesn't
    have.
  - Rendering the "tens of thousands" of images the memo's §16
    envisions at full scale — this plan verifies the generator against
    6 renders (enough to prove the projection math is correct; see
    §6) — scaling up is a compute-time decision for the user to make,
    not a capability question.

## 3. Affected areas

- New: `lib/features/ar_scanner/data/capture_quality_gate.dart`,
  `cv_service_inspection_repository.dart`.
- New: `lib/features/ar_scanner/domain/entities/cv_inspection_result.dart`
  (+ generated `.freezed.dart`).
- New: `lib/features/ar_scanner/presentation/providers/cv_service_inspection_provider.dart`
  (+ generated `.g.dart`).
- Update: `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart`.
- New: `cv-service/Dockerfile`, `cv-service/training/generate_synthetic_dataset.py`.
- New: root `.dockerignore`.
- Update: `cv-service/README.md`, `CLAUDE.md` §5.10 and top-level tree.

## 4. Step-by-step plan

1. Survey the existing `ar_scanner` feature (repository/provider/screen
   patterns) before extending it, to keep the new Phase-2 path
   stylistically and structurally consistent rather than bolted on.
2. Build the Dart domain models mirroring `cv-service`'s actual JSON
   report shape field-for-field.
3. Build the HTTP repository (`package:http`, already a dependency —
   no pubspec change) and provider.
4. Wire a long-press dev entry point + new scorecard widget into
   `ar_scanner_screen.dart`, guarded so the default flow is untouched.
5. Regenerate `freezed`/`riverpod` code, run `flutter analyze` and
   `flutter test`.
6. Build the capture-quality gate against `google_mlkit_pose_detection`,
   wire it into both capture paths ahead of the network call.
7. Re-run `flutter analyze` + `flutter test`.
8. Write `cv-service/Dockerfile` + `.dockerignore`.
9. Build `generate_synthetic_dataset.py`; run it for a handful of
   renders and visually verify (draw the derived bboxes back onto the
   rendered image) that the projection math is actually correct before
   calling it done — not just that it runs without crashing.
10. Update docs, mark this plan `executed`, then `verified`.

## 5. Risks & rollback

- The Flutter capture gate degrades to "accept" on any internal error
  (model not downloaded, platform channel failure) rather than
  blocking capture — a broken gate must never be worse than no gate.
  See `CaptureQualityGate.evaluate`'s catch block.
- The dev entry point (long-press) is discoverable only to someone who
  knows to try it — deliberate, since it points at `localhost:8001` by
  default and has no business surfacing to a real user until `cv-service`
  is actually deployed (M6/production wiring, not this plan).
- `Dockerfile` is unverified by an actual `docker build` — flagged
  explicitly in its own header comment and in this plan's verification
  section, not silently presented as tested.
- Rollback: every file here is new except `ar_scanner_screen.dart`,
  whose diff is additive (new imports, one new field, one new method,
  one new phase, one new widget) — revertable via `git diff` review
  without touching the existing Phase-1 code paths.

## 6. Verification

- `flutter analyze` — **no issues found**.
- `flutter test` — **77/77 passed**, including the pre-existing
  `compliance_result_test.dart` (untouched, confirms Phase-1 models
  weren't disturbed).
- `generate_synthetic_dataset.py` run for 6 renders
  (`--seed 42 --n-renders 6`): completed without error, 47 accessory
  annotations across 6 images. Visually verified by drawing the
  generated bounding boxes back onto the source render — every box
  (beret+cap badge, both epaulettes, arms badge, belt) tightly and
  correctly wraps the actual rendered accessory geometry, confirming
  the camera-pose-matrix + perspective-projection math is correct, not
  merely non-crashing.
- `cv-service/Dockerfile` — **not build-tested**; no `docker` binary in
  this environment (`which docker` → not found). Reviewed by hand
  against `cv-service/requirements.txt` and the actual file layout
  (`assets/3d/bodies/`, `cv-service/models/download_models.sh`) for
  path correctness, but "reviewed" is not "verified" — flagged as such
  in the file's own header comment.
- The Flutter dev path (long-press → `cv-service` call) is code-complete
  and passes static analysis, but **not exercised against a running
  `cv-service` instance** in this session (would require a device/
  simulator with camera access plus a locally running `uvicorn`
  process, neither available here) — the user should smoke-test it per
  `CLAUDE.md` policy 1.5 before relying on it.

## 7. CLAUDE.md updates required

- §5.10: note the Flutter-side capture gate and Phase-2 dev entry
  point now exist (M1 client half + M7), the Dockerfile (M6, unverified),
  and the synthetic-dataset generator (real M2/M3 prerequisite, not
  M2/M3 itself).
- §2 top-level tree: no new top-level directories (all changes are
  inside `lib/` and `cv-service/`, both already documented), so only
  the `cv-service/` entry's description needs a small addendum rather
  than a new line.

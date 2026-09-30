# cv-service

Python backend for the Phase-2 uniform-compliance computer-vision
pipeline. Sibling to `functions/` (Node Cloud Functions) and
`admin-portal/` (Angular) — has its own dependency stack and is not
part of either build.

## Current state: real geometry + a vision-language stand-in for the untrained detector

Two plan files built this in order:

1. `ChangeRequest/2026-08-05_cv-service-anchor-extraction-scaffold.md` —
   the data foundation (canonical anchors + doctrine rules, no models).
2. `ChangeRequest/2026-08-05_cv-service-mvp-inspect-endpoint.md` — this
   slice: a real, runnable `POST /inspect` endpoint.

**What's real, measured geometry today** (no training data needed —
either classical CV or off-the-shelf pretrained models):

| Stage | Module | What it actually does |
| --- | --- | --- |
| 1 | `pose/detect_person.py` | YOLOv8n person detection — rejects empty/multi-person frames |
| 2 | `pose/estimate_pose.py` | MediaPipe Tasks PoseLandmarker — 33 real body keypoints |
| 3 | `calibration/pnp_solve.py` | OpenCV `solvePnP` — recovers where the camera stood relative to the body, from the canonical anchors extracted in the earlier slice. Includes a `reliable` guard: a pose that doesn't resemble a relaxed standing A-pose (tested against an actual yoga photo — see the session that built this) makes `solvePnP` converge to a mathematically valid but physically nonsensical camera, and this is now detected and rejected rather than silently trusted. |
| 6 | `rules/rule_engine.py` | Projects every doctrine rule's expected 3D position into this specific photo's pixel space and sizes a crop region around it. Includes a fix for "half of sleeve length from the shoulder seam"-style rules, which blend the projected shoulder anchor toward the detected elbow landmark rather than sitting statically at the shoulder. |

**What is NOT a trained detector — read before trusting the output:**

`detectors/vision_crop_inspector.py` (standing in for the real Stage
4/5) sends each geometrically-located crop to Claude and asks "what do
you see here." This is a genuine improvement over the Phase-1 approach
in `checkUniformCompliance.ts` (whole-photo glance, no geometry) —
Claude only has to answer "what's in this small, already-located
region" instead of "find 18 things somewhere in this photo" — but it
is a vision-language judgment, not a trained detector's measurement.
The *position* is real (PnP + projection). The *identification* inside
that position is not yet backed by training data. See the plan file's
Risks section.

`reporting/report.py` (Stage 7) aggregates verdicts into a JSON report
+ annotated image (green/yellow/red boxes). Scoring weights are an
explicit placeholder — see `_scoring_note` in the report output.

## Setup

```bash
python3 -m venv .venv-tools        # from the repo root, if it doesn't exist yet
.venv-tools/bin/pip install -r cv-service/requirements.txt
cv-service/models/download_models.sh   # fetches the MediaPipe pose model
                                        # (YOLOv8n weights auto-download on first run)
```

## Running the service

```bash
cd cv-service
../.venv-tools/bin/uvicorn api.main:app --reload --port 8001
```

`POST /inspect` (multipart form): `photo` (file), `rank_tier`,
`gender`, `is_sikh`, `medal_row_count`. Requires `ANTHROPIC_API_KEY` in
the environment — the same secret already provisioned in Firebase
Secret Manager for `checkUniformCompliance`. Without it, stages 1-3-6
still run (you'll get a 503 at the vision-crop step) — useful for
testing the geometry alone.

```bash
curl -X POST http://localhost:8001/inspect \
  -F "photo=@/path/to/photo.jpg" \
  -F "rank_tier=specialist" \
  -F "gender=male"
```

## Running tests

```bash
.venv-tools/bin/pytest cv-service/tests/ -v
```

106 tests, all runnable with **zero external credentials** — the
Anthropic call is dependency-injected and replaced with a deterministic
fake client in every test (`client=` parameter on
`inspect_crop`/`inspect_resolved_rules`; see `tests/test_report_pipeline.py`
and `tests/test_api.py`). What they validate:

- `test_extract_anchors.py` — anchor extraction against the real body GLB.
- `test_pnp_projection.py` — PnP math against synthetic correspondences,
  including generalization to an anchor never used in the solve.
- `test_rule_engine.py` — rule condition filtering, paired-anchor crops.
- `test_report_pipeline.py` — the full Stage 1→7 pipeline against a real
  (rendered) photo, with a deterministic fake vision layer so the report
  aggregation, scoring, and annotated-image rendering are all exercised.
- `test_api.py` — the same, through an actual HTTP request to `/inspect`.
- `test_segmentation.py` — the trained YOLOv8n-seg model against the
  fixture render.
- `test_compare_phase1_phase2.py` — Phase-1 vs Phase-2 expected-item
  agreement in fake mode.
- `test_ground_truth_schema.py` — the real-photo labeling schema (see
  below); skips (not fails) the produced-label checks on a machine with
  no local `cv-service/data/labels/`, since that folder is gitignored.
- `test_pose_anchor_mapping.py` — `pose/anchor_mapping.py`'s BlazePose→anchor
  mapping (see below); its real-photo accuracy check also skips cleanly
  with no local labels.
- `test_geometry_camera_pose.py` / `test_geometry_project_rules.py` —
  `geometry/solve_camera_pose.py` + `geometry/project_rules.py` (see
  below).
- `test_segmentation_real_vs_synthetic_comparison.py` —
  `evaluation/compare_segmentation_real_vs_synthetic.py` (see below); its
  own real-vs-synthetic run also reports 0 real photos today.
- `test_verdict_engine.py` — `rules/rule_engine.py`'s `evaluate_verdicts()`
  + `segmentation/mask_geometry.py` (see below).
- `test_real_photo_sanity_check.py` —
  `evaluation/run_real_photo_sanity_check.py` (see below); includes a
  regression lock confirming the `no3_acc/` accessory reference images
  are correctly reported as "no person detected," not miscounted as
  usable real-photo data.

The one real photo used for the full-pipeline tests
(`tests/fixtures/rendered_army_no3_male_front.jpg`) is an offscreen
render of the actual reference body GLB — not a stock photo — since no
real soldier photo exists yet to test against. Regenerate it with
`tests/fixtures/generate_fixture.py` if the reference body changes.

## Regenerating anchors

Run whenever a reference body GLB changes:

```bash
.venv-tools/bin/python cv-service/utils/extract_anchors.py \
  --glb assets/3d/bodies/male_apose.glb \
  --out cv-service/rules/anchors.male.json
```

Left/right anchors are named by the **wearer's anatomy** (`left_*` = the
wearer's left = +x, image-right in a front photo — the same convention as
MediaPipe's landmarks), regardless of the GLB's socket names, which are
swapped on `male_apose.glb`; `glb_socket_names_swapped` in the output
records which pairs were renamed. After regenerating, re-fit the
landmark→socket offsets: `.venv-tools/bin/python cv-service/pose/calibrate_anchor_offsets.py --n 60`.

## Generating synthetic training data (bounding boxes)

```bash
.venv-tools/bin/pip install -r cv-service/training/requirements-training.txt
.venv-tools/bin/python cv-service/training/generate_synthetic_dataset.py \
  --n-renders 200 --out cv-service/synthetic_data/army_no3_male_v1
```

Renders the reference body + doctrine-anchored accessories from
randomized cameras and writes a COCO-shaped `annotations.json` — bounding
boxes are derived by projecting each accessory's actual mesh vertices
through the exact camera used to render, not guessed or hand-drawn.

## Segmentation — a real trained model, synthetic data only

```bash
.venv-tools/bin/python cv-service/training/generate_segmentation_dataset.py \
  --n-train 150 --n-val 30 --out cv-service/synthetic_data/seg_v1
.venv-tools/bin/python cv-service/training/train_segmentation.py \
  --data cv-service/synthetic_data/seg_v1/data.yaml --epochs 40 \
  --out cv-service/models/segmentation_v1
```

This one actually trains a model — `cv-service/segmentation/segment_uniform.py`
wraps the result as a real Stage 4, wired into `/inspect`'s `segmentation`
field. Masks are ground-truth-exact by construction (pyrender's
`RenderFlags.SEG` flat-color render mode, not an approximation), and
40 epochs of YOLOv8n-seg on `mps` took **~12 minutes**. Final validation
(on a held-out **synthetic** split — 30 renders of the same body from
different random cameras):

| Class | mAP50 (mask) |
| --- | --- |
| shirt / trousers / headwear / footwear | ~0.995 each |
| cap_badge | 0.904 |
| belt | 0.556 |
| arms_badge | 0.524 |
| epaulette | 0.496 |
| sleeve_rank | 0.222 |
| **overall** | **0.742** |

Read that table as: the large body regions (derived from a horizontal
plane-cut of the one continuous body mesh — see the generator's module
docstring for why `collar`/`pocket`/`sleeve` aren't separable classes)
are essentially solved *in the synthetic domain*; small accessories are
much harder, especially `sleeve_rank`. **None of this was validated
against a real photograph — zero exist in this project.** The
synthetic-to-real domain gap is completely open. Confirmed directly:
running the trained model on the fixture photo correctly finds
shirt/trousers/footwear at 0.96–0.99 confidence, and also visibly
reproduces a known, documented limitation — both hands, hanging near
hip height in the reference A-pose, get misclassified as `trousers`
(the plane-cut doesn't distinguish torso from arm at the same world
height). See `ChangeRequest/2026-08-05_cv-service-m2-synthetic-segmentation-model.md`
for the full account, including two real bugs hit and fixed while
building this (`pyrender.Scene.from_trimesh_scene` silently drops node
names, breaking `seg_node_map` lookups; the initial body-mesh slice
dropped the head from the RGB training images entirely).

## Real-photo ground-truth labeling (infrastructure only — 0 real photos)

`cv-service/labeling/` + `cv-service/data/` stand up the pipe for turning
real photos into ground truth the rest of this service can eventually be
measured against — **not** the real photos themselves, which don't exist
yet (see `ChangeRequest/2026-08-11_cv-service-real-photo-ground-truth-tooling.md`).

- `cv-service/data/real_photos/README.md` — the intake convention:
  `<subject_id>/<subject_id>__<angle>__<lighting>.jpg`.
- `cv-service/data/schemas/ground_truth.v1.schema.json` — versioned JSON
  Schema for one label file (15 anchor clicks + per-accessory polygons),
  generated by `labeling/schema.py` from the same `SOCKET_NAMES` /
  `CLASSES` lists the rest of the pipeline already uses — regenerate
  after changing either.
- `labeling/server.py` — a local FastAPI + single-page canvas UI
  (`labeling/templates/label.html`, no external JS/CSS) that walks a
  non-engineer through labeling one photo in the intake folder and
  writes a schema-validated label to `cv-service/data/labels/`.
- `cv-service/data/real_photos/` and `cv-service/data/labels/` are
  **gitignored** — they will hold photos of real servicemembers, which
  must never be committed.
- `labeling/render_standins.py` + `labeling/label_standins.py` — produced
  and labeled 3 **synthetic stand-in** photos (bare reference body GLB
  renders — no real person) to prove the tool works end-to-end, since
  zero real photos exist. Every label file this produces sets
  `is_synthetic_stand_in: true`, a required schema field so nothing
  downstream can mistake a stand-in for real validation data.

## Pose→anchor mapping (general coverage, not wired into `/inspect`)

`cv-service/pose/anchor_mapping.py`'s `estimate_anchor_pose(image_path) ->
dict` maps Stage 2's existing MediaPipe pose output onto **all 16**
`anchors.male.json` keys — no new model, reuses the pretrained
PoseLandmarker as-is. This is deliberately separate from
`calibration/pnp_solve.py`'s own narrower 7-anchor `CORRESPONDENCES`
(kept as-is, not touched); 8 of the 16 anchors have no BlazePose
equivalent and are confidence-penalized geometric heuristics rather than
detections — see the module docstring and
`ChangeRequest/2026-08-11_cv-service-pose-anchor-mapping.md` §4 for the
full per-anchor table. Not currently called from `/inspect` — it's a
standalone, tested capability, not a pipeline change.

```bash
.venv-tools/bin/python cv-service/pose/evaluate_pose_accuracy.py
```

prints synthetic vs. real-photo accuracy **as two separate rows, never
blended**. Measured against Milestone A's 3 synthetic stand-ins: mean
error 143.55px, median 131.05px, 92% coverage (800×1200px renders) — a
real, moderate-to-poor number, not a pass/fail gate. **The real-photo row
reads 0 photos** — same gap as ground-truth labeling above.

## Geometry — camera-pose solve + rule projection from the fuller pose estimate

`cv-service/geometry/solve_camera_pose.py` + `geometry/project_rules.py`
are a second, additive path alongside `calibration/pnp_solve.py` +
`rules/rule_engine.py` (neither of which is touched). The difference:
this path takes Milestone B's anchor-keyed 2D pose estimate directly and
can use up to 15 correspondences instead of `pnp_solve.py`'s fixed 7;
`project_rules.py` calls `rule_engine.resolve_rules()` internally and
adds `angle_deg`/`tolerance_deg`, which wasn't previously surfaced as its
own field.

```bash
.venv-tools/bin/python cv-service/geometry/evaluate_camera_pose_accuracy.py
```

Measured against Milestone A's 3 stand-ins (**known, not approximate,
ground-truth camera** — these are renders, so the exact camera pose used
is known exactly): reprojection error mean 32.1px (25.6–36.5px) looks
fine alone, but breaking translation error into components tells the
real story — lateral error is good (mean 6.1cm) while **depth error is
large and unstable (mean 61.9cm, up to ~1m)**, a real single-view-PnP
limitation (near-frontal body landmarks barely constrain depth), not a
bug. Good enough for 2D crop-region placement (what `project_rules.py`
needs); not yet trustworthy for anything depending on recovered depth
alone. **0 real photos**, so this whole table is synthetic-only.

> **Correction (2026-09-28, `ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`):**
> the depth error above was a bug, not a single-view limitation.
> `anchors.male.json` inherited the GLB's socket names, which are
> left/right-swapped relative to the wearer (CLAUDE.md §8 pass 8), while
> MediaPipe names landmarks anatomically — so every PnP solve paired
> mirrored points and converged to a camera with the body *behind* it,
> and this evaluator compared the solved rotation against identity (the
> wrong convention), grading that mirrored solution as near-perfect. With
> anatomical anchor names, a behind-camera guard, the true focal length
> and fitted landmark→socket offsets, the same three stand-ins solve to
> **1-4 cm depth error, 0.4-7° rotation, 1.5-6.7 px reprojection**. See
> "Accuracy program" below.

## Segmentation real-vs-synthetic comparison (tooling only — 0 real photos)

`cv-service/evaluation/compare_segmentation_real_vs_synthetic.py` runs
the trained `segmentation_v1` model against labeled real photos and
compares per-class mAP50 to its synthetic-only validation, side by side.
`evaluation/segmentation_label_conversion.py` converts Milestone A's
label JSON into the exact YOLO-seg format the original training used, so
`model.val()` computes both sides through the identical code path — not
a reimplemented metric.

```bash
.venv-tools/bin/python cv-service/evaluation/compare_segmentation_real_vs_synthetic.py
```

Today this reports **"Real photos found: 0 (skipped 3 synthetic
stand-ins)"** rather than a table — Milestone A's 3 labeled photos are
all synthetic stand-ins, not real. Re-running the synthetic side live
reproduces the exact previously-documented per-class numbers
(0.995/0.904/0.496/0.222/0.524/0.556/0.995), confirming the comparison
methodology is sound and ready — it just has nothing real to compare
against yet. `flag_regressions()` and the `Diagnosis` structure (root
causes, proposed fixes) exist and are tested but stay unpopulated until
real regressions exist to diagnose.

## Verdict engine — geometric pass/fail/missing/unverifiable (Army No.3 Male)

`rules/rule_engine.py`'s `evaluate_verdicts(resolved_rules, segmentation,
cm_per_px, image_width, image_height, camera_reliable=...)` compares
Milestone C's projected doctrine zones against the trained segmenter's
detected regions and returns one of `pass`/`fail`/`missing`/`unverifiable`
per accessory — tolerances come from doctrine's own `tolerance_cm`/
`tolerance_deg` fields, not invented numbers; `segmentation/mask_geometry.py`
adds mask centroid + orientation estimation. `unverifiable` (with a
stated reason) covers: no detector exists for that doctrine category (5
of 18 rules, always reported even if optional), the region falls outside
the frame (occlusion/extreme angle), the camera solve was unreliable, or
orientation couldn't be measured reliably — never forced into a
confident pass/fail the pipeline can't back up.

```bash
.venv-tools/bin/python cv-service/evaluation/evaluate_verdict_precision_recall.py
```

First script to chain B → C → the trained segmenter → a verdict
end-to-end. Against Milestone A's 3 stand-ins: `footwear`
precision/recall 1.0/1.0 (n=2, thin), every other accessory class 0
ground-truth-positive signal (correctly `N/A`, not a fake 0%), and
`standin02`'s out-of-frame feet correctly returned `unverifiable`
rather than a false `missing`. **0 real photos**, same as every other
tool in this file.

## `POST /check_uniform` — stable API contract + central config

`ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md` added a
second, additive endpoint alongside `/inspect`: `POST /check_uniform`, form
fields `image`, `uniform_type` (today only `army_no3_male`), `rank_tier`,
`gender`, `is_sikh`, `medal_row_count`, optional `view`/`body_type`/
`include_debug_image`. Same underlying pipeline as `/inspect`'s
`geometric_verdicts` field (anchor-mapping pose → PnP camera solve →
rule resolution → trained segmentation → `evaluate_verdicts`), but as the
endpoint's *primary* path — every failure is a hard, typed error
(`NO_PERSON_DETECTED`, `MULTIPLE_PEOPLE_DETECTED`, `POSE_UNRELIABLE`,
`SCALE_UNAVAILABLE`, `IMAGE_TOO_DARK`/`_BLURRY`/`_SMALL`/`_LARGE`/`_BRIGHT`,
`CORRUPTED_IMAGE`, `UNSUPPORTED_UNIFORM`, `SEGMENTER_UNAVAILABLE`), not a
best-effort secondary pass swallowed into an empty list. **Zero Anthropic
dependency** — pure geometry + the trained segmentation model.

Response shape: `{success, overall_status, overall_score, image_quality,
person, accessories[], summary}`, with each accessory carrying
`present`/`position_correct`/`confidence`/`status`/`visibility`/
`bounding_box`/`expected_position`/`detected_position`/`error`/
`doctrine_ref`/`message`. `status` is one of `CORRECT`/
`SLIGHTLY_MISALIGNED`/`INCORRECT`/`MISSING`/`UNCERTAIN` — the new
`SLIGHTLY_MISALIGNED` band (`rules/rule_engine.py`'s `evaluate_verdicts`,
additive `VerdictResult` fields) avoids a hard binary cut right at the
tolerance boundary. `api/response_schema.py` does the pure JSON mapping;
`api/validation.py` is the new Stage-0 image-quality gate (corrupted /
oversized / too small / too dark-or-bright / too blurry) that runs before
any model inference. `include_debug_image=true` returns
`debug_image_base64` (`reporting/report.py`'s `render_debug_image_b64`) —
expected-position markers, detected-position markers, and an error-vector
arrow between them per accessory.

`cv-service/config.py` centralizes every confidence/tolerance constant
that used to be scattered (and sometimes duplicated, e.g. the
segmentation-confidence `0.4` previously defined separately in
`rules/rule_engine.py` and `segmentation/segment_uniform.py`) across the
pipeline, each overridable via a `CV_SERVICE_<NAME>` environment variable
without editing source — useful for tuning against real photos once any
exist. This was a behavior-preserving refactor: every default matches
what the code already used.

Same caveat as everywhere else in this file: the underlying detection/
segmentation accuracy is unchanged by this work — still **synthetic-only,
0 real photos**. This plan makes the contract stable and explainable, not
more accurate.

## Flutter integration (dev-only)

`lib/features/ar_scanner/` now has a Phase-2 path alongside the shipped
Phase-1 (`checkUniformCompliance`) one: `CvServiceInspectionRepository`
calls this service's `/inspect` over HTTP, `CvServiceInspectionController`
drives it, and `ar_scanner_screen.dart` reaches it via a **long-press**
on the capture button (the default tap is untouched). Point a device at
a locally running `cv-service` with
`--dart-define=CV_SERVICE_BASE_URL=http://<host>:8001` (Android emulator:
`10.0.2.2`). See `ChangeRequest/2026-08-05_cv-service-remaining-milestones.md` —
this wiring is code-complete and passes `flutter analyze`/`flutter test`,
but has not been exercised against a running instance on a device.

Also new: `lib/features/ar_scanner/data/capture_quality_gate.dart`, an
on-device pose-quality check (via `google_mlkit_pose_detection`, a
previously unused dependency) that rejects a bad photo — no person,
torso not visible, camera tilted — before it reaches *either* backend.

## Real-photo Phase 1 sanity check (tooling only — not yet run)

Before investing in labeling or training on real data, the cheapest
possible test of whether the whole geometric approach holds up at all:

```bash
# Drop 15-20 real photos under cv-service/data/real_photos/<subject_id>/
# following the existing naming convention, then:
.venv-tools/bin/python cv-service/evaluation/run_real_photo_sanity_check.py
```

No labeling required — unlike `evaluate_verdict_precision_recall.py`
(which needs Milestone A-format ground-truth labels to score
precision/recall), this just runs person-detection → pose → camera-solve
→ segmentation against every photo and reports whether each stage holds
up or degrades (detection rate, pose anchor coverage, camera
solved/reliable rate, reprojection-error distribution, segmentation
region counts) — one bad photo never aborts the batch. Verified
mechanically via `--include-standins` against the 3 synthetic stand-ins
(not a real-world finding) and against a `no3_acc/` folder that turned
up in `cv-service/data/real_photos/` — individual accessory reference
pictures, not photos of a person, correctly reported as 0% detected
rather than silently counted as usable data. **Not run for its actual
purpose** — 0 real photos exist in this repo.

## Container image

`cv-service/Dockerfile` builds a container for this service.
**Unverified** — no Docker in the environment that authored it, so this
has been reviewed by hand against `requirements.txt` and the actual
file layout, not build-tested. Not deployed anywhere.

## Not built yet

- Any *trained* accessory detector (Stage 5 / Milestone 3) — still
  needs labeled data the same way segmentation did, just not built
  yet. `detectors/vision_crop_inspector.py` remains the stand-in.
- Any validation of the segmentation model (or a future detector)
  against a real photograph — zero exist in this project. This is the
  single biggest open risk across M2 and M3 both.
- Blender synthetic-data generation specifically — the generators
  above use `pyrender` instead (no Blender binary in this
  environment); swap in a Blender-based version later if useful,
  output shape is the same.
- Wiring into `checkUniformCompliance.ts` (i.e. making this the
  production path) — the Flutter app *can* reach this service now (see
  above), but only via an opt-in dev path; flipping the shipped default
  over is its own plan + device test per `CLAUDE.md` policy 1.5.
- Actual deployment to Cloud Run — the Dockerfile exists; nothing has
  been deployed anywhere.
- Wiring `/check_uniform` (or `/inspect`) into the Flutter app's
  production capture flow, or per-accessory GLB geometry extraction to
  auto-derive expected bounding-box sizes (today expected placement
  comes from hand-authored doctrine JSON only) — both deferred roadmap
  items noted in
  `ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md`.

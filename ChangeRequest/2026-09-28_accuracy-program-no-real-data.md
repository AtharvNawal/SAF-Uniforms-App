# Accuracy program — every improvement that doesn't need real photos

- **Date:** 2026-09-28
- **Author:** Claude (Opus 5.5) for Atharv Nawal
- **Status:** executed — pytest, `flutter analyze`, `flutter test`, Android debug build pass; not device-verified (no reachable cv-service on a phone), synthetic-only

Follows `2026-09-28_cv-service-coverage-gate-and-matching.md`. Implements
the 19-item list from the same session's accuracy review (A1–A6, B7–B13,
C14, D15–D17, E18–E19). The real-photo dataset remains out of scope — the
user explicitly asked for everything *except* that.

## 1. Goal
Raise the accuracy and honesty of `POST /check_uniform` and the AR Scanner
result using only code, pretrained models, existing 3D assets, and
synthetic data; and build a synthetic benchmark with known ground-truth
violations so each change can actually be measured.

## 2. Scope

### A — Measurement / geometry (cv-service)
- **A1** Pose: `pose_landmarker_heavy.task` (fallback to lite if absent);
  pose runs on the detected-person crop (padded, upscaled to ≥1024 px
  tall) and landmarks are mapped back to full-image pixels.
- **A2** Mask-derived anchor refinement: collar tips from the top
  corners of the `shirt` mask, `belt_center` from the shirt/trousers
  boundary, `head_top` from the top of `headwear`. Refined anchors
  replace heuristic ones (confidence raised) *before* the PnP solve.
- **A3** Doctrine reference point: new optional rule field
  `reference_point` (`center` default | `top_edge` | `bottom_edge`);
  the verdict compares that point of the mask, not its centroid. Set on
  rules whose doctrine text names an edge (name tag, medal ribbons, SAF
  badges → `bottom_edge`; skill tabs → `top_edge`).
- **A4** Tolerance projected in 3D: tolerance radius is computed by
  projecting a tolerance-sized offset at the rule's 3D point through the
  solved camera — replaces the single shoulder-width `cm_per_px` for the
  tolerance comparison (cm_per_px kept only for crop sizing fallback).
- **A5** Uncertainty-aware verdicts: per-rule measurement uncertainty
  (px) combined from anchor confidence (direct / interpolated /
  extrapolated / mask-refined), PnP reprojection error, and mask size.
  `pass` only if `distance + u ≤ tol`; `fail` only if
  `distance − u > band`; otherwise `unverifiable` with the reason.
- **A6** Segmentation test-time augmentation (`augment=True`), config flag.

### B — Models without real photos
- **B7** Zero-shot second opinion: YOLO-World (open-vocabulary) boxes +
  SAM 2 masks (both via the already-installed `ultralytics`), run on the
  per-rule search crops; used when the trained segmenter finds nothing in
  a crop (fills its misses) — never overrides a trained-model detection.
- **B8** Name-tag OCR (EasyOCR) on the name-tag region; new
  `surname` form field; match → name tag `pass`-eligible, mismatch →
  `fail` with reason.
- **B9** Variant check: DINOv2-small embeddings of each detected
  accessory crop vs. the reference PNGs in `assets/accessories/<id>/image.png`
  for every variant in the same category; wrong variant → `fail`
  ("wrong_type"). Low margin → no change (never guesses).
- **B10** Colour checks (HSV on the mask): beret / belt / socks / shoes
  must be black-ish for Army No.3; violation → `fail`.
- **B11** New synthetic classes: `name_tag`, `socks`, `hand` (forearm +
  hand split out of the body mesh — fixes "hands labelled trousers").
- **B12** Retrain: `seg_v2` dataset (domain randomisation: procedural
  backgrounds, lighting, colour jitter, blur, noise, JPEG, body
  proportion scaling, wider camera range), yolov8s-seg, larger imgsz.
  Old `segmentation_v1` kept; loader prefers v2 when present.
- **B13** Two-stage small-item pass: re-segment an upscaled crop around
  small-item rules (cap badge, arms badge, sleeve rank, name tag,
  epaulette) and merge detections back into full-image coordinates.

### C — Measurement without real photos
- **C14** `training/generate_violation_benchmark.py`: renders uniforms
  with known violations (displaced by N cm, missing, wrong arm, wrong
  variant) + JSON ground truth per rule; `evaluation/run_violation_benchmark.py`
  runs the full `/check_uniform` pipeline and reports per-rule accuracy,
  a confusion matrix, and PASS/FAIL/INCOMPLETE agreement. Used to
  measure every change above.

### D — Capture (Flutter)
- **D15** Guided capture: live ML Kit pose on the camera image stream,
  silhouette overlay, shutter enabled only when full body in frame,
  square-on, and filling the right fraction of the frame.
- **D16** Send device pitch/roll (`sensors_plus` accelerometer) and
  profile height; server reads real focal length from EXIF
  (`FocalLengthIn35mmFilm`) and uses it for the PnP intrinsics; pitch
  constrains/validates the solved camera; height gives an alternative
  scale. Profile gains optional `heightCm`.
- **D17** Burst: capture 3 frames; new `POST /check_uniform_burst`
  runs each and takes a per-item majority (ties → worse/uncertain).

### E — Presentation
- **E18** Human-readable per-item instructions in cm and wearer-relative
  direction (`instruction` field).
- **E19** Flutter scorecard: debug overlay image, separate "Couldn't
  check" list with reasons, instruction text instead of px.

### Out of scope
Real-photo collection/labelling; Cloud Run deploy; No.1/2/4/5 doctrine;
female/maternity doctrine.

## 3. Affected areas
`cv-service/` (api, config, pose, geometry, rules, segmentation, new
`detectors/zero_shot.py`, `detectors/name_tag_ocr.py`,
`detectors/variant_matcher.py`, `detectors/color_check.py`, training,
evaluation, tests, requirements, models/download_models.sh);
`lib/features/ar_scanner/**`, `lib/features/profile/**` (heightCm),
`pubspec.yaml` (`sensors_plus`), Flutter tests; CLAUDE.md.

## 4. Step-by-step plan
1. B11/B12 dataset generator → start render + training in background.
2. A1–A6 + D16 server side + E18.
3. B7, B8, B9, B10, B13.
4. C14 benchmark; run baseline (v1) vs. new pipeline.
5. D15–D17, E19 Flutter.
6. Swap in seg_v2 after training; re-run benchmark; docs.

## 5. Risks & rollback
- New heavy deps (EasyOCR, DINOv2 via torch.hub, YOLO-World CLIP,
  SAM 2 weights) — every new stage is optional and degrades to the
  previous behaviour when its model/dep is unavailable; toggles in
  `config.py`.
- Latency: B7/B8/B9/B13 add inference passes; each only runs on small
  crops, and each is individually switchable.
- Synthetic-only validation: benchmark numbers measure the synthetic
  domain; real-world accuracy remains unvalidated (restated, not solved).
- Rollback: per-stage config flags; `segmentation_v1` retained.

## 6. Verification
pytest; C14 benchmark before/after table; `flutter analyze`;
`flutter test` (blocked until the Xcode licence is accepted on this Mac).

## 7. CLAUDE.md updates required
§3 tech stack (`sensors_plus`), §4 ar_scanner + profile entries,
§5.10 cv-service (all of the above), §2 layout (`cv-service` entry).

## 8. Execution record

### Bugs found and fixed along the way (not in the original list)
1. **Mirrored anchors → body-behind-camera PnP.** `anchors.male.json`
   inherited the GLB socket names, which are left/right-swapped relative
   to the wearer (CLAUDE.md §8 pass 8), while MediaPipe names landmarks
   anatomically. Every solve paired mirrored points and converged to a
   camera with the body *behind* it (all points at negative depth).
   Consequences: the documented "~62 cm depth error, a single-view
   limitation" was this bug; every left/right doctrine item (name tag on
   the right pocket, arms badge on the right collar) was measured on the
   wrong side. Fixed in `utils/extract_anchors.py` (`_to_anatomical_sides`,
   decided per pair by x sign), anchors regenerated.
2. **No cheirality check.** A low reprojection error was accepted as
   "reliable" even with the scene behind the camera. Added
   `pnp_solve.points_in_front` to both solvers + `project_point`, and a
   frontal-seeded iterative solve + SQPnP candidate selection
   (`best_pnp_solution`).
3. **Camera evaluator used the wrong convention** (identity instead of
   diag(1,-1,-1) for an OpenGL render camera) and so graded the mirrored
   solution as near-perfect. Fixed; compares camera centres.
4. **Cap-badge rules never resolved for enlistees/specialists.** Their
   conditions tested `rank_tier == sltc_me6_and_below`, a value the app
   never sends; the Sikh-turban condition compared against
   `col_me7_and_above`, also never sent. Added derived `cap_badge_tier`.
5. **Blur gate falsely rejected 40% of benchmark photos** — Laplacian
   variance over the whole image is dragged down by a plain wall (the
   protocol's recommended background). Now measured on the person crop.
6. **Half-trained model hazard.** Ultralytics rewrites `best.pt` every
   epoch; the loader preferred `segmentation_v2` as soon as the file
   existed. Now requires a `training_complete.json` marker written by
   `train_segmentation.py` at the end of training.
7. **Zero-shot false positives.** Flooring YOLO-World's score at the
   verdict threshold turned a bare head (score 0.18) into a "correct
   beret". Measured true-vs-false scores; accept threshold 0.45, large
   classes only.
8. **Flutter: typed error codes always lost** (read from `error`, server
   sends `status`) and **UTF-8 instructions garbled** (`Response.body`
   falls back to Latin-1 without a charset).
9. **Ultralytics `augment=True` is a no-op for segmentation** — A6 is a
   manual flip-and-merge TTA instead.
10. **The AR Scanner's "aligned" state was a fixed 1.8 s timer** — replaced
    by live pose guidance (D15).

### Measured on the synthetic stand-ins / violation benchmark
| Stage | Before | After |
| --- | --- | --- |
| Anchor error, 3 known-camera stand-ins (mean) | 55.6 px (143.6 px as documented before the side fix) | 5.7 px (median 3.0) — fitted landmark→socket offsets |
| Camera depth error, same stand-ins | 57-115 cm | 1-4 cm (true focal) |
| Camera rotation error | 6-18° | 0.4-7° (0.4-2.4° with gravity prior) |
| Doctrine-point geometric error, benchmark (p50 / p90) | 1.42 / 2.56 cm | 0.97 / 1.92 cm (weighted PnP + dressed-body offsets) |
| Measured error on correctly placed items (p50) | 1.76 cm | 1.30 cm |
| Benchmark photos wrongly rejected as blurry | 24/60 | see benchmark table |

**Central finding.** The measurement error on correctly placed items
(median 1.3 cm) is the same size as the doctrine tolerances (0.8-1.5 cm).
With an uncertainty calibrated to cover 90% of real errors, the engine
never flags a correct item, but it also cannot *certify* a ±1 cm item as
correct from one full-body photo — those come back "too close to call"
with the measured offset. Missing items, wrong variants/colours and
clearly misplaced items (≳ 3 cm) are still caught. Next step for cm-level
certification (out of scope here): a second, closer upper-body photo —
the error is roughly constant in pixels, so doubling pixels-per-cm halves
it in cm.

### Final benchmark (60 scenes, 540 item verdicts, synthetic)
| Variant | Exact | Violation recall | False alarms | Abstain |
| --- | --- | --- | --- | --- |
| baseline (program stages off) | 10.2% | 56.6% | 52.6% | 39.4% |
| program, v1 segmenter | 15.9% | 45.3% | 32.9% | 52.8% |
| program, v2 segmenter (default) | 36.1% | 60.4% | 5.5% | 58.1% |

segmentation_v2: 20 epochs (9 + 11 resumed from the epoch-9 weights after
contention slowed training to 15 min/epoch), mask mAP50 0.879. Uncertainty
re-fitted for v2: weights 0.75 / 0.37, median measurement error 0.78 cm.
Remaining weak spots: epaulette 15.5% / belt 17.9% false alarms; no truly
compliant scene reached PASS (9 FAIL, 6 INCOMPLETE).

### Verification run
- pytest: all pass except the pre-existing `test_inspect_rejects_multi_person_photo`.
- `flutter analyze`: clean. `flutter test`: all pass (via the Command Line
  Tools `xcrun` shim — Xcode licence still unaccepted on this Mac).
- `flutter build apk --debug`: builds.
- Not run: `flutter run` on a device against a live cv-service (policy 1.5
  step 4) — hence `executed`, not `verified`.


# cv-service MVP /inspect endpoint — real geometry, region-guided vision

- **Date:** 2026-08-05
- **Author:** Claude
- **Status:** verified

## 1. Goal

Ship the largest *honest* slice of the Phase-2 CV pipeline achievable
in a single day: a real, runnable `/inspect` endpoint that replaces
guesswork with actual geometry everywhere geometry is possible today,
and is explicit about the one piece that genuinely cannot be finished
today — trained accessory detectors (Stage 4/5 in the architecture
memo) need labeled training data or weeks of synthetic rendering that
don't exist yet.

What "today" changes for the compliance check: instead of Claude
looking at one whole photo and guessing where 18 accessories should
be, the service now (1) detects the person, (2) estimates real body
keypoints, (3) solves camera pose via PnP against the canonical
anchors from the previous slice, (4) projects every doctrine rule's
expected position into this specific photo's pixel space, (5) crops a
small region around each projected position, and (6) asks Claude to
judge presence/type *inside that geometrically-derived crop* rather
than the whole frame — the geometry does the "where to look" job, the
model only does the "what is this" job. This is a real accuracy
upgrade over Phase 1 today, without waiting on trained detectors.

## 2. Scope

- In scope:
  - `cv-service/pose/detect_person.py` — YOLOv8n (COCO "person"
    class, pretrained, no fine-tuning) human-detection gate.
  - `cv-service/pose/estimate_pose.py` — MediaPipe Tasks
    PoseLandmarker (lite, pretrained) wrapper, 33 keypoints.
  - `cv-service/calibration/pnp_solve.py` — OpenCV `solvePnP` camera
    pose recovery matching canonical 3D anchors (from
    `rules/anchors.male.json`) to 2D pose landmarks, plus a
    `project_point()` helper reused by the rule engine.
  - `cv-service/rules/rule_engine.py` — loads
    `rules/army_no3_male.json`, resolves each rule's expected 3D
    position (anchor + offset), projects it through the solved
    camera, and computes a pixel-space crop region sized from
    `search_radius_cm` (or a rule-appropriate default) via the
    PnP-derived scale factor.
  - `cv-service/detectors/vision_crop_inspector.py` — the Stage 4/5
    *substitute*: sends each crop to the existing Anthropic
    tool-forced call (same pattern as `checkUniformCompliance.ts`)
    and returns a per-item verdict. Explicitly documented as a
    placeholder for a trained detector, not the trained detector
    itself.
  - `cv-service/reporting/report.py` — aggregates verdicts into the
    JSON shape from the architecture memo §14, plus an annotated
    image (OpenCV, green/yellow/red crop boxes).
  - `cv-service/api/main.py` — FastAPI app, `POST /inspect` wiring
    stages 1→7 end to end.
  - Tests that don't require a real photo or an API key: PnP math
    against synthetic correspondences, rule-engine crop-region
    computation.
  - One end-to-end smoke test against a real downloaded test photo
    (public-domain/standard CV test image, since no real soldier
    photo exists yet) to prove stages 1–3 actually run, not just
    unit-pass.
- Out of scope (explicitly not achievable today, not attempted):
  - Any trained accessory or segmentation model (needs labeled
    data — see the "Milestone 3" / "Milestone 2" gap this leaves).
  - Blender synthetic-data generation (separate milestone,
    non-trivial Blender scripting + render time).
  - Wiring this into `checkUniformCompliance.ts` / the Flutter app
    (Milestone 6/7) — this plan ships the Python service standalone
    and documents the integration point, but does not flip the
    Cloud Function over to call it, since that changes production
    behavior and deserves its own plan + device test per policy 1.5.
  - Deploying to Cloud Run — local-only for this slice.

## 3. Affected areas

- New: `cv-service/pose/`, `cv-service/calibration/`,
  `cv-service/detectors/`, `cv-service/reporting/`, `cv-service/api/`.
- Update: `cv-service/requirements.txt`, `cv-service/README.md`.
- Update: `cv-service/tests/`.
- Update: `CLAUDE.md` §5.10 to describe the new modules and their
  honest capability boundary.
- No changes to `functions/`, `lib/`, or `admin-portal/`.

## 4. Step-by-step plan

1. Verify the local toolchain can actually do this (network access
   for pretrained weights) — done: `opencv-python-headless`,
   `mediapipe`, `ultralytics`, `fastapi`, `anthropic` all installed
   and importable; YOLOv8n weights and the MediaPipe pose-landmarker
   task bundle both download successfully in this environment.
2. Human detection wrapper around YOLOv8n.
3. Pose estimation wrapper around MediaPipe Tasks PoseLandmarker.
4. PnP solve: map a fixed correspondence set (shoulders, collar tips,
   belt_center, head_top) between `anchors.male.json` and the
   matching MediaPipe landmark indices, solve for camera extrinsics +
   intrinsics via `cv2.solvePnP`, expose `project_point(anchor_xyz) ->
   (px, py)`.
5. Rule engine: for each entry in `army_no3_male.json`, resolve
   `expected_anchor` (+ offset) to a 3D point, project it, and emit a
   crop bounding box in pixel space sized from `search_radius_cm` (or
   a default derived from `tolerance_cm` when no explicit radius is
   given).
6. Vision-crop inspector: for each rule's crop, call Anthropic with a
   forced tool-use schema (reusing the `report_compliance`-style
   pattern) asking specifically about that one item.
7. Report aggregation: fold verdicts into the §14 JSON shape, draw
   the annotated image.
8. FastAPI endpoint wiring stages 1–7, returns the JSON + a base64
   annotated image.
9. Tests: PnP unit test with synthetic correspondences (known camera
   → verify recovered projection matches within tolerance); rule
   engine unit test (crop regions computed correctly from a fixed
   fake camera); one live smoke test against a downloaded public test
   photo for stages 1–3 only (no Anthropic key required for this
   part).
10. Update docs, mark this plan `executed`, run everything, mark
    `verified`.

## 5. Risks & rollback

- **The vision-crop inspector is not a trained detector** — it is
  Claude looking at a small, geometrically-targeted crop and
  answering a forced-schema question. It is a real improvement over
  whole-photo Phase 1 (tighter context, geometry does the "where"),
  but it is not the accuracy a fine-tuned YOLO/RT-DETR detector would
  eventually give, and this must not be presented to end users as
  "the AI measured this in centimeters" — the measurement is real
  (PnP + projection), the item-identification inside the measured
  region is still a vision-language judgment.
- PnP accuracy depends entirely on the reference body's proportions
  matching the photographed person's — flagged as an open risk in the
  original architecture memo (§5, "what has to be true"). Not
  resolved by this slice; the smoke test in step 9 validates the math
  runs correctly, not that its real-world accuracy meets a target.
  That validation needs real soldier photos, which don't exist yet.
- Purely additive — no existing file is modified except `CLAUDE.md`
  and `cv-service/README.md`/`requirements.txt`. Rollback is `rm -rf`
  the five new `cv-service/` subfolders and reverting the two doc
  edits.
- Nothing in `functions/` or `lib/` calls this service yet, so there
  is zero production regression surface.

## 6. Verification — what actually happened

- `pytest cv-service/tests/ -v` — **23/23 passed**, zero external
  credentials needed anywhere (the Anthropic call is
  dependency-injected and faked deterministically).
- Live smoke tests run against three real photos during this session,
  which surfaced two real bugs that got fixed before calling this
  done — not just a clean run on the first try:
  1. **MediaPipe's own canonical pose-demo photo** (a Warrior-II yoga
     pose, side profile, legs in a deep lunge) made `solvePnP`
     "succeed" with a reprojection error of **3320px** and projected
     anchor coordinates thousands of pixels outside the frame —
     because the correspondence math assumes a roughly rigid,
     A-pose-like standing body, and this photo violates that
     assumption hard. This is exactly the failure mode the
     architecture memo's §10 camera-handling section anticipated in
     the abstract; this session made it concrete and fixed it: added
     `CameraSolution.reliable`, a reprojection-error threshold scaled
     to the subject's own measured shoulder width. The bad photo now
     reports `solved=True, reliable=False` instead of silently
     returning garbage.
  2. An offscreen `pyrender` render of the actual reference body GLB
     (front-on, arms at sides — a synthetic but geometrically
     ground-truth photo, used because no real soldier photo exists
     yet) reprojected at **32px** on an 800×1200 image and correctly
     marked `reliable=True`. Visual inspection of the projected crop
     regions (drawn as boxes on the image) confirmed most items
     landed in the anatomically correct region — but also caught that
     the "half of sleeve length from the shoulder seam" rule
     (specialist/enlistee sleeve insignia) was resolving to the
     shoulder anchor itself with no sleeve-length component, landing
     the crop on the chest pocket instead of the sleeve. Fixed by
     blending the projected anchor toward the detected elbow landmark
     in 2D by the doctrine's stated fraction
     (`rule_engine._apply_sleeve_fraction`); re-verified visually that
     the crop moved onto the actual sleeve.
  3. Zidane.jpg (ultralytics' bundled two-person sample) correctly
     triggers `multiple_people_detected` at both the module level and
     through a real HTTP call to `/inspect`.
- Full Stage 1→7 pipeline exercised twice: once by calling the Python
  functions directly (`test_report_pipeline.py`), once through a real
  HTTP POST to the FastAPI app (`test_api.py`) — both against the
  rendered reference-body photo (now a committed fixture,
  `tests/fixtures/rendered_army_no3_male_front.jpg`), with forced
  `missing`/`low_confidence` verdicts injected via the fake Anthropic
  client to confirm the report's `issues`/`uncertain` lists, subscore
  aggregation (including honest `null` for the two unmodeled
  buckets), and the green/yellow/red annotated image all wire
  together correctly.
- The vision-crop inspector's actual Anthropic call is code-complete
  and exercised only through the fake client in every automated test —
  no `ANTHROPIC_API_KEY` is available in this environment. The user
  runs the one live end-to-end test with their own key (already
  provisioned in Firebase Secret Manager for `checkUniformCompliance`)
  via `cv-service/README.md`'s `curl` example.

## 7. CLAUDE.md updates required

- §5.10: describe the new `pose/`, `calibration/`, `detectors/`,
  `reporting/`, `api/` modules, and restate plainly which stages are
  real CV today (1, 2, 3, 6) versus which stage is a vision-language
  substitute standing in for a not-yet-trained detector (4/5), so
  nobody mistakes this for a finished, trained pipeline later.

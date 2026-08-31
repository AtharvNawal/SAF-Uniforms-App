# cv-service — real-photo ground-truth intake, labeling schema, and labeling tool

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** verified

## 1. Goal

Every accuracy number produced so far by `cv-service` (PnP reliability, the
YOLOv8n-seg mAP50 table, the vision-crop stand-in) is measured against
synthetic renders of one reference body GLB — the README and `CLAUDE.md`
§5.10 both flag this as the single biggest open risk, repeated across every
prior plan file. This plan does not fix that gap; it stands up the
**infrastructure** so the gap *can* be closed later: a place to put real
photos, a versioned schema for what "ground truth" means for one photo (15
anchor points + per-accessory segmentation polygons, matching the exact
vocabulary the rest of the pipeline already uses), and a small tool so a
non-engineer can produce a label file in under two minutes without touching
Python.

No later milestone's accuracy claims are meaningful without this existing
first. This is explicitly a data-tooling slice — nothing about the trained
model, the Cloud Function, or the Flutter app changes.

## 2. Scope

- In scope:
  - `cv-service/data/real_photos/` intake convention (folder/filename
    convention encoding subject id, angle, lighting), documented in a
    `README.md` in that directory.
  - A versioned ground-truth JSON schema
    (`cv-service/data/schemas/ground_truth.v1.schema.json`), generated from
    the two lists that already exist elsewhere in the codebase rather than
    hand-duplicated: the 15 socket names in
    `cv-service/utils/extract_anchors.py`'s `SOCKET_NAMES`, and the 9
    segmentation classes in
    `cv-service/training/generate_segmentation_dataset.py`'s `CLASSES`. One
    label file = one photo: per-anchor pixel click (or an explicit
    not-visible flag) for all 15 anchors, plus zero or more per-accessory
    polygon instances tagged with one of the 9 class names.
  - `cv-service/labeling/` package: `schema.py` (builds the schema dict from
    the two existing lists above), `validate.py` (loads the generated schema
    file and validates a label dict against it via `jsonschema`), `server.py`
    (a small FastAPI app + a single self-contained HTML/canvas page — no
    external JS/CSS — that walks an annotator through clicking the 15
    anchors in order, marking any occluded one not-visible, then optionally
    drawing a polygon per visible accessory; POSTs to `/save`, which
    validates and writes the label JSON, and advances to the next
    unlabeled photo in the intake folder).
  - `cv-service/tests/test_ground_truth_schema.py` — validates the schema
    against a hand-built valid label, and against several deliberately
    broken ones (missing anchor, bad enum value, `present: true` without a
    polygon, wrong `schema_version`), plus (once produced) the 3 label
    files this plan's verification step writes.
  - New dependency: `jsonschema` (added to `cv-service/requirements.txt`,
    installed into the shared `.venv-tools`) — the standard library for
    "validate this dict against this JSON Schema document," which is
    literally what the task requires; hand-rolling that check would either
    duplicate `jsonschema` badly or silently stop being "validated against
    the schema file."
  - Since **zero real photographs exist anywhere in this repository** (
    confirmed by search before writing this plan — see §5), the mandated
    "personally label 3 photos end-to-end" verification step uses 3
    synthetic stand-in renders of the existing reference body GLB, produced
    by a new `cv-service/labeling/render_standins.py` (same `pyrender`
    off-screen technique as the existing
    `tests/fixtures/generate_fixture.py`, at 3 different camera
    distances/lighting intensities so at least one variant crops a couple
    of anchors out of frame and exercises the not-visible path). Every
    stand-in's label file sets `is_synthetic_stand_in: true` — a field the
    schema requires on every label file, real or not, so nothing downstream
    can accidentally treat a stand-in as real data.
  - `.gitignore` update: `cv-service/data/real_photos/` and
    `cv-service/data/labels/` — these will eventually hold photos of real
    servicemembers, so they must never be committed (same reasoning as the
    existing `secrets/` and `cv-service/models/` entries, plus a privacy
    dimension neither of those has). The schema file itself
    (`cv-service/data/schemas/`) is small, has no PII, and is committed
    normally.
- Out of scope:
  - Collecting or sourcing any actual real photo of a person. This plan
    only builds the intake pipe; filling it is a separate, non-engineering
    task (get a consenting subject, a camera, and doctrine-compliant
    uniform pieces in front of it).
  - Any change to `functions/`, `lib/`, `checkUniformCompliance.ts`, or the
    trained segmentation model.
  - Training or retraining anything against the labels this tooling
    produces — that's the milestone *after* real photos exist, per the
    goal statement above.
  - A production-grade web app for labeling (auth, multi-user review,
    inter-annotator agreement). This is a local single-user tool.

## 3. Affected areas

- New: `cv-service/labeling/` (package: `schema.py`, `validate.py`,
  `server.py`, `render_standins.py`, `templates/label.html`).
- New: `cv-service/data/real_photos/README.md` (intake convention) +
  gitignored `real_photos/` and `labels/` subfolders (populated at
  verification time with 3 stand-ins).
- New: `cv-service/data/schemas/ground_truth.v1.schema.json` (committed,
  generated — regenerate via `labeling/schema.py`'s CLI if `SOCKET_NAMES`
  or `CLASSES` ever change).
- New: `cv-service/tests/test_ground_truth_schema.py`.
- Update: `cv-service/requirements.txt` (add `jsonschema`).
- Update: `.gitignore`.
- Update: `cv-service/README.md` and `CLAUDE.md` §5.10 (per policy 1.2 —
  this changes `cv-service/`'s folder layout).

## 4. Step-by-step plan

1. Confirm zero real photos exist anywhere in the repo (done — see §5
   below, and the "0 real photos" line this plan's final report will
   restate explicitly per the requester's instruction).
2. Write `cv-service/data/real_photos/README.md`: directory layout
   `real_photos/<subject_id>/<subject_id>__<angle>__<lighting>.jpg`,
   `angle ∈ {front, back, left_3q, right_3q}`, `lighting ∈ {indoor_bright,
   indoor_dim, outdoor_overcast, outdoor_sunny}`, `subject_id` an
   anonymized token (never a real name), plus a privacy note that this
   folder is gitignored.
3. Write `cv-service/labeling/schema.py`: imports `SOCKET_NAMES` from
   `utils.extract_anchors` and `CLASSES` from
   `training.generate_segmentation_dataset`, assembles the JSON Schema
   dict (draft 2020-12), with a CLI that writes
   `cv-service/data/schemas/ground_truth.v1.schema.json`.
4. Write `cv-service/labeling/validate.py`: `load_schema()` +
   `validate_label(data: dict) -> list[str]` (empty list = valid) using
   `jsonschema.Draft202012Validator`, collecting every error rather than
   raising on the first.
5. Write `cv-service/labeling/server.py`: FastAPI app serving one
   self-contained HTML page (`templates/label.html`, vanilla JS canvas, no
   CDN dependency) that (a) loads the next unlabeled photo found under
   `--intake-dir` (any photo under it without a matching file in
   `--out-dir`), (b) walks the annotator through the 15 anchors in a fixed
   order with a "not visible" button per anchor, (c) lets the annotator
   toggle each of the 9 accessory classes present/absent and draw a
   polygon for each present one, (d) POSTs the assembled label dict to
   `/save`, which calls `validate_label`, writes the JSON to `--out-dir` on
   success, and returns the next photo (or "all labeled") — errors are
   returned inline instead of a 500 so a mislabel is fixable without
   losing work.
6. Write `cv-service/labeling/render_standins.py`: renders 3 stand-in
   photos of the existing `assets/3d/bodies/male_apose.glb` (bare body,
   `pyrender` offscreen, same technique as
   `tests/fixtures/generate_fixture.py`) at 3 different camera
   distances/light intensities, using the actual camera pose + intrinsics
   to also compute each anchor's true projected pixel position (so the
   labeling pass in step 8 uses geometrically-correct coordinates, not
   guesses) and each anchor's in-frame/out-of-frame visibility.
7. Update `cv-service/requirements.txt`, `.gitignore`, `cv-service/README.md`,
   `CLAUDE.md` §5.10 + §2.
8. Run `render_standins.py`, boot `labeling/server.py`, and drive its real
   `/save` endpoint for all 3 stand-ins (see §6 for exactly how "my own
   tooling" is interpreted here, since an agent has no mouse) —
   `is_synthetic_stand_in: true` on every one, at least one variant with
   ≥1 anchor marked not-visible (cropped out of frame) to exercise that
   path, and at least the `shirt`/`trousers` accessory classes drawn as
   present (everything else `present: false`, since the bare placeholder
   body has no other accessory geometry to trace).
9. Write `cv-service/tests/test_ground_truth_schema.py`: schema-only unit
   tests (valid minimal label passes; missing anchor / bad enum /
   `present: true` without `polygon_px` / wrong `schema_version` each
   fail) plus a parametrized test that loads and validates all 3 files
   produced in step 8.
10. Run the full `cv-service` suite, update `CLAUDE.md`, mark this plan
    `executed`, then `verified` once §6 below is satisfied.

## 5. Real-photo count (confirmed before writing this plan)

**Zero.** Searched the full repo for image files outside known
non-uniform asset directories (`ios/`, `admin-portal/`, launcher icons,
etc.) and specifically under `cv-service/`: every image that exists there
is either a `pyrender` synthetic render (`tests/fixtures/`,
`synthetic_data/seg_v1/`) or a training-diagnostic plot
(`models/segmentation_v1/*.png` — confusion matrices, PR curves). No
`real_photos/` or equivalent directory existed before this plan. This
matches every prior plan file's own stated caveat and is why this
milestone's step 8 verification explicitly uses synthetic stand-ins,
flagged as such in both the label schema and this document, rather than
silently presenting them as real.

## 6. Risks & rollback

- **Biggest risk: schema drift from the pipeline it's meant to measure.**
  If `SOCKET_NAMES` or the segmentation `CLASSES` list ever change and
  `ground_truth.v1.schema.json` isn't regenerated, old label files would
  validate against a schema that no longer matches what the rest of the
  pipeline expects. Mitigated by generating the schema file *from* those
  two source-of-truth lists (step 3) rather than hand-copying them, and by
  `test_ground_truth_schema.py` failing loudly if regeneration is skipped
  after such a change (the test always regenerates-and-compares rather
  than trusting the committed file blindly — see step 9's test list).
- **The stand-in photos are not real photos** and must never be mistaken
  for validation of real-world accuracy — mitigated by
  `is_synthetic_stand_in` being a required schema field (not optional,
  not inferable from the filename alone) and by this plan's own language
  never calling them "test photos" without the "synthetic stand-in"
  qualifier.
- **"My own tooling" for an agent with no mouse:** the labeling *server*
  and its `/save` validation path are real and exercised for real (an
  actual HTTP POST against the actual running FastAPI app), but the pixel
  coordinates fed into that POST are computed from the known camera
  projection rather than clicked in a browser by a human. This is
  disclosed explicitly rather than implied — see step 8 and the final
  report.
- Low blast radius otherwise: everything new is additive
  (`cv-service/labeling/`, `cv-service/data/`), nothing in `functions/` or
  `lib/` is touched, and `real_photos/`/`labels/` are gitignored so
  nothing produced during verification risks being committed. Rollback is
  `rm -rf cv-service/labeling cv-service/data` plus reverting the
  `requirements.txt`/`.gitignore`/README/CLAUDE.md edits.

## 7. Verification

- `.venv-tools/bin/pytest cv-service/tests/ -v` — **46/46 passed** (30
  pre-existing + 16 new in `test_ground_truth_schema.py`, including a
  parametrized check over the 3 produced stand-in labels and a
  schema-drift guard comparing the committed schema file against a fresh
  `build_schema()`).
- 3 stand-in label files produced via `labeling/render_standins.py` (3
  `pyrender` renders of the bare reference body GLB, one cropped close
  enough that `left/right_ankle` + `left/right_foot_top` land outside the
  frame) then `labeling/label_standins.py`, which drove the actual
  running `labeling/server.py` app's `/save` endpoint (via FastAPI's
  `TestClient`) with anchor coordinates computed from the render camera's
  own projection — not mouse clicks; see §6's 3rd risk for the full
  disclosure. All 3 wrote to `cv-service/data/labels/*.json`, all 3
  validate cleanly, all 3 correctly carry `is_synthetic_stand_in: true`.
- Also smoke-tested `labeling/server.py`'s `GET /` route directly (not
  just `/save`) against a fresh empty `--out-dir` — 200, serves the
  canvas HTML with the first unlabeled stand-in's config embedded.
- `flutter analyze` / `flutter test` not required — no Dart touched.

## 8. CLAUDE.md updates required

- §2 top-level layout: add `cv-service/labeling/` and `cv-service/data/`
  entries.
- §5.10: a short paragraph on the ground-truth labeling tool, the schema
  location, the intake convention, and — same load-bearing caveat as
  everywhere else in this section — that it currently holds 0 real photos.

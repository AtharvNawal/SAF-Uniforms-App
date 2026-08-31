# CV-service scaffold + GLB anchor extraction (Milestone 5 slice)

- **Date:** 2026-08-05
- **Author:** Claude
- **Status:** verified

## 1. Goal

Stand up the foundation of the Phase-2 uniform-compliance CV pipeline
described in the architecture memo ("Reading a Uniform the Way an
Inspector Does") without requiring any trained models, GPU, or new
infra: turn the reference body GLB's existing 15 named sockets into a
static, versioned "canonical anchor" file, and transcribe the Army
No.3 Male doctrine into a machine-readable rule set. This is the
data foundation every later CV stage (pose→PnP→segmentation→
detection→rule engine) measures against, so it needs to exist and be
correct before any model training work starts.

## 2. Scope

- In scope:
  - New `cv-service/` top-level Python package (sibling to
    `functions/` and `admin-portal/`), scaffolded per the memo's §17
    repo layout, but only the folders this slice actually populates.
  - `cv-service/utils/extract_anchors.py` — loads a body GLB via
    `trimesh`, reads the 15 named socket world-transforms plus one
    derived anchor (`chest_center`), and writes
    `cv-service/rules/anchors.<variant>.json`.
  - Generated `cv-service/rules/anchors.male.json` — real output run
    against `assets/3d/bodies/male_apose.glb`.
  - `cv-service/rules/army_no3_male.json` — the Army No.3 Male
    doctrine placement rules transcribed from the attached SAF No.3
    Dress PDF, in the schema from the architecture memo §8.
  - `cv-service/tests/test_extract_anchors.py` — unit test that
    exercises the extraction function against the real male body GLB
    and asserts the expected keys / a sane coordinate range are
    present.
  - `cv-service/requirements.txt` and `cv-service/README.md`.
  - A new root-level `.venv-tools` Python virtualenv (matching the
    existing `tool/` scripts' convention) with `trimesh`, `numpy`,
    `pygltflib` installed, used to run the extraction script.
- Out of scope (future milestones, not this slice):
  - Any FastAPI service / `/inspect` endpoint (Milestone 6).
  - Pose estimation, PnP camera-pose recovery, segmentation, or
    accessory detection code (Milestones 1–3, 5's PnP half).
  - Training, synthetic data generation, Blender automation
    (Milestone 2/3 support work).
  - Any change to the Flutter app or `functions/` — this slice is
    additive infrastructure only, nothing wires into the shipped
    compliance check yet.

## 3. Affected areas

- New: `cv-service/` (new top-level directory).
- New: root `.venv-tools/` (gitignored, matches `tool/`'s existing
  convention of a local venv for Python tooling — not committed).
- Update: `CLAUDE.md` top-level layout (§2) and a new §5.10 describing
  `cv-service/`'s purpose and the anchor/rule file schema, per policy
  1.2 (folder layout change).
- Update: root `.gitignore` if `cv-service/models/`,
  `cv-service/synthetic_data/`, or `.venv-tools/` aren't already
  covered.

## 4. Step-by-step plan

1. Create `cv-service/{utils,rules,tests}/` and a top-level
   `README.md` + `requirements.txt`.
2. Create root `.venv-tools` venv, install `trimesh`, `numpy`,
   `pygltflib` (mirrors `tool/`'s existing pattern for
   `generate_placeholder_bodies.py` etc.).
3. Write `extract_anchors.py`: a pure function
   `extract_anchors(glb_path) -> dict` returning each of the 15
   socket world positions plus `chest_center`
   (midpoint of `left_chest_pocket`/`right_chest_pocket`, x forced to
   0) and `reference_height_m` (derived from `head_top`'s y, not
   hardcoded), plus a CLI entry point that writes the JSON to
   `cv-service/rules/anchors.<variant>.json`.
4. Run it against `assets/3d/bodies/male_apose.glb`, inspect the
   output for sanity (no NaNs, y-values increasing sensibly from feet
   to head, no coordinate outside the mesh's bounding box).
5. Write `cv-service/rules/army_no3_male.json` transcribing the
   doctrine rules for every accessory already live in the Army No.3
   Male `accessory_library` set (beret, cap badge, epaulettes,
   enlistee/specialist sleeve insignia, arms badge, name tag, medal
   ribbon stack, SAF badges, sleeve tabs, marksmanship/proficiency
   badge, belt, footwear/socks), each carrying `doctrine_ref` back to
   the specific PDF picture/page.
6. Write a `pytest` test that runs the extraction against the real
   GLB and checks: all 15 expected keys present, `chest_center`
   present, y-coordinates monotonically sensible (ankle < belt <
   chest < collar < head), no coordinate is `NaN`/`inf`.
7. Update `CLAUDE.md`.
8. Mark this plan `executed`, run the test, mark `verified`.

## 5. Risks & rollback

- Low risk: purely additive, no existing file is modified except
  `CLAUDE.md` and (if needed) `.gitignore`. Rollback is `rm -rf
  cv-service/ .venv-tools/` and reverting the `CLAUDE.md` edit.
- The socket names/positions read here are a **snapshot** of the
  current `male_apose.glb` (post "pass 11" per `CLAUDE.md` §8) — if
  that GLB is regenerated later (new pass, new artist body), this
  script must be re-run and `anchors.male.json` regenerated. The
  extraction script itself has no expiry; only its output does.
- No production code path changes — nothing in `functions/` or `lib/`
  reads these new files yet, so there is no runtime regression
  surface.

## 6. Verification

- `.venv-tools/bin/pytest cv-service/tests/ -v` — **6/6 passed**
  (all sockets present, coordinates finite, left/right pairs
  mirrored, vertical ordering anatomically sane, reference height
  matches `head_top`).
- `cv-service/rules/anchors.male.json` generated from the real
  `assets/3d/bodies/male_apose.glb` and cross-checked against known
  pass-history numbers in `CLAUDE.md` §8 — `left/right_sleeve_upper`
  reads exactly `(∓0.30, 1.30, 0.0)`, matching the pass-6 retune
  verbatim. Confirms the script reads real, already-validated socket
  data rather than something bogus.
- `cv-service/rules/army_no3_male.json` — 18 rules, valid JSON,
  cross-checked against `assets/data/accessory_library.v1.json`'s
  live `render_logic` anchors for every accessory where one already
  exists (army_beret, cap badges, specialist/enlistee sleeve
  insignia, arms badge, belt).
- `flutter analyze` / `flutter test` not required — no Dart changed.

## 7. CLAUDE.md updates required

- §2 top-level layout tree: add `cv-service/` entry.
- New subsection under §5 (e.g. §5.10) documenting: what
  `cv-service/` is for, the anchor-file schema, the doctrine
  rule-file schema, and a pointer to the architecture memo this
  scaffold implements the first slice of.
-------------------

Phase 1 (shipped) — the checkUniformCompliance Cloud Function: architecture flow diagram, the forced tool-use JSON schema, every file touched, backend config (region/secrets/timeouts), and a clear verification table (what's tested vs. what's only "code-complete" — notably, no live Anthropic call or real-device run has happened yet).

Phase 2 (dev-only) — the cv-service pipeline: the core geometry idea (reusing the 3D body's named sockets as measurement anchors), a stage-by-stage breakdown (person detection → pose → PnP camera solve → rule projection → segmentation → vision-crop judgment → report), a table distinguishing what's real classical/pretrained CV from what's still a Claude vision-language stand-in, full detail on the actually-trained YOLOv8n-seg model (mAP50 scores per class, two real bugs hit and fixed during training), the Flutter dev-path wiring, and test coverage including three real bugs the smoke tests caught.

It closes with a shared-gaps section — the one fact repeated everywhere in your own plan files: zero real soldier photographs exist anywhere in this project, so every accuracy number in both phases is synthetic/test-image only — plus three concrete next steps.
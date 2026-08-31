# cv-service: `/check_uniform` API contract + robustness

**Status:** verified — 138/138 pytest passing (106 pre-existing unmodified
+ 32 new), manual curl smoke test of `/check_uniform` against the
rendered fixture photo confirmed the full response contract (including
`debug_image_base64`), and `/inspect` confirmed unchanged.

## Goal

Give `cv-service` a stable, explainable REST contract (`POST /check_uniform`)
matching a detailed backend spec the user supplied, plus the robustness
(central config, image-quality validation, graduated near-tolerance
verdicts, occlusion granularity) that spec calls for — without duplicating
or rewriting the ~80% of the pipeline that already exists and is tested.

This is Phase 1 of a larger roadmap; see "Explicitly out of scope" below
for the deferred phases.

## Scope

`cv-service/` only (Python). No Flutter, no Cloud Functions, no Cloud Run
deployment, no folder renaming.

## Affected areas

- New: `cv-service/config.py`, `cv-service/api/validation.py`,
  `cv-service/api/response_schema.py`, `cv-service/reporting/debug_overlay.py`
  (or an addition to `reporting/report.py`), 5 new/extended test files.
- Modified (additive, behavior-preserving): `cv-service/rules/rule_engine.py`
  (`VerdictResult` gains optional fields), `cv-service/api/main.py` (new
  `POST /check_uniform` endpoint, `/inspect` untouched), and the handful of
  files that currently hold local magic-number thresholds
  (`segmentation/segment_uniform.py`, `pose/detect_person.py`,
  `geometry/solve_camera_pose.py`, `calibration/pnp_solve.py`,
  `reporting/report.py`, `pose/anchor_mapping.py`) switched to import from
  `config.py` with identical default values.
- `cv-service/README.md` and `CLAUDE.md` §5.10 updated per policy 1.2.

## Step-by-step plan

1. `config.py` — central thresholds, env-var overridable, consumed by the
   existing modules listed above (same defaults — no behavior change).
2. `api/validation.py` — Stage-0 image-quality gate (corrupted / too large /
   too small / too dark / too bright / too blurry).
3. Enrich `rules/rule_engine.py`'s `VerdictResult` with optional
   `confidence`, `bounding_box_px`, `expected_position_px`,
   `detected_position_px`, `error_px`, `visibility`, and a new
   `slightly_misaligned` status band — `_evaluate_one_crop` already computes
   the underlying values, just needs to stop discarding them.
4. `api/response_schema.py` — pure function mapping resolved
   rules + enriched verdicts into the requested JSON contract.
5. `POST /check_uniform` in `api/main.py` — orchestrates
   validation → detect_person → anchor_mapping/solve_camera_pose →
   resolve_rules → segment_uniform → evaluate_verdicts →
   response_schema, with the full exhaustive error-code list.
6. Debug visualization: `render_debug_image_b64` (expected/detected markers
   + error-vector arrows), returned under `debug_image_base64`.
7. Tests: `test_config.py`, `test_image_validation.py`, extended
   `test_verdict_engine.py`, `test_response_schema.py`,
   `test_check_uniform_endpoint.py`.
8. Docs: `cv-service/README.md` + `CLAUDE.md` §5.10.

## Explicitly out of scope (deferred roadmap)

- Renaming folders to `vision/`/`glb/`/`compliance/`/`visualization/`.
- A real trained accessory bounding-box detector (Phase 2 candidate).
- Per-accessory GLB geometry extraction from `assets/3d/accessories/*.glb`
  (Phase 3 candidate).
- Wiring `/check_uniform` into the Flutter app / `checkUniformCompliance.ts`
  / Cloud Run deployment.

## Risks & rollback

All changes are additive (new files, new endpoint, new optional dataclass
fields with defaults). Rollback is `git checkout` on the touched files —
nothing here migrates data or changes `/inspect`'s existing behavior.
Main risk: threshold consolidation into `config.py` accidentally changing a
default value — mitigated by requiring the full existing pytest suite to
pass unmodified after the refactor (step 1).

## Verification

CLAUDE.md §1.5 is Flutter-specific; the Python-equivalent verification is:

1. `.venv-tools/bin/pytest cv-service/tests/` — full suite green.
2. Manual `curl` smoke test of `/check_uniform` against the existing
   rendered fixture photo.
3. Confirm `/inspect` behavior is unchanged (existing tests pass unmodified).
4. Flip Status to `executed` once built, `verified` once 1–3 pass.

## CLAUDE.md sections to refresh

§5.10 (cv-service narrative) — document `/check_uniform` + `config.py`.

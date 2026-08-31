# cv-service — real-photo Phase 1 sanity-check runner

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** verified (tooling only — the actual Phase 1 check itself remains unrun; see §4)

## 1. Goal

Build a one-command batch runner: point it at a folder of real photos,
it runs the existing pipeline (person detection → pose → camera solve →
rule resolution → segmentation) against every one, and reports whether
each stage holds up or degrades — no labeling, no new training, no new
model. This is deliberately lighter-weight than
`evaluation/evaluate_verdict_precision_recall.py` (already built,
already tested), which needs Milestone A-format ground-truth labels to
compute precision/recall. This tool needs nothing but raw photos — it's
a degradation/sanity signal, not an accuracy benchmark, matching the
actual ask: "does it hold up reasonably, or fall apart."

**This plan does not, and cannot, supply the actual photos.** That's
physical-world work (real people, real No.3 uniforms, a camera) outside
what a coding change can do. Confirmed before writing this plan: `cv-service/data/real_photos/`
still holds only the 3 synthetic stand-ins (`standin01`-`03`) plus a
`no3_acc/` folder of individual accessory reference images (not photos
of a person) — not usable for this check either.

## 2. Scope

- In scope:
  - `cv-service/evaluation/run_real_photo_sanity_check.py`: for every
    image under `--photos-dir` (default `cv-service/data/real_photos`,
    recursive; skips the known synthetic `standin*` subject folders
    unless `--include-standins` is passed — never silently mixes
    synthetic and real in one report), runs stages 1/2/3/6/4
    (`detect_person`, `estimate_anchor_pose`, `solve_camera_pose`,
    `resolve_rules`, `segment_uniform`) and records, per photo:
    person-detection accept/reason, pose anchor coverage + mean
    confidence, camera solved/reliable/reprojection-error/correspondence-count,
    resolved-rule count, segmentation region count + per-class
    confidences. One bad photo never aborts the batch — every stage is
    wrapped so a single failure is recorded and the run continues.
  - Aggregate report: per-stage pass rate across the batch,
    reprojection-error distribution, segmentation coverage summary —
    printed as a table, plus optional `--json-out` for the raw
    per-photo records.
  - `cv-service/tests/test_real_photo_sanity_check.py`: unit tests
    against small synthetic masks/mocked stage results for the
    aggregation math; a mechanical smoke test against the 3 existing
    stand-ins (`--include-standins`), explicitly **not** presented as a
    real-world finding — same posture as every other stand-in smoke
    test this session.
- Out of scope:
  - Sourcing real photos.
  - Precision/recall scoring (that's the existing, separate
    `evaluate_verdict_precision_recall.py`, which needs labels — this
    tool is the cheap pre-check *before* investing time in labeling).
  - Any change to `/inspect`, the trained model, or the Flutter app.

## 3. Real-photo count (unchanged, reconfirmed)

**Zero.** Same fact as every prior plan this session.

## 4. Verification

- `.venv-tools/bin/pytest cv-service/tests/` — **106/106 passed**
  (97 pre-existing + 9 new in `test_real_photo_sanity_check.py`).
- Mechanical smoke test via `--include-standins` — confirms the runner
  and aggregation math work end-to-end, and reproduces the exact
  previously-documented per-stand-in numbers (reprojection 34.28 /
  36.47 / 25.61px). **Not a real-world finding.** As a side effect,
  this run also swept the pre-existing `no3_acc/` folder (14 accessory
  reference images, not photos of a person) and confirmed all 14
  correctly report `person_detected=False` — the tool doesn't
  misidentify non-person images as usable data.
- The actual Phase 1 sanity check this tool exists to run — **not run
  by this plan.** Needs the requester to supply 15-20 real photos under
  `cv-service/data/real_photos/<subject_id>/<subject_id>__<angle>__<lighting>.jpg`
  (existing Milestone A naming convention), then:
  `.venv-tools/bin/python cv-service/evaluation/run_real_photo_sanity_check.py`

## 5. CLAUDE.md updates required

- §5.10: one paragraph noting the tool exists, is tested, and has not
  been run against real data because none exists.

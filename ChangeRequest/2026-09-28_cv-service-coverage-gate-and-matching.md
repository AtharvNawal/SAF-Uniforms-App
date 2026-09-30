# cv-service: verification-coverage gate + search-area-gated one-to-one matching

- **Date:** 2026-09-28
- **Author:** Claude (Opus 5.5) for Atharv Nawal
- **Status:** executed — pytest + `flutter analyze` + `flutter test` pass; not device-verified (see §6)

## 1. Goal
Fix two logic flaws in `POST /check_uniform` that make results misleading
independent of model accuracy:

1. **Coverage gate.** `compute_overall_score` excludes `unverifiable` items,
   so a photo where only 2 of 7 checkable required items could be measured
   (and both passed) scores 100 → `PASS`. Conversely, when nothing was
   scorable the score is 0 → `FAIL`. Neither is honest.
2. **Detection matching.** `_nearest_candidate` picks the nearest segment of
   the right class *anywhere in the image*, so an empty expected region
   next to a stray / other-side detection is reported `fail` (present but
   misplaced) instead of `missing`, and on paired rules (left + right
   sleeve / epaulette / shoe) a single detection can satisfy both sides.

## 2. Scope
- In scope:
  - `overall_status` gains a third value `INCOMPLETE`: returned when fewer
    than `MIN_VERIFIED_COVERAGE` (default 0.8, env-overridable) of the
    *detector-backed* required items got a definite verdict — unless a
    definite `fail`/`missing` was already found, in which case `FAIL`.
  - Additive `coverage` object on the response:
    `{verified_required, checkable_required, fraction, not_checkable_required}`.
    Structurally-undetectable categories (no segmentation class — name tag,
    socks, …) are excluded from the gate's denominator (otherwise PASS
    would be impossible for every profile today: 2 of ~9 required Army
    No.3 items have no detector) and counted separately so the gap stays
    visible.
  - Candidate segments must have their centroid inside the rule's crop
    (search) box; detections are assigned to crops one-to-one per rule
    (greedy by distance). An unmatched crop is `missing` (or
    `unverifiable`/out-of-frame when the crop is off-image). Optional
    rules with no crop matched are skipped, same as today's "nothing
    detected" behaviour.
  - Flutter: `UniformCheckResult.incomplete` getter; `_RealScorecard`
    shows `INCOMPLETE` (warn colour) instead of mislabelling it `FAIL`.
- Out of scope: every other item from the accuracy review (EXIF
  normalisation, pose-model swap, uncertainty propagation, 3D tolerance
  projection, intrinsics, model/data work). `/inspect`'s
  `geometric_verdicts` inherits the matching fix (same function) but its
  shape is unchanged.

## 3. Affected areas
- `cv-service/config.py` — `MIN_VERIFIED_COVERAGE`.
- `cv-service/rules/rule_engine.py` — `has_detector()`, matching rewrite in
  `evaluate_verdicts` / `_evaluate_one_crop`.
- `cv-service/api/response_schema.py` — coverage computation + status.
- `cv-service/tests/test_verdict_engine.py`, `test_response_schema.py`.
- `lib/features/ar_scanner/domain/entities/uniform_check_result.dart`,
  `.../screens/ar_scanner_screen.dart`, `test/features/ar_scanner/uniform_check_result_test.dart`.

## 4. Step-by-step plan
1. Add config constant.
2. Rule engine: gate candidates to crop box, greedy one-to-one assignment,
   per-crop unmatched evaluation; simplify the now-always-true region check.
3. Response schema: `compute_coverage`, new status logic, `coverage` field.
4. Update/add pytest cases (paired-rule test now expects `missing`).
5. Flutter getter + label + tests.

## 5. Risks & rollback
- A far-off detection that *was* the real (badly misplaced) item is now
  `missing` rather than `fail` — both are non-compliant and score 0, so the
  overall score is unchanged; the reason text notes the out-of-area
  detection.
- Older app builds treat any non-`PASS` status as FAIL — `INCOMPLETE`
  renders as `FAIL` there; no crash.
- Rollback: revert this change set; no data/schema migration.

## 6. Verification
- `.venv-tools/bin/pytest cv-service/tests/`
- `flutter analyze`, `flutter test`
- No device run (cv-service still undeployed; same status as the prior plan).

**Run 2026-09-28:**
- pytest: 147 passed, 1 failed (10 new tests) — `test_api.py::test_inspect_rejects_multi_person_photo`
  (`/inspect` returns `pose_not_found` instead of `multiple_people_detected`),
  which fails identically with this change stashed, so it predates this plan
  and is untouched by it.
- `flutter analyze`: no issues.
- `flutter test`: **not run** — `objective_c`'s native-assets hook fails
  because the Xcode license is unaccepted on this machine
  (`sudo xcodebuild -license`). Re-run after accepting, then mark `verified`.

**Re-run later the same day** (during the follow-up
`2026-09-28_accuracy-program-no-real-data.md`): `flutter test` now runs by
pointing the build hook's `xcrun` at the Command Line Tools SDK instead of
the unlicensed Xcode (`PATH=<shim>:$PATH DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test`,
where the shim is a 3-line `xcrun` wrapper that exports `DEVELOPER_DIR` —
Flutter's hooks drop that variable from their environment). **All Flutter
tests pass**, including this plan's `incomplete` test. Still not
`verified`: policy 1.5 step 4 (`flutter run` against a reachable
`cv-service` on a device) hasn't been done.

## 7. CLAUDE.md updates required
- §5.10 `/check_uniform` paragraph (new `INCOMPLETE` status + `coverage`),
  §4 `uniform_check_result.dart` entry.

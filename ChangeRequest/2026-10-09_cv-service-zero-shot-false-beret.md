# cv-service — a zero-shot detection can't certify an item (false "beret present")

- **Date:** 2026-10-09
- **Author:** Claude (agent)
- **Status:** executed — tests + benchmarks done; Cloud Run redeploy pending operator approval

## 1. Goal
User report (Android, RSAF No.4): the scorecard said the beret was present
when it wasn't worn.

Cause: the trained segmenter correctly found no headwear. The zero-shot
fallback (B7, `detectors/zero_shot.py`: YOLO-World + SAM 2, run on any
empty headwear/belt/footwear search box) then scored the **hair** as
"beret" at 0.72, above `ZERO_SHOT_ACCEPT_CONFIDENCE` 0.45. Presence-only
rules pass on any region in the box, so the beret passed. The 0.45 bar was
calibrated on the bald Army test body (bare head = 0.18); bodies with hair,
including real people, score far higher. The RSAF benchmark already had this
case: its only beret-removed scene (`scene_0016`) was predicted `pass`.

## 2. Scope
- In scope: a verdict built on a zero-shot region is `unverifiable` with
  `failure_kind: "unconfirmed"` and its own instruction ("couldn't confirm
  it's there…"), never `pass` / `fail`. Zero-shot still keeps an item from
  being called `missing` when the trained model may have missed it.
- Out of scope: retraining the segmenter on figures with hair; a beret
  colour check (RSAF blue vs black hair).

## 3. Affected areas
- `cv-service/rules/rule_engine.py` (`_evaluate_one_crop`)
- `cv-service/api/instructions.py`
- `cv-service/tests/test_accuracy_program.py` (2 new tests)
- No Flutter change: `unverifiable` + checkable already lands in the
  scorecard's "could not check — a retake may help" list.

## 4. Steps
1. Downgrade zero-shot-sourced crop evaluations to `unverifiable/unconfirmed`.
2. Instruction text for `unconfirmed`.
3. Tests; re-run the RSAF and Army benchmarks (`program_default`).
4. Redeploy Cloud Run (`deploy/deploy-cv-service-cloudrun.sh`) — operator
   approval required.

## 5. Risks & rollback
- A real beret that the synthetic-trained model misses is now reported as
  "couldn't confirm" instead of "present". That is the honest result. It may
  push some scans to INCOMPLETE.
- Rollback: revert the block in `_evaluate_one_crop`, or redeploy the
  previous image.

## 6. Verification
- `pytest cv-service/tests/`: 214 pass (1 pre-existing failure,
  `test_inspect_rejects_multi_person_photo`, deselected).
- Benchmarks: see §8.

## 7. CLAUDE.md updates required
- §5.10 accuracy-program list, stage 7: zero-shot can't certify an item.

## 8. Results
`evaluation/run_violation_benchmark.py --variants program_default`:

| Bench | Beret, removed | Beret, worn | Everything else |
|---|---|---|---|
| RSAF (before) | 1/1 false **pass** | 46/46 pass | — |
| RSAF (after) | 1/1 "couldn't confirm" | 46/46 pass | unchanged (24.5% exact, 39.1% recall, 3.2% false alarms) |
| Army (before → after) | 4/4 missing (trained model) | 43/43 pass | unchanged (36.1% / 60.4% / 5.5%) |

No correct item in either benchmark relied on a zero-shot detection, so the
change removes the false pass at no measured cost. The removed beret is still
not called `missing`. The trained model is the only thing that can call it
missing, and the backup detector's hair hit now blocks that.

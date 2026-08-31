# cv-service — segmentation real-vs-synthetic mAP comparison tooling

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** verified

## 1. Goal

Build the tooling to run the already-trained YOLOv8n-seg model
(`cv-service/models/segmentation_v1`) against real labeled photos and
produce a per-class mAP50 real-vs-synthetic comparison table, plus a
structured framework for root-causing and proposing fixes for any class
that regresses. **Do not run this against real data — there is none.**

## 2. Why this plan looks different from the task as originally phrased

The task was scoped as "run against Milestone A's real photos." I
re-verified before writing this plan: `cv-service/data/labels/*.json`
has exactly 3 entries, **all three `is_synthetic_stand_in: true`**.
Zero real photos exist in this repo — same fact, still true, as every
prior plan this session. There is nothing to run the comparison against
yet, so this plan builds the tooling only, verifies it mechanically
(see §6), and stops — it does not fabricate a real-vs-synthetic table by
quietly substituting synthetic data for real, and does not retrain
anything. This was confirmed with the requester before writing this plan
(recommended option: "build the tooling now, run nothing").

## 3. Scope

- In scope:
  - `cv-service/evaluation/segmentation_label_conversion.py`:
    `convert_labels_to_yolo_seg(label_paths, out_dir, *, require_real=True) -> ConversionResult`
    — converts Milestone A's ground-truth label JSON (pixel-space
    polygons, `cv-service/data/labels/*.json`) into the exact YOLO-seg
    dataset format `generate_segmentation_dataset.py` already produces
    (normalized polygon coords, one instance per line, `data.yaml` with
    the same `CLASS_ID` ordering) — **not a new metric implementation**,
    a format converter, so `model.val()` computes mAP50 through the
    identical Ultralytics code path the original training run used. This
    is what makes the comparison genuinely apples-to-apples rather than
    two differently-computed numbers that happen to share a name.
    `require_real=True` by default: labels with `is_synthetic_stand_in:
    true` are excluded, not silently included — a caller has to
    explicitly opt out to convert synthetic labels (used only by this
    plan's own mechanical smoke test, see §6).
  - `cv-service/evaluation/compare_segmentation_real_vs_synthetic.py`:
    the harness. For the synthetic side, **re-runs** `model.val()`
    against the existing `cv-service/synthetic_data/seg_v1/data.yaml`
    val split (still present locally) rather than hard-coding the
    numbers already written down in `CLAUDE.md`/the README — reproducible
    and guarantees both sides of the table went through the exact same
    code path. Falls back to those documented numbers, clearly labeled
    `"source": "documented, not re-run"`, only if the synthetic dataset
    isn't present locally (it's gitignored, so this varies by machine).
    For the real side: converts every non-synthetic label via the module
    above, and — if that yields zero images — **stops and reports "0
    real photos, nothing to compare" rather than running anything.**
    Output: one table, `class | synthetic_mAP50 | real_mAP50 | delta`.
  - Regression flagging: `flag_regressions(comparison, threshold=0.15) ->
    list[RegressionFlag]`. **Threshold justification:** the weakest
    synthetic classes already sit in the 0.5–0.6 range (`belt` 0.556,
    `arms_badge` 0.524) — a smaller threshold would flag normal
    run-to-run noise on an already-weak class as a "regression," while a
    much larger one would miss a real problem on a strong class (e.g.
    `shirt` dropping from 0.995 to 0.85 is a real, meaningful issue at
    only a 0.145 absolute drop). 0.15 absolute mAP50 drop sits between
    those two failure modes.
  - `Diagnosis` structure per flagged class: a fixed, non-fabricated
    vocabulary of candidate root causes (`lighting`,
    `occlusion`, `fabric_texture_mismatch`, `camera_angle_ood`,
    `insufficient_real_examples`, `other`) and proposed fixes
    (`augment_synthetic_data`, `fine_tune_on_real`,
    `flag_needs_more_real_data`, `no_action_needed`) — populated by a
    human reviewer (or a future automated heuristic) once real regressions
    exist to look at. Today, with 0 real photos, every field is `None`/
    unpopulated by construction, not guessed at.
  - `cv-service/tests/test_segmentation_real_vs_synthetic_comparison.py`:
    unit tests for the label converter (hand-built label dict → correct
    normalized YOLO lines, correct class ids, `present: false` correctly
    excluded, `is_synthetic_stand_in: true` correctly excluded by
    default); unit tests for `flag_regressions` against synthetic dummy
    mAP dicts (not real data — pure function tests); an integration
    **smoke test** that runs the full converter + `model.val()` path
    against Milestone A's 3 stand-ins with `require_real=False` (an
    explicit test-only override) — this only proves the mechanism runs
    without crashing, and is clearly commented as NOT a real-world
    result; and a test confirming the default (real-photo) path
    correctly reports 0 photos today rather than crashing or fabricating
    output.
- Out of scope:
  - Sourcing real photos.
  - Retraining or fine-tuning the segmentation model — that's a
    follow-up decision this tooling exists to *inform*, once real data
    exists, per the task's own root-cause options (augment synthetic
    data / fine-tune / flag as needing more data).
  - Actually diagnosing any class (no real regressions exist yet to
    diagnose).

## 4. Real-photo count (unchanged, reconfirmed before writing this plan)

**Zero.** `cv-service/data/labels/*.json` — 3 files, all
`is_synthetic_stand_in: true`. Same fact as Milestones A/B/C.

## 5. Risks & rollback

- **The biggest risk this plan actively defends against:** silently
  running the comparison against the 3 synthetic stand-ins and
  presenting the result as "real-world performance" — which would be
  actively misleading (synthetic-vs-synthetic, not synthetic-vs-real)
  and, per the coverage gap already documented in Milestone A/this
  session, could only ever cover 3 of 9 classes (`shirt`/`trousers`/
  `footwear` — the ones baked into the bare body mesh; the stand-in
  renders have no accessory GLBs composited in, so `headwear`,
  `cap_badge`, `epaulette`, `sleeve_rank`, `arms_badge`, `belt` have zero
  geometry present and can't register at all). Mitigated by
  `require_real=True` being the default, not opt-in, and by the smoke
  test living clearly outside the "real comparison" code path.
  - Note this differs from Milestone A's own permissive use of the
    stand-ins (there, they were reasonable stand-ins for exercising the
    *labeling tool itself*); reusing them here to claim something about
    *real-world segmentation accuracy* would be a different, unjustified
    claim, which is why this plan treats them as smoke-test-only.
- **Re-running synthetic `model.val()` depends on
  `cv-service/synthetic_data/seg_v1/` still being present locally**
  (gitignored — not guaranteed on every machine/clone). Mitigated by the
  documented-baseline fallback in §3, clearly labeled as such rather than
  silently passed off as freshly computed.
- Low blast radius: new files only under `cv-service/evaluation/` and
  `cv-service/tests/`; the trained model weights are read, never
  modified. Rollback is `rm cv-service/evaluation/segmentation_label_conversion.py
  cv-service/evaluation/compare_segmentation_real_vs_synthetic.py
  cv-service/tests/test_segmentation_real_vs_synthetic_comparison.py`.

## 6. Verification

- `.venv-tools/bin/pytest cv-service/tests/ -v` — full suite including
  the 8 new tests in `test_segmentation_real_vs_synthetic_comparison.py`.
- `.venv-tools/bin/python cv-service/evaluation/compare_segmentation_real_vs_synthetic.py`
  run for real (default `require_real=True`, no override) — this is the
  actual default-path result, not a smoke test.
- Mechanical smoke test separately (`require_real=False`, Milestone A's
  3 stand-ins, exercised only inside
  `test_mechanism_smoke_test_against_synthetic_stand_ins`) — proves the
  converter + `model.val()` invocation works end-to-end. **Not reported
  below as a real-vs-synthetic result** — see §5. For the record only
  (mechanism check, not a finding): `shirt`/`trousers`/`footwear` were
  the only classes with any ground-truth instances in the 3 stand-ins
  (matches the risk section's prediction — no accessory GLBs are
  composited into those renders), confirming the converter correctly
  reads Milestone A's polygon format and Ultralytics correctly computes
  metrics against it.

**Real-vs-synthetic comparison table (measured — synthetic side
re-run live against `cv-service/synthetic_data/seg_v1/`, exactly
reproducing the previously-documented per-class numbers, confirming the
same code path is being exercised both times):**

| Class | Synthetic mAP50 | Real mAP50 | Delta | Flagged? | Diagnosis |
| --- | --- | --- | --- | --- | --- |
| shirt | 0.995 (re_run) | **N/A — 0 real photos** | N/A | — | — |
| trousers | 0.995 (re_run) | N/A | N/A | — | — |
| headwear | 0.995 (re_run) | N/A | N/A | — | — |
| cap_badge | 0.904 (re_run) | N/A | N/A | — | — |
| epaulette | 0.496 (re_run) | N/A | N/A | — | — |
| sleeve_rank | 0.222 (re_run) | N/A | N/A | — | — |
| arms_badge | 0.524 (re_run) | N/A | N/A | — | — |
| belt | 0.556 (re_run) | N/A | N/A | — | — |
| footwear | 0.995 (re_run) | N/A | N/A | — | — |

**Real photos found: 0** (`compare_segmentation_real_vs_synthetic.py`'s
actual printed output: "Real photos found: 0 (skipped 3 synthetic
stand-ins)"). Every "Real mAP50" cell stays `N/A` — not populated with a
placeholder number, not silently dropped, and not backfilled with the
smoke-test numbers above even though they exist, because those measure
the wrong thing (synthetic-vs-synthetic, and only 3 of 9 classes). No
class is flagged and no `Diagnosis` is populated, because there is
nothing to diagnose yet — this table becomes real, and the flagging /
diagnosis columns become populated, the moment real photos +
Milestone-A-format labels exist and this script is re-run.

- `flutter analyze` / `flutter test` not required — no Dart touched.

## 7. CLAUDE.md updates required

- §5.10: a short paragraph on the comparison tooling, why it currently
  reports "0 real photos, nothing to compare" rather than a table, and a
  pointer to re-run it once real photos + labels exist.

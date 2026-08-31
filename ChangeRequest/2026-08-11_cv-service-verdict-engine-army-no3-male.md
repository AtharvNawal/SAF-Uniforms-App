# cv-service — geometric pass/fail verdict engine (Army No.3 Male)

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** verified

## 1. Goal

Given Milestone C's projected expected 2D zones (`rules/rule_engine.py`'s
`resolve_rules()` output) and the trained segmentation model's detected
accessory regions (`segmentation/segment_uniform.py`'s
`SegmentationResult`), produce a `pass` / `fail` / `missing` /
`unverifiable` verdict per accessory, for Army No.3 Male, with a
human-readable reason and no invented tolerances.

## 2. Decisions confirmed with the requester before writing this plan

1. **"Milestone D's detected accessory segments"** = the pre-existing
   trained `segmentation/segment_uniform.py` model (9 classes) — there is
   no other candidate in this codebase.
2. **Tolerance/matching logic — approved as proposed:** doctrine's own
   `tolerance_cm`/`tolerance_deg` fields (already transcribed from the
   SAF No.3 Dress PDF into `army_no3_male.json`) are the source of truth,
   not invented numbers. Matching method: detected mask centroid vs. the
   already-projected doctrine point (`CropBox.center_px`), compared
   against `tolerance_cm` converted to px via `cm_per_px`. Rules with
   `tolerance_cm: null` (doctrine gives no cm figure — berets, turbans,
   epaulettes, footwear, socks) get a generous region-overlap check
   (centroid inside the already-computed crop bounds) instead of a tight
   distance check — those items get NO tighter a check than doctrine
   itself specifies.
3. **Orientation checking — build now.** `angle_deg`/`tolerance_deg`
   rules (cap badges, name tag, sleeve insignia) get a real mask
   orientation estimate via `cv2.minAreaRect`, not left unverifiable by
   default.

## 3. The coverage gap (surfaced before writing this plan, shapes the design)

`army_no3_male.json` has 18 rules; the segmentation model has 9 classes,
several shared by multiple rule variants:

| Segmentation class | Doctrine rules that map to it | What this class alone can/can't confirm |
| --- | --- | --- |
| `headwear` | `army_beret`, `army_sikh_turban_standard` | presence + position; **cannot** tell beret from turban |
| `cap_badge` | 3 rank-tier variants | presence + position; **cannot** tell which variant |
| `epaulette` | 2 variants | same |
| `sleeve_rank` | 2 variants (specialist/enlistee) | same |
| `arms_badge` | 1 rule | presence + position, no variant ambiguity |
| `belt` | 1 rule | presence + position |
| `footwear` | 1 rule | presence + position |
| *(none)* | `name_tag_standard`, `medal_ribbons`, `saf_badges_chest`, `skill_tabs_sleeve`, `skill_badges_sleeve` | **nothing — 5 of 18 rules have zero detection path** |
| *(none)* | `black_socks` | same — no `socks` class exists |

This is a structural limitation of the trained model, not something this
plan works around by guessing. The verdict engine reports `unverifiable`
for all of the above with an explicit reason, and never claims
variant-correctness (e.g. "this is the COL cap badge, not SLTC's") that
the detector has no way to know.

## 4. Scope

- In scope:
  - `cv-service/segmentation/mask_geometry.py` — new, small, pure
    geometry helpers operating on a `SegmentedRegion.mask`:
    - `mask_centroid_px(mask) -> tuple[float, float] | None`
    - `mask_orientation_deg(mask, *, min_aspect_ratio: float = 1.3) -> float | None`
      — `cv2.minAreaRect` on the mask's contour; returns `None` (not a
      guessed angle) when the mask's bounding rectangle is too close to
      square to have a reliable long axis (min aspect ratio 1.3,
      justified: below that, a rectangle fit's angle is dominated by
      pixel-level mask noise, not the object's actual orientation — a
      round-ish cap badge silhouette shouldn't produce a confident angle
      reading it can't actually support). Angle comparison is mod-180°
      (a plain rectangle fit can't distinguish 0° from 180° — doctrine
      tolerances here are single-digit-to-low-teens degrees, far tighter
      than that ambiguity window, so resolving to the nearer of the two
      equivalent readings is safe).
  - `cv-service/rules/rule_engine.py`: `evaluate_verdicts(resolved_rules,
    segmentation, cm_per_px, image_width, image_height, *,
    camera_reliable=True, min_segment_confidence=0.4) ->
    list[VerdictResult]`, `VerdictResult = {accessory, status, reason,
    doctrine_ref}`. Added to the existing file per the task's own
    instruction — no circular import risk (`segmentation/segment_uniform.py`
    imports nothing from `rules/`).
    - `camera_reliable=False` → every verdict is `unverifiable`
      ("camera pose unreliable for this photo — projected zones cannot
      be trusted") — directly wires up Milestone C's own
      `CameraSolution.reliable` flag as an input, so an unreliable
      camera solve can't silently produce confident-looking verdicts
      downstream.
    - **Occlusion / extreme-angle handling:** if a rule's projected crop
      falls partially or fully outside the image bounds, that's
      `unverifiable` ("expected region falls outside the photo — likely
      occluded or camera angle too extreme"), not `missing`. `missing`
      is reserved for "the expected region was fully in view and nothing
      was there" — a confident absence claim, which is a materially
      different real-world conclusion from "we couldn't actually see
      that part of the body."
    - Two different "nothing to report" situations get different
      treatment, deliberately: an **optional** rule whose detector
      *exists* but found nothing in an in-bounds region is skipped
      entirely (matches `reporting/report.py`'s existing
      `combine_item_verdicts` convention — an optional item simply not
      worn isn't a doctrine violation). A rule with **no detector at
      all** (medal ribbons, SAF badges, skill tabs/badges, socks) is
      always reported `unverifiable`, even when optional — silently
      skipping those would make a report look like every category was
      checked when several structurally never were.
  - `cv-service/tests/test_verdict_engine.py`: unit tests for
    `mask_geometry.py` (synthetic masks with known centroid/orientation);
    unit tests for `evaluate_verdicts` against hand-built
    `ResolvedRule`/`SegmentationResult` fixtures covering every status —
    `pass`, `fail` (position and orientation), `missing`,
    `unverifiable` (no-detector-class, out-of-bounds, unreliable camera,
    ambiguous orientation); precision/recall computed per accessory
    class against Milestone A's ground truth where its coverage allows
    (see §6 — this is minimal, and the real-photo row is explicit `N/A`).
- Out of scope:
  - Any change to `segment_uniform.py`, `pnp_solve.py`,
    `project_rules.py`, or `reporting/report.py` — additive only.
  - Solving the variant-correctness problem (would need a classifier,
    not this milestone).
  - Adding a `socks` segmentation class or a `name_tag`/`medal_ribbons`/
    `saf_badge`/`skill_tab`/`skill_badge` detector — flagged as the real
    next step (§3), not built here.
  - Sourcing real photos (still 0 — see §6).

## 5. Risks & rollback

- **Biggest risk: this function can look more authoritative than it is**
  if a caller doesn't read the `unverifiable` reasons — a third of the
  ruleset structurally can't be checked by this detector. Mitigated by
  never forcing those into pass/fail (per the task's own instruction)
  and by `reason` always stating *why* a verdict is `unverifiable`
  rather than just returning the label.
- **Orientation ambiguity is real, not fully solved.** `mask_orientation_deg`
  correctly refuses to guess on near-square masks, but for masks that
  *do* pass the aspect-ratio gate, `cv2.minAreaRect` is still a coarse
  rectangle fit, not a learned pose estimator — expect some genuine
  noise on real photos (once they exist) that this plan can't fully rule
  out from synthetic testing alone.
- **The 5-uncoverable-rule gap and the socks gap are pre-existing model
  limitations**, not introduced here — this plan makes them visible
  (`unverifiable`, explicit reason) rather than fixing them, which is a
  deliberate scope boundary (§4), not an oversight.
- Low blast radius: `mask_geometry.py` is new; the only edit to an
  existing file is an additive function in `rule_engine.py` (new
  dataclass + new function, existing `resolve_rules`/`ResolvedRule`
  untouched) — confirmed by the full pre-existing suite passing
  unmodified. Rollback: `rm cv-service/segmentation/mask_geometry.py
  cv-service/tests/test_verdict_engine.py` + revert the `rule_engine.py`
  addition.

## 6. Verification

- `.venv-tools/bin/pytest cv-service/tests/ -v` — full suite including
  the new test file.
- **Precision/recall per accessory class** — the task's explicit
  requirement. Computed against Milestone A's ground truth, with the
  same honesty constraint every prior milestone this session has
  carried: **0 real photos exist**, so the real-photo row is `N/A`, not
  fabricated. The 3 synthetic stand-ins can only exercise
  `shirt`/`trousers`/`footwear` (no accessory GLBs are composited into
  those renders — same limitation noted in the segmentation-comparison
  plan), so even the synthetic precision/recall table below is
  necessarily thin — stated plainly, not padded out.

**Measured** (`.venv-tools/bin/python cv-service/evaluation/evaluate_verdict_precision_recall.py`)
— this ran the **full pipeline chain for the first time**: Milestone B
pose → Milestone C camera solve → rule projection → trained segmentation
→ this milestone's verdict engine, against all 3 of Milestone A's
stand-ins:

| Accessory class | Real precision/recall | Synthetic precision/recall (3 stand-ins) |
| --- | --- | --- |
| headwear | N/A — 0 real photos | N/A — no ground-truth-positive signal (0 TP/FP/FN; correctly `missing` all 3 times, matching ground truth, but 0 positive cases means precision/recall are undefined, not 0%) |
| cap_badge | N/A | N/A — same |
| epaulette | N/A | N/A — same |
| sleeve_rank | N/A | N/A — same |
| arms_badge | N/A | N/A — same |
| belt | N/A | N/A — same |
| **footwear** | N/A | **precision 1.0, recall 1.0 (TP=2, FP=0, FN=0)** — n=2, thin, not a strong claim |
| name_tag / medal_ribbons / saf_badge / skill_tab / skill_badge / socks | N/A — no detector exists | N/A — no detector exists |

**Reading this honestly:** `footwear` is the *only* accessory category
where the stand-ins have any ground-truth-positive case at all (2 of the
3 stand-ins have visible feet; `standin02`'s tighter crop pushes them
out of frame — and the verdict engine correctly reported `unverifiable`
for that one, not a false `missing`, confirming the occlusion/out-of-
-frame handling works on a real pipeline run, not just a synthetic unit
test). Every other accessory class has zero ground-truth-positive
examples in this data (the bare-body stand-ins have no accessory GLBs
composited in — same limitation noted in the segmentation-comparison
plan), so "0 TP/FP/FN" there is the correct, honest outcome, not a
failure to find something that should have been there — precision/recall
are mathematically undefined at zero positives, reported as `N/A (no
signal)`, not padded to a fake 0% or 100%.

- `flutter analyze` / `flutter test` not required — no Dart touched.

## 7. CLAUDE.md updates required

- §5.10: a short paragraph on `evaluate_verdicts`, the coverage-gap
  table from §3, the occlusion/camera-reliability handling, and the same
  0-real-photos caveat as every other subsection.

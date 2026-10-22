# cv-service — RSAF No.4 (men + ladies) uniform check

- **Date:** 2026-10-05
- **Author:** Claude (Opus 5.5) for Atharv Nawal
- **Status:** executed — live on Cloud Run (revision cv-service-00003); device test pending

## 1. Goal
Make the AR Scanner check **RSAF No.4** for men and ladies. Today
`/check_uniform` only accepts `army_no3_male` and answers
`UNSUPPORTED_UNIFORM` for everything else.

The app already sends `uniform_type = rsaf_no4_male` / `rsaf_no4_female`
(`ar_scanner_screen.dart` `_uniformTypeWireValue`) and the `rank_tier`
vocabulary the rules use, so **no app code change is needed**. All the
work is in `cv-service`, followed by a redeploy.

The reference geometry is the operator's RSAF No.4 dressed figures
(Storage `models/uniforms/rasf_no4_{male,female}.glb`, prepared copies at
`assets/3d/bodies/rsaf_no4_{male,female}.glb`). They supply three things:
1. the reference body anchors;
2. synthetic training renders for the segmenter;
3. a synthetic violation benchmark with exact ground truth.

## 2. Scope
**In scope**

1. **Uniform registry** (`cv-service/uniforms.py`). Per `uniform_type`:
   - rules file, anchors file, pose-offset file, reference stature.

   The pipeline, rule engine, camera solve and pose mapping read from it
   instead of the hard-wired `army_no3_male.json` / `anchors.male.json` /
   `anchor_offsets.male.json` / 1.78 m. `army_no3_male` behaviour stays
   byte-identical (regression tests).
2. **RSAF anchors** (`utils/extract_figure_anchors.py`).
   - The 16 named anchors are measured from the figure's own parts:
     head crown, beret band front, collar tips, chest-pocket tops,
     shoulder seams, upper sleeves, waistband, ankles, boot tops.
   - Anatomical left/right, same convention as `anchors.male.json` after
     `_to_anatomical_sides`.
   - Output: `rules/anchors.rsaf_no4_{male,female}.json`.
3. **RSAF doctrine rules** `rules/rsaf_no4_{male,female}.json`, transcribed
   from the SAF No.4 PDF RSAF section (pp.13-18), each item with a
   `doctrine_ref`:

   | Item | Rule |
   |---|---|
   | Beret | Sikh → RSAF turban with blue fifty |
   | Cap badge | per tier: B-5 all other ranks / B-6 COL & ME7 / B-7 BG+ & ME8 |
   | Chest rank tab | centre, standard vs cadet/trainee |
   | Name tag | right chest |
   | SINGAPORE tag | left chest |
   | Sleeve unit patch | both sleeves, 20 mm below the shoulder seam (C-1, C-4) |
   | Collar vocation badge | 10 mm (C-1), optional |
   | Chest badges | above the SINGAPORE tag, optional |
   | Boots | — |

   The PDF gives no tolerance figures, so tolerances follow the Army
   file's values and are marked `"tolerance_source": "assumed"`. Socks
   are inside the boots and the belt is under the untucked shirt (PDF
   pictures A-1..A-3), so they are omitted as not visible, with a note.
4. **Segmenter v3.** Adds classes `rank_tab` and `sleeve_patch`; the
   SINGAPORE tag reuses `name_tag`, and position separates the two.
   - New generator `training/generate_segmentation_dataset_rsaf.py`
     renders the textured figures with node→class labels. It reuses
     dataset v2's camera / lighting / background / photometric
     randomisation and randomly removes items so the model learns
     absence. Sikh turban scenes are included.
   - Train `segmentation_v3`: fine-tuned from v2 on Army seg_v2 + RSAF
     renders, so Army accuracy is kept. It is promoted to default only if
     its Army val mAP50 ≥ v2's minus 0.02.
5. **Pose offsets per uniform.** Generalise
   `pose/calibrate_anchor_offsets.py` to `--uniform`, then fit
   `pose/anchor_offsets.rsaf_no4_{male,female}.json` on the figures.
6. **Benchmark.**
   - `training/generate_violation_benchmark_rsaf.py`: per gender, correct
     scenes, items displaced 0.5 / 1.25 / 2× tolerance, and removals,
     with exact ground truth.
   - `evaluation/run_violation_benchmark.py` gains
     `--bench` / `--uniform`.
   - Report exact-match, violation recall, false alarms and abstain, as
     for Army.
7. **Tests.**
   - Registry and rules load for all three types.
   - The Army regression stays.
   - An RSAF end-to-end test on a rendered figure photo.
8. **Redeploy** Cloud Run, then live smoke test with an RSAF render.

**Out of scope**
- Other branches' No.4 (no dressed figures yet).
- Real-photo validation (0 real photos, as for Army).
- Variant checks for the RSAF cap-badge tiers: there's only one modelled
  badge, so no wrong-variant benchmark scene is possible. Presence and
  position are still checked.

## 3. Affected areas
- `cv-service/uniforms.py` (new), `api/pipeline.py`, `api/main.py`
  (docs), `rules/rule_engine.py`, `geometry/solve_camera_pose.py`,
  `geometry/project_rules.py`, `pose/anchor_mapping.py`,
  `pose/calibrate_anchor_offsets.py`
- `rules/rsaf_no4_{male,female}.json`, `rules/anchors.rsaf_no4_*.json`,
  `pose/anchor_offsets.rsaf_no4_*.json` (new)
- `utils/extract_figure_anchors.py`, `training/*_rsaf.py` (new)
- `models/segmentation_v3/` (gitignored weights; shipped in the image)
- `.dockerignore`, `.gcloudignore` (ship v3; the image must contain the
  figure GLBs, which are already under `assets/3d/bodies/`)
- `tests/`
- `CLAUDE.md` §5.10, §2

## 4. Steps
1. Write this plan.
2. Registry refactor, then run the Army regression suite.
3. Anchors, rules.
4. Render the RSAF dataset and train v3 (background, hours).
5. Pose offsets, benchmark.
6. Tests, then redeploy and run the live smoke test.
7. Update docs.

## 5. Risks & rollback
- **Army regression from the refactor.** Mitigated by the full existing
  suite plus the Army benchmark re-run on v3.
- **v3 worse for Army.** Mitigated by the promotion gate in §2.4; the
  default stays v2 otherwise.
- **Stylised figure ≠ real RSAF uniform.** This is the same
  synthetic-only caveat as Army; stated in the response notes and docs.
- **Rollback:** redeploy the previous image tag
  `cv-service:20261002-224206`.

## 6. Verification
- `pytest cv-service/tests/`, both benchmarks (Army + RSAF), and the live
  smoke test of an RSAF scan.
- `flutter test` (no app change expected).

## 7. Execution notes (2026-10-05 → 07)

**Segmenter v3**
- Fine-tuned from v2 on seg_v2 (Army) + 510 RSAF renders.
- Stopped at epoch 8/12: val mask mAP50 had plateaued at 0.83-0.86
  since epoch 2.
- Gate passed: Army val mask mAP50 0.878 vs v2 0.879; mAP50-95 0.604 vs
  0.600.
- RSAF val 0.852:
  - rank_tab 0.85, headwear 0.99, footwear 0.97;
  - cap_badge 0.71, name_tag 0.67;
  - sleeve_patch 0.49 (edge-on in front views).

**Per-uniform model**
- On the Army benchmark v3 raised belt false alarms from 17.9% to 62.5%
  (it learned "no belt visible" from untucked RSAF shirts).
- So `uniforms.UniformSpec.segmentation_model` selects the model per
  uniform (Army → v2 unchanged, RSAF → v3), via
  `segment_uniform.using_model`.

**Bugs found by the benchmark and fixed**
- **Anchor definitions.** RSAF `head_top` / `belt_center` / ankles must be
  defined as `mask_anchor_refinement` measures them: beret top, untucked
  shirt hem, boot tops. Otherwise the refined 2D points bent the PnP
  solve and chest items projected ~2.5 cm low. Chest-anchor projection
  bias went from +19 px to −0.4 px.
- **Boots.** The presence box is now centred on the boot.
- **Sleeve unit patch** is now not required ("check by eye"): it sits on
  the outer arm and was detected in only 2 of 46 correct front scenes.
- **Benchmark-only person-box fallback.** COCO YOLOv8n misses the
  stylised mannequins ("teddy bear"/none) in 37 of 60 scenes. It is
  reported as its own column; production is unchanged, and real people
  are unaffected.

**RSAF benchmark** (60 scenes, 420 item verdicts, production model
selection):

| Exact | Violation recall | False alarms | Abstain |
|---|---|---|---|
| 24.5% | 39.1% | 3.2% | 71.2% |

- Compliant scenes: 15 INCOMPLETE, 1 FAIL.
- Correct items measure 0.4-2.0 cm from doctrine against 1.0-1.5 cm
  tolerances, so they come back "too close to call" with the measured
  offset. This is the same single-photo limit as Army.

**Deploy**
- Two `gcloud` client crashes, both network: a 300 s upload read
  timeout, then DNS during polling. The remote build
  `20c2ef3e` succeeded; the image was deployed by hand.

**Live smoke**
- rsaf_no4_male: 200 in 13.6 s; rsaf_no4_female: 200 in 11.3 s;
  army_no3_male: 200 (13 items, as before).
- No-token requests → 401.

**Tests**
- cv-service: 212 pass, plus the one pre-existing
  `test_inspect_rejects_multi_person_photo` failure.
- Flutter: 155/155.

**APK:** `~/Desktop/SAF-Uniforms-RSAF-No4.apk` (no app change; it already
sends `rsaf_no4_*`).

# M2 — a real trained segmentation model, synthetic-only, correcting the "complete database" premise

- **Date:** 2026-08-05
- **Author:** Claude
- **Status:** verified

## 1. Goal

The user pointed at the fact that Firestore/Storage already holds a
"complete database" and asked to complete M2 (uniform segmentation).
Checked what that database actually contains before acting on it:
82 `accessory_library` entries (67 with a real `image_url`) plus
`branch_configs` / `dress_requirements` reference/config data — none
of it is photos of a person wearing the uniform with pixel-level
region labels, which is what M2 needs. So the premise "we have the
data, go complete M2" doesn't hold as stated.

What *does* hold: the same 3D asset completeness that made the
Milestone-5 anchor extraction and the earlier bbox synthetic-dataset
generator possible also supports generating pixel-perfect segmentation
masks (pyrender's `RenderFlags.SEG` mode renders exact, occlusion-correct
flat-color masks from the geometry — no approximation), and this
machine has `torch` with Apple-Silicon MPS acceleration available. So
rather than only correct the premise and stop, this plan goes one step
further than the earlier bbox-only dataset generator: it trains an
actual YOLOv8n-seg model on synthetic renders and wires it into
`cv-service` as a real Stage 4. This is genuine progress on M2 — with
an unavoidable, load-bearing caveat stated everywhere this model is
touched: **zero real photographs were used.**

## 2. Scope

- In scope:
  - `cv-service/training/generate_segmentation_dataset.py` — renders
    150 train + 30 val synthetic images with YOLO-seg-format polygon
    labels, using `pyrender.RenderFlags.SEG` + `seg_node_map` for
    exact per-pixel class colors. 9 classes: `shirt`, `trousers`
    (derived via a horizontal-plane cut of the single continuous body
    mesh at waist/neck height — the same y-slicing technique already
    used in this repo's own merger pipeline, see `CLAUDE.md` §8's pass
    history — not a novel hack), `headwear`, `cap_badge`, `epaulette`,
    `sleeve_rank`, `arms_badge`, `belt`, `footwear`.
  - `cv-service/training/train_segmentation.py` — trains YOLOv8n-seg
    on that dataset via `ultralytics`, device `mps`.
  - `cv-service/segmentation/segment_uniform.py` — inference wrapper
    around the trained weights, real Stage 4 module.
  - Wire it into `POST /inspect` (`api/main.py`) as a best-effort
    addition to the report (`segmentation` field: per-class pixel
    coverage fractions) — never breaks the rest of the report if the
    model is missing or fails.
  - New Python deps needed only at generation/training time (not
    added to `requirements.txt`, which stays inference-only):
    `pyrender`, `shapely`, `rtree`, `mapbox_earcut` (trimesh's mesh-
    slicing/capping dependency chain), `pyyaml`.
- Out of scope:
  - Any claim that this model works on real photos. It has been
    validated against a held-out *synthetic* split only — see §6.
  - Collecting or using real photos — none exist in this project yet
    (the Gallery feature's user-uploaded photos are a separate,
    private, per-user Firestore/Storage path that was not touched or
    accessed here).
  - Retraining any accessory *detector* (Stage 5 / M3) — this plan is
    segmentation (M2) only; the vision-crop inspector standing in for
    M3 is unchanged.
  - `collar` / `pocket` / `sleeve` as distinct segmentation classes —
    the reference body mesh has no separate sub-mesh or vertex-group
    for these; only `shirt` and `trousers` are derivable from the
    actual geometry (see `generate_segmentation_dataset.py`'s module
    docstring for the full explanation, including the known
    limitation that a hand hanging near hip height gets misclassified
    as `trousers`).

## 3. Affected areas

- New: `cv-service/training/generate_segmentation_dataset.py`,
  `train_segmentation.py`.
- New: `cv-service/segmentation/segment_uniform.py`.
- New (gitignored, not committed): `cv-service/synthetic_data/seg_v1/`
  (180 rendered images + labels), `cv-service/models/segmentation_v1/`
  (trained weights + ultralytics run artifacts).
- Update: `cv-service/api/main.py` (segmentation wired into `/inspect`,
  best-effort).
- Update: `cv-service/README.md`, `CLAUDE.md` §5.10.

## 4. Step-by-step plan

1. Check what's actually in the seeded Firestore data before acting
   on the "complete database" claim — confirmed it's reference/config
   metadata + single-item accessory photos, not a labeled dataset.
2. Confirm `torch` + MPS acceleration is actually available in this
   environment (it is — Apple M3).
3. Build the mask-rendering generator using `pyrender.RenderFlags.SEG`.
   First attempt used `pyrender.Scene.from_trimesh_scene`, which does
   **not** preserve node names on the resulting pyrender Nodes
   (verified directly: `node.name is None` for every node) — this
   silently produced an all-black SEG pass with zero labels for the
   first several debugging iterations. Fixed by building the SEG scene
   by hand, adding each mesh with an explicit `name=` and keeping the
   `Node` object `Scene.add()` returns directly.
4. Second bug: naively slicing the body into shirt/trousers dropped
   the head entirely from the RGB training images (nothing above the
   neck cut was kept anywhere). Fixed by rendering the RGB pass from
   the full, unsliced original body mesh, and adding the above-neck
   slice back into the SEG scene as an explicit unlabeled `_occluder`
   (same black as background) so it still correctly hides whatever's
   behind it without being classified as anything.
5. Verified both fixes by drawing the generated polygon labels back
   onto the rendered RGB image and visually confirming every region
   (shirt outline including sleeves, trousers, beret, cap badge,
   epaulettes, sleeve insignia, belt, shoes) lines up with the actual
   rendered geometry — not just that the script ran without error.
6. Generated the full 180-image dataset (150 train / 30 val) — ~4m45s.
7. Trained YOLOv8n-seg for 40 epochs on `mps` — see §6 for the actual
   run log and metrics, including a real environment gotcha
   (`pyrender`'s pyglet/Cocoa offscreen context intermittently fails
   with "screens[0] index out of range" when the display is allowed to
   sleep mid-run; fixed by wrapping long-running render/train
   invocations in `caffeinate`).
8. Built `segment_uniform.py` and wired it into `/inspect` as a
   best-effort addition.
9. Update docs, run the full test suite, mark this plan `verified`.

## 5. Risks & rollback

- **The dominant risk is the one stated everywhere this model
  appears: zero real photos, unknown real-world accuracy.** This must
  never be presented to an end user as "the AI segmented your uniform"
  without that caveat attached — it is a research checkpoint, not a
  shipped capability.
- Two silent-failure modes were found and fixed during this exact
  build (missing node names → blank masks; missing head → RGB/label
  mismatch) precisely *because* the output was verified visually at
  each step rather than trusted on "it ran without crashing." Anyone
  extending this generator (more classes, different body) should keep
  that verification habit — pyrender's flat-color SEG mode is easy to
  get silently, plausibly wrong.
- `/inspect`'s new `segmentation` field degrades to `null` on
  `FileNotFoundError` (model not trained/present) — never raises, never
  blocks the rest of the report.
- Rollback: delete `cv-service/segmentation/`,
  `cv-service/training/generate_segmentation_dataset.py` +
  `train_segmentation.py`, revert the `api/main.py` diff (additive,
  isolated to one try/except block).

## 6. Verification

- Trained YOLOv8n-seg for the full 40 epochs on `mps` — **0.193 hours
  (~12 minutes)**. Full log at the time of this run:
  `/tmp/cv_test/train_seg.log` (not part of the repo — session-local).
- **Final validation metrics (synthetic val split — 30 held-out
  renders of the same reference body, different random cameras; NOT
  real photos):**

  | Class | mAP50 (mask) |
  | --- | --- |
  | shirt | 0.995 |
  | trousers | 0.995 |
  | headwear | 0.995 |
  | footwear | 0.995 |
  | cap_badge | 0.904 |
  | belt | 0.556 |
  | arms_badge | 0.524 |
  | epaulette | 0.496 |
  | sleeve_rank | 0.222 |
  | **overall mAP50 (mask)** | **0.742** |
  | **overall mAP50-95 (mask)** | **0.486** |

  The pattern is coherent and worth stating plainly rather than just
  citing the average: the four large, high-contrast, unambiguous
  regions derived directly from body geometry (shirt/trousers/headwear/
  footwear) are essentially solved *on synthetic data* — expected,
  since they're big and the masks are geometrically exact by
  construction. The small accessory classes are much weaker,
  `sleeve_rank` especially (0.222) — likely some combination of small
  object size, the sleeve-insignia placement issue documented in the
  earlier MVP plan (rank insignia sitting near/overlapping the pocket
  region in some camera angles), and it only appearing in the ~60% of
  renders where the `specialist` condition and non-omitted-optional
  logic both fired, meaning fewer effective training examples than the
  raw instance count suggests.
- `.venv-tools/bin/pytest cv-service/tests/ -v` — **27/27 passed**,
  including 4 new `test_segmentation.py` cases, run against the final
  (not an interim) checkpoint.
- Ran the trained model directly against
  `tests/fixtures/rendered_army_no3_male_front.jpg` and rendered the
  predicted masks back onto the photo for visual inspection (not just
  "it returned some JSON"): shirt, trousers, and both feet's footwear
  regions are correctly located with 0.96–0.99 confidence. The visual
  check also makes the documented hand-as-trousers limitation directly
  visible — both hands, hanging near hip height in the A-pose, are
  colored as `trousers` — confirming that documented limitation is
  real and observable, not just theoretical.
- `flutter analyze` / `flutter test` — not re-run for this plan (no
  Dart files touched); still clean from the prior plan's verification.
- Confirmed via `git check-ignore -v` that the generated dataset
  (`cv-service/synthetic_data/seg_v1/`) and trained weights
  (`cv-service/models/segmentation_v1/`) are excluded from git by the
  existing `cv-service/models/` / `cv-service/synthetic_data/`
  `.gitignore` rules — nothing large or generated gets committed.
- What remains unverified, stated once more because it's the load-bearing
  caveat: **real-world accuracy against an actual photo of a person.**
  Nothing in this verification section tests that, because no such
  photo exists in this project yet.

# cv-service — geometry/ camera-pose solve + rule projection from Milestone B's pose estimate

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** verified

## 1. Goal

Given Milestone B's 2D anchor-pose estimate for a specific photo and the
known 3D anchors (`anchors.male.json`), recover the camera's pose via PnP
and use it to project every applicable doctrine rule
(`army_no3_male.json`) into expected 2D image-space zones — with
orientation tolerance, not just position — for that photo.

## 2. Relationship to already-shipped code (read before scoping)

Two things already exist and are already wired into `/inspect`:

- `calibration/pnp_solve.py`'s `solve_camera_pose(pose: PoseResult, ...)`
  — takes a raw `PoseResult`, does its own internal lookup against a
  fixed 7-anchor `CORRESPONDENCES` list keyed by BlazePose landmark name.
- `rules/rule_engine.py`'s `resolve_rules(camera, cm_per_px, ...)` —
  anchor+offset → 2D crop box, doctrine condition filtering, sleeve-
  fraction blending. Already returns per-rule `tolerance_cm` but not
  `tolerance_deg`, even though the doctrine JSON carries it.

This plan does not replace either. The task's own required signature —
"function taking 2D pose (Milestone B) + 3D anchors → camera
rotation/translation" — is a different input contract than
`pnp_solve.py`'s (`PoseResult`, not Milestone B's anchor-keyed dict), so
it can't be a thin wrapper regardless; it's a genuinely new
correspondence-gathering step that gets to use up to 15 anchors instead
of 7, since Milestone B covers 8 anchors PnP never had before
(`head_top`, `cap_band_front`, both collar tips, both chest pockets,
both sleeve-uppers). What IS reused, not reinvented: `pnp_solve.py`'s
`CameraSolution` type and `project_point()` — the actual projection math
is proven and tested; only correspondence-gathering is new. Similarly,
`project_rules.py` calls `rule_engine.resolve_rules()` internally rather
than reimplementing anchor+offset resolution, crop sizing, or condition
filtering — it only adds the orientation-tolerance field on top.

Nothing in `/inspect`'s shipped path changes. Both new modules are
standalone and tested, not wired in — same posture as Milestone B's
`anchor_mapping.py`.

## 3. Scope

- In scope:
  - `cv-service/geometry/solve_camera_pose.py`:
    - `solve_camera_pose(anchor_pose: dict, image_width: int, image_height: int, anchors: dict | None = None, *, min_correspondences: int = 6, min_confidence: float = 0.3) -> CameraSolution`
      (`CameraSolution` = `pnp_solve.py`'s existing type, imported not
      redefined).
    - Correspondence gathering: every one of Milestone B's 15 socket
      anchors (excluding the derived `chest_center` — using it would add
      a correspondence that's just the midpoint of two others already in
      the set, no new geometric information, and risks quietly biasing
      the solve toward its own derivation) with `confidence >=
      min_confidence` becomes one `cv2.solvePnP` correspondence.
    - `min_confidence = 0.3` justified: Milestone B's direct anchors
      report confidence ≈ landmark visibility (commonly 0.8–0.99);
      interpolated anchors are visibility × 0.6; extrapolated anchors
      (`head_top`, `cap_band_front`) are visibility × 0.35. A 0.5
      threshold (matching `pnp_solve.py`'s visibility cutoff) would
      exclude essentially every heuristic anchor even at high underlying
      visibility, defeating the point of using Milestone B's fuller
      estimate. 0.3 keeps well-detected heuristic anchors (visibility
      ≳0.5 for interpolated, ≳0.85 for extrapolated) while still
      dropping genuinely poor ones.
    - `min_correspondences = 6` justified: `cv2.solvePnP` mathematically
      requires ≥4 non-coplanar points; 6 gives a 2-point stability margin
      given several of Milestone B's points are themselves geometric
      estimates, not raw detections, and reprojection error is the only
      gate anyway (see below), not a hard proof of accuracy.
    - Degenerate cases explicitly flagged, never silently returned: too
      few qualifying correspondences → `solved=False, reason=
      "insufficient_correspondences"`; `solvePnP` non-convergence →
      `solved=False, reason="solvepnp_failed"`; reprojection error above
      threshold → `solved=True, reliable=False, reason=
      "high_reprojection_error"` (matches `pnp_solve.py`'s existing
      `reliable` semantics exactly, reusing its dynamic
      shoulder-width-scaled threshold — `0.4 × shoulder width in px`,
      computed here from Milestone B's `left/right_shoulder_seam`
      estimates directly — over a fixed pixel count, for the same reason
      `pnp_solve.py` already chose it: a tight crop and a full-body shot
      need different absolute tolerances).
  - `cv-service/geometry/project_rules.py`:
    - `project_rules(camera: CameraSolution, cm_per_px: float, profile: dict | None = None, rules: list[dict] | None = None) -> list[ProjectedRule]`
      — calls `rule_engine.resolve_rules()` internally (no
      reimplementation) and wraps each `ResolvedRule` in a new
      `ProjectedRule` (adds `angle_deg: float | None` and
      `tolerance_deg: float | None`, read straight from the rule's
      `raw_rule` — already carried by `ResolvedRule` but not surfaced —
      no invented numbers).
    - `cm_per_px_from_anchor_pose(anchor_pose, anchors=None) -> float | None`
      — Milestone B's-dict equivalent of `pnp_solve.py`'s
      `scale_factor_cm_per_unit(pose)`, same ratio-of-shoulder-widths
      method, different input shape.
  - `cv-service/geometry/evaluate_camera_pose_accuracy.py`: runs the new
    solver against Milestone A's 3 synthetic stand-ins (known-exact
    ground-truth camera translation + identity rotation, imported
    directly from `labeling/render_standins.py`'s `VARIANTS` — not
    re-derived or guessed) and reports, **as a distribution across the
    test set, not a single blended number**:
    - Reprojection error (px) — the self-consistency metric the task
      calls "load-bearing."
    - Translation error (cm) and rotation error (deg) against the
      *actual* render camera — possible only because these are synthetic
      renders with exactly-known ground truth; this is strictly
      stronger evidence than reprojection error alone, which only proves
      internal consistency between the correspondences and the solved
      camera, not that the solved camera matches reality.
    - A real-photo row reporting **0 photos**, not a number.
  - `cv-service/tests/test_geometry_camera_pose.py`: synthetic-correspondence
    unit tests (mirroring `test_pnp_projection.py`'s existing pattern —
    project known anchors through a known camera, confirm recovery,
    including a held-out anchor never in the correspondence set),
    degenerate-case tests (too few correspondences, corrupted
    correspondences → high reprojection error), and an integration test
    against Milestone A's 3 stand-ins asserting the measured
    translation/rotation error stays within a documented bound.
  - `cv-service/tests/test_geometry_project_rules.py`: confirms
    `tolerance_deg`/`angle_deg` are correctly surfaced for rules that
    have them (e.g. cap badges: `tolerance_deg=10`) and `None` for rules
    that don't (e.g. `army_beret`: presence-only, no orientation data in
    doctrine).
- Out of scope:
  - Any change to `calibration/pnp_solve.py`, `rules/rule_engine.py`, or
    `api/main.py` — confirmed by the full pre-existing suite passing
    unmodified.
  - Wiring either new module into `/inspect`.
  - Sourcing real photos (still 0 — see §5).
  - A per-accessory *orientation estimate* from the photo (i.e. actually
    measuring the observed angle of a badge in the crop) — this plan
    only projects the *expected* angle + tolerance doctrine specifies;
    comparing that against an observed angle is Stage 4/5's job
    (currently the vision-crop stand-in), not this plan's.

## 4. Real-photo count (unchanged)

**Zero.** Same repo, same gap as Milestones A and B. The evaluation
script's real-photo row states this explicitly rather than omitting it
or reusing the synthetic number.

## 5. Risks & rollback

- **Reprojection error alone would overstate confidence** if it were the
  only metric reported — a badly-solved camera can still self-consistently
  reproject its own (also-wrong) correspondence set with low pixel error
  if the error is systematic rather than random. This is exactly why §3
  also measures translation/rotation error against the *actual* render
  camera for the synthetic set, not reprojection error alone. This
  stronger check is unavailable for real photos (no independent ground
  truth), which is a real limitation carried forward, not solved here.
- **A third parallel BlazePose-derived correspondence path now exists**
  (`pnp_solve.py`'s 7-anchor `CORRESPONDENCES`, Milestone B's general
  16-anchor `anchor_mapping.py`, and now this plan's confidence-filtered
  subset of Milestone B's output for PnP specifically) — same accepted
  trade-off as Milestone B's risk log: documented in each module's
  docstring rather than unified, since unifying them is a separate
  consolidation decision with its own risk, not a byproduct of this
  plan.
- Low blast radius: new files only (`cv-service/geometry/`), the only
  cross-module dependency is importing `pnp_solve.py`'s `CameraSolution`
  /`project_point` and `rule_engine.py`'s `resolve_rules` — both already
  public, neither modified. Rollback is `rm -rf cv-service/geometry
  cv-service/tests/test_geometry_camera_pose.py
  cv-service/tests/test_geometry_project_rules.py`.

## 6. Verification

- `.venv-tools/bin/pytest cv-service/tests/ -v` — full suite including
  the two new test files, plus every pre-existing test (confirms zero
  disturbance to `pnp_solve`/`rule_engine`/`api`).
- `cv-service/geometry/evaluate_camera_pose_accuracy.py` run against
  Milestone A's 3 known-camera synthetic stand-ins. Results below.

**Reprojection + pose-recovery error (measured —
`.venv-tools/bin/python cv-service/geometry/evaluate_camera_pose_accuracy.py`):**

| Metric | Photos | Mean | Median | Min | Max |
| --- | --- | --- | --- | --- | --- |
| Reprojection error (px) | 3 | 32.1 | 34.3 | 25.6 | 36.5 |
| Translation error (cm) | 3 | 62.3 | 76.9 | 8.0 | 101.9 |
| — lateral component (cm) | 3 | 6.1 | 7.8 | 2.7 | 7.9 |
| — depth component (cm) | 3 | 61.9 | 76.5 | 7.6 | 101.6 |
| Rotation error (deg) | 3 | 9.7 | 6.8 | 4.0 | 18.3 |

| Anchor set | Photos |
| --- | --- |
| Synthetic (known camera) | 3 |
| Real photos | **0 — none exist in this repo** |

**Reading these numbers honestly — this is the actual finding this
milestone was built to surface:** reprojection error (25–36px on a
800×1200px synthetic render) looks reasonable on its own, and would read
as "the geometry works" if reported alone. It doesn't tell the whole
story. Breaking translation error into components shows why: lateral
error (in-image-plane position) is genuinely good — 2.7–7.9cm, mean
6.1cm — but depth error (distance from camera along its viewing axis) is
large and unstable — 7.6–101.6cm, mean 61.9cm, i.e. up to roughly a
metre of error recovering how far back the camera stood. This is a real,
expected PnP failure mode for a near-frontal single-photo view: depth
along the viewing axis has almost no parallax to constrain it from body
landmarks alone (small errors in the 2D correspondences translate into
large uncertainty along that one axis specifically), independent of how
good the 2D pose estimate is. Verified empirically, not just derived:
the solved rotation is near-identity and the solved translation's
lateral components land close to the known camera position for all 3
photos — confirming the error is concentrated in depth specifically, not
spread evenly or symmetric with a sign error in the ground-truth
comparison itself.

**What this means for viability:** the geometric approach looks sound
for what `project_rules.py` actually needs — 2D crop-region placement,
which depends primarily on reprojection accuracy and lateral position,
both of which are reasonable here. It is **not** currently trustworthy
for anything that depends on recovered depth specifically (e.g. deriving
absolute real-world distances, or comparing depth across photos) from a
single near-frontal correspondence set alone — that would need either a
second view, a strong prior on camera-to-subject distance, or accepting
depth as unreliable and not building anything on top of it. This is a
real geometric limitation of single-view PnP from body landmarks, not a
bug in this milestone's code, and not something a fallback (e.g. purely
vision-language judgment) would obviously fix either, since it's a
distance-estimation problem specifically, not a "does the model
understand the photo" problem.

- `flutter analyze` / `flutter test` not required — no Dart touched.

## 7. CLAUDE.md updates required

- §5.10: a short paragraph on `geometry/solve_camera_pose.py` +
  `geometry/project_rules.py`, why they're additive alongside
  `pnp_solve.py`/`rule_engine.py` rather than replacements, and the
  measured error table above (with the same 0-real-photos caveat every
  other subsection here carries).

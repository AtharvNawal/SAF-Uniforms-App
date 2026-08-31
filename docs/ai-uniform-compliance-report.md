# AI Uniform Compliance Check — Phase 1 & Phase 2 Report

**Scope of this document:** everything built for the "does this photo match
the expected uniform?" feature, across two phases:

- **Phase 1** — a shipped, single-shot AI-vision compliance check wired into
  the production `ARScannerScreen` (2026-07-26 – 2026-07-31).
- **Phase 2** — a standalone `cv-service` computer-vision pipeline that
  replaces whole-photo guessing with real geometry (2026-08-05 – 2026-08-06).

Both phases are **real, working code**, not mockups. Neither is fully
production-validated — the honest caveats for each are called out inline
rather than glossed over, because that distinction matters for anyone
deciding what to rely on next.

---

## TL;DR

| | Phase 1 | Phase 2 |
| --- | --- | --- |
| What it is | One Cloud Function, one Claude vision call over the whole photo | A 7-stage Python CV pipeline: detect → pose → camera solve → project doctrine rules → crop → vision-judge each crop → aggregate |
| Status | **Shipped** — live in `ARScannerScreen`'s default tap-to-capture flow | **Dev-only** — reachable via a long-press on the same capture button, points at `localhost:8001`, never deployed |
| Where the "where to look" comes from | The model guesses, from the whole image | Real 3D geometry (PnP camera-pose solve against the reference body's sockets) |
| Where the "what is this" judgment comes from | Claude, looking at the whole photo | Claude, looking at a small geometry-derived crop (same technique, tighter input) |
| Trained ML in the loop | None | A real trained YOLOv8n-seg model (segmentation) — synthetic training data only |
| Real-photo validation | None (no real soldier photo exists in this project yet) | None — same gap, explicitly documented in every plan/README that touches it |
| Persisted anywhere? | No — fully ephemeral | No — fully ephemeral |
| Cost per check | 1 Claude call | Up to N Claude calls (one per doctrine rule crop) + local inference (YOLO, MediaPipe, PnP — free) |

---

## Phase 1 — AI Uniform Compliance Check (shipped)

**Plan:** [`ChangeRequest/2026-07-30_ai-uniform-compliance-check.md`](../ChangeRequest/2026-07-30_ai-uniform-compliance-check.md)
**Status:** code executed and locally verified 2026-07-31; live device + Firebase
deploy verification still pending (needs an operator with Anthropic + Firebase
credentials and a physical device/simulator).

### 1.1 The problem it solves

Before this phase, `ARScannerScreen`'s Phase-2 scorecard was cosmetic — it
always showed a hardcoded score of `86`, two fixed "issue" strings, and four
fixed "pass" strings, regardless of what photo was captured. This phase
replaces every one of those hardcoded numbers with a real verdict from an
actual AI vision model looking at the user's actual photo.

### 1.2 Why this design, not the alternatives

Three approaches were on the table; two were explicitly rejected:

- **Render-and-diff against the composed 3D GLB** — rejected. Aligning a real
  photo's camera angle/pose against a 3D render is a hard, high-risk problem
  on its own, and Phase 1 needed something shippable quickly.
- **On-device pose heuristics** (e.g., ML Kit landmark distance checks) —
  rejected as crude and high-false-positive.
- **Cloud vision-LLM analysis** (chosen) — send the photo, plus the exact
  list of accessories the system already expects for that user's
  branch/rank/gender/dress code, to Claude, and ask for a structured verdict.

The expected-accessory list is not re-derived by guesswork — it reuses
`resolveAccessorySplit`, the **same TypeScript resolver `composeUniformModel`
already uses** to decide which accessories go on the 3D model. That means the
compliance check and the 3D avatar are provably checking against the same
source of truth.

### 1.3 How it works end to end

```
ARScannerScreen (tap capture)
  → image_picker camera capture (JPEG)
  → UniformComplianceController.check(dressCode, photoBytes)
  → UniformComplianceRepository → FirebaseFunctions.httpsCallable('checkUniformCompliance')
       (photo base64-encoded client-side)
  → Cloud Function: checkUniformCompliance
       1. Verify auth (req.auth.uid)
       2. Zod-validate {dressCode, photoBase64, mimeType}
       3. Load users/{uid}/profile/current  → {branch, rank, gender, isSikh, dressAccessoryChecks}
       4. Load dress_requirements/{dressDoc} + accessory_library
       5. resolveAccessorySplit(...) → {mandatory, optional}
       6. expected = mandatory + (optional accessories the user has ticked)
       7. Best-effort fetch each expected accessory's reference image
          from Storage (accessories/{id}/image.png) — up to 8 images,
          degrades to text-only description per accessory on failure
       8. Anthropic messages.create, model = claude-sonnet-5,
          tool_choice FORCED to `report_compliance`
             content = [prompt text, user's photo, ...reference images]
       9. zod-validate the tool_use.input before trusting it
      10. Return {overallScore, summary, items[]} — nothing persisted
  ← ComplianceResult rendered in the real scorecard
       (correct → green "Checks", missing/incorrect → red "Issues",
        uncertain → neutral third list)
```

### 1.4 The forced tool-use schema

The response shape is **guaranteed**, not parsed out of free-form prose —
`tool_choice` is pinned to a single tool, and the tool's `input` is
zod-validated server-side before it's ever returned to the client:

```ts
{
  overallScore: number;      // 0–100
  summary: string;           // 1–2 sentence plain-English verdict
  items: Array<{
    accessoryId: string;
    displayName: string;
    status: "correct" | "missing" | "incorrect" | "uncertain";
    note: string;             // why this status was given
  }>;
}
```

The `"uncertain"` status exists specifically so the model can hedge on a
poorly-lit or off-angle photo instead of guessing — the UI is expected to
present this as "AI estimate," not "verified."

### 1.5 Files touched / created

| File | What it is |
| --- | --- |
| [`functions/src/checkUniformCompliance.ts`](../functions/src/checkUniformCompliance.ts) | The Cloud Function itself |
| [`functions/src/checkUniformCompliance.test.ts`](../functions/src/checkUniformCompliance.test.ts) | 6 tests — zod schema + prompt builder, no live Anthropic call |
| `functions/src/index.ts` | Exports the new callable |
| `functions/package.json` | Adds `@anthropic-ai/sdk` |
| [`lib/features/ar_scanner/domain/entities/compliance_result.dart`](../lib/features/ar_scanner/domain/entities/compliance_result.dart) | `@freezed` `ComplianceResult` / `ComplianceItem` / `ComplianceStatus`, mirrors the CF's JSON 1:1 |
| [`lib/features/ar_scanner/data/uniform_compliance_repository.dart`](../lib/features/ar_scanner/data/uniform_compliance_repository.dart) | Wraps the httpsCallable, base64-encodes the JPEG client-side |
| [`lib/features/ar_scanner/presentation/providers/uniform_compliance_provider.dart`](../lib/features/ar_scanner/presentation/providers/uniform_compliance_provider.dart) | `UniformComplianceController` (`@riverpod AsyncNotifier`) — `check()` / `reset()` |
| `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart` | Rewired: real camera capture → analyzing phase → real scorecard → retry-on-failure state |
| `lib/core/l10n/arb/{app_en,app_zh}.arb` | New strings: analyzing / analyzing-sub / check-failed / retry / uncertain-checks |

### 1.6 Backend details worth knowing

- **Region:** `asia-southeast1`, 60s timeout, 512MiB memory.
- **Secret:** `ANTHROPIC_API_KEY` via Firebase Secret Manager
  (`defineSecret`) — never logged, never sent to the client. Operator must
  run `firebase functions:secrets:set ANTHROPIC_API_KEY` once before this
  can work live.
- **Auth required** — same `req.auth` pattern as `composeUniformModel`.
- **Nothing is persisted.** No Firestore write, no history. Every scan
  starts clean; this was an explicit user decision, not an oversight.
- **Reference images:** capped at 8 per check (`MAX_REFERENCE_IMAGES`) to
  bound both latency and cost — accessories beyond that limit still appear
  in the prompt as text (id/name/category), just without an image.
- **Logging:** `info` on start/ok (uid, dressCode, item count), `debug` on
  resolved accessory ids, `error` with stack trace on failure — matches
  project policy 1.3.
- **Error handling:** the entire handler body is one `try/catch`; any
  failure surfaces to the client as `HttpsError("internal", ...)` so the UI
  can show a retry button instead of crashing.

### 1.7 What was verified vs. what wasn't

| Check | Status |
| --- | --- |
| `npm run build && npm test` (functions) | ✅ 28/28 pass (22 pre-existing + 6 new) |
| `flutter analyze` | ✅ clean |
| `build_runner build` | ✅ generated `compliance_result.freezed.dart` + `uniform_compliance_provider.g.dart` |
| `flutter gen-l10n` | ✅ clean |
| `flutter test` | ✅ 77/77 pass |
| Live Anthropic API call | ❌ not exercised in-session (no API key available) |
| `firebase deploy --only functions` + secret provisioning | ❌ not run (needs operator credentials) |
| Real device smoke test (capture → real scorecard) | ❌ not run (no attached device/simulator) |

**Bottom line for Phase 1:** the code is complete, type-checked, and unit
tested down to the schema/prompt-builder level. What's *not* proven yet is
that a live Anthropic call from a real device produces a sensible verdict on
a real photo — that requires an operator to provision the secret, deploy,
and run the scan once on a phone.

### 1.8 Known limitations (by design, not oversights)

- Single-shot capture only — no continuous/live camera analysis.
- Accuracy depends entirely on Claude's whole-photo judgment; no geometry
  helps it find where an accessory *should* be (that's what Phase 2 adds).
- Anthropic API cost scales with checks performed — mitigated only by
  "manual capture, not continuous scanning" and small `max_tokens`.

---

## Phase 2 — `cv-service` (dev-only CV pipeline)

**Plans (built in this order):**
1. [`2026-08-05_cv-service-anchor-extraction-scaffold.md`](../ChangeRequest/2026-08-05_cv-service-anchor-extraction-scaffold.md) — data foundation
2. [`2026-08-05_cv-service-mvp-inspect-endpoint.md`](../ChangeRequest/2026-08-05_cv-service-mvp-inspect-endpoint.md) — the real `/inspect` endpoint
3. [`2026-08-05_cv-service-remaining-milestones.md`](../ChangeRequest/2026-08-05_cv-service-remaining-milestones.md) — Flutter wiring, container, dataset generator
4. [`2026-08-05_cv-service-m2-synthetic-segmentation-model.md`](../ChangeRequest/2026-08-05_cv-service-m2-synthetic-segmentation-model.md) — trained segmentation model

**Status:** all four plans marked `verified`. **Not deployed anywhere, not
wired into production** — `functions/src/checkUniformCompliance.ts` (Phase 1)
is completely untouched and remains the shipped default.

### 2.1 The core idea

Phase 1's weakness is that Claude has to find 18 accessories somewhere in one
whole photo with no help. Phase 2's core insight: **the reference body GLB
that already powers the 3D avatar (`composeUniformModel`) carries 15 named
sockets that are geometrically identical to doctrine's own placement anchors**
("collar edge," "pocket top edge," "shoulder seam"). Those sockets can be
frozen into a static coordinate file once, offline, and then every future
inspection just measures a photo against that file — never comparing pixels
to a rendered image, never re-parsing a GLB per request.

Given a photo, if you can figure out **where the camera was standing
relative to the body**, you can project any doctrine anchor + offset into
that specific photo's pixel space — turning "find the cap badge somewhere in
this photo" into "look inside this small 80×80px box, the cap badge should
be right there." That's exactly what stages 1–3 + 6 below do, using real,
untrained, classical/pretrained computer vision. Only the last step (Claude
judging what's inside the box) is still a vision-language judgment rather
than a trained detector — because a trained detector needs labeled data that
doesn't exist yet.

### 2.2 Pipeline stages

```
POST /inspect (multipart: photo, rank_tier, gender, is_sikh, medal_row_count)
  │
  ├─ Stage 1: pose/detect_person.py         YOLOv8n (pretrained, COCO "person")
  │             → rejects empty or multi-person frames (422 on failure)
  │
  ├─ Stage 2: pose/estimate_pose.py         MediaPipe Tasks PoseLandmarker (pretrained)
  │             → 33 real body keypoints
  │
  ├─ Stage 3: calibration/pnp_solve.py      OpenCV solvePnP
  │             → matches a fixed correspondence set (shoulders, collar tips,
  │               belt_center, head_top) between the canonical 3D anchors
  │               (rules/anchors.male.json) and the 2D pose landmarks
  │             → recovers camera position/orientation relative to the body
  │             → CameraSolution.reliable: a reprojection-error guard scaled
  │               to the subject's own shoulder width — rejects poses that
  │               don't resemble a relaxed standing A-pose (422, "recapture")
  │
  ├─ Stage 4: (segmentation)                segmentation/segment_uniform.py
  │             → a REAL TRAINED YOLOv8n-seg model, 9 classes
  │             → best-effort: degrades to `segmentation: null` if the
  │               model/weights aren't present, never blocks the report
  │
  ├─ Stage 5/4 (detection): rules/rule_engine.py
  │             → loads rules/army_no3_male.json (18 doctrine rules)
  │             → filters by profile condition (rank tier / gender / Sikh /
  │               medal row count)
  │             → resolves each rule's anchor + cm offset to a 3D point,
  │               projects it via Stage 3's solved camera
  │             → sizes a pixel-space crop region around the projection
  │               (from search_radius_cm or a tolerance-derived default)
  │             → includes a 2D blend toward the detected elbow landmark
  │               for "half of sleeve length from the shoulder seam"-style
  │               rules, so the crop lands on the actual sleeve, not the
  │               shoulder anchor
  │
  ├─ Stage 4/5 substitute: detectors/vision_crop_inspector.py
  │             → sends EACH geometrically-located crop (not the whole
  │               photo) to Claude with a forced-tool-use schema, same
  │               pattern as Phase 1's checkUniformCompliance
  │             → explicitly NOT a trained detector — a vision-language
  │               judgment applied to an already-measured region
  │
  └─ Stage 7: reporting/report.py
                → aggregates every verdict into the report JSON:
                  overall_score, per-region subscores, issues[], uncertain[]
                → draws a green/yellow/red annotated image (OpenCV)
                → 2 of the subscore buckets (lower_body, appearance) have
                  no rules yet and report `null` — not a faked passing score
```

### 2.3 What's real geometry vs. what's a stand-in — the load-bearing table

| Stage | Module | Real CV / pretrained, no training data needed? |
| --- | --- | --- |
| Human detection | `pose/detect_person.py` (YOLOv8n) | ✅ pretrained |
| Pose estimation | `pose/estimate_pose.py` (MediaPipe) | ✅ pretrained, 33 keypoints |
| Camera-pose recovery | `calibration/pnp_solve.py` (OpenCV `solvePnP`) | ✅ classical CV, real math |
| Rule → pixel-space projection | `rules/rule_engine.py` | ✅ real geometry, no ML |
| Segmentation | `segmentation/segment_uniform.py` | ✅ a real **trained** model — but **synthetic training data only**, zero real photos |
| Accessory presence/type judgment | `detectors/vision_crop_inspector.py` | ❌ **not a trained detector** — Claude vision-language judgment on a real, geometrically-derived crop |

The one sentence worth repeating from every plan file and the service's own
README: *the position is real (PnP + projection); the identification inside
that position is not yet backed by training data.*

### 2.4 The segmentation model — the one piece that's actually trained

This is the most substantial new artifact in Phase 2. Triggered by a check
that the "we already have a complete database" premise didn't actually hold
for segmentation (82 `accessory_library` entries + config data is not
pixel-labeled photos of a worn uniform) — but the same 3D-asset completeness
that unblocked the anchor extraction also unblocks **rendering exact,
occlusion-correct segmentation masks straight from the geometry**
(`pyrender.RenderFlags.SEG`), with `torch` + Apple-Silicon MPS available
locally for training.

**What was built:**
- [`cv-service/training/generate_segmentation_dataset.py`](../cv-service/training/generate_segmentation_dataset.py)
  — renders 150 train + 30 val synthetic images with YOLO-seg polygon
  labels, 9 classes: `shirt`, `trousers` (derived via a horizontal-plane cut
  of the one continuous body mesh — the same slicing technique already used
  in this repo's own 3D merger), `headwear`, `cap_badge`, `epaulette`,
  `sleeve_rank`, `arms_badge`, `belt`, `footwear`.
- [`cv-service/training/train_segmentation.py`](../cv-service/training/train_segmentation.py)
  — trains YOLOv8n-seg via `ultralytics` on device `mps`. **40 epochs took
  ~12 minutes.**
- [`cv-service/segmentation/segment_uniform.py`](../cv-service/segmentation/segment_uniform.py)
  — inference wrapper, wired into `/inspect`'s `segmentation` field
  (best-effort, never breaks the rest of the report).

**Two real bugs found and fixed while building this** (not just "it ran"):
1. `pyrender.Scene.from_trimesh_scene` silently drops node names, which
   broke the SEG-mode class-color lookup and produced an all-black mask for
   several debugging iterations before being caught.
2. Naively slicing the body at the neck for the shirt/trousers cut dropped
   the head entirely from the RGB training images. Fixed by rendering RGB
   from the full unsliced body and adding the head back into the SEG scene
   as an unlabeled occluder.

**Validation results (synthetic held-out split — 30 renders, same body,
different random cameras; NOT real photos):**

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
| **overall mAP50** | **0.742** |
| **overall mAP50-95** | **0.486** |

Large, unambiguous, geometrically-exact regions (shirt/trousers/headwear/
footwear) are essentially solved *in the synthetic domain*. Small accessory
classes are much weaker — `sleeve_rank` (0.222) worst of all, likely a
combination of small object size and the known sleeve-placement issue from
the MVP plan. Running the trained model against the one real-ish test
fixture (a rendered photo, not a photograph) reproduces a documented,
real limitation directly and visibly: **hands hanging near hip height in
the A-pose get misclassified as `trousers`**, because the plane-cut can't
distinguish torso from arm at the same world height.

**The caveat that must travel with this model everywhere it's mentioned:
zero real photographs were used in training or validation. Real-world
accuracy is completely unvalidated.** This is a real trained model and a
real mechanism proof — not a production-ready segmenter.

### 2.5 Flutter-side wiring (dev path only)

Everything below is **additive** — the shipped Phase-1 tap-to-capture flow
in `ar_scanner_screen.dart` is untouched.

| File | Purpose |
| --- | --- |
| [`lib/features/ar_scanner/domain/entities/cv_inspection_result.dart`](../lib/features/ar_scanner/domain/entities/cv_inspection_result.dart) | Mirrors `cv-service`'s report shape field-for-field: 5-state `CvVerdict` (present / missing / misaligned / wrongType / lowConfidence), `CvSubscores`, `CvIssue`, `CvUncertainItem`, `CvCameraDiagnostics`. Deliberately kept separate from Phase 1's `ComplianceResult` — the two backends return different-shaped reports. |
| [`lib/features/ar_scanner/data/cv_service_inspection_repository.dart`](../lib/features/ar_scanner/data/cv_service_inspection_repository.dart) | HTTP multipart client for `cv-service`'s `POST /inspect` (`kCvServiceBaseUrl`, defaults to `localhost:8001`). |
| [`lib/features/ar_scanner/presentation/providers/cv_service_inspection_provider.dart`](../lib/features/ar_scanner/presentation/providers/cv_service_inspection_provider.dart) | `CvServiceInspectionController` — same `@riverpod AsyncNotifier` shape as Phase 1's controller. |
| [`lib/features/ar_scanner/data/capture_quality_gate.dart`](../lib/features/ar_scanner/data/capture_quality_gate.dart) | On-device pose-quality check via `google_mlkit_pose_detection` (a previously declared-but-unused dependency) — rejects a picked photo (no person / torso not visible / camera tilted) **before** it's uploaded to *either* backend. Runs post-capture (this app has no live camera feed to gate mid-shutter). Degrades to "accept" on any internal error — a broken gate must never be worse than no gate. |
| `ar_scanner_screen.dart` | **Long-press** the capture button (instead of tap) routes through the Phase-2 path → `_CvScorecard`, labelled "PHASE 2 · DEV". |

**How to reach it on a device:** run `cv-service` locally
(`uvicorn api.main:app --port 8001`), then `flutter run
--dart-define=CV_SERVICE_BASE_URL=http://<host>:8001` (Android emulator:
`10.0.2.2`).

### 2.6 Supporting infrastructure

- **`cv-service/Dockerfile` + root `.dockerignore`** — a container image for
  the service. **Unverified** — no Docker binary was available in the
  environment that authored it; reviewed by hand against
  `requirements.txt` and the real file layout, not build-tested. Not
  deployed anywhere.
- **`cv-service/training/generate_synthetic_dataset.py`** — a bounding-box
  dataset generator (COCO-shaped `annotations.json`) for the not-yet-built
  accessory detector (Milestone 3). Renders the reference body + doctrine
  accessories from randomized `pyrender` cameras; boxes are derived by
  projecting actual mesh vertices through the exact render camera, not
  guessed. Verified for 6 renders by drawing the generated boxes back onto
  the source image and visually confirming every box (beret+cap badge, both
  epaulettes, arms badge, belt) tightly wraps the real geometry. This is
  genuine progress on M3's *data prerequisite* — not M3 itself.

### 2.7 Test coverage

`cv-service/tests/` — **27 tests, all runnable with zero external
credentials** (the Anthropic call is dependency-injected and replaced with a
deterministic fake client everywhere it's exercised):

| Test file | What it covers |
| --- | --- |
| `test_extract_anchors.py` | Anchor extraction against the real body GLB — 15 sockets present, coordinates finite, left/right mirrored, vertical ordering anatomically sane |
| `test_pnp_projection.py` | PnP math against synthetic correspondences, including generalization to an anchor never used in the solve |
| `test_rule_engine.py` | Rule condition filtering, paired-anchor crop computation |
| `test_report_pipeline.py` | Full Stage 1→7 pipeline called directly in Python, against a real rendered photo, with forced `missing`/`low_confidence` verdicts injected via the fake client |
| `test_api.py` | The same pipeline, exercised through a real HTTP `POST /inspect` |
| `test_segmentation.py` | 4 tests against the final trained segmentation checkpoint |

**Live smoke tests run during development surfaced two real bugs, fixed
before calling any of this done:**
1. MediaPipe's own canonical demo photo (a Warrior-II yoga pose, deep lunge)
   made `solvePnP` "succeed" with a reprojection error of **3320px** —
   projected anchors landed thousands of pixels outside the frame. This is
   exactly the failure mode `CameraSolution.reliable` was built to catch;
   the bad photo now correctly reports `solved=True, reliable=False`
   instead of silently returning garbage.
2. The rendered reference-body test photo initially mis-projected the
   sleeve-insignia crop onto the chest pocket (the "half sleeve length from
   shoulder seam" rule had no sleeve-length component). Fixed by blending
   the projected anchor toward the detected elbow landmark; re-verified
   visually.
3. `zidane.jpg` (Ultralytics' bundled two-person sample) correctly triggers
   `multiple_people_detected`, both at the module level and through a real
   HTTP call.

The one "real" photo used throughout (`tests/fixtures/rendered_army_no3_male_front.jpg`)
is an offscreen `pyrender` render of the actual reference body GLB —
**not a photograph** — since no real soldier photo exists in this project.
Regenerate it via `tests/fixtures/generate_fixture.py` if the reference body
changes.

### 2.8 What's explicitly NOT built / NOT achievable yet

Stated once, plainly, because it's the load-bearing gap across all of Phase 2:

- **A trained accessory detector (Milestone 3)** — genuinely un-completable
  without labeled real-photo (or at minimum, validated synthetic) training
  data that doesn't exist. `vision_crop_inspector.py` remains the stand-in.
- **Any validation against a real photograph, for anything** — segmentation,
  PnP accuracy, the vision-crop judgments, all of it. This is the single
  biggest open risk across the whole phase, repeated deliberately in every
  plan and README section that touches a model.
- **Docker build verification** — the `Dockerfile` exists and was reviewed
  by hand, not `docker build`-tested.
- **Cloud Run deployment** — nothing has been deployed anywhere.
- **Flipping `checkUniformCompliance.ts` over to call this service** — the
  Flutter app *can* reach `cv-service` today, but only via the opt-in
  long-press dev path. Making this the production default is explicitly
  deferred to its own future plan + device test.
- **Blender-based synthetic rendering** — `pyrender` was used instead
  (no Blender binary available in the build environment); same job,
  different renderer, swappable later.

---

## Where things stand today (2026-08-10)

- **Phase 1 is shipped code**, live in the default tap-to-capture AR Scanner
  flow, but has never been exercised against a live Anthropic key or a real
  device in this project — that's an operator action away, not more
  engineering.
- **Phase 2 is a complete, tested, standalone service** that nothing in
  production calls. It's reachable today only via a developer's long-press
  gesture pointed at a `localhost` instance.
- **Both phases are fully ephemeral** — no compliance-check history is
  persisted to Firestore in either phase; every scan starts from a clean
  slate by design.
- **The single biggest shared gap across both phases: zero real soldier
  photographs exist anywhere in this project.** Every accuracy number in
  this report (mAP50 scores, PnP reprojection error, visual crop checks) was
  measured against synthetic renders or a handful of stock/test images —
  never a photo of an actual person wearing the actual uniform. Closing that
  gap is the natural next milestone before either phase's numbers can be
  trusted at face value.

## Suggested next steps (not started, for whoever picks this up)

1. Provision `ANTHROPIC_API_KEY` + deploy `checkUniformCompliance`, then run
   Phase 1 once on a real device with a real photo — closes the last
   verification gap on a fully-built feature.
2. Collect even a handful of real soldier photos (with consent/authorization)
   to sanity-check PnP reprojection error and segmentation mask quality
   outside the synthetic domain — this is the prerequisite for trusting any
   number in §2.4 or §2.7 beyond "the code runs correctly."
3. If Phase 2's geometry-guided approach proves out, plan the cutover of
   `checkUniformCompliance.ts` to call `cv-service` instead of (or alongside)
   the whole-photo Claude call — its own `ChangeRequest/` plan per policy 1.1,
   since it changes production behavior.

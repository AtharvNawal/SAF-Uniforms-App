# Wire the geometric verdict engine into `/inspect` + the Flutter dev scorecard

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** executed — see §7, "verified" is explicitly blocked, not met

## 1. Goal

Surface this session's new geometric pass/fail/missing/unverifiable
verdict engine (`rules/rule_engine.py`'s `evaluate_verdicts`) through the
app's photo-capture flow, per-accessory, with doctrine references —
instead of only being reachable via a standalone Python script.

## 2. Architecture decisions (required by the task, stated explicitly)

**Decision 1 — runtime shape: keep the existing direct FastAPI path,
do NOT add a Cloud Function proxy.** `cv-service` has never been
deployed anywhere — no Cloud Run instance exists (`cv-service/Dockerfile`
is unverified, per the README's "Not built yet" list). There is nothing
for a Cloud Function to call yet. Building that (Cloud Run deploy +
Cloud Function proxy + auth + secrets + cost controls) is a real,
separate infrastructure project, not a byproduct of wiring a UI. The
Flutter app already has a working direct-HTTP dev path
(`CvServiceInspectionRepository` → `cv-service`'s `POST /inspect`,
`kCvServiceBaseUrl`) built in an earlier milestone
(`ChangeRequest/2026-08-05_cv-service-remaining-milestones.md`) — this
plan extends that path's response shape, it does not build a new
transport.

**Decision 2 — run alongside Phase 1, do not replace it.** Phase 1
(`checkUniformCompliance.ts`, the shipped Cloud Function) is untouched —
no edit to that file, no change to its default capture flow. The new
geometric verdicts appear only inside the existing "PHASE 2 · DEV"
long-press path, same posture the whole `cv-service` integration has had
since it was first wired in. Justification: this session's own
measurements are the reason — the geometric verdict engine has 5 of 18
doctrine rules structurally unverifiable, orientation estimation with a
disclosed ambiguity, PnP depth error up to ~1m, and its only
real-world-adjacent evidence is `footwear` precision/recall on **2**
synthetic stand-in photos. Replacing a shipped path with that would be
irresponsible regardless of how clean the code is.

**Decision 3 — `/inspect` gets an additive field, not a replacement of
its existing report shape.** The existing vision-crop-based
`issues`/`uncertain`/`subscores` stay exactly as they are (untouched
code path, untouched tests). A new `geometric_verdicts` field is
computed via a **second, independent** run of the geometry stack — this
time using this session's actual new modules
(`pose/anchor_mapping.estimate_anchor_pose` →
`geometry/solve_camera_pose.solve_camera_pose` → `rule_engine.resolve_rules`
→ `rule_engine.evaluate_verdicts`, fed the same already-computed
segmentation result) — rather than reusing the endpoint's existing
old-style `pose/estimate_pose` + `calibration/pnp_solve` computation
(which only has the narrower 7-anchor correspondence set). This costs a
second pose+camera solve per request; accepted deliberately to avoid any
risk to the already-tested vision-crop path, matching this session's
consistent additive-only posture.

## 3. Scope

- In scope:
  - `cv-service/api/main.py`: add the second geometry computation
    described in Decision 3, add `report["geometric_verdicts"]` — a list
    of `{accessory, status, reason, doctrine_ref}`, empty list (not
    omitted) if the second camera solve fails, so the field is always
    present and typed the same way on every response.
  - `lib/features/ar_scanner/domain/entities/cv_inspection_result.dart`:
    new `GeometricVerdictStatus` enum (`pass`/`fail`/`missing`/
    `unverifiable`) — **deliberately separate** from the existing
    `CvVerdict` (5-state, vision-crop-specific) rather than shoehorned
    into it, same "documented, not unified, multiple vocabularies"
    pattern this session has used every time a new judgment mechanism
    was added; new `GeometricVerdict` freezed class (`accessory`,
    `status`, `reason`, `doctrineRef`); new `geometricVerdicts` field on
    `CvInspectionResult`.
  - `lib/features/ar_scanner/data/cv_service_inspection_repository.dart`:
    parse the new field.
  - `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart`:
    new section in `_CvScorecard` — one row per accessory, status-colored
    (pass reuses the existing `_PassCard`; fail/missing reuse `_IssueCard`
    with red; unverifiable reuses `_IssueCard` with the existing
    "uncertain" grey/help-icon styling), doctrine reference shown, not
    just a blanket verdict.
  - `dart run build_runner build --delete-conflicting-outputs` (new
    freezed fields).
  - `flutter analyze` + `flutter test` — **no longer optional**, per the
    task: this is the first milestone this session where Dart code
    changes.
  - New tests: `test/features/ar_scanner/cv_geometric_verdict_test.dart`
    (enum wire-name parsing, mirrors the existing
    `compliance_result_test.dart` pattern); `cv-service/tests/test_api.py`
    extended to assert `geometric_verdicts` is present and well-shaped on
    the existing fixture-photo round-trip.
- Out of scope:
  - Cloud Run deployment, Cloud Function proxying, auth (Decision 1).
  - Touching `checkUniformCompliance.ts` or the default capture flow
    (Decision 2).
  - Unifying the vision-crop and geometric verdict paths onto one camera
    solve (Decision 3's accepted redundancy).

## 4. The verification gate this plan cannot meet — stated upfront, not discovered at the end

The task requires, **before calling this milestone verified**: "one real
photo... producing a verdict a human reviewer agrees with... for at
least 5 real photos spanning different compliance states." **Zero real
photos exist in this project** — the same fact, unchanged, confirmed
independently before every one of this session's five prior plans.
There is no synthetic substitute that satisfies this requirement
honestly: a human reviewing a rendered placeholder body agreeing that
"yes, the beret is missing, because there is no beret mesh" is not the
same claim as a human reviewing a real photo and confirming the pipeline
got a real, ambiguous, real-world case right.

**This plan is therefore marked `executed`, not `verified`, and stays
that way until real photos exist.** Everything else in scope (Decisions
1–3, the UI, `flutter analyze`/`flutter test`) is completed and verified
in the ordinary sense (§7) — only the 5-real-photo human-reviewed gate is
outstanding, and it is a data problem, not a code problem.

## 5. Risks & rollback

- **Running the geometry stack twice per `/inspect` call** (Decision 3)
  roughly doubles that endpoint's latency/compute — acceptable for a
  dev-only, un-deployed endpoint; would need revisiting before any real
  deployment (natural point to unify onto one camera solve once the new
  path has more validation).
- **The new UI section can look more authoritative than it is** if a
  reviewer doesn't read the `unverifiable` reasons — same risk flagged
  in the verdict-engine plan, now visible in the app itself. Mitigated
  by keeping the "PHASE 2 · DEV" labelling and by rendering `reason` text
  for every row, not just a colored status pill.
- Low blast radius on the Flutter side: new enum + new freezed fields +
  new UI section are additive; no existing widget, provider, or model is
  modified beyond adding one field to `CvInspectionResult` (which is
  itself already dev-only/ephemeral, never persisted, never read by any
  other screen). Rollback: revert the 4 touched files + delete the new
  test file + re-run `build_runner`.

## 6. CLAUDE.md updates required

- §5.10 / the `ar_scanner` feature description in §2's Dart source tree:
  note the new `geometric_verdicts` field on `/inspect`'s response and
  the corresponding Dart models, with the same explicit "0 real photos,
  not verified end-to-end" caveat.

## 7. Verification

- `.venv-tools/bin/pytest cv-service/tests/ -v` — **97/97 passed**,
  including `test_api.py`'s extended assertions confirming
  `geometric_verdicts` is present on a real `/inspect` HTTP round-trip
  (via `TestClient`, not just unit-level): against the fixture render,
  `army_beret` → `missing`, `leather_shoes_low_cut` → `pass`,
  `name_tag_standard` → `unverifiable`, doctrine references present on
  every entry — confirms the full B→C→segmentation→verdict chain
  actually runs inside the FastAPI request/response cycle, not just in
  a standalone script.
- `dart run build_runner build --delete-conflicting-outputs` — ran
  clean, 1 freezed output regenerated
  (`cv_inspection_result.freezed.dart`).
- `flutter analyze` — **clean, "No issues found!"**.
- `flutter test` — **full suite, 82/82 passed**, including the 5 new
  `cv_geometric_verdict_test.dart` tests (enum wire-name mapping +
  round-trip, unknown-value fallback to `unverifiable` not a throw,
  `geometricVerdicts` defaulting to `[]` not `null`).
- **5-real-photo human-reviewed end-to-end test: NOT DONE — blocked on
  §4.** This line is the honest status, not a placeholder to fill in
  later without comment. Everything gated on code (architecture, the
  additive `/inspect` field, the Dart models, the UI, both test suites)
  is done and green; the one thing gated on data is not, because the
  data doesn't exist.

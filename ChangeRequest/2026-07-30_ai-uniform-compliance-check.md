# AI Uniform Compliance Check (Photo vs Expected Accessories)

- **Date:** 2026-07-30
- **Author:** Claude (with Datta)
- **Status:** in-progress (code executed 2026-07-31; live device + deploy verification still pending)

## 1. Goal

Let the user capture a photo of themselves wearing the uniform and get a plain-language
verdict on what's correct and what's wrong, by sending the photo — plus the exact list of
accessories the system already expects for that user's branch/rank/gender/dress code (the
same list `composeUniformModel` uses to build the 3D GLB) — to a multimodal Claude model for
visual inspection. Surface the result through the existing `ARScannerScreen` scorecard, which
today shows hardcoded demo numbers (score `86`, two static "issue" strings, four static
"pass" strings) that need to become real.

Decisions already made with the user (see prior turn):
- Comparison method: **cloud vision-LLM analysis** (not on-device pose heuristics, not
  render-and-diff against the GLB — both rejected as lower-accuracy / higher-risk).
- Model: **Claude** (Anthropic API), per this project's "default to latest Claude models for
  AI features" guidance.
- Location: **extend `ARScannerScreen`** (its Phase-2 scorecard was already built for this).
- Persistence: **ephemeral only** — no Firestore write of check history.

## 2. Scope

**In scope:**
- New Cloud Function callable `checkUniformCompliance` (`functions/src/checkUniformCompliance.ts`).
- Anthropic SDK (`@anthropic-ai/sdk`) integration using a Secret-Manager-backed API key.
- Reuse of the existing `resolveAccessorySplit` (TypeScript resolver already used by
  `composeUniformModel`) to build the expected-accessory list server-side — no duplicate
  resolution logic.
- Client: capture a photo via the existing `image_picker` pattern (already used by the
  Gallery feature — no new camera-preview plumbing), call the new callable, and render the
  real result in `ARScannerScreen`'s scorecard.
- New Dart domain entities / repository / Riverpod controller for the compliance result.
- A handful of new l10n strings (loading / error / "uncertain" states).

**Out of scope (explicitly rejected or deferred):**
- Render-and-diff of the composed GLB against the photo (rejected — camera-angle/pose
  alignment between a real photo and a 3D render is a hard, high-risk problem on its own).
- On-device ML/pose heuristics (rejected — crude, high false-positive rate).
- Persisting check history to Firestore (user chose ephemeral).
- Continuous/live camera-feed analysis — this is a single-shot "capture then analyze" flow.
- Any change to `composeUniformModel`, the GLB pipeline, or `MODEL_BUNDLE_VERSION`.

## 3. Affected areas

- `functions/src/checkUniformCompliance.ts` (new)
- `functions/src/index.ts` (export the new callable)
- `functions/package.json` (+ `@anthropic-ai/sdk` dependency)
- Firebase Secret Manager: new secret `ANTHROPIC_API_KEY` (operator action, see §4 step 8)
- `lib/features/ar_scanner/domain/entities/compliance_result.dart` (new, `@freezed`)
- `lib/features/ar_scanner/data/uniform_compliance_repository.dart` (new)
- `lib/features/ar_scanner/presentation/providers/uniform_compliance_provider.dart` (new)
- `lib/features/ar_scanner/presentation/providers/uniform_compliance_provider.g.dart` (codegen)
- `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart` (rewire capture flow)
- `lib/core/l10n/arb/{app_en.arb,app_zh.arb}` (+ a few new keys)
- `CLAUDE.md` §4 (source tree), §5.2 (provider graph), §5.5 (Cloud Functions list), §8
  (remove the "ARScannerScreen is a placeholder" note)

## 4. Step-by-step plan

1. **`functions/package.json`**: add `"@anthropic-ai/sdk": "^0.32.0"` to `dependencies`;
   `npm install`.
2. **`functions/src/checkUniformCompliance.ts`** (new):
   - `onCall({ region: "asia-southeast1", secrets: [ANTHROPIC_API_KEY], timeoutSeconds: 60 })`.
   - Auth required (`req.auth`), same pattern as `composeUniformModel`.
   - Zod-validate input: `{ dressCode: enum(No1..No5), photoBase64: string, mimeType: enum("image/jpeg","image/png") }`.
   - Load `users/{uid}/profile/current` (reuse the same field-reading approach as
     `composeUniformModel.ts`'s `readProfile`), `dress_requirements/{dressDoc}`, and
     `accessory_library` — call the existing `resolveAccessorySplit(...)` to get
     `{ mandatory, optional }` `ResolvedAccessory[]`, then filter optional down to the ones
     the user has ticked in `dressAccessoryChecks[dressDoc]` (identical logic to
     `composeUniformModel`'s `includeAccessories`).
   - For each expected accessory, best-effort fetch its `record.image_url` from Storage as a
     reference image (skip gracefully — try/catch per policy 1.4 — if fetch fails or the URL
     is empty; the LLM still gets the accessory's `display_name` + `category` as text).
   - Build an Anthropic `messages.create` call using **tool-forced structured output**
     (`tool_choice: { type: "tool", name: "report_compliance" }`) rather than parsing JSON out
     of prose — this is the robust option and matches this project's "defensive parsing at
     boundaries" convention. Tool input schema:
     ```ts
     {
       overallScore: number,       // 0-100
       summary: string,            // one/two sentence plain-English verdict
       items: [{
         accessoryId: string,
         displayName: string,
         status: "correct" | "missing" | "incorrect" | "uncertain",
         note: string,            // why — e.g. "beret visible but tilted; cap badge not visible"
       }],
     }
     ```
   - Model: `claude-sonnet-5`. Validate the tool-call `input` through a zod schema before
     returning it to the client — never trust the model's output shape blindly.
   - Wrap the whole handler body in try/catch; log `info` (start/ok with uid + dressCode +
     item count), `debug` (resolved accessory ids), `error` (with stack trace) per policy 1.3;
     rethrow as `HttpsError("internal", ...)` on failure so the client can show a retry state.
   - Nothing is written to Firestore or Storage — fully ephemeral per the user's decision.
3. **`functions/src/index.ts`**: `export { checkUniformCompliance } from "./checkUniformCompliance";`.
4. **Dart domain entity** `ComplianceResult` / `ComplianceItem` (`@freezed`) mirroring the CF's
   JSON shape 1:1 (`overallScore`, `summary`, `items: List<ComplianceItem>` with
   `accessoryId`, `displayName`, `status` (enum mirroring the 4 wire values), `note`).
5. **`UniformComplianceRepository`**: wraps `FirebaseFunctions.instance.httpsCallable('checkUniformCompliance')`
   exactly like `ModelGenerationRepository` (same logging shape, same error rethrow
   convention); takes `dressCode` + raw JPEG bytes, base64-encodes client-side, returns
   `ComplianceResult`.
6. **`UniformComplianceController`** (`@riverpod` `AsyncNotifier`): exposes
   `check(DressCode dressCode, Uint8List photoBytes)` → `state = AsyncValue<ComplianceResult>`.
7. **`ARScannerScreen` rewire**:
   - Capture button calls `ImagePicker().pickImage(source: ImageSource.camera)` (same package
     + pattern the Gallery feature already uses — `permission_handler` already a dependency
     for the camera-permission prompt).
   - On a photo being returned, transition to a new `_ArPhase.analyzing` phase (spinner +
     "Analyzing your photo…") while `controller.check(...)` runs.
   - On success, render `_Scorecard` using the **real** `overallScore` / `items` instead of
     the hardcoded `86` / two fixed issue strings / four fixed pass strings — group `items`
     by status (`missing`/`incorrect` → red "Issues" list, `correct` → green "Checks" list,
     `uncertain` → a neutral third list).
   - On failure (`AsyncError`), show a retry state (`GhostButton` "Try again") instead of a
     crash — no raw exception text shown to the user.
8. **l10n**: add `arAnalyzing`, `arAnalyzingSub`, `arCheckFailed`, `arRetry`,
   `arUncertainChecks` keys to both ARBs; regenerate via `flutter gen-l10n`.
9. **Operator action (blocks live use, not local dev)**: `firebase functions:secrets:set ANTHROPIC_API_KEY`,
   then `firebase deploy --only functions`.
10. Update `CLAUDE.md` per §7 below.

## 5. Risks & rollback

- **Risk:** Anthropic API cost per check. **Mitigation:** manual single-shot capture only, no
  continuous scanning; `max_tokens` kept small (structured JSON output only).
- **Risk:** vision accuracy is imperfect on off-angle/poorly-lit photos.
  **Mitigation:** the `"uncertain"` status exists specifically so the model can hedge instead
  of guessing; UI copy should say "AI estimate" not "verified".
- **Risk:** API key leakage. **Mitigation:** key lives only in Secret Manager via
  `defineSecret`, injected server-side; never logged, never sent to the client.
- **Risk:** reference-image fetch (per-accessory `image_url`) slows the call down or fails.
  **Mitigation:** best-effort with try/catch per accessory; missing images degrade to
  text-only description for that item rather than failing the whole check.
- **Rollback:** remove the `checkUniformCompliance` export and revert
  `ar_scanner_screen.dart` to the previous hardcoded-demo version; no data migrations
  involved since nothing is persisted.

## 6. Verification

1. `cd functions && npm run build && npm test` — ✅ 2026-07-31: `tsc` builds clean; added
   `checkUniformCompliance.test.ts` (6 tests: `ComplianceResponse` zod schema accepts a
   well-formed payload and rejects out-of-range score / unknown status / missing field;
   `buildPromptText` includes every expected accessory id/name and behaves on an empty list).
   No real Anthropic network call is made — the test exercises only the pure schema +
   prompt-builder surfaces. Full suite: 28/28 pass (22 pre-existing + 6 new).
2. `flutter analyze` — ✅ 2026-07-31: clean ("No issues found!").
3. `dart run build_runner build --delete-conflicting-outputs` — ✅ 2026-07-31: ran clean,
   generated `compliance_result.freezed.dart` and `uniform_compliance_provider.g.dart`.
4. `flutter gen-l10n` — ✅ 2026-07-31: ran clean (config picked up from `l10n.yaml`).
5. `flutter test` — ✅ 2026-07-31: added `test/features/ar_scanner/compliance_result_test.dart`
   covering `ComplianceStatus.fromWireName` (including the unknown-value → `uncertain`
   fallback) and `ComplianceResult`'s `correctItems`/`issues`/`uncertainItems` derived
   getters. A fake-`FirebaseFunctions` test for `UniformComplianceRepository` /
   `UniformComplianceController` was scoped out — this repo has no existing precedent for
   faking the Firebase Functions platform channel (the sibling `ModelGenerationRepository` /
   `ModelGenerationController` for `composeUniformModel` also have zero tests), so coverage
   here matches the established bar for this layer: pure domain logic is tested, the thin
   Firebase-calling wrapper is exercised only via manual/device testing (step 7). Full suite:
   77/77 pass (73 pre-existing + 4 new).
6. Operator: set the `ANTHROPIC_API_KEY` secret, `firebase deploy --only functions` — not
   run in this session (needs deploy credentials + a real Anthropic API key, neither
   available here).
7. `flutter run` on a device: Dashboard → AR scan → capture a real photo → confirm the
   scorecard shows a real score + real issues/checks pulled from the live response; test the
   failure path (airplane mode) shows the retry state, not a crash. — not run in this session
   (no attached device/simulator; same caveat as the unified-dressed-figure plan).
8. `Status:` stays `in-progress` — code + local verification (1–5) is done; steps 6–7 need an
   operator with Anthropic + Firebase deploy credentials and a device/simulator before this
   can be marked `verified`.

## 7. CLAUDE.md updates required

- §4 source tree: flesh out the `ar_scanner/` entry (currently only has a screen file) with
  the new `domain/`, `data/`, `presentation/providers/` files.
- §5.2 provider graph: document `uniformComplianceControllerProvider`.
- §5.5 Cloud Functions list: document `checkUniformCompliance` alongside
  `claimDeviceIdentity` / `markProfileComplete` / `composeUniformModel`, including the new
  `ANTHROPIC_API_KEY` secret dependency.
- §8 known gaps: remove the "`ARScannerScreen` is a placeholder UI — no real camera feed or
  pose detection yet" line; replace with a note that it now does a real single-shot
  AI-vision compliance check (and that pose-detection/live-AR remain out of scope).

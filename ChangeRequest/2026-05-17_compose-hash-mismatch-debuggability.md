# composeUniformModel — Surface Early-Throw 4xx Rejections (Pass 5)

- **Date:** 2026-05-17
- **Author:** Claude (with Datta)
- **Status:** executed (awaiting user device retry for `verified`)
- **Follows:** [2026-05-17_army-no3-lanyard-drop.md](2026-05-17_army-no3-lanyard-drop.md) (pass 4)

## Execution log (2026-05-17, late evening)

- **Diagnosis.** After pass 4's deploy at 13:22:07Z, the user's Android device hit `composeUniformModel` at 13:34:59Z (uid `WEQNNJ9PUPejc3fBZd9dzAX5qr63`, `ua: okhttp/4.12.0`). The log shows the `composeUniformModel: incoming` entry fire and then **nothing** — no "resolved", no "done", no error stack — despite the user reporting a client-side error. Reading [composeUniformModel.ts:249-329](../functions/src/composeUniformModel.ts#L249-L329) revealed the cause: the function throws `HttpsError("failed-precondition", "Stale request…")` at line 291 when the client's profile hash doesn't match the server's recomputed hash. **Firebase Functions v2 does not log `HttpsError` throws** — only uncaught `internal`/5xx errors trigger `logger.error`. So a 4xx rejection looks identical to a silent crash in `firebase functions:log`.

- **Root cause of the mismatch.** Pass 4 bumped both `MODEL_BUNDLE_VERSION = 6 → 7` (TS) and `kModelBundleVersion = 6 → 7` (Dart). The TS bump took effect on `firebase deploy`. The Dart bump did **not** take effect until the Flutter app is rebuilt + reinstalled — the constant is compile-time. The user's running app (last rebuilt at pass-3 time when v6 was current) sends `clientHash` computed with `bundleVersion: 6` in the payload. The server expects v7. SHA-256 of different payloads diverges → mismatch → silent 4xx.

- **Phase 1 — Added `logger.warn` before three early throws** in [functions/src/composeUniformModel.ts](../functions/src/composeUniformModel.ts):
  1. Before `throw new HttpsError("unauthenticated", "Sign-in required.")` (no auth) — logs `"composeUniformModel: rejected (no auth)"` with the user-agent.
  2. Before `throw new HttpsError("invalid-argument", parsed.error.message)` (bad schema) — logs `"composeUniformModel: rejected (bad request)"` with uid + issue.
  3. Before `throw new HttpsError("failed-precondition", "Stale request…")` (hash mismatch) — logs `"composeUniformModel: rejected (hash mismatch — client likely stale; rebuild Flutter app to pick up new kModelBundleVersion)"` with uid, dressCode, clientHash, expectedHash, serverBundle. This is the diagnostic that would have surfaced the pass-4 issue from logs alone.
  All three throws are unchanged — only the breadcrumb logs are new. Pure additive change.

- **Phase 2 — Build + redeploy:**
  - `cd functions && npm test` → 18/18 pass.
  - `npm run build` → clean.
  - `firebase deploy --only functions:composeUniformModel` → `composeUniformModel(asia-southeast1)` updated (revision 17 now serving).

- **Phase 3 — User unblocker.** The user needs to run **`flutter run`** on the Samsung device to rebuild the Dart binary with `kModelBundleVersion = 7`. After that, the client sends a v7 hash, the server expects v7, hashes match, compose proceeds, and the pass-4 lanyard fix takes effect.

## 1. Goal

(a) Surface every 4xx rejection of `composeUniformModel` in CF logs so future hash mismatches / auth failures / bad-request issues are self-diagnosing. (b) Unblock the user's Dress-3 compose by communicating the rebuild requirement.

## 2. Scope

In scope: three `logger.warn` additions in `composeUniformModel.ts` and a redeploy; documentation update for the bundle-bump-requires-rebuild gotcha.

Out of scope: refactoring the hash to exclude bundleVersion (would require redesigning the cache-key model); reverting the bundle bump (the v7 jump is correct server-side); accessory placement (the pass-4 lanyard fix is correct, just blocked behind the hash check).

## 3. Affected files

- [functions/src/composeUniformModel.ts](../functions/src/composeUniformModel.ts) — added three `logger.warn` calls before existing `HttpsError` throws (no behavioural change).
- [CLAUDE.md §5.5](../CLAUDE.md) — added a note that bumping `MODEL_BUNDLE_VERSION` (TS) requires a matching bump in `kModelBundleVersion` (Dart) AND a rebuild+reinstall of the Flutter app; otherwise every existing install gets a hash mismatch and the model never composes.

## 4. Risks & rollback

- **Pure additive logging change.** Worst case is verbose CF logs.
- **The unblocker (Phase 3) requires the user to act** — we can't rebuild their app from here.
- **Rollback:** `git restore functions/src/composeUniformModel.ts`, redeploy. The throws still work; just the breadcrumb logs disappear.

## 5. Verification

1. `cd functions && npm test` ✅ 18/18 pass.
2. `firebase deploy --only functions:composeUniformModel` ✅ revision 17 ACTIVE.
3. On the next user invocation:
   - If they rebuilt: full pipeline runs (incoming → resolved → planned assets → … → done) and the user sees the lanyard fix.
   - If they didn't: the new `composeUniformModel: rejected (hash mismatch …)` log line fires with both hashes — pointing exactly at the rebuild requirement.
4. Mark `Status: verified` once the user confirms either outcome from CF logs.

## 6. CLAUDE.md updates

§5.5 — bullet "composeUniformModel" — append: "**Operator note.** Bumping `MODEL_BUNDLE_VERSION` (TS) requires a matching bump in `kModelBundleVersion` (Dart) AND a `flutter run` (rebuild + reinstall) on every active device — the Dart constant is compile-time, so editing the source file does NOT update an already-installed app. Without the rebuild, every existing install sends a hash computed with the OLD bundle version, the server's hash uses the NEW value, hashes diverge, and the function throws `HttpsError(failed-precondition, "Stale request…")` to the client. As of pass 5, this throw is preceded by a `logger.warn("composeUniformModel: rejected (hash mismatch — client likely stale; rebuild Flutter app …)", { clientHash, expectedHash, serverBundle })` so future occurrences surface directly in `firebase functions:log` instead of looking like silent crashes."

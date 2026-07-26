# Admin Portal Phase 4 — Models Page: 3D Asset Upload, Download & Preview

- **Date:** 2026-05-18
- **Author:** Claude / Datta
- **Status:** executed

## 1. Goal

Make the Models page the operator's primary interface for managing all 3D GLB
assets — body GLBs, uniform GLBs, and accessory GLBs — replacing every
non-functional upload/download button and hardcoded socket-status row with real
Firebase Storage interactions and an in-browser 3D preview.

## 2. Scope

- **In scope:**
  1. **Body GLB upload** — file picker → `models/bodies/{id}.glb` in Storage → `bodyModels()` signal refreshes.
  2. **Uniform GLB upload** — branch + dress code + gender selector → `models/uniforms/{branch}_{code}_{gender}.glb`.
  3. **Accessory GLB upload (Models page)** — upload to `models/accessories/{id}.glb` (companion to Phase 2's Accessories page upload).
  4. **GLB download** — get Storage download URL → trigger browser file download for all three tabs.
  5. **3D model preview** — embed the `<model-viewer>` web component to render any GLB inline with rotate/zoom.
  6. **Socket status** — real check: for body GLBs, verify that the expected named socket nodes exist in the file (via a lightweight GLB binary header parse or a Cloud Function).
  7. **Placeholder generation** — "Generate placeholder" button that calls a new `generatePlaceholderBody` Firebase Cloud Function.

- **Out of scope:** Batch upload, automatic format conversion, artist workflow tooling, Storage cost reporting.

## 3. Affected areas

| File | Change |
|------|--------|
| `admin-portal/src/app/pages/models/models.component.ts` | Add upload/download/preview methods + socket-check signal |
| `admin-portal/src/app/core/data/storage-data.service.ts` | Add `uploadBodyGlb()`, `uploadUniformGlb()`, `uploadAccessoryGlb()` (if not added in Phase 2), `getGlbUrl()`, `deleteGlb()` |
| `admin-portal/src/app/core/data/firestore-data.service.ts` | Add `logModelUpload()` activity log helper |
| `admin-portal/src/app/core/data/models.ts` | Extend `BodyModel` with `socketStatus?: SocketCheckResult` |
| `functions/src/index.ts` | Add `generatePlaceholderBody` HTTPS callable (optional, Phase 4.7) |
| `admin-portal/public/i18n/en.json` | Add translation keys for upload labels, socket check results, preview |
| `admin-portal/src/index.html` | Add `<script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js">` |

## 4. Step-by-step plan

### Step 1 — Extend `StorageDataService` with write methods

Add to `storage-data.service.ts`:
```typescript
uploadBodyGlb(id: string, file: File): Observable<number>
  // Uploads to models/bodies/{id}.glb, emits upload progress (0–100)

uploadUniformGlb(branch: string, code: string, gender: string, file: File): Observable<number>
  // Uploads to models/uniforms/{branch}_{code}_{gender}.glb

uploadAccessoryGlb(id: string, file: File): Observable<number>
  // Uploads to models/accessories/{id}.glb (may already exist from Phase 2)

getGlbUrl(path: string): Promise<string>
  // Returns download URL for any models/** path

deleteGlb(path: string): Promise<void>
  // Deletes a GLB file (for replacing bad uploads)
```

All uploads: use `uploadBytesResumable` from AngularFire Storage for real progress events.

### Step 2 — Body GLB upload (Bodies tab)

1. Each `BodyModel` row in the Bodies tab gets an "Upload GLB" button.
2. Hidden `<input type="file" accept=".glb">` triggered on click.
3. On file select: show upload progress bar inline in the row → `storage.uploadBodyGlb(id, file)` → on complete: `svc.addActivityLog('Uploaded body GLB', id)` → toast success → `bodyModels()` signal refreshes via the existing `listAll` stream.
4. Show a "Replace" button (with warning) when a GLB already exists — same upload flow, overwrites the existing file.

### Step 3 — Uniform GLB upload (Uniforms tab)

1. The Uniforms tab shows a 4×5 matrix (branch × dress code) per gender. Each cell is either "uploaded" ✓ or "missing" —.
2. Clicking a "missing" cell opens a small upload popover: confirm the slot (`Army No.3 Male`) → file picker → progress → upload to `models/uniforms/army_no3_male.glb`.
3. Clicking an "uploaded" cell shows a "Replace / Download / Delete" mini-menu.
4. On upload complete: `uniformMatrix()` signal refreshes (it's a `listAll` that returns a Set of filenames).

### Step 4 — Accessory GLB upload (Accessories tab in Models page)

1. The Accessories tab in the Models page lists all accessory IDs from `accessory_library` alongside a GLB status badge.
2. Add "Upload GLB" + "Download GLB" buttons per row (same implementation as Phase 2's Accessories page tab, reusing the same `StorageDataService` methods).
3. This gives operators a single-pane view of all accessory GLB coverage.

### Step 5 — GLB download (all tabs)

1. For any GLB that exists (status = uploaded / delivered):
   ```typescript
   async downloadGlb(path: string, filename: string): Promise<void> {
     const url = await this.storage.getGlbUrl(path);
     const a = document.createElement('a');
     a.href = url;
     a.download = filename;
     a.click();
   }
   ```
2. Wire to a "Download" button per row / cell.

### Step 6 — 3D model preview

1. Add the `<model-viewer>` web component script to `index.html`:
   ```html
   <script type="module"
     src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js">
   </script>
   ```
   Declare `CUSTOM_ELEMENTS_SCHEMA` in the Models component (or in a wrapper component).
2. Add a "Preview" button per body/uniform row.
3. On click: `storage.getGlbUrl(path)` → open a `<app-modal>` containing:
   ```html
   <model-viewer
     [src]="previewUrl()"
     camera-controls
     auto-rotate
     style="width: 100%; height: 500px; background: var(--charcoal-2);">
   </model-viewer>
   ```
4. The modal shows a spinner while the URL is loading; error state if the URL fetch fails.
5. This works for body GLBs and uniform GLBs. Accessory GLBs can use the same preview (they may render as a small object in the scene — acceptable).

### Step 7 — Socket status check (Bodies tab)

**Option A — Client-side GLB header parse (lightweight):**
1. After a body GLB is uploaded (or on first load), fetch the file and parse just the JSON chunk of the GLB binary (`Uint8Array` → find the JSON chunk offset at byte 20 → `TextDecoder` → `JSON.parse`).
2. Look for nodes with names matching the 15 expected sockets (`head_top`, `cap_band_front`, `left_collar_tip`, etc.).
3. Store the result as `socketStatus: { found: string[], missing: string[] }` in a `signal<Map<string, SocketCheckResult>>(new Map())`.
4. Display in the Bodies tab: green tick per found socket, red warning per missing socket.

**Option B — Cloud Function (more reliable, handles compressed/binary buffers):**
1. Add a `checkBodySockets(storagePath: string)` Firebase HTTPS callable that downloads the GLB, loads it with `@gltf-transform/core`, and returns `{ found: string[], missing: string[] }`.
2. Call on demand when the operator clicks a "Check Sockets" button.

Implement Option A first (no Cloud Function cost); fall back to Option B if the client-side parse proves unreliable.

### Step 8 — Placeholder generation (optional, nice-to-have)

1. Add a Cloud Function `generatePlaceholderBody(gender: 'male' | 'female' | 'female_maternity')` that runs the Python logic from `tool/generate_placeholder_bodies.py` ported to Node.js (or invokes a Cloud Run job).
2. In the Models page Bodies tab: "Generate Placeholder" button per body slot → calls the function → on complete, re-uploads the GLB to Storage → toast success.
3. This is a nice-to-have; operators can always run the Python script manually.

## 5. Risks & rollback

- **Uploading a bad GLB** to `models/bodies/male_apose.glb` will break all future `composeUniformModel` calls for male users until replaced. Mitigation: always offer a "Replace" flow that lets the operator immediately upload a corrected file. The existing file is overwritten (not versioned) in Storage — keep a local backup before uploading.
- **`<model-viewer>` web component** adds ~800 KB to the page load. It is only loaded on the Models page and is loaded from the Google CDN. Impact is acceptable for an admin portal.
- **Socket check client-side parse** may fail on GLBs with compressed binary buffers (Draco). If the parse fails, fall back to showing "Unable to check — use Firebase Console" rather than crashing.
- **Uniform matrix slot overwrites** take effect immediately for the mobile app's `composeUniformModel`. Bump `MODEL_BUNDLE_VERSION` in `functions/src/profile_hash.ts` AND `lib/features/ar_engine/data/profile_hash.dart` after uploading new uniform GLBs to force all existing cached compositions to be regenerated.

## 6. Verification

1. `npx ng build --configuration development` — zero errors. Check for `CUSTOM_ELEMENTS_SCHEMA` warning suppression.
2. Smoke test:
   - Bodies tab: upload a `.glb` → progress bar → "Delivered" badge appears.
   - Bodies tab: Download button → browser downloads the file.
   - Bodies tab: Preview button → `<model-viewer>` renders the 3D model in the modal.
   - Bodies tab: Check Sockets → shows green ticks for expected sockets.
   - Uniforms tab: click a "Missing" cell → upload popover → upload → cell turns to "Uploaded".
   - Accessories tab: upload a GLB → GLB badge turns green (same as Phase 2 Accessories page).
3. Storage Console: verify files exist at the correct paths after upload.
4. Firebase Functions log: no errors from `composeUniformModel` after new GLBs are uploaded.

## 8. Verification log

- `npx ng build --configuration development` — clean (0 errors, 0 warnings). Run: 2026-05-18.
- Steps 1–6 from §6 require an authenticated Firebase session and live Storage bucket; smoke-test manually after deploy.

## 7. CLAUDE.md updates required

- Update `admin-portal` section: note Phase 4 features (GLB upload/download, 3D preview, socket check) are live.
- Update the `models/**` Storage section: note Models page is now the write surface.
- Add note about `CUSTOM_ELEMENTS_SCHEMA` in the Models component (allows `<model-viewer>`).
- Remind operators: bump `MODEL_BUNDLE_VERSION` after uploading new uniform or body GLBs.

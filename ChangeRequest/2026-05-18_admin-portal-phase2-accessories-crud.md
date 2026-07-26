# Admin Portal Phase 2 — Accessories Full CRUD + Image/GLB Management

- **Date:** 2026-05-18
- **Author:** Claude / Datta
- **Status:** executed

## 1. Goal

Complete the Accessories page so admins can create, edit, and delete accessory
records; view and upload accessory images and placement diagrams; and upload /
download the matching GLB 3D asset. This makes the Accessories page the primary
content-management surface for the `accessory_library` Firestore collection and
the `accessories/` Firebase Storage prefix.

## 2. Scope

- **In scope:**
  1. **Create accessory** — Add Accessory modal form → `addDoc` on `accessory_library`.
  2. **Edit accessory** — detail drawer fields become editable → Save → `updateDoc`.
  3. **Delete accessory** — two-step confirm → `deleteDoc` + Storage cleanup (best-effort).
  4. **Display accessory image** — show real image from `image_url` field in drawer.
  5. **Display placement diagram** — show real image from `placement_diagram` field in drawer.
  6. **Upload image / placement diagram** — file picker → Storage upload → patch Firestore URL field.
  7. **Upload GLB** — file picker → Storage `models/accessories/{id}.glb` → `glb` badge goes live.
  8. **Download GLB** — get Storage download URL → trigger browser file download.

- **Out of scope:** Bulk import, AI-assisted field fill, accessory categories management, accessories on the Models page (Phase 4).

## 3. Affected areas

| File | Change |
|------|--------|
| `admin-portal/src/app/pages/accessories/accessories.component.ts` | Add all CRUD + upload/download methods and signals |
| `admin-portal/src/app/core/data/firestore-data.service.ts` | Add `createAccessory()`, `updateAccessory()`, `deleteAccessory()` |
| `admin-portal/src/app/core/data/storage-data.service.ts` | Add `uploadAccessoryImage()`, `uploadAccessoryGlb()`, `getAccessoryGlbUrl()` |
| `admin-portal/src/app/core/data/models.ts` | Confirm `Accessory` interface covers all editable fields |
| `admin-portal/public/i18n/en.json` | Add translation keys for new actions, labels, errors |

## 4. Step-by-step plan

### Step 1 — Extend `Accessory` model + service write methods

1. In `models.ts`, confirm `Accessory` has all editable fields: `name`, `cat`, `branch`, `gender`, `img` (boolean), `glb` (boolean), `place` (boolean), `legacy` (boolean). Add `imageUrl?: string` and `placementUrl?: string` so the drawer can bind to raw URLs without re-fetching the service.
2. In `firestore-data.service.ts` add:
   ```typescript
   createAccessory(id: string, data: AccessoryWritePayload): Promise<void>
   updateAccessory(id: string, data: Partial<AccessoryWritePayload>): Promise<void>
   deleteAccessory(id: string): Promise<void>
   ```
   Where `AccessoryWritePayload` maps the form fields back to Firestore field names (`display_name`, `category`, `branch_id`, `gender`, `active`, `render_logic.anchor`).
3. In `storage-data.service.ts` add:
   ```typescript
   uploadAccessoryImage(id: string, file: File, type: 'image' | 'placement'): Observable<string>
     // Uploads to accessories/{id}/{image|placement}.png, returns download URL
   uploadAccessoryGlb(id: string, file: File): Observable<number>
     // Uploads to models/accessories/{id}.glb, emits upload progress (0–100)
   getAccessoryGlbUrl(id: string): Promise<string>
     // Returns the download URL for models/accessories/{id}.glb
   ```

### Step 2 — Create accessory (Add modal)

1. In `accessories.component.ts`, bind each form field in the Add Accessory modal to a reactive form: `display_name` (required), `category` (select), `branch_id` (select), `gender` (select), `render_logic.anchor` (select), `active` (toggle).
2. On submit: validate → generate a kebab-case `id` from `display_name` (or use `addDoc` with auto-ID) → call `svc.createAccessory(id, payload)` → call `svc.addActivityLog('Created accessory', id)` → close modal → show success toast.
3. Wrap in try/catch with error toast.

### Step 3 — Edit accessory (drawer)

1. Add an `editing = signal(false)` to the component.
2. When the drawer opens for a selected accessory, populate editable form fields from the selected accessory object.
3. Show an "Edit" button in the drawer header that sets `editing.set(true)` and makes fields editable.
4. Show "Save" / "Cancel" buttons when `editing()` is true.
5. Save: `svc.updateAccessory(selected.id, changedFields)` → `svc.addActivityLog('Updated accessory', selected.id)` → `editing.set(false)` → success toast.

### Step 4 — Delete accessory

1. Add `pendingDelete = signal<string | null>(null)`.
2. Wire the Delete button in the drawer: first click → `pendingDelete.set(id)` + warning toast. Second click → `svc.deleteAccessory(id)` (+ best-effort Storage delete if GLB exists) → `svc.addActivityLog(...)` → close drawer → success toast.
3. Firestore `deleteDoc` is the primary action; Storage cleanup is fire-and-forget (log errors, don't block).

### Step 5 — Display images in drawer

1. In the drawer template, replace the placeholder grey box in the "Image" tab with:
   ```html
   @if (selected()?.imageUrl) {
     <img [src]="selected().imageUrl" class="accessory-img" alt="Accessory image" />
   } @else {
     <app-empty-state icon="image" label="No image uploaded" />
   }
   ```
2. Same pattern for the "Placement" tab using `placementUrl`.
3. Make `FirestoreDataService.accessories()` populate `imageUrl` and `placementUrl` from the raw Firestore `image_url` / `placement_diagram` fields (currently mapped only to booleans `img` / `place`).

### Step 6 — Upload image / placement diagram

1. Add a hidden `<input type="file" accept="image/png,image/jpeg">` for each image slot.
2. On file select: show upload progress bar → call `storage.uploadAccessoryImage(id, file, type)` → on complete: `svc.updateAccessory(id, { image_url: downloadUrl })` (or `placement_diagram`) → refresh `selected()` → success toast.
3. Show a spinner on the image area during upload.

### Step 7 — Upload GLB

1. Add a "Upload GLB" button in the drawer (shown in the "3D Model" tab).
2. Hidden `<input type="file" accept=".glb">`.
3. On file select: show progress → `storage.uploadAccessoryGlb(id, file)` → on complete: `svc.updateAccessory(id, { glb_uploaded: true })` → `svc.addActivityLog('Uploaded GLB', id)` → success toast. The `glbSet` in `StorageDataService.accessoryGlbSet()` is a `listAll` snapshot; it will reflect the new file on the next read.

### Step 8 — Download GLB

1. Add a "Download GLB" button (shown when `selected().glb === true`).
2. On click: `await storage.getAccessoryGlbUrl(id)` → create a temporary `<a href=url download=id+'.glb'>` → click it programmatically → revoke.

## 5. Risks & rollback

- **Delete** removes the Firestore doc and (best-effort) the Storage objects. If Storage delete fails, the orphaned files are harmless (Storage billing is minimal). Re-creating the doc via the Add modal restores the record.
- **Image upload overwrites** the existing file at the same Storage path — this is intentional (latest image wins, idempotent).
- **GLB upload** to `models/accessories/{id}.glb` immediately affects the mobile app's `composeUniformModel` Cloud Function on the next composition request. Uploading an incorrect GLB will produce a bad composed model. Rollback: re-upload the correct GLB or delete the bad one via Firebase Console Storage browser.
- **Auto-generated accessory ID** from `display_name` may collide with existing docs. Guard: check with `getDoc` before `setDoc`; show error toast if ID already exists.

## 6. Verification

1. `npx ng build --configuration development` — zero errors.
2. Smoke test:
   - Open Add Accessory modal → fill all fields → Submit → new doc appears in the table.
   - Open the new accessory drawer → click Edit → change the name → Save → table updates.
   - Delete the test accessory (two-step) → removed from table.
   - Open any existing accessory with a real `image_url` → Image tab shows the photo.
   - Upload a PNG to an accessory → image appears in drawer after upload.
   - Upload a `.glb` → GLB badge turns green.
   - Download GLB → browser downloads the file.
3. Firestore Console: confirm create/update/delete docs are correct.
4. Storage Console: confirm `accessories/{id}/image.png` and `models/accessories/{id}.glb` exist after upload.

## 7. CLAUDE.md updates required

- Update `admin-portal` section: note Accessories page is fully CRUD-capable with image/GLB management.
- Update `accessory_library` Firestore collection description: note admin portal is now the write surface (replaces seed script for future additions).

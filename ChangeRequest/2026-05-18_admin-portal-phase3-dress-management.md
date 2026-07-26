# Admin Portal Phase 3 — Dress Management Full Lifecycle

- **Date:** 2026-05-18
- **Author:** Claude / Datta
- **Status:** executed

## 1. Goal

Complete the Dress pages so admins can upload PDF doctrine documents, create new
dress requirement records, edit mandatory/optional/branch-override rules inline,
save drafts, publish, and view real change history — replacing every hardcoded
constant and stub toast across the `/dress/add`, `/dress/:id`, and
`/dress` (list) flows.

## 2. Scope

- **In scope:**
  1. **Dress Add — PDF upload** to Firebase Storage (`dress_pdfs/{id}.pdf`).
  2. **Dress Add — real `setDoc`** creating a `dress_requirements/{id}` Firestore document after the wizard.
  3. **Dress Add — real review pane metadata** (filename, size, page count from the file object).
  4. **Dress Review — Add / Edit mandatory rules** inline → `updateDoc`.
  5. **Dress Review — Add / Edit optional logic rules** inline → `updateDoc`.
  6. **Dress Review — branch override editor** → `updateDoc` on `branch_overrides` map.
  7. **Dress Review — real `saveDraft`** → `updateDoc({doctrine_status: 'stub_pending_pdf'})`.
  8. **Dress Review — PDF viewer** — embed the Storage PDF URL in an `<iframe>` (or a "View PDF" button that opens it in a new tab).
  9. **Dress Edit — real change history** from `activity_log` filtered by `target === dress.id`.

- **Out of scope:** AI extraction from PDF (stub animation replaced with a real upload but no AI parse), per-branch accessory override editor (complex nested object editor — deferred to a follow-up plan), dress delete (implemented in Phase 1 on the list page).

## 3. Affected areas

| File | Change |
|------|--------|
| `admin-portal/src/app/pages/dress/dress-add/dress-add.component.ts` | Real file upload + Firestore setDoc |
| `admin-portal/src/app/pages/dress/dress-detail/dress-detail.component.ts` | Real rule editors + real history + PDF viewer |
| `admin-portal/src/app/core/data/firestore-data.service.ts` | Add `createDress()`, `updateDress()`, `dressHistory()` |
| `admin-portal/src/app/core/data/storage-data.service.ts` | Add `uploadDressPdf()`, `getDressPdfUrl()` |
| `admin-portal/src/app/core/data/models.ts` | Extend `Dress` with `pdfUrl?: string`, `mandatoryRules: string[]`, `optionalLogic: Record<string,unknown>`, `branchOverrides: Record<string,unknown>` |
| `admin-portal/public/i18n/en.json` | Add translation keys for new rule editor labels, history tab, PDF viewer |

## 4. Step-by-step plan

### Step 1 — Extend model + service write methods

1. In `models.ts`, add to `Dress`:
   ```typescript
   pdfUrl?:         string;
   mandatoryRules:  string[];
   optionalLogic:   Record<string, unknown>;
   branchOverrides: Record<string, unknown>;
   ```
2. In `firestore-data.service.ts` add:
   ```typescript
   createDress(id: string, data: DressWritePayload): Promise<void>
     // setDoc dress_requirements/{id}
   updateDress(id: string, data: Partial<DressWritePayload>): Promise<void>
     // updateDoc dress_requirements/{id}
   dressHistory(dressId: string): Observable<ActivityEntry[]>
     // collectionData activity_log where target == dressId, orderBy timestamp desc, limit 50
   ```
3. In `storage-data.service.ts` add:
   ```typescript
   uploadDressPdf(id: string, file: File): Observable<number>
     // Uploads to dress_pdfs/{id}.pdf, emits progress 0–100
   getDressPdfUrl(id: string): Promise<string>
     // Returns download URL for dress_pdfs/{id}.pdf
   ```

### Step 2 — Dress Add: real PDF upload

1. Replace the fake animated "AI scan" sequence with a real upload flow:
   - Step 1 (drop zone): user drops or picks a PDF file.
   - On file selected: show filename, size (e.g. "2.4 MB"), and page count (read from `file.name` — page count requires a PDF parser or can be shown as `—` without one).
   - Step 2 (review pane): show real file metadata. Show an "Upload PDF" progress bar that calls `storage.uploadDressPdf(id, file)`.
   - The animated scan overlay is replaced by a real upload progress indicator.
2. On upload complete: store the download URL in a `pdfUrl` signal for use in the Firestore write.

### Step 3 — Dress Add: real Firestore document creation

1. In the wizard's final step ("Finalise"), the Confirm button calls:
   ```typescript
   await svc.createDress(id, {
     dress_name:      this.dressName(),
     display_name:    this.displayName(),
     doctrine_status: 'stub_pending_pdf',
     pdf_url:         this.pdfUrl(),
     mandatory_rules: [],
     optional_logic:  {},
     branch_overrides: {},
   });
   await svc.addActivityLog('Created dress', id);
   ```
2. On success: `toast.success(...)` → `router.navigate(['/dress', id])`.
3. Wrap in try/catch with `toast.error(...)`.

### Step 4 — Dress Review: PDF viewer

1. In `dress-detail.component.ts`, add a "PDF" tab (or a "View PDF" button in the header).
2. Load the PDF URL: `await storage.getDressPdfUrl(dress.id)` → store in `pdfUrl = signal<string | null>(null)`.
3. If `pdfUrl()` is set, render:
   ```html
   <iframe [src]="pdfUrl() | safeUrl" class="pdf-frame" title="Dress PDF"></iframe>
   ```
   using an `SafeUrlPipe` (or `DomSanitizer.bypassSecurityTrustResourceUrl`).
4. If not set, show `<app-empty-state icon="doc" label="No PDF uploaded" />`.

### Step 5 — Dress Review: mandatory rules editor

1. In the detail component, show the `mandatory_rules` array as an editable list.
2. Each rule row has an inline text input (disabled by default) + an Edit pencil icon.
3. Clicking Edit enables the input. Clicking Save: `svc.updateDress(id, { mandatory_rules: updatedList })` + activity log + success toast.
4. "Add Rule" button appends a blank row in edit mode.
5. Delete rule: remove from array → `svc.updateDress(...)` → toast.

### Step 6 — Dress Review: optional logic editor

1. Same pattern as mandatory rules but for the `optional_logic` key/value map.
2. Each entry is `{ key: string, value: unknown }`. Display as a two-column table: key | value.
3. Edit / Add / Delete follows the same inline pattern.
4. Save: `svc.updateDress(id, { optional_logic: updatedMap })`.

### Step 7 — Dress Review: branch override editor

1. Show a collapsible section per branch (Army / Navy / RSAF / DIS) in the Review pane.
2. Each section shows the current `branch_overrides[branchId]` as a JSON viewer (using the existing `<app-json-viewer>` component).
3. An "Edit" button switches to a `<textarea>` with the JSON string for raw editing.
4. Save: parse JSON → `svc.updateDress(id, { branch_overrides: { ...existing, [branchId]: parsed } })` + activity log.
5. Show a parse error inline if the JSON is invalid.

### Step 8 — Dress Review: real saveDraft / publish

1. Replace the toast-only "Save Draft" button with:
   ```typescript
   await svc.updateDress(id, { doctrine_status: 'stub_pending_pdf', updatedAt: serverTimestamp() });
   await svc.addActivityLog('Saved draft', id);
   ```
2. Add a "Publish" button (only shown for `status !== 'live'`):
   ```typescript
   await svc.updateDress(id, { doctrine_status: 'pdf_aligned' });
   await svc.addActivityLog('Published dress', id);
   ```

### Step 9 — Dress Edit: real change history

1. In `dress-detail.component.ts`, replace the hardcoded `HISTORY` constant with:
   ```typescript
   readonly history = toSignal(this.svc.dressHistory(this.dressId()), { initialValue: [] });
   ```
   Where `dressId()` reads from the route param.
2. Render the history tab with the real `ActivityEntry` list (who, action, timestamp).
3. If the list is empty (new dress, no edits yet), show `<app-empty-state label="No changes yet" />`.

## 5. Risks & rollback

- **PDF upload** stores the file at `dress_pdfs/{id}.pdf`. Rollback: delete from Storage Console. No impact on mobile app (mobile does not read dress PDFs).
- **`createDress` with a colliding ID** — guard with `getDoc` check before `setDoc`; show error if the doc already exists.
- **Branch overrides raw JSON editor** — invalid JSON is caught client-side before any write. Bad valid-JSON that breaks the mobile resolver degrades gracefully (the mobile `DressAccessoryResolver` reads `branch_overrides[branchId]` and falls back to base rules on missing keys).
- **`dressHistory` query** requires a composite Firestore index on `activity_log` for `(target, timestamp desc)`. Create the index in Firestore Console if the query returns an error (the error message includes a direct Console link to create it).

## 6. Verification

1. `npx ng build --configuration development` — zero errors.
2. Smoke test:
   - Dress Add: drop a PDF → progress bar reaches 100% → wizard advances → Confirm creates a new `dress_requirements` doc → redirects to `/dress/:id`.
   - Dress Review: PDF tab shows the embedded PDF (or opens in new tab).
   - Dress Review: Edit a mandatory rule → Save → Firestore doc reflects the change.
   - Dress Review: Add a mandatory rule → appears in list.
   - Dress Review: Save Draft → `doctrine_status` updates in Firestore.
   - Dress Review: Publish → `doctrine_status` becomes `pdf_aligned`.
   - Dress Edit: History tab shows real `activity_log` entries for this dress.
3. Firestore Console: verify `dress_requirements/{id}` is created/updated correctly.
4. Storage Console: verify `dress_pdfs/{id}.pdf` exists after upload.

## 7. CLAUDE.md updates required

- Update `dress_requirements` Firestore collection description: admin portal is now the write surface.
- Update `admin-portal` section: note Phase 3 features (full dress lifecycle, PDF upload, rule editors, history) are live.
- Note new Storage prefix `dress_pdfs/` and composite Firestore index requirement for `activity_log`.

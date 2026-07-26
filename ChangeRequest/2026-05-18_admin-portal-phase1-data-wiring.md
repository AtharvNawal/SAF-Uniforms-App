# Admin Portal Phase 1 — Data Wiring & Quick Wins

- **Date:** 2026-05-18
- **Author:** Claude / Datta
- **Status:** executed

## 1. Goal

Wire the five remaining hardcoded/non-functional UI elements to real data,
giving every currently-built screen accurate live values without adding any new
pages or file-upload flows.

## 2. Scope

- **In scope:**
  1. **Branches** — replace hardcoded "Last saved: —" with real `updatedAt` timestamp read from `branch_configs` Firestore docs.
  2. **Users drawer** — remove hardcoded `12 photos / 4 models / 28 sessions`; query real `users/{uid}/gallery` subcollection count; show `—` for sessions (no session tracking yet).
  3. **Dress List — filter chips** — wire the branch/status filter controls to actually filter the `dresses()` signal instead of being decorative.
  4. **Dress List — kebab menu** — wire each dress card's overflow menu: "Edit" navigates to `/dress/:id`; "Delete" shows a two-step confirm then calls `deleteDoc` on `dress_requirements/{id}`.
  5. **Accessories — pagination** — wire the page-size selector and page navigation buttons to slice the full `accessories()` array in memory.

- **Out of scope:** File uploads, GLB handling, 3D viewers, PDF viewers, new Firestore collections, Cloud Functions.

## 3. Affected areas

| File | Change |
|------|--------|
| `admin-portal/src/app/pages/branches/branches.component.ts` | Read `updatedAt` from `branchConfigs()` signal; format and display per card |
| `admin-portal/src/app/pages/users/users.component.ts` | Add Firestore query for `users/{uid}/gallery` count in drawer; remove hardcoded stats |
| `admin-portal/src/app/core/data/firestore-data.service.ts` | Add `galleryCount(uid: string): Observable<number>` method |
| `admin-portal/src/app/pages/dress/dress-list/dress-list.component.ts` | Wire filter signals to computed filtered list; wire kebab delete action |
| `admin-portal/src/app/pages/accessories/accessories.component.ts` | Wire pagination controls to computed paginated slice |
| `admin-portal/src/app/core/data/models.ts` | Ensure `BranchCfg` has `updatedAt?: string` field |
| `admin-portal/public/i18n/en.json` | Add any new translation keys (e.g. `dress.delete.confirm`, `users.drawer.row.photos`) |

## 4. Step-by-step plan

### Step 1 — Branches: real `updatedAt` timestamp

1. In `firestore-data.service.ts`, confirm `branchConfigs()` maps the Firestore `updatedAt` Timestamp field to a formatted string (e.g. `"18 May 2026 14:32"`). Add the field to the `BranchCfg` interface in `models.ts` if missing.
2. In `branches.component.ts`, read `updatedAt` from `this.configs()['army'].updatedAt` etc. and display it in the "Last saved" slot of each branch card.

### Step 2 — Users drawer: real photo count

1. Add `galleryCount(uid: string): Observable<number>` to `FirestoreDataService` — uses `collectionData` on `users/{uid}/gallery` and maps to `.length`.
2. In `users.component.ts`, when a user row is selected to open the drawer, subscribe to `svc.galleryCount(user.uid)` and store the result in a `drawerPhotoCount = signal(0)`. Set it before showing the drawer.
3. Replace the hardcoded `12 photos` row with `drawerPhotoCount()`. Remove `4 models` and `28 sessions` rows entirely (replace with `—` or remove the stat rows).

### Step 3 — Dress List: filter chips

1. In `dress-list.component.ts`, identify the existing branch/status filter signals (likely `filterBranch` and `filterStatus`).
2. Add a `filtered = computed(() => { ... })` signal that applies both filters against `dresses()`.
3. Replace the template's `@for (d of dresses(); ...)` with `@for (d of filtered(); ...)`.
4. Ensure the filter chip click handlers update the filter signals (they may already do so — just need the computed to consume them).

### Step 4 — Dress List: kebab menu actions

1. Wire the "Edit" kebab action to `this.router.navigate(['/dress', dress.id])`.
2. Add `pendingDelete = signal<string | null>(null)` to `DressListComponent`.
3. Wire the "Delete" kebab action: first click → `pendingDelete.set(dress.id)` + `toast.warn('Click again to confirm delete')`. Second click → `deleteDoc(doc(firestore, 'dress_requirements', dress.id))` + activity log + `toast.success(...)`. Wrap in try/catch with `toast.error(...)` on failure.
4. Inject `FirestoreDataService` and `Firestore` (for `deleteDoc`) into the component.
5. Add i18n keys: `dress.delete.confirm`, `dress.delete.success`, `dress.delete.error`.

### Step 5 — Accessories: pagination wiring

1. In `accessories.component.ts`, add `pageSize = signal(20)`, `currentPage = signal(0)`.
2. Add `paginated = computed(() => { const all = filtered(); const s = currentPage() * pageSize(); return all.slice(s, s + pageSize()); })`.
3. Add `totalPages = computed(() => Math.ceil(filtered().length / pageSize()))`.
4. Wire the page-size `<app-select>` to update `pageSize` and reset `currentPage` to 0.
5. Wire the Previous / Next buttons to decrement/increment `currentPage` with bounds checking.
6. Replace `@for (a of filtered(); ...)` in the template with `@for (a of paginated(); ...)`.
7. Update the results count display to show `{{ currentPage() * pageSize() + 1 }}–{{ min(...) }} of {{ filtered().length }}`.

## 5. Risks & rollback

- **Delete dress** is irreversible once confirmed. The two-step pattern (same as Logic rules) mitigates accidental deletion. Rollback: re-create the doc manually in Firestore Console.
- **Gallery count query** adds one extra Firestore read per drawer open. For small user counts this is negligible. If `users/{uid}/gallery` does not exist yet, `collectionData` returns an empty array (count = 0) — safe.
- No schema changes; no Storage changes; no Cloud Function changes.

## 6. Verification

1. `cd admin-portal && npx ng build --configuration development` — zero errors.
2. `npx ng serve` — smoke test:
   - Branches page: each card shows the real `updatedAt` value (or `—` if the field is absent from Firestore).
   - Users page: open a user drawer — photo count reflects real gallery subcollection count.
   - Dress list: toggle branch chip to "ARMY" — only army dresses remain visible.
   - Dress list: open kebab → Edit → navigates to `/dress/:id`.
   - Dress list: open kebab → Delete → warning toast → Delete again → doc removed, list updates.
   - Accessories: change page size to 10 → shows 10 rows; Next button → next 10 rows.

## 7. CLAUDE.md updates required

- Update the `admin-portal` section to note Phase 1 features are live (real timestamps, real photo counts, working filters, dress delete, accessories pagination).

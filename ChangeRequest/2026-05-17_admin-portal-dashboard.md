# Admin Portal — Dashboard Screen

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Replace the `<app-page-stub>` at `/dashboard` with the full Dashboard
screen from the Claude Design handoff: 5-card stat row, recent-activity
list, 5-button quick actions grid, and a 4-branch × 5-dress-code
coverage matrix. All strings flow through ngx-translate; all data flows
through `MockDataService` (swap to AngularFire-backed services in a
later "real Firestore wiring" plan).

The design's hardcoded stat values (`2,418` users, `1,026` models, etc.)
are kept as static template strings on the component for now — they
will become Firestore aggregations in the "real wiring" plan.

## 2. Scope

**In:**
- Full Dashboard layout matching the JSX source at
  `/tmp/saf-handoff2/saf-uniforms/project/src/admin/dashboard.jsx`.
- All design CSS classes are already in `src/styles/_design.scss` —
  no new SCSS work.
- Translation keys under `dashboard.*` (stat labels, eyebrow strings,
  quick-action labels, coverage legend, table headers).
- Activity rows + coverage values fetched via `MockDataService`.
- Quick-action buttons trigger router navigation + toast notifications
  matching the design's `useToast` behaviour.

**Out:**
- Real Firestore aggregations for the stat values (still hardcoded).
- Wiring the "View all logs" link to a real activity log (no destination
  exists yet; left as a non-functional anchor).
- Wiring "Firestore Console" external link to the real URL (still a
  toast for now — matches the design source's behaviour).

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/dashboard/dashboard.component.ts` | **Rewrite** — replace stub with full implementation |
| `admin-portal/public/i18n/en.json` | Edit — add `dashboard.*` keys (stats, activity card, quick actions, coverage) |
| `CLAUDE.md` | Edit — mark Dashboard as done in the `admin-portal/` §2 row |
| `ChangeRequest/2026-05-17_admin-portal-dashboard.md` | **NEW** — this file |

## 4. Step-by-step plan

1. **i18n keys** — extend `public/i18n/en.json` with `dashboard.*` keys:
   - `eyebrow`, `title`, `subtitle`, `refresh`
   - `stat.users.{value,label,sub}`, `stat.models.{...}`,
     `stat.dressCodes.{...}`, `stat.accessories.{...}`,
     `stat.branches.{...}`
   - `activity.title`, `activity.viewAll`
   - `quickActions.title`, `quickActions.{uploadPdf,addAccessory,uploadBody,sync,firestore}`
   - `coverage.eyebrow`, `coverage.title`, `coverage.legend.{live,placeholder,pending,missing}`,
     `coverage.col.branch`
   - `toast.refreshing.{title,body}`, `toast.syncQueued.{title,body}`,
     `toast.firestore.title`
   - Branch names already covered by branch data; reuse `BRANCHES` for
     row labels (they're proper nouns, not translated).

2. **Component template** — rewrite
   `pages/dashboard/dashboard.component.ts` with the four sections:
   - **Page header** (using the foundation's `<header class="page-header">` pattern; Refresh button is an `<app-btn variant="ghost">` triggering a toast)
   - **Stat grid** (5 `.stat-card` divs, each with `.stat-card-icon`, `.stat-value`, `.stat-label`, `.stat-sub`)
   - **`dash-mid`** two-column section:
     - Left: **Recent Activity card** — eyebrow + "View all logs" link, then `.activity-list` of 10 rows from `mockData.activity()`
     - Right: **Quick Actions card** — eyebrow + 5 `.quick-action` buttons; first three navigate (`router.navigateByUrl`), last two fire toasts
   - **Coverage matrix card** — eyebrow + h3 title + legend, then a CSS-grid-or-flex `.coverage-table` driven by `mockData.branches()`, `mockData.dressCodes()`, `mockData.coverage()`.

3. **Wiring** — inject `MockDataService`, `Router`, `ToastService`,
   `TranslateService`. Use `toSignal(observable)` for the three data
   streams so the template reads them synchronously.

4. **Verify** — `npm run build` clean; dev server hot-reloads;
   visiting `/dashboard` shows the full layout with translated labels.

## 5. Risks & rollback

| Risk | Mitigation |
| ---- | ---------- |
| Hardcoded stat values look fake | Acceptable for foundation phase; flagged in §2 (Out of scope). Will be replaced by Firestore aggregations in the later "real wiring" plan |
| Mock activity items reference admins / accessories that don't exist | The data was lifted verbatim from the design's `data.jsx` so this matches the design intent; same swap as above |
| Coverage matrix legend visual mismatch | Pre-existing `_design.scss` has `.coverage-live`, `.coverage-placeholder`, `.coverage-pending`, `.coverage-missing`; cells receive the matching class — should render correctly without new CSS |

**Rollback:** revert `dashboard.component.ts` to its stub form, drop
the `dashboard.*` keys from `en.json`, revert CLAUDE.md.

## 6. Verification

1. `npm run build` exits 0; no new warnings.
2. Dev server (already running on `http://localhost:4200/` in
   watch mode) hot-reloads.
3. Browser at `/dashboard` shows:
   - Page header with "OVERVIEW" eyebrow + "Dashboard" h1 + subtitle +
     "Refresh" ghost button.
   - 5-card stat grid wrapping to 3 columns ≤ 1180 px, 2 ≤ 720 px, 1 ≤ 480 px.
   - Two-column mid section (collapses to one column ≤ 980 px).
   - Activity list shows all 10 mock rows.
   - Quick Actions list shows 5 buttons; clicking "Upload New Dress
     PDF" navigates to `/dress/add`; clicking "Sync Seed Data" raises
     a toast.
   - Coverage table shows 4 rows × 6 columns (1 branch label + 5 codes),
     cells coloured per status.
4. Flip ChangeRequest status to `verified` once 3 passes.

## 7. CLAUDE.md updates required

- §2 `admin-portal/` row — change the listing of completed screens
  from "Login + Settings fully designed; …7 stubs" to "Login +
  Dashboard + Settings fully designed; …6 stubs".
- Update the route description for `/dashboard` from "stub" to
  "stats / activity / quick actions / coverage matrix".

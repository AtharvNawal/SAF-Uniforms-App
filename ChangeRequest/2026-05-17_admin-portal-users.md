# Admin Portal — App Users Screen

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Implement the `/users` screen per the Claude Design handoff
(`config-screens.jsx` lines 213–341). Read-only table of mobile-app
users with search + filters + per-row drawer.

Detailed scope is in
[ChangeRequest/2026-05-17_admin-portal-remaining-screens-roadmap.md](2026-05-17_admin-portal-remaining-screens-roadmap.md)
Screen 1.

## 2. Scope

**In:**
- `UsersComponent` with page header, search input, two filter pill
  groups (branch + profile completeness), table, per-row drawer.
- New shared **Drawer** primitive (`<app-drawer>`) at
  `shared/ui/drawer/` — will be reused by Accessories.
- New shared **IconBtn** component (`<app-icon-btn>`) for the round
  icon-only buttons. The CSS `.icon-btn` class already exists in
  `_design.scss`; this gives it a typed Angular wrapper.
- i18n keys under `users.*`.

**Out:** real Firestore wiring; per-user gallery photo previews; the
"Copy UID" action actually copying to clipboard (UI placeholder for now).

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/users/users.component.ts` | Rewrite — replace stub with full implementation |
| `admin-portal/src/app/shared/ui/drawer/drawer.component.ts` | **NEW** — slide-in right panel |
| `admin-portal/src/app/shared/ui/icon-btn/icon-btn.component.ts` | **NEW** — round 28×28 icon button |
| `admin-portal/public/i18n/en.json` | Extend — add `users.*` keys |
| `CLAUDE.md` | Edit — flip `/users` from stub to designed |

## 4. Verification

1. `npm run build` clean.
2. Dev server hot-reloads.
3. `/users` shows 8 mock rows; search filters live; both pill groups
   compose; clicking a row opens the drawer; ESC + backdrop close;
   theme switch (dark ↔ light) keeps the table readable.

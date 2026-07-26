# Admin Portal — Admin Accounts Screen

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Implement `/admins` per `config-screens.jsx` lines 344–408. Table of
admin accounts + "Add Admin" modal.

Roadmap reference: Screen 2 in
`2026-05-17_admin-portal-remaining-screens-roadmap.md`.

## 2. Scope

**In:**
- `AdminsComponent` — page header with "Add Admin" primary button,
  info banner ("password management lives in Firebase Auth"), table
  with avatar + name + email + role chip + dates + status toggle +
  kebab icon, "Add Admin" modal with 3 fields.
- The kebab is a single icon button in this design (no popover menu);
  KebabMenu primitive is **deferred** until a screen actually needs the
  dropdown behaviour.
- i18n keys under `admins.*`.

**Out:** real Firebase Auth admin creation (mock; toasts on submit);
status toggle persistence (UI-only); kebab popover (no menu items in
the design source).

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/admins/admins.component.ts` | Rewrite |
| `admin-portal/public/i18n/en.json` | Extend — `admins.*` |
| `CLAUDE.md` | Edit — flip `/admins` from stub to designed |

## 4. Verification

1. `npm run build` clean.
2. Dev server hot-reloads.
3. `/admins` shows 3 mock rows; "Add Admin" opens the modal; modal
   validates email format; submit closes modal + raises toast; status
   toggle flips visually.

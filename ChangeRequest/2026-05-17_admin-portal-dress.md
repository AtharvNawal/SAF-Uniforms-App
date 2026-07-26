# Admin Portal — Dress Requirements Screens

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Implement the three Dress Requirements routes per `dress.jsx`:

- `/dress` — list with filters
- `/dress/add` — 3-step wizard (Upload → Review → Finalise)
- `/dress/:id` — edit (reuses Review pane + change history)

## 2. Scope

**In:**
- `DressListComponent` — page header (Filters ghost + Add Dress
  primary), 2 filter pill groups, grid of dress cards, empty state.
  Each card: code pill, status chip, title, metadata (overrides /
  mandatory / optional counts), branch dots, kebab menu (UI-only).
- `DressAddComponent` — 3-step flow:
  1. PDF dropzone + dress code select + display name input + Analyse
     button → triggers mock AI scan overlay (animated progress ring +
     4-step list, ~3.3 s).
  2. Review pane — split layout with placeholder PDF frame on the left
     + extracted rules on the right (mandatory + optional + collapsible
     branch overrides).
  3. Finalise pane — summary card + status pill toggle (draft /
     placeholder / live) + warning banner when Live + 3 action buttons.
- `DressEditComponent` — reuses the review-pane layout + 5-row change
  history accordion.
- New `<app-pdf-dropzone>` primitive for drag-drop file input.
- All sample rule data inlined (matches design source).
- i18n keys under `dress.*`.

**Out:** real PDF rendering; real AI extraction (mock animation); real
Firestore writes.

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/dress/dress-list.component.ts` | Rewrite |
| `admin-portal/src/app/pages/dress/dress-add.component.ts` | Rewrite |
| `admin-portal/src/app/pages/dress/dress-edit.component.ts` | Rewrite |
| `admin-portal/src/app/shared/ui/pdf-dropzone/pdf-dropzone.component.ts` | **NEW** |
| `admin-portal/public/i18n/en.json` | Extend — `dress.*` |
| `CLAUDE.md` | Edit — flip all 3 dress routes from stubs to designed |

## 4. Verification

`/dress` shows 6 mock cards + filter pills working; clicking a card
goes to `/dress/{id}`; "Add Dress" goes to `/dress/add`; the wizard
flows through all 3 steps including the animated scan overlay; the
Edit route shows the review pane + change history accordion.

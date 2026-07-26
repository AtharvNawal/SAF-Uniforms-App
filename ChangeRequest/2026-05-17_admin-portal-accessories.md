# Admin Portal — Accessory Library Screen

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Implement `/accessories` per `accessories.jsx` (422 lines). Filterable
sortable table of accessories + tabbed detail drawer (Details / Images
/ 3D Model / Usage) + "Add Accessory" modal.

## 2. Scope

**In:**
- `AccessoriesComponent` with header, toolbar (search + 4 filters),
  table, empty state, pagination footer (UI only), per-row drawer with
  4 tabs, "Add Accessory" modal.
- Reuses Drawer primitive from the Users screen.
- Inline accessory thumb (category-colored badge icon).
- All four drawer tabs implemented:
  - **Details** — name + category + branch + gender + 2 JSON viewers
    (rules + render_logic).
  - **Images** — 2 image slots (accessory image + placement diagram)
    with placeholder previews.
  - **3D Model** — model-viewer placeholder frame + GLB drop zone
    placeholder + meta. **No real `<model-viewer>` yet** — that lands
    in the 3D Models screen.
  - **Usage** — list of dresses referencing the accessory (top 4 mock).
- i18n keys under `accessories.*`.

**Out:** real image / GLB uploads, real PDF preview, real Firestore
writes, real `<model-viewer>`.

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/accessories/accessories.component.ts` | Rewrite |
| `admin-portal/public/i18n/en.json` | Extend — `accessories.*` |
| `CLAUDE.md` | Edit — flip `/accessories` from stub to designed |

## 4. Verification

`/accessories` shows 17 mock rows; search + 4 filters compose correctly;
empty state shows on zero results; clicking a row opens the drawer;
tabs switch; close + ESC dismiss; theme switch preserves table
contrast.

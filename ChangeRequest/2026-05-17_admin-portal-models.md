# Admin Portal — 3D Models Screen

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Implement `/models` per `models.jsx` (267 lines). Tab router with 4
tabs: Bodies / Uniforms / Accessories / Placeholder.

## 2. Scope revision

The roadmap estimated this as Complexity L with a `@google/model-viewer`
install. On reading the source carefully, the design uses placeholder
frames (`.model-viewer-frame` with a cube icon + filename label) — not
real 3D rendering. **No `@google/model-viewer` install needed.** Real
3D rendering becomes its own follow-up plan when GLB loading + Storage
`getDownloadURL` lands. Complexity drops to M.

**In:**
- `ModelsComponent` with header (Re-scan Storage ghost button) + pill
  toggle tab bar + per-tab content.
- **Bodies tab** — 3-card grid (male / female / female-maternity) with
  status chips, viewer-frame placeholder, upload buttons. "View Full"
  opens a large modal with viewer + 14-socket validation panel.
- **Uniforms tab** — 4×5 branches × dress codes matrix; each cell is
  either UPLOADED (file size + date + Replace/Download links) or
  MISSING (suggested filename + Upload button).
- **Accessories tab** — full-width table (8 cols) listing every
  accessory with GLB status chip + size + uploaded date + actions.
- **Placeholder tab** — info banner + large viewer frame + meta sidebar.
- i18n keys under `models.*`.

**Out:** real `<model-viewer>` rendering; real GLB Storage reads.

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/models/models.component.ts` | Rewrite |
| `admin-portal/public/i18n/en.json` | Extend — `models.*` |
| `CLAUDE.md` | Edit — flip `/models` from stub to designed |

## 4. Verification

`/models` shows all 4 tabs; pill toggle switches between them; Bodies
tab opens a full-view modal; Uniforms tab shows the 4×5 matrix with
correct uploaded/missing states; Accessories tab shows table with
correct GLB status; Placeholder tab shows file info.

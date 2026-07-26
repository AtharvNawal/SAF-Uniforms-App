# Admin Portal — Logic Rules Screen

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Implement `/logic` per `config-screens.jsx` lines 117–210. Rule cards
with description + params + per-rule edit/save/delete + "Add Rule"
modal.

## 2. Scope revision

The roadmap estimated this as Complexity L with a Monaco dependency.
On reading the source carefully, the design's `JsonEditor` is
**read-only display** with simple regex syntax highlighting — not an
actual editor. **No Monaco install needed.** This drops the complexity
to S.

**In:**
- `LogicComponent` — header with "Add Rule", vertical stack of rule
  cards from `MockDataService.logicRules()`, each card with header
  (id + status chip + version + modified timestamp), description
  textarea, params view (form or JSON), delete + save buttons. "Add
  Rule" modal with id + description + params JSON fields.
- New `<app-json-viewer>` primitive — line-numbered colour-highlighted
  JSON display (no editing).
- i18n keys under `logic.*`.

**Out:** real JSON editing (would need Monaco or CodeMirror — defer
to follow-up plan if needed); real Firestore writes.

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/logic/logic.component.ts` | Rewrite |
| `admin-portal/src/app/shared/ui/json-viewer/json-viewer.component.ts` | **NEW** |
| `admin-portal/public/i18n/en.json` | Extend — `logic.*` |
| `CLAUDE.md` | Edit — flip `/logic` from stub to designed |

## 4. Verification

`/logic` shows 4 rule cards; "Edit JSON" toggles between form view
and JSON viewer; description textareas accept text; Save / Delete
fire toasts; "Add Rule" opens the modal with a default JSON template.

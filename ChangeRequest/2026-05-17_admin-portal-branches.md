# Admin Portal — Branch Config Screen

- **Date:** 2026-05-17
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Implement `/branches` per `config-screens.jsx` lines 1–115. 4-card
responsive grid of per-branch render config (collar offset, medal
anchor, sikh logic, enabled dress codes).

Roadmap reference: Screen 3.

## 2. Scope

**In:**
- `BranchesComponent` with page header (Save All Branches primary
  button) + grid of 4 `BranchCard` instances.
- New `<app-cfg-section>` primitive (eyebrow + content).
- Inline `BRANCH_DEFAULTS` config matching the design source.
- Save button per card raises a toast (mock).
- i18n keys under `branches.*`.

**Out:** real Firestore writes to `branch_configs/{branchId}`;
color picker (just a text input matching the design for now).

## 3. Affected areas

| Path | Action |
| ---- | ------ |
| `admin-portal/src/app/pages/branches/branches.component.ts` | Rewrite |
| `admin-portal/src/app/shared/ui/cfg-section/cfg-section.component.ts` | **NEW** |
| `admin-portal/public/i18n/en.json` | Extend — `branches.*` |
| `CLAUDE.md` | Edit — flip `/branches` from stub to designed |

## 4. Verification

`/branches` shows 4 cards (Army / Navy / RSAF / DIS) with their
config sections; inputs accept values; toggling a dress-code pill
updates the card state; Save Changes raises a per-branch toast;
Save All Branches raises a single toast.

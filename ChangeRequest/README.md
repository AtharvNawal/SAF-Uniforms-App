# ChangeRequest

This folder holds the plan files for every non-trivial change executed on this
project (see policy 1 in [CLAUDE.md](../CLAUDE.md)).

## Naming convention

`YYYY-MM-DD_<short-kebab-title>.md`

Example: `2026-05-02_add-profile-screen.md`

## Plan file template

```markdown
# <Plan title>

- **Date:** YYYY-MM-DD
- **Author:** <name / agent>
- **Status:** draft | in-progress | executed | verified | reverted

## 1. Goal
What outcome we want and why.

## 2. Scope
- In scope: ...
- Out of scope: ...

## 3. Affected areas
Files, modules, packages, schemas, assets that will change.

## 4. Step-by-step plan
1. ...
2. ...

## 5. Risks & rollback
What can break, and how to undo.

## 6. Verification
How we will analyse / run / test the app after execution
(per policy 5 in CLAUDE.md).

## 7. CLAUDE.md updates required
Sections of CLAUDE.md that must be refreshed once the plan is executed
(per policy 2 in CLAUDE.md).
```

# Belt + footwear cross-check: fix patent shoes gender; men get 2-shoe alternatives

- **Date:** 2026-05-11
- **Author:** Claude (Datta-driven session)
- **Status:** executed (operator on-device verification pending)
- **Verification:**
  - `flutter analyze` clean. `flutter test` 73/73. `cd functions && npm run build && npm test` 18/18.
  - Re-seed: `dress_requirements: ok (5 docs)`, `accessory_library: ok (82 docs)`.
  - CF deploy successful. User's `no_3` cache wiped.

## 1. Goal

User cross-check on belt + shoes data:

| Item | User says | Library was | Action |
| --- | --- | --- | --- |
| `nylon_belt` | men | gender=men | ✓ no change |
| `leather_belt` | ladies | gender=ladies | ✓ no change |
| `leather_shoes_low_cut` | men (standard) | gender=men | ✓ no change |
| `patent_shoes_low_cut` | men (formal alt) | gender=null | **fix to men** |

For shoes, men have TWO variants that are alternatives to each other. The previous `dress_requirements` shape allowed only a single id per gender. Extend the schema so the men slot can be a LIST, with all listed alternatives appearing in the Wardrobe Mandatory section.

## 2. Scope

### In scope
- Patch `patent_shoes_low_cut.gender` from `null` → `"men"` in `accessory_library.v1.json`.
- Update the `footwear` key in each `branch_overrides[branchId]` (20 entries: 5 dress codes × 4 branches) to:
  ```json
  "footwear": {
    "men":    ["leather_shoes_low_cut", "patent_shoes_low_cut"],
    "ladies": "court_shoes"
  }
  ```
- Extend both resolvers (Dart + TS) so `addGenderedMandatory` accepts either a bare string, a list of strings, or a `{men, ladies}` selector whose side values are themselves either shape.
- Re-seed Firestore; redeploy CF; wipe test user's `no_3` cache.

### Out of scope
- Belt — already correct, no changes.
- Ladies' footwear — user only specified men's; `court_shoes` kept as the sole ladies' shoe.
- Per-rank-tier footwear (officer formal vs enlistee standard) — both alternatives are shown as mandatory; the user chooses which they're wearing in practice (Wardrobe verification check).
- 3D z-fight when the merger attaches both shoes — Phase-2 placeholder accepted limitation; the user can iterate which appears canonically later.

## 3. Affected areas

### Data
- `assets/data/accessory_library.v1.json` — single field change on `patent_shoes_low_cut`.
- `assets/data/dress_requirements.v1.json` — `footwear` key reshaped from `{men: string, ladies: string}` to `{men: string[], ladies: string}` across all 20 branch overrides.

### Flutter
- `lib/features/checklist/domain/services/dress_accessory_resolver.dart` — `addGenderedMandatory` factored into `addOne` (handles string OR list) + a thin gender-selector wrapper.

### Backend
- `functions/src/dress_accessory_resolver.ts` — same shape change.

## 4. Step-by-step (executed)

1. Patched `patent_shoes_low_cut.gender` → `"men"`.
2. Reshaped footwear values in all 20 branch overrides.
3. Extended Dart resolver: shared `addOne(raw)` that accepts string or list, then `addGenderedMandatory(raw)` dispatches on bare value vs `{men, ladies}` map.
4. Mirrored the change on TS resolver.
5. `flutter analyze` + `flutter test` + `npm test` all clean.
6. Re-seeded Firestore.
7. Redeployed CF.
8. Wiped user `no_3` cache.

## 5. Verification

1. `flutter analyze` clean.
2. `flutter test` 73/73 (existing resolver tests don't assert on belt/shoes and continue to pass; new resolver paths are no-ops when keys are absent).
3. `npm test` 18/18.
4. Re-seed success.
5. CF redeployed.
6. **On-device (pending):** open the Wardrobe tab → for a male profile, BOTH `leather_shoes_low_cut` and `patent_shoes_low_cut` appear in the **Mandatory** section. The CF logs after a fresh regen should show two `accessory mirrored: …` lines for shoes (one per variant) — visually they will overlap on the feet; the user picks which they treat as canonical.

## 6. Risks & rollback

| Risk | Mitigation |
| --- | --- |
| Two shoes overlap on the model (z-fight) | Visible artefact, acceptable for placeholder phase. Later refinement: pick one per profile via a new render selector. |
| Wardrobe shows two near-identical entries | This is the intended UX — user verifies whichever they're actually wearing. |

**Rollback:** flip footwear values back to single-string form per branch; revert the resolver list-handling.

## 7. CLAUDE.md updates

- §5.5 `composeUniformModel` block — extended description of belt / socks / footwear value shapes (bare id, list of alternatives, or gender selector around either).

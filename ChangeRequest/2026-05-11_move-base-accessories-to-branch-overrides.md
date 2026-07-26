# Move belt / socks / footwear from `base_accessories` into each `branch_overrides` entry

- **Date:** 2026-05-11
- **Author:** Claude (Datta-driven session)
- **Status:** executed (operator on-device verification pending)
- **Verification:**
  - `dart run build_runner build --delete-conflicting-outputs` — 5 outputs, clean.
  - `flutter analyze` clean. `flutter test` 73/73. `cd functions && npm run build && npm test` 18/18.
  - Re-seed: `dress_requirements: ok (5 docs)`, `accessory_library: ok (82 docs)`.
  - CF deploy successful.
  - User's `no_3` cache wiped.

## 1. Goal

The previous CR (`2026-05-11_base-accessories-belt-socks-shoes.md`) added belt / socks / footwear as a new top-level `base_accessories` field on each `dress_requirements` doc. That worked structurally (the resolver did surface them as mandatory in its output) but split the source-of-truth into two places: per-branch `branch_overrides` + universal `base_accessories`. The Wardrobe UI groups accessories by what the resolver returns as mandatory/optional, so the field SHOULD have shown up correctly — but having two homes for the same logical concept (mandatory accessories for a dress) was confusing.

Consolidate: move `belt`, `socks`, `footwear` into each branch's `branch_overrides` entry. Resolver reads them via the same code path as headdress / cap_badge / etc., and the Wardrobe shows them in the Mandatory section automatically.

## 2. Scope

### In scope
- Remove the top-level `base_accessories` field from each `dress_requirements` doc.
- Add `belt`, `socks`, `footwear` keys to each branch's override across all 5 dress codes (5 × 4 = 20 branch overrides updated). Values are identical across branches today (same SAF-wide doctrine) but duplicated for source-of-truth consistency.
- Revert the `DressRequirement.baseAccessories` field + DTO decode added in the previous CR.
- Update both resolvers (Dart + TS) to read `override['belt']` / `override['socks']` / `override['footwear']` instead of the separate `requirement.base_accessories` map.
- Remove `base_accessories` from the TS `DressRequirementRecord` interface.

### Out of scope
- Body socket layout (left/right_ankle + left/right_foot_top remain unchanged — the sockets exist regardless of where the IDs live in the dress doc).
- Merger `PAIRED_SOCKETS` map (unchanged).
- Placeholder geometry generators (unchanged).
- Library data (`gender: "any"` value was investigated; confirmed it's stored as `null` for `black_socks` / `patent_shoes_low_cut`, which the resolver's null-check already passes — no fix needed).

## 3. Affected areas

### Data
- `assets/data/dress_requirements.v1.json`: 5 docs lose top-level `base_accessories`; each branch_override gains `belt` + `socks` + `footwear`.

### Flutter
- `lib/features/checklist/domain/entities/dress_requirement.dart`: `baseAccessories` field removed (freezed regen via build_runner).
- `lib/features/checklist/data/dtos/dress_requirement_firestore.dart`: stops decoding `base_accessories`.
- `lib/features/checklist/domain/services/dress_accessory_resolver.dart`: removed top-level `requirement.baseAccessories` walk; added `override['belt' | 'socks' | 'footwear']` reads via shared `addGenderedMandatory(raw)` helper.

### Backend
- `functions/src/dress_accessory_resolver.ts`: same shape change as the Dart side; `DressRequirementRecord.base_accessories` field removed from the typed interface.

## 4. Verification

1. `flutter analyze` clean.
2. `flutter test` 73/73 (resolver tests don't assert on belt/socks/footwear specifically — they continue to pass because the test fixtures don't include these keys, and the resolver's new branch-level reads are no-ops when keys are absent).
3. `cd functions && npm run build && npm test` 18/18.
4. Re-seed shows `dress_requirements: ok (5 docs)`.
5. CF deploys without errors.
6. **On-device (pending):** open Wardrobe tab, filter to No.3 dress → confirm belt / socks / footwear appear in the **Mandatory** section alongside headdress / cap_badge / chevrons. Then open GhostScreen → confirm the merger still attaches belt + socks + shoes (same CF log lines as the previous CR: `accessory attached: nylon_belt`, `accessory mirrored: black_socks → [left_ankle, right_ankle]`, `accessory mirrored: leather_shoes_low_cut → [left_foot_top, right_foot_top]`).

## 5. Risks & rollback

| Risk | Mitigation |
| --- | --- |
| 4× duplication of identical belt/socks/footwear values across branches drifts if one branch is edited | If real per-branch divergence emerges (e.g. RSAF wears different shoes), this structure handles it natively. If keeping them in sync becomes a problem, we can introduce a separate normalized source later. |
| User has multiple cached `generatedDresses` entries pointing at stale resolver output | Wiped `no_3_dress_requirements` for the active test user; other dresses follow the same path on next open. |

**Rollback:** revert the JSON edits and resolver changes; re-seed. The Dart entity's `baseAccessories` field is gone so no schema mismatch on rollback. Storage assets unchanged.

## 6. CLAUDE.md updates

- §5.5 `composeUniformModel` block — updated to describe the consolidated source (all mandatory accessories from `branch_overrides[branchId]`, including belt/socks/footwear).
- §8 — updated "universal base accessories" note to reflect they live inside branch_overrides now.

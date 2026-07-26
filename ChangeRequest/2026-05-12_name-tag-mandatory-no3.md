# Name Tag — Add as Mandatory Accessory for No. 3 Dress

**Date:** 2026-05-12
**Status:** verified

---

## Goal

Add `name_tag_standard` (and `dis_protocol_name_tag` for DIS) as a mandatory
accessory in the No. 3 dress requirements so it appears in the Wardrobe
checklist. The 3D baking of the name tag already works in the Cloud Function —
this change makes the resolver and Wardrobe UI aware of it.

---

## Scope

| Layer | File | Change |
|---|---|---|
| Seed data | `assets/data/dress_requirements.v1.json` | Add `name_tag` key to all 4 branch overrides |
| Dart resolver | `lib/features/checklist/domain/services/dress_accessory_resolver.dart` | Handle `name_tag` key as mandatory |
| TS resolver | `functions/src/dress_accessory_resolver.ts` | Same — keep Dart ↔ TS parity |
| Firestore | `dress_requirements` collection | Re-seed with updated JSON |
| CF deploy | `functions/` | Re-deploy (TS resolver changed) |

**Not changing:**
- `assets/data/accessory_library.v1.json` — `name_tag_standard` already exists with full data
- `functions/src/glb_compose.ts` — `bakeNameTag()` already works
- `functions/src/index.ts` (`composeUniformModel`) — the name_tag category filter already skips attachment; bake still runs unconditionally

---

## Affected Areas

- Wardrobe tab checklist — name tag now shows as MANDATORY row
- `/checklist` screen — same
- `coordinateMapProvider` — not affected (name tag is baked, not positioned via CoordinateMap)
- 3D composition output — no change (bake was already happening)

---

## Step-by-Step Plan

### Step 1 — Update `assets/data/dress_requirements.v1.json`

In `no_3_dress_requirements.branch_overrides`, add `"name_tag"` key to each
branch. Insert after `"lanyard"` in each branch object:

**army:**
```json
"name_tag": "name_tag_standard"
```

**navy:**
```json
"name_tag": "name_tag_standard"
```

**rsaf:**
```json
"name_tag": "name_tag_standard"
```

**dis:**
```json
"name_tag": "name_tag_standard"
```
(DIS already has `"name_tag_protocol": "dis_protocol_name_tag"` for optional
protocol appointments — that key is separate and stays optional via the
`name_tag_protocol` key which is not read by the resolver today.)

### Step 2 — Update Dart resolver

**File:** `lib/features/checklist/domain/services/dress_accessory_resolver.dart`

After the epaulettes block (around line 108, just before the belt/socks/footwear
section), add:

```dart
// name_tag: mandatory for all branches. Rendered via texture bake in
// the 3D pipeline; included here so the Wardrobe checklist surfaces it.
addMandatory(override['name_tag']);
```

### Step 3 — Update TypeScript resolver

**File:** `functions/src/dress_accessory_resolver.ts`

After the epaulettes block (around line 244, just before the belt/socks/footwear
section), add:

```typescript
// name_tag: mandatory for all branches. Handled by bakeNameTag() in
// composeUniformModel — included here to keep Dart/TS resolver parity
// and surface it in the Wardrobe checklist.
addMandatory(override["name_tag"]);
```

### Step 4 — Re-seed Firestore `dress_requirements` collection

```bash
dart run tool/seed_firestore.dart \
  /Users/meet/Documents/Projects/SAF-Uniforms/2-Designs/saf-uniforms-firebase-adminsdk-fbsvc-647d26c8e1.json
```

Confirm output: `dress_requirements: ok (5 docs)`.

### Step 5 — Build and deploy Cloud Functions

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

### Step 6 — Verify

```bash
flutter analyze          # must be clean
flutter test             # all pass
flutter run              # Wardrobe tab No.3 checklist shows Name Tag (Standard) as MANDATORY
```

---

## Risks & Rollback

- The name_tag bake in the CF is unconditional (it checks `profile.fullName`,
  not the resolver list) — so 3D output is unchanged regardless.
- Rollback: revert the `name_tag` keys from `dress_requirements.v1.json`,
  revert the two resolver lines, re-seed Firestore, re-deploy CF.
- Risk: near-zero — the TS resolver change causes the CF to see
  `name_tag_standard` in `includeAccessories`, but the existing
  `category === "name_tag"` filter immediately skips it. No 3D regression possible.

---

## CLAUDE.md Sections to Refresh After Execution

- §5.2 — note that `name_tag` is now a structured key in `branch_overrides`,
  handled as mandatory by the resolver (same as `belt`/`socks`/`footwear`).
- §8 — remove the implicit gap note about name_tag not being in the resolver.

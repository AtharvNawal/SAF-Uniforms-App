# ChangeRequest: Split Base_Accessories into separate mandatory rule entries

**Date:** 2026-05-11  
**Status:** executed

## Goal
Remove the grouped `"category": "Base_Accessories"` entry from each dress's `mandatory_rules` and replace it with 3 separate entries: `Belt`, `Socks`, and `Footwear`.

## Scope
Single file: `assets/data/dress_requirements.v1.json`

No code changes — the Dart and TypeScript resolvers read `branch_overrides` (already correct), not `mandatory_rules`.

## Affected areas
- `assets/data/dress_requirements.v1.json` — `mandatory_rules` array in all 5 dress documents

## Step-by-step plan
For each of the 5 dresses, replace the single `"category": "Base_Accessories"` block in `mandatory_rules` with 3 separate blocks: `Belt`, `Socks`, `Footwear`. Values are preserved as-is from the original grouping.

| Dress | Belt logic | Footwear logic |
|-------|-----------|----------------|
| No.1, No.2 | leather_belt for both genders | men=leather_shoes_low_cut, ladies=court_shoes |
| No.3 | men=nylon_belt, ladies=leather_belt | men=leather_shoes_low_cut, ladies=court_shoes |
| No.4, No.5 | nylon_belt for both genders | leather_shoes_low_cut for both genders |

## Risks & rollback
- Low risk — `mandatory_rules` is human-readable doctrine metadata, not consumed by the resolver.
- Rollback: revert `assets/data/dress_requirements.v1.json` to previous state in git.

## Verification
1. `python3 -m json.tool assets/data/dress_requirements.v1.json` — JSON must be valid.
2. Confirm no dress has `"category": "Base_Accessories"` remaining.
3. Confirm each dress has exactly 3 new entries: Belt, Socks, Footwear.
4. `flutter analyze` — must be clean.
5. Re-seed Firestore when ready: `dart run tool/seed_firestore.dart <svc-account.json>`.

## CLAUDE.md sections to refresh
None — `mandatory_rules` is not referenced in CLAUDE.md.

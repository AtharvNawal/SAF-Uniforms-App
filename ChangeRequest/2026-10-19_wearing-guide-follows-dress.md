# Wearing Guide follows the active dress

- **Date:** 2026-10-19
- **Author:** Claude (agent)
- **Status:** executed (not device-verified)

## 1. Goal
With a No.4 profile, Ghost screen → "Start Wearing" still showed No.3
steps (No. 3 trousers / service shirt, nylon belt, medal ribbons, collar
rank insignias, lanyard). `WearingGuideScreen` was a fixed list of 9
No.3 steps that never read `profile.dressCode`. The guide must show only
the items of the active dress.

## 2. Scope
- In scope: build the guide's steps from the accessories resolved for
  the active dress (`dressAccessoriesByIdProvider(dressCode.requirementDocId)`
  — same source as the Wardrobe tab), plus the base garments.
- Optional accessories appear only if ticked in the Wardrobe for that
  dress (same rule `composeUniformModel` uses).
- Medal ribbons step: No.3 only, and only when `medalRowCount > 0`.
- Each step's tip comes from the accessory's doctrine `rules` text.
- Out of scope: voice narration, per-dress illustrations.

## 3. Affected areas
- New `lib/features/wearing_guide/domain/wearing_steps.dart` (pure
  step builder + ordering + tip picker).
- `lib/features/wearing_guide/presentation/screens/wearing_guide_screen.dart`.
- `lib/core/l10n/arb/app_{en,zh}.arb` (+ generated).
- New `test/features/wearing_guide/wearing_steps_test.dart`.

## 4. Step-by-step plan
1. Pure `buildWearingSteps(dressCode, split, profile)` → ordered
   `WearingStep` list (garments, inner shirt, socks, footwear, belt,
   insignia, name/country tags, badges, lanyard, headdress, cap badge).
2. Screen watches the profile + split; loading / error states; chip and
   garment labels show the dress code.
3. ARB strings for zones and per-dress garment labels.
4. Unit tests: No.4 has no No.3-only items; No.3 keeps its items;
   optional items gated by ticks.

## 5. Risks & rollback
- Tip text is now the doctrine sentence (longer than the old one-liners).
- No.1/2/5 have no doctrine-aligned accessories: guide shows the base
  garments only. Rollback: revert the files above.

## 6. Verification
- `flutter gen-l10n`, `flutter analyze`, `flutter test`.
- Device: No.4 profile → Ghost → Start Wearing shows No.4 items.

## 7. CLAUDE.md updates required
- §4 source tree: `wearing_guide/` entry (domain file, dynamic steps).
- §8: Wearing Guide note.

## 8. Execution notes (2026-10-19)
- `flutter gen-l10n`; `flutter analyze` clean; `flutter test` 172/172
  (new `test/features/wearing_guide/wearing_steps_test.dart` runs every
  branch × men/ladies for No.4 against the real seed JSON and asserts no
  No.3-only categories, no medals step, chest rank tab + Singapore tag +
  boots present).
- No.5 in the seed data does resolve belt / socks / shoes, so the
  "pending doctrine" note keys off "nothing beyond belt/socks/footwear",
  not "empty".
- Not yet run on a device.

## 9. Follow-up (2026-10-19, same day) — user re-reported with the No.4 PDF
- **Dress pick could silently revert to No.3.** `UniformProfileNotifier.hydrate`
  replaced the whole state on every Firestore snapshot *and* cancelled the
  pending debounced write. A snapshot arriving within 500 ms of tapping No.4
  reverted the dress to No.3 and the pick was never saved, so Ghost and the
  Wearing Guide both read No.3. `hydrate` now ignores snapshots while a local
  edit is pending (`uniform_provider.dart`); the pending write's own snapshot
  re-syncs. Tests in `uniform_provider_test.dart`.
- **Badge steps restored.** The first pass dropped the old "SAF Badges" step.
  No.3: one SAF-badges step when any badge is selected. No.4 (SAF No.4 Dress
  PDF): chest badges (Army above left pocket; Navy 3 cm above; RSAF/DIS above
  the Singapore tag) and sleeve badges (marksman / sniper / IPPT, left sleeve;
  Army 1 cm below seam + IPPT 0.5 cm below; RSAF 5 mm below unit patch; DIS
  ~0.4 cm below patch).
- Printed No.4 guides from the seed data and compared with the PDF (Army:
  olive belt + combat boots; Navy: grey inner shirt + mid-cut safety boots;
  RSAF: blue inner T + safety boots + unit patch; DIS: grey inner T + safety
  boots + service patch). `flutter analyze` clean, `flutter test` 179/179.

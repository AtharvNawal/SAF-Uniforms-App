# No.3 + No.4 complete for men, ladies, maternity and Sikh

- **Date:** 2026-10-19
- **Author:** Claude (agent)
- **Status:** executed (not device-verified)

## 1. Goal
Every No.3 and No.4 combination (Army / Navy / RSAF / DIS × men / ladies
/ maternity × Sikh, every rank) lists the right accessories from the two
SAF Dress PDFs, each with an accessory picture and a placement picture.

## 2. Audit (Dart resolver over the seed data, every rank)
No.4 was complete. No.3 had:
1. Maternity resolved as **men** (beret, nylon belt, men's shoes). The TS
   port already treats maternity as ladies.
2. Navy / RSAF ladies at enlisted / specialist ranks got **no hat**: their
   data keys (`specialist_rating_cadet_me_trainee_me1_me2`,
   `specialist_me1_me2_cadet_me_trainee`) were never matched. Lady OCTs got
   the officers' hat (Navy / RSAF PDFs: cadets wear the specialist hat).
   RSAF `bg_me8_above` ladies hat never picked.
3. No **epaulettes** for Army / Navy / RSAF (no data key); DIS gave them to
   ladies too (PDF pictures: ladies wear collar pins / gorgettes, not
   epaulettes). No **collar rank pins** (lady officers / WOs) or
   **gorgettes** (lady OCT / ME trainees) anywhere.
4. Navy Sikh `sikh_3wo_me3_above` (white turban) never picked.
5. Navy / RSAF **cap embellishment** (service-hat peak) given to men, who
   wear berets.
6. BG+: DIS `bg_me8_radm_above`, RSAF `bg_me8_above_beret` /
   `_service_hat` cap badges never picked.
7. No.3 never offered medal ribbons / SAF / sleeve / foreign badges.

## 3. Scope
- In: Dart `DressAccessoryResolver` fixes 1-6; No.3 `branch_overrides`
  gain `epaulettes` (Army/Navy/RSAF), `ladies_rank` (all) and
  `additional_optional` badges (all); Wearing Guide de-duplicates the
  medal / badge steps against those optional items; re-seed Firestore.
- Out: the TypeScript resolver used by `composeUniformModel` stays as is
  (changing it would attach new GLBs — placeholder cubes for items with no
  model — and needs a Functions deploy). Recorded as a divergence.

## 4. Steps
1. Resolver: `_isLadies` (female + maternity); ladies-hat tier pick;
   Navy white turban; epaulettes `{standard, cadet_trainee|me_trainee}` for
   men; `ladies_rank`; embellishment ladies-only; BG cap-badge keys.
2. Data edits; tests (every combination) against the seed JSON.
3. Seed, analyze, test, APK.

## 5. Risks & rollback
Wardrobe checks keyed by accessory id are unaffected. Rollback: revert
resolver + JSON, re-seed.

## 6. Verification
Audit re-run (no combination missing headdress / rank / belt / footwear /
socks; every item has a picture), `flutter analyze`, `flutter test`, APK.

## 7. CLAUDE.md updates
§5.2 resolver notes; §8 "known No.3 data quirks" (now fixed) and the
Dart/TS divergence.

## 8. Execution notes (2026-10-19)
- Also found + fixed: Navy / RSAF lady MAJ–SLTC / SWO–CWO got no cap
  embellishment (tier key unhandled).
- Wearing Guide: a ticked `medal_ribbons` / `saf_badges_chest` /
  `skill_badges_sleeve` no longer repeats the profile-driven step (this
  also affected No.4).
- Re-audit: 0 incomplete combinations; every item has a picture. Still
  no accessory photo for the five badge-group entries (placement only —
  in the PDFs the badges are ~20 px, crops would be unreadable) and no
  placement for 12 No.4 items the PDF never shows worn.
- `flutter analyze` clean; `flutter test` 197/197; seeded (dress
  requirements 5, accessory library 113); release APK rebuilt.

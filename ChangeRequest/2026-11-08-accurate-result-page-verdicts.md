# Accurate Result-Page Verdicts

- **Date:** 2026-11-08
- **Author:** Copilot
- **Status:** verified

## 1. Goal
Make the uniform-check result page clearly and accurately report every evaluated
accessory: correctly placed items, misplaced items, missing items, items that
could not be verified from the capture, and items that still require a visual
check. Preserve the existing geometry service as the source of truth rather
than presenting unsupported certainty.

## 2. Scope
- In scope:
  - Improve the Flutter `/check_uniform` result model presentation.
  - Show a complete per-item verdict list, including correct items and all
    non-verifiable categories.
  - Surface useful evidence already returned by the service: presence,
    placement, confidence, visibility, instruction, measured error, and
    frame agreement.
  - Add focused widget/model tests for verdict grouping and displayed evidence.
- Out of scope:
  - Replacing the existing CV models or geometry pipeline.
  - Claiming GLB-derived accuracy that the current service cannot measure.
  - Integrating heavyweight new Hugging Face models or BlenderProc in this
    change.

## 3. Affected areas
- `lib/features/ar_scanner/domain/entities/uniform_check_result.dart`
- `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart`
- Tests mirroring the affected model/presentation paths.
- `CLAUDE.md` result-page and AR scanner documentation.

## 4. Step-by-step plan
1. Inspect the current scorecard and result parsing behavior.
2. Add small, typed presentation helpers for complete verdict grouping and
   human-readable evidence.
3. Update the scorecard to render every accessory exactly once with an explicit
   status and supporting evidence.
4. Add or update focused tests.
5. Run formatting, Flutter analysis, and targeted/full Flutter tests as
   available.
6. Update this plan to `verified` with the actual validation results and refresh
   the relevant `CLAUDE.md` section.

## 5. Risks & rollback
- Risk: changing scorecard grouping could hide an item or misclassify an
  uncertain result. Mitigation: derive all sections from the full accessory list
  and add uniqueness/grouping tests.
- Risk: generated Freezed files may need regeneration if the entity changes.
  Mitigation: avoid changing the serialized entity shape unless required.
- Rollback: revert the scorecard/model/test changes and leave the backend
  contract unchanged.

## 6. Verification
- `dart format` or the repository formatter on changed Dart files.
- `flutter analyze`.
- `flutter test` with focused tests first, then the full suite.
- `flutter pub run build_runner build --delete-conflicting-outputs` if
  annotations or generated model inputs are changed.
- Device smoke testing is recommended for the scanner result screen when a
  reachable `cv-service` and camera device are available.

Verification completed:
- `dart format` on changed Dart files.
- Focused scanner model/repository tests passed.
- `flutter analyze` passed with no issues.
- Full `flutter test` passed: 199 tests.
- No code generation was required because the Freezed entity shape was
  unchanged.
- Physical Android/iOS smoke testing was not available in this environment.

## 7. CLAUDE.md updates required
- Refresh the AR scanner result-card description in §5.10 and the relevant
  known-gap/result-page notes in §8 after implementation.

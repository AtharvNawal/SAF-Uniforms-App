# Uniform Identity Gate

- **Date:** 2026-11-08
- **Author:** Copilot
- **Status:** executed

## 1. Goal
Prevent civilian clothing or an unidentified outfit from receiving an
accessory-based SAF compliance score. Uniform identity must pass before GLB
anchor placement and accessory verdicts are calculated.

## 2. Scope
- In scope:
  - Add a conservative identity gate using the existing segmentation evidence.
  - Return explicit `INVALID_ATTIRE`, `WRONG_UNIFORM`, and
    `UNABLE_TO_VERIFY` statuses without a normal score.
  - Include uniform-identification evidence in API responses and Flutter
    results.
  - Render the gate outcome prominently on the result page.
  - Add backend and Flutter parsing tests.
- Out of scope:
  - Claiming SigLIP, DINOv2, Grounding DINO, SAM 2, or FASHN accuracy without
    model installation and validation data.
  - Training a classifier from synthetic-only data.
  - Removing the existing accessory/geometry pipeline for verified attire.

## 3. Affected areas
- `cv-service/detectors/uniform_identity.py`
- `cv-service/api/pipeline.py`
- `cv-service/api/response_schema.py`
- `cv-service/api/main.py`
- `cv-service/api/burst.py`
- Related CV and Flutter tests/models/result page.
- `CLAUDE.md`

## 4. Step-by-step plan
1. Define the identity result and conservative thresholds based on existing
   segmentation classes.
2. Run the gate after person detection and segmentation, before pose/anchor
   projection and accessory detection.
3. Return a scoreless, explicit identity-failure response.
4. Preserve identity metadata through burst aggregation.
5. Parse and display identity status in Flutter.
6. Add tests for invalid, uncertain, verified, and score suppression behavior.
7. Run focused tests and document the validation limits.

## 5. Risks & rollback
- A conservative gate may classify low-quality genuine uniforms as unable to
  verify; this is safer than a false compliance approval and is surfaced as a
  retake/verification state.
- Synthetic-only segmentation is not a validated real-photo classifier; the
  response will label the gate as heuristic and will not claim model accuracy.
- Rollback by reverting the gate and additive response/UI changes.

## 6. Verification
- Focused CV identity/response tests.
- Existing CV tests where dependencies are available.
- Flutter result model tests and `flutter analyze`/`flutter test`.
- No real-photo precision/recall claim until labelled validation images exist.

Verification completed:
- `python3 -m pytest cv-service/tests/test_uniform_identity.py`: 3 passed.
- Python bytecode compilation passed for the changed backend modules.
- `flutter analyze`: passed.
- Focused Flutter scanner tests: 14 passed.
- Full CV suite remains unavailable in the active environment because existing
  dependencies such as `cv2` and `ultralytics` are missing; no dependency
  manifest was changed.
- No real-photo/device accuracy claim is made; the gate is conservative and
  synthetic-model dependent.

## 7. CLAUDE.md updates required
- Update §5.10 to document the mandatory identity gate and its conservative,
  synthetic-only limitation.
- Update the AR scanner result-page description to include identity status and
  score suppression.

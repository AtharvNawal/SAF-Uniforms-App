# Official SAF rule-engine configuration

- **Date:** 2026-11-08
- **Author:** Copilot
- **Status:** verified

## 1. Goal
Make the `/check_uniform` pipeline select and validate service-specific, dress-specific SAF rules from explicit configuration rather than relying on an implicit Army-centric rule path.

## 2. Scope
- In scope:
  - Add a validated rule registry for the supported Army, Navy, RSAF and DIS No.3/No.4 inspection profiles.
  - Preserve the existing geometry and detector pipeline while selecting the exact uniform specification and rule source for each profile.
  - Add tests for profile selection, invalid profiles, conditional Sikh/gender/rank inputs, and response status handling.
  - Document which official-rule details are represented and which remain unavailable without the source PDFs or trained detectors.
- Out of scope:
  - Inventing measurements absent from the supplied text.
  - Claiming visual verification for accessories without detector/reference support.
  - Training new vision models or adding unlabelled PDF-derived measurements.
  - Replacing existing endpoints or Firebase integration.

## 3. Affected areas
- `cv-service/uniforms.py` and rule configuration modules.
- `cv-service/rules/` configuration and selection/validation helpers.
- `cv-service/api/pipeline.py` and response metadata.
- `cv-service/tests/`.
- `CLAUDE.md`.

## 4. Step-by-step plan
1. Inventory the current uniform registry, rule files, and pipeline parameters.
2. Introduce a typed inspection-profile registry that validates service, dress, gender, rank category, personnel category and Sikh applicability.
3. Make rule loading/selecting explicit and reject mismatched service/dress combinations before analysis.
4. Preserve existing verdict semantics, including `UNCERTAIN`, `INVALID_ATTIRE`, `WRONG_UNIFORM`, and scoreless identity failures.
5. Add focused tests and run the available backend and Flutter validation.
6. Update `CLAUDE.md` and mark this plan verified only for the checks that can run in the current environment.

## 5. Risks & rollback
- Existing callers may use shorthand uniform identifiers; retain backward-compatible normalization.
- Some official rules are diagram-only or lack trained detector classes; represent them as uncheckable/conditional rather than fabricating a pass.
- Roll back by reverting this change set; no Firestore schema or endpoint contract removal is planned.

## 6. Verification
- `PYTHONPATH=cv-service python3 -m pytest cv-service/tests/test_rule_selection.py -q` — 6 passed.
- Python syntax compilation passed for the changed backend modules.
- `flutter analyze` — clean.
- `flutter test` — 199 passed.
- The broader CV suite remains blocked in this environment because the active Python environment does not provide `cv2`; no full backend-suite result is claimed.
- `git diff --check` is required before commit.

## 7. CLAUDE.md updates required
- Refresh the cv-service rule-selection and supported-uniform documentation.
- Document the explicit limitations around PDF source fidelity and detector coverage.

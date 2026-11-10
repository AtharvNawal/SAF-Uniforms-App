# Uniform evidence aggregation and visibility consistency

- **Date:** 2026-11-09
- **Author:** Copilot
- **Status:** executed

## 1. Goal
Ensure invalid attire never receives accessory verdicts, every applicable rule has exactly one canonical result, visibility states consistently prevent false `MISSING` results, and burst aggregation preserves profile confidence separately from person confidence.

## 2. Scope
- In scope:
  - Canonicalize accessory entries by rule/accessory identity before summary calculation.
  - Add explicit `UNVERIFIED`/`OUT_OF_FRAME` handling to aggregation.
  - Expose separate person, uniform, and accessory confidence fields.
  - Preserve the existing uniform gate and burst disagreement behavior.
  - Add regression tests for inconsistent counts and correlated frame evidence.
- Out of scope:
  - Training a custom YOLO detector without labelled data.
  - Claiming automated RSAF badge verification where no detector/reference evidence exists.
  - Changing official rule measurements or endpoint authentication.

## 3. Affected areas
- `cv-service/api/response_schema.py`, `cv-service/api/burst.py`, `cv-service/api/pipeline.py`.
- `cv-service/tests/`.
- Flutter result model/UI only if the existing response shape requires a compatible display adjustment.
- `CLAUDE.md`.

## 4. Step-by-step plan
1. Trace current response and burst aggregation counts.
2. Introduce canonical rule identity and visibility-aware status normalization.
3. Ensure invalid-attire responses remain scoreless and accessory-free.
4. Add confidence namespace separation and diagnostics.
5. Add focused regression tests.
6. Run backend focused tests and full Flutter validation.

## 5. Risks & rollback
- Deduplication must not hide genuinely distinct rules; use stable rule/accessory IDs where available.
- Existing clients may rely on current status strings; preserve them and add fields.
- Roll back by reverting this plan’s code changes.

## 6. Verification
- Python syntax compilation and `git diff --check` passed.
- Focused pytest collection was attempted but the active environment lacks
  `ultralytics`; the existing project environment is required for execution.
- Full Flutter validation was not required because this slice only changes the
  Python service response contract.
- Flutter analyze and tests.
- `git diff --check`.
- No detector accuracy or latency improvement claimed without labelled data/benchmark measurements.

## 7. CLAUDE.md updates required
- Documented canonical aggregation, confidence separation, and visibility semantics.

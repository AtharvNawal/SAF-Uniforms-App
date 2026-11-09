# Cascaded inference optimization

- **Date:** 2026-11-09
- **Author:** Copilot
- **Status:** verified

## 1. Goal
Reduce avoidable inspection latency while preserving conservative uniform/accessory decisions and explicit `UNVERIFIED` outcomes.

## 2. Scope
- In scope:
  - Add per-stage latency and request-id diagnostics.
  - Cache immutable rule/anchor configuration in-process.
  - Make optional Hugging Face evidence lazy and conditional.
  - Improve burst processing by selecting a sharp primary frame and retaining correlated-frame disagreement metadata.
  - Add focused tests and a benchmarkable diagnostics contract.
- Out of scope:
  - Downloading or deploying new model weights.
  - Claiming speed or accuracy improvements without measurements.
  - TensorRT/ONNX conversion before a compatible production GPU and accuracy baseline exist.
  - Replacing existing endpoint contracts or Flutter screens.

## 3. Affected areas
- `cv-service/api/pipeline.py`, `cv-service/api/main.py`, `cv-service/api/burst.py`.
- `cv-service/rules/` loaders and reference cache.
- `cv-service/detectors/hf_evidence.py`.
- `cv-service/tests/`.
- `CLAUDE.md`.

## 4. Step-by-step plan
1. Trace current single-photo and burst execution paths.
2. Add a reusable timing/request context with no inference behavior changes.
3. Cache immutable rule and anchor reads while preserving test isolation.
4. Add sharpness-based primary-frame selection for bursts and explicit correlated-frame metadata.
5. Keep deep evidence opt-in and expose whether it ran.
6. Test diagnostics, cache behavior, frame selection, and existing identity protections.
7. Run Python focused checks, Flutter analysis/tests, and document unmeasured targets.

## 5. Risks & rollback
- Caches can become stale after rule-file edits; cache keys include file modification time and can be cleared explicitly.
- Burst primary-frame selection must not turn a cropped/occluded frame into a pass; all frame errors remain visible.
- Rollback is a code revert; no schema or deployment changes are required.

## 6. Verification
- Python syntax compilation passed for changed modules.
- Focused CV tests passed for diagnostics/cache behavior and existing identity protections.
- `flutter analyze` and `flutter test` passed.
- `git diff --check` passed.
- No before/after latency benchmark is claimed because no representative deployment dataset was available.

## 7. CLAUDE.md updates required
- Document staged diagnostics, reference caching, and burst primary-frame behavior.
- Document that optimization is not an accuracy claim and deep models remain opt-in.

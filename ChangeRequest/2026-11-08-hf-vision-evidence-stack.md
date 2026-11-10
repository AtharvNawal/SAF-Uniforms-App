# Optional Hugging Face evidence stack

- **Date:** 2026-11-08
- **Author:** Copilot
- **Status:** verified

## 1. Goal
Strengthen the uniform identity and accessory evidence pipeline with optional, lazy-loaded Hugging Face model adapters while preserving the conservative rule/geometry gate and keeping the service runnable without downloaded model weights.

## 2. Scope
- In scope:
  - Add the requested Python ML dependencies to the CV service manifest.
  - Add a model configuration module and lazy adapters for SigLIP 2, Florence-2, and DINOv2.
  - Integrate optional uniform-classification evidence into the identity gate.
  - Preserve the existing segmentation-only fallback when models or weights are unavailable.
  - Add tests for deterministic evidence/status logic and unavailable-model behavior.
- Out of scope:
  - Downloading multi-gigabyte weights during this change.
  - Claiming pretrained models are SAF-accurate without labelled validation data.
  - Automatically making Grounding DINO, SAM 2, SAM 3D Body, FASHN, or Depth Anything production dependencies without a tested adapter and deployment budget.
  - Replacing existing endpoint contracts or Flutter behavior.

## 3. Affected areas
- `cv-service/requirements.txt`.
- `cv-service/config.py` and new detector/model-adapter modules.
- `cv-service/detectors/uniform_identity.py` and `api/pipeline.py`.
- `cv-service/tests/`.
- `CLAUDE.md`.

## 4. Step-by-step plan
1. Inventory current identity, segmentation, and detector interfaces.
2. Add pinned/compatible optional ML dependencies and environment-controlled model IDs.
3. Implement lazy model loading so imports and normal tests do not require weights.
4. Produce structured model evidence and combine it conservatively with segmentation; never allow head location alone to verify a beret or uniform.
5. Add focused tests covering missing dependencies, low-confidence evidence, and valid/invalid identity outcomes.
6. Run syntax, focused CV tests, Flutter analysis/tests, and update documentation with the real-data limitations.

## 5. Risks & rollback
- Transformers and torch increase deployment size and cold-start cost; lazy loading and opt-in configuration limit that risk.
- Pretrained general-domain models may misclassify SAF clothing; evidence below the configured threshold must abstain.
- Rollback is a manifest/code revert; the existing segmentation-only path remains available.

## 6. Verification
- Python syntax compilation passed for changed modules.
- Focused CV tests: 11 passed.
- `flutter analyze` — clean.
- `flutter test` — 199 passed.
- `git diff --check` — clean.
- Full model inference was not run: weights are intentionally not downloaded and
  `CV_SERVICE_HF_EVIDENCE_ENABLED` remains disabled by default.

## 7. CLAUDE.md updates required
- Document optional Hugging Face adapters, model IDs, lazy loading, and the requirement for labelled SAF/civilian validation before enabling automatic PASS decisions.

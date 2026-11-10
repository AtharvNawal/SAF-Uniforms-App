# GLB Reference Manifest Engine

- **Date:** 2026-11-08
- **Author:** Copilot
- **Status:** verified

## 1. Goal
Create a reusable, machine-readable GLB inspection/reference manifest that
distinguishes scene nodes, meshes, materials, transforms, named placement
anchors, and actual accessory geometry. This will give the compliance pipeline a
stable inventory without assuming that every marker node is an accessory mesh.

## 2. Scope
- In scope:
  - Extract manifests from one GLB or a directory of GLBs.
  - Record scene hierarchy, world transforms, mesh bounds/counts, material and
    texture presence, skin/animation metadata, and known SAF anchor nodes.
  - Mark transform-only nodes separately from nodes with geometry.
  - Add deterministic tests using the repository GLBs and a small synthetic scene.
  - Document how the manifest feeds later detector/reference work.
- Out of scope:
  - Adding heavyweight AI models.
  - Training or generating synthetic photographs.
  - Changing the Flutter result contract or claiming real-photo accuracy.
  - Automatically classifying arbitrary artist meshes as doctrine-approved items.

## 3. Affected areas
- `cv-service/utils/extract_glb_manifest.py`
- `cv-service/tests/test_extract_glb_manifest.py`
- `tool/extract_glb_reference.py`
- `CLAUDE.md`

## 4. Step-by-step plan
1. Reuse the canonical socket list and existing trimesh conventions.
2. Implement single-file and directory manifest extraction with explicit
   geometry/marker separation.
3. Add a CLI for writing a JSON manifest.
4. Add tests for real model metadata, anchors, transform-only markers, and
   deterministic JSON-safe output.
5. Run formatting/tests and update documentation/status.

## 5. Risks & rollback
- GLB exporters differ in optional metadata; missing skin/animation metadata must
  be reported as zero/empty rather than treated as an error.
- World-transform semantics must remain consistent with `extract_anchors.py`;
  tests will compare the shared anchor coordinates.
- Rollback is limited to the new utility, CLI, tests, and documentation.

## 6. Verification
- `.venv-tools/bin/pytest cv-service/tests/test_extract_glb_manifest.py`
- `.venv-tools/bin/pytest cv-service/tests/`
- `git diff --check`
- Run the CLI against the four reference body GLBs and inspect the generated
  manifest summary.

Verification completed:
- `python3 -m pytest cv-service/tests/test_extract_glb_manifest.py`: 5 passed.
- `python3 tool/extract_glb_reference.py --directory assets/3d/bodies ...`:
  successfully extracted all 6 available body GLBs.
- `git diff --check`: passed.
- The full CV suite could not be collected because the active system Python
  environment lacks the existing `cv2` dependency; the repository's
  `.venv-tools` launcher also points at a stale path and was not modified.

## 7. CLAUDE.md updates required
- Refresh the cv-service/reference-geometry notes in §5.10 and the operator
  tooling list to describe the manifest extractor and its marker-versus-mesh
  distinction.

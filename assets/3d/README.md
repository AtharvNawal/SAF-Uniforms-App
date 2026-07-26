# `assets/3d/` — 3D asset library (local mirror)

This directory is the local source-of-truth for the GLB asset library
that the `composeUniformModel` Cloud Function reads from. The
[`tool/upload_models.py`](../../tool/upload_models.py) script mirrors
this tree into `gs://saf-uniforms.firebasestorage.app/models/**`.

```
assets/3d/
├── placeholder.glb              ← grey-cube fallback for any missing asset
├── bodies/                      ← rigged humanoid GLBs (Phase 1: placeholders)
│   ├── male_apose.glb
│   ├── female_apose.glb
│   └── female_maternity_apose.glb
├── uniforms/                    ← (empty in Phase 1; freelance artist deliveries
│                                  drop here as `<branch>_<dress>_<gender>.glb`,
│                                  e.g. `dis_no3_male.glb`)
└── accessories/                 ← (empty in Phase 1; one .glb per accessory_library
                                   doc id, e.g. `army_beret.glb`)
```

## Phase 1: placeholder bodies (current state)

The three body GLBs are **algorithmically generated** by
[`tool/generate_placeholder_bodies.py`](../../tool/generate_placeholder_bodies.py)
using `trimesh`. They compose simple primitives (head sphere, torso
box, arms, legs, beret, name-tag patch, medal ribbons) into a visibly
humanoid figure per variant — broad-shouldered male, narrower
skirt-wearing female, rounded-belly maternity.

These are **NOT** doctrine-accurate. They exist so the demo runs
end-to-end while real 3D-artist work happens in parallel.

To regenerate (e.g. after tweaking proportions in the generator):

```bash
.venv-tools/bin/python tool/generate_placeholder_bodies.py
```

## Phase 2: real bodies

Replace the placeholders with proper MakeHuman + Blender authored GLBs
following the recipe in
[`docs/3d-body-authoring.md`](../../docs/3d-body-authoring.md). Use the
same filenames; the Cloud Function looks them up by exact name.

## Uniforms + accessories

These are commissioned from freelance 3D artists. The artist brief is
in [`docs/3d-body-authoring.md`](../../docs/3d-body-authoring.md) (the
"named anchor sockets" section). Drop their deliveries into
`uniforms/` or `accessories/` with the conventional filenames:

- Uniforms: `<branch>_<dress>_<gender>.glb` — e.g. `army_no3_male.glb`,
  `dis_no3_female.glb`. Maternity uniforms use `_female_maternity` suffix.
- Accessories: `<accessory_id>.glb` where the id matches the
  `accessory_library` Firestore doc id (e.g. `army_beret.glb`,
  `dis_cap_badge_col_me7.glb`, `name_tag.glb`).

The Cloud Function picks them up automatically on the next
`composeUniformModel` call once they're uploaded — no app or
function-side code changes needed.

## Upload

```bash
GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \
  python3 tool/upload_models.py \
    --bucket saf-uniforms.firebasestorage.app
```

The script is idempotent (per-object SHA-256 metadata check) so reruns
only push files that have actually changed. Use `--dry-run` to preview,
or `--only 'bodies/*'` to limit a run.

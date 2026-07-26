# 3D Body Authoring Recipe — MakeHuman + Blender

This doc is the deterministic recipe for producing the three rigged
body GLBs that drive the SAF Uniforms 3D pipeline:

```
assets/3d/bodies/male_apose.glb
assets/3d/bodies/female_apose.glb
assets/3d/bodies/female_maternity_apose.glb
```

It captures the slider values, rig settings, and Blender post-processing
steps so any future contributor can regenerate the bodies byte-identical
(modulo Blender's non-deterministic compression) without guessing.

The current bodies in `assets/3d/` are **algorithmically-generated
placeholders** produced by [`tool/generate_placeholder_bodies.py`](../tool/generate_placeholder_bodies.py).
They are visibly humanoid but anatomically rough — the goal is to ship
the demo end-to-end while the real authoring work happens in parallel.
When the real bodies are ready, drop them in with the same filenames
and run `tool/upload_models.py` — no other code changes required.

---

## 0. Prerequisites

| Tool | Version | License | Where |
|---|---|---|---|
| **MakeHuman Community** | 1.3.0 or newer | AGPL (tool) / CC0 (output mesh) | http://www.makehumancommunity.org/ |
| **Blender** | 4.0 LTS or newer | GPL | https://www.blender.org/download/ |
| **MPFB2** plugin for Blender | latest | GPL | https://github.com/makehumancommunity/mpfb2 |

Install MakeHuman first, then Blender, then drop the MPFB2 zip into
Blender's Edit → Preferences → Add-ons → Install. Enable the addon
and point it at your MakeHuman install directory.

---

## 1. Authoring the three archetypes in MakeHuman

All three bodies start from the **same MakeHuman base mesh** — only
slider values differ. This guarantees identical topology + rig + UV
layout across variants, which means accessory GLBs that fit one body
fit all three.

Open MakeHuman → File → New, then for each archetype set the sliders:

### Male (`male_apose.glb`)

| Category | Slider | Value |
|---|---|---|
| Macro → Gender | Gender | 1.0 (full male) |
| Macro → Age | Age | 0.55 (young adult, ~28 yrs) |
| Macro → Race | African / Asian / Caucasian | leave at neutral 0.33 each |
| Macro → Muscle | Muscle | 0.55 |
| Macro → Weight | Weight | 0.50 |
| Macro → Height | Height | 0.55 (≈ 1.75 m) |
| Macro → Proportions | Proportions | 0.50 |
| Body → Torso | Torso muscle | 0.55 |
| Body → Torso | Stomach | 0.40 |

### Female (`female_apose.glb`)

| Category | Slider | Value |
|---|---|---|
| Macro → Gender | Gender | 0.0 (full female) |
| Macro → Age | Age | 0.50 |
| Macro → Race | (neutral) | 0.33 / 0.33 / 0.33 |
| Macro → Muscle | Muscle | 0.40 |
| Macro → Weight | Weight | 0.45 |
| Macro → Height | Height | 0.40 (≈ 1.65 m) |
| Macro → Proportions | Proportions | 0.50 |
| Body → Breast | Cup size | 0.45 |

### Female maternity (`female_maternity_apose.glb`)

Start from the female archetype above (same height, same shoulders),
then enlarge the abdomen for the rounded silhouette in Picture B-7.

| Category | Slider | Value |
|---|---|---|
| (all of the female archetype values) |  |  |
| Body → Stomach | Pregnancy | **0.85** ← key change |
| Body → Stomach | Stomach volume | 0.65 |

### Pose

For all three:
- **Pose preset:** `tpose`. We want a strict A-pose actually, so after
  applying T-pose, manually rotate the upper-arm bones inward by ~10°
  (or use any community A-pose preset). Why A-pose: shoulder rigging
  is cleaner under a uniform shirt; sleeve insignia placement reads
  predictably.

### Rig

- **Skeleton tab → Rig type:** `Game-Engine Rig`
  - This is a clean ~30-bone rig that exports to glTF without
    secondary issues. The other rigs (CMU, default) have too many
    bones for our purposes.
- **Weights:** keep MakeHuman's auto-generated weights.

### Materials

- **Skin tab → Material:** young_caucasian_average. (Skin tone is
  irrelevant — the head will be partly covered by the beret/turban
  and the visible portion is small. We pick one consistent tone for
  all three archetypes.)
- **Eyes / Hair / Teeth:** default presets are fine.

### Export from MakeHuman

File → Export →
- **Format:** `Wavefront obj` is fine, but **prefer the MPFB2 path** below
  (skip the MakeHuman exporter entirely and pipe directly into Blender).

---

## 2. MPFB2 → Blender: import the MakeHuman character

In Blender:

1. Open a new file. Delete the default cube + light + camera.
2. `N` panel → MPFB tab → "Create human from MakeHuman".
3. Point at the running MakeHuman instance and pick the slider preset
   you just dialled in. The character imports as a fully-rigged armature
   with mesh as a child.
4. With the armature selected: Object → Apply → All Transforms.
5. With the mesh selected: Edit → Apply → All Transforms.

---

## 3. Blender post-processing (the "named anchor sockets" recipe)

The CF expects each body GLB's armature to have eleven named socket
bones in addition to the standard humanoid skeleton. These are empty
bones at known offsets that the future merge step will use as
attachment points for the uniform / accessory GLBs.

### Add the eleven socket bones

In Edit Mode on the armature, add child bones with these exact names
and positions. Each bone is parented to the armature bone listed in the
"parent" column with a length of 0.02 m and zero head/tail rotation
relative to its parent.

| Bone name | Parent bone | Head offset (m, local) |
|---|---|---|
| `head_top` | head | (0.000,  0.110, 0.000) |
| `cap_band_front` | head | (0.000,  0.040, 0.085) |
| `left_collar_tip` | spine_03 (chest) | (-0.060,  0.130, 0.090) |
| `right_collar_tip` | spine_03 (chest) | ( 0.060,  0.130, 0.090) |
| `left_chest_pocket` | spine_03 | (-0.090,  0.030, 0.105) |
| `right_chest_pocket` | spine_03 | ( 0.090,  0.030, 0.105) |
| `left_shoulder_seam` | clavicle_l | ( 0.000,  0.020, 0.000) |
| `right_shoulder_seam` | clavicle_r | ( 0.000,  0.020, 0.000) |
| `left_sleeve_upper` | upperarm_l | (-0.005, -0.055, 0.000) |
| `right_sleeve_upper` | upperarm_r | ( 0.005, -0.055, 0.000) |
| `belt_center` | spine_01 (pelvis) | ( 0.000, -0.140, 0.090) |

After adding, switch to Pose Mode → select the new bones → Bone
Properties → Deform: **disable** (these are sockets, not deformers).

> **Quick check:** with the armature selected in Object mode, run
> `Window → Toggle System Console` (Windows) / `~` (macOS Terminal),
> then `bpy.context.active_object.data.bones.keys()` should list all
> the standard MakeHuman bones plus the 11 names above.

### Name-tag mesh contract (Phase 2 bake target)

The Phase-2 server merger composites the user's surname onto a designated
material's base-color texture using `sharp`, then patches the new bytes
back into the GLB. For the merger to find the right texture, the body GLB
must expose:

| Object | Required name | Purpose |
|---|---|---|
| Mesh node | `name_tag` | The mesh that will display the surname. Typically a flat ~1cm × 4cm patch on the right chest. |
| Material | `name_tag_mat` | A single PBR material assigned to the `name_tag` mesh. |
| Base-color texture | (any) | The bake target. Phase-2 reads `material.getBaseColorTexture()`, composites text onto its bytes, and writes back via `texture.setImage(...)`. |

Recommended texture size: **1024 × 256**. The text is rendered at ~55% of
the texture height, so 1024 × 256 leaves enough headroom for surnames up
to ~12 characters at readable resolution. Smaller textures (256×64) are
acceptable but produce visibly soft text on close zoom.

If the body GLB ships **without** a `name_tag` mesh + `name_tag_mat`
material, the merger logs a `name tag bake: baked=false` warning and
the rest of the composition still proceeds — the user just won't see
their surname on the model.

The placeholder body generator
[`tool/generate_placeholder_bodies.py`](../tool/generate_placeholder_bodies.py)
already satisfies this contract (`_name_tag_textured` builds a 1024×256
white-background PBR material named `name_tag_mat` on the chest patch),
so engineering can develop and verify the bake step end-to-end before
real artist GLBs land.

### Hair / scalp split for Sikh-turban swappability

The default MakeHuman head includes hair geometry that would z-fight
against a Sikh turban accessory. Split the head mesh into two named
sub-meshes so the CF can hide the hair when a turban is mounted:

1. Select the head mesh, enter Edit Mode.
2. Box-select the hair vertices (top of skull, hair shells).
3. Press `P` → "Selection". This creates a new mesh.
4. Rename the resulting mesh objects: head → `head`, the new one → `hair`.

The composeUniformModel CF will (in Phase 2) hide the `hair` node
whenever a turban accessory is attached at `head_top`.

---

## 4. Export to GLB

File → Export → glTF 2.0 (.glb), with these settings:

| Section | Setting | Value |
|---|---|---|
| Format | Format | `glTF Binary (.glb)` |
| Include | Selected Objects | **off** (export the whole scene) |
| Include | Custom Properties | **on** (preserves bone metadata) |
| Transform | +Y Up | **on** |
| Geometry | Apply Modifiers | **on** |
| Geometry | UVs / Normals / Tangents | **on** for all three |
| Geometry | Vertex Colors | leave at "MATERIAL" |
| Geometry | Materials | "Export" |
| Geometry | Images | "Automatic" |
| Geometry | Compression (Draco) | **off** (we apply Draco server-side) |
| Animation | Animation | **off** (these are static A-pose bodies) |
| Animation | Skinning | **on** |

Save to:
- `assets/3d/bodies/male_apose.glb`
- `assets/3d/bodies/female_apose.glb`
- `assets/3d/bodies/female_maternity_apose.glb`

---

## 5. Validate before upload

Run the same parse the production CF does:

```bash
cd functions
node -e "
import('@gltf-transform/core').then(async ({ NodeIO }) => {
  const { readFile } = await import('fs/promises');
  const io = new NodeIO();
  for (const f of [
    '../assets/3d/bodies/male_apose.glb',
    '../assets/3d/bodies/female_apose.glb',
    '../assets/3d/bodies/female_maternity_apose.glb',
  ]) {
    const bytes = await readFile(f);
    const doc = await io.readBinary(new Uint8Array(bytes));
    console.log(f, 'meshes=', doc.getRoot().listMeshes().length);
  }
});
"
```

Each body should:
- Parse without errors.
- Report 1–5 meshes (head + body + hair + maybe teeth + tongue) — not
  hundreds (a sign that geometry wasn't merged).
- Be under 4 MB uncompressed (the placeholder generator hits ~60 KB;
  a real MakeHuman body lands around 1.5–3.5 MB).

Drop into a glTF viewer (https://gltf-viewer.donmccurdy.com/ for a
quick sanity check, or `model_viewer_plus`'s online demo) and confirm
the rotation / lighting / proportions look correct.

---

## 6. Upload

```bash
GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \
  python3 tool/upload_models.py \
    --bucket saf-uniforms.firebasestorage.app
```

The script is idempotent — it'll only upload bodies whose SHA-256 has
changed since the last run.

---

## 7. Common gotchas

- **Inverted Z-axis at runtime.** model_viewer_plus expects +Y up,
  -Z forward. If your figure faces away from the camera, you skipped
  "+Y Up" in the GLB exporter.
- **Empty scene in the app, but the GLB looks fine in viewer.** Check
  that the armature is the *parent* of the mesh, not a sibling. glTF
  drops orphan armatures.
- **Texture swatches show as solid white.** MakeHuman skin uses a
  shader that doesn't survive glTF export by default. Bake textures
  before export, or just live with the diffuse-only result for the
  placeholder phase.
- **CF logs "asset missing, using placeholder".** The Storage object
  isn't where the CF expects. Check exact filename match (case
  sensitive) and run `tool/upload_models.py` again.
- **CF logs "Compose failed: …".** Open the function logs in the
  Firebase Console and scroll up — the actual exception message will
  be on a line above the failure. Most common is malformed GLB; re-run
  the validation in step 5.

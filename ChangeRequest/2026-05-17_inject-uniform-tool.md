# Proper Uniform-GLB Normaliser — `tool/inject_uniform.py`

- **Date:** 2026-05-17
- **Author:** Claude (with Datta)
- **Status:** proposed (not executed — follow-up to [2026-05-17_army-no3-uniform-y-flip.md](2026-05-17_army-no3-uniform-y-flip.md))

## 1. Goal

Replace the ad-hoc one-off `trimesh` scale-translate(-and-now-rotate)
that has been used twice now to normalise `army_no3_male.glb` with a
proper repeatable tool, modelled on `tool/inject_sockets.py` (bodies)
and `tool/inject_accessory.py` (accessories). Every future
artist / generative uniform delivery should land at the same
+Z-forward, height-normalised, x/z-centred, feet-at-y=0 contract that
the merger and socket positions assume — no operator scripting per
file.

CLAUDE.md §8 already calls this out:
> A formal `tool/inject_uniform.py` should be authored when more uniforms land.

The Y-flip pass 4 (`2026-05-17_army-no3-uniform-y-flip.md`) is a
demo-unblocker, not a long-term solution. The next uniform delivery
will land with its own undocumented orientation + scale, and we'll be
back at the same investigation. This plan formalises the contract.

## 2. Scope

In scope:
- New file `tool/inject_uniform.py` — CLI Python tool.
- Doc updates in CLAUDE.md §2 top-level layout (`tool/` section) and
  §8 (Known gaps).
- Re-normalise the existing `army_no3_male.glb` from its raw Tripo
  source via the new tool to validate parity with the manual fix.

Out of scope:
- Changing the merger contract (it stays "uniforms come pre-aligned
  +Z-forward at the same height as the body"; the tool is what
  enforces it).
- Authoring new uniforms (the tool is a normaliser, not a generator).
- Auto-detecting branch / dress / gender from the input GLB
  (filename-driven, explicit CLI).

## 3. Affected files

- `tool/inject_uniform.py` — new file (~150 lines, mirrors
  `tool/inject_sockets.py`).
- `assets/3d_raw/army_no3_male_source.glb` — raw Tripo input,
  re-staged from `assets/3d_raw/` (gitignored per project convention).
- `assets/3d/uniforms/army_no3_male.glb` — re-generated to validate
  the tool produces a byte-equivalent result to the manual pass.
- `CLAUDE.md` §2 and §8 — doc updates.

## 4. Step-by-step plan

1. **Author `tool/inject_uniform.py`** with this CLI:
   ```
   inject_uniform.py
       --in <raw.glb>
       --out <normalised.glb>
       [--target-height METRES]         # default 1.78 male, 1.65 female / maternity
       [--facing {+z,-z,+x,-x}]         # explicit override
       [--no-auto-orient]               # skip the bbox-deepest heuristic
       [--rotate-y DEG]                 # final manual rotate (rare)
   ```
   Pipeline:
   1. `trimesh.load(in_path, force="mesh")` — bakes node transforms
      into vertex coordinates so the output is a single transform-free
      mesh (same trick as `inject_sockets.py` / `inject_accessory.py`).
   2. **Auto-orient** (unless `--no-auto-orient`): the bbox's deepest
      extent is the front-back axis. Most humanoid exports have
      width(x) > depth(z) > height(y) after the Y-up assumption. If
      the auto-detected forward axis isn't +Z, apply the rotation
      that puts it there. `--facing` short-circuits the heuristic.
   3. Scale uniformly so the y-extent matches `--target-height`.
   4. Recentre on x/z (mean of bbox), snap feet to y=0
      (translate by `(-cx, -y0, -cz)`).
   5. Apply `--rotate-y` if provided (escape hatch).
   6. `mesh.export(out_path)`.
2. **Sanity tests** baked into the tool (no separate test file):
   - Post-output bbox y-extent within ±1 cm of `--target-height`.
   - Post-output feet (min Y) within ±1 mm of 0.
   - Post-output centre of x and z within ±5 cm of 0.
   - Front-facing axis verification by head-slice nose-protrusion test
     (same script the Explore agent used to verify pass 4) — exits
     non-zero if the +Z extreme is not the deeper of the two.
3. **Validate against pass 4 output**: run
   `inject_uniform.py --in assets/3d_raw/army_no3_male_source.glb --out /tmp/army_no3_male.glb`
   and confirm the resulting GLB's bbox + nose-protrusion test
   matches the pass-4 in-place rewrite (Y-flip + scale + recentre).
   Then copy over `assets/3d/uniforms/army_no3_male.glb`, re-upload,
   confirm device parity.
4. **Doc updates**: add a `tool/inject_uniform.py` entry to CLAUDE.md
   §2 (mirroring the existing `inject_sockets.py` / `inject_accessory.py`
   bullets), and drop the §8 "should be authored when more uniforms
   land" caveat.
5. **No `MODEL_BUNDLE_VERSION` bump required** — the regenerated GLB
   must be visually identical to the pass-4 file (bbox match + nose
   test passes). If not, treat as a bug and tighten the heuristic
   before merging.

## 5. Risks & rollback

- **Risk:** auto-orient heuristic picks the wrong axis on edge
  exports (e.g. ones that come out tilted ±15°). **Mitigation:**
  `--facing` and `--rotate-y` escape hatches keep the operator in
  control.
- **Risk:** `trimesh.load(force="mesh")` collapses textured submeshes
  or loses materials. The accessory tool has the same constraint
  and has been fine — but a uniform with multiple PBR materials
  could surprise us. **Mitigation:** if multi-material support is
  needed, switch the loader to `force="scene"` and walk geometries
  individually (more code, deferred until needed).
- **Rollback:** the tool is purely additive. The pass-4 in-place
  GLB stays live until the tool's output is bytewise equivalent
  and visually verified.

## 6. Verification

When this plan executes:
1. `flutter analyze` and `flutter test` — should be no-ops (tool is
   not in the app build graph).
2. `python3 tool/inject_uniform.py --help` — prints usage.
3. Round-trip on the raw `army_no3_male_source.glb` produces a GLB
   whose bbox is within 1 mm of the pass-4 output.
4. Re-upload + device test → no visual regression vs pass 4.

## 7. CLAUDE.md updates required

- §2 `tool/` section — add `inject_uniform.py` entry.
- §8 — drop the "should be authored when more uniforms land" caveat
  and replace with a pointer to the tool.
- §5.5 — mention the tool alongside the existing inject_sockets /
  inject_accessory references when describing the asset pipeline.

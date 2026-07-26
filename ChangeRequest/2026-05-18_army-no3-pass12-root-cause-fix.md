# Army No.3 Male — Pass 12: root-cause diagnosis after 11 invisible passes

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** executed
- **Supersedes:** none

## Context

After 11 passes, user reported that the "green dome" and belt issues
persisted unchanged despite multiple beret/belt edits. Decided to
stop iterating blind and verify the pipeline empirically.

Two distinct root causes uncovered by running the CF compose
pipeline locally + reading CF logs:

### Root cause 1: belt has been failing to load on every compose since pass-10

In pass-10 I replaced `nylon_belt.glb` with the user-provided
wrap-around belt and stripped the textures + images array (set both
to `[]`). I removed `baseColorTexture`, `normalTexture`,
`occlusionTexture`, `emissiveTexture` from the materials — **but
missed `metallicRoughnessTexture`**, leaving a stray
`{"index": 2}` reference to a non-existent texture.

gltf-transform throws `TypeError: Cannot read properties of
undefined (reading 'source')` on load. The CF's per-accessory
try/catch swallows the error and logs
`"accessory load/merge threw; skipping","accId":"nylon_belt"` — so
the BELT NEVER GOT ATTACHED for any compose since pass-10. The user
has been seeing the belt-less GLB and (correctly) reporting "belt is
invisible / nothing changed."

### Root cause 2: the "green dome" was `army_sikh_turban_standard`, not the beret

CF log shows the resolver picking `army_sikh_turban_standard`
attached at `head_top` — not `army_beret`. Per
`dress_requirements/no_3_dress_requirements.branch_overrides.army.headdress.men`:
```
{ "sikh": "army_sikh_turban_standard",
  "sikh_col_me7_above": "...",
  "default": "army_beret" }
```

The user's `users/{uid}/profile/current.isSikh` was `true` (likely
toggled accidentally during config), so the resolver correctly
picked the Sikh turban. Every "beret colour / size / position" fix
across passes 7-11 was operating on `army_beret.glb` — which the CF
was never attaching for this profile.

## Fixes applied

1. **Belt material**: removed `metallicRoughnessTexture` from
   `nylon_belt.glb`'s material; re-uploaded to Storage.
2. **User profile**: user's `isSikh` is now `false` (either user
   toggled it via the app or it was already changed by the time I
   checked). Cleared the cached
   `users/{uid}/profile/current.generatedDresses` entry to force a
   fresh compose on next GhostScreen open.

## Lessons

- Strip **all** texture references when stripping materials —
  `metallicRoughnessTexture` is easily missed.
- The CF's per-accessory try/catch is great for resilience but
  silently masks asset bugs. Should add a `criticalAccessories`
  list or surface compose-time warnings to the client so future
  debugging is faster.
- Profile-state matters as much as accessory-state. `isSikh: true`
  switching the entire headdress route was invisible without
  inspecting the resolver picks in the CF log.

## Verification

1. `cd functions && npm run build && npm test` — 22/22 still pass.
2. Local compose pipeline test (`test_compose.mjs`) now succeeds:
   `beret attach: { attached: true }`, `belt attach: { attached: true }`,
   `hair detach: true`, final composed GLB has 4 materials including
   `beret_black: baseColor [0.02, 0.02, 0.02, 1]`.
3. **Device** — next GhostScreen open triggers fresh compose;
   should show:
   - Hand-built black beret on head (pass-11 dome)
   - Belt visible across the front of the waist (just-fixed
     nylon_belt now loads)
   - Name plate on wearer's right pocket (pass-8/-11 fix)
   - All other pass-7..pass-11 fixes that were attached for
     non-sikh-route accessories

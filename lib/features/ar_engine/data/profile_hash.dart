import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../profile/domain/entities/dress_code.dart';
import '../../profile/domain/entities/uniform_profile.dart';

/// Bumps when the composition logic itself changes. Forces every user's
/// 3D model to regenerate next time they open the Ghost screen, even if
/// their profile fields are unchanged.
///
/// Bump this when:
/// - the `composeUniformModel` Cloud Function changes how it merges GLBs
/// - the asset library layout in Firebase Storage changes
/// - the named anchor sockets on the body GLBs change
/// - texture / mesh compression settings change in a user-visible way
///
/// v2: Phase-2 multi-asset composition (uniform merge + accessory
/// re-parenting under named sockets + name-tag bake + Draco/WebP
/// texture compression).
///
/// v3: Phase-2 accessory population — chest-side socket offset fix
/// (name-tag now flush on chest), anchor reconciliation across the
/// accessory library, mirror_left_right + side support, and ~55
/// placeholder accessory GLBs in Storage.
///
/// v5: Army No.3 placement pass 2 — bigger beret to cover hair, single-
/// shoe GLB with mirror_left_right for both feet, lanyard re-rotated to
/// flip loop direction, belt z-offset reduced. Cap-badge and beret
/// offsets retuned to match the bigger beret bbox.
///
/// v6: Army No.3 body / uniform alignment fix — male_apose.glb
/// regenerated from Tripo source (the live file was a corrupted flat
/// strip), uniform GLB scaled up to 1.78m to match the body. Fixes the
/// upper-body accessories floating ~80cm above the visible mesh.
///
/// v7: Army lanyard offset_y_cm -12 -> -22 so the cord drapes down the
/// right chest instead of arcing across the face.
///
/// v8: Army No.3 male uniform Y-flip — army_no3_male.glb was modelled
/// back-to-camera (faced -Z) while the body faces +Z. Every front-side
/// accessory landed on the back of the visible shirt. Fixed by a one-off
/// 180° Y rotation + recentre on the uniform GLB in place.
///
/// v9: Pass-5 Army No.3 male — body and uniform meshes were both authored
/// facing the X axis, but sockets sat at +Z. Diagnosed by user-report
/// ("initial GhostScreen load shows model in profile, mouth camera-right").
/// Fixed by rotating both meshes so the face moves from ±X to +Z, baked
/// into vertex coords (sockets untouched). Also added
/// `consolidateScenesToOne` to the compose pipeline so mergeDocuments'
/// secondary scenes don't strand uniform / accessory geometry outside
/// the default scene.
///
/// v10: Pass-6 Army No.3 male placement tuning — removed mirror_left_right
/// negative-scale (was inverting triangle winding → back-face culled the
/// right copy invisible), moved sleeve_upper sockets to outer upper-arm,
/// sliced body's bare feet into a detachable `feet` node, stripped
/// socket marker mesh refs, adjusted army_arms_badge + nylon_belt offsets.
///
/// v11: Pass-7 Army No.3 male — nine per-accessory detail fixes:
/// shoes pair sliced to single shoe, beret recoloured to black,
/// lanyard rotated 180°X, belt rotated 180°Y + recoloured black,
/// socks replaced with cylinder mesh, name_tag socket moved above the
/// chest pocket, arms_badge pulled back, cap_badge pushed forward
/// onto the beret's front face.
///
/// v12: Pass-8 Army No.3 male — doctrine-alignment corrections:
/// flipped body name_tag socket X from +0.0599 to -0.0599 so the
/// name plate lands on the wearer's right chest pocket per doctrine
/// (the body's socket naming convention has world +X = wearer's
/// LEFT side / camera-right). Lanyard offset_y_cm -22 → -30 so the
/// loop sits at the shoulder seam instead of floating 8 cm above.
///
/// v13: Pass-9 Army No.3 male — re-sliced body so the scalp/hair
/// region (y >= 1.65) lives in a real `hair` sub-mesh; the existing
/// hair-detach-on-headdress logic now actually drops the green-tinted
/// scalp geometry when a beret mounts. Scaled the belt mesh
/// 1.6×1.5×1.0 → 48 cm × 10.5 cm × 7 cm for a more visible wrap.
///
/// v14: Pass-10 Army No.3 male — beret coverage + user-provided
/// wrap-around belt. Stripped ALL textures from army_beret.glb +
/// reset materials to plain matte black (Tripo's normal+MR maps
/// were bleeding a green tint via PBR shading). Scaled beret 1.3×
/// uniformly (24→32 cm wide) + bumped offset_y_cm -4 → -7. Replaced
/// nylon_belt.glb with the user's wrap-around belt (bbox 24×22×98 cm,
/// actually wraps around the waist); centred via offset_y_cm=-11,
/// offset_z_cm=-16.
///
/// v15: Pass-11 Army No.3 male — built beret from scratch (hemisphere
/// + brim ring, 22×16×22 cm, vertex colors black + black PBR
/// material; previous Tripo beret kept bleeding green even after
/// every texture stripped). Removed body's hair sub-mesh entirely.
/// `army_beret.offset_y_cm`: -7 → -16. `nylon_belt.offset_y_cm`:
/// -11 → -3. `name_tag` socket: (-0.060, 1.345) → (-0.075, 1.36).
///
/// v16: Pass-13 Army No.3 male — wrap-around belt rebuilt from scratch
/// (torus major_radius 0.18m + gold buckle at +Z, vertex-color
/// material). User's nylon_belt.glb was a flat slab; appeared as a
/// huge horizontal plank in side view.
///
/// v17: Pass-14 Army No.3 male — belt strap thinned. Torus tube was
/// too thick (7cm); replaced with flat annulus profile (3.5cm strap
/// height) + bigger gold buckle (6×4×1.8cm) prominent at the front.
///
/// v18: Pass-15 Army No.3 male — belt tightened to body waist:
/// outer radius 19cm → 16.5cm, strap height 3.5cm → 2.5cm so it
/// touches the trousers on all sides.
///
/// v19: Pass-16 — CF now respects wardrobe unchecks for mandatory
/// items. Unchecking belt/socks/footwear in the Wardrobe tab now
/// excludes them from the composed GLB.
///
/// v20: Pass-17 — REVERTED v19. Mandatory items stay mandatory in the
/// composed GLB regardless of wardrobe checks (back to v18 behaviour)
/// — the AR/VR overlay needs all mandatory items present for the
/// "did I wear this correctly?" verification flow.
const int kModelBundleVersion = 22;

/// Computes the deterministic profile hash that gates 3D-model
/// regeneration. The same inputs must produce the same output on the
/// Flutter client and the `composeUniformModel` Cloud Function — hence
/// the explicit, sorted, JSON-encoded shape.
///
/// Returns the first 16 hex chars of `sha256(json)` — collision space
/// of 64 bits is plenty for a per-user cache key.
///
/// Only fields that affect what the model **looks like** are folded in.
/// `dressAccessoryChecks` are included only for the active [dress] (a
/// tick on No.5 must not invalidate the No.3 model).
String computeProfileHash(UniformProfile profile, DressCode dress) {
  final dressDocId = dress.requirementDocId;
  final payload = <String, Object?>{
    'bundleVersion': kModelBundleVersion,
    'branch': profile.branch.wireName,
    'rank': profile.rank.code,
    'gender': profile.gender.wireName,
    'dressCode': dress.wireName,
    'isSikh': profile.isSikh,
    'fullName': profile.fullName,
    'vocation': profile.vocation,
    'medalRowCount': profile.medalRowCount,
    'selectedBadgeIds': (profile.selectedBadgeIds.toList()..sort()),
    'selectedAccessoryIds': (profile.selectedAccessoryIds.toList()..sort()),
    'dressChecks':
        (profile.dressAccessoryChecks[dressDocId]?.toList() ?? <String>[])
          ..sort(),
  };

  final json = jsonEncode(_sortedMap(payload));
  final digest = sha256.convert(utf8.encode(json));
  return digest.toString().substring(0, 16);
}

/// Recursively sorts map keys so the JSON encoding is canonical
/// regardless of insertion order on either side of the wire.
Object? _sortedMap(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return <String, Object?>{
      for (final k in keys) k: _sortedMap(value[k]),
    };
  }
  if (value is List) {
    return value.map(_sortedMap).toList();
  }
  return value;
}

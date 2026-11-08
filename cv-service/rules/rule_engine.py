"""Stage 6 — rule engine (geometry half).

Resolves each doctrine rule in a uniform's rules file (`uniforms.py`; default
`army_no3_male.json`) to an expected 3D
position (anchor + cm offset), projects it into the current photo via
the Stage 3 camera solution, and sizes a pixel-space crop region around
it. This is the "where to look" half of Stage 6 — deterministic,
measured, no model involved. The "what is this" half (does the crop
actually contain the right item, correctly oriented) is Stage 4/5's
job; today that's the vision-crop inspector, not a trained detector —
see `detectors/vision_crop_inspector.py`'s module docstring.
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import re

import numpy as np

import config
from calibration.pnp_solve import CameraSolution, project_point
from pose.estimate_pose import PoseResult
from rules.rule_loader import load_rule_config
from segmentation.mask_geometry import angle_difference_deg, mask_centroid_px, mask_orientation_deg, mask_reference_point
from segmentation.segment_uniform import SegmentationResult

_RULES_PATH = Path(__file__).resolve().parent / "army_no3_male.json"
_ANCHORS_PATH = Path(__file__).resolve().parent / "anchors.male.json"

_DEFAULT_CROP_RADIUS_CM = config.DEFAULT_CROP_RADIUS_CM
_TOLERANCE_TO_CROP_MULTIPLIER = config.TOLERANCE_TO_CROP_MULTIPLIER
_MIN_CROP_RADIUS_CM = config.MIN_CROP_RADIUS_CM


def load_rules(path: Path = _RULES_PATH) -> list[dict]:
    return load_rule_config(path).rules


def load_anchors(path: Path = _ANCHORS_PATH) -> dict:
    return json.loads(path.read_text())["anchors"]


@dataclass(frozen=True)
class CropBox:
    anchor_name: str
    center_px: tuple[float, float]
    x1: float
    y1: float
    x2: float
    y2: float
    # A4: local image scale at this rule's 3D point, from projecting 1 cm
    # steps through the solved camera (None -> fall back to the global
    # shoulder-width cm_per_px). A5: geometric uncertainty of `center_px`.
    # See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
    px_per_cm: float | None = None
    uncertainty_px: float = 0.0


@dataclass(frozen=True)
class ResolvedRule:
    object_id: str
    category: str
    doctrine_ref: str
    required: bool
    crops: list[CropBox]
    tolerance_cm: float | None
    max_count: int | None
    rule_text: str
    raw_rule: dict = field(repr=False)


def _strip_profile_prefix(field_name: str) -> str:
    """`army_sikh_turban_standard`'s condition is authored as
    `profile.isSikh == true` — a `profile.` prefix that doesn't match
    any actual profile dict key (callers pass `{"isSikh": ..., ...}`,
    never nested under a `"profile"` key). Strip it so the field name
    actually resolves."""
    return field_name[len("profile."):] if field_name.startswith("profile.") else field_name


_OWN_CAP_BADGE_TIERS = {"col_me7", "bg_me8_and_above"}


def with_derived_fields(profile: dict[str, Any]) -> dict[str, Any]:
    """Adds `cap_badge_tier` — the cap-badge vocabulary the doctrine's
    cap-badge conditions are written in — derived from the single
    `rank_tier` the app sends (`enlistee`, `specialist`, `col_me7`, ...).
    COL/ME7 and BG/ME8+ have their own badges; everyone else wears the
    SLTC/ME6-and-below one. See rules/army_no3_male.json `_meta`."""
    if "cap_badge_tier" in profile:
        return profile
    rank_tier = profile.get("rank_tier")
    tier = rank_tier if rank_tier in _OWN_CAP_BADGE_TIERS else "sltc_me6_and_below"
    return {**profile, "cap_badge_tier": tier}


def _condition_matches(condition: str | None, profile: dict[str, Any]) -> bool:
    """Very small condition-language evaluator — only the comparisons
    the current rule set actually uses (`==`, `!=`, `in [...]`,
    `<`/`>=` against profile fields, optionally joined with ` AND `).
    Not a general expression evaluator by design: doctrine conditions
    are simple, and a real parser is unwarranted until the rule set
    needs more than this.
    """
    if not condition:
        return True

    # Must be checked before the single-operator loop below: e.g.
    # "profile.isSikh == true AND rank_tier != col_me7_and_above"
    # contains a "!=" inside its second clause, which the single-pass
    # loop would otherwise match against the WHOLE string first,
    # silently mis-parsing a compound condition as a malformed simple
    # one (this was a real, previously-unnoticed bug — see the
    # ChangeRequest plan this fix belongs to).
    if " AND " in condition:
        return all(_condition_matches(part.strip(), profile) for part in condition.split(" AND "))

    if " in [" in condition:
        field_name, rest = condition.split(" in [", 1)
        field_name = _strip_profile_prefix(field_name.strip())
        options = [o.strip() for o in rest.rstrip("]").split(",")]
        return str(profile.get(field_name)) in options

    for op in ("!=", "==", ">=", "<"):
        if op in condition:
            field_name, value = condition.split(op, 1)
            field_name, value = _strip_profile_prefix(field_name.strip()), value.strip()
            actual = profile.get(field_name)
            value = value.strip("'\"")
            try:
                value_typed: Any = int(value)
                actual_typed: Any = int(actual)
            except (TypeError, ValueError):
                value_typed, actual_typed = value, actual
                if isinstance(value_typed, str) and value_typed in ("true", "false"):
                    value_typed = value_typed == "true"
            if op == "==":
                return actual_typed == value_typed
            if op == "!=":
                return actual_typed != value_typed
            if op == ">=":
                return actual_typed is not None and actual_typed >= value_typed
            if op == "<":
                return actual_typed is not None and actual_typed < value_typed

    return True  # unrecognized condition shape — don't silently exclude a rule


def _crop_radius_cm(rule: dict) -> float:
    if "search_radius_cm" in rule:
        return rule["search_radius_cm"]
    tolerance = rule.get("tolerance_cm")
    if tolerance:
        return max(tolerance * _TOLERANCE_TO_CROP_MULTIPLIER, _MIN_CROP_RADIUS_CM)
    return _DEFAULT_CROP_RADIUS_CM


def _resolve_offset_point(anchor: dict, rule: dict) -> tuple[float, float, float]:
    offset_x = rule.get("offset_x_cm", 0.0) / 100.0
    offset_y = rule.get("offset_y_cm", 0.0) / 100.0
    offset_z = rule.get("offset_z_cm", 0.0) / 100.0
    return (anchor["x"] + offset_x, anchor["y"] + offset_y, anchor["z"] + offset_z)


_SLEEVE_FRACTION_RE = re.compile(r"fraction_of_sleeve_length:\s*([0-9.]+)")


def _sleeve_length_fraction(rule: dict) -> float | None:
    """Doctrine rules like sleeve rank insignia are specified as 'half
    of sleeve length from the shoulder seam' — a fraction ALONG THE ARM,
    not a fixed cm offset from a single anchor (arm length varies by
    body, and the reference GLB has no elbow/wrist socket to encode
    that in 3D). Parsed out of `position_rule` and applied in 2D against
    the detected elbow landmark — see `_apply_sleeve_fraction`."""
    match = _SLEEVE_FRACTION_RE.search(rule.get("position_rule", ""))
    return float(match.group(1)) if match else None


def _apply_sleeve_fraction(
    anchor_px: tuple[float, float],
    anchor_name: str,
    fraction: float,
    pose: PoseResult | None,
) -> tuple[float, float]:
    """Blend the projected shoulder/sleeve anchor toward the matching
    elbow landmark by `fraction` of the shoulder->elbow segment. Falls
    back to the raw anchor projection when no pose (or no visible
    elbow) is available — degrade to the less-precise geometry rather
    than fail the rule outright."""
    if pose is None:
        return anchor_px
    side = "left" if anchor_name.startswith("left") else "right"
    elbow = pose.named(f"{side}_elbow")
    if elbow is None or elbow.visibility < 0.5:
        return anchor_px
    ax, ay = anchor_px
    return (
        ax + (elbow.x_px - ax) * fraction,
        ay + (elbow.y_px - ay) * fraction,
    )


def _local_px_per_cm(point_3d: tuple[float, float, float], center_px: tuple[float, float], camera: CameraSolution) -> float | None:
    """Pixels per cm at `point_3d`, measured by projecting 1 cm steps along
    the body's horizontal and vertical axes through the solved camera and
    averaging. Unlike the single shoulder-width scale, this accounts for
    the point's own depth and for body rotation / foreshortening."""
    distances = []
    for step in ((0.01, 0.0, 0.0), (0.0, 0.01, 0.0)):
        try:
            qx, qy = project_point(tuple(p + d for p, d in zip(point_3d, step)), camera)
        except ValueError:
            continue
        distances.append(math.hypot(qx - center_px[0], qy - center_px[1]))
    return sum(distances) / len(distances) if distances else None


def resolve_rules(
    camera: CameraSolution,
    cm_per_px: float,
    profile: dict[str, Any] | None = None,
    rules: list[dict] | None = None,
    anchors: dict | None = None,
    pose: PoseResult | None = None,
) -> list[ResolvedRule]:
    """Resolve every applicable rule to one or more pixel-space crop
    boxes in the current photo. `cm_per_px` is the scale factor from
    `calibration.pnp_solve.scale_factor_cm_per_unit` — crop radii are
    stored in cm in the rule file and converted here.
    """
    profile = with_derived_fields(profile or {})
    rules = rules if rules is not None else load_rules()
    anchors = anchors if anchors is not None else load_anchors()

    resolved: list[ResolvedRule] = []
    for rule in rules:
        if not _condition_matches(rule.get("condition"), profile):
            continue

        anchor_names = [n.strip() for n in rule["expected_anchor"].split(",")]
        radius_cm = _crop_radius_cm(rule)
        sleeve_fraction = _sleeve_length_fraction(rule)
        geometric_uncertainty_px = config.UNCERTAINTY_REPROJECTION_WEIGHT * (camera.reprojection_error_px or 0.0)

        crops: list[CropBox] = []
        for anchor_name in anchor_names:
            anchor = anchors.get(anchor_name)
            if anchor is None:
                continue
            point_3d = _resolve_offset_point(anchor, rule)
            try:
                px, py = project_point(point_3d, camera)
            except ValueError:
                continue
            px_per_cm = _local_px_per_cm(point_3d, (px, py), camera)
            if sleeve_fraction is not None:
                px, py = _apply_sleeve_fraction(
                    (px, py), anchor_name, sleeve_fraction, pose
                )
            if px_per_cm:
                radius_px = radius_cm * px_per_cm
            else:
                radius_px = radius_cm / cm_per_px if cm_per_px else 40.0
            crops.append(
                CropBox(
                    anchor_name=anchor_name,
                    center_px=(px, py),
                    x1=px - radius_px,
                    y1=py - radius_px,
                    x2=px + radius_px,
                    y2=py + radius_px,
                    px_per_cm=px_per_cm,
                    uncertainty_px=geometric_uncertainty_px,
                )
            )

        if not crops:
            continue

        resolved.append(
            ResolvedRule(
                object_id=rule["object"],
                category=rule.get("category", ""),
                doctrine_ref=rule.get("doctrine_ref", ""),
                required=bool(rule.get("required", False)),
                crops=crops,
                tolerance_cm=rule.get("tolerance_cm"),
                max_count=rule.get("max_count"),
                rule_text=rule.get("rule_text", ""),
                raw_rule=rule,
            )
        )

    return resolved


# ---------------------------------------------------------------------------
# Verdict engine — geometric pass/fail/missing/unverifiable, given the
# trained segmentation model's detected regions. See
# ChangeRequest/2026-08-11_cv-service-verdict-engine-army-no3-male.md for
# the full design rationale (this section implements it, not re-derives
# it — read that file before changing tolerances or status logic here).
#
# `None` here means "no segmentation class exists yet for this doctrine
# category" — medal_ribbons, saf_badges_chest, skill_tabs_sleeve and
# skill_badges_sleeve have no detector at all and are always reported
# `unverifiable`, never guessed at. name_tag and socks map to classes that
# only segmentation_v2+ has; with the 9-class v1 model loaded they are
# `unverifiable` too (see `segmentation_class_for`). Several mapped classes are shared by multiple doctrine
# variants (e.g. 3 cap-badge rank-tier rules all map to one `cap_badge`
# class) — this engine can confirm presence + position for those, never
# which variant is actually present.
CATEGORY_TO_SEGMENTATION_CLASS: dict[str, str | None] = {
    "headdress_beret": "headwear",
    "headdress_sikh_turban": "headwear",
    "cap_badge": "cap_badge",
    "epaulette": "epaulette",
    "sleeve_rank_specialist": "sleeve_rank",
    "sleeve_rank_enlistee": "sleeve_rank",
    "arms_badge": "arms_badge",
    "belt": "belt",
    "footwear": "footwear",
    "name_tag": "name_tag",  # segmentation_v2+ only — see has_detector
    "medal_ribbons": None,
    "saf_badge": None,
    "skill_tab": None,
    "skill_badge": None,
    "socks": "socks",  # segmentation_v2+ only — see has_detector
    # RSAF No.4 (segmentation_v3+; ChangeRequest/2026-10-05_cv-service-rsaf-no4.md).
    "rank_epaulette_chest": "rank_tab",
    "sleeve_patch": "sleeve_patch",
    # The SINGAPORE tag looks like the name tag; the two rules' search boxes
    # (right vs left chest pocket) keep their detections apart.
    "country_tag": "name_tag",
    "vocation_badge": None,
}

_DEFAULT_MIN_SEGMENT_CONFIDENCE = config.MIN_SEGMENT_CONFIDENCE

# Worst-first ordering used when a paired rule (e.g. left+right sleeve
# insignia) produces more than one crop — the item's overall status is
# the worst of its per-crop statuses, same "correct on one side isn't
# good enough" principle `reporting/report.py`'s `_combine` already uses
# for the vision-crop path.
_STATUS_SEVERITY = {"fail": 0, "missing": 1, "unverifiable": 2, "slightly_misaligned": 3, "pass": 4}


@dataclass(frozen=True)
class VerdictResult:
    accessory: str
    status: str  # "pass" | "slightly_misaligned" | "fail" | "missing" | "unverifiable"
    reason: str
    doctrine_ref: str
    # Additive fields (see ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md)
    # — all default so every pre-existing caller (`/inspect`'s
    # `geometric_verdicts`, `test_verdict_engine.py`) is unaffected.
    confidence: float | None = None
    bounding_box_px: tuple[float, float, float, float] | None = None
    expected_position_px: tuple[float, float] | None = None
    detected_position_px: tuple[float, float] | None = None
    error_px: tuple[float, float] | None = None
    visibility: str = "uncertain"  # "visible" | "partially_visible" | "occluded" | "out_of_frame" | "uncertain"
    # ChangeRequest/2026-09-28_accuracy-program-no-real-data.md: what
    # drove a non-pass status (feeds the user-facing instruction, E18),
    # the local scale for converting `error_px` to cm, the measured angle
    # error, and the matched mask for the post-verdict checks (B8-B10).
    # failure_kind: "position" | "orientation" | "missing" | "out_of_frame"
    #   | "no_detector" | "camera" | "boundary" | "color" | "variant"
    #   | "name_text" | "unconfirmed" | None
    failure_kind: str | None = None
    px_per_cm: float | None = None
    angle_error_deg: float | None = None
    region_mask: np.ndarray | None = field(default=None, repr=False, compare=False)
    detection_source: str | None = None  # SegmentedRegion.source of the matched region
    tolerance_cm: float | None = None  # the doctrine tolerance the position was judged against


@dataclass(frozen=True)
class _CropEvaluation:
    """Internal — everything `_evaluate_one_crop` computes, kept instead
    of discarded so `evaluate_verdicts` can surface it on `VerdictResult`."""

    status: str
    reason: str
    confidence: float | None
    bounding_box_px: tuple[float, float, float, float] | None
    expected_position_px: tuple[float, float]
    detected_position_px: tuple[float, float] | None
    error_px: tuple[float, float] | None
    visibility: str
    failure_kind: str | None = None
    px_per_cm: float | None = None
    angle_error_deg: float | None = None
    region_mask: np.ndarray | None = None
    detection_source: str | None = None


def segmentation_class_for(category: str, class_names: frozenset[str] | None = None) -> str | None:
    """The segmentation class that detects this doctrine category, or
    `None` when there is none — either no class is mapped, or the loaded
    model doesn't have it (`class_names`, from
    `SegmentationResult.class_names`; `None` = assume every mapped class)."""
    segmentation_class = CATEGORY_TO_SEGMENTATION_CLASS.get(category)
    if segmentation_class is None or (class_names is not None and segmentation_class not in class_names):
        return None
    return segmentation_class


def has_detector(category: str, class_names: frozenset[str] | None = None) -> bool:
    """Whether the trained segmenter has a class for this doctrine
    category at all. `False` means every rule in the category is
    structurally `unverifiable` — used by `api/response_schema.py` to
    keep those out of the verification-coverage gate's denominator."""
    return segmentation_class_for(category, class_names) is not None


def _crop_in_bounds(crop: CropBox, image_width: int, image_height: int) -> bool:
    return crop.x1 >= 0 and crop.y1 >= 0 and crop.x2 <= image_width and crop.y2 <= image_height


def _centroid_in_crop(centroid: tuple[float, float], crop: CropBox) -> bool:
    return crop.x1 <= centroid[0] <= crop.x2 and crop.y1 <= centroid[1] <= crop.y2


def _assign_regions_to_crops(crops: list[CropBox], candidates: list) -> list:
    """One-to-one assignment of detected regions to a rule's crops.

    A region is only eligible for a crop when its mask centroid lies
    inside that crop's search box — a detection elsewhere in the photo
    (a stray false positive, or the *other* side of a paired item) must
    never stand in for this one. Greedy by distance (globally shortest
    pair first), which is optimal for the 1-2 crops a rule has. Returns
    one entry per crop: `(region, centroid)` or `None` when unmatched.
    See ChangeRequest/2026-09-28_cv-service-coverage-gate-and-matching.md.
    """
    pairs: list[tuple[float, int, int, tuple[float, float]]] = []
    for region_index, region in enumerate(candidates):
        centroid = mask_centroid_px(region.mask)
        if centroid is None:
            continue
        for crop_index, crop in enumerate(crops):
            if _centroid_in_crop(centroid, crop):
                distance = math.hypot(centroid[0] - crop.center_px[0], centroid[1] - crop.center_px[1])
                pairs.append((distance, crop_index, region_index, centroid))

    assignment: list = [None] * len(crops)
    used_regions: set[int] = set()
    for _, crop_index, region_index, centroid in sorted(pairs, key=lambda p: p[0]):
        if assignment[crop_index] is not None or region_index in used_regions:
            continue
        assignment[crop_index] = (candidates[region_index], centroid)
        used_regions.add(region_index)
    return assignment


def _unmatched_crop(
    crop: CropBox, candidates: list, segmentation_class: str, image_width: int, image_height: int
) -> _CropEvaluation:
    """Evaluation for a crop no detection could be assigned to."""
    if not _crop_in_bounds(crop, image_width, image_height):
        return _CropEvaluation(
            status="unverifiable",
            reason=f"{crop.anchor_name}: expected region falls outside the photo",
            confidence=None,
            bounding_box_px=None,
            expected_position_px=crop.center_px,
            detected_position_px=None,
            error_px=None,
            visibility="out_of_frame",
            failure_kind="out_of_frame",
            px_per_cm=crop.px_per_cm,
        )

    reason = f"{crop.anchor_name}: no {segmentation_class} segment detected in the expected region"
    centroids = [c for c in (mask_centroid_px(r.mask) for r in candidates) if c is not None]
    if centroids:
        nearest = min(math.hypot(c[0] - crop.center_px[0], c[1] - crop.center_px[1]) for c in centroids)
        reason += f" (nearest {segmentation_class} detection is {nearest:.0f}px away, outside the search area)"
    return _CropEvaluation(
        status="missing",
        reason=reason,
        confidence=None,
        bounding_box_px=None,
        expected_position_px=crop.center_px,
        detected_position_px=None,
        error_px=None,
        visibility="occluded",
        failure_kind="missing",
        px_per_cm=crop.px_per_cm,
    )


def _position_status(distance_px: float, uncertainty_px: float, tolerance_px: float) -> str:
    """A5 — three-way decision that respects measurement uncertainty:
    `pass` only if the item is inside tolerance even at the worst end of
    the uncertainty, out-of-tolerance only if it's outside even at the
    best end, otherwise the measurement can't tell (`unverifiable`)."""
    band_px = tolerance_px * config.SLIGHT_MISALIGNMENT_BAND
    if distance_px + uncertainty_px <= tolerance_px:
        return "pass"
    if distance_px - uncertainty_px > tolerance_px:
        return "slightly_misaligned" if distance_px <= band_px else "fail"
    return "unverifiable"


def _evaluate_one_crop(
    rule: ResolvedRule, crop: CropBox, region, centroid: tuple[float, float], cm_per_px: float
) -> _CropEvaluation:
    """Returns a `_CropEvaluation` for one crop of one rule, given the
    detected region already assigned to it (centroid inside the crop)."""
    # A3: measure the point doctrine actually names (e.g. the bottom edge
    # of a name tag sits on the pocket's top edge), not the mask centroid.
    reference_kind = rule.raw_rule.get("reference_point", "center")
    measured = mask_reference_point(region.mask, reference_kind) or centroid
    distance_px = math.hypot(measured[0] - crop.center_px[0], measured[1] - crop.center_px[1])
    tolerance_cm = rule.raw_rule.get("tolerance_cm")
    px_per_cm = crop.px_per_cm or (1.0 / cm_per_px if cm_per_px else None)
    failure_kind = None
    if tolerance_cm is not None:
        tolerance_px = tolerance_cm * px_per_cm if px_per_cm else float("inf")
        mask_uncertainty_px = config.UNCERTAINTY_MASK_FRACTION * math.sqrt(float(region.mask.sum()))
        uncertainty_px = math.hypot(crop.uncertainty_px, mask_uncertainty_px)
        status = _position_status(distance_px, uncertainty_px, tolerance_px)
        where = "" if reference_kind == "center" else f" ({reference_kind.replace('_', ' ')})"
        reason = (
            f"{crop.anchor_name}{where}: {distance_px:.1f}px from expected position "
            f"(doctrine tolerance {tolerance_px:.1f}px = {tolerance_cm}cm, measurement uncertainty ±{uncertainty_px:.1f}px)"
        )
        if status == "unverifiable":
            reason += " — too close to the tolerance boundary to call either way"
            failure_kind = "boundary"
        elif status != "pass":
            failure_kind = "position"
    else:
        # No doctrine cm figure — presence/region check only. Assignment
        # already guarantees the centroid lies inside the crop's own
        # search box (search_radius_cm or the default), so presence in
        # the expected region is established; never a tighter check than
        # doctrine itself specifies.
        status = "pass"
        reason = f"{crop.anchor_name}: present in expected region (doctrine gives no cm tolerance for this item)"

    angle_error = None
    angle_deg = rule.raw_rule.get("angle_deg")
    tolerance_deg = rule.raw_rule.get("tolerance_deg")
    if angle_deg is not None and tolerance_deg is not None:
        measured_angle = mask_orientation_deg(region.mask)
        if measured_angle is None:
            reason += f"; {crop.anchor_name}: orientation unverifiable (mask shape too ambiguous to measure a reliable angle)"
            if status == "pass":
                status = "unverifiable"
                failure_kind = "boundary"
        else:
            angle_error = angle_difference_deg(measured_angle, angle_deg)
            reason += f"; {crop.anchor_name}: orientation {angle_error:.1f}° off doctrine (tolerance {tolerance_deg}°)"
            if angle_error > tolerance_deg:
                status = "fail"
                failure_kind = "orientation" if failure_kind in (None, "boundary") else failure_kind

    # A zero-shot region (B7) only ever stands in for a trained detection
    # that wasn't there, so on its own it can't certify the item: on the
    # hair of a bare head YOLO-World scores "beret" 0.72 (RSAF benchmark
    # scene_0016), above the accept threshold. It turns a would-be
    # `missing` into "couldn't confirm", never into a pass or fail.
    if getattr(region, "source", "trained") == "zero_shot":
        status = "unverifiable"
        failure_kind = "unconfirmed"
        reason += "; found only by the zero-shot fallback (the trained model saw nothing here) — not confirmed"

    if region.confidence < config.MIN_SEGMENT_CONFIDENCE * config.PARTIAL_VISIBILITY_CONFIDENCE_MULTIPLIER:
        visibility = "partially_visible"
    else:
        visibility = "visible"

    return _CropEvaluation(
        status=status,
        reason=reason,
        confidence=region.confidence,
        bounding_box_px=region.bbox_px,
        expected_position_px=crop.center_px,
        detected_position_px=measured,
        error_px=(measured[0] - crop.center_px[0], measured[1] - crop.center_px[1]),
        visibility=visibility,
        failure_kind=failure_kind,
        px_per_cm=px_per_cm,
        angle_error_deg=angle_error,
        region_mask=region.mask,
        detection_source=getattr(region, "source", "trained"),
    )


def evaluate_verdicts(
    resolved_rules: list[ResolvedRule],
    segmentation: SegmentationResult,
    cm_per_px: float,
    image_width: int,
    image_height: int,
    *,
    camera_reliable: bool = True,
    min_segment_confidence: float = _DEFAULT_MIN_SEGMENT_CONFIDENCE,
) -> list[VerdictResult]:
    """Geometric pass/fail/missing/unverifiable verdict per accessory,
    given Milestone C's projected zones (`resolved_rules`) and the
    trained segmentation model's detected regions. Never forces a
    verdict the underlying detector can't support — see the module-level
    comment above `CATEGORY_TO_SEGMENTATION_CLASS` and the plan file this
    implements.
    """
    if not camera_reliable:
        return [
            VerdictResult(
                accessory=rule.object_id,
                status="unverifiable",
                reason="camera pose unreliable for this photo — projected zones cannot be trusted",
                doctrine_ref=rule.doctrine_ref,
                expected_position_px=rule.crops[0].center_px,
                visibility="uncertain",
                failure_kind="camera",
            )
            for rule in resolved_rules
        ]

    results: list[VerdictResult] = []
    for rule in resolved_rules:
        expected_position_px = rule.crops[0].center_px
        segmentation_class = segmentation_class_for(rule.category, segmentation.class_names)
        if segmentation_class is None:
            # Unlike the "detector exists but found nothing" branch below,
            # this is reported even for optional rules: "we have no way
            # to check this at all" is a structural gap worth surfacing
            # every time, not something to silently omit just because the
            # item wasn't required — silently skipping it would let a
            # report look like every category was checked when several
            # never were. See the plan file's §3/§4.
            results.append(
                VerdictResult(
                    accessory=rule.object_id,
                    status="unverifiable",
                    reason=f"no segmentation class exists yet for doctrine category '{rule.category}'",
                    doctrine_ref=rule.doctrine_ref,
                    expected_position_px=expected_position_px,
                    visibility="uncertain",
                    failure_kind="no_detector",
                )
            )
            continue

        candidates = [
            region
            for region in segmentation.regions
            if region.class_name == segmentation_class and region.confidence >= min_segment_confidence
        ]
        assignment = _assign_regions_to_crops(rule.crops, candidates)

        if all(match is None for match in assignment):
            any_crop_in_bounds = any(_crop_in_bounds(crop, image_width, image_height) for crop in rule.crops)
            if not any_crop_in_bounds:
                results.append(
                    VerdictResult(
                        accessory=rule.object_id,
                        status="unverifiable",
                        reason="expected region falls outside the photo — likely occluded or camera angle too extreme",
                        doctrine_ref=rule.doctrine_ref,
                        expected_position_px=expected_position_px,
                        visibility="out_of_frame",
                        failure_kind="out_of_frame",
                    )
                )
                continue
            if not rule.required:
                continue

        evaluations = [
            _unmatched_crop(crop, candidates, segmentation_class, image_width, image_height)
            if match is None
            else _evaluate_one_crop(rule, crop, match[0], match[1], cm_per_px)
            for crop, match in zip(rule.crops, assignment)
        ]
        worst = min(evaluations, key=lambda e: _STATUS_SEVERITY[e.status])
        reasons = "; ".join(e.reason for e in evaluations)

        results.append(
            VerdictResult(
                accessory=rule.object_id,
                status=worst.status,
                reason=reasons,
                doctrine_ref=rule.doctrine_ref,
                confidence=worst.confidence,
                bounding_box_px=worst.bounding_box_px,
                expected_position_px=worst.expected_position_px,
                detected_position_px=worst.detected_position_px,
                error_px=worst.error_px,
                visibility=worst.visibility,
                failure_kind=worst.failure_kind,
                px_per_cm=worst.px_per_cm,
                angle_error_deg=worst.angle_error_deg,
                region_mask=worst.region_mask,
                detection_source=worst.detection_source,
                tolerance_cm=rule.raw_rule.get("tolerance_cm"),
            )
        )

    return results

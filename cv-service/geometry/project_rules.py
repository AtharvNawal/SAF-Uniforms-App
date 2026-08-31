"""Projects doctrine rules (`rules/army_no3_male.json`) into expected 2D
image-space zones for a specific photo, given a solved camera pose
(`geometry/solve_camera_pose.py` or `calibration/pnp_solve.py` — either
produces the same `CameraSolution` type).

Does not reimplement rule resolution: `rules/rule_engine.py`'s
`resolve_rules()` already does anchor+offset resolution, crop-box sizing,
and doctrine condition filtering, and is already tested. This module
calls it and adds the one thing it doesn't currently surface —
per-rule orientation tolerance (`angle_deg`/`tolerance_deg`), which the
doctrine JSON already carries but `ResolvedRule` doesn't expose as its
own field (it's buried in `raw_rule`).

    from geometry.project_rules import project_rules, cm_per_px_from_anchor_pose
    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose)
    projected = project_rules(camera, cm_per_px, profile={"rank_tier": "specialist", ...})
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from calibration.pnp_solve import CameraSolution  # noqa: E402
from rules.rule_engine import CropBox, ResolvedRule, resolve_rules  # noqa: E402

_ANCHORS_PATH = Path(__file__).resolve().parents[1] / "rules" / "anchors.male.json"


@dataclass(frozen=True)
class ProjectedRule:
    object_id: str
    category: str
    doctrine_ref: str
    required: bool
    crops: list[CropBox]
    tolerance_cm: float | None
    angle_deg: float | None
    tolerance_deg: float | None
    max_count: int | None
    rule_text: str


def _wrap(resolved: ResolvedRule) -> ProjectedRule:
    return ProjectedRule(
        object_id=resolved.object_id,
        category=resolved.category,
        doctrine_ref=resolved.doctrine_ref,
        required=resolved.required,
        crops=resolved.crops,
        tolerance_cm=resolved.tolerance_cm,
        angle_deg=resolved.raw_rule.get("angle_deg"),
        tolerance_deg=resolved.raw_rule.get("tolerance_deg"),
        max_count=resolved.max_count,
        rule_text=resolved.rule_text,
    )


def project_rules(
    camera: CameraSolution,
    cm_per_px: float,
    profile: dict[str, Any] | None = None,
    rules: list[dict] | None = None,
    anchors: dict | None = None,
) -> list[ProjectedRule]:
    """Every applicable doctrine rule resolved to one or more pixel-space
    crop boxes for this photo, plus orientation tolerance where doctrine
    specifies one (`None` for presence-only rules like `army_beret`,
    which doctrine gives no angle for)."""
    resolved_rules = resolve_rules(camera, cm_per_px, profile=profile, rules=rules, anchors=anchors, pose=None)
    return [_wrap(r) for r in resolved_rules]


def cm_per_px_from_anchor_pose(anchor_pose: dict, anchors: dict | None = None) -> float | None:
    """Milestone B's-dict equivalent of `pnp_solve.py`'s
    `scale_factor_cm_per_unit(pose)` — same shoulder-width ratio method,
    different input shape (anchor-keyed dict, not `PoseResult`)."""
    left, right = anchor_pose.get("left_shoulder_seam"), anchor_pose.get("right_shoulder_seam")
    if not left or not right or left["confidence"] <= 0.0 or right["confidence"] <= 0.0:
        return None
    shoulder_width_px = abs(right["x_px"] - left["x_px"])
    if shoulder_width_px == 0:
        return None

    if anchors is None:
        import json

        anchors = json.loads(_ANCHORS_PATH.read_text())["anchors"]

    left_3d, right_3d = anchors["left_shoulder_seam"], anchors["right_shoulder_seam"]
    reference_shoulder_width_cm = abs(right_3d["x"] - left_3d["x"]) * 100.0
    return reference_shoulder_width_cm / shoulder_width_px

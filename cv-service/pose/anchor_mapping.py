"""Maps a BlazePose `PoseResult` (Stage 2, `pose/estimate_pose.py`) onto
this project's 16 named body anchors (`rules/anchors.male.json`'s 15
sockets + the derived `chest_center`) — a general-purpose mapping any
stage can use, additive to the pipeline that already ships.

This is deliberately a **second, separate** mapping from
`calibration/pnp_solve.py`'s own `CORRESPONDENCES` list. That one exists
for a narrower purpose (PnP needs a handful of *reliable* correspondences,
not full anchor coverage) and is left untouched. This module's job is
full coverage: every anchor gets an estimate, even where BlazePose has no
matching point at all — those 8 anchors (`head_top`, `cap_band_front`,
both collar tips, both chest pockets, both sleeve-uppers) are geometric
heuristics derived from the *other* visible landmarks, not real
detections, and are confidence-penalized accordingly so a caller can tell
the difference. See
`ChangeRequest/2026-08-11_cv-service-pose-anchor-mapping.md` §4 for the
full per-anchor table and the reasoning behind each fraction constant.

    from pose.anchor_mapping import estimate_anchor_pose
    anchors = estimate_anchor_pose("photo.jpg")
    anchors["left_shoulder_seam"]  # {"x_px": ..., "y_px": ..., "confidence": ...}
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np

import config
from pose.estimate_pose import PoseResult, estimate_pose

VISIBILITY_THRESHOLD = config.MIN_POSE_VISIBILITY  # matches pnp_solve.py's own threshold

# Direct/averaged BlazePose correspondences carry no penalty — they're
# real detections, not guesses. Confidence is the landmark's own
# visibility (or the minimum across the landmarks averaged).
DIRECT_CONFIDENCE_PENALTY = config.DIRECT_CONFIDENCE_PENALTY

# Single-hop interpolations BETWEEN two real, visible landmarks (collar
# tip between shoulder and neck, chest pocket between shoulder and hip,
# sleeve-upper between shoulder and elbow) — a real but bounded geometric
# guess, penalized once.
INTERPOLATION_CONFIDENCE_PENALTY = config.INTERPOLATION_CONFIDENCE_PENALTY

# Extrapolations BEYOND the detected landmarks (head_top, cap_band_front —
# BlazePose has no skull-top point at all) are categorically less
# reliable than interpolating between two known points, and are not
# calibrated against anchors.male.json's own geometry (that file has no
# eye/ear anchor to calibrate the ratio against) — penalized harder.
EXTRAPOLATION_CONFIDENCE_PENALTY = config.EXTRAPOLATION_CONFIDENCE_PENALTY

COLLAR_TIP_LERP_FRACTION = 0.35
CHEST_POCKET_LERP_FRACTION = 0.44  # derived from anchors.male.json's own (shoulder-chest)/(shoulder-belt) ratio
SLEEVE_UPPER_LERP_FRACTION = 0.4
HEAD_TOP_EXTRAPOLATION_FRACTION = 0.4  # rough anatomical approximation, see module docstring
CAP_BAND_LERP_FRACTION = 0.35

_NULL_ESTIMATE = {"x_px": None, "y_px": None, "confidence": 0.0}

_ALL_ANCHOR_NAMES = [
    "head_top",
    "cap_band_front",
    "left_collar_tip",
    "right_collar_tip",
    "left_chest_pocket",
    "right_chest_pocket",
    "left_shoulder_seam",
    "right_shoulder_seam",
    "left_sleeve_upper",
    "right_sleeve_upper",
    "belt_center",
    "left_ankle",
    "right_ankle",
    "left_foot_top",
    "right_foot_top",
    "chest_center",
]


def _point(landmark) -> tuple[float, float] | None:
    if landmark is None or landmark.visibility < VISIBILITY_THRESHOLD:
        return None
    return (landmark.x_px, landmark.y_px)


def _visibility(landmark) -> float:
    return landmark.visibility if landmark is not None else 0.0


def _lerp(a: tuple[float, float], b: tuple[float, float], t: float) -> tuple[float, float]:
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def _midpoint(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float]:
    return ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)


def _direct(pose: PoseResult, landmark_name: str) -> dict:
    landmark = pose.named(landmark_name)
    point = _point(landmark)
    if point is None:
        return dict(_NULL_ESTIMATE)
    return {"x_px": point[0], "y_px": point[1], "confidence": _visibility(landmark) * DIRECT_CONFIDENCE_PENALTY}


def _midpoint_of_two(pose: PoseResult, name_a: str, name_b: str) -> dict:
    a, b = pose.named(name_a), pose.named(name_b)
    pa, pb = _point(a), _point(b)
    if pa is None or pb is None:
        return dict(_NULL_ESTIMATE)
    mid = _midpoint(pa, pb)
    confidence = min(_visibility(a), _visibility(b)) * DIRECT_CONFIDENCE_PENALTY
    return {"x_px": mid[0], "y_px": mid[1], "confidence": confidence}


def _interpolated(pose: PoseResult, from_name: str, to_name: str, fraction: float) -> dict:
    a, b = pose.named(from_name), pose.named(to_name)
    pa, pb = _point(a), _point(b)
    if pa is None or pb is None:
        return dict(_NULL_ESTIMATE)
    point = _lerp(pa, pb, fraction)
    confidence = min(_visibility(a), _visibility(b)) * INTERPOLATION_CONFIDENCE_PENALTY
    return {"x_px": point[0], "y_px": point[1], "confidence": confidence}


def _head_top(pose: PoseResult) -> dict:
    left_shoulder, right_shoulder = pose.named("left_shoulder"), pose.named("right_shoulder")
    shoulder_pts = _point(left_shoulder), _point(right_shoulder)
    if shoulder_pts[0] is None or shoulder_pts[1] is None:
        return dict(_NULL_ESTIMATE)
    shoulder_mid = _midpoint(shoulder_pts[0], shoulder_pts[1])
    shoulder_visibility = min(_visibility(left_shoulder), _visibility(right_shoulder))

    # Prefer the ear midpoint as the face reference (most stable, least
    # affected by head turn), fall back to eyes, then nose.
    for a_name, b_name in (("left_ear", "right_ear"), ("left_eye", "right_eye")):
        a, b = pose.named(a_name), pose.named(b_name)
        pa, pb = _point(a), _point(b)
        if pa is not None and pb is not None:
            face_ref = _midpoint(pa, pb)
            face_visibility = min(_visibility(a), _visibility(b))
            break
    else:
        nose = pose.named("nose")
        nose_pt = _point(nose)
        if nose_pt is None:
            return dict(_NULL_ESTIMATE)
        face_ref = nose_pt
        face_visibility = _visibility(nose)

    face_span = shoulder_mid[1] - face_ref[1]  # positive: face is above shoulders in pixel space
    head_top_y = face_ref[1] - face_span * HEAD_TOP_EXTRAPOLATION_FRACTION
    confidence = min(shoulder_visibility, face_visibility) * EXTRAPOLATION_CONFIDENCE_PENALTY
    return {"x_px": face_ref[0], "y_px": head_top_y, "confidence": confidence}


def _cap_band_front(pose: PoseResult, head_top: dict) -> dict:
    if head_top["confidence"] <= 0.0:
        return dict(_NULL_ESTIMATE)
    nose = pose.named("nose")
    nose_pt = _point(nose)
    if nose_pt is None:
        return dict(_NULL_ESTIMATE)
    head_top_pt = (head_top["x_px"], head_top["y_px"])
    point = _lerp(nose_pt, head_top_pt, CAP_BAND_LERP_FRACTION)
    confidence = min(_visibility(nose), head_top["confidence"]) * EXTRAPOLATION_CONFIDENCE_PENALTY
    return {"x_px": point[0], "y_px": point[1], "confidence": confidence}


def _chest_center(left_chest_pocket: dict, right_chest_pocket: dict) -> dict:
    """Derived the same way `utils/extract_anchors.py` derives the 3D
    version: the midpoint of the left/right pair, not a fresh estimate."""
    if left_chest_pocket["confidence"] <= 0.0 or right_chest_pocket["confidence"] <= 0.0:
        return dict(_NULL_ESTIMATE)
    mid = _midpoint(
        (left_chest_pocket["x_px"], left_chest_pocket["y_px"]),
        (right_chest_pocket["x_px"], right_chest_pocket["y_px"]),
    )
    confidence = min(left_chest_pocket["confidence"], right_chest_pocket["confidence"])
    return {"x_px": mid[0], "y_px": mid[1], "confidence": confidence}


def _interpolated_via_midpoint(pose: PoseResult, shoulder_name: str, fraction: float) -> dict:
    """Collar tip: partway from the shoulder toward the shoulder-midpoint
    ("neck"), which needs BOTH shoulders even though the anchor itself is
    single-sided."""
    left_shoulder, right_shoulder = pose.named("left_shoulder"), pose.named("right_shoulder")
    shoulder = pose.named(shoulder_name)
    p_left, p_right, p_shoulder = _point(left_shoulder), _point(right_shoulder), _point(shoulder)
    if p_left is None or p_right is None or p_shoulder is None:
        return dict(_NULL_ESTIMATE)
    neck_mid = _midpoint(p_left, p_right)
    point = _lerp(p_shoulder, neck_mid, fraction)
    confidence = min(_visibility(left_shoulder), _visibility(right_shoulder)) * INTERPOLATION_CONFIDENCE_PENALTY
    return {"x_px": point[0], "y_px": point[1], "confidence": confidence}


_OFFSETS_PATH = Path(__file__).resolve().parent / "anchor_offsets.male.json"
_offsets_cache: dict | None = None


def _load_offsets() -> dict:
    global _offsets_cache
    if _offsets_cache is None:
        _offsets_cache = json.loads(_OFFSETS_PATH.read_text())["offsets"] if _OFFSETS_PATH.exists() else {}
    return _offsets_cache


def body_frame(estimate: dict[str, dict]):
    """Body-aligned 2D frame from the two shoulder estimates:
    `(origin, outward_x, down, shoulder_width_px)` where `outward_x` is the
    unit vector from the wearer's right shoulder to their left (image +x
    for a front photo) and `down` is perpendicular, pointing toward the
    hips. `None` when either shoulder is missing."""
    left, right = estimate.get("left_shoulder_seam"), estimate.get("right_shoulder_seam")
    if not left or not right or left["x_px"] is None or right["x_px"] is None:
        return None
    lp, rp = np.array([left["x_px"], left["y_px"]]), np.array([right["x_px"], right["y_px"]])
    width = float(np.linalg.norm(lp - rp))
    if width < 1e-6:
        return None
    outward_x = (lp - rp) / width
    down = np.array([-outward_x[1], outward_x[0]])
    return (lp + rp) / 2, outward_x, down, width


def apply_anchor_offsets(estimate: dict[str, dict], offsets: dict | None = None) -> dict[str, dict]:
    """Applies the fitted per-anchor bias corrections from
    `pose/calibrate_anchor_offsets.py` (see its docstring for why they
    exist). Each corrected estimate gains `calibrated: True` and
    `residual_px` — the fit's residual spread in pixels, which the
    verdict engine's uncertainty model uses (A5)."""
    offsets = _load_offsets() if offsets is None else offsets
    frame = body_frame(estimate)
    if not offsets or frame is None:
        return estimate
    _, outward_x, down, width = frame
    corrected = {}
    for name, est in estimate.items():
        o = offsets.get(name)
        if o is None or est["x_px"] is None:
            corrected[name] = est
            continue
        side = -1.0 if name.startswith("right_") else 1.0
        shift = width * (side * o["outward"] * outward_x + o["down"] * down)
        corrected[name] = {
            **est,
            "x_px": est["x_px"] + float(shift[0]),
            "y_px": est["y_px"] + float(shift[1]),
            "calibrated": True,
            "residual_px": o["residual_std"] * width,
        }
    return corrected


def map_pose_to_anchors(pose: PoseResult, *, apply_offsets: bool = True) -> dict[str, dict]:
    """Pure function: a `PoseResult` in, all 16 `anchors.male.json` keys
    out, each `{"x_px": float | None, "y_px": float | None, "confidence":
    float}`. `confidence == 0.0` (with null coordinates) means the
    required BlazePose landmark(s) weren't visible enough to estimate
    this anchor at all — never a silently-wrong guess."""
    if not pose.found:
        return {name: dict(_NULL_ESTIMATE) for name in _ALL_ANCHOR_NAMES}

    result: dict[str, dict] = {}
    result["left_shoulder_seam"] = _direct(pose, "left_shoulder")
    result["right_shoulder_seam"] = _direct(pose, "right_shoulder")
    result["left_ankle"] = _direct(pose, "left_ankle")
    result["right_ankle"] = _direct(pose, "right_ankle")
    result["left_foot_top"] = _direct(pose, "left_foot_index")
    result["right_foot_top"] = _direct(pose, "right_foot_index")
    result["belt_center"] = _midpoint_of_two(pose, "left_hip", "right_hip")

    result["left_collar_tip"] = _interpolated_via_midpoint(pose, "left_shoulder", COLLAR_TIP_LERP_FRACTION)
    result["right_collar_tip"] = _interpolated_via_midpoint(pose, "right_shoulder", COLLAR_TIP_LERP_FRACTION)

    result["left_chest_pocket"] = _interpolated(pose, "left_shoulder", "left_hip", CHEST_POCKET_LERP_FRACTION)
    result["right_chest_pocket"] = _interpolated(pose, "right_shoulder", "right_hip", CHEST_POCKET_LERP_FRACTION)

    result["left_sleeve_upper"] = _interpolated(pose, "left_shoulder", "left_elbow", SLEEVE_UPPER_LERP_FRACTION)
    result["right_sleeve_upper"] = _interpolated(pose, "right_shoulder", "right_elbow", SLEEVE_UPPER_LERP_FRACTION)

    head_top = _head_top(pose)
    result["head_top"] = head_top
    result["cap_band_front"] = _cap_band_front(pose, head_top)

    if apply_offsets and config.APPLY_ANCHOR_OFFSETS:
        result = apply_anchor_offsets(result)
    result["chest_center"] = _chest_center(result["left_chest_pocket"], result["right_chest_pocket"])

    return result


def estimate_anchor_pose(image_path: str, *, person_box=None, apply_offsets: bool = True) -> dict[str, dict]:
    """`image_path -> dict` convenience wrapper: runs Stage 2's pose
    estimator (on the person crop when `person_box` is given — see
    `estimate_pose`), then maps it onto all 16 anchor names in one call."""
    return map_pose_to_anchors(estimate_pose(image_path, person_box=person_box), apply_offsets=apply_offsets)

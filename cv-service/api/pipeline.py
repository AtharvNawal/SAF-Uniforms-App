"""The `/check_uniform` pipeline as a plain function.

Shared by `POST /check_uniform`, `POST /check_uniform_burst` (D17) and the
synthetic violation benchmark (`evaluation/run_violation_benchmark.py`,
C14), so all three measure exactly the same code. Every stage added by
ChangeRequest/2026-09-28_accuracy-program-no-real-data.md is here, in
order:

  0  image-quality gate                         api/validation.py
  1  person detection                           pose/detect_person.py
  2  segmentation (+ test-time augmentation A6) segmentation/segment_uniform.py
  3  pose on the person crop (A1) → anchors with fitted bias corrections
                                                pose/anchor_mapping.py
  4  mask-refined anchors (A2)                  geometry/mask_anchor_refinement.py
  5  intrinsics from EXIF / the app (D16), anchors scaled to the wearer's
     height (D16), PnP + gravity prior (D16)    geometry/solve_camera_pose.py
  6  rule resolution with per-point scale (A4) + uncertainty (A5)
  7  two-stage small-item pass (B13)            segmentation/two_stage.py
  8  zero-shot fill for empty search boxes (B7) detectors/zero_shot.py
  9  geometric verdicts (A3/A5)                 rules/rule_engine.py
  10 colour (B10), variant (B9), name-tag OCR (B8) checks
  11 response + per-item instructions (E18)     api/response_schema.py
"""

from __future__ import annotations

from dataclasses import dataclass

import cv2

import config
from api.intrinsics import resolve_intrinsics
from api.response_schema import build_check_uniform_response
from api.validation import check_sharpness, validate_image
from detectors.color_check import check_colors
from detectors.name_tag_ocr import check_name_tag
from detectors.variant_matcher import check_variants
from detectors.zero_shot import fill_missed_detections
from geometry.mask_anchor_refinement import refine_anchors_with_masks
from geometry.project_rules import cm_per_px_from_anchor_pose
from geometry.solve_camera_pose import gravity_disagreement_deg
from geometry.solve_camera_pose import solve_camera_pose as solve_camera_pose_v2
from pose.anchor_mapping import estimate_anchor_pose
from pose.detect_person import detect_person
from reporting.report import render_debug_image_b64
from rules.rule_engine import evaluate_verdicts, load_anchors, load_rules, resolve_rules
from segmentation.segment_uniform import segment_uniform
from segmentation.two_stage import refine_small_items

SUPPORTED_UNIFORM_TYPES = {"army_no3_male"}

# `assets/3d/bodies/male_apose.glb` was normalised to this stature by
# `tool/inject_sockets.py --target-height 1.78` (CLAUDE.md §8, pass 3);
# the anchor file's coordinates are in that body's metres.
REFERENCE_STATURE_M = 1.78


@dataclass(frozen=True)
class CheckParams:
    uniform_type: str
    rank_tier: str
    gender: str = "male"
    is_sikh: bool = False
    medal_row_count: int = 0
    view: str = "front"
    body_type: str = "male"
    include_debug_image: bool = False
    # D16 / B8 — all optional; each only improves the measurement.
    wearer_name: str | None = None
    height_cm: float | None = None
    focal_length_px: float | None = None
    gravity_up_cam: tuple[float, float, float] | None = None


class CheckError(Exception):
    """A typed, user-facing failure (`status` is the stable error code)."""

    def __init__(self, status_code: int, status: str, message: str, **extra):
        super().__init__(message)
        self.status_code, self.status, self.message, self.extra = status_code, status, message, extra


def scaled_anchors(height_cm: float | None) -> tuple[dict, float]:
    """Anchors scaled uniformly about the feet to the wearer's height (the
    doctrine cm offsets on top of them stay absolute). A 1.70 m wearer
    measured against a 1.78 m reference body otherwise shifts every
    projected point and puts the solved camera ~5% too far away."""
    anchors = load_anchors()
    if not height_cm or not (config.MIN_HEIGHT_CM <= height_cm <= config.MAX_HEIGHT_CM):
        return anchors, 1.0
    scale = (height_cm / 100.0) / REFERENCE_STATURE_M
    return {name: {**a, "x": a["x"] * scale, "y": a["y"] * scale, "z": a["z"] * scale} for name, a in anchors.items()}, scale


@dataclass
class Geometry:
    """Everything up to and including rule resolution (stages 0-6)."""

    detection: object
    validation: object
    image_bgr: object
    segmentation: object
    anchor_pose: dict
    intrinsics: object
    anchors: dict
    height_scale: float
    camera: object
    cm_per_px: float
    all_rules: list
    resolved: list


def solve_geometry(image_path: str, params: CheckParams) -> Geometry:
    """Stages 0-6 of the pipeline. Raises `CheckError` for every
    condition the photo can't be judged under."""
    if params.uniform_type not in SUPPORTED_UNIFORM_TYPES:
        raise CheckError(
            422, "UNSUPPORTED_UNIFORM",
            f"'{params.uniform_type}' is not a supported uniform_type. Supported: {sorted(SUPPORTED_UNIFORM_TYPES)}.",
        )

    # Blur is judged on the person, after detection (see check_sharpness).
    validation = validate_image(image_path, check_blur=False)
    if not validation.usable:
        raise CheckError(422, validation.status, validation.message)

    detection = detect_person(image_path)
    if not detection.accepted:
        if detection.reason == "no_person_detected":
            raise CheckError(422, "NO_PERSON_DETECTED",
                             "No person was detected in the photo. Please retake with the full body clearly visible.",
                             candidate_count=detection.candidate_count)
        raise CheckError(422, "MULTIPLE_PEOPLE_DETECTED",
                         "Multiple people were detected. Please retake with only the wearer in frame.",
                         candidate_count=detection.candidate_count)

    image_bgr = cv2.imread(image_path)
    height_px, width_px = image_bgr.shape[:2]
    sharpness = check_sharpness(image_bgr, detection.person)
    if not sharpness.usable:
        raise CheckError(422, sharpness.status, sharpness.message)

    try:
        segmentation = segment_uniform(image_path)
    except FileNotFoundError:
        raise CheckError(503, "SEGMENTER_UNAVAILABLE", "The uniform segmentation model is not installed on this server.")

    anchor_pose = estimate_anchor_pose(image_path, person_box=detection.person)
    anchor_pose = refine_anchors_with_masks(anchor_pose, segmentation)

    intrinsics = resolve_intrinsics(image_path, width_px, height_px, params.focal_length_px)
    anchors, height_scale = scaled_anchors(params.height_cm)
    camera = solve_camera_pose_v2(
        anchor_pose, width_px, height_px, anchors=anchors,
        focal_px=intrinsics.focal_px, gravity_up_cam=params.gravity_up_cam,
    )
    if not camera.solved or not camera.reliable:
        raise CheckError(
            422, "POSE_UNRELIABLE",
            "Could not reliably determine the camera angle from this photo. Please retake per the capture "
            "protocol: front-facing, arms relaxed at sides, full torso visible.",
            reprojection_error_px=camera.reprojection_error_px,
        )

    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose, anchors)
    if not cm_per_px:
        raise CheckError(422, "SCALE_UNAVAILABLE",
                         "Could not determine physical scale from this photo (shoulders not clearly visible). "
                         "Please retake with both shoulders in frame.")

    profile = {"rank_tier": params.rank_tier, "gender": params.gender, "isSikh": params.is_sikh, "medalRowCount": params.medal_row_count}
    all_rules = load_rules()
    resolved = resolve_rules(camera, cm_per_px, profile=profile, rules=all_rules, anchors=anchors)
    if not resolved:
        raise CheckError(500, "NO_RULES", "No doctrine rules resolved for this profile.")
    return Geometry(detection, validation, image_bgr, segmentation, anchor_pose, intrinsics, anchors,
                    height_scale, camera, cm_per_px, all_rules, resolved)


def run_check(image_path: str, params: CheckParams) -> dict:
    """Runs the full pipeline on one photo. Raises `CheckError` for every
    condition the photo can't be judged under."""
    g = solve_geometry(image_path, params)
    detection, validation, image_bgr, camera = g.detection, g.validation, g.image_bgr, g.camera
    segmentation, resolved, all_rules, cm_per_px = g.segmentation, g.resolved, g.all_rules, g.cm_per_px
    intrinsics, height_scale = g.intrinsics, g.height_scale
    height_px, width_px = image_bgr.shape[:2]

    segmentation = refine_small_items(image_bgr, resolved, segmentation)
    segmentation = fill_missed_detections(image_bgr, resolved, segmentation)

    verdicts = evaluate_verdicts(resolved, segmentation, cm_per_px, width_px, height_px, camera_reliable=camera.reliable)
    rules_by_id = {r["object"]: r for r in all_rules}
    if config.COLOR_CHECK_ENABLED:
        verdicts = check_colors(verdicts, rules_by_id, image_bgr, segmentation)
    if config.VARIANT_CHECK_ENABLED:
        verdicts = check_variants(verdicts, all_rules, image_bgr, {r.object_id: r.category for r in resolved})
    if config.NAME_TAG_OCR_ENABLED:
        verdicts = check_name_tag(verdicts, image_bgr, params.wearer_name)

    response = build_check_uniform_response(
        resolved, verdicts, detection, validation.usable, validation.confidence, class_names=segmentation.class_names,
    )
    response["camera"] = {
        "focal_length_px": round(float(camera.camera_matrix[0, 0]), 1),
        "focal_source": intrinsics.source,
        "reprojection_error_px": round(camera.reprojection_error_px, 2),
        "correspondence_count": camera.correspondence_count,
        "gravity_disagreement_deg": round(gravity_disagreement_deg(camera.rotation_vec, params.gravity_up_cam), 1)
        if params.gravity_up_cam else None,
        "height_scale": round(height_scale, 3),
    }
    if intrinsics.source == "assumed":
        response["image_quality"]["note"] = (
            "Camera focal length unknown (no EXIF, none sent) — distances are less accurate; "
            "send focal_length_px or keep the photo's EXIF data."
        )
    if params.view != "front" or params.body_type != "male":
        response["image_quality"]["note"] = (
            f"view='{params.view}', body_type='{params.body_type}' — only front/male doctrine exists today; "
            "results may be unreliable."
        )
    if params.include_debug_image:
        response["debug_image_base64"] = render_debug_image_b64(image_bgr, verdicts)
    return response


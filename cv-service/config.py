"""Central configuration — every confidence threshold, tolerance
multiplier, and image-quality cutoff used across the pipeline, in one
place with an optional environment-variable override.

Before this module existed, these numbers were scattered as local
per-file constants (some duplicated verbatim, e.g. the segmentation
minimum-confidence `0.4` was defined separately in both
`rules/rule_engine.py` and `segmentation/segment_uniform.py`). This is
a behavior-preserving consolidation — every default value here matches
what the code already used; nothing was re-tuned. See
`ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md`.

Each constant can be overridden via an environment variable named
`CV_SERVICE_<CONSTANT_NAME>` (same pattern already used for
`ANTHROPIC_API_KEY`), which is useful for tuning against real photos
once any exist without editing source.
"""

from __future__ import annotations

import os


def _float_env(name: str, default: float) -> float:
    raw = os.environ.get(f"CV_SERVICE_{name}")
    return float(raw) if raw is not None else default


def _int_env(name: str, default: int) -> int:
    raw = os.environ.get(f"CV_SERVICE_{name}")
    return int(raw) if raw is not None else default


def _bool_env(name: str, default: bool) -> bool:
    raw = os.environ.get(f"CV_SERVICE_{name}")
    return raw.strip().lower() in ("1", "true", "yes") if raw is not None else default


# --- Deployment: auth (api/auth.py) ------------------------------------------
# Require a Firebase ID token on every analysis endpoint. Off locally / in
# tests; the Cloud Run deployment sets CV_SERVICE_REQUIRE_AUTH=1.
REQUIRE_AUTH = _bool_env("REQUIRE_AUTH", False)
FIREBASE_PROJECT_ID = os.environ.get("CV_SERVICE_FIREBASE_PROJECT_ID", "saf-uniforms")


# --- Stage 1: person detection (pose/detect_person.py) ---------------------
MIN_PERSON_CONFIDENCE = _float_env("MIN_PERSON_CONFIDENCE", 0.6)

# --- Stage 2: pose / anchor mapping (pose/anchor_mapping.py) ---------------
# Matches calibration/pnp_solve.py's own inline landmark-visibility gate.
MIN_POSE_VISIBILITY = _float_env("MIN_POSE_VISIBILITY", 0.5)
DIRECT_CONFIDENCE_PENALTY = _float_env("DIRECT_CONFIDENCE_PENALTY", 1.0)
INTERPOLATION_CONFIDENCE_PENALTY = _float_env("INTERPOLATION_CONFIDENCE_PENALTY", 0.6)
EXTRAPOLATION_CONFIDENCE_PENALTY = _float_env("EXTRAPOLATION_CONFIDENCE_PENALTY", 0.35)

# A1 (ChangeRequest/2026-09-28_accuracy-program-no-real-data.md): pose
# model variant ("heavy" falls back to "lite" when the file is absent),
# and pose-on-person-crop — the detected person box is padded, then
# upscaled so its height is at least POSE_CROP_MIN_HEIGHT_PX (capped at
# POSE_CROP_MAX_UPSCALE) before landmarking.
POSE_MODEL_VARIANT = os.environ.get("CV_SERVICE_POSE_MODEL_VARIANT", "heavy")
POSE_CROP_PADDING = _float_env("POSE_CROP_PADDING", 0.15)
POSE_CROP_MIN_HEIGHT_PX = _int_env("POSE_CROP_MIN_HEIGHT_PX", 1024)
POSE_CROP_MAX_UPSCALE = _float_env("POSE_CROP_MAX_UPSCALE", 3.0)
# Apply pose/anchor_offsets.male.json's fitted landmark→socket bias
# corrections (pose/calibrate_anchor_offsets.py).
APPLY_ANCHOR_OFFSETS = os.environ.get("CV_SERVICE_APPLY_ANCHOR_OFFSETS", "1") != "0"

# --- Stage 3: camera-pose recovery (calibration/pnp_solve.py) --------------
# Reprojection-error reliability gate, scaled to the subject's own
# measured shoulder width (or image size when unavailable).
PNP_RELIABILITY_SHOULDER_WIDTH_FRACTION = _float_env("PNP_RELIABILITY_SHOULDER_WIDTH_FRACTION", 0.4)
PNP_RELIABILITY_IMAGE_SIZE_FRACTION = _float_env("PNP_RELIABILITY_IMAGE_SIZE_FRACTION", 0.03)

# --- Stage 3b: camera-pose recovery, v2 (geometry/solve_camera_pose.py) ----
# A straight 0.5 visibility-style cutoff would exclude nearly every
# heuristic (interpolated/extrapolated) anchor pose/anchor_mapping.py
# produces even at high underlying visibility — see that module's plan
# file §3. 6 correspondences gives a stability margin above solvePnP's
# mathematical minimum of 4.
PNP_V2_MIN_CONFIDENCE = _float_env("PNP_V2_MIN_CONFIDENCE", 0.3)
PNP_V2_MIN_CORRESPONDENCES = _int_env("PNP_V2_MIN_CORRESPONDENCES", 6)

# D16: weight of the phone-accelerometer gravity prior in the PnP
# refinement — 1° of pitch/roll disagreement costs this many px of
# reprojection error.
GRAVITY_PRIOR_PX_PER_DEG = _float_env("GRAVITY_PRIOR_PX_PER_DEG", 3.0)
# Weighted PnP refinement: each correspondence weighted by 1/its calibrated
# residual spread (floored at PNP_MIN_SIGMA_PX).
PNP_WEIGHTED_REFINEMENT = os.environ.get("CV_SERVICE_PNP_WEIGHTED_REFINEMENT", "1") != "0"
PNP_MIN_SIGMA_PX = _float_env("PNP_MIN_SIGMA_PX", 2.0)

# --- Stage 4: segmentation (segmentation/segment_uniform.py) ---------------
MIN_SEGMENT_CONFIDENCE = _float_env("MIN_SEGMENT_CONFIDENCE", 0.4)
# Below this, a matched region is reported `visibility="partially_visible"`
# rather than `"visible"` in the enriched VerdictResult (new — see the
# check_uniform-api-contract plan).
PARTIAL_VISIBILITY_CONFIDENCE_MULTIPLIER = _float_env("PARTIAL_VISIBILITY_CONFIDENCE_MULTIPLIER", 1.5)
# Which trained model to load ("" = prefer segmentation_v2, else v1).
SEGMENTATION_MODEL = os.environ.get("CV_SERVICE_SEGMENTATION_MODEL", "")
# A6: test-time augmentation on the full-image segmentation pass.
SEGMENTATION_TTA = os.environ.get("CV_SERVICE_SEGMENTATION_TTA", "1") != "0"
# B13: second, upscaled segmentation pass over each small item's search
# box. Categories it runs for, the crop's padding (× search box size) and
# the size the crop's long side is upscaled to.
TWO_STAGE_ENABLED = os.environ.get("CV_SERVICE_TWO_STAGE_ENABLED", "1") != "0"
TWO_STAGE_CATEGORIES = frozenset(os.environ.get(
    "CV_SERVICE_TWO_STAGE_CATEGORIES",
    "cap_badge,arms_badge,sleeve_rank_specialist,sleeve_rank_enlistee,name_tag,epaulette",
).split(","))
TWO_STAGE_PADDING = _float_env("TWO_STAGE_PADDING", 1.0)
TWO_STAGE_CROP_SIZE_PX = _int_env("TWO_STAGE_CROP_SIZE_PX", 640)
# Two detections of the same class overlapping more than this (IoU) are
# treated as the same object when merging passes.
MERGE_IOU_THRESHOLD = _float_env("MERGE_IOU_THRESHOLD", 0.3)

# --- Stage 6: rule engine — geometry half (rules/rule_engine.py) -----------
DEFAULT_CROP_RADIUS_CM = _float_env("DEFAULT_CROP_RADIUS_CM", 8.0)
TOLERANCE_TO_CROP_MULTIPLIER = _float_env("TOLERANCE_TO_CROP_MULTIPLIER", 2.5)
MIN_CROP_RADIUS_CM = _float_env("MIN_CROP_RADIUS_CM", 4.0)

# --- Stage 6: rule engine — verdict half (rules/rule_engine.py) ------------
# A position within [tolerance_px, tolerance_px * this] is reported
# "slightly_misaligned" rather than a hard "fail" — avoids a binary cut
# right at the tolerance boundary (new this plan).
SLIGHT_MISALIGNMENT_BAND = _float_env("SLIGHT_MISALIGNMENT_BAND", 1.5)

# A5: measurement uncertainty. Geometric part = this × the camera's mean
# reprojection error (how far the projected anchors sit from the detected
# ones); mask part = this × sqrt(mask area) (centroid/edge jitter of a
# segment grows with its size). Fitted by evaluation/calibrate_uncertainty.py
# on the synthetic violation benchmark to cover 90% of the pipeline's real
# measurement error on correctly placed items, so a correct item is almost
# never flagged. Fitted for the default segmenter (segmentation_v2: median
# error 0.78 cm; the 9-class v1 fit was 1.35 / 0.09 at 1.30 cm). The price:
# ±1 cm tolerances can't be *certified* from one full-body photo, and such
# items come back "too close to call" with the measured offset instead.
UNCERTAINTY_REPROJECTION_WEIGHT = _float_env("UNCERTAINTY_REPROJECTION_WEIGHT", 0.75)
UNCERTAINTY_MASK_FRACTION = _float_env("UNCERTAINTY_MASK_FRACTION", 0.37)

# --- Stage 7: report synthesis (reporting/report.py) -----------------------
# (score, label) pairs, highest threshold first — first match wins.
STATUS_SCORE_THRESHOLDS = [
    (_float_env("STATUS_THRESHOLD_FULLY_COMPLIANT", 95), "Fully Compliant"),
    (_float_env("STATUS_THRESHOLD_MINOR_ISSUES", 75), "Minor Issues"),
    (_float_env("STATUS_THRESHOLD_MULTIPLE_ISSUES", 50), "Multiple Issues"),
]
DEFAULT_STATUS_LABEL = "Non-Compliant"
# Minimum fraction of detector-backed required items that must receive a
# definite verdict (pass / slightly_misaligned / fail / missing) before
# `/check_uniform` may report PASS — below it the overall status is
# INCOMPLETE (or FAIL if a definite violation was already found). See
# ChangeRequest/2026-09-28_cv-service-coverage-gate-and-matching.md.
MIN_VERIFIED_COVERAGE = _float_env("MIN_VERIFIED_COVERAGE", 0.8)

# --- Stage 0 (new): image-quality validation (api/validation.py) ----------
MIN_IMAGE_WIDTH_PX = _int_env("MIN_IMAGE_WIDTH_PX", 480)
MIN_IMAGE_HEIGHT_PX = _int_env("MIN_IMAGE_HEIGHT_PX", 640)
MAX_IMAGE_BYTES = _int_env("MAX_IMAGE_BYTES", 20 * 1024 * 1024)  # 20 MiB
MIN_BRIGHTNESS = _float_env("MIN_BRIGHTNESS", 25.0)   # mean pixel value, 0-255
MAX_BRIGHTNESS = _float_env("MAX_BRIGHTNESS", 230.0)  # mean pixel value, 0-255
MIN_BLUR_VARIANCE = _float_env("MIN_BLUR_VARIANCE", 60.0)  # Laplacian variance

# --- Accuracy program (ChangeRequest/2026-09-28_accuracy-program-no-real-data.md)
# A2: segmentation-mask anchor refinement before the camera solve.
MASK_ANCHOR_REFINEMENT = os.environ.get("CV_SERVICE_MASK_ANCHOR_REFINEMENT", "1") != "0"
MASK_ANCHOR_MAX_SHIFT_SW = _float_env("MASK_ANCHOR_MAX_SHIFT_SW", 0.5)  # × shoulder width
MASK_ANCHOR_CONFIDENCE = _float_env("MASK_ANCHOR_CONFIDENCE", 0.85)
MASK_ANCHOR_RESIDUAL_SW = _float_env("MASK_ANCHOR_RESIDUAL_SW", 0.03)

# B7: zero-shot (YOLO-World + SAM 2) fill for search boxes the trained
# segmenter left empty. YOLO-World's open-vocabulary scores run low, hence
# the low floor.
# Accept threshold and classes measured on synthetic renders — see
# detectors/zero_shot.py's docstring (true large items 0.61-0.91, a bare
# head scored 0.18 as "beret", small items < 0.2 even when present).
ZERO_SHOT_ENABLED = os.environ.get("CV_SERVICE_ZERO_SHOT_ENABLED", "1") != "0"
ZERO_SHOT_ACCEPT_CONFIDENCE = _float_env("ZERO_SHOT_ACCEPT_CONFIDENCE", 0.45)
ZERO_SHOT_CLASSES = frozenset(os.environ.get("CV_SERVICE_ZERO_SHOT_CLASSES", "headwear,belt,footwear").split(","))

# B8: name-tag OCR vs the profile surname (fuzzy match ratio 0-1).
NAME_TAG_OCR_ENABLED = os.environ.get("CV_SERVICE_NAME_TAG_OCR_ENABLED", "1") != "0"
NAME_MATCH_OK = _float_env("NAME_MATCH_OK", 0.8)
NAME_MATCH_FAIL = _float_env("NAME_MATCH_FAIL", 0.5)

# B9: badge-variant check — a different variant must beat the expected one
# by this much cosine similarity before the item is failed.
VARIANT_CHECK_ENABLED = os.environ.get("CV_SERVICE_VARIANT_CHECK_ENABLED", "1") != "0"
VARIANT_MARGIN = _float_env("VARIANT_MARGIN", 0.05)

# B10: "black" = median brightness ≤ this × the shirt's, and median
# saturation ≤ this (0-255).
COLOR_CHECK_ENABLED = os.environ.get("CV_SERVICE_COLOR_CHECK_ENABLED", "1") != "0"
BLACK_MAX_RELATIVE_BRIGHTNESS = _float_env("BLACK_MAX_RELATIVE_BRIGHTNESS", 0.45)
BLACK_MAX_SATURATION = _float_env("BLACK_MAX_SATURATION", 110.0)

# D16: reference body height the anchor file was measured on is read from
# anchors.male.json; a profile height scales the anchors to the wearer.
USE_EXIF_INTRINSICS = os.environ.get("CV_SERVICE_USE_EXIF_INTRINSICS", "1") != "0"
MIN_HEIGHT_CM = _float_env("MIN_HEIGHT_CM", 140.0)
MAX_HEIGHT_CM = _float_env("MAX_HEIGHT_CM", 210.0)

# E18: error components smaller than this aren't mentioned in the
# user-facing instruction.
INSTRUCTION_MIN_CM = _float_env("INSTRUCTION_MIN_CM", 0.3)

# D17: burst — majority vote across frames.
BURST_MAX_FRAMES = _int_env("BURST_MAX_FRAMES", 5)
HF_EVIDENCE_ENABLED = os.getenv("CV_SERVICE_HF_EVIDENCE_ENABLED", "0").lower() in {"1", "true", "yes"}
HF_SIGLIP_MODEL = os.getenv("CV_SERVICE_HF_SIGLIP_MODEL", "google/siglip2-so400m-patch14-384")
HF_FLORENCE_MODEL = os.getenv("CV_SERVICE_HF_FLORENCE_MODEL", "microsoft/Florence-2-large-ft")
HF_DINOV2_MODEL = os.getenv("CV_SERVICE_HF_DINOV2_MODEL", "facebook/dinov2-base")
HF_UNIFORM_MIN_CONFIDENCE = _float_env("HF_UNIFORM_MIN_CONFIDENCE", 0.90)

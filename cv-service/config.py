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


# --- Stage 1: person detection (pose/detect_person.py) ---------------------
MIN_PERSON_CONFIDENCE = _float_env("MIN_PERSON_CONFIDENCE", 0.6)

# --- Stage 2: pose / anchor mapping (pose/anchor_mapping.py) ---------------
# Matches calibration/pnp_solve.py's own inline landmark-visibility gate.
MIN_POSE_VISIBILITY = _float_env("MIN_POSE_VISIBILITY", 0.5)
DIRECT_CONFIDENCE_PENALTY = _float_env("DIRECT_CONFIDENCE_PENALTY", 1.0)
INTERPOLATION_CONFIDENCE_PENALTY = _float_env("INTERPOLATION_CONFIDENCE_PENALTY", 0.6)
EXTRAPOLATION_CONFIDENCE_PENALTY = _float_env("EXTRAPOLATION_CONFIDENCE_PENALTY", 0.35)

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

# --- Stage 4: segmentation (segmentation/segment_uniform.py) ---------------
MIN_SEGMENT_CONFIDENCE = _float_env("MIN_SEGMENT_CONFIDENCE", 0.4)
# Below this, a matched region is reported `visibility="partially_visible"`
# rather than `"visible"` in the enriched VerdictResult (new — see the
# check_uniform-api-contract plan).
PARTIAL_VISIBILITY_CONFIDENCE_MULTIPLIER = _float_env("PARTIAL_VISIBILITY_CONFIDENCE_MULTIPLIER", 1.5)

# --- Stage 6: rule engine — geometry half (rules/rule_engine.py) -----------
DEFAULT_CROP_RADIUS_CM = _float_env("DEFAULT_CROP_RADIUS_CM", 8.0)
TOLERANCE_TO_CROP_MULTIPLIER = _float_env("TOLERANCE_TO_CROP_MULTIPLIER", 2.5)
MIN_CROP_RADIUS_CM = _float_env("MIN_CROP_RADIUS_CM", 4.0)

# --- Stage 6: rule engine — verdict half (rules/rule_engine.py) ------------
# A position within [tolerance_px, tolerance_px * this] is reported
# "slightly_misaligned" rather than a hard "fail" — avoids a binary cut
# right at the tolerance boundary (new this plan).
SLIGHT_MISALIGNMENT_BAND = _float_env("SLIGHT_MISALIGNMENT_BAND", 1.5)

# --- Stage 7: report synthesis (reporting/report.py) -----------------------
# (score, label) pairs, highest threshold first — first match wins.
STATUS_SCORE_THRESHOLDS = [
    (_float_env("STATUS_THRESHOLD_FULLY_COMPLIANT", 95), "Fully Compliant"),
    (_float_env("STATUS_THRESHOLD_MINOR_ISSUES", 75), "Minor Issues"),
    (_float_env("STATUS_THRESHOLD_MULTIPLE_ISSUES", 50), "Multiple Issues"),
]
DEFAULT_STATUS_LABEL = "Non-Compliant"

# --- Stage 0 (new): image-quality validation (api/validation.py) ----------
MIN_IMAGE_WIDTH_PX = _int_env("MIN_IMAGE_WIDTH_PX", 480)
MIN_IMAGE_HEIGHT_PX = _int_env("MIN_IMAGE_HEIGHT_PX", 640)
MAX_IMAGE_BYTES = _int_env("MAX_IMAGE_BYTES", 20 * 1024 * 1024)  # 20 MiB
MIN_BRIGHTNESS = _float_env("MIN_BRIGHTNESS", 25.0)   # mean pixel value, 0-255
MAX_BRIGHTNESS = _float_env("MAX_BRIGHTNESS", 230.0)  # mean pixel value, 0-255
MIN_BLUR_VARIANCE = _float_env("MIN_BLUR_VARIANCE", 60.0)  # Laplacian variance

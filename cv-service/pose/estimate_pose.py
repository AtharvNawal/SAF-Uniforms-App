"""Stage 2 — pose estimation.

MediaPipe Tasks PoseLandmarker (BlazePose, 33 keypoints), chosen for
the capture-time / lightweight tier per the architecture memo §5. The
server-side primary (RTMPose, for its whole-body keypoint set) is a
later milestone — this wrapper is deliberately swappable: everything
downstream consumes the `PoseResult` dataclass, not MediaPipe's own
types, so RTMPose can drop in later without touching Stage 3+.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks import python as mp_tasks
from mediapipe.tasks.python import vision as mp_vision

import config

_MODELS_DIR = Path(__file__).resolve().parents[1] / "models"


def _model_path() -> Path:
    """`pose_landmarker_<variant>.task` per config.POSE_MODEL_VARIANT,
    falling back to the lite model when the requested one isn't
    downloaded (see models/download_models.sh)."""
    preferred = _MODELS_DIR / f"pose_landmarker_{config.POSE_MODEL_VARIANT}.task"
    return preferred if preferred.exists() else _MODELS_DIR / "pose_landmarker_lite.task"


_MODEL_PATH = _model_path()

# BlazePose's fixed 33-point topology — the indices this project's PnP
# correspondence set (Stage 3) and the general anchor mapping
# (pose/anchor_mapping.py) read by name. `left_eye`/`right_eye` and
# `left_ear`/`right_ear` were added for anchor_mapping.py's head_top /
# cap_band_front heuristics — MediaPipe already returns all 33 landmarks
# per detection, this dict just wasn't naming them yet; existing entries
# and every existing consumer of this dict are unaffected.
LANDMARK_NAMES = {
    0: "nose",
    2: "left_eye",
    5: "right_eye",
    7: "left_ear",
    8: "right_ear",
    11: "left_shoulder",
    12: "right_shoulder",
    13: "left_elbow",
    14: "right_elbow",
    15: "left_wrist",
    16: "right_wrist",
    23: "left_hip",
    24: "right_hip",
    27: "left_ankle",
    28: "right_ankle",
    31: "left_foot_index",
    32: "right_foot_index",
}

_landmarker: mp_vision.PoseLandmarker | None = None


def _get_landmarker() -> mp_vision.PoseLandmarker:
    global _landmarker
    if _landmarker is None:
        options = mp_vision.PoseLandmarkerOptions(
            base_options=mp_tasks.BaseOptions(model_asset_path=str(_MODEL_PATH)),
            running_mode=mp_vision.RunningMode.IMAGE,
            num_poses=1,
        )
        _landmarker = mp_vision.PoseLandmarker.create_from_options(options)
    return _landmarker


@dataclass(frozen=True)
class Landmark2D:
    x_px: float
    y_px: float
    visibility: float
    presence: float


@dataclass(frozen=True)
class PoseResult:
    found: bool
    landmarks: dict[int, Landmark2D]  # keyed by BlazePose index
    image_width: int
    image_height: int

    def named(self, name: str) -> Landmark2D | None:
        for idx, label in LANDMARK_NAMES.items():
            if label == name and idx in self.landmarks:
                return self.landmarks[idx]
        return None

    @property
    def shoulder_width_px(self) -> float | None:
        left = self.named("left_shoulder")
        right = self.named("right_shoulder")
        if left is None or right is None:
            return None
        return abs(right.x_px - left.x_px)


def _crop_for_pose(image_rgb: np.ndarray, person_box) -> tuple[np.ndarray, float, float, float]:
    """Padded, upscaled crop around the detected person. Returns
    `(crop_rgb, x_offset, y_offset, scale)` so crop pixel (u, v) maps
    back to full-image `(x_offset + u / scale, y_offset + v / scale)`."""
    height, width = image_rgb.shape[:2]
    pad_x = (person_box.x2 - person_box.x1) * config.POSE_CROP_PADDING
    pad_y = (person_box.y2 - person_box.y1) * config.POSE_CROP_PADDING
    x1 = int(max(0, person_box.x1 - pad_x))
    y1 = int(max(0, person_box.y1 - pad_y))
    x2 = int(min(width, person_box.x2 + pad_x))
    y2 = int(min(height, person_box.y2 + pad_y))
    crop = image_rgb[y1:y2, x1:x2]
    scale = min(max(1.0, config.POSE_CROP_MIN_HEIGHT_PX / max(1, crop.shape[0])), config.POSE_CROP_MAX_UPSCALE)
    if scale > 1.0:
        crop = cv2.resize(crop, (int(crop.shape[1] * scale), int(crop.shape[0] * scale)), interpolation=cv2.INTER_CUBIC)
    return np.ascontiguousarray(crop), float(x1), float(y1), scale


def estimate_pose(image_path: str, *, person_box=None) -> PoseResult:
    """BlazePose landmarks in full-image pixels. With `person_box` (a
    `pose.detect_person.PersonBox`), landmarking runs on a padded,
    upscaled crop of that person — a small, full-body subject gets many
    more pixels per joint — and is mapped back to full-image pixels."""
    landmarker = _get_landmarker()
    image_bgr = cv2.imread(image_path)  # applies EXIF orientation
    if image_bgr is None:
        raise ValueError(f"could not read image: {image_path}")
    image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    full_h, full_w = image_rgb.shape[:2]

    if person_box is not None:
        crop, x_off, y_off, scale = _crop_for_pose(image_rgb, person_box)
    else:
        crop, x_off, y_off, scale = np.ascontiguousarray(image_rgb), 0.0, 0.0, 1.0
    crop_h, crop_w = crop.shape[:2]
    result = landmarker.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=crop))

    if not result.pose_landmarks:
        return PoseResult(found=False, landmarks={}, image_width=full_w, image_height=full_h)

    pose = result.pose_landmarks[0]  # single-person, per num_poses=1
    landmarks = {
        idx: Landmark2D(
            x_px=x_off + lm.x * crop_w / scale,
            y_px=y_off + lm.y * crop_h / scale,
            visibility=lm.visibility,
            presence=lm.presence,
        )
        for idx, lm in enumerate(pose)
    }
    return PoseResult(found=True, landmarks=landmarks, image_width=full_w, image_height=full_h)

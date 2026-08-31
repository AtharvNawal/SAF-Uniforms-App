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

import mediapipe as mp
from mediapipe.tasks import python as mp_tasks
from mediapipe.tasks.python import vision as mp_vision

_MODEL_PATH = (
    Path(__file__).resolve().parents[1] / "models" / "pose_landmarker_lite.task"
)

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


def estimate_pose(image_path: str) -> PoseResult:
    landmarker = _get_landmarker()
    mp_image = mp.Image.create_from_file(image_path)
    result = landmarker.detect(mp_image)

    if not result.pose_landmarks:
        return PoseResult(
            found=False,
            landmarks={},
            image_width=mp_image.width,
            image_height=mp_image.height,
        )

    pose = result.pose_landmarks[0]  # single-person, per num_poses=1
    landmarks = {
        idx: Landmark2D(
            x_px=lm.x * mp_image.width,
            y_px=lm.y * mp_image.height,
            visibility=lm.visibility,
            presence=lm.presence,
        )
        for idx, lm in enumerate(pose)
    }
    return PoseResult(
        found=True,
        landmarks=landmarks,
        image_width=mp_image.width,
        image_height=mp_image.height,
    )

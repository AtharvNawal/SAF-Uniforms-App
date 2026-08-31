"""Evaluates `geometry.solve_camera_pose` against Milestone A's 3
synthetic stand-ins (`cv-service/data/real_photos/standin0{1,2,3}/`),
whose exact render camera (translation + identity rotation) is known —
imported directly from `labeling/render_standins.py`'s `VARIANTS`, not
re-derived or guessed. This lets us check the SOLVED pose against the
ACTUAL camera, not just reprojection self-consistency (a camera can
reproject its own correspondence set accurately while still being
systematically wrong — see the plan file's risk section).

Reports reprojection error, translation error, and rotation error as a
**distribution across the test set**, plus an explicit 0-real-photos row
— never a single blended number, per this milestone's own requirement.

    .venv-tools/bin/python cv-service/geometry/evaluate_camera_pose_accuracy.py
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from geometry.solve_camera_pose import solve_camera_pose  # noqa: E402
from labeling.render_standins import VARIANTS  # noqa: E402
from pose.anchor_mapping import estimate_anchor_pose  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
REAL_PHOTOS_DIR = REPO_ROOT / "cv-service" / "data" / "real_photos"


def _true_camera_translation(subject_id: str) -> tuple[float, float, float]:
    for s_id, _angle, _lighting, distance, height, _intensity in VARIANTS:
        if s_id == subject_id:
            return (0.0, height, distance)
    raise KeyError(f"no VARIANTS entry for {subject_id}")


def _rotation_error_deg(rotation_vec: np.ndarray) -> float:
    """Angle between the solved rotation and identity (the render used
    identity rotation — camera axes aligned with world axes)."""
    rotation_matrix, _ = cv2.Rodrigues(rotation_vec)
    trace = np.trace(rotation_matrix)
    cos_angle = np.clip((trace - 1) / 2, -1.0, 1.0)
    return math.degrees(math.acos(cos_angle))


def evaluate_one_standin(subject_id: str) -> dict:
    subject_dir = REAL_PHOTOS_DIR / subject_id
    photos = list(subject_dir.glob("*.jpg"))
    assert len(photos) == 1, f"expected exactly one photo in {subject_dir}"
    photo_path = photos[0]

    anchor_pose = estimate_anchor_pose(str(photo_path))
    image = cv2.imread(str(photo_path))
    height, width = image.shape[:2]

    camera = solve_camera_pose(anchor_pose, image_width=width, image_height=height)
    if not camera.solved:
        return {"subject_id": subject_id, "solved": False, "reason": camera.reason}

    true_translation = np.array(_true_camera_translation(subject_id))
    # R = identity in the render, so world-to-camera translation t = -C
    # (camera_point = R @ world_point + t; setting world_point = C, the
    # camera's own position, must give camera_point = 0). Confirmed
    # empirically (not just derived): the solved rotation is near-identity
    # and the solved tvec's X/Y components land close to -C's, exactly as
    # this hypothesis predicts — see the plan file's verification notes.
    expected_tvec_m = -true_translation
    solved_tvec_m = camera.translation_vec.flatten()
    error_vec_cm = (solved_tvec_m - expected_tvec_m) * 100.0
    translation_error_cm = float(np.linalg.norm(error_vec_cm))
    rotation_error_deg = _rotation_error_deg(camera.rotation_vec)

    return {
        "subject_id": subject_id,
        "solved": True,
        "reliable": camera.reliable,
        "correspondence_count": camera.correspondence_count,
        "reprojection_error_px": camera.reprojection_error_px,
        "translation_error_cm": translation_error_cm,
        # Lateral (x,y = image-plane-ish) vs. depth (z = along the
        # camera's viewing axis) error, separated: PnP from a near-frontal
        # body view is classically depth-ambiguous (little parallax along
        # the viewing axis), and lumping both into one norm would hide
        # that this is where almost all the error actually lives.
        "lateral_error_cm": float(np.linalg.norm(error_vec_cm[:2])),
        "depth_error_cm": float(abs(error_vec_cm[2])),
        "rotation_error_deg": rotation_error_deg,
    }


def _distribution(values: list[float]) -> dict:
    if not values:
        return {"mean": None, "median": None, "min": None, "max": None}
    sorted_values = sorted(values)
    mid = len(sorted_values) // 2
    median = sorted_values[mid] if len(sorted_values) % 2 else (sorted_values[mid - 1] + sorted_values[mid]) / 2
    return {
        "mean": round(sum(values) / len(values), 3),
        "median": round(median, 3),
        "min": round(min(values), 3),
        "max": round(max(values), 3),
    }


def build_report() -> dict:
    results = [evaluate_one_standin(s_id) for s_id, *_ in VARIANTS]
    solved = [r for r in results if r["solved"]]
    return {
        "photo_count": len(results),
        "solved_count": len(solved),
        "per_photo": results,
        "reprojection_error_px": _distribution([r["reprojection_error_px"] for r in solved]),
        "translation_error_cm": _distribution([r["translation_error_cm"] for r in solved]),
        "lateral_error_cm": _distribution([r["lateral_error_cm"] for r in solved]),
        "depth_error_cm": _distribution([r["depth_error_cm"] for r in solved]),
        "rotation_error_deg": _distribution([r["rotation_error_deg"] for r in solved]),
    }


def main() -> None:
    report = build_report()
    print(f"Synthetic stand-ins: {report['solved_count']}/{report['photo_count']} solved\n")
    for r in report["per_photo"]:
        if r["solved"]:
            print(
                f"  {r['subject_id']}: reliable={r['reliable']} "
                f"correspondences={r['correspondence_count']} "
                f"reprojection={r['reprojection_error_px']:.2f}px "
                f"translation_err={r['translation_error_cm']:.2f}cm "
                f"(lateral={r['lateral_error_cm']:.2f}cm depth={r['depth_error_cm']:.2f}cm) "
                f"rotation_err={r['rotation_error_deg']:.2f}deg"
            )
        else:
            print(f"  {r['subject_id']}: NOT SOLVED ({r['reason']})")

    print("\n| Metric | Photos | Mean | Median | Min | Max |")
    print("| --- | --- | --- | --- | --- | --- |")
    for label, key, unit in (
        ("Reprojection error (px)", "reprojection_error_px", ""),
        ("Translation error (cm)", "translation_error_cm", ""),
        ("  — lateral component (cm)", "lateral_error_cm", ""),
        ("  — depth component (cm)", "depth_error_cm", ""),
        ("Rotation error (deg)", "rotation_error_deg", ""),
    ):
        d = report[key]
        print(f"| {label} | {report['solved_count']} | {d['mean']} | {d['median']} | {d['min']} | {d['max']} |")

    print("\n| Anchor set | Photos |")
    print("| --- | --- |")
    print(f"| Synthetic (known camera) | {report['photo_count']} |")
    print("| Real photos | **0 — none exist in this repo** |")


if __name__ == "__main__":
    main()

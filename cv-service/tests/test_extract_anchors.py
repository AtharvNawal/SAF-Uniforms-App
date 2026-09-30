"""Tests for `utils.extract_anchors` against the real reference body GLB.

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from utils.extract_anchors import SOCKET_NAMES, extract_anchors  # noqa: E402

MALE_GLB = REPO_ROOT / "assets" / "3d" / "bodies" / "male_apose.glb"


@pytest.fixture(scope="module")
def result():
    if not MALE_GLB.exists():
        pytest.skip(f"reference body GLB not found at {MALE_GLB}")
    return extract_anchors(MALE_GLB)


def test_all_expected_sockets_present(result):
    for name in SOCKET_NAMES:
        assert name in result["anchors"], f"missing socket: {name}"


def test_derived_chest_center_present_and_centered(result):
    assert "chest_center" in result["anchors"]
    assert result["anchors"]["chest_center"]["x"] == 0.0


def test_no_nan_or_inf_coordinates(result):
    for name, point in result["anchors"].items():
        for axis in ("x", "y", "z"):
            value = point[axis]
            assert math.isfinite(value), f"{name}.{axis} is not finite: {value}"


def test_vertical_ordering_is_anatomically_sane(result):
    """Feet < waist < chest < collar < head, top to bottom of the body."""
    y = {name: point["y"] for name, point in result["anchors"].items()}
    assert y["left_ankle"] < y["belt_center"]
    assert y["belt_center"] < y["left_chest_pocket"]
    assert y["left_chest_pocket"] < y["left_collar_tip"]
    assert y["left_collar_tip"] < y["head_top"]


def test_left_right_pairs_are_mirrored_on_x(result):
    pairs = [
        ("left_collar_tip", "right_collar_tip"),
        ("left_chest_pocket", "right_chest_pocket"),
        ("left_shoulder_seam", "right_shoulder_seam"),
        ("left_sleeve_upper", "right_sleeve_upper"),
        ("left_ankle", "right_ankle"),
        ("left_foot_top", "right_foot_top"),
    ]
    for left_name, right_name in pairs:
        left_x = result["anchors"][left_name]["x"]
        right_x = result["anchors"][right_name]["x"]
        # Anatomical convention: the body faces +z, so the wearer's left is
        # +x (image-right in a front photo, matching MediaPipe's naming).
        # See extract_anchors._to_anatomical_sides.
        assert right_x < 0 < left_x, f"{left_name}/{right_name} not mirrored: {left_x}, {right_x}"
        assert math.isclose(-left_x, right_x, abs_tol=1e-4), (
            f"{left_name}/{right_name} not symmetric: {left_x} vs {right_x}"
        )


def test_reference_height_matches_head_top(result):
    assert result["reference_height_m"] == result["anchors"]["head_top"]["y"]

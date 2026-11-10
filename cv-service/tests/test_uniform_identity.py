from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from detectors.uniform_identity import identify_uniform  # noqa: E402


class SegmentedRegion:
    def __init__(self, class_name, confidence, mask, bbox_px):
        self.class_name = class_name
        self.confidence = confidence
        self.mask = mask
        self.bbox_px = bbox_px


class SegmentationResult:
    def __init__(self, regions, image_width, image_height, class_names):
        self.regions = regions
        self.image_width = image_width
        self.image_height = image_height
        self.class_names = class_names

    def coverage_fraction(self, class_name):
        matches = [r for r in self.regions if r.class_name == class_name]
        if not matches:
            return 0.0
        combined = np.zeros((self.image_height, self.image_width), dtype=bool)
        for region in matches:
            combined |= region.mask.astype(bool)
        return float(combined.sum()) / (self.image_width * self.image_height)


def _segmented(classes: dict[str, float]) -> SegmentationResult:
    mask = np.ones((100, 100), dtype=np.uint8)
    regions = [
        SegmentedRegion(name, 0.9, mask, (0, 0, 100, 100))
        for name, coverage in classes.items()
        for _ in range(max(1, round(coverage)))
    ]
    # Use masks with exact requested coverage for the test helper.
    regions = []
    for name, coverage in classes.items():
        region_mask = np.zeros((100, 100), dtype=np.uint8)
        region_mask[: max(1, round(coverage * 100)), :] = 1
        regions.append(SegmentedRegion(name, 0.9, region_mask, (0, 0, 100, 100)))
    return SegmentationResult(regions, 100, 100, frozenset(classes))


def test_civilian_like_missing_uniform_structure_is_not_assessed():
    result = identify_uniform(_segmented({"shirt": 0.3}), "army_no3_male")
    assert result.status == "UNABLE_TO_VERIFY"
    assert result.inspection_allowed is False


def test_no_garment_evidence_is_invalid_attire():
    result = identify_uniform(_segmented({"headwear": 0.1}), "army_no3_male")
    assert result.status == "INVALID_ATTIRE"
    assert result.inspection_allowed is False


def test_complete_uniform_structure_can_continue_to_geometry():
    result = identify_uniform(
        _segmented({"shirt": 0.25, "trousers": 0.3, "footwear": 0.04, "belt": 0.01}),
        "army_no3_male",
    )
    assert result.status == "VERIFIED"
    assert result.inspection_allowed is True

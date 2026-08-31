"""Sanity check that thresholds are actually centralized in `config.py`
rather than living on as stale local constants — this is what the
`ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md`
refactor claims to have done; this test catches it silently drifting
back apart (e.g. someone editing a local constant instead of config.py).
"""

from __future__ import annotations

import sys
from pathlib import Path

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

import config  # noqa: E402
import pose.detect_person as detect_person  # noqa: E402
import segmentation.segment_uniform as segment_uniform  # noqa: E402
from geometry import solve_camera_pose  # noqa: E402
from rules import rule_engine  # noqa: E402


def test_person_detection_confidence_sourced_from_config():
    assert detect_person._DEFAULT_MIN_CONFIDENCE == config.MIN_PERSON_CONFIDENCE


def test_segmentation_confidence_matches_rule_engine_and_config():
    # The historical bug this guards against: these two used to be two
    # separately-declared `0.4` literals that could silently drift apart.
    assert segment_uniform._DEFAULT_MIN_CONFIDENCE == config.MIN_SEGMENT_CONFIDENCE
    assert rule_engine._DEFAULT_MIN_SEGMENT_CONFIDENCE == config.MIN_SEGMENT_CONFIDENCE


def test_pnp_v2_thresholds_sourced_from_config():
    assert solve_camera_pose.MIN_CONFIDENCE_DEFAULT == config.PNP_V2_MIN_CONFIDENCE
    assert solve_camera_pose.MIN_CORRESPONDENCES_DEFAULT == config.PNP_V2_MIN_CORRESPONDENCES


def test_crop_radius_thresholds_sourced_from_config():
    assert rule_engine._DEFAULT_CROP_RADIUS_CM == config.DEFAULT_CROP_RADIUS_CM
    assert rule_engine._TOLERANCE_TO_CROP_MULTIPLIER == config.TOLERANCE_TO_CROP_MULTIPLIER
    assert rule_engine._MIN_CROP_RADIUS_CM == config.MIN_CROP_RADIUS_CM


def test_env_override_applies(monkeypatch):
    monkeypatch.setenv("CV_SERVICE_MIN_PERSON_CONFIDENCE", "0.75")
    import importlib

    reloaded = importlib.reload(config)
    try:
        assert reloaded.MIN_PERSON_CONFIDENCE == 0.75
    finally:
        monkeypatch.delenv("CV_SERVICE_MIN_PERSON_CONFIDENCE", raising=False)
        importlib.reload(config)

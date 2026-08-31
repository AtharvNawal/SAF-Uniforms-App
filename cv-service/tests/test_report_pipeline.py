"""End-to-end Stage 1 -> 7 test against the real rendered reference-body
photo, with the Anthropic call replaced by a deterministic fake client
(no live API key needed — see `detectors/vision_crop_inspector.py`'s
`client=` injection point).

This is the closest thing to a full pipeline smoke test that doesn't
require external credentials: real YOLO detection, real MediaPipe pose,
real PnP solve, real rule resolution, real report scoring — only the
"what do you see in this crop" judgment is faked, deterministically, so
the test is reproducible.
"""

from __future__ import annotations

import sys
from pathlib import Path

import cv2
import pytest

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from calibration.pnp_solve import scale_factor_cm_per_unit, solve_camera_pose  # noqa: E402
from detectors.vision_crop_inspector import inspect_resolved_rules  # noqa: E402
from pose.detect_person import detect_person  # noqa: E402
from pose.estimate_pose import estimate_pose  # noqa: E402
from reporting.report import build_report, combine_item_verdicts, render_annotated_image  # noqa: E402
from rules.rule_engine import resolve_rules  # noqa: E402

RENDERED_IMAGE = Path(__file__).resolve().parent / "fixtures" / "rendered_army_no3_male_front.jpg"

# Deliberately mark one item missing and one low_confidence so the report's
# issues/uncertain lists both get exercised, not just the happy path.
_FORCED_VERDICTS = {
    "army_beret": {"verdict": "missing", "confidence": 0.9, "note": "no beret visible in crop"},
    "nylon_belt": {"verdict": "low_confidence", "confidence": 0.3, "note": "belt line ambiguous"},
}
_DEFAULT_VERDICT = {"verdict": "present", "confidence": 0.85, "note": "item visible as expected"}


class _FakeToolUseBlock:
    type = "tool_use"

    def __init__(self, input_: dict):
        self.input = input_


class _FakeMessage:
    def __init__(self, content):
        self.content = content


class _FakeMessagesAPI:
    def __init__(self):
        self.call_count = 0

    def create(self, **kwargs):
        self.call_count += 1
        prompt_text = kwargs["messages"][0]["content"][0]["text"]
        verdict = _DEFAULT_VERDICT
        for object_id, forced in _FORCED_VERDICTS.items():
            if f'"{object_id}"' in prompt_text:
                verdict = forced
                break
        return _FakeMessage([_FakeToolUseBlock(verdict)])


class FakeAnthropicClient:
    def __init__(self):
        self.messages = _FakeMessagesAPI()


@pytest.fixture(scope="module")
def pipeline_output():
    if not RENDERED_IMAGE.exists():
        pytest.skip(
            f"{RENDERED_IMAGE} not present — regenerate with "
            "tests/fixtures/generate_fixture.py"
        )

    image_path = str(RENDERED_IMAGE)
    detection = detect_person(image_path, min_confidence=0.3)
    assert detection.accepted, detection.reason

    pose = estimate_pose(image_path)
    assert pose.found

    camera = solve_camera_pose(pose)
    assert camera.solved and camera.reliable

    cm_per_px = scale_factor_cm_per_unit(pose)
    resolved = resolve_rules(camera, cm_per_px, profile={"rank_tier": "specialist"}, pose=pose)
    assert len(resolved) > 0

    image_bgr = cv2.imread(image_path)
    fake_client = FakeAnthropicClient()
    verdicts = inspect_resolved_rules(image_bgr, resolved, client=fake_client)

    return resolved, verdicts, image_bgr, fake_client


def test_vision_inspector_called_once_per_crop(pipeline_output):
    resolved, verdicts, _, fake_client = pipeline_output
    expected_crop_count = sum(len(r.crops) for r in resolved)
    assert fake_client.messages.call_count == expected_crop_count
    assert len(verdicts) == expected_crop_count


def test_report_contains_forced_issue_and_uncertain(pipeline_output):
    resolved, verdicts, _, _ = pipeline_output
    report = build_report(resolved, verdicts)

    issue_ids = {i["item"] for i in report["issues"]}
    uncertain_ids = {u["item"] for u in report["uncertain"]}
    assert "army_beret" in issue_ids
    assert "nylon_belt" in uncertain_ids


def test_report_score_and_subscores_are_well_formed(pipeline_output):
    resolved, verdicts, _, _ = pipeline_output
    report = build_report(resolved, verdicts)

    assert 0 <= report["overall_score"] <= 100
    assert report["status"] in (
        "Fully Compliant", "Minor Issues", "Multiple Issues", "Non-Compliant",
    )
    # lower_body / appearance have no rules yet — must be reported as
    # null, never silently faked as a passing score
    assert report["subscores"]["lower_body"] is None
    assert report["subscores"]["appearance"] is None
    assert report["subscores"]["headwear"] is not None


def test_annotated_image_renders(pipeline_output):
    resolved, verdicts, image_bgr, _ = pipeline_output
    items = combine_item_verdicts(resolved, verdicts)
    jpeg_bytes = render_annotated_image(image_bgr, items)
    assert jpeg_bytes[:2] == b"\xff\xd8"  # JPEG magic bytes
    assert len(jpeg_bytes) > 1000

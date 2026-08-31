"""Tests for the Phase1-vs-Phase2 comparison harness — fake-client
only, zero external credentials, same convention as every other
cv-service test. Validates the harness's own wiring (expected-item
resolution, both pipelines actually get called, comparison rows built
correctly) — NOT a real accuracy comparison, which needs `--live` and a
real photo (see `evaluation/compare_phase1_phase2.py`'s own docstring).
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from evaluation.compare_phase1_phase2 import (  # noqa: E402
    FakeComparisonClient,
    compare,
    expected_items_for_profile,
)

RENDERED_IMAGE = Path(__file__).resolve().parent / "fixtures" / "rendered_army_no3_male_front.jpg"


def test_expected_items_filters_by_condition():
    items = expected_items_for_profile({"rank_tier": "specialist"})
    assert len(items) > 0
    assert all(item.accessory_id for item in items)


def test_compare_runs_end_to_end_and_agrees_in_fake_mode():
    if not RENDERED_IMAGE.exists():
        pytest.skip("fixture missing — see tests/fixtures/generate_fixture.py")

    client = FakeComparisonClient()
    report = compare(
        str(RENDERED_IMAGE),
        {"rank_tier": "specialist", "gender": "male", "isSikh": False, "medalRowCount": 0},
        phase1_client=client,
        phase2_client=client,
    )

    assert len(report.rows) > 0
    assert report.phase1_call_count == 1
    assert report.phase2_call_count > 0
    # Both phases report every item present/correct in fake mode, so
    # every row judged by both sides should agree — this proves the
    # harness's plumbing is correct, not that the two backends actually
    # agree on real photos.
    judged = [r for r in report.rows if r.phase1_status and r.phase2_status]
    assert judged
    assert all(r.agree for r in judged)
    assert report.agreement_rate == 1.0

"""FastAPI `/inspect` endpoint test — real Stages 1-3/6, faked Stage 4/5
(same pattern as `test_report_pipeline.py`), exercised through an actual
HTTP request via Starlette's TestClient rather than calling the pipeline
functions directly.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

import detectors.vision_crop_inspector as vision_crop_inspector  # noqa: E402
from api.main import app  # noqa: E402
from tests.test_report_pipeline import RENDERED_IMAGE, FakeAnthropicClient  # noqa: E402


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setattr(vision_crop_inspector, "_client", lambda: FakeAnthropicClient())
    return TestClient(app)


def test_health():
    resp = TestClient(app).get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_inspect_end_to_end(client):
    if not RENDERED_IMAGE.exists():
        pytest.skip("fixture missing — see tests/fixtures/generate_fixture.py")

    with open(RENDERED_IMAGE, "rb") as f:
        resp = client.post(
            "/inspect",
            files={"photo": ("test.jpg", f, "image/jpeg")},
            data={"rank_tier": "specialist", "gender": "male", "is_sikh": "false", "medal_row_count": "0"},
        )

    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert "overall_score" in body
    assert "subscores" in body
    assert "camera_diagnostics" in body
    assert body["camera_diagnostics"]["reprojection_error_px"] < 100
    assert "annotated_image_base64" in body
    assert any(i["item"] == "army_beret" for i in body["issues"])

    # Geometric verdicts (this session's newest work) — always present as
    # a list, never omitted; the fixture render has no accessory GLBs
    # composited in, so every mapped-category rule should read "missing"
    # or "pass" (only footwear is baked into the body mesh) and every
    # no-detector-class rule should read "unverifiable", never a
    # fabricated pass.
    assert "geometric_verdicts" in body
    verdicts_by_accessory = {v["accessory"]: v for v in body["geometric_verdicts"]}
    assert set(v["status"] for v in verdicts_by_accessory.values()) <= {"pass", "fail", "missing", "unverifiable"}
    assert verdicts_by_accessory["army_beret"]["status"] == "missing"
    assert verdicts_by_accessory["leather_shoes_low_cut"]["status"] == "pass"
    assert verdicts_by_accessory["name_tag_standard"]["status"] == "unverifiable"
    assert "doctrine_ref" in verdicts_by_accessory["army_beret"]
    assert verdicts_by_accessory["army_beret"]["doctrine_ref"]


def test_inspect_rejects_multi_person_photo(client, tmp_path):
    # reuse the zidane.jpg ultralytics ships (two people) if present in the venv assets
    import ultralytics

    zidane = Path(ultralytics.__file__).resolve().parent / "assets" / "zidane.jpg"
    if not zidane.exists():
        pytest.skip("ultralytics sample asset not found")

    with open(zidane, "rb") as f:
        resp = client.post(
            "/inspect",
            files={"photo": ("zidane.jpg", f, "image/jpeg")},
            data={"rank_tier": "specialist"},
        )
    assert resp.status_code == 422
    assert resp.json()["error"] == "multiple_people_detected"

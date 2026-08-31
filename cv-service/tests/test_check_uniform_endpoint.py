"""`POST /check_uniform` endpoint test — real Stages 1-3/6/geometric-verdict
pipeline through an actual HTTP request via Starlette's TestClient. Unlike
`test_api.py`'s `/inspect` test, this endpoint has zero Anthropic
dependency, so no fake client injection is needed.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from api.main import app  # noqa: E402
from tests.test_report_pipeline import RENDERED_IMAGE  # noqa: E402


@pytest.fixture
def client():
    return TestClient(app)


def test_check_uniform_end_to_end(client):
    if not RENDERED_IMAGE.exists():
        pytest.skip("fixture missing — see tests/fixtures/generate_fixture.py")

    with open(RENDERED_IMAGE, "rb") as f:
        resp = client.post(
            "/check_uniform",
            files={"image": ("test.jpg", f, "image/jpeg")},
            data={
                "uniform_type": "army_no3_male",
                "rank_tier": "specialist",
                "gender": "male",
                "is_sikh": "false",
                "medal_row_count": "0",
            },
        )

    assert resp.status_code == 200, resp.text
    body = resp.json()

    assert body["success"] is True
    assert body["overall_status"] in ("PASS", "FAIL")
    assert isinstance(body["overall_score"], (int, float))
    assert body["image_quality"]["usable"] is True
    assert body["person"]["detected"] is True

    accessories_by_name = {a["name"]: a for a in body["accessories"]}
    assert accessories_by_name["army_beret"]["status"] == "MISSING"
    assert accessories_by_name["army_beret"]["present"] is False
    assert accessories_by_name["leather_shoes_low_cut"]["status"] == "CORRECT"
    assert accessories_by_name["leather_shoes_low_cut"]["present"] is True
    assert accessories_by_name["leather_shoes_low_cut"]["position_correct"] is True
    assert accessories_by_name["name_tag_standard"]["status"] == "UNCERTAIN"
    assert accessories_by_name["name_tag_standard"]["present"] is None

    summary = body["summary"]
    assert summary["required_accessories"] > 0
    assert summary["missing"] >= 1
    assert summary["uncertain"] >= 1


def test_check_uniform_debug_image_optional(client):
    if not RENDERED_IMAGE.exists():
        pytest.skip("fixture missing — see tests/fixtures/generate_fixture.py")

    with open(RENDERED_IMAGE, "rb") as f:
        resp = client.post(
            "/check_uniform",
            files={"image": ("test.jpg", f, "image/jpeg")},
            data={
                "uniform_type": "army_no3_male",
                "rank_tier": "specialist",
                "include_debug_image": "true",
            },
        )

    assert resp.status_code == 200, resp.text
    assert "debug_image_base64" in resp.json()


def test_check_uniform_rejects_unsupported_uniform_type(client):
    with open(RENDERED_IMAGE if RENDERED_IMAGE.exists() else __file__, "rb") as f:
        resp = client.post(
            "/check_uniform",
            files={"image": ("test.jpg", f, "image/jpeg")},
            data={"uniform_type": "navy_no1_male", "rank_tier": "specialist"},
        )

    assert resp.status_code == 422
    body = resp.json()
    assert body["success"] is False
    assert body["status"] == "UNSUPPORTED_UNIFORM"


def test_check_uniform_rejects_corrupted_image(client):
    resp = client.post(
        "/check_uniform",
        files={"image": ("test.jpg", b"not a real image", "image/jpeg")},
        data={"uniform_type": "army_no3_male", "rank_tier": "specialist"},
    )

    assert resp.status_code == 422
    body = resp.json()
    assert body["success"] is False
    assert body["status"] == "CORRUPTED_IMAGE"


def test_check_uniform_rejects_multi_person_photo(client):
    import ultralytics

    zidane = Path(ultralytics.__file__).resolve().parent / "assets" / "zidane.jpg"
    if not zidane.exists():
        pytest.skip("ultralytics sample asset not found")

    with open(zidane, "rb") as f:
        resp = client.post(
            "/check_uniform",
            files={"image": ("zidane.jpg", f, "image/jpeg")},
            data={"uniform_type": "army_no3_male", "rank_tier": "specialist"},
        )

    assert resp.status_code == 422
    assert resp.json()["status"] == "MULTIPLE_PEOPLE_DETECTED"

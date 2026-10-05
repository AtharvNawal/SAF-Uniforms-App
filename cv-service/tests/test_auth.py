"""Firebase ID-token gate (api/auth.py) — enforced only when
config.REQUIRE_AUTH is on (the Cloud Run deployment). Token verification
is faked; no network.
"""
from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

import api.auth as auth  # noqa: E402
import config  # noqa: E402
from api.main import app  # noqa: E402

FORM = {"uniform_type": "not_a_uniform", "rank_tier": "enlistee"}
FILES = {"image": ("x.jpg", b"not really a jpeg", "image/jpeg")}


def _fake_verify(token: str) -> dict:
    if token == "good-token":
        return {"sub": "uid-123", "aud": "saf-uniforms"}
    raise ValueError("Token signature invalid")


@pytest.fixture
def enforced(monkeypatch):
    monkeypatch.setattr(config, "REQUIRE_AUTH", True)
    monkeypatch.setattr(auth, "verify_token", _fake_verify)
    return TestClient(app)


def test_auth_off_by_default_requests_reach_the_endpoint():
    # The endpoint's own validation answers (422 UNSUPPORTED_UNIFORM), not auth.
    assert config.REQUIRE_AUTH is False
    resp = TestClient(app).post("/check_uniform", data=FORM, files=FILES)
    assert resp.status_code != 401


def test_missing_token_is_typed_401(enforced):
    resp = enforced.post("/check_uniform", data=FORM, files=FILES)
    assert resp.status_code == 401
    body = resp.json()
    assert body["success"] is False
    assert body["status"] == "UNAUTHENTICATED"


def test_invalid_token_is_401(enforced):
    resp = enforced.post("/check_uniform", data=FORM, files=FILES, headers={"Authorization": "Bearer forged"})
    assert resp.status_code == 401
    assert resp.json()["status"] == "UNAUTHENTICATED"


def test_valid_token_passes_through_to_the_endpoint(enforced):
    resp = enforced.post("/check_uniform", data=FORM, files=FILES, headers={"Authorization": "Bearer good-token"})
    assert resp.status_code != 401  # past the gate; the endpoint itself rejects the bogus uniform


@pytest.mark.parametrize("path,files", [
    ("/check_uniform_burst", {"images": ("x.jpg", b"x", "image/jpeg")}),
    ("/inspect", {"photo": ("x.jpg", b"x", "image/jpeg")}),
])
def test_every_analysis_endpoint_is_gated(enforced, path, files):
    assert enforced.post(path, data=FORM, files=files).status_code == 401


def test_health_stays_open(enforced):
    assert enforced.get("/health").status_code == 200

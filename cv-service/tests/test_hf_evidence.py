from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import config  # noqa: E402
from detectors.hf_evidence import classify_uniform, model_capabilities  # noqa: E402
from rules.rule_selector import profile_from_uniform_type  # noqa: E402


def test_hf_evidence_is_disabled_by_default(monkeypatch, tmp_path):
    monkeypatch.setattr(config, "HF_EVIDENCE_ENABLED", False)
    profile = profile_from_uniform_type("army_no3_male", "specialist", "male")
    evidence = classify_uniform(tmp_path / "missing.jpg", profile)
    assert evidence.available is False
    assert evidence.supported_by_visual_evidence is False
    assert evidence.source == "disabled"


def test_model_capabilities_are_configuration_only():
    capabilities = model_capabilities()
    assert capabilities["siglip2"]["purpose"] == "uniform/profile similarity"
    assert capabilities["florence2"]["purpose"] == "secondary localization and descriptions"
    assert capabilities["dinov2"]["purpose"] == "reference-image similarity"

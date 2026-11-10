from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import uniforms  # noqa: E402
from rules.rule_loader import RuleConfigError, load_rule_config  # noqa: E402
from rules.rule_selector import profile_from_uniform_type, select_rule_config  # noqa: E402


@pytest.mark.parametrize("uniform_type", sorted(uniforms.UNIFORMS))
def test_registered_profile_selects_matching_doctrine(uniform_type):
    spec = uniforms.UNIFORMS[uniform_type]
    profile = profile_from_uniform_type(uniform_type, "specialist", spec.gender)
    selected = select_rule_config(profile, spec)
    assert selected.metadata["branch"] == spec.service


def test_profile_preserves_personnel_and_sikh_conditions():
    profile = profile_from_uniform_type(
        "army_no3_male",
        "specialist",
        "male",
        personnel_category="cadet",
        is_sikh=True,
    )
    assert profile.as_rule_profile()["personnel_category"] == "cadet"
    assert profile.as_rule_profile()["isSikh"] is True


def test_invalid_uniform_shape_is_rejected():
    with pytest.raises(RuleConfigError):
        profile_from_uniform_type("army_no1_male", "specialist", "male")


def test_rule_config_requires_doctrine_metadata(tmp_path):
    path = tmp_path / "invalid.json"
    path.write_text('{"_meta": {}, "rules": [{"object": "x"}]}')
    with pytest.raises(RuleConfigError):
        load_rule_config(path)


def test_rule_config_is_cached_until_file_changes():
    path = ROOT / "rules" / "army_no3_male.json"
    first = load_rule_config(path)
    second = load_rule_config(path)
    assert first is second

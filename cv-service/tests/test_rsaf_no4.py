"""RSAF No.4 uniform support — registry, rule/anchor integrity, and the
`/check_uniform` plumbing for `rsaf_no4_male` / `rsaf_no4_female`.

Accuracy is measured by the synthetic violation benchmark
(`evaluation/run_violation_benchmark.py --bench violation_benchmark_rsaf`),
not here. See ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

CV_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_ROOT))

import uniforms  # noqa: E402
from api.main import app  # noqa: E402
from api.pipeline import SUPPORTED_UNIFORM_TYPES, scaled_anchors  # noqa: E402
from rules.rule_engine import CATEGORY_TO_SEGMENTATION_CLASS, load_anchors, load_rules  # noqa: E402
from tests.test_report_pipeline import RENDERED_IMAGE  # noqa: E402

RSAF = ["rsaf_no4_male", "rsaf_no4_female"]
ANCHOR_NAMES = set(load_anchors().keys())  # the 16 names every anchor file must carry


def test_registry_lists_army_and_rsaf():
    assert {"army_no3_male", *RSAF} <= set(SUPPORTED_UNIFORM_TYPES)
    assert uniforms.DEFAULT.uniform_type == "army_no3_male"


@pytest.mark.parametrize("uniform_type", sorted(uniforms.UNIFORMS))
def test_every_uniform_has_rules_and_complete_anchors(uniform_type):
    spec = uniforms.UNIFORMS[uniform_type]
    assert spec.rules_path.exists() and spec.anchors_path.exists()
    anchors = load_anchors(spec.anchors_path)
    assert set(anchors) == ANCHOR_NAMES
    for rule in load_rules(spec.rules_path):
        for name in rule["expected_anchor"].split(","):
            assert name.strip() in anchors, f"{uniform_type}/{rule['object']}: unknown anchor {name}"
        assert rule["category"] in CATEGORY_TO_SEGMENTATION_CLASS, \
            f"{uniform_type}/{rule['object']}: category {rule['category']} has no segmentation mapping (or explicit None)"


@pytest.mark.parametrize("uniform_type", RSAF)
def test_rsaf_anchors_are_anatomical_and_scaled_to_stature(uniform_type):
    spec = uniforms.UNIFORMS[uniform_type]
    anchors = load_anchors(spec.anchors_path)
    # Anatomical sides: the wearer's left is +x (same as anchors.male.json).
    for stem in ("collar_tip", "chest_pocket", "shoulder_seam", "sleeve_upper", "ankle", "foot_top"):
        assert anchors[f"left_{stem}"]["x"] > 0 > anchors[f"right_{stem}"]["x"]
    # Stature is the head crown; head_top is the beret top (what the
    # headwear-mask refinement measures) — a few cm above it.
    assert 0.0 < anchors["head_top"]["y"] - spec.reference_stature_m < 0.08
    scaled, scale = scaled_anchors(spec.reference_stature_m * 100 * 0.95, spec)
    assert scale == pytest.approx(0.95)
    assert scaled["head_top"]["y"] == pytest.approx(anchors["head_top"]["y"] * 0.95)


@pytest.mark.parametrize("uniform_type", RSAF)
def test_rsaf_rules_cover_the_no4_items(uniform_type):
    objects = {r["object"]: r for r in load_rules(uniforms.UNIFORMS[uniform_type].rules_path)}
    required = {o for o, r in objects.items() if r.get("required")}
    assert {"rsaf_beret", "rsaf_no4_rank_epaulette", "name_tag_standard", "singapore_tag",
            "safety_boots"} <= required
    # Sleeve patch: reported, but check-by-eye — edge-on in a front photo.
    assert "rsaf_unit_patch" in objects and not objects["rsaf_unit_patch"]["required"]
    # Doctrine sides: name tag on the wearer's right, SINGAPORE tag on the left.
    assert objects["name_tag_standard"]["expected_anchor"] == "right_chest_pocket"
    assert objects["singapore_tag"]["expected_anchor"] == "left_chest_pocket"
    # Every tolerance the PDF doesn't state is marked as assumed, never silent.
    for r in objects.values():
        if r.get("tolerance_cm"):
            assert r.get("tolerance_source", "").startswith("assumed")
    assert ("rsaf_sikh_turban" in objects) == (uniform_type == "rsaf_no4_male")


def test_committed_rules_match_the_generator():
    sys.path.insert(0, str(CV_ROOT / "utils"))
    from build_rsaf_no4_rules import build

    for gender in ("male", "female"):
        committed = json.loads((CV_ROOT / "rules" / f"rsaf_no4_{gender}.json").read_text())
        assert committed == json.loads(json.dumps(build(gender))), \
            f"rules/rsaf_no4_{gender}.json is stale — re-run utils/build_rsaf_no4_rules.py"


@pytest.mark.parametrize("uniform_type", RSAF)
def test_check_uniform_accepts_rsaf(uniform_type):
    """Plumbing only: the request is accepted and runs the pipeline against
    the RSAF doctrine (the fixture photo is an Army render, so the verdicts
    themselves aren't meaningful here)."""
    if not RENDERED_IMAGE.exists():
        pytest.skip("fixture photo missing")
    with RENDERED_IMAGE.open("rb") as f:
        resp = TestClient(app).post("/check_uniform", files={"image": ("p.jpg", f, "image/jpeg")},
                                    data={"uniform_type": uniform_type, "rank_tier": "enlistee",
                                          "gender": uniform_type.rsplit("_", 1)[1], "height_cm": "175"})
    body = resp.json()
    assert body.get("status") != "UNSUPPORTED_UNIFORM"
    if resp.status_code == 200:
        names = {a["name"] for a in body["accessories"]}
        assert "singapore_tag" in names and "rsaf_unit_patch" in names
        assert not any(n.startswith("army_") for n in names)


def test_unknown_uniform_still_rejected():
    with RENDERED_IMAGE.open("rb") as f:
        resp = TestClient(app).post("/check_uniform", files={"image": ("p.jpg", f, "image/jpeg")},
                                    data={"uniform_type": "navy_no4_male", "rank_tier": "enlistee"})
    assert resp.status_code == 422 and resp.json()["status"] == "UNSUPPORTED_UNIFORM"

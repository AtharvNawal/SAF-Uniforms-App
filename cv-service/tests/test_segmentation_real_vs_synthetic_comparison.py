"""Tests for the segmentation real-vs-synthetic comparison tooling
(`ChangeRequest/2026-08-11_cv-service-segmentation-real-vs-synthetic-comparison-tooling.md`).

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from evaluation.compare_segmentation_real_vs_synthetic import (  # noqa: E402
    REGRESSION_THRESHOLD_MAP50,
    ClassComparison,
    build_comparison,
    flag_regressions,
)
from evaluation.segmentation_label_conversion import convert_labels_to_yolo_seg  # noqa: E402
from training.generate_segmentation_dataset import CLASS_ID  # noqa: E402

LABELS_DIR = REPO_ROOT / "cv-service" / "data" / "labels"
MODEL_WEIGHTS = REPO_ROOT / "cv-service" / "models" / "segmentation_v1" / "weights" / "best.pt"


def _fixture_label(**overrides) -> dict:
    base = {
        "schema_version": 1,
        "photo_id": "fixture01__front__indoor_bright",
        "source_path": "cv-service/data/real_photos/standin01/standin01__front__indoor_bright.jpg",
        "subject_id": "fixture01",
        "angle": "front",
        "lighting": "indoor_bright",
        "image_width": 800,
        "image_height": 1200,
        "is_synthetic_stand_in": False,
        "annotator": "test",
        "labeled_at": "2026-08-11T00:00:00+00:00",
        "notes": "",
        "anchors": {},
        "accessories": [
            {"class_name": "shirt", "present": True, "polygon_px": [[100, 100], [200, 100], [200, 200], [100, 200]]},
            {"class_name": "belt", "present": False},
        ],
    }
    base.update(overrides)
    return base


def test_label_converter_produces_correct_normalized_yolo_line(tmp_path):
    label = _fixture_label()
    label_path = tmp_path / "in" / "fixture01.json"
    label_path.parent.mkdir(parents=True)
    label_path.write_text(json.dumps(label))

    result = convert_labels_to_yolo_seg([label_path], tmp_path / "out")

    assert result.converted_photo_ids == ["fixture01__front__indoor_bright"]
    txt = (tmp_path / "out" / "labels" / "val" / "fixture01__front__indoor_bright.txt").read_text()
    lines = txt.strip().splitlines()
    assert len(lines) == 1  # only `shirt` is present=True; `belt` excluded
    parts = lines[0].split()
    assert int(parts[0]) == CLASS_ID["shirt"]
    coords = [float(x) for x in parts[1:]]
    # 100/800=0.125, 100/1200=0.08333...
    assert coords[0] == pytest.approx(0.125)
    assert coords[1] == pytest.approx(100 / 1200, abs=1e-5)  # written at 5 decimal places


def test_label_converter_excludes_synthetic_by_default(tmp_path):
    label = _fixture_label(is_synthetic_stand_in=True)
    label_path = tmp_path / "in" / "synthetic.json"
    label_path.parent.mkdir(parents=True)
    label_path.write_text(json.dumps(label))

    result = convert_labels_to_yolo_seg([label_path], tmp_path / "out")
    assert result.converted_photo_ids == []
    assert result.skipped_synthetic_photo_ids == ["fixture01__front__indoor_bright"]
    assert result.data_yaml_path is None


def test_label_converter_includes_synthetic_when_explicitly_opted_out(tmp_path):
    label = _fixture_label(is_synthetic_stand_in=True)
    label_path = tmp_path / "in" / "synthetic.json"
    label_path.parent.mkdir(parents=True)
    label_path.write_text(json.dumps(label))

    result = convert_labels_to_yolo_seg([label_path], tmp_path / "out", require_real=False)
    assert result.converted_photo_ids == ["fixture01__front__indoor_bright"]


def test_flag_regressions_catches_large_drop_ignores_small_one():
    comparisons = [
        ClassComparison("shirt", synthetic_map50=0.99, synthetic_source="re_run", real_map50=0.60, delta=-0.39),
        ClassComparison("footwear", synthetic_map50=0.99, synthetic_source="re_run", real_map50=0.90, delta=-0.09),
        ClassComparison("belt", synthetic_map50=0.55, synthetic_source="re_run", real_map50=None, delta=None),
    ]
    flagged = flag_regressions(comparisons)
    flagged_names = {d.class_name for d in flagged}
    assert flagged_names == {"shirt"}
    assert flagged[0].likely_causes == []  # unpopulated by construction
    assert flagged[0].proposed_fix is None


def test_flag_regressions_respects_custom_threshold():
    comparisons = [ClassComparison("belt", 0.55, "re_run", 0.45, -0.10)]
    assert flag_regressions(comparisons, threshold=0.15) == []
    assert len(flag_regressions(comparisons, threshold=0.05)) == 1


def test_default_path_reports_zero_real_photos_today():
    """The actual current state of this repo: 0 real photos. Must report
    that cleanly, not crash, not fabricate a result."""
    if not MODEL_WEIGHTS.exists():
        pytest.skip(f"trained model weights not found at {MODEL_WEIGHTS}")
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        comparisons, real_count, skipped_count = build_comparison(Path(tmp))

    assert real_count == 0
    assert skipped_count == 3  # Milestone A's 3 synthetic stand-ins, all correctly excluded
    assert all(c.real_map50 is None for c in comparisons)
    assert all(c.delta is None for c in comparisons)


def test_mechanism_smoke_test_against_synthetic_stand_ins():
    """NOT a real-world result — explicitly runs with require_real=False
    against Milestone A's 3 synthetic stand-ins purely to prove the
    converter + model.val() mechanism works end-to-end without crashing.
    Only `shirt`/`trousers`/`footwear` can possibly register (the
    stand-ins have no accessory geometry for the other 6 classes — see
    the plan file's risk section) — this test only checks the mechanism
    runs and produces sane types, not that any number is "good"."""
    if not MODEL_WEIGHTS.exists():
        pytest.skip(f"trained model weights not found at {MODEL_WEIGHTS}")
    if not LABELS_DIR.exists() or not list(LABELS_DIR.glob("*.json")):
        pytest.skip("no local Milestone A stand-in labels (gitignored)")
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        comparisons, real_count, skipped_count = build_comparison(Path(tmp), require_real=False)

    assert real_count == 3
    assert skipped_count == 0
    shirt = next(c for c in comparisons if c.class_name == "shirt")
    assert shirt.real_map50 is not None
    assert 0.0 <= shirt.real_map50 <= 1.0


def test_regression_threshold_matches_plan_justification():
    assert REGRESSION_THRESHOLD_MAP50 == 0.15

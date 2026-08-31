"""Tests for `labeling.schema` / `labeling.validate`.

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from labeling.schema import ACCESSORY_CLASSES, ANCHOR_NAMES  # noqa: E402
from labeling.validate import schema_is_up_to_date, validate_label  # noqa: E402

LABELS_DIR = REPO_ROOT / "cv-service" / "data" / "labels"


def _minimal_valid_label() -> dict:
    anchors = {name: {"visible": False} for name in ANCHOR_NAMES}
    anchors["head_top"] = {"x_px": 400.0, "y_px": 120.0, "visible": True}
    return {
        "schema_version": 1,
        "photo_id": "subj01__front__indoor_bright",
        "source_path": "cv-service/data/real_photos/subj01/subj01__front__indoor_bright.jpg",
        "subject_id": "subj01",
        "angle": "front",
        "lighting": "indoor_bright",
        "image_width": 800,
        "image_height": 1200,
        "is_synthetic_stand_in": False,
        "annotator": "test",
        "labeled_at": "2026-08-11T00:00:00+00:00",
        "notes": "",
        "anchors": anchors,
        "accessories": [
            {"class_name": "shirt", "present": True, "polygon_px": [[0, 0], [10, 0], [10, 10]]},
            {"class_name": "trousers", "present": False},
        ],
    }


def test_schema_file_matches_source_of_truth_lists():
    """Fails loudly if SOCKET_NAMES / CLASSES changed upstream and nobody
    re-ran `labeling/schema.py` — see the plan file's risk section."""
    assert schema_is_up_to_date(), (
        "cv-service/data/schemas/ground_truth.v1.schema.json is stale — "
        "regenerate with `.venv-tools/bin/python cv-service/labeling/schema.py`"
    )


def test_anchor_and_accessory_vocab_nonempty():
    assert len(ANCHOR_NAMES) == 15
    assert len(ACCESSORY_CLASSES) == 9


def test_minimal_valid_label_passes():
    assert validate_label(_minimal_valid_label()) == []


def test_missing_anchor_rejected():
    label = _minimal_valid_label()
    del label["anchors"]["left_ankle"]
    errors = validate_label(label)
    assert errors
    assert any("left_ankle" in e for e in errors)


def test_bad_angle_enum_rejected():
    label = _minimal_valid_label()
    label["angle"] = "sideways"
    errors = validate_label(label)
    assert errors


def test_bad_lighting_enum_rejected():
    label = _minimal_valid_label()
    label["lighting"] = "candlelight"
    errors = validate_label(label)
    assert errors


def test_present_accessory_without_polygon_rejected():
    label = _minimal_valid_label()
    label["accessories"] = [{"class_name": "belt", "present": True}]
    errors = validate_label(label)
    assert errors
    assert any("polygon_px" in e for e in errors)


def test_visible_anchor_without_coordinates_rejected():
    label = _minimal_valid_label()
    label["anchors"]["belt_center"] = {"visible": True}
    errors = validate_label(label)
    assert errors


def test_wrong_schema_version_rejected():
    label = _minimal_valid_label()
    label["schema_version"] = 2
    errors = validate_label(label)
    assert errors


def test_unknown_accessory_class_rejected():
    label = _minimal_valid_label()
    label["accessories"].append({"class_name": "hat", "present": False})
    errors = validate_label(label)
    assert errors


def test_missing_is_synthetic_stand_in_rejected():
    label = _minimal_valid_label()
    del label["is_synthetic_stand_in"]
    errors = validate_label(label)
    assert errors
    assert any("is_synthetic_stand_in" in e for e in errors)


@pytest.mark.parametrize(
    "label_path",
    sorted(LABELS_DIR.glob("*.json")) if LABELS_DIR.exists() else [],
    ids=lambda p: p.stem,
)
def test_produced_stand_in_labels_validate(label_path: Path):
    """Every label file this milestone actually produced (see
    `labeling/label_standins.py`) must validate cleanly and must be
    honestly flagged as a synthetic stand-in, since zero real photos
    exist in this repo."""
    data = json.loads(label_path.read_text())
    assert validate_label(data) == []
    assert data["is_synthetic_stand_in"] is True


def test_produced_labels_exist():
    """`cv-service/data/labels/` is gitignored (privacy — see the plan
    file), so a fresh checkout legitimately has none; skip rather than
    fail there. This only guards against the parametrized test above
    silently collecting zero cases on a machine that SHOULD have them."""
    if not LABELS_DIR.exists() or not list(LABELS_DIR.glob("*.json")):
        pytest.skip(
            "no label files under cv-service/data/labels/ (gitignored, local-only) — "
            "run render_standins.py then label_standins.py to regenerate"
        )


def test_validate_label_does_not_mutate_input():
    label = _minimal_valid_label()
    snapshot = copy.deepcopy(label)
    validate_label(label)
    assert label == snapshot

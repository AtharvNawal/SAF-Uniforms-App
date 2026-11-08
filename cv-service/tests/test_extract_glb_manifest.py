"""Tests for the GLB reference manifest extractor."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from utils.extract_anchors import SOCKET_NAMES  # noqa: E402
from utils.extract_glb_manifest import extract_directory, extract_manifest  # noqa: E402


MALE_GLB = REPO_ROOT / "assets" / "3d" / "bodies" / "male_apose.glb"


@pytest.fixture(scope="module")
def manifest():
    if not MALE_GLB.exists():
        pytest.skip(f"reference body GLB not found at {MALE_GLB}")
    return extract_manifest(MALE_GLB)


def test_manifest_records_static_model_and_mesh_inventory(manifest):
    assert manifest["metadata"] == {"skin_count": 0, "animation_count": 0}
    assert manifest["counts"]["mesh_count"] > 0
    assert manifest["counts"]["node_count"] >= manifest["counts"]["mesh_count"]


def test_manifest_distinguishes_transform_only_anchors(manifest):
    assert set(manifest["anchors"]) == set(SOCKET_NAMES)
    assert manifest["counts"]["transform_only_anchor_count"] > 0
    assert any(not anchor["has_geometry"] for anchor in manifest["anchors"].values())


def test_manifest_preserves_anchor_translations_and_mesh_metadata(manifest):
    belt = manifest["anchors"]["belt_center"]["translation"]
    assert belt[1] == pytest.approx(1.0324, abs=1e-4)
    assert all(key in manifest["meshes"][next(iter(manifest["meshes"]))] for key in (
        "vertex_count",
        "face_count",
        "bounds_min",
        "bounds_max",
        "material",
    ))


def test_manifest_is_json_serializable(manifest):
    json.dumps(manifest)


def test_directory_manifest_finds_reference_bodies():
    bodies = REPO_ROOT / "assets" / "3d" / "bodies"
    if not bodies.exists():
        pytest.skip(f"reference body directory not found at {bodies}")
    result = extract_directory(bodies)
    assert len(result["models"]) >= 4
    assert {model["file"]["name"] for model in result["models"]} >= {
        "male_apose.glb",
        "female_apose.glb",
        "female_maternity_apose.glb",
    }

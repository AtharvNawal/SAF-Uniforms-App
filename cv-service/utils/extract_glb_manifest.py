"""Extract a JSON-safe reference manifest from SAF GLB files.

The manifest deliberately separates:

* anchors: named transform-only placement references;
* meshes: renderable geometry and its bounds/material metadata;
* nodes: the scene hierarchy connecting the two.

This prevents a marker cube or an empty socket node from being treated as an
actual detected accessory. It is an offline/operator tool; request-time
inspection continues to consume the frozen anchor JSON files.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import numpy as np
import trimesh
from pygltflib import GLTF2

from utils.extract_anchors import SOCKET_NAMES


def _rounded(values: Any) -> list[float]:
    return [round(float(value), 6) for value in values]


def _transform_matrix(transform: np.ndarray) -> list[list[float]]:
    return [[round(float(value), 6) for value in row] for row in transform]


def _parent_map(scene: trimesh.Scene) -> dict[str, str]:
    return dict(scene.graph.transforms.parents)


def _material_info(mesh: trimesh.Trimesh) -> dict[str, Any]:
    material = getattr(mesh.visual, "material", None)
    if material is None:
        return {"name": None, "has_base_color_texture": False, "has_any_texture": False}
    image = getattr(material, "image", None)
    texture = getattr(material, "baseColorTexture", None)
    return {
        "name": getattr(material, "name", None),
        "has_base_color_texture": texture is not None or image is not None,
        "has_any_texture": any(
            getattr(material, attribute, None) is not None
            for attribute in (
                "image",
                "baseColorTexture",
                "normalTexture",
                "metallicRoughnessTexture",
                "occlusionTexture",
                "emissiveTexture",
            )
        ),
    }


def _mesh_manifest(mesh: trimesh.Trimesh) -> dict[str, Any]:
    bounds = np.asarray(mesh.bounds, dtype=float)
    return {
        "vertex_count": int(len(mesh.vertices)),
        "face_count": int(len(mesh.faces)),
        "bounds_min": _rounded(bounds[0]),
        "bounds_max": _rounded(bounds[1]),
        "center": _rounded(mesh.centroid),
        "size": _rounded(bounds[1] - bounds[0]),
        "material": _material_info(mesh),
    }


def _gltf_metadata(path: Path) -> dict[str, int]:
    gltf = GLTF2().load(str(path))
    return {
        "skin_count": len(gltf.skins or []),
        "animation_count": len(gltf.animations or []),
    }


def extract_manifest(path: str | Path) -> dict[str, Any]:
    """Return a deterministic manifest for one GLB file."""
    glb_path = Path(path)
    scene = trimesh.load(str(glb_path), force="scene")
    parents = _parent_map(scene)
    geometry_nodes: dict[str, str] = {}
    for node in scene.graph.nodes_geometry:
        _transform, geometry_name = scene.graph[node]
        geometry_nodes[node] = geometry_name

    nodes: list[dict[str, Any]] = []
    for node in sorted(scene.graph.nodes):
        transform, geometry_name = scene.graph.get(node)
        record: dict[str, Any] = {
            "name": node,
            "parent": parents.get(node),
            "transform": _transform_matrix(transform),
            "translation": _rounded(transform[:3, 3]),
            "geometry": geometry_name,
            "has_geometry": node in geometry_nodes,
            "is_anchor": node in SOCKET_NAMES,
        }
        if geometry_name is not None:
            record["mesh"] = _mesh_manifest(scene.geometry[geometry_name])
        nodes.append(record)

    meshes = {
        name: _mesh_manifest(scene.geometry[name]) for name in sorted(scene.geometry)
    }
    anchors = {
        name: {
            "node": name,
            "translation": next(node["translation"] for node in nodes if node["name"] == name),
            "has_geometry": next(node["has_geometry"] for node in nodes if node["name"] == name),
        }
        for name in SOCKET_NAMES
        if any(node["name"] == name for node in nodes)
    }
    metadata = _gltf_metadata(glb_path)
    return {
        "schema_version": 1,
        "source_glb": str(glb_path),
        "file": {"name": glb_path.name, "size_bytes": glb_path.stat().st_size},
        "metadata": metadata,
        "counts": {
            "node_count": len(nodes),
            "mesh_count": len(meshes),
            "anchor_count": len(anchors),
            "transform_only_anchor_count": sum(
                not anchor["has_geometry"] for anchor in anchors.values()
            ),
        },
        "anchors": anchors,
        "meshes": meshes,
        "nodes": nodes,
    }


def extract_directory(directory: str | Path) -> dict[str, Any]:
    """Extract all top-level and nested GLBs below ``directory``."""
    root = Path(directory)
    paths = sorted(root.rglob("*.glb"))
    return {
        "schema_version": 1,
        "source_directory": str(root),
        "models": [extract_manifest(path) for path in paths],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--glb", type=Path, help="Extract one GLB")
    source.add_argument("--directory", type=Path, help="Extract all GLBs below a directory")
    parser.add_argument("--out", type=Path, required=True, help="Output JSON path")
    args = parser.parse_args()

    result = extract_manifest(args.glb) if args.glb else extract_directory(args.directory)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    if "models" in result:
        print(f"Wrote {len(result['models'])} model manifests to {args.out}")
    else:
        counts = result["counts"]
        print(
            f"Wrote {args.out}: {counts['node_count']} nodes, "
            f"{counts['mesh_count']} meshes, {counts['anchor_count']} anchors"
        )


if __name__ == "__main__":
    main()

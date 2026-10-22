"""RSAF No.4 dressed figures as render-ready, labelled scenes.

Shared by the RSAF segmentation-dataset generator, the pose-offset
calibration and the violation benchmark
(ChangeRequest/2026-10-05_cv-service-rsaf-no4.md).

The figures (`assets/3d/bodies/rsaf_no4_{male,female}.glb`, prepared by
`tool/prepare_unified_figure.mjs`) model every No.4 item as named nodes.
`load_figure` flattens one into a list of `Part`s — world-space mesh, the
segmentation class it belongs to (from its node ancestry), and the item
group it can be removed / displaced / swapped as. `build_scene` then
applies per-render variation: random removals (so the segmenter learns
absence), a Sikh turban in place of the beret, the cadet rank tab, a
random surname on the name tape, and item displacements (benchmark).
"""

from __future__ import annotations

import copy
import random
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[2]
FIGURE_GLB = {g: REPO_ROOT / "assets" / "3d" / "bodies" / f"rsaf_no4_{g}.glb" for g in ("male", "female")}
ACCESSORY_DIR = REPO_ROOT / "assets" / "3d" / "accessories"

# Segmentation classes: segmentation_v2's 12 + two RSAF No.4 items. Order is
# the YOLO class id — append only, never reorder (seg_v2 labels stay valid).
CLASSES_V3 = [
    "shirt", "trousers", "headwear", "cap_badge", "epaulette", "sleeve_rank",
    "arms_badge", "belt", "footwear", "name_tag", "socks", "hand",
    "rank_tab", "sleeve_patch",
]

# Item group → class. Checked against a part's node ancestry, most specific
# first (the beret badge sits inside the beret).
GROUP_CLASS = [
    ("beret_badge", "cap_badge"),
    ("beret", "headwear"),
    ("rank_tab_assembly", "rank_tab"),
    ("name_tape", "name_tag"),
    ("country_tape", "name_tag"),  # SINGAPORE tag: same look; position separates them
    ("shoulder_patch_left", "sleeve_patch"),
    ("shoulder_patch_right", "sleeve_patch"),
    ("wing_badge_assembly", None),  # optional chest badge — no class (as Army saf_badge)
    ("boots", "footwear"),
    ("trousers", "trousers"),
    ("field_shirt", "shirt"),
    ("field_collar", "shirt"),
    ("field_sleeves", "shirt"),
    ("arm_left", "hand"),
    ("arm_right", "hand"),
]
_GROUPS = [g for g, _ in GROUP_CLASS]

# Groups a scene may drop (probability), so the model sees each item absent.
REMOVAL_P = {
    "beret_badge": 0.12, "rank_tab_assembly": 0.12, "name_tape": 0.12, "country_tape": 0.12,
    "shoulder_patch_left": 0.12, "shoulder_patch_right": 0.12, "wing_badge_assembly": 0.5,
}

SURNAMES = ["TAN", "LIM", "LEE", "NG", "WONG", "ONG", "GOH", "CHUA", "KUMAR", "SINGH", "RAHMAN",
            "ISMAIL", "BALWANT S", "A K TAN", "NURUL", "KOH", "TEO", "LOW", "YEO", "RAJ"]


@dataclass
class Part:
    mesh: trimesh.Trimesh
    class_name: str | None
    group: str | None


@dataclass
class Figure:
    gender: str
    parts: list[Part]
    sockets: dict[str, np.ndarray]
    tape_material: object | None = field(default=None)


def _ancestry(scene: trimesh.Scene, node: str) -> list[str]:
    parents = scene.graph.transforms.parents
    out = []
    while node in parents:
        out.append(node)
        node = parents[node]
    return out


def load_figure(gender: str) -> Figure:
    scene = trimesh.load(FIGURE_GLB[gender])
    parts: list[Part] = []
    tape_material = None
    for node in scene.graph.nodes_geometry:
        transform, geom_name = scene.graph[node]
        mesh = scene.geometry[geom_name].copy()
        mesh.apply_transform(transform)
        chain = _ancestry(scene, node)
        group = next((g for g in _GROUPS if g in chain), None)
        class_name = dict(GROUP_CLASS).get(group) if group else None
        material = getattr(mesh.visual, "material", None)
        if material is not None and getattr(material, "name", "") == "name_tag_mat":
            tape_material = material
        parts.append(Part(mesh, class_name, group))
    sockets = {}
    for node in scene.graph.nodes:
        if node in scene.graph.nodes_geometry or node == scene.graph.base_frame:
            continue
        transform, _ = scene.graph[node]
        sockets[node] = np.asarray(transform)[:3, 3]
    return Figure(gender, parts, sockets, tape_material)


def group_bounds(figure: Figure, group: str) -> np.ndarray | None:
    pts = [p.mesh.vertices for p in figure.parts if p.group == group]
    return np.vstack(pts) if pts else None


def _tape_texture(base: Image.Image, text: str) -> Image.Image:
    img = base.convert("RGB").copy()
    draw = ImageDraw.Draw(img)
    w, h = img.size
    try:
        font = ImageFont.truetype("Arial Bold.ttf", int(h * 0.55))
    except OSError:
        try:
            font = ImageFont.truetype("DejaVuSans-Bold.ttf", int(h * 0.55))
        except OSError:
            font = ImageFont.load_default()
    box = draw.textbbox((0, 0), text, font=font)
    draw.text(((w - (box[2] - box[0])) / 2, (h - (box[3] - box[1])) / 2 - box[1]), text,
              fill=(238, 238, 232), font=font)
    return img


def _accessory(stem: str, offset: np.ndarray) -> trimesh.Trimesh | None:
    path = ACCESSORY_DIR / f"{stem}.glb"
    if not path.exists():
        return None
    mesh = trimesh.load(path, force="mesh")
    mesh.apply_translation(offset)
    return mesh


def build_scene(
    figure: Figure,
    rng: random.Random,
    *,
    removals: dict[str, float] | None = None,
    sikh: bool | None = None,
    cadet: bool | None = None,
    surname: str | None = None,
    displacements: dict[str, np.ndarray] | None = None,
    remove: set[str] | None = None,
) -> list[tuple[trimesh.Trimesh, str | None]]:
    """(mesh, class) pairs for one render. `removals` = per-group drop
    probabilities (default REMOVAL_P; `{}` for a fully dressed figure);
    `remove` drops groups deterministically; `displacements` translates a
    group (metres, world) — the benchmark's injected misplacements."""
    removals = REMOVAL_P if removals is None else removals
    remove = set(remove or ())
    remove |= {g for g, p in removals.items() if rng.random() < p}
    if sikh is None:
        sikh = figure.gender == "male" and rng.random() < 0.15
    if cadet is None:
        cadet = rng.random() < 0.1
    if sikh:
        remove |= {"beret", "beret_badge"}
    if cadet:
        remove.add("rank_tab_assembly")
    displacements = displacements or {}

    tape_text = surname or rng.choice(SURNAMES)
    out: list[tuple[trimesh.Trimesh, str | None]] = []
    for part in figure.parts:
        if part.group in remove:
            continue
        mesh = part.mesh
        if part.group in displacements:
            mesh = mesh.copy()
            mesh.apply_translation(displacements[part.group])
        if part.group == "name_tape" and figure.tape_material is not None:
            mesh = mesh.copy()
            mat = copy.copy(mesh.visual.material)
            base = getattr(figure.tape_material, "baseColorTexture", None)
            if base is not None:
                mat.baseColorTexture = _tape_texture(base, tape_text)
                mesh.visual.material = mat
        out.append((mesh, part.class_name))

    s = figure.sockets
    if sikh and "head_top" in s:
        turban = _accessory("rsaf_sikh_turban", s["head_top"])
        badge = _accessory("rsaf_cap_badge_sltc_me6_below", s["cap_band_front"] + np.array([0, 0.013, 0]))
        out += [(m, c) for m, c in ((turban, "headwear"), (badge, "cap_badge")) if m is not None]
    if cadet and "belt_center" in s:
        tab = _accessory("rsaf_no4_rank_epaulette_cadet_trainee", s["belt_center"] + np.array([0, 0.20, 0.005]))
        if tab is not None:
            out.append((tab, "rank_tab"))
    return out

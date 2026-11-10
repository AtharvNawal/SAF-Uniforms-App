"""Uniform registry — which doctrine, reference anchors, pose-offset fit
and reference stature each `uniform_type` is checked against.

Before this module every stage hard-wired Army No.3 male
(`rules/army_no3_male.json`, `rules/anchors.male.json`,
`pose/anchor_offsets.male.json`, 1.78 m). The `uniform_type` the app
sends (`{branch}_{dress}_{gender}`, e.g. `rsaf_no4_female`) now selects a
`UniformSpec`; anything not listed here is a typed 422
`UNSUPPORTED_UNIFORM`. Every module keeps Army No.3 as its default, so
callers that don't pass a spec behave exactly as before.

See ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

_ROOT = Path(__file__).resolve().parent


@dataclass(frozen=True)
class UniformSpec:
    uniform_type: str
    service: str
    dress: str
    gender: str
    rules_path: Path
    anchors_path: Path
    offsets_path: Path
    # Stature (m) of the reference body the anchor file was measured on;
    # anchors are rescaled about the feet to the wearer's `height_cm`.
    reference_stature_m: float
    # Segmentation model this uniform is judged with (a models/ dir name), or
    # `None` for the service default. Used only once that model is promoted
    # (segmentation/segment_uniform.py). Per uniform, because the model that
    # learned RSAF No.4 got worse at Army belts (false alarms 17.9% -> 62.5%).
    segmentation_model: str | None = None


def _spec(uniform_type: str, body: str, stature: float, segmentation_model: str | None = None) -> UniformSpec:
    service, dress, gender = uniform_type.split("_")
    return UniformSpec(
        uniform_type=uniform_type,
        service=service,
        dress=dress,
        gender=gender,
        rules_path=_ROOT / "rules" / f"{uniform_type}.json",
        anchors_path=_ROOT / "rules" / f"anchors.{body}.json",
        offsets_path=_ROOT / "pose" / f"anchor_offsets.{body}.json",
        reference_stature_m=stature,
        segmentation_model=segmentation_model,
    )


UNIFORMS: dict[str, UniformSpec] = {
    # `assets/3d/bodies/male_apose.glb`, normalised to 1.78 m by
    # tool/inject_sockets.py (CLAUDE.md §8, pass 3).
    "army_no3_male": _spec("army_no3_male", "male", 1.78),
    # RSAF No.4 dressed figures `assets/3d/bodies/rsaf_no4_{male,female}.glb`
    # (crown of the head, measured by utils/extract_figure_anchors.py).
    "rsaf_no4_male": _spec("rsaf_no4_male", "rsaf_no4_male", 1.745, "segmentation_v3"),
    "rsaf_no4_female": _spec("rsaf_no4_female", "rsaf_no4_female", 1.694, "segmentation_v3"),
}

DEFAULT = UNIFORMS["army_no3_male"]
SUPPORTED_UNIFORM_TYPES = frozenset(UNIFORMS)


def get(uniform_type: str) -> UniformSpec | None:
    return UNIFORMS.get(uniform_type)

"""E18 — one plain-language instruction per checked item.

Turns a `VerdictResult` into what the wearer should *do*, in centimetres
and in their own left/right ("move it 1.5 cm up and 0.5 cm to your
right"), instead of pixel offsets. Directions assume an un-mirrored photo
of the wearer from the front, where image-right is the wearer's LEFT —
the same convention `utils/extract_anchors.py` names anchors by.
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

import config
from rules.rule_engine import VerdictResult

_LIBRARY = Path(__file__).resolve().parents[2] / "assets" / "data" / "accessory_library.v1.json"


@lru_cache(maxsize=1)
def _display_names() -> dict[str, str]:
    try:
        return {e["id"]: e.get("display_name", e["id"]) for e in json.loads(_LIBRARY.read_text())["accessories"]}
    except (OSError, KeyError, ValueError):
        return {}


def display_name(accessory_id: str) -> str:
    return _display_names().get(accessory_id) or accessory_id.replace("_", " ").title()


def _move_phrase(verdict: VerdictResult) -> str | None:
    if verdict.error_px is None or not verdict.px_per_cm:
        return None
    # error = detected − expected, so the fix is the opposite vector.
    move_x_cm = -verdict.error_px[0] / verdict.px_per_cm
    move_y_cm = -verdict.error_px[1] / verdict.px_per_cm
    parts = []
    if abs(move_y_cm) >= config.INSTRUCTION_MIN_CM:
        parts.append(f"{abs(move_y_cm):.1f} cm {'down' if move_y_cm > 0 else 'up'}")
    if abs(move_x_cm) >= config.INSTRUCTION_MIN_CM:
        # image +x is the wearer's left
        parts.append(f"{abs(move_x_cm):.1f} cm to your {'left' if move_x_cm > 0 else 'right'}")
    return " and ".join(parts) if parts else None


def _offset_cm(verdict: VerdictResult) -> float | None:
    if verdict.error_px is None or not verdict.px_per_cm:
        return None
    return (verdict.error_px[0] ** 2 + verdict.error_px[1] ** 2) ** 0.5 / verdict.px_per_cm


def instruction_for(verdict: VerdictResult) -> str:
    name = display_name(verdict.accessory)
    kind = verdict.failure_kind
    if verdict.status == "pass":
        return f"{name}: correct."
    if verdict.status == "missing":
        return f"{name}: not found where doctrine places it — put it on, or make sure it isn't covered."
    if verdict.status in ("fail", "slightly_misaligned"):
        if kind == "color":
            return f"{name}: wrong colour — doctrine requires black."
        if kind == "variant":
            return f"{name}: this looks like a different badge from the one your rank wears — check you have the right one."
        if kind == "name_text":
            return f"{name}: the name on the tag doesn't match your profile — wear your own name tag."
        if kind == "orientation" and verdict.angle_error_deg is not None:
            return f"{name}: straighten it — it's tilted about {verdict.angle_error_deg:.0f}°."
        move = _move_phrase(verdict)
        prefix = "slightly off" if verdict.status == "slightly_misaligned" else "out of position"
        return f"{name}: {prefix} — move it about {move}." if move else f"{name}: {prefix} — check its placement against the doctrine diagram."
    # unverifiable
    if kind == "no_detector":
        return f"{name}: can't be checked automatically yet — check it yourself against the doctrine diagram."
    if kind == "out_of_frame":
        return f"{name}: not in the photo — retake with your whole body in frame."
    if kind == "camera":
        return f"{name}: couldn't measure from this photo's angle — retake standing square-on to the camera."
    if kind == "unconfirmed":
        return (f"{name}: couldn't confirm it's there — make sure it's on and clearly visible, "
                f"then retake, or check it yourself.")
    if kind == "boundary":
        offset = _offset_cm(verdict)
        if offset is None:
            return f"{name}: too close to the tolerance to judge from this photo — check it closely."
        tolerance = verdict.tolerance_cm or offset
        where = "looks correctly placed" if offset <= 0.75 * tolerance else "may be slightly off"
        return (f"{name}: {where} (measured about {offset:.1f} cm from the doctrine position), but a full-body photo "
                f"can't confirm it to doctrine's tolerance — check it closely.")
    return f"{name}: couldn't be checked from this photo."

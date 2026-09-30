"""Camera intrinsics for the PnP solve (D16).

A wrong focal length is the single biggest source of recovered-camera
depth error: PnP trades focal length off against camera distance, so a
guessed `focal ≈ image width` put the solved camera 57-115 cm off on the
known-camera stand-ins, while the true focal brings that to 0-4 cm (see
ChangeRequest/2026-09-28_accuracy-program-no-real-data.md). Phones write
the 35 mm-equivalent focal length into EXIF, which is enough to recover
the focal length in pixels without any calibration step.

Priority: explicit `focal_length_px` form field (the app knows its
camera) → EXIF `FocalLengthIn35mmFilm` → EXIF `FocalLength` +
`FocalPlaneXResolution` → `None` (caller falls back to the old guess and
reports `focal_source="assumed"`).
"""

from __future__ import annotations

import math
from dataclasses import dataclass

from PIL import Image

import config

_TAG_FOCAL_LENGTH = 0x920A
_TAG_FOCAL_35MM = 0xA405
_TAG_FOCAL_PLANE_X_RES = 0xA20E
_TAG_FOCAL_PLANE_RES_UNIT = 0xA210
_EXIF_IFD = 0x8769
_FULL_FRAME_DIAGONAL_MM = math.hypot(36.0, 24.0)


@dataclass(frozen=True)
class Intrinsics:
    focal_px: float | None
    source: str  # "client" | "exif_35mm" | "exif_focal_plane" | "assumed"


def _exif_fields(image_path: str) -> dict:
    try:
        with Image.open(image_path) as img:
            exif = img.getexif()
            fields = dict(exif)
            try:
                fields.update(exif.get_ifd(_EXIF_IFD))
            except (KeyError, AttributeError):
                pass
            return fields
    except Exception:  # noqa: BLE001 - unreadable EXIF just means "no EXIF"
        return {}


def focal_px_from_exif(image_path: str, width: int, height: int) -> Intrinsics:
    """`width`/`height` must be the dimensions of the image as it will be
    processed (after EXIF orientation is applied); the 35 mm equivalent is
    defined on the diagonal, which is orientation-independent."""
    fields = _exif_fields(image_path)

    f35 = fields.get(_TAG_FOCAL_35MM)
    try:
        f35 = float(f35) if f35 else 0.0
    except (TypeError, ValueError):
        f35 = 0.0
    if f35 > 0:
        return Intrinsics(focal_px=f35 * math.hypot(width, height) / _FULL_FRAME_DIAGONAL_MM, source="exif_35mm")

    focal_mm, x_res, unit = fields.get(_TAG_FOCAL_LENGTH), fields.get(_TAG_FOCAL_PLANE_X_RES), fields.get(_TAG_FOCAL_PLANE_RES_UNIT)
    try:
        focal_mm, x_res = float(focal_mm), float(x_res)
    except (TypeError, ValueError):
        return Intrinsics(focal_px=None, source="assumed")
    unit_mm = {2: 25.4, 3: 10.0, 4: 1.0}.get(int(unit or 2))
    if focal_mm > 0 and x_res > 0 and unit_mm:
        return Intrinsics(focal_px=focal_mm * x_res / unit_mm, source="exif_focal_plane")
    return Intrinsics(focal_px=None, source="assumed")


def resolve_intrinsics(image_path: str, width: int, height: int, client_focal_px: float | None) -> Intrinsics:
    if client_focal_px and client_focal_px > 0:
        return Intrinsics(focal_px=float(client_focal_px), source="client")
    if not config.USE_EXIF_INTRINSICS:
        return Intrinsics(focal_px=None, source="assumed")
    return focal_px_from_exif(image_path, width, height)

"""Pure geometry helpers on a `SegmentedRegion.mask` (boolean array) —
centroid and orientation. Used by `rules/rule_engine.py`'s
`evaluate_verdicts` to compare a detected segment's actual position/angle
against a doctrine rule's projected expected point.

Deliberately separate from `rule_engine.py`: this is mask-only math with
no doctrine/rule knowledge, independently testable against synthetic
masks with a known-exact answer.
"""

from __future__ import annotations

import cv2
import numpy as np

# Below this width/height ratio, a rectangle fit's angle is dominated by
# pixel-level mask noise rather than the object's actual orientation — a
# round-ish silhouette (e.g. a cap badge close to square-on) shouldn't
# produce a confident angle reading it can't actually support. See the
# plan file's §4 for the justification.
DEFAULT_MIN_ASPECT_RATIO = 1.3


def mask_centroid_px(mask: np.ndarray) -> tuple[float, float] | None:
    """Returns (x, y) in pixel space, or `None` for an empty mask."""
    ys, xs = np.nonzero(mask)
    if len(xs) == 0:
        return None
    return float(xs.mean()), float(ys.mean())


def mask_orientation_deg(mask: np.ndarray, *, min_aspect_ratio: float = DEFAULT_MIN_ASPECT_RATIO) -> float | None:
    """Angle (degrees) of the mask's dominant axis via `cv2.minAreaRect`
    on its largest contour. Returns `None` (never a guessed angle) when:
    the mask is empty, no contour can be extracted, or the fitted
    rectangle is too close to square (aspect ratio < `min_aspect_ratio`)
    to have a reliable long axis.

    The angle is only meaningful modulo 180° — a plain rectangle fit
    can't distinguish an object from its 180°-rotated twin. Doctrine
    tolerances this feeds into (single digits to low teens degrees) are
    far tighter than that ambiguity window, so callers should resolve to
    whichever of (angle, angle ± 180) is nearer their target rather than
    trusting the raw sign.
    """
    if mask is None or not mask.any():
        return None

    contours, _ = cv2.findContours(mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None
    largest = max(contours, key=cv2.contourArea)
    if cv2.contourArea(largest) < 9:  # a handful of stray pixels isn't a shape
        return None

    (_cx, _cy), (w, h), angle = cv2.minAreaRect(largest)
    if w == 0 or h == 0:
        return None

    long_side, short_side = max(w, h), min(w, h)
    if long_side / short_side < min_aspect_ratio:
        return None

    # cv2.minAreaRect's angle is relative to whichever of w/h it picked
    # as "width" — normalize so the returned angle always describes the
    # LONG axis, regardless of that internal choice.
    return angle if w >= h else angle + 90.0


def angle_difference_deg(measured: float, target: float) -> float:
    """Smallest difference between two angles, treated as equivalent
    modulo 180° (see `mask_orientation_deg`'s docstring)."""
    diff = abs(measured - target) % 180.0
    return min(diff, 180.0 - diff)


def mask_reference_point(mask: np.ndarray, kind: str = "center") -> tuple[float, float] | None:
    """The point of a mask that a doctrine rule measures from (A3):
    `center` (centroid), `top_edge` / `bottom_edge` (the centroid's x,
    and the median over the mask's columns of each column's top-most /
    bottom-most pixel — robust to a ragged outline in a way a single
    extreme pixel isn't). `None` for an empty mask."""
    centroid = mask_centroid_px(mask)
    if centroid is None or kind == "center":
        return centroid
    ys, xs = np.nonzero(mask)
    columns = np.unique(xs)
    if kind == "top_edge":
        edge = [ys[xs == c].min() for c in columns]
    elif kind == "bottom_edge":
        edge = [ys[xs == c].max() for c in columns]
    else:
        return centroid
    return (centroid[0], float(np.median(edge)))

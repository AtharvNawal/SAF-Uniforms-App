"""A2 — refine pose-derived anchors from segmentation masks before the
camera solve.

Pose landmarks are joint centres; several doctrine anchors are garment
features that the segmentation masks locate directly:

  - `head_top`       ← top of the `headwear` mask (the anchor sits at the
                       crown of a worn beret); `cap_band_front` is moved
                       by the same correction, since it's defined 6-7 cm
                       below `head_top` on the same head
  - `belt_center`    ← the waistline: midway between the bottom of the
                       `shirt` mask and the top of the `trousers` mask in
                       the columns around the hip midpoint
  - `left/right_ankle` ← top of each `footwear` blob

**No anchor is refined from the item that is later judged against it.**
The belt anchor comes from the shirt/trousers waistline, never from the
belt mask (that would measure the belt against itself). The headwear mask
refines `head_top`, which only feeds the *cap badge* check and the
beret's lenient presence-in-region check.

A refinement is applied only when it lands within
`MASK_ANCHOR_MAX_SHIFT_SW` shoulder widths of the pose estimate — a
wrong mask (a hat on the wall, the other person's shoes) can't drag the
geometry far. Refined anchors carry `source: "mask"`.
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import math

import cv2
import numpy as np

import config
from pose.anchor_mapping import body_frame
from segmentation.segment_uniform import SegmentationResult


def _largest(segmentation: SegmentationResult, class_name: str):
    regions = [r for r in segmentation.regions if r.class_name == class_name and r.confidence >= config.MIN_SEGMENT_CONFIDENCE]
    return max(regions, key=lambda r: int(r.mask.sum()), default=None)


def _head_top(segmentation: SegmentationResult) -> tuple[float, float] | None:
    headwear = _largest(segmentation, "headwear")
    if headwear is None:
        return None
    ys, xs = np.nonzero(headwear.mask)
    top = ys.min()
    band = xs[ys <= top + max(2, int(0.08 * (ys.max() - top)))]
    return float(np.median(band)), float(top)


def _waistline(segmentation: SegmentationResult, center_x: float, half_width: float) -> tuple[float, float] | None:
    shirt, trousers = _largest(segmentation, "shirt"), _largest(segmentation, "trousers")
    if shirt is None or trousers is None:
        return None
    x1, x2 = int(max(0, center_x - half_width)), int(center_x + half_width) + 1
    shirt_cols, trouser_cols = shirt.mask[:, x1:x2], trousers.mask[:, x1:x2]
    shirt_bottoms = [np.nonzero(c)[0].max() for c in shirt_cols.T if c.any()]
    trouser_tops = [np.nonzero(c)[0].min() for c in trouser_cols.T if c.any()]
    if not shirt_bottoms or not trouser_tops:
        return None
    return center_x, (float(np.median(shirt_bottoms)) + float(np.median(trouser_tops))) / 2


def _ankles(segmentation: SegmentationResult) -> dict[str, tuple[float, float]]:
    footwear = [r for r in segmentation.regions if r.class_name == "footwear" and r.confidence >= config.MIN_SEGMENT_CONFIDENCE]
    if not footwear:
        return {}
    combined = np.zeros_like(footwear[0].mask, dtype=np.uint8)
    for region in footwear:
        combined |= region.mask.astype(np.uint8)
    count, labels, stats, centroids = cv2.connectedComponentsWithStats(combined)
    blobs = sorted(range(1, count), key=lambda i: stats[i, cv2.CC_STAT_AREA], reverse=True)[:2]
    if len(blobs) < 2:
        return {}
    # Wearer's left foot is image-right in a front photo.
    right_blob, left_blob = sorted(blobs, key=lambda i: centroids[i][0])
    return {
        "left_ankle": (float(centroids[left_blob][0]), float(stats[left_blob, cv2.CC_STAT_TOP])),
        "right_ankle": (float(centroids[right_blob][0]), float(stats[right_blob, cv2.CC_STAT_TOP])),
    }


def refine_anchors_with_masks(anchor_pose: dict[str, dict], segmentation: SegmentationResult) -> dict[str, dict]:
    if not config.MASK_ANCHOR_REFINEMENT:
        return anchor_pose
    frame = body_frame(anchor_pose)
    if frame is None:
        return anchor_pose
    origin, _outward, _down, shoulder_width = frame
    max_shift = config.MASK_ANCHOR_MAX_SHIFT_SW * shoulder_width
    refined = dict(anchor_pose)

    def apply(name: str, point: tuple[float, float] | None) -> tuple[float, float] | None:
        current = anchor_pose.get(name)
        if point is None or not current or current.get("x_px") is None:
            return None
        shift = (point[0] - current["x_px"], point[1] - current["y_px"])
        if math.hypot(*shift) > max_shift:
            return None
        refined[name] = {
            **current, "x_px": point[0], "y_px": point[1],
            "confidence": max(current["confidence"], config.MASK_ANCHOR_CONFIDENCE),
            "residual_px": config.MASK_ANCHOR_RESIDUAL_SW * shoulder_width,
            "source": "mask",
        }
        return shift

    head_shift = apply("head_top", _head_top(segmentation))
    band = anchor_pose.get("cap_band_front")
    if head_shift is not None and band and band.get("x_px") is not None:
        refined["cap_band_front"] = {**band, "x_px": band["x_px"] + head_shift[0], "y_px": band["y_px"] + head_shift[1], "source": "mask"}

    belt = anchor_pose.get("belt_center")
    if belt and belt.get("x_px") is not None:
        apply("belt_center", _waistline(segmentation, belt["x_px"], 0.15 * shoulder_width))

    for name, point in _ankles(segmentation).items():
        apply(name, point)
    return refined

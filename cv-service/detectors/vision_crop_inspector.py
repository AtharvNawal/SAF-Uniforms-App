"""Stage 4/5 SUBSTITUTE — region-guided vision-language inspection.

Read this docstring before trusting this module's output for anything
beyond a demo. This is explicitly **not** the trained accessory
detector / segmentation model the architecture memo's Stage 4 and 5
describe — that needs labeled training data (real photos or Blender
synthetic renders) and a training run that do not exist yet.

What this *is*: the real geometry from Stages 1-3 and 6 already knows
*where* each accessory should appear in this specific photo — that part
is measured, not guessed. This module asks Claude to answer only the
narrower question "what do you see inside this small, already-located
crop" instead of "find all 18 accessories somewhere in this photo,"
which is a meaningfully easier and more constrained task than Phase 1's
whole-photo call, even without a trained detector standing behind it.
Treat every verdict here as a vision-language judgment, not a
measurement — the position was measured, the identification was not.
"""

from __future__ import annotations

import base64
import os
from dataclasses import dataclass

import cv2
import numpy as np

from rules.rule_engine import CropBox, ResolvedRule

MODEL = "claude-sonnet-5"
_REPORT_TOOL_NAME = "report_crop_verdict"
_CROP_PADDING_PX = 6
_MIN_CROP_SIDE_PX = 60  # upscale tiny crops so the model has enough to look at

_REPORT_TOOL = {
    "name": _REPORT_TOOL_NAME,
    "description": "Report whether the expected uniform item is present and correctly worn inside this cropped region.",
    "input_schema": {
        "type": "object",
        "properties": {
            "verdict": {
                "type": "string",
                "enum": ["present", "missing", "misaligned", "wrong_type", "low_confidence"],
            },
            "confidence": {"type": "number", "description": "0.0-1.0"},
            "note": {"type": "string", "description": "One sentence: what you actually see and why."},
        },
        "required": ["verdict", "confidence", "note"],
    },
}


@dataclass(frozen=True)
class CropVerdict:
    object_id: str
    anchor_name: str
    verdict: str
    confidence: float
    note: str
    crop: CropBox


def _client():
    import anthropic

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY not set — the vision-crop inspector needs it "
            "(same secret already provisioned for checkUniformCompliance in "
            "Firebase Secret Manager)."
        )
    return anthropic.Anthropic(api_key=api_key)


def _extract_crop_jpeg(image_bgr: np.ndarray, box: CropBox) -> bytes:
    h, w = image_bgr.shape[:2]
    x1 = max(0, int(box.x1) - _CROP_PADDING_PX)
    y1 = max(0, int(box.y1) - _CROP_PADDING_PX)
    x2 = min(w, int(box.x2) + _CROP_PADDING_PX)
    y2 = min(h, int(box.y2) + _CROP_PADDING_PX)
    crop = image_bgr[y1:y2, x1:x2]

    ch, cw = crop.shape[:2]
    if cw < _MIN_CROP_SIDE_PX or ch < _MIN_CROP_SIDE_PX:
        scale = _MIN_CROP_SIDE_PX / max(cw, ch, 1)
        crop = cv2.resize(crop, (max(int(cw * scale), 1), max(int(ch * scale), 1)))

    ok, buf = cv2.imencode(".jpg", crop, [cv2.IMWRITE_JPEG_QUALITY, 92])
    if not ok:
        raise ValueError("failed to encode crop as JPEG")
    return buf.tobytes()


def _build_prompt(rule: ResolvedRule, anchor_name: str) -> str:
    return (
        f"You are inspecting a small cropped region of a Singapore Armed Forces "
        f"(SAF) Army No.3 uniform photo. The crop was positioned by measured "
        f"body geometry (pose estimation + camera-pose recovery), centred where "
        f"this item is expected to be — your job is only to judge what is "
        f"visible inside this crop, not to search the rest of the photo.\n\n"
        f"Expected item: \"{rule.object_id}\" (category: {rule.category})\n"
        f"Doctrine rule: {rule.rule_text or rule.doctrine_ref}\n"
        f"Doctrine reference: {rule.doctrine_ref}\n"
        f"This crop corresponds to anchor: {anchor_name}\n\n"
        f"Decide: is the expected item clearly present and correctly worn here "
        f"(\"present\"), clearly absent (\"missing\"), visible but positioned/"
        f"oriented wrong within the crop (\"misaligned\"), visible but the wrong "
        f"variant/type of item (\"wrong_type\"), or impossible to judge — "
        f"occluded, blurry, cropped out (\"low_confidence\")? "
        f"Call {_REPORT_TOOL_NAME} with your verdict."
    )


def inspect_crop(
    image_bgr: np.ndarray, rule: ResolvedRule, crop: CropBox, *, client=None
) -> CropVerdict:
    """Judge a single crop. `client` is injectable for testing — pass a
    fake object exposing `.messages.create(...)` returning the same
    shape the Anthropic SDK does, to test this module without a live
    API key."""
    client = client or _client()
    jpeg_bytes = _extract_crop_jpeg(image_bgr, crop)
    image_b64 = base64.b64encode(jpeg_bytes).decode("ascii")

    message = client.messages.create(
        model=MODEL,
        max_tokens=512,
        tools=[_REPORT_TOOL],
        tool_choice={"type": "tool", "name": _REPORT_TOOL_NAME},
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _build_prompt(rule, crop.anchor_name)},
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": image_b64,
                        },
                    },
                ],
            }
        ],
    )

    tool_use = next((b for b in message.content if b.type == "tool_use"), None)
    if tool_use is None:
        return CropVerdict(
            object_id=rule.object_id,
            anchor_name=crop.anchor_name,
            verdict="low_confidence",
            confidence=0.0,
            note="model did not return a tool_use block",
            crop=crop,
        )

    result = tool_use.input
    return CropVerdict(
        object_id=rule.object_id,
        anchor_name=crop.anchor_name,
        verdict=result.get("verdict", "low_confidence"),
        confidence=float(result.get("confidence", 0.0)),
        note=result.get("note", ""),
        crop=crop,
    )


def inspect_resolved_rules(
    image_bgr: np.ndarray, resolved_rules: list[ResolvedRule], *, client=None
) -> list[CropVerdict]:
    """One verdict per crop (paired items — e.g. left/right sleeve
    insignia — produce two verdicts, one per side)."""
    client = client or _client()
    verdicts: list[CropVerdict] = []
    for rule in resolved_rules:
        for crop in rule.crops:
            verdicts.append(inspect_crop(image_bgr, rule, crop, client=client))
    return verdicts

"""Conservative uniform-identity gate built from existing segmentation output.

This is deliberately not presented as a trained SAF classifier. The current
segmentation models were trained on synthetic renders, so the gate only allows
inspection when the model finds a coherent torso, lower-body, and uniform
structure signal. Weak or contradictory evidence stops the compliance score
instead of allowing an accessory location false positive to become a pass.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from segmentation.segment_uniform import SegmentationResult


@dataclass(frozen=True)
class UniformIdentityResult:
    status: str
    detected_attire: str
    confidence: float
    message: str
    inspection_allowed: bool


def identify_uniform(
    segmentation: "SegmentationResult",
    selected_uniform: str,
    visual_evidence=None,
) -> UniformIdentityResult:
    shirt = segmentation.coverage_fraction("shirt")
    trousers = segmentation.coverage_fraction("trousers")
    footwear = segmentation.coverage_fraction("footwear")
    structure_classes = ("belt", "headwear", "epaulette", "sleeve_rank")
    structure = max(
        (segmentation.coverage_fraction(name) for name in structure_classes),
        default=0.0,
    )

    # These are intentionally conservative lower bounds. They are not a
    # classifier accuracy claim; they only block the known failure mode where
    # an isolated head-region detection is treated as an SAF accessory.
    if visual_evidence is not None and visual_evidence.available:
        if visual_evidence.detected_service == "CIVILIAN":
            return UniformIdentityResult(
                "INVALID_ATTIRE", "civilian clothing", visual_evidence.confidence,
                "The visual profile evidence identifies civilian clothing.", False,
            )
        if visual_evidence.detected_service == "OTHER_SAF":
            return UniformIdentityResult(
                "WRONG_UNIFORM", "different SAF service", visual_evidence.confidence,
                "The detected SAF profile does not match the selected service and dress.", False,
            )
        if not visual_evidence.supported_by_visual_evidence:
            return UniformIdentityResult(
                "UNABLE_TO_VERIFY", "unidentified attire", visual_evidence.confidence,
                "Visual uniform evidence is below the conservative verification threshold.", False,
            )

    if shirt < 0.04 and trousers < 0.04:
        return UniformIdentityResult(
            "INVALID_ATTIRE",
            "civilian clothing or no uniform",
            0.0,
            "No SAF uniform garment structure was detected.",
            False,
        )
    if shirt < 0.04 or trousers < 0.02 or footwear < 0.002:
        confidence = min(1.0, max(shirt, trousers, footwear) * 4)
        return UniformIdentityResult(
            "UNABLE_TO_VERIFY",
            "unidentified attire",
            round(confidence, 2),
            "The image does not show enough complete uniform structure to verify SAF attire.",
            False,
        )
    if structure < 0.0005:
        return UniformIdentityResult(
            "UNABLE_TO_VERIFY",
            "unidentified attire",
            round(min(1.0, shirt + trousers + footwear), 2),
            "Garment regions were detected, but no SAF-specific structure was verified.",
            False,
        )

    confidence = min(1.0, 0.45 + shirt + trousers + footwear + structure)
    return UniformIdentityResult(
        "VERIFIED",
        selected_uniform,
        round(confidence, 2),
        "Uniform garment structure passed the conservative identity gate.",
        True,
    )

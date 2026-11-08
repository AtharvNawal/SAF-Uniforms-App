"""Optional Hugging Face evidence adapters.

The adapters are deliberately lazy and opt-in. General-purpose pretrained
models are useful for candidate evidence, but they are not trained SAF
classifiers and must never override the conservative identity gate by default.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import config


@dataclass(frozen=True)
class UniformVisualEvidence:
    detected_service: str | None
    detected_dress: str | None
    confidence: float
    supported_by_visual_evidence: bool
    source: str
    available: bool
    message: str


def _labels(profile) -> list[str]:
    return [
        f"{profile.service.upper()} {profile.dress.upper()} SAF uniform",
        "civilian clothing",
        "different SAF service uniform",
    ]


def classify_uniform(image_path: str | Path, profile) -> UniformVisualEvidence:
    """Classify an image with SigLIP when explicitly enabled.

    Missing packages, weights, or inference failures return unavailable
    evidence instead of a success-shaped fallback.
    """
    if not config.HF_EVIDENCE_ENABLED:
        return UniformVisualEvidence(None, None, 0.0, False, "disabled", False, "Hugging Face evidence is disabled.")

    try:
        from PIL import Image
        import torch
        from transformers import AutoModel, AutoProcessor

        image = Image.open(image_path).convert("RGB")
        processor = AutoProcessor.from_pretrained(config.HF_SIGLIP_MODEL)
        model = AutoModel.from_pretrained(config.HF_SIGLIP_MODEL)
        inputs = processor(text=_labels(profile), images=image, padding="max_length", return_tensors="pt")
        with torch.no_grad():
            logits = model(**inputs).logits_per_image[0]
            probabilities = torch.softmax(logits, dim=-1)
        index = int(probabilities.argmax().item())
        confidence = float(probabilities[index].item())
    except (ImportError, OSError, RuntimeError, ValueError) as exc:
        return UniformVisualEvidence(None, None, 0.0, False, "siglip2", False, f"Model unavailable: {exc}")

    if index == 1:
        return UniformVisualEvidence("CIVILIAN", None, confidence, confidence >= config.HF_UNIFORM_MIN_CONFIDENCE, "siglip2", True, "Civilian clothing candidate.")
    if index == 2:
        return UniformVisualEvidence("OTHER_SAF", None, confidence, confidence >= config.HF_UNIFORM_MIN_CONFIDENCE, "siglip2", True, "Different SAF service candidate.")
    return UniformVisualEvidence(profile.service.upper(), profile.dress.upper(), confidence, confidence >= config.HF_UNIFORM_MIN_CONFIDENCE, "siglip2", True, "Selected profile candidate.")


def model_capabilities() -> dict[str, dict[str, str]]:
    """Return configured adapter capabilities without importing model packages."""
    return {
        "siglip2": {"model": config.HF_SIGLIP_MODEL, "purpose": "uniform/profile similarity"},
        "florence2": {"model": config.HF_FLORENCE_MODEL, "purpose": "secondary localization and descriptions"},
        "dinov2": {"model": config.HF_DINOV2_MODEL, "purpose": "reference-image similarity"},
    }

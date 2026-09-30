"""Stage 0 — image-quality validation, run before any model inference.

Cheap OpenCV/NumPy checks that catch the "this photo can't possibly work"
cases before spending a person-detection/pose/segmentation pass on it:
a corrupted file, an oversized upload, too small a resolution, or an
image too dark/bright/blurry to measure anything from reliably. None of
this is a trained model — just pixel statistics — so it needs no test
fixtures beyond synthetic NumPy arrays.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np

import config


@dataclass(frozen=True)
class ValidationResult:
    usable: bool
    status: str
    message: str
    confidence: float = 1.0


def _laplacian_variance(gray: np.ndarray) -> float:
    return float(cv2.Laplacian(gray, cv2.CV_64F).var())


def check_sharpness(image_bgr: np.ndarray, person_box=None) -> ValidationResult:
    """Laplacian-variance blur check, measured on the detected person when
    `person_box` is given. On the whole image, a plain wall — exactly the
    background the capture protocol asks for — has almost no edges and
    drags the score down even when the wearer is perfectly sharp: on the
    synthetic violation benchmark that falsely rejected 40% of scenes,
    while person-crop sharpness separated truly blurred frames (12-21)
    from sharp ones (69-435). See
    ChangeRequest/2026-09-28_accuracy-program-no-real-data.md."""
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    if person_box is not None:
        h, w = gray.shape
        x1, y1 = max(0, int(person_box.x1)), max(0, int(person_box.y1))
        x2, y2 = min(w, int(person_box.x2)), min(h, int(person_box.y2))
        if x2 - x1 > 8 and y2 - y1 > 8:
            gray = gray[y1:y2, x1:x2]
    if _laplacian_variance(gray) < config.MIN_BLUR_VARIANCE:
        return ValidationResult(
            usable=False,
            status="IMAGE_TOO_BLURRY",
            message="Image is too blurry to analyze. Please hold the camera steady and retake.",
        )
    return ValidationResult(usable=True, status="ok", message="Image is sharp enough.")


def validate_image(image_path: str, *, check_blur: bool = True) -> ValidationResult:
    """Run every Stage-0 check against the image at `image_path`.

    Returns the first failing check's `ValidationResult`, or a passing
    one once every check clears. Order matters: cheapest/most-fatal
    checks (file size, decodability) run before the pixel-statistics
    ones, which need a successfully decoded image to run at all.
    """
    path = Path(image_path)

    try:
        file_size = path.stat().st_size
    except OSError:
        return ValidationResult(
            usable=False, status="CORRUPTED_IMAGE", message="Could not read the uploaded file."
        )

    if file_size > config.MAX_IMAGE_BYTES:
        return ValidationResult(
            usable=False,
            status="IMAGE_TOO_LARGE",
            message=(
                f"Image is {file_size / (1024 * 1024):.1f}MB, which exceeds the "
                f"{config.MAX_IMAGE_BYTES / (1024 * 1024):.0f}MB limit. Please retake at a lower resolution."
            ),
        )

    image_bgr = cv2.imread(str(path))
    if image_bgr is None:
        return ValidationResult(
            usable=False,
            status="CORRUPTED_IMAGE",
            message="The uploaded file is not a readable image. Please retake the photo.",
        )

    height, width = image_bgr.shape[:2]
    if width < config.MIN_IMAGE_WIDTH_PX or height < config.MIN_IMAGE_HEIGHT_PX:
        return ValidationResult(
            usable=False,
            status="IMAGE_TOO_SMALL",
            message=(
                f"Image is {width}x{height}px, below the minimum "
                f"{config.MIN_IMAGE_WIDTH_PX}x{config.MIN_IMAGE_HEIGHT_PX}px. Please retake closer to full resolution."
            ),
        )

    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    brightness = float(np.mean(gray))
    if brightness < config.MIN_BRIGHTNESS:
        return ValidationResult(
            usable=False,
            status="IMAGE_TOO_DARK",
            message="Image is too dark to analyze. Please retake in better lighting.",
        )
    if brightness > config.MAX_BRIGHTNESS:
        return ValidationResult(
            usable=False,
            status="IMAGE_TOO_BRIGHT",
            message="Image is overexposed. Please retake with less direct light or flash.",
        )

    if check_blur:
        sharpness = check_sharpness(image_bgr)
        if not sharpness.usable:
            return sharpness

    return ValidationResult(usable=True, status="ok", message="Image passed quality checks.")

"""Stage-0 image-quality validation tests — pure OpenCV/NumPy checks
against synthetic images, no model inference or fixtures needed."""

from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np
import pytest

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

import config  # noqa: E402
from api.validation import validate_image  # noqa: E402


def _write(tmp_path: Path, name: str, image: np.ndarray) -> Path:
    path = tmp_path / name
    cv2.imwrite(str(path), image)
    return path


def test_valid_image_passes(tmp_path):
    # Mid-brightness noise, large enough and sharp enough to clear every
    # check — brightness centered near 128, well inside [MIN,MAX].
    rng = np.random.default_rng(0)
    image = rng.integers(90, 165, size=(800, 600, 3), dtype=np.uint8)
    path = _write(tmp_path, "ok.jpg", image)

    result = validate_image(str(path))

    assert result.usable is True
    assert result.status == "ok"


def test_missing_file_reports_corrupted():
    result = validate_image("/nonexistent/path/does_not_exist.jpg")

    assert result.usable is False
    assert result.status == "CORRUPTED_IMAGE"


def test_corrupted_bytes_reported(tmp_path):
    path = tmp_path / "garbage.jpg"
    path.write_bytes(b"not a real image file")

    result = validate_image(str(path))

    assert result.usable is False
    assert result.status == "CORRUPTED_IMAGE"


def test_too_small_image_reported(tmp_path):
    image = np.full((20, 20, 3), 128, dtype=np.uint8)
    path = _write(tmp_path, "tiny.jpg", image)

    result = validate_image(str(path))

    assert result.usable is False
    assert result.status == "IMAGE_TOO_SMALL"


def test_too_dark_image_reported(tmp_path):
    image = np.zeros((800, 600, 3), dtype=np.uint8)
    path = _write(tmp_path, "dark.jpg", image)

    result = validate_image(str(path))

    assert result.usable is False
    assert result.status == "IMAGE_TOO_DARK"


def test_too_bright_image_reported(tmp_path):
    image = np.full((800, 600, 3), 255, dtype=np.uint8)
    path = _write(tmp_path, "bright.jpg", image)

    result = validate_image(str(path))

    assert result.usable is False
    assert result.status == "IMAGE_TOO_BRIGHT"


def test_blurry_image_reported(tmp_path):
    rng = np.random.default_rng(1)
    noise = rng.integers(90, 165, size=(800, 600, 3), dtype=np.uint8)
    blurred = cv2.GaussianBlur(noise, (0, 0), sigmaX=25)
    path = _write(tmp_path, "blurry.jpg", blurred)

    result = validate_image(str(path))

    assert result.usable is False
    assert result.status == "IMAGE_TOO_BLURRY"


def test_oversized_image_reported(tmp_path, monkeypatch):
    monkeypatch.setattr(config, "MAX_IMAGE_BYTES", 100)
    image = np.full((800, 600, 3), 128, dtype=np.uint8)
    path = _write(tmp_path, "big.jpg", image)

    result = validate_image(str(path))

    assert result.usable is False
    assert result.status == "IMAGE_TOO_LARGE"

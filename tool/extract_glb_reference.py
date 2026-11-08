#!/usr/bin/env python3
"""CLI wrapper for the cv-service GLB reference manifest extractor."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "cv-service"))

from utils.extract_glb_manifest import main  # noqa: E402


if __name__ == "__main__":
    main()

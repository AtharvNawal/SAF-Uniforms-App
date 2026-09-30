"""Pins the end-to-end tests to the 9-class `segmentation_v1` model so
their expectations don't change with whichever trained model happens to
be on disk (v2 is measured by evaluation/run_violation_benchmark.py).
Must run before any cv-service module reads config."""

import os

os.environ.setdefault("CV_SERVICE_SEGMENTATION_MODEL", "segmentation_v1")

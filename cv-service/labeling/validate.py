"""Validates a ground-truth label dict against the generated schema.

    from labeling.validate import validate_label
    errors = validate_label(label_dict)   # [] means valid
"""

from __future__ import annotations

import json
from pathlib import Path

from jsonschema import Draft202012Validator

from .schema import SCHEMA_PATH, build_schema


def load_schema() -> dict:
    """Reads the committed schema file (fast path for callers that don't
    need to know whether it's stale) — see `schema_is_up_to_date` for the
    drift check itself."""
    return json.loads(Path(SCHEMA_PATH).read_text())


def schema_is_up_to_date() -> bool:
    """True if the committed schema file matches what `build_schema()`
    would generate right now. False means `SOCKET_NAMES` or `CLASSES`
    changed upstream and nobody re-ran `schema.py` — see the risk section
    of ChangeRequest/2026-08-11_cv-service-real-photo-ground-truth-tooling.md."""
    return load_schema() == build_schema()


def validate_label(data: dict) -> list[str]:
    """Returns every schema-validation error message for `data` (empty
    list = valid). Always validates against the freshly-built schema, not
    the possibly-stale file on disk, so a caller never gets a false
    "valid" against an out-of-date contract."""
    validator = Draft202012Validator(build_schema())
    return sorted(
        f"{'/'.join(str(p) for p in error.path) or '<root>'}: {error.message}"
        for error in validator.iter_errors(data)
    )

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from api.response_schema import canonicalize_entries  # noqa: E402


def _entry(rule_id: str, status: str) -> dict:
    return {
        "rule_id": rule_id,
        "name": rule_id,
        "status": status,
        "required": True,
        "checkable": True,
        "present": status == "CORRECT",
        "position_correct": status == "CORRECT",
        "confidence": 0.9,
        "visibility": "VISIBLE",
    }


def test_duplicate_rule_ids_are_counted_once():
    entries = canonicalize_entries([
        _entry("boots", "MISSING"),
        _entry("boots", "MISSING"),
    ])
    assert len(entries) == 1


def test_conflicting_duplicate_rule_ids_abstain():
    entries = canonicalize_entries([
        _entry("beret", "CORRECT"),
        _entry("beret", "MISSING"),
    ])
    assert len(entries) == 1
    assert entries[0]["status"] == "UNCERTAIN"
    assert entries[0]["present"] is None


def test_confidence_namespaces_are_not_accessory_statuses():
    entry = _entry("beret", "CORRECT")
    assert "person" not in entry
    assert "uniform" not in entry
    assert "confidence" in entry

"""Validated loading for service- and dress-specific doctrine rule files."""

from __future__ import annotations

import json
from functools import lru_cache
from dataclasses import dataclass
from pathlib import Path
from typing import Any


class RuleConfigError(ValueError):
    """Raised when a doctrine configuration is malformed."""


@dataclass(frozen=True)
class RuleConfig:
    metadata: dict[str, Any]
    rules: list[dict[str, Any]]


def _load_rule_config(path_string: str, modified_ns: int) -> RuleConfig:
    path = Path(path_string)
    try:
        payload = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise RuleConfigError(f"Unable to load rule configuration '{path}': {exc}") from exc

    if not isinstance(payload, dict) or not isinstance(payload.get("_meta"), dict):
        raise RuleConfigError(f"'{path}' must contain an object-valued _meta section")
    rules = payload.get("rules")
    if not isinstance(rules, list):
        raise RuleConfigError(f"'{path}' must contain a rules array")

    required_fields = {"object", "category", "doctrine_ref", "required", "expected_anchor"}
    for index, rule in enumerate(rules):
        if not isinstance(rule, dict) or not required_fields <= rule.keys():
            raise RuleConfigError(
                f"'{path}' rule {index} is missing one of {sorted(required_fields)}"
            )
        if not isinstance(rule["doctrine_ref"], str) or not rule["doctrine_ref"].strip():
            raise RuleConfigError(f"'{path}' rule {index} has no doctrine reference")

    return RuleConfig(metadata=payload["_meta"], rules=rules)


def load_rule_config(path: Path) -> RuleConfig:
    """Load a rule file with an mtime-aware process cache."""
    stat = path.stat()
    return _load_rule_config_cached(str(path), stat.st_mtime_ns)


@lru_cache(maxsize=64)
def _load_rule_config_cached(path_string: str, modified_ns: int) -> RuleConfig:
    return _load_rule_config(path_string, modified_ns)


def clear_rule_config_cache() -> None:
    _load_rule_config_cached.cache_clear()

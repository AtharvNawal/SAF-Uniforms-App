"""Offline harness comparing Phase 1 (whole-photo Claude verdict, the
approach `checkUniformCompliance.ts` ships) against Phase 2 (this
service's geometry-guided crop pipeline) on the same photo — built to
give the eventual Phase-2 cutover decision real evidence to act on
instead of a design argument alone. See the "Out of scope" section of
`ChangeRequest/2026-08-05_cv-service-mvp-inspect-endpoint.md`
("A/B the two approaches") and
`ChangeRequest/2026-08-10_phase1-spendcap-phase2-cutover-detector.md`.

Both paths are told to look for the SAME expected-accessory list (every
`army_no3_male.json` rule whose `condition` matches the given profile —
geometry-free, matching how Phase 1's expected list is resolved without
any 3D math in production) so the comparison isolates the one thing that
actually differs: Phase 1 asks Claude to find everything in the whole
photo in one call; Phase 2 measures where each item should be first
(person detection -> pose -> PnP camera solve -> rule projection) and
asks Claude to judge only inside each small, already-located crop.

Runs the real Stage 1-3/6 geometry either way. The judgment step is
swappable: `--live` uses a real Anthropic call (needs
`ANTHROPIC_API_KEY` — the same secret already provisioned in Firebase
Secret Manager for `checkUniformCompliance`); the default fake client
needs zero credentials but makes the comparison itself meaningless
(both sides get the same canned answer) — it only proves the harness's
own wiring is correct. A real A/B verdict requires an operator to run
this with `--live` against real photos, which don't exist in this
project yet (see `docs/ai-uniform-compliance-report.md`).

Usage:
    .venv-tools/bin/python cv-service/evaluation/compare_phase1_phase2.py \\
        --photo cv-service/tests/fixtures/rendered_army_no3_male_front.jpg \\
        --rank-tier specialist --live
"""

from __future__ import annotations

import argparse
import base64
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import cv2

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from calibration.pnp_solve import scale_factor_cm_per_unit, solve_camera_pose  # noqa: E402
from detectors.vision_crop_inspector import inspect_resolved_rules  # noqa: E402
from pose.detect_person import detect_person  # noqa: E402
from pose.estimate_pose import estimate_pose  # noqa: E402
from reporting.report import combine_item_verdicts  # noqa: E402
from rules.rule_engine import _condition_matches, load_rules, resolve_rules  # noqa: E402

PHASE1_MODEL = "claude-sonnet-5"
_PHASE1_TOOL_NAME = "report_compliance"

_PHASE1_TOOL = {
    "name": _PHASE1_TOOL_NAME,
    "description": (
        "Report the uniform compliance verdict for the submitted photo, "
        "one entry per expected accessory."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "overallScore": {"type": "number"},
            "summary": {"type": "string"},
            "items": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "accessoryId": {"type": "string"},
                        "displayName": {"type": "string"},
                        "status": {
                            "type": "string",
                            "enum": ["correct", "missing", "incorrect", "uncertain"],
                        },
                        "note": {"type": "string"},
                    },
                    "required": ["accessoryId", "displayName", "status", "note"],
                },
            },
        },
        "required": ["overallScore", "summary", "items"],
    },
}

# Phase 2's crop verdicts speak a 5-state vocabulary
# (present/missing/misaligned/wrong_type/low_confidence); Phase 1's
# whole-photo call speaks a 4-state one
# (correct/missing/incorrect/uncertain). This mapping puts both on the
# same axis for comparison — it is not a claim the vocabularies are
# equivalent (misaligned and wrong_type both collapse to "incorrect",
# since Phase 1 has no separate concept for "right item, wrong spot").
PHASE2_TO_PHASE1_VOCAB = {
    "present": "correct",
    "missing": "missing",
    "misaligned": "incorrect",
    "wrong_type": "incorrect",
    "low_confidence": "uncertain",
}


@dataclass(frozen=True)
class ExpectedItem:
    accessory_id: str
    display_name: str
    category: str


def expected_items_for_profile(profile: dict) -> list[ExpectedItem]:
    """Reuses `rule_engine`'s own condition evaluator rather than
    duplicating it — this is the same doctrine rule set + filtering
    Phase 2 resolves against, just without the geometry step, so both
    approaches are handed an identical expected-item list."""
    rules = load_rules()
    return [
        ExpectedItem(
            accessory_id=r["object"],
            display_name=r.get("rule_text") or r["object"],
            category=r.get("category", ""),
        )
        for r in rules
        if _condition_matches(r.get("condition"), profile)
    ]


def _phase1_prompt(expected: list[ExpectedItem]) -> str:
    lines = [
        f'- id="{e.accessory_id}" name="{e.display_name}" category="{e.category}"'
        for e in expected
    ]
    return (
        "You are inspecting a photo of a Singapore Armed Forces (SAF) soldier "
        "for uniform compliance. Decide, for EVERY expected accessory listed "
        'below, whether it is clearly present and correctly worn ("correct"), '
        'clearly absent ("missing"), present but wrong in some way '
        '("incorrect"), or impossible to judge from this photo '
        '("uncertain").\n\nExpected accessories:\n' + "\n".join(lines) +
        f"\n\nCall the {_PHASE1_TOOL_NAME} tool with your verdict."
    )


def run_phase1(image_bgr, expected: list[ExpectedItem], *, client) -> dict[str, str]:
    """One whole-photo Anthropic call, same tool-forced pattern as
    `checkUniformCompliance.ts` — regardless of how many accessories are
    expected, this is exactly one API call."""
    ok, buf = cv2.imencode(".jpg", image_bgr, [cv2.IMWRITE_JPEG_QUALITY, 92])
    if not ok:
        raise ValueError("failed to encode photo as JPEG")
    image_b64 = base64.b64encode(buf.tobytes()).decode("ascii")

    message = client.messages.create(
        model=PHASE1_MODEL,
        max_tokens=2048,
        tools=[_PHASE1_TOOL],
        tool_choice={"type": "tool", "name": _PHASE1_TOOL_NAME},
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": _phase1_prompt(expected)},
                    {
                        "type": "image",
                        "source": {"type": "base64", "media_type": "image/jpeg", "data": image_b64},
                    },
                ],
            }
        ],
    )
    tool_use = next((b for b in message.content if b.type == "tool_use"), None)
    if tool_use is None:
        return {}
    return {item["accessoryId"]: item["status"] for item in tool_use.input.get("items", [])}


@dataclass(frozen=True)
class ComparisonRow:
    accessory_id: str
    phase1_status: str | None
    phase2_status: str | None
    agree: bool


@dataclass(frozen=True)
class ComparisonReport:
    rows: list[ComparisonRow]
    phase1_call_count: int
    phase2_call_count: int

    @property
    def agreement_rate(self) -> float | None:
        judged = [r for r in self.rows if r.phase1_status and r.phase2_status]
        if not judged:
            return None
        return sum(r.agree for r in judged) / len(judged)


def compare(image_path: str, profile: dict, *, phase1_client, phase2_client) -> ComparisonReport:
    expected = expected_items_for_profile(profile)

    detection = detect_person(image_path)
    if not detection.accepted:
        raise RuntimeError(f"phase2: person detection failed: {detection.reason}")
    pose = estimate_pose(image_path)
    if not pose.found:
        raise RuntimeError("phase2: pose not found")
    camera = solve_camera_pose(pose)
    if not camera.solved or not camera.reliable:
        raise RuntimeError(
            f"phase2: camera pose unreliable (reprojection error "
            f"{camera.reprojection_error_px:.0f}px) — retake the photo"
        )
    cm_per_px = scale_factor_cm_per_unit(pose)
    resolved = resolve_rules(camera, cm_per_px, profile=profile, pose=pose)

    image_bgr = cv2.imread(image_path)
    phase2_verdicts = inspect_resolved_rules(image_bgr, resolved, client=phase2_client)
    phase2_items = {
        item.object_id: item.verdict for item in combine_item_verdicts(resolved, phase2_verdicts)
    }

    phase1_items = run_phase1(image_bgr, expected, client=phase1_client)

    all_ids = {e.accessory_id for e in expected} | set(phase1_items) | set(phase2_items)
    rows = []
    for accessory_id in sorted(all_ids):
        p1 = phase1_items.get(accessory_id)
        p2_raw = phase2_items.get(accessory_id)
        p2 = PHASE2_TO_PHASE1_VOCAB.get(p2_raw) if p2_raw else None
        rows.append(ComparisonRow(accessory_id, p1, p2, agree=(p1 is not None and p1 == p2)))

    return ComparisonReport(
        rows=rows,
        phase1_call_count=1,
        phase2_call_count=sum(len(r.crops) for r in resolved),
    )


def print_report(report: ComparisonReport) -> None:
    print(f"{'accessory':35s} {'phase1':10s} {'phase2':10s} agree")
    print("-" * 65)
    for row in report.rows:
        print(
            f"{row.accessory_id:35s} {row.phase1_status or '-':10s} "
            f"{row.phase2_status or '-':10s} {'yes' if row.agree else 'no'}"
        )
    print("-" * 65)
    print(
        f"Anthropic calls -> phase1: {report.phase1_call_count}   "
        f"phase2: {report.phase2_call_count}"
    )
    rate = report.agreement_rate
    print(f"Agreement rate: {rate:.0%}" if rate is not None else "Agreement rate: n/a")


class _FakeToolUseBlock:
    type = "tool_use"

    def __init__(self, input_: dict):
        self.input = input_


class _FakeMessage:
    def __init__(self, content):
        self.content = content


class FakeComparisonClient:
    """Deterministic fake shared by both phases in fake mode — always
    reports the item present/correct. Makes the harness runnable with
    zero credentials so its own wiring can be exercised, but the
    resulting "comparison" is meaningless (see module docstring) — pass
    `--live` for a real result."""

    def __init__(self):
        self.messages = self

    def create(self, **kwargs):
        if kwargs["tool_choice"]["name"] != _PHASE1_TOOL_NAME:
            return _FakeMessage(
                [_FakeToolUseBlock({"verdict": "present", "confidence": 0.9, "note": "fake mode"})]
            )
        prompt_text = kwargs["messages"][0]["content"][0]["text"]
        ids = re.findall(r'id="([^"]+)"', prompt_text)
        names = re.findall(r'name="([^"]+)"', prompt_text)
        items = [
            {"accessoryId": i, "displayName": n, "status": "correct", "note": "fake mode"}
            for i, n in zip(ids, names)
        ]
        return _FakeMessage(
            [_FakeToolUseBlock({"overallScore": 100, "summary": "fake mode", "items": items})]
        )


def _live_client():
    import anthropic

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY not set — omit --live for the fake client, or "
            "set the key for a real comparison."
        )
    return anthropic.Anthropic(api_key=api_key)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--photo", required=True)
    parser.add_argument("--rank-tier", default="specialist")
    parser.add_argument("--gender", default="male")
    parser.add_argument("--is-sikh", action="store_true")
    parser.add_argument("--medal-row-count", type=int, default=0)
    parser.add_argument("--live", action="store_true", help="use a real Anthropic call instead of the fake client")
    args = parser.parse_args()

    profile = {
        "rank_tier": args.rank_tier,
        "gender": args.gender,
        "isSikh": args.is_sikh,
        "medalRowCount": args.medal_row_count,
    }

    if args.live:
        client = _live_client()
    else:
        client = FakeComparisonClient()
        print(
            "*** FAKE MODE: no ANTHROPIC_API_KEY used — results are not a real\n"
            "*** comparison, only the harness's own wiring is exercised.\n"
            "*** Pass --live with ANTHROPIC_API_KEY set for a real A/B result.\n"
        )

    report = compare(args.photo, profile, phase1_client=client, phase2_client=client)
    print_report(report)


if __name__ == "__main__":
    main()

"""Phase 1 real-photo sanity check — the cheapest possible test of
whether the geometric approach (person detection → pose → PnP camera
solve → rule projection → segmentation) is sound at all before investing
in labeling, training, or anything else.

No labeling, no new model, no new training — just: point this at a
folder of real photos and see whether each stage holds up or degrades.
This is deliberately lighter than
`evaluation/evaluate_verdict_precision_recall.py` (needs Milestone
A-format ground-truth labels to score precision/recall); this tool
needs nothing but raw photos, because the question it answers is
narrower: "does detection/pose/camera-solve fall apart on real
fabric/lighting/skin, or does it hold up reasonably" — not "is it
accurate."

**Does not supply photos.** As of this writing, 0 real photos exist in
this repo — see `ChangeRequest/2026-08-11_real-photo-phase1-sanity-check-tooling.md`.

Usage:
    # Drop 15-20 real photos under cv-service/data/real_photos/<subject_id>/
    # following the existing naming convention, then:
    .venv-tools/bin/python cv-service/evaluation/run_real_photo_sanity_check.py

    # Mechanical smoke test only (NOT a real-world finding):
    .venv-tools/bin/python cv-service/evaluation/run_real_photo_sanity_check.py --include-standins
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path

import cv2

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from geometry.project_rules import cm_per_px_from_anchor_pose  # noqa: E402
from geometry.solve_camera_pose import solve_camera_pose  # noqa: E402
from pose.anchor_mapping import _ALL_ANCHOR_NAMES, estimate_anchor_pose  # noqa: E402
from pose.detect_person import detect_person  # noqa: E402
from rules.rule_engine import resolve_rules  # noqa: E402
from segmentation.segment_uniform import segment_uniform  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PHOTOS_DIR = REPO_ROOT / "cv-service" / "data" / "real_photos"
_IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png"}
_KNOWN_SYNTHETIC_SUBJECT_PREFIXES = ("standin",)

DEFAULT_PROFILE = {"rank_tier": "sltc_me6_and_below", "gender": "male", "isSikh": False, "medalRowCount": 0}


@dataclass
class PhotoDiagnostic:
    photo_id: str
    error: str | None = None
    person_detected: bool = False
    person_detect_reason: str = ""
    person_confidence: float | None = None
    pose_anchor_coverage: float = 0.0  # fraction of 16 anchors with confidence > 0
    pose_mean_confidence: float = 0.0  # mean confidence among covered anchors
    camera_solved: bool = False
    camera_reliable: bool = False
    reprojection_error_px: float | None = None
    correspondence_count: int = 0
    resolved_rule_count: int = 0
    segmentation_region_count: int = 0
    segmentation_classes: list[str] = field(default_factory=list)
    segmentation_mean_confidence: float = 0.0


def _is_synthetic_subject(photo_path: Path, photos_dir: Path) -> bool:
    try:
        subject_dir_name = photo_path.relative_to(photos_dir).parts[0]
    except ValueError:
        subject_dir_name = photo_path.parent.name
    return subject_dir_name.startswith(_KNOWN_SYNTHETIC_SUBJECT_PREFIXES)


def find_photos(photos_dir: Path, *, include_standins: bool) -> list[Path]:
    if not photos_dir.exists():
        return []
    photos = [p for p in sorted(photos_dir.rglob("*")) if p.suffix.lower() in _IMAGE_SUFFIXES]
    if include_standins:
        return photos
    return [p for p in photos if not _is_synthetic_subject(p, photos_dir)]


def diagnose_photo(photo_path: Path, profile: dict) -> PhotoDiagnostic:
    diag = PhotoDiagnostic(photo_id=photo_path.stem)
    try:
        detection = detect_person(str(photo_path))
        diag.person_detected = detection.accepted
        diag.person_detect_reason = detection.reason
        diag.person_confidence = detection.person.confidence if detection.person else None
        if not detection.accepted:
            return diag

        anchor_pose = estimate_anchor_pose(str(photo_path))
        covered = [a for a in anchor_pose.values() if a["confidence"] > 0.0]
        diag.pose_anchor_coverage = len(covered) / len(_ALL_ANCHOR_NAMES)
        diag.pose_mean_confidence = (
            sum(a["confidence"] for a in covered) / len(covered) if covered else 0.0
        )

        image = cv2.imread(str(photo_path))
        height, width = image.shape[:2]
        camera = solve_camera_pose(anchor_pose, image_width=width, image_height=height)
        diag.camera_solved = camera.solved
        diag.camera_reliable = camera.reliable
        diag.reprojection_error_px = camera.reprojection_error_px
        diag.correspondence_count = camera.correspondence_count

        if camera.solved:
            cm_per_px = cm_per_px_from_anchor_pose(anchor_pose) or 0.1
            resolved = resolve_rules(camera, cm_per_px, profile=profile)
            diag.resolved_rule_count = len(resolved)

        segmentation = segment_uniform(str(photo_path))
        diag.segmentation_region_count = len(segmentation.regions)
        diag.segmentation_classes = sorted({r.class_name for r in segmentation.regions})
        if segmentation.regions:
            diag.segmentation_mean_confidence = sum(
                r.confidence for r in segmentation.regions
            ) / len(segmentation.regions)
    except Exception as e:  # noqa: BLE001 — one bad photo must never abort the batch
        diag.error = f"{type(e).__name__}: {e}"
    return diag


def _rate(values: list[bool]) -> float:
    return sum(values) / len(values) if values else 0.0


def _distribution(values: list[float]) -> dict:
    if not values:
        return {"mean": None, "median": None, "min": None, "max": None}
    sorted_values = sorted(values)
    mid = len(sorted_values) // 2
    median = sorted_values[mid] if len(sorted_values) % 2 else (sorted_values[mid - 1] + sorted_values[mid]) / 2
    return {
        "mean": round(sum(values) / len(values), 2),
        "median": round(median, 2),
        "min": round(min(values), 2),
        "max": round(max(values), 2),
    }


def summarize(diagnostics: list[PhotoDiagnostic]) -> dict:
    errored = [d for d in diagnostics if d.error is not None]
    ok = [d for d in diagnostics if d.error is None]
    return {
        "photo_count": len(diagnostics),
        "crashed_count": len(errored),
        "person_detected_rate": _rate([d.person_detected for d in ok]),
        "pose_anchor_coverage": _distribution([d.pose_anchor_coverage for d in ok if d.person_detected]),
        "camera_solved_rate": _rate([d.camera_solved for d in ok if d.person_detected]),
        "camera_reliable_rate": _rate([d.camera_reliable for d in ok if d.camera_solved]),
        "reprojection_error_px": _distribution(
            [d.reprojection_error_px for d in ok if d.reprojection_error_px is not None]
        ),
        "segmentation_region_count": _distribution([float(d.segmentation_region_count) for d in ok]),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--photos-dir", type=str, default=str(DEFAULT_PHOTOS_DIR))
    parser.add_argument("--include-standins", action="store_true",
                         help="Include the known synthetic stand-ins — smoke-test only, NOT a real-world finding.")
    parser.add_argument("--json-out", type=str, default=None)
    parser.add_argument("--rank-tier", type=str, default=DEFAULT_PROFILE["rank_tier"])
    parser.add_argument("--gender", type=str, default=DEFAULT_PROFILE["gender"])
    args = parser.parse_args()

    profile = dict(DEFAULT_PROFILE, rank_tier=args.rank_tier, gender=args.gender)
    photos_dir = Path(args.photos_dir)
    photos = find_photos(photos_dir, include_standins=args.include_standins)

    if not photos:
        print(f"0 usable photos found under {photos_dir}.")
        print("Drop real photos under <photos_dir>/<subject_id>/<subject_id>__<angle>__<lighting>.jpg")
        print("(the existing Milestone A naming convention) and re-run.")
        return

    if args.include_standins:
        print("*** --include-standins: this run includes SYNTHETIC stand-ins. ***")
        print("*** Results below are a mechanical smoke test, NOT a real-world finding. ***\n")

    diagnostics = [diagnose_photo(p, profile) for p in photos]

    for d in diagnostics:
        if d.error:
            print(f"{d.photo_id}: CRASHED — {d.error}")
            continue
        print(
            f"{d.photo_id}: person={d.person_detected} "
            f"pose_coverage={d.pose_anchor_coverage:.0%} "
            f"camera_solved={d.camera_solved} reliable={d.camera_reliable} "
            f"reproj={d.reprojection_error_px} "
            f"rules_resolved={d.resolved_rule_count} "
            f"segments={d.segmentation_region_count} {d.segmentation_classes}"
        )

    summary = summarize(diagnostics)
    print(f"\n=== Summary across {summary['photo_count']} photos "
          f"({summary['crashed_count']} crashed) ===")
    print(f"Person detected:       {summary['person_detected_rate']:.0%}")
    print(f"Camera solved:         {summary['camera_solved_rate']:.0%}")
    print(f"Camera reliable:       {summary['camera_reliable_rate']:.0%} (of solved)")
    print(f"Pose anchor coverage:  {summary['pose_anchor_coverage']}")
    print(f"Reprojection error px: {summary['reprojection_error_px']}")
    print(f"Segmentation regions:  {summary['segmentation_region_count']}")

    if args.json_out:
        Path(args.json_out).write_text(
            json.dumps({"summary": summary, "photos": [asdict(d) for d in diagnostics]}, indent=2)
        )
        print(f"\nWrote {args.json_out}")


if __name__ == "__main__":
    main()

"""Tests for the Phase 1 real-photo sanity-check runner
(`ChangeRequest/2026-08-11_real-photo-phase1-sanity-check-tooling.md`).

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from evaluation.run_real_photo_sanity_check import (  # noqa: E402
    PhotoDiagnostic,
    _is_synthetic_subject,
    diagnose_photo,
    find_photos,
    summarize,
)

FIXTURE_PHOTO = REPO_ROOT / "cv-service" / "tests" / "fixtures" / "rendered_army_no3_male_front.jpg"
REAL_PHOTOS_DIR = REPO_ROOT / "cv-service" / "data" / "real_photos"


def test_is_synthetic_subject_matches_known_standin_prefix():
    photos_dir = Path("/x/real_photos")
    assert _is_synthetic_subject(Path("/x/real_photos/standin01/a.jpg"), photos_dir)
    assert not _is_synthetic_subject(Path("/x/real_photos/subj01/a.jpg"), photos_dir)


def test_find_photos_excludes_standins_by_default(tmp_path):
    (tmp_path / "standin01").mkdir()
    (tmp_path / "standin01" / "a.jpg").write_bytes(b"x")
    (tmp_path / "subj01").mkdir()
    (tmp_path / "subj01" / "b.jpg").write_bytes(b"x")

    default_result = find_photos(tmp_path, include_standins=False)
    assert [p.name for p in default_result] == ["b.jpg"]

    included_result = find_photos(tmp_path, include_standins=True)
    assert {p.name for p in included_result} == {"a.jpg", "b.jpg"}


def test_find_photos_ignores_non_image_files(tmp_path):
    (tmp_path / "subj01").mkdir()
    (tmp_path / "subj01" / "notes.txt").write_bytes(b"x")
    (tmp_path / "subj01" / "photo.png").write_bytes(b"x")
    result = find_photos(tmp_path, include_standins=False)
    assert [p.name for p in result] == ["photo.png"]


def test_find_photos_returns_empty_for_missing_directory(tmp_path):
    assert find_photos(tmp_path / "does_not_exist", include_standins=False) == []


def test_summarize_excludes_crashed_photos_from_rates():
    diagnostics = [
        PhotoDiagnostic(photo_id="a", error="boom"),
        PhotoDiagnostic(photo_id="b", person_detected=True, camera_solved=True, camera_reliable=True),
        PhotoDiagnostic(photo_id="c", person_detected=False),
    ]
    summary = summarize(diagnostics)
    assert summary["photo_count"] == 3
    assert summary["crashed_count"] == 1
    # rate computed over the 2 non-crashed photos, not all 3
    assert summary["person_detected_rate"] == pytest.approx(0.5)


def test_summarize_camera_reliable_rate_is_conditioned_on_solved():
    diagnostics = [
        PhotoDiagnostic(photo_id="a", person_detected=True, camera_solved=True, camera_reliable=True),
        PhotoDiagnostic(photo_id="b", person_detected=True, camera_solved=False, camera_reliable=False),
    ]
    summary = summarize(diagnostics)
    # only 1 of 2 photos solved; reliable rate is over solved photos only (100%), not diluted to 50%
    assert summary["camera_solved_rate"] == pytest.approx(0.5)
    assert summary["camera_reliable_rate"] == pytest.approx(1.0)


def test_diagnose_photo_never_raises_on_a_nonsense_image(tmp_path):
    """A file that isn't a valid image at all — the runner's whole
    point is that one bad photo can't abort the batch."""
    bad_photo = tmp_path / "not_a_real_image.jpg"
    bad_photo.write_bytes(b"this is not jpeg data")
    diag = diagnose_photo(bad_photo, profile={"rank_tier": "specialist", "gender": "male", "isSikh": False, "medalRowCount": 0})
    assert diag.photo_id == "not_a_real_image"
    # Either detect_person gracefully reports no person, or an exception
    # was caught — either way, no exception propagates out.
    assert diag.error is not None or diag.person_detected is False


def test_diagnose_photo_runs_end_to_end_against_rendered_fixture():
    if not FIXTURE_PHOTO.exists():
        pytest.skip(f"fixture photo not found at {FIXTURE_PHOTO}")
    diag = diagnose_photo(
        FIXTURE_PHOTO,
        profile={"rank_tier": "specialist", "gender": "male", "isSikh": False, "medalRowCount": 0},
    )
    assert diag.error is None
    assert diag.person_detected is True
    assert diag.camera_solved is True
    assert 0.0 <= diag.pose_anchor_coverage <= 1.0


def test_no3_acc_reference_images_correctly_report_no_person():
    """Sanity-locks a real finding from this session: the images under
    cv-service/data/real_photos/no3_acc/ are individual accessory
    reference pictures, not photos of a person, and must not be
    silently miscounted as usable real-photo data."""
    no3_acc_dir = REAL_PHOTOS_DIR / "no3_acc"
    if not no3_acc_dir.exists():
        pytest.skip("no3_acc/ not present locally")
    photos = find_photos(no3_acc_dir, include_standins=True)
    if not photos:
        pytest.skip("no3_acc/ is empty")
    diag = diagnose_photo(
        photos[0],
        profile={"rank_tier": "specialist", "gender": "male", "isSikh": False, "medalRowCount": 0},
    )
    assert diag.person_detected is False

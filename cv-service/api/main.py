"""FastAPI entry point — `POST /inspect` and `POST /check_uniform`.

Wires stages 1 through 7 together. This is a standalone local service
for this milestone (see the plan file's scope) — `checkUniformCompliance.ts`
does not call it yet; that wiring is Milestone 6/7, deliberately deferred
because it changes production behavior and deserves its own plan + device
test per CLAUDE.md policy 1.5.

`POST /check_uniform` (added
`ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md`) is a
second, additive endpoint — same underlying geometry + segmentation
pipeline as `/inspect`'s `geometric_verdicts` field, but as the *primary*
path (hard error responses instead of a best-effort secondary pass) and
reshaped into a stable `{success, overall_status, overall_score,
image_quality, person, accessories[], summary}` contract. It has **no
Anthropic dependency** — pure geometry + the trained segmentation model —
unlike `/inspect`'s vision-crop-dependent original path.

Run locally:

    .venv-tools/bin/uvicorn cv-service.api.main:app --reload --port 8001

Requires `ANTHROPIC_API_KEY` in the environment for the vision-crop
inspector (Stage 4/5 substitute) — same secret already provisioned in
Firebase Secret Manager for `checkUniformCompliance`. Stages 1-3 and 6
run with zero external credentials.
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import cv2
import numpy as np
from fastapi import Depends, FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import config  # noqa: E402
from api.auth import AuthError, auth_error_handler, require_user  # noqa: E402
from api.burst import aggregate_burst  # noqa: E402
from api.pipeline import SUPPORTED_UNIFORM_TYPES, CheckError, CheckParams, run_check  # noqa: E402
from calibration.pnp_solve import scale_factor_cm_per_unit, solve_camera_pose  # noqa: E402
from detectors.vision_crop_inspector import inspect_resolved_rules  # noqa: E402
from geometry.project_rules import cm_per_px_from_anchor_pose  # noqa: E402
from geometry.solve_camera_pose import solve_camera_pose as solve_camera_pose_v2  # noqa: E402
from pose.anchor_mapping import estimate_anchor_pose  # noqa: E402
from pose.detect_person import detect_person  # noqa: E402
from pose.estimate_pose import estimate_pose  # noqa: E402
from reporting.report import (  # noqa: E402
    build_report,
    combine_item_verdicts,
    render_annotated_image_b64,
)
from rules.rule_engine import evaluate_verdicts, resolve_rules  # noqa: E402
from segmentation.segment_uniform import segment_uniform  # noqa: E402

# Only doctrine this service has today — see rules/army_no3_male.json.
# Any other uniform_type is a hard 422, not a silent fallback.

app = FastAPI(
    title="SAF Uniform Compliance — cv-service (MVP)",
    description=(
        "Real geometry (human detection, pose, PnP camera-pose recovery, "
        "rule-engine crop resolution) + a vision-language substitute for "
        "the not-yet-trained accessory detector. See cv-service/README.md."
    ),
)
app.add_exception_handler(AuthError, auth_error_handler)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/inspect", dependencies=[Depends(require_user)])
async def inspect(
    photo: UploadFile = File(...),
    rank_tier: str = Form(...),
    gender: str = Form("male"),
    is_sikh: bool = Form(False),
    medal_row_count: int = Form(0),
    include_annotated_image: bool = Form(True),
):
    """Run the full pipeline against one uploaded photo.

    `rank_tier` — one of the values used in `rules/army_no3_male.json`
    conditions: `specialist`, `enlistee`, `sltc_me6_and_below`,
    `col_me7`, `bg_me8_and_above`, `officer_cadet_and_mxt_trainee`, or
    `officer` / `warrant_officer` / `military_expert` for the collar
    rank-pin tiers not yet broken out into their own rule.
    """
    suffix = Path(photo.filename or "photo.jpg").suffix or ".jpg"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await photo.read())
        tmp_path = tmp.name

    try:
        # TRIAL ONLY — person-detection gate disabled for /inspect so this
        # endpoint can be exercised with photos that don't clearly pass
        # detect_person (e.g. no person, low confidence, multiple people).
        # Re-enable before any real use: without this gate, pose estimation
        # runs against whatever is in the frame and downstream verdicts are
        # not meaningful. See ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md.
        detection = detect_person(tmp_path)
        # if not detection.accepted:
        #     return JSONResponse(
        #         status_code=422,
        #         content={"error": detection.reason, "candidate_count": detection.candidate_count},
        #     )

        pose = estimate_pose(tmp_path)
        if not pose.found:
            return JSONResponse(status_code=422, content={"error": "pose_not_found"})

        camera = solve_camera_pose(pose)
        if not camera.solved:
            return JSONResponse(status_code=422, content={"error": camera.reason})
        if not camera.reliable:
            return JSONResponse(
                status_code=422,
                content={
                    "error": "camera_pose_unreliable",
                    "reprojection_error_px": camera.reprojection_error_px,
                    "hint": "retake the photo per the capture protocol: front-facing, arms relaxed at sides, full torso visible",
                },
            )

        cm_per_px = scale_factor_cm_per_unit(pose)
        profile = {
            "rank_tier": rank_tier,
            "gender": gender,
            "isSikh": is_sikh,
            "medalRowCount": medal_row_count,
        }
        resolved = resolve_rules(camera, cm_per_px, profile=profile, pose=pose)
        if not resolved:
            raise HTTPException(status_code=500, detail="no rules resolved for this profile")

        image_bgr = cv2.imread(tmp_path)
        try:
            verdicts = inspect_resolved_rules(image_bgr, resolved)
        except RuntimeError as e:
            raise HTTPException(status_code=503, detail=str(e)) from e

        report = build_report(resolved, verdicts)
        report["camera_diagnostics"] = {
            "reprojection_error_px": camera.reprojection_error_px,
            "correspondence_count": camera.correspondence_count,
            "cm_per_px": cm_per_px,
        }

        if include_annotated_image:
            items = combine_item_verdicts(resolved, verdicts)
            report["annotated_image_base64"] = render_annotated_image_b64(image_bgr, items)

        # Stage 4 — real trained model, but synthetic-data-only (zero
        # real photos) — see segmentation/segment_uniform.py's module
        # docstring. Optional and best-effort: a missing/untrained
        # model must never break the rest of the report, which is why
        # this degrades to `null` rather than raising.
        seg_result = None
        try:
            seg_result = segment_uniform(tmp_path)
            report["segmentation"] = {
                "model": "yolov8n-seg (trained on synthetic renders only — see cv-service/segmentation/segment_uniform.py)",
                "coverage_fraction": {
                    class_name: round(seg_result.coverage_fraction(class_name), 4)
                    for class_name in {r.class_name for r in seg_result.regions}
                },
                "region_count": len(seg_result.regions),
            }
        except FileNotFoundError:
            report["segmentation"] = None

        # Geometric verdict engine (this session's newest work,
        # `rules/rule_engine.py`'s `evaluate_verdicts`) — a SECOND,
        # independent geometry pass using the fuller pose estimate
        # (pose/anchor_mapping) + richer PnP correspondence set
        # (geometry/solve_camera_pose), deliberately not reusing
        # `pose`/`camera`/`resolved` above (the older, narrower 7-anchor
        # path) — see the plan file's Decision 3 for why. Always present
        # on the response as a (possibly empty) list, never omitted, so
        # callers don't need to branch on whether the field exists; a
        # broad except is intentional here (unlike the narrower
        # `FileNotFoundError` above) because this path has several
        # independent new-code failure points (pose estimation, a second
        # camera solve, rule resolution) and none of them may ever break
        # the rest of an otherwise-successful report.
        geometric_verdicts: list[dict] = []
        if seg_result is not None:
            try:
                anchor_pose = estimate_anchor_pose(tmp_path)
                camera_v2 = solve_camera_pose_v2(anchor_pose, image_bgr.shape[1], image_bgr.shape[0])
                cm_per_px_v2 = cm_per_px_from_anchor_pose(anchor_pose) or cm_per_px
                resolved_v2 = resolve_rules(camera_v2, cm_per_px_v2, profile=profile)
                geometric_verdicts = [
                    {
                        "accessory": v.accessory,
                        "status": v.status,
                        "reason": v.reason,
                        "doctrine_ref": v.doctrine_ref,
                    }
                    for v in evaluate_verdicts(
                        resolved_v2,
                        seg_result,
                        cm_per_px_v2,
                        image_bgr.shape[1],
                        image_bgr.shape[0],
                        camera_reliable=camera_v2.reliable,
                    )
                ]
            except Exception:  # noqa: BLE001 - best-effort second pass, must never break the primary report
                geometric_verdicts = []
        report["geometric_verdicts"] = geometric_verdicts

        return report
    finally:
        Path(tmp_path).unlink(missing_ok=True)


def _error(status_code: int, status: str, message: str, **extra) -> JSONResponse:
    return JSONResponse(status_code=status_code, content={"success": False, "status": status, "message": message, **extra})


def _gravity(gravity_x: float | None, gravity_y: float | None, gravity_z: float | None) -> tuple[float, float, float] | None:
    """World-up in OpenCV camera coordinates (x right, y down, z forward),
    as the app computes it from the accelerometer — all three or none."""
    if gravity_x is None or gravity_y is None or gravity_z is None:
        return None
    return (float(gravity_x), float(gravity_y), float(gravity_z))


def _params(**kwargs) -> CheckParams:
    gravity = _gravity(kwargs.pop("gravity_x"), kwargs.pop("gravity_y"), kwargs.pop("gravity_z"))
    return CheckParams(**kwargs, gravity_up_cam=gravity)


async def _save_upload(image: UploadFile) -> str:
    suffix = Path(image.filename or "photo.jpg").suffix or ".jpg"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await image.read())
        return tmp.name


@app.post("/check_uniform", dependencies=[Depends(require_user)])
async def check_uniform(
    image: UploadFile = File(...),
    uniform_type: str = Form(...),
    rank_tier: str = Form(...),
    gender: str = Form("male"),
    is_sikh: bool = Form(False),
    medal_row_count: int = Form(0),
    view: str = Form("front"),
    body_type: str = Form("male"),
    include_debug_image: bool = Form(False),
    wearer_name: str | None = Form(None),
    height_cm: float | None = Form(None),
    focal_length_px: float | None = Form(None),
    gravity_x: float | None = Form(None),
    gravity_y: float | None = Form(None),
    gravity_z: float | None = Form(None),
):
    """Full compliance check against the `POST /check_uniform` contract —
    see `api/pipeline.py` for every stage.

    `uniform_type` must be one of `SUPPORTED_UNIFORM_TYPES` (today, only
    `"army_no3_male"`). The doctrine rules need `rank_tier`/`gender`/
    `is_sikh`/`medal_row_count` to resolve which items apply to this
    wearer. Optional, each improving accuracy (ChangeRequest/
    2026-09-28_accuracy-program-no-real-data.md): `wearer_name` (full name, for name-tag OCR
    match), `height_cm` (scales the reference body), `focal_length_px`
    (else read from EXIF), `gravity_x/y/z` (phone accelerometer
    world-up in camera coordinates — constrains camera tilt).

    Every failure is a hard, typed error, and the whole pipeline runs with
    **no Anthropic dependency**.
    """
    params = _params(
        uniform_type=uniform_type, rank_tier=rank_tier, gender=gender, is_sikh=is_sikh,
        medal_row_count=medal_row_count, view=view, body_type=body_type,
        include_debug_image=include_debug_image, wearer_name=wearer_name, height_cm=height_cm,
        focal_length_px=focal_length_px, gravity_x=gravity_x, gravity_y=gravity_y, gravity_z=gravity_z,
    )
    tmp_path = await _save_upload(image)
    try:
        return run_check(tmp_path, params)
    except CheckError as err:
        return _error(err.status_code, err.status, err.message, **err.extra)
    finally:
        Path(tmp_path).unlink(missing_ok=True)


@app.post("/check_uniform_burst", dependencies=[Depends(require_user)])
async def check_uniform_burst(
    images: list[UploadFile] = File(...),
    uniform_type: str = Form(...),
    rank_tier: str = Form(...),
    gender: str = Form("male"),
    is_sikh: bool = Form(False),
    medal_row_count: int = Form(0),
    view: str = Form("front"),
    body_type: str = Form("male"),
    include_debug_image: bool = Form(False),
    wearer_name: str | None = Form(None),
    height_cm: float | None = Form(None),
    focal_length_px: float | None = Form(None),
    gravity_x: float | None = Form(None),
    gravity_y: float | None = Form(None),
    gravity_z: float | None = Form(None),
):
    """D17 — the same check over 2-`BURST_MAX_FRAMES` frames of one pose,
    combined by per-item strict majority (`api/burst.py`). Frames the
    pipeline rejects are skipped and reported under `burst.frame_errors`;
    if every frame is rejected, the first frame's error is returned."""
    if not 1 <= len(images) <= config.BURST_MAX_FRAMES:
        return _error(422, "BAD_BURST", f"Send between 1 and {config.BURST_MAX_FRAMES} images.")
    if params_error := (None if uniform_type in SUPPORTED_UNIFORM_TYPES else uniform_type):
        return _error(422, "UNSUPPORTED_UNIFORM",
                      f"'{params_error}' is not a supported uniform_type. Supported: {sorted(SUPPORTED_UNIFORM_TYPES)}.")
    params = _params(
        uniform_type=uniform_type, rank_tier=rank_tier, gender=gender, is_sikh=is_sikh,
        medal_row_count=medal_row_count, view=view, body_type=body_type,
        include_debug_image=include_debug_image, wearer_name=wearer_name, height_cm=height_cm,
        focal_length_px=focal_length_px, gravity_x=gravity_x, gravity_y=gravity_y, gravity_z=gravity_z,
    )
    results: list[dict | None] = []
    errors: list[dict | None] = []
    first_error: CheckError | None = None
    for index, image in enumerate(images):
        tmp_path = await _save_upload(image)
        try:
            results.append(run_check(tmp_path, params))
            errors.append(None)
        except CheckError as err:
            first_error = first_error or err
            results.append(None)
            errors.append({"frame": index, "status": err.status, "message": err.message})
        finally:
            Path(tmp_path).unlink(missing_ok=True)
    if all(r is None for r in results):
        return _error(first_error.status_code, first_error.status, first_error.message, **first_error.extra)
    return aggregate_burst(results, errors)

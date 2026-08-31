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
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from api.response_schema import build_check_uniform_response  # noqa: E402
from api.validation import validate_image  # noqa: E402
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
    render_debug_image_b64,
)
from rules.rule_engine import evaluate_verdicts, resolve_rules  # noqa: E402
from segmentation.segment_uniform import segment_uniform  # noqa: E402

# Only doctrine this service has today — see rules/army_no3_male.json.
# Any other uniform_type is a hard 422, not a silent fallback.
SUPPORTED_UNIFORM_TYPES = {"army_no3_male"}

app = FastAPI(
    title="SAF Uniform Compliance — cv-service (MVP)",
    description=(
        "Real geometry (human detection, pose, PnP camera-pose recovery, "
        "rule-engine crop resolution) + a vision-language substitute for "
        "the not-yet-trained accessory detector. See cv-service/README.md."
    ),
)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/inspect")
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


@app.post("/check_uniform")
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
):
    """Full compliance check against the `POST /check_uniform` contract.

    `uniform_type` must be one of `SUPPORTED_UNIFORM_TYPES` (today, only
    `"army_no3_male"` — the only doctrine transcribed so far). The
    doctrine rules genuinely need `rank_tier`/`gender`/`is_sikh`/
    `medal_row_count` to resolve which items apply to this wearer — see
    `rules/army_no3_male.json`'s `condition` fields. `view`/`body_type`
    are accepted for forward-compatibility but only `"front"`/`"male"`
    are backed by doctrine today; anything else degrades to an advisory
    rather than a hard failure, since the geometry pipeline itself is
    view-agnostic (it measures whatever pose it's given).

    Unlike `/inspect`, every failure here is a hard error — this is the
    endpoint's primary path, not a best-effort secondary pass — and the
    whole pipeline runs with **no Anthropic dependency** (pure geometry +
    the trained segmentation model).
    """
    if uniform_type not in SUPPORTED_UNIFORM_TYPES:
        return _error(
            422, "UNSUPPORTED_UNIFORM",
            f"'{uniform_type}' is not a supported uniform_type. Supported: {sorted(SUPPORTED_UNIFORM_TYPES)}.",
        )

    suffix = Path(image.filename or "photo.jpg").suffix or ".jpg"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await image.read())
        tmp_path = tmp.name

    try:
        validation = validate_image(tmp_path)
        if not validation.usable:
            return _error(422, validation.status, validation.message)

        detection = detect_person(tmp_path)
        if not detection.accepted:
            status = "NO_PERSON_DETECTED" if detection.reason == "no_person_detected" else "MULTIPLE_PEOPLE_DETECTED"
            message = (
                "No person was detected in the photo. Please retake with the full "
                "body clearly visible."
                if status == "NO_PERSON_DETECTED"
                else "Multiple people were detected. Please retake with only the "
                "wearer in frame."
            )
            return _error(422, status, message, candidate_count=detection.candidate_count)

        anchor_pose = estimate_anchor_pose(tmp_path)
        image_bgr = cv2.imread(tmp_path)
        camera = solve_camera_pose_v2(anchor_pose, image_bgr.shape[1], image_bgr.shape[0])
        if not camera.solved or not camera.reliable:
            return _error(
                422, "POSE_UNRELIABLE",
                "Could not reliably determine the camera angle from this photo. "
                "Please retake per the capture protocol: front-facing, arms relaxed "
                "at sides, full torso visible.",
                reprojection_error_px=camera.reprojection_error_px,
            )

        cm_per_px = cm_per_px_from_anchor_pose(anchor_pose)
        if not cm_per_px:
            return _error(
                422, "SCALE_UNAVAILABLE",
                "Could not determine physical scale from this photo (shoulders not "
                "clearly visible). Please retake with both shoulders in frame.",
            )

        profile = {
            "rank_tier": rank_tier,
            "gender": gender,
            "isSikh": is_sikh,
            "medalRowCount": medal_row_count,
        }
        resolved = resolve_rules(camera, cm_per_px, profile=profile)
        if not resolved:
            raise HTTPException(status_code=500, detail="no rules resolved for this profile")

        try:
            seg_result = segment_uniform(tmp_path)
        except FileNotFoundError:
            return _error(
                503, "SEGMENTER_UNAVAILABLE",
                "The uniform segmentation model is not installed on this server.",
            )

        verdicts = evaluate_verdicts(
            resolved, seg_result, cm_per_px, image_bgr.shape[1], image_bgr.shape[0],
            camera_reliable=camera.reliable,
        )

        response = build_check_uniform_response(
            resolved, verdicts, detection, validation.usable, validation.confidence,
        )
        if view != "front" or body_type != "male":
            response["image_quality"]["note"] = (
                f"view='{view}', body_type='{body_type}' — only front/male doctrine exists today; "
                "results may be unreliable."
            )
        if include_debug_image:
            response["debug_image_base64"] = render_debug_image_b64(image_bgr, verdicts)

        return response
    finally:
        Path(tmp_path).unlink(missing_ok=True)

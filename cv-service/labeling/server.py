"""Local single-user labeling tool — serves one unlabeled photo at a
time from `--intake-dir`, walks an annotator through clicking the 15
anchors + outlining any visible accessories in a browser, and writes a
schema-validated label JSON to `--out-dir` on save.

Run:

    .venv-tools/bin/python -m cv-service.labeling.server \
        --intake-dir cv-service/data/real_photos \
        --out-dir cv-service/data/labels \
        --annotator "<your name>"

Then open the printed http://localhost:8002 URL. See
`cv-service/data/real_photos/README.md` for the intake convention this
reads, and `cv-service/labeling/schema.py` for exactly what gets saved.
"""

from __future__ import annotations

import argparse
import base64
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import cv2
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from labeling.schema import (  # noqa: E402
    ACCESSORY_CLASSES,
    ANCHOR_NAMES,
    ANGLES,
    LIGHTING_CONDITIONS,
)
from labeling.validate import validate_label  # noqa: E402

_PHOTO_EXTENSIONS = {".jpg", ".jpeg", ".png"}
_FILENAME_RE = re.compile(r"^(?P<subject_id>.+)__(?P<angle>[a-z0-9_]+)__(?P<lighting>[a-z0-9_]+)$")

TEMPLATE_PATH = Path(__file__).resolve().parent / "templates" / "label.html"


def discover_photos(intake_dir: Path) -> list[Path]:
    if not intake_dir.exists():
        return []
    return sorted(p for p in intake_dir.rglob("*") if p.suffix.lower() in _PHOTO_EXTENSIONS)


def label_path_for(photo_path: Path, out_dir: Path) -> Path:
    return out_dir / f"{photo_path.stem}.json"


def next_unlabeled(intake_dir: Path, out_dir: Path) -> Path | None:
    for photo in discover_photos(intake_dir):
        if not label_path_for(photo, out_dir).exists():
            return photo
    return None


def parse_filename_hint(photo_path: Path) -> dict:
    """Best-effort `<subject_id>__<angle>__<lighting>` parse for
    pre-filling the form — the annotator can still edit every field, so a
    photo that doesn't follow the convention just starts with blanks
    instead of failing."""
    match = _FILENAME_RE.match(photo_path.stem)
    if not match:
        return {"subject_id": "", "angle": "", "lighting": ""}
    return match.groupdict()


def create_app(intake_dir: Path, out_dir: Path, annotator: str) -> FastAPI:
    out_dir.mkdir(parents=True, exist_ok=True)
    app = FastAPI(title="cv-service ground-truth labeling tool")
    template_html = TEMPLATE_PATH.read_text()

    @app.get("/health")
    def health() -> dict:
        return {"status": "ok"}

    @app.get("/", response_class=HTMLResponse)
    def index() -> str:
        photo = next_unlabeled(intake_dir, out_dir)
        if photo is None:
            return "<html><body><h1>All photos labeled.</h1></body></html>"

        image_bgr = cv2.imread(str(photo))
        height, width = image_bgr.shape[:2]
        mime = "image/png" if photo.suffix.lower() == ".png" else "image/jpeg"
        data_url = f"data:{mime};base64,{base64.b64encode(photo.read_bytes()).decode()}"
        hint = parse_filename_hint(photo)

        config = {
            "photoId": photo.stem,
            "sourcePath": str(photo.relative_to(Path.cwd())) if photo.is_absolute() else str(photo),
            "imageDataUrl": data_url,
            "imageWidth": width,
            "imageHeight": height,
            "anchorNames": ANCHOR_NAMES,
            "accessoryClasses": ACCESSORY_CLASSES,
            "angles": ANGLES,
            "lightingConditions": LIGHTING_CONDITIONS,
            "subjectIdHint": hint["subject_id"],
            "angleHint": hint["angle"],
            "lightingHint": hint["lighting"],
            "annotator": annotator,
            "remaining": len(discover_photos(intake_dir)) - len(list(out_dir.glob("*.json"))),
        }
        return template_html.replace("__CONFIG_JSON__", json.dumps(config))

    @app.post("/save")
    async def save(request: Request) -> JSONResponse:
        label = await request.json()
        label.setdefault("labeled_at", datetime.now(timezone.utc).isoformat())
        errors = validate_label(label)
        if errors:
            return JSONResponse(status_code=400, content={"ok": False, "errors": errors})

        out_path = out_dir / f"{label['photo_id']}.json"
        out_path.write_text(json.dumps(label, indent=2) + "\n")
        remaining = next_unlabeled(intake_dir, out_dir) is not None
        return JSONResponse({"ok": True, "saved_to": str(out_path), "more_remaining": remaining})

    return app


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--intake-dir", type=Path, default=Path("cv-service/data/real_photos"))
    parser.add_argument("--out-dir", type=Path, default=Path("cv-service/data/labels"))
    parser.add_argument("--annotator", type=str, required=True)
    parser.add_argument("--host", type=str, default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8002)
    args = parser.parse_args()

    import uvicorn

    app = create_app(args.intake_dir.resolve(), args.out_dir.resolve(), args.annotator)
    uvicorn.run(app, host=args.host, port=args.port)


if __name__ == "__main__":
    main()

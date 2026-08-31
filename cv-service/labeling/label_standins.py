"""Drives the real `labeling/server.py` FastAPI app's `/save` endpoint to
label the 3 synthetic stand-ins produced by `render_standins.py` — this is
the "personally label 3 photos end-to-end with your own tooling" step
from the plan file, with one disclosed caveat:

**The pixel coordinates below are not mouse clicks.** No real photo
exists to click on (see the plan's §5), and an agent has no mouse anyway.
Instead, each stand-in's 15 anchor coordinates come straight from
`render_standins.py`'s `<stem>.anchors.json` "answer key" — computed by
projecting the exact same 3D socket positions used to render the photo
through the exact same camera. The accessory polygons are hand-derived
from those same anchor positions (a torso quad for `shirt`, a hip-to-ankle
quad for `trousers`, small boxes at the feet for `footwear` where visible
— everything else `present: false`, since the bare placeholder body has
no beret/badges/insignia geometry to trace). What IS real: every label
below goes through the server's actual `/save` handler — the same
`validate_label` call, the same JSON-write — via FastAPI's `TestClient`
(an in-process ASGI transport, the same technique `tests/test_api.py`
already uses to exercise `/inspect`), not a hand-written JSON file.

    .venv-tools/bin/python cv-service/labeling/label_standins.py
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient  # noqa: E402

from labeling.server import create_app  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
INTAKE_DIR = REPO_ROOT / "cv-service" / "data" / "real_photos"
OUT_DIR = REPO_ROOT / "cv-service" / "data" / "labels"
ANNOTATOR = "claude (agent, computed-projection driven — see plan §6 risk 3)"

SUBJECTS = ["standin01", "standin02", "standin03"]


def build_accessories(anchors: dict) -> list[dict]:
    def box(a_name: str, b_name: str, pad_x: float, top_y: float, bottom_y: float) -> list[list[float]] | None:
        a, b = anchors.get(a_name), anchors.get(b_name)
        if not a or not b or not a["visible"] or not b["visible"]:
            return None
        left = min(a["x_px"], b["x_px"]) - pad_x
        right = max(a["x_px"], b["x_px"]) + pad_x
        return [[left, top_y], [right, top_y], [right, bottom_y], [left, bottom_y]]

    accessories: list[dict] = []

    shirt_poly = box("left_shoulder_seam", "right_shoulder_seam", 20, anchors["left_collar_tip"]["y_px"] - 20, anchors["belt_center"]["y_px"])
    if shirt_poly:
        accessories.append({"class_name": "shirt", "present": True, "polygon_px": shirt_poly})
    else:
        accessories.append({"class_name": "shirt", "present": False})

    bottom_y = 1199.0
    if anchors["left_ankle"]["visible"]:
        bottom_y = anchors["left_ankle"]["y_px"]
    trousers_poly = box("left_shoulder_seam", "right_shoulder_seam", 5, anchors["belt_center"]["y_px"], bottom_y)
    if trousers_poly:
        accessories.append({"class_name": "trousers", "present": True, "polygon_px": trousers_poly})
    else:
        accessories.append({"class_name": "trousers", "present": False})

    if anchors["left_foot_top"]["visible"] and anchors["right_foot_top"]["visible"]:
        for side in ("left", "right"):
            a = anchors[f"{side}_foot_top"]
            poly = [[a["x_px"] - 25, a["y_px"] - 15], [a["x_px"] + 25, a["y_px"] - 15], [a["x_px"] + 25, a["y_px"] + 30], [a["x_px"] - 25, a["y_px"] + 30]]
            accessories.append({"class_name": "footwear", "present": True, "polygon_px": poly, "side": side})
    else:
        accessories.append({"class_name": "footwear", "present": False})

    # Nothing else is present on the bare placeholder body render — no
    # beret, cap badge, epaulette, sleeve rank, arms badge, or separate belt.
    for absent_class in ("headwear", "cap_badge", "epaulette", "sleeve_rank", "arms_badge", "belt"):
        accessories.append({"class_name": absent_class, "present": False})

    return accessories


def main() -> None:
    app = create_app(INTAKE_DIR, OUT_DIR, ANNOTATOR)
    client = TestClient(app)

    for subject_id in SUBJECTS:
        subject_dir = INTAKE_DIR / subject_id
        jpgs = list(subject_dir.glob("*.jpg"))
        assert len(jpgs) == 1, f"expected exactly one photo in {subject_dir}, found {jpgs}"
        photo_path = jpgs[0]
        stem = photo_path.stem
        _subject_id, angle, lighting = stem.split("__")

        anchors_answer_key = json.loads((subject_dir / f"{stem}.anchors.json").read_text())

        label = {
            "schema_version": 1,
            "photo_id": stem,
            "source_path": str(photo_path.relative_to(REPO_ROOT)),
            "subject_id": subject_id,
            "angle": angle,
            "lighting": lighting,
            "image_width": 800,
            "image_height": 1200,
            "is_synthetic_stand_in": True,
            "annotator": ANNOTATOR,
            "labeled_at": datetime.now(timezone.utc).isoformat(),
            "notes": (
                "Synthetic stand-in — bare reference body GLB render, zero real "
                "photos exist in this repo. Anchor coordinates are the exact "
                "camera-projected socket positions (render_standins.py's answer "
                "key), not manual clicks. See label_standins.py's module "
                "docstring for full disclosure."
            ),
            "anchors": anchors_answer_key,
            "accessories": build_accessories(anchors_answer_key),
        }

        response = client.post("/save", json=label)
        body = response.json()
        if not body.get("ok"):
            raise SystemExit(f"{stem}: validation failed: {body.get('errors')}")
        print(f"{stem}: saved to {body['saved_to']}")

    remaining = client.get("/health").json()
    print("health:", remaining)


if __name__ == "__main__":
    main()

"""D17 — combine several frames of the same pose into one result.

Any single frame can be unlucky: motion blur on the badge, a hand
passing the belt, a segmentation miss. `POST /check_uniform_burst` runs
the full pipeline on each frame (3-5, taken a moment apart) and takes,
per item, the status a **strict majority** of the usable frames agree
on. No majority → `UNCERTAIN`, never a coin-flip. The positions,
message and instruction shown come from a frame that voted with the
majority; `frame_agreement` ("2/3") says how solid each call is.
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

from collections import Counter

from api.response_schema import recompute_from_entries


def aggregate_burst(frame_results: list[dict | None], frame_errors: list[dict | None]) -> dict:
    """`frame_results[i]` is frame i's `/check_uniform` response, or
    `None` when that frame failed with `frame_errors[i]`."""
    usable = [r for r in frame_results if r is not None]
    names = []
    for result in usable:
        for accessory in result["accessories"]:
            if accessory["name"] not in names:
                names.append(accessory["name"])

    accessories = []
    for name in names:
        entries = [a for r in usable for a in r["accessories"] if a["name"] == name]
        votes = Counter(e["status"] for e in entries)
        status, count = votes.most_common(1)[0]
        majority = count * 2 > len(usable)
        chosen = next(e for e in entries if e["status"] == status) if majority else entries[0]
        entry = dict(chosen)
        if not majority:
            entry["status"] = "UNCERTAIN"
            entry["present"] = None
            entry["position_correct"] = None
            entry["instruction"] = (
                f"{entry['instruction'].split(':')[0]}: the frames disagreed "
                f"({', '.join(f'{k.lower()}×{v}' for k, v in votes.items())}) — retake holding still."
            )
        entry["frame_agreement"] = f"{count}/{len(usable)}"
        accessories.append(entry)

    base = max(usable, key=lambda r: sum(
        1 for a in r["accessories"] for b in accessories if a["name"] == b["name"] and a["status"] == b["status"]
    ))
    combined = {k: v for k, v in base.items() if k != "debug_image_base64"}
    combined.update(recompute_from_entries(accessories))
    combined["accessories"] = accessories
    if "debug_image_base64" in base:
        combined["debug_image_base64"] = base["debug_image_base64"]
    combined["burst"] = {
        "frames": len(frame_results),
        "usable_frames": len(usable),
        "frame_errors": [e for e in frame_errors if e is not None],
    }
    return combined

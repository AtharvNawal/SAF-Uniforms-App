#!/usr/bin/env python3
"""Upload `assets/3d/**/*.glb` to Firebase Storage `models/**`.

This is the operator counterpart to `tool/upload_accessory_images.py`.
It walks the local `assets/3d/` tree and uploads each GLB to the
matching path under `models/` in the Firebase Storage bucket that the
`composeUniformModel` Cloud Function reads from.

Local layout                           →  Storage object
────────────────────────────────────────────────────────────
assets/3d/placeholder.glb              →  models/placeholder.glb
assets/3d/bodies/<name>.glb            →  models/bodies/<name>.glb
assets/3d/uniforms/<name>.glb          →  models/uniforms/<name>.glb
assets/3d/accessories/<name>.glb       →  models/accessories/<name>.glb

The script is idempotent — each upload carries a `sha256` custom
metadata tag so reruns skip files whose remote hash matches the local
file. Each object also gets a stable `firebaseStorageDownloadTokens`
metadata entry so the public download URL doesn't churn between runs.

Usage:
    GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \\
      python3 tool/upload_models.py \\
        --bucket saf-uniforms.firebasestorage.app

Optional flags:
    --dry-run    Show what would be uploaded without making any changes.
    --only PATH  Limit upload to files matching this glob (e.g. "bodies/*").
"""
from __future__ import annotations

import argparse
import base64
import fnmatch
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS_ROOT = REPO_ROOT / "assets" / "3d"
TOKEN_TTL = 3500  # seconds; refresh just before the 1-hour cap

OAUTH_SCOPE = "https://www.googleapis.com/auth/devstorage.read_write"
TOKEN_URL = "https://oauth2.googleapis.com/token"


# ---------------------------------------------------------------------------
# OAuth (service-account JWT → access token).
# Lifted verbatim from upload_accessory_images.py for consistency — see
# that file for the rationale on using urllib + openssl over a Python SDK.
# ---------------------------------------------------------------------------


def _b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def _mint_access_token(sa_path: str) -> tuple[str, float]:
    with open(sa_path) as f:
        sa = json.load(f)
    header = {"alg": "RS256", "typ": "JWT"}
    now = int(time.time())
    claim = {
        "iss": sa["client_email"],
        "scope": OAUTH_SCOPE,
        "aud": TOKEN_URL,
        "exp": now + 3600,
        "iat": now,
    }
    signing_input = (
        f"{_b64url(json.dumps(header).encode())}."
        f"{_b64url(json.dumps(claim).encode())}"
    ).encode()
    with tempfile.NamedTemporaryFile(suffix=".pem", delete=False) as f:
        f.write(sa["private_key"].encode())
        key_file = f.name
    try:
        sig = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", key_file],
            input=signing_input,
            capture_output=True,
            check=True,
        ).stdout
    finally:
        os.unlink(key_file)
    jwt_token = signing_input.decode() + "." + _b64url(sig)
    req = urllib.request.Request(
        TOKEN_URL,
        data=urllib.parse.urlencode(
            {
                "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion": jwt_token,
            }
        ).encode(),
    )
    with urllib.request.urlopen(req) as resp:
        body = json.loads(resp.read())
    return body["access_token"], time.time() + TOKEN_TTL


# ---------------------------------------------------------------------------
# GCS REST helpers.
# ---------------------------------------------------------------------------


def _http_request(
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    data: bytes | None = None,
) -> bytes:
    req = urllib.request.Request(url, data=data, method=method)
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    with urllib.request.urlopen(req) as resp:
        return resp.read()


def _get_remote_metadata(
    bucket: str, object_name: str, token: str
) -> dict | None:
    encoded = urllib.parse.quote(object_name, safe="")
    url = f"https://storage.googleapis.com/storage/v1/b/{bucket}/o/{encoded}"
    try:
        body = _http_request(
            "GET", url, headers={"Authorization": f"Bearer {token}"}
        )
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise
    return json.loads(body)


def _multipart_upload(
    bucket: str,
    object_name: str,
    file_bytes: bytes,
    metadata: dict,
    token: str,
) -> dict:
    boundary = f"----saf{uuid.uuid4().hex}"
    metadata_json = json.dumps(metadata).encode()
    body = b"".join(
        [
            f"--{boundary}\r\n".encode(),
            b"Content-Type: application/json; charset=UTF-8\r\n\r\n",
            metadata_json,
            f"\r\n--{boundary}\r\n".encode(),
            f"Content-Type: {metadata['contentType']}\r\n\r\n".encode(),
            file_bytes,
            f"\r\n--{boundary}--\r\n".encode(),
        ]
    )
    encoded = urllib.parse.quote(object_name, safe="")
    url = (
        f"https://storage.googleapis.com/upload/storage/v1/b/{bucket}/o"
        f"?uploadType=multipart&name={encoded}"
    )
    return json.loads(
        _http_request(
            "POST",
            url,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": f"multipart/related; boundary={boundary}",
                "Content-Length": str(len(body)),
            },
            data=body,
        )
    )


def _download_url(bucket: str, object_name: str, download_token: str) -> str:
    encoded = urllib.parse.quote(object_name, safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded}"
        f"?alt=media&token={download_token}"
    )


# ---------------------------------------------------------------------------
# Local file walk.
# ---------------------------------------------------------------------------


def _walk_glbs(only: str | None) -> list[tuple[Path, str]]:
    """Return a list of (local_path, storage_object_name) tuples.

    Storage object names are constructed by replacing the local
    `assets/3d/` prefix with `models/`. So
    `assets/3d/bodies/male_apose.glb` → `models/bodies/male_apose.glb`.
    """
    results: list[tuple[Path, str]] = []
    if not ASSETS_ROOT.exists():
        return results
    for path in sorted(ASSETS_ROOT.rglob("*.glb")):
        if not path.is_file():
            continue
        rel = path.relative_to(ASSETS_ROOT).as_posix()
        if only and not fnmatch.fnmatch(rel, only):
            continue
        object_name = f"models/{rel}"
        results.append((path, object_name))
    return results


# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--bucket",
        required=True,
        help="Firebase Storage bucket (e.g. saf-uniforms.firebasestorage.app)",
    )
    ap.add_argument(
        "--credentials",
        default=os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"),
        help="Service account JSON path. Defaults to GOOGLE_APPLICATION_CREDENTIALS.",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be uploaded; do not actually upload.",
    )
    ap.add_argument(
        "--only",
        default=None,
        help=(
            "Limit upload to files matching this glob, "
            "evaluated relative to assets/3d/ "
            "(e.g. 'bodies/*' or 'accessories/army_*')."
        ),
    )
    args = ap.parse_args()

    if not args.dry_run and (
        not args.credentials or not Path(args.credentials).exists()
    ):
        sys.exit(
            "Service account JSON not found. Set GOOGLE_APPLICATION_CREDENTIALS "
            "or pass --credentials <path>. (Use --dry-run to preview without auth.)"
        )

    targets = _walk_glbs(args.only)
    if not targets:
        print(
            f"No .glb files found under {ASSETS_ROOT}. "
            "Run tool/generate_placeholder_bodies.py first, or drop "
            "real artist GLBs into assets/3d/."
        )
        return 0

    print(f"Found {len(targets)} GLB file(s) to consider:")
    for local, obj in targets:
        print(f"  {local.relative_to(REPO_ROOT)}  →  gs://{args.bucket}/{obj}")
    if args.dry_run:
        print("\n--dry-run set; not uploading.")
        return 0

    print(f"\nUploading to gs://{args.bucket}")
    token, token_exp = _mint_access_token(args.credentials)

    def maybe_refresh_token() -> str:
        nonlocal token, token_exp
        if time.time() >= token_exp - 60:
            token, token_exp = _mint_access_token(args.credentials)
        return token

    uploaded = skipped = failed = 0
    for local_path, object_name in targets:
        local_bytes = local_path.read_bytes()
        local_sha = hashlib.sha256(local_bytes).hexdigest()
        try:
            tk = maybe_refresh_token()
            remote = _get_remote_metadata(args.bucket, object_name, tk)
            if (
                remote is not None
                and (remote.get("metadata") or {}).get("sha256") == local_sha
            ):
                skipped += 1
                # Make sure a download token still exists (issue one if not).
                md = remote.get("metadata") or {}
                if not md.get("firebaseStorageDownloadTokens"):
                    new_tok = uuid.uuid4().hex
                    patch_url = (
                        f"https://storage.googleapis.com/storage/v1/b/"
                        f"{args.bucket}/o/{urllib.parse.quote(object_name, safe='')}"
                    )
                    _http_request(
                        "PATCH",
                        patch_url,
                        headers={
                            "Authorization": f"Bearer {tk}",
                            "Content-Type": "application/json",
                        },
                        data=json.dumps(
                            {
                                "metadata": {
                                    "firebaseStorageDownloadTokens": new_tok,
                                }
                            }
                        ).encode(),
                    )
                print(f"  · {object_name}  (sha256 match — skipped)")
                continue

            download_token = uuid.uuid4().hex
            _multipart_upload(
                args.bucket,
                object_name,
                local_bytes,
                metadata={
                    "name": object_name,
                    "contentType": "model/gltf-binary",
                    "cacheControl": "public, max-age=31536000, immutable",
                    "metadata": {
                        "sha256": local_sha,
                        "firebaseStorageDownloadTokens": download_token,
                    },
                },
                token=tk,
            )
            uploaded += 1
            url = _download_url(args.bucket, object_name, download_token)
            print(f"  ✓ {object_name}  ({len(local_bytes):,} bytes)")
            print(f"      url: {url}")
        except urllib.error.HTTPError as e:
            failed += 1
            print(
                f"  [fail] {object_name}: HTTP {e.code} {e.reason}",
                file=sys.stderr,
            )
        except Exception as e:  # noqa: BLE001
            failed += 1
            print(f"  [fail] {object_name}: {e}", file=sys.stderr)

    print(
        f"\nDone. uploaded={uploaded} skipped={skipped} failed={failed}"
    )
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    sys.exit(main())

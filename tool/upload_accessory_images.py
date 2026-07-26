#!/usr/bin/env python3
"""Upload assets/accessories/<id>/{image,placement}.png to Firebase Storage.

Why this lives in Python and not in tool/seed_firestore.dart:
  Dart's shared HttpClient inside `google_cloud_storage` (used via
  firebase_admin_sdk) gets into a corrupted-state mid-stream after a
  handful of uploads ("HttpException: Unexpected response (unsolicited
  response without request)") and that exception escapes try/catch via
  an async stream callback. Python's urllib / openssl path is rock-solid
  for this volume of multipart uploads, so we just delegate the upload
  half of the seed pipeline here.

After this script finishes, re-run the Dart seed script *without*
`--upload-images` to push the patched accessory_library.v1.json to
Firestore.

Usage:
    GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \\
      python3 tool/upload_accessory_images.py \\
        --bucket saf-uniforms.firebasestorage.app

Idempotent: each object carries a `sha256` custom metadata tag; reruns
skip files whose remote tag matches the local file hash. The Firebase
download token (`firebaseStorageDownloadTokens` metadata) is preserved
across reruns so already-issued URLs don't churn.
"""
from __future__ import annotations

import argparse
import base64
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
JSON_PATH = REPO_ROOT / "assets" / "data" / "accessory_library.v1.json"
ASSETS_ROOT = REPO_ROOT / "assets" / "accessories"
TOKEN_TTL = 3500  # seconds; refresh before the 1-hour cap

OAUTH_SCOPE = "https://www.googleapis.com/auth/devstorage.read_write"
TOKEN_URL = "https://oauth2.googleapis.com/token"


# ---------------------------------------------------------------------------
# OAuth (service-account JWT → access token)
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
# GCS REST helpers
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
        body = _http_request("GET", url, headers={"Authorization": f"Bearer {token}"})
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
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--bucket", required=True, help="Firebase Storage bucket (e.g. saf-uniforms.firebasestorage.app)")
    ap.add_argument(
        "--credentials",
        default=os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"),
        help="Path to the service account JSON. Defaults to GOOGLE_APPLICATION_CREDENTIALS env var.",
    )
    args = ap.parse_args()

    if not args.credentials or not Path(args.credentials).exists():
        sys.exit(
            "Service account JSON not found. Set GOOGLE_APPLICATION_CREDENTIALS "
            "or pass --credentials <path>."
        )

    print(f"Uploading to gs://{args.bucket}")
    token, token_exp = _mint_access_token(args.credentials)

    with open(JSON_PATH) as f:
        catalog = json.load(f)
    accessories = catalog["accessories"]

    uploaded = skipped = missing = failed = patched_entries = 0

    def maybe_refresh_token() -> str:
        nonlocal token, token_exp
        if time.time() >= token_exp - 60:
            token, token_exp = _mint_access_token(args.credentials)
        return token

    for entry in accessories:
        accessory_id = entry["id"]
        accessory_dir = ASSETS_ROOT / accessory_id
        if not accessory_dir.is_dir():
            missing += 1
            continue

        patched_this_entry = False
        for file_name, json_key in [("image.png", "image_url"), ("placement.png", "placement_diagram")]:
            local_path = accessory_dir / file_name
            if not local_path.is_file():
                missing += 1
                continue

            local_bytes = local_path.read_bytes()
            local_sha = hashlib.sha256(local_bytes).hexdigest()
            object_name = f"accessories/{accessory_id}/{file_name}"

            try:
                tk = maybe_refresh_token()
                remote = _get_remote_metadata(args.bucket, object_name, tk)

                download_token: str | None = None
                if remote is not None:
                    md = remote.get("metadata") or {}
                    if md.get("sha256") == local_sha:
                        skipped += 1
                        download_token = md.get("firebaseStorageDownloadTokens")
                        if download_token and "," in download_token:
                            download_token = download_token.split(",")[0]
                        if not download_token:
                            # Add a token to an existing object via metadata patch
                            download_token = uuid.uuid4().hex
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
                                    {"metadata": {"firebaseStorageDownloadTokens": download_token}}
                                ).encode(),
                            )

                if download_token is None:
                    download_token = uuid.uuid4().hex
                    _multipart_upload(
                        args.bucket,
                        object_name,
                        local_bytes,
                        metadata={
                            "name": object_name,
                            "contentType": "image/png",
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
                if entry.get(json_key) != url:
                    entry[json_key] = url
                    patched_this_entry = True
            except urllib.error.HTTPError as e:
                failed += 1
                print(f"  [fail] {object_name}: HTTP {e.code} {e.reason}", file=sys.stderr)
            except Exception as e:  # noqa: BLE001
                failed += 1
                print(f"  [fail] {object_name}: {e}", file=sys.stderr)

        if patched_this_entry:
            patched_entries += 1
            # Checkpoint after every patched entry so partial progress survives.
            with open(JSON_PATH, "w") as f:
                json.dump(catalog, f, indent=2, ensure_ascii=False)
                f.write("\n")
            print(f"  ✓ {accessory_id}")

    # Final write (covers cases where patched_this_entry never flipped).
    with open(JSON_PATH, "w") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(
        f"\nDone. uploaded={uploaded} skipped={skipped} missing={missing} "
        f"failed={failed} json_patched={patched_entries}"
    )
    return 0 if failed == 0 else 2


if __name__ == "__main__":
    sys.exit(main())

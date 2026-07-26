#!/usr/bin/env python3
"""Set the CORS policy on the Firebase Storage bucket so cross-origin
GLB / image fetches from Flutter `model_viewer_plus`'s WebView (which
runs on `http://127.0.0.1:<port>/`) succeed.

Without this, Chromium inside the WebView blocks the cross-origin
fetch from `http://127.0.0.1` to `https://firebasestorage.googleapis.com`
with a CORS policy error, even though the URL itself is publicly
fetchable (the Firebase download token gates access, not CORS).

The policy below allows GET / HEAD from any origin. Public download
URLs already use unguessable tokens, so this doesn't widen the
security surface — it only relaxes the *browser* CORS check.

Usage:
    GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \\
      python3 tool/set_storage_cors.py \\
        --bucket saf-uniforms.firebasestorage.app

This is a one-time operator action; CORS rules are bucket-level.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

OAUTH_SCOPE = "https://www.googleapis.com/auth/devstorage.full_control"
TOKEN_URL = "https://oauth2.googleapis.com/token"

CORS_POLICY = [
    {
        "origin": ["*"],
        "method": ["GET", "HEAD"],
        "responseHeader": [
            "Content-Type",
            "Content-Length",
            "Content-Range",
            "Content-Disposition",
            "Content-Encoding",
            "Cache-Control",
            "ETag",
            "Last-Modified",
        ],
        "maxAgeSeconds": 3600,
    }
]


def _b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def _mint_access_token(sa_path: str) -> str:
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
    signing = (
        f"{_b64url(json.dumps(header).encode())}."
        f"{_b64url(json.dumps(claim).encode())}"
    ).encode()
    with tempfile.NamedTemporaryFile(suffix=".pem", delete=False) as f:
        f.write(sa["private_key"].encode())
        keypath = f.name
    try:
        sig = subprocess.run(
            ["openssl", "dgst", "-sha256", "-sign", keypath],
            input=signing,
            capture_output=True,
            check=True,
        ).stdout
    finally:
        os.unlink(keypath)
    jwt = signing.decode() + "." + _b64url(sig)
    req = urllib.request.Request(
        TOKEN_URL,
        data=urllib.parse.urlencode(
            {
                "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion": jwt,
            }
        ).encode(),
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())["access_token"]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--bucket", required=True)
    ap.add_argument(
        "--credentials",
        default=os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"),
    )
    args = ap.parse_args()

    if not args.credentials or not os.path.exists(args.credentials):
        sys.exit(
            "Service account JSON not found. Set GOOGLE_APPLICATION_CREDENTIALS "
            "or pass --credentials <path>."
        )

    print(f"Bucket: gs://{args.bucket}")
    print(f"Policy:  {json.dumps(CORS_POLICY, indent=2)}\n")

    token = _mint_access_token(args.credentials)
    url = f"https://storage.googleapis.com/storage/v1/b/{args.bucket}?fields=cors"

    # First read existing CORS so we can show before/after.
    print("=== BEFORE ===")
    try:
        before = urllib.request.urlopen(
            urllib.request.Request(
                url, headers={"Authorization": f"Bearer {token}"}
            )
        ).read()
        existing = json.loads(before).get("cors", [])
        print(json.dumps(existing, indent=2) if existing else "  (no CORS rules set)")
    except urllib.error.HTTPError as e:
        print(f"  read failed: HTTP {e.code} — {e.read().decode()[:200]}")
        return 1

    # Apply new CORS via PATCH.
    print("\n=== APPLYING ===")
    req = urllib.request.Request(
        url,
        method="PATCH",
        data=json.dumps({"cors": CORS_POLICY}).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        result = urllib.request.urlopen(req).read()
    except urllib.error.HTTPError as e:
        print(
            f"  PATCH failed: HTTP {e.code} — {e.read().decode()[:500]}",
            file=sys.stderr,
        )
        return 2

    print("=== AFTER ===")
    print(json.dumps(json.loads(result).get("cors", []), indent=2))
    print("\n✓ CORS policy applied. Effective immediately for new requests.")
    print("  (No need to redeploy anything — this is bucket metadata.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

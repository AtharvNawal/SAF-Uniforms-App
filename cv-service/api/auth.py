"""Firebase ID-token gate for the public (Cloud Run) deployment.

The app signs every user in with Firebase Auth (custom token minted by the
`claimDeviceIdentity` Cloud Function), so each scan request can carry that
user's ID token as `Authorization: Bearer <token>`. When
`config.REQUIRE_AUTH` is on — set via `CV_SERVICE_REQUIRE_AUTH=1` on Cloud
Run — every analysis endpoint verifies it against the `saf-uniforms`
project and rejects anything else with a typed 401, in the same
`{success, status, message}` shape as every other error, so the app's
existing error mapping shows it.

Off by default: local runs (`deploy/run-cv-service-local.sh`, the LAN /
USB setups) and the test suite behave exactly as before.

See ChangeRequest/2026-10-02_cv-service-cloud-run-deploy.md.
"""

from __future__ import annotations

import logging
from typing import Callable

from fastapi import Request
from fastapi.responses import JSONResponse

import config

log = logging.getLogger("cv_service.auth")


class AuthError(Exception):
    """Raised by `require_user`; rendered by `auth_error_handler`."""

    def __init__(self, status: str, message: str):
        super().__init__(message)
        self.status = status
        self.message = message


def _default_verifier(token: str) -> dict:
    # Imported lazily so environments without google-auth (none today, but
    # it's only needed for the cloud deployment) can still import the API.
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token

    return id_token.verify_firebase_token(
        token, google_requests.Request(), audience=config.FIREBASE_PROJECT_ID
    )


# Swappable for tests (no network, no real tokens).
verify_token: Callable[[str], dict] = _default_verifier


def require_user(request: Request) -> dict | None:
    """FastAPI dependency. Returns the decoded token claims when auth is
    enforced, `None` when it isn't."""
    if not config.REQUIRE_AUTH:
        return None
    header = request.headers.get("authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token:
        log.info("auth: rejected %s %s — no bearer token", request.method, request.url.path)
        raise AuthError("UNAUTHENTICATED", "Sign in to the app to use the scanner (missing ID token).")
    try:
        claims = verify_token(token)
    except Exception as e:  # noqa: BLE001 — any verification failure is a 401
        log.info("auth: rejected %s — invalid token: %s", request.url.path, e)
        raise AuthError("UNAUTHENTICATED", "Your sign-in has expired or is invalid. Restart the app and try again.") from e
    if not claims or not claims.get("sub"):
        raise AuthError("UNAUTHENTICATED", "ID token has no user.")
    log.debug("auth: ok uid=%s path=%s", claims.get("sub"), request.url.path)
    return claims


async def auth_error_handler(_request: Request, exc: AuthError) -> JSONResponse:
    return JSONResponse(status_code=401, content={"success": False, "status": exc.status, "message": exc.message})

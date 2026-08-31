#!/usr/bin/env bash
#
# Run cv-service on this Mac so a phone on the same Wi-Fi can reach it.
# Keep this terminal open while you test. Ctrl-C to stop.
#
#   ./deploy/run-cv-service-local.sh
#
# The Flutter app's default points at this machine's LAN IP
# (kCvServiceBaseUrl in
#  lib/features/ar_scanner/data/cv_service_inspection_repository.dart).
# If your IP is not 192.168.1.144, update that constant + the matching
# entry in android/app/src/main/res/xml/network_security_config.xml,
# then rebuild the APK.

set -euo pipefail
cd "$(dirname "$0")/../cv-service"

IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo '?')"
echo "cv-service will listen on http://0.0.0.0:8001"
echo "phone should use:          http://${IP}:8001"
echo "test from the phone browser: http://${IP}:8001/health  -> {\"status\":\"ok\"}"
echo
echo "if macOS asks 'allow Python to accept incoming connections?' -> Allow"
echo

exec ../.venv-tools/bin/uvicorn api.main:app --host 0.0.0.0 --port 8001

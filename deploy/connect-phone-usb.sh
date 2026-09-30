#!/usr/bin/env bash
#
# Connect an Android phone to the laptop's cv-service over the USB cable,
# for when Wi-Fi between them doesn't work (different networks, firewall,
# client isolation, changing IP address).
#
#   1. Phone: Settings → About phone → tap "Build number" 7× → Developer
#      options → turn on "USB debugging". Plug it in, tap "Allow".
#   2. Laptop: keep ./deploy/run-cv-service-local.sh running in one terminal,
#      run THIS script in another.
#   3. App: Settings (or the scanner's "Connection problem" → Server
#      settings) → "USB cable" → Test connection.
#
# `adb reverse` makes the phone's own 127.0.0.1:8001 forward over the cable
# to this laptop's port 8001. It lasts until the cable is unplugged or adb
# restarts — just run this script again.
set -euo pipefail

ADB="$(command -v adb || true)"
[ -z "$ADB" ] && [ -x "$HOME/Library/Android/sdk/platform-tools/adb" ] && ADB="$HOME/Library/Android/sdk/platform-tools/adb"
if [ -z "$ADB" ]; then
  echo "adb not found — install Android platform-tools (Android Studio → SDK Manager) and retry." >&2
  exit 1
fi

if ! "$ADB" get-state >/dev/null 2>&1; then
  echo "No phone found over USB."
  echo "  - Is USB debugging on (Developer options)?"
  echo "  - Did you tap 'Allow USB debugging' on the phone?"
  echo "  - Try another cable/port (some cables are charge-only)."
  "$ADB" devices -l
  exit 1
fi

"$ADB" reverse tcp:8001 tcp:8001
echo "Phone connected: its 127.0.0.1:8001 now reaches this laptop's cv-service."
"$ADB" reverse --list

if curl -s --max-time 2 http://127.0.0.1:8001/health | grep -q '"ok"'; then
  echo "cv-service is running on this laptop."
else
  echo "WARNING: cv-service isn't answering on this laptop — start ./deploy/run-cv-service-local.sh"
fi
echo
echo "In the app: Settings → Analysis server → 'USB cable' → Test connection."

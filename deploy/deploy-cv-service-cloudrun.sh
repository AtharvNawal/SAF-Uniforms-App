#!/usr/bin/env bash
# Build cv-service with Cloud Build and deploy it to Cloud Run, so the
# app's uniform scanner works from any network (not just the Mac's Wi-Fi).
#
#   deploy/deploy-cv-service-cloudrun.sh
#
# Needs: `gcloud auth login` with an account that can administer the
# saf-uniforms project. No local Docker. Re-run to ship a new version.
# See ChangeRequest/2026-10-02_cv-service-cloud-run-deploy.md.
set -euo pipefail

PROJECT="${PROJECT:-saf-uniforms}"
REGION="${REGION:-asia-southeast1}"
SERVICE="${SERVICE:-cv-service}"
REPO="${REPO:-cv-service}"
TAG="${TAG:-$(date +%Y%m%d-%H%M%S)}"
IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/${SERVICE}:${TAG}"

cd "$(dirname "$0")/.."
log() { echo "[deploy-cv-service] $*"; }

log "project=${PROJECT} region=${REGION} image=${IMAGE}"
log "enabling APIs (no-op when already on)…"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com \
  --project "${PROJECT}"

if ! gcloud artifacts repositories describe "${REPO}" --location "${REGION}" --project "${PROJECT}" >/dev/null 2>&1; then
  log "creating Artifact Registry repo ${REPO}…"
  gcloud artifacts repositories create "${REPO}" --repository-format docker \
    --location "${REGION}" --project "${PROJECT}" --description "cv-service images"
fi

log "building on Cloud Build (first build ~15-25 min: torch, models)…"
gcloud builds submit . --project "${PROJECT}" --region "${REGION}" \
  --config deploy/cloudbuild.cv-service.yaml --substitutions "_IMAGE=${IMAGE}"

log "deploying to Cloud Run…"
# concurrency 1: the pipeline is CPU-bound, one scan per instance.
# max-instances 2: cost cap. min-instances 0: free when idle (cold start ~1 min).
# CV_SERVICE_REQUIRE_AUTH=1: only signed-in app users (Firebase ID token).
gcloud run deploy "${SERVICE}" --project "${PROJECT}" --region "${REGION}" \
  --image "${IMAGE}" \
  --cpu 4 --memory 8Gi --timeout 300 --concurrency 1 \
  --min-instances 0 --max-instances 2 --cpu-boost \
  --set-env-vars "CV_SERVICE_REQUIRE_AUTH=1,CV_SERVICE_FIREBASE_PROJECT_ID=${PROJECT}" \
  --allow-unauthenticated

URL="$(gcloud run services describe "${SERVICE}" --project "${PROJECT}" --region "${REGION}" --format 'value(status.url)')"
log "service URL: ${URL}"
log "health: $(curl -s -m 120 "${URL}/health" || echo 'no response yet (cold start) — retry in a minute')"
log "Build the app against it:"
log "  flutter build apk --release --split-per-abi --dart-define=CV_SERVICE_BASE_URL=${URL}"

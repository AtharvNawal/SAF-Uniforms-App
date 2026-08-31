# cv-service — container image (local use).
#
# Build context is the REPO ROOT (not cv-service/), because
# utils/extract_anchors.py reads assets/3d/bodies/*.glb at
# anchor-extraction time. .dockerignore (repo root) keeps the rest of
# the monorepo out of the context.
#
# Build:  docker build -t cv-service -f cv-service/Dockerfile .
# Run:    docker run -p 8001:8001 cv-service                       # /check_uniform needs no key
#         docker run -p 8001:8001 -e ANTHROPIC_API_KEY=sk-... cv-service   # + /inspect
#
# For the plain "run on my Mac" path the Flutter app uses, you don't
# need Docker at all — see deploy/run-cv-service-local.sh.

FROM python:3.11-slim

# libgl1 / libglib2.0-0: opencv-python-headless still needs these on
# Debian slim. curl: HEALTHCHECK + the model download script.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY cv-service/requirements.txt cv-service/requirements.txt
RUN pip install --no-cache-dir -r cv-service/requirements.txt

# Reference assets + the service itself.
COPY assets/3d/bodies/ assets/3d/bodies/
COPY cv-service/ cv-service/

# MediaPipe's pose-landmarker .task file is not auto-fetched (YOLO
# weights are). Bake it in so there's no first-request network hop.
RUN cv-service/models/download_models.sh

ENV PYTHONUNBUFFERED=1
WORKDIR /app/cv-service
EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s \
  CMD curl -f http://localhost:8001/health || exit 1

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8001"]

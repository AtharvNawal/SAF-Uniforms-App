# cv-service — container image (local Docker and the Cloud Run deployment).
#
# Build context is the REPO ROOT (not cv-service/): the service reads
# assets/3d/bodies/*.glb (anchors), assets/accessories/<id>/image.png
# (badge-variant references) and assets/data/accessory_library.v1.json
# (per-item instructions) at runtime. .dockerignore / .gcloudignore keep
# the rest of the monorepo out of the context.
#
# Cloud Run:  deploy/deploy-cv-service-cloudrun.sh  (builds remotely with
#             Cloud Build — no local Docker needed)
# Local:      docker build -t cv-service -f cv-service/Dockerfile .
#             docker run -p 8001:8001 cv-service
#
# For the plain "run on my Mac" path, Docker isn't needed at all — see
# deploy/run-cv-service-local.sh.

FROM python:3.11-slim

# libgl1 / libglib2.0-0: opencv + mediapipe on Debian slim. libegl1 /
# libgles2: MediaPipe's pose landmarker dlopens libEGL even on CPU (the
# first Cloud Build failed on exactly this). git: the `clip @ git+...`
# requirement. curl: HEALTHCHECK.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libegl1 \
    libgles2 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Model caches at fixed paths, so build-time downloads (warm_cache.py) are
# found at runtime regardless of $HOME.
ENV PYTHONUNBUFFERED=1 \
    TORCH_HOME=/app/.cache/torch \
    EASYOCR_MODULE_PATH=/app/.cache/easyocr \
    XDG_CACHE_HOME=/app/.cache \
    YOLO_CONFIG_DIR=/app/.cache/ultralytics

WORKDIR /app
RUN mkdir -p /app/.cache/torch /app/.cache/easyocr /app/.cache/ultralytics

# CPU-only PyTorch first: the default Linux wheel drags in ~3 GB of CUDA
# libraries Cloud Run (CPU) can never use. ultralytics / easyocr then see
# torch already satisfied.
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch torchvision

COPY cv-service/requirements.txt cv-service/requirements.txt
RUN pip install --no-cache-dir -r cv-service/requirements.txt

# Reference assets + the service itself (incl. the model weights that
# .dockerignore lets through — the tested files, not fresh downloads).
COPY assets/3d/bodies/ assets/3d/bodies/
COPY assets/accessories/ assets/accessories/
COPY assets/data/accessory_library.v1.json assets/data/accessory_library.v1.json
COPY cv-service/ cv-service/

WORKDIR /app/cv-service

# Fetch anything not shipped (MediaPipe .task files when absent), then load
# every model once so lazy downloads land in the image. Fails the build if
# any model can't load.
RUN [ -f models/pose_landmarker_heavy.task ] || models/download_models.sh
RUN python models/warm_cache.py

# Cloud Run injects $PORT (8080); local runs keep 8001.
ENV PORT=8001
EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD curl -f http://localhost:${PORT}/health || exit 1

CMD ["sh", "-c", "exec uvicorn api.main:app --host 0.0.0.0 --port ${PORT}"]

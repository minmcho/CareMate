# ---------------------------------------------------------------------------
# VitalPath AI — multi-stage production Dockerfile
# ---------------------------------------------------------------------------
# Stage 1: deps — install Python wheels into a virtual env
# Stage 2: production — slim runtime, non-root user, minimal surface area
# ---------------------------------------------------------------------------

FROM python:3.11-slim AS deps

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install -r requirements.txt

# ---------------------------------------------------------------------------
# Production image
# ---------------------------------------------------------------------------

FROM python:3.11-slim AS production

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r vitalpath && useradd -r -g vitalpath -s /sbin/nologin vitalpath

COPY --from=deps /opt/venv /opt/venv

WORKDIR /app
COPY app ./app
COPY tests ./tests

RUN chown -R vitalpath:vitalpath /app

USER vitalpath

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -sf http://localhost:8000/healthz || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]

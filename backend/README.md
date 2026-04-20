# VitalPath AI Backend

Safety-first wellness coaching API.

## Stack

- **Python 3.11+**
- **FastAPI** — HTTP/WS API gateway
- **Strawberry GraphQL** — flexible query surface for the iOS client
- **SQLAlchemy 2.0 (async)** + **PostgreSQL** — profiles, sessions, habits, audit
- **Celery + Redis** — long-running AI and video analysis workers
- **Redis Reasoning Context** — short-term event memory for chat + pose telemetry
- **ChromaDB** — semantic memory (RAG) via HNSW
- **Supabase Auth** — JWT flow with GraphQL interceptors

## Architecture

```
iOS client ──► FastAPI ──► Strawberry GraphQL ──► Services
                  │             │
                  │             └── SafetyValidator (pre- + post-)
                  │             └── MCPRouter ──► Llama 4 / Qwen 3.5 / Qwen 3.5 VL
                  │             └── WellnessMemory (ChromaDB)
                  │             └── ReasoningContextStore (Redis)
                  │
                  └── REST /chat/ask  /voice/transcribe  /healthz  /readyz
                  └── REST /admin/dashboard
                  └── Celery workers: video analysis, weekly digests, housekeeping
```

### Safety layer

`app/services/safety.py` runs on every inbound message and every model
output. It blocks crisis phrasing, rewrites prohibited medical claims, and
redacts PII. Crisis events are only ever stored as SHA-256 hashes.

### Multi-agent routing (MCP)

`app/services/mcp.py` dispatches:

| Input                       | Agent         | Reason                       |
|-----------------------------|---------------|------------------------------|
| Plain text                  | Llama 4       | Low latency, high empathy    |
| Complex / multilingual text | Qwen 3.5      | Large context, reasoning     |
| Image / video frames        | Qwen 3.5 VL   | Visual accuracy              |

## Running locally

```bash
cp .env.example .env
docker compose up --build
```

Then open:
- REST docs: http://localhost:8000/docs
- GraphQL playground: http://localhost:8000/graphql

## Tests

```bash
pytest backend/tests
```

## Production deployment

Helm chart outline lives in `backend/deploy/helm/` (not committed — generated
per-environment). Key observations:

- `api`, `worker`, `beat` run as separate deployments.
- Horizontal Pod Autoscaler on API CPU > 65%, max 20 replicas for 50k MAU.
- Celery worker concurrency = 4, prefetch = 1 (long AI tasks).
- Prometheus scrapes `/metrics`, Grafana dashboards in `deploy/grafana/`.
- Sentry DSN injected via secret.

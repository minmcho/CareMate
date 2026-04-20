# VitalPath AI — Production Readiness Blueprint

This plan upgrades the platform with an enterprise stack built around:

- **GraphQL + FastAPI** for app APIs
- **Supabase Auth** for secure identity and session handling
- **PostgreSQL** for persistent product data
- **Redis** for reasoning context and low-latency event memory
- **Celery** for long-running asynchronous AI + vision workflows

## 1) AI and multimodal model strategy

- Keep model selection configurable via environment variables so operations can swap in latest open-source text and vision models without code changes.
- Use text model for coaching/planning and vision model for meal + movement analysis.
- Add safety middleware before and after model calls.

## 2) Real-time pose analytics and behavior monitoring

- Client streams pose keypoints plus behavior states (`focused`, `fatigued`, `drowsy`, `distressed`) through GraphQL mutation.
- Backend computes a posture score, emits alerts, and stores events in Redis reasoning context.
- Celery workers can batch events into trend summaries for weekly reports and risk escalation.

## 3) Admin web panel (operations + growth)

- Operational KPIs: DAU, retention, moderation queue, safety interventions, vision sessions.
- Growth niche tracking: ergonomic coaching, perimenopause support, athlete recovery, shift-worker sleep.
- Trust center status: App Store submission checklist, privacy disclosures, and moderation coverage.

## 4) Apple App Store compliance checklist

- App Privacy labels and data handling descriptions aligned to current app behavior.
- Clear in-app disclaimer that coaching is wellness guidance, not medical diagnosis or treatment.
- In-app controls for content reporting, account deletion, and data export requests.
- Sign in with Apple enabled when third-party sign-in exists.
- Age rating, user-generated content moderation policy, and contact/support links completed.

## 5) Launch gate for production

1. Load and soak tests for API + workers.
2. Security review (JWT auth, secret rotation, rate limiting, audit logs).
3. Incident runbook and on-call alerting wired (health checks + job failure alerts).
4. Final TestFlight pass with App Store metadata/signing verification.

## 6) Runtime resilience and optimization (implemented)

- Reasoning context now degrades gracefully to in-memory mode if Redis is unavailable.
- `/readyz` exposes structured checks for Supabase auth config, reasoning store status, DB URL and Celery broker wiring.
- Admin dashboard includes production-readiness controls and reasoning-store backend status for operational visibility.

# CareMate Backend

FastAPI backend for the CareMate caregiver assistant platform.

## Stack

| Component | Technology |
|-----------|-----------|
| API Framework | FastAPI + Uvicorn |
| Database | MongoDB (via Motor async driver) |
| AI Agents | CrewAI (Care Coordinator, Medical Advisor, Diet Planner, Interpreter) |
| LLM Inference | VLLM (Mistral-7B-Instruct, OpenAI-compatible endpoint) |
| Speech-to-Text | Faster-Whisper (large-v3) |
| Text-to-Speech | Edge-TTS (Microsoft Neural voices) |
| Reasoning Cache | Redis (semantic + conversation memory) |

## Architecture

```
CareMate iOS App
      │
      ▼
FastAPI Routers (/api/*)
      │
      ├── Schedule, Medication, Diet, Guidance → MongoDB
      │
      └── Assistant / Translation
            │
            ├── STT Service (Whisper) ← audio input
            │
            ├── CrewAI Orchestrator
            │     ├── Care Coordinator Agent
            │     ├── Medical Advisor Agent
            │     ├── Diet Planner Agent
            │     └── Translation Agent
            │           │
            │           └── VLLM (Mistral-7B)
            │
            ├── Memory Cache (Redis)
            │     ├── Reasoning cache (SHA-256 keyed)
            │     ├── Conversation history (rolling 20 turns)
            │     └── Long-term care summary
            │
            └── TTS Service (Edge-TTS) → audio output
```

## Quick Start

### Prerequisites
- Docker & Docker Compose
- NVIDIA GPU (recommended for VLLM + Whisper)

### Run with Docker Compose

```bash
cp .env.example .env
docker-compose up -d
```

API available at: `http://localhost:8080`
Interactive docs: `http://localhost:8080/docs`

### Run locally (development)

```bash
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Start MongoDB and Redis separately, then:
uvicorn app.main:app --reload --port 8080
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/schedule/{user_id}` | Get daily tasks |
| POST | `/api/schedule/` | Create task |
| PATCH | `/api/schedule/{id}` | Update task status |
| GET | `/api/medication/{user_id}` | Get medications |
| POST | `/api/medication/{id}/toggle-taken` | Mark medication taken |
| GET | `/api/diet/recipes/{user_id}` | Get saved recipes |
| POST | `/api/diet/recipes/extract-from-image` | AI recipe extraction |
| GET | `/api/guidance/` | Get training modules |
| POST | `/api/assistant/chat` | AI chat (text or voice) |
| DELETE | `/api/assistant/history/{user_id}` | Clear conversation memory |
| POST | `/api/translate/text` | Translate text |
| POST | `/api/translate/audio` | Translate audio |

## Supported Languages

- English (`en`)
- Myanmar / Burmese (`my`)
- Thai (`th`)
- Arabic (`ar`)

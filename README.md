# CareMate — AI-Powered Caregiver Assistant

CareMate is a bilingual caregiver assistant for Myanmar caregivers working in Singapore.
This repository contains **two independent sub-projects**:

```
CareMate/
├── CareMate-iOS/        SwiftUI iOS application (frontend)
└── CareMate-Backend/    FastAPI backend — MongoDB · CrewAI · VLLM · STT · Memory Cache
```

---

## CareMate-iOS (SwiftUI)

Native iOS 17+ app built with **SwiftUI + MVVM + async/await**.

**Screens:** Schedule · Medication · Diet · Guidance · AI Assistant · Translate

→ [iOS README](CareMate-iOS/README.md)

---

## CareMate-Backend (FastAPI)

Production REST API backend.

| Service | Technology |
|---------|-----------|
| LLM Inference | VLLM — Mistral-7B-Instruct |
| AI Agent Orchestration | CrewAI (4 specialised agents) |
| Speech-to-Text | Faster-Whisper large-v3 |
| Text-to-Speech | Edge-TTS (Microsoft Neural) |
| Reasoning Memory Cache | Redis (semantic + conversation history) |
| Database | MongoDB (Motor async driver) |

→ [Backend README](CareMate-Backend/README.md)

---

## System Architecture

```
CareMate iOS (SwiftUI)
        │  REST API
        ▼
FastAPI Backend
  ├── MongoDB  ← schedules, medications, recipes
  ├── CrewAI   ← Care Coordinator · Medical Advisor · Diet Planner · Interpreter
  │     └── VLLM (Mistral-7B)
  ├── Faster-Whisper  ← Speech-to-Text
  ├── Edge-TTS        ← Text-to-Speech
  └── Redis           ← Reasoning cache + conversation memory
```

## Quick Start

```bash
# 1. Backend
cd CareMate-Backend && cp .env.example .env && docker-compose up -d
# API: http://localhost:8080  Docs: http://localhost:8080/docs

# 2. iOS app
cd CareMate-iOS && open CareMate.xcodeproj
```

## Supported Languages: English · Myanmar · Thai · Arabic

---

*Original web prototype (React/TypeScript) replaced by native SwiftUI + FastAPI architecture.*

This contains everything you need to run your app locally.

View your app in AI Studio: https://ai.studio/apps/7a9d2fe9-9ac7-4341-99d1-2feb3cc04299

## Run Locally

**Prerequisites:**  Node.js


1. Install dependencies:
   `npm install`
2. Set the `GEMINI_API_KEY` in [.env.local](.env.local) to your Gemini API key
3. Run the app:
   `npm run dev`

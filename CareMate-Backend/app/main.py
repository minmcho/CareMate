from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.database import connect_db, close_db
from app.routers import schedule, medication, diet, assistant, translate, guidance
from app.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()


app = FastAPI(
    title="CareMate API",
    description="AI-powered caregiver assistant backend with CrewAI, VLLM, Speech-to-Text, and reasoning memory caching",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(schedule.router, prefix="/api/schedule", tags=["Schedule"])
app.include_router(medication.router, prefix="/api/medication", tags=["Medication"])
app.include_router(diet.router, prefix="/api/diet", tags=["Diet"])
app.include_router(assistant.router, prefix="/api/assistant", tags=["Assistant"])
app.include_router(translate.router, prefix="/api/translate", tags=["Translation"])
app.include_router(guidance.router, prefix="/api/guidance", tags=["Guidance"])


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "CareMate API"}

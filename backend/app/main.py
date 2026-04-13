"""FastAPI entrypoint for VitalPath AI."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from app.api.graphql.schema import build_graphql_router
from app.api.rest import chat as chat_router
from app.api.rest import health as health_router
from app.api.rest import journal as journal_router
from app.api.rest import community as community_router
from app.core.config import get_settings
from app.core.middleware import SecurityMiddleware
from app.core.security import get_current_user
from app.services.mcp import MCPRouter

settings = get_settings()
mcp_router = MCPRouter()


@asynccontextmanager
async def lifespan(_: FastAPI):
    logger.info("VitalPath AI backend starting ({} environment)", settings.environment)
    yield
    logger.info("VitalPath AI backend shutting down")
    await mcp_router.aclose()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version="0.1.0",
        lifespan=lifespan,
        description=(
            "Safety-first wellness coaching platform. "
            "Multi-modal AI via Llama 4 (text) and Qwen 3.5 VL (vision)."
        ),
    )
    # Security middleware (rate limiting, CSRF, security headers)
    app.add_middleware(SecurityMiddleware, allowed_origins=settings.cors_origins)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health_router.router)
    app.include_router(chat_router.router)
    app.include_router(journal_router.router)
    app.include_router(community_router.router)
    app.include_router(
        build_graphql_router(mcp_router, get_current_user),
        prefix="/graphql",
    )
    return app


app = create_app()

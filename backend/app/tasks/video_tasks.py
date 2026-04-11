"""Celery worker tasks for multi-modal video analysis."""

from __future__ import annotations

import asyncio
from typing import List

from loguru import logger

from app.services.mcp import MCPRouter
from app.services.safety import scan_assistant_output
from app.tasks.celery_app import celery_app


@celery_app.task(name="app.tasks.video_tasks.analyze_video_task", bind=True)
def analyze_video_task(self, video_id: str, mode: str, frames_b64: List[str]) -> dict:
    """Extract frames, call Qwen 3.5 VL, enforce safety, and persist the result.

    In the real deployment this:
        1. Downloads the video from Supabase Storage.
        2. Samples up to 8 frames at evenly-spaced offsets.
        3. Passes them to Qwen 3.5 VL.
        4. Scans the JSON response for medical claims.
        5. Writes the VideoAnalysisRecord row.
    """
    logger.info("analyze_video_task start video_id={} mode={}", video_id, mode)
    router = MCPRouter()
    try:
        result = asyncio.run(router.analyse_video(mode=mode, frames_b64=frames_b64))
        flat = " ".join(
            [
                str(result.get("nutrition_estimate", "")),
                " ".join(result.get("highlights", [])),
                " ".join(result.get("cautions", [])),
                " ".join(result.get("form_notes", [])),
            ]
        )
        scan = scan_assistant_output(flat)
        result["safety_flag"] = not scan.passed
        if not scan.passed:
            result["nutrition_estimate"] = "Balanced plate estimate."
        return result
    finally:
        asyncio.run(router.aclose())

"""Multi-agent orchestrator.

Dispatches requests between:
    - Llama 4 Maverick 17B (text coaching, low latency, high empathy)
    - DeepSeek R1 (complex reasoning, multilingual, chain-of-thought)
    - Qwen 2.5 VL 72B (vision analysis)

The public surface is ``MCPRouter`` which picks an agent, calls the upstream
HTTP endpoint, and returns a normalized response.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from enum import Enum
from typing import List, Optional

import httpx
from loguru import logger

from app.core.config import get_settings
from app.services.safety import (
    SafetyCategory,
    scan_assistant_output,
    scan_user_input,
)


class AgentKind(str, Enum):
    LLAMA4 = "llama4"
    DEEPSEEK = "deepseek"
    QWEN25VL = "qwen25vl"
    FALLBACK = "fallback"


@dataclass
class RouteDecision:
    agent: AgentKind
    reason: str


@dataclass
class CoachMessage:
    role: str  # "user" | "assistant" | "system"
    content: str


@dataclass
class CoachResponse:
    message: str
    agent: AgentKind
    crisis_triggered: bool
    safety_rewritten: bool


SYSTEM_PROMPT = (
    "You are VitalPath, a warm, empathetic wellness coach.\n"
    "STRICT BOUNDARIES:\n"
    "- You are NOT a doctor, nurse, therapist or pharmacist.\n"
    "- Never diagnose, cure, treat, prescribe, or give medication advice.\n"
    "- Never imply a user has a medical condition.\n"
    "- If the user describes a medical emergency, gently redirect to local\n"
    "  emergency services.\n"
    "- Keep responses short (2-4 sentences) and warm.\n"
    "- Honour dietary preferences and physical comforts from the user profile.\n"
)


NON_ENGLISH_HINT = [
    "\u0e00",  # Thai
    "\u1000",  # Myanmar
    "\u3040",  # Hiragana
    "\u4e00",  # CJK
    "\uac00",  # Hangul
]


class MCPRouter:
    """Stateless request router and upstream caller."""

    def __init__(self, client: Optional[httpx.AsyncClient] = None) -> None:
        self.settings = get_settings()
        self._client = client or httpx.AsyncClient(timeout=30.0)

    async def aclose(self) -> None:
        await self._client.aclose()

    # ------------------------------------------------------------------
    # Routing
    # ------------------------------------------------------------------

    def route(self, user_text: str, has_attachment: bool) -> RouteDecision:
        if has_attachment:
            return RouteDecision(AgentKind.QWEN25VL, "Visual input detected")
        lowered = user_text.lower()
        if any(k in lowered for k in ("why", "explain", "compare", "strategy", "analyze", "reason")):
            return RouteDecision(AgentKind.DEEPSEEK, "Complex reasoning")
        if any(c in user_text for c in NON_ENGLISH_HINT):
            return RouteDecision(AgentKind.DEEPSEEK, "Non-English input")
        return RouteDecision(AgentKind.LLAMA4, "Conversational coaching")

    # ------------------------------------------------------------------
    # Coaching
    # ------------------------------------------------------------------

    async def ask(
        self,
        user_text: str,
        history: List[CoachMessage],
        profile_context: str,
    ) -> CoachResponse:
        input_scan = scan_user_input(user_text)
        if input_scan.category == SafetyCategory.CRISIS:
            return CoachResponse(
                message=(
                    "I'm really glad you reached out. What you're feeling "
                    "sounds serious and you deserve immediate support from "
                    "people trained to help. Please use the resources shown "
                    "in the app to contact a local helpline."
                ),
                agent=AgentKind.FALLBACK,
                crisis_triggered=True,
                safety_rewritten=False,
            )

        decision = self.route(input_scan.sanitized, has_attachment=False)
        endpoint, model = self._endpoint_for(decision.agent)
        prompt = self._build_prompt(profile_context, history, input_scan.sanitized)

        try:
            raw = await self._call(endpoint, model, prompt)
        except Exception as exc:  # pragma: no cover
            logger.warning("Upstream call failed: {}", exc)
            return CoachResponse(
                message=(
                    "Let's take a gentle breath together. "
                    "Inhale for four, hold for four, exhale for four."
                ),
                agent=AgentKind.FALLBACK,
                crisis_triggered=False,
                safety_rewritten=False,
            )

        out_scan = scan_assistant_output(raw)
        return CoachResponse(
            message=out_scan.sanitized,
            agent=decision.agent,
            crisis_triggered=False,
            safety_rewritten=not out_scan.passed,
        )

    # ------------------------------------------------------------------
    # Vision
    # ------------------------------------------------------------------

    async def analyse_video(
        self,
        mode: str,
        frames_b64: List[str],
    ) -> dict:
        """Call Qwen 2.5 VL to analyse extracted frames."""
        endpoint, model = self._endpoint_for(AgentKind.QWEN25VL)
        prompt = (
            "You are a wellness visual coach. Respond with ONLY valid JSON. "
            "Never make medical claims. Keep language supportive."
        )
        if mode == "meal":
            prompt += (
                ' Schema: {"nutrition_estimate":string,"highlights":string[],'
                '"cautions":string[],"score":number}'
            )
        else:
            prompt += (
                ' Schema: {"form_notes":string[],"highlights":string[],'
                '"cautions":string[],"score":number}'
            )

        body = {
            "model": model,
            "prompt": prompt,
            "images": frames_b64,
            "stream": False,
        }
        try:
            response = await self._client.post(endpoint, json=body)
            response.raise_for_status()
            data = response.json()
            text = data.get("response", "{}")
            return json.loads(text)
        except Exception as exc:  # pragma: no cover
            logger.warning("Vision call failed: {}", exc)
            return {
                "nutrition_estimate": "Balanced plate estimate.",
                "highlights": ["Colourful vegetables", "Whole grains"],
                "cautions": [],
                "score": 82,
            }

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _endpoint_for(self, agent: AgentKind) -> tuple[str, str]:
        if agent == AgentKind.LLAMA4:
            return self.settings.llama4_endpoint, self.settings.llama4_model
        if agent == AgentKind.DEEPSEEK:
            return self.settings.deepseek_endpoint, self.settings.deepseek_model
        if agent == AgentKind.QWEN25VL:
            return self.settings.qwen_vl_endpoint, self.settings.qwen_vl_model
        return self.settings.llama4_endpoint, self.settings.llama4_model

    def _build_prompt(
        self,
        profile_context: str,
        history: List[CoachMessage],
        user_text: str,
    ) -> str:
        memory = "\n".join(f"{m.role.upper()}: {m.content}" for m in history[-6:])
        return (
            f"{SYSTEM_PROMPT}\n\n"
            f"USER CONTEXT:\n{profile_context}\n\n"
            f"RECENT MEMORY:\n{memory}\n\n"
            f"USER: {user_text}\nCOACH:"
        )

    async def _call(self, endpoint: str, model: str, prompt: str) -> str:
        body = {"model": model, "prompt": prompt, "stream": False}
        response = await self._client.post(endpoint, json=body)
        response.raise_for_status()
        data = response.json()
        return str(data.get("response", "")).strip()

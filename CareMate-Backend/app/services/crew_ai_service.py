"""
CrewAI orchestration service.
Routes user queries to the appropriate specialised agent crew,
with reasoning memory caching to avoid redundant LLM calls.
"""
from crewai import Crew, Task, Process
from typing import Optional

from app.agents.care_coordinator_agent import create_care_coordinator_agent
from app.agents.medical_advisor_agent import create_medical_advisor_agent
from app.agents.diet_planner_agent import create_diet_planner_agent
from app.agents.translation_agent import create_translation_agent
from app.services.memory_cache import (
    get_cached_response,
    cache_response,
    append_to_history,
    get_history,
    get_summary,
)
from app.services.vllm_service import reason_and_generate


# ─── Intent classifier ────────────────────────────────────────────────────────

INTENT_KEYWORDS = {
    "medical": ["medication", "medicine", "symptom", "pain", "doctor", "health", "drug", "dose", "pills"],
    "diet": ["food", "meal", "eat", "recipe", "diet", "nutrition", "breakfast", "lunch", "dinner", "cook"],
    "translation": ["translate", "say in", "how do you say", "language", "myanmar", "thai", "arabic", "english"],
    "schedule": ["schedule", "task", "reminder", "appointment", "time", "when", "today", "tomorrow"],
}


def classify_intent(message: str) -> str:
    msg_lower = message.lower()
    for intent, keywords in INTENT_KEYWORDS.items():
        if any(kw in msg_lower for kw in keywords):
            return intent
    return "general"


# ─── Main orchestration ───────────────────────────────────────────────────────

async def process_message(
    user_id: str,
    message: str,
    language: str = "en",
    use_memory: bool = True,
) -> dict:
    """
    Route message to the right agent crew.
    Returns {"reply": str, "agent_used": str, "reasoning_steps": list, "memory_hit": bool}
    """
    # 1. Check reasoning cache
    if use_memory:
        cached = await get_cached_response(user_id, message, language)
        if cached:
            return {**cached, "memory_hit": True}

    # 2. Load conversation history for context
    history = await get_history(user_id)
    summary = await get_summary(user_id)
    context = summary or ""
    if history:
        context += "\n" + "\n".join(
            f"{m['role'].upper()}: {m['content']}" for m in history[-6:]
        )

    # 3. Classify intent and select crew
    intent = classify_intent(message)
    reply, agent_used, reasoning_steps = await _run_crew(intent, message, context, language)

    # 4. Store in history and cache
    await append_to_history(user_id, "user", message)
    await append_to_history(user_id, "assistant", reply)

    result = {
        "reply": reply,
        "agent_used": agent_used,
        "reasoning_steps": reasoning_steps,
        "memory_hit": False,
    }
    if use_memory:
        await cache_response(user_id, message, language, result)
    return result


async def _run_crew(intent: str, message: str, context: str, language: str) -> tuple:
    """Run the appropriate CrewAI crew and return (reply, agent_name, reasoning_steps)."""

    if intent == "medical":
        agent = create_medical_advisor_agent()
        agent_name = "Medical Advisor"
    elif intent == "diet":
        agent = create_diet_planner_agent()
        agent_name = "Diet Planner"
    elif intent == "translation":
        agent = create_translation_agent()
        agent_name = "Medical Interpreter"
    elif intent == "schedule":
        agent = create_care_coordinator_agent()
        agent_name = "Care Coordinator"
    else:
        # General query — use VLLM reasoning directly
        result = await reason_and_generate(message, context=context, language=language)
        return result["answer"], "General Assistant", [result["reasoning"]]

    task = Task(
        description=f"User query: {message}\n\nConversation context:\n{context}",
        agent=agent,
        expected_output="A helpful, clear, and accurate response to the caregiver's query.",
    )
    crew = Crew(
        agents=[agent],
        tasks=[task],
        process=Process.sequential,
        verbose=False,
    )
    result = crew.kickoff()
    return str(result), agent_name, []

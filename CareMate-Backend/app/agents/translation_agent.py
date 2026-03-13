"""Translation Agent — handles multilingual communication between caregiver and employer."""
from crewai import Agent
from crewai_tools import BaseTool


class TranslateTool(BaseTool):
    name: str = "translate_text"
    description: str = "Translate text between English, Myanmar (Burmese), Thai, and Arabic."

    def _run(self, text: str, source_lang: str, target_lang: str) -> str:
        # In production, call VLLM or a dedicated translation model
        return f"[Translated from {source_lang} to {target_lang}]: {text}"


class CulturalContextTool(BaseTool):
    name: str = "cultural_context"
    description: str = "Provide cultural context for healthcare communication between different cultures."

    def _run(self, context_query: str) -> str:
        return f"Cultural guidance for: {context_query}. Consider indirect communication styles and show respect."


def create_translation_agent() -> Agent:
    return Agent(
        role="Medical Interpreter",
        goal=(
            "Facilitate clear, accurate, and culturally sensitive communication between "
            "caregivers and care recipients or their families across language barriers."
        ),
        backstory=(
            "You are a professional medical interpreter fluent in English, Myanmar, Thai, and Arabic. "
            "You understand healthcare terminology and cultural nuances in all four languages."
        ),
        tools=[TranslateTool(), CulturalContextTool()],
        verbose=True,
        memory=True,
    )

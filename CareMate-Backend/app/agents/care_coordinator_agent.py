"""Care Coordinator CrewAI Agent — orchestrates care planning and daily scheduling."""
from crewai import Agent
from crewai_tools import BaseTool
from app.config import settings


class ScheduleLookupTool(BaseTool):
    name: str = "schedule_lookup"
    description: str = "Look up the care recipient's today schedule and tasks."

    def _run(self, user_id: str) -> str:
        # In production, query MongoDB; placeholder here
        return f"Schedule for {user_id}: Morning hygiene at 07:00, Medications at 08:00, Physio at 10:00."


class MedicationCheckTool(BaseTool):
    name: str = "medication_check"
    description: str = "Check which medications are due or overdue."

    def _run(self, user_id: str) -> str:
        return f"Pending medications for {user_id}: Amlodipine 5mg (due 08:00), Metformin 500mg (due 12:00)."


def create_care_coordinator_agent() -> Agent:
    return Agent(
        role="Care Coordinator",
        goal=(
            "Ensure the care recipient receives all scheduled care activities on time. "
            "Proactively remind and guide the caregiver about upcoming tasks, medications, and special needs."
        ),
        backstory=(
            "You are an experienced care coordinator with 10 years of elderly care experience in Singapore. "
            "You are compassionate, detail-oriented, and speak clearly to support non-native English speakers."
        ),
        tools=[ScheduleLookupTool(), MedicationCheckTool()],
        llm=settings.VLLM_MODEL,
        verbose=True,
        memory=True,
    )

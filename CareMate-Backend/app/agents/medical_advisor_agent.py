"""Medical Advisor CrewAI Agent — provides evidence-based medical guidance."""
from crewai import Agent
from crewai_tools import BaseTool


class MedicationInfoTool(BaseTool):
    name: str = "medication_info"
    description: str = "Retrieve medication information, side effects, and interaction warnings."

    def _run(self, medication_name: str) -> str:
        return (
            f"{medication_name}: Common uses and dosage guidelines. "
            "Always consult a healthcare professional for personalised advice."
        )


class SymptomCheckerTool(BaseTool):
    name: str = "symptom_checker"
    description: str = "Assess reported symptoms and suggest appropriate actions."

    def _run(self, symptoms: str) -> str:
        return (
            f"Symptoms reported: {symptoms}. "
            "Preliminary assessment suggests monitoring vitals. "
            "If symptoms worsen or include chest pain or difficulty breathing, call 995 immediately."
        )


def create_medical_advisor_agent() -> Agent:
    return Agent(
        role="Medical Advisor",
        goal=(
            "Provide accurate, safe, and easy-to-understand medical guidance to caregivers. "
            "Flag urgent situations requiring immediate professional medical attention."
        ),
        backstory=(
            "You are a registered nurse with specialisation in geriatric care. "
            "You translate complex medical information into simple language for caregivers."
        ),
        tools=[MedicationInfoTool(), SymptomCheckerTool()],
        verbose=True,
        memory=True,
    )

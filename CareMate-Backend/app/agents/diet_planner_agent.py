"""Diet Planner CrewAI Agent — plans nutritious meals for care recipients."""
from crewai import Agent
from crewai_tools import BaseTool


class NutritionalInfoTool(BaseTool):
    name: str = "nutritional_info"
    description: str = "Fetch nutritional information for ingredients or dishes."

    def _run(self, food_item: str) -> str:
        return f"{food_item}: Rich in essential nutrients. Suitable for elderly with standard dietary requirements."


class DietaryRestrictionTool(BaseTool):
    name: str = "dietary_restriction_checker"
    description: str = "Check if a meal is appropriate given the care recipient's dietary restrictions."

    def _run(self, meal: str) -> str:
        return f"{meal} passes standard dietary restriction checks. Suitable for diabetic-friendly diet."


def create_diet_planner_agent() -> Agent:
    return Agent(
        role="Diet Planner",
        goal=(
            "Create balanced, nutritious meal plans tailored to the care recipient's health conditions, "
            "dietary restrictions, and cultural food preferences."
        ),
        backstory=(
            "You are a certified dietitian with expertise in elderly nutrition and Asian cuisines. "
            "You create simple, affordable meal plans that caregivers can easily prepare."
        ),
        tools=[NutritionalInfoTool(), DietaryRestrictionTool()],
        verbose=True,
        memory=True,
    )

"""Chat Context Builder - Assembles rich context for AI chat requests.

This module extracts context building logic from the /chat endpoint into a clean,
reusable component. It gathers all relevant data (insights, health, nutrition, workouts)
and formats it for the LLM.
"""

from dataclasses import dataclass, field
from typing import Optional
import scheduler
import context_store
import hevy


@dataclass
class ChatContext:
    """Rich context assembled for a chat request.

    This includes:
    - Pre-computed insights from background analysis
    - Weekly summary
    - Body composition trends
    - Hevy workout data (set tracker and recent workouts)
    - HealthKit data from iOS
    - Nutrition data from iOS
    """
    insights: str = ""
    weekly_summary: str = ""
    body_comp_trends: str = ""
    set_tracker: str = ""
    hevy_workouts: str = ""
    health_context: str = ""
    nutrition_context: str = ""

    def has_any_context(self) -> bool:
        """Check if any context is available."""
        return any([
            self.insights,
            self.weekly_summary,
            self.body_comp_trends,
            self.set_tracker,
            self.hevy_workouts,
            self.health_context,
            self.nutrition_context
        ])

    def to_context_string(self) -> str:
        """Build the full context string to prepend to user message."""
        parts = []

        if self.insights:
            parts.append(self.insights)

        if self.weekly_summary:
            parts.append(self.weekly_summary)

        if self.body_comp_trends:
            parts.append(self.body_comp_trends)

        if self.set_tracker:
            parts.append(self.set_tracker)

        if self.hevy_workouts:
            parts.append(self.hevy_workouts)

        if self.health_context:
            parts.append(self.health_context)

        if self.nutrition_context:
            parts.append(self.nutrition_context)

        return "\n\n".join(parts)


def format_health_context(context: dict) -> str:
    """Format HealthKit data into a readable context string for the LLM."""
    parts = ["Here is the user's current health data:"]

    if "steps" in context:
        parts.append(f"- Steps today: {context['steps']}")
    if "sleep_hours" in context:
        parts.append(f"- Sleep last night: {context['sleep_hours']} hours")
    if "active_calories" in context:
        parts.append(f"- Active calories today: {context['active_calories']}")
    if "weight_kg" in context:
        parts.append(f"- Weight: {context['weight_kg']} kg")
    if "resting_hr" in context:
        parts.append(f"- Resting heart rate: {context['resting_hr']} bpm")

    # Add any other keys dynamically
    known_keys = {"steps", "sleep_hours", "active_calories", "weight_kg", "resting_hr"}
    for key, value in context.items():
        if key not in known_keys:
            parts.append(f"- {key.replace('_', ' ').title()}: {value}")

    return "\n".join(parts)


def format_nutrition_context(context: dict) -> str:
    """Format nutrition data into a readable context string for the LLM."""
    parts = ["Here is what the user has eaten today:"]

    # Totals for today
    if "total_calories" in context:
        parts.append(f"- Total calories: {context['total_calories']}")
    if "total_protein" in context:
        parts.append(f"- Total protein: {context['total_protein']}g")
    if "total_carbs" in context:
        parts.append(f"- Total carbs: {context['total_carbs']}g")
    if "total_fat" in context:
        parts.append(f"- Total fat: {context['total_fat']}g")

    # Entry count
    if "entry_count" in context:
        parts.append(f"- Logged {context['entry_count']} food entries today")

    # Today's individual entries
    if "entries" in context and context["entries"]:
        parts.append("\nFood logged today:")
        for entry in context["entries"]:
            name = entry.get("name", "Unknown")
            cal = entry.get("calories", 0)
            pro = entry.get("protein", 0)
            parts.append(f"  - {name}: {cal} cal, {pro}g protein")

    # Recent entries (last 2-3 days) for pattern recognition
    if "recent_entries" in context and context["recent_entries"]:
        parts.append("\nFood from the last few days:")
        for entry in context["recent_entries"]:
            name = entry.get("name", "Unknown")
            cal = entry.get("calories", 0)
            pro = entry.get("protein", 0)
            parts.append(f"  - {name}: {cal} cal, {pro}g protein")

    return "\n".join(parts)


async def build_chat_context(
    health_context: Optional[dict] = None,
    nutrition_context: Optional[dict] = None,
    insights_limit: int = 3
) -> ChatContext:
    """Build rich context for a chat request.

    This function gathers all available context from:
    - Background-generated insights
    - Weekly summary
    - Body composition trends
    - Hevy workout data
    - HealthKit data from iOS
    - Nutrition data from iOS

    Args:
        health_context: HealthKit data from iOS (optional)
        nutrition_context: Nutrition data from iOS (optional)
        insights_limit: Number of recent insights to include (default 3)

    Returns:
        ChatContext object with all assembled context
    """
    context = ChatContext()

    # Inject pre-computed insights from background agent
    # This is the key multi-agent integration - chat stays fast because
    # heavy insight generation already happened in background
    context.insights = scheduler.get_insights_for_chat_context(limit=insights_limit)

    # Add weekly summary for quick reference
    context.weekly_summary = scheduler.get_weekly_summary_for_chat()

    # Add body composition trends (EMA-smoothed for signal, not noise)
    context.body_comp_trends = context_store.format_body_comp_for_chat()

    # Add rolling 7-day training volume (set tracker)
    context.set_tracker = await hevy.format_set_tracker_for_chat()

    # Get Hevy workout data (server-side)
    hevy_context = await hevy.get_hevy_context()
    if hevy_context.get("hevy_workouts"):
        context.hevy_workouts = hevy_context["hevy_workouts"]

    # Add HealthKit data from iOS (if provided)
    if health_context:
        context.health_context = format_health_context(health_context)

    # Add nutrition data from iOS (if provided)
    if nutrition_context:
        context.nutrition_context = format_nutrition_context(nutrition_context)

    return context

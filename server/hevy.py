"""Hevy API integration - pulls workout data for AI context."""
import os
import httpx
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Optional

HEVY_API_BASE = "https://api.hevyapp.com/v1"


@dataclass
class HevyWorkout:
    """Summary of a Hevy workout."""
    id: str
    title: str
    date: datetime
    duration_minutes: int
    exercises: list[dict]  # [{name, sets: [{reps, weight_kg}]}]
    total_volume_kg: float


async def get_api_key() -> Optional[str]:
    """Get Hevy API key from environment."""
    return os.getenv("HEVY_API_KEY")


async def get_recent_workouts(days: int = 7, limit: int = 10) -> list[HevyWorkout]:
    """Fetch recent workouts from Hevy."""
    api_key = await get_api_key()
    if not api_key:
        return []

    headers = {
        "api-key": api_key,
        "Accept": "application/json"
    }

    # Calculate date range
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)

    params = {
        "page": 1,
        "pageSize": limit
    }

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{HEVY_API_BASE}/workouts",
                headers=headers,
                params=params,
                timeout=30.0
            )
            response.raise_for_status()
            data = response.json()

            workouts = []
            for w in data.get("workouts", []):
                # Parse exercises
                exercises = []
                total_volume = 0.0

                for ex in w.get("exercises", []):
                    sets_data = []
                    for s in ex.get("sets", []):
                        weight = s.get("weight_kg", 0) or 0
                        reps = s.get("reps", 0) or 0
                        sets_data.append({
                            "reps": reps,
                            "weight_kg": weight,
                            "weight_lbs": round(weight * 2.205, 1) if weight else 0
                        })
                        total_volume += weight * reps

                    exercises.append({
                        "name": ex.get("title", "Unknown"),
                        "sets": sets_data
                    })

                # Parse date
                start_time = w.get("start_time", "")
                try:
                    workout_date = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
                except:
                    workout_date = datetime.now()

                # Calculate duration
                duration = 0
                if w.get("end_time") and w.get("start_time"):
                    try:
                        end = datetime.fromisoformat(w["end_time"].replace("Z", "+00:00"))
                        start = datetime.fromisoformat(w["start_time"].replace("Z", "+00:00"))
                        duration = int((end - start).total_seconds() / 60)
                    except:
                        pass

                workouts.append(HevyWorkout(
                    id=w.get("id", ""),
                    title=w.get("title", "Workout"),
                    date=workout_date,
                    duration_minutes=duration,
                    exercises=exercises,
                    total_volume_kg=total_volume
                ))

            return workouts

    except Exception as e:
        print(f"Hevy API error: {e}")
        return []


def format_workout_context(workouts: list[HevyWorkout]) -> str:
    """Format workouts into a string for AI context."""
    if not workouts:
        return ""

    lines = ["Recent workouts from Hevy:"]

    for w in workouts[:5]:  # Limit to 5 most recent
        days_ago = (datetime.now(w.date.tzinfo) - w.date).days if w.date.tzinfo else (datetime.now() - w.date).days

        if days_ago == 0:
            when = "Today"
        elif days_ago == 1:
            when = "Yesterday"
        else:
            when = f"{days_ago} days ago"

        lines.append(f"\n{w.title} ({when}, {w.duration_minutes}min):")

        for ex in w.exercises[:6]:  # Limit exercises shown
            sets_summary = []
            for s in ex["sets"]:
                if s["weight_lbs"] > 0:
                    sets_summary.append(f"{s['reps']}×{s['weight_lbs']}lb")
                else:
                    sets_summary.append(f"{s['reps']} reps")

            if sets_summary:
                lines.append(f"  - {ex['name']}: {', '.join(sets_summary)}")

    return "\n".join(lines)


async def get_hevy_context() -> dict:
    """Get Hevy data formatted for API context."""
    workouts = await get_recent_workouts(days=7, limit=5)

    if not workouts:
        return {}

    # Build context dict
    context = {
        "workout_count_7d": str(len(workouts)),
        "hevy_workouts": format_workout_context(workouts)
    }

    # Add last workout summary
    if workouts:
        last = workouts[0]
        days_ago = (datetime.now(last.date.tzinfo) - last.date).days if last.date.tzinfo else (datetime.now() - last.date).days
        context["last_workout"] = f"{last.title} ({days_ago} days ago)"
        context["last_workout_exercises"] = ", ".join([e["name"] for e in last.exercises[:5]])

    return context

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
    exercises: list[dict]  # [{name, sets: [{reps, weight_kg}], notes}]
    total_volume_kg: float
    notes: str = ""  # Workout-level notes - often contain valuable subjective data
    exercise_notes: Optional[list[str]] = None  # Per-exercise notes


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

                exercise_notes = []
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

                    # Capture exercise-level notes (gold for subjective data)
                    ex_notes = ex.get("notes", "").strip()
                    exercises.append({
                        "name": ex.get("title", "Unknown"),
                        "sets": sets_data,
                        "notes": ex_notes
                    })
                    if ex_notes:
                        exercise_notes.append(f"{ex.get('title', 'Unknown')}: {ex_notes}")

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
                    total_volume_kg=total_volume,
                    notes=w.get("description", "").strip(),  # Workout-level notes
                    exercise_notes=exercise_notes if exercise_notes else None
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

        # Include workout-level notes if present (subjective data is gold)
        if w.notes:
            lines.append(f"  Notes: \"{w.notes}\"")

        for ex in w.exercises[:6]:  # Limit exercises shown
            sets_summary = []
            for s in ex["sets"]:
                if s["weight_lbs"] > 0:
                    sets_summary.append(f"{s['reps']}×{s['weight_lbs']}lb")
                else:
                    sets_summary.append(f"{s['reps']} reps")

            if sets_summary:
                ex_line = f"  - {ex['name']}: {', '.join(sets_summary)}"
                # Include exercise-level notes inline
                if ex.get("notes"):
                    ex_line += f" [{ex['notes']}]"
                lines.append(ex_line)

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


async def get_all_workouts(max_pages: int = 10) -> list[HevyWorkout]:
    """Fetch all workouts with pagination for full history.

    Used for insights - syncs complete workout history to context store.
    """
    api_key = await get_api_key()
    if not api_key:
        return []

    headers = {
        "api-key": api_key,
        "Accept": "application/json"
    }

    all_workouts = []
    page = 1

    try:
        async with httpx.AsyncClient() as client:
            while page <= max_pages:
                params = {
                    "page": page,
                    "pageSize": 20
                }

                response = await client.get(
                    f"{HEVY_API_BASE}/workouts",
                    headers=headers,
                    params=params,
                    timeout=30.0
                )
                response.raise_for_status()
                data = response.json()

                workouts_data = data.get("workouts", [])
                if not workouts_data:
                    break

                for w in workouts_data:
                    workout = _parse_workout(w)
                    if workout:
                        all_workouts.append(workout)

                # Check if there are more pages
                page_count = data.get("page_count", 1)
                if page >= page_count:
                    break
                page += 1

    except Exception as e:
        print(f"Hevy API error during full fetch: {e}")

    return all_workouts


def _parse_workout(w: dict) -> Optional[HevyWorkout]:
    """Parse a single workout from API response."""
    try:
        exercises = []
        total_volume = 0.0
        exercise_notes = []

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

            # Capture exercise-level notes
            ex_notes = ex.get("notes", "").strip()
            exercises.append({
                "name": ex.get("title", "Unknown"),
                "sets": sets_data,
                "notes": ex_notes
            })
            if ex_notes:
                exercise_notes.append(f"{ex.get('title', 'Unknown')}: {ex_notes}")

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

        return HevyWorkout(
            id=w.get("id", ""),
            title=w.get("title", "Workout"),
            date=workout_date,
            duration_minutes=duration,
            exercises=exercises,
            total_volume_kg=total_volume,
            notes=w.get("description", "").strip(),
            exercise_notes=exercise_notes if exercise_notes else None
        )
    except Exception as e:
        print(f"Error parsing workout: {e}")
        return None


def aggregate_workouts_by_day(workouts: list[HevyWorkout]) -> dict[str, dict]:
    """Aggregate workouts into daily summaries for context store.

    Returns a dict mapping date strings to workout summaries.
    """
    from collections import defaultdict

    daily = defaultdict(lambda: {
        "workout_count": 0,
        "total_duration_minutes": 0,
        "total_volume_kg": 0.0,
        "exercises": [],
        "workout_titles": []
    })

    for w in workouts:
        # Get date string
        if w.date.tzinfo:
            date_str = w.date.astimezone().strftime("%Y-%m-%d")
        else:
            date_str = w.date.strftime("%Y-%m-%d")

        daily[date_str]["workout_count"] += 1
        daily[date_str]["total_duration_minutes"] += w.duration_minutes
        daily[date_str]["total_volume_kg"] += w.total_volume_kg
        daily[date_str]["workout_titles"].append(w.title)

        # Aggregate exercise data
        for ex in w.exercises:
            total_reps = sum(s.get("reps", 0) for s in ex.get("sets", []))
            max_weight = max((s.get("weight_kg", 0) for s in ex.get("sets", [])), default=0)
            daily[date_str]["exercises"].append({
                "name": ex["name"],
                "sets": len(ex.get("sets", [])),
                "total_reps": total_reps,
                "max_weight_kg": max_weight
            })

    return dict(daily)

"""Exercise Store - Persistent storage for per-exercise strength history.

This module provides fast, low-latency access to exercise performance data
for charting strength progression over time. Data is synced hourly from
Hevy workouts and stored locally to avoid repeated API calls.

Key features:
- Per-exercise history (not per-workout)
- Estimated 1RM using Epley formula for cross-rep-range comparison
- Best performance per day (deduped)
- Top 20 exercises ranked by frequency
"""

import json
import threading
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Optional


# Storage path
DATA_DIR = Path(__file__).parent / "data"
EXERCISE_FILE = DATA_DIR / "exercise_history.json"

# Thread safety
LOCK = threading.Lock()

# In-memory cache
_cache: Optional[dict] = None
_cache_timestamp: float = 0
CACHE_TTL_SECONDS = 5.0


@dataclass
class ExercisePerformance:
    """A single day's best performance for an exercise."""
    date: str  # YYYY-MM-DD
    best_weight_lbs: float
    best_reps: int
    total_sets: int
    e1rm: float  # Estimated 1RM (Epley formula)


@dataclass
class ExerciseHistory:
    """Complete history for a single exercise."""
    performances: list[dict] = field(default_factory=list)  # List of ExercisePerformance as dicts
    current_pr: Optional[dict] = None  # {weight_lbs, reps, date, e1rm}
    workout_count: int = 0


@dataclass
class ExerciseStore:
    """The complete exercise history store."""
    exercises: dict[str, dict] = field(default_factory=dict)  # name -> ExerciseHistory as dict
    exercise_ranking: list[str] = field(default_factory=list)  # Top 20 by frequency
    last_sync: str = ""
    version: int = 1


def estimate_1rm(weight: float, reps: int) -> float:
    """Calculate estimated 1RM using Epley formula.

    Epley formula: weight × (1 + reps/30)
    This normalizes across different rep ranges for comparison.

    Args:
        weight: Weight lifted (any unit)
        reps: Number of repetitions

    Returns:
        Estimated 1RM in the same unit as input weight
    """
    if reps <= 0 or weight <= 0:
        return 0.0
    if reps == 1:
        return weight
    return round(weight * (1 + reps / 30), 1)


def _ensure_data_dir():
    """Create data directory if it doesn't exist."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)


def load_store() -> ExerciseStore:
    """Load the exercise store from disk with caching."""
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        current_time = time.time()
        if _cache is not None and (current_time - _cache_timestamp) < CACHE_TTL_SECONDS:
            return ExerciseStore(
                exercises=_cache.get("exercises", {}),
                exercise_ranking=_cache.get("exercise_ranking", []),
                last_sync=_cache.get("last_sync", ""),
                version=_cache.get("version", 1)
            )

        if not EXERCISE_FILE.exists():
            store = ExerciseStore()
            _cache = asdict(store)
            _cache_timestamp = current_time
            return store

        try:
            with open(EXERCISE_FILE) as f:
                data = json.load(f)
            _cache = data
            _cache_timestamp = current_time
            return ExerciseStore(
                exercises=data.get("exercises", {}),
                exercise_ranking=data.get("exercise_ranking", []),
                last_sync=data.get("last_sync", ""),
                version=data.get("version", 1)
            )
        except (json.JSONDecodeError, KeyError):
            store = ExerciseStore()
            _cache = asdict(store)
            _cache_timestamp = current_time
            return store


def save_store(store: ExerciseStore):
    """Save the exercise store to disk."""
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        data = {
            "exercises": store.exercises,
            "exercise_ranking": store.exercise_ranking,
            "last_sync": datetime.now().isoformat(),
            "version": store.version
        }
        with open(EXERCISE_FILE, "w") as f:
            json.dump(data, f, indent=2, default=str)

        _cache = data
        _cache_timestamp = time.time()


def upsert_performance(exercise_name: str, perf: ExercisePerformance):
    """Insert or update a performance for an exercise.

    If a performance already exists for that date, keeps the one with higher e1RM.
    Atomic: holds lock across read-modify-write.
    """
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        # Load current store
        if EXERCISE_FILE.exists():
            try:
                with open(EXERCISE_FILE) as f:
                    data = json.load(f)
                store = ExerciseStore(
                    exercises=data.get("exercises", {}),
                    exercise_ranking=data.get("exercise_ranking", []),
                    last_sync=data.get("last_sync", ""),
                    version=data.get("version", 1)
                )
            except (json.JSONDecodeError, KeyError):
                store = ExerciseStore()
        else:
            store = ExerciseStore()

        # Get or create exercise history
        if exercise_name not in store.exercises:
            store.exercises[exercise_name] = {
                "performances": [],
                "current_pr": None,
                "workout_count": 0
            }

        history = store.exercises[exercise_name]
        performances = history["performances"]

        # Check if we already have a performance for this date
        existing_idx = None
        for i, p in enumerate(performances):
            if p["date"] == perf.date:
                existing_idx = i
                break

        perf_dict = asdict(perf)

        if existing_idx is not None:
            # Keep the better performance (higher e1RM)
            if perf.e1rm > performances[existing_idx]["e1rm"]:
                performances[existing_idx] = perf_dict
        else:
            # Add new performance
            performances.append(perf_dict)
            history["workout_count"] += 1

        # Sort by date
        performances.sort(key=lambda x: x["date"])

        # Update current PR (highest e1RM ever)
        if performances:
            best = max(performances, key=lambda x: x["e1rm"])
            history["current_pr"] = {
                "weight_lbs": best["best_weight_lbs"],
                "reps": best["best_reps"],
                "date": best["date"],
                "e1rm": best["e1rm"]
            }

        store.exercises[exercise_name] = history

        # Save
        data = {
            "exercises": store.exercises,
            "exercise_ranking": store.exercise_ranking,
            "last_sync": datetime.now().isoformat(),
            "version": store.version
        }
        with open(EXERCISE_FILE, "w") as f:
            json.dump(data, f, indent=2, default=str)

        _cache = data
        _cache_timestamp = time.time()


def update_rankings():
    """Recompute the top 20 exercises by workout count.

    Call this after a batch of upserts to update the ranking.
    """
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        # Load current store
        if EXERCISE_FILE.exists():
            try:
                with open(EXERCISE_FILE) as f:
                    data = json.load(f)
                store = ExerciseStore(
                    exercises=data.get("exercises", {}),
                    exercise_ranking=data.get("exercise_ranking", []),
                    last_sync=data.get("last_sync", ""),
                    version=data.get("version", 1)
                )
            except (json.JSONDecodeError, KeyError):
                store = ExerciseStore()
        else:
            store = ExerciseStore()

        # Rank by workout count
        exercise_counts = [
            (name, hist.get("workout_count", 0))
            for name, hist in store.exercises.items()
        ]
        exercise_counts.sort(key=lambda x: x[1], reverse=True)
        store.exercise_ranking = [name for name, _ in exercise_counts[:20]]

        # Save
        data = {
            "exercises": store.exercises,
            "exercise_ranking": store.exercise_ranking,
            "last_sync": datetime.now().isoformat(),
            "version": store.version
        }
        with open(EXERCISE_FILE, "w") as f:
            json.dump(data, f, indent=2, default=str)

        _cache = data
        _cache_timestamp = time.time()


def get_top_exercises(
    n: int = 20,
    sort_by: str = "frequency",
    days: Optional[int] = None
) -> list[dict]:
    """Get the top N exercises with sorting and time window options.

    Args:
        n: Number of exercises to return
        sort_by: "frequency" (default), "most_improved", "least_improved"
        days: Time window in days (30, 90, 180, 365, None for all time)

    Returns:
        List of {name, workout_count, current_pr, recent_trend, improvement}
    """
    store = load_store()

    # Calculate cutoff date for time window
    cutoff = None
    if days:
        cutoff = (date.today() - timedelta(days=days)).isoformat()

    result = []
    for name, history in store.exercises.items():
        performances = history.get("performances", [])

        # Filter by time window
        if cutoff:
            performances = [p for p in performances if p["date"] >= cutoff]

        if not performances:
            continue

        # Calculate improvement (trend) within time window
        improvement = _calculate_improvement(performances)

        # Get last 8 performances for mini sparkline (within window)
        recent = performances[-8:] if performances else []
        recent_trend = [p["e1rm"] for p in recent]

        # Workout count within time window
        workout_count = len(performances)

        # Best PR within time window
        if performances:
            best = max(performances, key=lambda x: x["e1rm"])
            current_pr = {
                "weight_lbs": best["best_weight_lbs"],
                "reps": best["best_reps"],
                "date": best["date"],
                "e1rm": best["e1rm"]
            }
        else:
            current_pr = history.get("current_pr")

        result.append({
            "name": name,
            "workout_count": workout_count,
            "current_pr": current_pr,
            "recent_trend": recent_trend,
            "improvement": improvement  # lbs per month
        })

    # Sort based on criteria
    if sort_by == "most_improved":
        # Highest improvement first, filter out None
        result = [r for r in result if r["improvement"] is not None]
        result.sort(key=lambda x: x["improvement"], reverse=True)
    elif sort_by == "least_improved":
        # Lowest improvement first (including negative = declining)
        result = [r for r in result if r["improvement"] is not None]
        result.sort(key=lambda x: x["improvement"])
    else:  # frequency (default)
        result.sort(key=lambda x: x["workout_count"], reverse=True)

    return result[:n]


def _calculate_improvement(performances: list[dict]) -> Optional[float]:
    """Calculate improvement rate (lbs e1RM per month) using linear regression.

    Returns None if not enough data points or insufficient time span.
    Requires:
    - Minimum 5 data points for statistical reliability
    - Minimum 14 days span to avoid noise from short-term fluctuations
    """
    # Require minimum 5 data points for meaningful trend
    if len(performances) < 5:
        return None

    # Simple linear regression on e1RM values
    n = len(performances)

    # Convert dates to days since first
    try:
        first_date = datetime.strptime(performances[0]["date"], "%Y-%m-%d")
        last_date = datetime.strptime(performances[-1]["date"], "%Y-%m-%d")

        # Require minimum 14-day span to avoid short-term noise
        if (last_date - first_date).days < 14:
            return None

        x_values = [
            (datetime.strptime(p["date"], "%Y-%m-%d") - first_date).days
            for p in performances
        ]
    except (ValueError, KeyError):
        return None

    y_values = [p["e1rm"] for p in performances]

    # Calculate slope (change per day)
    x_mean = sum(x_values) / n
    y_mean = sum(y_values) / n

    numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_values, y_values))
    denominator = sum((x - x_mean) ** 2 for x in x_values)

    if denominator == 0:
        return None

    slope_per_day = numerator / denominator
    # Convert to lbs per month (30 days)
    return round(slope_per_day * 30, 1)


def get_exercise_chart_data(exercise_name: str, days: int = 365) -> dict:
    """Get performance history for a specific exercise for charting.

    Args:
        exercise_name: Name of the exercise
        days: Number of days to include (None for all time)

    Returns:
        {
            "exercise": str,
            "history": [{date, e1rm, weight_lbs, reps}, ...],
            "current_pr": {weight_lbs, reps, date, e1rm},
            "trend": float (lbs per month)
        }
    """
    store = load_store()

    if exercise_name not in store.exercises:
        return {
            "exercise": exercise_name,
            "history": [],
            "current_pr": None,
            "trend": None
        }

    history = store.exercises[exercise_name]
    performances = history.get("performances", [])

    # Filter by date range
    if days:
        cutoff = (date.today() - timedelta(days=days)).isoformat()
        performances = [p for p in performances if p["date"] >= cutoff]

    # Build history for chart
    chart_history = [
        {
            "date": p["date"],
            "e1rm": p["e1rm"],
            "weight_lbs": p["best_weight_lbs"],
            "reps": p["best_reps"]
        }
        for p in performances
    ]

    # Calculate trend (lbs per month) using linear regression
    trend = None
    if len(performances) >= 3:
        # Simple linear regression on e1RM values
        n = len(performances)

        # Convert dates to days since first
        first_date = datetime.strptime(performances[0]["date"], "%Y-%m-%d")
        x_values = [
            (datetime.strptime(p["date"], "%Y-%m-%d") - first_date).days
            for p in performances
        ]
        y_values = [p["e1rm"] for p in performances]

        # Calculate slope (change per day)
        x_mean = sum(x_values) / n
        y_mean = sum(y_values) / n

        numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(x_values, y_values))
        denominator = sum((x - x_mean) ** 2 for x in x_values)

        if denominator > 0:
            slope_per_day = numerator / denominator
            # Convert to lbs per month (30 days)
            trend = round(slope_per_day * 30, 1)

    return {
        "exercise": exercise_name,
        "history": chart_history,
        "current_pr": history.get("current_pr"),
        "trend": trend
    }


def get_last_sync_date() -> Optional[str]:
    """Get the date of the last sync (for incremental sync)."""
    store = load_store()
    return store.last_sync if store.last_sync else None


def clear_store():
    """Clear all exercise history (for testing/reset)."""
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        store = ExerciseStore()
        data = asdict(store)
        with open(EXERCISE_FILE, "w") as f:
            json.dump(data, f, indent=2)

        _cache = data
        _cache_timestamp = time.time()


def process_workout_for_exercises(workout_date: str, exercises: list[dict]):
    """Process a workout's exercises and update the exercise store.

    This is the main entry point for syncing Hevy workout data.

    Args:
        workout_date: ISO date string (YYYY-MM-DD)
        exercises: List of exercise dicts from Hevy:
            [{name, sets: [{reps, weight_kg, weight_lbs}], ...}]
    """
    for exercise in exercises:
        name = exercise.get("name", "")
        if not name:
            continue

        sets = exercise.get("sets", [])
        if not sets:
            continue

        # Find the best set (highest e1RM)
        best_weight = 0
        best_reps = 0
        best_e1rm = 0

        for s in sets:
            weight = s.get("weight_lbs", 0) or (s.get("weight_kg", 0) * 2.205)
            reps = s.get("reps", 0)

            if weight > 0 and reps > 0:
                e1rm = estimate_1rm(weight, reps)
                if e1rm > best_e1rm:
                    best_weight = weight
                    best_reps = reps
                    best_e1rm = e1rm

        if best_e1rm > 0:
            perf = ExercisePerformance(
                date=workout_date,
                best_weight_lbs=round(best_weight, 1),
                best_reps=best_reps,
                total_sets=len(sets),
                e1rm=best_e1rm
            )
            upsert_performance(name, perf)

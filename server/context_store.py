"""Context Store - Daily aggregate storage for AI context.

ARCHITECTURE NOTE (read before modifying):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- iOS device owns GRANULAR nutrition entries (individual meals in SwiftData)
- Server receives DAILY AGGREGATES only (totals per day)
- This is intentional for Raspberry Pi storage efficiency (~2KB/day)
- DO NOT add per-meal storage here - that stays on device
- See server/ARCHITECTURE.md for full data ownership model
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is the foundation of the AI-native insights system. It stores:
- Daily snapshots of all metrics (nutrition, health, workouts)
- Historical data for pattern analysis
- Indexed for fast temporal queries

Design principle: Store daily aggregates. Device keeps granular.
If server data is lost, device can re-sync. Granular stays safe on device.
"""

import json
import os
from dataclasses import dataclass, field, asdict
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Optional
import threading
import time


# Storage path (same directory as profile data)
DATA_DIR = Path(__file__).parent / "data"
CONTEXT_FILE = DATA_DIR / "context_store.json"

# Single lock protects BOTH file I/O AND cache access
# This prevents race conditions in load-modify-save cycles
LOCK = threading.Lock()

# In-memory cache to avoid blocking async event loop
_cache: Optional["ContextStore"] = None
_cache_timestamp: float = 0
CACHE_TTL_SECONDS = 5.0  # Cache for 5 seconds to avoid repeated file I/O


@dataclass
class NutritionSnapshot:
    """Daily nutrition summary."""
    calories: int = 0
    protein: int = 0
    carbs: int = 0
    fat: int = 0
    entry_count: int = 0

    # Derived metrics (computed on aggregation)
    protein_per_lb: Optional[float] = None  # If weight known
    caloric_balance: Optional[int] = None   # intake - TDEE estimate


@dataclass
class HealthSnapshot:
    """Daily health metrics from HealthKit."""
    steps: int = 0
    active_calories: int = 0

    # Body composition
    weight_lbs: Optional[float] = None
    body_fat_pct: Optional[float] = None
    lean_mass_lbs: Optional[float] = None

    # Recovery metrics
    sleep_hours: Optional[float] = None
    resting_hr: Optional[int] = None
    hrv_ms: Optional[float] = None  # Heart rate variability

    # Performance
    vo2_max: Optional[float] = None

    # Recovery metrics (Phase 1: HealthKit Dashboard Expansion)
    sleep_efficiency: Optional[float] = None     # 0.0-1.0, time asleep / time in bed
    sleep_deep_pct: Optional[float] = None       # Proportion of deep sleep (0.0-1.0)
    sleep_core_pct: Optional[float] = None       # Proportion of core/light sleep (0.0-1.0)
    sleep_rem_pct: Optional[float] = None        # Proportion of REM sleep (0.0-1.0)
    sleep_onset_minutes: Optional[int] = None    # Minutes from midnight (for bedtime tracking)
    hrv_baseline_ms: Optional[float] = None      # 7-day rolling mean HRV
    hrv_deviation_pct: Optional[float] = None    # Today's deviation from baseline (%)
    bedtime_consistency: Optional[str] = None    # "stable", "variable", or "irregular"

    # Data quality (Phase 2: Data Quality Filtering)
    quality_score: Optional[float] = None        # 0.0-1.0 overall quality
    quality_flags: list[str] = field(default_factory=list)  # Quality issue flags
    is_baseline_excluded: bool = False           # Exclude from baseline calculations


@dataclass
class WorkoutSnapshot:
    """Daily workout summary from Hevy."""
    workout_count: int = 0
    total_duration_minutes: int = 0
    total_volume_kg: float = 0.0

    # Exercise details (for pattern analysis)
    exercises: list[dict] = field(default_factory=list)
    # Each: {name, sets, total_reps, max_weight_kg}

    # Workout metadata
    workout_titles: list[str] = field(default_factory=list)


@dataclass
class DailySnapshot:
    """Complete snapshot of all data for a single day.

    This is the atomic unit of the context store.
    One per day, updated as new data comes in.
    """
    date: str  # ISO format: YYYY-MM-DD

    # Data sources
    nutrition: NutritionSnapshot = field(default_factory=NutritionSnapshot)
    health: HealthSnapshot = field(default_factory=HealthSnapshot)
    workout: WorkoutSnapshot = field(default_factory=WorkoutSnapshot)

    # Metadata
    last_updated: str = ""  # ISO timestamp
    sources_synced: list[str] = field(default_factory=list)  # ["nutrition", "health", "hevy"]

    def __post_init__(self):
        if not self.last_updated:
            self.last_updated = datetime.now().isoformat()


@dataclass
class Insight:
    """An AI-generated insight about the user's data.

    Insights are the primary output of the system.
    They represent what the AI thinks is worth knowing.
    """
    id: str
    created_at: str

    # Classification
    category: str  # correlation, trend, anomaly, milestone, nudge
    tier: int      # 1-5 priority (1 = highest value)

    # Content
    title: str
    body: str
    supporting_data: dict = field(default_factory=dict)

    # Scoring (0-1)
    importance: float = 0.5
    confidence: float = 0.5
    novelty: float = 1.0
    actionability: float = 0.5

    # Actions
    suggested_actions: list[str] = field(default_factory=list)
    conversation_context: str = ""  # For "tell me more"

    # Lifecycle
    surfaced_at: Optional[str] = None
    engagement: Optional[str] = None  # viewed, tapped, dismissed, acted
    dismissed_at: Optional[str] = None
    user_feedback: Optional[str] = None  # agree, disagree, not_relevant


@dataclass
class ContextStore:
    """The unified context store.

    Contains all daily snapshots and generated insights.
    """
    snapshots: dict[str, dict] = field(default_factory=dict)  # date -> DailySnapshot as dict
    insights: list[dict] = field(default_factory=list)

    # Metadata
    last_sync: str = ""
    version: int = 1


def _ensure_data_dir():
    """Create data directory if it doesn't exist."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)


def load_store() -> ContextStore:
    """Load the context store from disk with in-memory caching.

    Uses a short-lived (5 second) in-memory cache to avoid blocking the async
    event loop on every request. The cache is invalidated on every save_store().

    Lock covers both cache access AND file I/O to prevent race conditions.
    """
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        # Check cache inside lock to prevent races
        current_time = time.time()
        if _cache is not None and (current_time - _cache_timestamp) < CACHE_TTL_SECONDS:
            return _cache

        if not CONTEXT_FILE.exists():
            store = ContextStore()
            _cache = store
            _cache_timestamp = current_time
            return store

        try:
            with open(CONTEXT_FILE) as f:
                data = json.load(f)
            store = ContextStore(
                snapshots=data.get("snapshots", {}),
                insights=data.get("insights", []),
                last_sync=data.get("last_sync", ""),
                version=data.get("version", 1)
            )
            _cache = store
            _cache_timestamp = current_time
            return store
        except (json.JSONDecodeError, KeyError):
            store = ContextStore()
            _cache = store
            _cache_timestamp = current_time
            return store


def save_store(store: ContextStore):
    """Save the context store to disk and invalidate cache."""
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        data = {
            "snapshots": store.snapshots,
            "insights": store.insights,
            "last_sync": datetime.now().isoformat(),
            "version": store.version
        }
        with open(CONTEXT_FILE, "w") as f:
            json.dump(data, f, indent=2, default=str)

        # Invalidate cache after write
        _cache = store
        _cache_timestamp = time.time()


def get_snapshot(date_str: str) -> Optional[DailySnapshot]:
    """Get a snapshot for a specific date."""
    store = load_store()
    data = store.snapshots.get(date_str)
    if not data:
        return None

    return DailySnapshot(
        date=data.get("date", date_str),
        nutrition=NutritionSnapshot(**data.get("nutrition", {})),
        health=HealthSnapshot(**data.get("health", {})),
        workout=WorkoutSnapshot(**data.get("workout", {})),
        last_updated=data.get("last_updated", ""),
        sources_synced=data.get("sources_synced", [])
    )


def upsert_snapshot(snapshot: DailySnapshot):
    """Insert or update a daily snapshot.

    Atomic: holds lock across load-modify-save to prevent race conditions.
    """
    global _cache, _cache_timestamp

    _ensure_data_dir()

    # Convert to dict for storage
    snapshot_dict = {
        "date": snapshot.date,
        "nutrition": asdict(snapshot.nutrition),
        "health": asdict(snapshot.health),
        "workout": asdict(snapshot.workout),
        "last_updated": datetime.now().isoformat(),
        "sources_synced": snapshot.sources_synced
    }

    with LOCK:
        # Load current store (bypass cache since we're modifying)
        if CONTEXT_FILE.exists():
            try:
                with open(CONTEXT_FILE) as f:
                    data = json.load(f)
                store = ContextStore(
                    snapshots=data.get("snapshots", {}),
                    insights=data.get("insights", []),
                    last_sync=data.get("last_sync", ""),
                    version=data.get("version", 1)
                )
            except (json.JSONDecodeError, KeyError):
                store = ContextStore()
        else:
            store = ContextStore()

        # Modify
        store.snapshots[snapshot.date] = snapshot_dict

        # Save
        data = {
            "snapshots": store.snapshots,
            "insights": store.insights,
            "last_sync": datetime.now().isoformat(),
            "version": store.version
        }
        with open(CONTEXT_FILE, "w") as f:
            json.dump(data, f, indent=2, default=str)

        # Update cache
        _cache = store
        _cache_timestamp = time.time()


def _atomic_update_snapshot(date_str: str, field: str, value, source_tag: str):
    """Atomically update a single field in a snapshot.

    Holds lock across read-modify-write to prevent race conditions.
    """
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        # Load current store
        if CONTEXT_FILE.exists():
            try:
                with open(CONTEXT_FILE) as f:
                    data = json.load(f)
                store = ContextStore(
                    snapshots=data.get("snapshots", {}),
                    insights=data.get("insights", []),
                    last_sync=data.get("last_sync", ""),
                    version=data.get("version", 1)
                )
            except (json.JSONDecodeError, KeyError):
                store = ContextStore()
        else:
            store = ContextStore()

        # Get or create snapshot for this date
        existing = store.snapshots.get(date_str, {})
        sources = existing.get("sources_synced", [])
        if source_tag not in sources:
            sources.append(source_tag)

        # Update only the specified field
        snapshot_dict = {
            "date": date_str,
            "nutrition": existing.get("nutrition", asdict(NutritionSnapshot())),
            "health": existing.get("health", asdict(HealthSnapshot())),
            "workout": existing.get("workout", asdict(WorkoutSnapshot())),
            "last_updated": datetime.now().isoformat(),
            "sources_synced": sources
        }
        snapshot_dict[field] = asdict(value)

        store.snapshots[date_str] = snapshot_dict

        # Save
        data = {
            "snapshots": store.snapshots,
            "insights": store.insights,
            "last_sync": datetime.now().isoformat(),
            "version": store.version
        }
        with open(CONTEXT_FILE, "w") as f:
            json.dump(data, f, indent=2, default=str)

        # Update cache
        _cache = store
        _cache_timestamp = time.time()


def update_nutrition(date_str: str, nutrition: NutritionSnapshot):
    """Update just the nutrition data for a date (atomic)."""
    _atomic_update_snapshot(date_str, "nutrition", nutrition, "nutrition")


def update_health(date_str: str, health: HealthSnapshot):
    """Update just the health data for a date (atomic)."""
    _atomic_update_snapshot(date_str, "health", health, "health")


def update_workout(date_str: str, workout: WorkoutSnapshot):
    """Update just the workout data for a date (atomic)."""
    _atomic_update_snapshot(date_str, "workout", workout, "hevy")


def get_snapshots_range(start_date: str, end_date: str) -> list[DailySnapshot]:
    """Get all snapshots in a date range (inclusive)."""
    store = load_store()

    start = datetime.strptime(start_date, "%Y-%m-%d").date()
    end = datetime.strptime(end_date, "%Y-%m-%d").date()

    snapshots = []
    current = start
    while current <= end:
        date_str = current.isoformat()
        if date_str in store.snapshots:
            data = store.snapshots[date_str]
            snapshots.append(DailySnapshot(
                date=data.get("date", date_str),
                nutrition=NutritionSnapshot(**data.get("nutrition", {})),
                health=HealthSnapshot(**data.get("health", {})),
                workout=WorkoutSnapshot(**data.get("workout", {})),
                last_updated=data.get("last_updated", ""),
                sources_synced=data.get("sources_synced", [])
            ))
        current += timedelta(days=1)

    return snapshots


def get_recent_snapshots(days: int = 90) -> list[DailySnapshot]:
    """Get snapshots for the last N days."""
    end_date = date.today().isoformat()
    start_date = (date.today() - timedelta(days=days)).isoformat()
    return get_snapshots_range(start_date, end_date)


# --- Insight Management ---

def add_insight(insight: Insight):
    """Add a new insight to the store.

    Atomic: holds lock across load-modify-save to prevent race conditions.
    """
    global _cache, _cache_timestamp

    _ensure_data_dir()

    with LOCK:
        # Load current store
        if CONTEXT_FILE.exists():
            try:
                with open(CONTEXT_FILE) as f:
                    data = json.load(f)
                store = ContextStore(
                    snapshots=data.get("snapshots", {}),
                    insights=data.get("insights", []),
                    last_sync=data.get("last_sync", ""),
                    version=data.get("version", 1)
                )
            except (json.JSONDecodeError, KeyError):
                store = ContextStore()
        else:
            store = ContextStore()

        # Modify
        store.insights.append(asdict(insight))

        # Save
        data = {
            "snapshots": store.snapshots,
            "insights": store.insights,
            "last_sync": datetime.now().isoformat(),
            "version": store.version
        }
        with open(CONTEXT_FILE, "w") as f:
            json.dump(data, f, indent=2, default=str)

        # Update cache
        _cache = store
        _cache_timestamp = time.time()


def get_insights(
    category: Optional[str] = None,
    tier: Optional[int] = None,
    limit: int = 20,
    include_dismissed: bool = False
) -> list[Insight]:
    """Get insights, optionally filtered."""
    store = load_store()

    insights = []
    for data in store.insights:
        # Filter by category
        if category and data.get("category") != category:
            continue
        # Filter by tier
        if tier and data.get("tier") != tier:
            continue
        # Filter dismissed
        if not include_dismissed and data.get("dismissed_at"):
            continue

        insights.append(Insight(**data))

    # Sort by importance * confidence, newest first
    insights.sort(
        key=lambda i: (i.importance * i.confidence, i.created_at),
        reverse=True
    )

    return insights[:limit]


def update_insight_engagement(insight_id: str, engagement: str, feedback: Optional[str] = None):
    """Update engagement tracking for an insight."""
    store = load_store()

    for insight_data in store.insights:
        if insight_data.get("id") == insight_id:
            insight_data["engagement"] = engagement
            insight_data["surfaced_at"] = insight_data.get("surfaced_at") or datetime.now().isoformat()
            if engagement == "dismissed":
                insight_data["dismissed_at"] = datetime.now().isoformat()
            if feedback:
                insight_data["user_feedback"] = feedback
            break

    save_store(store)


def get_insight_by_id(insight_id: str) -> Optional[Insight]:
    """Get a specific insight by ID."""
    store = load_store()

    for insight_data in store.insights:
        if insight_data.get("id") == insight_id:
            return Insight(**insight_data)

    return None


def get_recent_insight_titles(limit: int = 20) -> list[str]:
    """Get titles of recent insights for deduplication."""
    insights = get_insights(limit=limit, include_dismissed=True)
    return [i.title for i in insights]


# --- Aggregation Helpers ---

def compute_averages(snapshots: list[DailySnapshot]) -> dict:
    """Compute averages from a list of snapshots."""
    if not snapshots:
        return {}

    # Nutrition
    total_calories = sum(s.nutrition.calories for s in snapshots)
    total_protein = sum(s.nutrition.protein for s in snapshots)
    total_carbs = sum(s.nutrition.carbs for s in snapshots)
    total_fat = sum(s.nutrition.fat for s in snapshots)

    # Count days with data
    nutrition_days = sum(1 for s in snapshots if s.nutrition.calories > 0)

    # Health (only count days with data)
    weights = [s.health.weight_lbs for s in snapshots if s.health.weight_lbs]
    sleeps = [s.health.sleep_hours for s in snapshots if s.health.sleep_hours]
    steps_list = [s.health.steps for s in snapshots if s.health.steps > 0]

    # Workouts
    total_workouts = sum(s.workout.workout_count for s in snapshots)
    total_volume = sum(s.workout.total_volume_kg for s in snapshots)

    return {
        "period_days": len(snapshots),
        "nutrition_days": nutrition_days,

        # Nutrition averages
        "avg_calories": round(total_calories / nutrition_days) if nutrition_days else 0,
        "avg_protein": round(total_protein / nutrition_days) if nutrition_days else 0,
        "avg_carbs": round(total_carbs / nutrition_days) if nutrition_days else 0,
        "avg_fat": round(total_fat / nutrition_days) if nutrition_days else 0,

        # Health
        "avg_weight": round(sum(weights) / len(weights), 1) if weights else None,
        "weight_change": round(weights[-1] - weights[0], 1) if len(weights) >= 2 else None,
        "avg_sleep": round(sum(sleeps) / len(sleeps), 1) if sleeps else None,
        "avg_steps": round(sum(steps_list) / len(steps_list)) if steps_list else 0,

        # Workouts
        "total_workouts": total_workouts,
        "avg_volume_per_workout": round(total_volume / total_workouts, 1) if total_workouts else 0,
    }


def compute_compliance(snapshots: list[DailySnapshot], protein_target: int = 160, calorie_target: int = 2200) -> dict:
    """Compute compliance rates for targets."""
    if not snapshots:
        return {}

    nutrition_days = [s for s in snapshots if s.nutrition.calories > 0]
    if not nutrition_days:
        return {}

    # Protein: within 90% of target
    protein_hits = sum(1 for s in nutrition_days if s.nutrition.protein >= protein_target * 0.9)

    # Calories: within 90-110% of target
    calorie_hits = sum(
        1 for s in nutrition_days
        if calorie_target * 0.9 <= s.nutrition.calories <= calorie_target * 1.1
    )

    return {
        "days_tracked": len(nutrition_days),
        "protein_compliance": round(protein_hits / len(nutrition_days), 2),
        "calorie_compliance": round(calorie_hits / len(nutrition_days), 2),
        "protein_hits": protein_hits,
        "calorie_hits": calorie_hits,
    }


def compute_ema(values: list[float], period: int) -> list[float]:
    """Compute Exponential Moving Average for a list of values.

    Args:
        values: List of values (must be in chronological order)
        period: EMA period (higher = smoother)

    Returns:
        List of EMA values, same length as input
    """
    if not values or period <= 0:
        return values

    k = 2.0 / (period + 1)
    ema_values = []
    ema = values[0]

    for value in values:
        ema = (value * k) + (ema * (1 - k))
        ema_values.append(ema)

    return ema_values


def compute_body_comp_trends() -> dict:
    """Compute EMA-smoothed body composition trends for chat context.

    Returns trends over different time periods:
    - Monthly (30 days): 10-day EMA
    - Yearly (365 days): 21-day EMA

    Each trend includes:
    - Current smoothed value
    - Change over the period
    - Direction (gaining/losing/stable)
    """
    trends = {
        "monthly": {},
        "yearly": {},
    }

    # Get data for each period
    for period_name, days, ema_period in [("monthly", 30, 10), ("yearly", 365, 21)]:
        snapshots = get_recent_snapshots(days)
        if not snapshots:
            continue

        # Extract weight data (chronological order - oldest first)
        weights = [(s.date, s.health.weight_lbs) for s in reversed(snapshots) if s.health.weight_lbs]
        body_fats = [(s.date, s.health.body_fat_pct) for s in reversed(snapshots) if s.health.body_fat_pct]

        period_trends = {}

        # Weight trend
        if len(weights) >= 3:
            weight_values = [w[1] for w in weights]
            ema_weights = compute_ema(weight_values, ema_period)

            current_ema = ema_weights[-1]
            start_ema = ema_weights[0] if len(ema_weights) > ema_period else weight_values[0]
            change = current_ema - start_ema

            period_trends["weight"] = {
                "current": round(current_ema, 1),
                "change": round(change, 1),
                "direction": "losing" if change < -0.5 else ("gaining" if change > 0.5 else "stable"),
                "readings": len(weights),
            }

        # Body fat trend
        if len(body_fats) >= 3:
            bf_values = [bf[1] for bf in body_fats]
            ema_bf = compute_ema(bf_values, ema_period)

            current_ema = ema_bf[-1]
            start_ema = ema_bf[0] if len(ema_bf) > ema_period else bf_values[0]
            change = current_ema - start_ema

            period_trends["body_fat"] = {
                "current": round(current_ema, 1),
                "change": round(change, 1),
                "direction": "losing" if change < -0.3 else ("gaining" if change > 0.3 else "stable"),
                "readings": len(body_fats),
            }

            # Calculate lean mass if we have both weight and body fat
            if "weight" in period_trends:
                current_weight = period_trends["weight"]["current"]
                current_bf = period_trends["body_fat"]["current"]
                lean_mass = current_weight * (1 - current_bf / 100)

                # Estimate lean mass change
                if len(weights) >= 3 and len(body_fats) >= 3:
                    # Use first values to estimate starting lean mass
                    start_weight = weight_values[0]
                    start_bf = bf_values[0]
                    start_lean = start_weight * (1 - start_bf / 100)
                    lean_change = lean_mass - start_lean

                    period_trends["lean_mass"] = {
                        "current": round(lean_mass, 1),
                        "change": round(lean_change, 1),
                        "direction": "gaining" if lean_change > 0.5 else ("losing" if lean_change < -0.5 else "stable"),
                    }

        trends[period_name] = period_trends

    return trends


def format_body_comp_for_chat() -> str:
    """Format body composition trends for chat context.

    Returns a concise string describing weight/body fat/lean mass trends
    that can be injected into the chat prompt.
    """
    trends = compute_body_comp_trends()

    parts = []

    # Monthly trends (most relevant for coaching)
    monthly = trends.get("monthly", {})
    if monthly:
        monthly_parts = []

        if "weight" in monthly:
            w = monthly["weight"]
            if w["change"] != 0:
                monthly_parts.append(f"weight {w['direction']} ({w['change']:+.1f}lbs, now {w['current']}lbs)")

        if "body_fat" in monthly:
            bf = monthly["body_fat"]
            if bf["change"] != 0:
                monthly_parts.append(f"body fat {bf['direction']} ({bf['change']:+.1f}%, now {bf['current']}%)")

        if "lean_mass" in monthly:
            lm = monthly["lean_mass"]
            if lm["change"] != 0:
                monthly_parts.append(f"lean mass {lm['direction']} ({lm['change']:+.1f}lbs)")

        if monthly_parts:
            parts.append(f"Monthly body comp trends: {', '.join(monthly_parts)}")

    # Yearly trends (bigger picture)
    yearly = trends.get("yearly", {})
    if yearly and yearly.get("weight"):
        w = yearly["weight"]
        if abs(w["change"]) >= 2:  # Only mention if significant
            parts.append(f"Yearly trend: {w['change']:+.1f}lbs over the year")

    return "\n".join(parts) if parts else ""

"""Background Scheduler - Multi-agent coordination for async AI tasks.

This module manages background AI work:
1. Insight generation (runs periodically, not blocking chat)
2. Pattern detection (analyzes behavior async)
3. Hevy sync (keeps workout data fresh)

The chat agent stays fast because heavy lifting happens here.
"""

import asyncio
import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional
from dataclasses import dataclass, asdict
import threading

import context_store
import insight_engine
import hevy
import profile as profile_module

# State file for scheduler persistence
DATA_DIR = Path(__file__).parent / "data"
SCHEDULER_STATE_FILE = DATA_DIR / "scheduler_state.json"


@dataclass
class SchedulerState:
    """Tracks what the background agents have done."""
    last_insight_generation: Optional[str] = None  # ISO timestamp
    last_hevy_sync: Optional[str] = None
    last_pattern_analysis: Optional[str] = None

    insights_generated_today: int = 0
    is_generating: bool = False
    generation_error: Optional[str] = None

    # Config
    insight_generation_interval_hours: int = 6
    hevy_sync_interval_hours: int = 1

    def to_dict(self) -> dict:
        return asdict(self)


def load_scheduler_state() -> SchedulerState:
    """Load scheduler state from disk."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    if not SCHEDULER_STATE_FILE.exists():
        return SchedulerState()

    try:
        with open(SCHEDULER_STATE_FILE) as f:
            data = json.load(f)
        return SchedulerState(**data)
    except (json.JSONDecodeError, TypeError):
        return SchedulerState()


def save_scheduler_state(state: SchedulerState):
    """Save scheduler state to disk."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(SCHEDULER_STATE_FILE, 'w') as f:
        json.dump(state.to_dict(), f, indent=2)


# --- Background Tasks ---

async def run_insight_generation(force: bool = False) -> dict:
    """Run insight generation in background.

    Returns status dict for logging/monitoring.
    """
    state = load_scheduler_state()

    # Check if already running
    if state.is_generating and not force:
        return {"status": "already_running", "started_at": state.last_insight_generation}

    # Check if too recent (unless forced)
    if not force and state.last_insight_generation:
        last_gen = datetime.fromisoformat(state.last_insight_generation)
        hours_since = (datetime.now() - last_gen).total_seconds() / 3600
        if hours_since < state.insight_generation_interval_hours:
            return {
                "status": "skipped",
                "reason": f"Last generation was {hours_since:.1f}h ago",
                "next_run_in_hours": state.insight_generation_interval_hours - hours_since
            }

    # Mark as generating
    state.is_generating = True
    state.generation_error = None
    save_scheduler_state(state)

    try:
        print("[Scheduler] Starting background insight generation...")

        # Get profile for context
        user_profile = profile_module.load_profile()
        profile_dict = {
            "goals": user_profile.goals,
            "constraints": user_profile.constraints,
            "preferences": user_profile.preferences,
            "protein_target": user_profile.training_day_targets.get("protein", 160),
            "calorie_target": user_profile.training_day_targets.get("calories", 2200),
        }

        # Generate insights (this calls the CLI - can take 10-30s)
        insights = await insight_engine.generate_insights(
            days=90,
            profile=profile_dict,
            force_refresh=force
        )

        # Update state
        state.is_generating = False
        state.last_insight_generation = datetime.now().isoformat()
        state.insights_generated_today += len(insights)
        save_scheduler_state(state)

        print(f"[Scheduler] Generated {len(insights)} insights")

        return {
            "status": "success",
            "insights_generated": len(insights),
            "timestamp": state.last_insight_generation
        }

    except Exception as e:
        state.is_generating = False
        state.generation_error = str(e)
        save_scheduler_state(state)

        print(f"[Scheduler] Insight generation failed: {e}")
        return {"status": "error", "error": str(e)}


async def run_hevy_sync() -> dict:
    """Sync Hevy workout data in background."""
    state = load_scheduler_state()

    # Check if too recent
    if state.last_hevy_sync:
        last_sync = datetime.fromisoformat(state.last_hevy_sync)
        hours_since = (datetime.now() - last_sync).total_seconds() / 3600
        if hours_since < state.hevy_sync_interval_hours:
            return {"status": "skipped", "hours_since_last": hours_since}

    try:
        print("[Scheduler] Syncing Hevy workouts...")

        workouts = await hevy.get_all_workouts()
        if not workouts:
            return {"status": "no_workouts"}

        # Aggregate by day
        daily_workouts = hevy.aggregate_workouts_by_day(workouts)

        # Store in context store
        for date_str, data in daily_workouts.items():
            workout_snapshot = context_store.WorkoutSnapshot(
                workout_count=data["workout_count"],
                total_duration_minutes=data["total_duration_minutes"],
                total_volume_kg=data["total_volume_kg"],
                exercises=data["exercises"],
                workout_titles=data["workout_titles"]
            )
            context_store.update_workout(date_str, workout_snapshot)

        state.last_hevy_sync = datetime.now().isoformat()
        save_scheduler_state(state)

        print(f"[Scheduler] Synced {len(workouts)} workouts across {len(daily_workouts)} days")

        return {
            "status": "success",
            "workouts": len(workouts),
            "days": len(daily_workouts)
        }

    except Exception as e:
        print(f"[Scheduler] Hevy sync failed: {e}")
        return {"status": "error", "error": str(e)}


# --- Context for Chat Agent ---

def get_insights_for_chat_context(limit: int = 3) -> str:
    """Get pre-computed insights formatted for chat system prompt.

    This is the key integration point: chat agent queries stored insights
    instead of regenerating them.
    """
    insights = context_store.get_insights(limit=limit, include_dismissed=False)

    if not insights:
        return ""

    lines = ["Recent AI-generated insights about this user:"]
    for i in insights[:limit]:
        lines.append(f"- [{i.category.upper()}] {i.title}: {i.body}")
        if i.suggested_actions:
            lines.append(f"  Suggested: {', '.join(i.suggested_actions[:2])}")

    return "\n".join(lines)


def get_weekly_summary_for_chat() -> str:
    """Get a compact weekly summary for chat context.

    This gives the chat agent quick access to trends without
    needing to regenerate analysis.
    """
    snapshots = context_store.get_recent_snapshots(7)
    if not snapshots:
        return ""

    averages = context_store.compute_averages(snapshots)

    parts = ["This week's summary:"]

    if averages.get("nutrition_days", 0) > 0:
        parts.append(f"- Nutrition: avg {averages['avg_calories']}cal, {averages['avg_protein']}g protein ({averages['nutrition_days']} days tracked)")

    if averages.get("avg_weight"):
        weight_str = f"- Weight: {averages['avg_weight']}lbs"
        if averages.get("weight_change"):
            direction = "↓" if averages["weight_change"] < 0 else "↑"
            weight_str += f" ({direction}{abs(averages['weight_change'])}lbs this week)"
        parts.append(weight_str)

    if averages.get("avg_sleep"):
        parts.append(f"- Sleep: avg {averages['avg_sleep']}h")

    if averages.get("total_workouts", 0) > 0:
        parts.append(f"- Workouts: {averages['total_workouts']} sessions")

    return "\n".join(parts) if len(parts) > 1 else ""


# --- Background Loop ---

class BackgroundScheduler:
    """Runs scheduled tasks in background thread."""

    def __init__(self):
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._loop: Optional[asyncio.AbstractEventLoop] = None

    def start(self):
        """Start the background scheduler."""
        if self._running:
            return

        self._running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()
        print("[Scheduler] Background scheduler started")

    def stop(self):
        """Stop the background scheduler."""
        self._running = False
        if self._loop:
            self._loop.call_soon_threadsafe(self._loop.stop)
        print("[Scheduler] Background scheduler stopped")

    def _run_loop(self):
        """Run the async event loop in background thread."""
        self._loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self._loop)

        try:
            self._loop.run_until_complete(self._scheduler_loop())
        except Exception as e:
            print(f"[Scheduler] Loop error: {e}")
        finally:
            self._loop.close()

    async def _scheduler_loop(self):
        """Main scheduler loop - runs periodic tasks."""
        # Initial delay to let server start up
        await asyncio.sleep(5)

        while self._running:
            try:
                # Run insight generation if due
                await run_insight_generation(force=False)

                # Run Hevy sync if due
                await run_hevy_sync()

            except Exception as e:
                print(f"[Scheduler] Task error: {e}")

            # Check every 15 minutes
            await asyncio.sleep(15 * 60)

    def trigger_insight_generation(self, force: bool = False):
        """Trigger insight generation from main thread."""
        if self._loop:
            asyncio.run_coroutine_threadsafe(
                run_insight_generation(force=force),
                self._loop
            )


# Global scheduler instance
_scheduler: Optional[BackgroundScheduler] = None


def get_scheduler() -> BackgroundScheduler:
    """Get or create the global scheduler."""
    global _scheduler
    if _scheduler is None:
        _scheduler = BackgroundScheduler()
    return _scheduler


def start_scheduler():
    """Start the background scheduler."""
    get_scheduler().start()


def stop_scheduler():
    """Stop the background scheduler."""
    if _scheduler:
        _scheduler.stop()


# --- Status Endpoint Support ---

def get_scheduler_status() -> dict:
    """Get current scheduler status for API."""
    state = load_scheduler_state()

    # Calculate time until next insight generation
    next_insight_gen = None
    if state.last_insight_generation:
        last_gen = datetime.fromisoformat(state.last_insight_generation)
        next_gen = last_gen + timedelta(hours=state.insight_generation_interval_hours)
        if next_gen > datetime.now():
            next_insight_gen = next_gen.isoformat()

    return {
        "is_running": _scheduler is not None and _scheduler._running,
        "is_generating_insights": state.is_generating,
        "last_insight_generation": state.last_insight_generation,
        "next_insight_generation": next_insight_gen,
        "last_hevy_sync": state.last_hevy_sync,
        "insights_generated_today": state.insights_generated_today,
        "last_error": state.generation_error
    }

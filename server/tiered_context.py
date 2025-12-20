"""Tiered Context System - Selective surfacing for AI coach.

Philosophy: The coach should feel like a well-informed friend, not a robot reading data.
Context is injected based on relevance, not dumped wholesale.

Tier 1: Core (~100-150 tokens) - Always injected
    - Phase/goal, today's status, alerts, insight headlines, tool hints

Tier 2: Topic-triggered (~200-400 tokens per topic) - Based on message analysis
    - Training, nutrition, recovery, progress, goals

Tier 3: Deep queries - Tool-based, on-demand
    - MCP for Claude CLI, function calling for Gemini API
"""

from dataclasses import dataclass, field
from typing import Optional
from enum import Enum
import re
from datetime import date, datetime

import scheduler
import context_store
import hevy
import profile as profile_module


class Topic(Enum):
    TRAINING = "training"
    NUTRITION = "nutrition"
    RECOVERY = "recovery"
    PROGRESS = "progress"
    GOALS = "goals"


@dataclass
class TieredContext:
    """Complete tiered context for a chat request."""

    # Tier 1: Always present
    core: str = ""

    # Tier 2: Topic-specific (0-2 topics)
    topic_contexts: dict[str, str] = field(default_factory=dict)
    detected_topics: list[str] = field(default_factory=list)

    # Metadata
    total_tokens_estimate: int = 0

    def has_any_context(self) -> bool:
        """Check if any context is available."""
        return bool(self.core) or bool(self.topic_contexts)

    def to_context_string(self) -> str:
        """Build the complete context string."""
        parts = []

        if self.core:
            parts.append(self.core)

        for topic, ctx in self.topic_contexts.items():
            if ctx:
                parts.append(f"[{topic.upper()}]\n{ctx}")

        return "\n\n".join(parts)


class TopicDetector:
    """Fast topic detection using keyword and regex patterns.

    No LLM call required - pure pattern matching for speed.
    """

    TOPIC_PATTERNS = {
        "training": {
            "keywords": [
                "workout", "training", "lift", "gym", "exercise", "sets", "reps",
                "volume", "chest", "back", "legs", "arms", "shoulders", "push", "pull",
                "bench", "squat", "deadlift", "hevy", "muscle", "strength", "pr",
                "session", "split", "routine", "gains", "pump", "weight room",
                "dumbbell", "barbell", "cable", "machine", "compound", "isolation"
            ],
            "patterns": [
                r"how.*(workout|training|lift)",
                r"should i.*(train|lift)",
                r"(chest|back|legs|arms).*(volume|sets)",
                r"last.*(workout|session)",
                r"next.*(workout|session)"
            ]
        },
        "nutrition": {
            "keywords": [
                "eat", "food", "meal", "calories", "protein", "carbs", "fat",
                "macros", "diet", "hungry", "eating", "breakfast", "lunch", "dinner",
                "snack", "tdee", "deficit", "surplus", "fasting", "cals",
                "nutrition", "intake", "log", "track"
            ],
            "patterns": [
                r"what.*(eat|have|should i eat)",
                r"how.*protein",
                r"(too much|not enough).*(eat|cal)",
                r"log.*(food|meal|breakfast|lunch|dinner)"
            ]
        },
        "recovery": {
            "keywords": [
                "sleep", "tired", "fatigue", "rest", "recovery", "hrv",
                "heart rate", "sore", "energy", "stress", "burnout",
                "overtraining", "deload", "worn out", "exhausted", "rested"
            ],
            "patterns": [
                r"how.*(sleep|recover)",
                r"feel.*(tired|sore|worn|exhausted)",
                r"(hrv|heart rate).*(low|high|dropping)",
                r"need.*(rest|deload|break)"
            ]
        },
        "progress": {
            "keywords": [
                "progress", "results", "weight", "body fat", "bf%", "lean",
                "losing", "gaining", "trend", "change", "working", "dexa",
                "scale", "measurements", "before", "after", "recomp"
            ],
            "patterns": [
                r"how.*(doing|going|progress)",
                r"(losing|gaining).*(weight|fat|muscle)",
                r"is.*(working|helping)",
                r"(weight|bf|body fat).*(trend|change)"
            ]
        },
        "goals": {
            "keywords": [
                "goal", "target", "plan", "phase", "cut", "bulk", "recomp",
                "maintain", "timeline", "deadline", "milestone", "objective"
            ],
            "patterns": [
                r"(my|the) goal",
                r"want to.*(lose|gain|get|be)",
                r"(current|next) phase",
                r"how long.*(take|until)"
            ]
        }
    }

    @classmethod
    def detect_topics(cls, message: str) -> list[str]:
        """Detect topics from user message. Returns top 2 by score."""
        message_lower = message.lower()
        scores: dict[str, int] = {}

        for topic, config in cls.TOPIC_PATTERNS.items():
            score = 0

            # Keyword matching (1 point each)
            for keyword in config["keywords"]:
                if keyword in message_lower:
                    score += 1

            # Pattern matching (2 points each - more specific)
            for pattern in config.get("patterns", []):
                if re.search(pattern, message_lower):
                    score += 2

            if score > 0:
                scores[topic] = score

        # Return top 2 topics by score
        sorted_topics = sorted(scores.keys(), key=lambda t: scores[t], reverse=True)
        return sorted_topics[:2]

    @classmethod
    def is_followup(cls, message: str) -> bool:
        """Check if message seems like a follow-up to previous topic."""
        message_lower = message.lower().strip()

        followup_patterns = [
            r"^(and|also|what about|how about|okay|so|yeah|yes|no|sure)",
            r"^(that|this|it)\b",
            r"^(more|another|other)",
            r"^(why|how|when|where|who)\b",
            r"\?$"  # Questions often follow-up
        ]

        # Short messages are often follow-ups
        if len(message_lower.split()) <= 5:
            for pattern in followup_patterns:
                if re.search(pattern, message_lower):
                    return True

        return False


async def build_core_context(
    user_profile: Optional["profile_module.UserProfile"] = None,
    health_context: Optional[dict] = None,
    nutrition_context: Optional[dict] = None
) -> str:
    """Build Tier 1 core context (~100-150 tokens).

    Always present - provides baseline awareness without data-dumping.
    """
    if not user_profile:
        user_profile = profile_module.load_profile()

    lines = ["[CONTEXT]"]

    # Phase/goal (1 line)
    phase_parts = []
    if user_profile.current_phase:
        phase_parts.append(user_profile.current_phase.upper())
    if user_profile.phase_context:
        phase_parts.append(user_profile.phase_context)
    elif user_profile.target_weight_lbs:
        phase_parts.append(f"target {user_profile.target_weight_lbs}lb")
    elif user_profile.goals:
        phase_parts.append(user_profile.goals[0][:50])

    if phase_parts:
        lines.append(f"Phase: {' - '.join(phase_parts)}")

    # Today's status (1 line)
    today_parts = []

    # Training day check
    try:
        workouts = await hevy.get_recent_workouts(days=1, limit=1)
        if workouts:
            workout_date = datetime.fromisoformat(workouts[0]["start_time"]).date()
            if workout_date == date.today():
                today_parts.append("Training day")
            else:
                today_parts.append("Rest day")
        else:
            today_parts.append("Rest day")
    except Exception:
        pass

    # Nutrition status
    if nutrition_context:
        cal = nutrition_context.get("total_calories", 0)
        pro = nutrition_context.get("total_protein", 0)
        if cal > 0:
            today_parts.append(f"{cal}cal, {pro}g protein")

    # Sleep
    if health_context:
        sleep = health_context.get("sleep_hours")
        if sleep:
            today_parts.append(f"Slept {sleep:.1f}h")

    if today_parts:
        lines.append("Today: " + " | ".join(today_parts))

    # Active alerts (risks/streaks)
    alerts = await _compute_alerts(user_profile)
    if alerts:
        lines.append("Alerts: " + "; ".join(alerts[:3]))

    # Top insight headlines (not full bodies)
    insight_str = scheduler.get_insights_for_chat_context(limit=3)
    if insight_str:
        # Extract just the titles/first lines
        insight_lines = [l.strip() for l in insight_str.split("\n") if l.strip().startswith("-")]
        if insight_lines:
            headlines = [l[:60] + "..." if len(l) > 60 else l for l in insight_lines[:3]]
            lines.append("Insights: " + " | ".join([h.lstrip("- ") for h in headlines]))

    # Tool availability hint
    lines.append("Tools: query_workouts, query_nutrition, query_body_comp, query_recovery")

    return "\n".join(lines)


async def _compute_alerts(user_profile: "profile_module.UserProfile") -> list[str]:
    """Compute active alerts/risks/streaks."""
    alerts = []

    try:
        # Check protein compliance from context store
        snapshots = context_store.get_recent_snapshots(5)
        if snapshots:
            target = user_profile.target_protein_g or 175
            low_days = sum(
                1 for s in snapshots
                if s.get("nutrition", {}).get("protein", 0) > 0
                and s["nutrition"]["protein"] < target * 0.85
            )
            if low_days >= 3:
                alerts.append(f"Protein under target {low_days}/5 days")

        # Check set tracker for undertrained muscles
        set_tracker = await hevy.get_rolling_set_counts(days=7)
        if set_tracker:
            for muscle, data in set_tracker.items():
                if data.get("status") in ["below", "at_floor"]:
                    alerts.append(f"{muscle.title()} volume low ({data.get('sets', 0)} sets)")
                    break  # Just first one
    except Exception:
        pass

    return alerts


async def build_topic_context(topic: str) -> str:
    """Build Tier 2 context for a specific topic."""
    builders = {
        "training": _build_training_context,
        "nutrition": _build_nutrition_context,
        "recovery": _build_recovery_context,
        "progress": _build_progress_context,
        "goals": _build_goals_context,
    }

    builder = builders.get(topic)
    if builder:
        return await builder()
    return ""


async def _build_training_context() -> str:
    """Build training-specific context (~300 tokens)."""
    parts = []

    # Rolling 7-day set tracker
    set_tracker = await hevy.format_set_tracker_for_chat()
    if set_tracker:
        parts.append(set_tracker)

    # Recent workouts (condensed)
    try:
        recent = await hevy.get_recent_workouts(days=7, limit=3)
        if recent:
            workout_lines = []
            for w in recent:
                workout_date = datetime.fromisoformat(w["start_time"]).date()
                days_ago = (date.today() - workout_date).days
                when = "Today" if days_ago == 0 else f"{days_ago}d ago"
                title = w.get("title", "Workout")
                exercises = w.get("exercises", [])[:4]
                ex_names = [e.get("title", "")[:15] for e in exercises]
                workout_lines.append(f"- {title} ({when}): {', '.join(ex_names)}")
            if workout_lines:
                parts.append("Recent:\n" + "\n".join(workout_lines))
    except Exception:
        pass

    return "\n\n".join(parts)


async def _build_nutrition_context() -> str:
    """Build nutrition-specific context (~250 tokens)."""
    parts = []

    # Weekly summary
    summary = scheduler.get_weekly_summary_for_chat()
    if summary:
        parts.append(summary)

    return "\n".join(parts)


async def _build_recovery_context() -> str:
    """Build recovery-specific context (~200 tokens)."""
    parts = []

    try:
        snapshots = context_store.get_recent_snapshots(7)
        if snapshots:
            # Sleep trend
            sleeps = [s["health"]["sleep_hours"] for s in snapshots
                     if s.get("health", {}).get("sleep_hours")]
            if sleeps:
                avg = sum(sleeps) / len(sleeps)
                parts.append(f"7-day sleep avg: {avg:.1f}h ({len(sleeps)} nights)")

            # HRV if available
            hrvs = [s["health"]["hrv_ms"] for s in snapshots
                   if s.get("health", {}).get("hrv_ms")]
            if hrvs:
                avg_hrv = sum(hrvs) / len(hrvs)
                parts.append(f"HRV avg: {avg_hrv:.0f}ms")
    except Exception:
        pass

    return "\n".join(parts)


async def _build_progress_context() -> str:
    """Build progress-specific context (~350 tokens)."""
    parts = []

    # Body comp trends (EMA-smoothed)
    trends = context_store.format_body_comp_for_chat()
    if trends:
        parts.append(trends)

    return "\n".join(parts)


async def _build_goals_context() -> str:
    """Build goals-specific context (~150 tokens)."""
    user_profile = profile_module.load_profile()
    parts = []

    if user_profile.goals:
        goals_str = "\n".join(f"- {g}" for g in user_profile.goals[:3])
        parts.append(f"Goals:\n{goals_str}")

    if user_profile.current_phase and user_profile.phase_context:
        parts.append(f"Phase: {user_profile.current_phase} - {user_profile.phase_context}")

    return "\n".join(parts)


async def build_tiered_context(
    message: str,
    health_context: Optional[dict] = None,
    nutrition_context: Optional[dict] = None,
    last_topic: Optional[str] = None,
) -> TieredContext:
    """Build complete tiered context for a chat request.

    This is the main entry point, replacing build_chat_context().

    Args:
        message: The user's message
        health_context: HealthKit data from iOS (optional)
        nutrition_context: Nutrition data from iOS (optional)
        last_topic: Previous conversation topic for continuity

    Returns:
        TieredContext with core + topic-specific contexts
    """
    # Detect topics from user message
    detected_topics = TopicDetector.detect_topics(message)

    # If no topic detected but seems like follow-up, use last topic
    if not detected_topics and last_topic and TopicDetector.is_followup(message):
        detected_topics = [last_topic]

    # Build Tier 1 (always)
    core = await build_core_context(
        health_context=health_context,
        nutrition_context=nutrition_context
    )

    # Build Tier 2 (topic-triggered)
    topic_contexts = {}
    for topic in detected_topics:
        ctx = await build_topic_context(topic)
        if ctx:
            topic_contexts[topic] = ctx

    # Estimate tokens
    total_text = core + "".join(topic_contexts.values())
    token_estimate = len(total_text) // 4  # Rough estimate

    return TieredContext(
        core=core,
        topic_contexts=topic_contexts,
        detected_topics=detected_topics,
        total_tokens_estimate=token_estimate
    )

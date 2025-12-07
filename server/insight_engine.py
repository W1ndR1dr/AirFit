"""Insight Engine - Maximally unhobbled AI analysis.

Design principles:
1. Feed raw data in compact format - no lossy summarization
2. Let the LLM reason freely - no hardcoded assumptions
3. Store everything - future models will find patterns we can't

The AI decides what's interesting. We just give it all the data.

NOTE: Uses CLI tools (claude, gemini, ollama) via llm_router - NOT API SDKs.
"""

import json
import uuid
from datetime import datetime, date, timedelta
from typing import Optional

import llm_router
from context_store import (
    load_store, get_recent_snapshots, DailySnapshot,
    Insight, add_insight, get_insights as get_stored_insights
)


# --- Compact Data Formatting ---
# Goal: Lossless compression. All data, minimal tokens.

def format_day_compact(snapshot: DailySnapshot) -> str:
    """Format a single day's data in ultra-compact form.

    Target: ~40-60 tokens per day with full data.
    """
    parts = [snapshot.date]

    # Nutrition: cal|p|c|f|entries
    n = snapshot.nutrition
    if n.calories > 0:
        parts.append(f"N:{n.calories}|{n.protein}|{n.carbs}|{n.fat}|{n.entry_count}")

    # Health: wt|bf%|sleep|hr|hrv|steps|kcal
    h = snapshot.health
    health_parts = []
    if h.weight_lbs:
        health_parts.append(f"w{h.weight_lbs:.1f}")
    if h.body_fat_pct:
        health_parts.append(f"bf{h.body_fat_pct:.1f}")
    if h.sleep_hours:
        health_parts.append(f"sl{h.sleep_hours:.1f}")
    if h.resting_hr:
        health_parts.append(f"hr{h.resting_hr}")
    if h.hrv_ms:
        health_parts.append(f"hrv{h.hrv_ms:.0f}")
    if h.steps > 0:
        health_parts.append(f"st{h.steps}")
    if h.active_calories > 0:
        health_parts.append(f"ac{h.active_calories}")
    if h.vo2_max:
        health_parts.append(f"vo2{h.vo2_max:.1f}")
    if health_parts:
        parts.append("H:" + ",".join(health_parts))

    # Workout: count|duration|volume + exercises
    w = snapshot.workout
    if w.workout_count > 0:
        workout_str = f"W:{w.workout_count}x|{w.total_duration_minutes}m|{w.total_volume_kg:.0f}kg"
        if w.exercises:
            # Compact exercise format: name(sets×reps@kg)
            ex_strs = []
            for ex in w.exercises[:8]:  # Limit to 8 exercises per day
                name = ex.get("name", "?")[:12]  # Truncate long names
                sets = ex.get("sets", 0)
                reps = ex.get("total_reps", 0)
                weight = ex.get("max_weight_kg", 0)
                if weight > 0:
                    ex_strs.append(f"{name}({sets}×{reps}@{weight:.0f})")
                else:
                    ex_strs.append(f"{name}({sets}×{reps})")
            if ex_strs:
                workout_str += " " + ",".join(ex_strs)
        parts.append(workout_str)

    return " | ".join(parts)


def format_all_data_compact(snapshots: list[DailySnapshot], profile: Optional[dict] = None) -> str:
    """Format all data for LLM consumption.

    Returns a compact string with all raw data.
    No interpretation - just data.
    """
    lines = []

    # Header with legend
    lines.append("=== RAW FITNESS DATA ===")
    lines.append("Format: DATE | N:cal|prot|carb|fat|entries | H:w(lbs),bf(%),sl(hrs),hr,hrv(ms),st(steps),ac(kcal) | W:count|duration|volume exercises")
    lines.append("")

    # Profile context if available
    if profile:
        lines.append("--- PROFILE ---")
        for key, value in profile.items():
            if value and key not in ["raw_notes", "notes_version"]:
                lines.append(f"{key}: {value}")
        lines.append("")

    # All daily data
    lines.append("--- DAILY DATA (newest first) ---")
    for snapshot in sorted(snapshots, key=lambda s: s.date, reverse=True):
        day_str = format_day_compact(snapshot)
        if len(day_str) > 12:  # Only include days with actual data
            lines.append(day_str)

    return "\n".join(lines)


def count_tokens_estimate(text: str) -> int:
    """Rough token count estimate (4 chars ≈ 1 token)."""
    return len(text) // 4


# --- Insight Generation ---

INSIGHT_PROMPT = """You are an expert fitness coach analyzing a client's data. You have access to their complete raw data - nutrition, health metrics, and workout history.

Your job: Find what's interesting, important, or actionable. Look for patterns, correlations, anomalies, progress, and risks.

Be specific and data-driven. Reference actual numbers from the data. Don't be generic - if you see something noteworthy, call it out with evidence.

Focus on insights the user wouldn't easily notice themselves - especially cross-domain correlations (e.g., how sleep affects training, how protein timing correlates with weight changes, etc.)

Respond in JSON format with an array of insights:
```json
{
  "insights": [
    {
      "category": "correlation|trend|anomaly|milestone|nudge",
      "tier": 1-5,
      "title": "Short punchy title (max 8 words)",
      "body": "Conversational explanation with data references (2-3 sentences)",
      "importance": 0.0-1.0,
      "confidence": 0.0-1.0,
      "actionability": 0.0-1.0,
      "suggested_actions": ["action 1", "action 2"],
      "supporting_data": {"key metrics or data points referenced"}
    }
  ]
}
```

Categories:
- correlation: Cross-domain patterns (highest value - things humans miss)
- trend: Directional movement over time
- anomaly: Something unusual that needs attention
- milestone: Achievement or progress worth celebrating
- nudge: Gentle reminder or suggestion

Tiers (1=highest priority):
1. Critical insights requiring immediate attention
2. Important patterns affecting goals
3. Noteworthy observations
4. Nice-to-know information
5. Minor observations

Generate 3-7 insights based on what's actually interesting in the data. Quality over quantity - only surface genuinely valuable observations."""


async def generate_insights(
    days: int = 90,
    profile: Optional[dict] = None,
    force_refresh: bool = False
) -> list[Insight]:
    """Generate insights from all available data.

    This is the core insight generation function.
    It feeds raw data to the LLM (via CLI) and lets it reason freely.

    Uses llm_router which calls CLI tools (claude, gemini, codex) -
    backed by subscriptions, no API costs.
    """
    # Load all data
    snapshots = get_recent_snapshots(days)

    if not snapshots:
        return []

    # Format data compactly
    data_text = format_all_data_compact(snapshots, profile)

    # Log token estimate
    token_estimate = count_tokens_estimate(data_text)
    print(f"[InsightEngine] Data formatted: {len(snapshots)} days, ~{token_estimate} tokens")

    # Build the prompt
    full_prompt = f"""{INSIGHT_PROMPT}

Here is the complete data:

{data_text}

Analyze this data and return your insights as JSON."""

    # Call LLM via CLI (no API costs - uses subscription)
    try:
        response = await llm_router.chat(
            prompt=full_prompt,
            system_prompt="You are an expert fitness coach. Respond only with valid JSON.",
            use_session=False  # One-off analysis, don't pollute chat session
        )

        if not response.success:
            print(f"[InsightEngine] LLM call failed: {response.error}")
            return []

        response_text = response.text
        print(f"[InsightEngine] Got response from {response.provider}")

        # Extract JSON from response
        json_str = response_text
        if "```json" in response_text:
            json_str = response_text.split("```json")[1].split("```")[0]
        elif "```" in response_text:
            json_str = response_text.split("```")[1].split("```")[0]

        result = json.loads(json_str)
        insights_data = result.get("insights", [])

        # Convert to Insight objects and store
        insights = []
        for data in insights_data:
            insight = Insight(
                id=str(uuid.uuid4()),
                created_at=datetime.now().isoformat(),
                category=data.get("category", "nudge"),
                tier=data.get("tier", 3),
                title=data.get("title", "Insight"),
                body=data.get("body", ""),
                supporting_data=data.get("supporting_data", {}),
                importance=data.get("importance", 0.5),
                confidence=data.get("confidence", 0.5),
                novelty=1.0,  # New insights are novel by definition
                actionability=data.get("actionability", 0.5),
                suggested_actions=data.get("suggested_actions", []),
                conversation_context=data_text[:2000]  # Store context for follow-up
            )
            insights.append(insight)
            add_insight(insight)

        print(f"[InsightEngine] Generated {len(insights)} insights via {response.provider}")
        return insights

    except json.JSONDecodeError as e:
        print(f"[InsightEngine] Failed to parse response: {e}")
        return []
    except Exception as e:
        print(f"[InsightEngine] Error generating insights: {e}")
        return []


async def get_insights_for_display(limit: int = 10) -> list[dict]:
    """Get insights formatted for iOS display."""
    insights = get_stored_insights(limit=limit, include_dismissed=False)

    return [
        {
            "id": i.id,
            "category": i.category,
            "tier": i.tier,
            "title": i.title,
            "body": i.body,
            "importance": i.importance,
            "confidence": i.confidence,
            "suggested_actions": i.suggested_actions,
            "created_at": i.created_at,
        }
        for i in insights
    ]


# --- Context Summary for Quick View ---

async def get_context_summary(days: int = 7, profile: Optional[dict] = None) -> dict:
    """Get a quick context summary for the insights header.

    This is computed data, not AI-generated - for the metric tiles.
    """
    snapshots = get_recent_snapshots(days)

    if not snapshots:
        return {
            "period_days": days,
            "has_data": False,
        }

    # Compute averages
    nutrition_days = [s for s in snapshots if s.nutrition.calories > 0]
    weights = [s.health.weight_lbs for s in snapshots if s.health.weight_lbs]
    sleeps = [s.health.sleep_hours for s in snapshots if s.health.sleep_hours]
    workout_days = [s for s in snapshots if s.workout.workout_count > 0]

    # Get targets from profile
    protein_target = int(profile.get("protein_target", 160)) if profile else 160
    calorie_target = int(profile.get("calorie_target", 2200)) if profile else 2200

    # Protein compliance
    protein_hits = sum(
        1 for s in nutrition_days
        if s.nutrition.protein >= protein_target * 0.9
    ) if nutrition_days else 0

    return {
        "period_days": days,
        "has_data": True,
        "avg_calories": round(sum(s.nutrition.calories for s in nutrition_days) / len(nutrition_days)) if nutrition_days else 0,
        "avg_protein": round(sum(s.nutrition.protein for s in nutrition_days) / len(nutrition_days)) if nutrition_days else 0,
        "avg_weight": round(sum(weights) / len(weights), 1) if weights else None,
        "weight_change": round(weights[0] - weights[-1], 1) if len(weights) >= 2 else None,  # newest - oldest
        "avg_sleep": round(sum(sleeps) / len(sleeps), 1) if sleeps else None,
        "total_workouts": sum(s.workout.workout_count for s in snapshots),
        "protein_compliance": round(protein_hits / len(nutrition_days), 2) if nutrition_days else None,
        "protein_target": protein_target,
        "calorie_target": calorie_target,
    }


# --- Test function ---

async def test_insight_generation():
    """Test the insight engine with sample data."""
    from context_store import DailySnapshot, NutritionSnapshot, HealthSnapshot, WorkoutSnapshot, upsert_snapshot

    # Create some sample data
    base_date = date.today()

    for i in range(7):
        d = base_date - timedelta(days=i)
        snapshot = DailySnapshot(
            date=d.isoformat(),
            nutrition=NutritionSnapshot(
                calories=2100 + (i * 50),
                protein=145 + (i * 5),
                carbs=220,
                fat=70,
                entry_count=4
            ),
            health=HealthSnapshot(
                weight_lbs=175.5 - (i * 0.2),
                sleep_hours=7.5 - (i * 0.1),
                steps=8000 + (i * 500),
                active_calories=400 + (i * 20),
                resting_hr=58 + i,
                hrv_ms=55 - i
            ),
            workout=WorkoutSnapshot(
                workout_count=1 if i % 2 == 0 else 0,
                total_duration_minutes=60 if i % 2 == 0 else 0,
                total_volume_kg=5000 if i % 2 == 0 else 0,
                exercises=[
                    {"name": "Bench Press", "sets": 4, "total_reps": 32, "max_weight_kg": 80},
                    {"name": "Squat", "sets": 4, "total_reps": 28, "max_weight_kg": 100}
                ] if i % 2 == 0 else []
            )
        )
        upsert_snapshot(snapshot)

    # Test formatting
    snapshots = get_recent_snapshots(7)
    formatted = format_all_data_compact(snapshots)
    print("=== FORMATTED DATA ===")
    print(formatted)
    print(f"\nEstimated tokens: {count_tokens_estimate(formatted)}")

    # Test insight generation (uses CLI tools)
    print("\n=== GENERATING INSIGHTS (via CLI) ===")
    insights = await generate_insights(days=7)
    for insight in insights:
        print(f"\n[{insight.category.upper()}] {insight.title}")
        print(f"  {insight.body}")
        print(f"  Actions: {insight.suggested_actions}")


if __name__ == "__main__":
    import asyncio
    asyncio.run(test_insight_generation())

"""Fitness Tools - Deep query capabilities for AI coach.

These tools enable Tier 3 context queries for both:
- Claude CLI via MCP (Model Context Protocol)
- Gemini API via function calling

The coach can invoke these to "look up" detailed data when needed,
rather than having everything pre-injected.
"""

from dataclasses import dataclass
from typing import Optional, Any
from datetime import date, datetime, timedelta

import hevy
import context_store
import profile as profile_module


# Tool schemas for Gemini function calling
TOOL_SCHEMAS = [
    {
        "name": "query_workouts",
        "description": "Query workout history from Hevy. Use when user asks about specific exercises, training history, volume, or PRs.",
        "parameters": {
            "type": "object",
            "properties": {
                "exercise": {
                    "type": "string",
                    "description": "Filter by exercise name (e.g., 'bench press', 'squat')"
                },
                "muscle_group": {
                    "type": "string",
                    "description": "Filter by muscle group (e.g., 'chest', 'back', 'legs')"
                },
                "days": {
                    "type": "integer",
                    "description": "Number of days to query (1-90, default 14)"
                }
            }
        }
    },
    {
        "name": "query_nutrition",
        "description": "Query nutrition history. Use when user asks about eating patterns, macro trends, or compliance.",
        "parameters": {
            "type": "object",
            "properties": {
                "days": {
                    "type": "integer",
                    "description": "Number of days to query (1-30, default 7)"
                },
                "include_meals": {
                    "type": "boolean",
                    "description": "Include individual meal entries (default false)"
                }
            }
        }
    },
    {
        "name": "query_body_comp",
        "description": "Query body composition trends. Use when user asks about weight, body fat, or lean mass progress.",
        "parameters": {
            "type": "object",
            "properties": {
                "days": {
                    "type": "integer",
                    "description": "Number of days to query (30-365, default 90)"
                }
            }
        }
    },
    {
        "name": "query_recovery",
        "description": "Query recovery metrics. Use when user mentions sleep, HRV, fatigue, or readiness.",
        "parameters": {
            "type": "object",
            "properties": {
                "days": {
                    "type": "integer",
                    "description": "Number of days to query (7-30, default 14)"
                }
            }
        }
    },
    {
        "name": "query_insights",
        "description": "Query AI-generated insights. Use when user asks about patterns, correlations, or 'what have you noticed'.",
        "parameters": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "enum": ["correlation", "trend", "anomaly", "milestone", "nudge"],
                    "description": "Filter by insight category"
                },
                "limit": {
                    "type": "integer",
                    "description": "Max insights to return (1-10, default 5)"
                }
            }
        }
    }
]


@dataclass
class ToolResult:
    """Result from a tool execution."""
    success: bool
    data: Any
    error: Optional[str] = None

    def to_context_string(self) -> str:
        """Format result for LLM consumption."""
        if not self.success:
            return f"Tool error: {self.error}"
        if isinstance(self.data, str):
            return self.data
        if isinstance(self.data, dict):
            return _format_dict(self.data)
        if isinstance(self.data, list):
            return "\n".join(_format_dict(item) if isinstance(item, dict) else str(item) for item in self.data)
        return str(self.data)


def _format_dict(d: dict, indent: int = 0) -> str:
    """Format a dict for readable LLM output."""
    lines = []
    prefix = "  " * indent
    for k, v in d.items():
        if isinstance(v, dict):
            lines.append(f"{prefix}{k}:")
            lines.append(_format_dict(v, indent + 1))
        elif isinstance(v, list):
            lines.append(f"{prefix}{k}: {', '.join(str(x) for x in v[:5])}")
        else:
            lines.append(f"{prefix}{k}: {v}")
    return "\n".join(lines)


async def execute_tool(name: str, params: dict) -> ToolResult:
    """Execute a tool by name with given parameters."""
    tools = {
        "query_workouts": query_workouts,
        "query_nutrition": query_nutrition,
        "query_body_comp": query_body_comp,
        "query_recovery": query_recovery,
        "query_insights": query_insights,
    }

    tool_fn = tools.get(name)
    if not tool_fn:
        return ToolResult(success=False, data=None, error=f"Unknown tool: {name}")

    try:
        result = await tool_fn(**params)
        return ToolResult(success=True, data=result)
    except Exception as e:
        return ToolResult(success=False, data=None, error=str(e))


async def query_workouts(
    exercise: Optional[str] = None,
    muscle_group: Optional[str] = None,
    days: int = 14
) -> dict:
    """Query workout history from Hevy."""
    days = min(max(days, 1), 90)

    workouts = await hevy.get_recent_workouts(days=days, limit=20)
    if not workouts:
        return {"message": "No workouts found in the specified period"}

    # Filter by exercise if specified
    if exercise:
        exercise_lower = exercise.lower()
        filtered = []
        for w in workouts:
            # w is a HevyWorkout dataclass; w.exercises is list[dict]
            matching_exercises = [
                e for e in w.exercises
                if exercise_lower in e.get("title", "").lower()
            ]
            if matching_exercises:
                filtered.append({
                    "date": w.date.strftime("%Y-%m-%d"),
                    "title": w.title,
                    "exercises": matching_exercises
                })
        if not filtered:
            return {"message": f"No workouts with '{exercise}' in the last {days} days"}
        return {"workouts": filtered, "count": len(filtered)}

    # Filter by muscle group if specified
    if muscle_group:
        set_counts = await hevy.get_rolling_set_counts(days=days)
        if muscle_group.lower() in set_counts:
            return {
                "muscle_group": muscle_group,
                "sets": set_counts[muscle_group.lower()].get("sets", 0),
                "status": set_counts[muscle_group.lower()].get("status", "unknown"),
                "period": f"{days} days"
            }

    # General workout summary
    summary = []
    for w in workouts[:10]:
        # w is a HevyWorkout dataclass
        workout_date = w.date.strftime("%Y-%m-%d")
        exercises = [e.get("title", "")[:20] for e in w.exercises[:5]]
        summary.append({
            "date": workout_date,
            "title": w.title,
            "exercises": exercises
        })

    return {"workouts": summary, "total_count": len(workouts)}


async def query_nutrition(
    days: int = 7,
    include_meals: bool = False
) -> dict:
    """Query nutrition history from context store."""
    days = min(max(days, 1), 30)

    snapshots = context_store.get_recent_snapshots(days)
    if not snapshots:
        return {"message": "No nutrition data found"}

    # Calculate averages and compliance
    total_cal, total_pro, total_carb, total_fat = 0, 0, 0, 0
    tracked_days = 0

    user_profile = profile_module.load_profile()
    # Get targets from training_day_targets dict
    targets = user_profile.training_day_targets or {}
    target_protein = targets.get("protein", 175)
    target_calories = targets.get("calories", 2400)

    daily_data = []
    for s in snapshots:
        nutr = s.nutrition
        if nutr and nutr.calories > 0:
            tracked_days += 1
            total_cal += nutr.calories
            total_pro += nutr.protein
            total_carb += nutr.carbs
            total_fat += nutr.fat

            if include_meals:
                daily_data.append({
                    "date": s.date,
                    "calories": nutr.calories,
                    "protein": nutr.protein,
                    "carbs": nutr.carbs,
                    "fat": nutr.fat
                })

    if tracked_days == 0:
        return {"message": "No nutrition data tracked in this period"}

    result = {
        "period": f"{days} days",
        "tracked_days": tracked_days,
        "averages": {
            "calories": round(total_cal / tracked_days),
            "protein": round(total_pro / tracked_days),
            "carbs": round(total_carb / tracked_days),
            "fat": round(total_fat / tracked_days)
        },
        "targets": {
            "calories": target_calories,
            "protein": target_protein
        },
        "protein_compliance": f"{round((total_pro / tracked_days) / target_protein * 100)}%"
    }

    if include_meals:
        result["daily_data"] = daily_data

    return result


async def query_body_comp(days: int = 90) -> dict:
    """Query body composition trends."""
    days = min(max(days, 30), 365)

    # Get EMA-smoothed trends
    trends = context_store.format_body_comp_for_chat()
    if trends:
        return {"trends": trends, "period": f"{days} days"}

    snapshots = context_store.get_recent_snapshots(days)
    if not snapshots:
        return {"message": "No body composition data found"}

    # Extract weight and body fat readings
    weights = []
    body_fats = []

    for s in snapshots:
        # s is a DailySnapshot dataclass; s.health is a HealthSnapshot dataclass
        health = s.health
        if health and health.weight_lbs:
            weights.append({
                "date": s.date,
                "weight": health.weight_lbs
            })
        if health and health.body_fat_pct:
            body_fats.append({
                "date": s.date,
                "body_fat": health.body_fat_pct
            })

    result = {"period": f"{days} days"}

    if weights:
        first_weight = weights[0]["weight"]
        last_weight = weights[-1]["weight"]
        result["weight"] = {
            "current": round(last_weight, 1),
            "start": round(first_weight, 1),
            "change": round(last_weight - first_weight, 1),
            "readings": len(weights)
        }

    if body_fats:
        first_bf = body_fats[0]["body_fat"]
        last_bf = body_fats[-1]["body_fat"]
        result["body_fat"] = {
            "current": round(last_bf, 1),
            "start": round(first_bf, 1),
            "change": round(last_bf - first_bf, 1),
            "readings": len(body_fats)
        }

    return result


async def query_recovery(days: int = 14) -> dict:
    """Query recovery metrics (sleep, HRV, RHR)."""
    days = min(max(days, 7), 30)

    snapshots = context_store.get_recent_snapshots(days)
    if not snapshots:
        return {"message": "No recovery data found"}

    sleep_data = []
    hrv_data = []
    rhr_data = []

    for s in snapshots:
        health = s.health
        if not health:
            continue
        date_str = s.date

        if health.sleep_hours:
            sleep_data.append({"date": date_str, "hours": health.sleep_hours})
        if health.hrv_ms:
            hrv_data.append({"date": date_str, "hrv": health.hrv_ms})
        if health.resting_hr:
            rhr_data.append({"date": date_str, "rhr": health.resting_hr})

    result = {"period": f"{days} days"}

    if sleep_data:
        avg_sleep = sum(d["hours"] for d in sleep_data) / len(sleep_data)
        result["sleep"] = {
            "average": round(avg_sleep, 1),
            "nights_tracked": len(sleep_data),
            "recent": sleep_data[-3:] if len(sleep_data) >= 3 else sleep_data
        }

    if hrv_data:
        avg_hrv = sum(d["hrv"] for d in hrv_data) / len(hrv_data)
        result["hrv"] = {
            "average": round(avg_hrv),
            "readings": len(hrv_data),
            "trend": "stable"  # Could compute actual trend
        }

    if rhr_data:
        avg_rhr = sum(d["rhr"] for d in rhr_data) / len(rhr_data)
        result["resting_hr"] = {
            "average": round(avg_rhr),
            "readings": len(rhr_data)
        }

    return result


async def query_insights(
    category: Optional[str] = None,
    limit: int = 5
) -> dict:
    """Query AI-generated insights."""
    limit = min(max(limit, 1), 10)

    # Get stored insights from context store
    insights = context_store.get_insights(category=category, limit=limit * 2)

    if not insights:
        return {"message": "No insights generated yet"}

    # Limit results (already filtered by category if specified)
    insights = insights[:limit]

    if not insights:
        return {"message": f"No insights in category '{category}'"}

    formatted = []
    for i in insights:
        formatted.append({
            "category": i.category,
            "title": i.title,
            "body": i.body,
            "actions": i.suggested_actions or []
        })

    return {"insights": formatted, "count": len(formatted)}

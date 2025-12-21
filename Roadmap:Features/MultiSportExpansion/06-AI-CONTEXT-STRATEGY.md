# AI Context Strategy

> LLM context injection approach for multi-sport support (Andrej Karpathy × Simon Willison perspective)

## The Core Challenge

LLMs have limited context windows. With multiple workout types, we need to:
1. **Prioritize** what to include (recent vs. comprehensive)
2. **Compress** workout data without losing insight-worthy details
3. **Decide** what's relevant to THIS conversation vs. background knowledge

---

## Tiered Context Architecture

### Overview

```
TIER 1 (~120 tokens, always included)
├── Phase + today's status
├── Most recent workout (any type)
├── Active alerts/streaks
├── Insight headlines
└── Tool hints

TIER 2 (~400 tokens max, topic-triggered)
├── Training context (if strength-related)
├── Cardio context (if running/cycling mentioned)
├── Cross-training context (if balance/interference mentioned)
└── Recovery context (if fatigue/sleep mentioned)

TIER 3 (on-demand via tools)
├── query_workouts(type, days, include_details)
├── query_cardio(type, days)
├── query_cross_modality_patterns()
└── query_body_comp(days)
```

### Tier 1: Always-Included Core (~120 tokens)

```python
async def build_core_context(
    user_profile: UserProfile,
    health_context: Optional[dict] = None,
    nutrition_context: Optional[dict] = None
) -> str:
    """
    Tier 1: Always present, ~120 tokens.
    Provides essential awareness without bloating context.
    """
    lines = ["[CONTEXT]"]

    # Phase awareness (10 tokens)
    if user_profile.current_phase:
        lines.append(f"Phase: {user_profile.current_phase.upper()}")

    # Today's snapshot (30 tokens)
    today_parts = []

    # Most recent workout (any type)
    recent = await get_most_recent_workout()
    if recent:
        today_parts.append(recent.one_liner)  # "Legs 2h ago" or "5mi run this AM"

    # Nutrition status
    if nutrition_context:
        cal = nutrition_context.get("total_calories", 0)
        pro = nutrition_context.get("total_protein", 0)
        today_parts.append(f"{cal}cal/{pro}g pro")

    # Sleep
    if health_context and health_context.get("sleep_hours"):
        today_parts.append(f"Slept {health_context['sleep_hours']:.1f}h")

    lines.append("Today: " + " | ".join(today_parts))

    # Training load status (20 tokens)
    load = await compute_load_status()
    if load.acr > 1.3:
        lines.append(f"Load: HIGH (ACR {load.acr:.1f}) - recovery priority")
    elif load.acr < 0.8:
        lines.append(f"Load: LOW (ACR {load.acr:.1f}) - can push harder")

    # Active alerts (20 tokens)
    alerts = await get_active_alerts()
    if alerts:
        lines.append("Alerts: " + "; ".join(alerts[:2]))

    # Insight headlines (30 tokens)
    insights = get_recent_insights(limit=2)
    if insights:
        lines.append(f"Insights: {insights}")

    # Tool hints (10 tokens)
    lines.append("Tools: query_workouts, query_cardio, query_patterns")

    return "\n".join(lines)
```

**Example output:**
```
[CONTEXT]
Phase: CUT
Today: Legs 2h ago | 1850cal/145g pro | Slept 7.2h
Load: OPTIMAL (ACR 1.1)
Alerts: Protein low 3 days; No cardio this week
Insights: Sleep improving with evening yoga; Leg strength up 8%
Tools: query_workouts, query_cardio, query_patterns
```

### Tier 2: Topic-Triggered Context (~400 tokens max)

Only included when topic is detected in user message.

```python
class TopicDetector:
    TOPIC_PATTERNS = {
        "training": {
            "keywords": ["workout", "lift", "gym", "sets", "reps", "volume",
                        "strength", "muscle", "pr", "heavy"],
            "patterns": [r"how.*(train|lift)", r"(my|the).*(workout|session)"]
        },
        "cardio": {
            "keywords": ["run", "running", "jog", "bike", "cycling", "ride",
                        "swim", "swimming", "pool", "pace", "miles", "km",
                        "hr", "heart rate", "zone", "tempo", "interval"],
            "patterns": [r"how.*(run|ride|swim)", r"\d+\s*(mi|km)",
                        r"(z[1-5]|zone\s*\d)"]
        },
        "cross_training": {
            "keywords": ["brick", "triathlon", "balance", "interference",
                        "cross train"],
            "patterns": [r"(run|ride).*(after|before).*(lift|legs)",
                        r"does.*(affect|help|hurt)"]
        },
        "recovery": {
            "keywords": ["tired", "fatigue", "rest", "deload", "sleep",
                        "hrv", "recovery", "sore"],
            "patterns": [r"should I.*(rest|skip)", r"feeling.*(tired|worn)"]
        }
    }

    @classmethod
    def detect(cls, message: str) -> list[str]:
        detected = []
        message_lower = message.lower()
        for topic, config in cls.TOPIC_PATTERNS.items():
            if any(kw in message_lower for kw in config["keywords"]):
                detected.append(topic)
            elif any(re.search(p, message_lower) for p in config["patterns"]):
                detected.append(topic)
        return detected
```

**Topic-specific context builders:**

```python
async def build_cardio_context() -> str:
    """~200 tokens of cardio-specific context."""
    runs = await get_recent_runs(days=14)
    if not runs:
        return ""

    lines = ["[CARDIO]"]

    # Weekly summary
    this_week = [r for r in runs if r.days_ago < 7]
    lines.append(f"This week: {len(this_week)} runs, "
                 f"{sum(r.distance_mi for r in this_week):.1f}mi total")

    # Recent sessions (compact)
    lines.append("Recent:")
    for run in runs[:5]:
        lines.append(f"  {run.to_compact()}")

    # Trends
    if len(runs) >= 4:
        pace_trend = calculate_pace_trend(runs)
        lines.append(f"Pace trend: {pace_trend}")

    return "\n".join(lines)

async def build_cross_modality_context() -> str:
    """~150 tokens about training interactions."""
    patterns = await analyze_cross_modality_patterns()

    lines = ["[CROSS-TRAINING]"]
    for pattern in patterns[:3]:
        lines.append(f"- {pattern.summary}")

    return "\n".join(lines)
```

### Tier 3: On-Demand Tools

When the AI needs more detail than Tier 2 provides, it can invoke tools:

```python
TOOL_SCHEMAS = [
    {
        "name": "query_cardio",
        "description": "Get detailed cardio workout history",
        "parameters": {
            "type": "object",
            "properties": {
                "activity_type": {
                    "type": "string",
                    "enum": ["run", "cycle", "swim", "all"],
                    "description": "Type of cardio activity"
                },
                "days": {
                    "type": "integer",
                    "description": "Number of days to look back"
                },
                "include_hr_zones": {
                    "type": "boolean",
                    "description": "Include heart rate zone breakdown"
                },
                "include_routes": {
                    "type": "boolean",
                    "description": "Include route summaries"
                }
            }
        }
    },
    {
        "name": "query_cross_modality",
        "description": "Analyze patterns across different workout types",
        "parameters": {
            "type": "object",
            "properties": {
                "pattern_type": {
                    "type": "string",
                    "enum": ["sequencing", "interference", "synergy", "recovery"],
                    "description": "Type of cross-modality pattern"
                },
                "days": {
                    "type": "integer",
                    "description": "Analysis window in days"
                }
            }
        }
    }
]
```

---

## Compact Notation System

### The Token Math

| Format | Example | Characters | Tokens |
|--------|---------|------------|--------|
| Full strength workout | (current verbose format) | ~400 | ~100 |
| Compact strength | `S:65m|5200kg Bench(4×8@225)` | ~35 | ~9 |
| Compact run | `R:45m|6.2mi|9:42/mi|Z2:32m` | ~30 | ~8 |
| Compact swim | `W:35m|1650yd|2:08/100` | ~25 | ~6 |

With compact notation: **7-10 recent workouts** in ~150 tokens where we currently fit 2-3.

### Notation by Workout Type

```
# STRENGTH
S:65m|5200kg|chest,quads Bench(3×16@315#PR),Squat(4×8@405)
│  │     │      │        └── Exercises: sets×reps@weight, #PR flag
│  │     │      └── Primary muscle groups
│  │     └── Total volume
│  └── Duration in minutes
└── Type

# RUNNING
R:45m|6.2mi|9:42/mi|Z2:32m,Z3:8m|+420ft|hr156avg
│  │    │      │      │          │      └── Average heart rate
│  │    │      │      │          └── Elevation gain
│  │    │      │      └── Time in HR zones
│  │    │      └── Average pace
│  │    └── Distance
│  └── Duration
└── Type

# CYCLING
C:90m|28.4mi|18.9mph|Z2:65m,Z3:20m|np185w|+1250ft
│  │     │      │       │          │      └── Elevation
│  │     │      │       │          └── Normalized power
│  │     │      │       └── Zone times
│  │     │      └── Average speed
│  │     └── Distance
│  └── Duration
└── Type

# SWIMMING
W:35m|1650yd|2:08/100|free:28,back:4|spm24|swolf72
│  │     │       │        │         │      └── SWOLF score
│  │     │       │        │         └── Strokes per minute
│  │     │       │        └── Laps by stroke type
│  │     │       └── Pace per 100
│  │     └── Distance
│  └── Duration
└── Type (W=sWim, S was taken)

# YOGA
Y:45m|vinyasa|hips,shoulders|rpe4
│  │     │         │         └── RPE/perceived benefit
│  │     │         └── Focus areas
│  │     └── Style
│  └── Duration
└── Type

# MULTI-ACTIVITY (triathlon/brick)
M:120m[C:45m|15mi][R:35m|4mi|8:45/mi]T1:4m,T2:3m
│   │   └── Individual activities in brackets
│   └── Total duration
└── Type
```

### Formatting Functions

```python
def format_strength_compact(workout: WorkoutSnapshot) -> str:
    exercises = ",".join([
        f"{e['name']}({e['sets']}×{e['reps']}@{e['weight']})"
        + ("#PR" if e.get('is_pr') else "")
        for e in workout.exercises[:4]  # Top 4 exercises
    ])
    muscles = ",".join(workout.muscle_groups[:3])
    return f"S:{workout.duration}m|{workout.volume_kg}kg|{muscles} {exercises}"

def format_run_compact(run: RunWorkout) -> str:
    zones = ",".join([f"Z{z}:{m}m" for z, m in run.hr_zones.items() if m > 0])
    return (f"R:{run.duration}m|{run.distance_mi}mi|{run.pace}|"
            f"{zones}|+{run.elevation_ft}ft|hr{run.avg_hr}avg")

def format_swim_compact(swim: SwimWorkout) -> str:
    strokes = ",".join([f"{s}:{n}" for s, n in swim.stroke_laps.items()])
    return (f"W:{swim.duration}m|{swim.distance_yd}yd|{swim.pace_per_100}|"
            f"{strokes}|spm{swim.strokes_per_min}|swolf{swim.avg_swolf}")
```

---

## Cross-Modality Pattern Detection

### What to Look For

```python
CROSS_MODALITY_ANALYSIS_PROMPT = """
Analyze this athlete's multi-sport training data for cross-modality patterns.

Look for:

1. SEQUENCING EFFECTS
   - Do heavy leg days affect running performance the next day?
   - Does yoga/mobility work correlate with fewer issues?
   - Rest day positioning effects on performance

2. INTERFERENCE PATTERNS
   - High running volume vs. lower body strength gains
   - Swimming volume vs. upper body hypertrophy
   - Competing adaptations

3. SYNERGY PATTERNS
   - Does cycling improve running (or vice versa)?
   - Zone 2 cardio volume vs. recovery metrics
   - Cross-training benefits

4. RECOVERY OPTIMIZATION
   - Which activity combinations lead to better sleep?
   - HRV patterns after different training loads
   - Optimal rest positioning

5. PERFORMANCE PREDICTORS
   - What precedes PR days?
   - Training patterns before breakthrough performances
   - Warning signs before performance dips

Be specific. Reference actual dates and data points.
"""
```

### Data Structure for Pattern Detection

```python
@dataclass
class DailySnapshot:
    """Complete snapshot for pattern analysis."""
    date: str  # YYYY-MM-DD

    # All workouts this day (can be multiple)
    workouts: list[WorkoutSnapshot]

    # Health metrics
    sleep_hours: float
    hrv_ms: int
    resting_hr: int

    # Nutrition summary
    calories: int
    protein_g: int

    # Computed load score (normalized 0-100)
    training_load: float

    # Rolling metrics
    load_7d_avg: float
    acute_chronic_ratio: float
```

### Pattern Examples to Surface

| Pattern | Data Needed | Insight |
|---------|-------------|---------|
| Leg day → run interference | Squat volume, next-day run pace/HR | "Runs within 36h of squats show elevated HR" |
| Yoga → sleep benefit | Evening yoga, same-night sleep score | "Evening yoga correlates with +12% deep sleep" |
| Volume overload | Weekly totals, HRV trend | "ACR >1.4 for 2 weeks, HRV declining" |
| PR predictor | Rest days before, sleep, protein | "PRs follow 2 rest days + >7h sleep" |

---

## Workout Type Inference

### The Disambiguation Problem

When user asks "how should I recover from yesterday's workout?", how does the AI know which workout if there were multiple?

### Strategy 1: Recency-Weighted Default

```python
def infer_workout_from_context(
    user_message: str,
    recent_workouts: list[Workout],  # Last 48 hours
    conversation_history: list[Message]
) -> Optional[Workout]:
    """Infer which workout the user is asking about."""

    message_lower = user_message.lower()

    # 1. Check for explicit type mentions
    type_keywords = {
        "strength": ["lift", "workout", "gym", "weights", "chest", "legs"],
        "run": ["run", "jog", "running"],
        "cycle": ["ride", "bike", "cycling"],
        "swim": ["swim", "swimming", "pool"],
        "yoga": ["yoga", "stretch", "mobility"]
    }

    mentioned_type = None
    for workout_type, keywords in type_keywords.items():
        if any(kw in message_lower for kw in keywords):
            mentioned_type = workout_type
            break

    # 2. Check for time references
    time_ref = extract_time_reference(message_lower)  # "yesterday", "this morning"

    # 3. Filter candidates
    candidates = recent_workouts
    if mentioned_type:
        candidates = [w for w in candidates if w.type == mentioned_type]
    if time_ref:
        candidates = [w for w in candidates if matches_time(w.date, time_ref)]

    if candidates:
        return candidates[0]  # Most recent matching

    # 4. Check conversation context (was a workout mentioned recently?)
    last_discussed = extract_from_history(conversation_history)
    if last_discussed:
        return last_discussed

    # 5. Default to most recent
    return recent_workouts[0] if recent_workouts else None
```

### Strategy 2: Multi-Workout Day Handling

When someone did multiple workouts in a day:

```python
def format_multi_workout_day(date: str, workouts: list[Workout]) -> str:
    """Show multiple same-day workouts together."""
    if len(workouts) == 1:
        return workouts[0].to_compact()

    lines = [f"{date}: {len(workouts)} sessions"]
    for i, w in enumerate(workouts, 1):
        time = w.start_time.strftime("%I:%M %p")
        lines.append(f"  {i}. {time} - {w.to_compact()}")
    return "\n".join(lines)

# Example:
# Dec 15: 2 sessions
#   1. 6:30 AM - R:45m|5mi|9:00/mi|Z2:35m
#   2. 5:00 PM - S:55m|4200kg Squat(4×8@185),RDL(3×10@135)
```

### Strategy 3: Explicit Disambiguation

When truly ambiguous, the AI should ask:

```
System prompt addition:

When the user asks about "yesterday's workout" or "my last workout" and there
were multiple sessions that day, briefly acknowledge both and ask which:

"You had two sessions yesterday - a morning run (5mi, 9:00 pace) and an
evening leg session. Which one are you asking about?"
```

---

## Implementation Checklist

### Server Changes

- [ ] Extend `TopicDetector` with cardio and cross-training patterns
- [ ] Add `build_cardio_context()` function
- [ ] Add `build_cross_modality_context()` function
- [ ] Create `workout_notation.py` with compact formatters
- [ ] Add `query_cardio` and `query_cross_modality` tools
- [ ] Extend `DailySnapshot` with multi-workout support
- [ ] Add cross-modality analysis prompts to insight engine

### Critical Files

| File | Changes |
|------|---------|
| `server/tiered_context.py` | Add topic patterns, context builders |
| `server/insight_engine.py` | Cross-modality prompts |
| `server/workout_notation.py` | NEW: Compact formatters |
| `server/tools.py` | Add new tool schemas |
| `server/chat_context.py` | Integrate cardio context |

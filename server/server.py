"""AirFit Server - FastAPI backend that wraps CLI LLM tools."""
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from contextlib import asynccontextmanager
import os

import config
import llm_router
import hevy
import nutrition
import profile
import context_store
import insight_engine


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    providers = llm_router.get_available_providers()
    print(f"AirFit server starting on http://{config.HOST}:{config.PORT}")
    print(f"Available providers: {providers or 'NONE - install claude/gemini/ollama'}")
    yield
    print("AirFit server shutting down")


app = FastAPI(
    title="AirFit Server",
    description="AI fitness coach backend using CLI LLM tools",
    version="0.1.0",
    lifespan=lifespan
)

# Allow iOS app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Status Endpoint ---

@app.get("/status")
async def get_status():
    """Get server status including available LLM providers."""
    import sessions
    providers = llm_router.get_available_providers()
    session = sessions.get_or_create_session(provider="claude")

    return {
        "status": "ok",
        "available_providers": providers,
        "session_id": session.session_id if session else None,
        "message_count": session.message_count if session else 0
    }


# --- Request/Response Models ---

class ChatRequest(BaseModel):
    """Chat message from the iOS app."""
    message: str
    system_prompt: Optional[str] = None
    health_context: Optional[dict] = None  # HealthKit data
    nutrition_context: Optional[dict] = None  # Today's nutrition entries


class ChatResponse(BaseModel):
    """Chat response back to the iOS app."""
    response: str
    provider: str
    success: bool
    error: Optional[str] = None


class HealthStatus(BaseModel):
    """Server health check response."""
    status: str
    providers: list[str]
    hevy_configured: bool
    version: str


class NutritionParseRequest(BaseModel):
    """Request to parse food into macros."""
    food_text: str


class NutritionComponent(BaseModel):
    """Single food component."""
    name: str
    calories: int
    protein: int
    carbs: int
    fat: int


class NutritionParseResponse(BaseModel):
    """Parsed nutrition data."""
    success: bool
    name: Optional[str] = None
    calories: Optional[int] = None
    protein: Optional[int] = None
    carbs: Optional[int] = None
    fat: Optional[int] = None
    confidence: Optional[str] = None
    components: list[NutritionComponent] = []
    error: Optional[str] = None


class TrainingDayResponse(BaseModel):
    """Whether today is a training day."""
    is_training_day: bool
    workout_name: Optional[str] = None


class MacroStatusRequest(BaseModel):
    """Request for macro status feedback."""
    calories: int
    protein: int
    carbs: int
    fat: int
    is_training_day: bool = True


class MacroStatusResponse(BaseModel):
    """AI feedback on current macros."""
    feedback: str


class NutritionCorrectRequest(BaseModel):
    """Request to correct nutrition entry via AI."""
    original_name: str
    original_calories: int
    original_protein: int
    original_carbs: int
    original_fat: int
    correction: str  # Natural language correction


class NutritionCorrectResponse(BaseModel):
    """Corrected nutrition data."""
    success: bool
    name: Optional[str] = None
    calories: Optional[int] = None
    protein: Optional[int] = None
    carbs: Optional[int] = None
    fat: Optional[int] = None
    error: Optional[str] = None


# --- Endpoints ---

@app.get("/health", response_model=HealthStatus)
async def health_check():
    """Check server status and available providers."""
    return HealthStatus(
        status="ok",
        providers=llm_router.get_available_providers(),
        hevy_configured=bool(os.getenv("HEVY_API_KEY")),
        version="0.1.0"
    )


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    Send a message to the AI coach.

    The server will:
    1. Load user profile for personalized context
    2. Fetch Hevy workout data (if API key configured)
    3. Include health context from iOS (HealthKit)
    4. Try available LLM providers in priority order
    5. Extract insights from conversation to evolve profile
    6. Return the AI response
    """
    context_parts = []

    # Get Hevy workout data (server-side)
    hevy_context = await hevy.get_hevy_context()
    if hevy_context.get("hevy_workouts"):
        context_parts.append(hevy_context["hevy_workouts"])

    # Add HealthKit data from iOS (if provided)
    if request.health_context:
        context_parts.append(format_health_context(request.health_context))

    # Add nutrition data from iOS (if provided)
    if request.nutrition_context:
        context_parts.append(format_nutrition_context(request.nutrition_context))

    # Build the full prompt
    if context_parts:
        context_str = "\n\n".join(context_parts)
        prompt = f"{context_str}\n\nUser message: {request.message}"
    else:
        prompt = request.message

    # Use profile-based system prompt (unless client overrides)
    user_profile = profile.load_profile()
    system_prompt = request.system_prompt or user_profile.to_system_prompt()

    # Call the LLM
    result = await llm_router.chat(prompt, system_prompt)

    # Learn from this conversation (async, don't block response)
    if result.success:
        import asyncio
        asyncio.create_task(
            profile.update_profile_from_conversation(request.message, result.text)
        )

    return ChatResponse(
        response=result.text,
        provider=result.provider,
        success=result.success,
        error=result.error
    )


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


@app.post("/nutrition/parse", response_model=NutritionParseResponse)
async def parse_nutrition(request: NutritionParseRequest):
    """
    Parse food text into nutrition data using AI.

    Example: "chipotle bowl with chicken, rice, beans, guac"
    Returns: calories, protein, carbs, fat estimates with component breakdown
    """
    result = await nutrition.parse_food(request.food_text)

    if result is None:
        return NutritionParseResponse(
            success=False,
            error="Could not parse nutrition data"
        )

    components = [
        NutritionComponent(
            name=c.name,
            calories=c.calories,
            protein=c.protein,
            carbs=c.carbs,
            fat=c.fat
        )
        for c in result.components
    ]

    return NutritionParseResponse(
        success=True,
        name=result.name,
        calories=result.calories,
        protein=result.protein,
        carbs=result.carbs,
        fat=result.fat,
        confidence=result.confidence,
        components=components
    )


@app.get("/nutrition/training-day", response_model=TrainingDayResponse)
async def check_training_day():
    """
    Check if today is a training day based on Hevy workouts.
    """
    from datetime import date, datetime

    workouts = await hevy.get_recent_workouts(days=1, limit=5)

    if workouts:
        today = date.today()
        for w in workouts:
            # Handle timezone-aware and naive datetimes
            workout_date = w.date.date() if isinstance(w.date, datetime) else w.date
            if workout_date == today:
                return TrainingDayResponse(
                    is_training_day=True,
                    workout_name=w.title
                )

    return TrainingDayResponse(is_training_day=False)


@app.post("/nutrition/status", response_model=MacroStatusResponse)
async def macro_status(request: MacroStatusRequest):
    """
    Get AI feedback on current macro intake.
    """
    feedback = await nutrition.get_macro_feedback(
        request.calories,
        request.protein,
        request.carbs,
        request.fat,
        request.is_training_day
    )
    return MacroStatusResponse(feedback=feedback)


@app.post("/nutrition/correct", response_model=NutritionCorrectResponse)
async def correct_nutrition(request: NutritionCorrectRequest):
    """
    Apply a natural language correction to nutrition data.

    Example corrections:
    - "that was a large portion"
    - "I had two of those"
    - "it was grilled, not fried"
    """
    result = await nutrition.correct_entry(
        request.original_name,
        request.original_calories,
        request.original_protein,
        request.original_carbs,
        request.original_fat,
        request.correction
    )

    if result is None:
        return NutritionCorrectResponse(
            success=False,
            error="Could not apply correction"
        )

    return NutritionCorrectResponse(
        success=True,
        name=result.name,
        calories=result.calories,
        protein=result.protein,
        carbs=result.carbs,
        fat=result.fat
    )


class ProfileResponse(BaseModel):
    """What the AI knows about the user."""
    # Identity
    name: str = ""
    age: int = 0
    height: str = ""
    occupation: str = ""

    # Current state
    current_weight_lbs: float = 0
    current_body_fat_pct: float = 0

    # Goals
    goals: list[str] = []
    target_weight_lbs: float = 0
    target_body_fat_pct: float = 0

    # Training
    training_days_per_week: str = ""
    training_style: list[str] = []
    favorite_activities: list[str] = []

    # Nutrition
    training_day_targets: dict = {}
    rest_day_targets: dict = {}
    nutrition_guidelines: list[str] = []

    # Other
    constraints: list[str] = []
    preferences: list[str] = []
    context: list[str] = []
    patterns: list[str] = []
    communication_style: str = ""

    # Meta
    insights_count: int = 0
    recent_insights: list[dict] = []
    has_profile: bool = False
    onboarding_complete: bool = False


@app.get("/profile", response_model=ProfileResponse)
async def get_profile():
    """
    Get what the AI has learned about you.

    This shows goals, preferences, constraints, and patterns
    that the AI has extracted from conversations and observed behavior.
    """
    return ProfileResponse(**profile.get_profile_summary())


@app.delete("/profile")
async def reset_profile():
    """
    Clear the AI's knowledge about you.

    Use this to start fresh or for testing.
    Also clears chat session so the AI starts fresh.
    """
    profile.clear_profile()
    llm_router.clear_chat_session()
    return {"status": "profile cleared", "session_cleared": True}


@app.post("/profile/seed")
async def seed_profile():
    """
    Seed the profile with Brian's data for testing.

    This creates a fully populated profile with personality settings.
    Also clears the chat session so the new profile takes effect.
    """
    seeded = profile.seed_brian_profile()
    # Clear chat session so new system prompt takes effect
    llm_router.clear_chat_session()
    return {
        "status": "seeded",
        "name": seeded.name,
        "onboarding_complete": seeded.onboarding_complete,
        "session_cleared": True
    }


@app.delete("/chat/session")
async def clear_chat_session():
    """
    Clear the chat session to start a fresh conversation.

    Use this when you want to reset the conversation context,
    similar to starting a new chat in Claude.
    """
    success = llm_router.clear_chat_session()
    return {"status": "session cleared" if success else "no session to clear"}


@app.post("/profile/learn")
async def trigger_learning():
    """
    Trigger the AI to analyze patterns from recent behavior.

    This analyzes nutrition and workout data to find patterns.
    Normally runs automatically, but can be triggered manually.
    """
    # Get recent nutrition data
    # TODO: Pull from actual data when we have iOS sending summaries

    # For now, just return current profile
    user_profile = profile.load_profile()
    return {"status": "learning complete", "patterns": user_profile.patterns}


# --- Insights Endpoints ---

class DailySyncData(BaseModel):
    """Daily data sent from iOS for syncing."""
    date: str  # YYYY-MM-DD

    # Nutrition
    calories: int = 0
    protein: int = 0
    carbs: int = 0
    fat: int = 0
    nutrition_entries: int = 0

    # Health (from HealthKit)
    steps: int = 0
    active_calories: int = 0
    weight_lbs: Optional[float] = None
    body_fat_pct: Optional[float] = None
    sleep_hours: Optional[float] = None
    resting_hr: Optional[int] = None
    hrv_ms: Optional[float] = None


class SyncRequest(BaseModel):
    """Request to sync daily data from iOS."""
    days: list[DailySyncData]


class InsightResponse(BaseModel):
    """An insight returned to the client."""
    id: str
    category: str
    tier: int
    title: str
    body: str
    importance: float
    created_at: str
    suggested_actions: list[str] = []


class ContextSummary(BaseModel):
    """Aggregated context for a time range."""
    period_days: int
    nutrition_days: int

    # Averages
    avg_calories: int
    avg_protein: int
    avg_carbs: int
    avg_fat: int

    # Health
    avg_weight: Optional[float] = None
    weight_change: Optional[float] = None
    avg_sleep: Optional[float] = None
    avg_steps: int = 0

    # Workouts
    total_workouts: int = 0
    avg_volume_per_workout: float = 0.0

    # Compliance
    protein_compliance: Optional[float] = None
    calorie_compliance: Optional[float] = None


@app.post("/insights/sync")
async def sync_insights_data(request: SyncRequest):
    """
    Sync daily data from iOS to the context store.

    iOS sends daily summaries (nutrition, health metrics).
    Server stores them for pattern analysis.
    """
    synced_dates = []

    for day in request.days:
        # Create nutrition snapshot
        nutrition_data = context_store.NutritionSnapshot(
            calories=day.calories,
            protein=day.protein,
            carbs=day.carbs,
            fat=day.fat,
            entry_count=day.nutrition_entries
        )

        # Create health snapshot
        health_data = context_store.HealthSnapshot(
            steps=day.steps,
            active_calories=day.active_calories,
            weight_lbs=day.weight_lbs,
            body_fat_pct=day.body_fat_pct,
            sleep_hours=day.sleep_hours,
            resting_hr=day.resting_hr,
            hrv_ms=day.hrv_ms
        )

        # Get or create snapshot for this date
        snapshot = context_store.get_snapshot(day.date) or context_store.DailySnapshot(date=day.date)

        # Update with new data
        snapshot.nutrition = nutrition_data
        snapshot.health = health_data

        # Track what was synced
        if "nutrition" not in snapshot.sources_synced:
            snapshot.sources_synced.append("nutrition")
        if "health" not in snapshot.sources_synced:
            snapshot.sources_synced.append("health")

        context_store.upsert_snapshot(snapshot)
        synced_dates.append(day.date)

    return {
        "status": "synced",
        "dates_synced": synced_dates,
        "count": len(synced_dates)
    }


@app.get("/insights/context", response_model=ContextSummary)
async def get_insights_context(range: str = "week"):
    """
    Get aggregated context for AI analysis.

    Range options: week, month, quarter (90 days)
    """
    days_map = {"week": 7, "month": 30, "quarter": 90}
    days = days_map.get(range, 7)

    snapshots = context_store.get_recent_snapshots(days)

    if not snapshots:
        return ContextSummary(
            period_days=days,
            nutrition_days=0,
            avg_calories=0,
            avg_protein=0,
            avg_carbs=0,
            avg_fat=0
        )

    averages = context_store.compute_averages(snapshots)
    compliance = context_store.compute_compliance(snapshots)

    return ContextSummary(
        period_days=averages.get("period_days", days),
        nutrition_days=averages.get("nutrition_days", 0),
        avg_calories=averages.get("avg_calories", 0),
        avg_protein=averages.get("avg_protein", 0),
        avg_carbs=averages.get("avg_carbs", 0),
        avg_fat=averages.get("avg_fat", 0),
        avg_weight=averages.get("avg_weight"),
        weight_change=averages.get("weight_change"),
        avg_sleep=averages.get("avg_sleep"),
        avg_steps=averages.get("avg_steps", 0),
        total_workouts=averages.get("total_workouts", 0),
        avg_volume_per_workout=averages.get("avg_volume_per_workout", 0.0),
        protein_compliance=compliance.get("protein_compliance"),
        calorie_compliance=compliance.get("calorie_compliance")
    )


@app.get("/insights", response_model=list[InsightResponse])
async def get_insights(category: Optional[str] = None, limit: int = 10):
    """
    Get AI-generated insights.

    Optionally filter by category: correlation, trend, anomaly, milestone, nudge
    """
    insights = context_store.get_insights(category=category, limit=limit)

    return [
        InsightResponse(
            id=i.id,
            category=i.category,
            tier=i.tier,
            title=i.title,
            body=i.body,
            importance=i.importance,
            created_at=i.created_at,
            suggested_actions=i.suggested_actions
        )
        for i in insights
    ]


@app.post("/insights/{insight_id}/engage")
async def engage_insight(insight_id: str, action: str, feedback: Optional[str] = None):
    """
    Record user engagement with an insight.

    Actions: viewed, tapped, dismissed, acted
    Feedback (optional): agree, disagree, not_relevant
    """
    context_store.update_insight_engagement(insight_id, action, feedback)
    return {"status": "recorded"}


@app.get("/insights/snapshots")
async def get_snapshots(days: int = 30):
    """
    Get raw daily snapshots for debugging/visualization.
    """
    snapshots = context_store.get_recent_snapshots(days)
    return {
        "count": len(snapshots),
        "snapshots": [
            {
                "date": s.date,
                "nutrition": {
                    "calories": s.nutrition.calories,
                    "protein": s.nutrition.protein,
                    "carbs": s.nutrition.carbs,
                    "fat": s.nutrition.fat
                },
                "health": {
                    "steps": s.health.steps,
                    "weight_lbs": s.health.weight_lbs,
                    "sleep_hours": s.health.sleep_hours
                },
                "workout": {
                    "count": s.workout.workout_count,
                    "volume_kg": s.workout.total_volume_kg
                },
                "sources_synced": s.sources_synced
            }
            for s in snapshots
        ]
    }


@app.post("/insights/sync-hevy")
async def sync_hevy_data():
    """
    Sync all Hevy workout data to the context store.

    Fetches complete workout history and stores daily summaries.
    """
    workouts = await hevy.get_all_workouts()
    if not workouts:
        return {"status": "no workouts found", "count": 0}

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

    return {
        "status": "synced",
        "workouts_found": len(workouts),
        "days_synced": len(daily_workouts)
    }


class GenerateInsightsRequest(BaseModel):
    """Request to generate new insights."""
    days: int = 90
    force: bool = False


class GenerateInsightsResponse(BaseModel):
    """Response with generated insights."""
    success: bool
    insights_generated: int
    token_estimate: int
    insights: list[InsightResponse]
    error: Optional[str] = None


@app.post("/insights/generate", response_model=GenerateInsightsResponse)
async def generate_insights(request: GenerateInsightsRequest):
    """
    Generate new AI insights from all available data.

    This feeds raw data to Claude and lets it reason freely.
    No hardcoded assumptions - the AI decides what's interesting.

    Args:
        days: How many days of data to analyze (default 90)
        force: Generate even if recent insights exist
    """
    # Load profile for context
    user_profile = profile.load_profile()
    profile_dict = {
        "goals": user_profile.goals,
        "constraints": user_profile.constraints,
        "preferences": user_profile.preferences,
        "communication_style": user_profile.communication_style
    }

    # Get data and estimate tokens
    snapshots = context_store.get_recent_snapshots(request.days)
    formatted_data = insight_engine.format_all_data_compact(snapshots, profile_dict)
    token_estimate = insight_engine.count_tokens_estimate(formatted_data)

    try:
        # Generate insights
        insights = await insight_engine.generate_insights(
            days=request.days,
            profile=profile_dict,
            force_refresh=request.force
        )

        return GenerateInsightsResponse(
            success=True,
            insights_generated=len(insights),
            token_estimate=token_estimate,
            insights=[
                InsightResponse(
                    id=i.id,
                    category=i.category,
                    tier=i.tier,
                    title=i.title,
                    body=i.body,
                    importance=i.importance,
                    created_at=i.created_at,
                    suggested_actions=i.suggested_actions
                )
                for i in insights
            ]
        )
    except Exception as e:
        return GenerateInsightsResponse(
            success=False,
            insights_generated=0,
            token_estimate=token_estimate,
            insights=[],
            error=str(e)
        )


@app.get("/insights/data-preview")
async def preview_insight_data(days: int = 90):
    """
    Preview the raw data that will be sent to the AI.

    Use this to see exactly what the insight engine sees.
    Helpful for debugging and understanding token usage.
    """
    # Load profile
    user_profile = profile.load_profile()
    profile_dict = {
        "goals": user_profile.goals,
        "constraints": user_profile.constraints,
        "preferences": user_profile.preferences,
        "communication_style": user_profile.communication_style
    }

    # Get formatted data
    snapshots = context_store.get_recent_snapshots(days)
    formatted_data = insight_engine.format_all_data_compact(snapshots, profile_dict)
    token_estimate = insight_engine.count_tokens_estimate(formatted_data)

    return {
        "days_requested": days,
        "days_with_data": len(snapshots),
        "token_estimate": token_estimate,
        "character_count": len(formatted_data),
        "data_preview": formatted_data
    }


if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host=config.HOST,
        port=config.PORT,
        reload=True  # Auto-reload during development
    )

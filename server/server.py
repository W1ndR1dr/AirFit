"""AirFit Server - FastAPI backend that wraps CLI LLM tools."""
from dotenv import load_dotenv
load_dotenv()  # Load .env before other imports that use env vars

import json
import uvicorn
from datetime import datetime, timedelta
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
import scheduler


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    providers = llm_router.get_available_providers()
    print(f"AirFit server starting on http://{config.HOST}:{config.PORT}")
    print(f"Available providers: {providers or 'NONE - install claude/gemini/ollama'}")

    # Start background scheduler for async AI tasks
    scheduler.start_scheduler()

    yield

    # Cleanup
    scheduler.stop_scheduler()
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


@app.get("/scheduler/status")
async def get_scheduler_status():
    """Get background scheduler status.

    Shows what the background agents are doing:
    - When insights were last generated
    - When next generation will occur
    - Current generation status
    """
    return scheduler.get_scheduler_status()


@app.post("/scheduler/trigger-insights")
async def trigger_insight_generation(force: bool = False):
    """Manually trigger insight generation.

    Args:
        force: If True, generate even if recently generated
    """
    result = await scheduler.run_insight_generation(force=force)
    return result


@app.post("/scheduler/trigger-hevy-sync")
async def trigger_hevy_sync():
    """Manually trigger Hevy workout sync."""
    result = await scheduler.run_hevy_sync()
    return result


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
    2. Inject pre-computed insights from background analysis
    3. Fetch Hevy workout data (if API key configured)
    4. Include health context from iOS (HealthKit)
    5. Try available LLM providers in priority order
    6. Extract insights from conversation to evolve profile
    7. Return the AI response
    """
    context_parts = []

    # Inject pre-computed insights from background agent
    # This is the key multi-agent integration - chat stays fast because
    # heavy insight generation already happened in background
    insights_context = scheduler.get_insights_for_chat_context(limit=3)
    if insights_context:
        context_parts.append(insights_context)

    # Add weekly summary for quick reference
    weekly_summary = scheduler.get_weekly_summary_for_chat()
    if weekly_summary:
        context_parts.append(weekly_summary)

    # Add body composition trends (EMA-smoothed for signal, not noise)
    body_comp_trends = context_store.format_body_comp_for_chat()
    if body_comp_trends:
        context_parts.append(body_comp_trends)

    # Add rolling 7-day training volume (set tracker)
    set_tracker_context = await hevy.format_set_tracker_for_chat()
    if set_tracker_context:
        context_parts.append(set_tracker_context)

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


class ProfileItemUpdate(BaseModel):
    category: str  # "goals", "context", "preferences", "constraints", "patterns"
    old_value: str
    new_value: Optional[str] = None  # None = delete


@app.patch("/profile/item")
async def update_profile_item(request: ProfileItemUpdate):
    """
    Update or delete a single profile item.

    Used for inline editing in the iOS app.
    """
    p = profile.load_profile()

    # Get the list based on category
    category_map = {
        "goals": p.goals,
        "context": p.context,
        "preferences": p.preferences,
        "constraints": p.constraints,
        "patterns": p.patterns,
        "life_context": p.life_context,
        "training_style": p.training_style,
    }

    if request.category not in category_map:
        raise HTTPException(status_code=400, detail=f"Invalid category: {request.category}")

    items = category_map[request.category]

    if request.old_value not in items:
        raise HTTPException(status_code=404, detail="Item not found")

    idx = items.index(request.old_value)

    if request.new_value is None:
        # Delete
        items.pop(idx)
        action = "deleted"
    else:
        # Update
        items[idx] = request.new_value
        action = "updated"

    profile.save_profile(p)

    return {"status": action, "category": request.category}


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


class OnboardingChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


@app.post("/chat/onboarding")
async def onboarding_chat(request: OnboardingChatRequest):
    """
    Onboarding conversation endpoint.

    This uses the ONBOARDING_SYSTEM_PROMPT to conduct a structured interview
    disguised as natural conversation. Profile data is extracted after each turn.
    """
    import sessions

    # Get or create session
    session = sessions.get_or_create_session(provider="claude")

    # Use onboarding system prompt
    system_prompt = profile.ONBOARDING_SYSTEM_PROMPT

    # If first message (empty), get initial greeting
    if not request.message:
        user_message = "Hi! I'm starting the onboarding process."
    else:
        user_message = request.message

    try:
        response = llm_router.chat(
            message=user_message,
            system_prompt=system_prompt,
            provider="claude"  # Use Claude for onboarding
        )

        # Extract profile info from conversation
        if request.message:  # Only extract if there was actual user input
            profile.update_profile_from_conversation(request.message, response)

        # Get updated profile completeness
        profile_summary = profile.get_profile_summary()
        completeness = profile_summary.get("profile_completeness", {})

        return {
            "response": response,
            "session_id": session.session_id,
            "profile_completeness": completeness
        }

    except Exception as e:
        return {
            "response": "I'm having trouble connecting. Let's try again!",
            "session_id": session.session_id if session else None,
            "profile_completeness": None,
            "error": str(e)
        }


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


@app.post("/profile/finalize-onboarding")
async def finalize_onboarding():
    """
    Finalize the onboarding process.

    Call this after the initial conversation to:
    1. Generate the personalized personality prompt
    2. Mark onboarding as complete
    3. Clear the chat session to start fresh with the new profile

    The system will synthesize everything learned into a rich
    personality profile that makes the AI feel personal.
    """
    # Generate the personality notes from gathered data
    user_profile = await profile.finalize_onboarding([])

    # Clear chat session so new personality takes effect
    llm_router.clear_chat_session()

    return {
        "status": "onboarding_complete",
        "name": user_profile.name,
        "has_personality": bool(user_profile.personality_notes),
        "preview": user_profile.personality_notes[:500] if user_profile.personality_notes else None
    }


@app.post("/profile/regenerate-personality")
async def regenerate_personality():
    """
    Regenerate the personality prompt from current profile data.

    Use this if you've manually updated profile fields and want
    to regenerate the personality notes to match.
    """
    user_profile = profile.load_profile()
    personality = await profile.generate_personality_notes(user_profile)

    if personality:
        user_profile.personality_notes = personality
        profile.save_profile(user_profile)

    # Clear session so new personality takes effect
    llm_router.clear_chat_session()

    return {
        "status": "regenerated",
        "personality": personality[:500] if personality else None
    }


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
    supporting_data: dict = {}


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


# --- Body Metrics Models ---

class MetricPoint(BaseModel):
    """Single data point for time series charts."""
    date: str
    value: float


class CurrentBodyMetrics(BaseModel):
    """Current body composition values."""
    weight_lbs: Optional[float] = None
    body_fat_pct: Optional[float] = None
    lean_mass_lbs: Optional[float] = None


class BodyTrends(BaseModel):
    """30-day change trends."""
    weight_change_30d: Optional[float] = None
    body_fat_change_30d: Optional[float] = None
    lean_mass_change_30d: Optional[float] = None


class BodyMetricsResponse(BaseModel):
    """Body composition history for charts."""
    current: CurrentBodyMetrics
    weight_history: list[MetricPoint]
    body_fat_history: list[MetricPoint]
    lean_mass_history: list[MetricPoint]
    trends: BodyTrends


@app.get("/health/body-metrics", response_model=BodyMetricsResponse)
async def get_body_metrics(days: int = 90):
    """
    Get body composition history for the Body tab charts.

    Returns weight, body fat %, and lean mass over time.
    """
    snapshots = context_store.get_recent_snapshots(days)

    # Build history arrays (only include days with data)
    weight_history = []
    body_fat_history = []
    lean_mass_history = []

    for s in sorted(snapshots, key=lambda x: x.date):
        if s.health.weight_lbs:
            weight_history.append(MetricPoint(date=s.date, value=s.health.weight_lbs))

            # Calculate lean mass if we have body fat
            if s.health.body_fat_pct:
                body_fat_history.append(MetricPoint(date=s.date, value=s.health.body_fat_pct))
                fat_mass = s.health.weight_lbs * (s.health.body_fat_pct / 100)
                lean_mass = s.health.weight_lbs - fat_mass
                lean_mass_history.append(MetricPoint(date=s.date, value=round(lean_mass, 1)))
            elif s.health.lean_mass_lbs:
                lean_mass_history.append(MetricPoint(date=s.date, value=s.health.lean_mass_lbs))

    # Get current values (most recent with data)
    current_weight = weight_history[-1].value if weight_history else None
    current_bf = body_fat_history[-1].value if body_fat_history else None
    current_lean = lean_mass_history[-1].value if lean_mass_history else None

    # Calculate 30-day trends
    def calc_trend(history: list[MetricPoint], days_back: int = 30) -> Optional[float]:
        if len(history) < 2:
            return None
        cutoff = (datetime.now() - timedelta(days=days_back)).strftime("%Y-%m-%d")
        recent = [p for p in history if p.date >= cutoff]
        if len(recent) < 2:
            return None
        return round(recent[-1].value - recent[0].value, 2)

    return BodyMetricsResponse(
        current=CurrentBodyMetrics(
            weight_lbs=current_weight,
            body_fat_pct=current_bf,
            lean_mass_lbs=current_lean
        ),
        weight_history=weight_history,
        body_fat_history=body_fat_history,
        lean_mass_history=lean_mass_history,
        trends=BodyTrends(
            weight_change_30d=calc_trend(weight_history),
            body_fat_change_30d=calc_trend(body_fat_history),
            lean_mass_change_30d=calc_trend(lean_mass_history)
        )
    )


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
            suggested_actions=i.suggested_actions,
            supporting_data=i.supporting_data
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


class InsightDiscussRequest(BaseModel):
    """Request to discuss an insight."""
    message: str


class InsightDiscussResponse(BaseModel):
    """Response from insight discussion."""
    response: str
    provider: str
    success: bool
    insight_title: str
    error: Optional[str] = None


@app.post("/insights/{insight_id}/discuss", response_model=InsightDiscussResponse)
async def discuss_insight(insight_id: str, request: InsightDiscussRequest):
    """
    Start or continue a conversation about a specific insight.

    This endpoint provides deep-dive discussion on an insight with full context:
    - The original insight (title, body, supporting_data)
    - The data context that generated the insight
    - User's profile for personalized responses

    Use this for "Tell me more" functionality.
    """
    # Load the insight
    insight = context_store.get_insight_by_id(insight_id)
    if not insight:
        return InsightDiscussResponse(
            response="I couldn't find that insight. It may have been removed.",
            provider="none",
            success=False,
            insight_title="Unknown",
            error="Insight not found"
        )

    # Build rich context for the discussion
    context_parts = []

    # The insight itself with supporting data
    context_parts.append(f"""The user wants to discuss this insight:

INSIGHT:
Title: {insight.title}
Body: {insight.body}
Category: {insight.category}
Supporting Data: {json.dumps(insight.supporting_data) if insight.supporting_data else 'None'}
Suggested Actions: {', '.join(insight.suggested_actions) if insight.suggested_actions else 'None'}
""")

    # Add the original data context used to generate the insight
    if insight.conversation_context:
        context_parts.append(f"""ORIGINAL DATA CONTEXT (what this insight was based on):
{insight.conversation_context}
""")

    # Add recent weekly summary for additional context
    weekly_summary = scheduler.get_weekly_summary_for_chat()
    if weekly_summary:
        context_parts.append(f"CURRENT WEEKLY SUMMARY:\n{weekly_summary}")

    # Build the prompt
    context_str = "\n\n".join(context_parts)
    prompt = f"""{context_str}

USER MESSAGE: {request.message}

Respond conversationally. Reference specific data points from the insight and supporting data. Be helpful and actionable."""

    # Use profile-based system prompt
    user_profile = profile.load_profile()
    system_prompt = user_profile.to_system_prompt()

    # Call the LLM
    result = await llm_router.chat(prompt, system_prompt)

    # Track engagement
    context_store.update_insight_engagement(insight_id, "discussed")

    return InsightDiscussResponse(
        response=result.text,
        provider=result.provider,
        success=result.success,
        insight_title=insight.title,
        error=result.error
    )


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


# --- Training Tab Endpoints (Hevy data visualization) ---

class MuscleGroupData(BaseModel):
    """Data for a single muscle group in the set tracker."""
    current: int
    min: int
    max: int
    status: str  # in_zone, below, at_floor, above


class SetTrackerResponse(BaseModel):
    """Rolling 7-day set tracker data by muscle group."""
    window_days: int
    muscle_groups: dict[str, MuscleGroupData]
    last_sync: Optional[str] = None


class PRData(BaseModel):
    """Personal record data for a lift."""
    weight_lbs: float
    reps: int
    date: str


class HistoryPoint(BaseModel):
    """Single point in lift history for sparkline."""
    date: str
    weight_lbs: float


class LiftData(BaseModel):
    """Progress data for a single lift."""
    name: str
    workout_count: int
    current_pr: PRData
    history: list[HistoryPoint]


class LiftProgressResponse(BaseModel):
    """All-time PR progress for top lifts."""
    lifts: list[LiftData]


class WorkoutSummary(BaseModel):
    """Summary of a single workout."""
    id: str
    title: str
    date: str
    days_ago: int
    duration_minutes: int
    exercises: list[str]
    total_volume_lbs: float


class RecentWorkoutsResponse(BaseModel):
    """Recent workouts for display."""
    workouts: list[WorkoutSummary]


@app.get("/hevy/set-tracker", response_model=SetTrackerResponse)
async def get_set_tracker(days: int = 7):
    """
    Get rolling set counts by muscle group for the Training tab.

    Returns progress toward optimal weekly volume for each muscle group.
    Used for the "Rolling 7-Day Sets" hero section.
    """
    from datetime import datetime

    try:
        muscle_data = await hevy.get_rolling_set_counts(days)

        return SetTrackerResponse(
            window_days=days,
            muscle_groups={
                name: MuscleGroupData(**data)
                for name, data in muscle_data.items()
            },
            last_sync=datetime.now().isoformat()
        )
    except Exception as e:
        print(f"Error getting set tracker: {e}")
        # Return empty data on error
        return SetTrackerResponse(
            window_days=days,
            muscle_groups={},
            last_sync=None
        )


@app.get("/hevy/lift-progress", response_model=LiftProgressResponse)
async def get_lift_progress(top_n: int = 6):
    """
    Get all-time PR progress for top lifts.

    Auto-detects the most frequently performed lifts and returns
    their PR history for sparkline visualization.
    """
    try:
        lifts = await hevy.get_lift_progress(top_n)

        return LiftProgressResponse(
            lifts=[
                LiftData(
                    name=lift["name"],
                    workout_count=lift["workout_count"],
                    current_pr=PRData(**lift["current_pr"]),
                    history=[HistoryPoint(**h) for h in lift["history"]]
                )
                for lift in lifts
            ]
        )
    except Exception as e:
        print(f"Error getting lift progress: {e}")
        return LiftProgressResponse(lifts=[])


@app.get("/hevy/recent-workouts", response_model=RecentWorkoutsResponse)
async def get_recent_workouts_endpoint(limit: int = 7):
    """
    Get recent workout summaries for display.

    Returns a simple list of recent workouts with basic stats.
    """
    try:
        workouts = await hevy.get_recent_workouts_summary(limit)

        return RecentWorkoutsResponse(
            workouts=[WorkoutSummary(**w) for w in workouts]
        )
    except Exception as e:
        print(f"Error getting recent workouts: {e}")
        return RecentWorkoutsResponse(workouts=[])


if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host=config.HOST,
        port=config.PORT,
        reload=True  # Auto-reload during development
    )

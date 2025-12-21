"""AirFit Server - FastAPI backend that wraps CLI LLM tools."""
from dotenv import load_dotenv
load_dotenv()  # Load .env before other imports that use env vars

import json
import uvicorn
from datetime import datetime, timedelta
from fastapi import FastAPI, HTTPException, Request
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
import chat_context
# Note: tiered_context.py is deprecated - we now use chat_context for AI-native context building
import exercise_store
import memory
import sessions
import tools


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
    detected_topics: list[str] = []  # Topics detected in user message (for debugging)


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
    Send a message to the AI coach with rich context injection.

    AI-Native Philosophy:
    - Give the LLM ALL relevant context (health, nutrition, workouts, insights)
    - Let the LLM decide what's relevant to the current message
    - No hardcoded keyword detection - trust the model's understanding

    The coach has full context but uses it naturally (like an informed friend).
    """
    # Build rich context (no topic filtering - let LLM focus naturally)
    context = await chat_context.build_chat_context(
        health_context=request.health_context,
        nutrition_context=request.nutrition_context
    )

    # Build the full prompt with all context
    if context.has_any_context():
        context_str = context.to_context_string()
        prompt = f"{context_str}\n\nUser message: {request.message}"
    else:
        prompt = request.message

    # Use profile-based system prompt (unless client overrides)
    user_profile = profile.load_profile()
    base_system_prompt = request.system_prompt or user_profile.to_system_prompt()

    # Inject relationship memory into system prompt
    memory_context = memory.get_memory_context()
    if memory_context:
        system_prompt = f"{base_system_prompt}\n\n--- RELATIONSHIP MEMORY ---\n{memory_context}"
    else:
        system_prompt = base_system_prompt

    # Call the LLM
    result = await llm_router.chat(prompt, system_prompt)

    # Process successful responses
    if result.success:
        import asyncio

        # Extract and store any memory markers from response (async)
        asyncio.create_task(
            _extract_memories_async(result.text)
        )

        # Learn from this conversation to evolve profile (async)
        asyncio.create_task(
            profile.update_profile_from_conversation(request.message, result.text)
        )

        # Strip memory markers from response before returning to user
        clean_response = memory.strip_memory_markers(result.text)
    else:
        clean_response = result.text

    return ChatResponse(
        response=clean_response,
        provider=result.provider,
        success=result.success,
        error=result.error,
        detected_topics=[]  # Deprecated: no longer using topic detection
    )


async def _extract_memories_async(response_text: str):
    """Helper to extract memories asynchronously."""
    try:
        memory.extract_and_store_memories(response_text)
    except Exception as e:
        print(f"Memory extraction error: {e}")


# --- Direct Gemini Support Endpoints ---
# These endpoints support iOS calling Gemini directly while still
# getting rich context and profile evolution from the server.

class ChatContextResponse(BaseModel):
    """Context bundle for direct Gemini calls from iOS."""
    system_prompt: str
    memory_context: str
    data_context: str
    profile_summary: str
    onboarding_complete: bool


@app.get("/chat/context", response_model=ChatContextResponse)
async def get_chat_context_for_direct_calls(
    include_health: bool = True,
    include_hevy: bool = True,
    include_insights: bool = True
):
    """
    Get system prompt + context for direct Gemini API calls from iOS.

    This endpoint enables the "hybrid direct API" architecture:
    - iOS stores the API key and calls Gemini directly (fast)
    - But still gets rich context from the server (profile, memory, insights)

    The iOS app should:
    1. Call this endpoint to get fresh context
    2. Use the system_prompt as Gemini's system_instruction
    3. Optionally append data_context to the first user message
    4. Call Gemini directly with the user's API key
    """
    # Build full context (same assembly as /chat uses)
    context = await chat_context.build_chat_context(
        health_context=None,  # iOS will provide this directly to Gemini
        nutrition_context=None,  # iOS will provide this directly to Gemini
        insights_limit=3 if include_insights else 0
    )

    # Get profile-based system prompt
    user_profile = profile.load_profile()
    base_system_prompt = user_profile.to_system_prompt()

    # Get relationship memory
    memory_context = memory.get_memory_context()

    # Combine system prompt with memory context
    if memory_context:
        full_system_prompt = f"{base_system_prompt}\n\n--- RELATIONSHIP MEMORY ---\n{memory_context}\n\n{memory.MEMORY_PROTOCOL}"
    else:
        full_system_prompt = f"{base_system_prompt}\n\n{memory.MEMORY_PROTOCOL}"

    # Build data context string
    data_context_parts = []
    if context.insights:
        data_context_parts.append(context.insights)
    if context.weekly_summary:
        data_context_parts.append(context.weekly_summary)
    if context.body_comp_trends:
        data_context_parts.append(context.body_comp_trends)
    if include_hevy:
        if context.set_tracker:
            data_context_parts.append(context.set_tracker)
        if context.hevy_workouts:
            data_context_parts.append(context.hevy_workouts)

    return ChatContextResponse(
        system_prompt=full_system_prompt,
        memory_context=memory_context or "",
        data_context="\n\n".join(data_context_parts),
        profile_summary=user_profile.summary or "",
        onboarding_complete=user_profile.onboarding_complete
    )


class ConversationExcerpt(BaseModel):
    """Conversation excerpt for profile evolution processing."""
    user_message: str
    ai_response: str


class ProcessConversationResponse(BaseModel):
    """Response from processing a conversation excerpt."""
    status: str
    memories_extracted: int
    profile_updated: bool


@app.post("/chat/process-conversation", response_model=ProcessConversationResponse)
async def process_conversation_for_evolution(request: ConversationExcerpt):
    """
    Process a conversation excerpt for profile evolution and memory extraction.

    Called by iOS after Gemini conversations to:
    1. Extract memory markers from the AI response
    2. Update the user profile based on conversation content
    3. Keep the "getting to know you" evolution working

    This endpoint should be called:
    - When the app backgrounds
    - When a new chat is started
    - When 5+ memory markers have accumulated locally
    """
    memories_extracted = 0
    profile_updated = False

    # Extract and store any memory markers from AI response
    if request.ai_response:
        memories_extracted = memory.extract_and_store_memories(request.ai_response)

    # Update profile from conversation (learns about user over time)
    if request.user_message and request.ai_response:
        try:
            await profile.update_profile_from_conversation(
                request.user_message,
                request.ai_response
            )
            profile_updated = True
        except Exception as e:
            print(f"Profile update error: {e}")
            profile_updated = False

    return ProcessConversationResponse(
        status="processed",
        memories_extracted=memories_extracted,
        profile_updated=profile_updated
    )


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
    Only counts workouts that meet a meaningful threshold:
    - At least 20 minutes duration, OR
    - At least 3 exercises logged
    This filters out accidental/partial logs.
    """
    from datetime import date, datetime

    workouts = await hevy.get_recent_workouts(days=1, limit=5)

    if workouts:
        today = date.today()
        for w in workouts:
            # Handle timezone-aware and naive datetimes
            workout_date = w.date.date() if isinstance(w.date, datetime) else w.date
            if workout_date == today:
                # Apply threshold: must be meaningful workout
                duration_minutes = getattr(w, 'duration_minutes', 0) or 0
                exercise_count = len(getattr(w, 'exercises', [])) if hasattr(w, 'exercises') else 0

                # Count as training if: 20+ min OR 3+ exercises
                if duration_minutes >= 20 or exercise_count >= 3:
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


@app.post("/profile/import-seed")
async def import_profile_seed(request: Request):
    """
    Import a profile from a seed JSON file (like brian_profile_seed.json).

    This endpoint handles the nested structure used in seed files:
    - identity: {name, age, height, occupation, summary}
    - body_composition: {current_weight_lbs, etc.}
    - training: {days_per_week, style, etc.}
    - nutrition: {training_day, rest_day, guidelines}

    For importing from /profile/export, use POST /profile/import instead.

    Usage:
        curl -X POST http://localhost:8080/profile/import-seed \
             -H 'Content-Type: application/json' \
             -d @~/Desktop/brian_profile_seed.json
    """
    try:
        data = await request.json()

        # Build UserProfile from JSON structure
        p = profile.UserProfile(
            # Identity
            name=data.get("identity", {}).get("name"),
            age=data.get("identity", {}).get("age"),
            height=data.get("identity", {}).get("height"),
            occupation=data.get("identity", {}).get("occupation"),
            summary=data.get("identity", {}).get("summary"),

            # Body composition
            current_weight_lbs=data.get("body_composition", {}).get("current_weight_lbs"),
            current_body_fat_pct=data.get("body_composition", {}).get("current_body_fat_pct"),
            target_weight_lbs=data.get("body_composition", {}).get("target_weight_lbs"),
            target_body_fat_pct=data.get("body_composition", {}).get("target_body_fat_pct"),

            # Goals and phase
            goals=data.get("goals", []),
            current_phase=data.get("phase", {}).get("current"),
            phase_context=data.get("phase", {}).get("context"),
            phase_started=data.get("phase", {}).get("started"),

            # Training
            training_days_per_week=data.get("training", {}).get("days_per_week"),
            training_style=data.get("training", {}).get("style", []),
            favorite_activities=data.get("training", {}).get("favorite_activities", []),

            # Nutrition
            training_day_targets=data.get("nutrition", {}).get("training_day"),
            rest_day_targets=data.get("nutrition", {}).get("rest_day"),
            nutrition_guidelines=data.get("nutrition", {}).get("guidelines", []),

            # Context
            life_context=data.get("life_context", []),
            constraints=data.get("constraints", []),
            preferences=data.get("preferences", []),
            context=data.get("context", []),

            # Relationship
            relationship_notes=data.get("relationship_notes", []),

            # Communication & personality
            communication_style=data.get("communication_style"),
            personality_notes=data.get("coaching_persona"),  # The prose persona

            # Hevy quirks
            hevy_quirks=list(filter(None, [
                data.get("hevy_integration", {}).get("quirk"),
                data.get("hevy_integration", {}).get("set_counting")
            ])) if data.get("hevy_integration") else None,

            # Status
            onboarding_complete=data.get("onboarding_complete", True)
        )

        # Save the profile
        profile.save_profile(p)

        # Clear chat session so new personality takes effect
        llm_router.clear_chat_session()

        return {
            "status": "imported",
            "name": p.name,
            "onboarding_complete": p.onboarding_complete,
            "has_coaching_persona": bool(p.personality_notes),
            "session_cleared": True
        }

    except Exception as e:
        return {"status": "error", "message": str(e)}


class MemorySyncRequest(BaseModel):
    """Memory markers synced from iOS device."""
    type: str  # "remember", "callback", "tone", "thread"
    contents: list[str]


@app.post("/sync/memories")
async def sync_memories(request: MemorySyncRequest):
    """
    Receive memory markers from iOS device.

    iOS extracts memory markers from AI responses (both Claude and Gemini)
    and syncs them to server for backup and cross-provider continuity.

    Marker types:
    - remember: Key facts about the user
    - callback: Inside jokes, references to remember
    - tone: Communication style preferences
    - thread: Topics to follow up on
    """
    try:
        stored_count = memory.store_memories(request.type, request.contents)
        return {
            "status": "synced",
            "type": request.type,
            "stored": stored_count
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


class ProfileSyncRequest(BaseModel):
    """Profile data synced from iOS device."""
    name: Optional[str] = None
    age: Optional[int] = None
    height: Optional[str] = None
    occupation: Optional[str] = None
    current_weight_lbs: Optional[float] = None
    current_body_fat_pct: Optional[float] = None
    target_weight_lbs: Optional[float] = None
    target_body_fat_pct: Optional[float] = None
    goals: list[str] = []
    current_phase: Optional[str] = None
    phase_context: Optional[str] = None
    life_context: list[str] = []
    constraints: list[str] = []
    preferences: list[str] = []
    communication_style: Optional[str] = None
    personality_notes: Optional[str] = None
    relationship_notes: Optional[str] = None
    training_days_per_week: Optional[int] = None
    training_style: Optional[str] = None
    favorite_activities: list[str] = []
    patterns: list[str] = []
    nutrition_guidelines: list[str] = []
    onboarding_complete: bool = False


@app.post("/profile/sync")
async def sync_profile_from_device(request: ProfileSyncRequest):
    """
    Receive profile updates from iOS device.

    Device is authoritative for profile data. This endpoint merges
    device profile into server profile for backup and Claude mode continuity.
    Only non-None fields are updated.
    """
    try:
        p = profile.load_profile()

        # Merge device data into server profile (device wins for non-None fields)
        if request.name is not None:
            p.name = request.name
        if request.age is not None:
            p.age = request.age
        if request.height is not None:
            p.height = request.height
        if request.occupation is not None:
            p.occupation = request.occupation
        if request.current_weight_lbs is not None:
            p.current_weight_lbs = request.current_weight_lbs
        if request.current_body_fat_pct is not None:
            p.current_body_fat_pct = request.current_body_fat_pct
        if request.target_weight_lbs is not None:
            p.target_weight_lbs = request.target_weight_lbs
        if request.target_body_fat_pct is not None:
            p.target_body_fat_pct = request.target_body_fat_pct
        if request.goals:
            p.goals = request.goals
        if request.current_phase is not None:
            p.current_phase = request.current_phase
        if request.phase_context is not None:
            p.phase_context = request.phase_context
        if request.life_context:
            p.life_context = request.life_context
        if request.constraints:
            p.constraints = request.constraints
        if request.preferences:
            p.preferences = request.preferences
        if request.communication_style is not None:
            p.communication_style = request.communication_style
        if request.personality_notes is not None:
            p.personality_notes = request.personality_notes
        if request.relationship_notes is not None:
            # Server expects list, iOS sends string - handle both
            if isinstance(request.relationship_notes, str):
                p.relationship_notes = [request.relationship_notes] if request.relationship_notes else []
            else:
                p.relationship_notes = request.relationship_notes
        if request.training_days_per_week is not None:
            p.training_days_per_week = str(request.training_days_per_week)
        if request.training_style is not None:
            # Server expects list, iOS sends string - handle both
            if isinstance(request.training_style, str):
                p.training_style = [request.training_style] if request.training_style else []
            else:
                p.training_style = request.training_style
        if request.favorite_activities:
            p.favorite_activities = request.favorite_activities
        if request.patterns:
            p.patterns = request.patterns
        if request.nutrition_guidelines:
            p.nutrition_guidelines = request.nutrition_guidelines

        p.onboarding_complete = request.onboarding_complete
        p.updated_at = datetime.now().isoformat()

        profile.save_profile(p)

        return {
            "status": "synced",
            "server_updated_at": p.updated_at
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


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
        result = await llm_router.chat(
            prompt=user_message,
            system_prompt=system_prompt,
            use_session=True  # Maintain conversation context
        )

        if not result.success:
            raise Exception(result.error or "LLM call failed")

        response = result.text

        # Extract profile info from conversation
        if request.message:  # Only extract if there was actual user input
            await profile.update_profile_from_conversation(request.message, response)

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


@app.get("/profile/export")
async def export_profile():
    """
    Export the full profile as JSON for backup.

    Returns the complete profile data that can be imported later.
    """
    from dataclasses import asdict

    user_profile = profile.load_profile()
    return {
        "version": 1,
        "exported_at": datetime.now().isoformat(),
        "profile": asdict(user_profile)
    }


class ProfileImport(BaseModel):
    """Profile import payload."""
    version: int
    profile: dict


@app.post("/profile/import")
async def import_profile(data: ProfileImport):
    """
    Import a previously exported profile.

    This replaces the current profile with the imported data.
    Optionally regenerates personality notes after import.
    """
    if data.version != 1:
        return {"success": False, "error": f"Unsupported version: {data.version}"}

    try:
        # Create profile from imported data
        imported_profile = profile.UserProfile(**data.profile)

        # Update timestamps
        imported_profile.updated_at = datetime.now().isoformat()

        # Save the imported profile
        profile.save_profile(imported_profile)

        # Clear session so personality takes effect
        llm_router.clear_chat_session()

        return {
            "success": True,
            "name": imported_profile.name,
            "goals_count": len(imported_profile.goals),
            "has_personality": bool(imported_profile.personality_notes)
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


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
    quality_flags: Optional[list[str]] = None    # Quality issue flags from iOS
    is_baseline_excluded: Optional[bool] = None  # Exclude from baseline calculations


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


class DailyNutritionPoint(BaseModel):
    """Daily nutrition data point for sparklines."""
    date: str
    calories: int
    protein: int
    carbs: int
    fat: int


class DailyHealthPoint(BaseModel):
    """Daily health data point for sparklines."""
    date: str
    sleep_hours: Optional[float] = None
    weight_lbs: Optional[float] = None
    steps: int = 0
    active_calories: int = 0


class ContextSummary(BaseModel):
    """
    Aggregated context for a time range.

    ARCHITECTURE NOTE: Server stores DAILY AGGREGATES, not individual meals.
    iOS device owns granular entries; server receives totals per day.
    See server/ARCHITECTURE.md for full data ownership model.
    """
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

    # Daily breakdown for sparklines (NEW)
    # This exposes the daily data that server already has in context_store
    daily_nutrition: Optional[list[DailyNutritionPoint]] = None
    daily_health: Optional[list[DailyHealthPoint]] = None


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
            hrv_ms=day.hrv_ms,
            # Recovery metrics (Phase 1: HealthKit Dashboard Expansion)
            sleep_efficiency=day.sleep_efficiency,
            sleep_deep_pct=day.sleep_deep_pct,
            sleep_core_pct=day.sleep_core_pct,
            sleep_rem_pct=day.sleep_rem_pct,
            sleep_onset_minutes=day.sleep_onset_minutes,
            hrv_baseline_ms=day.hrv_baseline_ms,
            hrv_deviation_pct=day.hrv_deviation_pct,
            bedtime_consistency=day.bedtime_consistency,
            # Data quality (Phase 2: Data Quality Filtering)
            quality_score=day.quality_score,
            quality_flags=day.quality_flags or [],
            is_baseline_excluded=day.is_baseline_excluded or False
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

    Returns both weekly averages AND daily breakdown for sparklines.
    The daily data enables iOS to show actual day-to-day variance
    instead of repeating the average.
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

    # Build daily breakdown for sparklines
    # Sort by date to ensure chronological order (oldest first)
    sorted_snapshots = sorted(snapshots, key=lambda s: s.date)

    daily_nutrition = []
    daily_health = []

    for s in sorted_snapshots:
        # Nutrition data (defaults to 0 if not present)
        n = s.nutrition
        daily_nutrition.append(DailyNutritionPoint(
            date=s.date,
            calories=n.calories if n else 0,
            protein=n.protein if n else 0,
            carbs=n.carbs if n else 0,
            fat=n.fat if n else 0,
        ))

        # Health data (None for missing values)
        h = s.health
        daily_health.append(DailyHealthPoint(
            date=s.date,
            sleep_hours=h.sleep_hours if h else None,
            weight_lbs=h.weight_lbs if h else None,
            steps=h.steps if h else 0,
            active_calories=h.active_calories if h else 0,
        ))

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
        calorie_compliance=compliance.get("calorie_compliance"),
        # NEW: Daily breakdown for sparklines
        daily_nutrition=daily_nutrition,
        daily_health=daily_health,
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


# --- Strength Tracking Endpoints (Exercise History for Charts) ---

class ExercisePR(BaseModel):
    """Current personal record for an exercise."""
    weight_lbs: float
    reps: int
    date: str
    e1rm: float  # Estimated 1RM


class TrackedExercise(BaseModel):
    """A tracked exercise with PR and trend data."""
    name: str
    workout_count: int
    current_pr: Optional[ExercisePR] = None
    recent_trend: list[float] = []  # Last 8 e1RM values for mini sparkline
    improvement: Optional[float] = None  # lbs e1RM per month (trend)


class TrackedExercisesResponse(BaseModel):
    """List of tracked exercises for the exercise picker."""
    exercises: list[TrackedExercise]
    last_sync: Optional[str] = None


class StrengthHistoryPoint(BaseModel):
    """Single data point for strength chart."""
    date: str
    e1rm: float
    weight_lbs: float
    reps: int


class StrengthHistoryResponse(BaseModel):
    """Performance history for a specific exercise."""
    exercise: str
    history: list[StrengthHistoryPoint]
    current_pr: Optional[ExercisePR] = None
    trend: Optional[float] = None  # lbs per month


class ExerciseSyncResponse(BaseModel):
    """Response from exercise history sync."""
    status: str
    workouts_processed: int
    exercises_updated: int
    error: Optional[str] = None


@app.get("/training/exercises", response_model=TrackedExercisesResponse)
async def get_tracked_exercises(
    limit: int = 20,
    sort_by: str = "frequency",
    days: Optional[int] = None
):
    """
    Get top tracked exercises with current PRs.

    Query parameters:
    - limit: Number of exercises to return (default 20)
    - sort_by: "frequency" (default), "most_improved", "least_improved"
    - days: Time window - 30, 90, 180, 365, or None for all time

    Returns exercises with PR, trend sparkline, and improvement rate.
    """
    try:
        # Validate sort_by
        valid_sorts = ["frequency", "most_improved", "least_improved"]
        if sort_by not in valid_sorts:
            sort_by = "frequency"

        exercises = exercise_store.get_top_exercises(
            n=limit,
            sort_by=sort_by,
            days=days
        )
        last_sync = exercise_store.get_last_sync_date()

        return TrackedExercisesResponse(
            exercises=[
                TrackedExercise(
                    name=ex["name"],
                    workout_count=ex["workout_count"],
                    current_pr=ExercisePR(**ex["current_pr"]) if ex.get("current_pr") else None,
                    recent_trend=ex.get("recent_trend", []),
                    improvement=ex.get("improvement")
                )
                for ex in exercises
            ],
            last_sync=last_sync
        )
    except Exception as e:
        print(f"Error getting tracked exercises: {e}")
        return TrackedExercisesResponse(exercises=[], last_sync=None)


@app.get("/training/strength-history", response_model=StrengthHistoryResponse)
async def get_strength_history(exercise: str, days: int = 365):
    """
    Get performance history for a specific exercise.

    Returns all performances for charting, including:
    - Estimated 1RM (e1rm) - normalized for cross-rep-range comparison
    - Raw weight and reps for each session
    - Trend (lbs per month) calculated via linear regression

    Used for the interactive strength chart.
    """
    try:
        data = exercise_store.get_exercise_chart_data(exercise, days)

        return StrengthHistoryResponse(
            exercise=data["exercise"],
            history=[
                StrengthHistoryPoint(
                    date=p["date"],
                    e1rm=p["e1rm"],
                    weight_lbs=p["weight_lbs"],
                    reps=p["reps"]
                )
                for p in data.get("history", [])
            ],
            current_pr=ExercisePR(**data["current_pr"]) if data.get("current_pr") else None,
            trend=data.get("trend")
        )
    except Exception as e:
        print(f"Error getting strength history for {exercise}: {e}")
        return StrengthHistoryResponse(
            exercise=exercise,
            history=[],
            current_pr=None,
            trend=None
        )


@app.post("/training/sync", response_model=ExerciseSyncResponse)
async def sync_exercise_history(full: bool = False):
    """
    Sync exercise history from Hevy workouts.

    By default, performs incremental sync (last 7 days).
    Set full=True to rebuild complete history from all workouts.

    This populates the exercise_store for fast chart rendering.
    """
    try:
        result = await scheduler.run_exercise_history_sync(full_sync=full)

        return ExerciseSyncResponse(
            status=result.get("status", "unknown"),
            workouts_processed=result.get("workouts_processed", 0),
            exercises_updated=result.get("exercises_updated", 0),
            error=result.get("error")
        )
    except Exception as e:
        print(f"Error syncing exercise history: {e}")
        return ExerciseSyncResponse(
            status="error",
            workouts_processed=0,
            exercises_updated=0,
            error=str(e)
        )


# --- Tool Execution Endpoints (for Gemini function calling from iOS) ---

class ToolCallRequest(BaseModel):
    """Request to execute a tool."""
    name: str
    arguments: dict = {}


class ToolCallResponse(BaseModel):
    """Response from tool execution."""
    success: bool
    content: str
    error: Optional[str] = None


class ToolSchema(BaseModel):
    """Tool schema for function calling."""
    name: str
    description: str
    parameters: dict


class ToolSchemasResponse(BaseModel):
    """All available tool schemas."""
    tools: list[ToolSchema]


@app.get("/tools/schemas", response_model=ToolSchemasResponse)
async def get_tool_schemas():
    """
    Get tool schemas for Gemini function calling.

    iOS calls this to get the function declarations to send to Gemini.
    The schemas follow the Gemini function calling format.
    """
    return ToolSchemasResponse(
        tools=[
            ToolSchema(
                name=schema["name"],
                description=schema["description"],
                parameters=schema["parameters"]
            )
            for schema in tools.TOOL_SCHEMAS
        ]
    )


@app.post("/tools/execute", response_model=ToolCallResponse)
async def execute_tool(request: ToolCallRequest):
    """
    Execute a tool and return results.

    iOS calls this when Gemini returns a function call.
    The result is then passed back to Gemini for the final response.

    Supported tools:
    - query_workouts: Workout history from Hevy
    - query_nutrition: Nutrition history and compliance
    - query_body_comp: Body composition trends
    - query_recovery: Sleep, HRV, recovery metrics
    - query_insights: AI-generated insights
    """
    result = await tools.execute_tool(request.name, request.arguments)

    return ToolCallResponse(
        success=result.success,
        content=result.to_context_string(),
        error=result.error
    )


if __name__ == "__main__":
    uvicorn.run(
        "server:app",
        host=config.HOST,
        port=config.PORT,
        reload=True  # Auto-reload during development
    )

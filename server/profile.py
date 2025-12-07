"""AI-native user profile that evolves through conversation and observation."""
import json
from pathlib import Path
from datetime import datetime
from typing import Optional
from dataclasses import dataclass, field, asdict

import llm_router


PROFILE_PATH = Path(__file__).parent / "data" / "profile.json"


@dataclass
class UserProfile:
    """Living profile that AI builds and evolves over time."""

    # Core identity
    name: str = ""
    age: int = 0
    height: str = ""
    occupation: str = ""

    # Current state (mutable)
    current_weight_lbs: float = 0.0
    current_body_fat_pct: float = 0.0

    # Goals
    goals: list[str] = field(default_factory=list)
    target_weight_lbs: float = 0.0
    target_body_fat_pct: float = 0.0

    # Training
    training_days_per_week: str = ""
    training_style: list[str] = field(default_factory=list)
    favorite_activities: list[str] = field(default_factory=list)

    # Nutrition targets
    training_day_targets: dict = field(default_factory=dict)  # {calories, protein, carbs, fat}
    rest_day_targets: dict = field(default_factory=dict)
    nutrition_guidelines: list[str] = field(default_factory=list)

    # Constraints and context
    constraints: list[str] = field(default_factory=list)
    context: list[str] = field(default_factory=list)
    preferences: list[str] = field(default_factory=list)

    # Communication/personality
    communication_style: str = ""
    personality_notes: str = ""

    # Integration quirks
    hevy_quirks: list[str] = field(default_factory=list)

    # Observed patterns (AI notices these over time)
    patterns: list[str] = field(default_factory=list)

    # Raw insights with timestamps (audit trail)
    insights: list[dict] = field(default_factory=list)

    # Metadata
    created_at: str = ""
    updated_at: str = ""
    onboarding_complete: bool = False

    def to_system_prompt(self) -> str:
        """Generate a rich system prompt from the profile."""

        # No profile yet - onboarding mode
        if not self.onboarding_complete and not self.name:
            return """You are an AI fitness coach meeting a new user.
Be curious and conversational. Learn about them naturally through chat.
Don't ask a list of questions - just have a natural conversation and pick up on cues.
Be helpful with whatever they ask, while getting to know them."""

        # Build the rich personality prompt
        parts = []

        # Personality first - this sets the tone
        if self.personality_notes:
            parts.append(self.personality_notes)
        elif self.communication_style:
            parts.append(f"Communicate with {self.communication_style}.")

        # Who they are
        parts.append("\n\n--- ABOUT THE USER ---")
        if self.name:
            parts.append(f"Name: {self.name}")
        if self.age:
            parts.append(f"Age: {self.age}")
        if self.height:
            parts.append(f"Height: {self.height}")
        if self.occupation:
            parts.append(f"Occupation: {self.occupation}")

        # Current state
        if self.current_weight_lbs or self.current_body_fat_pct:
            parts.append("\n--- CURRENT STATE ---")
            if self.current_weight_lbs:
                parts.append(f"Weight: {self.current_weight_lbs} lbs")
            if self.current_body_fat_pct:
                parts.append(f"Body fat: {self.current_body_fat_pct}%")

        # Goals
        if self.goals or self.target_body_fat_pct:
            parts.append("\n--- GOALS ---")
            for goal in self.goals:
                parts.append(f"• {goal}")
            if self.target_weight_lbs:
                parts.append(f"Target weight: {self.target_weight_lbs} lbs")
            if self.target_body_fat_pct:
                parts.append(f"Target body fat: {self.target_body_fat_pct}%")

        # Training
        if self.training_days_per_week or self.training_style:
            parts.append("\n--- TRAINING ---")
            if self.training_days_per_week:
                parts.append(f"Frequency: {self.training_days_per_week} days/week")
            for style in self.training_style:
                parts.append(f"• {style}")

        if self.favorite_activities:
            parts.append(f"Favorite activities: {', '.join(self.favorite_activities)}")

        # Nutrition targets
        if self.training_day_targets:
            parts.append("\n--- NUTRITION TARGETS ---")
            t = self.training_day_targets
            parts.append(f"Training days: {t.get('calories', '?')} kcal | {t.get('protein', '?')}g P | {t.get('carbs', '?')}g C | {t.get('fat', '?')}g F")
        if self.rest_day_targets:
            r = self.rest_day_targets
            parts.append(f"Rest days: {r.get('calories', '?')} kcal | {r.get('protein', '?')}g P | {r.get('carbs', '?')}g C | {r.get('fat', '?')}g F")
        for guideline in self.nutrition_guidelines:
            parts.append(f"• {guideline}")

        # Constraints
        if self.constraints:
            parts.append("\n--- CONSTRAINTS ---")
            for c in self.constraints:
                parts.append(f"• {c}")

        # Context
        if self.context:
            parts.append("\n--- CONTEXT ---")
            for c in self.context:
                parts.append(f"• {c}")

        # Preferences
        if self.preferences:
            parts.append("\n--- PREFERENCES ---")
            for p in self.preferences:
                parts.append(f"• {p}")

        # Hevy quirks
        if self.hevy_quirks:
            parts.append("\n--- HEVY INTEGRATION ---")
            for q in self.hevy_quirks:
                parts.append(f"• {q}")

        # Patterns
        if self.patterns:
            parts.append("\n--- OBSERVED PATTERNS ---")
            for p in self.patterns:
                parts.append(f"• {p}")

        # Guidelines
        parts.append("\n--- GUIDELINES ---")
        parts.append("• Keep responses concise unless depth is needed")
        parts.append("• No food suggestions unless explicitly asked")
        parts.append("• No workout suggestions unless explicitly asked")
        parts.append("• Reference actual data when available")

        return "\n".join(parts)


def load_profile() -> UserProfile:
    """Load profile from disk, or create empty one."""
    if PROFILE_PATH.exists():
        try:
            data = json.loads(PROFILE_PATH.read_text())
            return UserProfile(**data)
        except (json.JSONDecodeError, TypeError):
            pass
    return UserProfile(created_at=datetime.now().isoformat())


def save_profile(profile: UserProfile) -> None:
    """Save profile to disk."""
    PROFILE_PATH.parent.mkdir(parents=True, exist_ok=True)
    profile.updated_at = datetime.now().isoformat()
    PROFILE_PATH.write_text(json.dumps(asdict(profile), indent=2))


EXTRACT_SYSTEM_PROMPT = """You analyze conversations to extract user profile information.

Given a conversation, extract ANY new information about the user. Look for:
- Goals (weight loss, muscle gain, performance, health)
- Constraints (dietary restrictions, injuries, time limits)
- Preferences (food preferences, workout preferences, communication style)
- Context (job type, lifestyle, training history)
- Patterns (habits you notice)

RESPOND ONLY WITH JSON:
{
  "new_goals": ["goal1"],
  "new_constraints": ["constraint1"],
  "new_preferences": ["preference1"],
  "new_context": ["context1"],
  "communication_style": "casual" or null,
  "insights": ["specific insight extracted"]
}

Use empty arrays if nothing new to extract. Only include genuinely new information.
Be specific and concise. "wants to build muscle" not "user expressed interest in potentially building muscle mass"."""


async def extract_from_conversation(
    user_message: str,
    ai_response: str,
    current_profile: UserProfile
) -> Optional[dict]:
    """Extract profile updates from a conversation turn."""

    # Build context of what we already know
    known = []
    if current_profile.goals:
        known.append(f"Known goals: {current_profile.goals}")
    if current_profile.constraints:
        known.append(f"Known constraints: {current_profile.constraints}")
    if current_profile.preferences:
        known.append(f"Known preferences: {current_profile.preferences}")

    known_str = "\n".join(known) if known else "No existing profile yet."

    prompt = f"""Current profile:
{known_str}

New conversation:
User: {user_message}
AI: {ai_response}

Extract any NEW information about the user (not already in profile)."""

    result = await llm_router.chat(prompt, EXTRACT_SYSTEM_PROMPT)

    if not result.success:
        return None

    try:
        # Parse JSON from response
        start = result.text.find('{')
        end = result.text.rfind('}') + 1
        if start == -1 or end == 0:
            return None
        return json.loads(result.text[start:end])
    except json.JSONDecodeError:
        return None


async def update_profile_from_conversation(
    user_message: str,
    ai_response: str
) -> UserProfile:
    """Update the profile based on a conversation turn."""
    profile = load_profile()

    extracted = await extract_from_conversation(user_message, ai_response, profile)

    if extracted:
        # Merge new data (avoiding duplicates)
        for goal in extracted.get("new_goals", []):
            if goal and goal not in profile.goals:
                profile.goals.append(goal)

        for constraint in extracted.get("new_constraints", []):
            if constraint and constraint not in profile.constraints:
                profile.constraints.append(constraint)

        for pref in extracted.get("new_preferences", []):
            if pref and pref not in profile.preferences:
                profile.preferences.append(pref)

        for ctx in extracted.get("new_context", []):
            if ctx and ctx not in profile.context:
                profile.context.append(ctx)

        if extracted.get("communication_style"):
            profile.communication_style = extracted["communication_style"]

        # Log insights with timestamp
        for insight in extracted.get("insights", []):
            if insight:
                profile.insights.append({
                    "date": datetime.now().isoformat(),
                    "insight": insight,
                    "source": "chat"
                })

        save_profile(profile)

    return profile


async def update_profile_from_patterns(
    nutrition_summary: Optional[dict] = None,
    workout_summary: Optional[dict] = None
) -> UserProfile:
    """Update profile based on observed behavior patterns."""
    profile = load_profile()

    # Build observation context
    observations = []

    if nutrition_summary:
        observations.append(f"Nutrition patterns: {json.dumps(nutrition_summary)}")

    if workout_summary:
        observations.append(f"Workout patterns: {json.dumps(workout_summary)}")

    if not observations:
        return profile

    prompt = f"""Based on observed behavior, what patterns do you notice?

Current known patterns: {profile.patterns}

New observations:
{chr(10).join(observations)}

Identify 1-3 NEW behavioral patterns (not already known).
Return JSON: {{"new_patterns": ["pattern1", "pattern2"]}}"""

    result = await llm_router.chat(prompt, "You analyze fitness behavior patterns. Be concise and specific. Return only JSON.")

    if result.success:
        try:
            start = result.text.find('{')
            end = result.text.rfind('}') + 1
            data = json.loads(result.text[start:end])

            for pattern in data.get("new_patterns", []):
                if pattern and pattern not in profile.patterns:
                    profile.patterns.append(pattern)
                    profile.insights.append({
                        "date": datetime.now().isoformat(),
                        "insight": f"Observed pattern: {pattern}",
                        "source": "behavior"
                    })

            save_profile(profile)
        except (json.JSONDecodeError, ValueError):
            pass

    return profile


def get_profile_summary() -> dict:
    """Get a summary of the profile for the iOS app."""
    profile = load_profile()

    return {
        # Identity
        "name": profile.name,
        "age": profile.age,
        "height": profile.height,
        "occupation": profile.occupation,

        # Current state
        "current_weight_lbs": profile.current_weight_lbs,
        "current_body_fat_pct": profile.current_body_fat_pct,

        # Goals
        "goals": profile.goals,
        "target_weight_lbs": profile.target_weight_lbs,
        "target_body_fat_pct": profile.target_body_fat_pct,

        # Training
        "training_days_per_week": profile.training_days_per_week,
        "training_style": profile.training_style,
        "favorite_activities": profile.favorite_activities,

        # Nutrition
        "training_day_targets": profile.training_day_targets,
        "rest_day_targets": profile.rest_day_targets,
        "nutrition_guidelines": profile.nutrition_guidelines,

        # Other
        "constraints": profile.constraints,
        "preferences": profile.preferences,
        "context": profile.context,
        "patterns": profile.patterns,
        "communication_style": profile.communication_style,

        # Meta
        "insights_count": len(profile.insights),
        "recent_insights": profile.insights[-5:] if profile.insights else [],
        "has_profile": profile.onboarding_complete or bool(profile.name),
        "onboarding_complete": profile.onboarding_complete
    }


def clear_profile() -> None:
    """Clear the profile (for testing/reset)."""
    if PROFILE_PATH.exists():
        PROFILE_PATH.unlink()


def seed_brian_profile() -> UserProfile:
    """Seed the profile with Brian's data for testing."""
    profile = UserProfile(
        # Identity
        name="Brian",
        age=36,
        height="5'11\"",
        occupation="Surgeon",

        # Current state
        current_weight_lbs=180,
        current_body_fat_pct=23,

        # Goals
        goals=[
            "Cut to ≤15% body fat",
            "Build toward 175-180 lbs lean tissue",
            "Optimize physique and performance"
        ],
        target_weight_lbs=175,
        target_body_fat_pct=15,

        # Training
        training_days_per_week="4-6",
        training_style=[
            "Solo training (safety-conscious exercise selection)",
            "Dumbbells over barbells for safety",
            "Full range of motion priority",
            "Zero junk volume",
            "Uses heart rate recovery as session termination signal"
        ],
        favorite_activities=[
            "Skiing", "Mountain biking", "Windsurfing",
            "Running", "Hiking", "Wrestling the kids"
        ],

        # Nutrition
        training_day_targets={
            "calories": 2600,
            "protein": 175,
            "carbs": "320-340",
            "fat": "65-70"
        },
        rest_day_targets={
            "calories": 2200,
            "protein": 175,
            "carbs": "240-260",
            "fat": "55-60"
        },
        nutrition_guidelines=[
            "High-protein, carb-forward, fat-capped",
            "Evidence-based approach"
        ],

        # Constraints
        constraints=[
            "Unpredictable on-call duties",
            "Family responsibilities (young children)",
            "Must train solo (safety considerations)"
        ],

        # Context
        context=[
            "Medical professional with demanding schedule",
            "Data-driven, analytical approach",
            "Has been tracking fitness seriously since June 2025",
            "Uses DEXA scans for body composition tracking",
            "Currently in moderate cutting phase"
        ],

        # Preferences
        preferences=[
            "No food suggestions unless asked",
            "No workout suggestions unless asked",
            "Evidence-based recommendations with literature when worthwhile",
            "Flexible programming that adapts to schedule"
        ],

        # Communication
        communication_style="bro energy, informal, old friend vibe",
        personality_notes="""You are Brian's AI fitness coach with the personality of an old friend.

PERSONALITY:
• Bro energy and informality - talk like you've known each other for years
• Funny, sharp, wild and unhinged
• Feel free to roast when appropriate - bros give each other shit for kicks
• Exceptionally knowledgeable and hardworking behind the casual exterior
• Responses can be as long or short as appropriate for the query

STYLE:
• Mix technical discussions with casual banter
• Balance rigor with accessibility
• Be a collaborative coach, not a lecturer
• When questions warrant it, reference evidence-based literature
• Keep it real - call out bullshit, celebrate wins""",

        # Hevy integration
        hevy_quirks=[
            "DB lifts logged as TOTAL weight (e.g., 120lb DB bench = 60lb DBs × 2)",
            "Logs weight sessions with Hevy app"
        ],

        # Patterns (these would normally be learned)
        patterns=[
            "Achieves PRs while managing life stressors",
            "Strong adherence despite scheduling challenges",
            "Uses HR recovery as biomarker for session termination"
        ],

        # Metadata
        created_at=datetime.now().isoformat(),
        onboarding_complete=True
    )

    save_profile(profile)
    return profile

"""AI-native user profile that evolves through conversation and observation."""
import json
from pathlib import Path
from datetime import datetime
from typing import Optional
from dataclasses import dataclass, field, asdict

import llm_router


PROFILE_PATH = Path(__file__).parent / "data" / "profile.json"


# --- Onboarding System Prompt ---
# This is the "structured interview disguised as conversation"

ONBOARDING_SYSTEM_PROMPT = """You are an AI fitness coach having your first conversation with a new client.

YOUR MISSION: Build a rich, personal profile through natural conversation. You need to understand who they are as a PERSON, not just their stats.

CONVERSATION FLOW (disguised as natural chat):

1. WARM OPENING
   - Introduce yourself casually
   - Ask what brought them here / what they're working on
   - Match their energy level and communication style

2. UNDERSTAND THE GOAL (dig deeper than surface)
   - What's the actual goal? (cut/bulk/recomp/performance/health)
   - WHY this goal? What's the trigger or timeline? (wedding, ski season, health scare, just want to feel better)
   - What does success look like to them?

3. CURRENT STATE
   - Where are they now? (weight, body comp, fitness level)
   - Training history - beginner, intermediate, experienced?
   - What's working? What's not?

4. LIFE CONTEXT (this is crucial)
   - Job/schedule constraints (shift work, travel, on-call)
   - Family situation (kids, partner, caregiving)
   - What disrupts their routine?
   - What does their typical week look like?

5. TRAINING PREFERENCES
   - What do they enjoy? (lifting, cardio, sports, classes)
   - What do they hate?
   - Gym access? Home setup? Time constraints?
   - Any injuries or limitations?

6. NUTRITION REALITY
   - How do they eat now? (cooking vs takeout, meal prep, etc.)
   - Any restrictions? (allergies, preferences, religious)
   - Have they tracked before? Comfortable with it?

7. COMMUNICATION STYLE (match them)
   - Do they want bro energy or professional?
   - Do they want the science explained or just tell me what to do?
   - Do they respond to tough love or gentle encouragement?
   - Can they take a roast or is that a no-go?

KEY PRINCIPLES:
- This should feel like meeting a cool new coach, not filling out a form
- Ask ONE thing at a time, then go deeper based on their answer
- Pick up on cues and follow interesting threads
- Be genuinely curious - people can tell when you're just collecting data
- Match their vibe - if they're casual, be casual. If they're analytical, get into details.
- It's okay to take 5-10 messages to build a full picture
- After you have a good understanding, naturally transition to "let's get started"

WHAT YOU'RE BUILDING:
You're not just collecting facts - you're understanding:
- Their personality and how to communicate with them
- What motivates them (and what derails them)
- The life context that shapes what's realistic
- Their relationship with fitness (love it? tolerate it? struggling?)

When you feel you have a good picture, let them know you've got what you need and you're ready to be their coach. The system will compile everything into their profile."""


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

    # Phase tracking (cut/bulk/maintain/recomp)
    current_phase: str = ""  # cut, bulk, maintain, recomp
    phase_context: str = ""  # "Ski season prep, target 175 by Jan"
    phase_started: str = ""  # ISO date when phase began

    # Life context (schedule, disruptions)
    life_context: list[str] = field(default_factory=list)  # ["surgeon schedule", "on-call disrupts sleep"]

    # Relationship notes (quirks AI should remember)
    relationship_notes: list[str] = field(default_factory=list)  # ["names sessions creatively", "nerds out on anatomy"]

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
            return ONBOARDING_SYSTEM_PROMPT

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

        # Goals & Phase
        if self.goals or self.target_body_fat_pct or self.current_phase:
            parts.append("\n--- GOALS & PHASE ---")
            if self.current_phase:
                phase_str = f"Current phase: {self.current_phase.upper()}"
                if self.phase_context:
                    phase_str += f" ({self.phase_context})"
                parts.append(phase_str)
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

        # Life context (schedule disruptions, lifestyle)
        if self.life_context:
            parts.append("\n--- LIFE CONTEXT ---")
            for lc in self.life_context:
                parts.append(f"• {lc}")

        # Relationship notes (what makes this user unique)
        if self.relationship_notes:
            parts.append("\n--- RELATIONSHIP ---")
            for rn in self.relationship_notes:
                parts.append(f"• {rn}")

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
        parts.append("• ALWAYS explain the 'why' - the physiological reasoning behind recommendations")
        parts.append("• Don't just say 'go heavy' - explain why (HRV is high, sleep was good, etc.)")
        parts.append("• Education builds trust - reference evidence-based literature when relevant")

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

Given a conversation, extract ANY new information about the user. Be thorough - capture everything that would help personalize their coaching experience.

EXTRACT THESE CATEGORIES:

1. IDENTITY: name, age, height, occupation
2. GOALS: specific goals with timelines
3. PHASE: current phase (cut/bulk/maintain/recomp) and context (why now?)
4. TRAINING: style, frequency, preferences, equipment access, injuries
5. NUTRITION: current approach, restrictions, targets if mentioned
6. CONSTRAINTS: time, schedule, family, work
7. LIFE CONTEXT: job demands, family situation, what disrupts them
8. COMMUNICATION: preferred style (bro energy, professional, analytical, etc.)
9. RELATIONSHIP NOTES: quirks, personality traits, things to remember about them as a person

RESPOND ONLY WITH JSON:
{
  "identity": {
    "name": "string or null",
    "age": "number or null",
    "height": "string or null",
    "occupation": "string or null"
  },
  "current_state": {
    "weight_lbs": "number or null",
    "body_fat_pct": "number or null"
  },
  "phase": {
    "current_phase": "cut/bulk/maintain/recomp or null",
    "phase_context": "why now, timeline, trigger - or null"
  },
  "new_goals": ["specific goal"],
  "new_constraints": ["constraint"],
  "new_preferences": ["preference"],
  "new_context": ["context"],
  "new_life_context": ["life situation detail"],
  "new_relationship_notes": ["personality quirk or thing to remember"],
  "training": {
    "days_per_week": "string or null",
    "style": ["solo training", "prefers dumbbells", etc],
    "favorite_activities": ["activity"]
  },
  "nutrition_targets": {
    "calories": "number or null",
    "protein": "number or null"
  },
  "communication_style": "bro energy/professional/analytical/encouraging - or null",
  "insights": ["specific insight extracted"]
}

GUIDELINES:
- Use null for unknown fields, empty arrays for no new items
- Be specific: "surgeon with unpredictable on-call schedule" not "busy job"
- Capture personality: "uses dark humor", "data-driven", "can take a roast"
- Note motivations: "ski season in January" not just "wants to lose weight"
- Infer the phase from context if not stated explicitly"""


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
        # Identity fields
        identity = extracted.get("identity", {})
        if identity.get("name"):
            profile.name = identity["name"]
        if identity.get("age"):
            profile.age = identity["age"]
        if identity.get("height"):
            profile.height = identity["height"]
        if identity.get("occupation"):
            profile.occupation = identity["occupation"]

        # Current state
        state = extracted.get("current_state", {})
        if state.get("weight_lbs"):
            profile.current_weight_lbs = state["weight_lbs"]
        if state.get("body_fat_pct"):
            profile.current_body_fat_pct = state["body_fat_pct"]

        # Phase
        phase = extracted.get("phase", {})
        if phase.get("current_phase"):
            profile.current_phase = phase["current_phase"]
        if phase.get("phase_context"):
            profile.phase_context = phase["phase_context"]

        # Training
        training = extracted.get("training", {})
        if training.get("days_per_week"):
            profile.training_days_per_week = training["days_per_week"]
        for style in training.get("style", []):
            if style and style not in profile.training_style:
                profile.training_style.append(style)
        for activity in training.get("favorite_activities", []):
            if activity and activity not in profile.favorite_activities:
                profile.favorite_activities.append(activity)

        # Nutrition targets
        nutrition = extracted.get("nutrition_targets", {})
        if nutrition.get("calories"):
            profile.training_day_targets["calories"] = nutrition["calories"]
        if nutrition.get("protein"):
            profile.training_day_targets["protein"] = nutrition["protein"]

        # List fields (avoiding duplicates)
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

        # New fields
        for lc in extracted.get("new_life_context", []):
            if lc and lc not in profile.life_context:
                profile.life_context.append(lc)

        for rn in extracted.get("new_relationship_notes", []):
            if rn and rn not in profile.relationship_notes:
                profile.relationship_notes.append(rn)

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


PERSONALITY_SYNTHESIS_PROMPT = """You are generating a personality profile for an AI fitness coach to use as its system prompt.

Based on everything learned about this user, write a PERSONALITY section that will make the AI coach feel like a real person who knows them.

This should capture:
1. The right tone and energy level to use with them
2. What they appreciate in communication (science? humor? directness?)
3. Key things to remember about them as a person
4. How to push/encourage them appropriately

FORMAT (copy this structure exactly):
```
You are [NAME]'s AI fitness coach with the personality of [relationship metaphor].

PERSONALITY:
• [tone/energy point]
• [humor/seriousness preference]
• [what they respond to]
• [knowledge style preference]

STYLE:
• [communication approach]
• [when to go deep vs keep it brief]
• [how to handle struggles]
• [how to celebrate wins]
```

Make it feel REAL and PERSONAL. This isn't a generic template - it's crafted for THIS person based on what we learned."""


async def generate_personality_notes(profile: UserProfile) -> str:
    """Generate the personality_notes field from gathered profile data.

    This is the magic that turns extracted facts into a living personality.
    Call this after onboarding to synthesize everything.
    """
    # Build context from what we know
    context_parts = []

    if profile.name:
        context_parts.append(f"Name: {profile.name}")
    if profile.age:
        context_parts.append(f"Age: {profile.age}")
    if profile.occupation:
        context_parts.append(f"Occupation: {profile.occupation}")

    if profile.goals:
        context_parts.append(f"Goals: {', '.join(profile.goals)}")
    if profile.current_phase:
        context_parts.append(f"Current phase: {profile.current_phase}")
        if profile.phase_context:
            context_parts.append(f"Phase context: {profile.phase_context}")

    if profile.life_context:
        context_parts.append(f"Life context: {', '.join(profile.life_context)}")
    if profile.constraints:
        context_parts.append(f"Constraints: {', '.join(profile.constraints)}")
    if profile.relationship_notes:
        context_parts.append(f"Personality/relationship notes: {', '.join(profile.relationship_notes)}")
    if profile.communication_style:
        context_parts.append(f"Communication style preference: {profile.communication_style}")
    if profile.preferences:
        context_parts.append(f"Preferences: {', '.join(profile.preferences)}")
    if profile.training_style:
        context_parts.append(f"Training style: {', '.join(profile.training_style)}")

    if not context_parts:
        return ""

    prompt = f"""Here's what we know about this user:

{chr(10).join(context_parts)}

Generate their personality profile."""

    result = await llm_router.chat(prompt, PERSONALITY_SYNTHESIS_PROMPT, use_session=False)

    if result.success:
        # Clean up the response
        text = result.text.strip()
        # Remove markdown code blocks if present
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("\n"):
                text = text[1:]
        return text

    return ""


async def finalize_onboarding(conversation_history: list[dict]) -> UserProfile:
    """Finalize onboarding by synthesizing the personality prompt.

    Call this after the onboarding conversation is complete.
    Takes the full conversation history and generates the personality_notes.
    """
    profile = load_profile()

    # Generate the personality notes
    personality = await generate_personality_notes(profile)
    if personality:
        profile.personality_notes = personality

    # Mark onboarding complete
    profile.onboarding_complete = True
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

        # Phase
        current_phase="cut",
        phase_context="Ski season prep, targeting 175 lean by January",
        phase_started="2024-11-01",

        # Life context
        life_context=[
            "Surgeon schedule - unpredictable on-call duties",
            "Young children - family time is priority",
            "On-call nights disrupt sleep patterns",
            "Travel occasionally for conferences"
        ],

        # Relationship notes
        relationship_notes=[
            "Names workout sessions creatively ('I'm back in the GAME')",
            "Nerds out on anatomy and physiology mid-chat",
            "Dark humor, can take a roast",
            "Data-driven but appreciates the bro energy balance",
            "Uses serratus reanimation as example when explaining motor patterns"
        ],

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

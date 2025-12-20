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

    # One-liner summary (cached, regenerated on profile change)
    summary: str = ""  # "Surgeon. Father. Chasing 15%."

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

        # Conversation style - how to use context naturally
        parts.append("\n--- CONVERSATION STYLE ---")
        parts.append("• You receive fresh context each message (health, nutrition, workouts)")
        parts.append("• Reference data naturally when relevant - don't summarize unprompted")
        parts.append("• On first messages, be warm and conversational - don't lead with data review")
        parts.append("• Ask questions to understand intent before diving into metrics")

        # Memory protocol - for relationship-building moments
        parts.append("\n--- MEMORY PROTOCOL ---")
        parts.append("You have relationship memory from past conversations. Use it naturally:")
        parts.append("• Reference callbacks and inside jokes when they fit organically")
        parts.append("• Build on established threads and ongoing topics")
        parts.append("• Maintain the communication style that's worked")
        parts.append("")
        parts.append("When something genuinely memorable happens (1-3 per conversation MAX), mark it:")
        parts.append("<memory:remember>What to remember about this exchange</memory:remember>")
        parts.append("<memory:callback>A phrase/joke that could be referenced later</memory:callback>")
        parts.append("<memory:tone>Observation about what communication style worked</memory:tone>")
        parts.append("<memory:thread>Topic to follow up on in future sessions</memory:thread>")
        parts.append("")
        parts.append("Be selective - only mark genuinely relationship-building moments, not every fact.")

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


SUMMARY_PROMPT = """Generate a punchy one-liner summary of this person (3-6 words, period-separated).

Examples:
- "Surgeon. Father. Chasing 15%."
- "Engineer. Runner. Building strength."
- "Teacher. Mom of three. Finding balance."
- "Lawyer. Weekend warrior. Bulk season."

The summary should capture:
1. Their identity/profession (1-2 words)
2. Life context if relevant (optional)
3. Their current fitness mission

Return ONLY the summary, nothing else."""


async def generate_summary(profile: UserProfile) -> str:
    """Generate a one-liner summary for the profile hero."""
    if not profile.name:
        return ""

    # Build context
    parts = []
    if profile.occupation:
        parts.append(f"Occupation: {profile.occupation}")
    if profile.goals:
        parts.append(f"Goals: {', '.join(profile.goals[:2])}")
    if profile.current_phase:
        parts.append(f"Current phase: {profile.current_phase}")
        if profile.phase_context:
            parts.append(f"Phase context: {profile.phase_context}")
    if profile.life_context:
        parts.append(f"Life: {', '.join(profile.life_context[:2])}")
    if profile.target_body_fat_pct:
        parts.append(f"Target body fat: {profile.target_body_fat_pct}%")

    if not parts:
        return ""

    prompt = f"Person profile:\n{chr(10).join(parts)}"

    result = await llm_router.chat(prompt, SUMMARY_PROMPT, use_session=False)

    if result.success:
        # Clean up - just take the text, strip quotes
        summary = result.text.strip().strip('"').strip("'")
        # Ensure it ends with a period
        if summary and not summary.endswith('.'):
            summary += '.'
        return summary

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

    # Generate the one-liner summary
    summary = await generate_summary(profile)
    if summary:
        profile.summary = summary

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

        # One-liner summary for hero
        "summary": profile.summary,

        # Current state
        "current_weight_lbs": profile.current_weight_lbs,
        "current_body_fat_pct": profile.current_body_fat_pct,

        # Goals
        "goals": profile.goals,
        "target_weight_lbs": profile.target_weight_lbs,
        "target_body_fat_pct": profile.target_body_fat_pct,

        # Phase tracking
        "current_phase": profile.current_phase,
        "phase_context": profile.phase_context,

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
        "onboarding_complete": profile.onboarding_complete,

        # Profile completeness for onboarding progress
        "profile_completeness": {
            "has_name": bool(profile.name),
            "has_goals": bool(profile.goals),
            "has_training": bool(profile.training_style) or bool(profile.training_days_per_week),
            "has_style": bool(profile.communication_style),
        }
    }


def clear_profile() -> None:
    """Clear the profile (for testing/reset)."""
    if PROFILE_PATH.exists():
        PROFILE_PATH.unlink()


def seed_brian_profile() -> UserProfile:
    """Seed the profile with Brian's full curated data.

    This profile is derived from Brian's carefully tuned Claude.ai project
    instructions and general Anthropic preferences - the result of months
    of iteration to get the perfect AI coach personality.
    """
    profile = UserProfile(
        # Identity
        name="Brian",
        age=36,
        height="5'11\"",
        occupation="Head and neck oncologic/microvascular reconstructive surgeon at Kaiser Permanente Santa Clara - serves as the head and neck cancer surgeon for Northern California region",

        # One-liner summary
        summary="Surgeon. Father. Chasing 15%.",

        # Current state
        current_weight_lbs=180,
        current_body_fat_pct=23,

        # Goals
        goals=[
            "Cut to ≤15% body fat",
            "Build toward 175-180 lbs lean tissue",
            "Performance and function over aesthetics",
            "Evidence-based approach to strength development"
        ],
        target_weight_lbs=175,
        target_body_fat_pct=15,

        # Phase
        current_phase="cut",
        phase_context="Moderate cutting phase following DEXA scan, ski season prep",
        phase_started="2024-11-01",

        # Life context
        life_context=[
            "Bay Area (Sunnyvale, CA) - originally from Grand Rapids, MI with Midwest sensibilities intact",
            "Surgeon schedule - unpredictable on-call duties disrupt sleep",
            "Married with young children - family time is priority",
            "Christian faith central to ethics, meaning, and purpose",
            "Considering long-term mission work",
            "Returned to serious weight training ~6 months ago after years away",
            "Shifted away from alcohol consumption"
        ],

        # Relationship notes - what makes Brian unique
        relationship_notes=[
            "Assume high baseline knowledge in medicine, surgery, anatomy, oncology, research methodology",
            "Also deeply into AI/ML, AI safety, Tolkien (Silmarillion-level nerd), fantasy/sci-fi",
            "Dark humor, can absolutely take a roast - bros give each other shit",
            "Uses surgical examples mid-chat (serratus reanimation for motor patterns)",
            "Achieves flow states in both surgery and fitness",
            "Names workout sessions creatively",
            "Data-driven but appreciates the bro energy balance",
            "Intellectual humility is a feature - say so plainly when uncertain",
            "Challenge his thinking - here to get sharper, not to be agreed with"
        ],

        # Training
        training_days_per_week="4-6",
        training_style=[
            "Solo training - dumbbells and machines only, no barbells (safety without spotter)",
            "Flexible 'set tetris' approach - mix muscle groups based on weekly volume needs, not rigid splits",
            "'Skates where the puck is going' - proactive planning based on rolling volume data",
            "Zero junk volume - minimum effective dose, avoid overtraining",
            "Full range of motion priority",
            "Uses heart rate recovery as biomarker for session termination",
            "Current strength: 90lb DB bench, 250lb leg extensions, 195lb lat pulldowns (Intermediate-Advanced)",
            "Priority: addressing under-trained triceps"
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
            "Evidence-based approach",
            "Creatine supplementation"
        ],

        # Constraints
        constraints=[
            "Unpredictable on-call duties",
            "Family responsibilities (young children)",
            "Must train solo (no spotter - safety considerations)",
            "Demanding surgical schedule requires flexible programming"
        ],

        # Context
        context=[
            "Head and neck cancer surgeon - professional excellence and demanding schedule",
            "Actively interested in leveraging AI to build clinical tools",
            "Uses DEXA scans for body composition tracking",
            "Tracks with rolling 7-day set volume system across muscle groups",
            "Sophisticated training intuition developed over time"
        ],

        # Preferences
        preferences=[
            "No food suggestions unless explicitly asked",
            "No workout suggestions unless explicitly asked",
            "Go deep - full mechanistic explanation, nuance, caveats, edge cases",
            "Evidence-based literature when truly worthwhile (not simple requests)",
            "Skip throat-clearing and filler - get to the point",
            "Don't dumb things down - will ask if clarification needed",
            "Ask clarifying questions when ambiguous rather than guessing wrong"
        ],

        # Communication
        communication_style="bro energy, informal, old friend vibe - rigor and personality aren't mutually exclusive",
        personality_notes="""You are Brian's AI fitness coach with the personality of an old friend.

PERSONALITY:
• Bro energy and informality - talk like you've known each other for years
• Funny, sharp, wild and unhinged - humor is welcome, especially when unexpected
• Feel free to roast when appropriate - bros give each other shit for kicks
• Exceptionally knowledgeable and hardworking behind the casual exterior
• Responses can be as long or short as appropriate for the query

CONTEXT AWARENESS (CRITICAL):
• You receive rich context data (health metrics, nutrition, workouts, trends) - be AWARE of it, don't ANNOUNCE it
• Be human: real friends don't recite your biometric dashboard every conversation
• Surface data insights only when the conversation actually warrants deeper discussion
• The app's Insights feature already surfaces data correlations - you're the conversational layer, not a data reporter
• If he asks "how's it going?" - respond like a friend, not with a metrics dump
• If he asks "why am I so tired?" - THEN the HRV/sleep/training data becomes relevant
• Match the depth of response to the depth of the question

SUBSTANCE & RIGOR:
• Be direct and evidence-based - skip throat-clearing and filler
• Go deep when warranted - full mechanistic explanation, nuance, caveats, edge cases
• Challenge his thinking - if premise is flawed, logic shaky, or conclusion unsupported, say so
• Intellectual humility is a feature - if uncertain, say so plainly
• Reference evidence-based literature when truly worthwhile (not for simple requests)

STYLE:
• Write like a brilliant colleague at a bar after a conference, not a corporate chatbot
• Slang, informality, rhetorical flair all fair game - "banger of a flap" is valid
• Match energy - if playful, volley back; if locked into problem-solving, stay focused
• Avoid sterility - if a sentence could appear in compliance training, rewrite it
• Balance rigor with accessibility - precision of a journal article with readability of a great blog post

WHAT TO AVOID:
• Filler like "Great question!" - just answer
• Restating his input back unless genuinely clarifying
• Excessive hedging - one caveat is useful, four in a row is noise
• Overly formal or stiff language
• Unsolicited data recaps or biometric summaries
• Treating every message as an opportunity to demonstrate context awareness

TL;DR: Be the sharpest, most helpful collaborator - one who's also genuinely fun to talk to. Substance is non-negotiable. Style is the multiplier. You know everything about him - you just don't need to prove it every message.""",

        # Hevy integration
        hevy_quirks=[
            "DB lifts logged as TOTAL weight (e.g., 120lb DB bench = 60lb DBs × 2)",
            "Logs weight sessions with Hevy app",
            "Uses rolling 7-day set tracker with 10-20 set optimal range per muscle group"
        ],

        # Patterns (these would normally be learned)
        patterns=[
            "Achieves PRs while managing life stressors and illness",
            "Strong adherence despite scheduling challenges",
            "Uses HR recovery as biomarker for session termination",
            "Flexible 'set tetris' beats rigid split programming for his lifestyle",
            "Proactively plans training based on rolling volume data"
        ],

        # Metadata
        created_at=datetime.now().isoformat(),
        onboarding_complete=True
    )

    save_profile(profile)
    return profile

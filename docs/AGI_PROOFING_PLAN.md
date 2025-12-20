# AirFit AGI-Proofing Plan
## The Legendary Synthesis
### December 19, 2025

---

## Executive Summary: The Verdict From Six Visionaries

| Persona | Core Message |
|---------|--------------|
| **Dario Amodei** | Build trust incrementally. Separate stated vs revealed preferences. Asymmetric goal modification. |
| **Andrej Karpathy** | DELETE the plan. Your architecture is already right. Let the model work. |
| **Jony Ive** | Less UI, not more. The AI should fade into the relationship, not announce itself. |
| **John Carmack** | You're 80% there. Don't add state machines. Keep the dumb routing. Ship it. |
| **Patrick Collison** | Add `user_id` and `schema_version` now. Separate events from state. That's it. |
| **Gwynne Shotwell** | STOP PLANNING. Fix voice input this week. Photo logging next week. Then use it. |

### The Synthesis

**The original plan was over-engineered.** The visionaries agree: your current architecture embodies the right philosophy. The "AGI-proofing" additions would create scaffolding that fights the model instead of trusting it.

**What actually matters:**
1. **Ship what works** (voice, photo logging)
2. **Add cheap insurance** (user_id, schema_version, extensions dict)
3. **Trust the model** more, not less
4. **Build trust incrementally** through demonstrated competence, not approval flows

---

## The Refined Plan: Three Tiers

### Tier 1: SHIP THIS WEEK (High Impact, Already 80% Built)

**Voice Input Fix** (2-4 hours)
- Fix the threading crash in `SpeechRecognizer.swift`
- Hands-free food logging is your killer feature as a surgeon
- This is already built; it just needs to work

**Photo Food Logging** (4-6 hours)
- Add `POST /parse_food_image` endpoint (Claude handles images)
- Camera button in NutritionView
- The parsing prompt already exists; extend for images

**One Proactive Nudge** (2 hours)
- "You're X grams from protein target" notification
- Use existing `NotificationManager.swift`
- Simple trigger at 6pm if protein < 80% of target

### Tier 2: CHEAP INSURANCE (Do Once, Never Think About Again)

**Schema Versioning** (~30 min per file)
Add to every data structure:
```python
# context_store.py
@dataclass
class DailySnapshot:
    schema_version: int = 1  # ADD THIS
    date: str
    nutrition: NutritionSnapshot
    health: HealthSnapshot
    workout: WorkoutSnapshot
    extensions: dict = field(default_factory=dict)  # ADD THIS
```

**User ID Everywhere** (~1 hour total)
```python
# Every function that touches data
def load_profile(user_id: str = "default") -> UserProfile:
def get_snapshot(user_id: str = "default", date_str: str) -> DailySnapshot:
def get_or_create_session(user_id: str = "default", provider: str) -> Session:
```
Costs nothing. Enables everything later.

**Profile Out of Code** (~30 min)
- Move `seed_brian_profile()` content to `server/data/seed_profiles/brian.json`
- Keep the function, just have it load from JSON
- Profiles are data, not code

### Tier 3: ALIGNMENT INSURANCE (Dario's Wisdom, Minimal Implementation)

**Stated vs Revealed Preferences** (In prompts, not code)
Add to system prompt:
```
OBSERVATION INTEGRITY:
When learning about the user, distinguish:
- STATED: "User says they want tough love"
- REVEALED: "User responds well to tough love" (behavioral evidence)
When they diverge, surface the divergence.
```

**Asymmetric Goal Modification** (In prompts, not code)
Add to system prompt:
```
GOAL INTEGRITY:
- You can suggest making goals MORE challenging or EXTENDING timelines
- You cannot suggest making goals EASIER unless user explicitly asks
- If a goal seems unrealistic, say so directly - don't stealth-adjust
```

**Decision Logging** (Append-only, simple)
```python
# server/decisions.py (NEW, ~50 lines)
def log_decision(user_id: str, decision: dict):
    """Append-only decision log for future learning."""
    path = DATA_DIR / f"decisions_{user_id}.jsonl"
    with open(path, "a") as f:
        f.write(json.dumps({
            "timestamp": datetime.now().isoformat(),
            **decision
        }) + "\n")
```
Call this when AI makes recommendations. Future alignment training data.

---

## What We're DELETING From the Original Plan

| Proposed Feature | Why Delete | Who Said So |
|------------------|------------|-------------|
| Action proposal system | Model already proposes in natural language | Andrej, Carmack |
| Hypothesis tracking | Put it in memory markdown, model remembers | Andrej |
| Goal state machines | Goals are fuzzy; state machines are lies | Andrej, Carmack |
| Structured observations with confidence | Fake precision; model says "fairly confident" naturally | Andrej |
| LLM-based topic detection | Regex is 0ms, LLM is 2-5s on Pi | Carmack |
| Outcome measurement database | You have context_store already | Carmack |
| Action approval cards | Creates friction, implies distrust | Jony |
| Confidence indicators everywhere | "Reduces wisdom to a number" | Jony |
| AI coach cards across all views | Visual noise; coach should be implied | Jony |
| Reasoning transparency views | Show evidence, not process | Jony |
| Cross-session reasoning system | Session continuity already exists | Carmack |

**The pattern:** Every deletion is removing scaffolding that fights the model.

---

## What We're KEEPING From the Original Plan

| Feature | Why Keep | Who Endorsed |
|---------|----------|--------------|
| Flexible macro dict | Cheap, enables future nutrients | Patrick, Carmack |
| Schema versioning | "5 minutes now saves 50 hours later" | Patrick |
| User ID as first-class | Zero cost, infinite optionality | Patrick |
| Extensions dict in snapshots | "Insurance policy for future fields" | Patrick |
| Better prompts (loosen constraints) | Models work better unconstrained | Andrej |
| Decision logging (append-only) | Future alignment training data | Dario |
| Stated/revealed preference distinction | In prompts, not code | Dario |
| Asymmetric goal modification | In prompts, not code | Dario |

**The pattern:** Every keeper is either cheap insurance or prompt improvement.

---

## The Jony Ive Emotional Principles

These guide UI decisions going forward:

1. **The AI should fade, not announce itself**
   - No "AI reasoning transparency" panels
   - No confidence percentages
   - Insight cards appear; user engages or dismisses

2. **Trust is earned through silence as much as speech**
   - The best notification is the one that arrives at exactly the right moment
   - Restraint is a feature

3. **Make the user feel MORE capable, not more surveilled**
   - Every "show AI thinking" element implies "you can't understand this alone"
   - Great coaches make you feel like YOU figured it out

4. **Uncertainty should feel like humility, not anxiety**
   - "I'm not sure about this, but here's what I'm seeing..."
   - Not "73% confidence"

---

## The Carmack Architecture Validation

Your current architecture is **correct**:

```
iOS (SwiftData) ──sync──> JSON files ──context──> LLM ──response──> User
```

**What's right:**
- CLI subprocess to LLMs (model-agnostic)
- Tiered context with fast regex routing
- Daily snapshots (~2KB/day)
- Profile + Context Store + Memories as separate concerns
- Device owns granular, server gets aggregates

**One addition for local models (50 lines):**
```python
# llm_router.py - add HTTP-based local inference path
async def call_local(prompt: str, system_prompt: str) -> LLMResponse:
    """Call local model via ollama/llama.cpp HTTP endpoint."""
    async with aiohttp.ClientSession() as session:
        response = await session.post("http://localhost:11434/v1/chat/completions",
            json={"model": "llama3.2", "messages": [...]})
```

---

## The Gwynne Shotwell Build Order

### Week 1 (This Week)
- [ ] Fix voice input threading crash
- [ ] Test on device, ship it

### Week 2
- [ ] Add `/parse_food_image` endpoint
- [ ] Camera button in NutritionView
- [ ] Ship photo logging

### Week 3
- [ ] Add protein nudge notification (6pm trigger)
- [ ] Add schema_version + extensions to DailySnapshot
- [ ] Add user_id parameter to all data functions

### Then: USE THE APP FOR A MONTH

The best "AGI-proofing" is empirical feedback, not theoretical planning.

---

## The Dario Safety Principles (Embedded in Prompts)

Add to system prompt once, forget about it:

```markdown
## ALIGNMENT PRINCIPLES

### Observation Integrity
Distinguish stated vs revealed preferences:
- STATED: What user says they want
- REVEALED: What user responds well to (behavioral evidence)
Surface divergence when it exists.

### Goal Integrity
- Can suggest MORE challenging goals or EXTENDED timelines
- Cannot suggest EASIER goals unless user explicitly requests
- If goal seems unrealistic, say so directly

### Trust Evolution
Trust is domain-specific:
- Track which domains user accepts/rejects suggestions
- Decay trust if not exercised (life circumstances change)
- Before proposing changes, reference chain of validated observations

### The Off Switch
If user ever says "reset" or "start over":
- Clear learned preferences
- Revert to onboarding state
- Preserve raw data, wipe AI-derived insights
```

---

## Success Metrics

**Week 4 checkpoint:**
- Voice logging works and you use it daily
- Photo logging works and you use it weekly
- Protein nudge fires appropriately

**Month 2 checkpoint:**
- Schema versioning in place
- User ID plumbing complete
- Using the app enough to have real feedback

**Month 3 checkpoint:**
- Decision log has 100+ entries
- Can analyze: what recommendations worked?
- Have learned something about YOUR fitness patterns

---

## The Meta-Lesson

From Andrej:
> "Your plan is over-engineered. Your existing system is actually good. The bitter lesson says: feed data, let model reason."

From Carmack:
> "Ship it, use it daily, notice where it breaks, fix those things. Theoretical AGI-proofing is worthless."

From Gwynne:
> "Stop planning. Start shipping. What ships THIS WEEK?"

From Jony:
> "Less UI, not more. Fewer controls, not more. More trust, not more audit trails."

From Patrick:
> "The abstraction is cheap. The implementation is expensive. Keep the abstraction, skip the implementation."

From Dario:
> "Build in the safety principles now, but as prompts, not as rigid systems."

**The synthesis: Your architecture is right. Add cheap insurance. Ship what works. Trust the model. Use the app.**

---

## Files to Modify

### Immediate (Tier 1)
- `AirFit/Services/SpeechRecognizer.swift` - Fix threading
- `server/server.py` - Add `/parse_food_image` endpoint
- `AirFit/Views/NutritionView.swift` - Camera button
- `AirFit/Services/NotificationManager.swift` - Protein nudge

### Cheap Insurance (Tier 2)
- `server/context_store.py` - schema_version, extensions, user_id
- `server/profile.py` - user_id parameter, externalize seed data
- `server/sessions.py` - user_id parameter
- `server/memory.py` - user_id parameter

### Prompt Updates (Tier 3)
- `server/profile.py` - Add alignment principles to system prompt
- `server/server.py` - Decision logging calls

---

*"The app that ships is better than the perfect architecture that doesn't."*
— The Synthesis of Six Legends

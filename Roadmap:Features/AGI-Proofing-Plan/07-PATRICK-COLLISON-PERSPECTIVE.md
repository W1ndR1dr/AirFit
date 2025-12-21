# Patrick Collison Perspective: Long-Term Infrastructure

*Thinking as the Stripe CEO, deeply thoughtful about building infrastructure that lasts decades, interested in progress studies, and thinking about technology's long-term trajectory.*

---

## The Core Question: What's Actually Load-Bearing?

You're at an interesting inflection point. You've built something that works for one user, and the question is: what decisions made now will compound, and what will be sand washed away?

Let me work backwards from what matters.

---

## 1. What Infrastructure Decisions Made NOW Will Matter in 10 Years?

**Three things will matter. Everything else is scaffolding.**

### A. The Data Schema Is Your API Contract With the Future

Look at your `DailySnapshot` structure in `context_store.py`:

```python
@dataclass
class DailySnapshot:
    date: str  # ISO format: YYYY-MM-DD
    nutrition: NutritionSnapshot
    health: HealthSnapshot
    workout: WorkoutSnapshot
```

This is **load-bearing**. The structure of daily aggregates, the decision to use ISO date strings as keys, the separation of nutrition/health/workout domains—these become your "physical constants."

Changing them later is migration hell.

**What I'd Add Now:**

```python
@dataclass
class DailySnapshot:
    schema_version: int = 1  # CRITICAL: Enables future migrations
    date: str
    nutrition: NutritionSnapshot
    health: HealthSnapshot
    workout: WorkoutSnapshot
    extensions: dict = field(default_factory=dict)  # Escape valve
```

The `extensions` dict is your insurance policy. When someone wants to track "meditation minutes" or "caffeine intake" or "glucose levels," you don't change the schema—you put it in extensions.

**Schema migrations are where companies go to die.**

### B. The Event/Snapshot Duality

Your current architecture stores **snapshots** (point-in-time aggregates). But you're missing **events** (immutable facts that happened).

This matters because:
- Snapshots can be recomputed from events
- Events can't be reconstructed from snapshots
- AI reasoning about causation requires events ("you ate X, then felt Y")

The decision to store only aggregates on server is pragmatic for Raspberry Pi. But **the iOS device should store events, not just entries**.

Your `NutritionEntry` is close, but it's mutable (it's an @Model). Consider:

```swift
struct NutritionEvent: Codable {
    let id: UUID
    let timestamp: Date
    let type: EventType  // .logged, .corrected, .deleted
    let payload: [String: Any]
}
```

**Events are forever. Views are computed.**

### C. The User Identifier Story

Right now, you don't really have one. Single user, JSON files.

**Who owns identity?**

| Option | Implication |
|--------|-------------|
| Device-generated UUID | Each iOS device generates ID. Server keys by device. |
| Server-assigned ID | Server mints ID on first contact. |
| External identity | Apple ID, email, etc. |

**My recommendation: Device-generated UUID, server-agnostic.**

Why? In your architecture, the device is source of truth. The server is compute layer, not identity layer.

If I get a new iPhone and restore from backup, my data comes with me. If I switch servers, my identity persists.

**Identity should live where data lives.**

---

## 2. How Should the Data Model Be Designed for Millions?

You're not building for millions. You're building for one. But the question is really: **what would break if it were millions?**

### The Sharding Story

Your current approach:
```python
CONTEXT_FILE = DATA_DIR / "context_store.json"
```

For one user: fine.
For millions: `context_store_{user_id}.json`, then eventually database with `user_id` partition key.

**What to decide now:** Make `user_id` first-class everywhere, even if always "default" today.

```python
def get_snapshot(user_id: str, date_str: str) -> Optional[DailySnapshot]:
    store = load_store(user_id)
    ...
```

Costs nothing. Future-proofs everything.

### The Postgres-Ready JSON Pattern

Structure your JSON so it could become Postgres rows:

```json
{
  "2024-12-19": {
    "user_id": "default",     // Add NOW
    "schema_version": 1,      // Add NOW
    "date": "2024-12-19",
    "nutrition": {...},
    "health": {...},
    "workout": {...}
  }
}
```

Every record having `user_id` and `schema_version` means you can `INSERT INTO snapshots SELECT * FROM json_data` when the time comes.

### Immutable History, Mutable State

Separate concerns:
- **Immutable:** Historical snapshots, events, conversation logs, insights generated
- **Mutable:** Current profile, active goals, preferences, targets

Mutable state is the current "what should the system do." Immutable history is "what happened." Never confuse them.

---

## 3. What's the "Stripe-Like" API Abstraction for Personal AI Coaching?

Stripe's insight was: **abstract the complexity, expose simple primitives.**

### The Three Core Resources

**1. Context (what the AI knows)**
```
GET  /context/{user_id}          # Current state
GET  /context/{user_id}/history  # Time series
POST /context/{user_id}/events   # Append new events
```

**2. Conversation (what the AI says)**
```
POST /chat                       # Send message, get response
GET  /chat/context               # Get system prompt + memory
POST /chat/process               # Post-hoc processing
```

**3. Profile (who the user is)**
```
GET  /profile/{user_id}          # What AI has learned
PUT  /profile/{user_id}          # User corrections
POST /profile/{user_id}/learn    # Trigger extraction
```

### The Stripe Pattern

Make the API so simple that incorrect usage is impossible.

Your `/chat` endpoint does too much:
- Builds tiered context
- Injects memory
- Calls LLM
- Extracts memories async
- Updates profile async

**Better:**
```python
POST /chat
{
  "message": "...",
  "context_tier": "auto"  # or "minimal", "full"
}

Response:
{
  "response": "...",
  "provider": "claude",
  "tokens_used": 1234,
  "context_included": ["phase", "today_status"]
}
```

Side effects (memory extraction, profile learning) become webhooks or background jobs, not inline magic.

---

## 4. How to Build for One User Without Painting Into a Corner?

### The "One User, N=1 Special Case" Pattern

Your code has implicit single-user assumptions:
```python
PROFILE_PATH = Path(__file__).parent / "data" / "profile.json"
```

The fix is cheap: **wrap everything in user_id, default to "default".**

```python
def load_profile(user_id: str = "default") -> UserProfile:
    path = DATA_DIR / f"profile_{user_id}.json"
    ...

def get_or_create_session(user_id: str = "default", provider: str = "claude"):
    ...
```

Changes nothing about current behavior. Makes multi-user possible.

### The "Brian's Profile" Problem

Your `seed_brian_profile()` function is charming but dangerous. It's hardcoded institutional knowledge.

**Better pattern:**

```python
def import_profile(user_id: str, profile_json: dict) -> UserProfile:
    """Import a profile from JSON. Source-agnostic."""
    ...

# Brian's profile lives in a JSON file, not in code
# server/data/seed_profiles/brian.json
```

Profiles are data, not code.

---

## 5. Load-Bearing vs. Easily Changed

### LOAD-BEARING (Hard to Change Later)

| Decision | Why It's Hard |
|----------|---------------|
| Daily snapshot schema | Migration across all historical data |
| Date format (ISO 8601) | Every parser depends on this |
| Event vs aggregate decision | Retroactive event reconstruction impossible |
| Device as source of truth | Changing data ownership is political, not technical |
| User ID format | Foreign keys everywhere |
| LLM output format expectations | Every client parses this |

### EASILY CHANGED (Swap Without Pain)

| Decision | Why It's Easy |
|----------|---------------|
| Which LLM provider | Router already abstracts this |
| Server framework (FastAPI) | Protocol stays same |
| Storage format (JSON → Postgres) | Data model stays same |
| iOS UI framework | Data layer separate |
| Context injection strategy | Prompt engineering, not schema |
| Insight generation frequency | Configuration, not architecture |

---

## 6. The Compounding Infrastructure

Here's what I'd actually prioritize:

### Add Schema Versioning Now (5 minutes)
Every data structure gets a `version` field.

### Make User ID Explicit (1 hour)
Add `user_id` parameter everywhere, default to "default."

### Separate Events from State (Medium effort)
On iOS, store append-only event log alongside mutable entries.

### Define Three Immutable Contracts
- **Date format:** ISO 8601, always
- **ID format:** UUIDv4 for everything
- **Snapshot schema:** Daily, keyed by date, with extensions dict

### Don't Build Multi-User Yet
The abstraction is cheap. The implementation is expensive.

---

## The Meta-Insight

You're building in "Personal Infrastructure" category. The thesis is:

> **AI makes personal software viable again.**

For decades, personal software lost to cloud services because:
- Sync is hard
- Servers are expensive
- AI required scale

All three are inverting. Local-first sync is solved. Edge computing is free. LLMs run on phones.

Your architecture—device owns data, server is compute, AI is interchangeable—is the right bet.

---

## The Infrastructure That Compounds

1. **A rich, immutable history of what actually happened**
2. **An evolving model of who this person is**
3. **A routing layer that doesn't care which AI answers**

Build those three things well, and the rest is details.

---

## Summary

| Priority | Action | Effort |
|----------|--------|--------|
| Critical | Add `schema_version` to all data | 30 min |
| Critical | Add `user_id` parameter everywhere | 1 hour |
| Important | Add `extensions` dict to snapshots | 15 min |
| Important | Move seed profiles to JSON files | 30 min |
| Future | Consider event sourcing on iOS | Medium |
| Future | API simplification | Medium |

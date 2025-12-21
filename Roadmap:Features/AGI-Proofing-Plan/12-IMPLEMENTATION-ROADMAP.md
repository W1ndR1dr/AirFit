# Implementation Roadmap: The Refined 3-Week Plan

## Overview

This roadmap synthesizes the six consultant perspectives into an actionable, realistic plan. The key insight from Gwynne Shotwell's analysis: the original 12-week, 35-feature plan was unrealistic for a surgeon coding part-time. This is the focused version.

---

## Philosophy: Ship Early, Learn Fast

> **"The app that ships is better than the perfect architecture that doesn't."** — Gwynne Shotwell

The roadmap prioritizes:
1. **High-impact, low-effort wins** (voice, photo logging)
2. **Cheap insurance** (schema versioning, user_id)
3. **Using what exists** (don't build new features, wire up existing code)

---

## Week 1: Voice Input (HIGH IMPACT)

### Goal: Hands-Free Food Logging

**Why This First:**
- Surgeon logging food after surgery = killer use case
- `SpeechRecognizer.swift` exists but has threading issues
- 4-6 hours of work for massive UX improvement

### Tasks

| Task | Effort | File |
|------|--------|------|
| Fix threading crash in SpeechRecognizer | 2-3 hours | `SpeechRecognizer.swift` |
| Test voice input on device | 1 hour | Manual testing |
| Add voice button to NutritionView | 1-2 hours | `NutritionView.swift` |

### Definition of Done
- [ ] Can say "Two eggs and toast with butter" and have it logged
- [ ] No crashes on voice activation
- [ ] Works reliably 90% of the time

### Skip This Week
- Wake word detection (battery disaster)
- Continuous listening (privacy issues)
- Complex voice UI

---

## Week 2: Photo Food Logging

### Goal: Visual Macro Estimation

**Why This Second:**
- Claude handles images natively
- Server already has `/parse_food` endpoint
- Minimal new code, maximum convenience

### Tasks

| Task | Effort | File |
|------|--------|------|
| Add `POST /parse_food_image` endpoint | 2-3 hours | `server/nutrition.py` |
| Create image capture component | 2-3 hours | New Swift file |
| Add camera button to NutritionView | 1 hour | `NutritionView.swift` |
| Test on real meals | 1-2 hours | Manual testing |

### Server Endpoint

```python
@app.post("/parse_food_image")
async def parse_food_image(request: FoodImageRequest):
    """Parse food from image using vision-capable model."""
    # Base64 image → Claude vision → structured macros
    prompt = f"""Analyze this food image and estimate macros.

    Return JSON:
    {{
        "name": "description of the meal",
        "calories": 450,
        "protein": 35,
        "carbs": 40,
        "fat": 18,
        "confidence": "high|medium|low",
        "components": [...]
    }}
    """
    # Use Claude's vision capability via CLI
    result = await call_claude_with_image(request.image_base64, prompt)
    return parse_json_response(result)
```

### Definition of Done
- [ ] Can photograph a meal and get macro estimate
- [ ] Confidence indicator shows on result
- [ ] Can edit before saving

### Skip This Week
- AR portion estimation
- Barcode scanning (OpenFoodFacts yak shave)
- Restaurant menu lookup

---

## Week 3: Cheap Insurance + Proactive Nudge

### Part A: Schema Insurance (2 hours)

**Why Now:**
- Costs almost nothing today
- Saves migration hell later
- Patrick Collison's "5 minutes saves 50 hours"

### Tasks

| Task | Effort | File |
|------|--------|------|
| Add `schema_version` to all dataclasses | 30 min | `context_store.py`, `profile.py` |
| Add `user_id` parameter everywhere | 1 hour | Multiple server files |
| Add `extensions` dict to snapshots | 15 min | `context_store.py` |
| Rename existing JSON files | 15 min | `server/data/` |

### Schema Changes

```python
# context_store.py
@dataclass
class DailySnapshot:
    schema_version: int = 1  # NEW
    date: str
    nutrition: NutritionSnapshot
    health: HealthSnapshot
    workout: WorkoutSnapshot
    extensions: dict = field(default_factory=dict)  # NEW

# profile.py
@dataclass
class UserProfile:
    schema_version: int = 1  # NEW
    name: str = ""
    # ... existing fields
```

### Function Signature Changes

```python
# Before
def load_store() -> ContextStore:
    path = DATA_DIR / "context_store.json"

# After
def load_store(user_id: str = "default") -> ContextStore:
    path = DATA_DIR / f"context_store_{user_id}.json"
```

### Part B: Protein Nudge (2-3 hours)

**One Proactive Notification:**
- "You're 30g from your protein target. Easy wins: Greek yogurt (17g), protein shake (25g), cottage cheese (14g)."

### Tasks

| Task | Effort | File |
|------|--------|------|
| Review notification triggers | 30 min | `NotificationManager.swift` |
| Add protein target check | 1 hour | `AutoSyncManager.swift` |
| Wire up notification | 1 hour | Integration |

### Definition of Done
- [ ] Receive one helpful nudge per day max
- [ ] Nudge includes actionable suggestions
- [ ] Can disable in settings

---

## Week 4+: USE THE APP

### The Crucial Phase

> **"The best 'AGI-proofing' is learning from real usage."** — Andrej Karpathy

**Do NOT add features.** Instead:

- [ ] Use voice logging daily for 2 weeks
- [ ] Log 3+ photo meals
- [ ] Note friction points in a doc
- [ ] Review what insights the AI generates

### What You'll Learn

| Question | How to Answer |
|----------|---------------|
| Does voice work in the OR? | Try it |
| Are photo estimates accurate? | Compare to manual |
| What insights are useful? | Read them daily |
| What's missing? | You'll feel it |

---

## What NOT to Build (See 13-FEATURES-TO-DELETE.md)

These are explicitly deferred:

| Feature | Why Defer |
|---------|-----------|
| Always-listening wake word | Battery, privacy |
| Barcode scanning | Yak shave, not core |
| On-device inference | Wait for Apple Intelligence |
| Complex goal frameworks | YAGNI |
| Ambient AI notifications | Creepy, distracting |
| Workout video analysis | Scope creep |

---

## Prompt Improvements (Do Alongside)

As you use the app, make these prompt tweaks (see 09-PROMPT-IMPROVEMENTS.md):

### Week 1-2
- [ ] Add alignment principles to system prompt
- [ ] Loosen insight generation constraints

### Week 3
- [ ] Update extraction prompt to open schema
- [ ] Sync PersonalitySynthesis prompt to ProfileEvolution

### Ongoing
- [ ] Observe what prompts work, iterate

---

## Success Metrics

### Week 1 Complete If:
- Voice input works reliably
- You've logged 5+ meals by voice

### Week 2 Complete If:
- Photo logging works
- You've logged 5+ meals by photo
- Estimates are within 20% of reality

### Week 3 Complete If:
- Schema versioning in place
- Received one useful protein nudge
- No data migrations needed

### Month 1 Complete If:
- You're using the app daily
- You have a list of real friction points
- You know what to build next (from usage, not speculation)

---

## The Meta-Roadmap

```
┌─────────────────────────────────────────────────────────────┐
│  Week 1-3: Ship voice, photo, cheap insurance               │
├─────────────────────────────────────────────────────────────┤
│  Week 4-8: USE THE APP. Learn. Note friction.               │
├─────────────────────────────────────────────────────────────┤
│  Week 9+: Build based on REAL learnings, not speculation    │
└─────────────────────────────────────────────────────────────┘
```

---

## Estimated Time Investment

| Week | Hours | Focus |
|------|-------|-------|
| 1 | 4-6 | Voice input |
| 2 | 6-8 | Photo logging |
| 3 | 4-6 | Schema + nudge |
| 4+ | 0 (coding) | Using the app |

**Total coding: ~18 hours over 3 weeks**

This is realistic for surgeon-pace (5-6 hours/week).

---

## What "AGI-Proofing" Actually Means Now

The best preparation for smarter AI is:

1. **Keep architecture model-agnostic** ✅ Already done
2. **Use prompts, not code, for behavior** ✅ Mostly done
3. **Store rich data, let AI reason** ✅ Already done
4. **Build feedback loops** ← This roadmap adds
5. **Stay light, stay flexible** ← This roadmap reinforces

> **"Your architecture is already AGI-native. Now ship and learn."**

---

## Summary

| Priority | This Week | Next Week | Week 3 |
|----------|-----------|-----------|--------|
| Ship | Voice input | Photo logging | Nudge |
| Insurance | — | — | Schema versioning |
| Learn | — | — | Start using daily |
| Defer | Everything else | Everything else | Everything else |

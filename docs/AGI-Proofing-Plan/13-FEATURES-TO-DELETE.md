# Features to DELETE: What NOT to Build

## Overview

This document captures the unanimous consultant recommendation: **DELETE MORE THAN YOU ADD.**

> **"Your original plan has 35+ features. That's not a plan, that's a wish list disguised as a roadmap."** — Andrej Karpathy

The most AGI-native thing you can do is keep the system simple enough that better models automatically make it better.

---

## The Bitter Lesson Applied

From Andrej's perspective:

> Every piece of complex machinery you build today becomes technical debt when the next model ships. The CLI subprocess wrapper? That's the load-bearing wall. Everything else is furniture.

---

## Category 1: NEVER BUILD These

### 1.1 Always-Listening Wake Word

**What it is:** "Hey Coach" wake word detection, always listening for commands.

**Why NOT to build:**

| Reason | Explanation |
|--------|-------------|
| Battery disaster | Always-on microphone kills battery |
| Privacy nightmare | Users don't want always-listening |
| Model solves this | Apple Intelligence will handle this better |
| Push-to-talk works | Physical button is more reliable |

**Alternative:** Push-to-talk voice button. Users tap, speak, release.

---

### 1.2 Barcode Scanning

**What it is:** Scan food barcodes, look up nutrition from OpenFoodFacts or similar.

**Why NOT to build:**

| Reason | Explanation |
|--------|-------------|
| Yak shave | OpenFoodFacts API is incomplete, requires fallbacks |
| Photo is better | Claude can estimate macros from a photo directly |
| Not core value | You're building an AI coach, not a database lookup |
| Existing apps | MyFitnessPal does this, don't compete |

**Alternative:** Photo logging with AI estimation.

---

### 1.3 AR Portion Estimation

**What it is:** Use ARKit to measure portion sizes in 3D space.

**Why NOT to build:**

| Reason | Explanation |
|--------|-------------|
| Overkill | AI can estimate from 2D photo reasonably well |
| UX complexity | AR scanning is awkward for food |
| Accuracy theater | Gives false precision |
| Not core value | Rough estimates are fine for coaching |

**Alternative:** Photo + AI estimation with confidence indicator.

---

### 1.4 On-Device LLM Inference

**What it is:** Run models locally on iPhone for privacy and offline use.

**Why NOT to build:**

| Reason | Explanation |
|--------|-------------|
| Wait for Apple | Apple Intelligence will provide this |
| Current models weak | On-device models can't match Claude quality |
| Battery/heat | Local inference is expensive |
| Your CLI architecture works | Server-side is fine for personal use |

**Alternative:** Wait for Apple Intelligence to solve this natively.

---

### 1.5 Workout Video Analysis

**What it is:** Analyze workout videos for form, rep counting, etc.

**Why NOT to build:**

| Reason | Explanation |
|--------|-------------|
| Scope creep | You're not building Whoop or Tempo |
| Hevy integration exists | Get workout data from existing app |
| Complex ML | Form analysis requires specialized models |
| Not core value | Coaching is about conversation, not video |

**Alternative:** Pull workout data from Hevy via existing API.

---

### 1.6 Social Features

**What it is:** Leaderboards, friend challenges, social sharing.

**Why NOT to build:**

| Reason | Explanation |
|--------|-------------|
| Not personal | Personal AI coach is personal |
| Competition with giants | Strava, Peloton own this |
| Privacy | Your data model is single-user |
| Distraction | Focus on AI coaching, not social |

**Alternative:** Keep it personal. That's the moat.

---

## Category 2: DEFER These (Build Later If Needed)

### 2.1 Complex Goal Frameworks

**What it is:** Formal goal types, hypothesis tracking, A/B testing of interventions.

**Why DEFER:**

| Reason | Explanation |
|--------|-------------|
| YAGNI | You already have profile evolution |
| Over-engineering | Goals are fuzzy, not structured |
| Model handles this | Claude can track goals in prose |

**Current alternative:** `ProfileEvolutionService.swift` already extracts goals from conversation.

**When to reconsider:** If you find yourself manually tracking goals outside the app.

---

### 2.2 Complex Action Proposal System

**What it is:** AI proposes actions, user approves, system executes.

**Why DEFER:**

| Reason | Explanation |
|--------|-------------|
| What actions? | Most coaching is advice, not automation |
| Undo complexity | Actions need rollback, history, etc. |
| Trust calibration | Users need to trust AI first |

**Minimal version:** "Log this now" button that pre-fills nutrition entry.

**When to reconsider:** When you have specific automatable actions users request.

---

### 2.3 Ambient AI Notifications

**What it is:** AI proactively sends notifications based on context throughout the day.

**Why DEFER:**

| Reason | Explanation |
|--------|-------------|
| Creepy | "I noticed you haven't eaten" feels intrusive |
| Notification fatigue | Users hate too many notifications |
| Trust required | Need relationship before proactive outreach |

**Minimal version:** One protein nudge per day, max.

**When to reconsider:** After users explicitly request more proactive coaching.

---

### 2.4 Multi-User Support

**What it is:** Multiple users on same server, family accounts.

**Why DEFER:**

| Reason | Explanation |
|--------|-------------|
| Complexity | Authentication, isolation, permissions |
| Not needed | You're the only user |
| Architecture ready | user_id parameter enables this later |

**Current alternative:** Add `user_id` parameter everywhere (cheap insurance), but don't implement multi-user logic.

**When to reconsider:** When someone else wants to use it.

---

### 2.5 Confidence Percentages

**What it is:** Show "73% confident" on AI predictions.

**Why DEFER:**

| Reason | Explanation |
|--------|-------------|
| Fake precision | These numbers are often arbitrary |
| Misleading | Users interpret 73% as scientific |
| Natural language better | "I'm fairly confident" is more honest |

**Alternative:** Use natural language confidence: "I'm fairly confident", "This is speculative", "Based on limited data".

**When to reconsider:** Never. Keep it natural language.

---

### 2.6 Explanation UI

**What it is:** "Why did the AI say this?" breakdown for every response.

**Why DEFER:**

| Reason | Explanation |
|--------|-------------|
| Friction | Most users don't want to see the sausage being made |
| Model explanations sufficient | Claude can explain itself in chat |
| UI clutter | Extra buttons/panels add noise |

**Minimal version:** "What context did the AI have?" button in settings (not per-message).

**When to reconsider:** If users express confusion about AI responses.

---

## Category 3: SIMPLIFY These Existing Features

### 3.1 Tiered Context System

**Current:** 3 tiers with regex routing + topic detection.

**Keep:** The tiered structure.

**Simplify:** Don't add more tiers or complex routing.

> "Your topic detection regex is dumb and fast—don't replace it with LLM calls." — Carmack

---

### 3.2 Insight Categories

**Current:** 5 categories: correlation, trend, anomaly, milestone, nudge.

**Simplify:** Let the model decide categories. Remove hardcoded enum.

```python
# Before (over-specified)
"category": "correlation|trend|anomaly|milestone|nudge"

# After (model decides)
"You decide categories - use whatever makes sense"
```

---

### 3.3 Memory Protocol

**Current:** 4 types: remember, callback, tone, thread.

**Simplify:** Keep these as examples but allow model to create new types.

```markdown
Common types: remember, callback, tone, thread
You can also create your own: warning, celebration, boundary, etc.
```

---

### 3.4 Profile Schema

**Current:** 9 hardcoded categories in extraction.

**Simplify:** Open schema extraction.

```python
# Before
"EXTRACT THESE CATEGORIES: IDENTITY, GOALS, ..."

# After
"Extract what you actually learned. Don't force structure."
```

---

## The Decision Framework

When considering a new feature, ask:

### 1. Does the model already do this?

If Claude can do it in conversation, don't build UI for it.

### 2. Will a better model do this automatically?

If yes, don't build scaffolding around current limitations.

### 3. Is this core to AI coaching?

If it's not about personalized conversation + health data, skip it.

### 4. Am I building this because I want to code?

Be honest. Sometimes the urge to build is procrastination.

### 5. What's the simplest version?

Build that first. Usually you don't need more.

---

## The Anti-Roadmap

**Q1 2025:**
- ❌ Do NOT build always-listening
- ❌ Do NOT build barcode scanning
- ❌ Do NOT build AR portion estimation
- ❌ Do NOT add confidence percentages
- ❌ Do NOT build ambient AI

**Q2 2025:**
- ❌ Do NOT build on-device inference (wait for Apple)
- ❌ Do NOT build video analysis
- ❌ Do NOT build social features
- ❌ Do NOT build complex goal frameworks

**Forever:**
- ❌ Do NOT replace regex routing with LLM
- ❌ Do NOT add rigid insight schemas
- ❌ Do NOT build state machines for goals

---

## Summary Table

| Feature | Verdict | Reason |
|---------|---------|--------|
| Always-listening | NEVER | Battery, privacy, Apple will do it |
| Barcode scanning | NEVER | Yak shave, photo is better |
| AR portions | NEVER | Overkill, 2D photo works |
| On-device inference | WAIT | Apple Intelligence coming |
| Workout video | NEVER | Scope creep, Hevy exists |
| Social features | NEVER | Stay personal |
| Complex goals | DEFER | YAGNI |
| Action proposals | DEFER | What actions? |
| Ambient notifications | DEFER | Creepy |
| Multi-user | DEFER | user_id enables later |
| Confidence % | NEVER | Fake precision |
| Explanation UI | DEFER | Model explains itself |

---

## The Core Insight

> **"The features you DON'T build are what make your architecture AGI-native. Every piece of scaffolding becomes debt when the next model ships."** — Andrej Karpathy

Your current architecture is already right because it's simple:
- CLI wrapper for models (swappable)
- Rich context injection (model reasons over it)
- Prose-first personality (improves with models)
- Conversation as interface (timeless)

**Don't add complexity. Let better models make it better.**

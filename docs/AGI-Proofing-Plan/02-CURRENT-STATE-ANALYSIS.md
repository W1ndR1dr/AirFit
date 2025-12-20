# Current State Analysis: What AirFit Already Does Right

## Overview

Before proposing improvements, the six consultant perspectives first analyzed what AirFit's architecture already does well. The unanimous finding: **the codebase already embodies AGI-native design principles**.

---

## Architecture Summary

```
iOS App (SwiftUI/SwiftData) ──HTTP──> Python Server (FastAPI)
       │                                      │
       │                                      │ subprocess
       │                                      v
       │                            CLI Tools (claude, gemini, codex)
       │
       └── Widget Extension (Live Activities for macro tracking)
```

---

## What's Already Right

### 1. Model-Agnostic Scaffolding

**File:** `server/llm_router.py`

```python
async def call_claude(prompt, system_prompt, session_id, use_session=True):
    args = [config.CLAUDE_CLI, "--resume", session_id, "-p", prompt, ...]
    process = await asyncio.create_subprocess_exec(*args)
```

**Why It's Right:**
- CLI subprocess instead of SDK = no vendor lock-in
- Provider fallback chain (claude → gemini → codex)
- Session continuity via `--resume` flag
- New providers added without code changes
- Claude's CLI handles context compaction automatically

**Consultant Validation:**
> "Your CLI wrapper is prescient. When Claude 5 ships, you update the CLI and your app gets smarter immediately." — Carmack

---

### 2. Tiered Context Injection

**File:** `server/tiered_context.py`

```
Tier 1 (Core): ~100-150 tokens - ALWAYS injected
├─ Phase/goal
├─ Today's status (training/rest, cals/protein, sleep)
├─ Alerts (protein compliance, volume gaps)
├─ Top 3 insight headlines
└─ Tool hints

Tier 2 (Topic-triggered): ~200-400 tokens - Based on message
├─ Training: set tracker, recent workouts
├─ Nutrition: weekly summary
├─ Recovery: sleep/HRV trends
├─ Progress: body comp trends
└─ Goals: goal statements + phase

Tier 3 (On-demand): Tools (MCP/function calling)
└─ Deep queries not in standard context
```

**Why It's Right:**
- Not data dumping—smart relevance filtering
- Fast regex-based topic detection (0ms, not LLM inference)
- Token budget awareness
- Topic carryover via `last_topic` in sessions

**Consultant Validation:**
> "Your tiered context is exactly right. The topic detection regex is dumb and fast—don't replace it with LLM calls." — Carmack

---

### 3. Prose-First Profile System

**File:** `server/profile.py`

```python
personality_notes: str  # Full prose, not enum mappings
```

**Example:**
```
"With Brian, I lean into the dark surgeon humor - the guy spends his days
literally inside people's bodies, so nothing phases him. When he's grinding
through a cut, I might crack a joke about his protein being 'surgically precise'..."
```

**Why It's Right:**
- Future models synthesize better personas automatically
- No code changes needed for better personalization
- Captures nuance that enums never could
- Fallback to structured `CoachingDirectives` if synthesis unavailable

**Consultant Validation:**
> "The prose-first architecture is your crown jewel. It will improve automatically with every model upgrade." — Original Analysis

---

### 4. AI-Decided Memory

**File:** `server/memory.py`

```
<memory:remember>What to remember about this exchange</memory:remember>
<memory:callback>A phrase/joke that could be referenced later</memory:callback>
<memory:tone>Observation about what communication style worked</memory:tone>
<memory:thread>Topic to follow up on in future sessions</memory:thread>
```

**Why It's Right:**
- AI decides what's memorable—not hardcoded rules
- Semantic markers instead of rigid JSON schemas
- Stored as human-readable markdown
- 1-3 markers per conversation max prevents bloat

**Consultant Validation:**
> "This is exactly how you design prompts for evolving models. The model gets smarter at identifying relationship-building moments; your code doesn't change." — Original Analysis

---

### 5. Raw Data to AI Reasoning

**File:** `server/insight_engine.py`

```python
INSIGHT_PROMPT = """You are an expert fitness coach analyzing a client's data.

Your job: Find what's interesting, important, or actionable.
Look for patterns, correlations, anomalies, progress, and risks.

Focus on insights the user wouldn't easily notice themselves -
especially cross-domain correlations...
"""
```

**Data format (~40-60 tokens/day):**
```
2025-12-13 | N:2727|249|252|66|6 | H:w180.5,bf23,sl7.2,hr41,hrv64.7 | W:1x|41m|8747kg
```

**Why It's Right:**
- No hardcoded pattern rules
- Feeds raw data, lets AI reason
- Better models find deeper patterns automatically
- Compact format preserves full signal

**Consultant Validation:**
> "This is where the AI-native philosophy peaks. You're not building inferior pattern matching in Python—you're trusting the model to find what matters." — Original Analysis

---

### 6. Device-First Data Ownership

**Architecture Note (from `context_store.py`):**
```
iOS device OWNS GRANULAR nutrition entries (individual meals in SwiftData)
Server receives DAILY AGGREGATES only (~2KB/day)
```

**Why It's Right:**
- Privacy by design
- Raspberry Pi storage efficiency
- Future on-device models get full granular access
- Network resilience—app works offline

**Consultant Validation:**
> "Device owns identity and data; server is compute layer. This is the right bet for personal infrastructure." — Patrick

---

### 7. Organic Profile Evolution

**Flow:**
```
Conversation → extract_from_conversation() → Update profile → Personality synthesis
```

**Why It's Right:**
- No forms, no questionnaires
- AI learns from natural conversation
- Timestamped insights create audit trail
- Profile complexity grows with relationship

**Brian's Profile (after 4 days):**
- 12 discovered goals
- 12 relationship notes
- 8 observed patterns
- 8 timestamped insights

**Consultant Validation:**
> "The profile wasn't built from forms. It emerged from conversation. This is the only approach that scales to truly personalized AI." — Original Analysis

---

## Architecture Scorecard (Pre-Improvement)

| Principle | Score | Evidence |
|-----------|-------|----------|
| **Models improve** | 9/10 | CLI routing, prose personas, raw data → AI |
| **Model-agnostic scaffolding** | 9.5/10 | Provider fallback, no SDK lock-in |
| **Minimal rigid structure** | 8/10 | Prose profiles, markdown memory (macros are rigid) |
| **Context is king** | 9/10 | Tiered injection, rich system prompts |
| **Evolving personalization** | 9.5/10 | Organic growth, timestamped learning |
| **Forward-compatible** | 8.5/10 | Ready for better models (needs user_id, versioning) |

---

## The Key Insight

**The codebase already embodies the CLAUDE.md philosophy:**
- Don't over-engineer around current limitations
- Trust natural language in, natural language out
- Feed rich context, let the model reason
- AI learns through conversation, not forms

The temptation to add "AGI-proofing" features (action systems, hypothesis tracking, reasoning views) would actually **move away from these principles** by adding rigid scaffolding.

---

## What Actually Needs Improvement

### High Priority (Cheap Insurance)
1. Add `schema_version` to all data structures
2. Add `user_id` parameter everywhere (default to "default")
3. Add `extensions` dict to snapshots for future fields
4. Move profile seed data from code to JSON file

### Medium Priority (Prompt Improvements)
1. Loosen insight prompt constraints (no "max 8 words")
2. Loosen extraction prompt schema (flexible fields, not forced nulls)
3. Add alignment principles to system prompts

### Low Priority (Ship First)
1. Fix voice input threading
2. Add photo food logging
3. Add protein nudge notification

---

## Summary

The consultants unanimously validated the existing architecture as **already AGI-native**. The work ahead is:
1. Add cheap infrastructure insurance
2. Improve prompts (loosen, don't tighten)
3. Ship pending features
4. Use the app and learn

The architecture doesn't need to change—it needs to be trusted.

# Architecture Validation: What to Keep and Why

## Overview

The six consultant perspectives unanimously validated AirFit's existing architecture as **already AGI-native**. This document explains what's right and why it should be preserved.

---

## Core Architecture Pattern

```
iOS App (SwiftUI/SwiftData) ──HTTP──> Python Server (FastAPI)
       │                                      │
       │                                      │ subprocess
       │                                      v
       │                            CLI Tools (claude, gemini, codex)
       │
       └── Widget Extension (Live Activities)
```

**Why This Is Right:**

| Layer | Design Choice | Benefit |
|-------|---------------|---------|
| iOS | SwiftData as source of truth | Offline-first, privacy |
| Network | HTTP + JSON | Simple, debuggable |
| Server | FastAPI async | Fast, lightweight |
| LLM | CLI subprocess | Model-agnostic, no SDK lock-in |

---

## 1. CLI-Based LLM Routing

**File:** `server/llm_router.py`

```python
async def call_claude(prompt, system_prompt, session_id, use_session=True):
    args = [config.CLAUDE_CLI, "--resume", session_id, "-p", prompt, ...]
    process = await asyncio.create_subprocess_exec(*args)
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| No SDK dependency | Claude 5 ships? Update CLI, not code |
| Session continuity | `--resume` handles context compaction |
| Provider fallback | Tries claude → gemini → codex automatically |
| Future-proof | Any CLI tool works with same pattern |

### Consultant Validation:

> "Your CLI wrapper is prescient. When Claude 5 ships, you update the CLI and your app gets smarter immediately." — Carmack

> "The model-agnostic scaffolding is exactly right." — Original Analysis

---

## 2. Tiered Context Injection

**File:** `server/tiered_context.py`

```
Tier 1 (Core): ~100-150 tokens - ALWAYS
├─ Phase/goal
├─ Today's status
├─ Alerts
├─ Top 3 insight headlines
└─ Tool hints

Tier 2 (Topic-triggered): ~200-400 tokens
├─ Training / Nutrition / Recovery / Progress / Goals

Tier 3 (On-demand): Tools (MCP/function calling)
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| Not data dumping | Smart relevance filtering |
| Fast routing | Regex topic detection is 0ms |
| Token efficiency | Only sends what matters |
| Scalable | Works with any context window size |

### Consultant Validation:

> "Your tiered context is exactly right. The topic detection regex is dumb and fast—don't replace it with LLM calls." — Carmack

---

## 3. Prose-First Personality

**File:** `server/profile.py`

```python
personality_notes: str  # Full prose, not enum mappings
```

**Example:**
```
"With Brian, I lean into the dark surgeon humor - the guy spends his days
literally inside people's bodies, so nothing phases him..."
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| Future models improve it | No code changes needed |
| Captures nuance | Enums can't express "dark surgeon humor" |
| Natural language native | LLM-to-LLM communication |
| Fallback exists | CoachingDirectives if synthesis unavailable |

### Consultant Validation:

> "The prose-first architecture is your crown jewel." — Original Analysis

> "The best design choice I see in this codebase." — Jony

---

## 4. AI-Decided Memory

**File:** `server/memory.py`

```xml
<memory:remember>...</memory:remember>
<memory:callback>...</memory:callback>
<memory:tone>...</memory:tone>
<memory:thread>...</memory:thread>
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| Model decides what's memorable | No hardcoded rules |
| Semantic markers | Claude-native format |
| Markdown storage | Human-readable, debuggable |
| Selective (1-3 max) | Prevents memory bloat |

### Consultant Validation:

> "Your <memory:thread> pattern is already correct. Trust it more." — Andrej

---

## 5. Raw Data to AI Reasoning

**File:** `server/insight_engine.py`

```python
"""
Your job: Find what's interesting, important, or actionable.
Focus on cross-domain correlations the user wouldn't notice themselves.
"""
```

**Data format (~40-60 tokens/day):**
```
2025-12-13 | N:2727|249|252|66|6 | H:w180.5,bf23,sl7.2,hr41,hrv64.7 | W:1x|41m|8747kg
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| No hardcoded pattern rules | AI finds what matters |
| Compact but lossless | Full signal, minimal tokens |
| Improves with models | Better AI = better insights |
| Deduplication | Prevents repeated insights |

### Consultant Validation:

> "This is where the AI-native philosophy peaks. Feed raw data, let AI reason." — Original Analysis

---

## 6. Device-First Data Ownership

**Architecture Note:**
```
iOS device OWNS GRANULAR nutrition entries (individual meals)
Server receives DAILY AGGREGATES only (~2KB/day)
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| Privacy by design | Granular data never leaves device |
| Raspberry Pi efficient | ~700KB/year is nothing |
| Recovery | iPhone can resync if Pi dies |
| Offline-first | App works without network |

### Consultant Validation:

> "Device owns identity and data; server is compute layer. This is the right bet." — Patrick

---

## 7. Organic Profile Evolution

**Flow:**
```
Conversation → extract_from_conversation() → Update profile → Personality synthesis
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| No forms, no questionnaires | Natural learning |
| Timestamped insights | Audit trail |
| Continuous | Every conversation teaches |
| Personality synthesis | Evolves with relationship |

### Consultant Validation:

> "The profile emerged from conversation, not forms. This is the only approach that scales." — Original Analysis

---

## 8. JSON-Per-Concern Storage

**Structure:**
```
/data/
  profile.json       (~10KB)
  context_store.json (~50KB)
  memories/          (~5KB)
```

### Why Keep It:

| Aspect | Benefit |
|--------|---------|
| Simple | No database to maintain |
| Human-readable | Easy debugging |
| Portable | Copy files to backup |
| Efficient for one user | Overkill for one, but works |

### Consultant Validation:

> "One JSON file per concern. That's the architecture. You already have it." — Carmack

---

## What NOT to Change

### Keep These Patterns:

| Pattern | Reason |
|---------|--------|
| CLI subprocess routing | Model-agnostic |
| Regex topic detection | Fast (0ms vs 2-5s) |
| Markdown memory storage | Human-readable, LLM-native |
| Prose personality | Improves with models |
| Daily aggregates on server | Privacy, efficiency |
| Tools for on-demand queries | Let model request what it needs |

### Resist These Temptations:

| Temptation | Why Resist |
|------------|------------|
| Replace regex with LLM routing | 0ms vs 2-5s latency |
| Add rigid insight schemas | Limits what model can express |
| Build state machines for goals | Goals are fuzzy |
| Add confidence percentages | Fake precision |
| Create action frameworks | Model proposes in natural language |

---

## Summary

> **"Your architecture is already right. The biggest win would be to SIMPLIFY, not add."** — Andrej

The architecture embodies the CLAUDE.md philosophy:
- Models improve → CLI routing adapts automatically
- Context is king → Tiered injection, not data dumping
- Minimal rigid structure → Prose over schemas
- Evolving personalization → Organic profile growth

**Preserve these patterns. They're the load-bearing walls.**

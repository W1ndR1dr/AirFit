# Prompt Improvements Guide

## Overview

This guide documents specific prompt improvements identified by the consultant analysis. The key insight: **loosen constraints, don't tighten them.** Better models work better with freedom.

---

## 1. Insight Generation Prompt

### Current (Over-Constrained)

**File:** `server/insight_engine.py` (lines 124-182)
**Also:** `AirFit/Services/LocalInsightEngine.swift` (lines 312-368)

```python
"""
...
Respond in JSON format with an array of insights:
{
  "insights": [
    {
      "category": "correlation|trend|anomaly|milestone|nudge",
      "tier": 1-5,
      "title": "Short punchy title (max 8 words)",
      ...
    }
  ]
}
...
"""
```

### Problems:

| Constraint | Problem |
|------------|---------|
| `"category": "correlation\|trend\|anomaly\|milestone\|nudge"` | Hardcoded enum limits future insight types |
| `"tier": 1-5` | Fixed range, no room for nuance |
| `"max 8 words"` | Arbitrary, limits expression |
| Rigid JSON schema | Forces structure model doesn't need |

### Improved Version:

```python
INSIGHT_PROMPT = """You are an expert fitness coach analyzing a client's data.

Find what's interesting, important, or actionable. Be specific and data-driven.
Focus on cross-domain correlations the user wouldn't notice themselves.

Return JSON with your insights:
{
  "insights": [
    {
      "title": "...",
      "body": "...",
      "reasoning": "How I arrived at this conclusion",
      "confidence": 0.0-1.0,
      "evidence": ["data point 1", "data point 2"],
      "supporting_data": {...}  // For visualization
    }
  ]
}

You decide:
- Categories (use whatever makes sense: correlation, trend, warning, celebration, etc.)
- Priority (however you want to express importance)
- Actions (if any are worth suggesting)
- Any other fields that matter

Quality over quantity. Return only valid JSON.
"""
```

### Why This Is Better:

- Model decides categories → can invent new ones
- No arbitrary length constraints
- Explicit reasoning field enables learning
- Evidence array traces back to data
- Flexible structure for future needs

---

## 2. Profile Extraction Prompt

### Current (Rigid Schema)

**File:** `server/profile.py` (lines 313-369)
**Also:** `AirFit/Services/ProfileEvolutionService.swift`

```python
"""
EXTRACT THESE CATEGORIES:
1. IDENTITY: name, age, height, occupation
2. GOALS: specific goals with timelines
...

RESPOND ONLY WITH JSON:
{
  "identity": {"name": null, "age": null...},
  ...
}

Use null for unknown fields, empty arrays for no new items
"""
```

### Problems:

| Issue | Impact |
|-------|--------|
| 9 hardcoded categories | Can't discover new dimensions |
| Forced null-filling | Schema is prescriptive |
| Nested structure | Over-specified |

### Improved Version:

```python
EXTRACT_SYSTEM_PROMPT = """Analyze this conversation for profile information.

Extract ONLY what you actually learned. Don't force structure.

Return JSON:
{
  "learned": {
    // Whatever fields you discovered - be specific
    // Examples:
    // "protein_struggles_on_weekends": true
    // "prefers_morning_workouts": "before 7am"
    // "has_shoulder_injury": "left rotator cuff, from 2019"
  },
  "confidence": {
    // Confidence for each field (0-1)
    "protein_struggles_on_weekends": 0.9,
    "prefers_morning_workouts": 0.6
  },
  "source": {
    // Which message this came from
    "protein_struggles_on_weekends": "user_msg_3"
  }
}

Be specific: "surgeon with unpredictable on-call schedule" not "busy job"
Capture personality: "uses dark humor", "data-driven"
Note motivations: "ski season in January" not just "wants to lose weight"
"""
```

### Why This Is Better:

- No forced null-filling
- Confidence per field
- Source attribution for verification
- Open schema for new dimensions
- Model discovers what matters

---

## 3. Personality Synthesis Prompt

### Current (Two Versions)

**Better version:** `AirFit/Services/PersonalitySynthesisService.swift` (lines 32-77)
**Worse version:** `AirFit/Services/ProfileEvolutionService.swift` (lines 90-119)

### Recommended (PersonalitySynthesisService version):

```swift
"""
You are crafting a coaching persona for an AI fitness coach.

Write 3-5 paragraphs of natural prose. No bullet points, no headers.
This should read like a friend describing their coaching approach.

BAD EXAMPLE (too generic):
"I'm a supportive coach who believes in positive reinforcement."

GOOD EXAMPLE (specific and personal):
"With Brian, I lean into the dark surgeon humor - the guy spends his days
literally inside people's bodies, so nothing phases him. When he's grinding
through a cut, I might crack a joke about his protein being 'surgically
precise' or note that his volume is trending up like his patient outcomes."

ANOTHER GOOD EXAMPLE:
"She's a morning person who hates being lectured. I keep things punchy
before 9am - just the facts, maybe a joke about her cat, definitely not
a wall of text about glycogen replenishment."

Write as instructions to yourself - how YOU should behave with THIS person.
"""
```

### Action: Sync to ProfileEvolutionService

The PersonalitySynthesisService version is superior. Update ProfileEvolutionService to match.

---

## 4. Memory Protocol

### Current (Already Good)

**File:** `server/memory.py` (lines 28-43)

```
MEMORY PROTOCOL:
You have relationship memory from past conversations. Use it naturally:
- Reference callbacks and inside jokes when they fit organically
- Build on established threads and ongoing topics
- Maintain the communication style that's worked

When something genuinely memorable happens (1-3 per conversation max), mark it:
<memory:remember>What to remember about this exchange</memory:remember>
<memory:callback>A phrase/joke that could be referenced later</memory:callback>
<memory:tone>Observation about what communication style worked</memory:tone>
<memory:thread>Topic to follow up on in future sessions</memory:thread>

Be selective - only mark genuinely relationship-building moments, not every fact.
```

### Enhancement: Dynamic Memory Types

The regex already handles any type. Just update the prompt:

```
Mark memorable moments with: <memory:TYPE>content</memory:TYPE>

Common types:
- remember: General things to remember
- callback: Inside jokes to reference later
- tone: Communication style observations
- thread: Topics to follow up

You can also create your own types:
- <memory:warning>Something to watch out for</memory:warning>
- <memory:celebration>A win worth referencing</memory:celebration>
- <memory:boundary>Something user doesn't want</memory:boundary>

Be selective - 1-3 markers per conversation max.
```

---

## 5. Nutrition Parsing Prompt

### Current (Good, Minor Tweak)

**File:** `server/nutrition.py` (lines 32-56)

```python
"""
You are a nutrition parsing assistant. When given a food description,
estimate the macros.

RESPOND ONLY WITH JSON in this exact format:
{
  "name": "cleaned up food name",
  "calories": 450,
  "protein": 35,
  ...
}
"""
```

### Minor Enhancement:

Change:
```
RESPOND ONLY WITH JSON in this exact format:
```

To:
```
Return only valid JSON (no markdown, no explanation):
```

This is slightly more forgiving while maintaining the same constraint.

---

## 6. Alignment Principles (Add to System Prompt)

### New Addition

**File:** `server/profile.py` (add to system prompt generation)

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
- Before proposing changes, reference chain of validated observations

### Uncertainty Expression
When uncertain, say so in natural language:
- "I'm fairly confident that..."
- "This is speculative, but..."
- "Based on limited data..."
NOT: "73% confidence"

### The Off Switch
If user says "reset" or "start over":
- Clear learned preferences
- Revert to onboarding state
- Preserve raw data, wipe AI-derived insights
```

---

## Summary: Prompt Philosophy

| Principle | Application |
|-----------|-------------|
| **Loosen, don't tighten** | Remove arbitrary constraints (max 8 words, etc.) |
| **Let model decide structure** | Open schemas, not rigid enums |
| **Examples over templates** | Show the vibe, not the format |
| **Natural language confidence** | "I'm fairly confident" not "73%" |
| **Prose over JSON for creative** | Personality synthesis should be prose |
| **Reasoning as explicit field** | Add reasoning/evidence to insight schema |

---

## Implementation Checklist

- [ ] Update `insight_engine.py` INSIGHT_PROMPT
- [ ] Update `LocalInsightEngine.swift` insightPrompt
- [ ] Update `profile.py` EXTRACT_SYSTEM_PROMPT
- [ ] Sync PersonalitySynthesisService prompt to ProfileEvolutionService
- [ ] Update memory protocol to allow dynamic types
- [ ] Minor fix to nutrition parsing prompt
- [ ] Add alignment principles to system prompt

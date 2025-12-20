# John Carmack Perspective: Engineering Efficiency

*Thinking as the legendary programmer, former id Software/Oculus CTO, now AGI researcher—obsessed with performance, efficiency, cutting through complexity, and building things that actually work.*

---

## The Verdict: You're 80% There

I've read through your codebase. First, let me say—**you've already got a lot of this right**. Your CLAUDE.md philosophy is exactly correct. But let's cut through the proposal and look at what actually matters.

---

## 1. What's the SIMPLEST AGI-Ready Architecture?

The answer is already in your code. You have it:

**One JSON file per concern. Period.**

```
/data/
  profile.json       (~10KB) - Who is this person
  context_store.json (~50KB) - Daily aggregates
  memories/          (~5KB)  - Relationship texture
```

That's it. That's the architecture.

You're already storing ~2KB/day in `context_store.json` (daily snapshots of nutrition, health, workouts). The model reads the file, does its thing, writes back.

Your `context_store.py` with its `DailySnapshot` dataclass is already the correct abstraction.

The proposal mentions "hypothesis tracking systems" and "goal state machines"—that's enterprise brain poisoning. The LLM already *is* your reasoning engine. Feed it data, let it reason. You don't need to build inferior state machines in Python that will be obsolete in 18 months when the models can just do it better.

---

## 2. Where Is This Plan Adding Unnecessary Complexity?

### ALREADY CORRECT in your code:

| Component | File | Why It Works |
|-----------|------|--------------|
| Tiered context | `tiered_context.py` | Selective injection (100-150 tokens core, 200-400 per topic) |
| Memory markers | `memory.py` | `<memory:remember>` markers let model decide |
| Profile personality | `profile.py` | `seed_brian_profile()` shows personality > schema |
| Topic detection | `TopicDetector` | Fast, dumb regex. Works. |

### RED FLAGS in the proposal:

| Feature | Problem |
|---------|---------|
| Outcome measurement databases | You have `context_store.json`. Feature creep. |
| Structured observation stores | LLM should observe. Not rigid schemas. |
| LLM-based topic detection | **WRONG.** Regex is 0ms. LLM is 2-5s on Pi. |

The `TopicDetector` class is the correct pattern:

```python
# Fast and dumb. Works.
if "workout" in message_lower or "training" in message_lower:
    score += 1
```

Don't overthink this. Routing should be microseconds, not LLM inference.

---

## 3. What Should Stay On-Device vs. Server?

Your architecture note in `context_store.py` already nails this:

> iOS device owns GRANULAR nutrition entries (individual meals in SwiftData)
> Server receives DAILY AGGREGATES only

### Device (iPhone):
- Individual meal entries
- Raw HealthKit samples
- SwiftData as source of truth
- UI state, caching
- Voice transcription (use device neural engine)

### Server (Pi):
- Daily aggregates only
- Profile evolution
- LLM inference (when not using direct Gemini calls)
- Memory consolidation

### Why This Split Works:
1. **Privacy** — granular data never leaves device
2. **Storage** — Pi is cheap (~2KB/day = ~700KB/year)
3. **Recovery** — If Pi dies, iPhone can resync
4. **Resilience** — App works offline, syncs when available

The hybrid approach in your `/chat/context` endpoint (iOS calls Gemini directly but gets context from server) is actually clever—low-latency inference with centralized "brain."

---

## 4. Architecting for Local Models on Pi (2-3 years out)

You're calling CLI tools via subprocess:

```python
process = await asyncio.create_subprocess_exec(
    config.CLAUDE_CLI, "--resume", session_id, "-p", prompt...
)
```

This is fine for now but not future-proof for local inference.

### What I'd Add (50 lines):

```python
# llm_router.py - add local inference path
async def call_local(prompt: str, system_prompt: str) -> LLMResponse:
    """Call local model via HTTP endpoint (ollama, llama.cpp, vLLM)."""
    # All these expose OpenAI-compatible endpoints
    async with aiohttp.ClientSession() as session:
        response = await session.post(
            "http://localhost:11434/v1/chat/completions",
            json={
                "model": "llama3.2",
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ]
            })
        # ...
```

### Key Insight

Ollama, llama.cpp server, and vLLM all expose **OpenAI-compatible HTTP endpoints**.

Future-proofing is:
1. Add HTTP-based provider to router
2. Point at localhost for local inference
3. Rest of architecture unchanged

### Hardware Reality Check for Pi:

| Timeline | Capability |
|----------|------------|
| Current Pi 5 | ~1-3B models acceptable (Phi-3, Gemma-2B) |
| 2026-ish | 7-8B viable with ARM NPU acceleration |
| For fitness coaching | Fine-tuned 3B probably sufficient |

**Recommendation:** Build a simple `/v1/chat/completions` compatible endpoint wrapper now. Costs nothing today, enables everything later.

---

## 5. The Most Efficient Data Structure

Looking at what you're injecting in `tiered_context.py`:

```python
# Tier 1: Always (~150 tokens)
# - Phase/goal
# - Today's status
# - Active alerts
# - Top 3 insight headlines
# - Tool hints

# Tier 2: Topic-triggered (~300 tokens per topic)
# - Training, Nutrition, Recovery, Progress, Goals
```

**This is almost exactly right.** But I'd push further.

### The Carmack Compression

Instead of multiple data structures, one flat timeline with semantic headers:

```markdown
# Brian - Cut Phase (Ski Season)
Target: 175lb @ 15% BF (currently 180 @ 23%)

## TODAY (Dec 19)
Training day | 1850cal, 145g protein | Slept 6.2h
Alert: Protein under target 3/5 days

## ROLLING 7-DAY SNAPSHOT
Training: 4 sessions, 18 chest sets, 12 back sets (triceps LOW: 6 sets)
Nutrition: avg 2100cal (target 2200), 168g protein (target 175) - 89% compliance
Body: 180.2lb (EMA), trending -0.3lb/week
Recovery: 6.5h avg sleep, HRV stable at 45ms

## RECENT CONTEXT
- Dec 17: PR on DB bench (90lb x 8)
- Dec 15: Mentioned ski trip in January
- Dec 12: Complained about protein getting boring

## TOOLS AVAILABLE
query_workouts, query_nutrition, query_body_comp, query_recovery
```

That's ~250 tokens. It's everything. The model can reason from here.

### Key Insight

The model doesn't need separate objects. It needs a well-formatted text blob that's easy to parse.

**Markdown with consistent headers is the most LLM-native format.**

Your system prompt + this context window IS the entire "database" as far as the model cares.

---

## 6. What I'd Actually Build

### Keep:
1. Your current architecture—it's more correct than most enterprise apps
2. CLI wrapper for model-agnostic routing
3. JSON-per-concern storage pattern
4. Dumb regex for topic detection

### Add:
1. HTTP-based local model support (50 lines)
2. `schema_version` field on data structures
3. `user_id` parameter (default "default")

### Delete from proposal:
- Everything except the cheap insurance items

---

## Summary

| Proposed | Reality Check |
|----------|---------------|
| Hypothesis tracking | Model remembers if you put it in context |
| Goal state machines | Goals are fuzzy; state machines lie |
| Outcome databases | You have context_store |
| LLM topic detection | Regex: 0ms. LLM: 2-5s. Do the math. |
| Structured observations | Let the model observe |

---

## The TL;DR

1. **You're 80% there.** Your architecture is more correct than most.

2. **Don't add state machines.** The proposal's "hypothesis tracking" and "goal state machines" are premature optimization.

3. **Keep the dumb routing.** Regex for topics, LLM for content.

4. **Add HTTP-based local model support now.** 50 lines, future-proofs everything.

5. **Your JSON-per-concern pattern is correct.** `context_store.json` + `profile.json` + `memories/` is the right split.

6. **Flatten context for the model.** One markdown blob, not nested objects.

---

## The Thing That Matters

> **Does it actually work?**

Ship it. Use it daily. Notice where it breaks. Fix those things.

Theoretical AGI-proofing is worthless. Empirical feedback from using the app is everything.

Your codebase shows you understand this. Stay the course.

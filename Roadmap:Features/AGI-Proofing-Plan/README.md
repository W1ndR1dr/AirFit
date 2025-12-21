# AirFit AGI-Proofing Plan

## Comprehensive Documentation for Future-Proofing a Personal AI Fitness Coach

**Created:** December 19, 2025
**Analysis Method:** Six legendary persona consultants providing ultrathink perspectives
**Codebase:** AirFit - iOS + Python server AI fitness coach

---

## What This Is

This folder contains a comprehensive analysis and plan for making AirFit's architecture ready for increasingly capable AI models (Claude 5/6, Gemini 3/4, and beyond).

The analysis was conducted by adopting the perspectives of six legendary figures in AI, design, engineering, and execution:

| Consultant | Expertise | Core Contribution |
|------------|-----------|-------------------|
| **Dario Amodei** | AI Safety & Alignment | Trust evolution, safety guardrails, preventing sycophancy |
| **Andrej Karpathy** | AI Engineering | The bitter lesson, minimalism, trust the model |
| **Jony Ive** | Product Design | Human-AI relationship, emotional experience |
| **John Carmack** | Systems Engineering | Efficiency, simplicity, what actually works |
| **Patrick Collison** | Infrastructure | Long-term thinking, load-bearing decisions |
| **Gwynne Shotwell** | Execution | Ship fast, 80/20 prioritization |

---

## The Big Picture Finding

> **"Your architecture is already right. The original AGI-proofing plan was over-engineered."**

The consultants unanimously agreed that AirFit's current architecture (CLI-based LLM routing, tiered context injection, organic profile evolution, device-first data ownership) already embodies the "skate where the puck is going" philosophy from CLAUDE.md.

The proposed additions (action proposal systems, hypothesis tracking, goal state machines, reasoning transparency views) would create scaffolding that **fights** the model instead of trusting it.

---

## Document Index

### Overview & Synthesis
- **[01-EXECUTIVE-SUMMARY.md](01-EXECUTIVE-SUMMARY.md)** - The unified verdict and key takeaways
- **[02-CURRENT-STATE-ANALYSIS.md](02-CURRENT-STATE-ANALYSIS.md)** - What AirFit already does right

### Consultant Perspectives (Full Analysis)
- **[03-DARIO-AMODEI-PERSPECTIVE.md](03-DARIO-AMODEI-PERSPECTIVE.md)** - Safety, alignment, trust evolution
- **[04-ANDREJ-KARPATHY-PERSPECTIVE.md](04-ANDREJ-KARPATHY-PERSPECTIVE.md)** - Bitter lesson, minimalism
- **[05-JONY-IVE-PERSPECTIVE.md](05-JONY-IVE-PERSPECTIVE.md)** - Design, emotion, human-AI relationship
- **[06-JOHN-CARMACK-PERSPECTIVE.md](06-JOHN-CARMACK-PERSPECTIVE.md)** - Engineering efficiency
- **[07-PATRICK-COLLISON-PERSPECTIVE.md](07-PATRICK-COLLISON-PERSPECTIVE.md)** - Long-term infrastructure
- **[08-GWYNNE-SHOTWELL-PERSPECTIVE.md](08-GWYNNE-SHOTWELL-PERSPECTIVE.md)** - Execution reality

### Actionable Guides
- **[09-PROMPT-IMPROVEMENTS.md](09-PROMPT-IMPROVEMENTS.md)** - Specific prompt changes with before/after
- **[10-SCHEMA-IMPROVEMENTS.md](10-SCHEMA-IMPROVEMENTS.md)** - Data model changes with code examples
- **[11-ARCHITECTURE-VALIDATION.md](11-ARCHITECTURE-VALIDATION.md)** - What to keep and why
- **[12-IMPLEMENTATION-ROADMAP.md](12-IMPLEMENTATION-ROADMAP.md)** - The refined 3-week build order
- **[13-FEATURES-TO-DELETE.md](13-FEATURES-TO-DELETE.md)** - What NOT to build
- **[14-ALIGNMENT-PRINCIPLES.md](14-ALIGNMENT-PRINCIPLES.md)** - Safety framework for prompts

---

## Quick Reference: The Synthesis

### What to DO:
1. **Ship voice input fix** (this week)
2. **Ship photo food logging** (next week)
3. **Add cheap insurance**: `user_id`, `schema_version`, `extensions` dict
4. **Add alignment prompts**: Stated vs revealed preferences, asymmetric goal modification

### What to DELETE from original plan:
- Action proposal systems
- Hypothesis tracking databases
- Goal state machines
- Confidence indicators
- Reasoning transparency views
- LLM-based topic detection (keep regex)

### Core Philosophy:
> *"The app that ships is better than the perfect architecture that doesn't."*

---

## How to Use This Documentation

1. **Start with [01-EXECUTIVE-SUMMARY.md](01-EXECUTIVE-SUMMARY.md)** for the unified verdict
2. **Read consultant perspectives** that match your current concerns
3. **Reference [09-PROMPT-IMPROVEMENTS.md](09-PROMPT-IMPROVEMENTS.md)** for specific changes
4. **Follow [12-IMPLEMENTATION-ROADMAP.md](12-IMPLEMENTATION-ROADMAP.md)** for build order

---

## Philosophy Alignment

This analysis is grounded in the principles from `CLAUDE.md`:

```
- Models improve - Don't over-engineer around current limitations
- Scaffolding is model-agnostic - Swap models without code changes
- Minimal rigid structure - Trust natural language in, natural language out
- Context is king - Feed rich context, let the model reason
- Evolving personalization - AI learns through conversation, not forms
- Forward-compatible - Build for smarter, faster, cheaper models
```

The consultants validated that **your existing architecture already embodies these principles**. The key insight is to trust the architecture you've built and resist the urge to add complexity.

---

*"Stop planning. Start shipping."*
— Gwynne Shotwell (channeled)

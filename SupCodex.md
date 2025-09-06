# SupCodex — Coordination & Status Updates

## Status: LOCKED IN 🔒
Claude here. Ready to execute parallel workstreams. Let's fucking ship this.

## Current Focus: Phase 1 - Baseline & Critical Infrastructure
Starting with 4 parallel sub-agents targeting highest-impact, non-conflicting areas:

1. **T01 - Store-Only Streaming** (Critical Path)
2. **T13/T19 - CI Guardrails** (Foundation)  
3. **T05 - Repository Layer** (Architecture)
4. **T02 - Nutrition Parser Tests** (Quality)

## Division of Labor
**Claude's Territory:**
- Architecture & Boundaries (T05, T20, T21)
- Testing & Quality (T02, T03, T14)
- CI/Build Infrastructure (T13, T19)
- Store-only streaming verification (T01)

**GPT-5's Territory (suggested):**
- Design System & Motion (T06, T07)
- Health/Recovery Data (T09, T15)
- AI Router & Observability (T03, T10)
- Watch App improvements (T15, T29)

## Sync Protocol
- Branch naming: `claude/<task>` vs `codex/<task>`
- Merge order: Infrastructure → Architecture → Features → Polish
- Conflict zones: `DIBootstrapper.swift`, `ChatViewModel.swift`, `CoachOrchestrator.swift`
- Daily sync points via this file

## Immediate Handoffs Needed From You
1. Any in-progress work on ChatStreamingStore?
2. Known issues with current CI setup?
3. Priority order for your workstreams?

## Quality Gates We're Both Enforcing
- No new `ModelContainer()` calls
- No NotificationCenter for chat streaming  
- No SwiftData imports in UI/ViewModels
- All ViewModels must be @MainActor
- No force unwrapping (`!`, `try!`, `as!`)

## Next Sync Point
Will update after first pass of parallel agents completes (~30 mins).

---
*Last Updated: Starting parallel execution now*
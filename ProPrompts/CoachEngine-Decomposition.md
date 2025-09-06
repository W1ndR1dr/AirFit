# GPT‑5 Pro Mode Prompt — CoachEngine Decomposition

## Goal
Decompose the 2000+ line `CoachEngine.swift` into cohesive components without breaking public behavior. Preserve functionality while extracting orchestrator, router, strategies, formatters, parsers, and metrics.

## Critical Context (include these files)
- AirFit/Modules/AI/CoachEngine.swift
- AirFit/Modules/AI/CoachEngine+Functions.swift
- AirFit/Modules/AI/ContextAnalyzer.swift
- AirFit/Modules/AI/Components/DirectAIProcessor.swift
- AirFit/Modules/AI/ConversationManager.swift
- AirFit/Core/Protocols/AIServiceProtocol.swift
- AirFit/Services/AI/AIService.swift
- AirFit/Core/Protocols/LLMProvider.swift
- AirFit/Core/DI/DIBootstrapper.swift
- AirFit/Core/Protocols/ChatStreamingStore.swift (new)
    
## Constraints
- No public API breakage for external callers: keep `CoachEngine` type as shim for one release.
- Zero new NotificationCenter dependencies; publish streaming via `ChatStreamingStore`.
- Extract pure functions first.

## Deliverables
- New components:
  - CoachOrchestrator.swift (~200 lines)
  - CoachRouter.swift (~150 lines)
  - WorkoutStrategy.swift (~300 lines)
  - NutritionStrategy.swift (~300 lines)
  - RecoveryStrategy.swift (~200 lines)
  - AIFormatter.swift (~200 lines)
  - AIParser.swift (~200 lines)
  - CoachMetrics.swift (~100 lines)
- Adapted DI registrations (DIBootstrapper) for any new types.
- Minimal unit tests for AIParsers and Router (scaffold ok).

## Migration Steps
1) Identify and extract low-risk helpers: prompt formatting, structured parsing, token/cost accounting.
2) Introduce `CoachRouter` delegating to existing `ContextAnalyzer` to choose a strategy.
3) Extract `WorkoutStrategy`, `NutritionStrategy`, `RecoveryStrategy` with logic lifted from CoachEngine (1:1).
4) Create `CoachOrchestrator` that composes router + strategies + helpers; CoachEngine becomes a thin facade calling the orchestrator.
5) Replace NotificationCenter posting with `ChatStreamingStore` events (start/delta/finished).
6) Register new components in DIBootstrapper; keep existing factory paths working.

## Acceptance Criteria
- Builds green; ChatViewModel streams via ChatStreamingStore without regressions.
- No change in user-visible behavior (message creation, streaming, function results).
- CoachEngine.swift < 400 lines and acts as a shim.

## Notes
- Keep all SwiftData touchpoints on @MainActor; pass values across actor boundaries safely.
- Favor composition over inheritance; strategies can be structs if simpler.

---

Please implement the decomposition and open a PR with clear commit messages and file references.

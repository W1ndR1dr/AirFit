# Utopic Vision

Goal: A maintainable, testable, and performant AI-powered fitness app with clean boundaries, minimal global state, and reliable health data foundations.

Core tenets:
- Single source of truth: one SwiftData `ModelContainer` at app-level; `ModelContext` injected where needed; no ad-hoc containers.
- Cohesive components: engines decomposed into orchestrators, strategies, formatters/parsers, and stores. Each unit is small and testable.
- Typed streaming: AI/Chat flows expose typed async streams to ViewModels; no cross-module `NotificationCenter` coupling.
- Unified network layer: one actor owning request construction, retries, streaming, and error mapping; optimizer internal.
- Strict concurrency: remove `@unchecked Sendable` where possible; eliminate unsafe nonisolated snapshots by using atomic state or main-actor shims for read-mostly fields.
- Lint gates: staged introduction of file length/complexity caps (per-module budgets) to keep the system healthy.
- Tests that matter: unit tests for strategies/parsers/formatters; integration tests for persona synthesis and context assembly; thin UI tests for critical happy paths.

Desired architecture sketch:
- App
  - ModelContainer + DI bootstrap
- Core
  - Contracts (protocols), shared models/utilities, formatters, typed stores
- Services (domain)
  - AIService (actor), Network (actor), HealthKitManager (@MainActor), ContextAssembler (@MainActor with injected repos), Nutrition/Workouts (actors where safe)
- Modules (features)
  - ViewModels depend on contracts only; streaming/state via injected stores
  - Views are thin, composed, and focus on rendering

Operational excellence:
- Observability: structured logs for key flows (AI requests, Health aggregation), cost metrics, cache hit rates.
- Feature flags: guard experimental providers and models via toggles.
- Build hygiene: XcodeGen source groups reflect architecture; CI runs lint (strict) + targeted tests quickly.


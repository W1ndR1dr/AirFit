# Architecture Review

Summary: The project uses a layered approach (Application/Core/Data/Modules/Services) with a custom async DI container and SwiftData for persistence. Concurrency adopts Swift 6 annotations (`@MainActor`, actors, `nonisolated` snapshots). Feature modules are relatively self-contained but several very large files indicate cohesion/abstraction issues. Overall direction is solid, execution is uneven.

Strengths:
- DI: `DIContainer` + `DIBootstrapper` achieves lazy, type-safe resolution and clean separation of registration vs use.
- Concurrency: Widespread use of actors (`AIService`, HealthKit analyzers), `@MainActor` for SwiftData-touching services, and `nonisolated` accessors for UI-friendly reads.
- Error handling & telemetry: `AppLogger` with categories, signposts in AI requests, progress reporters in context assembly and persona synthesis.
- Clear feature boundaries under `Modules/` with domain services in `Services/` reused by multiple modules.

Concerns (impact-ranked):
1) Mega-files and mixed responsibilities:
   - `Modules/AI/CoachEngine.swift` (~2k lines) and other 700–2000 line files in Views/Engines reduce readability, testability, and reuse. Cohesion and SRP are frequently violated.
2) Force operations in app code:
   - `try!` and force-casts exist in non-preview code paths (e.g., `DIBootstrapper.swift: try … as!`, several views creating `ModelContainer` with `try!`). This is a runtime crash vector.
3) Ad-hoc `ModelContainer` creation in services and views:
   - Multiple call sites instantiate new containers or contexts (e.g., `ContextAssembler`, some dashboard views). This fragments persistence guarantees and breaks transaction boundaries/undo/consistency.
4) Inconsistent separation of concerns in “engines”: 
   - Chat/AI flows mix orchestration, UI-facing notifications, and provider logic; streaming deltas are bridged via notifications rather than dedicated reactive layer or state store.
5) SwiftLint is permissive on complexity/length:
   - Disabling length/complexity rules enabled the growth of mega-files and inconsistent abstractions.
6) Ambiguous duplication in networking:
   - `NetworkClient` vs `NetworkManager` vs `RequestOptimizer`—responsibilities overlap; high chance of drift and inconsistent error handling.
7) DI unchecked sendability and nonisolated snapshots:
   - `DIContainer` marked `@unchecked Sendable`; `AIService` exposes `nonisolated(unsafe)` snapshots. These must be carefully audited for data races.
8) Testing surface is thin:
   - Some focused unit tests exist (nutrition calc, strength progression, persona) but module-level integrations and UI are largely untested.

Layer-specific notes:
- Application: Good boot error surfaces for SwiftData container creation with retry/in-memory fallback. API setup flow recreates DI container correctly.
- Core: Protocols cover key boundaries (AI/Network/Nutrition/Health). Utilities (AppLogger, Haptics, AppState) are coherent.
- Data: SwiftData models reasonably sized; but creation/use patterns should centralize container ownership (App-level) and pass `ModelContext` via environment or DI.
- Modules: 
  - AI: Robust but dense; ContextAnalyzer, CoachEngine, function registry, persona layers, and streaming handlers would benefit from narrower components.
  - Chat: Notification-based streaming works but duplicates state mutation logic; better as a typed stream/state store injected into ViewModel.
  - Workouts/Nutrition/Body: Views are very large; split out subviews/formatters/selectors; ensure services own business logic.
- Services: HealthKitManager and ContextAssembler show forward-thinking (caching, progress, partial results). Consolidate network stack.

Recommendations (architecture):
- Split mega-files into cohesive components (Engines -> Orchestrator + Strategy + Parsers + Mappers).
- Enforce “single ModelContainer” ownership; pass `ModelContext` down via environment and DI only—no ad-hoc container creation in services/views.
- Replace notification fan-out for streaming with a lightweight typed stream/store protocol injected into ViewModel (Combine/AsyncSequence).
- Consolidate network layer under one actor (request building, retries, streaming); keep optimizer internal.
- Tighten SwiftLint rules for file/function/complexity length on non-UI files and set a target to reduce ‘exceeds’ over time.


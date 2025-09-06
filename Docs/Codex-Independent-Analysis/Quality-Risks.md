# Quality & Risks

This inventory captures actionable technical debt and quality risks prioritized by impact.

High impact:
- Force operations in app code:
  - `try!`/force-cast in `DIBootstrapper.swift`, `ExerciseDatabase.swift`, and several dashboard views. Replace with graceful error handling and preview-only force in `#if DEBUG` blocks when necessary.
- Ad-hoc `ModelContainer` construction:
  - Multiple sites create containers/contexts for reads (dashboards, `ContextAssembler`). Centralize container ownership (App) and pass `ModelContext` via environment/DI.
- Mega-files and SRP violations:
  - 700–2000 line files in AI engines and Views impede maintenance and introduce regression risk. Split into cohesive components with unit seams.
- Notification-driven streaming coupling:
  - Chat streaming updates coupled via `NotificationCenter`; migrate to injected `ChatStreamingStore` protocol.

Medium impact:
- Network layer overlap:
  - `NetworkClient`, `NetworkManager`, `RequestOptimizer`—consolidate responsibilities under a single actor with clear boundaries.
- SwiftLint permissive rules:
  - Length/complexity rules disabled; enable with gradual thresholds on non-UI code to encourage decomposition.
- `@unchecked Sendable` and `nonisolated(unsafe)` patterns:
  - Audit DI container and AI snapshots for race conditions; add targeted tests and reduce unsafe access.
- TODOs in provider code:
  - Structured output cache metrics and tool call handling remain TODO; concrete tracking would aid cost/perf insights.

Lower impact / hygiene:
- Mixed date/time and unit handling across modules—centralize formatters and unit helpers in Core.
- Duplicated parsing and formatting logic within mega-files—move to reusable helpers.
- Tests: add minimal fixtures for core flows (chat routing, nutrition calculations under varied profiles, workout sync with watch).

Quick hits (1–2 day wins):
- Replace `try!` and `as!` with safe alternatives; add non-fatal error surfaces.
- Ban direct `ModelContainer` creation outside App bootstrap and `ExerciseDatabase` (if justified); route through DI.
- Introduce `ChatStreamingStore` and refactor ChatViewModel to subscribe directly.
- Add SwiftLint warnings for `file_length`, `type_body_length` on Modules/AI and Services/* with high max thresholds to start.


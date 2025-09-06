# Roadmap (Pragmatic)

Phases are designed to be incremental, safe, and measurable. Each phase can ship independently.

Phase 0 — Baseline safety (1–2 days)
- Remove `try!`/`as!` in app code paths; add safe fallbacks.
- Ban ad-hoc `ModelContainer` creation via lint and code review policy; add TODOs to route through DI.
- Introduce `ChatStreamingStore` protocol and a basic implementation; wire ChatViewModel to it (keep Notification for compatibility short term).

Phase 1 — Composition & splitting (1–2 weeks)
- Split `CoachEngine` into orchestrator + strategies + formatters/parsers; maintain public API.
- Extract reusable provider encode/decode utilities; tighten error mapping.
- Split oversized Views into subviews; move logic to ViewModels/services.
- Enable SwiftLint warnings for file/function length in AI/Services; monitor counts in CI.

Phase 2 — Data and DI integrity (1 week)
- Ensure a single app-owned `ModelContainer`; refactor `ContextAssembler` and dashboards to use injected `ModelContext` or repositories.
- Add repository protocols for read paths to ease testing (e.g., `UserReadRepository`).

Phase 3 — Network consolidation (3–5 days)
- Merge `NetworkClient` and `NetworkManager` responsibilities into one actor; keep `RequestOptimizer` internal.
- Standardize request/response pipeline, streaming framing, and error taxonomy.

Phase 4 — Tests that pay back (1–2 weeks)
- Unit: AI parsers/formatters, routing, nutrition calc, strength progression.
- Integration: persona synthesis (golden fixtures), health context assembly (fake HealthKit), chat streaming pipeline.
- UI: a handful of happy-path flows (onboarding → dashboard, chat prompt → streamed response).

Phase 5 — Observability & polish (ongoing)
- Cost metrics per feature; cache hit rates; health checks surfaced in a diagnostics view.
- Tighten lint thresholds as file sizes drop; adopt pre-commit checks.

Risks & mitigations:
- Refactor churn: gate changes behind ‘internal’ protocols and maintain adapter layers temporarily.
- Concurrency hazards: prefer actors or main-actor isolation for shared state; avoid `nonisolated(unsafe)`.
- Build variance: verify `project.yml` excludes remain correct to prevent non-source assets from being compiled.


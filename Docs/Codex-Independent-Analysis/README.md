# AirFit — Independent Codebase Analysis (Codex)

Scope: A clean-room review of the AirFit repo to deeply understand structure, architecture, and risks; propose a utopic end-state and a pragmatic roadmap. This analysis intentionally excludes and does not rely on `Docs/Codebase-Status/**` to avoid bias, per request.

What’s included:
- Codebase Map: structure, counts, and entry points
- Architecture, Concurrency, and Data layers review
- Subsystem deep-dives (AI, HealthKit, Workouts, Chat)
- Quality and Risk inventory (technical debt, smells)
- Utopic Vision (target architecture) and Roadmap
- Build/Test/Lint snapshot and recommendations

How this was conducted:
- Systematic grep-based inventory and file sampling across all layers
- Tracing entry points from `AirFit/Application/AirFitApp.swift` to DI registration and primary flows
- Spot checks of large/complex files and all critical protocols/services
- No assumptions taken from `Docs/Codebase-Status/**`; only source of truth is code + configs

Reading order:
1) Codebase-Map.md
2) Architecture-Review.md
3) AI-Subsystem.md and HealthKit-Subsystem.md
4) Quality-Risks.md
5) Utopic-Vision.md
6) Roadmap.md
7) Build-Status.md

Notes:
- File paths in this analysis refer to the current repo state.
- Counts and examples are indicative, not exhaustive, but enough to guide refactor work.


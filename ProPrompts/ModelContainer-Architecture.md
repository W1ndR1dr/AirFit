# GPT‑5 Pro Mode Prompt — ModelContainer Architecture Unification

## Goal
Enforce a single app-owned SwiftData `ModelContainer` and eliminate ad-hoc container creation in services/views. Inject `ModelContext` or repositories where needed.

## Critical Context (include these files)
- AirFit/Application/AirFitApp.swift
- AirFit/Application/ContentView.swift
- AirFit/Core/DI/DIBootstrapper.swift
- AirFit/Core/DI/DIViewModelFactory.swift
- AirFit/Services/Context/ContextAssembler.swift
- AirFit/Modules/Dashboard/Views/TodayDashboardView.swift (preview only)
- AirFit/Modules/Dashboard/Views/NutritionDashboardView.swift (preview only)
- AirFit/Modules/Body/Views/BodyDashboardView.swift (preview only)
- AirFit/Services/ExerciseDatabase.swift (separate DB, keep isolated)

## Tasks
1) Replace ad‑hoc `ModelContainer(for:)` usages in `ContextAssembler` with injected `ModelContext` or a small read‑only repository.
2) Ensure DIViewModelFactory always retrieves `modelContainer.mainContext` and passes it to consumers.
3) Add a lint/CI guard to reject new `ModelContainer(` calls outside Application, TestSupport, and ExerciseDatabase.

## Acceptance Criteria
- No runtime `ModelContainer(` calls in app target except in Application bootstrap, TestSupport, and ExerciseDatabase (by design).
- ContextAssembler uses injected context or repositories.
- Builds/tests pass; no functional regressions.

---

Please implement and open a PR with the refactor, including a simple CI script or lint rule to guard against regressions.

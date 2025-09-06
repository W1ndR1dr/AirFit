# AirFit Ground Truth

## What Actually Works
- Photo Food Logging: Present and integrated — PhotoInputView uses CameraManager + Vision + AI function call to CoachEngine; flows to FoodConfirmationView. Evidence: `AirFit/Modules/FoodTracking/Views/PhotoInputView.swift:1` and `performAIFoodAnalysis` → `coachEngine.executeFunction`.
- Recovery Pipeline: RecoveryDetailView loads ContextAssembler + HealthKitManaging and runs RecoveryInference; some sections still reference temporary structs. Evidence: `AirFit/Modules/Dashboard/Views/RecoveryDetailView.swift:91` and TODO at `:632`.
- Watch App: 8 views exist; plan transfer and sync services implemented with WCSession delegates. Evidence: `AirFitWatchApp/Views/*`, `AirFit/Services/Watch/WorkoutPlanTransferService.swift:1`, `AirFit/Modules/Workouts/Services/WorkoutSyncService.swift:1`.
- AI Providers: OpenAI/Gemini providers support streaming and structured JSON; AIService orchestrates provider selection and cost tracking. Evidence: `AirFit/Services/AI/LLMProviders/*`, `AirFit/Services/AI/AIService.swift:1`.
- Persona Synthesis: Multi-phase, structured JSON with progress reporting; tested via canned JSON in tests. Evidence: `AirFit/Modules/AI/PersonaSynthesis/*.swift`, `AirFit/AirFitTests/PersonaSynthesizerTests.swift:1` (needs stub).

## What's Actually Broken
- DI Name Mismatch: `AIServiceProtocol` resolved with `name: "adaptive"` has no named registration; Chat VM creation fails silently (infinite spinner). Fix: remove the name or register it. Evidence: `AirFit/Core/DI/DIViewModelFactory.swift:105`.
- Test Fakes Missing: `HealthKitManagerFake`, `AIServiceStub` referenced in tests don’t exist; tests won’t compile. Fix: add fakes/stubs or refactor tests to use provided protocols.
- ModelContainer Fragmentation: Fresh containers created in `ContextAssembler` for reads (twice). Fix: inject `ModelContext`/repositories. Evidence: `AirFit/Services/Context/ContextAssembler.swift:127,162`.
- Force Paths: `try!` in `ExerciseDatabase` fallback; various `fatalError`/force unwraps in non-test code. Fix: replace with safe errors or DEBUG-only. Evidence: `AirFit/Services/ExerciseDatabase.swift:150`, plus searches.
- Chat Streaming Coupling: Uses NotificationCenter, fragile for ordering/testing. Fix: inject a typed `ChatStreamingStore`.
- Token Usage Estimation: OpenAI streaming uses rough length-based estimate; skews Monitoring total cost. Fix: use provider usage fields when available, or mark as estimated.

## What’s Hidden
- PhotoInputView: Functional pipeline appears hidden behind navigation; ensure it’s reachable from FoodTracking flows.
- Watch Feature: Code present but likely gated by availability; surface a unified watch status UI; add persistence for queued plans.
- API Setup Flow: Present but dead — `AppState.shouldShowAPISetup` hardcoded false while ContentView still branches to APISetupView.

## Architecture Reality
- Pattern: Layers + async DI + actors is strong; biggest risks are cohesion (mega-files), container ownership leaks, and silent failures.
- Recommendation: 
  - Week 1: Fix DI mismatch, remove dead API setup branch, add missing fakes, and eliminate critical try!/fatalError.
  - Week 2: Introduce `ChatStreamingStore`, standardize single ModelContainer via DI.
  - Week 3: Decompose CoachEngine (orchestrator/strategies/formatters/parsers) and consolidate network actor.

## Evidence Index
- DI mismatch: `AirFit/Core/DI/DIViewModelFactory.swift:105`
- Containers in ContextAssembler: `AirFit/Services/Context/ContextAssembler.swift:127`, `:162`
- Exercise DB try!: `AirFit/Services/ExerciseDatabase.swift:150`
- Recovery: `AirFit/Modules/Dashboard/Views/RecoveryDetailView.swift:91`, `:632`
- Photo flow: `AirFit/Modules/FoodTracking/Views/PhotoInputView.swift:1`
- Providers: `AirFit/Services/AI/LLMProviders/OpenAIProvider.swift:1`, `GeminiProvider.swift:1`


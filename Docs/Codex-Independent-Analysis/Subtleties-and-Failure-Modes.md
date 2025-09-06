# Subtleties & Failure Modes

This doc captures non-obvious issues that are easy to miss yet impactful.

- DI name mismatch stalls Chat
  - Where: `Core/DI/DIViewModelFactory.swift:105` resolves `AIServiceProtocol` with `name: "adaptive"` but no such named registration exists.
  - Symptom: `ChatViewWrapper` uses `try?` – on failure, the spinner persists forever, giving no error surface.
  - Fix: Register an "adaptive" AI service or drop the name; add a fallback UI state when ViewModel creation fails.

- API Setup flow is effectively dead code
  - Where: `AppState.shouldShowAPISetup` returns `false`, while `ContentView` still branches on it and includes DI container recreation on completion.
  - Symptom: Stale code paths; confusion during onboarding logic refactors; misleading expectations in tests.
  - Fix: Remove the APISetup branch or re-enable behind a feature flag; ensure `FeatureToggles.aiOptionalForOnboarding` is honored consistently.

- SwiftData container fragmentation
  - Where: `ContextAssembler` and some views construct fresh `ModelContainer`/`ModelContext` for reads.
  - Risk: Lost transaction boundaries, inconsistent view of data, performance regressions due to extra stores.
  - Fix: Inject `ModelContext` or repository objects from the single app container.

- Force paths that can crash in prod
  - Where: `ExerciseDatabase` fallback `try!`; various view previews without `#if DEBUG` guard.
  - Symptom: Rare but catastrophic crashes on initialization failures; difficult to diagnose in the field.
  - Fix: Replace with graceful errors or guard in DEBUG only; surface failure via `AppError` and UI.

- Streaming via NotificationCenter
  - Where: `CoachEngine` posts `.chatStream*` notifications, `ChatViewModel` subscribes.
  - Risk: Ordering issues, weak typing, hard-to-test flows, and potential reentrancy/observer leaks.
  - Fix: Introduce `ChatStreamingStore` with typed `AsyncThrowingStream` and inject into `ChatViewModel`.

- Test artifacts out of sync
  - Where: Tests reference `HealthKitManagerFake` that does not exist in repo.
  - Symptom: Unit tests won’t compile/run; gives a false sense of coverage from checked-in test files.
  - Fix: Add missing fakes or refactor tests to use simple stubs shipped in test target.

- WhisperKit model size & device constraints
  - Where: `VoiceInputManager.preferredModel = "large-v3-turbo"` with on-device download.
  - Risk: Large downloads, memory pressure on older devices, long initialization.
  - Fix: Add tiered model selection (small/base by device class and network); surface download progress and fallback.

- `@unchecked Sendable` and `nonisolated(unsafe)` exposure
  - Where: SwiftData models (`User`) and `AIService` snapshot fields.
  - Risk: Races if accessed across actors/threads without synchronization.
  - Fix: Prefer actor-isolated reads or main-actor shims; minimize unsafe nonisolated state.

- WatchConnectivity activation assumptions
  - Where: `WorkoutSyncService` and `WorkoutPlanTransferService` assume support and reachability in some branches.
  - Risk: Silent drops when watch not paired/active; confusing UX.
  - Fix: Centralize a "watch status" observable; gate UI affordances; queue retries with backoff.


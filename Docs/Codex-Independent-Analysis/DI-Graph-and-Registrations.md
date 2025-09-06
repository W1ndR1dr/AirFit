# DI Graph & Registrations Audit

This document enumerates key DI registrations, observed consumers, and mismatches.

Highlights:
- Container: `AirFit/Core/DI/DIContainer.swift:1` with lifetimes `.singleton|.transient|.scoped` and async factories.
- Bootstrap: `AirFit/Core/DI/DIBootstrapper.swift:1` groups registrations by Core/AI/Data/Domain/UI.

Key registrations (selected):
- Core
  - `ModelContainer` (singleton, instance): provided by `AirFitApp.swift:body`.
  - `APIKeyManagementProtocol` -> `APIKeyManager` (singleton).
  - `NetworkClientProtocol` -> `NetworkClient` (singleton).
  - `NetworkManagementProtocol` -> `NetworkManager` (singleton).
- AI
  - `AIServiceProtocol` -> `AIService` (singleton); mode derives from `AppConstants.Configuration.isUsingDemoMode`.
  - `DirectAIProcessor` (singleton) depends on `AIServiceProtocol`.
- Data (SwiftData-bound, @MainActor creations)
  - `UserServiceProtocol` -> `UserService` (singleton)
  - `GoalServiceProtocol` -> `GoalService` (singleton)
  - `AnalyticsServiceProtocol` -> `AnalyticsService` (singleton)
  - `NutritionServiceProtocol` -> `NutritionService` (transient)
  - `NutritionGoalService` (singleton) and protocol alias
  - `NutritionImportService` (singleton)
  - `WorkoutServiceProtocol` -> `WorkoutService` (transient)
  - `MuscleGroupVolumeServiceProtocol` -> `MuscleGroupVolumeService` (actor, singleton)
  - `StrengthProgressionServiceProtocol` -> `StrengthProgressionService` (actor, singleton)
  - `DashboardNutritionService` (transient) and protocol alias
- Domain
  - `WeatherServiceProtocol` -> `WeatherService` (actor, singleton)
  - `HealthKitManager` (singleton @MainActor) + alias `HealthKitManaging` (singleton)
  - `HealthKitAuthManager` (singleton)
  - `ContextAssembler` (transient)
  - `HealthKitService` (+ protocol alias)
  - `HealthKitPrefillProviding` -> `HealthKitProvider` (singleton)
  - `NutritionCalculatorProtocol` -> `NutritionCalculator` (actor, singleton)
  - `KeychainHelper`, `NetworkMonitor`, `RequestOptimizer`, `ExerciseDatabase` (singleton)
  - `WorkoutSyncService` (singleton)
  - `WorkoutPlanTransferProtocol` (iOS only) -> `WorkoutPlanTransferService` (singleton)
  - `MonitoringService`, `OnboardingCache` (singletons)
- UI
  - `GradientManager`, `HapticServiceProtocol` (singletons)
  - `OnboardingIntelligence` (transient)
  - `WhisperModelManager`, `VoiceInputManager`, `FoodVoiceAdapterProtocol`, `FoodTrackingCoordinator`, `NotificationManager`, `LiveActivityManager`, `RoutingConfiguration`, `PersonaSynthesizer`, `PersonaService`.

Consumers and mismatches:
- `DIViewModelFactory.swift:105` resolves `AIServiceProtocol` with `name: "adaptive"`. No registration exists with that name. Impact: ChatViewModel creation will throw `DIError.notRegistered` and the `ChatViewWrapper` will spin forever. Fix: remove the name or add a named registration.
- `ContextAssembler` registered `.transient`; it internally creates its own `ModelContainer` multiple times for read operations. Impact: inconsistent read views, unnecessary stores, potential schema drift under migration. Fix: inject `ModelContext`/Repositories.
- `ExerciseDatabase` owns a separate `ModelContainer` for `ExerciseDefinition`; acceptable as an isolated DB, but has a `try!` fallback path for catastrophic init — replace with fatal error in DEBUG and graceful AppError in PROD.
- `PersonaService`: depends on `PersonaSynthesizer` and `AIServiceProtocol` + `ModelContext`. It’s @MainActor; ensure heavy AI tasks are not performed on main.
- Multiple services are registered as singletons and @MainActor; ensure heavy IO (e.g., HealthKit aggregation) runs off main when possible.

DI hygiene recommendations:
- Add compile-time check (unit test) that attempts to resolve every registered protocol to catch name/key drift.
- Prefer protocol-typed dependencies in factory methods; keep concrete types out of call sites unless necessary.
- Introduce a `RepositoryModule` to supply read-only data accessors instead of ad-hoc SwiftData constructs from services.


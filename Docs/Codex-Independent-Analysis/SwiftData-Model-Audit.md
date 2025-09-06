# SwiftData Model Audit

Schema definition:
- `AirFit/Data/Migrations/SchemaV1.swift:1` lists all models and defines `AirFitMigrationPlan` with a single schema (no stages).

Model highlights:
- `User.swift:1` with cascaded relationships to onboarding, food entries, workouts, logs, messages, sessions, strength records. `@unchecked Sendable` is used.
- `ChatSession.swift:1` and `ChatMessage.swift:1` use `@Attribute(.externalStorage)` for `content` to avoid row bloat and have cascades/inverses properly set.
- Foods, Workouts, Exercises, Sets, StrengthRecord, Goals: conventional design; IDs mostly UUID/unique attributes.
- `ExerciseDatabase.swift:1` defines a separate `ExerciseDefinition` model with its own `ModelContainer` (isolated dictionary-like DB).

Identified issues:
- Multiple ad-hoc `ModelContainer` creations in services/views:
  - `Services/Context/ContextAssembler.swift:127` and `:162` create a fresh container for read ops; also used when computing trends. This bypasses the app’s primary context, and defeats caching/transactions.
  - Several previews and some dashboard views use `try! ModelContainer(for: User.self)` inline (e.g., `Modules/Dashboard/Views/TodayDashboardView.swift:628`, `Modules/Dashboard/Views/NutritionDashboardView.swift:939`). Acceptable in previews, but verify they are `#if DEBUG` or `#Preview`-only.
- Force ops:
  - `Data/Managers/DataManager.swift:141` and other places use `try!` for container creation. Replace with safe failure or `#if DEBUG` guard.
- Missing test fakes:
  - Tests reference `HealthKitManagerFake` which doesn’t exist in repo sources. Unit tests will not compile without it.

Recommendations:
- Enforce a single primary `ModelContainer` owned by `AirFitApp`, inject `ModelContext` where needed (via DI or Environment).
- Add a small Repository layer for common reads: `UserReadRepository`, `ChatHistoryRepository`, `WorkoutReadRepository` with `ModelContext` injected. This avoids container creation and makes testing trivial.
- Gate all container creation in views to Previews only. In app code, always use injected context.
- Add compile-time check that scans for `ModelContainer(` calls outside `Application/` and `Data/Managers/preview` helpers and fails CI.


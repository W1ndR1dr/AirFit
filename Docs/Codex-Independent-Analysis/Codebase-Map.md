# Codebase Map

Top-level layout (focused on app code):

- `AirFit/Application`: App entry, ContentView, main navigation.
- `AirFit/Core`: DI, protocols, models, utilities, views, theme.
- `AirFit/Data`: SwiftData models, migrations, extensions.
- `AirFit/Modules`: Feature areas (AI, Chat, Dashboard, FoodTracking, Notifications, Onboarding, Settings, Workouts, Body, Shared).
- `AirFit/Services`: Cross-cutting services (AI, Health, Goals, Context, Network, Security, Speech, Weather, Monitoring, Persona, Nutrition).
- `AirFitWatchApp`: watchOS subset with mirrored concepts.
- `project.yml`: XcodeGen configuration.
- `AirFit/.swiftlint.yml`: Lint configuration (strict concurrency; relaxed complexity/length rules).

Inventory snapshot (Swift files, excluding `Docs/Codebase-Status/**`):

- Total Swift files: ~315
- By area (approx):
  - `Modules`: ~130
  - `Core`: ~91
  - `Services`: ~39
  - `Data`: ~23
  - `Application`: ~4
  - `AirFitTests`: ~7

Notable large files (line counts):

- `Modules/Settings/Views/SettingsListView.swift`: ~2266
- `Modules/AI/CoachEngine.swift`: ~2112
- `Modules/Onboarding/OnboardingIntelligence.swift`: ~1319
- `Modules/Workouts/Views/*`: 700–1100 range
- `Services/Health/HealthKitManager.swift`: ~954
- `Services/Context/ContextAssembler.swift`: ~886
- `Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift`: ~791

Primary entry points & flows:

- `Application/AirFitApp.swift`: @main App, creates SwiftData `ModelContainer`, bootstraps DI lazily via `DIBootstrapper` (mock/demo/test/production modes). Handles error surfaces for model container creation with retry/in-memory fallback.
- `Application/ContentView.swift`: Resolves `AppState`, drives onboarding vs API setup vs dashboard, recreates DI container post-API-setup.
- `Application/MainTabView.swift`: Main TabView with Chat, Today, Nutrition, Workouts, Body; includes Floating AI Assistant and quick actions via `NavigationState`.

Dependency Injection:

- `Core/DI/DIContainer.swift`: Lightweight async DI with singleton/transient/scoped lifetimes; environment integration via `withDIContainer`.
- `Core/DI/DIBootstrapper.swift`: Registers core, AI, data, domain, and UI services; separates app vs test vs preview containers.

Data & Models (SwiftData):

- `Data/Models/*`: `@Model` types for User, Goals, Workouts, ChatSession, ChatMessage, FoodEntry, etc.
- `Services/ExerciseDatabase.swift`: Separate `ModelContainer` for exercise definitions (note: `try!` use in some paths).

Key services/protocols:

- `Core/Protocols/*`: Contracts for AI, Network, HealthKit, Nutrition, Workouts, etc.
- `Services/AI/AIService.swift`: Actor managing providers (OpenAI, Gemini, Anthropic) with streaming support and cost tracking.
- `Services/Health/HealthKitManager.swift`: @MainActor manager with async APIs, background delivery, observers, and aggregate fetches.
- `Services/Context/ContextAssembler.swift`: Aggregates health + app context with caching and progress reporting.

Chat & AI:

- `Modules/Chat/*`: ViewModel, Views; notification-driven streaming updates.
- `Modules/AI/*`: CoachEngine, ContextAnalyzer, ConversationManager, function registries, persona synthesis.


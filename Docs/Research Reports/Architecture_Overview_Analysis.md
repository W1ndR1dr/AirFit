# AirFit Architecture Overview Analysis

## 1. Project Structure Analysis

The repository is organized with a layered approach. At the top level the `AirFit` directory contains all runtime code for the iOS app. Major folders within this directory:

- **Application** – entry point `AirFitApp.swift` and root views for app initialization.
- **Core** – common enums, models, protocols, utilities and theme used by all modules.
- **Data** – SwiftData models, migrations and persistence helpers.
- **Services** – standalone services such as AI providers, networking, security and speech processing.
- **Modules** – feature‑specific modules (Onboarding, Dashboard, FoodTracking, Chat, Workouts, Notifications, Settings and AI).
- **AirFitTests** / **AirFitUITests** – unit and UI test suites.
- **AirFitWatchApp** – the watchOS companion app.

The project uses **MVVM‑C** (Model‑View‑ViewModel‑Coordinator). Each module contains `Views`, `ViewModels`, `Models`, `Services` and `Coordinators` subdirectories, allowing navigation logic to remain independent from presentation.

```
AirFit/
├── Application/
├── Core/
├── Data/
├── Services/
└── Modules/
    ├── Onboarding/
    ├── Dashboard/
    ├── FoodTracking/
    ├── Chat/
    ├── Workouts/
    ├── Notifications/
    ├── Settings/
    └── AI/
```

Modules depend on `Core`, `Services` and `Data` for shared functionality. Coordinators manage navigation between module views.

## 2. Layer Architecture

### Core Layer
- **Protocols** – service interfaces (`AIServiceProtocol`, `UserServiceProtocol`, etc.)
- **DI** – `DependencyContainer` and `ServiceRegistry` provide simple dependency injection.
- **Extensions** – small helpers on `Date`, `Color`, `URLRequest`, etc.
- **Models** – fundamental structs such as `AIModels` and `HealthContextSnapshot`.
- **Theme** – `AppColors`, `AppFonts`, `AppShadows` and `AppSpacing` define the design system.
- **Utilities** – `AppLogger`, `NetworkReachability`, `Validators`, `Formatters` and more.

### Data Layer
- SwiftData models like `User`, `FoodEntry`, `Workout`, `ChatSession` located in `Data/Models`.
- `DataManager` and migration schemas coordinate the SwiftData `ModelContainer`.
- Extensions under `Data/Extensions` provide fetch descriptors and testing helpers.

### Service Layer
- Services encapsulate business logic or platform APIs: `NetworkManager`, `AIAPIService`, `HealthKitManager`, `WeatherService`, `AIResponseCache`, etc.
- Services are grouped by concern inside subfolders (`AI`, `Network`, `Security`, `Analytics`, `Speech`).
- Protocols live in `Core/Protocols` and concrete implementations in `Services`.

### Module Layer
- Features organized per module under `Modules/`.
- Each module follows MVVM‑C with directories: `Views`, `ViewModels`, `Models`, `Services`, `Coordinators`.
- Modules interact with the Data and Service layers via protocols so that business logic remains testable.

### Application Layer
- `AirFitApp.swift` sets up the SwiftData model container and root view.
- The root `ContentView` launches either onboarding or dashboard based on `AppState`.
- Application‑wide state is managed through `AppState` observable object.

## 3. Key Architectural Decisions

1. **SwiftUI‑First UI** – All views are built with SwiftUI. UIKit is not present.
2. **SwiftData for Persistence** – Chosen over Core Data to leverage modern Swift concurrency and type‑safe models.
3. **Dependency Injection** – A lightweight `DependencyContainer` registers services. ViewModels obtain dependencies through this container, promoting testability.
4. **Navigation** – Coordinators encapsulate routing between views, ensuring separation between ViewModels and navigation logic.
5. **Error Handling** – Shared `AppError` enum and `ErrorPresentationView` provide user‑friendly messages. Services use `Result` and `throws` for propagation, logging errors through `AppLogger`.

## 4. Module Dependencies

- Modules rely on **Core** for models, utilities and protocols.
- Feature modules consume **Services** for AI calls, networking, HealthKit, etc.
- The **Data** layer is accessed through models and the `DataManager`.
- There are no circular dependencies—the flow is strictly downward: Application → Modules → Services/Data → Core.

```
Application
   │
   ▼
Modules ──► Services
   │         │
   │         └──► Core
   └──► Data ───► Core
```

This layered approach keeps modules decoupled and adheres to clean‑architecture ideals.


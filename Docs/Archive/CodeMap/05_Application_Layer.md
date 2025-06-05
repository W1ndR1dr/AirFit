# 05_Application_Layer.md

The Application layer (`/AirFit/Application`) is the entry point and top-level orchestrator for the AirFit iOS app.

## Key Files and Their Purpose:

*   **`/AirFit/Application/AirFitApp.swift`**:
    *   The main entry point of the application, conforming to the SwiftUI `App` protocol.
    *   Initializes the SwiftData `ModelContainer` (`sharedModelContainer`) and makes it available to the application, typically via the `.modelContainer()` view modifier.
    *   Sets up the main `WindowGroup` and presents the initial view (`ContentView` or `MinimalContentView`).
*   **`/AirFit/Application/ContentView.swift`**:
    *   The main view that determines the application's root UI based on the `AppState`.
    *   Likely injects the `ModelContext` and an `AppState` object into its view hierarchy.
    *   Handles transitions between loading, welcome, onboarding, and main dashboard/tab views.
    *   May include sub-views like `LoadingView`, `WelcomeView`, and `ErrorView` for different states.
*   **`/AirFit/Application/MinimalContentView.swift`**:
    *   Appears to be an alternative or simplified `ContentView`, possibly for testing, specific build configurations, or an earlier development stage.
    *   Might bypass complex state management for a more direct presentation of onboarding or a main view.

## Key Responsibilities:

*   **App Initialization**: Setting up essential services and the data stack (SwiftData).
*   **Dependency Injection Setup**: Initializing the DIContainer via DIBootstrapper and making it available to the app.
*   **Root View Management**: Determining and displaying the correct initial UI based on application state (e.g., whether the user is new, has completed onboarding, etc.).
*   **App State Coordination**: Working closely with `AppState` (from Core/Utilities) to manage and react to global state changes.
*   **Environment Setup**: Injecting necessary environment objects like `ModelContext`, `DIContainer`, and `DIViewModelFactory` into the SwiftUI view hierarchy.

## Key Dependencies:

*   **Consumed:**
    *   Core Layer (especially `AppState`, `AppLogger`, `ModelContainer`, `DIContainer`, `DIBootstrapper`, `DIViewModelFactory`).
    *   Data Layer (for initializing and providing the `ModelContainer`).
    *   Modules Layer (specifically, it will present the entry points of modules like `OnboardingFlowView` or a main tabbed view containing `DashboardView`, etc.).
    *   SwiftUI (System Framework).
*   **Provided:**
    *   The running application environment for all other layers.
    *   DIContainer instance configured for production use.
    *   DIViewModelFactory for creating ViewModels throughout the app.

## Tests:

*   Application layer testing often involves UI tests (`AirFitUITests`) that launch the app and verify initial states or flows.
*   Unit tests for `AppState` (if complex enough) would be in `/AirFit/AirFitTests/Core/` or a dedicated state management test file.
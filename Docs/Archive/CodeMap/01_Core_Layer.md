# 01_Core_Layer.md

The Core layer (`/AirFit/Core`) provides foundational elements shared across the entire AirFit application.

## Key Subdirectories and Their Purpose:

*   **`/AirFit/Core/Constants`**:
    *   `APIConstants.swift`: Defines constants related to API interactions (endpoints, headers).
    *   `AppConstants.swift`, `AppConstants+Settings.swift`: Application-wide constants for layout, animation, storage keys, validation rules, and settings-related values.
*   **`/AirFit/Core/Enums`**:
    *   `AppError.swift`: Defines common application error types.
    *   `GlobalEnums.swift`: Contains widely used enums like `BiologicalSex`, `ActivityLevel`, `AppTab`, `ExerciseCategory`, etc.
    *   `MessageType.swift`: Differentiates between `conversation` and `command` message types for AI.
*   **`/AirFit/Core/Extensions`**:
    *   Utility extensions for standard types like `Color`, `Date`, `Double`, `String`, `TimeInterval`, `URLRequest`, and `View`.
    *   `AIProvider+Extensions.swift`: Adds properties and utility methods to the `AIProvider` enum.
*   **`/AirFit/Core/Models`**:
    *   `AI/AIModels.swift`: Core models for AI interactions (`AIMessageRole`, `AIChatMessage`, `AIFunctionCall`, `AIRequest`, `AIResponse`, `AIProvider`).
    *   `HealthContextSnapshot.swift`: A comprehensive model capturing a snapshot of the user's health and app context at a point in time.
    *   `NutritionPreferences.swift`: Model for user's dietary preferences.
    *   `ServiceTypes.swift`: Common types used by services, like `ServiceError`, `WeatherData`.
    *   `WorkoutBuilderData.swift`: Data structure for building workouts, possibly for transfer between app and watch.
*   **`/AirFit/Core/Protocols`**:
    *   Defines interfaces for various services (`AIServiceProtocol`, `AnalyticsServiceProtocol`, `HealthKitManagerProtocol`, `NetworkClientProtocol`, `UserServiceProtocol`, etc.) promoting loose coupling and testability.
    *   `LLMProvider.swift`: Defines the interface for different Large Language Model providers.
*   **`/AirFit/Core/Theme`**:
    *   `AppColors.swift`, `AppFonts.swift`, `AppShadows.swift`, `AppSpacing.swift`: Defines the visual styling and theme of the application.
*   **`/AirFit/Core/Utilities`**:
    *   `AppLogger.swift`: Centralized logging utility.
    *   `AppState.swift`: Manages global application state (current user, onboarding status).
    *   `DIContainer.swift`: Modern dependency injection container with async resolution and lifetime management.
    *   `DIBootstrapper.swift`: Configures DI containers for production, test, and preview environments.
    *   `DIViewModelFactory.swift`: Factory for creating ViewModels with proper dependency injection.
    *   `DependencyContainer.swift`: Legacy dependency injection mechanism (being replaced by DIContainer).
    *   `Formatters.swift`: Utility for formatting data like calories, weight.
    *   `HapticManager.swift`: Manages haptic feedback.
    *   `HealthKitAuthManager.swift`: Handles HealthKit authorization status.
    *   `KeychainWrapper.swift`: Utility for secure storage in the keychain.
    *   `NetworkReachability.swift`: Monitors network connectivity.
    *   `PersonaMigrationUtility.swift`: Utility for migrating older persona/profile data structures.
    *   `Validators.swift`: Provides input validation functions.
*   **`/AirFit/Core/Views`**:
    *   `CommonComponents.swift`: Reusable SwiftUI views like `SectionHeader`, `EmptyStateView`, `Card`.
    *   `ErrorPresentationView.swift`: A view for displaying errors in various styles.

## Key Components & Responsibilities:

*   **`AIModels.swift` & `LLMProvider.swift`**: Define the fundamental structures and interfaces for interacting with AI services.
*   **`HealthContextSnapshot.swift`**: Crucial for providing context to AI and other services.
*   **Service Protocols (e.g., `AIServiceProtocol`, `UserServiceProtocol`)**: Enable dependency inversion and easier mocking for tests.
*   **Dependency Injection System**:
    *   `DIContainer`: Central service registry with async resolution, lifetime management (singleton/transient)
    *   `DIBootstrapper`: Configures containers for different environments (production, test, preview)
    *   `DIViewModelFactory`: Creates ViewModels with all dependencies properly injected
*   **`AppLogger`**: Standardizes logging throughout the app (kept as singleton for global access).
*   **`AppState`**: Manages the overall state of the application, determining what view the user sees (welcome, onboarding, dashboard).
*   **`KeychainWrapper`**: Secures sensitive data like API keys (kept as singleton for system resource).
*   **`NetworkReachability`**: Provides global network status information.
*   **Theme files (`AppColors`, `AppFonts`, etc.)**: Ensure a consistent UI.
*   **Common UI Components (`CommonComponents.swift`, `ErrorPresentationView.swift`)**: Promote UI reusability.

## Key Dependencies:

*   **Consumed:**
    *   System Frameworks (SwiftUI, Foundation, Combine, HealthKit, etc.)
*   **Provided:**
    *   Base models, protocols, utilities, and UI elements for all other layers (Application, Modules, Services, Data).

## Tests:

The Core layer components are tested in `/AirFit/AirFitTests/Core/`. Tests cover:
*   `AppConstantsTests.swift`
*   `CoreSetupTests.swift` (likely testing theme and common component initialization)
*   `ExtensionsTests.swift`
*   `FormattersTests.swift`
*   `KeychainWrapperTests.swift`
*   `ValidatorsTests.swift`
*   `VoiceInputManagerTests.swift` (Note: `VoiceInputManager` itself is in `/AirFit/Services/Speech/`, but its tests are here, perhaps due to its foundational nature or historical reasons. Its protocol might be in Core).
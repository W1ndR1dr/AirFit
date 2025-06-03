# 06_Testing_Strategy.md

This document outlines the testing structure and strategies employed in the AirFit project.

## Main Test Targets:

1.  **`/AirFit/AirFitTests` (Unit, Integration, Performance Tests)**:
    *   **Purpose**: Contains tests for individual components (unit tests), interactions between components (integration tests), and performance benchmarks.
    *   **Structure**: Tests are generally organized by mirroring the main app's module/layer structure.
        *   `AI/`: Tests for the AI module.
        *   `Context/`: Tests for context-related logic (e.g., `ContextAssemblerTests.swift`).
        *   `Core/`: Tests for foundational components in the Core layer.
        *   `Data/`: Tests for data models and persistence.
        *   `FoodTracking/`: Tests for the FoodTracking module.
        *   `Health/`: Tests for HealthKit-related components (though `HealthKitManagerTests.swift` might be a general test).
        *   `Integration/`: Contains tests focusing on the integration of multiple components or full flows (e.g., `NutritionParsingIntegrationTests.swift`, `OnboardingFlowTests.swift`, `PersonaSystemIntegrationTests.swift`).
        *   `Modules/`: Contains subfolders for module-specific tests (`AI`, `Chat`, `Dashboard`, `Notifications`, `Onboarding`, `Settings`, `Workouts`).
        *   `Performance/`: Performance-critical tests (e.g., `DirectAIPerformanceTests.swift`, `NutritionParsingPerformanceTests.swift`).
        *   `Services/`: Tests for the Services layer.
    *   **Mocks (`/AirFit/AirFitTests/Mocks`)**:
        *   A dedicated directory for mock objects used in testing. This is crucial for isolating components under test.
        *   **Base Mock**: `Base/MockProtocol.swift` (not present in map, but a common pattern).
        *   **Key Mocks**:
            *   `MockAIAPIService.swift`, `MockAIService.swift`, `MockLLMOrchestrator.swift`: For mocking AI interactions.
            *   `MockAIFunctionServices.swift`: For mocking specific AI function call results.
            *   `MockAnalyticsService.swift`
            *   `MockDashboardServices.swift`
            *   `MockFoodVoiceAdapter.swift`
            *   `MockHealthKitManager.swift`, `MockHealthKitPrefillProvider.swift`
            *   `MockNotificationManager.swift`
            *   `MockOnboardingService.swift`
            *   `MockUserService.swift`
            *   `MockVoiceInputManager.swift`, `MockWhisperServiceWrapper.swift`
            *   `MockNetworkManager.swift` (from `/AirFit/Services/MockServices/`)
            *   `MockAPIKeyManager.swift` (from `/AirFit/Services/MockServices/`)
    *   **Test Plans**: `AirFit.xctestplan` likely defines configurations for running tests.

2.  **`/AirFit/AirFitUITests` (UI Tests)**:
    *   **Purpose**: Automates user interface interactions to verify the app's behavior from a user's perspective.
    *   **Structure**:
        *   Tests are grouped by feature/flow (e.g., `DashboardUITests.swift`, `FoodTrackingFlowUITests.swift`, `OnboardingFlowUITests.swift`).
        *   **Page Object Model (POM)**:
            *   `PageObjects/OnboardingFlowPage.swift` (Higher-level abstraction for a flow).
            *   `Pages/BasePage.swift`: Base class with common UI interaction helpers.
            *   `Pages/OnboardingPage.swift`: Represents the Onboarding screen with its elements and actions.
        *   `AirFitUITests.swift`: General UI tests or launch tests.
        *   `AirFitUITestsLaunchTests.swift`: Specifically for testing app launch.

## Testing Dependencies:

*   `AirFitTests` target depends on the `AirFit` application target to access its code.
*   `AirFitUITests` target launches and interacts with a compiled instance of the `AirFit` application.

## Key Testing Approaches:

*   **Unit Testing**: Focused on individual classes and methods, heavily utilizing mock objects to isolate dependencies.
*   **Integration Testing**: Verifying the interaction between several components, such as a ViewModel with its Services, or a flow involving multiple classes. (e.g., `OnboardingFlowTests`, `NutritionParsingIntegrationTests`).
*   **Performance Testing**: Measuring the speed and resource usage of critical operations using `measure` blocks or custom timing.
*   **UI Testing**: Using `XCTest`'s UI testing framework to simulate user interactions and validate UI states, often employing the Page Object Model for maintainability.
*   **Mocking**: Extensive use of mock objects (see Mocks section above) is evident, which is good practice for creating reliable and fast tests.
*   **SwiftData Testing**: `ModelContainer+Testing.swift` suggests utilities for setting up in-memory `ModelContainer`s for tests, allowing data-dependent components to be tested without persistent side effects.
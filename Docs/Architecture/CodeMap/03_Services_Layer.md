# 03_Services_Layer.md

The Services layer (`/AirFit/Services`) encapsulates shared business logic, interactions with external systems (like AI APIs, HealthKit), and other cross-cutting concerns.

## Key Subdirectories and Their Purpose:

*   **`/AirFit/Services/AI`**:
    *   **`LLMProviders`**: Contains concrete implementations for different Large Language Model providers (`AnthropicProvider.swift`, `GeminiProvider.swift`, `OpenAIProvider.swift`).
        *   `LLMModels.swift`: Defines shared models like `LLMModel` (enum of specific models) and `AITask`.
    *   `AIAPIService.swift`: An older/simpler service for AI API interactions.
    *   `AIRequestBuilder.swift`: Builds requests for AI APIs.
    *   `AIResponseCache.swift`: Caches AI responses to improve performance and reduce costs.
    *   `AIResponseParser.swift`: Parses responses from AI APIs, especially streaming data.
    *   `EnhancedAIAPIService.swift`: A more advanced service for AI API interactions, possibly handling multiple providers and more complex logic.
    *   `LLMOrchestrator.swift`: Orchestrates calls to LLM providers, possibly handling model selection, task-specific prompting.
    *   `ProductionAIService.swift`, `MockAIService.swift`, `SimpleMockAIService.swift`: Concrete implementations and mocks for the `AIServiceProtocol`.
    *   `UnifiedAIService.swift`: Aims to provide a unified interface over multiple AI providers, potentially handling fallbacks and caching.
*   **`/AirFit/Services/Cache`**:
    *   `OnboardingCache.swift`: Specific caching mechanism for the onboarding process.
*   **`/AirFit/Services/Context`**:
    *   `ContextAssembler.swift`: Gathers data from various sources (HealthKit, app data) to create a `HealthContextSnapshot`.
*   **`/AirFit/Services/Health`**:
    *   `HealthKitDataFetcher.swift`: Fetches specific data types from HealthKit.
    *   `HealthKitDataTypes.swift`: Defines data types relevant to HealthKit.
    *   `HealthKitExtensions.swift`: Utility extensions for HealthKit data.
    *   `HealthKitManager.swift`: Core manager for HealthKit interactions, authorization, and fetching aggregated metrics.
    *   `HealthKitSleepAnalyzer.swift`: Specific logic for analyzing sleep data from HealthKit.
*   **`/AirFit/Services/MockServices`**:
    *   Contains mock implementations of various services for testing (`MockAIAPIService.swift`, `MockAPIKeyManager.swift`, `MockNetworkManager.swift`, `MockWeatherService.swift`). These are used by test targets.
*   **`/AirFit/Services/Monitoring`**:
    *   `ProductionMonitor.swift`: Tracks production metrics, performance, and errors for monitoring purposes.
*   **`/AirFit/Services/Network`**:
    *   `NetworkClient.swift`: A client for making network requests (seems simpler, perhaps for specific use cases).
    *   `NetworkManager.swift`: A more comprehensive network manager, possibly handling reachability and common request patterns.
    *   `RequestOptimizer.swift`: Optimizes network requests, potentially handling batching, retries, or duplicate request prevention.
*   **`/AirFit/Services/Security`**:
    *   `DefaultAPIKeyManager.swift`: Manages API keys, likely storing and retrieving them from the `KeychainWrapper`.
    *   `KeychainHelper.swift`: A more generic helper for Keychain interactions (may be an alternative or complement to `KeychainWrapper` from Core).
*   **`/AirFit/Services/Speech`**:
    *   `VoiceInputManager.swift`: Manages voice input, recording, and transcription using Whisper.
    *   `WhisperModelManager.swift`: Manages downloading and selecting Whisper speech-to-text models.
*   **`/AirFit/Services/User`**:
    *   `DefaultUserService.swift`: Implements `UserServiceProtocol` for user creation, profile updates, and fetching current user data.
*   **Root of `/AirFit/Services`**:
    *   `ExerciseDatabase.swift`: Manages a local database of exercise definitions, likely loaded from a JSON file.
    *   `ServiceConfiguration.swift`: Defines configurations for various services (AI, Weather, Network).
    *   `ServiceRegistry.swift`: A central registry for accessing shared service instances.
    *   `WeatherService.swift`: Fetches weather data from an external API.
    *   `WorkoutSyncService.swift`: Syncs workout data, possibly with Apple Watch or a cloud backend (uses WCSession, CKContainer).

## Key Responsibilities:

*   **AI Interaction**: Connecting to LLMs, sending prompts, parsing responses, managing API keys (`UnifiedAIService`, `LLMOrchestrator`, provider-specific classes).
*   **Health Data Management**: Interacting with HealthKit for reading and writing health data (`HealthKitManager`, `ContextAssembler`).
*   **User Management**: Creating, updating, and retrieving user information (`DefaultUserService`).
*   **Network Operations**: Making HTTP requests, handling responses, and managing network state (`NetworkManager`, `NetworkClient`).
*   **Secure Storage**: Managing API keys and other sensitive data (`DefaultAPIKeyManager`).
*   **Speech-to-Text**: Handling voice input and transcription (`VoiceInputManager`, `WhisperModelManager`).
*   **Context Aggregation**: Assembling comprehensive context snapshots for AI and other logic (`ContextAssembler`).
*   **External Data**: Fetching data like weather (`WeatherService`) and managing local data like exercises (`ExerciseDatabase`).
*   **Service Orchestration**: Providing a central point for service configuration and access (`ServiceConfiguration`, `ServiceRegistry`).

## Key Dependencies:

*   **Consumed:**
    *   Core Layer (for protocols, models, utilities like `KeychainWrapper`, `AppLogger`).
    *   Data Layer (for fetching/saving user data, e.g., `DefaultUserService` uses `ModelContext`).
    *   System Frameworks (Foundation, Combine, HealthKit, AVFoundation, WatchConnectivity, CloudKit).
*   **Provided:**
    *   Abstracted functionalities (e.g., AI coaching, health data access, user profile management) to the Modules Layer and Application Layer.

## Tests:

Services are tested in `/AirFit/AirFitTests/Services/` and module-specific tests often use mocks of these services.
*   `GeminiProviderTests.swift`
*   `MockServicesTests.swift` (Tests for the mock implementations themselves)
*   `NetworkManagerTests.swift`
*   `ServiceIntegrationTests.swift`
*   `ServicePerformanceTests.swift`
*   `ServiceProtocolsTests.swift`
*   `WeatherDataGenerators.swift` (Likely `TestDataGenerators.swift` in map)
*   `WeatherServiceTests.swift`
*   `WorkoutSyncServiceTests.swift`
*   `ContextAssemblerTests.swift` (in `/AirFit/AirFitTests/Context/`)
*   `KeychainWrapperTests.swift` (in `/AirFit/AirFitTests/Core/`, but `DefaultAPIKeyManager` uses it)
*   `VoiceInputManagerTests.swift` (in `/AirFit/AirFitTests/Core/`)

Individual AI Provider tests and other service-specific tests might also be present.
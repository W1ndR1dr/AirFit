# 04_Modules_Layer_Overview.md

The Modules layer (`/AirFit/Modules`) organizes the application into distinct feature areas. Each module typically encapsulates its own UI (Views, ViewModels, Coordinators) and domain-specific logic or models.

## General Module Structure:

Most modules under `/AirFit/Modules` follow a similar pattern:

*   **`Coordinators`**: Handle navigation logic within the module.
*   **`Models`**: Define data structures specific to the module's domain.
*   **`Services`**: Module-specific services or adapters for shared services.
*   **`ViewModels`**: Manage state and logic for the module's views.
*   **`Views`**: SwiftUI views that constitute the module's UI.

## Individual Modules:

### 1. AI (`/AirFit/Modules/AI`)
*   **Purpose**: Core AI coaching logic, persona management, function calling, and command parsing.
*   **Key Components**:
    *   `CoachEngine.swift`: Central engine for AI interactions, routing messages, and managing conversation flow.
    *   `PersonaEngine.swift`: Builds and manages the AI coach's persona.
    *   `ConversationManager.swift`: Manages storage and retrieval of conversation history (persisted via `CoachMessage` SwiftData model).
    *   `FunctionCallDispatcher.swift`, `FunctionRegistry.swift`: Handle AI function calling capabilities.
    *   `LocalCommandParser.swift`: Parses simple user commands locally.
    *   `ContextAnalyzer.swift`: Determines routing strategies for AI requests.
    *   `PersonaSynthesis/`: Contains logic for generating AI personas (`PersonaSynthesizer`, `OptimizedPersonaSynthesizer`).
    *   Models: `PersonaModels.swift`, `NutritionParseResult.swift`, `DirectAIModels.swift`.
*   **Dependencies**: Services (AIAPIs, ContextAssembler), Data (CoachMessage, User), Core.
*   **Tests**: `/AirFit/AirFitTests/Modules/AI/`

### 2. Chat (`/AirFit/Modules/Chat`)
*   **Purpose**: Provides the user interface for conversing with the AI coach.
*   **Key Components**:
    *   `ChatCoordinator.swift`
    *   `ChatViewModel.swift`
    *   `ChatView.swift`, `MessageBubbleView.swift`, `MessageComposer.swift`
    *   Services: `ChatExporter.swift`, `ChatHistoryManager.swift`, `ChatSuggestionsEngine.swift`
    *   Models: `ChatModels.swift`
*   **Dependencies**: AI Module (CoachEngine), Data (ChatMessage, ChatSession), Core, Services (VoiceInputManager).
*   **Tests**: `/AirFit/AirFitTests/Modules/Chat/`

### 3. Dashboard (`/AirFit/Modules/Dashboard`)
*   **Purpose**: Displays an overview of the user's health, nutrition, and activity. Serves as the main landing screen.
*   **Key Components**:
    *   `DashboardCoordinator.swift`
    *   `DashboardViewModel.swift`
    *   `DashboardView.swift`
    *   Views/Cards: `MorningGreetingCard.swift`, `NutritionCard.swift`, `PerformanceCard.swift`, etc.
    *   Services: `DefaultAICoachService.swift`, `DefaultDashboardNutritionService.swift`, `DefaultHealthKitService.swift` (adapters for shared services).
    *   Models: `DashboardModels.swift`
*   **Dependencies**: Services (HealthKit, AI, Nutrition), Data (User, DailyLog, FoodEntry), Core.
*   **Tests**: `/AirFit/AirFitTests/Modules/Dashboard/`

### 4. FoodTracking (`/AirFit/Modules/FoodTracking`)
*   **Purpose**: Allows users to log food intake via voice, photo, or manual search.
*   **Key Components**:
    *   `FoodTrackingCoordinator.swift`
    *   `FoodTrackingViewModel.swift`
    *   Views: `FoodLoggingView.swift`, `FoodVoiceInputView.swift`, `PhotoInputView.swift`, `NutritionSearchView.swift`, `FoodConfirmationView.swift`.
    *   Services: `FoodVoiceAdapter.swift` (for `VoiceInputManager`), `NutritionService.swift` (module-specific or adapter).
    *   Models: `FoodTrackingModels.swift` (e.g., `ParsedFoodItem`).
*   **Dependencies**: AI Module (CoachEngine for parsing), Data (FoodEntry, FoodItem, User), Core, Services (VoiceInputManager).
*   **Tests**: `/AirFit/AirFitTests/FoodTracking/`

### 5. Notifications (`/AirFit/Modules/Notifications`)
*   **Purpose**: Manages local and potentially remote notifications, engagement tracking, and live activities.
*   **Key Components**:
    *   `NotificationsCoordinator.swift`
    *   Managers: `LiveActivityManager.swift`, `NotificationManager.swift` (wrapper around UserNotifications).
    *   Services: `EngagementEngine.swift`, `NotificationContentGenerator.swift`.
    *   Models: `NotificationModels.swift`.
*   **Dependencies**: AI Module (CoachEngine for content generation), Data (User), Core, System (UserNotifications).
*   **Tests**: `/AirFit/AirFitTests/Modules/Notifications/`

### 6. Onboarding (`/AirFit/Modules/Onboarding`)
*   **Purpose**: Guides new users through the initial setup process, including persona generation.
*   **Key Components**:
    *   Coordinators: `OnboardingFlowCoordinator.swift`, `ConversationCoordinator.swift`.
    *   `OnboardingViewModel.swift`, `ConversationViewModel.swift`.
    *   Views: `OnboardingFlowView.swift`, `ConversationView.swift`, `PersonaSynthesisView.swift`, and various input modality views.
    *   Services: `OnboardingOrchestrator.swift`, `ConversationFlowManager.swift`, `PersonaService.swift`, `ResponseAnalyzer.swift`.
    *   Models: `OnboardingModels.swift`, `PersonalityInsights.swift`, `ConversationTypes.swift`.
*   **Dependencies**: AI Module (PersonaSynthesizer, LLMOrchestrator), Data (User, OnboardingProfile, ConversationSession), Core, Services (HealthKit for prefill).
*   **Tests**: `/AirFit/AirFitTests/Modules/Onboarding/`

### 7. Settings (`/AirFit/Modules/Settings`)
*   **Purpose**: Allows users to configure application settings, manage API keys, view privacy information, and export data.
*   **Key Components**:
    *   `SettingsCoordinator.swift`
    *   `SettingsViewModel.swift`
    *   Views: `SettingsListView.swift`, `AIPersonaSettingsView.swift`, `APIConfigurationView.swift`, `DataManagementView.swift`.
    *   Services: `BiometricAuthManager.swift`, `UserDataExporter.swift`.
    *   Models: `SettingsModels.swift`, `PersonaSettingsModels.swift`.
*   **Dependencies**: Data (User, OnboardingProfile for persona), Core, Services (APIKeyManager, NotificationManager).
*   **Tests**: `/AirFit/AirFitTests/Modules/Settings/`

### 8. Workouts (`/AirFit/Modules/Workouts`)
*   **Purpose**: Manages workout planning, logging, viewing history, and statistics.
*   **Key Components**:
    *   `WorkoutCoordinator.swift`
    *   `WorkoutViewModel.swift`
    *   Views: `WorkoutListView.swift`, `WorkoutDetailView.swift`, `ExerciseLibraryView.swift`, `WorkoutBuilderView.swift`.
    *   Models: `WorkoutModels.swift` (e.g., `WeeklyWorkoutStats`).
*   **Dependencies**: AI Module (CoachEngine for analysis), Data (Workout, Exercise, ExerciseSet, WorkoutTemplate), Core, Services (HealthKitManager, ExerciseDatabase).
*   **Tests**: `/AirFit/AirFitTests/Workouts/`

---
Each module listed above could have its own detailed Markdown file (e.g., `04a_Module_AI.md`) if a deeper dive is needed for a specific module, following the structure provided here. For now, this overview summarizes their key aspects.
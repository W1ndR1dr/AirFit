<file_map>
/Users/Brian/Coding Projects/AirFit
├── .claude
│   └── settings.local.json
├── .github
│   └── workflows
│       └── test.yml
├── .screenshots
│   ├── app_final_fixed.png
│   ├── app_with_proper_di.png
│   └── black_screen_issue.png
├── AirFit
│   ├── AirFitTests
│   │   ├── Core
│   │   │   ├── DI
│   │   │   │   ├── DIBootstrapperTests.swift
│   │   │   │   └── DIContainerTests.swift
│   │   │   ├── AppConstantsTests.swift
│   │   │   ├── CoreSetupTests.swift
│   │   │   ├── ExtensionsTests.swift
│   │   │   ├── FormattersTests.swift
│   │   │   ├── KeychainWrapperTests.swift
│   │   │   └── ValidatorsTests.swift
│   │   ├── Data
│   │   │   └── UserModelTests.swift
│   │   ├── Integration
│   │   │   ├── OnboardingErrorRecoveryTests.swift
│   │   │   ├── OnboardingFlowTests.swift
│   │   │   └── PersonaGenerationTests.swift
│   │   ├── Mocks
│   │   │   ├── Base
│   │   │   │   └── MockProtocol.swift
│   │   │   ├── MockAIAnalyticsService.swift
│   │   │   ├── MockAIAPIService.swift
│   │   │   ├── MockAICoachService.swift
│   │   │   ├── MockAIGoalService.swift
│   │   │   ├── MockAIPerformanceAnalytics.swift
│   │   │   ├── MockAIService.swift
│   │   │   ├── MockAIWorkoutService.swift
│   │   │   ├── MockAnalyticsService.swift
│   │   │   ├── MockAPIKeyManager.swift
│   │   │   ├── MockAVAudioRecorder.swift
│   │   │   ├── MockAVAudioSession.swift
│   │   │   ├── MockCoachEngine.swift
│   │   │   ├── MockConversationAnalytics.swift
│   │   │   ├── MockConversationFlowManager.swift
│   │   │   ├── MockConversationPersistence.swift
│   │   │   ├── MockDashboardNutritionService.swift
│   │   │   ├── MockFoodTrackingCoordinator.swift
│   │   │   ├── MockFoodVoiceAdapter.swift
│   │   │   ├── MockFoodVoiceService.swift
│   │   │   ├── MockGoalService.swift
│   │   │   ├── MockHealthKitManager.swift
│   │   │   ├── MockHealthKitPrefillProvider.swift
│   │   │   ├── MockHealthKitService.swift
│   │   │   ├── MockLLMOrchestrator.swift
│   │   │   ├── MockLLMProvider.swift
│   │   │   ├── MockNetworkClient.swift
│   │   │   ├── MockNetworkManager.swift
│   │   │   ├── MockNotificationManager.swift
│   │   │   ├── MockNutritionService.swift
│   │   │   ├── MockOnboardingService.swift
│   │   │   ├── MockPersonaService.swift
│   │   │   ├── MockService.swift
│   │   │   ├── MockUserService.swift
│   │   │   ├── MockViewModel.swift
│   │   │   ├── MockVoiceInputManager.swift
│   │   │   ├── MockWeatherService.swift
│   │   │   ├── MockWhisperKit.swift
│   │   │   ├── MockWhisperModelManager.swift
│   │   │   ├── MockWhisperServiceWrapper.swift
│   │   │   ├── MockWorkoutService.swift
│   │   │   ├── TestableVoiceInputManager.swift
│   │   │   └── VoicePerformanceMetrics.swift
│   │   ├── Modules
│   │   │   ├── AI
│   │   │   │   ├── CoachEngineTests.swift
│   │   │   │   ├── ContextAnalyzerTests.swift
│   │   │   │   ├── ConversationManagerPerformanceTests.swift
│   │   │   │   ├── ConversationManagerPersistenceTests.swift
│   │   │   │   ├── ConversationManagerTests.swift
│   │   │   │   ├── FunctionCallDispatcherTests.swift
│   │   │   │   ├── LocalCommandParserTests.swift
│   │   │   │   └── MessageClassificationTests.swift
│   │   │   ├── Chat
│   │   │   │   ├── ChatCoordinatorTests.swift
│   │   │   │   ├── ChatSuggestionsEngineTests.swift
│   │   │   │   └── ChatViewModelTests.swift
│   │   │   ├── Dashboard
│   │   │   │   ├── Services
│   │   │   │   │   ├── AICoachServiceTests.swift
│   │   │   │   │   ├── DashboardNutritionServiceTests.swift
│   │   │   │   │   └── HealthKitServiceTests.swift
│   │   │   │   └── DashboardViewModelTests.swift
│   │   │   ├── FoodTracking
│   │   │   │   ├── Services
│   │   │   │   │   └── NutritionServiceTests.swift
│   │   │   │   ├── AINutritionParsingIntegrationTests.swift
│   │   │   │   ├── AINutritionParsingTests.swift
│   │   │   │   ├── FoodTrackingCoordinatorTests.swift
│   │   │   │   ├── FoodTrackingViewModelAIIntegrationTests.swift
│   │   │   │   ├── FoodTrackingViewModelTests.swift
│   │   │   │   └── FoodVoiceAdapterTests.swift
│   │   │   ├── Notifications
│   │   │   │   ├── EngagementEngineTests.swift
│   │   │   │   └── NotificationManagerTests.swift.disabled
│   │   │   ├── Onboarding
│   │   │   │   ├── ConversationViewModelTests.swift
│   │   │   │   ├── OnboardingFlowViewTests.swift
│   │   │   │   ├── OnboardingIntegrationTests.swift
│   │   │   │   ├── OnboardingModelsTests.swift
│   │   │   │   ├── OnboardingServiceTests.swift
│   │   │   │   ├── OnboardingViewModelTests.swift
│   │   │   │   └── PersonaServiceTests.swift.disabled
│   │   │   ├── Settings
│   │   │   │   ├── BiometricAuthManagerTests.swift
│   │   │   │   ├── SettingsModelsTests.swift
│   │   │   │   └── SettingsViewModelTests.swift
│   │   │   └── Workouts
│   │   │       ├── WorkoutCoordinatorTests.swift
│   │   │       └── WorkoutViewModelTests.swift
│   │   ├── Performance
│   │   │   ├── DirectAIPerformanceTests.swift
│   │   │   └── OnboardingPerformanceTests.swift
│   │   ├── Services
│   │   │   ├── AI
│   │   │   │   ├── AIAnalyticsServiceTests.swift
│   │   │   │   ├── AIGoalServiceTests.swift
│   │   │   │   ├── AIServiceTests.swift
│   │   │   │   ├── AIWorkoutServiceTests.swift
│   │   │   │   └── LLMOrchestratorTests.swift
│   │   │   ├── Analytics
│   │   │   │   └── AnalyticsServiceTests.swift
│   │   │   ├── Context
│   │   │   │   └── ContextAssemblerTests.swift
│   │   │   ├── Health
│   │   │   │   └── HealthKitManagerTests.swift
│   │   │   ├── Network
│   │   │   │   └── NetworkClientTests.swift.disabled
│   │   │   ├── Security
│   │   │   │   └── APIKeyManagerTests.swift
│   │   │   ├── Speech
│   │   │   │   └── VoiceInputManagerTests.swift
│   │   │   ├── User
│   │   │   │   └── UserServiceTests.swift
│   │   │   ├── GeminiProviderTests.swift
│   │   │   ├── MockServicesTests.swift
│   │   │   ├── NetworkManagerTests.swift.disabled
│   │   │   ├── TestHelpers.swift
│   │   │   ├── WeatherServiceTests.swift
│   │   │   └── WorkoutSyncServiceTests.swift
│   │   ├── TestUtils
│   │   │   └── DITestHelper.swift
│   │   ├── SmokeTest.swift
│   │   └── TEST_STRUCTURE.md
│   ├── AirFitUITests
│   │   ├── Dashboard
│   │   │   └── DashboardUITests.swift
│   │   ├── FoodTracking
│   │   │   └── FoodTrackingFlowUITests.swift
│   │   ├── Onboarding
│   │   │   └── OnboardingFlowUITests.swift
│   │   ├── PageObjects
│   │   │   └── OnboardingFlowPage.swift
│   │   ├── Pages
│   │   │   ├── BasePage.swift
│   │   │   └── OnboardingPage.swift
│   │   ├── AirFitUITests.swift
│   │   └── AirFitUITestsLaunchTests.swift
│   ├── Application
│   │   ├── AirFitApp.swift
│   │   └── ContentView.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AccentSecondary.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   └── Contents.json
│   │   ├── BackgroundPrimary.colorset
│   │   │   └── Contents.json
│   │   ├── BackgroundSecondary.colorset
│   │   │   └── Contents.json
│   │   ├── BackgroundTertiary.colorset
│   │   │   └── Contents.json
│   │   ├── ButtonBackground.colorset
│   │   │   └── Contents.json
│   │   ├── ButtonText.colorset
│   │   │   └── Contents.json
│   │   ├── CaloriesColor.colorset
│   │   │   └── Contents.json
│   │   ├── CarbsColor.colorset
│   │   │   └── Contents.json
│   │   ├── CardBackground.colorset
│   │   │   └── Contents.json
│   │   ├── DividerColor.colorset
│   │   │   └── Contents.json
│   │   ├── ErrorColor.colorset
│   │   │   └── Contents.json
│   │   ├── FatColor.colorset
│   │   │   └── Contents.json
│   │   ├── InfoColor.colorset
│   │   │   └── Contents.json
│   │   ├── ProteinColor.colorset
│   │   │   └── Contents.json
│   │   ├── SuccessColor.colorset
│   │   │   └── Contents.json
│   │   ├── TextOnAccent.colorset
│   │   │   └── Contents.json
│   │   ├── TextPrimary.colorset
│   │   │   └── Contents.json
│   │   ├── TextSecondary.colorset
│   │   │   └── Contents.json
│   │   ├── TextTertiary.colorset
│   │   │   └── Contents.json
│   │   ├── WarningColor.colorset
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── Core
│   │   ├── Constants
│   │   │   ├── APIConstants.swift
│   │   │   ├── AppConstants.swift
│   │   │   └── AppConstants+Settings.swift
│   │   ├── DI
│   │   │   ├── DIBootstrapper.swift
│   │   │   ├── DIBootstrapper+Test.swift
│   │   │   ├── DIContainer.swift
│   │   │   ├── DIEnvironment.swift
│   │   │   ├── DIExample.swift
│   │   │   └── DIViewModelFactory.swift
│   │   ├── Enums
│   │   │   ├── AppError.swift
│   │   │   ├── AppError+Conversion.swift
│   │   │   ├── GlobalEnums.swift
│   │   │   └── MessageType.swift
│   │   ├── Extensions
│   │   │   ├── AIProvider+API.swift
│   │   │   ├── Color+Fallbacks.swift
│   │   │   ├── Color+Hex.swift
│   │   │   ├── Date+Helpers.swift
│   │   │   ├── Double+Formatting.swift
│   │   │   ├── String+Helpers.swift
│   │   │   ├── TimeInterval+Formatting.swift
│   │   │   ├── URLRequest+API.swift
│   │   │   └── View+Styling.swift
│   │   ├── Models
│   │   │   ├── AI
│   │   │   │   └── AIModels.swift
│   │   │   ├── HealthContextSnapshot.swift
│   │   │   ├── NutritionPreferences.swift
│   │   │   ├── ServiceModels.swift
│   │   │   ├── VoiceInputState.swift
│   │   │   └── WorkoutBuilderData.swift
│   │   ├── Protocols
│   │   │   ├── AIServiceProtocol.swift
│   │   │   ├── AIServiceProtocol+Extensions.swift
│   │   │   ├── AnalyticsServiceProtocol.swift
│   │   │   ├── APIKeyManagementProtocol.swift
│   │   │   ├── DashboardServiceProtocols.swift
│   │   │   ├── ErrorHandling.swift
│   │   │   ├── FoodTrackingCoordinatorProtocol.swift
│   │   │   ├── FoodVoiceAdapterProtocol.swift
│   │   │   ├── FoodVoiceServiceProtocol.swift
│   │   │   ├── GoalServiceProtocol.swift
│   │   │   ├── HealthKitManagerProtocol.swift
│   │   │   ├── LLMProvider.swift
│   │   │   ├── NetworkClientProtocol.swift
│   │   │   ├── NetworkManagementProtocol.swift
│   │   │   ├── NutritionServiceProtocol.swift
│   │   │   ├── OnboardingServiceProtocol.swift
│   │   │   ├── ServiceProtocol.swift
│   │   │   ├── UserServiceProtocol.swift
│   │   │   ├── ViewModelProtocol.swift
│   │   │   ├── VoiceInputProtocol.swift
│   │   │   ├── WeatherServiceProtocol.swift
│   │   │   ├── WhisperServiceWrapperProtocol.swift
│   │   │   └── WorkoutServiceProtocol.swift
│   │   ├── Theme
│   │   │   ├── AppColors.swift
│   │   │   ├── AppFonts.swift
│   │   │   ├── AppShadows.swift
│   │   │   └── AppSpacing.swift
│   │   ├── Utilities
│   │   │   ├── AppInitializer.swift
│   │   │   ├── AppLogger.swift
│   │   │   ├── AppState.swift
│   │   │   ├── DependencyContainer.swift
│   │   │   ├── Formatters.swift
│   │   │   ├── HapticManager.swift
│   │   │   ├── HealthKitAuthManager.swift
│   │   │   ├── KeychainWrapper.swift
│   │   │   ├── NetworkReachability.swift
│   │   │   ├── PersonaMigrationUtility.swift
│   │   │   └── Validators.swift
│   │   └── Views
│   │       ├── CommonComponents.swift
│   │       └── ErrorPresentationView.swift
│   ├── Data
│   │   ├── Extensions
│   │   │   ├── FetchDescriptor+Convenience.swift
│   │   │   └── ModelContainer+Test.swift
│   │   ├── Managers
│   │   │   └── DataManager.swift
│   │   ├── Migrations
│   │   │   └── SchemaV1.swift
│   │   └── Models
│   │       ├── ChatAttachment.swift
│   │       ├── ChatMessage.swift
│   │       ├── ChatSession.swift
│   │       ├── CoachMessage.swift
│   │       ├── ConversationResponse.swift
│   │       ├── ConversationSession.swift
│   │       ├── DailyLog.swift
│   │       ├── Exercise.swift
│   │       ├── ExerciseSet.swift
│   │       ├── ExerciseTemplate.swift
│   │       ├── FoodEntry.swift
│   │       ├── FoodItem.swift
│   │       ├── FoodItemTemplate.swift
│   │       ├── Goal.swift
│   │       ├── HealthKitSyncRecord.swift
│   │       ├── MealTemplate.swift
│   │       ├── NutritionData.swift
│   │       ├── OnboardingProfile.swift
│   │       ├── SetTemplate.swift
│   │       ├── User.swift
│   │       ├── Workout.swift
│   │       └── WorkoutTemplate.swift
│   ├── Modules
│   │   ├── AI
│   │   │   ├── Components
│   │   │   │   ├── ConversationStateManager.swift
│   │   │   │   ├── DirectAIProcessor.swift
│   │   │   │   ├── MessageProcessor.swift
│   │   │   │   └── StreamingResponseHandler.swift
│   │   │   ├── Configuration
│   │   │   │   └── RoutingConfiguration.swift
│   │   │   ├── Functions
│   │   │   │   ├── AnalysisFunctions.swift
│   │   │   │   ├── FunctionCallDispatcher.swift
│   │   │   │   ├── FunctionRegistry.swift
│   │   │   │   ├── GoalFunctions.swift
│   │   │   │   ├── NutritionFunctions.swift
│   │   │   │   └── WorkoutFunctions.swift
│   │   │   ├── Models
│   │   │   │   ├── ConversationPersonalityInsights.swift
│   │   │   │   ├── DirectAIModels.swift
│   │   │   │   ├── NutritionParseResult.swift
│   │   │   │   ├── PersonaMode.swift
│   │   │   │   └── PersonaModels.swift
│   │   │   ├── Parsing
│   │   │   │   └── LocalCommandParser.swift
│   │   │   ├── PersonaSynthesis
│   │   │   │   ├── FallbackPersonaGenerator.swift
│   │   │   │   ├── OptimizedPersonaSynthesizer.swift
│   │   │   │   ├── PersonaSynthesizer.swift
│   │   │   │   └── PreviewGenerator.swift
│   │   │   ├── CoachEngine.swift
│   │   │   ├── ContextAnalyzer.swift
│   │   │   ├── ConversationManager.swift
│   │   │   ├── PersonaEngine.swift
│   │   │   └── WorkoutAnalysisEngine.swift
│   │   ├── Chat
│   │   │   ├── Coordinators
│   │   │   │   └── ChatCoordinator.swift
│   │   │   ├── Models
│   │   │   │   └── ChatModels.swift
│   │   │   ├── Services
│   │   │   │   ├── ChatExporter.swift
│   │   │   │   ├── ChatHistoryManager.swift
│   │   │   │   └── ChatSuggestionsEngine.swift
│   │   │   ├── ViewModels
│   │   │   │   └── ChatViewModel.swift
│   │   │   └── Views
│   │   │       ├── ChatView.swift
│   │   │       ├── MessageBubbleView.swift
│   │   │       ├── MessageComposer.swift
│   │   │       └── VoiceSettingsView.swift
│   │   ├── Dashboard
│   │   │   ├── Coordinators
│   │   │   │   └── DashboardCoordinator.swift
│   │   │   ├── Models
│   │   │   │   └── DashboardModels.swift
│   │   │   ├── Services
│   │   │   │   ├── AICoachService.swift
│   │   │   │   ├── DashboardNutritionService.swift
│   │   │   │   └── HealthKitService.swift
│   │   │   ├── ViewModels
│   │   │   │   └── DashboardViewModel.swift
│   │   │   └── Views
│   │   │       ├── Cards
│   │   │       │   ├── MorningGreetingCard.swift
│   │   │       │   ├── NutritionCard.swift
│   │   │       │   ├── PerformanceCard.swift
│   │   │       │   ├── QuickActionsCard.swift
│   │   │       │   └── RecoveryCard.swift
│   │   │       └── DashboardView.swift
│   │   ├── FoodTracking
│   │   │   ├── Coordinators
│   │   │   │   └── FoodTrackingCoordinator.swift
│   │   │   ├── Models
│   │   │   │   └── FoodTrackingModels.swift
│   │   │   ├── Services
│   │   │   │   ├── FoodVoiceAdapter.swift
│   │   │   │   ├── NutritionService.swift
│   │   │   │   └── PreviewServices.swift
│   │   │   ├── ViewModels
│   │   │   │   └── FoodTrackingViewModel.swift
│   │   │   └── Views
│   │   │       ├── FoodConfirmationView.swift
│   │   │       ├── FoodLoggingView.swift
│   │   │       ├── FoodVoiceInputView.swift
│   │   │       ├── MacroRingsView.swift
│   │   │       ├── NutritionSearchView.swift
│   │   │       ├── PhotoInputView.swift
│   │   │       ├── VoiceInputDownloadView.swift
│   │   │       └── WaterTrackingView.swift
│   │   ├── Notifications
│   │   │   ├── Coordinators
│   │   │   │   └── NotificationsCoordinator.swift
│   │   │   ├── Managers
│   │   │   │   ├── LiveActivityManager.swift
│   │   │   │   └── NotificationManager.swift
│   │   │   ├── Models
│   │   │   │   └── NotificationModels.swift
│   │   │   └── Services
│   │   │       ├── EngagementEngine.swift
│   │   │       └── NotificationContentGenerator.swift
│   │   ├── Onboarding
│   │   │   ├── Coordinators
│   │   │   │   ├── ConversationCoordinator.swift
│   │   │   │   ├── OnboardingCoordinator.swift
│   │   │   │   └── OnboardingFlowCoordinator.swift
│   │   │   ├── Data
│   │   │   │   └── ConversationFlowData.swift
│   │   │   ├── Models
│   │   │   │   ├── ConversationModels.swift
│   │   │   │   ├── OnboardingModels.swift
│   │   │   │   └── PersonalityInsights.swift
│   │   │   ├── Services
│   │   │   │   ├── ConversationAnalytics.swift
│   │   │   │   ├── ConversationFlowManager.swift
│   │   │   │   ├── ConversationPersistence.swift
│   │   │   │   ├── OnboardingOrchestrator.swift
│   │   │   │   ├── OnboardingProgressManager.swift
│   │   │   │   ├── OnboardingRecovery.swift
│   │   │   │   ├── OnboardingService.swift
│   │   │   │   ├── OnboardingState.swift
│   │   │   │   ├── PersonaService.swift
│   │   │   │   └── ResponseAnalyzer.swift
│   │   │   ├── ViewModels
│   │   │   │   ├── ConversationViewModel.swift
│   │   │   │   └── OnboardingViewModel.swift
│   │   │   └── Views
│   │   │       ├── InputModalities
│   │   │       │   ├── ChoiceCardsView.swift
│   │   │       │   ├── ContextualSlider.swift
│   │   │       │   ├── TextInputView.swift
│   │   │       │   ├── VoiceInputView.swift
│   │   │       │   └── VoiceVisualizer.swift
│   │   │       ├── CoachingStyleView.swift
│   │   │       ├── CoachProfileReadyView.swift
│   │   │       ├── ConversationalInputView.swift
│   │   │       ├── ConversationProgress.swift
│   │   │       ├── ConversationView.swift
│   │   │       ├── CoreAspirationView.swift
│   │   │       ├── EngagementPreferencesView.swift
│   │   │       ├── FinalOnboardingFlow.swift
│   │   │       ├── GeneratingCoachView.swift
│   │   │       ├── HealthKitAuthorizationView.swift
│   │   │       ├── LifeSnapshotView.swift
│   │   │       ├── MotivationalAccentsView.swift
│   │   │       ├── OnboardingContainerView.swift
│   │   │       ├── OnboardingErrorBoundary.swift
│   │   │       ├── OnboardingFlowView.swift
│   │   │       ├── OnboardingFlowViewDI.swift
│   │   │       ├── OnboardingNavigationButtons.swift
│   │   │       ├── OnboardingStateView.swift
│   │   │       ├── OpeningScreenView.swift
│   │   │       ├── OptimizedGeneratingPersonaView.swift
│   │   │       ├── PersonaPreviewCard.swift
│   │   │       ├── PersonaPreviewView.swift
│   │   │       ├── PersonaSelectionView.swift
│   │   │       ├── PersonaSynthesisView.swift
│   │   │       └── SleepAndBoundariesView.swift
│   │   ├── Settings
│   │   │   ├── Coordinators
│   │   │   │   └── SettingsCoordinator.swift
│   │   │   ├── Models
│   │   │   │   ├── AIProvider+Settings.swift
│   │   │   │   ├── PersonaSettingsModels.swift
│   │   │   │   ├── SettingsModels.swift
│   │   │   │   └── User+Settings.swift
│   │   │   ├── Services
│   │   │   │   ├── BiometricAuthManager.swift
│   │   │   │   ├── NotificationManager+Settings.swift
│   │   │   │   └── UserDataExporter.swift
│   │   │   ├── ViewModels
│   │   │   │   └── SettingsViewModel.swift
│   │   │   └── Views
│   │   │       ├── Components
│   │   │       │   └── SettingsComponents.swift
│   │   │       ├── AIPersonaSettingsView.swift
│   │   │       ├── APIConfigurationView.swift
│   │   │       ├── APIKeyEntryView.swift
│   │   │       ├── AppearanceSettingsView.swift
│   │   │       ├── DataManagementView.swift
│   │   │       ├── InitialAPISetupView.swift
│   │   │       ├── NotificationPreferencesView.swift
│   │   │       ├── PrivacySecurityView.swift
│   │   │       ├── SettingsListView.swift
│   │   │       └── UnitsSettingsView.swift
│   │   └── Workouts
│   │       ├── Coordinators
│   │       │   └── WorkoutCoordinator.swift
│   │       ├── Models
│   │       │   └── WorkoutModels.swift
│   │       ├── Services
│   │       │   └── WorkoutService.swift
│   │       ├── ViewModels
│   │       │   └── WorkoutViewModel.swift
│   │       └── Views
│   │           ├── AllWorkoutsView.swift
│   │           ├── ExerciseLibraryComponents.swift
│   │           ├── ExerciseLibraryView.swift
│   │           ├── TemplatePickerView.swift
│   │           ├── WorkoutBuilderView.swift
│   │           ├── WorkoutDetailView.swift
│   │           ├── WorkoutListView.swift
│   │           └── WorkoutStatisticsView.swift
│   ├── Resources
│   │   ├── SeedData
│   │   │   └── exercises.json
│   │   └── Localizable.strings
│   ├── Scripts
│   │   ├── fix_targets.sh
│   │   └── verify_module_tests.sh
│   ├── Services
│   │   ├── AI
│   │   │   ├── LLMProviders
│   │   │   │   ├── AnthropicProvider.swift
│   │   │   │   ├── GeminiProvider.swift
│   │   │   │   ├── LLMModels.swift
│   │   │   │   └── OpenAIProvider.swift
│   │   │   ├── AIAnalyticsService.swift
│   │   │   ├── AIGoalService.swift
│   │   │   ├── AIRequestBuilder.swift
│   │   │   ├── AIResponseCache.swift
│   │   │   ├── AIResponseParser.swift
│   │   │   ├── AIService.swift
│   │   │   ├── AIWorkoutService.swift
│   │   │   ├── DemoAIService.swift
│   │   │   ├── LLMOrchestrator.swift
│   │   │   ├── OfflineAIService.swift
│   │   │   └── TestModeAIService.swift
│   │   ├── Analytics
│   │   │   └── AnalyticsService.swift
│   │   ├── Cache
│   │   │   └── OnboardingCache.swift
│   │   ├── Context
│   │   │   └── ContextAssembler.swift
│   │   ├── Goals
│   │   │   └── GoalService.swift
│   │   ├── Health
│   │   │   ├── HealthKit+Types.swift
│   │   │   ├── HealthKitDataFetcher.swift
│   │   │   ├── HealthKitDataTypes.swift
│   │   │   ├── HealthKitManager.swift
│   │   │   └── HealthKitSleepAnalyzer.swift
│   │   ├── Monitoring
│   │   │   └── MonitoringService.swift
│   │   ├── Network
│   │   │   ├── NetworkClient.swift
│   │   │   ├── NetworkManager.swift
│   │   │   └── RequestOptimizer.swift
│   │   ├── Security
│   │   │   ├── APIKeyManager.swift
│   │   │   └── KeychainHelper.swift
│   │   ├── Speech
│   │   │   ├── VoiceInputManager.swift
│   │   │   └── WhisperModelManager.swift
│   │   ├── User
│   │   │   └── UserService.swift
│   │   ├── Weather
│   │   │   └── WeatherService.swift
│   │   ├── ExerciseDatabase.swift
│   │   ├── ServiceConfiguration.swift
│   │   ├── ServiceRegistry.swift
│   │   └── WorkoutSyncService.swift
│   ├── .gitignore
│   ├── .swiftlint.yml
│   ├── AirFit.entitlements
│   └── Info.plist
├── AirFit.xcodeproj
│   └── project.pbxproj
├── AirFitWatchApp
│   ├── AirFitWatchAppTests
│   │   └── Services
│   │       └── WatchWorkoutManagerTests.swift
│   ├── Services
│   │   └── WatchWorkoutManager.swift
│   ├── Views
│   │   ├── ActiveWorkoutView.swift
│   │   ├── ExerciseLoggingView.swift
│   │   └── WorkoutStartView.swift
│   └── AirFitWatchApp.swift
├── Docs
│   ├── Archive
│   │   ├── IGNORE THIS FOLDER
│   ├── Research Reports
│   │   └── Deep Research Archive
│   │       └─ IGNORE THIS FOLDER
│   ├── AGENT_PROMPTS_WAVE1.md
│   ├── AGENT_PROMPTS_WAVE2.md
│   ├── AGENT_PROMPTS_WAVE3.md
│   ├── ARCHITECTURE_ANALYSIS_2025.md
│   ├── CODEX_EXECUTION_GUIDE.md
│   ├── COMPREHENSIVE_CODEBASE_ANALYSIS_PLAN.md
│   ├── CURRENT_ANALYSIS_README.md
│   └── Filetree 6-8-25-10am.md
├── .cursorrules
├── .gitignore
├── AGENTS.md
├── AirFit.xctestplan
├── app_logs.txt
├── build.log
├── CLAUDE.md
├── envsetupscript.sh
├── Manual.md
├── package.json
└── project.yml

</file_map>


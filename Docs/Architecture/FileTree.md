<file_map>
/Users/Brian/Coding Projects/AirFit
├── .claude
│   └── settings.local.json
├── .github
│   └── workflows
│       └── test.yml
├── AirFit
│   ├── AirFitTests
│   │   ├── AI
│   │   │   └── ContextAnalyzerTests.swift
│   │   ├── Context
│   │   │   └── ContextAssemblerTests.swift
│   │   ├── Core
│   │   │   ├── AppConstantsTests.swift
│   │   │   ├── CoreSetupTests.swift
│   │   │   ├── ExtensionsTests.swift
│   │   │   ├── FormattersTests.swift
│   │   │   ├── KeychainWrapperTests.swift
│   │   │   ├── ValidatorsTests.swift
│   │   │   └── VoiceInputManagerTests.swift
│   │   ├── Data
│   │   │   └── UserModelTests.swift
│   │   ├── FoodTracking
│   │   │   ├── AINutritionParsingIntegrationTests.swift
│   │   │   ├── AINutritionParsingTests.swift
│   │   │   ├── FoodTrackingViewModelAIIntegrationTests.swift
│   │   │   ├── FoodTrackingViewModelTests.swift
│   │   │   ├── FoodVoiceAdapterTests.swift
│   │   │   ├── NutritionParsingExtensiveTests.swift
│   │   │   └── NutritionParsingFinalIntegrationTests.swift
│   │   ├── Health
│   │   │   └── HealthKitManagerTests.swift
│   │   ├── Integration
│   │   │   ├── NutritionParsingIntegrationTests.swift
│   │   │   ├── OnboardingErrorRecoveryTests.swift
│   │   │   ├── OnboardingFlowTests.swift
│   │   │   ├── PersonaGenerationTests.swift
│   │   │   └── PersonaSystemIntegrationTests.swift
│   │   ├── Mocks
│   │   │   ├── Base
│   │   │   │   └── MockProtocol.swift
│   │   │   ├── MockAIAnalyticsService.swift
│   │   │   ├── MockAIAPIService.swift
│   │   │   ├── MockAICoachService.swift
│   │   │   ├── MockAIGoalService.swift
│   │   │   ├── MockAIService.swift
│   │   │   ├── MockAIWorkoutService.swift
│   │   │   ├── MockAnalyticsService.swift
│   │   │   ├── MockAPIKeyManager.swift
│   │   │   ├── MockAVAudioRecorder.swift
│   │   │   ├── MockAVAudioSession.swift
│   │   │   ├── MockDashboardNutritionService.swift
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
│   │   │   │   ├── ConversationManagerPerformanceTests.swift
│   │   │   │   ├── ConversationManagerPersistenceTests.swift
│   │   │   │   ├── ConversationManagerTests.swift
│   │   │   │   ├── FunctionCallDispatcherTests.swift
│   │   │   │   ├── LocalCommandParserTests.swift
│   │   │   │   ├── MessageClassificationTests.swift
│   │   │   │   ├── PersonaEnginePerformanceTests.swift
│   │   │   │   ├── PersonaEngineTests.swift
│   │   │   │   └── Phase2ValidationTests.swift
│   │   │   ├── Chat
│   │   │   │   ├── ChatCoordinatorTests.swift
│   │   │   │   ├── ChatSuggestionsEngineTests.swift
│   │   │   │   └── ChatViewModelTests.swift
│   │   │   ├── Dashboard
│   │   │   │   └── DashboardViewModelTests.swift
│   │   │   ├── Notifications
│   │   │   │   ├── EngagementEngineTests.swift
│   │   │   │   └── NotificationManagerTests.swift
│   │   │   ├── Onboarding
│   │   │   │   ├── ConversationViewModelTests.swift
│   │   │   │   ├── OnboardingFlowViewTests.swift
│   │   │   │   ├── OnboardingIntegrationTests.swift
│   │   │   │   ├── OnboardingModelsTests.swift
│   │   │   │   ├── OnboardingServiceTests.swift
│   │   │   │   ├── OnboardingViewModelTests.swift
│   │   │   │   └── OnboardingViewTests.swift
│   │   │   └── Settings
│   │   │       ├── BiometricAuthManagerTests.swift
│   │   │       ├── SettingsModelsTests.swift
│   │   │       └── SettingsViewModelTests.swift
│   │   ├── Performance
│   │   │   ├── DirectAIPerformanceTests.swift
│   │   │   ├── NutritionParsingPerformanceTests.swift
│   │   │   ├── NutritionParsingRegressionTests.swift
│   │   │   ├── OnboardingPerformanceTests.swift
│   │   │   └── PersonaGenerationStressTests.swift
│   │   ├── Services
│   │   │   ├── GeminiProviderTests.swift
│   │   │   ├── MockServicesTests.swift
│   │   │   ├── NetworkManagerTests.swift
│   │   │   ├── ServiceIntegrationTests.swift
│   │   │   ├── ServicePerformanceTests.swift
│   │   │   ├── ServiceProtocolsTests.swift
│   │   │   ├── TestHelpers.swift
│   │   │   ├── WeatherServiceTests.swift
│   │   │   └── WorkoutSyncServiceTests.swift
│   │   └── Workouts
│   │       ├── WorkoutCoordinatorTests.swift
│   │       └── WorkoutViewModelTests.swift
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
│   │   ├── ContentView.swift
│   │   └── MinimalContentView.swift
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
│   │   ├── Enums
│   │   │   ├── AppError.swift
│   │   │   ├── AppError+Conversion.swift
│   │   │   ├── GlobalEnums.swift
│   │   │   └── MessageType.swift
│   │   ├── Extensions
│   │   │   ├── AIProvider+API.swift
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
│   │   │   └── WorkoutBuilderData.swift
│   │   ├── Protocols
│   │   │   ├── AIServiceProtocol.swift
│   │   │   ├── AIServiceProtocol+Extensions.swift
│   │   │   ├── AnalyticsServiceProtocol.swift
│   │   │   ├── APIKeyManagementProtocol.swift
│   │   │   ├── DashboardServiceProtocols.swift
│   │   │   ├── ErrorHandling.swift
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
│   │   │   ├── WeatherServiceProtocol.swift
│   │   │   ├── WhisperServiceWrapperProtocol.swift
│   │   │   └── WorkoutServiceProtocol.swift
│   │   ├── Theme
│   │   │   ├── AppColors.swift
│   │   │   ├── AppFonts.swift
│   │   │   ├── AppShadows.swift
│   │   │   └── AppSpacing.swift
│   │   ├── Utilities
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
│   │   │       ├── OnboardingNavigationButtons.swift
│   │   │       ├── OnboardingStateView.swift
│   │   │       ├── OpeningScreenView.swift
│   │   │       ├── OptimizedGeneratingPersonaView.swift
│   │   │       ├── PersonaPreviewCard.swift
│   │   │       ├── PersonaPreviewView.swift
│   │   │       ├── PersonaSelectionView.swift
│   │   │       ├── PersonaSynthesisView.swift
│   │   │       ├── SleepAndBoundariesView.swift
│   │   │       └── UnifiedOnboardingView.swift
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
│   │   │   ├── AIRequestBuilder.swift
│   │   │   ├── AIResponseCache.swift
│   │   │   ├── AIResponseParser.swift
│   │   │   ├── AIService.swift
│   │   │   ├── LLMOrchestrator.swift
│   │   │   └── OfflineAIService.swift
│   │   ├── Analytics
│   │   │   └── AnalyticsService.swift
│   │   ├── Cache
│   │   │   └── OnboardingCache.swift
│   │   ├── Context
│   │   │   └── ContextAssembler.swift
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
│   ├── Architecture
│   │   ├── CodeMap
│   │   │   ├── 00_Project_Overview.md
│   │   │   ├── 01_Core_Layer.md
│   │   │   ├── 02_Data_Layer.md
│   │   │   ├── 03_Services_Layer.md
│   │   │   ├── 04_Modules_Layer.md
│   │   │   ├── 05_Application_Layer.md
│   │   │   ├── 06_Testing_Strategy.md
│   │   │   ├── 07_WatchApp.md
│   │   │   ├── 08_Supporting_Files.md
│   │   │   ├── 10_Dependency_Hints.md
│   │   │   ├── FileTree.md
│   │   │   └── Full_CodeMap.md
│   │   ├── Architecture Update Report.md
│   │   ├── ArchitectureAnalysis.md
│   │   └── ArchitectureOverview.md
│   ├── Archive
│   │   ├── Module_Development
│   │   │   ├── Completed
│   │   │   │   ├── API_INTEGRATION_ANALYSIS.md
│   │   │   │   ├── CODEBASE_CONTEXT.md
│   │   │   │   ├── COMMON_COMMANDS.md
│   │   │   │   ├── Gemini integration guide.md
│   │   │   │   ├── HealthKitIntegration.md
│   │   │   │   ├── IMPLEMENTATION_CHECKLIST.md
│   │   │   │   ├── Module10_Compatibility_Analysis.md
│   │   │   │   ├── OnboardingFlow.md
│   │   │   │   ├── PERSONA_REFACTOR_EXECUTION_GUIDE.md
│   │   │   │   ├── Phase1_ConversationalFoundation.md
│   │   │   │   ├── Phase2_PersonaSynthesis.md
│   │   │   │   ├── Phase3_Integration_Complete.md
│   │   │   │   ├── Phase3_IntegrationTesting.md
│   │   │   │   ├── Phase4_Batch4.1_Complete.md
│   │   │   │   ├── Phase4_FinalImplementation.md
│   │   │   │   ├── Phase4_Implementation_Summary.md
│   │   │   │   ├── README.md
│   │   │   │   ├── START_HERE.md
│   │   │   │   ├── STATUS_AND_VISION.md
│   │   │   │   ├── SystemPrompt.md
│   │   │   │   └── Tuneup.md
│   │   │   ├── API_FEATURES_GUIDE.md
│   │   │   ├── Persona Refactor Tasks.md
│   │   │   ├── Persona Refactor.md
│   │   │   └── PersonaRefactorContext.md
│   │   ├── Research Reports
│   │   │   ├── Agents.md Report.md
│   │   │   ├── API Integration Report.md
│   │   │   ├── Architecture Cleanup Summary.md
│   │   │   ├── Architecture Tightening Report.md
│   │   │   ├── Claude Config Report.md
│   │   │   ├── Codex Optimization Report.md
│   │   │   └── MLX Whisper Integration Report.md
│   │   └── NAMING_STANDARDS.md
│   ├── Cleanup
│   │   ├── Active
│   │   │   ├── BUILD_STATUS.md
│   │   │   ├── CLEANUP_TRACKER.md
│   │   │   ├── ERROR_HANDLING_GUIDE.md
│   │   │   ├── FILE_NAMING_FIXES_PLAN.md
│   │   │   ├── PRESERVATION_GUIDE.md
│   │   │   └── README.md
│   │   ├── Archive
│   │   │   ├── Analysis
│   │   │   │   ├── AI_SERVICE_CATEGORIZATION.md
│   │   │   │   ├── DEEP_ARCHITECTURE_ANALYSIS.md
│   │   │   │   ├── DUPLICATE_DEPENDENCY_ANALYSIS.md
│   │   │   │   ├── IMPORT_DEPENDENCY_ANALYSIS.md
│   │   │   │   └── PHASE_3_ANALYSIS_REPORT.md
│   │   │   ├── Deprecated
│   │   │   │   ├── CLEANUP_PHASE_3_STANDARDIZATION.md
│   │   │   │   ├── CLEANUP_PHASE_4_DI_OVERHAUL.md
│   │   │   │   ├── PHASE_3_4_ONBOARDING_CLEANUP.md
│   │   │   │   ├── PHASE_3_5_DASHBOARD_CLEANUP.md
│   │   │   │   ├── PHASE_3_6_FOODTRACKING_CLEANUP.md
│   │   │   │   ├── PHASE_3_7_CHAT_CLEANUP.md
│   │   │   │   ├── PHASE_3_8_SETTINGS_CLEANUP.md
│   │   │   │   ├── PHASE_3_9_WORKOUTS_CLEANUP.md
│   │   │   │   ├── PHASE_3_10_AI_CLEANUP.md
│   │   │   │   ├── PHASE_3_11_NOTIFICATIONS_CLEANUP.md
│   │   │   │   ├── PHASE_3_ERROR_HANDLING_TODO.md
│   │   │   │   ├── PHASE_3_MODULE_CLEANUP_SUMMARY.md
│   │   │   │   ├── README_NEW.md
│   │   │   │   └── START_HERE.md
│   │   │   ├── Planning
│   │   │   │   ├── ARCHITECTURE_CLEANUP_EXECUTIVE_SUMMARY.md
│   │   │   │   ├── ARCHITECTURE_CLEANUP_PLAN.md
│   │   │   │   ├── IMMEDIATE_ACTION_PLAN.md
│   │   │   │   └── REORGANIZATION_PLAN.md
│   │   │   ├── BUILDPROGRESS.md
│   │   │   └── PROJECT_STRUCTURE.md
│   │   └── Phases
│   │       ├── PHASE_1_CRITICAL_FIXES.md
│   │       ├── PHASE_2_SERVICE_MIGRATION.md
│   │       ├── PHASE_3_STANDARDIZATION.md
│   │       └── PHASE_4_FOUNDATION.md
│   ├── Development
│   │   ├── DOCUMENTATION_CHECKLIST.md
│   │   ├── NAMING_STANDARDS.md
│   │   ├── PROJECT_FILE_MANAGEMENT.md
│   │   └── TESTING_GUIDELINES.md
│   ├── Modules
│   │   ├── Design.md
│   │   ├── Module0.md
│   │   ├── Module1.md
│   │   ├── Module2.md
│   │   ├── Module3.md
│   │   ├── Module4.md
│   │   ├── Module5.md
│   │   ├── Module6.md
│   │   ├── Module7.md
│   │   ├── Module8.5.md
│   │   ├── Module8.md
│   │   ├── Module9.md
│   │   ├── Module10.md
│   │   ├── Module11.md
│   │   ├── Module12.md
│   │   └── Module13.md
│   └── README.md
├── Scripts
│   ├── add_files_to_xcode.sh
│   ├── architecture_audit.sh
│   ├── check_duplicates.sh
│   ├── fix_targets.sh
│   ├── test_module8_integration.sh
│   ├── validate_cleanup_claims.sh
│   ├── validate-tuneup.sh
│   ├── verify_module_tests.sh
│   ├── verify_module8_integration.sh
│   └── verify_module10.sh
├── .cursorrules
├── .gitignore
├── AGENTS.md
├── AirFit.xctestplan
├── CLAUDE.md
├── envsetupscript.sh
├── Manual.md
├── package.json
└── project.yml

</file_map>
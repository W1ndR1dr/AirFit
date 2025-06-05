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



<Complete Definitions>
Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/AI/ContextAnalyzerTests.swift

---
Classes:
  Class: ContextAnalyzerTests
    Methods:
      - func test_determineOptimalRoute_simpleParsing_returnsDirectAI() {
      - func test_determineOptimalRoute_complexWorkflow_returnsFunctionCalling() {
      - func test_determineOptimalRoute_activeChain_preservesFunctionCalling() {
      - func test_detectsSimpleParsing_recognizesPatterns() {
      - func test_detectsComplexWorkflow_recognizesPatterns() {
      - func test_chainContext_detectsActiveChains() {
      - func test_routingAnalytics_logsCorrectly() {
      - func test_processingRoute_properties() {
      - func test_userContextSnapshot_initialization() {
      - func test_urgencyLevel_detection() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Context/ContextAssemblerTests.swift

---
Classes:
  Class: ContextAssemblerTests
    Properties:
      - var modelContainer: ModelContainer!
      - var context: ModelContext!
      - var mockHealthKit: MockHealthKitManager!
      - var sut: ContextAssembler!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_assembleSnapshot_withCompleteData_populatesSnapshot() async throws {
      - @MainActor
    private func addTestData() async throws {
      - @MainActor
    func test_assembleSnapshot_whenHealthKitThrows_returnsDefaultMetrics() async {
      - @MainActor
    func test_performance_assembleSnapshot_largeDataSet() async throws {
      - @MainActor
    func test_assembleSnapshot_whenHealthKitDenied_usesDefaultValues() async {
      - @MainActor
    func test_assembleSnapshot_whenPartialPermissions_handlesGracefully() async {
      - @MainActor
    func test_assembleSnapshot_withIncompleteHealthData_assemblesPartialSnapshot() async {
      - @MainActor
    func test_assembleSnapshot_withStaleData_includesTimestampWarnings() async throws {
      - @MainActor
    func test_assembleSnapshot_withLargeDataSets_maintainsPerformance() async throws {
      - @MainActor
    func test_assembleSnapshot_coordinating_HealthKitAndSwiftData_successfully() async throws {
      - @MainActor
    func test_assembleSnapshot_withConcurrentAccess_remainsThreadSafe() async throws {
      - @MainActor
    func test_assembleSnapshot_withTimeout_handlesGracefully() async {
      - @MainActor
    func test_assembleSnapshot_withCorruptedSwiftData_handlesGracefully() async {
  Class: TestError

Enums:
  - TestError
    Cases:
      - test
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Core/AppConstantsTests.swift

---
Classes:
  Class: AppConstantsTests
    Methods:
      - @Test
    func test_layout_constants() {
      - @Test
    func test_validation_limits() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Core/CoreSetupTests.swift

---
Classes:
  Class: CoreSetupTests
    Methods:
      - @Test
    @MainActor
    func test_emptyStateView_initialization() {
      - @Test
    @MainActor
    func test_emptyStateView_withAction() {
      - @Test
    @MainActor
    func test_sectionHeader_initialization() {
      - @Test
    @MainActor
    func test_sectionHeader_withIconAndAction() {
      - @Test
    func test_appColors_accessibility() {
      - @Test
    func test_appFonts_accessibility() {
      - @Test
    func test_appSpacing_constants() {
      - @Test
    func test_appConstants_layout() {
      - @Test
    func test_viewExtensions_compilation() {
      - @Test
    func test_globalEnums_accessibility() {
      - @Test
    func test_appTab_enum() {
      - @Test
    func test_appError_descriptions() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Core/ExtensionsTests.swift

---
Classes:
  Class: ExtensionsTests
    Methods:
      - @Test
    func test_kilogramsToPounds() {
      - @Test
    func test_colorHex() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Core/FormattersTests.swift

---
Classes:
  Class: FormattersTests
    Methods:
      - @Test
    func test_formatCalories() {
      - @Test
    func test_formatWeight_metric() {
      - @Test
    func test_formatWeight_imperial() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Core/KeychainWrapperTests.swift

---
Classes:
  Class: KeychainWrapperTests
    Properties:
      - private var sut: KeychainWrapper!
      - private let testKey = "test_key"
    Methods:
      - override func setUp() {
      - override func tearDown() {
      - func test_saveData_shouldSucceed() throws {
      - func test_saveString_shouldSucceed() throws {
      - func test_saveCodable_shouldSucceed() throws {
      - func test_loadData_shouldReturnSavedData() throws {
      - func test_loadString_shouldReturnSavedString() throws {
      - func test_loadCodable_shouldReturnSavedObject() throws {
      - func test_loadData_withNonExistentKey_shouldThrow() {
      - func test_deleteKey_shouldSucceed() throws {
      - func test_deleteNonExistentKey_shouldSucceed() throws {
      - func test_exists_withExistingKey_shouldReturnTrue() throws {
      - func test_exists_withNonExistentKey_shouldReturnFalse() {
      - func test_update_existingKey_shouldSucceed() throws {
      - func test_update_nonExistentKey_shouldCreateNew() throws {
  Class: TestCodableObject
    Properties:
      - let id: Int
      - let name: String
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Core/ValidatorsTests.swift

---
Classes:
  Class: ValidatorsTests
    Methods:
      - @Test
    func test_validateEmail() {
      - @Test
    func test_validatePassword() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Core/VoiceInputManagerTests.swift

---
Classes:
  Class: VoiceInputManagerTests
    Properties:
      - var sut: TestableVoiceInputManager!
      - var mockModelManager: MockWhisperModelManager!
      - var mockAudioSession: MockAVAudioSession!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_requestPermission_whenGranted_shouldReturnTrue() async throws {
      - func test_requestPermission_whenDenied_shouldReturnFalse() async throws {
      - func test_startRecording_shouldUpdateState() async throws {
      - func test_stopRecording_shouldUpdateStateAndReturnTranscription() async throws {
      - func test_stopRecording_whenNotRecording_shouldReturnNil() async {
      - func test_startStreamingTranscription_shouldUpdateState() async throws {
      - func test_startStreamingTranscription_whenWhisperNotReady_shouldThrowError() async throws {
      - func test_stopStreamingTranscription_shouldUpdateState() async throws {
      - func test_transcriptionCallback_shouldBeCalledOnSuccess() async throws {
      - func test_partialTranscriptionCallback_shouldBeCalledDuringStreaming() async throws {
      - func test_errorCallback_shouldBeCalledOnTranscriptionFailure() async throws {
      - func test_waveformCallback_shouldBeCalledWithData() async throws {
      - func test_postProcessTranscription_shouldCorrectFitnessTerms() async throws {
      - func test_postProcessTranscription_shouldHandlePRCorrection() async throws {
      - func test_postProcessTranscription_shouldTrimWhitespace() async throws {
      - func test_whisperInitializationFailure_shouldCallErrorCallback() async throws {
      - func test_transcriptionPerformance_shouldMeetLatencyRequirements() async throws {
      - func test_waveformBufferSize_shouldBeLimited() async throws {
      - func test_stopRecording_shouldCleanupResources() async throws {
      - func test_stopStreamingTranscription_shouldCleanupResources() async throws {
      - func test_modelSelection_shouldUseOptimalModel() async throws {
      - func test_modelDownload_shouldUpdateDownloadedModels() async throws {
      - func test_modelDeletion_shouldRemoveFromDownloadedModels() throws {
      - func test_audioSessionConfiguration_shouldSetCorrectCategory() throws {
      - func test_audioSessionActivation_shouldActivateSuccessfully() throws {
      - func test_audioSessionActivation_whenError_shouldThrow() {
      - func test_concurrentRecordingAttempts_shouldHandleGracefully() async throws {
      - func test_rapidStartStopCycles_shouldMaintainStability() async throws {
      - func test_errorDescriptions_shouldMatch() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Data/UserModelTests.swift

---
Classes:
  Class: UserModelTests
    Properties:
      - var container: ModelContainer!
      - var context: ModelContext!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_createUser_withDefaultValues_shouldInitializeCorrectly() throws {
      - @MainActor
    func test_createUser_withCustomValues_shouldSetCorrectly() throws {
      - @MainActor
    func test_userRelationships_whenDeleted_shouldCascadeDelete() throws {
      - @MainActor
    func test_getTodaysLog_withMultipleLogs_shouldReturnToday() throws {
      - @MainActor
    func test_getRecentMeals_shouldReturnSortedMeals() throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/FoodTracking/AINutritionParsingIntegrationTests.swift

---
Classes:
  Class: AINutritionParsingIntegrationTests
    Properties:
      - private var modelContainer: ModelContainer!
      - private var modelContext: ModelContext!
      - private var coachEngine: CoachEngine!
      - private var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_parseNaturalLanguageFood_withMockAI_returnsValidResults() async throws {
      - func test_parseNaturalLanguageFood_fallbackBehavior_handlesInvalidInput() async throws {
      - func test_parseNaturalLanguageFood_mealTypeContext_adjustsDefaultCalories() async throws {
      - func test_parseNaturalLanguageFood_nutritionValidation_rejectsInvalidValues() async throws {
      - func test_parseNaturalLanguageFood_performance_completesQuickly() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/FoodTracking/AINutritionParsingTests.swift

---
Classes:
  Class: AINutritionParsingTests
    Properties:
      - private var modelContainer: ModelContainer!
      - private var modelContext: ModelContext!
      - private var coachEngine: MockFoodCoachEngine!
      - private var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_parseNaturalLanguageFood_simpleFood_returnsParsedItem() async throws {
      - func test_parseNaturalLanguageFood_foodWithQuantity_returnsParsedItem() async throws {
      - func test_parseNaturalLanguageFood_multipleFoods_returnsMultipleParsedItems() async throws {
      - func test_parseNaturalLanguageFood_networkError_throwsError() async {
      - func test_parseNaturalLanguageFood_invalidInput_returnsFallbackItem() async throws {
      - func test_parseNaturalLanguageFood_breakfastContext_adjustsCalories() async throws {
      - func test_parseNaturalLanguageFood_performance_completesWithinTimeout() async throws {
      - func test_parseNaturalLanguageFood_validatesNutritionValues_rejectsInvalidData() async throws {
      - func test_parseNaturalLanguageFood_withLunchMealType_shouldReturnCorrectFallback() async throws {
      - func test_parseNaturalLanguageFood_withDinnerMealType_shouldReturnCorrectFallback() async throws {
      - func test_parseNaturalLanguageFood_withMultipleFoods_shouldReturnMultipleItems() async throws {
      - func test_parseNaturalLanguageFood_withSnackMealType_shouldReturnCorrectFallback() async throws {
      - func test_parseNaturalLanguageFood_withBreakfastMealType_shouldReturnCorrectFallback() async throws {
      - func test_parseNaturalLanguageFood_withPerformanceRequirement_shouldCompleteUnder3Seconds() async throws {
      - func test_parseNaturalLanguageFood_withComplexMeal_shouldParseCorrectly() async throws {
      - func test_parseNaturalLanguageFood_snackParsing_returnsFallbackItem() async throws {
  Class: MockFoodCoachEngine
    Properties:
      - var mockParseResult: [ParsedFoodItem] = []
      - var shouldThrowError = false
      - var errorToThrow: Error = FoodTrackingError.aiParsingFailed
      - var shouldReturnFallback = false
      - var shouldValidate = false
      - var simulateDelay: TimeInterval = 0
      - var lastMealType: MealType?
      - var lastText: String?
      - var lastUser: User?
    Methods:
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
      - func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
      - func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
      - func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
      - private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
      - private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/FoodTracking/FoodTrackingViewModelAIIntegrationTests.swift

---
Classes:
  Class: FoodTrackingViewModelAIIntegrationTests
    Properties:
      - private var sut: FoodTrackingViewModel!
      - private var mockCoachEngine: MockAICoachEngine!
      - private var mockVoiceAdapter: MockFoodVoiceAdapter!
      - private var mockNutritionService: MockNutritionService!
      - private var mockCoordinator: MockFoodTrackingCoordinator!
      - private var testUser: User!
      - private var modelContainer: ModelContainer!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_processTranscription_aiParsingSuccess_showsConfirmation() async throws {
      - func test_processTranscription_multipleItems_parsesAllCorrectly() async throws {
      - func test_processTranscription_complexDescription_handlesDetailedInput() async throws {
      - func test_processTranscription_performance_completesUnder3Seconds() async throws {
      - func test_processTranscription_emptyText_noProcessing() async throws {
      - func test_processTranscription_aiParsingFailure_showsError() async throws {
      - func test_processTranscription_networkError_handlesGracefully() async throws {
      - func test_processTranscription_noFoodFound_showsError() async throws {
      - func test_processTranscription_preservesMealTypeContext() async throws {
      - func test_processTranscription_validatesNutritionValues() async throws {
      - func test_processTranscription_regressionPrevention_noHardcodedValues() async throws {
      - func test_processTranscription_stateManagement_isProcessingAI() async throws {
      - func test_processTranscription_errorHandling_clearsProcessingState() async throws {
  Class: MockAICoachEngine
    Properties:
      - var mockParseResult: [ParsedFoodItem] = []
      - var shouldThrowError = false
      - var errorToThrow: Error = FoodTrackingError.aiParsingFailed
      - var simulateDelay: TimeInterval = 0
      - var lastMealType: MealType?
      - var lastUserPassed: User?
      - var wasParseNaturalLanguageFoodCalled = false
    Methods:
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
      - func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
      - func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
      - func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
  Class: MockFoodVoiceAdapter
    Properties:
      - var isRecording: Bool = false
      - var isTranscribing: Bool = false
      - var transcribedText: String = ""
      - var voiceWaveform: [Float] = []
      - var onFoodTranscription: ((String) -> Void)?
      - var onError: ((Error) -> Void)?
      - var requestPermissionShouldSucceed: Bool = true
      - var startRecordingShouldSucceed: Bool = true
      - var stopRecordingText: String? = "mock transcription"
    Methods:
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
  Class: MockNutritionService
    Properties:
      - var shouldThrowError: Bool = false
    Methods:
      - func saveFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
      - func deleteFoodEntry(_ entry: FoodEntry) async throws {
  Class: MockFoodTrackingCoordinator
    Properties:
      - var didShowSheet: FoodTrackingSheet?
      - var didShowFullScreenCover: FoodTrackingFullScreenCover?
      - var didDismiss = false
    Methods:
      - override func showSheet(_ sheet: FoodTrackingSheet) {
      - override func showFullScreenCover(_ cover: FoodTrackingFullScreenCover) {
      - override func dismiss() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/FoodTracking/FoodTrackingViewModelTests.swift

---
Classes:
  Class: MockFoodVoiceAdapter
    Properties:
      - var isRecording: Bool = false
      - var isTranscribing: Bool = false
      - var transcribedText: String = ""
      - var voiceWaveform: [Float] = []
      - var onFoodTranscription: ((String) -> Void)?
      - var onError: ((Error) -> Void)?
      - var requestPermissionShouldSucceed: Bool = true
      - var startRecordingShouldSucceed: Bool = true
      - var stopRecordingText: String? = "mock transcription"
    Methods:
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
      - func simulateTranscription(_ text: String) {
      - func simulateError(_ error: Error) {
  Class: MockNutritionService
    Properties:
      - var foodEntriesToReturn: [FoodEntry] = []
      - var nutritionSummaryToReturn = FoodNutritionSummary()
      - var waterIntakeToReturn: Double = 0
      - var recentFoodsToReturn: [FoodItem] = []
      - var mealHistoryToReturn: [FoodEntry] = []
      - var targetsToReturn = NutritionTargets.default
      - var shouldThrowError: Bool = false
      - var loggedWaterAmount: Double?
      - var loggedWaterDate: Date?
    Methods:
      - func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
      - func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
      - func getWaterIntake(for user: User, date: Date) async throws -> Double {
      - func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
      - func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
      - func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
      - func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
      - func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
  Class: MockFoodDatabaseService
    Properties:
      - var searchResultsToReturn: [FoodDatabaseItem] = []
      - var commonFoodToReturn: FoodDatabaseItem?
      - var analyzePhotoResultToReturn: [FoodDatabaseItem] = []
      - var shouldThrowError: Bool = false
    Methods:
      - func searchFoods(query: String, limit: Int) async throws -> [FoodDatabaseItem] {
      - func searchCommonFood(_ name: String) async throws -> FoodDatabaseItem? {
      - func analyzePhotoForFoods(_ image: UIImage) async throws -> [FoodDatabaseItem]? {
  Class: MockCoachEngine
    Properties:
      - var executeFunctionShouldSucceed: Bool = true
      - var executeFunctionDataToReturn: [String: SendableValue]? = nil
      - var analyzeMealPhotoShouldSucceed: Bool = true
      - var analyzeMealPhotoItemsToReturn: [ParsedFoodItem] = []
      - var searchFoodsShouldSucceed: Bool = true
      - var searchFoodsResultToReturn: [ParsedFoodItem] = []
      - var shouldTimeout: Bool = false
    Methods:
      - override func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> AIFunctionResult {
      - override func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
      - func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
  Class: MockFoodTrackingCoordinator
    Properties:
      - var didShowSheet: FoodTrackingSheet?
      - var didShowFullScreenCover: FoodTrackingFullScreenCover?
      - var didDismiss = false
      - var didPop = false
      - var didPopToRoot = false
    Methods:
      - override func showSheet(_ sheet: FoodTrackingSheet) {
      - override func showFullScreenCover(_ cover: FoodTrackingFullScreenCover) {
      - override func dismiss() {
      - override func pop() {
      - override func popToRoot() {
  Class: MockError
  Class: SwiftDataTestHelper
    Methods:
      - @MainActor
    static func previewContainer() throws -> ModelContainer {
  Class: FoodTrackingViewModelTests
    Properties:
      - var modelContainer: ModelContainer!
      - var modelContext: ModelContext!
      - var testUser: User!
      - var mockFoodVoiceAdapter: MockFoodVoiceAdapter!
      - var mockNutritionService: MockNutritionService!
      - var mockCoachEngine: MockCoachEngine!
      - var mockCoordinator: MockFoodTrackingCoordinator!
      - var sut: FoodTrackingViewModel!
    Methods:
      - override func setUpWithError() async throws {
      - override func tearDownWithError() throws {
      - private func createSampleParsedItem(name: String = "Apple", calories: Double = 95, confidence: Float = 0.9) -> ParsedFoodItem {
      - private func createSampleFoodDatabaseItem(id: String = "db_apple", name: String = "Apple", calories: Double = 95) -> FoodDatabaseItem {
      - private func createSampleFoodItem(name: String = "Logged Apple") -> FoodItem {
      - func test_init_loadsInitialDataViaSetNutritionService() async {
      - func test_loadTodaysData_success_populatesPropertiesCorrectly() async {
      - func test_loadTodaysData_serviceFailure_setsError() async {
      - func test_startVoiceInput_permissionGranted_showsVoiceSheet() async {
      - func test_startVoiceInput_permissionDenied_setsError() async {
      - func test_startRecording_success_updatesState() async {
      - func test_startRecording_failure_setsErrorAndState() async {
      - func test_stopRecording_withText_processesTranscription() async {
      - func test_stopRecording_emptyText_doesNotProcess() async {
      - func test_voiceCallbacks_onFoodTranscription_updatesTextAndProcesses() async {
      - func test_voiceCallbacks_onError_setsViewModelError() {
      - func test_processTranscription_localCommandSuccess_showsConfirmation() async {
      - func test_processTranscription_aiParsingSuccess_showsConfirmation() async {
      - func test_processTranscription_aiParsingTimeout_handlesTimeoutError() async {
      - func test_processTranscription_aiParsingReturnsNoPrimaryItems_butAlternatives_showsAlternatives() async {
      - func test_processTranscription_aiParsingFailure_keywordFallback_showsSuggestions() async {
      - func test_startPhotoCapture_showsPhotoSheet() {
      - func test_processPhotoResult_success_showsConfirmation() async {
      - func test_processPhotoResult_failure_setsError() async {
      - func test_processPhotoResult_noItemsDetected_setsError() async {
      - func test_searchFoods_validQuery_updatesSearchResults() async {
      - func test_searchFoods_emptyQuery_clearsResults() async {
      - func test_selectSearchResult_updatesParsedItemsAndShowsConfirmation() {
      - func test_clearSearchResults_emptiesViewModelProperty() {
      - func test_setSearchResults_updatesViewModelProperty() {
      - func test_confirmAndSaveFoodItems_success_savesAndRefreshes() async throws {
      - func test_confirmAndSaveFoodItems_saveFailure_setsError() async {
      - func test_logWater_success_updatesViewModelAndCallsService() async {
      - func test_logWater_serviceFailure_setsError() async {
      - func test_generateSmartSuggestions_withHistory_returnsSuggestions() async {
      - func test_deleteFoodEntry_success_removesEntryAndRefreshes() async throws {
      - func test_duplicateFoodEntry_success_createsNewEntryAndRefreshes() async throws {
      - func test_errorState_isSetAndClearedCorrectly() {
      - func test_isLoading_isSetCorrectlyDuringAsyncOperations() async {
      - func test_viewModel_withNilNutritionService_gracefullyHandlesCalls() async {
      - func test_setNutritionService_loadsDataWithNewService() async {
      - func test_setSelectedMealType_updatesPropertyAndSuggestions() async {
      - func test_setParsedItems_updatesViewModelProperty() {
  Class: MockAPIKeyManager
    Methods:
      - func getKey(for service: APIServiceType) -> String? {
      - func setKey(_ key: String, for service: APIServiceType) {
      - func deleteKey(for service: APIServiceType) {
      - func deleteAllKeys() {
  Class: MockNetworkClient
    Methods:
      - func post<T: Decodable>(url: URL, body: some Encodable, headers: [String : String]) async throws -> T {
      - func get<T: Decodable>(url: URL, headers: [String : String]) async throws -> T {
      - func stream<T: Decodable>(url: URL, body: some Encodable, headers: [String : String], responseType: T.Type) -> AsyncThrowingStream<T, Error> {

Enums:
  - MockError
    Cases:
      - generic
      - permissionDenied
      - recordingFailed
      - serviceError
      - aiError
      - dataSaveFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/FoodTracking/FoodVoiceAdapterTests.swift

---
Classes:
  Class: MockVoiceInputManager
    Properties:
      - var isRecording: Bool = false
      - var transcribedText: String = "" // For simulating final transcription from stopRecording
      - var currentPartialText: String = ""
      - var currentWaveform: [Float] = []
      - var currentError: Error?
      - var onTranscription: ((String) -> Void)?
      - var onPartialTranscription: ((String) -> Void)?
      - var onWaveformUpdate: (([Float]) -> Void)?
      - var onError: ((Error) -> Void)?
      - var mockIsTranscribing: Bool = false
      - var requestPermissionShouldSucceed: Bool = true
      - var startRecordingShouldSucceed: Bool = true
      - var stopRecordingResultText: String? = "default mock transcription"
    Methods:
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
      - func simulatePartialTranscription(_ text: String) {
      - func simulateFinalTranscription(_ text: String) {
      - func simulateWaveformUpdate(_ levels: [Float]) {
      - func simulateError(_ error: Error) {
  Class: FoodVoiceAdapterTests
    Properties:
      - var mockVoiceInputManager: MockVoiceInputManager!
      - var sut: FoodVoiceAdapter!
    Methods:
      - override func setUpWithError() throws {
      - override func tearDownWithError() throws {
      - func test_init_setsUpCallbacks() {
      - func test_requestPermission_success_returnsTrue() async throws {
      - func test_requestPermission_failure_throwsError() async {
      - func test_startRecording_success_setsIsRecordingToTrue() async throws {
      - func test_startRecording_failure_isRecordingRemainsFalseAndErrorPropagated() async {
      - func test_stopRecording_setsIsRecordingToFalseAndReturnsProcessedText() async {
      - func test_stopRecording_nilResultFromManager_returnsNil() async {
      - func test_postProcessForFood_trimsWhitespace() {
      - func test_postProcessForFood_correctsCommonMistakes() {
      - func test_postProcessForFood_noCorrectionsNeeded() {
      - func test_onTranscriptionCallback_fromManager_updatesAdapterAndCallsOwnCallback() {
      - func test_onPartialTranscriptionCallback_fromManager_updatesAdapterTranscribedText() {
      - func test_onWaveformUpdateCallback_fromManager_updatesAdapterWaveform() {
      - func test_onErrorCallback_fromManager_callsAdapterOwnOnErrorCallback() {
      - func test_isTranscribing_defaultState() {
      - func test_multipleCalls_maintainStateIntegrity() async throws {
      - func test_adapterDeinitialization() {
      - @MainActor // Keep on main actor if it accesses main actor isolated properties, though this one is pure.
    func postProcessForFood(_ text: String) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/FoodTracking/NutritionParsingExtensiveTests.swift

---
Classes:
  Class: NutritionParsingExtensiveTests
    Properties:
      - private var modelContainer: ModelContainer!
      - private var modelContext: ModelContext!
      - private var coachEngine: MockCoachEngineExtensive!
      - private var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_nutritionParsing_commonFoods_accurateValues() async throws {
      - func test_nutritionParsing_multipleItems_separateEntries() async throws {
      - func test_nutritionParsing_complexDescriptions_handlesCookingMethods() async throws {
      - func test_nutritionParsing_performance_under3Seconds() async throws {
      - func test_nutritionParsing_batchProcessing_maintainsSpeed() async throws {
      - func test_nutritionParsing_invalidInput_gracefulFallback() async throws {
      - func test_nutritionParsing_aiFailure_returnsIntelligentFallback() async throws {
      - func test_nutritionParsing_validation_rejectsUnrealisticValues() async throws {
      - func test_nutritionParsing_validation_acceptsRealisticValues() async throws {
      - func test_nutritionParsing_mealTypeContext_adjustsDefaults() async throws {
      - func test_nutritionParsing_regressionPrevention_noHardcodedValues() async throws {
      - func test_nutritionParsing_apiContractMaintained() async throws {
  Class: MockCoachEngineExtensive
    Properties:
      - var mockParseResult: [ParsedFoodItem] = []
      - var shouldThrowError = false
      - var errorToThrow: Error = FoodTrackingError.aiParsingFailed
      - var shouldReturnFallback = false
      - var shouldValidate = false
      - var simulateDelay: TimeInterval = 0
      - var lastMealType: MealType?
    Methods:
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
      - func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
      - func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
      - func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
      - func setupRealisticNutrition(for food: String) {
      - func setupMultipleItems(for description: String) {
      - func setupCookingMethodNutrition(for food: String, method: String) {
      - private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
      - private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
      - private func getRealisticNutrition(for food: String) -> ParsedFoodItem {
      - private func parseMultipleItems(from description: String) -> [ParsedFoodItem] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/FoodTracking/NutritionParsingFinalIntegrationTests.swift

---
Classes:
  Class: NutritionParsingFinalIntegrationTests
    Properties:
      - private var sut: FoodTrackingViewModel!
      - private var coachEngine: CoachEngine!
      - private var mockVoiceAdapter: MockFoodVoiceAdapter!
      - private var mockNutritionService: MockNutritionService!
      - private var mockCoordinator: MockFoodTrackingCoordinator!
      - private var testUser: User!
      - private var modelContainer: ModelContainer!
      - private var modelContext: ModelContext!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_endToEnd_voiceToNutrition_realData() async throws {
      - func test_nutritionQuality_realDataNotPlaceholders() async throws {
      - func test_successCriteria_realNutritionData() async throws {
      - func test_integration_performanceTarget() async throws {
      - func test_integration_errorRecovery() async throws {
      - func test_integration_mealTypeContextIntegration() async throws {
      - func test_integration_multipleFoodsParsingFlow() async throws {
      - func test_integration_completeUIFlow() async throws {
      - func test_integration_noRegressionInExistingFunctionality() async throws {
      - func test_integration_performanceUnderLoad() async throws {
      - func test_finalValidation_allSuccessCriteriaMet() async throws {
      - func simulateTranscription(_ text: String) {
  Class: TestFullScreenCover
    Properties:
      - var testDidShowFullScreenCover: TestFullScreenCover? {

Enums:
  - TestFullScreenCover
    Cases:
      - confirmation
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Health/HealthKitManagerTests.swift

---
Classes:
  Class: HealthKitManagerTests
    Methods:
      - @MainActor
    func test_sharedInstance_exists() {
      - @MainActor
    func test_authorizationStatus_default_isNotDetermined() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Integration/NutritionParsingIntegrationTests.swift

---
Classes:
  Class: NutritionParsingIntegrationTests
    Properties:
      - private var sut: FoodTrackingViewModel!
      - private var coachEngine: CoachEngine!
      - private var mockVoiceAdapter: MockFoodVoiceAdapter!
      - private var mockNutritionService: MockNutritionService!
      - private var mockCoordinator: MockFoodTrackingCoordinator!
      - private var testUser: User!
      - private var modelContainer: ModelContainer!
      - private var modelContext: ModelContext!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_endToEnd_voiceToNutrition_realData() async throws {
      - func test_nutritionQuality_realDataNotPlaceholders() async throws {
      - func test_successCriteria_realNutritionData() async throws {
      - func test_integration_errorRecovery() async throws {
      - func test_integration_performanceTarget() async throws {
      - func test_phase1_comprehensive_beforeAfterValidation() async throws {
      - func test_finalValidation_allSuccessCriteriaMet() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Integration/OnboardingErrorRecoveryTests.swift

---
Classes:
  Class: OnboardingErrorRecoveryTests
    Properties:
      - var coordinator: OnboardingFlowCoordinator!
      - var recovery: OnboardingRecovery!
      - var cache: OnboardingCache!
      - var modelContext: ModelContext!
    Methods:
      - override func setUp() async throws {
      - func testNetworkErrorRecovery() async throws {
      - func testMaxRetryLimit() async throws {
      - func testSessionRecovery() async throws {
      - func testErrorPresentation() async throws {
      - func testCoordinatorErrorHandling() async throws {
      - func testRecoveryStateCleanup() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Integration/OnboardingFlowTests.swift

---
Classes:
  Class: OnboardingFlowTests
    Properties:
      - var coordinator: OnboardingFlowCoordinator!
      - var modelContext: ModelContext!
      - var conversationManager: ConversationFlowManager!
      - var personaService: PersonaService!
      - var userService: MockUserService!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testInitialState() {
      - func testNavigationFlow() async throws {
      - func testBeginConversationError() async {
      - func testCompleteConversationWithoutSession() async {
      - func testAcceptPersonaWithoutGeneration() async {
      - func testRetryLastAction() async {
      - func testProgressTracking() async {
      - func testPersonaAdjustment() async throws {
      - func testPersonaRegeneration() async throws {
      - func testLoadingStates() async {
      - func testErrorClearing() {
      - private func createMockResponses() -> [ConversationResponse] {
      - private func setupPersonaPreview() async {
  Class: MockAPIKeyManager
    Properties:
      - var shouldFailNextRequest: Bool {
    Methods:
      - func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
      - func getAPIKey(forProvider provider: AIProvider) -> String? {
      - func deleteAPIKey(forProvider provider: AIProvider) throws {
      - func getAPIKey(for provider: String) async -> String? {
      - func saveAPIKey(_ apiKey: String, for provider: String) async throws {
      - func deleteAPIKey(for provider: String) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Integration/PersonaGenerationTests.swift

---
Classes:
  Class: PersonaGenerationTests
    Properties:
      - var personaService: PersonaService!
      - var modelContext: ModelContext!
      - var mockLLMOrchestrator: MockLLMOrchestrator!
      - var personaSynthesizer: PersonaSynthesizer!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testPersonaGenerationFromConversation() async throws {
      - func testPersonaGenerationWithMinimalData() async throws {
      - func testPersonaAdjustment() async throws {
      - func testMultipleAdjustments() async throws {
      - func testPersonaSaving() async throws {
      - func testPersonaUpdate() async throws {
      - func testPersonaGenerationPerformance() async throws {
      - func testConcurrentPersonaGeneration() async throws {
      - func testPersonaGenerationFailure() async throws {
      - func testInvalidResponseData() async throws {
      - private func createTestConversationSession() -> ConversationSession {
      - private func createTestPersona(name: String = "Coach Test") -> PersonaProfile {
  Class: MockLLMOrchestrator
    Properties:
      - var shouldFail = false
    Methods:
      - override func complete(_ request: LLMRequest) async throws -> LLMResponse {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Integration/PersonaSystemIntegrationTests.swift

---
Classes:
  Class: PersonaSystemIntegrationTests
    Properties:
      - var modelContext: ModelContext!
      - var orchestrator: OnboardingOrchestrator!
      - var coachEngine: CoachEngine!
      - var unifiedAIService: UnifiedAIService!
      - var monitor: ProductionMonitor!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testCompleteOnboardingToCoachFlow() async throws {
      - func testConversationRecovery() async throws {
      - func testMultiProviderFallback() async throws {
      - func testSystemWideCaching() async throws {
      - func testProductionMonitoring() async throws {
      - func testErrorHandlingAcrossSystem() async throws {
      - private func createRealisticConversationData(userId: UUID) -> ConversationData {
      - private func createRealisticInsights() -> PersonalityInsights {
      - func generatePersona(
        from data: ConversationData,
        insights: PersonalityInsights
    ) async throws -> PersonaProfile {
      - func savePersona(_ persona: PersonaProfile, for userId: UUID) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/Base/MockProtocol.swift

---
Classes:
  Class: MockProtocol
    Methods:
      - func recordInvocation(_ method: String, arguments: Any...) {
      - func stub<T>(_ method: String, with result: T) {
      - func verify(_ method: String, called times: Int) {
      - func reset() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAIAnalyticsService.swift

---
Classes:
  Class: MockAIAnalyticsService
    Methods:
      - func analyzePerformance(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        for user: User
    ) async throws -> PerformanceAnalysisResult {
      - private func generateInsights(for metrics: [String], days: Int) -> [String] {
      - private func generateTrends(for metrics: [String]) -> [PerformanceAnalysisResult.TrendInfo] {
      - private func generateRecommendations(for metrics: [String]) -> [String] {
      - private func generateAnalysisSummary(
        query: String,
        insights: [String],
        trends: [PerformanceAnalysisResult.TrendInfo]
    ) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAIAPIService.swift

---
Classes:
  Class: ConfigureCallData
    Properties:
      - let provider: AIProvider
      - let apiKey: String
      - let modelIdentifier: String?
  Class: MockAIAPIService
    Properties:
      - var configureCalledWith: ConfigureCallData?
      - var getStreamingResponseCalledWithRequest: AIRequest?
      - var mockStreamingResponsePublisher: AnyPublisher<AIResponse, Error> = Empty().eraseToAnyPublisher()
    Methods:
      - func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
      - func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponse, Error> {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAICoachService.swift

---
Classes:
  Class: MockAICoachService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var mockGreeting: String = "Hello"
    Methods:
      - func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAIGoalService.swift

---
Classes:
  Class: MockAIGoalService
    Methods:
      - func createOrRefineGoal(
        current: String?,
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        constraints: [String],
        motivations: [String],
        goalType: String?,
        for user: User
    ) async throws -> GoalResult {
      - private func createSMARTGoal(
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        goalType: String?
    ) -> (title: String, description: String, criteria: GoalResult.SMARTCriteria) {
      - private func refinedGoalTitle(from aspirations: String, timeframe: String?) -> String {
      - private func generateGoalDescription(title: String, aspirations: String) -> String {
      - private func generateMilestones(for title: String, timeframe: String?) -> [String] {
      - private func generateMetrics(for goalType: String) -> [String] {
      - private func parseTargetDate(from timeframe: String?) -> Date? {
      - private func extractNumber(from text: String) -> Int? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAIService.swift

---
Classes:
  Class: MockAIService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var analyzeGoalResult: Result<String, Error> = .failure(MockError.notSet)
      - private(set) var analyzeGoalCalled = false
    Methods:
      - func analyzeGoal(_ goalText: String) async throws -> String {
  Class: MockError
    Properties:
      - static var mock: UserProfileJsonBlob {

Enums:
  - MockError
    Cases:
      - notSet
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAIWorkoutService.swift

---
Classes:
  Class: MockAIWorkoutService
    Methods:
      - func generatePlan(
        for user: User,
        goal: String,
        duration: Int,
        intensity: String,
        targetMuscles: [String],
        equipment: [String],
        constraints: String?,
        style: String
    ) async throws -> WorkoutPlanResult {
      - private func generateExercises(
        goal: String,
        duration: Int,
        targetMuscles: [String],
        equipment: [String],
        style: String
    ) -> [WorkoutPlanResult.ExerciseInfo] {
      - private func getExerciseDatabase(equipment: [String]) -> [(name: String, muscleGroups: [String])] {
      - private func getSetsAndReps(goal: String, style: String, exerciseIndex: Int) -> (sets: Int, reps: String) {
      - private func getRestTime(goal: String, style: String) -> Int {
      - private func calculateEstimatedCalories(
        exercises: [WorkoutPlanResult.ExerciseInfo],
        duration: Int,
        intensity: String
    ) -> Int {
      - private func generateWorkoutSummary(
        goal: String,
        exercises: [WorkoutPlanResult.ExerciseInfo],
        duration: Int
    ) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAnalyticsService.swift

---
Classes:
  Class: MockAnalyticsService
    Properties:
      - var trackedEvents: [AnalyticsEvent] = []
      - var trackedScreens: [(screen: String, properties: [String: String]?)] = []
      - var userProperties: [String: String] = [:]
      - var trackedWorkouts: [Workout] = []
      - var trackedMeals: [FoodEntry] = []
      - var shouldThrowError = false
      - var mockInsights = UserInsights(
 workoutFrequency: 3.5, averageWorkoutDuration: 3600, caloriesTrend: Trend(direction: .up, changePercentage: 5.0), macroBalance: MacroBalance(proteinPercentage: 30, carbsPercentage: 45, fatPercentage: 25), streakDays: 7, achievements: []
      - var trackEventCallCount = 0
      - var trackScreenCallCount = 0
      - var setUserPropertiesCallCount = 0
      - var trackWorkoutCompletedCallCount = 0
      - var trackMealLoggedCallCount = 0
      - var getInsightsCallCount = 0
    Methods:
      - func trackEvent(_ event: AnalyticsEvent) async {
      - func trackScreen(_ screen: String, properties: [String: String]?) async {
      - func setUserProperties(_ properties: [String: String]) async {
      - func trackWorkoutCompleted(_ workout: Workout) async {
      - func trackMealLogged(_ meal: FoodEntry) async {
      - func getInsights(for user: User) async throws -> UserInsights {
      - func reset() {
      - func verifyEventTracked(name: String, count: Int = 1) -> Bool {
      - func verifyScreenTracked(screen: String) -> Bool {
      - func getLastTrackedEvent() -> AnalyticsEvent? {
      - func getTrackedEvents(withName name: String) -> [AnalyticsEvent] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAPIKeyManager.swift

---
Classes:
  Class: MockAPIKeyManagement
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var stubbedSaveAPIKeyError: Error?
      - var stubbedGetAPIKeyResult: String = "test-api-key"
      - var stubbedGetAPIKeyError: Error?
      - var stubbedDeleteAPIKeyError: Error?
      - var stubbedHasAPIKeyResult: Bool = true
      - var stubbedGetAllConfiguredProvidersResult: [AIProvider] = []
    Methods:
      - func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func getAPIKey(for provider: AIProvider) async throws -> String {
      - func deleteAPIKey(for provider: AIProvider) async throws {
      - func hasAPIKey(for provider: AIProvider) async -> Bool {
      - func getAllConfiguredProviders() async -> [AIProvider] {
  Class: MockAPIKeyManager
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var stubbedSetAPIKeyError: Error?
      - var stubbedGetAPIKeyResult: String? = "test-api-key"
      - var stubbedGetAPIKeyError: Error?
      - var stubbedRemoveAPIKeyError: Error?
      - var stubbedHasAPIKeyResult: Bool = true
      - var stubbedGetAllConfiguredProvidersResult: [AIProvider] = []
      - var stubbedSaveAPIKeyError: Error?
      - var stubbedDeleteAPIKeyError: Error?
    Methods:
      - func setAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func getAPIKey(for provider: AIProvider) async throws -> String? {
      - func removeAPIKey(for provider: AIProvider) async throws {
      - func hasAPIKey(for provider: AIProvider) async -> Bool {
      - func getAllConfiguredProviders() async -> [AIProvider] {
      - func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
      - func getAPIKey(forProvider provider: AIProvider) -> String? {
      - func deleteAPIKey(forProvider provider: AIProvider) throws {
      - func getAPIKey(for provider: String) async -> String? {
      - func saveAPIKey(_ apiKey: String, for provider: String) async throws {
      - func deleteAPIKey(for provider: String) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAVAudioRecorder.swift

---
Classes:
  Class: MockAVAudioRecorder
    Properties:
      - private let queue = DispatchQueue(label: "MockAVAudioRecorder", attributes: .concurrent)
      - private var _isRecording = false
      - private var _isMeteringEnabled = false
      - private var _recordingError: Error?
      - private var _averagePowerValue: Float = -20.0
      - private let url: URL
      - private let settings: [String: Any]
      - var isRecording: Bool {
      - var isMeteringEnabled: Bool {
      - var recordingError: Error? {
      - var averagePowerValue: Float {
    Methods:
      - func record() -> Bool {
      - func stop() {
      - func updateMeters() {
      - func averagePower(forChannel channelNumber: Int) -> Float {
      - func stubRecordingError(_ error: Error?) {
      - func stubAveragePower(_ power: Float) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockAVAudioSession.swift

---
Classes:
  Class: MockAVAudioSession
    Properties:
      - private let queue = DispatchQueue(label: "MockAVAudioSession", attributes: .concurrent)
      - private var _recordPermissionResponse = true
      - private var _categorySetError: Error?
      - private var _activationError: Error?
      - private var _isActive = false
      - private var _category: AVAudioSession.Category = .playAndRecord
      - var recordPermissionResponse: Bool {
      - var categorySetError: Error? {
      - var activationError: Error? {
      - var isActive: Bool {
      - var category: AVAudioSession.Category {
    Methods:
      - func requestRecordPermission(_ response: @escaping @Sendable (Bool) -> Void) {
      - func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
      - func setActive(_ active: Bool) throws {
      - func stubCategorySetError(_ error: Error?) {
      - func stubActivationError(_ error: Error?) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockDashboardNutritionService.swift

---
Classes:
  Class: MockDashboardNutritionService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var mockSummary = NutritionSummary()
      - var mockTargets = NutritionTargets.default
    Methods:
      - func getTodaysSummary(for user: User) async throws -> NutritionSummary {
      - func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockFoodVoiceAdapter.swift

---
Classes:
  Class: MockFoodVoiceAdapter
    Properties:
      - private var _isListening = false
      - var mockTranscription = "one apple and a glass of milk"
      - var shouldThrowError = false
      - var throwError: Error?
      - var startListeningCallCount = 0
      - var stopListeningCallCount = 0
      - var isListeningCallCount = 0
      - var simulatedDelay: TimeInterval = 0
      - var transcriptionSequence: [String] = []
      - private var transcriptionIndex = 0
    Methods:
      - func startListening() async throws {
      - func stopListening() async throws -> String {
      - func isListening() -> Bool {
      - func reset() {
      - func configureTranscription(_ text: String) {
      - func configureTranscriptionSequence(_ texts: [String]) {
      - func configureError(_ error: Error) {
      - func verifyListeningState(expected: Bool) -> Bool {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockFoodVoiceService.swift

---
Classes:
  Class: MockFoodVoiceService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var isRecording: Bool = false
      - var isTranscribing: Bool = false
      - var transcribedText: String = ""
      - var voiceWaveform: [Float] = []
      - var onFoodTranscription: ((String) -> Void)?
      - var onError: ((Error) -> Void)?
      - var stubbedRequestPermissionResult: Bool = true
      - var stubbedRequestPermissionError: Error?
      - var stubbedStartRecordingError: Error?
      - var stubbedStopRecordingResult: String? = "Mock transcription"
      - var stubbedTranscriptionUpdates: [String] = []
      - var stubbedWaveformUpdates: [[Float]] = []
    Methods:
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
      - func stubRequestPermission(with result: Bool) {
      - func stubRequestPermissionError(with error: Error) {
      - func stubStartRecordingError(with error: Error) {
      - func stubStopRecording(with result: String?) {
      - func stubTranscriptionUpdates(with updates: [String]) {
      - func stubWaveformUpdates(with waveforms: [[Float]]) {
      - func simulateError(_ error: Error) {
      - func simulateTranscription(_ text: String) {
      - func verifyRequestPermission(called times: Int = 1) {
      - func verifyStartRecording(called times: Int = 1) {
      - func verifyStopRecording(called times: Int = 1) {
      - override func reset() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockGoalService.swift

---
Classes:
  Class: MockGoalService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var shouldThrowError = false
      - var errorToThrow: Error = AppError.serviceError("Mock goal service error")
      - private var goals: [UUID: ServiceGoal] = [:]
      - private var userGoals: [UUID: Set<UUID>] = [:] // User ID to Goal IDs mapping
      - var stubbedGoal: ServiceGoal?
      - var stubbedGoals: [ServiceGoal] = []
      - var stubbedCompletionStatus: Bool = false
    Methods:
      - func createGoal(_ goalData: GoalCreationData, for user: User) async throws -> ServiceGoal {
      - func updateGoal(_ goal: ServiceGoal, updates: GoalUpdate) async throws {
      - func deleteGoal(_ goal: ServiceGoal) async throws {
      - func getActiveGoals(for user: User) async throws -> [ServiceGoal] {
      - func trackProgress(for goal: ServiceGoal, value: Double) async throws {
      - func checkGoalCompletion(_ goal: ServiceGoal) async -> Bool {
      - func stubGoal(_ goal: ServiceGoal) {
      - func stubActiveGoals(_ goals: [ServiceGoal]) {
      - func stubCompletionStatus(_ isCompleted: Bool) {
      - func getGoal(byId id: UUID) -> ServiceGoal? {
      - func verifyGoalCreated(type: GoalType, target: Double) {
      - func verifyProgressTracked(goalId: UUID, value: Double) {
      - func resetAllGoals() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockHealthKitManager.swift

---
Classes:
  Class: MockHealthKitManager
    Properties:
      - var authorizationStatus: HealthKitManager.AuthorizationStatus = .authorized
      - private(set) var refreshCalled = false
      - private(set) var requestAuthCalled = false
      - var simulateDelay: TimeInterval = 0
      - var callCount = 0
      - var shouldFailAfterCalls: Int? = nil
      - var activityResult: Result<ActivityMetrics, Error> = .success(ActivityMetrics())
      - var heartResult: Result<HeartHealthMetrics, Error> = .success(HeartHealthMetrics())
      - var bodyResult: Result<BodyMetrics, Error> = .success(BodyMetrics())
      - var sleepResult: Result<SleepAnalysis.SleepSession?, Error> = .success(nil)
      - private(set) var fetchActivityCallCount = 0
      - private(set) var fetchHeartCallCount = 0
      - private(set) var fetchBodyCallCount = 0
      - private(set) var fetchSleepCallCount = 0
    Methods:
      - func refreshAuthorizationStatus() {
      - func requestAuthorization() async throws {
      - func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
      - func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
      - func fetchLatestBodyMetrics() async throws -> BodyMetrics {
      - func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
      - func reset() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockHealthKitPrefillProvider.swift

---
Classes:
  Class: Mutex
    Properties:
      - private let lock = NSLock()
      - private var _value: T
      - var value: T {
  Class: MockHealthKitPrefillProvider
    Properties:
      - private let _result = Mutex<Result<(bed: Date, wake: Date)?, Error>>(.success(nil))
      - var result: Result<(bed: Date, wake: Date)?, Error> {
    Methods:
      - func fetchTypicalSleepWindow() async throws -> (bed: Date, wake: Date)? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockHealthKitService.swift

---
Classes:
  Class: MockHealthKitService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var mockContext = HealthContext(
 lastNightSleepDurationHours: nil, sleepQuality: nil, currentWeatherCondition: nil, currentTemperatureCelsius: nil, yesterdayEnergyLevel: nil, currentHeartRate: nil, hrv: nil, steps: nil
      - var recoveryResult = RecoveryScore(score: 0, components: [])
      - var performanceResult = PerformanceInsight(summary: "", trend: .steady, keyMetric: "", value: 0)
    Methods:
      - func getCurrentContext() async throws -> HealthContext {
      - func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
      - func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockLLMOrchestrator.swift

---
Classes:
  Class: MockLLMOrchestrator
    Properties:
      - var mockResponse: LLMResponse?
      - var shouldThrowError = false
      - var mockError: Error = LLMError.invalidResponse("Mock error")
    Methods:
      - override func complete(_ request: LLMRequest) async throws -> LLMResponse {
      - override func stream(prompt request: LLMRequest) async throws -> AsyncThrowingStream<LLMStreamChunk, Error> {
  Class: MockAPIKeyManager
    Properties:
      - private var keys: [String: String] = [:]
    Methods:
      - func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
      - func getAPIKey(forProvider provider: AIProvider) -> String? {
      - func deleteAPIKey(forProvider provider: AIProvider) throws {
      - func getAPIKey(for provider: String) async -> String? {
      - func saveAPIKey(_ apiKey: String, for provider: String) async throws {
      - func deleteAPIKey(for provider: String) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockLLMProvider.swift

---
Classes:
  Class: MockLLMProvider
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - let identifier: LLMProviderIdentifier = LLMProviderIdentifier(name: "MockProvider", version: "1.0")
      - let capabilities: LLMCapabilities = LLMCapabilities(
 maxContextTokens: 100_000, supportsJSON: true, supportsStreaming: true, supportsSystemPrompt: true, supportsFunctionCalling: true, supportsVision: true
      - let costPerKToken: (input: Double, output: Double) = (input: 0.01, output: 0.03)
      - var stubbedCompleteResult: LLMResponse = LLMResponse(
 content: "Mock response", model: "mock-model", usage: LLMResponse.TokenUsage(promptTokens: 100, completionTokens: 50), finishReason: .stop, metadata: [:]
      - var stubbedCompleteError: Error?
      - var stubbedStreamChunks: [LLMStreamChunk] = []
      - var stubbedStreamError: Error?
      - var stubbedValidateAPIKeyResult: Bool = true
      - var stubbedValidateAPIKeyError: Error?
    Methods:
      - func complete(_ request: LLMRequest) async throws -> LLMResponse {
      - func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
      - func validateAPIKey(_ key: String) async throws -> Bool {
      - private func recordInvocation(_ method: String, arguments: Any...) {
      - func stubComplete(with response: LLMResponse) {
      - func stubCompleteError(with error: Error) {
      - func stubStream(with chunks: [LLMStreamChunk]) {
      - func stubStreamError(with error: Error) {
      - func stubValidateAPIKey(with result: Bool) {
      - func stubValidateAPIKeyError(with error: Error) {
      - func verifyComplete(called times: Int = 1) {
      - func verifyStream(called times: Int = 1) {
      - func verifyValidateAPIKey(called times: Int = 1) {
      - func reset() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockNetworkClient.swift

---
Classes:
  Class: MockNetworkClient
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var shouldThrowError = false
      - var errorToThrow: Error = NetworkError.networkError(NSError(domain: "MockNetworkClient", code: 1, userInfo: nil))
      - var stubbedResponses: [String: Any] = [:]
      - var stubbedData: Data?
      - var responseDelay: TimeInterval = 0
    Methods:
      - func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
      - func upload(_ data: Data, to endpoint: Endpoint) async throws {
      - func download(from endpoint: Endpoint) async throws -> Data {
      - func stubResponse<T: Encodable>(_ response: T, for path: String) throws {
      - func stubResponse<T>(_ response: T, for type: T.Type) {
      - func verifyRequest(to path: String, method: HTTPMethod) {
      - func simulateHTTPError(statusCode: Int, data: Data? = nil) {
      - func simulateTimeout() {
      - func simulateNoNetwork() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockNetworkManager.swift

---
Classes:
  Class: MockNetworkManager
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var isReachable: Bool = true
      - var currentNetworkType: NetworkType = .wifi
      - var stubbedPerformRequestResult: Any?
      - var stubbedPerformRequestError: Error?
      - var stubbedStreamingRequestChunks: [Data] = []
      - var stubbedStreamingRequestError: Error?
      - var stubbedDownloadDataResult: Data = Data()
      - var stubbedDownloadDataError: Error?
      - var stubbedUploadDataResponse: URLResponse = HTTPURLResponse(
 url: URL(string: "https://test.com")!, statusCode: 200, httpVersion: nil, headerFields: nil
      - var stubbedUploadDataError: Error?
    Methods:
      - func performRequest<T: Decodable & Sendable>(
        _ request: URLRequest,
        expecting: T.Type
    ) async throws -> T {
      - func performStreamingRequest(_ request: URLRequest) -> AsyncThrowingStream<Data, Error> {
      - func downloadData(from url: URL) async throws -> Data {
      - func uploadData(_ data: Data, to url: URL) async throws -> URLResponse {
      - func buildRequest(
        url: URL,
        method: String,
        headers: [String: String]
    ) -> URLRequest {
      - func stubRequest<T>(with result: T) {
      - func stubRequestError(with error: Error) {
      - func stubStreamingRequest(with chunks: [Data]) {
      - func stubStreamingRequestError(with error: Error) {
      - func stubDownloadData(with data: Data) {
      - func stubDownloadDataError(with error: Error) {
      - func stubUploadResponse(with response: URLResponse) {
      - func stubUploadError(with error: Error) {
      - func stubNetworkStatus(reachable: Bool, type: NetworkType) {
      - func verifyPerformRequest(called times: Int = 1) {
      - func verifyStreamingRequest(called times: Int = 1) {
      - func verifyDownloadData(called times: Int = 1) {
      - func verifyUploadData(called times: Int = 1) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockNotificationManager.swift

---
Classes:
  Class: MockNotificationManager
    Properties:
      - static let shared = MockNotificationManager()
      - var authorizationStatus: UNAuthorizationStatus = .authorized
      - var requestAuthorizationCalled = false
      - var requestAuthorizationResult: Bool = true
      - var requestAuthorizationError: Error?
      - var scheduleNotificationCalled = false
      - var scheduledNotifications: [(identifier: NotificationManager.NotificationIdentifier, title: String, body: String)] = []
      - var cancelNotificationCalled = false
      - var cancelledIdentifiers: [NotificationManager.NotificationIdentifier] = []
      - var cancelAllNotificationsCalled = false
      - var getPendingNotificationsCalled = false
      - var pendingNotifications: [UNNotificationRequest] = []
      - var updateBadgeCountCalled = false
      - var badgeCount: Int = 0
      - var getAuthorizationStatusCalled = false
      - var updatePreferencesCalled = false
      - var rescheduleWithQuietHoursCalled = false
    Methods:
      - func requestAuthorization() async throws -> Bool {
      - func scheduleNotification(
        identifier: NotificationManager.NotificationIdentifier,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        attachments: [UNNotificationAttachment] = [],
        categoryIdentifier: NotificationManager.NotificationCategory? = nil,
        userInfo: [String: Any] = [:],
        trigger: UNNotificationTrigger
    ) async throws {
      - func cancelNotification(identifier: NotificationManager.NotificationIdentifier) {
      - func cancelAllNotifications() {
      - func getPendingNotifications() async -> [UNNotificationRequest] {
      - func updateBadgeCount(_ count: Int) async {
      - func clearBadge() async {
      - func getAuthorizationStatus() async -> UNAuthorizationStatus {
      - func updatePreferences(_ preferences: NotificationPreferences) async {
      - func rescheduleWithQuietHours(_ quietHours: QuietHours) async {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockNutritionService.swift

---
Classes:
  Class: MockNutritionService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var shouldThrowError = false
      - var errorToThrow: Error = AppError.serviceError("Mock nutrition service error")
      - private var foodEntries: [UUID: FoodEntry] = [:]
      - private var waterIntakes: [String: Double] = [:] // Key: "userId-date"
      - var stubbedSummary: FoodNutritionSummary?
      - var stubbedTargets: NutritionTargets?
      - var stubbedRecentFoods: [FoodItem] = []
    Methods:
      - func saveFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
      - func deleteFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
      - nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
      - func getWaterIntake(for user: User, date: Date) async throws -> Double {
      - func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
      - func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
      - func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
      - nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
      - func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
      - private func waterIntakeKey(userId: UUID, date: Date) -> String {
      - func stubSummary(_ summary: FoodNutritionSummary) {
      - func stubTargets(_ targets: NutritionTargets) {
      - func stubRecentFoods(_ foods: [FoodItem]) {
      - func addTestFoodEntry(_ entry: FoodEntry) {
      - func verifyFoodEntrySaved(withId id: UUID) -> Bool {
      - func verifyWaterIntake(for userId: UUID, date: Date) -> Double {
      - func resetAllData() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockOnboardingService.swift

---
Classes:
  Class: MockOnboardingService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var saveProfileCalled = false
      - var saveProfileError: Error?
      - private let modelContext: ModelContext?
    Methods:
      - func saveProfile(_ profile: OnboardingProfile) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockService.swift

---
Classes:
  Class: MockService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var isConfigured: Bool = true
      - let serviceIdentifier: String
      - var stubbedConfigureError: Error?
      - var stubbedHealthCheckResult: ServiceHealth = ServiceHealth(
 status: .healthy, lastCheckTime: Date(), responseTime: 0.1, errorMessage: nil, metadata: [:]
    Methods:
      - func configure() async throws {
      - func reset() async {
      - func healthCheck() async -> ServiceHealth {
      - func stubConfigureError(with error: Error) {
      - func stubHealthCheck(with health: ServiceHealth) {
      - func stubHealthCheckStatus(_ status: ServiceHealth.Status, message: String? = nil) {
      - func verifyConfigure(called times: Int = 1) {
      - func verifyReset(called times: Int = 1) {
      - func verifyHealthCheck(called times: Int = 1) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockUserService.swift

---
Classes:
  Class: MockUserService
    Properties:
      - private let lock = NSLock()
      - private var _invocations: [String: [Any]] = [:]
      - private var _stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var invocations: [String: [Any]] {
      - var stubbedResults: [String: Any] {
      - var createUserResult: Result<User, Error> = .success(User.mock)
      - var updateProfileResult: Result<Void, Error> = .success(())
      - var getCurrentUserResult: User? = User.mock
      - static var mock: User {
    Methods:
      - func createUser(from profile: OnboardingProfile) async throws -> User {
      - func updateProfile(_ updates: ProfileUpdate) async throws {
      - func getCurrentUser() -> User? {
      - func getCurrentUserId() async -> UUID? {
      - func deleteUser(_ user: User) async throws {
      - func completeOnboarding() async throws {
      - func setCoachPersona(_ persona: CoachPersona) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockViewModel.swift

---
Classes:
  Class: MockViewModel
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - @Published var loadingState: LoadingState = .idle
      - var stubbedInitializeError: Error?
      - var stubbedRefreshError: Error?
      - var shouldDelayInitialize: Bool = false
      - var shouldDelayRefresh: Bool = false
      - var initializeDelay: TimeInterval = 0.5
      - var refreshDelay: TimeInterval = 0.5
    Methods:
      - func initialize() async {
      - func refresh() async {
      - func cleanup() {
      - func stubInitializeError(with error: Error) {
      - func stubRefreshError(with error: Error) {
      - func stubLoadingState(_ state: LoadingState) {
      - func stubDelayInitialize(for duration: TimeInterval) {
      - func stubDelayRefresh(for duration: TimeInterval) {
      - func verifyInitialize(called times: Int = 1) {
      - func verifyRefresh(called times: Int = 1) {
      - func verifyCleanup(called times: Int = 1) {
  Class: MockFormViewModel
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - @Published var loadingState: LoadingState = .idle
      - @Published var formData: T
      - @Published var isFormValid: Bool = true
      - var stubbedValidationErrors: [String: String] = [:]
      - var stubbedSubmitError: Error?
      - var shouldDelaySubmit: Bool = false
      - var submitDelay: TimeInterval = 0.5
    Methods:
      - func initialize() async {
      - func refresh() async {
      - func cleanup() {
      - func validate() -> [String: String] {
      - func submit() async throws {
      - func stubValidationErrors(_ errors: [String: String]) {
      - func stubSubmitError(with error: Error) {
      - func stubDelaySubmit(for duration: TimeInterval) {
  Class: MockListViewModel
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - @Published var loadingState: LoadingState = .idle
      - @Published var items: [Item] = []
      - @Published var hasMoreItems: Bool = true
      - @Published var searchQuery: String = ""
      - var stubbedLoadMoreError: Error?
      - var stubbedDeleteError: Error?
      - var additionalItemsToLoad: [Item] = []
    Methods:
      - func initialize() async {
      - func refresh() async {
      - func cleanup() {
      - func loadMore() async {
      - func delete(at offsets: IndexSet) async throws {
      - func stubItems(_ items: [Item]) {
      - func stubAdditionalItems(_ items: [Item]) {
      - func stubLoadMoreError(with error: Error) {
      - func stubDeleteError(with error: Error) {
      - func stubHasMoreItems(_ hasMore: Bool) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockVoiceInputManager.swift

---
Classes:
  Class: MockVoiceInputManager
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - private(set) var isRecording = false
      - private(set) var isTranscribing = false
      - private(set) var waveformBuffer: [Float] = []
      - private(set) var currentTranscription = ""
      - var onTranscription: ((String) -> Void)?
      - var onPartialTranscription: ((String) -> Void)?
      - var onWaveformUpdate: (([Float]) -> Void)?
      - var onError: ((Error) -> Void)?
      - var shouldGrantPermission = true
      - var shouldFailRecording = false
      - var shouldFailTranscription = false
      - var mockTranscriptionResult = "Mock transcription result"
      - var mockWaveformData: [Float] = [0.1, 0.3, 0.5, 0.7, 0.5, 0.3, 0.1]
      - var transcriptionDelay: TimeInterval = 0.1
      - private(set) var requestPermissionCalled = false
      - private(set) var startRecordingCalled = false
      - private(set) var stopRecordingCalled = false
      - private(set) var startStreamingCalled = false
      - private(set) var stopStreamingCalled = false
    Methods:
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
      - func startStreamingTranscription() async throws {
      - func stopStreamingTranscription() async {
      - func simulateTranscription(_ text: String) {
      - func simulatePartialTranscription(_ text: String) {
      - func simulateWaveformUpdate(_ levels: [Float]) {
      - func simulateError(_ error: Error) {
      - func reset() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockWeatherService.swift

---
Classes:
  Class: MockWeatherService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var isAvailable: Bool = true
      - private(set) var lastRequestTime: Date?
      - private(set) var requestCount: Int = 0
      - var shouldThrowError = false
      - var errorToThrow: Error = ServiceError.networkUnavailable
      - var stubbedCurrentWeather: ServiceWeatherData?
      - var stubbedForecast: WeatherForecast?
      - var cachedWeatherData: [String: ServiceWeatherData] = [:]
      - var responseDelay: TimeInterval = 0
    Methods:
      - func getCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
      - func getForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
      - func getCachedWeather(latitude: Double, longitude: Double) -> ServiceWeatherData? {
      - func stubWeather(_ weather: ServiceWeatherData, for latitude: Double, longitude: Double) {
      - func stubForecast(_ forecast: WeatherForecast, for latitude: Double, longitude: Double, days: Int) {
      - func simulateRateLimitError(retryAfter: TimeInterval? = nil) {
      - func simulateAuthenticationError(reason: String = "Invalid API key") {
      - func verifyWeatherRequested(for latitude: Double, longitude: Double) {
      - func resetCache() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockWhisperKit.swift

---
Classes:
  Class: MockWhisperKit
    Properties:
      - private let queue = DispatchQueue(label: "MockWhisperKit", attributes: .concurrent)
      - private var _transcriptionResult: [TranscriptionResult] = []
      - private var _transcriptionError: Error?
      - private var _isReady = true
      - var transcriptionResult: [TranscriptionResult] {
      - var transcriptionError: Error? {
      - var isReady: Bool {
  Class: TranscriptionResult
    Properties:
      - let text: String
      - let segments: [TranscriptionSegment]
  Class: TranscriptionSegment
    Properties:
      - let text: String
      - let start: Double
      - let end: Double
    Methods:
      - func transcribe(audioPath: String, decodeOptions: MockDecodeOptions? = nil) async throws -> [TranscriptionResult] {
      - func transcribe(audioArray: [Float], decodeOptions: MockDecodeOptions? = nil) async throws -> [TranscriptionResult] {
      - func stubTranscriptionResult(_ result: [TranscriptionResult]) {
      - func stubTranscriptionError(_ error: Error) {
      - func stubReady(_ ready: Bool) {
  Class: MockDecodeOptions
    Properties:
      - let verbose: Bool
      - let task: TranscriptionTask
      - let language: String?
      - let temperature: Float
      - let temperatureIncrementOnFallback: Float
      - let temperatureFallbackCount: Int
      - let sampleLength: Int
      - let topK: Int
      - let usePrefillPrompt: Bool
      - let usePrefillCache: Bool
      - let skipSpecialTokens: Bool
      - let withoutTimestamps: Bool
      - let wordTimestamps: Bool
      - let clipTimestamps: [Double]
      - let suppressBlank: Bool
      - let supressTokens: [Int]?
      - let compressionRatioThreshold: Float
      - let logProbThreshold: Float
      - let noSpeechThreshold: Float
  Class: TranscriptionTask

Enums:
  - TranscriptionTask
    Cases:
      - transcribe
      - translate
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockWhisperModelManager.swift

---
Classes:
  Class: MockWhisperModelManager
    Properties:
      - private var optimalModel = "base"
      - private var transcriptionResult: String?
      - private var transcriptionError: Error?
      - private var whisperReady = true
      - private var initializationError: Error?
      - private var downloadProgress: [String: Double] = [:]
      - private var isDownloading: [String: Bool] = [:]
      - @Published var availableModels: [WhisperModel] = []
      - @Published var downloadedModels: Set<String> = ["base", "tiny"]
      - @Published var activeModel: String = "base"
  Class: WhisperModel
    Properties:
      - let id: String
      - let displayName: String
      - let size: String
      - let sizeBytes: Int
      - let accuracy: String
      - let speed: String
      - let languages: String
      - let requiredMemory: UInt64
      - let huggingFaceRepo: String
    Methods:
      - func selectOptimalModel() -> String {
      - func downloadModel(_ modelId: String) async throws {
      - func deleteModel(_ modelId: String) throws {
      - func modelPath(for modelId: String) -> URL? {
      - func stubOptimalModel(_ model: String) {
      - func stubTranscription(_ text: String) {
      - func stubTranscriptionError(_ error: Error) {
      - func stubWhisperReady(_ ready: Bool) {
      - func stubInitializationError(_ error: Error) {
      - func getTranscriptionResult() -> String? {
      - func getTranscriptionError() -> Error? {
      - func isWhisperReady() -> Bool {
      - func simulatePartialTranscription(_ text: String) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockWhisperServiceWrapper.swift

---
Classes:
  Class: MockWhisperServiceWrapper
    Properties:
      - var isAvailable = CurrentValueSubject<Bool, Never>(true)
      - var isTranscribing = CurrentValueSubject<Bool, Never>(false)
      - var mockTranscript: String = ""
      - var permissionGranted: Bool = true
      - private var currentResultHandler: ((Result<String, TranscriptionError>) -> Void)?
    Methods:
      - func requestPermission(completion: @escaping (Bool) -> Void) {
      - func startTranscription(resultHandler: @escaping (Result<String, TranscriptionError>) -> Void) {
      - func stopTranscription() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/MockWorkoutService.swift

---
Classes:
  Class: MockWorkoutService
    Properties:
      - var invocations: [String: [Any]] = [:]
      - var stubbedResults: [String: Any] = [:]
      - let mockLock = NSLock()
      - var shouldThrowError = false
      - var errorToThrow: Error = AppError.serviceError("Mock workout service error")
      - var stubbedWorkout: Workout?
      - var stubbedWorkoutHistory: [Workout] = []
      - var stubbedWorkoutTemplates: [WorkoutTemplate] = []
      - private var activeWorkouts: Set<UUID> = []
      - private var pausedWorkouts: Set<UUID> = []
    Methods:
      - func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
      - func pauseWorkout(_ workout: Workout) async throws {
      - func resumeWorkout(_ workout: Workout) async throws {
      - func endWorkout(_ workout: Workout) async throws {
      - func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
      - func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
      - func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
      - func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
      - private func setupDefaultStubs() {
      - private func calculateMockCalories(_ workout: Workout) -> Int {
      - func stubWorkout(_ workout: Workout) {
      - func stubWorkoutHistory(_ history: [Workout]) {
      - func stubTemplates(_ templates: [WorkoutTemplate]) {
      - func verifyWorkoutStarted(type: WorkoutType) {
      - func verifyExerciseLogged(named exerciseName: String) {
      - func isWorkoutActive(_ workoutId: UUID) -> Bool {
      - func isWorkoutPaused(_ workoutId: UUID) -> Bool {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/TestableVoiceInputManager.swift

---
Classes:
  Class: TestableVoiceInputManager
    Properties:
      - private(set) var isRecording = false
      - private(set) var isTranscribing = false
      - private(set) var waveformBuffer: [Float] = []
      - private(set) var currentTranscription = ""
      - var onTranscription: ((String) -> Void)?
      - var onPartialTranscription: ((String) -> Void)?
      - var onWaveformUpdate: (([Float]) -> Void)?
      - var onError: ((Error) -> Void)?
      - private let modelManager: MockWhisperModelManager
      - private let audioSession: MockAVAudioSession
      - private var mockWhisper: MockWhisperKit?
      - private var waveformTimer: Timer?
      - private var recordingURL: URL?
    Methods:
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
      - func startStreamingTranscription() async throws {
      - func stopStreamingTranscription() async {
      - private func initializeWhisper() async {
      - private func prepareRecorder() async throws {
      - private func transcribeAudio() async throws -> String {
      - private func startWaveformTimer() {
      - private func stopWaveformTimer() {
      - private func postProcessTranscription(_ text: String) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Mocks/VoicePerformanceMetrics.swift

---
Classes:
  Class: VoicePerformanceMetrics
    Methods:
      - static func measureTranscriptionLatency<T>(
        operation: () async throws -> T
    ) async rethrows -> (result: T, latency: TimeInterval) {
      - static func measureMemoryUsage<T>(
        operation: () throws -> T
    ) rethrows -> (result: T, memoryDelta: Int64) {
      - private static func getMemoryUsage() -> Int64 {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/CoachEngineTests.swift

---
Classes:
  Class: CoachEngineTests
    Properties:
      - var sut: CoachEngine!
      - var mockAIService: MockAIAPIService!
      - var modelContext: ModelContext!
      - var testUser: User!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_processUserMessage_withWaterLogCommand_shouldUseLocalParser() async throws {
      - @MainActor
    func test_processUserMessage_withHelpCommand_shouldProvideHelpResponse() async throws {
      - @MainActor
    func test_clearConversation_shouldResetState() async throws {
      - @MainActor
    func test_regenerateLastResponse_withNoConversation_shouldSetError() async throws {
      - @MainActor
    func test_localCommandProcessing_shouldCompleteQuickly() async throws {
      - @MainActor
    func test_parseAndLogNutritionDirect_basicFood_success() async throws {
      - @MainActor
    func test_parseAndLogNutritionDirect_emptyInput_throwsError() async throws {
      - @MainActor
    func test_generateEducationalContentDirect_basicTopic_success() async throws {
      - @MainActor
    func test_generateEducationalContentDirect_exerciseTopic_classifiesCorrectly() async throws {
      - @MainActor
    private func createTestableCoachEngine() -> CoachEngine {
  Class: FunctionError

Enums:
  - FunctionError
    Cases:
      - unknownFunction
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/ConversationManagerPerformanceTests.swift

---
Classes:
  Class: ConversationManagerPerformanceTests
    Properties:
      - var sut: ConversationManager!
      - var modelContainer: ModelContainer!
      - var modelContext: ModelContext!
      - var testUser: User!
      - var testConversationId: UUID!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_getRecentMessages_withLargeDataset_shouldMeetStrictPerformanceTargets() async throws {
      - func test_getConversationStats_withLargeConversation_shouldPerformWell() async throws {
      - func test_pruneOldConversations_withManyConversations_shouldPerformWell() async throws {
      - func test_queryPerformance_comparisonWithBenchmarks() async throws {
      - func test_memoryUsage_withLargeMessages_shouldNotExceedLimits() async throws {
      - func test_concurrentAccess_shouldHandleMultipleOperations() async throws {
      - func test_saveMessage_performance_shouldCompleteQuickly() async throws {
      - func measureAsync<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> (result: T, time: TimeInterval) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/ConversationManagerPersistenceTests.swift

---
Classes:
  Class: ConversationManagerPersistenceTests
    Properties:
      - var sut: ConversationManager!
      - var modelContainer: ModelContainer!
      - var modelContext: ModelContext!
      - var testUser: User!
      - var testConversationId: UUID!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_saveUserMessage_givenValidInput_shouldPersistMessage() async throws {
      - func test_saveUserMessage_withLargeContent_shouldPersistCorrectly() async throws {
      - func test_createAssistantMessage_withBasicContent_shouldPersistCorrectly() async throws {
      - func test_createAssistantMessage_withFunctionCall_shouldStoreFunctionCallData() async throws {
      - func test_createAssistantMessage_withLocalCommand_shouldMarkAsLocalCommand() async throws {
      - func test_createAssistantMessage_withError_shouldMarkAsUnhelpful() async throws {
      - func test_recordAIMetadata_givenValidMessage_shouldUpdateMetadata() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/ConversationManagerTests.swift

---
Classes:
  Class: ConversationManagerTests
    Properties:
      - var sut: ConversationManager!
      - var modelContainer: ModelContainer!
      - var modelContext: ModelContext!
      - var testUser: User!
      - var testConversationId: UUID!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_getRecentMessages_withNoMessages_shouldReturnEmptyArray() async throws {
      - func test_getRecentMessages_withMultipleMessages_shouldReturnInChronologicalOrder() async throws {
      - func test_deleteConversation_shouldRemoveAllMessages() async throws {
      - func test_getConversationIds_withNoConversations_shouldReturnEmpty() async throws {
      - func test_getConversationStats_withNoMessages_shouldReturnZeroStats() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/FunctionCallDispatcherTests.swift

---
Classes:
  Class: FunctionCallDispatcherTests
    Properties:
      - var dispatcher: FunctionCallDispatcher!
      - var testUser: User!
      - var testContext: FunctionContext!
      - var modelContainer: ModelContainer!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testGeneratePersonalizedWorkoutPlan() async throws {
      - func testAdaptPlanBasedOnFeedback() async throws {
      - func testAnalyzePerformanceTrends() async throws {
      - func testAssistGoalSettingOrRefinement() async throws {
      - func testUnknownFunctionError() async throws {
      - func testRemovedFunctionsThrowError() async throws {
      - func test_phase3_functionRemovalSuccess() async throws {
      - func test_phase3_codeReductionMetrics() async throws {
      - func testFunctionExecutionPerformance() async throws {
      - func testMetricsTracking() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/LocalCommandParserTests.swift

---
Classes:
  Class: LocalCommandParserTests
    Properties:
      - var sut: LocalCommandParser!
    Methods:
      - @MainActor
    func test_parseWaterCommands() {
      - @MainActor
    func test_parseNavigationCommands() {
      - @MainActor
    func test_parseQuickLogCommands() {
      - @MainActor
    func test_unrecognizedCommand_shouldReturnNone() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/MessageClassificationTests.swift

---
Classes:
  Class: MessageClassificationTests
    Properties:
      - private var modelContext: ModelContext!
      - private var coachEngine: CoachEngine!
      - private var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_classifyMessage_detectsShortCommands() async {
      - func test_classifyMessage_detectsCommandStarters() async {
      - func test_classifyMessage_detectsNutritionCommands() async {
      - func test_classifyMessage_detectsPatternBasedCommands() async {
      - func test_classifyMessage_detectsConversations() async {
      - func test_classifyMessage_longMessagesAreConversations() async {
      - func test_classifyMessage_edgeCases() async {
      - func test_messageType_contextLimits() {
      - func test_processUserMessage_storesCorrectClassification() async throws {
      - func test_processUserMessage_usesOptimizedHistoryLimits() async throws {
      - func test_classifyMessage_performance() async {
      - func test_classifyMessage_accuracyMetrics() async {
      - private func classifyTestMessage(_ text: String) async -> MessageType {
      - private func getMessageCount() async -> Int {
      - private func getAllMessages() async throws -> [CoachMessage] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/PersonaEnginePerformanceTests.swift

---
Classes:
  Class: PersonaEnginePerformanceTests
    Properties:
      - private var sut: PersonaEngine!
      - private var healthContext: HealthContextSnapshot!
    Methods:
      - override func setUpWithError() throws {
      - override func tearDownWithError() throws {
      - func test_promptGeneration_achievesTargetTokenReduction() throws {
      - func test_allPersonaModes_maintainTokenEfficiency() throws {
      - func test_contextAdaptation_maintainsTokenEfficiency() throws {
      - func test_promptGeneration_performanceImprovement() throws {
      - func test_caching_improvesPerformance() throws {
      - func test_legacyMethod_maintainsCompatibility() throws {
      - func test_promptTooLong_throwsError() throws {
      - private func createTestHealthContext() -> HealthContextSnapshot {
      - private func createComplexHealthContext() -> HealthContextSnapshot {
      - private func createMassiveHealthContext() -> HealthContextSnapshot {
      - private func createMinimalTestFunctions() -> [AIFunctionDefinition] {
      - private func createManyTestFunctions(count: Int) -> [AIFunctionDefinition] {
      - private func createMassiveConversationHistory(count: Int) -> [AIChatMessage] {
      - private func createLegacyUserProfile() -> UserProfileJsonBlob {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/PersonaEngineTests.swift

---
Classes:
  Class: PersonaEngineTests
    Properties:
      - var sut: PersonaEngine!
      - var modelContext: ModelContext!
      - var testUser: User!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_buildSystemPrompt_withValidInputs_shouldGenerateCompletePrompt() throws {
      - @MainActor
    func test_buildSystemPrompt_withJSONInjection_shouldEscapeSpecialCharacters() throws {
      - @MainActor
    func test_buildSystemPrompt_withLongConversationHistory_shouldLimitToLast20Messages() throws {
      - @MainActor
    func test_buildSystemPrompt_withTokenLengthValidation_shouldThrowForLongPrompts() throws {
      - @MainActor
    func test_adjustPersonaForContext_withLowEnergy_shouldIncreaseEmpathy() {
      - @MainActor
    func test_adjustPersonaForContext_withHighStress_shouldReduceProvocative() {
      - @MainActor
    func test_adjustPersonaForContext_withEveningTime_shouldBeCalmAndLessPlayful() {
      - @MainActor
    func test_adjustPersonaForContext_withPoorSleep_shouldBeMoreUnderstanding() {
      - @MainActor
    func test_adjustPersonaForContext_withRecoveryNeeds_shouldBeMoreSupportive() {
      - @MainActor
    func test_adjustPersonaForContext_withWorkoutStreak_shouldBeMoreChallenging() {
      - @MainActor
    func test_adjustPersonaForContext_withDetrainingStatus_shouldBeVeryEncouraging() {
      - @MainActor
    func test_adjustPersonaForContext_withMultipleFactors_shouldApplyAllAdjustments() {
      - @MainActor
    func test_buildSystemPrompt_withFunctionRegistry_shouldIncludeAllFunctions() throws {
      - @MainActor
    func test_buildSystemPrompt_withHealthContext_shouldIncludeRelevantMetrics() throws {
      - @MainActor
    func test_buildSystemPrompt_withConversationHistory_shouldMaintainContext() throws {
      - @MainActor
    func test_buildSystemPrompt_performance_shouldCompleteQuickly() throws {
      - @MainActor
    func test_adjustPersonaForContext_performance_shouldCompleteQuickly() {
      - @MainActor
    func test_buildSystemPrompt_withInvalidTimezone_shouldUseAsIs() throws {
      - @MainActor
    func test_adjustPersonaForContext_withNilHealthData_shouldReturnOriginalProfile() {
      - private func createTestUserProfile() -> PersonaProfile {
      - private func createTestUserProfileWithSpecialChars() -> PersonaProfile {
      - private func createTestUserProfileWithInvalidTimezone() -> PersonaProfile {
      - private func createTestHealthContext() -> HealthContextSnapshot {
      - private func createTestHealthContextWithLowEnergy() -> HealthContextSnapshot {
      - private func createTestHealthContextWithHighStress() -> HealthContextSnapshot {
      - private func createTestHealthContextWithEveningTime() -> HealthContextSnapshot {
      - private func createTestHealthContextWithPoorSleep() -> HealthContextSnapshot {
      - private func createTestHealthContextWithRecoveryNeeds() -> HealthContextSnapshot {
      - private func createTestHealthContextWithWorkoutStreak() -> HealthContextSnapshot {
      - private func createTestHealthContextWithDetraining() -> HealthContextSnapshot {
      - private func createTestHealthContextWithMultipleFactors() -> HealthContextSnapshot {
      - private func createTestHealthContextWithSpecificMetrics() -> HealthContextSnapshot {
      - private func createTestHealthContextWithNilData() -> HealthContextSnapshot {
      - private func createTestConversationHistory() -> [ChatMessage] {
      - private func createTestFunctions() -> [AIFunctionDefinition] {
      - private func createLongConversationHistory(count: Int) -> [ChatMessage] {
      - private func createMassiveHealthContext() -> HealthContextSnapshot {
      - private func createManyTestFunctions(count: Int) -> [AIFunctionDefinition] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/Phase2ValidationTests.swift

---
Classes:
  Class: Phase2ValidationTests
    Properties:
      - var modelContainer: ModelContainer!
      - var modelContext: ModelContext!
      - var testUser: User!
      - var conversationManager: ConversationManager!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_phase2_predicateOptimization_works() async throws {
      - func test_phase2_userIDFiltering_correctness() async throws {
      - func test_phase2_indexPerformance_withLargeDataset() async throws {
      - func test_phase2_conversationStats_optimization() async throws {
      - func test_phase2_summaryReport() {
      - static func *(left: String, right: Int) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Chat/ChatCoordinatorTests.swift

---
Classes:
  Class: ChatCoordinatorTests
    Properties:
      - var coordinator: ChatCoordinator!
    Methods:
      - override func setUp() async throws {
      - func test_navigateToPushesDestination() {
      - func test_showSheetSetsActiveSheet() {
      - func test_scrollToStoresMessageId() {
      - func test_dismissClearsPresentation() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Chat/ChatSuggestionsEngineTests.swift

---
Classes:
  Class: ChatSuggestionsEngineTests
    Properties:
      - var user: User!
      - var engine: ChatSuggestionsEngine!
    Methods:
      - override func setUp() async throws {
      - func test_generateSuggestions_withoutHistory_returnsDefaultPrompts() async {
      - func test_generateSuggestions_workoutMessage_includesWorkoutSuggestion() async {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Chat/ChatViewModelTests.swift

---
Classes:
  Class: ChatViewModelTests
    Properties:
      - var sut: ChatViewModel?
      - var mockAIService: MockAIService?
      - var mockCoachEngine: MockCoachEngine?
      - var mockVoiceManager: MockVoiceInputManager?
      - var mockCoordinator: ChatCoordinator?
      - var modelContext: ModelContext?
      - var testUser: User?
    Methods:
      - override func setUpWithError() throws {
      - override func tearDownWithError() throws {
      - @MainActor
    private func setupTest() throws {
      - @MainActor
    private func createSUT() {
      - @MainActor
    private func setupVoiceManagerCallbacks() {
      - @MainActor
    private func setError(_ error: Error) {
      - @MainActor
    private func cleanupSUT() {
      - @MainActor
    func test_loadOrCreateSession_withNoExistingSession_shouldCreateNewSession() async {
      - @MainActor
    func test_loadOrCreateSession_withExistingActiveSession_shouldLoadExistingSession() async {
      - @MainActor
    func test_voiceRecording_initialState_shouldBeCorrect() {
      - @MainActor
    func test_toggleVoiceRecording_whenNotRecording_shouldStartRecording() async {
      - @MainActor
    func test_toggleVoiceRecording_whenRecording_shouldStopRecording() async {
      - @MainActor
    func test_toggleVoiceRecording_withPermissionDenied_shouldSetError() async {
      - @MainActor
    func test_toggleVoiceRecording_withRecordingFailure_shouldSetError() async {
      - @MainActor
    func test_voiceTranscription_callback_shouldUpdateComposerText() async {
      - @MainActor
    func test_voiceWaveformUpdate_callback_shouldUpdateWaveformData() async {
      - @MainActor
    func test_voiceError_callback_shouldSetErrorStateAndStopRecording() async {
      - @MainActor
    func test_voiceRecording_withTranscriptionFailure_shouldHandleGracefully() async {
      - @MainActor
    func test_sendMessage_withValidText_shouldCreateUserMessage() async {
      - @MainActor
    func test_sendMessage_withEmptyText_shouldNotCreateMessage() async {
      - @MainActor
    func test_sendMessage_withNoSession_shouldNotCreateMessage() async {
      - @MainActor
    func test_sendMessage_shouldGenerateAIResponse() async {
      - @MainActor
    func test_deleteMessage_shouldRemoveMessageFromList() async {
      - @MainActor
    func test_copyMessage_shouldCopyToClipboard() async {
      - @MainActor
    func test_regenerateResponse_withValidAssistantMessage_shouldRegenerateResponse() async {
      - @MainActor
    func test_regenerateResponse_withUserMessage_shouldNotRegenerate() async {
      - @MainActor
    func test_aiStreaming_shouldUpdateStreamingState() async {
      - @MainActor
    func test_aiStreaming_shouldUpdateMessageContentIncrementally() async {
      - @MainActor
    func test_searchMessages_withMatchingQuery_shouldReturnFilteredResults() async {
      - @MainActor
    func test_searchMessages_withNoMatches_shouldReturnEmptyArray() async {
      - @MainActor
    func test_exportChat_withActiveSession_shouldReturnURL() async throws {
      - @MainActor
    func test_exportChat_withNoActiveSession_shouldThrowError() async {
      - @MainActor
    func test_selectSuggestion_withAutoSend_shouldSendMessage() async {
      - @MainActor
    func test_selectSuggestion_withoutAutoSend_shouldOnlySetComposerText() {
      - @MainActor
    func test_scheduleWorkout_fromMessage_shouldLogAction() async {
      - @MainActor
    func test_scheduleWorkout_fromMessageWithoutWorkoutData_shouldCreateGenericWorkout() async {
      - @MainActor
    func test_setReminder_fromMessage_shouldLogAction() async {
      - @MainActor
    func test_setReminder_fromMessageWithoutReminderData_shouldCreateGenericReminder() async {
      - @MainActor
    func test_initialState_shouldBeCorrect() {
      - @MainActor
    func test_composerState_shouldBeManaged() {
      - @MainActor
    func test_performance_largeMessageList_shouldHandleEfficiently() async {
      - @MainActor
    func test_performance_searchLargeMessageSet_shouldBeEfficient() async {
      - @MainActor
    func test_waveformVisualization_dataFlow_shouldWork() async {
      - @MainActor
    func test_waveformVisualization_realTimeUpdates_shouldAnimate() async {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Dashboard/DashboardViewModelTests.swift

---
Classes:
  Class: DashboardViewModelTests
    Properties:
      - var container: ModelContainer!
      - var modelContext: ModelContext!
      - var mockHealthKitService: MockHealthKitService!
      - var mockAICoachService: MockAICoachService!
      - var mockNutritionService: MockDashboardNutritionService!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - private func createTestUser() -> User {
      - private func createSUT(with user: User) -> DashboardViewModel {
      - private func waitForLoadingToComplete(_ viewModel: DashboardViewModel, timeout: TimeInterval = 2.0) async throws {
      - private func forceGreetingRefresh(_ viewModel: DashboardViewModel) {
      - func test_initialState_defaults() {
      - func test_loadDashboardData_loadsDashboardData() async throws {
      - func test_onAppear_triggersDataLoad() async throws {
      - func test_aiFailure_usesFallbackGreeting() async throws {
  Class: FailingAI
    Methods:
      - func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
  Class: TestError
    Methods:
      - func test_logEnergyLevel_createsNewLog() async throws {
      - func test_logEnergyLevel_updatesExistingLog() async throws {
      - func test_loadNutritionData_withProfile_fetchesTargets() async throws {
      - func test_loadHealthInsights_errorDoesNotCrash() async throws {
  Class: ErrorHealthService
    Methods:
      - func getCurrentContext() async throws -> HealthContext {
  Class: TestError
    Methods:
      - func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
      - func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Notifications/EngagementEngineTests.swift

---
Classes:
  Class: EngagementEngineTests
    Properties:
      - var sut: EngagementEngine!
      - var container: ModelContainer!
      - var modelContext: ModelContext!
      - var mockCoachEngine: MockCoachEngine!
      - var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_detectLapsedUsers_withInactiveUser_shouldReturnUser() async throws {
      - func test_detectLapsedUsers_withActiveUser_shouldNotReturn() async throws {
      - func test_sendReEngagementNotification_shouldGeneratePersonalizedMessage() async {
      - func test_sendReEngagementNotification_withGiveMeSpace_shouldNotSend() async {
      - func test_analyzeEngagementMetrics_shouldCalculateCorrectly() async throws {
      - func test_updateUserActivity_shouldUpdateLastActiveDate() {
      - func test_scheduleBackgroundTasks_shouldNotCrash() {
  Class: MockCoachEngine
    Properties:
      - var didCallGenerateReEngagementMessage = false
      - var stubReEngagementMessage = "Default message"
      - var didCallGenerateMorningGreeting = false
      - var stubMorningGreeting = "Good morning!"
      - var didCallGenerateWorkoutReminder = false
      - var stubWorkoutReminder = ("Workout time!", "Let's get moving!")
      - var didCallGenerateMealReminder = false
      - var stubMealReminder = ("Meal time!", "Don't forget to eat!")
    Methods:
      - override func generateReEngagementMessage(_ context: ReEngagementContext) async throws -> String {
      - override func generateMorningGreeting(for user: User) async throws -> String {
      - override func generateWorkoutReminder(workoutType: String, userName: String) async throws -> (title: String, body: String) {
      - override func generateMealReminder(mealType: MealType, userName: String) async throws -> (title: String, body: String) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Notifications/NotificationManagerTests.swift

---
Classes:
  Class: NotificationManagerTests
    Properties:
      - var sut: NotificationManager!
    Methods:
      - override func setUp() async throws {
      - func test_requestAuthorization_shouldRequestCorrectOptions() async throws {
      - func test_scheduleNotification_withValidData_shouldSucceed() async throws {
      - func test_cancelNotification_shouldRemoveFromPending() async {
      - func test_createAttachment_withValidImageData_shouldReturnAttachment() throws {
      - func test_updateBadgeCount_shouldSetCorrectValue() async {
      - func test_clearBadge_shouldSetToZero() async {
      - func test_notificationCategories_shouldBeRegistered() async {
      - func test_notificationIdentifier_stringValues_shouldBeUnique() {
      - func test_scheduleNotification_withCategory_shouldSetCorrectInterruptionLevel() async throws {
      - func test_cancelAllNotifications_shouldClearAllPending() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Onboarding/ConversationViewModelTests.swift

---
Classes:
  Class: ConversationViewModelTests
    Properties:
      - var viewModel: ConversationViewModel!
      - var mockFlowManager: MockConversationFlowManager!
      - var mockPersistence: MockConversationPersistence!
      - var mockAnalytics: MockConversationAnalytics!
      - var testUserId: UUID!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_start_withNoExistingSession_startsNewSession() async {
      - func test_start_withExistingSession_resumesSession() async {
      - func test_start_multipleCalls_onlyStartsOnce() async {
      - func test_start_withPersistenceError_setsError() async {
      - func test_submitResponse_withCurrentNode_submitsToFlowManager() async {
      - func test_submitResponse_withNoCurrentNode_doesNothing() async {
      - func test_submitResponse_withError_setsError() async {
      - func test_submitResponse_completesConversation_callsCompletion() async {
      - func test_skipCurrentQuestion_withCurrentNode_skipsInFlowManager() async {
      - func test_progressTracking_updatesCorrectly() {
  Class: MockConversationFlowManager
    Properties:
      - var startNewSessionCallCount = 0
      - var resumeSessionCallCount = 0
      - var submitResponseCallCount = 0
      - var skipCurrentNodeCallCount = 0
      - var lastStartedUserId: UUID?
      - var lastResumedSession: ConversationSession?
      - var lastSubmittedResponse: ResponseValue?
      - var shouldThrowError = false
      - var mockInsights = PersonalityInsights.mock
    Methods:
      - override func startNewSession(userId: UUID) async {
      - override func resumeSession(_ session: ConversationSession) async {
      - override func submitResponse(_ response: ResponseValue) async throws {
      - override func skipCurrentNode() async {
      - override func generateInsights() -> PersonalityInsights {
      - func simulateProgressUpdate(_ progress: Double) {
  Class: MockConversationPersistence
    Properties:
      - var mockSession: ConversationSession?
      - var shouldThrowError = false
    Methods:
      - override func fetchActiveSession(for userId: UUID) throws -> ConversationSession? {
  Class: MockConversationAnalytics
    Properties:
      - var trackedEvents: [ConversationEvent] = []
      - static var mock: ConversationNode {
      - static var mock: PersonalityInsights {
    Methods:
      - override func track(_ event: ConversationEvent) async {
      - public static func == (lhs: ResponseValue, rhs: ResponseValue) -> Bool {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Onboarding/OnboardingFlowViewTests.swift

---
Classes:
  Class: OnboardingFlowViewTests
    Properties:
      - var modelContainer: ModelContainer!
      - var context: ModelContext!
      - var mockAIService: MockAIService!
      - var mockOnboardingService: MockOnboardingService!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_onboardingFlowView_initialization_shouldCreateWithCorrectDependencies() {
      - func test_onboardingFlowView_withCompletion_shouldStoreCallback() {
      - func test_progressBar_shouldShowForCorrectScreens() {
      - func test_progressBar_shouldHideForCorrectScreens() {
      - func test_progressBar_calculatesCorrectProgress() {
      - func test_privacyFooter_shouldShowForCorrectScreens() {
      - func test_privacyFooter_shouldHideForCorrectScreens() {
      - func test_screenTransition_shouldUseCorrectAnimation() {
      - func test_errorAlert_shouldDisplayWhenErrorExists() {
      - func test_loadingOverlay_shouldDisplayWhenLoading() {
      - func test_onboardingFlow_shouldHaveAccessibilityIdentifier() {
      - func test_progressBar_shouldHaveAccessibilityValue() {
      - func test_allScreens_shouldBeRepresented() {
      - func test_onboardingFlow_withRealViewModel_shouldInitializeCorrectly() async throws {
      - func test_onboardingFlow_completionCallback_shouldBeInvoked() async throws {
      - private func shouldShowProgressBar(for screen: OnboardingScreen) -> Bool {
      - private func shouldShowPrivacyFooter(for screen: OnboardingScreen) -> Bool {
  Class: StepProgressBarTests
    Methods:
      - func test_progressBar_segmentCount_shouldBeSeven() {
      - func test_progressBar_segmentColor_shouldBeCorrect() {
      - func test_progressBar_accessibility_shouldProvideCorrectValue() {
  Class: PrivacyFooterTests
    Methods:
      - func test_privacyFooter_shouldHaveCorrectText() {
      - func test_privacyFooter_shouldHaveAccessibilityIdentifier() {
      - func test_privacyFooter_shouldLogWhenTapped() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Onboarding/OnboardingIntegrationTests.swift

---
Classes:
  Class: OnboardingAppStateIntegrationTests
    Properties:
      - var container: ModelContainer!
      - var context: ModelContext!
      - var appState: AppState!
      - var onboardingService: OnboardingService!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_appState_withNoUser_shouldShowWelcome() async throws {
      - @MainActor
    func test_appState_withUserButNoProfile_shouldShowOnboarding() async throws {
      - @MainActor
    func test_appState_withCompletedOnboarding_shouldShowDashboard() async throws {
  Class: OnboardingServiceIntegrationTests
    Properties:
      - var container: ModelContainer!
      - var context: ModelContext!
      - var appState: AppState!
      - var onboardingService: OnboardingService!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_onboardingService_saveProfile_shouldValidateRequiredFields() async throws {
      - @MainActor
    func test_onboardingService_saveProfile_shouldLinkToUser() async throws {
  Class: OnboardingJSONStructureTests
    Methods:
      - func test_userProfileJsonBlob_shouldMatchSystemPromptRequirements() throws {
      - private func createTestProfileBlob() -> UserProfileJsonBlob {
      - private func encodeProfileToJSON(_ profileBlob: UserProfileJsonBlob) throws -> [String: Any] {
      - private func verifyRequiredFields(in jsonObject: [String: Any]) {
      - private func verifyNestedStructure(in jsonObject: [String: Any]) {
  Class: OnboardingFlowIntegrationTests
    Properties:
      - var container: ModelContainer!
      - var context: ModelContext!
      - var appState: AppState!
      - var onboardingService: OnboardingService!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_completeOnboardingFlow_shouldTransitionToDashboard() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Onboarding/OnboardingModelsTests.swift

---
Classes:
  Class: OnboardingModelsTests
    Methods:
      - func test_blend_isValid_whenSumEqualsOne_shouldReturnTrue() {
      - func test_blend_isValid_whenSumNotEqual_shouldReturnFalse() {
      - func test_blend_normalize_whenValuesDontSumToOne_shouldNormalize() {
      - func test_userProfileJsonBlobEncoding_shouldUseSnakeCaseKeys() throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Onboarding/OnboardingServiceTests.swift

---
Classes:
  Class: OnboardingServiceTests
    Properties:
      - var modelContainer: ModelContainer!
      - var context: ModelContext!
      - var sut: OnboardingService!
      - var testUser: User!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_saveProfile_givenValidProfile_shouldPersistSuccessfully() async throws {
      - @MainActor
    func test_saveProfile_givenNoUser_shouldThrowError() async throws {
      - @MainActor
    func test_saveProfile_givenInvalidJSON_shouldThrowError() async {
      - @MainActor
    func test_saveProfile_givenMissingRequiredField_shouldThrowError() async throws {
      - @MainActor
    func test_saveProfile_givenMultipleUsers_shouldLinkToMostRecent() async throws {
      - func test_onboardingError_localizedDescriptions() {
      - private func createValidProfileData() -> Data {
  Class: OnboardingServiceValidationTests
    Properties:
      - var modelContainer: ModelContainer!
      - var context: ModelContext!
      - var sut: OnboardingService!
      - var testUser: User!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_validateProfileStructure_givenValidProfile_shouldPass() async throws {
      - @MainActor
    func test_validateProfileStructure_givenAllRequiredFields_shouldPass() async throws {
      - @MainActor
    func test_saveProfile_givenEmptyData_shouldThrowError() async {
      - private func createValidProfileData() -> Data {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Onboarding/OnboardingViewModelTests.swift

---
Classes:
  Class: OnboardingViewModelTests
    Properties:
      - var modelContainer: ModelContainer!
      - var context: ModelContext!
      - var mockAIService: MockAIService!
      - var mockOnboardingService: MockOnboardingService!
      - var mockHealthProvider: MockHealthKitPrefillProvider!
      - var sut: OnboardingViewModel!
    Methods:
      - @MainActor
    override func setUp() async throws {
      - @MainActor
    override func tearDown() async throws {
      - @MainActor
    func test_navigationFlow_shouldTraverseAllScreens() {
      - @MainActor
    func test_analyzeGoalText_givenValidText_shouldLogGoalText() async {
      - @MainActor
    func test_analyzeGoalText_givenEmptyText_shouldStillWork() async {
      - @MainActor
    func test_prefillFromHealthKit_givenWindow_shouldUpdateSleepTimes() async {
      - @MainActor
    func test_validateBlend_shouldNormalizeValues() {
      - @MainActor
    func test_completeOnboarding_shouldSaveProfileWithCorrectJSON() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Onboarding/OnboardingViewTests.swift

---
Classes:
  Class: OnboardingViewTests
    Properties:
      - var modelContainer: ModelContainer!
      - var context: ModelContext!
      - var mockAIService: MockAIService!
      - var mockOnboardingService: MockOnboardingService!
      - var viewModel: OnboardingViewModel!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_lifeSnapshotView_initialization_shouldCreateWithViewModel() {
      - func test_lifeSnapshotView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_lifeSnapshotView_checkboxOptions_shouldHaveCorrectIdentifiers() {
      - func test_lifeSnapshotView_workoutOptions_shouldHaveCorrectIdentifiers() {
      - func test_lifeSnapshotView_navigationButtons_shouldHaveCorrectIdentifiers() {
      - func test_coreAspirationView_initialization_shouldCreateWithViewModel() {
      - func test_coreAspirationView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_coreAspirationView_goalFamilyCards_shouldHaveCorrectIdentifiers() {
      - func test_coreAspirationView_voiceButton_shouldHaveCorrectIdentifier() {
      - func test_coachingStyleView_initialization_shouldCreateWithViewModel() {
      - func test_coachingStyleView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_coachingStyleView_blendSliders_shouldHaveCorrectIdentifiers() {
      - func test_coachingStyleView_blendValidation_shouldNormalizeValues() {
      - func test_engagementPreferencesView_initialization_shouldCreateWithViewModel() {
      - func test_engagementPreferencesView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_engagementPreferencesView_trackingStyleCards_shouldHaveCorrectIdentifiers() {
      - func test_engagementPreferencesView_checkInFrequency_shouldHaveCorrectIdentifiers() {
      - func test_sleepAndBoundariesView_initialization_shouldCreateWithViewModel() {
      - func test_sleepAndBoundariesView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_sleepAndBoundariesView_timeSliders_shouldHaveCorrectIdentifiers() {
      - func test_motivationalAccentsView_initialization_shouldCreateWithViewModel() {
      - func test_motivationalAccentsView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_motivationalAccentsView_celebrationStyles_shouldHaveCorrectIdentifiers() {
      - func test_motivationalAccentsView_absenceResponses_shouldHaveCorrectIdentifiers() {
      - func test_openingScreenView_initialization_shouldCreateWithViewModel() {
      - func test_openingScreenView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_openingScreenView_beginButton_shouldHaveCorrectIdentifier() {
      - func test_generatingCoachView_initialization_shouldCreateWithViewModel() {
      - func test_generatingCoachView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_coachProfileReadyView_initialization_shouldCreateWithViewModel() {
      - func test_coachProfileReadyView_shouldHaveCorrectAccessibilityIdentifier() {
      - func test_coachProfileReadyView_beginCoachButton_shouldHaveCorrectIdentifier() {
      - func test_onboardingNavigationButtons_shouldHaveCorrectIdentifiers() {
      - func test_onboardingNavigationButtons_shouldCallCorrectActions() {
      - func test_allViews_shouldBindToViewModelCorrectly() {
      - func test_views_shouldHandleErrorStatesGracefully() {
      - func test_views_shouldHandleLoadingStatesGracefully() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Settings/BiometricAuthManagerTests.swift

---
Classes:
  Class: BiometricAuthManagerTests
    Properties:
      - var sut: BiometricAuthManager!
    Methods:
      - override func setUp() {
      - override func tearDown() {
      - func test_biometricType_shouldReturnCorrectType() {
      - func test_canUseBiometrics_shouldReturnBooleanValue() {
      - func test_reset_shouldInvalidateContext() {
      - func test_biometricError_fromLAError_shouldMapCorrectly() {
      - func test_biometricType_displayName_shouldReturnCorrectString() {
      - func test_biometricType_icon_shouldReturnCorrectIcon() {
      - func test_biometricError_localizedDescription_shouldReturnCorrectMessage() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Settings/SettingsModelsTests.swift

---
Classes:
  Class: SettingsModelsTests
    Methods:
      - func test_measurementSystem_displayName_shouldReturnCorrectValues() {
      - func test_measurementSystem_description_shouldReturnCorrectValues() {
      - func test_appearanceMode_displayName_shouldReturnCorrectValues() {
      - func test_notificationPreferences_defaultValues_shouldBeTrue() {
      - func test_quietHours_defaultValues_shouldBeCorrect() {
      - func test_dataExport_initialization_shouldSetProperties() {
      - func test_personaEvolutionTracker_initialization_shouldSetDefaults() {
      - func test_previewScenario_randomScenario_shouldReturnValidScenario() {
      - func test_settingsError_errorDescription_shouldReturnCorrectMessages() {
      - func test_settingsDestination_allCases_shouldBeHashable() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/Settings/SettingsViewModelTests.swift

---
Classes:
  Class: SettingsViewModelTests
    Properties:
      - var sut: SettingsViewModel!
      - var mockAPIKeyManager: MockAPIKeyManager!
      - var mockAIService: MockAIService!
      - var mockNotificationManager: MockNotificationManager!
      - var modelContext: ModelContext!
      - var testUser: User!
      - var coordinator: SettingsCoordinator!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_loadSettings_shouldPopulateAvailableProviders() async {
      - func test_loadSettings_shouldCheckInstalledAPIKeys() async {
      - func test_saveAPIKey_withValidKey_shouldStoreAndConfigureService() async throws {
      - func test_saveAPIKey_withInvalidFormat_shouldThrowError() async {
      - func test_deleteAPIKey_forActiveProvider_shouldSwitchToAlternative() async throws {
      - func test_updateUnits_shouldSaveAndPostNotification() async throws {
      - func test_updateAppearance_shouldSavePreference() async throws {
      - func test_updateHaptics_shouldSavePreference() async throws {
      - func test_updateBiometricLock_whenNotAvailable_shouldThrowError() async {
      - func test_loadCoachPersona_withValidData_shouldLoadPersona() async throws {
      - func test_generatePersonaPreview_withNoPersona_shouldThrowError() async {
      - private func createTestPersona() -> CoachPersona {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Performance/DirectAIPerformanceTests.swift

---
Classes:
  Class: DirectAIPerformanceTests
    Properties:
      - private var coachEngine: CoachEngine!
      - private var mockModelContext: ModelContext!
      - private var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_nutritionParsing_directAI_performance() async throws {
      - func test_educationalContent_directAI_performance() async throws {
      - func test_tokenEfficiency_shortVsLongInput() async throws {
      - func test_directAI_concurrentRequests() async throws {
      - func test_performance_regressionBaseline() async throws {
      - private func measurePerformance<T>(
        operation: () async throws -> T,
        expectedMaxTime: TimeInterval = 5.0,
        description: String
    ) async throws -> (result: T, executionTime: TimeInterval) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Performance/NutritionParsingPerformanceTests.swift

---
Classes:
  Class: NutritionParsingPerformanceTests
    Properties:
      - private var modelContainer: ModelContainer!
      - private var modelContext: ModelContext!
      - private var coachEngine: MockCoachEngineExtensive!
      - private var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_nutritionParsing_singleFood_under3Seconds() async throws {
      - func test_nutritionParsing_multipleFoods_under5Seconds() async throws {
      - func test_nutritionParsing_batchProcessing_maintainsSpeed() async throws {
      - func test_nutritionParsing_memoryUsage_under50MB() async throws {
      - func test_nutritionParsing_memoryCleanup_properlyReleases() async throws {
      - func test_accuracyRegression_realNutritionNotPlaceholders() async throws {
      - func test_accuracyRegression_differentFoodsDifferentValues() async throws {
      - func test_apiContractRegression_interfaceMaintained() async throws {
      - func test_apiContractRegression_errorHandlingMaintained() async throws {
      - private func getMemoryUsage() -> Int64 {
  Class: MockCoachEngineExtensive
    Properties:
      - var mockParseResult: [ParsedFoodItem] = []
      - var shouldThrowError = false
      - var shouldReturnFallback = false
      - var shouldValidate = false
      - var simulateDelay: TimeInterval = 0
      - var lastMealType: MealType?
    Methods:
      - func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
      - func setupRealisticNutrition(for food: String) {
      - func setupMultipleItems(for description: String) {
      - private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
      - private func createDefaultItem(from text: String) -> ParsedFoodItem {
      - private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
      - private func getRealisticNutrition(for food: String) -> ParsedFoodItem {
      - private func parseMultipleItems(from description: String) -> [ParsedFoodItem] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Performance/NutritionParsingRegressionTests.swift

---
Classes:
  Class: NutritionParsingRegressionTests
    Properties:
      - private var modelContainer: ModelContainer!
      - private var modelContext: ModelContext!
      - private var coachEngine: MockCoachEngineExtensive!
      - private var viewModel: FoodTrackingViewModel!
      - private var testUser: User!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_criticalRegression_noHardcoded100Calories() async throws {
      - func test_criticalRegression_noHardcodedMacros() async throws {
      - func test_criticalRegression_nutritionVarietyNotUniform() async throws {
      - func test_viewModelRegression_processTranscriptionRealisticResults() async throws {
      - func test_viewModelRegression_errorHandlingMaintained() async throws {
      - func test_performanceRegression_responseTimeAcceptable() async throws {
      - func test_performanceRegression_batchProcessingStable() async throws {
      - func test_apiContractRegression_methodSignaturePreserved() async throws {
      - func test_apiContractRegression_errorHandlingPreserved() async throws {
      - func test_dataQualityRegression_nutritionDataRealistic() async throws {
      - func test_dataQualityRegression_confidenceScoresMeaningful() async throws {
  Class: MockFoodTrackingCoordinator
    Properties:
      - var didShowFullScreenCover: FoodTrackingRoute?
    Methods:
      - func showFullScreenCover(_ route: FoodTrackingRoute) {
      - func dismissFullScreenCover() {
  Class: MockNutritionService
    Methods:
      - func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
      - func saveFoodEntry(_ entry: FoodEntry) async throws {
      - func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
      - func getWaterIntake(for user: User, date: Date) async throws -> Double {
      - func updateWaterIntake(for user: User, date: Date, amount: Double) async throws {
      - func getRecentFoods(for user: User, limit: Int) async throws -> [ParsedFoodItem] {
      - func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
  Class: MockError

Enums:
  - MockError
    Cases:
      - testError
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Performance/OnboardingPerformanceTests.swift

---
Classes:
  Class: OnboardingPerformanceTests
    Properties:
      - var coordinator: OnboardingFlowCoordinator!
      - var cache: AIResponseCache!
      - var modelContext: ModelContext!
    Methods:
      - override func setUp() async throws {
      - func testPersonaGenerationUnder3Seconds() async throws {
      - func testCachedPersonaGenerationUnder100ms() async throws {
      - func testMemoryUsageUnder50MB() async throws {
      - func testMemoryWarningHandling() async throws {
      - func testOnboardingCachePerformance() async throws {
      - func testRequestOptimizerBatching() async throws {
      - func testCompleteOnboardingFlowPerformance() async throws {
      - private func setupAndGeneratePersona() async {
      - private func createRealisticResponses() -> [ConversationResponse] {
      - private func createLargeResponseDict() -> [String: Any] {
      - private func getMemoryUsage() -> Int64 {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Performance/PersonaGenerationStressTests.swift

---
Classes:
  Class: PersonaGenerationStressTests
    Properties:
      - var orchestrator: OnboardingOrchestrator!
      - var synthesizer: PersonaSynthesizer!
      - var llmOrchestrator: LLMOrchestrator!
      - var modelContext: ModelContext!
      - var monitor: ProductionMonitor!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testPersonaGenerationPerformance() async throws {
      - func testConcurrentPersonaGeneration() async throws {
      - func testMemoryUsageUnderLoad() async throws {
      - func testCachePerformance() async throws {
      - func testErrorRecoveryUnderLoad() async throws {
      - func testLongConversationHistory() async throws {
      - func testRapidSuccessiveRequests() async throws {
      - private func createTestConversationData(variant: Int = 0) -> ConversationData {
      - private func createTestInsights(variant: Int = 0) -> PersonalityInsights {
      - private func getMemoryUsage() -> Int64 {
  Class: MockAPIKeyManager
    Methods:
      - func getAPIKey(for service: String) async -> String? {
      - func setAPIKey(_ key: String, for service: String) async throws {
      - func deleteAPIKey(for service: String) async throws {
      - func hasAPIKey(for service: String) async -> Bool {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/GeminiProviderTests.swift

---
Classes:
  Class: GeminiProviderTests
    Methods:
      - func testGemini25FlashModelSupport() {
      - func testThinkingBudgetInRequest() async {
      - func testMultimodalMessageSupport() {
      - func testGeminiProviderInitialization() async throws {
      - func testStructuredOutputConfiguration() throws {
      - func buildRequest(
        prompt: String,
        model: LLMModel,
        temperature: Double,
        maxTokens: Int?,
        stream: Bool,
        task: AITask
    ) -> LLMRequest {
  Class: MockAPIKeyManager
    Methods:
      - func getAPIKey(for provider: LLMProviderIdentifier) async throws -> String {
      - func setAPIKey(_ key: String, for provider: LLMProviderIdentifier) async throws {
      - func deleteAPIKey(for provider: LLMProviderIdentifier) async throws {
      - func hasAPIKey(for provider: LLMProviderIdentifier) async -> Bool {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/MockServicesTests.swift

---
Classes:
  Class: MockServicesTests
    Methods:
      - func testMockNetworkManagerInitialState() {
      - func testMockNetworkManagerRecordsRequests() async throws {
      - func testMockNetworkManagerSimulatesFailure() async {
      - func testMockNetworkManagerStreaming() async throws {
      - func testMockAIAPIServiceInitialState() {
      - func testMockAIAPIServiceConfigure() async throws {
      - func testMockAIAPIServiceStreaming() async throws {
      - func testMockAIAPIServiceHealthCheck() async {
      - func testMockWeatherServiceDefaultResponses() async throws {
      - func testMockWeatherServiceCustomResponse() async throws {
      - func testMockWeatherServiceRequestHistory() async throws {
      - func testMockAPIKeyManagerOperations() async throws {
      - func testMockAPIKeyManagerGetAllProviders() async throws {
  Class: EmptyResponse
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/NetworkManagerTests.swift

---
Classes:
  Class: NetworkManagerTests
    Properties:
      - var sut: NetworkManager!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testNetworkManagerInitializes() {
      - func testBuildRequestCreatesCorrectRequest() {
      - func testNetworkTypeEnumCases() {
      - func testServiceErrorDescriptions() {
      - func testServiceErrorWithParameters() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/ServiceIntegrationTests.swift

---
Classes:
  Class: ServiceIntegrationTests
    Properties:
      - var networkManager: NetworkManager!
      - var apiKeyManager: DefaultAPIKeyManager!
      - var aiService: EnhancedAIAPIService!
      - var weatherService: WeatherService!
      - var serviceRegistry: ServiceRegistry!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testServiceRegistryIntegration() async throws {
      - func testAPIKeyManagerWithKeychain() async throws {
      - func testNetworkManagerWithReachability() async {
      - func testAIServiceWithAllProviders() async throws {
      - func testAIServiceRequestFlow() async throws {
      - func testWeatherServiceCaching() async throws {
      - func testFullServiceStackIntegration() async throws {
      - func testServiceErrorPropagation() async throws {
      - func testRateLimitHandling() async throws {
      - func testPerformanceRequirements() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/ServicePerformanceTests.swift

---
Classes:
  Class: ServicePerformanceTests
    Properties:
      - var networkManager: NetworkManager!
      - var aiService: EnhancedAIAPIService!
      - var weatherService: WeatherService!
      - var mockAPIKeyManager: MockAPIKeyManager!
    Methods:
      - override func setUp() async throws {
      - func testNetworkManagerRequestBuildingPerformance() {
      - func testURLRequestExtensionsPerformance() {
      - func testAIRequestBuildingPerformance() async throws {
      - func testAIResponseParsingPerformance() async throws {
      - func testTokenEstimationPerformance() async throws {
      - func testWeatherCacheLookupPerformance() async throws {
      - func testServiceRegistryPerformance() async {
      - func testAIStreamingMemoryUsage() async throws {
      - func testServiceLayerOverallMemoryFootprint() async throws {
      - func testConcurrentAIRequestsPerformance() async throws {
      - private func getMemoryUsage() -> Int64 {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/ServiceProtocolsTests.swift

---
Classes:
  Class: ServiceProtocolsTests
    Methods:
      - func testServiceHealthInitialization() {
      - func testServiceHealthOperationalStatus() {
      - func testAIModelInitialization() {
      - func testWeatherDataInitialization() {
      - func testWeatherConditionCases() {
      - func testGoalTypeEnumeration() {
      - func testWorkoutTypeEnumeration() {
      - func testAnalyticsEventCreation() {
      - func testTrendDirection() {
      - func testMacroBalance() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/TestHelpers.swift

---
Classes:
  Class: TestDataGenerators
    Methods:
      - static func makeAIRequest(
        systemPrompt: String = "You are a helpful assistant",
        userMessage: String = "Hello, how are you?",
        model: String? = nil,
        temperature: Double? = 0.7,
        maxTokens: Int? = 2048,
        stream: Bool = true,
        functions: [FunctionSchema]? = nil
    ) -> AIRequest {
      - static func makeConversationRequest(
        messages: [(role: AIMessageRole, content: String)],
        functions: [FunctionSchema]? = nil
    ) -> AIRequest {
      - static func makeStreamingResponses(text: String, chunkSize: Int = 10) -> [AIResponse] {
      - static func makeFunctionCallResponse(
        functionName: String,
        arguments: [String: Any]
    ) -> [AIResponse] {
      - static func makeWeatherData(
        temperature: Double = 72.0,
        condition: WeatherCondition = .partlyCloudy,
        location: String = "New York",
        humidity: Double = 65.0,
        windSpeed: Double = 10.0
    ) -> WeatherData {
      - static func makeWeatherForecast(
        location: String = "New York",
        days: Int = 5,
        baseTemp: Double = 70.0
    ) -> WeatherForecast {
      - static func makeHTTPURLResponse(
        statusCode: Int = 200,
        headers: [String: String]? = nil
    ) -> HTTPURLResponse {
      - static func makeSSEData(_ content: String, event: String? = nil) -> Data {
      - static func makeOpenAIStreamData(content: String? = nil, functionCall: (name: String, args: String)? = nil, done: Bool = false) -> Data {
      - static func makeAnthropicStreamData(
        event: String,
        content: String? = nil,
        stopReason: String? = nil
    ) -> Data {
      - static func makeGeminiStreamData(
        text: String? = nil,
        functionCall: (name: String, args: [String: Any])? = nil,
        finishReason: String? = nil
    ) -> Data {
      - static func makeErrorResponse(
        provider: AIProvider,
        code: String,
        message: String
    ) -> Data {
      - static func makeServiceHealth(
        status: ServiceHealth.Status = .healthy,
        responseTime: TimeInterval? = 0.1,
        errorMessage: String? = nil
    ) -> ServiceHealth {
      - static func makeOnboardingProfile(
        name: String = "Test User",
        age: Int = 30,
        fitnessLevel: FitnessLevel = .intermediate
    ) -> OnboardingProfile {
  Class: FunctionSchema
    Properties:
      - let name: String
      - let description: String
      - let parameters: [String: Any]
  Class: CodingKeys
    Methods:
      - func encode(to encoder: Encoder) throws {

Enums:
  - TestDataGenerators
  - CodingKeys
    Cases:
      - name
      - description
      - parameters
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/WeatherServiceTests.swift

---
Classes:
  Class: WeatherServiceTests
    Properties:
      - var sut: WeatherService!
      - var mockNetworkManager: MockNetworkManager!
      - var mockAPIKeyManager: MockAPIKeyManager!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func testConfigureSuccess() async throws {
      - func testConfigureFailsWithoutAPIKey() async {
      - func testHealthCheckWhenConfigured() async throws {
      - func testHealthCheckWhenNotConfigured() async {
      - func testGetCurrentWeatherSuccess() async throws {
      - func testGetCurrentWeatherUsesCache() async throws {
      - func testGetForecastSuccess() async throws {
      - func testResetClearsConfiguration() async throws {
  Class: OpenWeatherMockResponse
    Properties:
      - let main: Main
      - let weather: [Weather]
      - let wind: Wind
      - let name: String
  Class: Main
    Properties:
      - let temp: Double
      - let humidity: Int
  Class: Weather
    Properties:
      - let main: String
  Class: Wind
    Properties:
      - let speed: Double
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Services/WorkoutSyncServiceTests.swift

---
Classes:
  Class: WorkoutSyncServiceTests
    Methods:
      - func test_sharedInstance_exists() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Workouts/WorkoutCoordinatorTests.swift

---
Classes:
  Class: WorkoutCoordinatorTests
    Properties:
      - var coordinator: WorkoutCoordinator!
    Methods:
      - override func setUp() async throws {
      - func test_navigateToPushesDestination() {
      - func test_showAndDismissSheet() {
      - func test_handleDeepLinkResetsPath() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Workouts/WorkoutViewModelTests.swift

---
Classes:
  Class: WorkoutViewModelTests
    Properties:
      - var container: ModelContainer!
      - var context: ModelContext!
      - var user: User!
      - var mockCoach: MockWorkoutCoachEngine!
      - var mockHealth: MockHealthKitManager!
      - var sut: WorkoutViewModel!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_loadWorkouts_withNoWorkouts_shouldReturnEmptyArray() async throws {
      - func test_loadWorkouts_fetchesUserWorkouts() async throws {
      - func test_loadWorkouts_shouldSortByCompletedDateDescending() async throws {
      - func test_loadWorkouts_withDatabaseError_shouldHandleGracefully() async throws {
      - func test_processReceivedWorkout_createsWorkout() async throws {
      - func test_processReceivedWorkout_withComplexWorkout_shouldCreateAllExercisesAndSets() async throws {
      - func test_processReceivedWorkout_shouldTriggerAIAnalysis() async throws {
      - func test_processReceivedWorkout_withSyncError_shouldHandleGracefully() async throws {
      - func test_generateAIAnalysis_updatesSummary() async throws {
      - func test_generateAIAnalysis_withMultipleWorkouts_shouldIncludeRecentWorkouts() async throws {
      - func test_generateAIAnalysis_withError_shouldHandleGracefully() async throws {
      - func test_calculateWeeklyStats_countsWorkouts() async throws {
      - func test_calculateWeeklyStats_excludesOldWorkouts() async throws {
      - func test_calculateWeeklyStats_withPlannedDateFallback_shouldIncludeWorkout() async throws {
      - func test_calculateWeeklyStats_withNilValues_shouldHandleGracefully() async throws {
      - func test_handleWorkoutDataReceived_shouldProcessData() async throws {
      - func test_handleWorkoutDataReceived_withInvalidData_shouldIgnore() async throws {
      - func test_isLoading_shouldBeSetDuringOperations() async throws {
      - func test_isGeneratingAnalysis_shouldBeSetDuringAIGeneration() async throws {
      - func test_loadWorkouts_performance_shouldCompleteQuickly() async throws {
      - func test_calculateWeeklyStats_performance_shouldCompleteQuickly() async throws {
      - func test_deinit_shouldRemoveNotificationObserver() throws {
  Class: MockWorkoutCoachEngine
    Properties:
      - var mockAnalysis: String = "Mock analysis"
      - var didGenerateAnalysis: Bool = false
      - var shouldThrowError: Bool = false
    Methods:
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
  Class: TestError
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/Dashboard/DashboardUITests.swift

---
Classes:
  Class: DashboardUITests
    Properties:
      - private var app: XCUIApplication!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_dashboardLaunchPerformance() throws {
      - func test_loadingState_displaysAndDismisses() async throws {
      - func test_errorState_showsAndHandlesRetry() async throws {
      - func test_morningGreeting_logEnergy() async throws {
      - func test_nutritionCard_navigation() async throws {
      - func test_quickAction_tapNavigates() async throws {
      - func test_backNavigation_returnsToDashboard() async throws {
      - func test_deepLink_nutrition() async throws {
      - func test_accessibility_labels_exist() {
      - func test_dynamicType_supportsAccessibility() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/FoodTracking/FoodTrackingFlowUITests.swift

---
Classes:
  Class: FoodLoggingViewIDs
    Properties:
      - static let view = "foodLoggingView" // Main view identifier
      - static let voiceInputButton = "foodLogging.voiceInputButton"
      - static let photoInputButton = "foodLogging.photoInputButton"
      - static let searchInputButton = "foodLogging.searchInputButton"
      - static let manualEntryButton = "foodLogging.manualEntryButton" // If exists
      - static let datePicker = "foodLogging.datePicker"
      - static let mealTypeSelectorPrefix = "foodLogging.mealTypeSelector." // e.g., .breakfast
      - static let macroRingsView = "foodLogging.macroRingsView"
      - static let saveMealButton = "foodLogging.saveMealButton" // General save, if applicable at this level
      - static let doneButton = "foodLogging.doneButton" // If it's a sheet
  Class: VoiceInputViewIDs
    Properties:
      - static let view = "voiceInputView"
      - static let recordButton = "voiceInput.recordButton"
      - static let transcriptionText = "voiceInput.transcriptionText"
      - static let processingIndicator = "voiceInput.processingIndicator"
      - static let doneButton = "voiceInput.doneButton" // Or a confirm button
      - static let cancelButton = "voiceInput.cancelButton"
  Class: PhotoInputViewIDs
    Properties:
      - static let view = "photoInputView"
      - static let captureButton = "photoInput.captureButton"
      - static let imagePreview = "photoInput.imagePreview" // After capture
      - static let analyzeButton = "photoInput.analyzeButton" // Or auto-analyze
      - static let usePhotoButton = "photoInput.usePhotoButton"
      - static let retakeButton = "photoInput.retakeButton"
      - static let photoLibraryButton = "photoInput.photoLibraryButton"
      - static let cancelButton = "photoInput.cancelButton"
  Class: FoodConfirmationViewIDs
    Properties:
      - static let view = "foodConfirmationView"
      - static let foodItemCardPrefix = "foodConfirmation.foodItemCard." // Append item name or index
      - static let editItemButtonPrefix = "foodConfirmation.editItemButton."
      - static let deleteItemButtonPrefix = "foodConfirmation.deleteItemButton."
      - static let addItemButton = "foodConfirmation.addItemButton"
      - static let saveButton = "foodConfirmation.saveButton"
      - static let cancelButton = "foodConfirmation.cancelButton"
      - static let totalCaloriesText = "foodConfirmation.totalCaloriesText"
  Class: NutritionSearchViewIDs
    Properties:
      - static let view = "nutritionSearchView"
      - static let searchField = "nutritionSearch.searchField"
      - static let searchResultRowPrefix = "nutritionSearch.resultRow." // Append item name or id
      - static let recentFoodItemPrefix = "nutritionSearch.recentItem."
      - static let categoryChipPrefix = "nutritionSearch.categoryChip."
      - static let noResultsText = "nutritionSearch.noResultsText"
      - static let cancelButton = "nutritionSearch.cancelButton"
  Class: DashboardViewIDs
    Properties:
      - static let view = "dashboardView"
      - static let foodTrackingNavigationButton = "dashboard.navigateToFoodTrackingButton"
  Class: FoodTrackingFlowUITests
    Properties:
      - var app: XCUIApplication!
    Methods:
      - override func setUpWithError() throws {
      - override func tearDownWithError() throws {
      - private func navigateToFoodLogging() {
      - func testVoiceFoodLoggingFlow() throws {
      - func testPhotoFoodLoggingFlow() throws {
      - func testManualSearchFoodLoggingFlow() throws {
      - func testMicrophonePermissionDenied() {
      - func testInvalidSearchQuery() {
      - func testVoiceInputResponsivenessPerformance() {
      - func testAccessibilityLabelsPresent() {
      - func waitForNonExistence(timeout: TimeInterval) -> Bool {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/Onboarding/OnboardingFlowUITests.swift

---
Classes:
  Class: OnboardingFlowUITests
    Properties:
      - var app: XCUIApplication!
      - var onboardingPage: OnboardingPage!
    Methods:
      - override func setUp() async throws {
      - override func tearDown() async throws {
      - func test_completeOnboardingFlow_happyPath() async throws {
      - func test_cardSelection_updatesState() async throws {
      - func test_sliderAdjustment_updatesValue() async throws {
      - func test_voiceButton_isAccessible() async throws {
      - func test_backNavigation_worksCorrectly() async throws {
      - func test_endToEndFlow_completesSuccessfully() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/PageObjects/OnboardingFlowPage.swift

---
Classes:
  Class: OnboardingFlowPage
    Properties:
      - var nextButton: XCUIElement {
    Methods:
      - func tapNext() async {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/Pages/BasePage.swift

---
Classes:
  Class: BasePage
    Properties:
      - let app: XCUIApplication
      - let timeout: TimeInterval = 10.0
    Methods:
      - func tapElement(_ element: XCUIElement) async {
      - func typeText(in element: XCUIElement, text: String) async {
      - func verifyElement(exists element: XCUIElement, timeout: TimeInterval? = nil) async {
      - func verifyElement(notExists element: XCUIElement) {
      - func waitForElement(_ element: XCUIElement, timeout: TimeInterval? = nil) async -> Bool {
      - func swipeUp() {
      - func swipeDown() {
      - func scrollToElement(_ element: XCUIElement) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/Pages/OnboardingPage.swift

---
Classes:
  Class: GoalFamily
  Class: OnboardingPage
    Properties:
      - var beginButton: XCUIElement {
      - var skipButton: XCUIElement {
      - var lifeSnapshotScreen: XCUIElement {
      - var coreAspirationScreen: XCUIElement {
      - var goalScreen: XCUIElement {
      - var goalTextInput: XCUIElement {
      - var voiceButton: XCUIElement {
      - var coachingStyleScreen: XCUIElement {
      - var engagementScreen: XCUIElement {
      - var sleepScreen: XCUIElement {
      - var motivationScreen: XCUIElement {
      - var generatingScreen: XCUIElement {
      - var coachReadyScreen: XCUIElement {
      - var beginCoachButton: XCUIElement {
      - var nextButton: XCUIElement {
      - var backButton: XCUIElement {
      - var isOn: Bool {
    Methods:
      - func verifyOnOpeningScreen() async {
      - func tapBegin() async {
      - func verifyOnLifeSnapshot() async {
      - func selectLifeOption(_ optionId: String) async {
      - func selectWorkoutOption(_ option: String) async {
      - func verifyOnCoreAspiration() async {
      - func selectPredefinedGoal(_ goal: String) async {
      - func selectGoalFamily(_ family: GoalFamily) async {
      - func selectLifeSnapshotOptions() async {
      - func enterGoalText(_ text: String) async {
      - func tapVoiceButton() async {
      - func verifyOnCoachingStyle() async {
      - func waitForCoachingStyleScreen() async -> Bool {
      - func adjustSlider(_ identifier: String, to position: CGFloat) async {
      - func verifyOnEngagementPreferences() async {
      - func waitForEngagementPreferencesScreen() async -> Bool {
      - func selectEngagementCard(_ id: String) async {
      - func selectRadioOption(_ id: String) async {
      - func toggleAutoRecovery(_ on: Bool) async {
      - func verifyOnSleepBoundaries() async {
      - func waitForSleepBoundariesScreen() async -> Bool {
      - func adjustTimeSlider(_ id: String, to position: CGFloat) async {
      - func verifyOnMotivationalAccents() async {
      - func waitForMotivationalAccentsScreen() async -> Bool {
      - func selectMotivationOption(_ id: String) async {
      - func verifyOnGeneratingCoach() async {
      - func waitForGeneratingCoachScreen() async -> Bool {
      - func verifyCoachProfileReady() async {
      - func tapBeginCoachButton() async {
      - func tapNextButton() async {
      - func tapBackButton() async {
      - func isOnDashboard() async -> Bool {

Enums:
  - GoalFamily
    Cases:
      - weightLoss
      - strengthTone
      - performance
      - wellness
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/AirFitUITests.swift

---
Classes:
  Class: AirFitUITests
    Methods:
      - override func setUpWithError() throws {
      - func testLaunch() async throws {
      - @MainActor
    func testLaunchPerformance() throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/AirFitUITests/AirFitUITestsLaunchTests.swift

---
Classes:
  Class: AirFitUITestsLaunchTests
    Properties:
      - override static var runsForEachTargetApplicationUIConfiguration: Bool {
    Methods:
      - override func setUpWithError() throws {
      - func testLaunch() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Application/AirFitApp.swift

---
Classes:
  Class: AirFitApp
    Properties:
      - static let sharedModelContainer: ModelContainer = {
      - var body: some Scene {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Application/ContentView.swift

---
Classes:
  Class: ContentView
    Properties:
      - private var modelContext
      - @State private var appState: AppState?
      - var body: some View {
  Class: LoadingView
    Properties:
      - var body: some View {
  Class: WelcomeView
    Properties:
      - let appState: AppState
      - var body: some View {
  Class: ErrorView
    Properties:
      - let error: Error?
      - let onRetry: () -> Void
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Application/MinimalContentView.swift

---
Classes:
  Class: ContentView
    Properties:
      - private var modelContext
      - @State private var showOnboarding = true
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Constants/APIConstants.swift

---
Classes:
  Class: APIConstants
  Class: Headers
  Class: ContentType
  Class: Endpoints
  Class: Pagination
  Class: Cache

Enums:
  - APIConstants
  - Headers
  - ContentType
  - Endpoints
  - Pagination
  - Cache
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Constants/AppConstants.swift

---
Classes:
  Class: AppConstants
  Class: Layout
  Class: Animation
  Class: API
  Class: Storage
  Class: Health
  Class: Validation

Enums:
  - AppConstants
  - Layout
  - Animation
  - API
  - Storage
  - Health
  - Validation
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Constants/AppConstants+Settings.swift

---
Classes:
  Class: AppConstants+Settings
    Properties:
      - static var appVersionString: String {
      - static let privacyPolicyURL = "https://airfit.app/privacy"
      - static let termsOfServiceURL = "https://airfit.app/terms"
      - static let supportEmail = "support@airfit.app"
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Enums/AppError.swift

---
Classes:
  Class: AppError

Enums:
  - AppError
    Cases:
      - networkError
      - decodingError
      - validationError
      - unauthorized
      - serverError
      - unknown
      - healthKitNotAuthorized
      - cameraNotAuthorized
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Enums/AppError+Conversion.swift

---
Classes:
  Class: AppError+Conversion
    Properties:
      - var isRecoverable: Bool {
      - var shouldRetry: Bool {
      - var retryDelay: TimeInterval? {
    Methods:
      - static func from(_ aiError: AIError) -> AppError {
      - static func from(_ directAIError: DirectAIError) -> AppError {
      - static func from(_ networkError: NetworkError) -> AppError {
      - static func from(_ serviceError: ServiceError) -> AppError {
      - static func from(_ workoutError: WorkoutError) -> AppError {
      - static func from(_ keychainError: KeychainError) -> AppError {
      - static func from(_ onboardingError: OnboardingError) -> AppError {
      - static func from(_ orchestratorError: OnboardingOrchestratorError) -> AppError {
      - static func from(_ foodError: FoodTrackingError) -> AppError {
      - static func from(_ voiceError: FoodVoiceError) -> AppError {
      - static func from(_ chatError: ChatError) -> AppError {
      - static func from(_ settingsError: SettingsError) -> AppError {
      - static func from(_ conversationError: ConversationManagerError) -> AppError {
      - static func from(_ functionError: FunctionError) -> AppError {
      - static func from(_ personaEngineError: PersonaEngineError) -> AppError {
      - static func from(_ personaError: PersonaError) -> AppError {
      - static func from(_ liveActivityError: LiveActivityError) -> AppError {
      - static func from(_ coachError: CoachEngineError) -> AppError {
  Class: ErrorContext
    Properties:
      - let error: AppError
      - let file: String
      - let function: String
      - let line: Int
      - let additionalInfo: [String: String]? // Changed to Sendable type
    Methods:
      - func mapToAppError() -> Result<Success, AppError> {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Enums/GlobalEnums.swift

---
Classes:
  Class: GlobalEnums
  Class: BiologicalSex
  Class: ActivityLevel
  Class: FitnessGoal
  Class: LoadingState
    Methods:
      - public static func == (lhs: Self, rhs: Self) -> Bool {
  Class: AppTab
  Class: ExerciseCategory
  Class: MuscleGroup
  Class: Equipment
  Class: Difficulty

Enums:
  - GlobalEnums
  - BiologicalSex
    Cases:
      - male
      - female
  - ActivityLevel
    Cases:
      - sedentary
      - lightlyActive
      - moderate
      - veryActive
      - extreme
  - FitnessGoal
    Cases:
      - loseWeight
      - maintainWeight
      - gainMuscle
  - LoadingState
    Cases:
      - idle
      - loading
      - loaded
      - error
  - AppTab
    Cases:
      - dashboard
      - meals
      - discover
      - progress
      - settings
  - ExerciseCategory
    Cases:
      - strength
      - cardio
      - flexibility
      - plyometrics
      - balance
      - sports
  - MuscleGroup
    Cases:
      - chest
      - shoulders
      - biceps
      - triceps
      - forearms
      - abs
      - lats
      - middleBack
      - lowerBack
      - traps
      - quads
      - hamstrings
      - glutes
      - calves
      - adductors
      - abductors
  - Equipment
    Cases:
      - bodyweight
      - dumbbells
      - barbell
      - kettlebells
      - cables
      - machine
      - resistanceBands
      - foamRoller
      - medicineBall
      - stabilityBall
      - other
  - Difficulty
    Cases:
      - beginner
      - intermediate
      - advanced
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Enums/MessageType.swift

---
Classes:
  Class: MessageType

Enums:
  - MessageType
    Cases:
      - conversation
      - command
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/AIProvider+API.swift

---
Classes:
  Class: AIProvider+API
    Properties:
      - var baseURL: URL {
      - var displayName: String {
      - var defaultModel: String {
      - var availableModels: [String] {
      - var defaultContextWindow: Int {
      - var supportsFunctionCalling: Bool {
      - var supportsVision: Bool {
      - var freeRateLimit: Int? {
    Methods:
      - func authHeaders(apiKey: String) -> [String: String] {
      - func streamingEndpoint(for model: String) -> String {
      - func pricing(for model: String) -> (input: Double, output: Double)? {
      - func isValidModel(_ model: String) -> Bool {
      - func errorMessage(for code: String) -> String? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/Color+Hex.swift

---
Classes:
  Class: Color+Hex
    Methods:
      - func toHex() -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/Date+Helpers.swift

---
Classes:
  Class: Date+Helpers
    Properties:
      - var isToday: Bool {
      - var isYesterday: Bool {
      - var startOfDay: Date {
      - var endOfDay: Date {
    Methods:
      - func formatted(as format: String) -> String {
      - func adding(days: Int) -> Date {
      - func adding(hours: Int) -> Date {
      - func timeAgoDisplay() -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/Double+Formatting.swift

---
Classes:
  Class: Double+Formatting
    Properties:
      - var kilogramsToPounds: Double {
      - var poundsToKilograms: Double {
    Methods:
      - func rounded(toPlaces places: Int) -> Double {
      - func formattedDistance() -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/String+Helpers.swift

---
Classes:
  Class: String+Helpers
    Properties:
      - var isBlank: Bool {
      - var isValidEmail: Bool {
      - var trimmed: String {
    Methods:
      - func truncated(to length: Int, addEllipsis: Bool = true) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/TimeInterval+Formatting.swift

---
Classes:
  Class: TimeInterval+Formatting
    Methods:
      - func formattedDuration(style: DateComponentsFormatter.UnitsStyle = .abbreviated) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/URLRequest+API.swift

---
Classes:
  Class: URLRequest+API
    Properties:
      - var cURLCommand: String {
      - private var userAgent: String {
    Methods:
      - mutating func addCommonHeaders() {
      - mutating func addStreamingHeaders() {
      - mutating func addAuthorization(_ token: String, type: String = "Bearer") {
      - mutating func setJSONBody<T: Encodable>(_ body: T) throws {
      - mutating func setJSONBody(_ body: [String: Any]) throws {
      - mutating func addQueryParameters(_ parameters: [String: String]) {
      - func logDetails(category: AppLogger.Category = .networking) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Extensions/View+Styling.swift

---
Classes:
  Class: View+Styling
    Methods:
      - func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
      - func standardPadding() -> some View {
      - func cardStyle() -> some View {
      - func primaryButton() -> some View {
      - func onFirstAppear(perform action: @escaping () -> Void) -> some View {
  Class: RoundedCorner
    Properties:
      - var radius: CGFloat = .infinity
      - var corners: UIRectCorner = .allCorners
    Methods:
      - func path(in rect: CGRect) -> Path {
  Class: FirstAppear
    Properties:
      - let action: () -> Void
      - @State private var hasAppeared = false
    Methods:
      - func body(content: Content) -> some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Models/AI/AIModels.swift

---
Classes:
  Class: AIModel
    Properties:
      - let id: String
      - let name: String
      - let provider: AIProvider
      - let contextWindow: Int
      - let costPerThousandTokens: TokenCost
  Class: TokenCost
    Properties:
      - let input: Double
      - let output: Double
  Class: AIMessageRole
  Class: AIChatMessage
    Properties:
      - let id: UUID
      - let role: AIMessageRole
      - let content: String
      - let name: String?
      - let functionCall: AIFunctionCall?
      - let timestamp: Date
  Class: AIFunctionCall
    Properties:
      - let name: String
      - let arguments: [String: AIAnyCodable]
  Class: AIFunctionDefinition
    Properties:
      - let name: String
      - let description: String
      - let parameters: AIFunctionParameters
  Class: AIFunctionParameters
    Properties:
      - let type: String
      - let properties: [String: AIParameterDefinition]
      - let required: [String]
  Class: AIParameterDefinition
    Properties:
      - let type: String
      - let description: String
      - let enumValues: [String]?
      - let minimum: Double?
      - let maximum: Double?
      - let items: AIBox<AIParameterDefinition>?
  Class: CodingKeys
  Class: AIBox
    Properties:
      - let value: T
    Methods:
      - func encode(to encoder: Encoder) throws {
  Class: AIRequest
    Properties:
      - let id = UUID()
      - let systemPrompt: String
      - let messages: [AIChatMessage]
      - let functions: [AIFunctionDefinition]?
      - let temperature: Double
      - let maxTokens: Int?
      - let stream: Bool
      - let user: String
      - let enableGrounding: Bool  // Google Gemini grounding
      - let cacheKey: String?      // Anthropic context caching
      - let audioData: Data?       // OpenAI audio input
  Class: AIResponse
  Class: AITokenUsage
    Properties:
      - let promptTokens: Int
      - let completionTokens: Int
      - let totalTokens: Int
  Class: AIError
  Class: AIProvider
  Class: AIAnyCodable
    Properties:
      - let value: Any
    Methods:
      - func encode(to encoder: Encoder) throws {

Enums:
  - AIMessageRole
    Cases:
      - system
      - user
      - assistant
      - function
      - tool
  - CodingKeys
    Cases:
      - type
      - description
      - enumValues
      - minimum
      - maximum
      - items
  - AIResponse
    Cases:
      - text
      - textDelta
      - functionCall
      - error
      - done
  - AIError
    Cases:
      - networkError
      - rateLimitExceeded
      - invalidResponse
      - modelOverloaded
      - contextLengthExceeded
      - unauthorized
  - AIProvider
    Cases:
      - openAI
      - gemini
      - anthropic
      - openRouter
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Models/HealthContextSnapshot.swift

---
Classes:
  Class: HealthContextSnapshot
    Properties:
      - let id: UUID
      - let timestamp: Date
      - let date: Date
      - let subjectiveData: SubjectiveData
      - let environment: EnvironmentContext
      - let activity: ActivityMetrics
      - let sleep: SleepAnalysis
      - let heartHealth: HeartHealthMetrics
      - let body: BodyMetrics
      - let appContext: AppSpecificContext
      - let trends: HealthTrends
  Class: SubjectiveData
    Properties:
      - var energyLevel: Int?      // 1-5
      - var mood: Int?             // 1-5
      - var stress: Int?           // 1-5
      - var motivation: Int?       // 1-5
      - var soreness: Int?         // 1-5
      - var notes: String?
  Class: EnvironmentContext
    Properties:
      - var weatherCondition: String?
      - var temperature: Measurement<UnitTemperature>?
      - var humidity: Double?           // percentage 0-100
      - var airQualityIndex: Int?
      - var timeOfDay: TimeOfDay = .init()
  Class: TimeOfDay
  Class: ActivityMetrics
    Properties:
      - var activeEnergyBurned: Measurement<UnitEnergy>?
      - var basalEnergyBurned: Measurement<UnitEnergy>?
      - var steps: Int?
      - var distance: Measurement<UnitLength>?
      - var flightsClimbed: Int?
      - var exerciseMinutes: Int?
      - var standHours: Int?
      - var moveMinutes: Int?
      - var currentHeartRate: Int?
      - var isWorkoutActive = false
      - var workoutTypeRawValue: UInt?  // Store HKWorkoutActivityType as raw value
      - var moveProgress: Double?
      - var exerciseProgress: Double?
      - var standProgress: Double?
      - var workoutType: HKWorkoutActivityType? {
  Class: SleepAnalysis
    Properties:
      - var lastNight: SleepSession?
      - var weeklyAverage: SleepAverages?
  Class: SleepSession
    Properties:
      - let bedtime: Date?
      - let wakeTime: Date?
      - let totalSleepTime: TimeInterval?
      - let timeInBed: TimeInterval?
      - let efficiency: Double?   // 0-100
      - let remTime: TimeInterval?
      - let coreTime: TimeInterval?
      - let deepTime: TimeInterval?
      - let awakeTime: TimeInterval?
      - var quality: SleepQuality? {
  Class: SleepAverages
    Properties:
      - let averageBedtime: Date?
      - let averageWakeTime: Date?
      - let averageDuration: TimeInterval?
      - let averageEfficiency: Double?
      - let consistency: Double?    // 0-100
  Class: SleepQuality
  Class: HeartHealthMetrics
    Properties:
      - var restingHeartRate: Int?
      - var hrv: Measurement<UnitDuration>?      // milliseconds
      - var respiratoryRate: Double?             // breaths per minute
      - var vo2Max: Double?                      // ml/kg/min
      - var cardioFitness: CardioFitnessLevel?
      - var recoveryHeartRate: Int?              // 1 min post-workout
      - var heartRateRecovery: Int?              // drop from peak
  Class: CardioFitnessLevel
  Class: BodyMetrics
    Properties:
      - var weight: Measurement<UnitMass>?
      - var bodyFatPercentage: Double?
      - var leanBodyMass: Measurement<UnitMass>?
      - var bmi: Double?
      - var bodyMassIndex: BMICategory? {
      - var weightTrend: Trend?
      - var bodyFatTrend: Trend?
  Class: BMICategory
  Class: Trend
  Class: AppSpecificContext
    Properties:
      - var activeWorkoutName: String?
      - var lastMealTime: Date?
      - var lastMealSummary: String?
      - var waterIntakeToday: Measurement<UnitVolume>?
      - var lastCoachInteraction: Date?
      - var upcomingWorkout: String?
      - var currentStreak: Int?
      - var workoutContext: WorkoutContext?
  Class: WorkoutContext
    Properties:
      - var recentWorkouts: [CompactWorkout] = []
      - var activeWorkout: CompactWorkout?
      - var upcomingWorkout: CompactWorkout?
      - var plannedWorkouts: [CompactWorkout] = []
      - var streakDays: Int = 0
      - var weeklyVolume: Double = 0
      - var muscleGroupBalance: [String: Int] = [:]
      - var intensityTrend: IntensityTrend = .stable
      - var recoveryStatus: RecoveryStatus = .unknown
  Class: CompactWorkout
    Properties:
      - let name: String
      - let type: String
      - let date: Date
      - let duration: TimeInterval?
      - let exerciseCount: Int
      - let totalVolume: Double // weight × reps total
      - let avgRPE: Double?
      - let muscleGroups: [String]
      - let keyExercises: [String] // Top 3 exercises
  Class: WorkoutPatterns
    Properties:
      - let weeklyVolume: Double
      - let muscleGroupBalance: [String: Int]
      - let intensityTrend: IntensityTrend
      - let recoveryStatus: RecoveryStatus
  Class: IntensityTrend
  Class: RecoveryStatus
    Properties:
      - var name: String {
  Class: HealthTrends
    Properties:
      - var weeklyActivityChange: Double?       // percentage
      - var sleepConsistencyScore: Double?      // 0-100
      - var recoveryTrend: RecoveryTrend?
      - var performanceTrend: PerformanceTrend?
  Class: RecoveryTrend
  Class: PerformanceTrend

Enums:
  - TimeOfDay
    Cases:
      - earlyMorning
      - morning
      - afternoon
      - evening
      - night
  - SleepQuality
    Cases:
      - excellent
      - good
      - fair
      - poor
  - CardioFitnessLevel
    Cases:
      - low
      - belowAverage
      - average
      - aboveAverage
      - high
  - BMICategory
    Cases:
      - underweight
      - normal
      - overweight
      - obese
  - Trend
    Cases:
      - increasing
      - stable
      - decreasing
  - IntensityTrend
    Cases:
      - increasing
      - stable
      - decreasing
  - RecoveryStatus
    Cases:
      - active
      - recovered
      - wellRested
      - detraining
      - unknown
  - RecoveryTrend
    Cases:
      - wellRecovered
      - normal
      - needsRecovery
      - overreaching
  - PerformanceTrend
    Cases:
      - peaking
      - improving
      - maintaining
      - declining
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Models/NutritionPreferences.swift

---
Classes:
  Class: NutritionPreferences
    Properties:
      - let dietaryRestrictions: [String]
      - let allergies: [String]
      - let preferredUnits: String // "metric" or "imperial"
      - let calorieGoal: Double?
      - let proteinGoal: Double?
      - let carbGoal: Double?
      - let fatGoal: Double?
      - static let `default` = NutritionPreferences(
 dietaryRestrictions: [], allergies: [], preferredUnits: "imperial", calorieGoal: nil, proteinGoal: nil, carbGoal: nil, fatGoal: nil
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Models/ServiceModels.swift

---
Classes:
  Class: ServiceError
  Class: ServiceWeatherData
    Properties:
      - let temperature: Double
      - let condition: WeatherCondition
      - let humidity: Double
      - let windSpeed: Double
      - let location: String
      - let timestamp: Date
  Class: WeatherForecast
    Properties:
      - let daily: [DailyForecast]
      - let location: String
  Class: DailyForecast
    Properties:
      - let date: Date
      - let highTemperature: Double
      - let lowTemperature: Double
      - let condition: WeatherCondition
      - let precipitationChance: Double
  Class: WeatherCondition

Enums:
  - ServiceError
    Cases:
      - notConfigured
      - invalidConfiguration
      - networkUnavailable
      - authenticationFailed
      - rateLimitExceeded
      - invalidResponse
      - streamingError
      - timeout
      - cancelled
      - providerError
      - unknown
  - WeatherCondition
    Cases:
      - clear
      - partlyCloudy
      - cloudy
      - rain
      - snow
      - thunderstorm
      - fog
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Models/WorkoutBuilderData.swift

---
Classes:
  Class: WorkoutBuilderData
    Properties:
      - var id = UUID()
      - var workoutType: Int = 0
      - var startTime: Date?
      - var endTime: Date?
      - var exercises: [ExerciseBuilderData] = []
      - var totalCalories: Double = 0
      - var totalDistance: Double = 0
      - var duration: TimeInterval = 0
  Class: ExerciseBuilderData
    Properties:
      - let id: UUID
      - let name: String
      - let muscleGroups: [String]
      - let startTime: Date
      - var sets: [SetBuilderData] = []
  Class: SetBuilderData
    Properties:
      - let reps: Int?
      - let weightKg: Double?
      - let duration: TimeInterval?
      - let rpe: Double?
      - let completedAt: Date
  Class: WorkoutError

Enums:
  - WorkoutError
    Cases:
      - saveFailed
      - syncFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/AIServiceProtocol.swift

---

---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/AIServiceProtocol+Extensions.swift

---
Classes:
  Class: WorkoutPlanResult
    Properties:
      - let id: UUID
      - let exercises: [PlannedExercise]
      - let estimatedCalories: Int
      - let estimatedDuration: Int
      - let summary: String
      - let difficulty: WorkoutDifficulty
      - let focusAreas: [String]
  Class: WorkoutDifficulty
  Class: PlannedExercise
    Properties:
      - let exerciseId: UUID
      - let name: String
      - let sets: Int
      - let reps: String // Can be range like "8-12"
      - let restSeconds: Int
      - let notes: String?
      - let alternatives: [String]
  Class: PerformanceAnalysisResult
    Properties:
      - let summary: String
      - let insights: [AIPerformanceInsight]
      - let trends: [PerformanceTrend]
      - let recommendations: [String]
      - let dataPoints: Int
      - let confidence: Double
  Class: AIPerformanceInsight
    Properties:
      - let category: String
      - let finding: String
      - let impact: ImpactLevel
      - let evidence: [String]
  Class: ImpactLevel
  Class: PerformanceTrend
    Properties:
      - let metric: String
      - let direction: TrendDirection
      - let magnitude: Double
      - let timeframe: String
  Class: TrendDirection
  Class: PredictiveInsights
    Properties:
      - let projections: [String: Double]
      - let risks: [String]
      - let opportunities: [String]
      - let confidence: Double
  Class: GoalResult
    Properties:
      - let id: UUID
      - let title: String
      - let description: String
      - let targetDate: Date?
      - let metrics: [GoalMetric]
      - let milestones: [GoalMilestone]
      - let smartCriteria: SMARTCriteria
  Class: SMARTCriteria
    Properties:
      - let specific: String
      - let measurable: String
      - let achievable: String
      - let relevant: String
      - let timeBound: String
  Class: GoalMetric
    Properties:
      - let name: String
      - let currentValue: Double
      - let targetValue: Double
      - let unit: String
  Class: GoalMilestone
    Properties:
      - let title: String
      - let targetDate: Date
      - let criteria: String
      - let reward: String?
  Class: GoalAdjustment
    Properties:
      - let type: AdjustmentType
      - let reason: String
      - let suggestedChange: String
      - let impact: String
  Class: AdjustmentType

Enums:
  - WorkoutDifficulty
    Cases:
      - beginner
      - intermediate
      - advanced
      - expert
  - ImpactLevel
    Cases:
      - low
      - medium
      - high
      - critical
  - TrendDirection
    Cases:
      - improving
      - stable
      - declining
      - volatile
  - AdjustmentType
    Cases:
      - timeline
      - target
      - approach
      - intensity
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/AnalyticsServiceProtocol.swift

---
Classes:
  Class: AnalyticsEvent
    Properties:
      - let name: String
      - let properties: [String: String]
      - let timestamp: Date
  Class: UserInsights
    Properties:
      - let workoutFrequency: Double
      - let averageWorkoutDuration: TimeInterval
      - let caloriesTrend: Trend
      - let macroBalance: MacroBalance
      - let streakDays: Int
      - let achievements: [UserAchievement]
  Class: Trend
  Class: Direction
    Properties:
      - let direction: Direction
      - let changePercentage: Double
  Class: MacroBalance
    Properties:
      - let proteinPercentage: Double
      - let carbsPercentage: Double
      - let fatPercentage: Double
  Class: UserAchievement
    Properties:
      - let id: String
      - let title: String
      - let description: String
      - let unlockedAt: Date
      - let icon: String

Enums:
  - Direction
    Cases:
      - up
      - down
      - stable
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/APIKeyManagementProtocol.swift

---

---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/DashboardServiceProtocols.swift

---
Classes:
  Class: HealthContext
    Properties:
      - let lastNightSleepDurationHours: Double?
      - let sleepQuality: Int?
      - let currentWeatherCondition: String?
      - let currentTemperatureCelsius: Double?
      - let yesterdayEnergyLevel: Int?
      - let currentHeartRate: Int?
      - let hrv: Double?
      - let steps: Int?
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/ErrorHandling.swift

---
Classes:
  Class: ErrorHandling
    Methods:
      - func handleError(_ error: Error) {
      - func clearError() {
      - func withErrorHandling<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async -> T? {
      - func withErrorHandling<T: Sendable>(
        setLoading: @MainActor @escaping (Bool) -> Void,
        _ operation: @Sendable () async throws -> T
    ) async -> T? {
  Class: ErrorAlertModifier
    Properties:
      - @Binding var error: AppError?
      - @Binding var isPresented: Bool
      - let onDismiss: (() -> Void)?
    Methods:
      - func body(content: Content) -> some View {
      - func errorAlert(
        error: Binding<AppError?>,
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
      - func handleServiceError<T>(
        _ operation: () async throws -> T,
        context: String
    ) async throws -> T {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/FoodVoiceAdapterProtocol.swift

---

---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/FoodVoiceServiceProtocol.swift

---
Classes:
  Class: FoodVoiceError

Enums:
  - FoodVoiceError
    Cases:
      - voiceInputManagerUnavailable
      - transcriptionFailed
      - permissionDenied
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/GoalServiceProtocol.swift

---
Classes:
  Class: ServiceGoal
    Properties:
      - let id: UUID
      - let type: GoalType
      - let target: Double
      - let currentValue: Double
      - let deadline: Date?
      - let createdAt: Date
      - let updatedAt: Date
  Class: GoalType
  Class: GoalCreationData
    Properties:
      - let type: GoalType
      - let target: Double
      - let deadline: Date?
      - let description: String?
  Class: GoalUpdate
    Properties:
      - let target: Double?
      - let deadline: Date?
      - let description: String?

Enums:
  - GoalType
    Cases:
      - weightLoss
      - muscleGain
      - stepCount
      - workoutFrequency
      - calorieIntake
      - waterIntake
      - custom
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/LLMProvider.swift

---
Classes:
  Class: LLMProviderIdentifier
    Properties:
      - let name: String
      - let version: String
      - static let anthropic = LLMProviderIdentifier(name: "Anthropic", version: "2024-01")
      - static let openai = LLMProviderIdentifier(name: "OpenAI", version: "v1")
      - static let google = LLMProviderIdentifier(name: "Google", version: "v1beta")
  Class: LLMCapabilities
    Properties:
      - let maxContextTokens: Int
      - let supportsJSON: Bool
      - let supportsStreaming: Bool
      - let supportsSystemPrompt: Bool
      - let supportsFunctionCalling: Bool
      - let supportsVision: Bool
  Class: LLMRequest
    Properties:
      - let messages: [LLMMessage]
      - let model: String
      - let temperature: Double
      - let maxTokens: Int?
      - let systemPrompt: String?
      - let responseFormat: ResponseFormat?
      - let stream: Bool
      - let metadata: [String: String]
  Class: ResponseFormat
  Class: LLMMessage
    Properties:
      - let role: Role
      - let content: String
      - let name: String?
  Class: Role
  Class: LLMResponse
    Properties:
      - let content: String
      - let model: String
      - let usage: TokenUsage
      - let finishReason: FinishReason
      - let metadata: [String: String]
  Class: TokenUsage
    Properties:
      - let promptTokens: Int
      - let completionTokens: Int
      - var totalTokens: Int {
    Methods:
      - func cost(at rates: (input: Double, output: Double)) -> Double {
  Class: FinishReason
  Class: LLMStreamChunk
    Properties:
      - let delta: String
      - let isFinished: Bool
      - let usage: LLMResponse.TokenUsage?
  Class: LLMError

Enums:
  - ResponseFormat
    Cases:
      - text
      - json
  - Role
    Cases:
      - system
      - user
      - assistant
  - FinishReason
    Cases:
      - stop
      - length
      - contentFilter
      - toolCalls
  - LLMError
    Cases:
      - invalidAPIKey
      - rateLimitExceeded
      - contextLengthExceeded
      - invalidResponse
      - networkError
      - serverError
      - timeout
      - cancelled
      - unsupportedFeature
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/NetworkClientProtocol.swift

---
Classes:
  Class: Endpoint
    Properties:
      - let path: String
      - let method: HTTPMethod
      - let headers: [String: String]?
      - let queryItems: [URLQueryItem]?
      - let body: Data?
  Class: HTTPMethod
  Class: NetworkError

Enums:
  - HTTPMethod
    Cases:
      - get
      - post
      - put
      - patch
      - delete
  - NetworkError
    Cases:
      - invalidURL
      - invalidResponse
      - noData
      - decodingError
      - httpError
      - networkError
      - timeout
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/NetworkManagementProtocol.swift

---
Classes:
  Class: NetworkType

Enums:
  - NetworkType
    Cases:
      - wifi
      - cellular
      - ethernet
      - unknown
      - none
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/NutritionServiceProtocol.swift

---

---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/OnboardingServiceProtocol.swift

---

---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/ServiceProtocol.swift

---
Classes:
  Class: ServiceHealth
  Class: Status
    Properties:
      - let status: Status
      - let lastCheckTime: Date
      - let responseTime: TimeInterval?
      - let errorMessage: String?
      - let metadata: [String: String]
      - var isOperational: Bool {

Enums:
  - Status
    Cases:
      - healthy
      - degraded
      - unhealthy
      - unknown
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/UserServiceProtocol.swift

---
Classes:
  Class: ProfileUpdate
    Properties:
      - var email: String?
      - var name: String?
      - var preferredUnits: String?
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/ViewModelProtocol.swift

---
Classes:
  Class: ViewModelProtocol
    Methods:
      - func initialize() async {
      - func refresh() async {
      - func cleanup() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/WeatherServiceProtocol.swift

---
Classes:
  Class: WeatherData
    Properties:
      - let temperature: Double
      - let condition: String
      - let humidity: Int
      - let windSpeed: Double
      - let uvIndex: Int?
      - let timestamp: Date
  Class: WeatherForecast
    Properties:
      - let days: [WeatherDay]
      - let location: String
      - let timestamp: Date
  Class: WeatherDay
    Properties:
      - let date: Date
      - let high: Double
      - let low: Double
      - let condition: String
      - let precipitationChance: Int
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/WhisperServiceWrapperProtocol.swift

---
Classes:
  Class: TranscriptionError

Enums:
  - TranscriptionError
    Cases:
      - unavailable
      - permissionDenied
      - failedToStart
      - processingError
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Protocols/WorkoutServiceProtocol.swift

---

---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Theme/AppColors.swift

---
Classes:
  Class: AppColors
    Properties:
      - static let backgroundPrimary = Color("BackgroundPrimary")
      - static let backgroundSecondary = Color("BackgroundSecondary")
      - static let backgroundTertiary = Color("BackgroundTertiary")
      - static let textPrimary = Color("TextPrimary")
      - static let textSecondary = Color("TextSecondary")
      - static let textTertiary = Color("TextTertiary")
      - static let textOnAccent = Color("TextOnAccent")
      - static let cardBackground = Color("CardBackground")
      - static let dividerColor = Color("DividerColor")
      - static let shadowColor = Color.black.opacity(0.1)
      - static let overlayColor = Color.black.opacity(0.4)
      - static let buttonBackground = Color("ButtonBackground")
      - static let buttonText = Color("ButtonText")
      - static let accentColor = Color("AccentColor")
      - static let accent = accentColor // Alias for consistency
      - static let accentSecondary = Color("AccentSecondary")
      - static let errorColor = Color("ErrorColor")
      - static let successColor = Color("SuccessColor")
      - static let warningColor = Color("WarningColor")
      - static let infoColor = Color("InfoColor")
      - static let caloriesColor = Color("CaloriesColor")
      - static let proteinColor = Color("ProteinColor")
      - static let carbsColor = Color("CarbsColor")
      - static let fatColor = Color("FatColor")
      - static let primaryGradient = LinearGradient(
 colors: [accentColor, accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing
      - static let caloriesGradient = LinearGradient(
 colors: [caloriesColor.opacity(0.8), caloriesColor], startPoint: .topLeading, endPoint: .bottomTrailing
      - static let proteinGradient = LinearGradient(
 colors: [proteinColor.opacity(0.8), proteinColor], startPoint: .topLeading, endPoint: .bottomTrailing
      - static let carbsGradient = LinearGradient(
 colors: [carbsColor.opacity(0.8), carbsColor], startPoint: .topLeading, endPoint: .bottomTrailing
      - static let fatGradient = LinearGradient(
 colors: [fatColor.opacity(0.8), fatColor], startPoint: .topLeading, endPoint: .bottomTrailing
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Theme/AppFonts.swift

---
Classes:
  Class: AppFonts
  Class: Size
    Properties:
      - static let largeTitle = Font.system(size: Size.largeTitle, weight: .bold, design: .rounded)
      - static let title = Font.system(size: Size.title, weight: .bold, design: .rounded)
      - static let title2 = Font.system(size: Size.title2, weight: .semibold, design: .rounded)
      - static let title3 = Font.system(size: Size.title3, weight: .semibold, design: .rounded)
      - static let headline = Font.system(size: Size.headline, weight: .semibold, design: .default)
      - static let body = Font.system(size: Size.body, weight: .regular, design: .default)
      - static let bodyBold = Font.system(size: Size.body, weight: .semibold, design: .default)
      - static let callout = Font.system(size: Size.callout, weight: .regular, design: .default)
      - static let subheadline = Font.system(size: Size.subheadline, weight: .regular, design: .default)
      - static let footnote = Font.system(size: Size.footnote, weight: .regular, design: .default)
      - static let caption = Font.system(size: Size.caption, weight: .regular, design: .default)
      - static let captionBold = Font.system(size: Size.caption, weight: .medium, design: .default)
      - static let caption2 = Font.system(size: Size.caption2, weight: .regular, design: .default)
      - static let numberLarge = Font.system(size: Size.title, weight: .bold, design: .rounded)
      - static let numberMedium = Font.system(size: Size.title3, weight: .semibold, design: .rounded)
      - static let numberSmall = Font.system(size: Size.body, weight: .medium, design: .rounded)
    Methods:
      - func appFont(_ font: Font) -> Text {
      - func primaryTitle() -> Text {
      - func secondaryBody() -> Text {

Enums:
  - Size
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Theme/AppShadows.swift

---
Classes:
  Class: AppShadows
    Properties:
      - static let small = Shadow(
 color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2
      - static let medium = Shadow(
 color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4
      - static let large = Shadow(
 color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8
      - static let card = Shadow(
 color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5
      - static let elevated = Shadow(
 color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10
      - static let accent = Shadow(
 color: AppColors.accentColor.opacity(0.3), radius: 12, x: 0, y: 6
      - static let success = Shadow(
 color: AppColors.successColor.opacity(0.3), radius: 8, x: 0, y: 4
      - static let error = Shadow(
 color: AppColors.errorColor.opacity(0.3), radius: 8, x: 0, y: 4
  Class: Shadow
    Properties:
      - let color: Color
      - let radius: CGFloat
      - let x: CGFloat
      - let y: CGFloat
    Methods:
      - func appShadow(_ shadow: Shadow) -> some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Theme/AppSpacing.swift

---
Classes:
  Class: AppSpacing

Enums:
  - AppSpacing
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/AppLogger.swift

---
Classes:
  Class: AppLogger
  Class: Category
    Methods:
      - static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
      - static func info(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
      - static func warning(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
  Class: LogContext
    Properties:
      - let file: String
      - let function: String
      - let line: Int
    Methods:
      - static func error(
        _ message: String,
        error: Error? = nil,
        category: Category = .general,
        context: LogContext = LogContext()
    ) {
      - static func fault(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
      - private static func log(
        _ message: String,
        category: Category,
        level: OSLogType,
        context: LogContext
    ) {
      - private static func emojiForLevel(_ level: OSLogType) -> String {
      - static func measure<T>(
        _ label: String,
        category: Category = .performance,
        operation: () throws -> T
    ) rethrows -> T {
      - static func measureAsync<T>(
        _ label: String,
        category: Category = .performance,
        operation: () async throws -> T
    ) async rethrows -> T {

Enums:
  - AppLogger
  - Category
    Cases:
      - general
      - ui
      - data
      - network
      - networking
      - health
      - ai
      - auth
      - onboarding
      - meals
      - performance
      - app
      - storage
      - chat
      - notifications
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/AppState.swift

---
Classes:
  Class: AppState
    Properties:
      - private(set) var isLoading = true
      - private(set) var currentUser: User?
      - private(set) var hasCompletedOnboarding = false
      - private(set) var error: Error?
      - private let modelContext: ModelContext
      - private let isUITesting: Bool
      - private let healthKitAuthManager: HealthKitAuthManager
      - var shouldShowOnboarding: Bool {
      - var healthKitStatus: HealthKitAuthorizationStatus {
      - var shouldCreateUser: Bool {
      - var shouldShowDashboard: Bool {
    Methods:
      - func loadUserState() async {
      - func createNewUser() async throws {
      - func completeOnboarding() async {
      - func clearError() {
      - @discardableResult
    func requestHealthKitAuthorization() async -> Bool {
      - private func setupUITestingState() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/DependencyContainer.swift

---
Classes:
  Class: DependencyContainer
    Properties:
      - static let shared = DependencyContainer()
      - private(set) var modelContainer: ModelContainer?
      - private(set) var networkClient: NetworkClientProtocol
      - private(set) var keychain: KeychainWrapper
      - private(set) var logger: AppLogger.Type
      - private(set) var aiService: AIServiceProtocol?
      - private(set) var userService: UserServiceProtocol?
      - private(set) var apiKeyManager: APIKeyManagerProtocol?
      - private(set) var notificationManager: NotificationManager?
    Methods:
      - func configure(with modelContainer: ModelContainer) {
      - func makeModelContext() -> ModelContext? {
      - func register<T>(service: T, for type: T.Type) {
  Class: DependencyContainerKey
    Properties:
      - static let defaultValue = DependencyContainer.shared
      - var dependencies: DependencyContainer {
    Methods:
      - func withDependencies(_ container: DependencyContainer = .shared) -> some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/Formatters.swift

---
Classes:
  Class: Formatters
  Class: WeightUnit
    Methods:
      - static func formatCalories(_ calories: Double) -> String {
      - static func formatMacro(_ grams: Double, suffix: String = "g") -> String {
      - static func formatWeight(_ kilograms: Double, unit: WeightUnit = .metric) -> String {

Enums:
  - Formatters
  - WeightUnit
    Cases:
      - metric
      - imperial
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/HapticManager.swift

---
Classes:
  Class: HapticManager
    Properties:
      - static let shared = HapticManager()
      - private var engine: CHHapticEngine?
      - private let impactFeedback = UIImpactFeedbackGenerator()
      - private let notificationFeedback = UINotificationFeedbackGenerator()
      - private let selectionFeedback = UISelectionFeedbackGenerator()
      - var intensity: CGFloat {
    Methods:
      - static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
      - static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
      - static func selection() {
      - private func setupHapticEngine() {
      - private func prepareGenerators() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/HealthKitAuthManager.swift

---
Classes:
  Class: HealthKitAuthManager
    Properties:
      - private let healthKitManager: HealthKitManaging
      - var authorizationStatus: HealthKitAuthorizationStatus = .notDetermined
    Methods:
      - @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
      - func refreshStatus() {
      - private static func map(status: HealthKitManager.AuthorizationStatus) -> HealthKitAuthorizationStatus {
  Class: HealthKitAuthorizationStatus

Enums:
  - HealthKitAuthorizationStatus
    Cases:
      - notDetermined
      - authorized
      - denied
      - restricted
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/KeychainWrapper.swift

---
Classes:
  Class: KeychainWrapper
    Properties:
      - static let shared = KeychainWrapper()
      - private let service = Bundle.main.bundleIdentifier ?? "com.airfit.app"
    Methods:
      - func save(_ data: Data, forKey key: String) throws {
      - func load(key: String) throws -> Data {
      - func delete(key: String) throws {
      - func update(_ data: Data, forKey key: String) throws {
      - func exists(key: String) -> Bool {
  Class: KeychainError
    Methods:
      - func saveString(_ string: String, forKey key: String) throws {
      - func loadString(key: String) throws -> String {
      - func saveCodable<T: Codable>(_ object: T, forKey key: String) throws {
      - func loadCodable<T: Codable>(_ type: T.Type, key: String) throws -> T {

Enums:
  - KeychainError
    Cases:
      - itemNotFound
      - duplicateItem
      - invalidData
      - unhandledError
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/NetworkReachability.swift

---
Classes:
  Class: NetworkReachability
    Properties:
      - static let shared = NetworkReachability()
      - @Published private(set) var isConnected: Bool = true
      - @Published private(set) var connectionType: ConnectionType = .unknown
      - @Published private(set) var isExpensive: Bool = false
      - @Published private(set) var isConstrained: Bool = false
      - private let monitor: NWPathMonitor
      - private let queue = DispatchQueue(label: "com.airfit.networkmonitor")
      - private var cancellables = Set<AnyCancellable>()
  Class: ConnectionType
    Properties:
      - var connectionQuality: ConnectionQuality {
    Methods:
      - func startMonitoring() {
      - func stopMonitoring() {
      - func isHostReachable(_ host: String) async -> Bool {
      - func waitForConnectivity(timeout: TimeInterval = 30) async throws {
      - private func updateConnectionStatus(_ path: NWPath) {
      - private func logConnectionChange() {
  Class: ConnectionQuality
  Class: ReachabilityError
    Properties:
      - var statusMessage: String {
      - var shouldShowOfflineAlert: Bool {
      - var connectionPublisher: AnyPublisher<Bool, Never> {
      - var connectionTypePublisher: AnyPublisher<ConnectionType, Never> {
      - var connectionQualityPublisher: AnyPublisher<ConnectionQuality, Never> {
    Methods:
      - func performWithConnectivity<T: Sendable>(
        timeout: TimeInterval = 30,
        operation: () async throws -> T
    ) async throws -> T {

Enums:
  - ConnectionType
    Cases:
      - wifi
      - cellular
      - ethernet
      - unknown
      - none
  - ConnectionQuality
    Cases:
      - good
      - moderate
      - poor
      - unknown
      - none
  - ReachabilityError
    Cases:
      - noConnection
      - timeout
      - hostUnreachable
      - poorConnection
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/PersonaMigrationUtility.swift

---
Classes:
  Class: PersonaMigrationUtility
    Methods:
      - static func migrateBlendToPersonaMode(_ blend: Blend) -> PersonaMode {
      - static func migrateUserProfile(_ profile: UserProfileJsonBlob) -> UserProfileJsonBlob {
      - static func needsMigration(_ profile: UserProfileJsonBlob) -> Bool {
      - static func createNewProfile(
        lifeContext: LifeContext,
        goal: Goal,
        selectedPersonaMode: PersonaMode,
        engagementPreferences: EngagementPreferences,
        sleepWindow: SleepWindow,
        motivationalStyle: MotivationalStyle,
        timezone: String = TimeZone.current.identifier
    ) -> UserProfileJsonBlob {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Utilities/Validators.swift

---
Classes:
  Class: Validators
  Class: ValidationResult
    Methods:
      - static func validateEmail(_ email: String) -> ValidationResult {
      - static func validatePassword(_ password: String) -> ValidationResult {
      - static func validateAge(_ age: Int) -> ValidationResult {
      - static func validateWeight(_ weight: Double) -> ValidationResult {
      - static func validateHeight(_ height: Double) -> ValidationResult {

Enums:
  - Validators
  - ValidationResult
    Cases:
      - success
      - failure
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Views/CommonComponents.swift

---
Classes:
  Class: SectionHeader
    Properties:
      - let title: String
      - let icon: String?
      - let action: (() -> Void)?
      - public var body: some View {
  Class: EmptyStateView
    Properties:
      - let icon: String
      - let title: String
      - let message: String
      - let action: (() -> Void)?
      - let actionTitle: String?
      - public var body: some View {
  Class: Card
    Properties:
      - let content: () -> Content
      - public var body: some View {
  Class: LoadingOverlay
    Properties:
      - let isLoading: Bool
      - let message: String?
    Methods:
      - public func body(content: Content) -> some View {
      - func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Core/Views/ErrorPresentationView.swift

---
Classes:
  Class: ErrorPresentationView
    Properties:
      - let error: Error
      - let style: ErrorStyle
      - let retryAction: (() async -> Void)?
      - let dismissAction: (() -> Void)?
      - @Environment(\.dismiss) private var dismiss
      - @State private var isRetrying = false
  Class: ErrorStyle
    Properties:
      - var body: some View {
      - private var inlineView: some View {
      - private var cardView: some View {
      - private var fullScreenView: some View {
      - private var toastView: some View {
      - private var retryButton: some View {
      - private var errorTitle: String {
      - private var recoverySuggestion: String? {
      - private var errorIcon: String {
      - var icon: String {
    Methods:
      - func errorOverlay(
        error: Binding<Error?>,
        style: ErrorPresentationView.ErrorStyle = .card,
        retryAction: (() async -> Void)? = nil
    ) -> some View {
      - func errorToast(
        error: Binding<Error?>,
        duration: TimeInterval = 4.0
    ) -> some View {
  Class: ErrorPresentationView_Previews
    Properties:
      - static var previews: some View {

Enums:
  - ErrorStyle
    Cases:
      - inline
      - card
      - fullScreen
      - toast
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Extensions/FetchDescriptor+Convenience.swift

---
Classes:
  Class: FetchDescriptor+Convenience
    Properties:
      - static var activeUser: FetchDescriptor<User> {
      - static var systemTemplates: FetchDescriptor<WorkoutTemplate> {
      - static var favoriteTemplates: FetchDescriptor<WorkoutTemplate> {
      - static var systemTemplates: FetchDescriptor<MealTemplate> {
      - static var activeChats: FetchDescriptor<ChatSession> {
      - static var archivedChats: FetchDescriptor<ChatSession> {
    Methods:
      - static func forDate(_ date: Date) -> FetchDescriptor<DailyLog> {
      - static func dateRange(from start: Date, to end: Date) -> FetchDescriptor<DailyLog> {
      - static func forMealType(_ mealType: MealType, on date: Date) -> FetchDescriptor<FoodEntry> {
      - static func recentEntries(days: Int = 7) -> FetchDescriptor<FoodEntry> {
      - static func upcoming(limit: Int = 10) -> FetchDescriptor<Workout> {
      - static func completed(days: Int = 30) -> FetchDescriptor<Workout> {
      - static func forMealType(_ mealType: MealType) -> FetchDescriptor<MealTemplate> {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Extensions/ModelContainer+Test.swift

---
Classes:
  Class: ModelContainer+Test
    Properties:
      - static var preview: ModelContainer {
    Methods:
      - static func createTestContainer() throws -> ModelContainer {
      - @MainActor
    static func createTestContainerWithSampleData() throws -> ModelContainer {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Managers/DataManager.swift

---
Classes:
  Class: DataManager
    Properties:
      - static let shared = DataManager()
      - static var preview: DataManager {
      - static var previewContainer: ModelContainer {
      - private var _previewContainer: ModelContainer? {
      - var modelContext: ModelContext {
    Methods:
      - func performInitialSetup(with container: ModelContainer) async {
      - private func createSystemTemplatesIfNeeded(context: ModelContext) async {
      - private func createDefaultWorkoutTemplates(context: ModelContext) {
      - private func createDefaultMealTemplates(context: ModelContext) {
      - func fetchFirst<T: PersistentModel>(_ type: T.Type, where predicate: Predicate<T>? = nil) throws -> T? {
      - func count<T: PersistentModel>(_ type: T.Type, where predicate: Predicate<T>? = nil) throws -> Int {
      - static func createMemoryContainer() -> ModelContainer {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Migrations/SchemaV1.swift

---
Classes:
  Class: SchemaV1
  Class: AirFitMigrationPlan

Enums:
  - SchemaV1
  - AirFitMigrationPlan
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ChatAttachment.swift

---
Classes:
  Class: ChatAttachment
    Properties:
      - var id: UUID
      - var type: String // "image", "document", "data"
      - var filename: String
      - var mimeType: String?
      - var data: Data
      - var thumbnailData: Data?
      - var metadata: Data? // JSON encoded metadata
      - var uploadedAt: Date
      - var message: ChatMessage?
      - var fileSize: Int {
      - var formattedFileSize: String {
      - var attachmentType: AttachmentType? {
      - var typeEnum: AttachmentType {
      - var isImage: Bool {
      - var isDocument: Bool {
      - var fileExtension: String? {
    Methods:
      - func generateThumbnail() {
      - func setMetadata(_ dict: [String: Any]) {
      - func getMetadata() -> [String: Any]? {
  Class: AttachmentType

Enums:
  - AttachmentType
    Cases:
      - image
      - document
      - data
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ChatMessage.swift

---
Classes:
  Class: ChatMessage
  Class: MessageType
    Properties:
      - var id: UUID
      - var timestamp: Date
      - var role: String // "user", "assistant", "system"
      - var content: String
      - var isRead: Bool
      - var isEdited: Bool
      - var editedAt: Date?
      - var modelUsed: String?
      - var tokenCount: Int?
      - var processingTimeMs: Int?
      - var errorMessage: String?
      - var functionCallName: String?
      - var functionCallArgs: String?
      - var session: ChatSession?
      - var attachments: [ChatAttachment] = []
      - var roleEnum: MessageType {
      - var hasAttachments: Bool {
      - var formattedTime: String {
      - var isUserMessage: Bool {
      - var isAssistantMessage: Bool {
    Methods:
      - func markAsRead() {
      - func edit(newContent: String) {
      - func addAttachment(_ attachment: ChatAttachment) {
      - func recordMetadata(model: String, tokens: Int, processingTime: TimeInterval) {
      - func recordError(_ error: String) {
      - func recordFunctionCall(name: String, args: String) {

Enums:
  - MessageType
    Cases:
      - user
      - assistant
      - system
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ChatSession.swift

---
Classes:
  Class: ChatSession
    Properties:
      - var id: UUID
      - var title: String?
      - var createdAt: Date
      - var lastMessageDate: Date?
      - var isActive: Bool
      - var archivedAt: Date?
      - var messageCount: Int
      - var messages: [ChatMessage] = []
      - var user: User?
      - var displayTitle: String {
      - var formattedDate: String {
      - var hasUnreadMessages: Bool {
      - var lastMessage: ChatMessage? {
    Methods:
      - func addMessage(_ message: ChatMessage) {
      - func archive() {
      - func reactivate() {
      - func generateTitle() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/CoachMessage.swift

---
Classes:
  Class: CoachMessage
    Properties:
      - var id: UUID
      - var timestamp: Date
      - var role: String
      - var content: String
      - var userID: UUID
      - var conversationID: UUID?
      - private var messageTypeRawValue: String = MessageType.conversation.rawValue
      - var messageType: MessageType {
      - var modelUsed: String?
      - var promptTokens: Int?
      - var completionTokens: Int?
      - var totalTokens: Int?
      - var temperature: Double?
      - var responseTimeMs: Int?
      - var functionCallData: Data?
      - var functionResultData: Data?
      - var userRating: Int? // 1-5
      - var userFeedback: String?
      - var wasHelpful: Bool?
      - var user: User?
      - var messageRole: MessageRole? {
      - var isCommand: Bool {
      - var functionCall: FunctionCall? {
      - var functionResult: FunctionResult? {
      - var estimatedCost: Double? {
    Methods:
      - func recordAIMetadata(
        model: String,
        promptTokens: Int,
        completionTokens: Int,
        temperature: Double,
        responseTime: TimeInterval
    ) {
      - func recordUserFeedback(rating: Int? = nil, feedback: String? = nil, helpful: Bool? = nil) {
  Class: MessageRole
  Class: FunctionCall
    Properties:
      - let name: String
      - let arguments: [String: AnyCodable]
  Class: FunctionResult
    Properties:
      - let success: Bool
      - let result: AnyCodable?
      - let error: String?
  Class: AnyCodable
    Properties:
      - let value: Any
    Methods:
      - func encode(to encoder: Encoder) throws {

Enums:
  - MessageRole
    Cases:
      - system
      - user
      - assistant
      - function
      - tool
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ConversationResponse.swift

---
Classes:
  Class: ConversationResponse
    Properties:
      - @Attribute(.unique) var id: UUID
      - var sessionId: UUID
      - var nodeId: String
      - var responseData: Data
      - var timestamp: Date
      - var isValid: Bool
      - @Relationship(inverse: \ConversationSession.responses) var session: ConversationSession?
  Class: ResponseValue
    Methods:
      - func getValue() throws -> ResponseValue {
      - func setValue(_ value: ResponseValue) throws {

Enums:
  - ResponseValue
    Cases:
      - text
      - choice
      - multiChoice
      - slider
      - voice
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ConversationSession.swift

---
Classes:
  Class: ConversationSession
    Properties:
      - @Attribute(.unique) var id: UUID
      - var userId: UUID
      - var startedAt: Date
      - var completedAt: Date?
      - var currentNodeId: String?
      - var isComplete: Bool
      - @Relationship(deleteRule: .cascade) var responses: [ConversationResponse]
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/DailyLog.swift

---
Classes:
  Class: DailyLog
    Properties:
      - var date: Date
      - var subjectiveEnergyLevel: Int? // 1-5
      - var sleepQuality: Int? // 1-5
      - var stressLevel: Int? // 1-5
      - var mood: String?
      - var weight: Double? // kg
      - var bodyFat: Double? // percentage
      - var notes: String?
      - var checkedIn: Bool = false
      - var steps: Int?
      - var activeCalories: Double?
      - var exerciseMinutes: Int?
      - var standHours: Int?
      - var user: User?
      - var overallWellness: Double? {
      - var hasHealthMetrics: Bool {
      - var hasSubjectiveMetrics: Bool {
    Methods:
      - func updateHealthMetrics(
        steps: Int? = nil,
        activeCalories: Double? = nil,
        exerciseMinutes: Int? = nil,
        standHours: Int? = nil
    ) {
      - func checkIn(
        energy: Int? = nil,
        sleep: Int? = nil,
        stress: Int? = nil,
        mood: String? = nil
    ) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/Exercise.swift

---
Classes:
  Class: Exercise
    Properties:
      - var id: UUID
      - var name: String
      - var muscleGroupsData: Data?
      - var equipmentData: Data?
      - var notes: String?
      - var orderIndex: Int
      - var restSeconds: TimeInterval?
      - var sets: [ExerciseSet] = []
      - var workout: Workout?
      - var muscleGroups: [String] {
      - var equipment: [String] {
      - var completedSets: [ExerciseSet] {
      - var bestSet: ExerciseSet? {
      - var totalVolume: Double? {
    Methods:
      - func addSet(_ set: ExerciseSet) {
      - func duplicateLastSet() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ExerciseSet.swift

---
Classes:
  Class: ExerciseSet
    Properties:
      - var id: UUID
      - var setNumber: Int
      - var targetReps: Int?
      - var completedReps: Int?
      - var targetWeightKg: Double?
      - var completedWeightKg: Double?
      - var targetDurationSeconds: TimeInterval?
      - var completedDurationSeconds: TimeInterval?
      - var rpe: Double? // Rate of Perceived Exertion (1-10)
      - var restDurationSeconds: TimeInterval?
      - var notes: String?
      - var completedAt: Date?
      - var exercise: Exercise?
      - var isCompleted: Bool {
      - var volume: Double? {
      - var oneRepMax: Double? {
      - var intensityPercentage: Double? {
    Methods:
      - func complete(
        reps: Int? = nil,
        weight: Double? = nil,
        duration: TimeInterval? = nil,
        rpe: Double? = nil
    ) {
      - func reset() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ExerciseTemplate.swift

---
Classes:
  Class: ExerciseTemplate
    Properties:
      - var id: UUID
      - var name: String
      - var muscleGroupsData: Data?
      - var orderIndex: Int
      - var restSeconds: TimeInterval?
      - var notes: String?
      - var sets: [SetTemplate] = []
      - var workoutTemplate: WorkoutTemplate?
      - var muscleGroups: [String] {
      - var totalVolume: Double? {
      - var formattedRestTime: String? {
    Methods:
      - func addSet(_ set: SetTemplate) {
      - func removeSet(at index: Int) {
      - func duplicateLastSet() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/FoodEntry.swift

---
Classes:
  Class: FoodEntry
    Properties:
      - var id: UUID
      - var loggedAt: Date
      - var mealType: String
      - var rawTranscript: String?
      - var photoData: Data?
      - var notes: String?
      - var parsingModelUsed: String?
      - var parsingConfidence: Double?
      - var parsingTimestamp: Date?
      - var items: [FoodItem] = []
      - var nutritionData: NutritionData?
      - var user: User?
      - var totalCalories: Int {
      - var totalProtein: Double {
      - var totalCarbs: Double {
      - var totalFat: Double {
      - var mealTypeEnum: MealType? {
      - var isComplete: Bool {
      - var mealDisplayName: String {
    Methods:
      - func addItem(_ item: FoodItem) {
      - func updateFromAIParsing(model: String, confidence: Double) {
      - func duplicate() -> FoodEntry {
  Class: MealType

Enums:
  - MealType
    Cases:
      - breakfast
      - lunch
      - dinner
      - snack
      - preWorkout
      - postWorkout
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/FoodItem.swift

---
Classes:
  Class: FoodItem
    Properties:
      - var id: UUID
      - var name: String
      - var brand: String?
      - var barcode: String?
      - var quantity: Double?
      - var unit: String?
      - var calories: Double?
      - var proteinGrams: Double?
      - var carbGrams: Double?
      - var fatGrams: Double?
      - var fiberGrams: Double?
      - var sugarGrams: Double?
      - var sodiumMg: Double?
      - var servingSize: String?
      - var servingsConsumed: Double = 1.0
      - var dataSource: String? // "user", "database", "ai_parsed", "barcode"
      - var databaseID: String? // External database reference
      - var verificationStatus: String? // "verified", "unverified", "user_modified"
      - var foodEntry: FoodEntry?
      - var actualCalories: Double {
      - var actualProtein: Double {
      - var actualCarbs: Double {
      - var actualFat: Double {
      - var macroPercentages: FoodMacroPercentages? {
      - var isValid: Bool {
    Methods:
      - func updateNutrition(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil
    ) {
  Class: FoodMacroPercentages
    Properties:
      - let protein: Double
      - let carbs: Double
      - let fat: Double
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/FoodItemTemplate.swift

---
Classes:
  Class: FoodItemTemplate
    Properties:
      - var id: UUID
      - var name: String
      - var brand: String?
      - var quantity: Double?
      - var unit: String?
      - var calories: Double?
      - var proteinGrams: Double?
      - var carbGrams: Double?
      - var fatGrams: Double?
      - var fiberGrams: Double?
      - var sugarGrams: Double?
      - var sodiumMg: Double?
      - var servingSize: String?
      - var mealTemplate: MealTemplate?
      - var macroPercentages: MacroPercentages? {
      - var isComplete: Bool {
      - var formattedQuantity: String? {
    Methods:
      - func updateNutrition(
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil
    ) {
      - func duplicate() -> FoodItemTemplate {
  Class: MacroPercentages
    Properties:
      - let protein: Double
      - let carbs: Double
      - let fat: Double
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/HealthKitSyncRecord.swift

---
Classes:
  Class: HealthKitSyncRecord
    Properties:
      - var id: UUID
      - var dataType: String // HKQuantityType identifier
      - var lastSyncDate: Date
      - var syncDirection: String // "read", "write", "both"
      - var recordCount: Int
      - var success: Bool
      - var errorMessage: String?
      - var user: User?
    Methods:
      - func recordSync(count: Int, success: Bool, error: String? = nil) {
  Class: SyncDirection

Enums:
  - SyncDirection
    Cases:
      - read
      - write
      - both
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/MealTemplate.swift

---
Classes:
  Class: MealTemplate
    Properties:
      - var id: UUID
      - var name: String
      - var mealType: String
      - var descriptionText: String?
      - var photoData: Data?
      - var estimatedCalories: Double?
      - var estimatedProtein: Double?
      - var estimatedCarbs: Double?
      - var estimatedFat: Double?
      - var isSystemTemplate: Bool = false
      - var isFavorite: Bool = false
      - var lastUsedDate: Date?
      - var useCount: Int = 0
      - var items: [FoodItemTemplate] = []
      - var mealTypeEnum: MealType? {
      - var totalCalories: Double {
      - var totalProtein: Double {
      - var totalCarbs: Double {
      - var totalFat: Double {
      - var macroBreakdown: MacroBreakdown? {
    Methods:
      - func recordUse() {
      - func toggleFavorite() {
      - func addItem(_ item: FoodItemTemplate) {
      - func removeItem(_ item: FoodItemTemplate) {
      - private func updateEstimates() {
      - func createFoodEntry(for user: User) -> FoodEntry {
  Class: MacroBreakdown
    Properties:
      - let protein: Double
      - let carbs: Double
      - let fat: Double
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/NutritionData.swift

---
Classes:
  Class: NutritionData
    Properties:
      - var id: UUID
      - var date: Date
      - var targetCalories: Double?
      - var targetProtein: Double?
      - var targetCarbs: Double?
      - var targetFat: Double?
      - var actualCalories: Double = 0
      - var actualProtein: Double = 0
      - var actualCarbs: Double = 0
      - var actualFat: Double = 0
      - var waterLiters: Double = 0
      - var notes: String?
      - var foodEntries: [FoodEntry] = []
      - var calorieDeficit: Double? {
      - var proteinProgress: Double {
      - var carbsProgress: Double {
      - var fatProgress: Double {
      - var isComplete: Bool {
    Methods:
      - func updateActuals() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/OnboardingProfile.swift

---
Classes:
  Class: OnboardingProfile
    Properties:
      - var id: UUID
      - var createdAt: Date
      - var personaPromptData: Data
      - var communicationPreferencesData: Data
      - var rawFullProfileData: Data
      - var user: User?
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/SetTemplate.swift

---
Classes:
  Class: SetTemplate
    Properties:
      - var id: UUID
      - var setNumber: Int
      - var targetReps: Int?
      - var targetWeightKg: Double?
      - var targetDurationSeconds: TimeInterval?
      - var notes: String?
      - var exerciseTemplate: ExerciseTemplate?
      - var isTimeBasedSet: Bool {
      - var isRepBasedSet: Bool {
      - var formattedTarget: String {
    Methods:
      - func duplicate() -> SetTemplate {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/User.swift

---
Classes:
  Class: User
    Properties:
      - var id: UUID
      - var createdAt: Date
      - var lastActiveAt: Date
      - var email: String?
      - var name: String?
      - var preferredUnits: String // "imperial" or "metric"
      - var isMetric: Bool {
      - var nutritionPreferences: NutritionPreferences {
      - var daysActive: Int {
      - var isInactive: Bool {
      - var activeChats: [ChatSession] {
      - var onboardingProfile: OnboardingProfile?
      - var foodEntries: [FoodEntry] = []
      - var workouts: [Workout] = []
      - var dailyLogs: [DailyLog] = []
      - var coachMessages: [CoachMessage] = []
      - var healthKitSyncRecords: [HealthKitSyncRecord] = []
      - var chatSessions: [ChatSession] = []
      - static let example = User(
 email: "john@example.com", name: "John Doe", preferredUnits: "imperial"
    Methods:
      - func updateActivity() {
      - func getTodaysLog() -> DailyLog? {
      - func getRecentMeals(days: Int = 7) -> [FoodEntry] {
      - func getRecentWorkouts(days: Int = 7) -> [Workout] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/Workout.swift

---
Classes:
  Class: Workout
    Properties:
      - var id: UUID
      - var name: String
      - var plannedDate: Date?
      - var completedDate: Date?
      - var durationSeconds: TimeInterval?
      - var caloriesBurned: Double?
      - var notes: String?
      - var workoutType: String
      - var intensity: String? // "low", "moderate", "high"
      - var healthKitWorkoutID: String?
      - var healthKitSyncedDate: Date?
      - var templateID: UUID?
      - var aiAnalysis: String?
      - var exercises: [Exercise] = []
      - var user: User?
      - var isCompleted: Bool {
      - var duration: TimeInterval? {
      - var totalSets: Int {
      - var totalVolume: Double {
      - var workoutTypeEnum: WorkoutType? {
      - var formattedDuration: String? {
    Methods:
      - func startWorkout() {
      - func completeWorkout() {
      - func addExercise(_ exercise: Exercise) {
      - func createFromTemplate(_ template: WorkoutTemplate) {
  Class: WorkoutType

Enums:
  - WorkoutType
    Cases:
      - strength
      - cardio
      - flexibility
      - sports
      - general
      - hiit
      - yoga
      - pilates
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/WorkoutTemplate.swift

---
Classes:
  Class: WorkoutTemplate
    Properties:
      - var id: UUID
      - var name: String
      - var descriptionText: String?
      - var workoutType: String
      - var estimatedDuration: TimeInterval?
      - var difficulty: String? // "beginner", "intermediate", "advanced"
      - var isSystemTemplate: Bool = false
      - var isFavorite: Bool = false
      - var lastUsedDate: Date?
      - var useCount: Int = 0
      - var exercises: [ExerciseTemplate] = []
      - var workoutTypeEnum: WorkoutType? {
      - var difficultyLevel: DifficultyLevel? {
      - var formattedDuration: String? {
      - var totalSets: Int {
    Methods:
      - func recordUse() {
      - func toggleFavorite() {
      - func addExercise(_ exercise: ExerciseTemplate) {
  Class: DifficultyLevel

Enums:
  - DifficultyLevel
    Cases:
      - beginner
      - intermediate
      - advanced
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Components/ConversationStateManager.swift

---
Classes:
  Class: ConversationStateManager
  Class: ConversationState
    Properties:
      - let id: UUID
      - let userId: UUID
      - let startTime: Date
      - var messageCount: Int
      - var lastInteraction: Date
      - var activeMode: PersonaMode
      - var contextWindow: Int
      - var isStale: Bool {
      - private var sessions: [UUID: ConversationState] = [:]
      - private let maxSessions = 10
      - private let defaultContextWindow = 20
    Methods:
      - func createSession(
        userId: UUID,
        mode: PersonaMode,
        contextWindow: Int? = nil
    ) -> UUID {
      - func getSession(_ id: UUID) -> ConversationState? {
      - func updateSession(_ id: UUID, messageProcessed: Bool = true) {
      - func updateMode(_ id: UUID, mode: PersonaMode) {
      - func endSession(_ id: UUID) {
      - func getOptimalHistoryLimit(for sessionId: UUID, messageType: MessageType) -> Int {
      - func shouldResetContext(for sessionId: UUID) -> Bool {
      - private func removeOldestSession() {
      - func cleanupStaleSessions() {
      - func getActiveSessionCount() -> Int {
      - func getSessionMetrics() -> [String: Any] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Components/DirectAIProcessor.swift

---
Classes:
  Class: DirectAIProcessor
    Properties:
      - private let aiService: AIServiceProtocol
      - private let nutritionParsingConfig = AIConfig(
 temperature: 0.1,      // Low for consistent parsing maxTokens: 500,        // Optimized for JSON responses systemPrompt: "You are a precision nutrition expert. Return only valid JSON without explanations."
      - private let educationalContentConfig = AIConfig(
 temperature: 0.7,      // Higher for creative content maxTokens: 800,        // Sufficient for detailed content systemPrompt: "You are an expert fitness educator providing personalized, science-based guidance."
  Class: AIConfig
    Properties:
      - let temperature: Double
      - let maxTokens: Int
      - let systemPrompt: String
    Methods:
      - func parseNutrition(
        foodText: String,
        context: String = "",
        user: User,
        conversationId: UUID? = nil
    ) async throws -> NutritionParseResult {
      - func generateEducationalContent(
        topic: String,
        userContext: String,
        userProfile: UserProfileJsonBlob
    ) async throws -> EducationalContent {
      - func generateSimpleResponse(
        text: String,
        userProfile: UserProfileJsonBlob,
        healthContext: HealthContextSnapshot
    ) async throws -> String {
      - private func executeAIRequest(
        prompt: String,
        config: AIConfig,
        userId: String
    ) async throws -> String {
      - private func buildNutritionPrompt(foodText: String, context: String) -> String {
      - private func buildEducationalPrompt(
        topic: String,
        userContext: String,
        userProfile: UserProfileJsonBlob
    ) -> String {
      - private func parseNutritionJSON(_ response: String) throws -> [NutritionItem] {
      - private func validateNutritionItems(_ items: [NutritionItem]) -> [NutritionItem] {
      - private func extractJSON(from response: String) -> String {
      - private func estimateTokenCount(_ text: String) -> Int {
      - private func calculatePersonalization(_ content: String, userProfile: UserProfileJsonBlob) -> Double {
      - private func classifyContentType(_ topic: String) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Components/MessageProcessor.swift

---
Classes:
  Class: MessageProcessor
    Properties:
      - private let localCommandParser: LocalCommandParser
      - private let contextAnalyzer = ContextAnalyzer()
    Methods:
      - func classifyMessage(_ text: String) -> MessageType {
      - func checkLocalCommand(_ text: String, for user: User) async -> LocalCommand? {
      - func generateLocalCommandResponse(_ command: LocalCommand) -> String {
      - func detectsEducationalContent(_ text: String) -> Bool {
      - func detectsNutritionParsing(_ text: String) -> Bool {
      - func extractEducationalTopic(from text: String) -> String {
      - func getCurrentTimeOfDay() -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Components/StreamingResponseHandler.swift

---
Classes:
  Class: StreamingResponseHandler
  Class: StreamingResult
    Properties:
      - let fullResponse: String
      - let functionCall: AIFunctionCall?
      - let tokenUsage: Int
      - let timeToFirstToken: TimeInterval?
      - let totalTime: TimeInterval
  Class: StreamingState
    Properties:
      - var fullResponse = ""
      - var tokens: [String] = []
      - var functionCall: AIFunctionCall?
      - var tokenUsage = 0
      - var firstTokenTime: TimeInterval?
      - let startTime: CFAbsoluteTime
      - weak var delegate: StreamingResponseDelegate?
    Methods:
      - func handleStream(
        _ stream: AsyncThrowingStream<AIResponse, Error>,
        routingStrategy: RoutingStrategy? = nil
    ) async throws -> StreamingResult {
      - func collectText(from stream: AsyncThrowingStream<AIResponse, Error>) async throws -> String {
      - private func processResponse(
        _ response: AIResponse,
        state: inout StreamingState
    ) async throws {
      - private func handleTextResponse(_ text: String, state: inout StreamingState) {
      - private func handleTextDelta(_ delta: String, state: inout StreamingState) {
      - private func handleFunctionCall(_ call: AIFunctionCall, state: inout StreamingState) {
      - private func handleCompletion(_ usage: AITokenUsage?, state: inout StreamingState) {
      - private func logFirstToken(_ timeToFirstToken: TimeInterval) {
      - private func logPerformanceMetrics(
        _ result: StreamingResult,
        routingStrategy: RoutingStrategy?
    ) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Configuration/RoutingConfiguration.swift

---
Classes:
  Class: RoutingConfiguration
    Properties:
      - private(set) var hybridRoutingEnabled: Bool = true
      - private(set) var hybridRoutingPercentage: Double = 1.0
      - private(set) var forcedRoute: ProcessingRoute?
      - private(set) var performanceMonitoringEnabled: Bool = true
      - private(set) var enableIntelligentFallback: Bool = true
      - private(set) var directAITimeoutMs: Int = 5_000
      - private(set) var tokenEfficiencyThreshold: Int = 500
      - private(set) var nutritionConfidenceThreshold: Double = 0.7
      - static let shared = RoutingConfiguration()
    Methods:
      - func shouldUseHybridRouting(for userId: UUID) -> Bool {
      - func determineRoutingStrategy(
        userInput: String,
        conversationHistory: [AIChatMessage],
        userContext: UserContextSnapshot,
        userId: UUID
    ) -> RoutingStrategy {
      - func updateConfiguration(
        hybridRoutingEnabled: Bool? = nil,
        hybridRoutingPercentage: Double? = nil,
        forcedRoute: ProcessingRoute? = nil,
        performanceMonitoringEnabled: Bool? = nil,
        enableIntelligentFallback: Bool? = nil,
        directAITimeoutMs: Int? = nil,
        tokenEfficiencyThreshold: Int? = nil,
        nutritionConfidenceThreshold: Double? = nil
    ) {
      - func recordRoutingMetrics(_ metrics: RoutingMetrics) {
      - private func loadConfiguration() {
      - private func saveConfiguration() {
  Class: RoutingStrategy
    Properties:
      - let route: ProcessingRoute
      - let reason: String
      - let fallbackEnabled: Bool
      - let timestamp: Date
  Class: RoutingMetrics
    Properties:
      - let route: ProcessingRoute
      - let executionTimeMs: Int
      - let success: Bool
      - let tokenUsage: Int?
      - let confidence: Double?
      - let fallbackUsed: Bool
      - let timestamp: Date
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Functions/AnalysisFunctions.swift

---
Classes:
  Class: AnalysisFunctions

Enums:
  - AnalysisFunctions
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Functions/FunctionCallDispatcher.swift

---
Classes:
  Class: FunctionContext
    Properties:
      - let modelContext: ModelContext
      - let conversationId: UUID
      - let userId: UUID
      - let timestamp = Date()
  Class: FunctionExecutionResult
    Properties:
      - let success: Bool
      - let message: String
      - let data: [String: SendableValue]?
      - let executionTimeMs: Int
      - let functionName: String
  Class: SendableValue
  Class: WorkoutPlanResult
    Properties:
      - let id: UUID
      - let exercises: [ExerciseInfo]
      - let estimatedCalories: Int
      - let estimatedDuration: Int
      - let summary: String
  Class: ExerciseInfo
    Properties:
      - let name: String
      - let sets: Int
      - let reps: String
      - let restSeconds: Int
      - let muscleGroups: [String]
  Class: PerformanceAnalysisResult
    Properties:
      - let summary: String
      - let insights: [String]
      - let trends: [TrendInfo]
      - let recommendations: [String]
      - let dataPoints: Int
  Class: TrendInfo
    Properties:
      - let metric: String
      - let direction: String
      - let magnitude: Double
      - let significance: String
  Class: GoalResult
    Properties:
      - let id: UUID
      - let title: String
      - let description: String
      - let targetDate: Date?
      - let metrics: [String]
      - let milestones: [String]
      - let smartCriteria: SMARTCriteria
  Class: SMARTCriteria
    Properties:
      - let specific: String
      - let measurable: String
      - let achievable: String
      - let relevant: String
      - let timeBound: String
  Class: FunctionCallDispatcher
    Properties:
      - private let workoutService: AIWorkoutServiceProtocol
      - private let analyticsService: AIAnalyticsServiceProtocol
      - private let goalService: AIGoalServiceProtocol
      - private let metricsQueue = DispatchQueue(label: "com.airfit.function-metrics", attributes: .concurrent)
      - private var _functionMetrics: [String: FunctionMetrics] = [:]
      - private let intFormatter: NumberFormatter = {
      - private let functionDispatchTable: [String: @Sendable (FunctionCallDispatcher, [String: AIAnyCodable], User, FunctionContext) async throws -> (message: String, data: [String: Any])]
  Class: FunctionMetrics
    Properties:
      - var totalCalls: Int = 0
      - var totalExecutionTime: TimeInterval = 0
      - var successCount: Int = 0
      - var errorCount: Int = 0
      - var averageExecutionTime: TimeInterval {
      - var successRate: Double {
    Methods:
      - func execute(
        _ call: AIFunctionCall,
        for user: User,
        context: FunctionContext
    ) async throws -> FunctionExecutionResult {
      - func getMetrics() -> [String: Any] {
      - private func executeFunction(
        _ call: AIFunctionCall,
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {
      - private func executeWorkoutPlan(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {
      - private func executeAdaptPlan(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {
      - private func executePerformanceAnalysis(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {
      - private func executeGoalSetting(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {
      - private func generateAdaptationSummary(
        feedback: String,
        type: String,
        concern: String?,
        urgency: String
    ) -> String {
      - private func updateMetrics(for functionName: String, executionTime: TimeInterval, success: Bool) {
      - private func handleError(_ error: Error, functionName: String) -> String {
      - private func extractString(from anyCodable: AIAnyCodable?) -> String? {
      - private func extractInt(from anyCodable: AIAnyCodable?) -> Int? {
      - private func extractDouble(from anyCodable: AIAnyCodable?) -> Double? {
      - private func extractBool(from anyCodable: AIAnyCodable?) -> Bool? {
      - private func extractStringArray(from anyCodable: AIAnyCodable?) -> [String]? {
  Class: FunctionError

Enums:
  - SendableValue
    Cases:
      - string
      - int
      - double
      - bool
      - array
      - dictionary
      - null
  - FunctionError
    Cases:
      - unknownFunction
      - invalidArguments
      - serviceUnavailable
      - dataNotFound
      - processingTimeout
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Functions/FunctionRegistry.swift

---
Classes:
  Class: FunctionRegistry
    Properties:
      - static var functionNames: [String] {
    Methods:
      - static func validateFunctions() -> [String] {
      - static func function(named name: String) -> AIFunctionDefinition? {

Enums:
  - FunctionRegistry
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Functions/GoalFunctions.swift

---
Classes:
  Class: GoalFunctions

Enums:
  - GoalFunctions
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Functions/NutritionFunctions.swift

---
Classes:
  Class: NutritionFunctions

Enums:
  - NutritionFunctions
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Functions/WorkoutFunctions.swift

---
Classes:
  Class: WorkoutFunctions

Enums:
  - WorkoutFunctions
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Models/ConversationPersonalityInsights.swift

---
Classes:
  Class: ConversationPersonalityInsights
    Properties:
      - let dominantTraits: [String]
      - let communicationStyle: ConversationCommunicationStyle
      - let motivationType: ConversationMotivationType
      - let energyLevel: ConversationEnergyLevel
      - let preferredComplexity: ConversationComplexity
      - let emotionalTone: [String]
      - let stressResponse: ConversationStressResponse
      - let preferredTimes: [String]
      - let extractedAt: Date
  Class: ConversationCommunicationStyle
  Class: ConversationMotivationType
  Class: ConversationEnergyLevel
  Class: ConversationComplexity
  Class: ConversationStressResponse

Enums:
  - ConversationCommunicationStyle
    Cases:
      - direct
      - conversational
      - supportive
      - analytical
      - energetic
  - ConversationMotivationType
    Cases:
      - achievement
      - health
      - social
      - balanced
      - performance
  - ConversationEnergyLevel
    Cases:
      - low
      - moderate
      - high
  - ConversationComplexity
    Cases:
      - simple
      - moderate
      - detailed
  - ConversationStressResponse
    Cases:
      - needsSupport
      - prefersDirectness
      - wantsEncouragement
      - requiresBreakdown
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Models/DirectAIModels.swift

---
Classes:
  Class: LegacyNutritionParseResult
    Properties:
      - let items: [ParsedNutritionItem]
      - let totalCalories: Double
      - let confidence: Double
      - let parseMethod: ParseMethod
      - let processingTimeMs: Int
      - let tokenCount: Int?
  Class: ParsedNutritionItem
    Properties:
      - let name: String
      - let quantity: String
      - let calories: Double
      - let proteinGrams: Double
      - let carbGrams: Double
      - let fatGrams: Double
      - let fiberGrams: Double?
      - let confidence: Double
      - var isValid: Bool {
  Class: LegacyEducationalContent
    Properties:
      - let topic: String
      - let content: String
      - let keyPoints: [String]
      - let personalizationLevel: Double
      - let generatedAt: Date
      - let processingTimeMs: Int
      - let tokenCount: Int?
      - var qualityScore: Double {
  Class: ParseMethod

Enums:
  - ParseMethod
    Cases:
      - directAI
      - functionDispatcher
      - hybrid
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Models/NutritionParseResult.swift

---
Classes:
  Class: NutritionParseResult
    Properties:
      - let items: [NutritionItem]
      - let totalCalories: Double
      - let confidence: Double
      - let tokenCount: Int
      - let processingTimeMs: Int
      - let parseStrategy: ParseStrategy
  Class: ParseStrategy
  Class: NutritionItem
    Properties:
      - let name: String
      - let quantity: String
      - let calories: Double
      - let protein: Double
      - let carbs: Double
      - let fat: Double
      - let confidence: Double
      - var formattedCalories: String {
      - var formattedMacros: String {
  Class: EducationalContent
    Properties:
      - let topic: String
      - let content: String
      - let generatedAt: Date
      - let tokenCount: Int
      - let personalizationLevel: Double
      - let contentType: ContentType
  Class: ContentType

Enums:
  - ParseStrategy
    Cases:
      - directAI
      - functionCall
      - fallback
  - ContentType
    Cases:
      - exercise
      - nutrition
      - recovery
      - motivation
      - general
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Models/PersonaMode.swift

---
Classes:
  Class: PersonaMode
    Methods:
      - func adaptedInstructions(for healthContext: HealthContextSnapshot) -> String {
      - private func buildContextAdaptations(_ context: HealthContextSnapshot) -> String {

Enums:
  - PersonaMode
    Cases:
      - supportiveCoach
      - directTrainer
      - analyticalAdvisor
      - motivationalBuddy
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Models/PersonaModels.swift

---
Classes:
  Class: ConversationData
    Properties:
      - let userName: String
      - let primaryGoal: String
      - let responses: [String: AnyCodable]
      - let summary: String
      - let nodeCount: Int
      - var dominantTraits: [String] {
      - var conversationCommunicationStyle: ConversationCommunicationStyle {
      - var motivationType: MotivationType {
      - var conversationEnergyLevel: ConversationEnergyLevel {
      - var emotionalTone: [String] {
      - var preferredComplexity: ComplexityLevel {
      - var preferredTimes: [String] {
      - var stressResponse: StressResponseType {
    Methods:
      - private static func generateSummary(from responses: [String: Any], userName: String, goal: String) -> String {
      - private func formatTrait(dimension: PersonalityDimension, score: Double) -> String {
  Class: MotivationType
  Class: ComplexityLevel
  Class: StressResponseType
  Class: PersonaIdentity
    Properties:
      - let name: String
      - let archetype: String
      - let coreValues: [String]
      - let backgroundStory: String
  Class: VoiceCharacteristics
    Properties:
      - let energy: Energy
      - let pace: Pace
      - let warmth: Warmth
      - let vocabulary: Vocabulary
      - let sentenceStructure: SentenceStructure
  Class: Energy
  Class: Pace
  Class: Warmth
  Class: Vocabulary
  Class: SentenceStructure
  Class: InteractionStyle
    Properties:
      - let greetingStyle: String
      - let closingStyle: String
      - let encouragementPhrases: [String]
      - let acknowledgmentStyle: String
      - let correctionApproach: String
      - let humorLevel: HumorLevel
      - let formalityLevel: FormalityLevel
      - let responseLength: ResponseLength
  Class: HumorLevel
  Class: FormalityLevel
  Class: ResponseLength
  Class: AdaptationRule
    Properties:
      - let trigger: Trigger
      - let condition: String
      - let adjustment: String
  Class: Trigger
  Class: PersonaMetadata
    Properties:
      - let createdAt: Date
      - let version: String
      - let sourceInsights: ConversationPersonalityInsights
      - let generationDuration: TimeInterval
      - let tokenCount: Int
      - let previewReady: Bool
  Class: PersonaProfile
    Properties:
      - let id: UUID
      - let name: String
      - let archetype: String
      - let systemPrompt: String
      - let coreValues: [String]
      - let backgroundStory: String
      - let voiceCharacteristics: VoiceCharacteristics
      - let interactionStyle: InteractionStyle
      - let adaptationRules: [AdaptationRule]
      - let metadata: PersonaMetadata
  Class: CoachPersona
    Properties:
      - let id: UUID
      - let identity: PersonaIdentity
      - let communication: VoiceCharacteristics
      - let philosophy: CoachingPhilosophy
      - let behaviors: CoachingBehaviors
      - let quirks: [PersonaQuirk]
      - let profile: PersonalityInsights
      - let systemPrompt: String
      - let generatedAt: Date
  Class: CoachingPhilosophy
    Properties:
      - let approach: String
      - let principles: [String]
      - let motivationalStyle: String
  Class: CoachingBehaviors
    Properties:
      - let greetingStyle: String
      - let feedbackStyle: String
      - let encouragementStyle: String
      - let adaptations: [AdaptationRule]
  Class: PersonaQuirk
    Properties:
      - let trait: String
      - let expression: String
      - let frequency: String

Enums:
  - MotivationType
    Cases:
      - achievement
      - health
      - social
  - ComplexityLevel
    Cases:
      - simple
      - moderate
      - detailed
  - StressResponseType
    Cases:
      - needsSupport
      - needsDirection
      - independent
  - Energy
    Cases:
      - high
      - moderate
      - calm
  - Pace
    Cases:
      - brisk
      - measured
      - natural
  - Warmth
    Cases:
      - warm
      - neutral
      - friendly
  - Vocabulary
    Cases:
      - simple
      - moderate
      - advanced
  - SentenceStructure
    Cases:
      - simple
      - moderate
      - complex
  - HumorLevel
    Cases:
      - none
      - light
      - moderate
      - playful
  - FormalityLevel
    Cases:
      - casual
      - balanced
      - professional
  - ResponseLength
    Cases:
      - concise
      - moderate
      - detailed
  - Trigger
    Cases:
      - timeOfDay
      - stress
      - progress
      - mood
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/Parsing/LocalCommandParser.swift

---
Classes:
  Class: LocalCommand
  Class: WaterUnit
  Class: QuickLogType
  Class: LocalCommandParser
    Properties:
      - private let navigationCommands: [String: LocalCommand]
      - private let quickLogPatterns: [(pattern: String, command: LocalCommand)]
      - var requiresNavigation: Bool {
      - var analyticsName: String {
    Methods:
      - func parse(_ input: String) -> LocalCommand {
      - private func parseWaterCommand(_ input: String) -> LocalCommand? {
      - private func parseTabNavigation(_ input: String) -> LocalCommand? {

Enums:
  - LocalCommand
    Cases:
      - showDashboard
      - navigateToTab
      - logWater
      - quickLog
      - showSettings
      - showProfile
      - startWorkout
      - help
      - none
  - WaterUnit
    Cases:
      - ounces
      - milliliters
      - liters
      - cups
  - QuickLogType
    Cases:
      - meal
      - mood
      - energy
      - weight
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/PersonaSynthesis/FallbackPersonaGenerator.swift

---
Classes:
  Class: FallbackPersonaGenerator
    Properties:
      - private let cache: AIResponseCache
    Methods:
      - func generateBasicPersona(
        userName: String,
        primaryGoal: String,
        responses: [String: Any]
    ) async -> PersonaProfile {
      - private func extractFitnessLevel(from responses: [String: Any]) -> String {
      - private func extractTimePreference(from responses: [String: Any]) -> String {
      - private func extractMotivationStyle(from responses: [String: Any]) -> String {
      - private func selectArchetype(for goal: String, fitnessLevel: String) -> String {
      - private func generateCoachName(archetype: String, style: String) -> String {
      - private func generateVoiceCharacteristics(
        archetype: String,
        motivationStyle: String
    ) -> VoiceCharacteristics {
      - private func generateInteractionStyle(
        archetype: String,
        timePreference: String,
        motivationStyle: String
    ) -> InteractionStyle {
      - private func generateGreetings(timePreference: String) -> [String] {
      - private func generateEncouragements(motivationStyle: String) -> [String] {
      - private func generateSystemPrompt(
        name: String,
        archetype: String,
        userName: String,
        primaryGoal: String
    ) -> String {
      - private func generateCoreValues(archetype: String) -> [String] {
      - private func generateBackgroundStory(archetype: String) -> String {
      - private func generateAdaptationRules() -> [AdaptationRule] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/PersonaSynthesis/OptimizedPersonaSynthesizer.swift

---
Classes:
  Class: OptimizedPersonaSynthesizer
    Properties:
      - private let llmOrchestrator: LLMOrchestrator
      - private let cache: AIResponseCache
      - private let voiceTemplates: [String: VoiceCharacteristics] = [
 "high-energy": VoiceCharacteristics(energy: .high, pace: .brisk, warmth: .warm, vocabulary: .moderate, sentenceStructure: .simple), "calm-supportive": VoiceCharacteristics(energy: .calm, pace: .measured, warmth: .warm, vocabulary: .moderate, sentenceStructure: .moderate), "balanced": VoiceCharacteristics(energy: .moderate, pace: .natural, warmth: .friendly, vocabulary: .moderate, sentenceStructure: .moderate)
    Methods:
      - func synthesizePersona(
        from conversationData: ConversationData,
        insights: ConversationPersonalityInsights
    ) async throws -> PersonaProfile {
      - private func selectVoiceCharacteristics(insights: ConversationPersonalityInsights) -> VoiceCharacteristics {
      - private func selectArchetype(insights: ConversationPersonalityInsights) -> String {
      - private func generateAdaptationRules(insights: ConversationPersonalityInsights) -> [AdaptationRule] {
  Class: CreativeContent
    Properties:
      - let name: String
      - let archetype: String
      - let coreValues: [String]
      - let backgroundStory: String
      - let systemPrompt: String
      - let interactionStyle: InteractionStyle
    Methods:
      - private func generateAllCreativeContent(
        conversationData: ConversationData,
        insights: ConversationPersonalityInsights,
        baseArchetype: String
    ) async throws -> CreativeContent {
      - private func parseCreativeContent(from json: String) throws -> CreativeContent {
      - private func generateDefaultSystemPrompt() -> String {
      - func batchSynthesize(
        conversations: [(ConversationData, ConversationPersonalityInsights)]
    ) async throws -> [PersonaProfile] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift

---
Classes:
  Class: PersonaSynthesizer
    Properties:
      - private let llmOrchestrator: LLMOrchestrator
      - private let cache = PersonaSynthesisCache()
    Methods:
      - func synthesizePersona(
        from conversationData: ConversationData,
        insights: ConversationPersonalityInsights
    ) async throws -> PersonaProfile {
      - private func generateIdentityAndStyle(
        conversationData: ConversationData,
        insights: ConversationPersonalityInsights
    ) async throws -> (PersonaIdentity, InteractionStyle) {
      - private func generateVoiceCharacteristics(insights: ConversationPersonalityInsights) -> VoiceCharacteristics {
      - private func generateOptimizedSystemPrompt(
        identity: PersonaIdentity,
        voiceCharacteristics: VoiceCharacteristics,
        insights: ConversationPersonalityInsights
    ) async throws -> String {
      - private func generateCacheKey(conversationData: ConversationData, insights: ConversationPersonalityInsights) -> String {
      - private func generatePreview(
        identity: PersonaIdentity,
        voiceCharacteristics: VoiceCharacteristics,
        interactionStyle: InteractionStyle
    ) -> PersonaPreview {
      - private func generateAdaptationRules(insights: ConversationPersonalityInsights) -> [AdaptationRule] {
      - private func parseIdentity(from json: [String: Any]) throws -> PersonaIdentity {
      - private func parseInteractionStyle(from json: [String: Any]) throws -> InteractionStyle {
  Class: PersonaSynthesisCache
    Properties:
      - private var cache: [String: PersonaProfile] = [:]
      - private let maxCacheSize = 100
      - private let cacheExpiration: TimeInterval = 3600 // 1 hour
  Class: CacheEntry
    Properties:
      - let profile: PersonaProfile
      - let timestamp: Date
      - private var entries: [String: CacheEntry] = [:]
    Methods:
      - func get(key: String) -> PersonaProfile? {
      - func set(key: String, value: PersonaProfile) {
  Class: PersonaPreview
    Properties:
      - let name: String
      - let archetype: String
      - let sampleGreeting: String
      - let voiceDescription: String
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/PersonaSynthesis/PreviewGenerator.swift

---
Classes:
  Class: PreviewGenerator
    Properties:
      - @Published private(set) var currentStage: SynthesisStage = .notStarted
      - @Published private(set) var preview: PersonaPreview?
      - @Published private(set) var progress: Double = 0
      - @Published private(set) var error: Error?
      - private let synthesizer: PersonaSynthesizer
      - private var synthesisTask: Task<Void, Never>?
    Methods:
      - func startSynthesis(
        insights: PersonalityInsights,
        conversationData: ConversationData
    ) {
      - func cancelSynthesis() {
      - private func performSynthesis(
        insights: PersonalityInsights,
        conversationData: ConversationData
    ) async {
      - private func updateStage(_ stage: SynthesisStage) {
      - private func extractTopTraits(from insights: PersonalityInsights) -> [String] {
      - private func formatTrait(dimension: PersonalityDimension, score: Double) -> String {
      - private func generateSampleGreeting(for persona: PersonaProfile) -> String {
      - private func generateVoiceDescription(for persona: PersonaProfile) -> String {
      - private func generateFinalGreeting(for persona: PersonaProfile) -> String {
      - private func generateFinalVoiceDescription(for persona: PersonaProfile) -> String {
      - private func convertMotivationType(_ motivation: MotivationType) -> ConversationMotivationType {
      - private func convertComplexity(_ complexity: ComplexityLevel) -> ConversationComplexity {
      - private func convertStressResponse(_ response: StressResponseType) -> ConversationStressResponse {
  Class: SynthesisStage
    Methods:
      - static func == (lhs: SynthesisStage, rhs: SynthesisStage) -> Bool {

Enums:
  - SynthesisStage
    Cases:
      - notStarted
      - analyzingPersonality
      - creatingIdentity
      - buildingPersonality
      - finalizing
      - complete
      - failed
      - cancelled
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/CoachEngine.swift

---
Classes:
  Class: DirectAIError
  Class: CoachEngineError
  Class: CoachEngine
    Properties:
      - private(set) var isProcessing = false
      - private(set) var currentResponse = ""
      - private(set) var error: Error?
      - private(set) var activeConversationId: UUID?
      - private(set) var streamingTokens: [String] = []
      - private(set) var lastFunctionCall: String?
      - private let localCommandParser: LocalCommandParser
      - private let functionDispatcher: FunctionCallDispatcher
      - private let personaEngine: PersonaEngine
      - private let conversationManager: ConversationManager
      - private let aiService: AIServiceProtocol
      - private let contextAssembler: ContextAssembler
      - private let modelContext: ModelContext
      - private let routingConfiguration: RoutingConfiguration
      - private let maxRetries = 3
      - private let streamingTimeout: TimeInterval = 30.0
      - private let functionCallTimeout: TimeInterval = 10.0
    Methods:
      - private func collectAIResponse(from request: AIRequest) async -> String {
      - func processUserMessage(_ text: String, for user: User) async {
      - func clearConversation() {
      - func regenerateLastResponse(for user: User) async {
      - func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async -> String {
      - private func buildWorkoutAnalysisPrompt(_ request: PostWorkoutAnalysisRequest) -> String {
      - private func classifyMessage(_ text: String) -> MessageType {
      - private func startProcessing() async {
      - private func finishProcessing() async {
      - private func checkLocalCommand(_ text: String, for user: User) async -> LocalCommand? {
      - private func handleLocalCommandResponse(
        _ command: LocalCommand,
        for user: User,
        conversationId: UUID
    ) async {
      - private func processAIResponse(
        _ text: String,
        for user: User,
        conversationId: UUID,
        messageType: MessageType
    ) async {
      - private func processWithDirectAI(
        text: String,
        user: User,
        conversationId: UUID,
        conversationHistory: [AIChatMessage],
        healthContext: HealthContextSnapshot,
        routingStrategy: RoutingStrategy,
        startTime: CFAbsoluteTime
    ) async {
      - private func processWithFunctionCalling(
        text: String,
        user: User,
        conversationId: UUID,
        conversationHistory: [AIChatMessage],
        healthContext: HealthContextSnapshot,
        routingStrategy: RoutingStrategy,
        startTime: CFAbsoluteTime
    ) async {
      - private func extractEducationalTopic(from text: String) -> String {
      - private func generateSimpleConversationalResponse(
        text: String,
        user: User,
        conversationHistory: [AIChatMessage],
        healthContext: HealthContextSnapshot
    ) async throws -> String {
      - private func getCurrentTimeOfDay() -> String {
      - private func detectsEducationalContent(_ text: String) -> Bool {
      - private func streamAIResponseWithMetrics(
        _ request: AIRequest,
        for user: User,
        conversationId: UUID,
        routingStrategy: RoutingStrategy,
        startTime: CFAbsoluteTime
    ) async {
      - private func streamAIResponse(
        _ request: AIRequest,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async {
      - private func executeFunctionCall(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        originalMessage: CoachMessage
    ) async {
      - private func handleDirectNutritionParsing(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async {
      - private func handleDirectEducationalContent(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async {
      - private func handleDispatcherFunction(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID,
        startTime: CFAbsoluteTime
    ) async throws {
      - private func buildNutritionParsingResponse(_ result: NutritionParseResult) -> String {
      - private func handleFunctionError(
        _ error: Error,
        for user: User,
        conversationId: UUID
    ) async {
      - private func extractString(_ value: AIAnyCodable?) -> String? {
      - private func generateFunctionFollowUp(_ result: FunctionExecutionResult) -> String {
      - private func generateLocalCommandResponse(_ command: LocalCommand) -> String {
      - private func getUserProfile(for user: User) async throws -> UserProfileJsonBlob {
      - private func handleError(_ error: Error) async {
      - private func createDefaultProfile() -> UserProfileJsonBlob {
      - func executeFunction(
        _ functionCall: AIFunctionCall,
        for user: User
    ) async throws -> FunctionExecutionResult {
      - public func parseAndLogNutritionDirect(
        foodText: String,
        context: String = "",
        for user: User,
        conversationId: UUID? = nil
    ) async throws -> NutritionParseResult {
      - public func generateEducationalContentDirect(
        topic: String,
        userContext: String,
        for user: User
    ) async throws -> EducationalContent {
      - private func buildOptimizedNutritionPrompt(
        foodText: String,
        context: String,
        user: User
    ) -> String {
      - private func buildEducationalPrompt(
        topic: String,
        userContext: String,
        userProfile: UserProfileJsonBlob
    ) -> String {
      - private func executeStreamingAIRequest(_ request: AIRequest) async throws -> String {
      - private func parseNutritionResponse(_ response: String) throws -> [ParsedNutritionItem] {
      - private func validateNutritionItems(_ items: [ParsedNutritionItem]) -> [ParsedNutritionItem] {
      - private func extractKeyPoints(from content: String) -> [String] {
      - private func calculatePersonalizationLevel(_ content: String, userProfile: UserProfileJsonBlob) -> Double {
      - private func extractJSON(from response: String) -> String {
      - private func estimateTokenCount(_ text: String) -> Int {
      - func parseAndLogNutritionDirect(
        foodText: String,
        for user: User,
        conversationId: UUID
    ) async throws -> NutritionParseResult {
      - private func buildDirectNutritionParsingPrompt(text: String, userProfile: UserProfileJsonBlob) -> String {
      - private func buildDirectEducationPrompt(
        topic: String,
        userContext: String,
        userProfile: UserProfileJsonBlob
    ) -> String {
      - private func parseDirectNutritionResponse(_ response: String) throws -> [NutritionItem] {
      - private func classifyContentType(_ topic: String) -> EducationalContent.ContentType {
      - func getActiveConversationStats(for user: User) async throws -> ConversationStats? {
      - func pruneOldConversations(for user: User) async {
      - static func createDefault(modelContext: ModelContext) -> CoachEngine {
  Class: MinimalAIAPIService
    Properties:
      - var serviceIdentifier = "minimal-ai-service"
      - var isConfigured = true
      - var activeProvider: AIProvider = .anthropic
      - var availableModels: [AIModel] = []
    Methods:
      - func configure() async throws {
      - func reset() async {
      - func healthCheck() async -> ServiceHealth {
      - func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
      - func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
      - func validateConfiguration() async throws -> Bool {
      - func checkHealth() async -> ServiceHealth {
      - func estimateTokenCount(for text: String) -> Int {
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
      - func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
      - func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
      - private func buildNutritionParsingPrompt(text: String, mealType: MealType, user: User) -> String {
      - private func parseNutritionJSON(_ jsonString: String) throws -> [ParsedFoodItem] {
      - private func validateNutritionValues(_ items: [ParsedFoodItem]) -> [ParsedFoodItem] {
      - private func createFallbackFoodItem(from text: String, mealType: MealType) -> ParsedFoodItem {
  Class: PreviewAIWorkoutService
    Methods:
      - func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
      - func pauseWorkout(_ workout: Workout) async throws {
      - func resumeWorkout(_ workout: Workout) async throws {
      - func endWorkout(_ workout: Workout) async throws {
      - func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
      - func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
      - func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
      - func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
      - func generatePlan(for user: User, goal: String, duration: Int, intensity: String, targetMuscles: [String], equipment: [String], constraints: String?, style: String) async throws -> WorkoutPlanResult {
      - func adaptPlan(_ plan: WorkoutPlanResult, feedback: String, adjustments: [String: Any]) async throws -> WorkoutPlanResult {
  Class: PreviewAIAnalyticsService
    Methods:
      - func trackEvent(_ event: AnalyticsEvent) async {
      - func trackScreen(_ screen: String, properties: [String: String]?) async {
      - func setUserProperties(_ properties: [String: String]) async {
      - func trackWorkoutCompleted(_ workout: Workout) async {
      - func trackMealLogged(_ meal: FoodEntry) async {
      - func getInsights(for user: User) async throws -> UserInsights {
      - func analyzePerformance(query: String, metrics: [String], days: Int, depth: String, includeRecommendations: Bool, for user: User) async throws -> PerformanceAnalysisResult {
      - func generatePredictiveInsights(for user: User, timeframe: Int) async throws -> PredictiveInsights {
  Class: PreviewAIGoalService
    Methods:
      - func createGoal(_ goalData: GoalCreationData, for user: User) async throws -> ServiceGoal {
      - func updateGoal(_ goal: ServiceGoal, updates: GoalUpdate) async throws {
      - func deleteGoal(_ goal: ServiceGoal) async throws {
      - func getActiveGoals(for user: User) async throws -> [ServiceGoal] {
      - func trackProgress(for goal: ServiceGoal, value: Double) async throws {
      - func checkGoalCompletion(_ goal: ServiceGoal) async -> Bool {
      - func createOrRefineGoal(current: String?, aspirations: String, timeframe: String?, fitnessLevel: String?, constraints: [String], motivations: [String], goalType: String?, for user: User) async throws -> GoalResult {
      - func suggestGoalAdjustments(for goal: ServiceGoal, user: User) async throws -> [GoalAdjustment] {

Enums:
  - DirectAIError
    Cases:
      - nutritionParsingFailed
      - nutritionValidationFailed
      - educationalContentFailed
      - invalidResponse
      - timeout
      - emptyResponse
      - invalidJSONResponse
      - invalidNutritionValues
  - CoachEngineError
    Cases:
      - noActiveConversation
      - noMessageToRegenerate
      - aiServiceUnavailable
      - streamingTimeout
      - functionExecutionFailed
      - contextAssemblyFailed
      - invalidUserProfile
      - nutritionParsingFailed
      - educationalContentFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/ContextAnalyzer.swift

---
Classes:
  Class: ContextAnalyzer
    Properties:
      - nonisolated(unsafe) private static let routingCache: NSCache<NSString, NSString> = {
    Methods:
      - static func determineOptimalRoute(
        userInput: String,
        conversationHistory: [AIChatMessage],
        userState: UserContextSnapshot
    ) -> ProcessingRoute {
      - static func detectsComplexWorkflow(_ input: String, history: [AIChatMessage]) -> Bool {
      - static func detectsSimpleParsing(_ input: String) -> Bool {
      - private static func analyzeUserInput(_ input: String) -> InputAnalysis {
      - private static func analyzeConversationContext(_ history: [AIChatMessage]) -> ContextAnalysis {
      - private static func buildChainContext(_ history: [AIChatMessage]) -> ChainContext {
      - private static func applyRoutingHeuristics(
        inputAnalysis: InputAnalysis,
        contextAnalysis: ContextAnalysis,
        chainContext: ChainContext,
        userState: UserContextSnapshot
    ) -> ProcessingRoute {
      - private static func containsNumbers(_ input: String) -> Bool {
      - private static func containsQuestions(_ input: String) -> Bool {
      - private static func detectUrgencyLevel(_ input: String) -> UrgencyLevel {
      - private static func calculateTopicConsistency(_ messages: [AIChatMessage]) -> Double {
      - private static func extractTopic(_ content: String) -> String {
      - private static func calculateChainProbability(_ recentFunctions: [String]) -> Double {
      - private static func getFunctionType(_ functionName: String) -> String {
      - private static func generateCacheKey(_ input: String, historyCount: Int) -> String {
  Class: ProcessingRoute
  Class: InputAnalysis
    Properties:
      - let length: Int
      - let wordCount: Int
      - let isSimpleParsing: Bool
      - let isComplexWorkflow: Bool
      - let containsNumbers: Bool
      - let containsQuestions: Bool
      - let urgencyLevel: UrgencyLevel
      - var debugDescription: String {
  Class: ContextAnalysis
    Properties:
      - let recentFunctionCalls: [String]
      - let conversationDepth: Int
      - let averageMessageLength: Int
      - let isOngoingWorkflow: Bool
      - let topicConsistency: Double
  Class: ChainContext
    Properties:
      - let recentFunctions: [String]
      - let chainProbability: Double
      - let workflowActive: Bool
      - let lastFunctionTimestamp: Date?
    Methods:
      - func suggestsChaining() -> Bool {
  Class: UrgencyLevel
  Class: UserContextSnapshot
    Properties:
      - let activeGoals: [String]
      - let recentActivity: [String]
      - let preferences: [String: Any]
      - let timeOfDay: String
      - let isNewUser: Bool
      - var legacyFunctionCall: FunctionCall? {
  Class: RoutingAnalytics
    Methods:
      - static func logRoutingDecision(
        route: ProcessingRoute,
        input: String,
        processingTimeMs: Int,
        context: [String: Any] = [:]
    ) {
      - static func logPerformanceComparison(
        route: ProcessingRoute,
        executionTimeMs: Int,
        tokenCount: Int?,
        success: Bool
    ) {

Enums:
  - ProcessingRoute
    Cases:
      - functionCalling
      - directAI
      - hybrid
  - UrgencyLevel
    Cases:
      - low
      - medium
      - high
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/ConversationManager.swift

---
Classes:
  Class: ConversationManager
    Properties:
      - private let modelContext: ModelContext
    Methods:
      - func saveUserMessage(
        _ content: String,
        for user: User,
        conversationId: UUID
    ) async throws -> CoachMessage {
      - func createAssistantMessage(
        _ content: String,
        for user: User,
        conversationId: UUID,
        functionCall: FunctionCall? = nil,
        isLocalCommand: Bool = false,
        isError: Bool = false
    ) async throws -> CoachMessage {
      - func recordAIMetadata(
        for message: CoachMessage,
        model: String,
        tokens: (prompt: Int, completion: Int),
        temperature: Double,
        responseTime: TimeInterval
    ) async throws {
      - func getRecentMessages(
        for user: User,
        conversationId: UUID,
        limit: Int = 20
    ) async throws -> [AIChatMessage] {
      - func getConversationStats(
        for user: User,
        conversationId: UUID
    ) async throws -> ConversationStats {
      - func pruneOldConversations(
        for user: User,
        keepLast: Int = 5
    ) async throws {
      - func deleteConversation(
        for user: User,
        conversationId: UUID
    ) async throws {
      - func getConversationIds(for user: User) async throws -> [UUID] {
      - func archiveOldMessages(
        for user: User,
        olderThan days: Int = 30
    ) async throws {
  Class: ConversationStats
    Properties:
      - let totalMessages: Int
      - let userMessages: Int
      - let assistantMessages: Int
      - let totalTokens: Int
      - let estimatedCost: Double
      - let firstMessageDate: Date?
      - let lastMessageDate: Date?
      - var averageTokensPerMessage: Double {
      - var costPerMessage: Double {
  Class: ConversationManagerError

Enums:
  - ConversationManagerError
    Cases:
      - userNotFound
      - conversationNotFound
      - invalidMessageRole
      - encodingFailed
      - saveFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/PersonaEngine.swift

---
Classes:
  Class: PersonaEngine
    Properties:
      - private static var cachedPromptTemplate: String?
      - private var cachedPersonaInstructions: [PersonaMode: String] = [:]
    Methods:
      - func buildSystemPrompt(
        personaMode: PersonaMode,
        userGoal: String,
        userContext: String,
        healthContext: HealthContextSnapshot,
        conversationHistory: [AIChatMessage],
        availableFunctions: [AIFunctionDefinition]
    ) throws -> String {
      - func buildSystemPrompt(
        userProfile: UserProfileJsonBlob,
        healthContext: HealthContextSnapshot,
        conversationHistory: [AIChatMessage],
        availableFunctions: [AIFunctionDefinition]
    ) throws -> String {
      - private static func buildOptimizedPromptTemplate() -> String {
      - private func buildUserContextString(from profile: UserProfileJsonBlob) -> String {
      - private func buildCompactHealthContext(_ healthContext: HealthContextSnapshot) throws -> String {
      - private func buildCompactConversationHistory(_ history: [AIChatMessage]) throws -> String {
      - private func buildCompactFunctionList(_ functions: [AIFunctionDefinition]) throws -> String {
  Class: PersonaEngineError

Enums:
  - PersonaEngineError
    Cases:
      - promptTooLong
      - invalidProfile
      - encodingFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/AI/WorkoutAnalysisEngine.swift

---
Classes:
  Class: WorkoutAnalysisEngine
    Properties:
      - private let aiService: AIServiceProtocol
    Methods:
      - func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
      - private func buildWorkoutAnalysisPrompt(_ request: PostWorkoutAnalysisRequest) -> String {
  Class: PostWorkoutAnalysisRequest
    Properties:
      - let workout: Workout
      - let recentWorkouts: [Workout]
      - let userGoals: [String]?
      - let recoveryData: RecoveryData?
  Class: RecoveryData
    Properties:
      - let sleepHours: Double?
      - let restingHeartRate: Int?
      - let hrv: Double?
      - let subjectedEnergyLevel: Int? // 1-10 scale
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Coordinators/ChatCoordinator.swift

---
Classes:
  Class: ChatCoordinator
    Properties:
      - @Published var navigationPath = NavigationPath()
      - @Published var activeSheet: ChatSheet?
      - @Published var activePopover: ChatPopover?
      - @Published var scrollToMessageId: String?
  Class: ChatSheet
  Class: ChatPopover
    Methods:
      - func navigateTo(_ destination: ChatDestination) {
      - func showSheet(_ sheet: ChatSheet) {
      - func showPopover(_ popover: ChatPopover) {
      - func scrollTo(messageId: String) {
      - func dismiss() {
  Class: ChatDestination

Enums:
  - ChatSheet
    Cases:
      - sessionHistory
      - exportChat
      - voiceSettings
      - imageAttachment
  - ChatPopover
    Cases:
      - contextMenu
      - quickActions
      - emojiPicker
  - ChatDestination
    Cases:
      - messageDetail
      - searchResults
      - sessionSettings
      - progressView
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Models/ChatModels.swift

---
Classes:
  Class: QuickSuggestion
    Properties:
      - let id = UUID()
      - let text: String
      - let autoSend: Bool
  Class: ContextualAction
    Properties:
      - let id = UUID()
      - let title: String
      - let icon: String?
  Class: ChatError

Enums:
  - ChatError
    Cases:
      - noActiveSession
      - exportFailed
      - voiceRecognitionUnavailable
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Services/ChatExporter.swift

---
Classes:
  Class: ChatExporter
  Class: ExportFormat
    Methods:
      - func export(
        session: ChatSession,
        messages: [ChatMessage],
        format: ExportFormat = .markdown
    ) async throws -> URL {
      - private func exportAsJSON(session: ChatSession, messages: [ChatMessage]) throws -> String {
      - private func exportAsMarkdown(session: ChatSession, messages: [ChatMessage]) -> String {
      - private func exportAsText(session: ChatSession, messages: [ChatMessage]) -> String {
  Class: ChatExportData
    Properties:
      - let session: SessionExportData
      - let messages: [MessageExportData]
  Class: SessionExportData
    Properties:
      - let id: String
      - let title: String
      - let createdAt: String
      - let messageCount: Int
  Class: MessageExportData
    Properties:
      - let id: String
      - let content: String
      - let role: String
      - let timestamp: String
      - let attachments: [AttachmentExportData]
  Class: AttachmentExportData
    Properties:
      - let id: String
      - let type: String
      - let mimeType: String

Enums:
  - ExportFormat
    Cases:
      - json
      - markdown
      - txt
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Services/ChatHistoryManager.swift

---
Classes:
  Class: ChatHistoryManager
    Properties:
      - private let modelContext: ModelContext
      - @Published private(set) var sessions: [ChatSession] = []
      - @Published private(set) var isLoading = false
      - @Published private(set) var error: Error?
    Methods:
      - func loadSessions(for user: User) async {
      - func deleteSession(_ session: ChatSession) async {
      - func exportSession(_ session: ChatSession, format: ChatExporter.ExportFormat) async throws -> URL {
      - func searchSessions(query: String) -> [ChatSession] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Services/ChatSuggestionsEngine.swift

---
Classes:
  Class: ChatSuggestionsEngine
    Properties:
      - private let user: User
      - private let contextAssembler: ContextAssembler
    Methods:
      - func generateSuggestions(
        messages: [ChatMessage],
        userContext: User
    ) async -> SuggestionSet {
      - private func getFitnessPrompts() -> [QuickSuggestion] {
  Class: SuggestionSet
    Properties:
      - let quick: [QuickSuggestion]
      - let contextual: [ContextualAction]
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/ViewModels/ChatViewModel.swift

---
Classes:
  Class: ChatViewModel
    Properties:
      - private let modelContext: ModelContext
      - let user: User
      - private let coachEngine: CoachEngineProtocol
      - private let aiService: AIServiceProtocol
      - var voiceManager: VoiceInputManager
      - private let coordinator: ChatCoordinator
      - @Published private(set) var messages: [ChatMessage] = []
      - @Published private(set) var currentSession: ChatSession?
      - @Published private(set) var isLoading = false
      - @Published private(set) var isStreaming = false
      - @Published private(set) var error: Error?
      - @Published var composerText = ""
      - @Published var isRecording = false
      - @Published var voiceWaveform: [Float] = []
      - @Published var attachments: [ChatAttachment] = []
      - @Published private(set) var quickSuggestions: [QuickSuggestion] = []
      - @Published private(set) var contextualActions: [ContextualAction] = []
      - private var streamBuffer = ""
      - private var streamTask: Task<Void, Never>?
    Methods:
      - func loadOrCreateSession() async {
      - private func loadMessages(for session: ChatSession) async {
      - func sendMessage() async {
      - private func generateAIResponse(for userInput: String, session: ChatSession) async {
      - private func setupVoiceManager() {
      - func toggleVoiceRecording() async {
      - private func refreshSuggestions() async {
      - func selectSuggestion(_ suggestion: QuickSuggestion) {
      - func deleteMessage(_ message: ChatMessage) async {
      - func copyMessage(_ message: ChatMessage) {
      - func regenerateResponse(for message: ChatMessage) async {
      - func searchMessages(query: String) async -> [ChatMessage] {
      - func exportChat() async throws -> URL {
      - private func handleFunctionCall(name: String, arguments: [String: Any], message: ChatMessage) async {
      - func scheduleWorkout(from message: ChatMessage) async {
      - func setReminder(from message: ChatMessage) async {
      - private func createGenericWorkout() async {
      - private func createGenericReminder() async {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Views/ChatView.swift

---
Classes:
  Class: ChatView
    Properties:
      - @StateObject private var viewModel: ChatViewModel
      - @StateObject private var coordinator: ChatCoordinator
      - @FocusState private var isComposerFocused: Bool
      - @State private var scrollProxy: ScrollViewProxy?
      - var body: some View {
      - private var messagesScrollView: some View {
      - private var suggestionsBar: some View {
      - private var toolbarContent: some ToolbarContent {
    Methods:
      - @ViewBuilder
    private func destinationView(for destination: ChatDestination) -> some View {
      - @ViewBuilder
    private func sheetView(for sheet: ChatCoordinator.ChatSheet) -> some View {
      - private func handleMessageAction(_ action: MessageAction, message: ChatMessage) {
      - private func startNewSession() {
      - private func scrollToBottom() {
  Class: ChatMockCoachEngine
    Methods:
      - func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
      - func processUserMessage(_ text: String, for user: User) async {
  Class: SuggestionChip
    Properties:
      - let suggestion: QuickSuggestion
      - let onTap: () -> Void
      - var body: some View {
  Class: ChatTypingIndicator
    Properties:
      - var body: some View {
  Class: MessageDetailView
    Properties:
      - let messageId: String
      - var body: some View {
  Class: ChatSearchView
    Properties:
      - let viewModel: ChatViewModel
      - var body: some View {
  Class: SessionSettingsView
    Properties:
      - let session: ChatSession?
      - var body: some View {
  Class: ChatHistoryView
    Properties:
      - let user: User
      - var body: some View {
  Class: ChatExportView
    Properties:
      - let viewModel: ChatViewModel
      - var body: some View {
  Class: ImagePickerView
    Properties:
      - var onPick: (UIImage) -> Void
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Views/MessageBubbleView.swift

---
Classes:
  Class: MessageBubbleView
    Properties:
      - let message: ChatMessage
      - let isStreaming: Bool
      - let onAction: (MessageAction) -> Void
      - @State private var showActions = false
      - @State private var isExpanded = false
      - @State private var animateIn = false
      - @State private var selectedReaction: String?
      - var body: some View {
      - private var bubble: some View {
      - private var bubbleBackground: some View {
      - private var attachmentsView: some View {
      - private var richContent: some View {
      - private var interactiveElements: some View {
      - private var messageFooter: some View {
      - private var messageStatusIcon: some View {
      - private var messageActions: some View {
      - private var hasExpandableContent: Bool {
    Methods:
      - private func formatTimestamp(_ date: Date) -> String {
      - private func toggleReaction(_ emoji: String) {
      - private func handleQuickAction(_ actionId: String) {
  Class: ChatBubbleShape
    Properties:
      - let role: ChatMessage.MessageType
    Methods:
      - func path(in rect: CGRect) -> Path {
  Class: ReactionButton
    Properties:
      - let emoji: String
      - let isSelected: Bool
      - let onTap: () -> Void
      - var body: some View {
  Class: MessageAction
  Class: ChatChartDataPoint
    Properties:
      - let id = UUID()
      - let label: String
      - let value: Double
  Class: ChatQuickAction
    Properties:
      - let id: String
      - let title: String
  Class: MessageContent
    Properties:
      - let text: String
      - let isStreaming: Bool
      - let role: ChatMessage.MessageType
      - @State private var displayedCount: Int = 0
      - private var displayedText: String {
      - var body: some View {
  Class: AttachmentThumbnail
    Properties:
      - let attachment: ChatAttachment
      - let isExpanded: Bool
      - var body: some View {
  Class: NavigationLinkCard
    Properties:
      - let title: String
      - let subtitle: String?
      - let destination: String
      - let icon: String?
      - var body: some View {
  Class: ChartView
    Properties:
      - let data: [ChatChartDataPoint]
      - let isExpanded: Bool
      - var body: some View {
  Class: ReminderCard
    Properties:
      - let time: String
      - let title: String
      - let isExpanded: Bool
      - var body: some View {
  Class: ProgressCard
    Properties:
      - let progress: Double
      - let isExpanded: Bool
      - var body: some View {
  Class: QuickActionsView
    Properties:
      - let actions: [ChatQuickAction]
      - let onAction: (String) -> Void
      - var body: some View {

Enums:
  - MessageAction
    Cases:
      - copy
      - delete
      - regenerate
      - showDetails
      - scheduleWorkout
      - viewProgress
      - setReminder
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Views/MessageComposer.swift

---
Classes:
  Class: MessageComposer
    Properties:
      - @Binding var text: String
      - @Binding var attachments: [ChatAttachment]
      - let isRecording: Bool
      - let waveform: [Float]
      - let onSend: () -> Void
      - let onVoiceToggle: () -> Void
      - @State private var showAttachmentPicker = false
      - @State private var selectedPhoto: PhotosPickerItem?
      - @FocusState private var isTextFieldFocused: Bool
      - private var canSend: Bool {
      - var body: some View {
      - private var attachmentMenu: some View {
      - private var textInputView: some View {
      - private var recordingView: some View {
      - private var attachmentsPreview: some View {
  Class: VoiceWaveformView
    Properties:
      - let levels: [Float]
      - var body: some View {
  Class: RecordingIndicator
    Properties:
      - @State private var isAnimating = false
      - var body: some View {
  Class: AttachmentPreview
    Properties:
      - let attachment: ChatAttachment
      - let onRemove: () -> Void
      - var body: some View {
  Class: MessageComposer_Previews
    Properties:
      - static var previews: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Views/VoiceSettingsView.swift

---
Classes:
  Class: VoiceSettingsView
    Properties:
      - @ObservedObject var modelManager = WhisperModelManager.shared
      - @Environment(\.dismiss) private var dismiss
      - @State private var downloadError: Error?
      - @State private var showDeleteConfirmation: String?
      - @AppStorage("voice.autoSelectModel") private var autoSelectModel = true
      - @AppStorage("voice.downloadCellular") private var downloadCellular = false
      - var body: some View {
      - private var currentModelSection: some View {
      - private var availableModelsSection: some View {
      - private var storageInfoSection: some View {
      - private var advancedSettingsSection: some View {
  Class: ModelRow
    Properties:
      - let model: WhisperModelManager.WhisperModel
      - let isDownloaded: Bool
      - let isActive: Bool
      - let isDownloading: Bool
      - let downloadProgress: Double
      - let onDownload: () -> Void
      - let onDelete: () -> Void
      - let onActivate: () -> Void
      - var body: some View {
  Class: StorageInfoView
    Properties:
      - @ObservedObject var modelManager: WhisperModelManager
      - private var totalModelSize: Int {
      - var body: some View {
    Methods:
      - private func formatBytes(_ bytes: Int) -> String {
      - private func getDeviceStorage() -> (available: Int, total: Int)? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Coordinators/DashboardCoordinator.swift

---
Classes:
  Class: DashboardCoordinator
    Properties:
      - @Published var path = NavigationPath()
      - @Published var selectedSheet: DashboardSheet?
      - @Published var alertItem: AlertItem?
  Class: Destination
  Class: DashboardSheet
  Class: AlertItem
    Properties:
      - let id = UUID()
      - let title: String
      - let message: String
      - let dismissButton: String
    Methods:
      - func navigate(to destination: Destination) {
      - func navigateBack() {
      - func navigateToRoot() {
      - func showSheet(_ sheet: DashboardSheet) {
      - func dismissSheet() {
      - func showAlert(title: String, message: String, dismissButton: String = "OK") {
      - func dismissAlert() {

Enums:
  - Destination
    Cases:
      - nutritionDetail
      - workoutHistory
      - recoveryDetail
      - settings
  - DashboardSheet
    Cases:
      - energyLogging
      - quickFoodEntry
      - quickWorkoutStart
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Models/DashboardModels.swift

---
Classes:
  Class: NutritionSummary
    Properties:
      - let calories: Double
      - let caloriesTarget: Double
      - let protein: Double
      - let proteinTarget: Double
      - let carbs: Double
      - let carbsTarget: Double
      - let fat: Double
      - let fatTarget: Double
      - let fiber: Double
      - let fiberTarget: Double
      - let water: Double
      - let waterTarget: Double
      - let waterLiters: Double
      - let mealCount: Int
      - let meals: [FoodEntry]
  Class: NutritionTargets
    Properties:
      - let calories: Double
      - let protein: Double
      - let carbs: Double
      - let fat: Double
      - let fiber: Double
      - let water: Double
      - static let `default` = NutritionTargets(
 calories: 2000, protein: 150, carbs: 250, fat: 65, fiber: 25, water: 64
  Class: GreetingContext
    Properties:
      - let userName: String
      - let sleepHours: Double?
      - let sleepQuality: String?
      - let weather: String?
      - let temperature: Double?
      - let todaysSchedule: String?
      - let energyYesterday: String?
      - let dayOfWeek: String
      - let recentAchievements: [String]
  Class: RecoveryScore
  Class: Status
    Properties:
      - let score: Int
      - let status: Status
      - let factors: [String]
  Class: PerformanceInsight
  Class: Trend
    Properties:
      - let trend: Trend
      - let metric: String
      - let value: String
      - let insight: String
  Class: QuickAction
    Properties:
      - let id = UUID()
      - let title: String
      - let subtitle: String
      - let systemImage: String
      - let color: String
      - let action: QuickActionType
  Class: QuickActionType

Enums:
  - Status
    Cases:
      - poor
      - moderate
      - good
  - Trend
    Cases:
      - improving
      - stable
      - declining
  - QuickActionType
    Cases:
      - logMeal
      - startWorkout
      - logWater
      - checkIn
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Services/AICoachService.swift

---
Classes:
  Class: AICoachService
    Properties:
      - private let coachEngine: CoachEngine
    Methods:
      - func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Services/DashboardNutritionService.swift

---
Classes:
  Class: DashboardNutritionService
    Properties:
      - private let modelContext: ModelContext
    Methods:
      - func getTodaysSummary(for user: User) async throws -> NutritionSummary {
      - func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Services/HealthKitService.swift

---
Classes:
  Class: HealthKitService
    Properties:
      - private let healthKitManager: HealthKitManaging
      - private let contextAssembler: ContextAssembler
    Methods:
      - func getCurrentContext() async throws -> HealthContext {
      - func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
      - func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/ViewModels/DashboardViewModel.swift

---
Classes:
  Class: DashboardViewModel
    Properties:
      - private(set) var isLoading = true
      - private(set) var error: Error?
      - private(set) var morningGreeting = "Good morning!"
      - private(set) var greetingContext: GreetingContext?
      - private(set) var currentEnergyLevel: Int?
      - private(set) var isLoggingEnergy = false
      - private(set) var nutritionSummary = NutritionSummary()
      - private(set) var nutritionTargets = NutritionTargets.default
      - private(set) var recoveryScore: RecoveryScore?
      - private(set) var performanceInsight: PerformanceInsight?
      - private(set) var suggestedActions: [QuickAction] = []
      - private let user: User
      - private let modelContext: ModelContext
      - private let healthKitService: HealthKitServiceProtocol
      - private let aiCoachService: AICoachServiceProtocol
      - private let nutritionService: DashboardNutritionServiceProtocol
      - private var refreshTask: Task<Void, Never>?
      - private var lastGreetingDate: Date?
      - private var forceGreetingRefresh = false
    Methods:
      - func onAppear() {
      - func onDisappear() {
      - func refreshDashboard() {
      - func loadDashboardData() async {
      - func logEnergyLevel(_ level: Int) async {
      - func resetGreetingState() {
      - private func _loadDashboardData() async {
      - private func loadMorningGreeting() async {
      - private func loadEnergyLevel() async {
      - private func loadNutritionData() async {
      - private func loadHealthInsights() async {
      - func loadQuickActions(for date: Date = Date()) async {
      - private func generateFallbackGreeting() -> String {
      - private func hasWorkoutToday() -> Bool {
  Class: NutritionSummary
    Properties:
      - var calories: Double = 0
      - var protein: Double = 0
      - var carbs: Double = 0
      - var fat: Double = 0
      - var fiber: Double = 0
      - var waterLiters: Double = 0
      - var meals: [MealType: FoodEntry] = [:]
  Class: NutritionTargets
    Properties:
      - let calories: Double
      - let protein: Double
      - let carbs: Double
      - let fat: Double
      - let fiber: Double
      - let water: Double
      - static let `default` = NutritionTargets(
 calories: 2_000, protein: 150, carbs: 250, fat: 70, fiber: 30, water: 2.5
  Class: GreetingContext
    Properties:
      - let userName: String
      - let sleepHours: Double?
      - let sleepQuality: Int?
      - let weather: String?
      - let temperature: Double?
      - let dayOfWeek: String
      - let energyYesterday: Int?
  Class: RecoveryScore
    Properties:
      - let score: Int
      - let components: [Component]
  Class: Component
    Properties:
      - let name: String
      - let value: Double
      - let weight: Double
      - var trend: Trend {
  Class: Trend
  Class: PerformanceInsight
    Properties:
      - let summary: String
      - let trend: Trend
      - let keyMetric: String
      - let value: Double
  Class: Trend
  Class: QuickAction

Enums:
  - Trend
    Cases:
      - improving
      - steady
      - declining
  - Trend
    Cases:
      - up
      - steady
      - down
  - QuickAction
    Cases:
      - logMeal
      - startWorkout
      - logWater
      - checkIn
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Views/Cards/MorningGreetingCard.swift

---
Classes:
  Class: MorningGreetingCard
    Properties:
      - let greeting: String
      - let context: GreetingContext?
      - let currentEnergy: Int?
      - let onEnergyLog: (Int) -> Void
      - @State private var showEnergyPicker = false
      - @State private var animateIn = false
      - var body: some View {
    Methods:
      - @ViewBuilder
    private func contextPills(for context: GreetingContext) -> some View {
      - private func weatherIcon(for condition: String) -> String {
      - private func temperatureColor(for temp: Double) -> Color {
  Class: ContextPill
    Properties:
      - let icon: String
      - let text: String
      - let color: Color
      - var body: some View {
  Class: EnergyLevelIndicator
    Properties:
      - let level: Int
      - private var emoji: String {
      - private var description: String {
      - var body: some View {
  Class: EnergyPickerSheet
    Properties:
      - let currentLevel: Int?
      - let onSelect: (Int) -> Void
      - @State private var selectedLevel: Int?
      - private var dismiss
      - var body: some View {
  Class: EnergyOption
    Properties:
      - let level: Int
      - let isSelected: Bool
      - let onTap: () -> Void
      - private var emoji: String {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Views/Cards/NutritionCard.swift

---
Classes:
  Class: NutritionCard
    Properties:
      - let summary: NutritionSummary
      - let targets: NutritionTargets
      - var onTap: (() -> Void)?
      - @State private var animateRings = false
      - private var caloriesProgress: Double {
      - private var proteinProgress: Double {
      - private var carbsProgress: Double {
      - private var fatProgress: Double {
      - private var waterProgress: Double {
      - var body: some View {
      - var cardHeader: some View {
      - var caloriesRing: some View {
      - var macroBreakdown: some View {
      - var waterIntakeRow: some View {
  Class: MacroRow
    Properties:
      - let label: String
      - let value: Double
      - let target: Double
      - let color: Color
      - let progress: Double
      - var body: some View {
  Class: AnimatedRing
    Properties:
      - let progress: Double
      - let gradient: LinearGradient
      - let lineWidth: CGFloat
      - @State private var animatedProgress: Double = 0
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Views/Cards/PerformanceCard.swift

---
Classes:
  Class: PerformanceCard
    Properties:
      - let insight: PerformanceInsight?
  Class: ChartPoint
    Properties:
      - let id = UUID()
      - let index: Int
      - let value: Double
      - private var history: [ChartPoint] {
      - var body: some View {
      - private var header: some View {
      - private var noDataView: some View {
      - private var accessibilityDescription: String {
  Class: TrendIndicator
    Properties:
      - let trend: Any
      - private var icon: String {
      - private var color: Color {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Views/Cards/QuickActionsCard.swift

---
Classes:
  Class: QuickActionsCard
    Properties:
      - let suggestedActions: [QuickAction]
      - let onActionTap: (QuickAction) -> Void
      - private let actionColumns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 3)
      - var body: some View {
  Class: QuickActionButton
    Properties:
      - let action: QuickAction
      - let onTap: () -> Void
      - var body: some View {
    Methods:
      - private func handleTap() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Views/Cards/RecoveryCard.swift

---
Classes:
  Class: RecoveryCard
    Properties:
      - let recoveryScore: RecoveryScore?
      - @State private var animateRing = false
      - private var progress: Double {
      - private var scoreColor: Color {
      - private var ringGradient: LinearGradient {
  Class: ChartPoint
    Properties:
      - let id = UUID()
      - let index: Int
      - let value: Double
      - private var history: [ChartPoint] {
      - var body: some View {
      - private var header: some View {
      - private var componentsView: some View {
      - private var noDataView: some View {
      - private var accessibilityDescription: String {
  Class: ProgressRing
    Properties:
      - let progress: Double
      - let gradient: LinearGradient
      - let lineWidth: CGFloat
      - let label: String
      - @State private var animatedProgress: Double = 0
      - var body: some View {
  Class: TrendIndicator
    Properties:
      - let trend: Any
      - private var icon: String {
      - private var color: Color {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Dashboard/Views/DashboardView.swift

---
Classes:
  Class: DashboardView
    Properties:
      - private var modelContext
      - @State private var viewModel: DashboardViewModel
      - @StateObject private var coordinator: DashboardCoordinator
      - @State private var hasAppeared = false
      - private let columns: [GridItem] = [
 GridItem(.adaptive(minimum: 180), spacing: AppSpacing.medium)
      - var body: some View {
      - private var loadingView: some View {
      - private var dashboardContent: some View {
    Methods:
      - private func errorView(_ error: Error) -> some View {
      - @ViewBuilder
    private func destinationView(for destination: DashboardDestination) -> some View {
      - private func handleQuickAction(_ action: QuickAction) {
  Class: DashboardCoordinator
    Properties:
      - @Published var path = NavigationPath()
    Methods:
      - func navigate(to destination: DashboardDestination) {
      - func navigateBack() {
  Class: DashboardDestination
  Class: PlaceholderHealthKitService
    Methods:
      - func getCurrentContext() async throws -> HealthContext {
      - func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
      - func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
  Class: PlaceholderAICoachService
    Methods:
      - func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
  Class: PlaceholderNutritionService
    Methods:
      - func getTodaysSummary(for user: User) async throws -> NutritionSummary {
      - func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets {

Enums:
  - DashboardDestination
    Cases:
      - placeholder
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Coordinators/FoodTrackingCoordinator.swift

---
Classes:
  Class: FoodTrackingCoordinator
    Properties:
      - var navigationPath = NavigationPath()
      - var activeSheet: FoodTrackingSheet?
      - var activeFullScreenCover: FoodTrackingFullScreenCover?
  Class: FoodTrackingSheet
  Class: FoodTrackingFullScreenCover
    Methods:
      - func navigateTo(_ destination: FoodTrackingDestination) {
      - func showSheet(_ sheet: FoodTrackingSheet) {
      - func showFullScreenCover(_ cover: FoodTrackingFullScreenCover) {
      - func dismiss() {
      - func pop() {
      - func popToRoot() {
      - func handleDeepLink(_ destination: FoodTrackingDestination) {
  Class: FoodTrackingDestination

Enums:
  - FoodTrackingSheet
    Cases:
      - voiceInput
      - photoCapture
      - foodSearch
      - manualEntry
      - waterTracking
      - mealDetails
  - FoodTrackingFullScreenCover
    Cases:
      - camera
      - confirmation
  - FoodTrackingDestination
    Cases:
      - history
      - insights
      - favorites
      - recipes
      - mealPlan
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift

---
Classes:
  Class: FoodNutritionSummary
    Properties:
      - var calories: Double = 0
      - var protein: Double = 0
      - var carbs: Double = 0
      - var fat: Double = 0
      - var fiber: Double = 0
      - var sugar: Double = 0
      - var sodium: Double = 0
      - var calorieGoal: Double = 2000
      - var proteinGoal: Double = 150
      - var carbGoal: Double = 250
      - var fatGoal: Double = 65
      - var calorieProgress: Double {
      - var proteinProgress: Double {
      - var carbProgress: Double {
      - var fatProgress: Double {
  Class: VisionAnalysisResult
    Properties:
      - let recognizedText: [String]
      - let confidence: Float
  Class: ParsedFoodItem
    Properties:
      - let id = UUID()
      - let name: String
      - let brand: String?
      - let quantity: Double
      - let unit: String
      - let calories: Int
      - let proteinGrams: Double
      - let carbGrams: Double
      - let fatGrams: Double
      - let fiberGrams: Double?
      - let sugarGrams: Double?
      - let sodiumMilligrams: Double?
      - let databaseId: String?
      - let confidence: Float
      - var fiber: Double? {
      - var sugar: Double? {
      - var sodium: Double? {
  Class: TimeoutError
    Properties:
      - let operation: String
      - let timeoutDuration: TimeInterval
      - var errorDescription: String? {
  Class: MealPhotoAnalysisResult
    Properties:
      - let items: [ParsedFoodItem]
      - let confidence: Float
      - let processingTime: TimeInterval
  Class: FoodTrackingError
  Class: FoodDatabaseItem
    Properties:
      - let id: String
      - let name: String
      - let brand: String?
      - let caloriesPerServing: Double
      - let proteinPerServing: Double
      - let carbsPerServing: Double
      - let fatPerServing: Double
      - let servingSize: Double
      - let servingUnit: String
      - let defaultQuantity: Double
      - let defaultUnit: String
  Class: NutritionContext
    Properties:
      - let userGoals: NutritionTargets?
      - let recentMeals: [FoodEntry]
      - let currentDate: Date
  Class: FoodSearchResult
    Properties:
      - let id = UUID()
      - let name: String
      - let calories: Double
      - let protein: Double
      - let carbs: Double
      - let fat: Double
      - let servingSize: String

Enums:
  - FoodTrackingError
    Cases:
      - transcriptionFailed
      - aiParsingFailed
      - noFoodFound
      - networkError
      - invalidInput
      - permissionDenied
      - aiProcessingTimeout
      - invalidNutritionResponse
      - invalidNutritionData
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Services/FoodVoiceAdapter.swift

---
Classes:
  Class: FoodVoiceAdapter
    Properties:
      - private let voiceInputManager: VoiceInputManager
      - @Published private(set) var isRecording = false
      - @Published private(set) var transcribedText = ""
      - @Published private(set) var voiceWaveform: [Float] = []
      - @Published private(set) var isTranscribing = false
      - var onFoodTranscription: ((String) -> Void)?
      - var onError: ((Error) -> Void)?
    Methods:
      - private func setupCallbacks() {
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
      - private func postProcessForFood(_ text: String) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Services/NutritionService.swift

---
Classes:
  Class: NutritionService
    Properties:
      - private let modelContext: ModelContext
      - private let healthStore = HKHealthStore()
    Methods:
      - func saveFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
      - func deleteFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
      - nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
      - func getWaterIntake(for user: User, date: Date) async throws -> Double {
      - func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
      - func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
      - func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
      - nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
      - func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
      - func syncCaloriesToHealthKit(for user: User, date: Date) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Services/PreviewServices.swift

---
Classes:
  Class: PreviewNutritionService
    Properties:
      - private var entries: [FoodEntry] = []
      - private var waterLogs: [UUID: [Date: Double]] = [:]
    Methods:
      - func saveFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
      - func deleteFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
      - nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
      - func getWaterIntake(for user: User, date: Date) async throws -> Double {
      - func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
      - func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
      - func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
      - nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
      - func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
  Class: PreviewCoachEngine
    Methods:
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
      - func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
      - func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
      - func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/ViewModels/FoodTrackingViewModel.swift

---
Classes:
  Class: FoodTrackingViewModel
    Properties:
      - private let modelContext: ModelContext
      - internal let user: User
      - private let foodVoiceAdapter: FoodVoiceAdapter
      - private let nutritionService: NutritionServiceProtocol?
      - internal let coachEngine: FoodCoachEngineProtocol
      - private let coordinator: FoodTrackingCoordinator
      - private(set) var isLoading = false
      - private(set) var error: Error?
      - var selectedMealType: MealType = .lunch
      - var currentDate = Date()
      - private(set) var isRecording = false
      - private(set) var transcribedText = ""
      - private(set) var transcriptionConfidence: Float = 0
      - private(set) var voiceWaveform: [Float] = []
      - private(set) var parsedItems: [ParsedFoodItem] = []
      - private(set) var isProcessingAI = false
      - private(set) var todaysFoodEntries: [FoodEntry] = []
      - private(set) var todaysNutrition = FoodNutritionSummary()
      - private(set) var waterIntakeML: Double = 0
      - private(set) var searchResults: [ParsedFoodItem] = []
      - private(set) var recentFoods: [FoodItem] = []
      - private(set) var suggestedFoods: [FoodItem] = []
      - private(set) var currentError: Error?
      - var hasError: Bool {
    Methods:
      - func clearError() {
      - private func setError(_ error: Error) {
      - private func setupVoiceCallbacks() {
      - func loadTodaysData() async {
      - func startVoiceInput() async {
      - func startRecording() async {
      - func stopRecording() async {
      - private func processTranscription() async {
      - func startPhotoCapture() {
      - func processPhotoResult(_ image: UIImage) async {
      - func searchFoods(_ query: String) async {
      - func selectSearchResult(_ item: ParsedFoodItem) {
      - func confirmAndSaveFoodItems(_ items: [ParsedFoodItem]) async {
      - func logWater(amount: Double, unit: WaterUnit) async {
      - private func generateSmartSuggestions() async throws -> [FoodItem] {
      - func deleteFoodEntry(_ entry: FoodEntry) async {
      - func duplicateFoodEntry(_ entry: FoodEntry) async {
      - private func processAIResult(functionCall: AIFunctionCall) async {
      - private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
      - func setSelectedMealType(_ mealType: MealType) {
      - func setParsedItems(_ items: [ParsedFoodItem]) {
  Class: WaterUnit
    Methods:
      - func toMilliliters(_ amount: Double) -> Double {

Enums:
  - WaterUnit
    Cases:
      - milliliters
      - oz
      - cups
      - liters
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Views/FoodConfirmationView.swift

---
Classes:
  Class: FoodConfirmationView
    Properties:
      - @State private var items: [ParsedFoodItem]
      - @State var viewModel: FoodTrackingViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var editingItem: ParsedFoodItem?
      - @State private var showAddItem = false
      - var body: some View {
      - private var mealTypeHeader: some View {
      - private var nutritionSummary: some View {
      - private var actionButtons: some View {
      - private var totalCalories: Double {
      - private var totalProtein: Double {
      - private var totalCarbs: Double {
      - private var totalFat: Double {
    Methods:
      - private func deleteItem(_ item: ParsedFoodItem) {
      - private func saveItems() {
  Class: FoodItemCard
    Properties:
      - let item: ParsedFoodItem
      - let onEdit: () -> Void
      - let onDelete: () -> Void
      - var body: some View {
  Class: NutrientLabel
    Properties:
      - let value: Double
      - let unit: String
      - var label: String? = nil
      - let color: Color
      - var body: some View {
      - var icon: String {
  Class: FoodItemEditView
    Properties:
      - @State var item: ParsedFoodItem
      - var onSave: (ParsedFoodItem) -> Void
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: ManualFoodEntryView
    Properties:
      - @State var viewModel: FoodTrackingViewModel
      - var onAdd: (ParsedFoodItem) -> Void
      - @Environment(\.dismiss) private var dismiss
      - @State private var name = ""
      - @State private var calories: Double = 0
      - var body: some View {
  Class: MockNutritionService
    Methods:
      - func saveFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
      - func deleteFoodEntry(_ entry: FoodEntry) async throws {
      - func getFoodEntries(for user: User, date: Date) async throws -> [FoodEntry] {
      - nonisolated func calculateNutritionSummary(from entries: [FoodEntry]) -> FoodNutritionSummary {
      - func getWaterIntake(for user: User, date: Date) async throws -> Double {
      - func getRecentFoods(for user: User, limit: Int) async throws -> [FoodItem] {
      - func logWaterIntake(for user: User, amountML: Double, date: Date) async throws {
      - func getMealHistory(for user: User, mealType: MealType, daysBack: Int) async throws -> [FoodEntry] {
      - nonisolated func getTargets(from profile: OnboardingProfile?) -> NutritionTargets {
      - func getTodaysSummary(for user: User) async throws -> FoodNutritionSummary {
  Class: MockCoachEngine
    Methods:
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func executeFunction(_ functionCall: AIFunctionCall, for user: User) async throws -> FunctionExecutionResult {
      - func analyzeMealPhoto(image: UIImage, context: NutritionContext?) async throws -> MealPhotoAnalysisResult {
      - func searchFoods(query: String, limit: Int) async throws -> [ParsedFoodItem] {
      - func parseNaturalLanguageFood(
        text: String,
        mealType: MealType,
        for user: User
    ) async throws -> [ParsedFoodItem] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Views/FoodLoggingView.swift

---
Classes:
  Class: FoodLoggingView
    Properties:
      - @State private var viewModel: FoodTrackingViewModel
      - @State private var coordinator: FoodTrackingCoordinator
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
      - private var datePicker: some View {
      - private var macroSummaryCard: some View {
      - private var quickActionsSection: some View {
      - private var mealsSection: some View {
      - private var suggestionsSection: some View {
    Methods:
      - private func previousDay() {
      - private func nextDay() {
      - private func selectSuggestedFood(_ food: FoodItem) {
      - @ViewBuilder
    private func destinationView(for destination: FoodTrackingDestination) -> some View {
      - @ViewBuilder
    private func sheetView(for sheet: FoodTrackingCoordinator.FoodTrackingSheet) -> some View {
      - @ViewBuilder
    private func fullScreenView(for cover: FoodTrackingCoordinator.FoodTrackingFullScreenCover) -> some View {
  Class: QuickActionButton
    Properties:
      - let title: String
      - let icon: String
      - let color: Color
      - let action: () -> Void
      - var body: some View {
  Class: MealCard
    Properties:
      - let mealType: MealType
      - let entries: [FoodEntry]
      - let onAdd: () -> Void
      - let onTapEntry: (FoodEntry) -> Void
      - private var totalCalories: Int {
      - var body: some View {
  Class: SuggestionCard
    Properties:
      - let food: FoodItem
      - let action: () -> Void
      - var body: some View {
  Class: PlaceholderView
    Properties:
      - let title: String
      - let subtitle: String
      - var body: some View {
      - var icon: String {
      - var displayQuantity: String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Views/FoodVoiceInputView.swift

---
Classes:
  Class: FoodVoiceInputView
    Properties:
      - @State var viewModel: FoodTrackingViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var pulseAnimation = false
      - @State private var audioLevel: Float = 0
      - private let audioLevelTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
      - var body: some View {
      - private var instructionsSection: some View {
      - private var microphoneButton: some View {
      - private var waveformSection: some View {
      - private var transcriptionSection: some View {
      - private var statusSection: some View {
    Methods:
      - private func handlePressing(_ isPressing: Bool) {
      - private func updateAudioLevel() {
  Class: ExampleText
    Properties:
      - let text: String
      - var body: some View {
  Class: ConfidenceIndicator
    Properties:
      - let confidence: Float
      - private var color: Color {
      - var body: some View {
  Class: VoiceWaveformView
    Properties:
      - let levels: [Float]
      - var body: some View {
  Class: VoiceInputView_Previews
    Properties:
      - static var previews: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Views/MacroRingsView.swift

---
Classes:
  Class: MacroRingsView
    Properties:
      - let nutrition: FoodNutritionSummary
      - var style: Style = .full
      - var animateOnAppear: Bool = true
      - @State private var animateRings = false
  Class: Style
    Properties:
      - private let ringWidthFull: CGFloat = 16
      - private let ringWidthCompact: CGFloat = 8
      - private let ringSpacing: CGFloat = 4
      - var body: some View {
      - private var fullRingsView: some View {
      - private var compactRingsView: some View {
      - private var macroData: [MacroData] {
    Methods:
      - private func ringDiameter(for index: Int) -> CGFloat {
  Class: MacroLegendItem
    Properties:
      - let title: String
      - let value: Double
      - let goal: Double
      - let color: Color
      - let unit: String
      - private var progress: Double {
      - private var isOverGoal: Bool {
      - var body: some View {
  Class: CompactRingView
    Properties:
      - let macro: MacroData
      - let animate: Bool
      - let delay: Double
      - @State private var animateProgress = false
      - var body: some View {
  Class: MacroData
    Properties:
      - let label: String
      - let value: Double
      - let goal: Double
      - let color: Color
      - let progress: Double

Enums:
  - Style
    Cases:
      - full
      - compact
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Views/NutritionSearchView.swift

---
Classes:
  Class: NutritionSearchView
    Properties:
      - @State var viewModel: FoodTrackingViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var searchText = ""
      - @State private var selectedCategory: FoodCategory?
      - @State private var debounceTimer: Timer?
      - private let foodCategories: [FoodCategory] = [
 FoodCategory(name: "Fruits", icon: "apple"), FoodCategory(name: "Vegetables", icon: "carrot"), FoodCategory(name: "Proteins", icon: "fish"), FoodCategory(name: "Grains", icon: "leaf"), FoodCategory(name: "Dairy", icon: "drop"), FoodCategory(name: "Snacks", icon: "takeoutbag.and.cup.and.straw")
      - var body: some View {
      - private var searchBar: some View {
      - private var initialContent: some View {
      - private var categoryResultsContent: some View {
      - private var searchResultsContent: some View {
    Methods:
      - private func triggerSearch() {
      - private func performSearch() async {
      - private func selectRecentFood(_ food: FoodItem) {
  Class: CategoriesSection
    Properties:
      - let categories: [FoodCategory]
      - @Binding var selectedCategory: FoodCategory?
      - var body: some View {
  Class: FoodListItem
  Class: FoodItemRow
    Properties:
      - let food: FoodItem
      - let action: () -> Void
      - var body: some View {
  Class: FoodCategory
    Properties:
      - let id = UUID()
      - let name: String
      - let icon: String
  Class: CategoryChip
    Properties:
      - let category: FoodCategory
      - let isSelected: Bool
      - let action: () -> Void
      - var body: some View {
    Methods:
      - @MainActor func makePreview() -> some View {

Enums:
  - FoodListItem
    Cases:
      - recentItem
      - databaseItem
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Views/PhotoInputView.swift

---
Classes:
  Class: PhotoInputView
    Properties:
      - @State var viewModel: FoodTrackingViewModel
      - @Environment(\.dismiss) private var dismiss
      - @StateObject private var cameraManager = CameraManager()
      - @State private var showingImagePicker = false
      - @State private var showingPermissionAlert = false
      - @State private var capturedImage: UIImage?
      - @State private var isAnalyzing = false
      - @State private var analysisProgress: Double = 0
      - @State private var showingTips = false
      - var body: some View {
      - private var cameraPreviewLayer: some View {
      - private var topControls: some View {
      - private var bottomControls: some View {
      - private var analysisOverlay: some View {
    Methods:
      - private func setupCamera() {
      - private func requestCameraPermission() {
      - private func capturePhoto() {
      - private func toggleAIAnalysis() {
      - private func analyzePhoto(_ image: UIImage) {
      - private func updateProgress(to value: Double, message: String) async {
      - private func performVisionAnalysis(on image: UIImage) async throws -> VisionAnalysisResult {
      - private func performAIFoodAnalysis(image: UIImage, visionResults: VisionAnalysisResult) async throws -> [ParsedFoodItem] {
      - private func convertAIResultToFoodItems(_ data: [String: SendableValue]) throws -> [ParsedFoodItem] {
      - private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
      - private func extractString(from value: SendableValue?) -> String? {
      - private func extractDouble(from value: SendableValue?) -> Double? {
      - private func extractFloat(from value: SendableValue?) -> Float? {
      - private func openSettings() {
  Class: CameraManager
    Properties:
      - @Published var isAuthorized = false
      - @Published var session = AVCaptureSession()
      - @Published var flashMode: AVCaptureDevice.FlashMode = .off
      - @Published var isCapturing = false
      - @Published var isFocusing = false
      - @Published var focusScale: CGFloat = 1.0
      - @Published var aiAnalysisEnabled = true
      - private var photoOutput = AVCapturePhotoOutput()
      - private var currentCamera: AVCaptureDevice?
      - private var frontCamera: AVCaptureDevice?
      - private var backCamera: AVCaptureDevice?
      - private var photoContinuation: CheckedContinuation<UIImage?, Never>?
    Methods:
      - func requestPermission() async {
      - func startSession() async {
      - func stopSession() {
      - func capturePhoto() async -> UIImage? {
      - func toggleFlash() {
      - func switchCamera() {
      - private func setupCameras() {
      - func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
  Class: CameraPreview
    Properties:
      - let session: AVCaptureSession
    Methods:
      - func makeUIView(context: Context) -> UIView {
      - func updateUIView(_ uiView: UIView, context: Context) {
  Class: CameraPlaceholder
    Properties:
      - let action: () -> Void
      - var body: some View {
  Class: ImagePicker
    Properties:
      - @Binding var image: UIImage?
      - let sourceType: UIImagePickerController.SourceType
      - @Environment(\.dismiss) private var dismiss
    Methods:
      - func makeUIViewController(context: Context) -> UIImagePickerController {
      - func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
      - func makeCoordinator() -> Coordinator {
  Class: Coordinator
    Properties:
      - let parent: ImagePicker
    Methods:
      - func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      - func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
  Class: PhotoTipsView
    Properties:
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: TipRow
    Properties:
      - let icon: String
      - let title: String
      - let description: String
      - var body: some View {
  Class: PhotoAnalysisError

Enums:
  - PhotoAnalysisError
    Cases:
      - invalidImage
      - imageProcessingFailed
      - visionAnalysisFailed
      - aiAnalysisFailed
      - noFoodsDetected
      - analysisTimeout
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Views/WaterTrackingView.swift

---
Classes:
  Class: WaterTrackingView
    Properties:
      - @Environment(\.dismiss) private var dismiss
      - @State private var viewModel: FoodTrackingViewModel
      - @State private var selectedAmount: Double = 250 // Default quick add selection
      - @State private var selectedUnit: WaterUnit = .milliliters
      - @State private var customAmountString: String = ""
      - @State private var useCustomAmount: Bool = false
      - private let quickAmountsInML: [Double] = [250, 350, 500, 750] // Common amounts in mL
      - private let dailyWaterGoalInML: Double = 2000 // Default daily goal, can be dynamic later
      - @State private var waterLevel: CGFloat = 0
      - @State private var showTips: Bool = false
      - var body: some View {
      - private var currentCustomAmountValue: Double {
      - private var isAddButtonDisabled: Bool {
      - private var progressTowardsGoal: Double {
      - private var overGoalProgress: Double {
      - private var currentIntakeSection: some View {
      - private var goalStatusText: String {
      - private var quickAddSection: some View {
      - private var customAmountSection: some View {
      - private var hydrationTipsSection: some View {
    Methods:
      - private func initialSetup() {
      - private func updateWaterLevelAnimation(intake: Double) {
      - private func addWater() {
  Class: QuickWaterButton
    Properties:
      - let amount: Double
      - let unit: WaterUnit // Expecting .ml for consistency from quickAmountsInML
      - let isSelected: Bool
      - let action: () -> Void
      - private var displayText: String {
      - var body: some View {
  Class: HydrationTipsView
    Properties:
      - @Environment(\.dismiss) private var dismiss
      - private let tips = [
 ("Start Early", "Drink a glass of water when you wake up."), ("Flavor It Up", "Add lemon, cucumber, or berries to your water."), ("Eat Water-Rich Foods", "Fruits like watermelon and vegetables like cucumber contribute to hydration."), ("Set Reminders", "Use app notifications or alarms to remind yourself to drink."), ("Before Meals", "Drink a glass of water before each meal."), ("Track Your Intake", "Use this app to monitor your progress!"), ("Listen to Your Body", "Drink when you feel thirsty, and check urine color (pale yellow is good).")
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Notifications/Coordinators/NotificationsCoordinator.swift

---
Classes:
  Class: NotificationsCoordinator
    Properties:
      - private let modelContext: ModelContext
      - private let notificationManager: NotificationManager
      - private let engagementEngine: EngagementEngine
      - private let liveActivityManager: LiveActivityManager
      - private let notificationContentGenerator: NotificationContentGenerator
    Methods:
      - func setupNotifications() async throws {
      - func updateUserActivity(for user: User) {
      - func scheduleSmartNotifications(for user: User) async {
      - func startWorkoutLiveActivity(workoutType: String) async throws {
      - func updateWorkoutLiveActivity(
        elapsedTime: TimeInterval,
        heartRate: Int,
        activeCalories: Int,
        currentExercise: String?
    ) async {
      - func endWorkoutLiveActivity() async {
      - func startMealTrackingLiveActivity(mealType: MealType) async throws {
      - func updateMealTrackingLiveActivity(
        itemsLogged: Int,
        totalCalories: Int,
        totalProtein: Double,
        lastFoodItem: String?
    ) async {
      - func endMealTrackingLiveActivity() async {
      - func scheduleMorningGreeting(for user: User) async throws {
      - func checkAndHandleLapsedUsers() async throws {
      - func sendAchievementNotification(for user: User, achievement: Achievement) async throws {
      - func cancelAllNotifications() {
      - func getPendingNotifications() async -> [UNNotificationRequest] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Notifications/Managers/LiveActivityManager.swift

---
Classes:
  Class: LiveActivityManager
    Properties:
      - static let shared = LiveActivityManager()
      - private var workoutActivity: Activity<WorkoutActivityAttributes>?
      - private var mealTrackingActivity: Activity<MealTrackingActivityAttributes>?
    Methods:
      - func startWorkoutActivity(
        workoutType: String,
        startTime: Date
    ) async throws {
      - func updateWorkoutActivity(
        elapsedTime: TimeInterval,
        heartRate: Int,
        activeCalories: Int,
        currentExercise: String?
    ) async {
      - func endWorkoutActivity() async {
      - func startMealTrackingActivity(mealType: MealType) async throws {
      - func updateMealTracking(
        itemsLogged: Int,
        totalCalories: Int,
        totalProtein: Double,
        lastFoodItem: String?
    ) async {
      - func endMealTrackingActivity() async {
      - func endAllActivities() async {
      - func observePushTokenUpdates() {
      - private func sendPushTokenToServer(_ token: Data) async {
  Class: WorkoutActivityAttributes
  Class: ContentState
    Properties:
      - let elapsedTime: TimeInterval
      - let heartRate: Int
      - let activeCalories: Int
      - let currentExercise: String?
      - let workoutType: String
      - let startTime: Date
  Class: MealTrackingActivityAttributes
  Class: ContentState
    Properties:
      - let itemsLogged: Int
      - let totalCalories: Int
      - let totalProtein: Double
      - let lastFoodItem: String?
      - let mealType: String
      - let targetCalories: Int
      - let targetProtein: Double
  Class: LiveActivityError

Enums:
  - LiveActivityError
    Cases:
      - notEnabled
      - failedToStart
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Notifications/Managers/NotificationManager.swift

---
Classes:
  Class: NotificationManager
    Properties:
      - static let shared = NotificationManager()
      - private let center = UNUserNotificationCenter.current()
      - private var pendingNotifications: Set<String> = []
  Class: NotificationCategory
  Class: NotificationIdentifier
    Properties:
      - static let navigateToMoodLogging = Notification.Name("navigateToMoodLogging")
      - static let navigateToChat = Notification.Name("navigateToChat")
      - static let navigateToWorkout = Notification.Name("navigateToWorkout")
      - static let navigateToMealLogging = Notification.Name("navigateToMealLogging")
    Methods:
      - func requestAuthorization() async throws -> Bool {
      - private func registerForRemoteNotifications() async {
      - private func setupNotificationCategories() {
      - func scheduleNotification(
        identifier: NotificationIdentifier,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        attachments: [UNNotificationAttachment] = [],
        categoryIdentifier: NotificationCategory? = nil,
        userInfo: [String: Any] = [:],
        trigger: UNNotificationTrigger
    ) async throws {
      - func cancelNotification(identifier: NotificationIdentifier) {
      - func cancelAllNotifications() {
      - func getPendingNotifications() async -> [UNNotificationRequest] {
      - func createAttachment(from imageData: Data, identifier: String) throws -> UNNotificationAttachment? {
      - private func determineInterruptionLevel(for category: NotificationCategory?) -> UNNotificationInterruptionLevel {
      - func updateBadgeCount(_ count: Int) async {
      - func clearBadge() async {
      - nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
      - nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
      - private func handleNotificationResponse(_ response: UNNotificationResponse) async {
      - private func navigateToMoodLogging() async {
      - private func navigateToChat() async {
      - private func navigateToWorkout() async {
      - private func navigateToMealLogging() async {
      - private func handleDefaultAction(userInfo: [AnyHashable: Any]) async {

Enums:
  - NotificationCategory
    Cases:
      - dailyCheck
      - workout
      - meal
      - hydration
      - achievement
      - reEngagement
  - NotificationIdentifier
    Cases:
      - morning
      - workout
      - meal
      - hydration
      - achievement
      - lapse
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Notifications/Models/NotificationModels.swift

---
Classes:
  Class: NotificationContent
    Properties:
      - let title: String
      - let body: String
      - var subtitle: String?
      - var imageKey: String?
      - var sound: NotificationSound = .default
      - var actions: [NotificationAction] = []
      - var badge: Int?
  Class: NotificationAction
    Properties:
      - let id: String
      - let title: String
      - let isDestructive: Bool = false
  Class: NotificationSound
  Class: EngagementMetrics
    Properties:
      - let totalUsers: Int
      - let activeUsers: Int
      - let lapsedUsers: Int
      - let churnRiskUsers: Int
      - let avgSessionsPerWeek: Double
      - let avgSessionDuration: TimeInterval
      - var engagementRate: Double {
  Class: ReEngagementContext
    Properties:
      - let userName: String
      - let daysSinceLastActive: Int
      - let primaryGoal: String?
      - let previousEngagementAttempts: Int
      - let lastWorkoutType: String?
      - let personalityTraits: PersonaProfile?
  Class: CommunicationPreferences
    Properties:
      - let absenceResponse: String // "give_me_space", "light_nudge", "check_in_on_me"
      - let preferredTimes: [String]
      - let frequency: String
  Class: NotificationPreferences
    Properties:
      - var systemEnabled: Bool = true
      - var morningGreeting = true
      - var morningTime = Date()
      - var workoutReminders = true
      - var workoutSchedule: [WorkoutSchedule] = []
      - var mealReminders = true
      - var hydrationReminders = true
      - var hydrationFrequency: HydrationFrequency = .biHourly
      - var dailyCheckins: Bool = true
      - var achievementAlerts: Bool = true
      - var coachMessages: Bool = true
  Class: HydrationFrequency
  Class: WorkoutSchedule
    Properties:
      - let type: String
      - let scheduledDate: Date
      - let dateComponents: DateComponents
  Class: MorningContext
    Properties:
      - let userName: String
      - let sleepQuality: SleepQuality?
      - let sleepDuration: TimeInterval?
      - let weather: WeatherData?
      - let plannedWorkout: WorkoutTemplate?
      - let currentStreak: Int
      - let dayOfWeek: Int
      - let motivationalStyle: MotivationalStyle
  Class: WorkoutReminderContext
    Properties:
      - let userName: String
      - let workoutType: String
      - let lastWorkoutDays: Int
      - let streak: Int
      - let motivationalStyle: MotivationalStyle
  Class: MealReminderContext
    Properties:
      - let userName: String
      - let mealType: MealType
      - let nutritionGoals: NutritionGoals?
      - let lastMealLogged: Date?
      - let favoritesFoods: [String]
  Class: AchievementContext
    Properties:
      - let userName: String
      - let achievementName: String
      - let achievementDescription: String
      - let streak: Int?
      - let personalBest: Bool
  Class: SleepQuality
  Class: SleepData
    Properties:
      - let quality: SleepQuality
      - let duration: TimeInterval
  Class: NutritionGoals
    Properties:
      - let dailyCalories: Int
      - let proteinGrams: Int
      - let carbGrams: Int
      - let fatGrams: Int
  Class: Achievement
    Properties:
      - let id: String
      - let name: String
      - let description: String
      - let imageKey: String
      - let isPersonalBest: Bool
      - let streak: Int?

Enums:
  - NotificationSound
    Cases:
      - `default`
      - achievement
      - reminder
      - urgent
  - HydrationFrequency
    Cases:
      - hourly
      - biHourly
      - triDaily
  - SleepQuality
    Cases:
      - poor
      - fair
      - good
      - excellent
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Notifications/Services/EngagementEngine.swift

---
Classes:
  Class: EngagementEngine
    Properties:
      - private let modelContext: ModelContext
      - private let notificationManager = NotificationManager.shared
      - private let coachEngine: CoachEngine
      - static let lapseDetectionTaskIdentifier = "com.airfit.lapseDetection"
      - static let engagementAnalysisTaskIdentifier = "com.airfit.engagementAnalysis"
      - private let inactivityThresholdDays = 3
      - private let churnRiskThresholdDays = 7
      - var daysSinceLastActive: Int {
      - var reEngagementAttempts: Int {
    Methods:
      - private func registerBackgroundTasks() {
      - func scheduleBackgroundTasks() {
      - private func scheduleLapseDetection() {
      - private func scheduleEngagementAnalysis() {
      - private func handleLapseDetection(task: BGProcessingTask) async {
      - func detectLapsedUsers() async throws -> [User] {
      - private func handleEngagementAnalysis(task: BGProcessingTask) async {
      - private func analyzeEngagementMetrics() async throws -> EngagementMetrics {
      - func sendReEngagementNotification(for user: User) async {
      - private func generateReEngagementMessage(for user: User) async throws -> (title: String, body: String) {
      - func scheduleSmartNotifications(for user: User) async {
      - private func scheduleMorningGreeting(for user: User, time: Date) async {
      - private func scheduleWorkoutReminders(for user: User, schedule: [WorkoutSchedule]) async {
      - private func scheduleMealReminders(for user: User) async {
      - private func scheduleHydrationReminders(frequency: HydrationFrequency) async {
      - private func calculateAverageSessionsPerWeek(_ users: [User]) -> Double {
      - private func calculateAverageSessionDuration(_ users: [User]) -> TimeInterval {
      - private func updateEngagementStrategies(based metrics: EngagementMetrics) async {
      - func updateUserActivity(for user: User) {
      - func generateReEngagementMessage(_ context: ReEngagementContext) async throws -> String {
      - func generateMorningGreeting(for user: User) async throws -> String {
      - func generateWorkoutReminder(workoutType: String, userName: String) async throws -> (title: String, body: String) {
      - func generateMealReminder(mealType: MealType, userName: String) async throws -> (title: String, body: String) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Notifications/Services/NotificationContentGenerator.swift

---
Classes:
  Class: NotificationContentGenerator
    Properties:
      - private let coachEngine: CoachEngine
      - private let modelContext: ModelContext
      - private let fallbackTemplates = NotificationTemplates()
    Methods:
      - func generateMorningGreeting(for user: User) async throws -> NotificationContent {
      - func generateWorkoutReminder(
        for user: User,
        workout: WorkoutTemplate?
    ) async throws -> NotificationContent {
      - func generateMealReminder(
        for user: User,
        mealType: MealType
    ) async throws -> NotificationContent {
      - func generateAchievementNotification(
        for user: User,
        achievement: Achievement
    ) async throws -> NotificationContent {
      - private func gatherMorningContext(for user: User) async -> MorningContext {
      - private func selectMorningImage(context: MorningContext) -> String {
      - private func selectWorkoutTitle(context: WorkoutReminderContext) -> String {
      - private func fetchLastNightSleep(for user: User) async throws -> SleepData? {
      - private func fetchCurrentWeather() async throws -> WeatherData? {
      - private func extractMotivationalStyle(from user: User) async -> MotivationalStyle? {
  Class: NotificationTemplates
    Properties:
      - var workoutStreak: Int {
      - var daysSinceLastWorkout: Int {
      - var plannedWorkoutForToday: WorkoutTemplate? {
      - var overallStreak: Int {
      - var nutritionGoals: NutritionGoals? {
      - var lastMealLoggedTime: Date? {
      - var favoriteFoods: [String] {
    Methods:
      - func morningGreeting(user: User, context: MorningContext) -> NotificationContent {
      - func workoutReminder(context: WorkoutReminderContext) -> NotificationContent {
      - func mealReminder(mealType: MealType, context: MealReminderContext) -> NotificationContent {
      - func achievement(achievement: Achievement, context: AchievementContext) -> NotificationContent {
  Class: NotificationContentType
    Methods:
      - func generateNotificationContent<T>(type: NotificationContentType, context: T) async throws -> String {

Enums:
  - NotificationContentType
    Cases:
      - morningGreeting
      - workoutReminder
      - mealReminder
      - achievement
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Coordinators/ConversationCoordinator.swift

---
Classes:
  Class: ConversationCoordinator
  Class: CoordinatorView
    Properties:
      - @Published var isActive = false
      - @Published var currentView: CoordinatorView?
      - private let modelContext: ModelContext
      - private let userId: UUID
      - private let apiKeyManager: APIKeyManagerProtocol
      - private let onCompletion: (PersonaProfile) -> Void
      - private var insights: PersonalityInsights?
      - private var conversationData: ConversationData?
    Methods:
      - func start() {
      - func handleConversationComplete(insights: PersonalityInsights, data: ConversationData) {
      - func handleSynthesisComplete(personaProfile: PersonaProfile) {
      - private func createConversationView() -> ConversationView {
      - private func createSynthesisView(insights: PersonalityInsights, data: ConversationData) -> PersonaSynthesisView {
      - private func extractConversationData(from session: ConversationSession) -> ConversationData {

Enums:
  - CoordinatorView
    Cases:
      - conversation
      - synthesis
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Coordinators/OnboardingCoordinator.swift

---
Classes:
  Class: OnboardingCoordinator
    Properties:
      - var path = NavigationPath()
      - var currentScreen: OnboardingScreen = .openingScreen
    Methods:
      - func navigateToNext() {
      - func navigateToPrevious() {
      - func navigateTo(_ screen: OnboardingScreen) {
      - func reset() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Coordinators/OnboardingFlowCoordinator.swift

---
Classes:
  Class: OnboardingFlowCoordinator
    Properties:
      - var currentView: OnboardingView = .welcome
      - var isLoading = false
      - var error: Error?
      - var progress: Double = 0.0
      - private let conversationManager: ConversationFlowManager
      - private let personaService: PersonaService
      - private let userService: UserServiceProtocol
      - private let modelContext: ModelContext
      - private(set) var conversationSession: ConversationSession?
      - private(set) var generatedPersona: PersonaProfile?
      - private let cache = OnboardingCache()
      - private var memoryWarningObserver: NSObjectProtocol?
      - private lazy var recovery = OnboardingRecovery(cache: cache, modelContext: modelContext)
      - private let reachability = NetworkReachability.shared
      - var isRecovering = false
      - var recoveryMessage: String?
    Methods:
      - func start() {
      - func beginConversation() async {
      - func completeConversation() async {
      - func acceptPersona() async {
      - func adjustPersona(_ adjustment: String) async {
      - func regeneratePersona() async {
      - private func handleError(_ error: Error) async {
      - private func handleRecoveryResult(_ result: RecoveryResult, originalError: Error) async {
      - private func handleAlternativeApproach(_ approach: AlternativeApproach) async {
      - func clearError() {
      - func retryLastAction() async {
      - private func setupMemoryMonitoring() {
      - private func setupNetworkMonitoring() {
      - private func handleMemoryWarning() {
      - func cleanup() {
  Class: OnboardingView
  Class: OnboardingError

Enums:
  - OnboardingView
    Cases:
      - welcome
      - conversation
      - generatingPersona
      - personaPreview
      - complete
  - OnboardingError
    Cases:
      - noSession
      - noPersona
      - personaGenerationFailed
      - saveFailed
      - networkError
      - recoveryFailed
      - noUserFound
      - invalidProfileData
      - missingRequiredField
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Data/ConversationFlowData.swift

---
Classes:
  Class: ConversationFlowData
    Methods:
      - static func defaultFlow() -> [String: ConversationNode] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Models/ConversationModels.swift

---
Classes:
  Class: ConversationNode
    Properties:
      - let id: UUID
      - let nodeType: NodeType
      - let question: ConversationQuestion
      - let inputType: InputType
      - let branchingRules: [BranchingRule]
      - let dataKey: String
      - let validationRules: ValidationRules
      - let analyticsEvent: String?
  Class: NodeType
  Class: ConversationQuestion
    Properties:
      - let primary: String
      - let clarifications: [String]
      - let examples: [String]?
      - let voicePrompt: String?
  Class: InputType
    Methods:
      - static func == (lhs: InputType, rhs: InputType) -> Bool {
  Class: ChoiceOption
    Properties:
      - let id: String
      - let text: String
      - let emoji: String?
      - let traits: [String: Double]
  Class: SliderLabels
    Properties:
      - let min: String
      - let max: String
      - let center: String?
  Class: BranchingRule
    Properties:
      - let condition: BranchCondition
      - let nextNodeId: String
  Class: BranchCondition
  Class: ValidationRules
    Properties:
      - let required: Bool
      - let customValidator: String?

Enums:
  - NodeType
    Cases:
      - opening
      - goals
      - lifestyle
      - personality
      - preferences
      - confirmation
  - InputType
    Cases:
      - text
      - voice
      - singleChoice
      - multiChoice
      - slider
      - hybrid
  - BranchCondition
    Cases:
      - always
      - responseContains
      - traitAbove
      - traitBelow
      - hasResponse
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Models/OnboardingModels.swift

---
Classes:
  Class: OnboardingScreen
  Class: LifeContext
    Properties:
      - var isDeskJob = false
      - var isPhysicallyActiveWork = false
      - var travelsFrequently = false
      - var hasChildrenOrFamilyCare = false
      - var scheduleType: ScheduleType = .predictable
      - var workoutWindowPreference: WorkoutWindow = .varies
  Class: ScheduleType
  Class: WorkoutWindow
  Class: Goal
    Properties:
      - var family: GoalFamily = .healthWellbeing
      - var rawText: String = ""
  Class: GoalFamily
  Class: EngagementPreferences
    Properties:
      - var trackingStyle: TrackingStyle = .dataDrivenPartnership
      - var informationDepth: InformationDepth = .keyMetrics
      - var updateFrequency: UpdateFrequency = .weekly
      - var autoRecoveryLogicPreference = true
  Class: TrackingStyle
  Class: InformationDepth
  Class: UpdateFrequency
  Class: SleepWindow
    Properties:
      - var bedTime: String = "22:30"  // "HH:mm" format
      - var wakeTime: String = "06:30" // "HH:mm" format
      - var consistency: SleepConsistency = .consistent
  Class: SleepConsistency
  Class: MotivationalStyle
    Properties:
      - var celebrationStyle: CelebrationStyle = .subtleAffirming
      - var absenceResponse: AbsenceResponse = .gentleNudge
  Class: CelebrationStyle
  Class: AbsenceResponse
  Class: UserProfileJsonBlob
    Properties:
      - let lifeContext: LifeContext
      - let goal: Goal
      - let personaMode: PersonaMode  // Phase 4: Discrete persona modes
      - let engagementPreferences: EngagementPreferences
      - let sleepWindow: SleepWindow
      - let motivationalStyle: MotivationalStyle
      - let timezone: String
      - let baselineModeEnabled: Bool
      - let blend: Blend?
  Class: Blend
    Properties:
      - var authoritativeDirect: Double = 0.25
      - var encouragingEmpathetic: Double = 0.35
      - var analyticalInsightful: Double = 0.30
      - var playfullyProvocative: Double = 0.10
    Methods:
      - mutating func normalize() {

Enums:
  - OnboardingScreen
    Cases:
      - openingScreen
      - lifeSnapshot
      - coreAspiration
      - coachingStyle
      - engagementPreferences
      - sleepAndBoundaries
      - motivationalAccents
      - generatingCoach
      - coachProfileReady
  - ScheduleType
    Cases:
      - predictable
      - unpredictableChaotic
  - WorkoutWindow
    Cases:
      - earlyBird
      - midDay
      - nightOwl
      - varies
  - GoalFamily
    Cases:
      - strengthTone
      - endurance
      - performance
      - healthWellbeing
      - recoveryRehab
  - TrackingStyle
    Cases:
      - dataDrivenPartnership
      - balancedConsistent
      - guidanceOnDemand
      - custom
  - InformationDepth
    Cases:
      - detailed
      - keyMetrics
      - essentialOnly
  - UpdateFrequency
    Cases:
      - daily
      - weekly
      - onDemand
  - SleepConsistency
    Cases:
      - consistent
      - weekSplit
      - variable
  - CelebrationStyle
    Cases:
      - subtleAffirming
      - enthusiasticCelebratory
  - AbsenceResponse
    Cases:
      - gentleNudge
      - respectSpace
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Models/PersonalityInsights.swift

---
Classes:
  Class: PersonalityInsights
    Properties:
      - var traits: [PersonalityDimension: Double]
      - var communicationStyle: CommunicationProfile
      - var motivationalDrivers: Set<MotivationalDriver>
      - var stressResponses: [StressTrigger: CopingStyle]
      - var confidenceScores: [PersonalityDimension: Double]
      - var lastUpdated: Date
  Class: CodingKeys
    Methods:
      - func encode(to encoder: Encoder) throws {
  Class: PersonalityDimension
  Class: CommunicationProfile
    Properties:
      - var preferredTone: CommunicationTone
      - var detailLevel: DetailLevel
      - var encouragementStyle: EncouragementStyle
      - var feedbackTiming: FeedbackTiming
  Class: CommunicationTone
  Class: DetailLevel
  Class: EncouragementStyle
  Class: FeedbackTiming
  Class: MotivationalDriver
  Class: StressTrigger
  Class: CopingStyle
  Class: GeneratedPersonaProfile
    Properties:
      - let id: UUID
      - let name: String
      - let archetype: String
      - let personalityPrompt: String
      - let voiceCharacteristics: GeneratedVoiceCharacteristics
      - let interactionStyle: GeneratedInteractionStyle
      - let createdAt: Date
      - let sourceInsights: PersonalityInsights
  Class: GeneratedVoiceCharacteristics
    Properties:
      - let pace: VoicePace
      - let energy: VoiceEnergy
      - let warmth: VoiceWarmth
  Class: VoicePace
  Class: VoiceEnergy
  Class: VoiceWarmth
  Class: GeneratedInteractionStyle
    Properties:
      - let greetingStyle: String
      - let signoffStyle: String
      - let encouragementPhrases: [String]
      - let correctionStyle: String
      - let humorLevel: HumorLevel
  Class: HumorLevel

Enums:
  - CodingKeys
    Cases:
      - traits
      - communicationStyle
      - motivationalDrivers
      - stressResponses
      - confidenceScores
      - lastUpdated
  - PersonalityDimension
    Cases:
      - authorityPreference
      - socialOrientation
      - structureNeed
      - intensityPreference
      - dataOrientation
      - emotionalSupport
  - CommunicationTone
    Cases:
      - formal
      - casual
      - balanced
      - energetic
  - DetailLevel
    Cases:
      - minimal
      - moderate
      - comprehensive
  - EncouragementStyle
    Cases:
      - cheerleader
      - analytical
      - balanced
      - tough
  - FeedbackTiming
    Cases:
      - immediate
      - periodic
      - milestone
  - MotivationalDriver
    Cases:
      - achievement
      - health
      - appearance
      - performance
      - social
      - discipline
      - enjoyment
      - knowledge
  - StressTrigger
    Cases:
      - timeConstraints
      - socialPressure
      - lackOfProgress
      - complexity
      - uncertainty
  - CopingStyle
    Cases:
      - directGuidance
      - emotionalSupport
      - simplification
      - dataAndFacts
      - flexibility
  - VoicePace
    Cases:
      - slow
      - moderate
      - fast
  - VoiceEnergy
    Cases:
      - calm
      - balanced
      - energetic
  - VoiceWarmth
    Cases:
      - professional
      - friendly
      - enthusiastic
  - HumorLevel
    Cases:
      - none
      - occasional
      - frequent
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/ConversationAnalytics.swift

---
Classes:
  Class: ConversationAnalyticsEvent
  Class: ConversationMetrics
    Properties:
      - let averageCompletionTime: TimeInterval
      - let completionRate: Double
      - let mostCommonDropOffNode: String?
      - let averageResponseTime: [String: TimeInterval] // nodeId -> avg time
      - let skipRates: [String: Double] // nodeId -> skip rate
  Class: ConversationAnalytics
    Properties:
      - private var events: [AnalyticsEventRecord] = []
      - private let maxEventsInMemory = 1000
    Methods:
      - func track(_ event: ConversationAnalyticsEvent) {
      - func calculateMetrics() -> ConversationMetrics {
      - func calculateFunnel() -> [ConversationNode.NodeType: Double] {
      - func getSlowNodes(threshold: TimeInterval = 5.0) -> [String] {
      - func getErrorRate() -> Double {
      - private func logEvent(_ event: ConversationAnalyticsEvent) {
  Class: AnalyticsEventRecord
    Properties:
      - let event: ConversationAnalyticsEvent
      - let timestamp: Date
      - let sessionId: UUID
      - static var allCases: [ConversationNode.NodeType] {

Enums:
  - ConversationAnalyticsEvent
    Cases:
      - sessionStarted
      - sessionResumed
      - nodeViewed
      - responseSubmitted
      - nodeSkipped
      - sessionCompleted
      - sessionAbandoned
      - errorOccurred
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/ConversationFlowManager.swift

---
Classes:
  Class: ConversationFlowManager
    Properties:
      - private let flowDefinition: [String: ConversationNode]
      - private let modelContext: ModelContext
      - private let responseAnalyzer: ResponseAnalyzer?
      - @Published private(set) var currentNode: ConversationNode?
      - @Published private(set) var session: ConversationSession?
      - @Published private(set) var isLoading = false
      - @Published private(set) var error: Error?
    Methods:
      - func startNewSession(userId: UUID) async {
      - func resumeSession(_ existingSession: ConversationSession) async {
      - func submitResponse(_ response: ResponseValue) async throws {
      - func skipCurrentNode() async throws {
      - private func navigateToNode(nodeId: String) async {
      - private func validateResponse(_ response: ResponseValue, for node: ConversationNode) throws {
      - private func determineNextNode(
        from node: ConversationNode,
        with response: ResponseValue,
        session: ConversationSession
    ) -> String? {
      - private func evaluateBranchCondition(
        _ condition: BranchCondition,
        response: ResponseValue,
        session: ConversationSession
    ) -> Bool {
      - private func updateProgress() {
      - private func completeSession() async {
  Class: ConversationError
  Class: ResponseSnapshot
    Properties:
      - let nodeId: String
      - let responseType: String
      - let responseData: Data
      - let timestamp: Date

Enums:
  - ConversationError
    Cases:
      - noActiveSession
      - nodeNotFound
      - invalidTextLength
      - invalidChoice
      - invalidMultiChoice
      - sliderOutOfRange
      - responseTypeMismatch
      - cannotSkipRequired
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/ConversationPersistence.swift

---
Classes:
  Class: ConversationPersistence
    Properties:
      - private let modelContext: ModelContext
      - private let maxSessionAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    Methods:
      - func saveSession(_ session: ConversationSession) throws {
      - func fetchActiveSession(for userId: UUID) throws -> ConversationSession? {
      - func fetchCompletedSessions(for userId: UUID, limit: Int = 10) throws -> [ConversationSession] {
      - func deleteSession(_ session: ConversationSession) throws {
      - func cleanupOldSessions() async throws {
      - func updateProgress(for session: ConversationSession, nodeId: String, responseCount: Int, totalNodes: Int) throws {
      - func addResponse(to session: ConversationSession, response: ConversationResponse) throws {
      - func getResponses(for session: ConversationSession) -> [ConversationResponse] {
      - func saveInsights(_ insights: PersonalityInsights, for session: ConversationSession) throws {
      - func loadInsights(from session: ConversationSession) throws -> PersonalityInsights? {
      - func exportSession(_ session: ConversationSession) throws -> Data {
      - func importSession(from data: Data, userId: UUID) throws -> ConversationSession {
  Class: ConversationExport
    Properties:
      - let session: SessionData
      - let responses: [ResponseData]
      - let insights: PersonalityInsights?
  Class: SessionData
    Properties:
      - let startedAt: Date
      - let completedAt: Date?
      - let currentNodeId: String
      - let completionPercentage: Double
  Class: ResponseData
    Properties:
      - let nodeId: String
      - let responseType: String
      - let responseData: Data
      - let timestamp: Date
      - let processingTime: TimeInterval
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/OnboardingOrchestrator.swift

---
Classes:
  Class: OnboardingOrchestrator
    Properties:
      - @Published private(set) var state: OnboardingState = .notStarted
      - @Published private(set) var progress: OnboardingProgress = .init()
      - @Published private(set) var error: OnboardingOrchestratorError?
      - private let modelContext: ModelContext
      - private let apiKeyManager: APIKeyManagerProtocol
      - private let userService: UserServiceProtocol
      - private let analytics: ConversationAnalytics
      - private var conversationCoordinator: ConversationCoordinator?
      - private var generatedPersona: PersonaProfile?
    Methods:
      - func startOnboarding(userId: UUID) async throws {
      - func pauseOnboarding() {
      - func resumeOnboarding() async throws {
      - func cancelOnboarding() {
      - func completeOnboarding() async throws {
      - func adjustPersona(_ adjustments: PersonaAdjustments) async throws {
      - private func handlePersonaGenerated(_ persona: PersonaProfile) async {
      - private func applyPersonaAdjustments(
        to persona: PersonaProfile,
        adjustments: PersonaAdjustments
    ) async throws -> PersonaProfile {
      - private func handleError(_ error: OnboardingOrchestratorError) {
  Class: OnboardingState
    Methods:
      - static func == (lhs: OnboardingState, rhs: OnboardingState) -> Bool {
  Class: OnboardingProgress
    Properties:
      - var conversationStarted = false
      - var nodesCompleted = 0
      - var totalNodes = 12
      - var completionPercentage: Double = 0
      - var synthesisStarted = false
      - var extractionComplete = false
      - var synthesisComplete = false
      - var adjustmentCount = 0
      - var startTime = Date()
      - var completionTime: Date?
      - var duration: TimeInterval {
      - var estimatedTimeRemaining: TimeInterval? {
  Class: OnboardingOrchestratorError
    Methods:
      - static func == (lhs: OnboardingOrchestratorError, rhs: OnboardingOrchestratorError) -> Bool {
  Class: PersonaAdjustments
  Class: AdjustmentType
    Properties:
      - let type: AdjustmentType
      - let value: Double // -1.0 to 1.0
      - let feedback: String?

Enums:
  - OnboardingState
    Cases:
      - notStarted
      - conversationInProgress
      - synthesizingPersona
      - reviewingPersona
      - adjustingPersona
      - saving
      - completed
      - paused
      - cancelled
      - error
  - OnboardingOrchestratorError
    Cases:
      - conversationStartFailed
      - responseProcessingFailed
      - synthesisFailed
      - saveFailed
      - adjustmentFailed
      - invalidStateTransition
      - timeout
      - networkError
      - userCancelled
  - AdjustmentType
    Cases:
      - tone
      - energy
      - formality
      - humor
      - supportiveness
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/OnboardingProgressManager.swift

---
Classes:
  Class: OnboardingProgressManager
    Properties:
      - @Published private(set) var currentProgress: PersistedProgress?
      - @Published private(set) var isLoading = false
      - private let modelContext: ModelContext
      - private let userDefaults: UserDefaults
      - private let analytics: ConversationAnalytics
      - private let progressKey = "onboarding.progress"
      - private let lastUpdateKey = "onboarding.lastUpdate"
      - private let versionKey = "onboarding.version"
      - private let currentVersion = 1
    Methods:
      - func saveProgress(_ progress: OnboardingProgress, sessionId: UUID, userId: UUID) async {
      - func loadProgress() async {
      - func clearProgress(sessionId: UUID) async {
      - func hasIncompleteSession(userId: UUID) async -> Bool {
      - func migrateIfNeeded() async {
      - private func saveToUserDefaults(_ progress: PersistedProgress) {
      - private func loadFromUserDefaults() -> PersistedProgress? {
      - private func saveToDatabase(_ progress: PersistedProgress) async {
      - private func loadFromDatabase(userId: UUID) async -> PersistedProgress? {
      - private func markSessionCleared(_ sessionId: UUID) async {
      - private func getCurrentUserId() async -> UUID? {
      - private func migrateProgress(_ progress: PersistedProgress) async -> PersistedProgress? {
  Class: PersistedProgress
    Properties:
      - let sessionId: UUID
      - let userId: UUID
      - let state: OnboardingProgress
      - let lastUpdate: Date
      - var version: Int
  Class: OnboardingProgressRecord
    Properties:
      - var sessionId: UUID
      - var userId: UUID
      - var progressData: Data
      - var lastUpdate: Date
      - var version: Int
      - var isCompleted: Bool
      - var isCleared: Bool
      - var clearedAt: Date?
      - var createdAt: Date
    Methods:
      - func update(from persisted: PersistedProgress) {
      - func toPersistedProgress() -> PersistedProgress? {
  Class: CodingKeys
    Methods:
      - func encode(to encoder: Encoder) throws {
  Class: ProgressEvent
    Methods:
      - func trackEvent(_ event: ProgressEvent, properties: [String: Any] = [:]) {

Enums:
  - CodingKeys
    Cases:
      - conversationStarted
      - nodesCompleted
      - totalNodes
      - completionPercentage
      - synthesisStarted
      - extractionComplete
      - synthesisComplete
      - adjustmentCount
      - startTime
      - completionTime
  - ProgressEvent
    Cases:
      - progressSaved
      - progressCleared
      - progressMigrated
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/OnboardingRecovery.swift

---
Classes:
  Class: OnboardingRecovery
    Properties:
      - private let modelContext: ModelContext
      - private let analytics: ConversationAnalytics
      - private let maxRetryAttempts = 3
      - private let sessionTimeout: TimeInterval = 3600 // 1 hour
      - private var retryAttempts: [String: Int] = [:]
      - private var lastError: [String: Error] = [:]
    Methods:
      - func canRecover(from error: OnboardingOrchestratorError, sessionId: String) -> Bool {
      - func recordError(_ error: OnboardingOrchestratorError, sessionId: String) {
      - func createRecoveryPlan(for error: OnboardingOrchestratorError, sessionId: String) -> RecoveryPlan {
      - func executeRecoveryPlan(_ plan: RecoveryPlan, sessionId: String) async throws {
      - func findRecoverableSession(userId: UUID) async throws -> RecoverableSession? {
      - func resumeSession(_ session: RecoverableSession) async throws -> ConversationSession {
      - private func executeRecoveryAction(_ action: RecoveryAction, sessionId: String) async throws {
      - private func checkNetworkConnectivity() async throws {
      - private func calculateProgress(from session: ConversationSession) -> Double {
      - func clearRecoveryState(sessionId: String) {
  Class: RecoveryPlan
  Class: Strategy
    Properties:
      - let strategy: Strategy
      - let actions: [RecoveryAction]
      - let userMessage: String
  Class: RecoveryAction
  Class: RecoverableSession
    Properties:
      - let sessionId: UUID
      - let userId: UUID
      - let progress: Double
      - let lastNodeId: String?
      - let responses: Int
      - let canResume: Bool
  Class: RecoveryError
  Class: RecoveryEvent
    Methods:
      - func trackEvent(_ event: RecoveryEvent, properties: [String: Any] = [:]) {

Enums:
  - Strategy
    Cases:
      - none
      - retry
      - fallback
      - resume
      - revert
  - RecoveryAction
    Cases:
      - checkConnectivity
      - retryWithBackoff
      - increaseTimeout
      - switchProvider
      - simplifyRequest
      - retry
      - loadFromCache
      - validateState
      - validateResponse
      - retryLastStep
      - validateData
      - revertToLastGood
  - RecoveryError
    Cases:
      - sessionNotFound
      - networkUnavailable
      - corruptedState
      - tooManyRetries
  - RecoveryEvent
    Cases:
      - recoveryStarted
      - recoveryCompleted
      - sessionResumed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/OnboardingService.swift

---
Classes:
  Class: OnboardingService
    Properties:
      - private let modelContext: ModelContext
    Methods:
      - func saveProfile(_ profile: OnboardingProfile) async throws {
      - private func validateProfileStructure(_ profile: OnboardingProfile) throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/OnboardingState.swift

---
Classes:
  Class: SimpleAnalyticsError
    Properties:
      - let message: String
  Class: OnboardingEvent
    Methods:
      - func trackEvent(_ event: OnboardingEvent, properties: [String: Any] = [:]) {
      - func updatePersona(_ persona: PersonaProfile) async throws {
      - func markOnboardingComplete() async throws {

Enums:
  - OnboardingEvent
    Cases:
      - onboardingStarted
      - onboardingPaused
      - onboardingResumed
      - onboardingCancelled
      - onboardingCompleted
      - onboardingError
      - personaGenerated
      - personaAdjusted
      - stateTransition
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/PersonaService.swift

---
Classes:
  Class: PersonaService
    Properties:
      - private let personaSynthesizer: OptimizedPersonaSynthesizer
      - private let llmOrchestrator: LLMOrchestrator
      - private let modelContext: ModelContext
      - private let cache: AIResponseCache
    Methods:
      - func generatePersona(from session: ConversationSession) async throws -> PersonaProfile {
      - func adjustPersona(_ persona: PersonaProfile, adjustment: String) async throws -> PersonaProfile {
      - func savePersona(_ persona: PersonaProfile, for userId: UUID) async throws {
      - private func extractPersonalityInsights(from responses: [ConversationResponse]) async throws -> ConversationPersonalityInsights {
      - private func parsePersonalityInsights(from response: LLMResponse) throws -> ConversationPersonalityInsights {
  Class: InsightsResponse
    Properties:
      - let dominantTraits: [String]
      - let communicationStyle: String
      - let motivationType: String
      - let energyLevel: String
      - let preferredComplexity: String
      - let emotionalTone: [String]
      - let stressResponse: String
      - let preferredTimes: [String]
    Methods:
      - private func parseAdjustedPersona(from response: LLMResponse, original: PersonaProfile) throws -> PersonaProfile {
  Class: AdjustmentResponse
    Properties:
      - let name: String?
      - let archetype: String?
      - let energy: String?
      - let warmth: String?
      - let formality: String?
      - let humorLevel: String?
      - let encouragementPhrases: [String]?
  Class: PersonaError
    Properties:
      - var completionPercentage: Int {
      - var sessionId: UUID {
      - var nodeCount: Int {
      - var summary: String? {
      - var extractedData: [String: Any]? {
    Methods:
      - private func extractUserName(from responses: [ConversationResponse]) -> String {
      - private func extractPrimaryGoal(from responses: [ConversationResponse]) -> String {
      - private func convertResponsesToDict(_ responses: [ConversationResponse]) -> [String: Any] {

Enums:
  - PersonaError
    Cases:
      - parsingFailed
      - generationFailed
      - saveFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/ResponseAnalyzer.swift

---
Classes:
  Class: ResponseAnalyzerImpl
    Methods:
      - func analyzeResponse(
        response: ResponseValue,
        node: ConversationNode,
        previousResponses: [ResponseSnapshot]
    ) async throws -> PersonalityInsights {
      - private func extractExistingInsights(from responses: [ResponseSnapshot]) async throws -> PersonalityInsights? {
      - private func extractText(from response: ResponseValue) -> String {
      - private func updateGoalTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
      - private func updateLifestyleTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
      - private func updatePersonalityTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
      - private func updatePreferenceTraits(insights: PersonalityInsights, response: String, node: ConversationNode) -> PersonalityInsights {
      - private func updateFromChoiceTraits(insights: PersonalityInsights, choiceId: String, node: ConversationNode) -> PersonalityInsights {
      - private func calculateConfidenceScores(insights: PersonalityInsights, responseCount: Int) -> [PersonalityDimension: Double] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/ViewModels/ConversationViewModel.swift

---
Classes:
  Class: ConversationViewModel
    Properties:
      - var currentNode: ConversationNode?
      - var isLoading = false
      - var error: Error?
      - var completionPercentage: Double = 0
      - var showSkipOption = false
      - private let flowManager: ConversationFlowManager
      - private let persistence: ConversationPersistence
      - private let analytics: ConversationAnalytics
      - private let userId: UUID
      - var onCompletion: ((PersonalityInsights) -> Void)?
      - private var hasStarted = false
      - var currentNodeType: ConversationNode.NodeType? {
      - var currentQuestion: String {
      - var currentClarifications: [String] {
      - var currentInputType: InputType? {
      - var progressText: String {
    Methods:
      - func start() async {
      - func submitResponse(_ response: ResponseValue) async {
      - func skipCurrentQuestion() async {
      - func clearError() {
      - private func setupObservers() {
      - private func updateFromFlowManager() {
      - private func updateProgress() {
      - private func handleCompletion() async {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/ViewModels/OnboardingViewModel.swift

---
Classes:
  Class: OnboardingViewModel
  Class: OnboardingMode
    Properties:
      - private(set) var currentScreen: OnboardingScreen = .openingScreen
      - private(set) var isLoading = false
      - var error: Error?
      - private(set) var mode: OnboardingMode = .conversational
      - private(set) var orchestratorState: OnboardingState = .notStarted
      - private(set) var orchestratorProgress: OnboardingProgress = .init()
      - private var orchestrator: OnboardingOrchestrator?
      - var lifeContext = LifeContext()
      - var goal = Goal()
      - var selectedPersonaMode: PersonaMode = .supportiveCoach  // Phase 4: Discrete persona selection
      - var engagementPreferences = EngagementPreferences()
      - var sleepWindow = SleepWindow()
      - var motivationalStyle = MotivationalStyle()
      - var timezone: String = TimeZone.current.identifier
      - var baselineModeEnabled = true
      - private(set) var isTranscribing = false
      - var hasHealthKitIntegration: Bool {
      - private(set) var healthKitAuthorizationStatus: HealthKitAuthorizationStatus = .notDetermined
      - private let aiService: AIServiceProtocol
      - private let onboardingService: OnboardingServiceProtocol
      - private let modelContext: ModelContext
      - private let speechService: WhisperServiceWrapperProtocol?
      - private let healthPrefillProvider: HealthKitPrefillProviding?
      - private let healthKitAuthManager: HealthKitAuthManager
      - private let apiKeyManager: APIKeyManagementProtocol
      - private let userService: UserServiceProtocol
      - private let analytics: ConversationAnalytics
      - var onCompletionCallback: (() -> Void)?
      - var personaPreviewText: String {
      - var hasSelectedPersona: Bool {
    Methods:
      - private func setupOrchestrator() {
      - private func handleOrchestratorStateChange(_ state: OnboardingState) {
      - func navigateToNextScreen() {
      - func navigateToPreviousScreen() {
      - func startConversationalOnboarding(userId: UUID) async throws {
      - func pauseConversation() {
      - func resumeConversation() async throws {
      - func completeConversationalOnboarding() async throws {
      - func adjustPersona(_ adjustments: PersonaAdjustments) async throws {
      - func switchToLegacyMode() {
      - func switchToConversationalMode() {
      - func startVoiceCapture() {
      - func stopVoiceCapture() {
      - func requestHealthKitAuthorization() async {
      - func analyzeGoalText() async {
      - func completeOnboarding() async throws {
      - func validatePersonaSelection() {
      - func validateBlend() {
      - private func prefillFromHealthKit() async {
      - private func buildUserProfile() -> UserProfileJsonBlob {
      - private static func formatTime(_ date: Date) -> String {

Enums:
  - OnboardingMode
    Cases:
      - legacy
      - conversational
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/InputModalities/ChoiceCardsView.swift

---
Classes:
  Class: ChoiceCardsView
    Properties:
      - let options: [ChoiceOption]
      - let multiSelect: Bool
      - var minSelections: Int = 1
      - var maxSelections: Int = Int.max
      - let onSubmit: ([String]) -> Void
      - @State private var selectedIds = Set<String>()
      - @State private var showError = false
      - private var isValid: Bool {
      - var body: some View {
    Methods:
      - private func toggleSelection(_ optionId: String) {
      - private func submitChoices() {
  Class: ChoiceCard
    Properties:
      - let option: ChoiceOption
      - let isSelected: Bool
      - let action: () -> Void
      - @State private var isPressed = false
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/InputModalities/ContextualSlider.swift

---
Classes:
  Class: ContextualSlider
    Properties:
      - let min: Double
      - let max: Double
      - let step: Double
      - let labels: SliderLabels
      - let onSubmit: (Double) -> Void
      - @State private var value: Double
      - @State private var isDragging = false
      - private var normalizedValue: Double {
      - private var formattedValue: String {
      - private var contextualLabel: String {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/InputModalities/TextInputView.swift

---
Classes:
  Class: TextInputView
    Properties:
      - let minLength: Int
      - let maxLength: Int
      - let placeholder: String
      - let onSubmit: (String) -> Void
      - @State private var text = ""
      - @State private var showError = false
      - @FocusState private var isFocused: Bool
      - private var isValid: Bool {
      - private var characterCount: Int {
      - private var remainingCharacters: Int {
      - var body: some View {
    Methods:
      - private func submitResponse() {
  Class: SmartSuggestions
    Properties:
      - let context: String
      - let onSelect: (String) -> Void
      - private var suggestions: [String] {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/InputModalities/VoiceInputView.swift

---
Classes:
  Class: VoiceInputView
    Properties:
      - let maxDuration: TimeInterval
      - let onSubmit: (String, Data) -> Void
      - @StateObject private var voiceRecorder = VoiceRecorder()
      - @State private var isRecording = false
      - @State private var recordingDuration: TimeInterval = 0
      - @State private var transcription = ""
      - @State private var showTranscription = false
      - @State private var timer: Timer?
      - private var formattedDuration: String {
      - var body: some View {
    Methods:
      - private func toggleRecording() {
      - private func startRecording() {
      - private func stopRecording() {
      - private func submitRecording() {
  Class: VoiceRecorder
    Properties:
      - @Published var audioLevel: Float = 0
      - @Published var isRecording = false
      - private var audioRecorder: AVAudioRecorder?
      - private var levelTimer: Timer?
      - private var recordingURL: URL?
      - var lastRecordingData: Data?
    Methods:
      - func startRecording() {
      - func stopRecording() async -> Data? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/InputModalities/VoiceVisualizer.swift

---
Classes:
  Class: VoiceVisualizer
    Properties:
      - let isRecording: Bool
      - let audioLevel: Float
      - @State private var phase: CGFloat = 0
      - private let barCount = 20
      - private let baseHeight: CGFloat = 20
      - private let maxAmplitude: CGFloat = 40
      - var body: some View {
  Class: VoiceBar
    Properties:
      - let index: Int
      - let totalBars: Int
      - let audioLevel: Float
      - let phase: CGFloat
      - let isRecording: Bool
      - let baseHeight: CGFloat
      - let maxAmplitude: CGFloat
      - private var height: CGFloat {
      - private var color: Color {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/CoachingStyleView.swift

---
Classes:
  Class: CoachingStyleView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - var body: some View {
  Class: PersonaOptionCard
    Properties:
      - let persona: PersonaMode
      - let isSelected: Bool
      - let onTap: () -> Void
      - var body: some View {
  Class: PersonaStylePreviewCard
    Properties:
      - let selectedPersona: PersonaMode
      - var body: some View {
  Class: NavigationButtons
    Properties:
      - var backAction: () -> Void
      - var nextAction: () -> Void
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/CoachProfileReadyView.swift

---
Classes:
  Class: CoachProfileReadyView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - var body: some View {
      - private var aspirationText: String {
      - private var styleText: String {
      - private var engagementText: String {
      - private var boundariesText: String {
      - private var celebrationText: String {
    Methods:
      - private func summaryRow(title: String, text: String) -> some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/ConversationalInputView.swift

---
Classes:
  Class: ConversationalInputView
    Properties:
      - let inputType: InputType
      - let onSubmit: (ResponseValue) -> Void
      - @State private var animateIn = false
      - @Environment(\.colorScheme) private var colorScheme
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/ConversationProgress.swift

---
Classes:
  Class: ConversationProgress
    Properties:
      - let completionPercentage: Double
      - let currentNodeType: ConversationNode.NodeType?
      - @State private var animatedProgress: Double = 0
      - private let nodeTypes: [ConversationNode.NodeType] = [
 .opening, .goals, .lifestyle, .personality, .preferences, .confirmation
      - private let nodeIcons: [ConversationNode.NodeType: String] = [
 .opening: "hand.wave", .goals: "target", .lifestyle: "figure.walk", .personality: "person.fill", .preferences: "slider.horizontal.3", .confirmation: "checkmark.circle"
      - var body: some View {
    Methods:
      - private func isNodeCompleted(_ nodeType: ConversationNode.NodeType) -> Bool {
  Class: NodeIndicator
    Properties:
      - let nodeType: ConversationNode.NodeType
      - let icon: String
      - let isActive: Bool
      - let isCompleted: Bool
      - private var scale: CGFloat {
      - private var color: Color {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/ConversationView.swift

---
Classes:
  Class: ConversationView
    Properties:
      - @State var viewModel: ConversationViewModel
      - @State private var animateContent = false
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: ConversationLoadingOverlay
    Properties:
      - @State private var rotation: Double = 0
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/CoreAspirationView.swift

---
Classes:
  Class: CoreAspirationView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - private let columns = [GridItem(.flexible())]
      - var body: some View {
    Methods:
      - private func handleNext() {
      - private func goalCard(family: Goal.GoalFamily) -> some View {
  Class: NavigationButtons
    Properties:
      - var backAction: () -> Void
      - var nextAction: () -> Void
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/EngagementPreferencesView.swift

---
Classes:
  Class: EngagementPreferencesView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - var body: some View {
      - @ViewBuilder private var customOptions: some View {
    Methods:
      - private func presetCard(
        title: LocalizedStringKey,
        style: EngagementPreferences.TrackingStyle,
        id: String
    ) -> some View {
      - private func radioOption(title: String, isSelected: Bool, action: @escaping () -> Void, id: String) -> some View {
      - private func handleNext() {
      - private func selectPreset(_ preset: EngagementPreferences.TrackingStyle) {
  Class: NavigationButtons
    Properties:
      - var backAction: () -> Void
      - var nextAction: () -> Void
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/FinalOnboardingFlow.swift

---
Classes:
  Class: FinalOnboardingFlow
    Properties:
      - @State private var coordinator: OnboardingFlowCoordinator
      - @Environment(\.modelContext) private var modelContext
      - @State private var showingExitConfirmation = false
      - var body: some View {
      - private var contentView: some View {
      - private var backgroundGradient: some View {
  Class: WelcomeView
    Properties:
      - @Bindable var coordinator: OnboardingFlowCoordinator
      - @State private var animationPhase = 0
      - var body: some View {
  Class: ConversationFlowView
    Properties:
      - @Bindable var coordinator: OnboardingFlowCoordinator
      - var body: some View {
  Class: OnboardingCompletionView
    Properties:
      - @Bindable var coordinator: OnboardingFlowCoordinator
      - @State private var showingContent = false
      - var body: some View {
  Class: ProgressBar
    Properties:
      - let progress: Double
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/GeneratingCoachView.swift

---
Classes:
  Class: GeneratingCoachView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - @State private var currentStep = 0
      - private let steps: [LocalizedStringKey] = [
 "onboarding.generating.step1", "onboarding.generating.step2", "onboarding.generating.step3", "onboarding.generating.step4", "onboarding.generating.step5"
      - var body: some View {
    Methods:
      - private func startGeneration() {
  Class: CircularProgress
    Properties:
      - let progress: Double
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/HealthKitAuthorizationView.swift

---
Classes:
  Class: HealthKitAuthorizationView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/LifeSnapshotView.swift

---
Classes:
  Class: LifeSnapshotView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - private let columns = [GridItem(.flexible()), GridItem(.flexible())]
      - var body: some View {
    Methods:
      - private func checkbox(text: LocalizedStringKey, binding: Binding<Bool>, id: String) -> some View {
      - private func workoutOption(_ option: LifeContext.WorkoutWindow) -> some View {
      - private func workoutOptionIcon(for option: LifeContext.WorkoutWindow) -> String {
  Class: CheckboxToggleStyle
    Methods:
      - func makeBody(configuration: Configuration) -> some View {
  Class: NavigationButtons
    Properties:
      - var backAction: () -> Void
      - var nextAction: () -> Void
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/MotivationalAccentsView.swift

---
Classes:
  Class: MotivationalAccentsView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - var body: some View {
    Methods:
      - private func radioOption(
        title: String,
        description: String,
        isSelected: Bool,
        action: @escaping () -> Void,
        id: String
    ) -> some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/OnboardingContainerView.swift

---
Classes:
  Class: OnboardingContainerView
    Properties:
      - @StateObject private var coordinator: OnboardingFlowCoordinator
      - @State private var showingError = false
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: WelcomeView
    Properties:
      - let coordinator: OnboardingFlowCoordinator
      - var body: some View {
  Class: ConversationFlowView
    Properties:
      - let coordinator: OnboardingFlowCoordinator
      - var body: some View {
  Class: GeneratingPersonaView
    Properties:
      - let coordinator: OnboardingFlowCoordinator
      - @State private var dots = 0
      - var body: some View {
    Methods:
      - private func animateDots() {
  Class: ProgressMessage
    Properties:
      - let text: String
      - let isComplete: Bool
      - var body: some View {
  Class: CompletionView
    Properties:
      - let coordinator: OnboardingFlowCoordinator
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: LoadingOverlay
    Properties:
      - var body: some View {
  Class: OnboardingProgressBar
    Properties:
      - let progress: Double
      - var body: some View {
  Class: PreviewUserService
    Methods:
      - func getCurrentUser() async -> User? {
      - func updateUser(_ user: User) async throws {
      - func createUser(name: String, email: String?) async throws -> User {
  Class: PreviewAPIKeyManager
    Methods:
      - func getAPIKey(for provider: AIProvider) async throws -> String {
      - func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func deleteAPIKey(for provider: AIProvider) async throws {
      - func hasAPIKey(for provider: AIProvider) async -> Bool {
      - func getAllConfiguredProviders() async -> [AIProvider] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/OnboardingErrorBoundary.swift

---
Classes:
  Class: OnboardingErrorBoundary
    Properties:
      - @ViewBuilder let content: () -> Content
      - @Bindable var coordinator: OnboardingFlowCoordinator
      - @State private var showingFullError = false
      - var body: some View {
  Class: RecoveryOverlay
    Properties:
      - let message: String?
      - @State private var rotation: Double = 0
      - var body: some View {
  Class: ErrorOverlay
    Properties:
      - let error: Error
      - let isRecovering: Bool
      - let onRetry: () -> Void
      - let onDismiss: () -> Void
      - let onShowDetails: () -> Void
      - @State private var showingAnimation = false
      - var body: some View {
      - private var errorIcon: Image {
      - private var errorColor: Color {
      - private var errorTitle: String {
      - private var recoverySuggestion: String? {
  Class: ErrorDetailsView
    Properties:
      - let error: Error?
      - let onDismiss: () -> Void
      - var body: some View {
  Class: ErrorDetailRow
    Properties:
      - let title: String
      - let value: String
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/OnboardingFlowView.swift

---
Classes:
  Class: OnboardingFlowView
    Properties:
      - private var modelContext
      - @State private var viewModel: OnboardingViewModel
      - let onCompletion: (() -> Void)?
      - var body: some View {
      - private var shouldShowProgressBar: Bool {
      - private var shouldShowPrivacyFooter: Bool {
  Class: StepProgressBar
    Properties:
      - let progress: Double
      - private let segments = 7
      - var body: some View {
    Methods:
      - private func segmentColor(for index: Int) -> Color {
  Class: PrivacyFooter
    Properties:
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/OnboardingNavigationButtons.swift

---
Classes:
  Class: OnboardingNavigationButtons
    Properties:
      - let backAction: () -> Void
      - let nextAction: () -> Void
      - let isNextEnabled: Bool
      - let nextTitle: String
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/OnboardingStateView.swift

---
Classes:
  Class: OnboardingStateView
    Properties:
      - let state: OnboardingState
      - let progress: OnboardingProgress
      - let onAction: (OnboardingAction) -> Void
      - var body: some View {
      - private var backgroundView: some View {
      - private var backgroundColors: [Color] {
      - private var shouldShowProgress: Bool {
      - private var stateContent: some View {
  Class: OnboardingAction
  Class: OnboardingProgressBar
    Properties:
      - let progress: OnboardingProgress
      - private var displayProgress: Double {
      - private var progressText: String {
      - var body: some View {
  Class: ConversationInProgressView
    Properties:
      - let progress: OnboardingProgress
      - let onPause: () -> Void
      - var body: some View {
  Class: SynthesizingView
    Properties:
      - let progress: OnboardingProgress
      - @State private var rotation: Double = 0
      - var body: some View {
  Class: ReviewingPersonaView
    Properties:
      - let persona: PersonaProfile
      - let onAccept: () -> Void
      - let onAdjust: (PersonaAdjustments) -> Void
      - @State private var showAdjustments = false
      - var body: some View {
  Class: PersonaCard
    Properties:
      - let persona: PersonaProfile
      - var body: some View {
  Class: TraitBadge
    Properties:
      - let trait: String
      - var body: some View {
  Class: MessageBubble
    Properties:
      - let text: String
      - let isFromCoach: Bool
      - var body: some View {
  Class: PersonaAdjustmentSheet
    Properties:
      - let currentPersona: PersonaProfile
      - let onSave: (PersonaAdjustments) -> Void
      - @State private var selectedType: PersonaAdjustments.AdjustmentType = .tone
      - @State private var adjustmentValue: Double = 0
      - @State private var feedback: String = ""
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
      - private var adjustmentDescription: String {
      - private var sliderMinLabel: String {
      - private var sliderMaxLabel: String {
  Class: AdjustingPersonaView
    Properties:
      - let persona: PersonaProfile
      - var body: some View {
  Class: SavingView
    Properties:
      - @State private var checkmarkScale: CGFloat = 0
      - var body: some View {
  Class: CompletedView
    Properties:
      - let onContinue: () -> Void
      - var body: some View {
  Class: PausedStateView
    Properties:
      - let onResume: () -> Void
      - let onRestart: () -> Void
      - var body: some View {
  Class: CancelledStateView
    Properties:
      - let onRestart: () -> Void
      - let onExit: () -> Void
      - var body: some View {
  Class: ErrorStateView
    Properties:
      - let error: OnboardingOrchestratorError
      - let onRetry: () -> Void
      - let onExit: () -> Void
      - var body: some View {

Enums:
  - OnboardingAction
    Cases:
      - pause
      - resume
      - accept
      - adjust
      - `continue`
      - restart
      - retry
      - exit
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/OpeningScreenView.swift

---
Classes:
  Class: OpeningScreenView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - @State private var animateIn = false
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/OptimizedGeneratingPersonaView.swift

---
Classes:
  Class: OptimizedGeneratingPersonaView
    Properties:
      - let coordinator: OnboardingFlowCoordinator
      - @State private var currentStep = 0
      - @State private var stepProgress: [Double] = [0, 0, 0, 0]
      - @State private var estimatedTimeRemaining = 5.0
      - @State private var startTime = Date()
      - private let steps = [
 (icon: "brain", title: "Analyzing responses", duration: 0.5), (icon: "sparkles", title: "Extracting personality", duration: 1.0), (icon: "person.fill.badge.plus", title: "Creating unique identity", duration: 2.0), (icon: "text.bubble", title: "Crafting communication style", duration: 1.5)
      - var body: some View {
    Methods:
      - private func startProgress() {
      - private func animateStepProgress(index: Int, duration: Double) async {
  Class: StepProgressRow
    Properties:
      - let icon: String
      - let title: String
      - let progress: Double
      - let isActive: Bool
      - let isComplete: Bool
      - var body: some View {
  Class: PreviewUserService
    Methods:
      - func createUser(from profile: OnboardingProfile) async throws -> User {
      - func updateProfile(_ updates: ProfileUpdate) async throws {
      - func getCurrentUser() async -> User? {
      - func getCurrentUserId() async -> UUID? {
      - func deleteUser(_ user: User) async throws {
      - func completeOnboarding() async throws {
      - func setCoachPersona(_ persona: CoachPersona) async throws {
  Class: PreviewAPIKeyManager
    Methods:
      - func getAPIKey(for provider: AIProvider) async throws -> String {
      - func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func deleteAPIKey(for provider: AIProvider) async throws {
      - func hasAPIKey(for provider: AIProvider) async -> Bool {
      - func getAllConfiguredProviders() async -> [AIProvider] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/PersonaPreviewCard.swift

---
Classes:
  Class: PersonaPreviewCard
    Properties:
      - let preview: PersonaPreview
      - @State private var showContent = false
      - var body: some View {
  Class: PreviewTraitChip
    Properties:
      - let trait: String
      - var body: some View {
  Class: PersonaVisualization
    Properties:
      - @State private var rotation: Double = 0
      - @State private var scale: CGFloat = 1
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/PersonaPreviewView.swift

---
Classes:
  Class: PersonaPreviewView
    Properties:
      - let persona: PersonaProfile
      - let coordinator: OnboardingFlowCoordinator
      - @State private var showingAdjustmentSheet = false
      - @State private var adjustmentText = ""
      - @State private var selectedSampleIndex = 0
      - private let sampleMessages = [
 "Good morning! Ready to crush your fitness goals today? 🔥", "Great job on that workout! You're getting stronger every day.", "Remember, progress isn't always linear. Every step forward counts!", "Let's adjust your plan based on how you're feeling today.", "You've been consistent this week - that's what builds real results!"
      - var body: some View {
      - private var coachCard: some View {
      - private var sampleMessagesSection: some View {
      - private var actionButtons: some View {
    Methods:
      - private func generateSampleMessages() -> [String] {
      - private func personalizedMessage(_ base: String) -> String {
  Class: PreviewPersonaAdjustmentSheet
    Properties:
      - @Binding var adjustmentText: String
      - let onSubmit: () -> Void
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: TraitChip
    Properties:
      - let text: String
      - var body: some View {
  Class: StyleIndicator
    Properties:
      - let label: String
      - let value: String
      - let icon: String
      - var body: some View {
  Class: PreviewMessageBubble
    Properties:
      - let message: String
      - let isFromCoach: Bool
      - var body: some View {
  Class: FlowLayout
    Properties:
      - let spacing: CGFloat
    Methods:
      - func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
      - func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
      - private func arrangement(proposal: ProposedViewSize, subviews: Subviews) -> (maxX: CGFloat, maxY: CGFloat, positions: [Int: CGPoint], sizes: [CGSize]) {
  Class: PreviewUserService
    Methods:
      - func getCurrentUser() -> User? {
      - func getCurrentUserId() async -> UUID? {
      - func createUser(from profile: OnboardingProfile) async throws -> User {
      - func updateProfile(_ updates: ProfileUpdate) async throws {
      - func completeOnboarding() async throws {
      - func setCoachPersona(_ persona: CoachPersona) async throws {
      - func deleteUser(_ user: User) async throws {
  Class: PreviewAPIKeyManager
    Methods:
      - func getAPIKey(for provider: AIProvider) async throws -> String {
      - func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func deleteAPIKey(for provider: AIProvider) async throws {
      - func hasAPIKey(for provider: AIProvider) async -> Bool {
      - func getAllConfiguredProviders() async -> [AIProvider] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/PersonaSelectionView.swift

---
Classes:
  Class: PersonaSelectionView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - var body: some View {
  Class: PersonaOptionCard
    Properties:
      - let persona: PersonaMode
      - let isSelected: Bool
      - let onTap: () -> Void
      - var body: some View {
  Class: NavigationButtons
    Properties:
      - var backAction: () -> Void
      - var nextAction: () -> Void
      - var body: some View {
  Class: PreviewAPIKeyManager
    Methods:
      - func getAPIKey(for provider: AIProvider) async throws -> String {
      - func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func deleteAPIKey(for provider: AIProvider) async throws {
      - func hasAPIKey(for provider: AIProvider) async -> Bool {
      - func getAllConfiguredProviders() async -> [AIProvider] {
  Class: PreviewUserService
    Methods:
      - func getCurrentUser() -> User? {
      - func createUser(from profile: OnboardingProfile) async throws -> User {
      - func updateProfile(_ updates: ProfileUpdate) async throws {
      - func getCurrentUserId() async -> UUID? {
      - func completeOnboarding() async throws {
      - func setCoachPersona(_ persona: CoachPersona) async throws {
      - func deleteUser(_ user: User) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/PersonaSynthesisView.swift

---
Classes:
  Class: PersonaSynthesisView
    Properties:
      - @StateObject private var previewGenerator: PreviewGenerator
      - @State private var animateElements = false
      - @State private var pulseAnimation = false
      - let insights: PersonalityInsights
      - let conversationData: ConversationData
      - let onCompletion: (PersonaProfile) -> Void
      - var body: some View {
    Methods:
      - private func startSynthesis() {
      - private func retry() {
  Class: SynthesisProgressView
    Properties:
      - let stage: SynthesisStage
      - let progress: Double
      - private let stages: [(SynthesisStage, String, String)] = [
 (.analyzingPersonality, "brain.head.profile", "Analyze"), (.creatingIdentity, "person.fill.badge.plus", "Create"), (.buildingPersonality, "sparkles", "Build"), (.finalizing, "checkmark.seal", "Finalize")
      - var body: some View {
    Methods:
      - private func isStageActive(_ checkStage: SynthesisStage) -> Bool {
      - private func isStageCompleted(_ checkStage: SynthesisStage) -> Bool {
      - private func connectorProgress(for index: Int) -> Double {
  Class: StageIndicator
    Properties:
      - let icon: String
      - let label: String
      - let isActive: Bool
      - let isCompleted: Bool
      - private var iconColor: Color {
      - private var backgroundColor: Color {
      - var body: some View {
  Class: ProgressConnector
    Properties:
      - let progress: Double
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/SleepAndBoundariesView.swift

---
Classes:
  Class: SleepAndBoundariesView
    Properties:
      - @Bindable var viewModel: OnboardingViewModel
      - @State private var bedMinutes: Double
      - @State private var wakeMinutes: Double
      - var body: some View {
    Methods:
      - private func timeSlider(title: LocalizedStringKey, minutes: Binding<Double>, id: String) -> some View {
      - private func radioOption(title: String, isSelected: Bool, action: @escaping () -> Void, id: String) -> some View {
      - private func displayTime(_ minutes: Double) -> String {
      - private static func minutes(from hhmm: String) -> Double {
      - private static func hhmm(from minutes: Double) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Views/UnifiedOnboardingView.swift

---
Classes:
  Class: UnifiedOnboardingView
    Properties:
      - @State private var viewModel: OnboardingViewModel?
      - @Environment(\.modelContext) private var modelContext
      - @Environment(\.dismiss) private var dismiss
      - let apiKeyManager: APIKeyManagementProtocol
      - let userService: UserServiceProtocol
      - let aiService: AIServiceProtocol
      - let onboardingService: OnboardingServiceProtocol
      - let onCompletion: () -> Void
      - var body: some View {
      - private var conversationalFlowView: some View {
      - private var legacyFlowView: some View {
      - private var modeSwitcher: some View {
  Class: ConversationalWelcomeView
    Properties:
      - let onStart: () -> Void
      - var body: some View {
  Class: PersonaReviewView
    Properties:
      - let persona: PersonaProfile
      - let onAccept: () -> Void
      - let onAdjust: (PersonaAdjustments) -> Void
      - var body: some View {
  Class: CharacteristicRow
    Properties:
      - let label: String
      - let value: String
      - var body: some View {
  Class: SavingProgressView
    Properties:
      - @State private var progress: Double = 0
      - var body: some View {
  Class: CompletionView
    Properties:
      - let onDismiss: () -> Void
      - @State private var showContent = false
      - var body: some View {
  Class: PausedView
    Properties:
      - let onResume: () -> Void
      - let onRestart: () -> Void
      - var body: some View {
  Class: CancelledView
    Properties:
      - let onRestart: () -> Void
      - let onSwitchToLegacy: () -> Void
      - var body: some View {
  Class: ErrorView
    Properties:
      - let error: OnboardingOrchestratorError
      - let onRetry: () -> Void
      - let onSwitchToLegacy: () -> Void
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Coordinators/SettingsCoordinator.swift

---
Classes:
  Class: SettingsCoordinator
    Properties:
      - var navigationPath = NavigationPath()
      - var activeSheet: SettingsSheet?
      - var activeAlert: SettingsAlert?
  Class: SettingsSheet
  Class: SettingsAlert
    Methods:
      - func navigateTo(_ destination: SettingsDestination) {
      - func navigateBack() {
      - func navigateToRoot() {
      - func showSheet(_ sheet: SettingsSheet) {
      - func showAlert(_ alert: SettingsAlert) {
      - func dismiss() {

Enums:
  - SettingsSheet
    Cases:
      - personaRefinement
      - apiKeyEntry
      - dataExport
      - deleteAccount
  - SettingsAlert
    Cases:
      - confirmDelete
      - exportSuccess
      - apiKeyInvalid
      - error
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Models/AIProvider+Settings.swift

---
Classes:
  Class: AIProvider+Settings
    Properties:
      - var id: String {
      - var icon: String {
      - var keyInstructions: [String] {
      - var apiKeyURL: URL? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Models/PersonaSettingsModels.swift

---
Classes:
  Class: PersonalityTrait
    Properties:
      - let id = UUID()
      - let name: String
      - let description: String
      - let icon: String
      - let dimension: PersonalityDimension
      - let value: Double
      - var dominantTraits: [PersonalityTrait] {
      - var initials: String {
      - var gradientColors: [Color] {
      - var uniquenessScore: Double {
      - var tone: CommunicationTone {
      - var energyLevel: EnergyLevel {
      - var detailLevel: DetailLevel {
      - var humorStyle: HumorStyle {
    Methods:
      - func calculateDifference(from other: CoachPersona) -> Double {
  Class: EnergyLevel
  Class: HumorStyle
  Class: SimplifiedCommunicationStyle
    Properties:
      - let tone: CommunicationTone
      - let energyLevel: EnergyLevel
      - let detailLevel: DetailLevel
      - let humorStyle: HumorStyle
      - var communicationStyle: SimplifiedCommunicationStyle {
      - var coachingPhilosophy: CoachingPhilosophyDisplay {
  Class: CoachingPhilosophyDisplay
    Properties:
      - let core: String
      - let principles: [String]

Enums:
  - EnergyLevel
    Cases:
      - high
      - medium
      - low
  - HumorStyle
    Cases:
      - playful
      - light
      - occasional
      - minimal
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Models/SettingsModels.swift

---
Classes:
  Class: MeasurementSystem
  Class: AppearanceMode
  Class: QuietHours
    Properties:
      - var enabled: Bool = false
      - var startTime: Date
      - var endTime: Date
  Class: DataExport
    Properties:
      - let id = UUID()
      - let date: Date
      - let size: Int64
      - let format: ExportFormat
  Class: ExportFormat
  Class: PersonaEvolutionTracker
    Properties:
      - var adaptationLevel: Int = 0
      - var lastUpdateDate: Date = Date()
      - var recentAdaptations: [PersonaAdaptation] = []
  Class: PersonaAdaptation
    Properties:
      - let id = UUID()
      - let date: Date
      - let type: AdaptationType
      - let description: String
      - let icon: String
  Class: AdaptationType
  Class: PreviewScenario
    Methods:
      - static func randomScenario() -> PreviewScenario {
  Class: PersonaPreviewRequest
    Properties:
      - let persona: CoachPersona
      - let scenario: PreviewScenario
      - let userContext: String?
  Class: SettingsError
  Class: SettingsDestination

Enums:
  - MeasurementSystem
    Cases:
      - imperial
      - metric
  - AppearanceMode
    Cases:
      - light
      - dark
      - system
  - ExportFormat
    Cases:
      - json
      - csv
  - AdaptationType
    Cases:
      - naturalLanguage
      - behaviorLearning
      - feedbackBased
  - PreviewScenario
    Cases:
      - morningGreeting
      - workoutMotivation
      - nutritionGuidance
      - recoveryCheck
      - goalSetting
  - SettingsError
    Cases:
      - missingAPIKey
      - invalidAPIKey
      - apiKeyTestFailed
      - biometricsNotAvailable
      - exportFailed
      - personaNotConfigured
      - personaAdjustmentFailed
  - SettingsDestination
    Cases:
      - aiPersona
      - apiConfiguration
      - notifications
      - privacy
      - appearance
      - units
      - dataManagement
      - about
      - debug
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Models/User+Settings.swift

---
Classes:
  Class: User+Settings
    Properties:
      - var appearanceMode: AppearanceMode? {
      - var hapticFeedbackEnabled: Bool {
      - var analyticsEnabled: Bool {
      - var selectedAIProvider: AIProvider? {
      - var selectedAIModel: String? {
      - var biometricLockEnabled: Bool {
      - var coachPersonaData: Data? {
      - var notificationPreferences: NotificationPreferences? {
      - var quietHours: QuietHours? {
      - var dataExports: [DataExport] {
      - var currentContext: String {
      - var preferredUnitsEnum: MeasurementSystem {
    Methods:
      - private func userDefaultsKey(_ key: String) -> String {
      - func updatePreferredUnits(_ system: MeasurementSystem) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Services/BiometricAuthManager.swift

---
Classes:
  Class: BiometricAuthManager
    Properties:
      - private let context = LAContext()
      - var canUseBiometrics: Bool {
      - var biometricType: BiometricType {
    Methods:
      - func authenticate(reason: String) async throws -> Bool {
      - func reset() {
  Class: BiometricType
  Class: BiometricError
    Methods:
      - static func fromLAError(_ error: LAError) -> BiometricError {

Enums:
  - BiometricType
    Cases:
      - faceID
      - touchID
      - opticID
      - none
  - BiometricError
    Cases:
      - notAvailable
      - authenticationFailed
      - userCancelled
      - userFallback
      - systemCancel
      - passcodeNotSet
      - biometryNotAvailable
      - biometryNotEnrolled
      - biometryLockout
      - other
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Services/NotificationManager+Settings.swift

---
Classes:
  Class: NotificationManager+Settings
    Methods:
      - func getAuthorizationStatus() async -> UNAuthorizationStatus {
      - func updatePreferences(_ preferences: NotificationPreferences) async {
      - func rescheduleWithQuietHours(_ quietHours: QuietHours) async {
      - private func rescheduleNotifications(preferences: NotificationPreferences) async {
      - private func scheduleWorkoutReminders() async {
      - private func scheduleMealReminders() async {
      - private func scheduleDailyCheckins() async {
      - private func adjustTriggerForQuietHours(_ trigger: UNCalendarNotificationTrigger, quietHours: QuietHours) -> UNCalendarNotificationTrigger? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Services/UserDataExporter.swift

---
Classes:
  Class: UserDataExporter
    Properties:
      - private let modelContext: ModelContext
    Methods:
      - func exportAllData(for user: User) async throws -> URL {
      - func exportAsCSV(for user: User, dataType: ExportDataType) async throws -> URL {
      - private func gatherUserData(for user: User) async throws -> UserDataExport {
      - private func fetchWorkouts(for user: User) async throws -> [Workout] {
      - private func fetchFoodEntries(for user: User) async throws -> [FoodEntry] {
      - private func fetchDailyLogs(for user: User) async throws -> [DailyLog] {
      - private func fetchChatSessions(for user: User) async throws -> [ChatSession] {
      - private func generateCSV(for user: User, dataType: ExportDataType) async throws -> String {
      - private func generateWorkoutsCSV(for user: User) async throws -> String {
      - private func generateNutritionCSV(for user: User) async throws -> String {
      - private func generateProgressCSV(for user: User) async throws -> String {
      - private func formatDuration(_ seconds: TimeInterval) -> String {
  Class: ExportDataType
  Class: UserDataExport
    Properties:
      - let exportDate: Date
      - let appVersion: String
      - let user: UserExportData
      - let workouts: [WorkoutExportData]
      - let nutrition: [FoodEntryExportData]
      - let dailyLogs: [DailyLogExportData]
      - let chatHistory: [ChatSessionExportData]
      - let settings: UserSettingsExport
  Class: UserExportData
    Properties:
      - let id: UUID
      - let name: String
      - let email: String?
      - let createdAt: Date
      - let lastActiveAt: Date?
  Class: WorkoutExportData
    Properties:
      - let id: UUID
      - let type: String
      - let startTime: Date
      - let duration: TimeInterval
      - let totalCalories: Int?
      - let exercises: [ExerciseExportData]
      - let notes: String?
  Class: ExerciseExportData
    Properties:
      - let name: String
      - let sets: Int
      - let reps: [Int]
      - let weight: [Double]
  Class: FoodEntryExportData
    Properties:
      - let id: UUID
      - let name: String
      - let consumedAt: Date
      - let calories: Double?
      - let protein: Double?
      - let carbs: Double?
      - let fat: Double?
      - let notes: String?
  Class: DailyLogExportData
    Properties:
      - let date: Date
      - let weight: Double?
      - let bodyFatPercentage: Double?
      - let sleepHours: Double?
      - let steps: Int?
      - let mood: String?
      - let energyLevel: Int?
      - let notes: String?
  Class: ChatSessionExportData
    Properties:
      - let id: UUID
      - let createdAt: Date
      - let messageCount: Int
      - let title: String?
  Class: UserSettingsExport
    Properties:
      - let preferredUnits: String
      - let notificationsEnabled: Bool
      - let selectedAIProvider: String?
      - static let fileNameFormatter: DateFormatter = {
      - static let shortFormatter: DateFormatter = {
      - static let timeFormatter: DateFormatter = {
      - static let formatted: JSONEncoder = {

Enums:
  - ExportDataType
    Cases:
      - workouts
      - nutrition
      - progress
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/ViewModels/SettingsViewModel.swift

---
Classes:
  Class: SettingsViewModel
    Properties:
      - private let modelContext: ModelContext
      - private let user: User
      - private let apiKeyManager: APIKeyManagerProtocol
      - private let aiService: AIServiceProtocol
      - private let notificationManager: NotificationManager
      - private let coordinator: SettingsCoordinator
      - private(set) var isLoading = false
      - private(set) var error: Error?
      - var preferredUnits: MeasurementSystem
      - var appearanceMode: AppearanceMode
      - var hapticFeedback: Bool
      - var analyticsEnabled: Bool
      - var selectedProvider: AIProvider
      - var selectedModel: String
      - var availableProviders: [AIProvider] = []
      - var installedAPIKeys: Set<AIProvider> = []
      - var coachPersona: CoachPersona?
      - var personaEvolution: PersonaEvolutionTracker
      - var personaUniquenessScore: Double = 0.0
      - var notificationPreferences: NotificationPreferences
      - var quietHours: QuietHours
      - var biometricLockEnabled: Bool
      - var exportHistory: [DataExport] = []
      - static let unitsChanged = Notification.Name("unitsChanged")
      - static let themeChanged = Notification.Name("themeChanged")
    Methods:
      - func loadSettings() async {
      - func updateUnits(_ units: MeasurementSystem) async throws {
      - func updateAppearance(_ mode: AppearanceMode) async throws {
      - func updateHaptics(_ enabled: Bool) async throws {
      - func updateAnalytics(_ enabled: Bool) async throws {
      - func updateAIProvider(_ provider: AIProvider, model: String) async throws {
      - func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func deleteAPIKey(for provider: AIProvider) async throws {
      - func updateNotificationPreferences(_ prefs: NotificationPreferences) async throws {
      - func updateQuietHours(_ hours: QuietHours) async throws {
      - func openSystemNotificationSettings() {
      - func updateBiometricLock(_ enabled: Bool) async throws {
      - func exportUserData() async throws -> URL {
      - func deleteAllData() async throws {
      - private func performDataDeletion() async throws {
      - private func hasAPIKey(for provider: AIProvider) async -> Bool {
      - private func getAPIKey(for provider: AIProvider) async throws -> String {
      - private func isValidAPIKey(_ key: String, for provider: AIProvider) -> Bool {
      - private func testAPIKey(_ key: String, provider: AIProvider) async throws -> Bool {
      - func loadCoachPersona() async throws {
      - func generatePersonaPreview(scenario: PreviewScenario) async throws -> String {
      - func applyNaturalLanguageAdjustment(_ adjustmentText: String) async throws {
      - private func trackPersonaAdjustment(type: PersonaAdaptation.AdaptationType, description: String, impact: Double) async {
      - func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/Components/SettingsComponents.swift

---
Classes:
  Class: SettingsCard
    Properties:
      - let content: Content
      - let style: CardStyle
      - var body: some View {
  Class: CardStyle
    Properties:
      - static var primaryProminent: PrimaryProminentButtonStyle {
  Class: PrimaryProminentButtonStyle
    Properties:
      - @Environment(\.isEnabled) private var isEnabled
      - static var secondary: SecondaryButtonStyle {
    Methods:
      - func makeBody(configuration: Configuration) -> some View {
  Class: SecondaryButtonStyle
    Properties:
      - static var destructive: DestructiveButtonStyle {
    Methods:
      - func makeBody(configuration: Configuration) -> some View {
  Class: DestructiveButtonStyle
    Methods:
      - func makeBody(configuration: Configuration) -> some View {
  Class: ShareSheet
    Properties:
      - let items: [Any]
      - static var secondaryBackground: Color {
    Methods:
      - func makeUIViewController(context: Context) -> UIActivityViewController {
      - func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {

Enums:
  - CardStyle
    Cases:
      - normal
      - destructive
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/AIPersonaSettingsView.swift

---
Classes:
  Class: AIPersonaSettingsView
    Properties:
      - @Bindable var viewModel: SettingsViewModel
      - @State private var showPersonaRefinement = false
      - @State private var previewText = "Let's crush today's workout! I see you're feeling energized - perfect timing for that strength session we planned."
      - @State private var isGeneratingPreview = false
      - var body: some View {
      - private var personaOverview: some View {
      - private var personaTraits: some View {
      - private var evolutionInsights: some View {
      - private var communicationPreferences: some View {
      - private var personaActions: some View {
    Methods:
      - private func generateNewPreview() {
  Class: TraitCard
    Properties:
      - let trait: PersonalityTrait
      - var body: some View {
  Class: CommunicationRow
    Properties:
      - let title: String
      - let value: String
      - let icon: String
      - var body: some View {
  Class: NaturalLanguagePersonaAdjustment
    Properties:
      - @Bindable var viewModel: SettingsViewModel
      - @State private var adjustmentText = ""
      - @State private var isProcessing = false
      - @FocusState private var isTextFieldFocused: Bool
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
    Methods:
      - private func applyAdjustment() {
  Class: ConversationalPersonaRefinement
    Properties:
      - let user: User
      - let currentPersona: CoachPersona?
      - @Environment(\.dismiss) private var dismiss
      - @State private var messages: [RefinementMessage] = []
      - @State private var inputText = ""
      - @State private var isTyping = false
      - @State private var showSuggestions = true
      - @FocusState private var isInputFocused: Bool
      - private let suggestions = [
 "Be more encouraging and supportive", "Use simpler language, less jargon", "Add more humor to our conversations", "Be more data-driven in your feedback", "Push me harder during workouts"
      - var body: some View {
    Methods:
      - private func sendMessage(_ text: String) {
      - private func generateResponse(for input: String) -> String {
      - private func applyRefinements() {
  Class: RefinementMessage
    Properties:
      - let id: UUID
      - let content: String
      - let isUser: Bool
      - let timestamp: Date
  Class: RefinementMessageBubble
    Properties:
      - let message: RefinementMessage
      - let currentPersona: CoachPersona?
      - var body: some View {
  Class: TypingIndicator
    Properties:
      - @State private var animationPhase = 0
      - var body: some View {
      - var displayName: String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/APIConfigurationView.swift

---
Classes:
  Class: APIConfigurationView
    Properties:
      - @Bindable var viewModel: SettingsViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var selectedProvider: AIProvider
      - @State private var selectedModel: String
      - @State private var showAPIKeyEntry = false
      - @State private var providerToAddKey: AIProvider?
      - var body: some View {
      - private var currentConfiguration: some View {
      - private var providerSelection: some View {
      - private var apiKeyManagement: some View {
      - private var saveButton: some View {
    Methods:
      - private func saveConfiguration() {
  Class: ProviderRow
    Properties:
      - let provider: AIProvider
      - let isSelected: Bool
      - let hasAPIKey: Bool
      - let models: [String]
      - @Binding var selectedModel: String
      - let onSelect: () -> Void
      - var body: some View {
  Class: ModelDetailsCard
    Properties:
      - let model: String
      - let provider: AIProvider
      - private var modelEnum: LLMModel? {
      - var body: some View {
    Methods:
      - private func formatTokenCount(_ count: Int) -> String {
  Class: DetailRow
    Properties:
      - let label: String
      - let value: String
      - var body: some View {
  Class: ModelChip
    Properties:
      - let model: String
      - let isSelected: Bool
      - let provider: AIProvider
      - let onSelect: () -> Void
      - private var pricing: (input: Double, output: Double)? {
      - private var displayName: String {
      - private var priceString: String? {
      - var body: some View {
  Class: APIKeyRow
    Properties:
      - let provider: AIProvider
      - let hasKey: Bool
      - let onAdd: () -> Void
      - let onDelete: () -> Void
      - var body: some View {
  Class: ConfigRow
    Properties:
      - let title: String
      - let value: String
      - let icon: String
      - var valueColor: Color = .primary
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/APIKeyEntryView.swift

---
Classes:
  Class: APIKeyEntryView
    Properties:
      - let provider: AIProvider
      - @Bindable var viewModel: SettingsViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var apiKey = ""
      - @State private var isValidating = false
      - @State private var showKey = false
      - @FocusState private var isKeyFieldFocused: Bool
      - var body: some View {
      - private var providerInfo: some View {
      - private var keyInput: some View {
      - private var instructions: some View {
    Methods:
      - private func saveKey() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/AppearanceSettingsView.swift

---
Classes:
  Class: AppearanceSettingsView
    Properties:
      - var viewModel: SettingsViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var selectedAppearance: AppearanceMode
      - @State private var accentColor: Color = .accentColor
      - var body: some View {
      - private var appearanceModeSection: some View {
      - private var themePreview: some View {
      - private var colorAccentSection: some View {
      - private var textSizeSection: some View {
      - private var saveButton: some View {
    Methods:
      - private func saveAppearance() {
      - private func openDisplaySettings() {
  Class: AppearanceModeRow
    Properties:
      - let mode: AppearanceMode
      - let isSelected: Bool
      - let onSelect: () -> Void
      - var body: some View {
  Class: PreviewCard
    Properties:
      - let title: String
      - let icon: String
      - let appearance: AppearanceMode
      - var body: some View {
      - private var backgroundColorForAppearance: Color {
      - private var borderColorForAppearance: Color {
  Class: AccentColorButton
    Properties:
      - let color: Color
      - let isSelected: Bool
      - let onSelect: () -> Void
      - var body: some View {
      - var icon: String {
      - var description: String {
  Class: AccentColorOption

Enums:
  - AccentColorOption
    Cases:
      - blue
      - purple
      - green
      - orange
      - red
      - pink
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/DataManagementView.swift

---
Classes:
  Class: DataManagementView
    Properties:
      - @ObservedObject var viewModel: SettingsViewModel
      - @State private var showExportProgress = false
      - @State private var exportURL: URL?
      - var body: some View {
      - private var exportSection: some View {
      - private var exportHistory: some View {
      - private var deleteSection: some View {
    Methods:
      - private func startExport() {
      - private func confirmDelete() {
  Class: DataExportProgressSheet
    Properties:
      - @ObservedObject var viewModel: SettingsViewModel
      - @Binding var exportURL: URL?
      - @Environment(\.dismiss) private var dismiss
      - @State private var progress: Double = 0
      - @State private var currentStep = "Preparing export..."
      - var body: some View {
    Methods:
      - private func simulateProgress() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/NotificationPreferencesView.swift

---
Classes:
  Class: NotificationPreferencesView
    Properties:
      - var viewModel: SettingsViewModel
      - @State private var preferences: NotificationPreferences
      - @State private var quietHours: QuietHours
      - var body: some View {
      - private var systemNotificationStatus: some View {
      - private var notificationTypes: some View {
      - private var quietHoursSection: some View {
      - private var saveButton: some View {
    Methods:
      - private func savePreferences() {
  Class: NotificationToggle
    Properties:
      - let title: String
      - let description: String
      - let icon: String
      - @Binding var isOn: Bool
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/PrivacySecurityView.swift

---
Classes:
  Class: PrivacySecurityView
    Properties:
      - var viewModel: SettingsViewModel
      - @State private var showPrivacyPolicy = false
      - @State private var showTermsOfService = false
      - var body: some View {
      - private var biometricSection: some View {
      - private var dataPrivacySection: some View {
      - private var analyticsSection: some View {
      - private var legalSection: some View {
  Class: PrivacyRow
    Properties:
      - let title: String
      - let description: String
      - let icon: String
      - let status: PrivacyStatus
  Class: PrivacyStatus
    Properties:
      - var body: some View {
  Class: SafariView
    Properties:
      - let url: URL
    Methods:
      - func makeUIViewController(context: Context) -> SFSafariViewController {
      - func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {

Enums:
  - PrivacyStatus
    Cases:
      - secure
      - notCollected
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/SettingsListView.swift

---
Classes:
  Class: SettingsListView
    Properties:
      - @Environment(\.dismiss) private var dismiss
      - @Environment(\.modelContext) private var modelContext
      - @State private var viewModel: SettingsViewModel
      - @State private var coordinator: SettingsCoordinator
      - var body: some View {
      - private var aiSection: some View {
      - private var preferencesSection: some View {
      - private var privacySection: some View {
      - private var dataSection: some View {
      - private var supportSection: some View {
      - private var debugSection: some View {
    Methods:
      - @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
      - @ViewBuilder
    private func sheetView(for sheet: SettingsCoordinator.SettingsSheet) -> some View {
      - private func alertView(for alert: SettingsCoordinator.SettingsAlert) -> Alert {
  Class: PersonaRefinementFlow
    Properties:
      - let user: User
      - @Environment(\.dismiss) private var dismiss
      - @State private var currentStep = 0
      - @State private var refinementText = ""
      - @State private var isProcessing = false
      - @State private var refinementOptions: [RefinementOption] = []
      - @FocusState private var isTextFieldFocused: Bool
      - var body: some View {
      - private var refinementIntroView: some View {
      - private var refinementOptionsView: some View {
      - private var refinementSummaryView: some View {
    Methods:
      - private func loadRefinementOptions() {
      - private func applyRefinements() {
  Class: RefinementOption
    Properties:
      - let id: UUID
      - let title: String
      - let description: String
      - let category: RefinementCategory
      - var isSelected: Bool
  Class: RefinementCategory
  Class: RefinementOptionCard
    Properties:
      - @Binding var option: RefinementOption
      - var body: some View {
  Class: DataExportProgressView
    Properties:
      - @Bindable var viewModel: SettingsViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var exportProgress: Double = 0
      - @State private var currentStatus = "Preparing export..."
      - @State private var exportSteps: [ExportStep] = []
      - @State private var exportURL: URL?
      - @State private var exportError: Error?
      - @State private var showShareSheet = false
      - var body: some View {
    Methods:
      - private func startExport() {
  Class: ExportStep
    Properties:
      - let id = UUID()
      - let name: String
      - var isComplete: Bool
      - var isActive: Bool
  Class: DeleteAccountView
    Properties:
      - @Bindable var viewModel: SettingsViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var confirmationText = ""
      - @State private var isDeleting = false
      - @State private var showFinalConfirmation = false
      - @FocusState private var isTextFieldFocused: Bool
      - private let confirmationPhrase = "DELETE ACCOUNT"
      - var body: some View {
    Methods:
      - private func deletionItem(_ text: String) -> some View {
      - private func performDeletion() {
  Class: AboutView
    Properties:
      - @State private var showAcknowledgments = false
      - var body: some View {
  Class: FeatureRow
    Properties:
      - let icon: String
      - let title: String
      - let description: String
      - var body: some View {
  Class: TechRow
    Properties:
      - let name: String
      - let version: String
      - var body: some View {
  Class: AcknowledgmentsView
    Properties:
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: AcknowledgmentRow
    Properties:
      - let name: String
      - let author: String
      - let license: String
      - var body: some View {
  Class: DebugSettingsView
    Properties:
      - @State private var showClearCacheAlert = false
      - @State private var showResetOnboardingAlert = false
      - @State private var showExportLogsSheet = false
      - @State private var exportedLogsURL: URL?
      - @State private var isProcessing = false
      - @State private var statusMessage = ""
      - var body: some View {
    Methods:
      - private func getCacheSize() -> String {
      - private func clearCache() {
      - private func resetOnboarding() {
      - private func exportLogs() {
      - private func triggerTestNotification() {
      - private func simulateMemoryWarning() {
  Class: FeatureFlagsView
    Properties:
      - @AppStorage("debug.verboseLogging") private var verboseLogging = false
      - @AppStorage("debug.mockAIResponses") private var mockAIResponses = false
      - @AppStorage("debug.forceOfflineMode") private var forceOfflineMode = false
      - @AppStorage("debug.showPerformanceOverlay") private var showPerformanceOverlay = false
      - var body: some View {
  Class: SettingsShareSheet
    Properties:
      - let items: [Any]
    Methods:
      - func makeUIViewController(context: Context) -> UIActivityViewController {
      - func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {

Enums:
  - RefinementCategory
    Cases:
      - communication
      - analysis
      - engagement
      - personality
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Settings/Views/UnitsSettingsView.swift

---
Classes:
  Class: UnitsSettingsView
    Properties:
      - @ObservedObject var viewModel: SettingsViewModel
      - @Environment(\.dismiss) private var dismiss
      - @State private var selectedUnits: MeasurementSystem
      - var body: some View {
      - private var unitSelection: some View {
      - private var examples: some View {
      - private var saveButton: some View {
    Methods:
      - private func saveUnits() {
  Class: UnitSystemRow
    Properties:
      - let system: MeasurementSystem
      - let isSelected: Bool
      - let onSelect: () -> Void
      - var body: some View {
  Class: ExampleRow
    Properties:
      - let label: String
      - let imperial: String
      - let metric: String
      - let selectedSystem: MeasurementSystem
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Coordinators/WorkoutCoordinator.swift

---
Classes:
  Class: WorkoutCoordinator
    Properties:
      - var path = NavigationPath()
      - var presentedSheet: WorkoutSheet?
  Class: WorkoutDestination
  Class: WorkoutSheet
    Methods:
      - func navigateTo(_ destination: WorkoutDestination) {
      - func pop() {
      - func resetNavigation() {
      - func showSheet(_ sheet: WorkoutSheet) {
      - func dismissSheet() {
      - func handleDeepLink(_ destination: WorkoutDestination) {

Enums:
  - WorkoutDestination
    Cases:
      - workoutDetail
      - exerciseLibrary
      - allWorkouts
      - statistics
  - WorkoutSheet
    Cases:
      - templatePicker
      - newTemplate
      - exerciseDetail
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Models/WorkoutModels.swift

---
Classes:
  Class: WeeklyWorkoutStats
    Properties:
      - var totalWorkouts: Int = 0
      - var totalDuration: TimeInterval = 0
      - var totalCalories: Double = 0
      - var muscleGroupDistribution: [String: Int] = [:]
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Services/WorkoutService.swift

---
Classes:
  Class: WorkoutService
    Properties:
      - private let modelContext: ModelContext
    Methods:
      - func startWorkout(type: WorkoutType, user: User) async throws -> Workout {
      - func pauseWorkout(_ workout: Workout) async throws {
      - func resumeWorkout(_ workout: Workout) async throws {
      - func endWorkout(_ workout: Workout) async throws {
      - func logExercise(_ exercise: Exercise, in workout: Workout) async throws {
      - func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout] {
      - func getWorkoutTemplates() async throws -> [WorkoutTemplate] {
      - func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws {
      - private func calculateEstimatedCalories(for workout: Workout) -> Double {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/ViewModels/WorkoutViewModel.swift

---
Classes:
  Class: WorkoutViewModel
    Properties:
      - private(set) var workouts: [Workout] = []
      - private(set) var weeklyStats = WeeklyWorkoutStats()
      - private(set) var isLoading = false
      - private(set) var aiWorkoutSummary: String?
      - private(set) var isGeneratingAnalysis = false
      - var activeWorkout: Workout?
      - private let modelContext: ModelContext
      - private let user: User
      - private let coachEngine: CoachEngineProtocol
      - private let healthKitManager: HealthKitManaging
      - private let contextAssembler: ContextAssembler
    Methods:
      - func loadWorkouts() async {
      - func loadExerciseLibrary() async {
      - func processReceivedWorkout(data: WorkoutBuilderData) async {
      - func generateAIAnalysis(for workout: Workout) async {
      - func calculateWeeklyStats() async {
      - @objc private func handleWorkoutDataReceived(_ notification: Notification) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/AllWorkoutsView.swift

---
Classes:
  Class: AllWorkoutsView
    Properties:
      - @State var viewModel: WorkoutViewModel
      - @State private var searchText = ""
      - @State private var selectedFilter: WorkoutFilter = .all
      - @State private var sortOrder: SortOrder = .dateDescending
  Class: WorkoutFilter
  Class: SortOrder
    Properties:
      - var filteredWorkouts: [Workout] {
      - var groupedWorkouts: [(String, [Workout])] {
      - var body: some View {
  Class: WorkoutHistoryStats
    Properties:
      - let workouts: [Workout]
      - var totalWorkouts: Int {
      - var totalDuration: TimeInterval {
      - var totalCalories: Double {
      - var averageDuration: TimeInterval {
      - var body: some View {
  Class: StatCard
    Properties:
      - let value: String
      - let label: String
      - let icon: String
      - let color: Color
      - var body: some View {
  Class: FilterChip
    Properties:
      - let title: String
      - let isSelected: Bool
      - let action: () -> Void
      - var body: some View {
  Class: WorkoutHistoryRow
    Properties:
      - let workout: Workout
      - private var dateText: String {
      - private var timeText: String {
      - var body: some View {

Enums:
  - WorkoutFilter
    Cases:
      - all
      - strength
      - cardio
      - flexibility
      - sports
  - SortOrder
    Cases:
      - dateDescending
      - dateAscending
      - duration
      - exercises
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/ExerciseLibraryComponents.swift

---
Classes:
  Class: ExerciseCard
    Properties:
      - let exercise: ExerciseDefinition
      - var body: some View {
      - private var exerciseImage: some View {
  Class: ExerciseDetailSheet
    Properties:
      - private var dismiss
      - let exercise: ExerciseDefinition
      - @State private var selectedImageIndex = 0
      - var body: some View {
      - private var exerciseHeader: some View {
      - private var instructionsSection: some View {
      - private var tipsSection: some View {
      - private var mistakesSection: some View {
      - private var actionButton: some View {
    Methods:
      - private func addToWorkout() {
  Class: FilterSheet
    Properties:
      - private var dismiss
      - @Binding var selectedCategory: ExerciseCategory?
      - @Binding var selectedMuscleGroup: MuscleGroup?
      - @Binding var selectedEquipment: Equipment?
      - @Binding var selectedDifficulty: Difficulty?
      - var body: some View {
  Class: DifficultyPill
    Properties:
      - let difficulty: Difficulty
      - var body: some View {
  Class: CategoryBadge
    Properties:
      - let category: ExerciseCategory
      - var body: some View {
  Class: CompoundBadge
    Properties:
      - var body: some View {
  Class: MuscleGroupTags
    Properties:
      - let muscleGroups: [MuscleGroup]
      - var body: some View {
  Class: MuscleGroupWrap
    Properties:
      - let muscleGroups: [MuscleGroup]
      - var body: some View {
  Class: EquipmentTags
    Properties:
      - let equipment: [Equipment]
      - var body: some View {
      - var systemImage: String {
      - var color: Color {
      - var color: Color {
      - var systemImage: String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/ExerciseLibraryView.swift

---
Classes:
  Class: ExerciseLibraryView
    Properties:
      - @StateObject private var exerciseDatabase = ExerciseDatabase.shared
      - @State private var searchText = ""
      - @State private var selectedCategory: ExerciseCategory?
      - @State private var selectedMuscleGroup: MuscleGroup?
      - @State private var selectedEquipment: Equipment?
      - @State private var selectedDifficulty: Difficulty?
      - @State private var exercises: [ExerciseDefinition] = []
      - @State private var selectedExercise: ExerciseDefinition?
      - @State private var showingFilters = false
      - @State private var hasLoaded = false
      - private let columns = [
 GridItem(.adaptive(minimum: 160), spacing: 16)
      - var filteredExercises: [ExerciseDefinition] {
      - var body: some View {
      - private var hasActiveFilters: Bool {
      - private var loadingView: some View {
      - private var emptyStateView: some View {
      - private var exerciseGridView: some View {
    Methods:
      - private func loadExercises() async {
      - private func clearFilters() {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/TemplatePickerView.swift

---
Classes:
  Class: TemplatePickerView
    Properties:
      - private var dismiss
      - private var modelContext
      - @State var viewModel: WorkoutViewModel
      - @State private var selectedTemplate: UserWorkoutTemplate?
      - @State private var showingCustomTemplate = false
      - private let predefinedTemplates = UserWorkoutTemplate.predefinedTemplates
      - var userTemplates: [UserWorkoutTemplate] {
      - var body: some View {
    Methods:
      - private func startWorkout(with template: UserWorkoutTemplate) {
  Class: TemplateCard
    Properties:
      - let template: UserWorkoutTemplate
      - let action: () -> Void
      - var body: some View {
  Class: UserTemplateRow
    Properties:
      - let template: UserWorkoutTemplate
      - let action: () -> Void
      - var body: some View {
  Class: UserWorkoutTemplate
    Properties:
      - var id = UUID()
      - var name: String
      - var workoutType: String
      - var exercises: [TemplateExercise]
      - var estimatedDuration: TimeInterval?
      - var notes: String?
      - var isUserCreated: Bool
      - var lastUsedDate: Date?
      - var createdDate: Date
      - var iconName: String {
      - var accentColor: Color {
      - static var predefinedTemplates: [UserWorkoutTemplate] {
    Methods:
      - func createWorkout() -> Workout {
  Class: TemplateExercise
    Properties:
      - var name: String
      - var muscleGroups: [String]?
      - var notes: String?
      - var sets: [TemplateSetData]
  Class: TemplateSetData
    Properties:
      - let order: Int
      - let targetReps: Int?
      - let targetWeight: Double?
      - let targetDuration: TimeInterval?
      - static let startActiveWorkout = Notification.Name("startActiveWorkout")
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/WorkoutBuilderView.swift

---
Classes:
  Class: WorkoutBuilderView
    Properties:
      - private var dismiss
      - private var modelContext
      - @State var viewModel: WorkoutViewModel
      - @State private var workoutName = ""
      - @State private var workoutType: WorkoutType = .strength
      - @State private var selectedExercises: [BuilderExercise] = []
      - @State private var showingExercisePicker = false
      - @State private var notes = ""
      - @State private var saveAsTemplate = true
      - var isValid: Bool {
      - var body: some View {
    Methods:
      - private func addExercise(from definition: ExerciseDefinition) {
      - private func removeExercise(_ exercise: BuilderExercise) {
      - private func startWorkout() {
  Class: BuilderExercise
    Properties:
      - let id = UUID()
      - var name: String
      - var muscleGroups: [String]
      - var notes: String?
      - var sets: [BuilderSet]
  Class: BuilderSet
    Properties:
      - let id = UUID()
      - var targetReps: Int?
      - var targetWeight: Double?
  Class: ExerciseBuilderRow
    Properties:
      - @Binding var exercise: BuilderExercise
      - let onDelete: () -> Void
      - var body: some View {
  Class: ExercisePickerView
    Properties:
      - private var dismiss
      - @State private var searchText = ""
      - @State private var exercises: [ExerciseDefinition] = []
      - @State private var isLoading = true
      - let onSelect: (ExerciseDefinition) -> Void
      - var filteredExercises: [ExerciseDefinition] {
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/WorkoutDetailView.swift

---
Classes:
  Class: WorkoutDetailView
    Properties:
      - let workout: Workout
      - @State var viewModel: WorkoutViewModel
      - @State private var showingAIAnalysis = false
      - @State private var selectedExercise: Exercise?
      - @State private var showingTemplateSheet = false
      - @State private var showingShareSheet = false
      - @State private var shareItem: ShareItem?
      - private var modelContext
      - var body: some View {
      - var workoutHeaderSection: some View {
      - var summaryStatsSection: some View {
      - var aiAnalysisSection: some View {
      - var exercisesSection: some View {
      - var actionsSection: some View {
    Methods:
      - func shareWorkout() {
      - func generateShareText() -> String {
  Class: SummaryStatCard
    Properties:
      - let title: String
      - let value: String
      - let icon: String
      - let color: Color
      - var body: some View {
  Class: WorkoutExerciseCard
    Properties:
      - let exercise: Exercise
      - let action: () -> Void
  Class: ChartPoint
    Properties:
      - let id = UUID()
      - let index: Int
      - let volume: Double
      - private var chartData: [ChartPoint] {
      - private var totalVolume: Double {
      - var body: some View {
  Class: ShareItem
    Properties:
      - let id = UUID()
      - let text: String
  Class: ShareSheet
    Properties:
      - let activityItems: [Any]
    Methods:
      - func makeUIViewController(context: Context) -> UIActivityViewController {
      - func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
  Class: SaveAsTemplateView
    Properties:
      - let workout: Workout
      - let modelContext: ModelContext
      - private var dismiss
      - @State private var templateName: String = ""
      - @State private var includeNotes = true
      - var body: some View {
    Methods:
      - private func saveTemplate() {
  Class: AIAnalysisView
    Properties:
      - let analysis: String
      - private var dismiss
      - var body: some View {
  Class: ExerciseDetailView
    Properties:
      - let exercise: Exercise
      - let workout: Workout
      - private var dismiss
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/WorkoutListView.swift

---
Classes:
  Class: WorkoutListView
    Properties:
      - @State private var viewModel: WorkoutViewModel
      - @State private var coordinator: WorkoutCoordinator
      - @State private var searchText = ""
      - @State private var hasLoaded = false
      - var body: some View {
      - private var filteredWorkouts: [Workout] {
      - private var quickActionsSection: some View {
      - private var recentWorkoutsSection: some View {
      - private var emptyStateView: some View {
    Methods:
      - @ViewBuilder
    private func destinationView(for destination: WorkoutCoordinator.WorkoutDestination) -> some View {
      - @ViewBuilder
    private func sheetView(for sheet: WorkoutCoordinator.WorkoutSheet) -> some View {
  Class: WeeklySummaryCard
    Properties:
      - let stats: WeeklyWorkoutStats
      - var body: some View {
  Class: StatItem
    Properties:
      - let value: String
      - let label: String
      - let icon: String
      - let color: Color
      - var body: some View {
  Class: WorkoutRow
    Properties:
      - let workout: Workout
      - let action: () -> Void
      - private var dateText: String {
      - var body: some View {
  Class: QuickActionCard
    Properties:
      - let title: String
      - let icon: String
      - let color: Color
      - let action: () -> Void
      - var body: some View {
  Class: PreviewHealthKitManager
    Properties:
      - var authorizationStatus: HealthKitManager.AuthorizationStatus = .authorized
    Methods:
      - func refreshAuthorizationStatus() {
      - func requestAuthorization() async throws {
      - func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
      - func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
      - func fetchLatestBodyMetrics() async throws -> BodyMetrics {
      - func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {
  Class: WorkoutMockCoachEngine
    Methods:
      - func processUserMessage(_ message: String, context: HealthContextSnapshot?) async throws -> [String: SendableValue] {
      - func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Views/WorkoutStatisticsView.swift

---
Classes:
  Class: WorkoutStatisticsView
    Properties:
      - @State var viewModel: WorkoutViewModel
      - @State private var selectedTimeRange: TimeRange = .month
      - @State private var selectedMetric: MetricType = .frequency
  Class: TimeRange
  Class: MetricType
    Properties:
      - var filteredWorkouts: [Workout] {
      - var body: some View {
      - private var summaryCardsSection: some View {
      - private var mainChartSection: some View {
      - private var personalRecordsSection: some View {
      - private var muscleGroupSection: some View {
      - private var workoutTypeSection: some View {
      - private var totalDuration: TimeInterval {
      - private var totalCalories: Double {
      - private var averageWorkoutsPerWeek: Double {
      - private var chartData: [ChartDataPoint] {
      - private var muscleGroupData: [(name: String, count: Int)] {
      - private var workoutTypeData: [(type: WorkoutType, count: Int, percentage: Int)] {
    Methods:
      - private func calculateTrend(for metric: MetricType) -> Double? {
  Class: ChartDataPoint
    Properties:
      - let id = UUID()
      - let date: Date
      - let value: Double
  Class: TimeRangeChip
    Properties:
      - let title: String
      - let isSelected: Bool
      - let action: () -> Void
      - var body: some View {
  Class: MetricChip
    Properties:
      - let title: String
      - let icon: String
      - let isSelected: Bool
      - let action: () -> Void
      - var body: some View {
  Class: SummaryCard
    Properties:
      - let title: String
      - let value: String
      - let trend: Double?
      - let icon: String
      - let color: Color
      - var body: some View {
  Class: PersonalRecordRow
    Properties:
      - let title: String
      - let value: String
      - let subtitle: String
      - let date: Date
      - let icon: String
      - let color: Color
      - var body: some View {

Enums:
  - TimeRange
    Cases:
      - week
      - month
      - quarter
      - year
      - all
  - MetricType
    Cases:
      - frequency
      - volume
      - duration
      - calories
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/LLMProviders/AnthropicProvider.swift

---
Classes:
  Class: AnthropicProvider
    Properties:
      - private let config: LLMProviderConfig
      - private let session: URLSession
      - let identifier = LLMProviderIdentifier.anthropic
      - let capabilities = LLMCapabilities(
 maxContextTokens: 200_000, supportsJSON: true, supportsStreaming: true, supportsSystemPrompt: true, supportsFunctionCalling: true,  // Now supported in beta supportsVision: true
      - let costPerKToken: (input: Double, output: Double) = (0.003, 0.015) // Default Sonnet pricing
    Methods:
      - func complete(_ request: LLMRequest) async throws -> LLMResponse {
      - func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
      - func validateAPIKey(_ key: String) async throws -> Bool {
      - private func buildAnthropicRequest(from request: LLMRequest) throws -> AnthropicRequest {
      - private func mapToLLMResponse(_ response: AnthropicResponse, model: String) throws -> LLMResponse {
      - private func mapToStreamChunk(_ event: AnthropicStreamEvent) -> LLMStreamChunk? {
      - private func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
  Class: AnthropicRequest
    Properties:
      - let model: String
      - let messages: [AnthropicMessage]
      - let max_tokens: Int
      - let temperature: Double
      - let stream: Bool
  Class: AnthropicMessage
    Properties:
      - let role: String
      - let content: String
  Class: AnthropicResponse
    Properties:
      - let id: String
      - let content: [Content]
      - let stop_reason: String?
      - let usage: Usage
  Class: Content
    Properties:
      - let text: String
  Class: Usage
    Properties:
      - let input_tokens: Int
      - let output_tokens: Int
  Class: AnthropicStreamEvent
    Properties:
      - let type: String
      - let delta: Delta?
      - let usage: AnthropicResponse.Usage?
  Class: Delta
    Properties:
      - let text: String?
  Class: AnthropicError
    Properties:
      - let error: ErrorDetail
  Class: ErrorDetail
    Properties:
      - let message: String
      - let type: String
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/LLMProviders/GeminiProvider.swift

---
Classes:
  Class: GeminiProvider
    Properties:
      - let identifier = LLMProviderIdentifier.google
      - let capabilities = LLMCapabilities(
 maxContextTokens: 2_097_152,  // 2M tokens for Gemini 1.5 Pro, 1M for 2.5 Flash supportsJSON: true, supportsStreaming: true, supportsSystemPrompt: true, supportsFunctionCalling: true,  // Supports function declarations supportsVision: true  // Multimodal support
      - let costPerKToken: (input: Double, output: Double) = (0.0005, 0.0015)
      - private let apiKey: String
      - private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
      - private var retryCount = 0
      - private let maxRetries = 3
      - private let baseDelay: TimeInterval = 1.0
      - private let session = URLSession.shared
    Methods:
      - func validateAPIKey(_ key: String) async throws -> Bool {
      - func complete(_ request: LLMRequest) async throws -> LLMResponse {
      - private func executeWithRetry(request: LLMRequest, isStreaming: Bool, attemptNumber: Int = 0) async throws -> LLMResponse {
      - func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
      - private func buildGeminiRequest(_ request: LLMRequest) throws -> GeminiRequest {
      - private func buildGeminiStreamRequest(_ request: LLMRequest) throws -> GeminiRequest {
      - private func convertMessagesToContents(_ messages: [LLMMessage]) throws -> [GeminiContent] {
      - private func convertToLLMResponse(_ response: GeminiResponse, for request: LLMRequest) throws -> LLMResponse {
      - private func convertToStreamChunk(_ response: GeminiProviderStreamResponse) throws -> LLMStreamChunk {
      - private func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
  Class: GeminiRequest
    Properties:
      - let contents: [GeminiContent]
      - let generationConfig: GeminiGenerationConfig
      - let safetySettings: [GeminiSafetySetting]
      - let tools: [GeminiTool]? // For structured output and function calling
  Class: GeminiContent
    Properties:
      - let role: String
      - let parts: [GeminiPart]
  Class: GeminiPart
    Properties:
      - let text: String?
      - let inlineData: GeminiInlineData?
  Class: GeminiInlineData
    Properties:
      - let mimeType: String
      - let data: String // Base64 encoded
  Class: GeminiGenerationConfig
    Properties:
      - let temperature: Double
      - let maxOutputTokens: Int
      - let topP: Double
      - let candidateCount: Int
      - let thinkingBudgetTokens: Int? // For Gemini 2.5 Flash thinking mode
  Class: GeminiSafetySetting
    Properties:
      - let category: String
      - let threshold: String
  Class: GeminiResponse
    Properties:
      - let candidates: [GeminiCandidate]
      - let usageMetadata: GeminiUsageMetadata?
  Class: GeminiProviderStreamResponse
    Properties:
      - let candidates: [GeminiCandidate]?
  Class: GeminiCandidate
    Properties:
      - let content: GeminiContent
      - let finishReason: String?
      - let index: Int?
      - let safetyRatings: [GeminiSafetyRating]?
  Class: GeminiUsageMetadata
    Properties:
      - let promptTokenCount: Int
      - let candidatesTokenCount: Int
      - let totalTokenCount: Int
  Class: GeminiSafetyRating
    Properties:
      - let category: String
      - let probability: String
  Class: GeminiTool
    Properties:
      - let type: String // "codeExecution" or "structuredOutput"
      - let codeExecution: GeminiCodeExecution?
      - let structuredOutput: GeminiStructuredOutput?
    Methods:
      - static func codeExecution() -> GeminiTool {
      - static func structuredOutput(schema: String) -> GeminiTool {
  Class: GeminiCodeExecution
  Class: GeminiStructuredOutput
    Properties:
      - let schema: String // JSON schema as string
      - static var supportedModels: [String] {
    Methods:
      - private func handleGeminiError(_ data: Data, statusCode: Int) throws -> Never {
  Class: GeminiErrorResponse
    Properties:
      - let error: GeminiError
  Class: GeminiError
    Properties:
      - let code: Int
      - let message: String
      - let status: String
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/LLMProviders/LLMModels.swift

---
Classes:
  Class: LLMModel
  Class: AITask
  Class: LLMProviderConfig
    Properties:
      - let apiKey: String
      - let baseURL: URL?
      - let timeout: TimeInterval
      - let maxRetries: Int

Enums:
  - LLMModel
    Cases:
      - claude35Sonnet
      - claude3Opus
      - claude3Sonnet
      - claude35Haiku
      - claude3Haiku
      - gpt4o
      - gpt4oMini
      - gpt4Turbo
      - gpt4
      - gpt35Turbo
      - gemini25Flash
      - gemini25FlashThinking
      - gemini20FlashThinking
      - gemini20Flash
      - gemini15Pro
      - gemini15Flash
      - gemini10Pro
  - AITask
    Cases:
      - personalityExtraction
      - personaSynthesis
      - conversationAnalysis
      - coaching
      - quickResponse
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/LLMProviders/OpenAIProvider.swift

---
Classes:
  Class: OpenAIProvider
    Properties:
      - private let config: LLMProviderConfig
      - private let session: URLSession
      - let identifier = LLMProviderIdentifier.openai
      - let capabilities = LLMCapabilities(
 maxContextTokens: 128_000, supportsJSON: true, supportsStreaming: true, supportsSystemPrompt: true, supportsFunctionCalling: true, supportsVision: true
      - let costPerKToken: (input: Double, output: Double) = (0.01, 0.03) // Default GPT-4 Turbo pricing
    Methods:
      - func complete(_ request: LLMRequest) async throws -> LLMResponse {
      - func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
      - func validateAPIKey(_ key: String) async throws -> Bool {
      - private func buildOpenAIRequest(from request: LLMRequest) throws -> OpenAIRequest {
      - private func mapToLLMResponse(_ response: OpenAIResponse) throws -> LLMResponse {
      - private func mapToStreamChunk(_ event: OpenAIStreamResponse) -> LLMStreamChunk? {
      - private func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
  Class: OpenAIRequest
    Properties:
      - let model: String
      - let messages: [OpenAIMessage]
      - let temperature: Double
      - let max_tokens: Int?
      - let stream: Bool
      - var response_format: ResponseFormat?
  Class: OpenAIMessage
    Properties:
      - let role: String
      - let content: String
  Class: ResponseFormat
    Properties:
      - let type: String
  Class: OpenAIResponse
    Properties:
      - let id: String
      - let model: String
      - let choices: [Choice]
      - let usage: Usage?
  Class: Choice
    Properties:
      - let message: Message
      - let finish_reason: String?
  Class: Message
    Properties:
      - let content: String?
  Class: Usage
    Properties:
      - let prompt_tokens: Int
      - let completion_tokens: Int
  Class: OpenAIStreamResponse
    Properties:
      - let id: String
      - let choices: [StreamChoice]
  Class: StreamChoice
    Properties:
      - let delta: Delta?
      - let finish_reason: String?
  Class: Delta
    Properties:
      - let content: String?
  Class: OpenAIError
    Properties:
      - let error: ErrorDetail
  Class: ErrorDetail
    Properties:
      - let message: String
      - let type: String
      - let code: String?
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/AIRequestBuilder.swift

---
Classes:
  Class: AIRequestBuilder
    Methods:
      - func buildRequest(
        for aiRequest: AIRequest,
        provider: AIProvider,
        model: String,
        apiKey: String
    ) async throws -> URLRequest {
      - private func endpoint(for provider: AIProvider, model: String) -> URL {
      - private func buildRequestBody(
        for request: AIRequest,
        provider: AIProvider,
        model: String
    ) async throws -> [String: Any] {
      - private func buildOpenAIRequestBody(
        request: AIRequest,
        model: String
    ) -> [String: Any] {
      - private func buildAnthropicRequestBody(
        request: AIRequest,
        model: String
    ) -> [String: Any] {
      - private func buildGeminiRequestBody(
        request: AIRequest,
        model: String
    ) -> [String: Any] {
  Class: FunctionSchema
    Properties:
      - let name: String
      - let description: String
      - let parameters: [String: Any]
  Class: CodingKeys
    Methods:
      - func encode(to encoder: Encoder) throws {

Enums:
  - CodingKeys
    Cases:
      - name
      - description
      - parameters
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/AIResponseCache.swift

---
Classes:
  Class: AIResponseCache
    Properties:
      - private var memoryCache: [String: CacheEntry] = [:]
      - private var diskCachePath: URL
      - private let maxMemoryCacheSize = 100
      - private let maxDiskCacheSize = 1000
      - private let defaultTTL: TimeInterval = 3600 // 1 hour
      - private var hitCount = 0
      - private var missCount = 0
      - private var evictionCount = 0
  Class: CacheEntry
    Properties:
      - let key: String
      - let response: Data
      - let metadata: CacheMetadata
      - let timestamp: Date
      - let accessCount: Int
      - var isExpired: Bool {
      - var size: Int {
  Class: CacheMetadata
    Properties:
      - let model: String
      - let temperature: Double
      - let tokenCount: Int
      - let ttl: TimeInterval
      - let tags: Set<String>
    Methods:
      - func get(request: LLMRequest) async -> LLMResponse? {
      - func set(request: LLMRequest, response: LLMResponse, ttl: TimeInterval? = nil) async {
      - func invalidate(tag: String) async {
      - func clear() async {
      - func getStatistics() -> CacheStatistics {
      - private func generateCacheKey(for request: LLMRequest) -> String {
      - private func extractTags(from request: LLMRequest) -> Set<String> {
      - private func addToMemoryCache(_ entry: CacheEntry) async {
      - private func evictLRUEntry() async {
      - private func saveToDisk(entry: CacheEntry) async {
      - private func loadFromDisk(key: String) async -> CacheEntry? {
      - private func removeFromDisk(key: String) async {
      - private func loadDiskCacheMetadata() async {
      - private func encodeLLMResponse(_ response: LLMResponse) throws -> Data {
      - private func decodeLLMResponse(from data: Data) throws -> LLMResponse {
  Class: CacheStatistics
    Properties:
      - let hitCount: Int
      - let missCount: Int
      - let hitRate: Double
      - let evictionCount: Int
      - let memoryEntries: Int
      - let memorySizeBytes: Int
  Class: DiskCacheContainer
    Properties:
      - let response: Data
      - let metadata: AIResponseCache.CacheMetadata
      - let timestamp: Date
  Class: CodingKeys
    Methods:
      - func encode(to encoder: Encoder) throws {

Enums:
  - CodingKeys
    Cases:
      - content
      - model
      - usage
      - finishReason
      - metadata
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/AIResponseParser.swift

---
Classes:
  Class: AIResponseParser
    Properties:
      - private var buffers: [UUID: ResponseBuffer] = [:]
    Methods:
      - func parseStreamData(
        _ data: Data,
        provider: AIProvider
    ) async throws -> [AIResponse] {
      - private func parseOpenAIStream(_ data: Data) throws -> [AIResponse] {
      - private func parseOpenAIResponse(_ response: OpenAIStreamResponse) -> [AIResponse] {
      - private func parseAnthropicStream(_ data: Data) throws -> [AIResponse] {
      - private func parseAnthropicEvent(type: String, data: String) -> AIResponse? {
      - private func parseGeminiStream(_ data: Data) throws -> [AIResponse] {
      - private func parseGeminiResponse(_ response: GeminiStreamResponse) -> [AIResponse] {
  Class: ResponseBuffer
    Properties:
      - var text: String = ""
      - var functionCalls: [String: PartialFunctionCall] = [:]
  Class: PartialFunctionCall
    Properties:
      - var name: String?
      - var arguments: String = ""
  Class: OpenAIStreamResponse
    Properties:
      - let choices: [Choice]
  Class: Choice
    Properties:
      - let delta: Delta
      - let finishReason: String?
  Class: Delta
    Properties:
      - let role: String?
      - let content: String?
      - let toolCalls: [ToolCall]?
  Class: ToolCall
    Properties:
      - let id: String?
      - let type: String?
      - let function: FunctionCall?
  Class: FunctionCall
    Properties:
      - let name: String?
      - let arguments: String?
  Class: CodingKeys
  Class: AnthropicContentDelta
    Properties:
      - let delta: Delta
  Class: Delta
    Properties:
      - let type: String
      - let text: String?
  Class: AnthropicMessageDelta
    Properties:
      - let delta: Delta
  Class: Delta
    Properties:
      - let stopReason: String?
  Class: CodingKeys
  Class: AnthropicError
    Properties:
      - let error: ErrorDetail
  Class: ErrorDetail
    Properties:
      - let type: String
      - let message: String
  Class: GeminiStreamResponse
    Properties:
      - let candidates: [Candidate]
  Class: Candidate
    Properties:
      - let content: Content
      - let finishReason: String?
  Class: Content
    Properties:
      - let parts: [Part]
  Class: Part
    Properties:
      - let text: String?
      - let functionCall: FunctionCall?
  Class: FunctionCall
    Properties:
      - let name: String
      - let args: String?

Enums:
  - CodingKeys
    Cases:
      - delta
      - finishReason
  - CodingKeys
    Cases:
      - stopReason
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/AIService.swift

---
Classes:
  Class: AIService
    Properties:
      - let serviceIdentifier = "production-ai-service"
      - private(set) var isConfigured: Bool = false
      - private(set) var activeProvider: AIProvider = .anthropic
      - private(set) var availableModels: [AIModel] = []
      - private let orchestrator: LLMOrchestrator
      - private let apiKeyManager: APIKeyManagementProtocol
      - private let cache: AIResponseCache
      - private var currentModel: String = LLMModel.claude3Sonnet.identifier
      - @Published private(set) var totalCost: Double = 0
      - private var fallbackProviders: [AIProvider] = [.openAI, .gemini, .anthropic]
      - private var cacheEnabled = true
    Methods:
      - func configure() async throws {
      - func reset() async {
      - func healthCheck() async -> ServiceHealth {
      - func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
      - func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
      - func validateConfiguration() async throws -> Bool {
      - func checkHealth() async -> ServiceHealth {
      - func estimateTokenCount(for text: String) -> Int {
      - func analyzeGoal(_ goalText: String) async throws -> String {
      - func setCacheEnabled(_ enabled: Bool) {
      - func clearCache() async {
      - func getCacheStatistics() async -> (hits: Int, misses: Int, size: Int) {
      - func resetCostTracking() {
      - func getCostBreakdown() -> [(provider: AIProvider, cost: Double)] {
      - private func generateCacheKey(for request: AIRequest) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/LLMOrchestrator.swift

---
Classes:
  Class: LLMOrchestrator
    Methods:
      - func complete(
        prompt: String,
        task: AITask,
        model: LLMModel? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> LLMResponse {
      - func stream(
        prompt: String,
        task: AITask,
        model: LLMModel? = nil,
        temperature: Double = 0.7
    ) -> AsyncThrowingStream<LLMStreamChunk, Error> {
      - func estimateCost(for prompt: String, model: LLMModel, responseTokens: Int = 1000) -> Double {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/AI/OfflineAIService.swift

---
Classes:
  Class: OfflineAIService
    Properties:
      - var isConfigured: Bool {
      - var serviceIdentifier: String {
      - var activeProvider: AIProvider {
      - var availableModels: [AIModel] {
    Methods:
      - func configure() async throws {
      - func reset() async {
      - func healthCheck() async -> ServiceHealth {
      - func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
      - func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
      - func validateConfiguration() async throws -> Bool {
      - func checkHealth() async -> ServiceHealth {
      - func estimateTokenCount(for text: String) -> Int {
      - func sendMessage(_ message: String, withContext context: [String: Any]?) async throws -> String {
      - func streamMessage(_ message: String, withContext context: [String: Any]?) -> AsyncThrowingStream<String, Error> {
      - func generateStructuredResponse<T: Decodable>(_ prompt: String, responseType: T.Type, withContext context: [String: Any]?) async throws -> T {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Analytics/AnalyticsService.swift

---
Classes:
  Class: AnalyticsService
    Properties:
      - private let modelContext: ModelContext
      - private var eventQueue: [AnalyticsEvent] = []
    Methods:
      - func trackEvent(_ event: AnalyticsEvent) async {
      - func trackScreen(_ screen: String, properties: [String: String]?) async {
      - func setUserProperties(_ properties: [String: String]) async {
      - func trackWorkoutCompleted(_ workout: Workout) async {
      - func trackMealLogged(_ meal: FoodEntry) async {
      - func getInsights(for user: User) async throws -> UserInsights {
      - private func calculateCalorieTrend(from meals: [FoodEntry]) -> Trend {
      - private func calculateMacroBalance(from meals: [FoodEntry]) -> MacroBalance {
      - private func calculateStreakDays(for user: User) -> Int {
      - private func generateAchievements(for user: User, workouts: [Workout], meals: [FoodEntry]) -> [UserAchievement] {
      - static func +(lhs: [String: String], rhs: [String: String]) -> [String: String] {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Cache/OnboardingCache.swift

---
Classes:
  Class: OnboardingCache
    Properties:
      - private let diskCache: URL
      - private var memoryCache: [UUID: CachedSession] = [:]
  Class: CachedSession
    Properties:
      - let userId: UUID
      - let conversationData: ConversationData
      - let partialInsights: PersonalityInsights?
      - let currentStep: String
      - let responses: [String: Data]
      - let timestamp: Date
      - var isValid: Bool {
    Methods:
      - func saveSession(
        userId: UUID,
        conversationData: ConversationData,
        insights: PersonalityInsights?,
        currentStep: String,
        responses: [ConversationResponse]
    ) {
      - func restoreSession(userId: UUID) async -> CachedSession? {
      - func clearSession(userId: UUID) {
      - func getActiveSessions() async -> [UUID: Date] {
      - private func loadActiveSessions() async {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Context/ContextAssembler.swift

---
Classes:
  Class: ContextAssembler
    Properties:
      - private let healthKitManager: HealthKitManaging
    Methods:
      - func assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot {
      - private func fetchActivityMetrics() async -> ActivityMetrics? {
      - private func fetchHeartHealthMetrics() async -> HeartHealthMetrics? {
      - private func fetchBodyMetrics() async -> BodyMetrics? {
      - private func fetchSleepSession() async -> SleepAnalysis.SleepSession? {
      - private func fetchSubjectiveData(using context: ModelContext) async -> SubjectiveData {
      - private func createMockEnvironmentContext() -> EnvironmentContext {
      - private func createMockAppContext(using context: ModelContext) async -> AppSpecificContext {
      - private func assembleWorkoutContext(
        context: ModelContext,
        now: Date,
        sevenDaysAgo: Date
    ) async -> WorkoutContext {
      - private func compressWorkoutForContext(_ workout: Workout) -> CompactWorkout {
      - private func calculateWorkoutStreak(context: ModelContext, endDate: Date) -> Int {
      - private func analyzeWorkoutPatterns(_ workouts: [Workout]) -> WorkoutPatterns {
      - private func calculateTrends(
        activity: ActivityMetrics?,
        body: BodyMetrics?,
        sleep: SleepAnalysis.SleepSession?,
        context: ModelContext
    ) async -> HealthTrends {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Health/HealthKit+Types.swift

---
Classes:
  Class: HealthKit+Types
    Methods:
      - static func from(vo2Max: Double) -> HeartHealthMetrics.CardioFitnessLevel? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Health/HealthKitDataFetcher.swift

---
Classes:
  Class: HealthKitDataFetcher
    Properties:
      - private let healthStore: HKHealthStore
    Methods:
      - func enableBackgroundDelivery() async throws {
      - func fetchTotalQuantity(
        identifier: HKQuantityTypeIdentifier,
        start: Date,
        end: Date,
        unit: HKUnit
    ) async throws -> Double? {
      - func fetchLatestQuantitySample(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double? {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Health/HealthKitDataTypes.swift

---
Classes:
  Class: HealthKitDataTypes

Enums:
  - HealthKitDataTypes
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Health/HealthKitManager.swift

---
Classes:
  Class: HealthKitManager
    Properties:
      - static let shared = HealthKitManager()
      - private let healthStore = HKHealthStore()
      - private let dataFetcher: HealthKitDataFetcher
      - private let sleepAnalyzer: HealthKitSleepAnalyzer
      - private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
  Class: AuthorizationStatus
  Class: HealthKitError
    Methods:
      - func requestAuthorization() async throws {
      - func refreshAuthorizationStatus() {
      - func fetchTodayActivityMetrics() async throws -> ActivityMetrics {
      - private func fetchActivityMetrics(from startDate: Date, to endDate: Date) async throws -> ActivityMetrics {
      - func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics {
      - func fetchLatestBodyMetrics() async throws -> BodyMetrics {
      - func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? {

Enums:
  - AuthorizationStatus
    Cases:
      - notDetermined
      - authorized
      - denied
      - restricted
  - HealthKitError
    Cases:
      - notAvailable
      - authorizationDenied
      - dataNotFound
      - queryFailed
      - invalidData
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Health/HealthKitSleepAnalyzer.swift

---
Classes:
  Class: HealthKitSleepAnalyzer
    Properties:
      - private let healthStore: HKHealthStore
    Methods:
      - func analyzeSleepSamples(from startDate: Date, to endDate: Date) async throws -> SleepAnalysis.SleepSession? {
      - nonisolated private func createSleepSession(from samples: [HKCategorySample]) -> SleepAnalysis.SleepSession {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Monitoring/MonitoringService.swift

---
Classes:
  Class: MonitoringService
    Properties:
      - static let shared = MonitoringService()
      - @Published private(set) var metrics = ProductionMetrics()
      - @Published private(set) var alerts: [MonitoringAlert] = []
      - private let logger = Logger(subsystem: "com.airfit", category: "monitoring")
      - private var metricsTimer: Timer?
      - private let metricsQueue = DispatchQueue(label: "com.airfit.monitoring", qos: .utility)
      - private let performanceThresholds = PerformanceThresholds(
 personaGenerationMax: 5.0, conversationResponseMax: 2.0, apiCallMax: 3.0, cacheHitRateMin: 0.7, errorRateMax: 0.05
    Methods:
      - func trackPersonaGeneration(duration: TimeInterval, success: Bool, model: String? = nil) {
      - func trackConversationResponse(duration: TimeInterval, nodeId: String, tokenCount: Int) {
      - func trackAPICall(provider: String, model: String, duration: TimeInterval, success: Bool, cost: Double) {
      - func trackCacheHit(hit: Bool) {
      - func trackError(_ error: Error, context: String) {
      - func getMetricsSnapshot() -> ProductionMetrics {
      - func exportMetrics() -> Data? {
      - func resetMetrics() {
      - private func startMonitoring() {
      - private func reportMetrics() {
      - private func checkForAnomalies(in metrics: ProductionMetrics) {
      - private func monitorSystemResources() async {
      - private func createAlert(type: AlertType, severity: AlertSeverity, message: String, metadata: [String: Any]) {
      - private func getMemoryUsage() -> Int64 {
  Class: ProductionMetrics
    Properties:
      - var personaGeneration = PersonaGenerationMetrics()
      - var conversationFlow = ConversationFlowMetrics()
      - var apiPerformance = APIPerformanceMetrics()
      - var cachePerformance = CachePerformanceMetrics()
      - var errors: [ErrorRecord] = []
      - var startTime = Date()
  Class: PersonaGenerationMetrics
    Properties:
      - var count = 0
      - var successCount = 0
      - var failureCount = 0
      - var totalDuration: TimeInterval = 0
      - var averageDuration: TimeInterval {
      - var successRate: Double {
  Class: ConversationFlowMetrics
    Properties:
      - var responseCount = 0
      - var totalResponseTime: TimeInterval = 0
      - var totalTokens = 0
      - var averageResponseTime: TimeInterval {
      - var averageTokensPerResponse: Double {
  Class: APIPerformanceMetrics
    Properties:
      - var callCount = 0
      - var errorCount = 0
      - var totalDuration: TimeInterval = 0
      - var totalCost: Double = 0
      - var byProvider: [String: ProviderMetrics] = [:]
      - var averageLatency: TimeInterval {
      - var errorRate: Double {
  Class: CachePerformanceMetrics
    Properties:
      - var hitCount = 0
      - var missCount = 0
      - var hitRate: Double {
  Class: ProviderMetrics
    Properties:
      - var callCount = 0
      - var errorCount = 0
      - var totalDuration: TimeInterval = 0
  Class: ErrorRecord
    Properties:
      - let timestamp: Date
      - let errorDescription: String
      - let context: String
  Class: MonitoringAlert
    Properties:
      - let id: UUID
      - let type: AlertType
      - let severity: AlertSeverity
      - let message: String
      - let timestamp: Date
      - let metadata: [String: String]
  Class: AlertType
  Class: AlertSeverity
  Class: PerformanceThresholds
    Properties:
      - let personaGenerationMax: TimeInterval
      - let conversationResponseMax: TimeInterval
      - let apiCallMax: TimeInterval
      - let cacheHitRateMin: Double
      - let errorRateMax: Double

Enums:
  - AlertType
    Cases:
      - performanceDegradation
      - highErrorRate
      - lowCacheHitRate
      - errorSpike
      - highMemoryUsage
  - AlertSeverity
    Cases:
      - info
      - warning
      - critical
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Network/NetworkClient.swift

---
Classes:
  Class: NetworkClient
    Properties:
      - static let shared = NetworkClient()
      - private let session: URLSession
      - private let decoder: JSONDecoder
      - private let encoder: JSONEncoder
      - private var userAgent: String {
    Methods:
      - func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
      - func upload(_ data: Data, to endpoint: Endpoint) async throws {
      - func download(from endpoint: Endpoint) async throws -> Data {
      - private func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
      - func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
      - func post<T: Decodable, U: Encodable>(_ path: String, body: U) async throws -> T {
      - func put<T: Decodable, U: Encodable>(_ path: String, body: U) async throws -> T {
      - func delete(_ path: String) async throws {
  Class: EmptyResponse
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Network/NetworkManager.swift

---
Classes:
  Class: NetworkManager
    Properties:
      - static let shared = NetworkManager()
      - @Published private(set) var isReachable: Bool = true
      - @Published private(set) var currentNetworkType: NetworkType = .unknown
      - private(set) var isConfigured: Bool = false
      - let serviceIdentifier = "network-manager"
      - private let session: URLSession
      - private let monitor: NWPathMonitor
      - private let monitorQueue = DispatchQueue(label: "com.airfit.networkmonitor")
      - private var cancellables = Set<AnyCancellable>()
      - private var userAgent: String {
    Methods:
      - func configure() async throws {
      - func reset() async {
      - func healthCheck() async -> ServiceHealth {
      - func buildRequest(url: URL, method: String = "GET", headers: [String: String] = [:]) -> URLRequest {
      - func performRequest<T: Decodable>(
        _ request: URLRequest,
        expecting: T.Type
    ) async throws -> T {
      - func performStreamingRequest(
        _ request: URLRequest
    ) -> AsyncThrowingStream<Data, Error> {
      - func downloadData(from url: URL) async throws -> Data {
      - func uploadData(_ data: Data, to url: URL) async throws -> URLResponse {
      - private func setupNetworkMonitoring() {
      - @MainActor
    private func updateNetworkStatus(_ path: NWPath) {
      - private func validateHTTPResponse(_ response: HTTPURLResponse, data: Data?) throws {
      - func buildRequest(
        url: URL,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil,
        timeout: TimeInterval = 30
    ) -> URLRequest {
      - static func createURLSession(
        configuration: URLSessionConfiguration = .default,
        delegate: URLSessionDelegate? = nil
    ) -> URLSession {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Network/RequestOptimizer.swift

---
Classes:
  Class: RequestOptimizer
    Properties:
      - private var pendingRequests: [RequestKey: PendingRequest] = [:]
      - private var batchQueue: [BatchableRequest] = []
      - private var retryQueue: [RetryableRequest] = []
      - private let maxBatchSize = 10
      - private let batchDelay: TimeInterval = 0.1 // 100ms
      - private var batchTimer: Task<Void, Never>?
  Class: RequestKey
    Properties:
      - let endpoint: String
      - let method: String
      - let bodyHash: Int?
  Class: PendingRequest
    Properties:
      - let request: URLRequest
      - let completion: CheckedContinuation<Data, Error>
      - let retryCount: Int
  Class: BatchableRequest
    Properties:
      - let request: URLRequest
      - let completion: CheckedContinuation<Data, Error>
  Class: RetryableRequest
    Properties:
      - let request: URLRequest
      - let completion: CheckedContinuation<Data, Error>
      - let retryCount: Int
      - let nextRetryTime: Date
    Methods:
      - func execute(_ request: URLRequest) async throws -> Data {
      - private func isBatchable(_ request: URLRequest) -> Bool {
      - private func batchRequest(_ request: URLRequest) async throws -> Data {
      - private func processBatch() async {
      - private func executeWithRetry(_ request: URLRequest, retryCount: Int = 0) async throws -> Data {
      - private func shouldRetry(error: Error, retryCount: Int) -> Bool {
      - private func retryDelay(for attempt: Int) -> TimeInterval {
      - private func makeKey(for request: URLRequest) -> RequestKey {
  Class: NetworkMonitor
    Properties:
      - static let shared = NetworkMonitor()
      - @Published private(set) var isConnected = true
      - private var monitor: NWPathMonitor?
      - private let queue = DispatchQueue(label: "NetworkMonitor")
    Methods:
      - private func startMonitoring() {
  Class: RequestOptimizerError
    Methods:
      - func optimizedData(for request: URLRequest) async throws -> Data {

Enums:
  - RequestOptimizerError
    Cases:
      - offline
      - timeout
      - connectionLost
      - duplicate
      - invalidResponse
      - httpError
      - rateLimited
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Security/APIKeyManager.swift

---
Classes:
  Class: APIKeyManager
    Properties:
      - private let keychain: KeychainWrapper
      - private let keychainPrefix = "com.airfit.apikey."
      - private(set) var isConfigured: Bool = false
      - let serviceIdentifier = "api-key-manager"
    Methods:
      - func configure() async throws {
      - func reset() async {
      - func healthCheck() async -> ServiceHealth {
      - func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
      - func getAPIKey(for provider: AIProvider) async throws -> String {
      - func deleteAPIKey(for provider: AIProvider) async throws {
      - func hasAPIKey(for provider: AIProvider) async -> Bool {
      - func getAllConfiguredProviders() async -> [AIProvider] {
      - private func keychainKey(for provider: String) -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Security/KeychainHelper.swift

---
Classes:
  Class: KeychainHelper
    Properties:
      - static let shared = KeychainHelper()
      - private let serviceName: String
      - private let accessGroup: String?
      - private let lock = NSLock()
    Methods:
      - func save(_ data: Data, for key: String, accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly) throws {
      - func save(_ string: String, for key: String, accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly) throws {
      - func getData(for key: String) throws -> Data {
      - func getString(for key: String) throws -> String {
      - func delete(for key: String) throws {
      - func deleteAll() throws {
      - func getAllKeys() throws -> [String] {
      - func exists(for key: String) -> Bool {
      - private func baseQuery(for key: String) -> [CFString: Any] {
  Class: KeychainAccessibility
  Class: KeychainError

Enums:
  - KeychainAccessibility
    Cases:
      - whenUnlocked
      - whenUnlockedThisDeviceOnly
      - afterFirstUnlock
      - afterFirstUnlockThisDeviceOnly
      - whenPasscodeSetThisDeviceOnly
  - KeychainError
    Cases:
      - itemNotFound
      - duplicateItem
      - invalidItemFormat
      - unexpectedItemData
      - encodingError
      - decodingError
      - unhandledError
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Speech/VoiceInputManager.swift

---
Classes:
  Class: VoiceInputManager
    Properties:
      - private(set) var isRecording = false
      - private(set) var isTranscribing = false
      - private(set) var waveformBuffer: [Float] = []
      - private(set) var currentTranscription = ""
      - var onTranscription: ((String) -> Void)?
      - var onPartialTranscription: ((String) -> Void)?
      - var onWaveformUpdate: (([Float]) -> Void)?
      - var onError: ((Error) -> Void)?
      - private var audioEngine = AVAudioEngine()
      - private var audioRecorder: AVAudioRecorder?
      - private var waveformTimer: Timer?
      - private var audioBuffer: [Float] = []
      - private var recordingURL: URL?
      - private var whisper: WhisperKit?
      - private let modelManager: WhisperModelManager
      - private var inputNode: AVAudioInputNode {
    Methods:
      - func requestPermission() async throws -> Bool {
      - func startRecording() async throws {
      - func stopRecording() async -> String? {
      - func startStreamingTranscription() async throws {
      - func stopStreamingTranscription() async {
      - private func initializeWhisper() async {
      - private func prepareRecorder() async throws {
      - private func transcribeAudio(at url: URL) async throws -> String {
      - private func processAudioChunk(_ audioData: [Float]) async {
      - private func processStreamingBuffer(_ buffer: AVAudioPCMBuffer) async {
      - private func startWaveformTimer() {
      - private func stopWaveformTimer() {
      - private func updateAudioLevels() {
      - private func analyzeAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
      - private func postProcessTranscription(_ text: String) -> String {
  Class: VoiceInputError

Enums:
  - VoiceInputError
    Cases:
      - notAuthorized
      - whisperInitializationFailed
      - whisperNotReady
      - recordingFailed
      - transcriptionFailed
      - audioEngineError
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Speech/WhisperModelManager.swift

---
Classes:
  Class: WhisperModelManager
    Properties:
      - static let shared = WhisperModelManager()
  Class: WhisperModel
    Properties:
      - let id: String
      - let displayName: String
      - let size: String
      - let sizeBytes: Int
      - let accuracy: String
      - let speed: String
      - let languages: String
      - let requiredMemory: UInt64
      - let huggingFaceRepo: String
  Class: ModelError
    Properties:
      - static let modelConfigurations: [WhisperModel] = [
 WhisperModel( id: "tiny", displayName: "Tiny (39 MB)", size: "39 MB", sizeBytes: 39_000_000, accuracy: "Good", speed: "Fastest", languages: "English + 98 more", requiredMemory: 200_000_000, huggingFaceRepo: "mlx-community/whisper-tiny-mlx" ), WhisperModel( id: "base", displayName: "Base (74 MB)", size: "74 MB", sizeBytes: 74_000_000, accuracy: "Better", speed: "Very Fast", languages: "English + 98 more", requiredMemory: 500_000_000, huggingFaceRepo: "mlx-community/whisper-base-mlx" ), WhisperModel( id: "small", displayName: "Small", size: "244 MB", sizeBytes: 244_000_000, accuracy: "Good", speed: "Moderate", languages: "Multi", requiredMemory: 3_000_000_000, huggingFaceRepo: "mlx-community/whisper-small-mlx" ), WhisperModel( id: "medium", displayName: "Medium", size: "769 MB", sizeBytes: 769_000_000, accuracy: "Very Good", speed: "Slower", languages: "Multi", requiredMemory: 4_000_000_000, huggingFaceRepo: "mlx-community/whisper-medium-mlx" ), WhisperModel( id: "large-v3", displayName: "Large v3", size: "1.55 GB", sizeBytes: 1_550_000_000, accuracy: "Best", speed: "Slowest", languages: "Multi", requiredMemory: 6_000_000_000, huggingFaceRepo: "mlx-community/whisper-large-v3-mlx" )
      - private let modelStorageURL: URL
      - @Published var availableModels: [WhisperModel] = []
      - @Published var downloadedModels: Set<String> = []
      - @Published var isDownloading: [String: Bool] = [:]
      - @Published var downloadProgress: [String: Double] = [:]
      - @Published var activeModel: String = "base"
    Methods:
      - private func loadModelInfo() {
      - private func updateDownloadedModels() {
      - func downloadModel(_ modelId: String) async throws {
      - func deleteModel(_ modelId: String) throws {
      - private func hasEnoughStorage(for model: WhisperModel) -> Bool {
      - private func locateWhisperKitCache(for modelId: String) -> URL? {
      - func selectOptimalModel() -> String {
      - func modelPath(for modelId: String) -> URL? {
      - func clearUnusedModels() throws {

Enums:
  - ModelError
    Cases:
      - modelNotFound
      - insufficientStorage
      - downloadFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/User/UserService.swift

---
Classes:
  Class: UserService
    Properties:
      - private let modelContext: ModelContext
    Methods:
      - func createUser(from profile: OnboardingProfile) async throws -> User {
      - func updateProfile(_ updates: ProfileUpdate) async throws {
      - func getCurrentUser() async -> User? {
      - func getCurrentUserId() async -> UUID? {
      - func deleteUser(_ user: User) async throws {
      - func completeOnboarding() async throws {
      - func setCoachPersona(_ persona: CoachPersona) async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/Weather/WeatherService.swift

---
Classes:
  Class: WeatherService
    Properties:
      - let serviceIdentifier = "weatherkit-service"
      - private(set) var isConfigured = true // WeatherKit requires no configuration
      - private let weatherService = WeatherKit.WeatherService.shared
      - private let locationManager = CLLocationManager()
      - private var cache: (location: CLLocation, weather: ServiceWeatherData, timestamp: Date)?
      - private let cacheLifetime: TimeInterval = 600 // 10 minutes
    Methods:
      - func configure() async throws {
      - func healthCheck() async -> ServiceHealth {
      - func reset() async {
      - func getCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
      - func getForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
      - func getCachedWeather(latitude: Double, longitude: Double) -> ServiceWeatherData? {
      - func getLLMContext(latitude: Double, longitude: Double) async -> String? {
      - private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> AirFit.WeatherCondition {
      - private func getLocationName(for location: CLLocation) async -> String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/ExerciseDatabase.swift

---
Classes:
  Class: ExerciseDefinition
    Properties:
      - var id: String
      - var name: String
      - var category: ExerciseCategory
      - var muscleGroups: [MuscleGroup]
      - var equipment: [Equipment]
      - var instructions: [String]
      - var tips: [String]
      - var commonMistakes: [String]
      - var difficulty: Difficulty
      - var isCompound: Bool
      - var imageNames: [String]
      - var force: String?
      - var mechanic: String?
  Class: CodingKeys
    Methods:
      - func encode(to encoder: Encoder) throws {
  Class: RawExerciseData
    Properties:
      - let name: String
      - let force: String?
      - let level: String
      - let mechanic: String?
      - let equipment: String?
      - let primaryMuscles: [String]
      - let secondaryMuscles: [String]
      - let instructions: [String]
      - let category: String
      - let images: [String]
      - let id: String
  Class: ExerciseDatabase
    Properties:
      - static let shared = ExerciseDatabase()
      - @Published private(set) var isLoading = false
      - @Published private(set) var loadingProgress: Double = 0
      - @Published private(set) var error: ExerciseDatabaseError?
      - private let container: ModelContainer
      - private var exercises: [ExerciseDefinition] = []
      - private let cacheQueue = DispatchQueue(label: "exercise.cache", qos: .utility)
    Methods:
      - func getAllExercises() async throws -> [ExerciseDefinition] {
      - func searchExercises(query: String) async -> [ExerciseDefinition] {
      - func getExercisesByMuscleGroup(_ muscleGroup: MuscleGroup) async -> [ExerciseDefinition] {
      - func getExercisesByCategory(_ category: ExerciseCategory) async -> [ExerciseDefinition] {
      - func getExercisesByEquipment(_ equipment: Equipment) async -> [ExerciseDefinition] {
      - func getExercisesByDifficulty(_ difficulty: Difficulty) async -> [ExerciseDefinition] {
      - func getExercise(by id: String) async -> ExerciseDefinition? {
      - private func initializeDatabase() async {
      - private func seedDatabase() async {
      - private func transformRawExercise(_ raw: RawExerciseData) throws -> ExerciseDefinition {
      - private func handleError(_ error: ExerciseDatabaseError) async {
  Class: ExerciseDatabaseError
    Methods:
      - static func fromRawValue(_ raw: String) -> ExerciseCategory {
      - static func fromRawValue(_ raw: String) -> MuscleGroup? {
      - static func fromRawValue(_ raw: String) -> [Equipment] {
      - static func fromRawValue(_ raw: String) -> Difficulty {

Enums:
  - CodingKeys
    Cases:
      - id
      - name
      - category
      - muscleGroups
      - equipment
      - instructions
      - tips
      - commonMistakes
      - difficulty
      - isCompound
      - imageNames
      - force
      - mechanic
  - ExerciseDatabaseError
    Cases:
      - seedDataNotFound
      - initializationFailed
      - seedingFailed
      - queryFailed
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/ServiceConfiguration.swift

---
Classes:
  Class: ServiceConfiguration
  Class: AIConfiguration
    Properties:
      - let defaultProvider: AIProvider
      - let defaultModel: String
      - let maxRetries: Int
      - let timeout: TimeInterval
      - let cacheEnabled: Bool
      - let cacheDuration: TimeInterval
      - let streamingEnabled: Bool
      - let costTrackingEnabled: Bool
      - static let `default` = AIConfiguration(
 defaultProvider: .openAI, defaultModel: "gpt-4o-mini", maxRetries: 3, timeout: 30, cacheEnabled: true, cacheDuration: 3600, // 1 hour streamingEnabled: true, costTrackingEnabled: true
  Class: WeatherConfiguration
    Properties:
      - let apiProvider: WeatherProvider
      - let updateInterval: TimeInterval
      - let cacheEnabled: Bool
      - let cacheDuration: TimeInterval
      - let defaultUnits: WeatherUnits
  Class: WeatherProvider
  Class: WeatherUnits
    Properties:
      - static let `default` = WeatherConfiguration(
 apiProvider: .openWeather, updateInterval: 900, // 15 minutes cacheEnabled: true, cacheDuration: 600, // 10 minutes defaultUnits: .imperial
  Class: NetworkConfiguration
    Properties:
      - let maxConcurrentRequests: Int
      - let requestTimeout: TimeInterval
      - let resourceTimeout: TimeInterval
      - let retryCount: Int
      - let retryDelay: TimeInterval
      - let enableLogging: Bool
      - static let `default` = NetworkConfiguration(
 maxConcurrentRequests: 4, requestTimeout: 30, resourceTimeout: 60, retryCount: 3, retryDelay: 1.0, enableLogging: true
  Class: AnalyticsConfiguration
    Properties:
      - let enabled: Bool
      - let debugLogging: Bool
      - let sessionTimeout: TimeInterval
      - let flushInterval: TimeInterval
      - let maxEventsPerBatch: Int
      - static let `default` = AnalyticsConfiguration(
 enabled: true, debugLogging: false, sessionTimeout: 1800, // 30 minutes flushInterval: 60, // 1 minute maxEventsPerBatch: 100
      - let ai: AIConfiguration
      - let weather: WeatherConfiguration
      - let network: NetworkConfiguration
      - let analytics: AnalyticsConfiguration
      - let environment: Environment
  Class: Environment
    Properties:
      - static let shared = ServiceConfiguration(
 ai: .default, weather: .default, network: .default, analytics: .default, environment: detectEnvironment()
      - static var serviceRegistry: ServiceRegistry {
    Methods:
      - static func detectEnvironment() -> Environment {
      - @MainActor
    static func registerService<T: ServiceProtocol>(_ service: T, for type: T.Type) {
      - @MainActor
    static func getService<T: ServiceProtocol>(_ type: T.Type) -> T? {
      - @MainActor
    static func requireService<T: ServiceProtocol>(_ type: T.Type) -> T {

Enums:
  - WeatherProvider
    Cases:
      - openWeather
      - weatherAPI
  - WeatherUnits
    Cases:
      - metric
      - imperial
  - Environment
    Cases:
      - development
      - staging
      - production
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/ServiceRegistry.swift

---
Classes:
  Class: ServiceRegistry
    Properties:
      - static let shared = ServiceRegistry()
      - private var services: [ObjectIdentifier: any ServiceProtocol] = [:]
      - private var serviceTypes: [ObjectIdentifier: Any.Type] = [:]
      - private let lock = NSLock()
      - var registeredTypes: [String] {
      - var count: Int {
    Methods:
      - func register<T>(_ service: any ServiceProtocol, for type: T.Type) {
      - func registerAll(_ registrations: [(service: any ServiceProtocol, type: Any.Type)]) {
      - func get<T>(_ type: T.Type) -> T? {
      - func require<T>(_ type: T.Type) -> T {
      - func has<T>(_ type: T.Type) -> Bool {
      - func healthCheck() async -> [String: ServiceHealth] {
      - func healthCheck<T>(for type: T.Type) async -> ServiceHealth? {
      - func resetAll() async {
      - func reset<T>(_ type: T.Type) async {
      - func unregister<T>(_ type: T.Type) {
      - func unregisterAll() {
      - func registerDefaultServices(
        networkManager: NetworkManagementProtocol & ServiceProtocol,
        apiKeyManager: APIKeyManagementProtocol & ServiceProtocol,
        aiService: AIServiceProtocol?,
        weatherService: WeatherServiceProtocol?
    ) {
  Class: Injected
    Properties:
      - private let type: Service.Type
      - var wrappedValue: Service {
      - var projectedValue: Service? {
  Class: ServiceBootstrapper
    Methods:
      - static func bootstrap() async throws {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFit/Services/WorkoutSyncService.swift

---
Classes:
  Class: WorkoutSyncService
    Properties:
      - static let shared = WorkoutSyncService()
      - private let session: WCSession
      - private var pendingWorkouts: [WorkoutBuilderData] = []
      - private lazy var container: CKContainer? = {
      - static let workoutDataReceived = Notification.Name("workoutDataReceived")
    Methods:
      - func sendWorkoutData(_ data: WorkoutBuilderData) async {
      - private func syncToCloudKit(_ data: WorkoutBuilderData) async {
      - func processReceivedWorkout(_ data: WorkoutBuilderData, modelContext: ModelContext) async throws {
      - nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
      - nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
      - nonisolated func sessionDidDeactivate(_ session: WCSession) {
      - nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFitWatchApp/AirFitWatchAppTests/Services/WatchWorkoutManagerTests.swift

---
Classes:
  Class: WatchWorkoutManagerTests
    Properties:
      - var sut: WatchWorkoutManager!
      - var mockHealthStore: MockHealthStoreProtocol!
      - var mockSession: MockWCSessionProtocol!
    Methods:
      - @MainActor
    override func setUp() {
      - @MainActor
    override func tearDown() {
      - func test_init_shouldSetInitialState() {
      - func test_startWorkout_shouldUpdateState() async throws {
      - func test_startWorkout_withInvalidPermissions_shouldThrowError() async {
      - func test_pauseWorkout_shouldUpdateState() {
      - func test_resumeWorkout_shouldUpdateState() {
      - func test_endWorkout_shouldUpdateState() async {
      - func test_startNewExercise_shouldCreateExercise() {
      - func test_logSet_shouldAddSetToCurrentExercise() {
      - func test_logSet_withoutCurrentExercise_shouldNotCrash() {
      - func test_heartRateProperty_shouldBeReadable() {
      - func test_activeCaloriesProperty_shouldBeReadable() {
      - func test_elapsedTimeProperty_shouldBeReadable() {
      - func test_startWorkout_performance_shouldCompleteQuickly() async throws {
      - func test_logMultipleSets_performance_shouldCompleteQuickly() {
      - func test_startWorkout_withHealthKitError_shouldHandleGracefully() async {
      - func test_workoutStateTransitions_shouldFollowValidFlow() async throws {
      - func test_endWorkout_shouldTriggerSync() async throws {
      - func test_requestAuthorization_shouldReturnSuccess() async throws {
      - func test_requestAuthorization_shouldThrowError() async {
  Class: MockHealthStoreProtocol
    Properties:
      - var shouldFailAuthorization = false
      - var shouldFailWorkoutSession = false
    Methods:
      - func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?
    ) async throws {
  Class: MockWCSessionProtocol
    Properties:
      - var mockReachable = true
      - var sentMessages: [[String: Any]] = []
      - var isReachable: Bool {
    Methods:
      - func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFitWatchApp/Services/WatchWorkoutManager.swift

---
Classes:
  Class: WatchWorkoutManager
    Properties:
      - private let healthStore = HKHealthStore()
      - private var session: HKWorkoutSession?
      - private var builder: HKLiveWorkoutBuilder?
      - private(set) var workoutState: WorkoutState = .idle
      - private(set) var isPaused = false
      - private(set) var heartRate: Double = 0
      - private(set) var activeCalories: Double = 0
      - private(set) var totalCalories: Double = 0
      - private(set) var distance: Double = 0
      - private(set) var elapsedTime: TimeInterval = 0
      - private(set) var currentPace: Double = 0
      - var selectedActivityType: HKWorkoutActivityType = .traditionalStrengthTraining
      - private(set) var currentWorkoutData = WorkoutBuilderData()
      - private var startTime: Date?
      - private var elapsedTimer: Timer?
  Class: WorkoutState
    Properties:
      - var name: String {
      - var isIndoor: Bool {
      - static let workoutDataReceived = Notification.Name("workoutDataReceived")
    Methods:
      - func requestAuthorization() async throws -> Bool {
      - func startWorkout(activityType: HKWorkoutActivityType) async throws {
      - func pauseWorkout() {
      - func resumeWorkout() {
      - func endWorkout() async {
      - func startNewExercise(name: String, muscleGroups: [String]) {
      - func logSet(reps: Int?, weight: Double?, duration: TimeInterval?, rpe: Double?) {
      - private func startElapsedTimer() {
      - private func processCompletedWorkout(_ workout: HKWorkout) async {
      - nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
      - nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
      - nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
      - nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
      - func updatePace() {

Enums:
  - WorkoutState
    Cases:
      - idle
      - starting
      - running
      - paused
      - ending
      - ended
      - error
---


Path: /Users/Brian/Coding Projects/AirFit/AirFitWatchApp/Views/ActiveWorkoutView.swift

---
Classes:
  Class: ActiveWorkoutView
    Properties:
      - let workoutManager: WatchWorkoutManager
      - @State private var selectedTab = 0
      - @Environment(\.dismiss) private var dismiss
      - var body: some View {
  Class: WorkoutMetricsView
    Properties:
      - let workoutManager: WatchWorkoutManager
      - var body: some View {
  Class: MetricRow
    Properties:
      - let icon: String
      - let value: String
      - let label: String
      - let color: Color
      - var body: some View {
  Class: WorkoutControlsView
    Properties:
      - let workoutManager: WatchWorkoutManager
      - let onEnd: () -> Void
      - @State private var showingEndConfirmation = false
      - var body: some View {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFitWatchApp/Views/ExerciseLoggingView.swift

---
Classes:
  Class: ExerciseLoggingView
    Properties:
      - let workoutManager: WatchWorkoutManager
      - @State private var showingExercisePicker = false
      - @State private var showingSetLogger = false
      - var currentExercise: ExerciseBuilderData? {
      - var body: some View {
  Class: CurrentExerciseCard
    Properties:
      - let exercise: ExerciseBuilderData
      - var body: some View {
  Class: RecentSetsView
    Properties:
      - let sets: [SetBuilderData]
      - var recentSets: [SetBuilderData] {
      - var body: some View {
  Class: ExercisePickerView
    Properties:
      - let onExerciseSelected: (ExerciseTemplate) -> Void
      - @Environment(\.dismiss) private var dismiss
      - private let exercises: [ExerciseTemplate] = [
 ExerciseTemplate(name: "Push-ups", muscleGroups: ["Chest", "Triceps"]), ExerciseTemplate(name: "Squats", muscleGroups: ["Legs", "Glutes"]), ExerciseTemplate(name: "Pull-ups", muscleGroups: ["Back", "Biceps"]), ExerciseTemplate(name: "Bench Press", muscleGroups: ["Chest", "Triceps"]), ExerciseTemplate(name: "Deadlift", muscleGroups: ["Back", "Legs"]), ExerciseTemplate(name: "Overhead Press", muscleGroups: ["Shoulders", "Triceps"])
      - var body: some View {
  Class: SetLoggerView
    Properties:
      - let onSetLogged: (Int?, Double?, TimeInterval?, Double?) -> Void
      - @Environment(\.dismiss) private var dismiss
      - @State private var reps: Int = 10
      - @State private var weight: Double = 20.0
      - @State private var duration: TimeInterval = 0
      - @State private var rpe: Double = 7.0
      - var body: some View {
  Class: ExerciseTemplate
    Properties:
      - let name: String
      - let muscleGroups: [String]
---


Path: /Users/Brian/Coding Projects/AirFit/AirFitWatchApp/Views/WorkoutStartView.swift

---
Classes:
  Class: WorkoutStartView
    Properties:
      - @State private var workoutManager = WatchWorkoutManager()
      - @State private var selectedActivity: HKWorkoutActivityType = .traditionalStrengthTraining
      - @State private var showingActiveWorkout = false
      - @State private var isRequestingPermission = false
      - private let activities: [HKWorkoutActivityType] = [
 .traditionalStrengthTraining, .functionalStrengthTraining, .running, .walking, .cycling, .swimming, .yoga, .coreTraining
      - var body: some View {
    Methods:
      - private func requestPermissions() async {
      - private func startWorkout() {
  Class: ActivityRow
    Properties:
      - let activity: HKWorkoutActivityType
      - let isSelected: Bool
      - let action: () -> Void
      - var body: some View {
      - var symbolName: String {
---


Path: /Users/Brian/Coding Projects/AirFit/AirFitWatchApp/AirFitWatchApp.swift

---
Classes:
  Class: AirFitWatchApp
    Properties:
      - var body: some Scene {
---

</Complete Definitions>
</file_map>


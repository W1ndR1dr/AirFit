<file_map>
/Users/Brian/Coding Projects/AirFit
├── .claude
│   └── settings.local.json
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
│   │   │   ├── MockAIAPIService.swift
│   │   │   ├── MockAIFunctionServices.swift
│   │   │   ├── MockAIService.swift
│   │   │   ├── MockDashboardServices.swift
│   │   │   ├── MockHealthKitManager.swift
│   │   │   ├── MockHealthKitPrefillProvider.swift
│   │   │   ├── MockLLMOrchestrator.swift
│   │   │   ├── MockNotificationManager.swift
│   │   │   ├── MockOnboardingService.swift
│   │   │   ├── MockUserService.swift
│   │   │   ├── MockVoiceInputManager.swift
│   │   │   ├── MockVoiceServices.swift
│   │   │   └── MockWhisperServiceWrapper.swift
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
│   │   │   ├── MockServicesTests.swift
│   │   │   ├── NetworkManagerTests.swift
│   │   │   ├── ServiceIntegrationTests.swift
│   │   │   ├── ServicePerformanceTests.swift
│   │   │   ├── ServiceProtocolsTests.swift
│   │   │   ├── TestDataGenerators.swift
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
│   │   │   ├── GlobalEnums.swift
│   │   │   └── MessageType.swift
│   │   ├── Extensions
│   │   │   ├── AIProvider+Extensions.swift
│   │   │   ├── Color+Extensions.swift
│   │   │   ├── Date+Extensions.swift
│   │   │   ├── Double+Extensions.swift
│   │   │   ├── String+Extensions.swift
│   │   │   ├── TimeInterval+Extensions.swift
│   │   │   ├── URLRequest+Extensions.swift
│   │   │   └── View+Extensions.swift
│   │   ├── Models
│   │   │   ├── AI
│   │   │   │   └── AIModels.swift
│   │   │   ├── HealthContextSnapshot.swift
│   │   │   ├── NutritionPreferences.swift
│   │   │   ├── ServiceTypes.swift
│   │   │   └── WorkoutBuilderData.swift
│   │   ├── Protocols
│   │   │   ├── AIAPIServiceProtocol.swift
│   │   │   ├── AIServiceProtocol.swift
│   │   │   ├── AnalyticsServiceProtocol.swift
│   │   │   ├── APIKeyManagementProtocol.swift
│   │   │   ├── APIKeyManagerProtocol.swift
│   │   │   ├── DashboardServiceProtocols.swift
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
│   │   │   ├── FetchDescriptor+Extensions.swift
│   │   │   └── ModelContainer+Testing.swift
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
│   ├── Docs
│   │   ├── IGNORE
│   │   │   ├── Archive
│   │   │   │   ├── Persona Refactor Tasks.md
│   │   │   │   ├── Persona Refactor.md
│   │   │   │   └── PersonaRefactorContext.md
│   │   │   └── Completed
│   │   │       ├── API_INTEGRATION_ANALYSIS.md
│   │   │       ├── CODEBASE_CONTEXT.md
│   │   │       ├── COMMON_COMMANDS.md
│   │   │       ├── HealthKitIntegration.md
│   │   │       ├── IMPLEMENTATION_CHECKLIST.md
│   │   │       ├── Module10_Compatibility_Analysis.md
│   │   │       ├── OnboardingFlow.md
│   │   │       ├── PERSONA_REFACTOR_EXECUTION_GUIDE.md
│   │   │       ├── Phase1_ConversationalFoundation.md
│   │   │       ├── Phase2_PersonaSynthesis.md
│   │   │       ├── Phase3_Integration_Complete.md
│   │   │       ├── Phase3_IntegrationTesting.md
│   │   │       ├── Phase4_Batch4.1_Complete.md
│   │   │       ├── Phase4_FinalImplementation.md
│   │   │       ├── Phase4_Implementation_Summary.md
│   │   │       ├── README.md
│   │   │       ├── START_HERE.md
│   │   │       ├── STATUS_AND_VISION.md
│   │   │       ├── SystemPrompt.md
│   │   │       └── Tuneup.md
│   │   ├── Research Reports
│   │   │   ├── Agents.md Report.md
│   │   │   ├── API Integration Report.md
│   │   │   ├── Architecture Cleanup Summary.md
│   │   │   ├── Claude Config Report.md
│   │   │   ├── Codex Optimization Report.md
│   │   │   └── MLX Whisper Integration Report.md
│   │   ├── Architecture Update Report.md
│   │   ├── ArchitectureAnalysis.md
│   │   ├── ArchitectureOverview.md
│   │   ├── CodeMap.md
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
│   │   ├── Module13.md
│   │   └── TESTING_GUIDELINES.md
│   ├── Modules
│   │   ├── AI
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
│   │   │   │   ├── DefaultAICoachService.swift
│   │   │   │   ├── DefaultDashboardNutritionService.swift
│   │   │   │   └── DefaultHealthKitService.swift
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
│   │   │       ├── MacroRingsView.swift
│   │   │       ├── NutritionSearchView.swift
│   │   │       ├── PhotoInputView.swift
│   │   │       ├── VoiceInputView.swift
│   │   │       └── WaterTrackingView.swift
│   │   ├── Notifications
│   │   │   ├── Coordinators
│   │   │   │   └── NotificationsCoordinator.swift
│   │   │   ├── Managers
│   │   │   │   ├── LiveActivityManager.swift
│   │   │   │   └── NotificationManager.swift
│   │   │   ├── Models
│   │   │   │   └── NotificationModels.swift
│   │   │   ├── Services
│   │   │   │   ├── EngagementEngine.swift
│   │   │   │   └── NotificationContentGenerator.swift
│   │   │   └── README.md
│   │   ├── Onboarding
│   │   │   ├── Coordinators
│   │   │   │   ├── ConversationCoordinator.swift
│   │   │   │   ├── OnboardingCoordinator.swift
│   │   │   │   └── OnboardingFlowCoordinator.swift
│   │   │   ├── Data
│   │   │   │   └── ConversationFlowData.swift
│   │   │   ├── Models
│   │   │   │   ├── ConversationTypes.swift
│   │   │   │   ├── OnboardingModels.swift
│   │   │   │   └── PersonalityInsights.swift
│   │   │   ├── Services
│   │   │   │   ├── ConversationAnalytics.swift
│   │   │   │   ├── ConversationFlowManager.swift
│   │   │   │   ├── ConversationPersistence.swift
│   │   │   │   ├── OfflinePersonaGenerator.swift
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
│   │   │   │   ├── AIProviderExtensions.swift
│   │   │   │   ├── PersonaSettingsModels.swift
│   │   │   │   ├── SettingsModels.swift
│   │   │   │   └── UserSettingsExtensions.swift
│   │   │   ├── Services
│   │   │   │   ├── BiometricAuthManager.swift
│   │   │   │   ├── NotificationManagerExtensions.swift
│   │   │   │   └── UserDataExporter.swift
│   │   │   ├── ViewModels
│   │   │   │   └── SettingsViewModel.swift
│   │   │   ├── Views
│   │   │   │   ├── Components
│   │   │   │   │   └── SettingsComponents.swift
│   │   │   │   ├── AIPersonaSettingsView.swift
│   │   │   │   ├── APIConfigurationView.swift
│   │   │   │   ├── APIKeyEntryView.swift
│   │   │   │   ├── AppearanceSettingsView.swift
│   │   │   │   ├── DataManagementView.swift
│   │   │   │   ├── NotificationPreferencesView.swift
│   │   │   │   ├── PrivacySecurityView.swift
│   │   │   │   ├── SettingsListView.swift
│   │   │   │   └── UnitsSettingsView.swift
│   │   │   └── README.md
│   │   └── Workouts
│   │       ├── Coordinators
│   │       │   └── WorkoutCoordinator.swift
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
│   │   │   ├── AIAPIService.swift
│   │   │   ├── AIRequestBuilder.swift
│   │   │   ├── AIResponseCache.swift
│   │   │   ├── AIResponseParser.swift
│   │   │   ├── EnhancedAIAPIService.swift
│   │   │   ├── LLMOrchestrator.swift
│   │   │   ├── MockAIService.swift
│   │   │   ├── ProductionAIService.swift
│   │   │   ├── SimpleMockAIService.swift
│   │   │   └── UnifiedAIService.swift
│   │   ├── Cache
│   │   │   └── OnboardingCache.swift
│   │   ├── Context
│   │   │   └── ContextAssembler.swift
│   │   ├── Health
│   │   │   ├── HealthKitDataFetcher.swift
│   │   │   ├── HealthKitDataTypes.swift
│   │   │   ├── HealthKitExtensions.swift
│   │   │   ├── HealthKitManager.swift
│   │   │   └── HealthKitSleepAnalyzer.swift
│   │   ├── MockServices
│   │   │   ├── MockAIAPIService.swift
│   │   │   ├── MockAPIKeyManager.swift
│   │   │   ├── MockNetworkManager.swift
│   │   │   └── MockWeatherService.swift
│   │   ├── Monitoring
│   │   │   └── ProductionMonitor.swift
│   │   ├── Network
│   │   │   ├── NetworkClient.swift
│   │   │   ├── NetworkManager.swift
│   │   │   └── RequestOptimizer.swift
│   │   ├── Security
│   │   │   ├── DefaultAPIKeyManager.swift
│   │   │   └── KeychainHelper.swift
│   │   ├── Speech
│   │   │   ├── VoiceInputManager.swift
│   │   │   └── WhisperModelManager.swift
│   │   ├── User
│   │   │   └── DefaultUserService.swift
│   │   ├── ExerciseDatabase.swift
│   │   ├── ServiceConfiguration.swift
│   │   ├── ServiceRegistry.swift
│   │   ├── WeatherService.swift
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
├── Scripts
│   ├── add_files_to_xcode.sh
│   ├── fix_targets.sh
│   ├── test_module8_integration.sh
│   ├── validate-tuneup.sh
│   ├── verify_module_tests.sh
│   ├── verify_module8_integration.sh
│   └── verify_module10.sh
├── .cursorrules
├── .gitignore
├── AGENTS.md
├── CLAUDE.md
├── envsetupscript.sh
├── Manual.md
├── package.json
├── PROJECT_FILE_MANAGEMENT.md
└── project.yml

</file_map>


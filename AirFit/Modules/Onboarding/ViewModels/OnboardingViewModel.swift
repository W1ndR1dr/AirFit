import Foundation
import SwiftData
import Observation
import Combine

// MARK: - HealthKit Prefill Protocol
protocol HealthKitPrefillProviding: AnyObject, Sendable {
    func fetchTypicalSleepWindow() async throws -> (bed: Date, wake: Date)?
    func fetchCurrentWeight() async throws -> Double?
}

// MARK: - ViewModel
@MainActor
@Observable
final class OnboardingViewModel: ErrorHandling {
    // MARK: - Navigation State
    
    internal(set) var currentScreen: OnboardingScreen = .opening
    internal(set) var isLoading = false
    var error: AppError?
    var isShowingError = false
    
    // MARK: - Progress
    var progress: Double {
        return currentScreen.progress
    }

    // MARK: - Collected Data
    var userName: String = ""
    var lifeContext: String = ""
    var currentWeight: Double?
    var targetWeight: Double?
    var bodyRecompositionGoals: [BodyRecompositionGoal] = []
    var functionalGoalsText: String = ""
    var communicationStyles: [CommunicationStyle] = []
    var informationPreferences: [InformationStyle] = []
    var sleepWindow: SleepWindow = SleepWindow()
    var hasHealthKitIntegration: Bool = false
    
    // MARK: - Synthesis Results
    internal(set) var synthesizedGoals: LLMGoalSynthesis?
    internal(set) var generatedPersona: PersonaProfile?
    
    // MARK: - HealthKit
    internal(set) var healthKitData: HealthKitSnapshot?
    internal(set) var healthKitAuthorizationStatus: HealthKitAuthorizationStatus = .notDetermined
    
    // MARK: - Voice Input
    var isTranscribing = false
    
    // MARK: - Weight Text Input
    var currentWeightText: String = ""
    var targetWeightText: String = ""
    
    // MARK: - Loading States
    var isHealthKitLoading = false
    var synthesisProgress: Double = 0.0
    
    // MARK: - Synthesis Task
    private var synthesisTask: Task<Void, Never>?

    // MARK: - Dependencies
    let aiService: AIServiceProtocol
    let onboardingService: OnboardingServiceProtocol
    var modelContext: ModelContext
    let speechService: WhisperServiceWrapperProtocol?
    let healthPrefillProvider: HealthKitPrefillProviding?
    let healthKitAuthManager: HealthKitAuthManager
    let userService: UserServiceProtocol
    let personaService: PersonaService
    let analytics: ConversationAnalytics
    let onboardingLLMService: OnboardingLLMService?

    // MARK: - Completion Callback
    var onCompletionCallback: (() -> Void)?

    // MARK: - Initialization
    init(
        aiService: AIServiceProtocol,
        onboardingService: OnboardingServiceProtocol,
        modelContext: ModelContext,
        userService: UserServiceProtocol,
        personaService: PersonaService,
        speechService: WhisperServiceWrapperProtocol? = nil,
        healthPrefillProvider: HealthKitPrefillProviding? = nil,
        healthKitAuthManager: HealthKitAuthManager,
        analytics: ConversationAnalytics = ConversationAnalytics(),
        onboardingLLMService: OnboardingLLMService? = nil
    ) {
        self.aiService = aiService
        self.onboardingService = onboardingService
        self.modelContext = modelContext
        self.userService = userService
        self.personaService = personaService
        self.speechService = speechService
        self.healthPrefillProvider = healthPrefillProvider
        self.healthKitAuthManager = healthKitAuthManager
        self.analytics = analytics
        self.onboardingLLMService = onboardingLLMService
    }

    // MARK: - Navigation
    
    func beginOnboarding() {
        currentScreen = .healthKit
        // Track analytics event
        // await analytics.trackEvent(.onboardingStarted)
    }
    
    func navigateToNext() {
        HapticService.impact(.light)
        
        switch currentScreen {
        case .opening:
            currentScreen = .healthKit
        case .healthKit:
            currentScreen = .lifeContext
        case .lifeContext:
            currentScreen = .goals
        case .goals:
            currentScreen = .weightObjectives
        case .weightObjectives:
            currentScreen = .bodyComposition
        case .bodyComposition:
            currentScreen = .communicationStyle
        case .communicationStyle:
            synthesisTask = Task { await synthesizePersona() }
        case .synthesis:
            currentScreen = .coachReady
        case .coachReady:
            Task { await completeOnboarding() }
        }
        
        // Track state transition
        // await analytics.trackEvent(.stateTransition, properties: ["from": currentScreen.rawValue, "to": currentScreen.rawValue])
    }
    
    func navigateToPrevious() {
        HapticService.impact(.light)
        
        switch currentScreen {
        case .opening:
            break
        case .healthKit:
            currentScreen = .opening
        case .lifeContext:
            currentScreen = .healthKit
        case .goals:
            currentScreen = .lifeContext
        case .weightObjectives:
            currentScreen = .goals
        case .bodyComposition:
            currentScreen = .weightObjectives
        case .communicationStyle:
            currentScreen = .bodyComposition
        case .synthesis:
            synthesisTask?.cancel()
            synthesisTask = nil
            isLoading = false
            currentScreen = .communicationStyle
        case .coachReady:
            currentScreen = .communicationStyle
        }
    }

    // MARK: - HealthKit
    // HealthKit methods moved to OnboardingViewModel+HealthKit.swift

    // MARK: - Voice Input
    // Voice input methods moved to OnboardingViewModel+Voice.swift

    // MARK: - Multi-Select Helpers
    // Multi-select methods moved to OnboardingViewModel+MultiSelect.swift

    // MARK: - Synthesis
    // Synthesis methods moved to OnboardingViewModel+PersonaSynthesis.swift

    // MARK: - Goal Parsing
    // Goal parsing and synthesis methods moved to OnboardingViewModel+Synthesis.swift

    // MARK: - Completion & Error Handling
    // Completion and error handling methods moved to OnboardingViewModel+Completion.swift
}

// MARK: - Supporting Types
// All supporting types moved to OnboardingViewModel+Types.swift

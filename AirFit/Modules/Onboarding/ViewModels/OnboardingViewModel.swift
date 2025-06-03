import Foundation
import SwiftData
import Observation
import Combine


// MARK: - HealthKit Prefill Protocol
protocol HealthKitPrefillProviding: AnyObject, Sendable {
    func fetchTypicalSleepWindow() async throws -> (bed: Date, wake: Date)?
}

// MARK: - ViewModel
@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: - Onboarding Flow State
    enum OnboardingMode {
        case legacy          // Old 4-persona form flow
        case conversational  // New AI conversation flow
    }
    
    // MARK: - Navigation State
    private(set) var currentScreen: OnboardingScreen = .openingScreen
    private(set) var isLoading = false
    var error: Error?
    
    // MARK: - Integration State
    private(set) var mode: OnboardingMode = .conversational
    private(set) var orchestratorState: OnboardingState = .notStarted
    private(set) var orchestratorProgress: OnboardingProgress = .init()
    private var orchestrator: OnboardingOrchestrator?

    // MARK: - Collected Data (Phase 4 Refactored - uses PersonaMode)
    var lifeContext = LifeContext()
    var goal = Goal()
    var selectedPersonaMode: PersonaMode = .supportiveCoach  // Phase 4: Discrete persona selection
    var engagementPreferences = EngagementPreferences()
    var sleepWindow = SleepWindow()
    var motivationalStyle = MotivationalStyle()
    var timezone: String = TimeZone.current.identifier
    var baselineModeEnabled = true

    // MARK: - Voice Input
    private(set) var isTranscribing = false

    // MARK: - HealthKit Integration
    var hasHealthKitIntegration: Bool {
        healthPrefillProvider != nil
    }
    private(set) var healthKitAuthorizationStatus: HealthKitAuthorizationStatus = .notDetermined

    // MARK: - Dependencies
    private let aiService: AIServiceProtocol
    private let onboardingService: OnboardingServiceProtocol
    private let modelContext: ModelContext
    private let speechService: WhisperServiceWrapperProtocol?
    private let healthPrefillProvider: HealthKitPrefillProviding?
    private let healthKitAuthManager: HealthKitAuthManager
    private let apiKeyManager: APIKeyManagementProtocol
    private let userService: UserServiceProtocol
    private let analytics: ConversationAnalytics

    // MARK: - Completion Callback
    var onCompletionCallback: (() -> Void)?

    // MARK: - Initialization
    init(
        aiService: AIServiceProtocol,
        onboardingService: OnboardingServiceProtocol,
        modelContext: ModelContext,
        apiKeyManager: APIKeyManagementProtocol,
        userService: UserServiceProtocol,
        speechService: WhisperServiceWrapperProtocol? = nil,
        healthPrefillProvider: HealthKitPrefillProviding? = nil,
        healthKitAuthManager: HealthKitAuthManager = HealthKitAuthManager(),
        analytics: ConversationAnalytics = ConversationAnalytics(),
        mode: OnboardingMode = .conversational
    ) {
        self.aiService = aiService
        self.onboardingService = onboardingService
        self.modelContext = modelContext
        self.apiKeyManager = apiKeyManager
        self.userService = userService
        self.speechService = speechService
        self.healthPrefillProvider = healthPrefillProvider
        self.healthKitAuthManager = healthKitAuthManager
        self.analytics = analytics
        self.mode = mode
        self.healthKitAuthorizationStatus = healthKitAuthManager.authorizationStatus

        // Initialize orchestrator if using conversational mode
        if mode == .conversational {
            setupOrchestrator()
        }

        Task { await prefillFromHealthKit() }
    }
    
    // MARK: - Orchestrator Setup
    private func setupOrchestrator() {
        orchestrator = OnboardingOrchestrator(
            modelContext: modelContext,
            apiKeyManager: apiKeyManager,
            userService: userService,
            analytics: analytics
        )
        
        // Observe orchestrator state changes
        Task {
            for await state in orchestrator!.$state.values {
                orchestratorState = state
                handleOrchestratorStateChange(state)
            }
        }
        
        // Observe progress changes
        Task {
            for await progress in orchestrator!.$progress.values {
                orchestratorProgress = progress
            }
        }
    }
    
    private func handleOrchestratorStateChange(_ state: OnboardingState) {
        switch state {
        case .completed:
            onCompletionCallback?()
        case .error(let error):
            self.error = error
        default:
            break
        }
    }

    // MARK: - Navigation
    func navigateToNextScreen() {
        // Legacy mode navigation
        guard mode == .legacy else { return }
        
        guard let index = OnboardingScreen.allCases.firstIndex(of: currentScreen),
              index < OnboardingScreen.allCases.count - 1 else { return }
        currentScreen = OnboardingScreen.allCases[index + 1]
        AppLogger.info("Navigated to \(currentScreen)", category: .onboarding)
    }

    func navigateToPreviousScreen() {
        // Legacy mode navigation
        guard mode == .legacy else { return }
        
        guard let index = OnboardingScreen.allCases.firstIndex(of: currentScreen),
              index > 0 else { return }
        currentScreen = OnboardingScreen.allCases[index - 1]
        AppLogger.info("Navigated back to \(currentScreen)", category: .onboarding)
    }
    
    // MARK: - Conversational Mode Methods
    func startConversationalOnboarding(userId: UUID) async throws {
        guard mode == .conversational,
              let orchestrator = orchestrator else {
            throw OnboardingOrchestratorError.invalidStateTransition
        }
        
        try await orchestrator.startOnboarding(userId: userId)
    }
    
    func pauseConversation() {
        orchestrator?.pauseOnboarding()
    }
    
    func resumeConversation() async throws {
        try await orchestrator?.resumeOnboarding()
    }
    
    func completeConversationalOnboarding() async throws {
        try await orchestrator?.completeOnboarding()
    }
    
    func adjustPersona(_ adjustments: PersonaAdjustments) async throws {
        try await orchestrator?.adjustPersona(adjustments)
    }
    
    // MARK: - Mode Switching
    func switchToLegacyMode() {
        mode = .legacy
        orchestrator = nil
        currentScreen = .openingScreen
    }
    
    func switchToConversationalMode() {
        mode = .conversational
        setupOrchestrator()
    }

    // MARK: - Voice Input
    func startVoiceCapture() {
        guard let speechService else { return }
        speechService.requestPermission { [weak self] granted in
            guard let self else { return }
            guard granted else { return }
            self.isTranscribing = true
            speechService.startTranscription { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isTranscribing = false
                    switch result {
                    case .success(let transcript):
                        self.goal.rawText = transcript
                    case .failure(let error):
                        self.error = error
                        AppLogger.error("Voice transcription failed", error: error, category: .onboarding)
                    }
                }
            }
        }
    }

    func stopVoiceCapture() {
        speechService?.stopTranscription()
        isTranscribing = false
    }

    // MARK: - HealthKit Authorization
    func requestHealthKitAuthorization() async {
        let granted = await healthKitAuthManager.requestAuthorizationIfNeeded()
        healthKitAuthorizationStatus = healthKitAuthManager.authorizationStatus
        if granted {
            AppLogger.info("HealthKit authorization granted", category: .health)
        } else {
            AppLogger.warning("HealthKit authorization not granted", category: .health)
        }
    }

    // MARK: - Business Logic
    func analyzeGoalText() async {
        // Goal analysis is handled by the AI coach after onboarding completion
        // The raw text is sufficient for the USER_PROFILE_JSON_BLOB
        AppLogger.info("Goal text captured: \(goal.rawText)", category: .onboarding)
    }

    func completeOnboarding() async throws {
        switch mode {
        case .conversational:
            // Conversational mode is handled by the orchestrator
            try await completeConversationalOnboarding()
            
        case .legacy:
            // Legacy form-based flow
            isLoading = true
            defer { isLoading = false }

            let profileBlob = buildUserProfile()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(profileBlob)

            let profile = OnboardingProfile(
                personaPromptData: data,
                communicationPreferencesData: data,
                rawFullProfileData: data
            )
            
            // Let the service handle all SwiftData operations to avoid conflicts
            try await onboardingService.saveProfile(profile)

            AppLogger.info(
                "Legacy onboarding completed successfully with persona: \(selectedPersonaMode.displayName) (mode: \(selectedPersonaMode.rawValue), goal: \(goal.family.rawValue))", 
                category: .onboarding
            )

            // Notify completion
            onCompletionCallback?()
        }
    }

    // MARK: - Persona Selection Helpers (Phase 4)
    
    /// Preview text for selected persona mode
    var personaPreviewText: String {
        return selectedPersonaMode.description
    }
    
    /// Check if user has made persona selection
    var hasSelectedPersona: Bool {
        return true  // PersonaMode always has a valid default
    }

    /// Validate persona selection (replaces validateBlend)
    func validatePersonaSelection() {
        // PersonaMode enum ensures valid selection by design
        // No validation needed - type safety handles this
        AppLogger.info("Persona validated: \(selectedPersonaMode.displayName)", category: .onboarding)
    }

    // Legacy method name for UI compatibility during transition
    func validateBlend() {
        validatePersonaSelection()
    }

    // MARK: - Private Helpers
    private func prefillFromHealthKit() async {
        guard let provider = healthPrefillProvider else { return }
        do {
            if let window = try await provider.fetchTypicalSleepWindow() {
                sleepWindow.bedTime = Self.formatTime(window.bed)
                sleepWindow.wakeTime = Self.formatTime(window.wake)
            }
        } catch {
            AppLogger.error("HealthKit prefill failed", error: error, category: .health)
        }
    }

    private func buildUserProfile() -> UserProfileJsonBlob {
        // Phase 4: Use new PersonaMode-based initializer
        return PersonaMigrationUtility.createNewProfile(
            lifeContext: lifeContext,
            goal: goal,
            selectedPersonaMode: selectedPersonaMode,
            engagementPreferences: engagementPreferences,
            sleepWindow: sleepWindow,
            motivationalStyle: motivationalStyle,
            timezone: timezone
        )
    }

    private static func formatTime(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Phase 4 Refactor Complete
//
// ✅ ELIMINATED:
// - blend: Blend property (replaced with selectedPersonaMode: PersonaMode)  
// - validateBlend() method (no longer needed with discrete personas)
// - Complex blend calculation and normalization logic
//
// ✅ REPLACED WITH:
// - selectedPersonaMode: PersonaMode with clear, discrete options
// - PersonaMode.allCases for simple UI iteration
// - PersonaMigrationUtility.createNewProfile() for clean profile creation
// - Built-in validation through enum type safety

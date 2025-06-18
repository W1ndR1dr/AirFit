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
    enum OnboardingScreen: String, CaseIterable {
        case opening
        case healthKit
        case lifeContext
        case goals
        case communicationStyle
        case synthesis
        case coachReady
        
        var title: String {
            switch self {
            case .opening: return "Welcome"
            case .healthKit: return "Health Data"
            case .lifeContext: return "About You"
            case .goals: return "Your Goals"
            case .communicationStyle: return "Coaching Style"
            case .synthesis: return "Creating Coach"
            case .coachReady: return "Coach Ready"
            }
        }
    }
    
    private(set) var currentScreen: OnboardingScreen = .opening
    private(set) var isLoading = false
    var error: AppError?
    var isShowingError = false
    
    // MARK: - Progress
    var progress: Double {
        let screens = OnboardingScreen.allCases
        guard let currentIndex = screens.firstIndex(of: currentScreen) else { return 0 }
        return Double(currentIndex) / Double(screens.count - 1)
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
    private(set) var synthesizedGoals: LLMGoalSynthesis?
    private(set) var generatedPersona: PersonaProfile?
    
    // MARK: - HealthKit
    private(set) var healthKitData: HealthKitSnapshot?
    private(set) var healthKitAuthorizationStatus: HealthKitAuthorizationStatus = .notDetermined
    
    // MARK: - Voice Input
    private(set) var isTranscribing = false

    // MARK: - Dependencies
    private let aiService: AIServiceProtocol
    private let onboardingService: OnboardingServiceProtocol
    private var modelContext: ModelContext
    private let speechService: WhisperServiceWrapperProtocol?
    private let healthPrefillProvider: HealthKitPrefillProviding?
    private let healthKitAuthManager: HealthKitAuthManager
    private let userService: UserServiceProtocol
    private let personaService: PersonaService
    private let analytics: ConversationAnalytics

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
        analytics: ConversationAnalytics = ConversationAnalytics()
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
            currentScreen = .communicationStyle
        case .communicationStyle:
            Task { await synthesizePersona() }
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
        case .communicationStyle:
            currentScreen = .goals
        case .synthesis:
            currentScreen = .communicationStyle
        case .coachReady:
            currentScreen = .communicationStyle
        }
    }

    // MARK: - HealthKit
    
    func requestHealthKitAuthorization() async {
        let granted = await healthKitAuthManager.requestAuthorizationIfNeeded()
        healthKitAuthorizationStatus = healthKitAuthManager.authorizationStatus
        
        if granted {
            await fetchHealthKitData()
        }
        
        // Track health kit authorization
        // await analytics.trackEvent(.stateTransition, properties: ["type": "healthKitAuthorization", "granted": granted])
    }
    
    private func fetchHealthKitData() async {
        guard let provider = healthPrefillProvider else { return }
        
        do {
            // Fetch weight
            if let weight = try await provider.fetchCurrentWeight() {
                currentWeight = weight
            }
            
            // Fetch sleep patterns
            if let sleepData = try await provider.fetchTypicalSleepWindow() {
                // Convert to SleepWindow format
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                sleepWindow.bedTime = formatter.string(from: sleepData.bed)
                sleepWindow.wakeTime = formatter.string(from: sleepData.wake)
            }
            
            // Create snapshot
            healthKitData = HealthKitSnapshot(
                weight: currentWeight,
                height: nil, // Add if needed
                age: nil, // Add if needed
                sleepSchedule: nil // Add if needed
            )
        } catch {
            AppLogger.error("Failed to fetch HealthKit data", error: error, category: .health)
        }
    }

    // MARK: - Voice Input
    
    func startVoiceCapture(for field: VoiceInputField) {
        guard let speechService else { return }
        
        speechService.requestPermission { [weak self] granted in
            guard let self, granted else { return }
            
            self.isTranscribing = true
            speechService.startTranscription { [weak self] result in
                guard let self else { return }
                
                DispatchQueue.main.async {
                    self.isTranscribing = false
                    
                    switch result {
                    case .success(let transcript):
                        switch field {
                        case .lifeContext:
                            self.lifeContext = transcript
                        case .functionalGoals:
                            self.functionalGoalsText = transcript
                        }
                    case .failure(let error):
                        self.handleError(error)
                    }
                }
            }
        }
    }
    
    func stopVoiceCapture() {
        speechService?.stopTranscription()
        isTranscribing = false
    }
    
    enum VoiceInputField {
        case lifeContext
        case functionalGoals
    }

    // MARK: - Multi-Select Helpers
    
    func toggleBodyRecompositionGoal(_ goal: BodyRecompositionGoal) {
        if bodyRecompositionGoals.contains(goal) {
            bodyRecompositionGoals.removeAll { $0 == goal }
        } else {
            bodyRecompositionGoals.append(goal)
        }
    }
    
    func toggleCommunicationStyle(_ style: CommunicationStyle) {
        if communicationStyles.contains(style) {
            communicationStyles.removeAll { $0 == style }
        } else {
            communicationStyles.append(style)
        }
    }
    
    func toggleInformationPreference(_ pref: InformationStyle) {
        if informationPreferences.contains(pref) {
            informationPreferences.removeAll { $0 == pref }
        } else {
            informationPreferences.append(pref)
        }
    }

    // MARK: - Synthesis
    
    private func synthesizePersona() async {
        currentScreen = .synthesis
        isLoading = true
        error = nil
        
        do {
            // Create weight objective
            let weightObjective = WeightObjective(
                currentWeight: currentWeight,
                targetWeight: targetWeight,
                timeframe: nil
            )
            
            // Build raw data for synthesis
            let rawData = OnboardingRawData(
                userName: userName.isEmpty ? "Friend" : userName,
                lifeContextText: lifeContext,
                weightObjective: weightObjective,
                bodyRecompositionGoals: bodyRecompositionGoals,
                functionalGoalsText: functionalGoalsText,
                communicationStyles: communicationStyles,
                informationPreferences: informationPreferences,
                healthKitData: healthKitData,
                manualHealthData: nil
            )
            
            // Synthesize goals with LLM
            synthesizedGoals = try await onboardingService.synthesizeGoals(from: rawData)
            
            // Generate persona
            guard let userId = await userService.getCurrentUserId() else {
                throw AppError.authentication("No user ID found")
            }
            
            let session = ConversationSession(
                userId: userId,
                startedAt: Date()
            )
            session.responses = createResponsesFromData(rawData)
            
            generatedPersona = try await personaService.generatePersona(from: session)
            
            // Show coach ready screen
            currentScreen = .coachReady
            
        } catch {
            self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
            isShowingError = true
        }
        
        isLoading = false
    }
    
    private func createResponsesFromData(_ data: OnboardingRawData) -> [ConversationResponse] {
        var responses: [ConversationResponse] = []
        let sessionId = UUID()
        
        // Helper to create response
        func addResponse(nodeId: String, value: ResponseValue) {
            let response = ConversationResponse(
                sessionId: sessionId,
                nodeId: nodeId,
                responseData: try! JSONEncoder().encode(value)
            )
            responses.append(response)
        }
        
        // Add responses
        addResponse(nodeId: "userName", value: .text(data.userName))
        addResponse(nodeId: "lifeContext", value: .text(data.lifeContextText))
        addResponse(nodeId: "functionalGoals", value: .text(data.functionalGoalsText))
        
        if let weight = data.weightObjective {
            if let current = weight.currentWeight {
                addResponse(nodeId: "currentWeight", value: .text("\(current)"))
            }
            if let target = weight.targetWeight {
                addResponse(nodeId: "targetWeight", value: .text("\(target)"))
            }
        }
        
        addResponse(nodeId: "bodyGoals", value: .multiChoice(data.bodyRecompositionGoals.map(\.rawValue)))
        addResponse(nodeId: "communicationStyles", value: .multiChoice(data.communicationStyles.map(\.rawValue)))
        addResponse(nodeId: "informationPreferences", value: .multiChoice(data.informationPreferences.map(\.rawValue)))
        
        return responses
    }

    // MARK: - Completion
    
    private func completeOnboarding() async {
        guard let persona = generatedPersona,
              let userId = await userService.getCurrentUserId() else {
            error = .validationError(message: "Missing persona or user")
            isShowingError = true
            return
        }
        
        isLoading = true
        
        do {
            // Save persona
            try await personaService.savePersona(persona, for: userId)
            
            // Update user with coach persona
            let coachPersona = CoachPersona(from: persona)
            try await userService.setCoachPersona(coachPersona)
            
            // Complete onboarding
            try await userService.completeOnboarding()
            
            // Track completion
            // Track completion
            // await analytics.trackEvent(.onboardingCompleted)
            
            // Notify completion
            onCompletionCallback?()
            
        } catch {
            self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
            isShowingError = true
        }
        
        isLoading = false
    }

    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        self.error = error as? AppError ?? .unknown(message: error.localizedDescription)
        isShowingError = true
        HapticService.play(.error)
    }
    
    func clearError() {
        error = nil
        isShowingError = false
    }
}

// MARK: - Supporting Types

struct HealthKitSnapshot: Codable, Sendable {
    let weight: Double?
    let height: Double?
    let age: Int?
    let sleepSchedule: SleepSchedule?
}

struct SleepSchedule: Codable, Sendable {
    let bedtime: Date
    let waketime: Date
}


// Communication styles from the enhancement doc
enum CommunicationStyle: String, Codable, CaseIterable {
    case encouraging = "encouraging_supportive"
    case direct = "direct_no_nonsense"
    case analytical = "data_driven_analytical"
    case motivational = "energetic_motivational"
    case patient = "patient_understanding"
    case challenging = "challenging_pushing"
    case educational = "educational_explanatory"
    case playful = "playful_humorous"
    
    var displayName: String {
        switch self {
        case .encouraging: return "Encouraging and supportive"
        case .direct: return "Direct and no-nonsense"
        case .analytical: return "Data-driven and analytical"
        case .motivational: return "Energetic and motivational"
        case .patient: return "Patient with setbacks"
        case .challenging: return "Challenging and pushing"
        case .educational: return "Educational and explanatory"
        case .playful: return "Playful and fun"
        }
    }
    
    var description: String {
        switch self {
        case .encouraging: return "\"You've got this!\""
        case .direct: return "\"Here's what needs to happen\""
        case .analytical: return "\"Let's look at the numbers\""
        case .motivational: return "\"Let's crush these goals!\""
        case .patient: return "\"Progress isn't always linear\""
        case .challenging: return "\"I know you can do better\""
        case .educational: return "\"Here's why this works\""
        case .playful: return "\"Fitness doesn't have to be serious!\""
        }
    }
}

enum InformationStyle: String, Codable, CaseIterable {
    case detailed = "detailed_explanations"
    case keyMetrics = "key_metrics_only"
    case celebrations = "progress_celebrations"
    case educational = "educational_content"
    case quickCheckins = "quick_check_ins"
    case inDepthAnalysis = "in_depth_analysis"
    case essentials = "just_essentials"
    
    var displayName: String {
        switch self {
        case .detailed: return "Detailed explanations"
        case .keyMetrics: return "Key metrics only"
        case .celebrations: return "Progress celebrations"
        case .educational: return "Educational content"
        case .quickCheckins: return "Quick check-ins"
        case .inDepthAnalysis: return "In-depth analysis"
        case .essentials: return "Just the essentials"
        }
    }
}

// Analytics events are defined in OnboardingState.swift
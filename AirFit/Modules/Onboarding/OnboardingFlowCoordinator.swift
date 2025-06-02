import SwiftUI
import SwiftData

/// Main coordinator for the entire onboarding flow
@MainActor
final class OnboardingFlowCoordinator: ObservableObject {
    // MARK: - State
    @Published var currentView: OnboardingView = .welcome
    @Published var isLoading = false
    @Published var error: Error?
    @Published var progress: Double = 0
    
    // MARK: - Services
    let conversationFlowManager: ConversationFlowManager
    private let personaService: PersonaService
    private let userService: UserServiceProtocol
    let modelContext: ModelContext
    
    // MARK: - Data
    private var conversationSession: ConversationSession?
    @Published private(set) var generatedPersona: CoachPersona?
    let user: User
    
    init(
        modelContext: ModelContext,
        user: User,
        userService: UserServiceProtocol,
        apiKeyManager: APIKeyManagerProtocol
    ) {
        self.modelContext = modelContext
        self.user = user
        self.userService = userService
        
        // Initialize conversation flow manager
        let flowData = ConversationFlowData.defaultFlow()
        self.conversationFlowManager = ConversationFlowManager(
            flowDefinition: flowData,
            modelContext: modelContext,
            responseAnalyzer: ResponseAnalyzerImpl()
        )
        
        // Initialize persona service
        let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        let synthesizer = PersonaSynthesizer(llmOrchestrator: llmOrchestrator)
        self.personaService = PersonaService(
            synthesizer: synthesizer,
            llmOrchestrator: llmOrchestrator,
            modelContext: modelContext
        )
    }
    
    // MARK: - Navigation
    
    func start() {
        currentView = .welcome
        progress = 0
    }
    
    func proceedFromWelcome() async {
        await beginConversation()
    }
    
    func beginConversation() async {
        currentView = .conversation
        progress = 0.1
        
        do {
            conversationSession = try await conversationFlowManager.startNewSession(userId: user.id)
        } catch {
            await handleError(error)
        }
    }
    
    func completeConversation() async {
        guard let session = conversationSession else {
            await handleError(OnboardingError.noSession)
            return
        }
        
        isLoading = true
        currentView = .generatingPersona
        progress = 0.6
        
        do {
            // Generate persona from conversation
            generatedPersona = try await personaService.generatePersona(from: session)
            
            // Show preview
            currentView = .personaPreview
            progress = 0.8
            
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func acceptPersona() async {
        guard let persona = generatedPersona else {
            await handleError(OnboardingError.noPersona)
            return
        }
        
        isLoading = true
        progress = 0.9
        
        do {
            // Save persona to user profile
            try await personaService.savePersona(persona, for: user)
            
            // Mark onboarding as complete
            try await userService.completeOnboarding()
            
            // Done!
            currentView = .complete
            progress = 1.0
            
            // Trigger haptic feedback
            HapticManager.success()
            
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func adjustPersona(_ adjustment: String) async {
        guard let currentPersona = generatedPersona else {
            await handleError(OnboardingError.noPersona)
            return
        }
        
        isLoading = true
        
        do {
            // Apply adjustment
            generatedPersona = try await personaService.adjustPersona(
                currentPersona,
                adjustment: adjustment
            )
            
            // Refresh the preview
            objectWillChange.send()
            
        } catch {
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func regeneratePersona() async {
        // Re-run persona generation with same conversation data
        await completeConversation()
    }
    
    // MARK: - Helper Methods
    
    private func handleError(_ error: Error) async {
        self.error = error
        HapticManager.error()
        
        // Log error
        AppLogger.error("Onboarding error: \(error.localizedDescription)", category: .onboarding)
        
        // Show error view based on type
        if error is OnboardingError {
            // Stay on current view and show error
        } else {
            // Show generic error view
            currentView = .error(error)
        }
    }
    
    func dismissError() {
        error = nil
    }
    
    func restartOnboarding() {
        conversationSession = nil
        generatedPersona = nil
        error = nil
        progress = 0
        start()
    }
}

// MARK: - Onboarding Views

enum OnboardingView: Equatable {
    case welcome
    case conversation
    case generatingPersona
    case personaPreview
    case complete
    case error(Error)
    
    static func == (lhs: OnboardingView, rhs: OnboardingView) -> Bool {
        switch (lhs, rhs) {
        case (.welcome, .welcome),
             (.conversation, .conversation),
             (.generatingPersona, .generatingPersona),
             (.personaPreview, .personaPreview),
             (.complete, .complete):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .welcome:
            return "Welcome"
        case .conversation:
            return "Let's Chat"
        case .generatingPersona:
            return "Creating Your Coach"
        case .personaPreview:
            return "Meet Your Coach"
        case .complete:
            return "All Set!"
        case .error:
            return "Oops"
        }
    }
}

// MARK: - Onboarding Errors

enum OnboardingError: LocalizedError {
    case noSession
    case noPersona
    case personaGenerationFailed(String)
    case saveFailed(String)
    case networkError
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active conversation session"
        case .noPersona:
            return "No persona has been generated yet"
        case .personaGenerationFailed(let reason):
            return "Failed to create your personalized coach: \(reason)"
        case .saveFailed(let reason):
            return "Failed to save your settings: \(reason)"
        case .networkError:
            return "Network connection issue. Please check your internet and try again."
        case .userCancelled:
            return "Onboarding was cancelled"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noSession, .noPersona:
            return "Please restart the onboarding process"
        case .personaGenerationFailed:
            return "Try regenerating your coach or adjusting the settings"
        case .saveFailed:
            return "Please try again or contact support if the issue persists"
        case .networkError:
            return "Check your connection and try again"
        case .userCancelled:
            return "You can restart onboarding anytime from settings"
        }
    }
}
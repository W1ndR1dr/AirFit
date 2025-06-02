import SwiftUI
import SwiftData
import UIKit

@MainActor
@Observable
final class OnboardingFlowCoordinator {
    // MARK: - State
    var currentView: OnboardingView = .welcome
    var isLoading = false
    var error: Error?
    var progress: Double = 0.0
    
    // MARK: - Services
    private let conversationManager: ConversationFlowManager
    private let personaService: PersonaService
    private let userService: UserServiceProtocol
    private let modelContext: ModelContext
    
    // MARK: - Data
    private(set) var conversationSession: ConversationSession?
    private(set) var generatedPersona: PersonaProfile?
    
    // Performance optimization
    private let cache = OnboardingCache()
    private var memoryWarningObserver: NSObjectProtocol?
    
    init(
        conversationManager: ConversationFlowManager,
        personaService: PersonaService,
        userService: UserServiceProtocol,
        modelContext: ModelContext
    ) {
        self.conversationManager = conversationManager
        self.personaService = personaService
        self.userService = userService
        self.modelContext = modelContext
        
        // Setup memory monitoring
        setupMemoryMonitoring()
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Navigation
    
    func start() {
        currentView = .welcome
        progress = 0.0
    }
    
    func beginConversation() async {
        currentView = .conversation
        progress = 0.1
        
        do {
            // Start new conversation session
            let userId = await userService.getCurrentUserId()
            conversationSession = try await conversationManager.startNewSession(userId: userId)
        } catch {
            handleError(error)
        }
    }
    
    func completeConversation() async {
        guard let session = conversationSession else {
            handleError(OnboardingError.noSession)
            return
        }
        
        isLoading = true
        currentView = .generatingPersona
        progress = 0.7
        
        do {
            // Mark session as complete
            session.completedAt = Date()
            
            // Generate persona from conversation
            generatedPersona = try await personaService.generatePersona(from: session)
            
            // Show preview
            currentView = .personaPreview
            progress = 0.9
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func acceptPersona() async {
        guard let persona = generatedPersona,
              let userId = await userService.getCurrentUserId() else {
            handleError(OnboardingError.noPersona)
            return
        }
        
        isLoading = true
        progress = 0.95
        
        do {
            // Save persona
            try await personaService.savePersona(persona, for: userId)
            
            // Convert to CoachPersona for user service
            let coachPersona = CoachPersona(from: persona)
            try await userService.setCoachPersona(coachPersona)
            
            // Complete onboarding
            try await userService.completeOnboarding()
            
            // Save conversation session
            try modelContext.save()
            
            // Done!
            currentView = .complete
            progress = 1.0
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func adjustPersona(_ adjustment: String) async {
        guard let currentPersona = generatedPersona else {
            handleError(OnboardingError.noPersona)
            return
        }
        
        isLoading = true
        
        do {
            // Apply adjustment
            generatedPersona = try await personaService.adjustPersona(
                currentPersona,
                adjustment: adjustment
            )
            
            // Refresh preview
            currentView = .personaPreview
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func regeneratePersona() async {
        guard conversationSession != nil else {
            handleError(OnboardingError.noSession)
            return
        }
        
        // Re-run persona generation
        await completeConversation()
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        self.error = error
        HapticManager.error()
        
        // Log error for debugging
        print("Onboarding error: \(error.localizedDescription)")
    }
    
    func clearError() {
        error = nil
    }
    
    func retryLastAction() async {
        clearError()
        
        switch currentView {
        case .conversation:
            await beginConversation()
        case .generatingPersona:
            await completeConversation()
        case .personaPreview:
            if generatedPersona == nil {
                await completeConversation()
            }
        default:
            break
        }
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryMonitoring() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }
    }
    
    private func handleMemoryWarning() {
        // Clear any cached data that can be regenerated
        print("Memory warning - clearing onboarding caches")
        
        // Save current state to disk before clearing
        if let session = conversationSession,
           let userId = session.userId {
            Task {
                await cache.saveSession(
                    userId: userId,
                    conversationData: ConversationData(
                        userName: "User",
                        primaryGoal: "fitness",
                        responses: [:]
                    ),
                    insights: nil,
                    currentStep: currentView.rawValue,
                    responses: session.responses
                )
            }
        }
        
        // Clear non-essential memory
        if currentView != .conversation {
            conversationSession = nil
        }
    }
    
    func cleanup() {
        // Called when onboarding completes
        conversationSession = nil
        generatedPersona = nil
        
        if let userId = userService.getCurrentUser()?.id {
            Task {
                await cache.clearSession(userId: userId)
            }
        }
    }
}

// MARK: - Onboarding States

enum OnboardingView: String, CaseIterable {
    case welcome
    case conversation
    case generatingPersona
    case personaPreview
    case complete
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to AirFit"
        case .conversation:
            return "Let's Get to Know You"
        case .generatingPersona:
            return "Creating Your Coach"
        case .personaPreview:
            return "Meet Your Coach"
        case .complete:
            return "All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Let's create your personalized AI fitness coach"
        case .conversation:
            return "Answer a few questions to help us understand you better"
        case .generatingPersona:
            return "We're crafting your unique coach personality"
        case .personaPreview:
            return "Here's your personalized fitness coach"
        case .complete:
            return "Your coach is ready to help you achieve your goals"
        }
    }
}

// MARK: - Errors

enum OnboardingError: LocalizedError {
    case noSession
    case noPersona
    case personaGenerationFailed(String)
    case saveFailed(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noSession:
            return "No active conversation session"
        case .noPersona:
            return "No persona has been generated"
        case .personaGenerationFailed(let detail):
            return "Failed to create your coach: \(detail)"
        case .saveFailed(let detail):
            return "Failed to save your settings: \(detail)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noSession:
            return "Please restart the onboarding process"
        case .noPersona:
            return "Please complete the conversation first"
        case .personaGenerationFailed:
            return "Try generating your coach again"
        case .saveFailed:
            return "Check your connection and try again"
        case .networkError:
            return "Check your internet connection and retry"
        }
    }
}
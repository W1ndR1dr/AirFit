import Foundation

struct SimpleAnalyticsError: Error {
    let message: String
}

// MARK: - Analytics Event Extensions

extension ConversationAnalytics {
    enum OnboardingEvent: String {
        case onboardingStarted = "onboarding_started"
        case onboardingPaused = "onboarding_paused"
        case onboardingResumed = "onboarding_resumed"
        case onboardingCancelled = "onboarding_cancelled"
        case onboardingCompleted = "onboarding_completed"
        case onboardingError = "onboarding_error"
        case personaGenerated = "persona_generated"
        case personaAdjusted = "persona_adjusted"
        case stateTransition = "state_transition"
    }
    
    func trackEvent(_ event: OnboardingEvent, properties: [String: Any] = [:]) async {
        // TODO: Implement proper event tracking integration
        // For now, we'll create a simple log entry
        await track(.errorOccurred(nodeId: nil, error: SimpleAnalyticsError(message: event.rawValue)))
    }
}

// MARK: - User Service Protocol Extension

extension UserServiceProtocol {
    func updatePersona(_ persona: PersonaProfile) async throws {
        // Default implementation that stores in user's coach settings
        // This would be implemented by the actual UserService
    }
    
    func markOnboardingComplete() async throws {
        // Default implementation
    }
}
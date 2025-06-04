import Foundation
import SwiftData

@MainActor
final class OnboardingOrchestrator: ObservableObject {
    // MARK: - State
    @Published private(set) var state: OnboardingState = .notStarted
    @Published private(set) var progress: OnboardingProgress = .init()
    @Published private(set) var error: OnboardingOrchestratorError?
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let apiKeyManager: APIKeyManagerProtocol
    private let userService: UserServiceProtocol
    private let analytics: ConversationAnalytics
    
    // MARK: - Components
    private var conversationCoordinator: ConversationCoordinator?
    private var generatedPersona: PersonaProfile?
    
    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        apiKeyManager: APIKeyManagerProtocol,
        userService: UserServiceProtocol,
        analytics: ConversationAnalytics = ConversationAnalytics()
    ) {
        self.modelContext = modelContext
        self.apiKeyManager = apiKeyManager
        self.userService = userService
        self.analytics = analytics
    }
    
    // MARK: - Public Methods
    func startOnboarding(userId: UUID) async throws {
        guard state == .notStarted else {
            throw OnboardingOrchestratorError.invalidStateTransition
        }
        
        state = .conversationInProgress
        progress.startTime = Date()
        progress.conversationStarted = true
        
        await analytics.track(.sessionStarted(userId: userId))
        
        // Create conversation coordinator
        conversationCoordinator = ConversationCoordinator(
            modelContext: modelContext,
            userId: userId,
            apiKeyManager: apiKeyManager,
            onCompletion: { [weak self] persona in
                Task { @MainActor in
                    await self?.handlePersonaGenerated(persona)
                }
            }
        )
        
        conversationCoordinator?.start()
    }
    
    func pauseOnboarding() async {
        guard case .conversationInProgress = state else { return }
        
        state = .paused
        // Track pause as abandonment with current progress
        if let user = try? await userService.getCurrentUser() {
            let userId = user.id
            await analytics.track(.sessionAbandoned(
                userId: userId,
                lastNodeId: "unknown",
                completionPercentage: progress.completionPercentage
            ))
        }
    }
    
    func resumeOnboarding() async throws {
        guard case .paused = state else {
            throw OnboardingOrchestratorError.invalidStateTransition
        }
        
        state = .conversationInProgress
        // Track resume
        if let user = try? await userService.getCurrentUser() {
            let userId = user.id
            await analytics.track(.sessionResumed(userId: userId, nodeId: "unknown"))
        }
        
        // Resume conversation if needed
        if conversationCoordinator?.isActive == false {
            conversationCoordinator?.start()
        }
    }
    
    func cancelOnboarding() async {
        let previousState = state
        state = .cancelled
        
        // Track cancellation
        if let user = try? await userService.getCurrentUser() {
            let userId = user.id
            await analytics.track(.sessionAbandoned(
                userId: userId,
                lastNodeId: "cancelled",
                completionPercentage: progress.completionPercentage
            ))
        }
        
        // Clean up
        conversationCoordinator?.isActive = false
        conversationCoordinator = nil
    }
    
    func completeOnboarding() async throws {
        guard case .reviewingPersona(let persona) = state else {
            throw OnboardingOrchestratorError.invalidStateTransition
        }
        
        state = .saving
        
        do {
            // Save persona to user profile
            try await userService.updatePersona(persona)
            
            // Mark onboarding complete
            try await userService.markOnboardingComplete()
            
            // Track completion
            await analytics.trackEvent(.onboardingCompleted, properties: [
                "duration": progress.duration,
                "persona_id": persona.id.uuidString,
                "persona_name": persona.name,
                "persona_archetype": persona.archetype
            ])
            
            state = .completed
            progress.completionTime = Date()
            
        } catch {
            await handleError(.saveFailed(error))
            throw error
        }
    }
    
    func adjustPersona(_ adjustments: PersonaAdjustments) async throws {
        guard case .reviewingPersona(let currentPersona) = state else {
            throw OnboardingOrchestratorError.invalidStateTransition
        }
        
        state = .adjustingPersona(currentPersona)
        
        do {
            // Apply adjustments (would integrate with PersonaSynthesizer)
            let adjustedPersona = try await applyPersonaAdjustments(
                to: currentPersona,
                adjustments: adjustments
            )
            
            state = .reviewingPersona(adjustedPersona)
            generatedPersona = adjustedPersona
            
            await analytics.trackEvent(.personaAdjusted, properties: [
                "adjustment_type": adjustments.type.rawValue,
                "adjustment_count": progress.adjustmentCount + 1
            ])
            
            progress.adjustmentCount += 1
            
        } catch {
            await handleError(.adjustmentFailed(error))
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func handlePersonaGenerated(_ persona: PersonaProfile) async {
        generatedPersona = persona
        progress.synthesisComplete = true
        progress.completionPercentage = 1.0
        
        state = .reviewingPersona(persona)
        
        await analytics.trackEvent(.personaGenerated, properties: [
            "generation_time": Date().timeIntervalSince(progress.startTime),
            "persona_traits": persona.metadata.sourceInsights.dominantTraits.count
        ])
    }
    
    private func applyPersonaAdjustments(
        to persona: PersonaProfile,
        adjustments: PersonaAdjustments
    ) async throws -> PersonaProfile {
        // In real implementation, would call PersonaSynthesizer
        // For now, return the same persona
        return persona
    }
    
    private func handleError(_ error: OnboardingOrchestratorError) async {
        self.error = error
        state = .error(error)
        
        await analytics.trackEvent(.onboardingError, properties: [
            "error_type": error.errorCode,
            "error_message": error.localizedDescription,
            "state": String(describing: state)
        ])
    }
}

// MARK: - Supporting Types

enum OnboardingState: Equatable {
    case notStarted
    case conversationInProgress
    case synthesizingPersona
    case reviewingPersona(PersonaProfile)
    case adjustingPersona(PersonaProfile)
    case saving
    case completed
    case paused
    case cancelled
    case error(OnboardingOrchestratorError)
    
    static func == (lhs: OnboardingState, rhs: OnboardingState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.conversationInProgress, .conversationInProgress),
             (.synthesizingPersona, .synthesizingPersona),
             (.saving, .saving),
             (.completed, .completed),
             (.paused, .paused),
             (.cancelled, .cancelled):
            return true
        case (.reviewingPersona(let p1), .reviewingPersona(let p2)),
             (.adjustingPersona(let p1), .adjustingPersona(let p2)):
            return p1.id == p2.id
        case (.error(let e1), .error(let e2)):
            return e1.errorCode == e2.errorCode
        default:
            return false
        }
    }
}

struct OnboardingProgress {
    var conversationStarted = false
    var nodesCompleted = 0
    var totalNodes = 12
    var completionPercentage: Double = 0
    var synthesisStarted = false
    var extractionComplete = false
    var synthesisComplete = false
    var adjustmentCount = 0
    var startTime = Date()
    var completionTime: Date?
    
    var duration: TimeInterval {
        if let completionTime = completionTime {
            return completionTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
    
    var estimatedTimeRemaining: TimeInterval? {
        guard completionPercentage > 0 && completionPercentage < 1 else { return nil }
        let elapsed = duration
        let totalEstimate = elapsed / completionPercentage
        return totalEstimate - elapsed
    }
}

enum OnboardingOrchestratorError: LocalizedError, Equatable {
    case conversationStartFailed(Error)
    case responseProcessingFailed(Error)
    case synthesisFailed(Error)
    case saveFailed(Error)
    case adjustmentFailed(Error)
    case invalidStateTransition
    case timeout
    case networkError
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .conversationStartFailed(let error):
            return "Failed to start conversation: \(error.localizedDescription)"
        case .responseProcessingFailed(let error):
            return "Failed to process response: \(error.localizedDescription)"
        case .synthesisFailed(let error):
            return "Failed to create your coach: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .adjustmentFailed(let error):
            return "Failed to adjust persona: \(error.localizedDescription)"
        case .invalidStateTransition:
            return "Invalid operation for current state"
        case .timeout:
            return "Operation timed out"
        case .networkError:
            return "Network connection error"
        case .userCancelled:
            return "Onboarding was cancelled"
        }
    }
    
    var errorCode: String {
        switch self {
        case .conversationStartFailed: return "conversation_start_failed"
        case .responseProcessingFailed: return "response_processing_failed"
        case .synthesisFailed: return "synthesis_failed"
        case .saveFailed: return "save_failed"
        case .adjustmentFailed: return "adjustment_failed"
        case .invalidStateTransition: return "invalid_state"
        case .timeout: return "timeout"
        case .networkError: return "network_error"
        case .userCancelled: return "user_cancelled"
        }
    }
    
    static func == (lhs: OnboardingOrchestratorError, rhs: OnboardingOrchestratorError) -> Bool {
        lhs.errorCode == rhs.errorCode
    }
}

struct PersonaAdjustments {
    enum AdjustmentType: String {
        case tone = "tone"
        case energy = "energy"
        case formality = "formality"
        case humor = "humor"
        case supportiveness = "supportiveness"
    }
    
    let type: AdjustmentType
    let value: Double // -1.0 to 1.0
    let feedback: String?
}
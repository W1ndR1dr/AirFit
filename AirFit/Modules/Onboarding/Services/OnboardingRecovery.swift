import Foundation
import SwiftData

// Simple error for analytics tracking
struct RecoveryAnalyticsSimpleError: Error {
    let message: String
    var localizedDescription: String { message }
}

// MARK: - Recovery Analytics Error
enum RecoveryAnalyticsError: LocalizedError {
    case recoveryStarted(strategy: String)
    case recoveryCompleted(strategy: String)
    
    var errorDescription: String? {
        switch self {
        case .recoveryStarted(let strategy):
            return "Recovery started with strategy: \(strategy)"
        case .recoveryCompleted(let strategy):
            return "Recovery completed with strategy: \(strategy)"
        }
    }
}

@MainActor
final class OnboardingRecovery {
    // MARK: - Properties
    private let modelContext: ModelContext
    private let analytics: ConversationAnalytics
    private let maxRetryAttempts = 3
    private let sessionTimeout: TimeInterval = 3600 // 1 hour
    
    // Recovery state
    private var retryAttempts: [String: Int] = [:]
    private var lastError: [String: Error] = [:]
    
    // MARK: - Initialization
    init(modelContext: ModelContext, analytics: ConversationAnalytics = ConversationAnalytics()) {
        self.modelContext = modelContext
        self.analytics = analytics
    }
    
    // MARK: - Recovery Methods
    
    func canRecover(from error: OnboardingOrchestratorError, sessionId: String) -> Bool {
        let attempts = retryAttempts[sessionId] ?? 0
        
        switch error {
        case .networkError, .timeout:
            // Network errors are always recoverable
            return attempts < maxRetryAttempts
            
        case .synthesisFailed:
            // Synthesis failures can be retried with different providers
            return attempts < maxRetryAttempts
            
        case .conversationStartFailed, .responseProcessingFailed:
            // Conversation errors may be recoverable
            return attempts < maxRetryAttempts
            
        case .saveFailed:
            // Save failures are recoverable
            return attempts < maxRetryAttempts
            
        case .invalidStateTransition, .userCancelled:
            // These are not recoverable
            return false
            
        case .adjustmentFailed:
            // Adjustment failures can be retried
            return attempts < 2 // Limit to 2 attempts
        }
    }
    
    func recordError(_ error: OnboardingOrchestratorError, sessionId: String) async {
        lastError[sessionId] = error
        retryAttempts[sessionId] = (retryAttempts[sessionId] ?? 0) + 1
        
        await analytics.trackEvent(.onboardingError, properties: [
            "error_type": error.errorCode,
            "session_id": sessionId,
            "retry_attempt": retryAttempts[sessionId] ?? 0
        ])
    }
    
    func createRecoveryPlan(for error: OnboardingOrchestratorError, sessionId: String) -> RecoveryPlan {
        guard canRecover(from: error, sessionId: sessionId) else {
            return RecoveryPlan(
                strategy: .none,
                actions: [],
                userMessage: "We're unable to complete setup right now. Please try again later."
            )
        }
        
        switch error {
        case .networkError:
            return RecoveryPlan(
                strategy: .retry,
                actions: [.checkConnectivity, .retryWithBackoff],
                userMessage: "Connection issue detected. Retrying..."
            )
            
        case .timeout:
            return RecoveryPlan(
                strategy: .retry,
                actions: [.increaseTimeout, .retryWithBackoff],
                userMessage: "This is taking longer than expected. Please wait..."
            )
            
        case .synthesisFailed:
            return RecoveryPlan(
                strategy: .fallback,
                actions: [.switchProvider, .simplifyRequest, .retry],
                userMessage: "Trying a different approach..."
            )
            
        case .conversationStartFailed:
            return RecoveryPlan(
                strategy: .resume,
                actions: [.loadFromCache, .validateState, .retry],
                userMessage: "Resuming where you left off..."
            )
            
        case .responseProcessingFailed:
            return RecoveryPlan(
                strategy: .retry,
                actions: [.validateResponse, .retryLastStep],
                userMessage: "Processing your response..."
            )
            
        case .saveFailed:
            return RecoveryPlan(
                strategy: .retry,
                actions: [.validateData, .retryWithBackoff],
                userMessage: "Saving your profile..."
            )
            
        case .adjustmentFailed:
            return RecoveryPlan(
                strategy: .revert,
                actions: [.revertToLastGood, .retry],
                userMessage: "Reverting to previous settings..."
            )
            
        default:
            return RecoveryPlan(
                strategy: .none,
                actions: [],
                userMessage: "An unexpected error occurred."
            )
        }
    }
    
    func executeRecoveryPlan(_ plan: RecoveryPlan, sessionId: String) async throws {
        // Track recovery start - using error event as there's no specific recovery event
        await analytics.track(.errorOccurred(
            nodeId: sessionId,
            error: RecoveryAnalyticsError.recoveryStarted(strategy: plan.strategy.rawValue)
        ))
        
        for action in plan.actions {
            try await executeRecoveryAction(action, sessionId: sessionId)
        }
        
        // Track recovery completion
        await analytics.track(.errorOccurred(
            nodeId: sessionId,
            error: RecoveryAnalyticsError.recoveryCompleted(strategy: plan.strategy.rawValue)
        ))
    }
    
    // MARK: - Session Recovery
    
    func findRecoverableSession(userId: UUID) async throws -> RecoverableSession? {
        let cutoffDate = Date().addingTimeInterval(-sessionTimeout)
        
        // Query for incomplete sessions - simplified predicate
        let targetUserId = userId
        let targetCutoffDate = cutoffDate
        
        let descriptor = FetchDescriptor<ConversationSession>(
            predicate: #Predicate<ConversationSession> { session in
                session.userId == targetUserId && session.completedAt == nil
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        let sessions = try modelContext.fetch(descriptor)
        
        // Filter by date in memory to avoid complex predicate
        let validSessions = sessions.filter { $0.startedAt > targetCutoffDate }
        
        guard let latestSession = validSessions.first else {
            return nil
        }
        
        // Check if session is recoverable
        let _ = latestSession.responses.count
        let lastResponseTime = latestSession.responses.last?.timestamp ?? latestSession.startedAt
        let timeSinceLastResponse = Date().timeIntervalSince(lastResponseTime)
        
        if timeSinceLastResponse > sessionTimeout {
            return nil // Session too old
        }
        
        return RecoverableSession(
            sessionId: latestSession.id,
            userId: userId,
            progress: calculateProgress(from: latestSession),
            lastNodeId: latestSession.currentNodeId,
            responses: latestSession.responses.count,
            canResume: true
        )
    }
    
    func resumeSession(_ session: RecoverableSession) async throws -> ConversationSession {
        // Use the session ID to fetch
        let targetId = session.sessionId
        let descriptor = FetchDescriptor<ConversationSession>(
            predicate: #Predicate<ConversationSession> { conversationSession in
                conversationSession.id == targetId
            }
        )
        
        let sessions = try modelContext.fetch(descriptor)
        guard let conversationSession = sessions.first else {
            throw OnboardingError.conversationStartFailed(RecoveryError.sessionNotFound)
        }
        
        // Track event asynchronously without blocking
        Task {
            await analytics.track(.errorOccurred(nodeId: nil, error: RecoveryAnalyticsSimpleError(message: "session_resumed")))
        }
        
        return conversationSession
    }
    
    // MARK: - Private Methods
    
    private func executeRecoveryAction(_ action: RecoveryAction, sessionId: String) async throws {
        switch action {
        case .checkConnectivity:
            try await checkNetworkConnectivity()
            
        case .retryWithBackoff:
            let attempt = retryAttempts[sessionId] ?? 0
            let delay = pow(2.0, Double(attempt)) // Exponential backoff
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
        case .increaseTimeout:
            // Would update timeout configuration
            break
            
        case .switchProvider:
            // Would switch to fallback LLM provider
            break
            
        case .simplifyRequest:
            // Would simplify the synthesis request
            break
            
        case .retry:
            // Caller handles the actual retry
            break
            
        case .loadFromCache:
            // Load cached conversation state
            break
            
        case .validateState:
            // Validate current state consistency
            break
            
        case .validateResponse:
            // Validate last response format
            break
            
        case .retryLastStep:
            // Retry the last failed step
            break
            
        case .validateData:
            // Validate data before save
            break
            
        case .revertToLastGood:
            // Revert to last known good state
            break
        }
    }
    
    private func checkNetworkConnectivity() async throws {
        // Simple connectivity check
        let url = URL(string: "https://api.anthropic.com/health")!
        let (_, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RecoveryError.networkUnavailable
        }
    }
    
    private func calculateProgress(from session: ConversationSession) -> Double {
        // Calculate based on responses and expected flow
        let totalExpectedNodes = 12 // From flow definition
        let completedNodes = session.responses.count
        return Double(completedNodes) / Double(totalExpectedNodes)
    }
    
    func clearRecoveryState(sessionId: String) {
        retryAttempts.removeValue(forKey: sessionId)
        lastError.removeValue(forKey: sessionId)
    }
}

// MARK: - Supporting Types

struct RecoveryPlan {
    enum Strategy: String {
        case none
        case retry
        case fallback
        case resume
        case revert
    }
    
    let strategy: Strategy
    let actions: [RecoveryAction]
    let userMessage: String
}

enum RecoveryAction {
    case checkConnectivity
    case retryWithBackoff
    case increaseTimeout
    case switchProvider
    case simplifyRequest
    case retry
    case loadFromCache
    case validateState
    case validateResponse
    case retryLastStep
    case validateData
    case revertToLastGood
}

struct RecoverableSession {
    let sessionId: UUID
    let userId: UUID
    let progress: Double
    let lastNodeId: String?
    let responses: Int
    let canResume: Bool
}

enum RecoveryError: LocalizedError {
    case sessionNotFound
    case networkUnavailable
    case corruptedState
    case tooManyRetries
    
    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Could not find your previous session"
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .corruptedState:
            return "Session data is corrupted"
        case .tooManyRetries:
            return "Maximum retry attempts exceeded"
        }
    }
}

// MARK: - Analytics Extensions

extension ConversationAnalytics {
    enum RecoveryEvent: String {
        case recoveryStarted = "recovery_started"
        case recoveryCompleted = "recovery_completed"
        case sessionResumed = "session_resumed"
    }
    
    func trackEvent(_ event: RecoveryEvent, properties: [String: Any] = [:]) {
        // Convert to appropriate analytics event
        // For now, track as an error with the event name
        Task {
            // TODO: Implement proper analytics error tracking
            // await track(.errorOccurred(nodeId: nil, error: RecoveryAnalyticsSimpleError(message: event.rawValue)))
            AppLogger.info("RecoveryEvent: \(event.rawValue)", category: .app)
        }
    }
}
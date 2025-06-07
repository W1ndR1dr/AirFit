import XCTest
import SwiftData
@testable import AirFit

/// Tests for error handling and recovery in onboarding flow
@MainActor
final class OnboardingErrorRecoveryTests: XCTestCase {

    var recovery: OnboardingRecovery!
    var modelContext: ModelContext!
    var analytics: ConversationAnalytics!

    override func setUp() async throws {
        try await super.setUp()

        do {
            let container = try ModelContainer.createTestContainer()
            modelContext = container.mainContext
        } catch {
            XCTFail("Failed to create test container: \(error)")
            return
        }

        analytics = ConversationAnalytics()
        recovery = OnboardingRecovery(modelContext: modelContext, analytics: analytics)
    }

    // MARK: - Network Error Recovery

    func testNetworkErrorRecovery() async throws {
        let sessionId = "test-session-123"

        // Test network error recovery
        let networkError = OnboardingOrchestratorError.networkError

        // Record error
        await recovery.recordError(networkError, sessionId: sessionId)

        // Check if recovery is possible
        let canRecover = recovery.canRecover(from: networkError, sessionId: sessionId)
        XCTAssertTrue(canRecover, "Network errors should be recoverable")

        // Create recovery plan
        let plan = recovery.createRecoveryPlan(for: networkError, sessionId: sessionId)
        XCTAssertEqual(plan.strategy, RecoveryPlan.Strategy.retry)
        XCTAssertTrue(plan.actions.contains(RecoveryAction.checkConnectivity))
        XCTAssertTrue(plan.actions.contains(RecoveryAction.retryWithBackoff))
    }

    func testMaxRetryLimit() async throws {
        let sessionId = "test-session-456"
        let networkError = OnboardingOrchestratorError.networkError

        // Simulate hitting retry limit
        for _ in 0..<3 {
            await recovery.recordError(networkError, sessionId: sessionId)
        }

        // After 3 attempts, should not be recoverable
        let canRecover = recovery.canRecover(from: networkError, sessionId: sessionId)
        XCTAssertFalse(canRecover, "Should not be recoverable after max attempts")

        // Recovery plan should indicate no recovery possible
        let plan = recovery.createRecoveryPlan(for: networkError, sessionId: sessionId)
        XCTAssertEqual(plan.strategy, RecoveryPlan.Strategy.none)
    }

    func testSynthesisFailureRecovery() async throws {
        let sessionId = "test-session-789"
        let synthesisError = OnboardingOrchestratorError.synthesisFailed(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model unavailable"]))

        // Record error
        await recovery.recordError(synthesisError, sessionId: sessionId)

        // Check if recovery is possible
        let canRecover = recovery.canRecover(from: synthesisError, sessionId: sessionId)
        XCTAssertTrue(canRecover, "Synthesis failures should be recoverable")

        // Create recovery plan
        let plan = recovery.createRecoveryPlan(for: synthesisError, sessionId: sessionId)
        XCTAssertEqual(plan.strategy, RecoveryPlan.Strategy.fallback)
        XCTAssertTrue(plan.actions.contains(RecoveryAction.switchProvider))
    }

    func testNonRecoverableErrors() async throws {
        let sessionId = "test-session-nonrecoverable"

        // Test user cancelled - should not be recoverable
        let cancelledError = OnboardingOrchestratorError.userCancelled
        let canRecoverCancelled = recovery.canRecover(from: cancelledError, sessionId: sessionId)
        XCTAssertFalse(canRecoverCancelled, "User cancelled should not be recoverable")

        // Test invalid state transition - should not be recoverable
        let invalidStateError = OnboardingOrchestratorError.invalidStateTransition
        let canRecoverInvalidState = recovery.canRecover(from: invalidStateError, sessionId: sessionId)
        XCTAssertFalse(canRecoverInvalidState, "Invalid state transitions should not be recoverable")
    }

    func testClearRecoveryData() async throws {
        let sessionId = "test-session-clear"
        let networkError = OnboardingOrchestratorError.networkError

        // Record some errors
        await recovery.recordError(networkError, sessionId: sessionId)
        await recovery.recordError(networkError, sessionId: sessionId)

        // After recording multiple errors, should eventually not be recoverable
        // Record one more error to reach limit
        await recovery.recordError(networkError, sessionId: sessionId)

        // Should not be recoverable after 3 attempts
        let canRecover = recovery.canRecover(from: networkError, sessionId: sessionId)
        XCTAssertFalse(canRecover, "Should not be recoverable after max attempts")
    }

    func testRecoveryPlanUserMessages() async throws {
        let sessionId = "test-session-messages"

        // Test different error types produce appropriate user messages
        let errors: [(OnboardingOrchestratorError, String)] = [
            (.networkError, "Connection issue detected"),
            (.timeout, "Taking longer than expected"),
            (.synthesisFailed(NSError(domain: "test", code: -1)), "generation issue"),
            (.saveFailed(NSError(domain: "test", code: 0)), "save your progress")
        ]

        for (error, expectedMessage) in errors {
            let plan = recovery.createRecoveryPlan(for: error, sessionId: sessionId)
            XCTAssertTrue(plan.userMessage.contains(expectedMessage),
                         "User message for \(error) should contain: \(expectedMessage)")
        }
    }
}
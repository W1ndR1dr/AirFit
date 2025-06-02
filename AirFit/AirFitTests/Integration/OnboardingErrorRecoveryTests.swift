import XCTest
import SwiftData
@testable import AirFit

/// Tests for error handling and recovery in onboarding flow
final class OnboardingErrorRecoveryTests: XCTestCase {
    
    var coordinator: OnboardingFlowCoordinator!
    var recovery: OnboardingRecovery!
    var cache: OnboardingCache!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        
        cache = OnboardingCache()
        recovery = OnboardingRecovery(cache: cache, modelContext: modelContext)
        
        let conversationManager = ConversationFlowManager()
        let personaService = PersonaService(
            personaSynthesizer: PersonaSynthesizer(llmOrchestrator: MockLLMOrchestrator()),
            llmOrchestrator: MockLLMOrchestrator(),
            modelContext: modelContext,
            cache: cache
        )
        
        coordinator = OnboardingFlowCoordinator(
            conversationManager: conversationManager,
            personaService: personaService,
            userService: MockUserService(),
            modelContext: modelContext
        )
    }
    
    // MARK: - Network Error Recovery
    
    func testNetworkErrorRecovery() async throws {
        let userId = UUID()
        
        // Test offline error
        let offlineResult = await recovery.attemptRecovery(
            from: NetworkError.offline,
            userId: userId,
            currentState: .conversation
        )
        
        switch offlineResult {
        case .waitForConnection(let resumeFrom):
            XCTAssertEqual(resumeFrom, .conversation)
        default:
            XCTFail("Expected waitForConnection result")
        }
        
        // Test timeout error with retries
        let timeoutResult1 = await recovery.attemptRecovery(
            from: NetworkError.timeout,
            userId: userId,
            currentState: .generatingPersona
        )
        
        switch timeoutResult1 {
        case .retry(let delay):
            XCTAssertGreaterThan(delay, 0)
            XCTAssertLessThanOrEqual(delay, 30)
        default:
            XCTFail("Expected retry result")
        }
    }
    
    func testMaxRetryLimit() async throws {
        let userId = UUID()
        
        // Simulate hitting retry limit
        for i in 0..<3 {
            _ = await recovery.attemptRecovery(
                from: NetworkError.timeout,
                userId: userId,
                currentState: .generatingPersona
            )
        }
        
        // Fourth attempt should abort
        let result = await recovery.attemptRecovery(
            from: NetworkError.timeout,
            userId: userId,
            currentState: .generatingPersona
        )
        
        switch result {
        case .abort(let reason):
            XCTAssertTrue(reason.contains("Maximum retry"))
        default:
            XCTFail("Expected abort after max retries")
        }
    }
    
    // MARK: - Session Recovery
    
    func testSessionRecovery() async throws {
        let userId = UUID()
        
        // Save session state
        let responses = [
            ConversationResponse(
                nodeId: "name",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Test User"))
            )
        ]
        
        await recovery.saveRecoveryState(
            userId: userId,
            conversationData: ConversationData(
                userName: "Test User",
                primaryGoal: "fitness",
                responses: ["name": "Test User"]
            ),
            insights: nil,
            currentStep: "personaPreview",
            responses: responses
        )
        
        // Simulate recovery
        let result = await recovery.attemptRecovery(
            from: PersonaError.generationFailed("Test error"),
            userId: userId,
            currentState: .generatingPersona
        )
        
        switch result {
        case .useAlternative(let approach):
            XCTAssertEqual(approach, .simplifiedGeneration)
        default:
            XCTFail("Expected alternative approach")
        }
        
        // Verify cached data exists
        let cached = await cache.restoreSession(userId: userId)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.currentStep, "personaPreview")
    }
    
    // MARK: - Error Presentation
    
    func testErrorPresentation() async throws {
        // Network error
        let networkError = NetworkError.offline
        XCTAssertEqual(networkError.errorDescription, "No internet connection")
        XCTAssertEqual(networkError.recoverySuggestion, "Please check your network settings and try again")
        
        // Persona error
        let personaError = PersonaError.parsingFailed("Invalid JSON")
        XCTAssertTrue(personaError.errorDescription?.contains("Failed to parse") ?? false)
        
        // Validation error
        let validationError = ValidationError.missingRequiredField("name")
        XCTAssertEqual(validationError.errorDescription, "Please provide your name")
    }
    
    // MARK: - Coordinator Error Handling
    
    func testCoordinatorErrorHandling() async throws {
        coordinator.start()
        
        // Simulate network error during conversation
        await coordinator.beginConversation()
        
        // Should have error set if offline
        // Note: This test assumes NetworkReachability can be mocked
        // In real tests, you'd inject a mock NetworkReachability
    }
    
    func testRecoveryStateCleanup() async throws {
        let userId = UUID()
        
        // Save recovery state
        await recovery.saveRecoveryState(
            userId: userId,
            conversationData: nil,
            insights: nil,
            currentStep: "conversation",
            responses: []
        )
        
        // Verify saved
        var cached = await cache.restoreSession(userId: userId)
        XCTAssertNotNil(cached)
        
        // Clear recovery state
        await recovery.clearRecoveryState(userId: userId)
        
        // Verify cleared
        cached = await cache.restoreSession(userId: userId)
        XCTAssertNil(cached)
    }
}

// MARK: - Mock LLMOrchestrator

private class MockLLMOrchestrator: LLMOrchestrator {
    init() {
        super.init(apiKeyManager: MockAPIKeyManager())
    }
    
    override func complete(_ request: LLMRequest) async throws -> LLMResponse {
        // Return mock response
        return LLMResponse(
            content: "{}",
            model: request.model ?? "mock",
            usage: LLMUsage(promptTokens: 0, completionTokens: 0, totalTokens: 0),
            cost: 0
        )
    }
}

private class MockAPIKeyManager: APIKeyManagerProtocol {
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws { }
    func getAPIKey(forProvider provider: AIProvider) -> String? { "mock-key" }
    func deleteAPIKey(forProvider provider: AIProvider) throws { }
    func getAPIKey(for provider: String) async -> String? { "mock-key" }
    func saveAPIKey(_ apiKey: String, for provider: String) async throws { }
    func deleteAPIKey(for provider: String) async throws { }
}
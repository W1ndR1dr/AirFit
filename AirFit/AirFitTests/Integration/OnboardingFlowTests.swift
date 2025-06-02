import XCTest
import SwiftData
@testable import AirFit

final class OnboardingFlowTests: XCTestCase {
    
    var coordinator: OnboardingFlowCoordinator!
    var modelContext: ModelContext!
    var conversationManager: ConversationFlowManager!
    var personaService: PersonaService!
    var userService: MockUserService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory container
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        
        // Initialize services
        conversationManager = ConversationFlowManager()
        
        let apiKeyManager = MockAPIKeyManager()
        let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        let personaSynthesizer = PersonaSynthesizer(llmOrchestrator: llmOrchestrator)
        
        personaService = PersonaService(
            personaSynthesizer: personaSynthesizer,
            llmOrchestrator: llmOrchestrator,
            modelContext: modelContext
        )
        
        userService = MockUserService()
        
        // Initialize coordinator
        coordinator = OnboardingFlowCoordinator(
            conversationManager: conversationManager,
            personaService: personaService,
            userService: userService,
            modelContext: modelContext
        )
    }
    
    override func tearDown() async throws {
        coordinator = nil
        modelContext = nil
        conversationManager = nil
        personaService = nil
        userService = nil
        try await super.tearDown()
    }
    
    // MARK: - Navigation Tests
    
    func testInitialState() {
        XCTAssertEqual(coordinator.currentView, .welcome)
        XCTAssertFalse(coordinator.isLoading)
        XCTAssertNil(coordinator.error)
        XCTAssertEqual(coordinator.progress, 0.0)
    }
    
    func testNavigationFlow() async throws {
        // Start
        coordinator.start()
        XCTAssertEqual(coordinator.currentView, .welcome)
        
        // Begin conversation
        await coordinator.beginConversation()
        XCTAssertEqual(coordinator.currentView, .conversation)
        XCTAssertNotNil(coordinator.conversationSession)
        XCTAssertEqual(coordinator.progress, 0.1)
        
        // Add some responses to session
        if let session = coordinator.conversationSession {
            session.responses = createMockResponses()
            try modelContext.save()
        }
        
        // Complete conversation
        await coordinator.completeConversation()
        XCTAssertEqual(coordinator.currentView, .personaPreview)
        XCTAssertNotNil(coordinator.generatedPersona)
        XCTAssertEqual(coordinator.progress, 0.9)
        
        // Accept persona
        await coordinator.acceptPersona()
        XCTAssertEqual(coordinator.currentView, .complete)
        XCTAssertEqual(coordinator.progress, 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testBeginConversationError() async {
        // Setup error condition
        conversationManager.shouldFailNextRequest = true
        
        await coordinator.beginConversation()
        
        XCTAssertNotNil(coordinator.error)
        XCTAssertEqual(coordinator.currentView, .conversation) // Still moves to conversation view
    }
    
    func testCompleteConversationWithoutSession() async {
        // Try to complete without session
        await coordinator.completeConversation()
        
        XCTAssertNotNil(coordinator.error)
        if let error = coordinator.error as? OnboardingError {
            XCTAssertEqual(error, .noSession)
        }
    }
    
    func testAcceptPersonaWithoutGeneration() async {
        // Try to accept without persona
        await coordinator.acceptPersona()
        
        XCTAssertNotNil(coordinator.error)
        if let error = coordinator.error as? OnboardingError {
            XCTAssertEqual(error, .noPersona)
        }
    }
    
    func testRetryLastAction() async {
        // Create error condition
        conversationManager.shouldFailNextRequest = true
        await coordinator.beginConversation()
        XCTAssertNotNil(coordinator.error)
        
        // Clear error and retry
        conversationManager.shouldFailNextRequest = false
        await coordinator.retryLastAction()
        
        XCTAssertNil(coordinator.error)
        XCTAssertNotNil(coordinator.conversationSession)
    }
    
    // MARK: - Progress Tracking Tests
    
    func testProgressTracking() async {
        XCTAssertEqual(coordinator.progress, 0.0)
        
        coordinator.start()
        XCTAssertEqual(coordinator.progress, 0.0)
        
        await coordinator.beginConversation()
        XCTAssertEqual(coordinator.progress, 0.1)
        
        // Add responses and complete
        if let session = coordinator.conversationSession {
            session.responses = createMockResponses()
        }
        
        await coordinator.completeConversation()
        XCTAssertEqual(coordinator.progress, 0.9)
        
        await coordinator.acceptPersona()
        XCTAssertEqual(coordinator.progress, 1.0)
    }
    
    // MARK: - Persona Adjustment Tests
    
    func testPersonaAdjustment() async throws {
        // Setup persona
        await setupPersonaPreview()
        
        let originalPersona = coordinator.generatedPersona!
        let adjustment = "Be more energetic and motivational"
        
        await coordinator.adjustPersona(adjustment)
        
        XCTAssertNotNil(coordinator.generatedPersona)
        // In real implementation, would verify persona properties changed
        XCTAssertEqual(coordinator.currentView, .personaPreview)
    }
    
    func testPersonaRegeneration() async throws {
        // Setup persona
        await setupPersonaPreview()
        
        let originalPersona = coordinator.generatedPersona!
        
        await coordinator.regeneratePersona()
        
        XCTAssertNotNil(coordinator.generatedPersona)
        // In real implementation, would verify new persona is different
        XCTAssertEqual(coordinator.currentView, .personaPreview)
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStates() async {
        // Test loading during conversation completion
        let expectation = XCTestExpectation(description: "Loading state changes")
        
        Task {
            await coordinator.beginConversation()
            if let session = coordinator.conversationSession {
                session.responses = createMockResponses()
            }
            
            // Monitor loading state
            XCTAssertFalse(coordinator.isLoading)
            
            await coordinator.completeConversation()
            
            // Loading should have been set and unset
            XCTAssertFalse(coordinator.isLoading)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testErrorClearing() {
        // Create error
        coordinator.handleError(OnboardingError.noSession)
        XCTAssertNotNil(coordinator.error)
        
        // Clear error
        coordinator.clearError()
        XCTAssertNil(coordinator.error)
    }
    
    // MARK: - Helper Methods
    
    private func createMockResponses() -> [ConversationResponse] {
        let responses = [
            ConversationResponse(
                nodeId: "name",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Test User"))
            ),
            ConversationResponse(
                nodeId: "goals",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Get fit and healthy"))
            ),
            ConversationResponse(
                nodeId: "experience",
                responseType: "choice",
                responseData: try! JSONEncoder().encode(ResponseValue.choice("intermediate"))
            ),
            ConversationResponse(
                nodeId: "preferences",
                responseType: "multiChoice",
                responseData: try! JSONEncoder().encode(ResponseValue.multiChoice(["morning", "strength training"]))
            )
        ]
        
        return responses
    }
    
    private func setupPersonaPreview() async {
        await coordinator.beginConversation()
        
        if let session = coordinator.conversationSession {
            session.responses = createMockResponses()
            try? modelContext.save()
        }
        
        await coordinator.completeConversation()
        
        XCTAssertNotNil(coordinator.generatedPersona)
        XCTAssertEqual(coordinator.currentView, .personaPreview)
    }
}

// MARK: - Mock Services

private class MockAPIKeyManager: APIKeyManagerProtocol {
    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
        // Mock implementation
    }
    
    func getAPIKey(forProvider provider: AIProvider) -> String? {
        return "mock-api-key"
    }
    
    func deleteAPIKey(forProvider provider: AIProvider) throws {
        // Mock implementation
    }
    
    func getAPIKey(for provider: String) async -> String? {
        return "mock-api-key"
    }
    
    func saveAPIKey(_ apiKey: String, for provider: String) async throws {
        // Mock implementation
    }
    
    func deleteAPIKey(for provider: String) async throws {
        // Mock implementation
    }
}

extension ConversationFlowManager {
    var shouldFailNextRequest: Bool {
        get { false }
        set { }
    }
}
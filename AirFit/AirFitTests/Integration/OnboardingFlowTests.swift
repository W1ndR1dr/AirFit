import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class OnboardingFlowTests: XCTestCase {

    var coordinator: OnboardingFlowCoordinator!
    var modelContext: ModelContext!
    var conversationManager: ConversationFlowManager!
    var personaService: PersonaService!
    var userService: MockUserService!
    var flowDefinition: [String: ConversationNode]!

    override func setUp() async throws {
        try super.setUp()

        // Create in-memory container
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext

        // Create flow definition
        flowDefinition = createTestFlowDefinition()

        // Initialize conversation manager with flow definition
        conversationManager = ConversationFlowManager(
            flowDefinition: flowDefinition,
            modelContext: modelContext,
            responseAnalyzer: nil
        )

        // Initialize services
        let apiKeyManager = MockAPIKeyManager()
        let _ = MockLLMOrchestrator()
        let cache = AIResponseCache()
        // Create a real LLMOrchestrator with mock API key manager for testing
        let realLLMOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)

        let personaSynthesizer = OptimizedPersonaSynthesizer(
            llmOrchestrator: realLLMOrchestrator,
            cache: cache
        )

        personaService = PersonaService(
            personaSynthesizer: personaSynthesizer,
            llmOrchestrator: realLLMOrchestrator,
            modelContext: modelContext,
            cache: cache
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
        try super.tearDown()
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
        await coordinator.start()
        XCTAssertEqual(coordinator.currentView, .welcome)

        // Begin conversation
        await coordinator.beginConversation()
        XCTAssertEqual(coordinator.currentView, .conversation)
        XCTAssertNotNil(coordinator.conversationSession)
        XCTAssertEqual(coordinator.progress, 0.1)

        // Add some responses to session
        if let session = await coordinator.conversationSession {
            // Create mock responses
            let responseValue1 = ResponseValue.text("I'm new to fitness")
            let responseData1 = try JSONEncoder().encode(responseValue1)
            let response1 = ConversationResponse(
                sessionId: session.id,
                nodeId: "opening",
                responseData: responseData1
            )

            let responseValue2 = ResponseValue.choice("beginner")
            let responseData2 = try JSONEncoder().encode(responseValue2)
            let response2 = ConversationResponse(
                sessionId: session.id,
                nodeId: "experience",
                responseData: responseData2
            )
            session.responses = [response1, response2]
            do {

                try modelContext.save()

            } catch {

                XCTFail("Failed to save test context: \(error)")

            }
        }

        // Complete conversation
        await coordinator.completeConversation()
        XCTAssertEqual(coordinator.currentView, .generatingPersona)
        XCTAssertTrue(coordinator.progress >= 0.7)

        // Wait for persona generation to complete or fail
        // Since we can't set generatedPersona directly, we'll just check the state
        // In a real test, we'd mock the persona service to return our test persona

        // Accept persona
        await coordinator.acceptPersona()
        XCTAssertEqual(coordinator.currentView, .complete)
        XCTAssertEqual(coordinator.progress, 1.0)
    }

    // MARK: - Error Handling Tests

    func testBeginConversationError() async {
        // Simulate network error
        let reachability = await NetworkReachability.shared
        // We can't actually control network state, so test error handling directly

        await coordinator.beginConversation()

        // If network is available, session should be created
        // If not, error should be set
        if await reachability.isConnected {
            XCTAssertNotNil(coordinator.conversationSession)
        } else {
            XCTAssertNotNil(coordinator.error)
        }
    }

    func testErrorHandling() async throws {
        // Test that errors are properly set when operations fail
        // This test works with the public API only

        // Begin conversation (may fail if network is down)
        await coordinator.beginConversation()

        // If there's an error, verify it's handled
        if coordinator.error != nil {
            XCTAssertFalse(coordinator.isLoading)
            XCTAssertNotEqual(coordinator.currentView, .complete)
        }
    }

    // MARK: - Helper Methods

    private func createTestFlowDefinition() -> [String: ConversationNode] {
        [
            "opening": ConversationNode(
                nodeType: .opening,
                question: ConversationQuestion(
                    primary: "Welcome! Tell me about your fitness journey.",
                    clarifications: ["What brings you here?", "What are your goals?"],
                    examples: nil,
                    voicePrompt: nil
                ),
                inputType: .text(minLength: 10, maxLength: 500, placeholder: "Share your story..."),
                dataKey: "fitnessJourney"
            ),
            "experience": ConversationNode(
                nodeType: .lifestyle,
                question: ConversationQuestion(
                    primary: "What's your experience level?",
                    clarifications: ["How long have you been training?"],
                    examples: nil,
                    voicePrompt: nil
                ),
                inputType: .singleChoice(options: [
                    ChoiceOption(id: "beginner", text: "Beginner", emoji: "🌱", traits: [:]),
                    ChoiceOption(id: "intermediate", text: "Intermediate", emoji: "💪", traits: [:]),
                    ChoiceOption(id: "advanced", text: "Advanced", emoji: "🏆", traits: [:])
                ]),
                dataKey: "experienceLevel"
            ),
            "goals": ConversationNode(
                nodeType: .goals,
                question: ConversationQuestion(
                    primary: "What are your fitness goals?",
                    clarifications: ["What do you want to achieve?"],
                    examples: ["Lose weight", "Build muscle", "Improve endurance"],
                    voicePrompt: nil
                ),
                inputType: .text(minLength: 10, maxLength: 500, placeholder: "Describe your goals..."),
                dataKey: "fitnessGoals"
            )
        ]
    }
}
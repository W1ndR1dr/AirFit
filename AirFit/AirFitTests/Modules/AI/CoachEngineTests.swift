import XCTest
import SwiftData
import Combine
@testable import AirFit

final class CoachEngineTests: XCTestCase {
    // MARK: - Properties
    var sut: CoachEngine!
    var mockAIService: MockAIAPIService!
    var modelContext: ModelContext!
    var testUser: User!

    // MARK: - Setup & Teardown
    @MainActor
    override func setUp() async throws {
        // Create in-memory model container for testing
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            CoachMessage.self,
            FoodEntry.self,
            Workout.self,
            DailyLog.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(container)

        // Create test user
        testUser = User(
            id: UUID(),
            createdAt: Date(),
            lastActiveAt: Date()
        )
        modelContext.insert(testUser)
        try modelContext.save()

        // Initialize mocks
        mockAIService = MockAIAPIService()

        // Create system under test - integration testing with real components
        sut = createTestableCoachEngine()
    }

    @MainActor
    override func tearDown() async throws {
        sut = nil
        mockAIService = nil
        modelContext = nil
        testUser = nil
    }

    // MARK: - Local Command Integration Tests

    @MainActor
    func test_processUserMessage_withWaterLogCommand_shouldUseLocalParser() async throws {
        // Given - water logging command
        let waterLogText = "log 16 oz water"

        // When
        await sut.processUserMessage(waterLogText, for: testUser)

        // Then - should handle locally without calling AI service
        XCTAssertFalse(sut.isProcessing)
        XCTAssertTrue(sut.currentResponse.contains("16"))
        XCTAssertTrue(sut.currentResponse.contains("water"))
        XCTAssertTrue(sut.currentResponse.contains("logged"))
    }

    @MainActor
    func test_processUserMessage_withHelpCommand_shouldProvideHelpResponse() async throws {
        // Given - help command
        let helpText = "help"

        // When
        await sut.processUserMessage(helpText, for: testUser)

        // Then - should provide help response locally
        XCTAssertFalse(sut.isProcessing)
        XCTAssertTrue(sut.currentResponse.contains("help"))
        XCTAssertTrue(sut.currentResponse.contains("workouts"))
        XCTAssertTrue(sut.currentResponse.contains("nutrition"))
    }

    // MARK: - Conversation Management Tests

    @MainActor
    func test_clearConversation_shouldResetState() async throws {
        // Given - simulate having some state
        let originalConversationId = sut.activeConversationId

        // When
        sut.clearConversation()

        // Then
        XCTAssertNotNil(sut.activeConversationId)
        XCTAssertNotEqual(sut.activeConversationId, originalConversationId)
        XCTAssertEqual(sut.currentResponse, "")
        XCTAssertTrue(sut.streamingTokens.isEmpty)
        XCTAssertNil(sut.lastFunctionCall)
        XCTAssertNil(sut.error)
    }

    @MainActor
    func test_regenerateLastResponse_withNoConversation_shouldSetError() async throws {
        // Given - fresh CoachEngine with no conversation history

        // When
        await sut.regenerateLastResponse(for: testUser)

        // Then - should set appropriate error
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.currentResponse.contains("new conversation") || sut.currentResponse.contains("Ask me something"))
    }

    // MARK: - Performance Tests

    @MainActor
    func test_localCommandProcessing_shouldCompleteQuickly() async throws {
        // Given
        let startTime = CFAbsoluteTimeGetCurrent()

        // When
        await sut.processUserMessage("log 8 oz water", for: testUser)

        // Then
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(processingTime, 0.1) // Should complete in < 100ms
        XCTAssertFalse(sut.isProcessing)
    }

    // MARK: - Helper Methods for Testing

    @MainActor
    private func createTestableCoachEngine() -> CoachEngine {
        // Create real implementations for integration testing
        let realLocalCommandParser = LocalCommandParser()
        let realFunctionDispatcher = FunctionCallDispatcher()
        let realPersonaEngine = PersonaEngine()
        let realConversationManager = ConversationManager(modelContext: modelContext)
        let realContextAssembler = ContextAssembler()

        return CoachEngine(
            localCommandParser: realLocalCommandParser,
            functionDispatcher: realFunctionDispatcher,
            personaEngine: realPersonaEngine,
            conversationManager: realConversationManager,
            aiService: mockAIService,
            contextAssembler: realContextAssembler,
            modelContext: modelContext
        )
    }
}

// MARK: - Error Types

enum FunctionError: Error {
    case unknownFunction(String)
}

import XCTest
import SwiftData
import Combine
@testable import AirFit

final class CoachEngineTests: XCTestCase {
    // MARK: - Properties
    var sut: CoachEngine!
    var modelContext: ModelContext!
    var testUser: User!
    var mockAIService: MockAIService!

    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try super.setUp()

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

        // Initialize mock AI service
        mockAIService = MockAIService()

        // Create system under test - integration testing with real components
        sut = createTestableCoachEngine()
    }

    override func tearDown() async throws {
        sut = nil
        modelContext = nil
        testUser = nil
        mockAIService = nil
        try super.tearDown()
    }

    // MARK: - Local Command Integration Tests

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

    func test_regenerateLastResponse_withNoConversation_shouldSetError() async throws {
        // Given - fresh CoachEngine with no conversation history

        // When
        await sut.regenerateLastResponse(for: testUser)

        // Then - should set appropriate error
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.currentResponse.contains("new conversation") || sut.currentResponse.contains("Ask me something"))
    }

    // MARK: - Performance Tests

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

    // MARK: - Direct AI Methods Tests (Phase 3 Implementation)

    func test_parseAndLogNutritionDirect_basicFood_success() async throws {
        // Given
        let foodText = "2 slices whole wheat bread with peanut butter"

        // When
        let result = try await sut.parseAndLogNutritionDirect(
            foodText: foodText,
            for: testUser,
            conversationId: UUID()
        )

        // Then
        XCTAssertGreaterThan(result.items.count, 0, "Should parse at least one item")
        XCTAssertGreaterThan(result.totalCalories, 100, "Should have realistic calories")
        XCTAssertLessThan(result.totalCalories, 1_000, "Should not have excessive calories")
        XCTAssertGreaterThan(result.confidence, 0.5, "Should have reasonable confidence")
        XCTAssertEqual(result.parseStrategy, .directAI, "Should use direct AI strategy")
        XCTAssertGreaterThan(result.tokenCount, 0, "Should track token usage")
        XCTAssertGreaterThan(result.processingTimeMs, 0, "Should track processing time")
    }

    func test_parseAndLogNutritionDirect_emptyInput_throwsError() async throws {
        // Given
        let invalidInput = ""

        // When/Then
        do {
            _ = try await sut.parseAndLogNutritionDirect(
                foodText: invalidInput,
                for: testUser,
                conversationId: UUID()
            )
            XCTFail("Should throw error for empty input")
        } catch {
            XCTAssertTrue(error is CoachEngineError, "Should throw CoachEngineError")
        }
    }

    func test_generateEducationalContentDirect_basicTopic_success() async throws {
        // Given
        let topic = "progressive_overload"
        let userContext = "I'm not seeing strength gains anymore"

        // When
        let result = try await sut.generateEducationalContentDirect(
            topic: topic,
            userContext: userContext,
            for: testUser
        )

        // Then
        XCTAssertEqual(result.topic, topic, "Should preserve topic")
        XCTAssertGreaterThan(result.content.count, 100, "Should generate meaningful content")
        XCTAssertLessThan(result.content.count, 2_000, "Should not be excessively long")
        XCTAssertGreaterThan(result.tokenCount, 0, "Should track token usage")
        XCTAssertGreaterThan(result.personalizationLevel, 0.1, "Should have some personalization")
        XCTAssertNotEqual(result.contentType, .general, "Should classify content type appropriately")
    }

    func test_generateEducationalContentDirect_exerciseTopic_classifiesCorrectly() async throws {
        // Given
        let topic = "deadlift_form"
        let userContext = "I want to improve my deadlift technique"

        // When
        let result = try await sut.generateEducationalContentDirect(
            topic: topic,
            userContext: userContext,
            for: testUser
        )

        // Then
        XCTAssertEqual(result.contentType, .exercise, "Should classify as exercise content")
        XCTAssertTrue(
            result.content.localizedCaseInsensitiveContains("deadlift") ||
                result.content.localizedCaseInsensitiveContains("form"),
            "Content should relate to the topic"
        )
    }

    // MARK: - Helper Methods for Testing

    @MainActor
    private func createTestableCoachEngine() -> CoachEngine {
        // Create real implementations for integration testing
        let realLocalCommandParser = LocalCommandParser()
        let realFunctionDispatcher = FunctionCallDispatcher(
            workoutService: MockAIWorkoutService(),
            analyticsService: MockAIAnalyticsService(),
            goalService: MockAIGoalService()
        )
        let realPersonaEngine = PersonaEngine()
        let realConversationManager = ConversationManager(modelContext: modelContext)
        let realContextAssembler = ContextAssembler()

        return CoachEngine(
            localCommandParser: realLocalCommandParser,
            functionDispatcher: realFunctionDispatcher,
            personaEngine: realPersonaEngine,
            conversationManager: realConversationManager,
            aiService: mockAIService,
            mockContextAssembler: realContextAssembler,
            modelContext: modelContext
        )
    }
}

// MARK: - Error Types

enum FunctionError: Error {
    case unknownFunction(String)
}

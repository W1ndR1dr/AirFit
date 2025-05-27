import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class ConversationManagerPersistenceTests: XCTestCase {
    // MARK: - Properties
    var sut: ConversationManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testUser: User!
    var testConversationId: UUID!

    // MARK: - Setup & Teardown
    override func setUp() async throws {
        await MainActor.run {
            super.setUp()
        }

        // Create in-memory model container for testing
        modelContainer = try ModelContainer.createTestContainer()
        modelContext = modelContainer.mainContext

        // Create test user
        testUser = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            preferredUnits: "metric"
        )
        modelContext.insert(testUser)
        try modelContext.save()

        // Create test conversation ID
        testConversationId = UUID()

        // Initialize system under test
        sut = ConversationManager(modelContext: modelContext)
    }

    override func tearDown() async throws {
        sut = nil
        testUser = nil
        testConversationId = nil
        modelContext = nil
        modelContainer = nil

        await MainActor.run {
            super.tearDown()
        }
    }

    // MARK: - Message Persistence Tests

    func test_saveUserMessage_givenValidInput_shouldPersistMessage() async throws {
        // Arrange
        let content = "Hello, I need help with my nutrition plan"

        // Act
        let savedMessage = try await sut.saveUserMessage(
            content,
            for: testUser,
            conversationId: testConversationId
        )

        // Assert
        XCTAssertEqual(savedMessage.content, content)
        XCTAssertEqual(savedMessage.role, MessageRole.user.rawValue)
        XCTAssertEqual(savedMessage.conversationID, testConversationId)
        XCTAssertEqual(savedMessage.user?.id, testUser.id)
        XCTAssertNotNil(savedMessage.id)
        XCTAssertTrue(savedMessage.timestamp.timeIntervalSinceNow > -1) // Recent timestamp

        // Verify persistence
        let descriptor = FetchDescriptor<CoachMessage>()
        let messages = try modelContext.fetch(descriptor)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.id, savedMessage.id)
    }

    func test_saveUserMessage_withLargeContent_shouldPersistCorrectly() async throws {
        // Arrange
        let largeContent = String(repeating: "This is a very long message content. ", count: 1_000)

        // Act
        let savedMessage = try await sut.saveUserMessage(
            largeContent,
            for: testUser,
            conversationId: testConversationId
        )

        // Assert
        XCTAssertEqual(savedMessage.content, largeContent)
        XCTAssertEqual(savedMessage.content.count, largeContent.count)

        // Verify external storage attribute works for large content
        let descriptor = FetchDescriptor<CoachMessage>()
        let messages = try modelContext.fetch(descriptor)
        XCTAssertEqual(messages.first?.content, largeContent)
    }

    func test_createAssistantMessage_withBasicContent_shouldPersistCorrectly() async throws {
        // Arrange
        let content = "Based on your goals, I recommend focusing on protein intake."

        // Act
        let assistantMessage = try await sut.createAssistantMessage(
            content,
            for: testUser,
            conversationId: testConversationId
        )

        // Assert
        XCTAssertEqual(assistantMessage.content, content)
        XCTAssertEqual(assistantMessage.role, MessageRole.assistant.rawValue)
        XCTAssertEqual(assistantMessage.conversationID, testConversationId)
        XCTAssertEqual(assistantMessage.user?.id, testUser.id)
        XCTAssertNil(assistantMessage.functionCallData)
        XCTAssertNil(assistantMessage.modelUsed)
        XCTAssertNil(assistantMessage.wasHelpful)
    }

    func test_createAssistantMessage_withFunctionCall_shouldStoreFunctionCallData() async throws {
        // Arrange
        let content = "I'll log your water intake now."
        let functionCall = FunctionCall(
            name: "logWaterIntake",
            arguments: ["amount": 16, "unit": "oz"]
        )

        // Act
        let assistantMessage = try await sut.createAssistantMessage(
            content,
            for: testUser,
            conversationId: testConversationId,
            functionCall: functionCall
        )

        // Assert
        XCTAssertEqual(assistantMessage.content, content)
        XCTAssertNotNil(assistantMessage.functionCallData)

        // Verify function call can be decoded
        let decodedCall = assistantMessage.functionCall
        XCTAssertNotNil(decodedCall)
        XCTAssertEqual(decodedCall?.name, "logWaterIntake")
        XCTAssertEqual(decodedCall?.arguments["amount"]?.value as? Int, 16)
        XCTAssertEqual(decodedCall?.arguments["unit"]?.value as? String, "oz")
    }

    func test_createAssistantMessage_withLocalCommand_shouldMarkAsLocalCommand() async throws {
        // Arrange
        let content = "Here's your daily summary."

        // Act
        let assistantMessage = try await sut.createAssistantMessage(
            content,
            for: testUser,
            conversationId: testConversationId,
            isLocalCommand: true
        )

        // Assert
        XCTAssertEqual(assistantMessage.modelUsed, "local_command")
    }

    func test_createAssistantMessage_withError_shouldMarkAsUnhelpful() async throws {
        // Arrange
        let content = "I'm sorry, I encountered an error processing your request."

        // Act
        let assistantMessage = try await sut.createAssistantMessage(
            content,
            for: testUser,
            conversationId: testConversationId,
            isError: true
        )

        // Assert
        XCTAssertEqual(assistantMessage.wasHelpful, false)
    }

    func test_recordAIMetadata_givenValidMessage_shouldUpdateMetadata() async throws {
        // Arrange
        let message = try await sut.saveUserMessage(
            "Test message",
            for: testUser,
            conversationId: testConversationId
        )

        // Act
        try await sut.recordAIMetadata(
            for: message,
            model: "gpt-4",
            tokens: (prompt: 100, completion: 50),
            temperature: 0.7,
            responseTime: 2.5
        )

        // Assert
        XCTAssertEqual(message.modelUsed, "gpt-4")
        XCTAssertEqual(message.promptTokens, 100)
        XCTAssertEqual(message.completionTokens, 50)
        XCTAssertEqual(message.totalTokens, 150)
        XCTAssertEqual(message.temperature, 0.7)
        XCTAssertEqual(message.responseTimeMs, 2_500)

        // Verify estimated cost calculation
        XCTAssertNotNil(message.estimatedCost)
        XCTAssertEqual(message.estimatedCost!, 0.0045, accuracy: 0.0001) // 150/1000 * 0.03
    }
}

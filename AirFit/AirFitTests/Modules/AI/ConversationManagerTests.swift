import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class ConversationManagerTests: XCTestCase {
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

    // MARK: - Core Functionality Tests

    func test_getRecentMessages_withNoMessages_shouldReturnEmptyArray() async throws {
        // Act
        let messages = try await sut.getRecentMessages(
            for: testUser,
            conversationId: testConversationId
        )

        // Assert
        XCTAssertTrue(messages.isEmpty)
    }

    func test_getRecentMessages_withMultipleMessages_shouldReturnInChronologicalOrder() async throws {
        // Arrange
        let message1 = try await sut.saveUserMessage(
            "First message",
            for: testUser,
            conversationId: testConversationId
        )

        // Small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 10_000_000)

        let message2 = try await sut.createAssistantMessage(
            "Assistant response",
            for: testUser,
            conversationId: testConversationId
        )

        // Act
        let messages = try await sut.getRecentMessages(
            for: testUser,
            conversationId: testConversationId
        )

        // Assert
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].id, message1.id)
        XCTAssertEqual(messages[1].id, message2.id)

        // Verify chronological order
        XCTAssertTrue(messages[0].timestamp <= messages[1].timestamp)
    }

    func test_deleteConversation_shouldRemoveAllMessages() async throws {
        // Arrange
        try await sut.saveUserMessage("Message 1", for: testUser, conversationId: testConversationId)
        try await sut.createAssistantMessage("Response 1", for: testUser, conversationId: testConversationId)

        // Verify messages exist
        let messagesBefore = try await sut.getRecentMessages(for: testUser, conversationId: testConversationId)
        XCTAssertEqual(messagesBefore.count, 2)

        // Act
        try await sut.deleteConversation(for: testUser, conversationId: testConversationId)

        // Assert
        let messagesAfter = try await sut.getRecentMessages(for: testUser, conversationId: testConversationId)
        XCTAssertTrue(messagesAfter.isEmpty)
    }

    func test_getConversationIds_withNoConversations_shouldReturnEmpty() async throws {
        // Act
        let conversationIds = try await sut.getConversationIds(for: testUser)

        // Assert
        XCTAssertTrue(conversationIds.isEmpty)
    }

    func test_getConversationStats_withNoMessages_shouldReturnZeroStats() async throws {
        // Act
        let stats = try await sut.getConversationStats(
            for: testUser,
            conversationId: testConversationId
        )

        // Assert
        XCTAssertEqual(stats.totalMessages, 0)
        XCTAssertEqual(stats.userMessages, 0)
        XCTAssertEqual(stats.assistantMessages, 0)
        XCTAssertEqual(stats.totalTokens, 0)
        XCTAssertEqual(stats.estimatedCost, 0)
        XCTAssertNil(stats.firstMessageDate)
        XCTAssertNil(stats.lastMessageDate)
        XCTAssertEqual(stats.averageTokensPerMessage, 0)
        XCTAssertEqual(stats.costPerMessage, 0)
    }
}

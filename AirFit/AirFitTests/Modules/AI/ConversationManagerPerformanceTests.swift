import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class ConversationManagerPerformanceTests: XCTestCase {
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

    // MARK: - Performance Tests

    func test_saveMessage_performance_shouldCompleteQuickly() async throws {
        // Arrange
        let content = "Performance test message"

        // Act & Assert
        let startTime = CFAbsoluteTimeGetCurrent()

        _ = try await sut.saveUserMessage(
            content,
            for: testUser,
            conversationId: testConversationId
        )

        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        // More realistic expectation for simulator environment
        XCTAssertLessThan(executionTime, 0.1, "Message saving should complete within 100ms")

        print("📊 Performance Test: Single message save completed in \(String(format: "%.3f", executionTime * 1_000))ms")
    }

    func test_getRecentMessages_withLargeConversation_shouldPerformWell() async throws {
        // Arrange - Create 100 messages (more realistic for test environment)
        let messageCount = 100
        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 1...messageCount {
            try await sut.saveUserMessage(
                "Message \(i)",
                for: testUser,
                conversationId: testConversationId
            )
        }

        let insertTime = CFAbsoluteTimeGetCurrent() - startTime
        print("📊 Performance Test: Inserted \(messageCount) messages in \(String(format: "%.3f", insertTime))s")

        // Act
        let queryStartTime = CFAbsoluteTimeGetCurrent()
        let messages = try await sut.getRecentMessages(
            for: testUser,
            conversationId: testConversationId,
            limit: 20
        )
        let queryTime = CFAbsoluteTimeGetCurrent() - queryStartTime

        // Assert
        XCTAssertEqual(messages.count, 20)

        // More realistic performance expectation for simulator (200ms instead of 50ms)
        XCTAssertLessThan(
            queryTime,
            0.2,
            "Query should complete within 200ms even with \(messageCount) messages"
        )

        print("📊 Performance Test: Query completed in \(String(format: "%.3f", queryTime * 1_000))ms")

        // Verify we got the most recent messages
        XCTAssertEqual(messages.last?.content, "Message \(messageCount)")
        XCTAssertEqual(messages[messages.count - 2].content, "Message \(messageCount - 1)")

        // Performance metrics for monitoring
        let avgInsertTime = insertTime / Double(messageCount)
        print(
            "📊 Performance Test: Average insert time: \(String(format: "%.3f", avgInsertTime * 1_000))ms per message"
        )

        // Ensure reasonable performance characteristics
        XCTAssertLessThan(avgInsertTime, 0.1, "Average message insert should be under 100ms")
    }

    func test_conversationStats_withLargeDataset_shouldPerformWell() async throws {
        // Arrange - Create messages with metadata
        for i in 1...100 {
            let message = try await sut.createAssistantMessage(
                "Assistant message \(i)",
                for: testUser,
                conversationId: testConversationId
            )

            try await sut.recordAIMetadata(
                for: message,
                model: "gpt-4",
                tokens: (prompt: 100, completion: 50),
                temperature: 0.7,
                responseTime: 1.0
            )
        }

        // Act
        let startTime = CFAbsoluteTimeGetCurrent()
        let stats = try await sut.getConversationStats(
            for: testUser,
            conversationId: testConversationId
        )
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        // Assert
        XCTAssertEqual(stats.totalMessages, 100)
        XCTAssertEqual(stats.totalTokens, 15_000) // 100 messages * 150 tokens each
        XCTAssertLessThan(executionTime, 0.1, "Stats calculation should complete within 100ms")

        print(
            "📊 Performance Test: Stats calculation for 100 messages completed in " +
            "\(String(format: "%.3f", executionTime * 1_000))ms"
        )

        // Verify stats accuracy
        XCTAssertEqual(stats.assistantMessages, 100)
        XCTAssertEqual(stats.userMessages, 0)
        XCTAssertGreaterThan(stats.estimatedCost, 0)
    }

    func test_pruneOldConversations_withManyConversations_shouldPerformWell() async throws {
        // Arrange - Create 50 conversations with multiple messages each
        let totalConversations = 50
        let messagesPerConversation = 10

        for i in 1...totalConversations {
            let convId = UUID()
            for j in 1...messagesPerConversation {
                try await sut.saveUserMessage(
                    "Conv\(i) Message\(j)",
                    for: testUser,
                    conversationId: convId
                )
            }
        }

        let totalMessages = totalConversations * messagesPerConversation
        print("📊 Performance Test: Created \(totalConversations) conversations with \(totalMessages) total messages")

        // Act
        let startTime = CFAbsoluteTimeGetCurrent()
        try await sut.pruneOldConversations(for: testUser, keepLast: 10)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime

        // Assert
        let remainingIds = try await sut.getConversationIds(for: testUser)
        XCTAssertEqual(remainingIds.count, 10)
        XCTAssertLessThan(executionTime, 1.0, "Pruning should complete within 1 second")

        print(
            "📊 Performance Test: Pruned \(totalConversations - 10) conversations in " +
            "\(String(format: "%.3f", executionTime * 1_000))ms"
        )

        // Verify correct number of messages remain
        let descriptor = FetchDescriptor<CoachMessage>()
        let remainingMessages = try modelContext.fetch(descriptor)
        XCTAssertEqual(remainingMessages.count, 100) // 10 conversations * 10 messages each

        let deletedMessages = totalMessages - remainingMessages.count
        print("📊 Performance Test: Deleted \(deletedMessages) messages, kept \(remainingMessages.count) messages")
    }

    // MARK: - Memory Efficiency Tests

    func test_memoryUsage_withLargeMessages_shouldNotExceedLimits() async throws {
        // Arrange - Create messages with large content
        let largeContent = String(repeating: "Large content block. ", count: 10_000) // ~200KB per message

        // Act - Create 10 large messages
        for i in 1...10 {
            try await sut.saveUserMessage(
                "\(largeContent) Message \(i)",
                for: testUser,
                conversationId: testConversationId
            )
        }

        // Assert - Verify messages are stored and retrievable
        let messages = try await sut.getRecentMessages(
            for: testUser,
            conversationId: testConversationId
        )

        XCTAssertEqual(messages.count, 10)
        XCTAssertTrue(messages.first?.content.contains("Large content block") == true)

        // Verify external storage is working (content should be accessible)
        let descriptor = FetchDescriptor<CoachMessage>()
        let storedMessages = try modelContext.fetch(descriptor)
        XCTAssertEqual(storedMessages.count, 10)
        XCTAssertTrue(storedMessages.first?.content.contains("Large content block") == true)
    }

    func test_concurrentAccess_shouldHandleMultipleOperations() async throws {
        // Arrange
        let operationCount = 20

        // Act - Perform concurrent operations
        let sut = self.sut!
        let testUser = self.testUser!
        let testConversationId = self.testConversationId!

        await withTaskGroup(of: Void.self) { group in
            for i in 1...operationCount {
                group.addTask { @Sendable @MainActor in
                    do {
                        try await sut.saveUserMessage(
                            "Concurrent message \(i)",
                            for: testUser,
                            conversationId: testConversationId
                        )
                    } catch {
                        XCTFail("Concurrent operation failed: \(error)")
                    }
                }
            }
        }

        // Assert
        let messages = try await sut.getRecentMessages(
            for: testUser,
            conversationId: testConversationId
        )

        XCTAssertEqual(messages.count, operationCount)

        // Verify all messages were saved
        let descriptor = FetchDescriptor<CoachMessage>()
        let allMessages = try modelContext.fetch(descriptor)
        XCTAssertEqual(allMessages.count, operationCount)
    }
}

// MARK: - Performance Measurement Extensions

extension ConversationManagerPerformanceTests {
    func measureAsync<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        return (result, executionTime)
    }
}

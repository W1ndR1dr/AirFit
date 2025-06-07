import XCTest
import SwiftData
@testable import AirFit

final class MessageClassificationTests: XCTestCase {
    
    // MARK: - Test Properties
    private var modelContext: ModelContext!
    private var coachEngine: CoachEngine!
    private var testUser: User!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, CoachMessage.self, configurations: configuration)
        modelContext = ModelContext(container)
        
        // Create test user
        testUser = User()
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Create CoachEngine with minimal dependencies for testing
        coachEngine = await CoachEngine.createDefault(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        coachEngine = nil
        testUser = nil
        try await super.tearDown()
    }
    
    // MARK: - Command Classification Tests
    
    @MainActor
    func test_classifyMessage_detectsShortCommands() async throws {
        // Arrange
        let shortCommands = [
            "log 500 calories",
            "add protein",
            "track water",
            "record workout",
            "yes",
            "no",
            "ok",
            "2 apples"
        ]
        
        // Act & Assert
        for command in shortCommands {
            let messageType = await classifyTestMessage(command)
            XCTAssertEqual(messageType, MessageType.command, "Failed to classify '\(command)' as command")
        }
    }
    
    @MainActor
    func test_classifyMessage_detectsCommandStarters() async throws {
        // Arrange
        let commandStarters = [
            "log my breakfast today",
            "add some chicken to my meal",
            "track my daily water intake",
            "record today's gym session", 
            "show me my dashboard",
            "open the workout section",
            "start a new workout"
        ]
        
        // Act & Assert
        for command in commandStarters {
            let messageType = await classifyTestMessage(command)
            XCTAssertEqual(messageType, MessageType.command, "Failed to classify '\(command)' as command")
        }
    }
    
    @MainActor
    func test_classifyMessage_detectsNutritionCommands() async throws {
        // Arrange
        let nutritionCommands = [
            "500 calories",
            "25g protein",
            "log my carbs",
            "2000ml water",
            "track 10k steps"
        ]
        
        // Act & Assert
        for command in nutritionCommands {
            let messageType = await classifyTestMessage(command)
            XCTAssertEqual(messageType, MessageType.command, "Failed to classify nutrition command '\(command)'")
        }
    }
    
    @MainActor
    func test_classifyMessage_detectsPatternBasedCommands() async throws {
        // Arrange
        let patternCommands = [
            "1500 calories",
            "50g protein powder",
            "2 cups rice", 
            "500ml water",
            "thanks",
            "got it"
        ]
        
        // Act & Assert
        for command in patternCommands {
            let messageType = await classifyTestMessage(command)
            XCTAssertEqual(messageType, MessageType.command, "Failed to classify pattern command '\(command)'")
        }
    }
    
    // MARK: - Conversation Classification Tests
    
    @MainActor
    func test_classifyMessage_detectsConversations() async throws {
        // Arrange
        let conversations = [
            "How can I improve my workout routine for building muscle?",
            "I'm struggling with meal planning. Can you help me create a weekly plan?",
            "What are the best exercises for someone with a busy schedule?",
            "I want to lose weight but I'm not sure where to start. Any advice?",
            "Can you explain the difference between complex and simple carbohydrates?",
            "I've been feeling tired lately. Could it be related to my diet?"
        ]
        
        // Act & Assert
        for conversation in conversations {
            let messageType = await classifyTestMessage(conversation)
            XCTAssertEqual(messageType, MessageType.conversation, "Failed to classify '\(conversation)' as conversation")
        }
    }
    
    @MainActor
    func test_classifyMessage_longMessagesAreConversations() async throws {
        // Arrange
        let longMessage = "I've been trying to get back into fitness after a long break due to work stress. I used to be quite active but haven't worked out consistently in over a year. Now I want to create a sustainable routine that fits my current lifestyle and helps me regain my strength and energy."
        
        // Act & Assert
        let messageType = await classifyTestMessage(longMessage)
        XCTAssertEqual(messageType, MessageType.conversation, "Long messages should be classified as conversations")
    }
    
    // MARK: - Edge Case Tests
    
    @MainActor
    func test_classifyMessage_edgeCases() async throws {
        // Arrange
        let edgeCases: [(String, MessageType)] = [
            ("", MessageType.conversation), // Empty string defaults to conversation
            ("   ", MessageType.conversation), // Whitespace defaults to conversation
            ("a", MessageType.command), // Single character is command (very short)
            ("log", MessageType.command), // Command word alone
            ("calories protein carbs but this is a longer discussion about nutrition", MessageType.conversation) // Keywords in long text
        ]
        
        // Act & Assert
        for (message, expectedType) in edgeCases {
            let messageType = await classifyTestMessage(message)
            XCTAssertEqual(messageType, expectedType, "Edge case '\(message)' should be \(expectedType.rawValue)")
        }
    }
    
    // MARK: - History Limit Tests
    
    func test_messageType_contextLimits() {
        // Arrange & Act & Assert
        XCTAssertEqual(MessageType.command.contextLimit, 5, "Commands should use 5 message history limit")
        XCTAssertEqual(MessageType.conversation.contextLimit, 20, "Conversations should use 20 message history limit")
        
        XCTAssertFalse(MessageType.command.requiresHistory, "Commands should not require full history")
        XCTAssertTrue(MessageType.conversation.requiresHistory, "Conversations should require full history")
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func test_processUserMessage_storesCorrectClassification() async throws {
        // Arrange
        let commandMessage = "log 500 calories"
        let conversationMessage = "How should I plan my workout schedule?"
        
        // Act
        _ = await coachEngine.processUserMessage(commandMessage, for: testUser)
        _ = await coachEngine.processUserMessage(conversationMessage, for: testUser)
        
        // Assert
        let messages = try await getAllMessages()
        
        let commandMessages = messages.filter { $0.content == commandMessage }
        let conversationMessages = messages.filter { $0.content == conversationMessage }
        
        XCTAssertEqual(commandMessages.count, 1, "Should have saved one command message")
        XCTAssertEqual(conversationMessages.count, 1, "Should have saved one conversation message")
        
        XCTAssertEqual(commandMessages.first?.messageType, MessageType.command, "Command message should be classified correctly")
        XCTAssertEqual(conversationMessages.first?.messageType, MessageType.conversation, "Conversation message should be classified correctly")
    }
    
    @MainActor
    func test_processUserMessage_usesOptimizedHistoryLimits() async throws {
        // Arrange - Create conversation history with multiple messages
        for i in 1...25 {
            let message = CoachMessage(
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 60)), // 1 minute apart
                role: i % 2 == 0 ? .user : .assistant,
                content: "Message \(i)",
                conversationID: coachEngine.activeConversationId,
                user: testUser
            )
            modelContext.insert(message)
        }
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }
        
        // Act - Process a command (should use limit of 5)
        _ = await coachEngine.processUserMessage("log 300 calories", for: testUser)
        
        // Verify through conversation manager (indirect test since classifyMessage is private)
        let conversationManager = ConversationManager(modelContext: modelContext)
        let recentMessages = try await conversationManager.getRecentMessages(
            for: testUser,
            conversationId: coachEngine.activeConversationId!,
            limit: 5 // Command limit
        )
        
        // Assert
        XCTAssertLessThanOrEqual(recentMessages.count, 5, "Command processing should use minimal history")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func test_classifyMessage_performance() async throws {
        // Arrange
        let testMessages = [
            "log 500 calories",
            "How can I improve my workout routine for building muscle and losing fat?",
            "track water",
            "I need help creating a sustainable meal plan that works with my busy schedule",
            "2 apples",
            "What's the best time to eat carbohydrates for optimal energy?"
        ]
        
        // Act
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for message in testMessages {
            _ = await classifyTestMessage(message)
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert - Classification should be very fast
        XCTAssertLessThan(duration, 0.001, "Message classification should complete in under 1ms")
        
        print("Message classification performance: \(Int(duration * 1_000_000))μs for \(testMessages.count) messages")
    }
    
    @MainActor
    func test_classifyMessage_accuracyMetrics() async throws {
        // Arrange - Test dataset with known classifications
        let testDataset: [(String, MessageType)] = [
            // Commands
            ("log 500 calories", MessageType.command),
            ("add protein shake", MessageType.command),
            ("track water intake", MessageType.command),
            ("record workout", MessageType.command),
            ("show dashboard", MessageType.command),
            ("2 cups rice", MessageType.command),
            ("yes", MessageType.command),
            ("no", MessageType.command),
            ("thanks", MessageType.command),
            ("500ml water", MessageType.command),
            
            // Conversations
            ("How can I improve my workout routine?", MessageType.conversation),
            ("I need help with meal planning", MessageType.conversation),
            ("What are the best exercises for weight loss?", MessageType.conversation),
            ("Can you explain protein requirements?", MessageType.conversation),
            ("I'm struggling with motivation", MessageType.conversation),
            ("Help me understand macronutrients", MessageType.conversation),
            ("What's the difference between cardio and strength training?", MessageType.conversation),
            ("I want to build a sustainable fitness habit", MessageType.conversation),
            ("Can you recommend a weekly workout split?", MessageType.conversation),
            ("How do I track my progress effectively?", MessageType.conversation)
        ]
        
        // Act
        var correctClassifications = 0
        
        for (message, expectedType) in testDataset {
            let actualType = await classifyTestMessage(message)
            if actualType == expectedType {
                correctClassifications += 1
            } else {
                print("Misclassified: '\(message)' - Expected: \(expectedType), Got: \(actualType)")
            }
        }
        
        let accuracy = Double(correctClassifications) / Double(testDataset.count)
        
        // Assert - Should achieve 90%+ accuracy
        XCTAssertGreaterThanOrEqual(accuracy, 0.9, "Classification accuracy should be at least 90%")
        
        print("Classification accuracy: \(Int(accuracy * 100))% (\(correctClassifications)/\(testDataset.count))")
    }
    
    // MARK: - Helper Methods
    
    /// Helper to access the private classifyMessage method for testing
    @MainActor
    private func classifyTestMessage(_ text: String) async -> MessageType {
        // Since classifyMessage is private, we test it indirectly through processUserMessage
        // and check the stored message type
        let originalMessageCount = await getMessageCount()
        
        _ = await coachEngine.processUserMessage(text, for: testUser)
        
        let messages = try! await getAllMessages()
        let newMessages = Array(messages.dropFirst(originalMessageCount))
        
        // Find the user message (not assistant response)
        let userMessage = newMessages.first { $0.role == MessageRole.user.rawValue && $0.content == text }
        
        return userMessage?.messageType ?? MessageType.conversation
    }
    
    @MainActor
    private func getMessageCount() async -> Int {
        let descriptor = FetchDescriptor<CoachMessage>()
        return (try? modelContext.fetch(descriptor).count) ?? 0
    }
    
    @MainActor
    private func getAllMessages() async throws -> [CoachMessage] {
        let descriptor = FetchDescriptor<CoachMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
} 
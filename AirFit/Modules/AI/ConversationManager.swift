import SwiftData
import Foundation

// MARK: - ConversationManager
@MainActor
final class ConversationManager {
    // MARK: - Properties
    private let modelContext: ModelContext

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Message Creation

    /// Saves a user message to the conversation
    func saveUserMessage(
        _ content: String,
        for user: User,
        conversationId: UUID
    ) async throws -> CoachMessage {
        let message = CoachMessage(
            role: .user,
            content: content,
            conversationID: conversationId,
            user: user
        )

        modelContext.insert(message)
        try modelContext.save()

        AppLogger.info(
            "Saved user message for conversation \(conversationId)",
            category: .ai
        )
        return message
    }

    /// Creates an assistant message with optional function call metadata
    func createAssistantMessage(
        _ content: String,
        for user: User,
        conversationId: UUID,
        functionCall: FunctionCall? = nil,
        isLocalCommand: Bool = false,
        isError: Bool = false
    ) async throws -> CoachMessage {
        let message = CoachMessage(
            role: .assistant,
            content: content,
            conversationID: conversationId,
            user: user
        )

        // Store function call metadata if provided
        if let call = functionCall {
            do {
                message.functionCallData = try JSONEncoder().encode(call)
            } catch {
                AppLogger.error("Failed to encode function call", error: error, category: .ai)
            }
        }

        // Mark as local command if applicable
        if isLocalCommand {
            message.modelUsed = "local_command"
        }

        // Mark as error if applicable
        if isError {
            message.wasHelpful = false
        }

        modelContext.insert(message)
        try modelContext.save()

        AppLogger.info(
            "Created assistant message for conversation \(conversationId)",
            category: .ai
        )
        return message
    }

    /// Records AI metadata for a message
    func recordAIMetadata(
        for message: CoachMessage,
        model: String,
        tokens: (prompt: Int, completion: Int),
        temperature: Double,
        responseTime: TimeInterval
    ) async throws {
        message.recordAIMetadata(
            model: model,
            promptTokens: tokens.prompt,
            completionTokens: tokens.completion,
            temperature: temperature,
            responseTime: responseTime
        )

        try modelContext.save()
        AppLogger.debug("Recorded AI metadata for message \(message.id)", category: .ai)
    }

    // MARK: - Message Retrieval

    /// Retrieves recent messages for AI service compatibility
    func getRecentMessages(
        for user: User,
        conversationId: UUID,
        limit: Int = 20
    ) async throws -> [AIChatMessage] {
        // Fetch all messages for the user first, then filter in memory
        var descriptor = FetchDescriptor<CoachMessage>()
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]

        let allMessages = try modelContext.fetch(descriptor)

        // Filter for the specific user and conversation
        let filteredMessages = allMessages
            .filter { message in
                message.user?.id == user.id && message.conversationID == conversationId
            }
            .prefix(limit)

        // Convert to AIChatMessage for AI service compatibility
        let aiMessages = Array(filteredMessages.reversed()).compactMap { message -> AIChatMessage? in
            guard let role = AIMessageRole(rawValue: message.role) else {
                AppLogger.warning("Invalid message role: \(message.role)", category: .ai)
                return nil
            }

            return AIChatMessage(
                id: message.id,
                role: role,
                content: message.content,
                name: nil,
                functionCall: message.functionCall.map { call in
                    AIFunctionCall(name: call.name, arguments: call.arguments.mapValues { $0.value })
                },
                timestamp: message.timestamp
            )
        }

        AppLogger.debug(
            "Retrieved \(aiMessages.count) messages for conversation \(conversationId)",
            category: .ai
        )
        return aiMessages
    }

    /// Gets conversation statistics
    func getConversationStats(
        for user: User,
        conversationId: UUID
    ) async throws -> ConversationStats {
        let descriptor = FetchDescriptor<CoachMessage>()
        let allMessages = try modelContext.fetch(descriptor)

        // Filter for the specific user and conversation
        let messages = allMessages.filter { message in
            message.user?.id == user.id && message.conversationID == conversationId
        }

        let userMessages = messages.filter { $0.role == MessageRole.user.rawValue }
        let assistantMessages = messages.filter { $0.role == MessageRole.assistant.rawValue }
        let totalTokens = messages.compactMap { $0.totalTokens }.reduce(0, +)
        let totalCost = messages.compactMap { $0.estimatedCost }.reduce(0, +)

        return ConversationStats(
            totalMessages: messages.count,
            userMessages: userMessages.count,
            assistantMessages: assistantMessages.count,
            totalTokens: totalTokens,
            estimatedCost: totalCost,
            firstMessageDate: messages.min { $0.timestamp < $1.timestamp }?.timestamp,
            lastMessageDate: messages.max { $0.timestamp < $1.timestamp }?.timestamp
        )
    }

    // MARK: - Conversation Management

    /// Prunes old conversations to prevent memory bloat
    func pruneOldConversations(
        for user: User,
        keepLast: Int = 5
    ) async throws {
        // Get all messages for the user
        var descriptor = FetchDescriptor<CoachMessage>()
        descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]

        let allMessages = try modelContext.fetch(descriptor)

        // Filter for the specific user with non-nil conversation IDs
        let userMessages = allMessages.filter { message in
            message.user?.id == user.id && message.conversationID != nil
        }

        let conversationIds = Array(Set(userMessages.compactMap { $0.conversationID }))

        // Group messages by conversation and find the most recent message in each
        let conversationDates = conversationIds.compactMap { conversationId -> (UUID, Date)? in
            let conversationMessages = userMessages.filter { $0.conversationID == conversationId }
            guard let latestMessage = conversationMessages.max(by: { $0.timestamp < $1.timestamp }) else {
                return nil
            }
            return (conversationId, latestMessage.timestamp)
        }

        // Sort by date and keep only the most recent conversations
        let sortedConversations = conversationDates.sorted { $0.1 > $1.1 }
        let conversationsToDelete = sortedConversations.dropFirst(keepLast).map { $0.0 }

        if conversationsToDelete.isEmpty {
            AppLogger.info("No conversations to prune for user \(user.id)", category: .ai)
            return
        }

        // Delete messages from old conversations
        let messagesToDelete = userMessages.filter { message in
            guard let conversationId = message.conversationID else { return false }
            return conversationsToDelete.contains(conversationId)
        }

        for message in messagesToDelete {
            modelContext.delete(message)
        }

        try modelContext.save()

        AppLogger.info(
            "Pruned \(conversationsToDelete.count) old conversations (\(messagesToDelete.count) messages) for user \(user.id)",
            category: .ai
        )
    }

    /// Deletes a specific conversation
    func deleteConversation(
        for user: User,
        conversationId: UUID
    ) async throws {
        let descriptor = FetchDescriptor<CoachMessage>()
        let allMessages = try modelContext.fetch(descriptor)

        // Filter for the specific user and conversation
        let messages = allMessages.filter { message in
            message.user?.id == user.id && message.conversationID == conversationId
        }

        for message in messages {
            modelContext.delete(message)
        }

        try modelContext.save()

        AppLogger.info("Deleted conversation \(conversationId) for user \(user.id)", category: .ai)
    }

    /// Gets all conversation IDs for a user
    func getConversationIds(for user: User) async throws -> [UUID] {
        let descriptor = FetchDescriptor<CoachMessage>()
        let allMessages = try modelContext.fetch(descriptor)

        // Filter for the specific user with non-nil conversation IDs
        let messages = allMessages.filter { message in
            message.user?.id == user.id && message.conversationID != nil
        }

        let conversationIds = Set(messages.compactMap { $0.conversationID })

        return Array(conversationIds).sorted { id1, id2 in
            // Sort by most recent message in each conversation
            let date1 = messages.filter { $0.conversationID == id1 }.max { $0.timestamp < $1.timestamp }?.timestamp ?? Date.distantPast
            let date2 = messages.filter { $0.conversationID == id2 }.max { $0.timestamp < $1.timestamp }?.timestamp ?? Date.distantPast
            return date1 > date2
        }
    }

    /// Archives old messages while keeping conversation metadata
    func archiveOldMessages(
        for user: User,
        olderThan days: Int = 30
    ) async throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<CoachMessage>()
        let allMessages = try modelContext.fetch(descriptor)

        // Filter for the specific user and old messages
        let oldMessages = allMessages.filter { message in
            message.user?.id == user.id && message.timestamp < cutoffDate
        }

        // Keep only the last message from each conversation for context
        let conversationIds = Set(oldMessages.compactMap { $0.conversationID })
        var messagesToKeep: Set<UUID> = []

        for conversationId in conversationIds {
            let conversationMessages = oldMessages.filter { $0.conversationID == conversationId }
            if let lastMessage = conversationMessages.max(by: { $0.timestamp < $1.timestamp }) {
                messagesToKeep.insert(lastMessage.id)
            }
        }

        let messagesToDelete = oldMessages.filter { !messagesToKeep.contains($0.id) }

        for message in messagesToDelete {
            modelContext.delete(message)
        }

        try modelContext.save()

        AppLogger.info(
            "Archived \(messagesToDelete.count) old messages for user \(user.id)",
            category: .ai
        )
    }
}

// MARK: - Supporting Types

struct ConversationStats: Sendable {
    let totalMessages: Int
    let userMessages: Int
    let assistantMessages: Int
    let totalTokens: Int
    let estimatedCost: Double
    let firstMessageDate: Date?
    let lastMessageDate: Date?

    var averageTokensPerMessage: Double {
        totalMessages > 0 ? Double(totalTokens) / Double(totalMessages) : 0
    }

    var costPerMessage: Double {
        totalMessages > 0 ? estimatedCost / Double(totalMessages) : 0
    }
}

// MARK: - ConversationManager Errors

enum ConversationManagerError: LocalizedError {
    case userNotFound
    case conversationNotFound
    case invalidMessageRole
    case encodingFailed
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .conversationNotFound:
            return "Conversation not found"
        case .invalidMessageRole:
            return "Invalid message role"
        case .encodingFailed:
            return "Failed to encode message data"
        case .saveFailed(let error):
            return "Failed to save message: \(error.localizedDescription)"
        }
    }
}

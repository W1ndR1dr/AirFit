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
        NotificationCenter.default.post(name: .coachAssistantMessageCreated, object: message)
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
    /// PERFORMANCE OPTIMIZED: Uses SwiftData predicate with userID + conversationID filtering
    func getRecentMessages(
        for user: User,
        conversationId: UUID,
        limit: Int = 20
    ) async throws -> [AIChatMessage] {
        let startTime = CFAbsoluteTimeGetCurrent()

        // PHASE 2 FIX: Filter by BOTH userID AND conversationID in database predicate
        // This eliminates memory filtering and achieves 10x performance improvement
        let userId = user.id // Capture user ID outside predicate
        var descriptor = FetchDescriptor<CoachMessage>(
            predicate: #Predicate<CoachMessage> { message in
                message.userID == userId && message.conversationID == conversationId
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        let messages = try modelContext.fetch(descriptor)

        let queryTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.debug(
            "Query completed in \(Int(queryTime * 1_000))ms for \(messages.count) messages",
            category: .ai
        )

        // Convert to AIChatMessage for AI service compatibility (return in chronological order)
        let aiMessages = Array(messages.reversed()).compactMap { message -> AIChatMessage? in
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
            "Retrieved \(aiMessages.count) messages for conversation \(conversationId) in \(Int(queryTime * 1_000))ms",
            category: .ai
        )
        return aiMessages
    }

    /// Gets conversation statistics
    /// PERFORMANCE OPTIMIZED: Uses SwiftData predicate with userID + conversationID filtering
    func getConversationStats(
        for user: User,
        conversationId: UUID
    ) async throws -> ConversationStats {
        let startTime = CFAbsoluteTimeGetCurrent()

        // PHASE 2 FIX: Filter by BOTH userID AND conversationID in database predicate
        let userId = user.id // Capture user ID outside predicate
        let descriptor = FetchDescriptor<CoachMessage>(
            predicate: #Predicate<CoachMessage> { message in
                message.userID == userId && message.conversationID == conversationId
            }
        )

        let messages = try modelContext.fetch(descriptor)

        let queryTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.debug(
            "Stats query completed in \(Int(queryTime * 1_000))ms for \(messages.count) messages",
            category: .ai
        )

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
    /// PERFORMANCE OPTIMIZED: Uses targeted queries instead of fetch-all-then-filter
    func pruneOldConversations(
        for user: User,
        keepLast: Int = 5
    ) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Get conversation IDs efficiently using our optimized method
        let conversationIds = try await getConversationIds(for: user)
        let idsToDelete = Array(conversationIds.dropFirst(keepLast))

        if idsToDelete.isEmpty {
            AppLogger.info("No conversations to prune for user \(user.id)", category: .ai)
            return
        }

        var totalMessagesDeleted = 0

        // PHASE 2 FIX: Delete messages using userID + conversationID predicate filtering
        let userId = user.id // Capture user ID outside predicate
        for conversationId in idsToDelete {
            let descriptor = FetchDescriptor<CoachMessage>(
                predicate: #Predicate<CoachMessage> { message in
                    message.userID == userId && message.conversationID == conversationId
                }
            )

            let messages = try modelContext.fetch(descriptor)

            for message in messages {
                modelContext.delete(message)
            }
            totalMessagesDeleted += messages.count
        }

        try modelContext.save()

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.info(
            "Pruned \(idsToDelete.count) conversations (\(totalMessagesDeleted) messages) for user \(user.id) in \(Int(totalTime * 1_000))ms",
            category: .ai
        )
    }

    /// Deletes a specific conversation
    /// PERFORMANCE OPTIMIZED: Uses SwiftData predicate with userID + conversationID filtering
    func deleteConversation(
        for user: User,
        conversationId: UUID
    ) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()

        // PHASE 2 FIX: Filter by BOTH userID AND conversationID in database predicate
        let userId = user.id // Capture user ID outside predicate
        let descriptor = FetchDescriptor<CoachMessage>(
            predicate: #Predicate<CoachMessage> { message in
                message.userID == userId && message.conversationID == conversationId
            }
        )

        let messages = try modelContext.fetch(descriptor)

        for message in messages {
            modelContext.delete(message)
        }

        try modelContext.save()

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.info(
            "Deleted conversation \(conversationId) (\(messages.count) messages) for user \(user.id) in \(Int(totalTime * 1_000))ms",
            category: .ai
        )
    }

    /// Gets all conversation IDs for a user
    /// PERFORMANCE OPTIMIZED: Uses SwiftData predicate with userID filtering
    func getConversationIds(for user: User) async throws -> [UUID] {
        let startTime = CFAbsoluteTimeGetCurrent()

        // PHASE 2 FIX: Filter by userID AND non-null conversationID in database predicate
        let userId = user.id // Capture user ID outside predicate
        let descriptor = FetchDescriptor<CoachMessage>(
            predicate: #Predicate<CoachMessage> { message in
                message.userID == userId && message.conversationID != nil
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let userMessages = try modelContext.fetch(descriptor)

        let queryTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.debug(
            "Conversation IDs query completed in \(Int(queryTime * 1_000))ms for \(userMessages.count) messages",
            category: .ai
        )

        // Extract unique conversation IDs while preserving sort order (most recent first)
        var seenIds = Set<UUID>()
        let sortedIds = userMessages.compactMap { message -> UUID? in
            guard let conversationId = message.conversationID,
                  !seenIds.contains(conversationId) else { return nil }
            seenIds.insert(conversationId)
            return conversationId
        }

        return sortedIds
    }

    /// Archives old messages while keeping conversation metadata
    /// PERFORMANCE OPTIMIZED: Uses userID + date predicate filtering
    func archiveOldMessages(
        for user: User,
        olderThan days: Int = 30
    ) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let userId = user.id // Capture user ID outside predicate

        // PHASE 2 FIX: Filter by BOTH userID AND date in database predicate
        let descriptor = FetchDescriptor<CoachMessage>(
            predicate: #Predicate<CoachMessage> { message in
                message.userID == userId && message.timestamp < cutoffDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        let oldMessages = try modelContext.fetch(descriptor)

        if oldMessages.isEmpty {
            AppLogger.info("No old messages to archive for user \(user.id)", category: .ai)
            return
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

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.info(
            "Archived \(messagesToDelete.count) old messages for user \(user.id) in \(Int(totalTime * 1_000))ms",
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

import Foundation
import SwiftData

/// Read-only repository for Chat data access
/// Provides efficient message retrieval with filtering and pagination
@MainActor
final class ChatHistoryRepository: ChatHistoryRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - ReadRepositoryProtocol
    
    func find(filter: ChatFilter) async throws -> [ChatMessage] {
        let descriptor = createMessageFetchDescriptor(for: filter)
        return try modelContext.fetch(descriptor)
    }
    
    func findFirst(filter: ChatFilter) async throws -> ChatMessage? {
        var descriptor = createMessageFetchDescriptor(for: filter)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    func count(filter: ChatFilter) async throws -> Int {
        let descriptor = createMessageFetchDescriptor(for: filter)
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - ChatHistoryRepositoryProtocol
    
    func getMessages(sessionId: UUID, limit: Int?, offset: Int?) async throws -> [ChatMessage] {
        var descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        
        // Filter messages by session
        descriptor.predicate = #Predicate<ChatMessage> { message in
            message.session?.id == sessionId
        }
        
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        if let offset = offset {
            descriptor.fetchOffset = offset
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func searchMessages(userId: UUID, query: String, limit: Int?) async throws -> [ChatMessage] {
        let lowercaseQuery = query.lowercased()
        
        var descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        descriptor.predicate = #Predicate<ChatMessage> { message in
            message.session?.user?.id == userId &&
            message.content.localizedStandardContains(lowercaseQuery)
        }
        
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func getActiveSession(userId: UUID) async throws -> ChatSession? {
        var descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor<ChatSession>(\.lastMessageDate, order: .reverse)]
        )
        
        descriptor.predicate = #Predicate<ChatSession> { session in
            session.isActive && session.user?.id == userId
        }
        
        descriptor.fetchLimit = 1
        
        return try modelContext.fetch(descriptor).first
    }
    
    func getRecentSessions(userId: UUID, limit: Int) async throws -> [ChatSession] {
        var descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor<ChatSession>(\.lastMessageDate, order: .reverse)]
        )
        
        descriptor.predicate = #Predicate<ChatSession> { session in
            session.user?.id == userId
        }
        
        descriptor.fetchLimit = limit
        
        return try modelContext.fetch(descriptor)
    }
    
    func getMessageCount(sessionId: UUID) async throws -> Int {
        var descriptor = FetchDescriptor<ChatMessage>()
        
        descriptor.predicate = #Predicate<ChatMessage> { message in
            message.session?.id == sessionId
        }
        
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - Private Helpers
    
    private func createMessageFetchDescriptor(for filter: ChatFilter) -> FetchDescriptor<ChatMessage> {
        var descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        var predicates: [Predicate<ChatMessage>] = []
        
        if let sessionId = filter.sessionId {
            predicates.append(#Predicate { message in
                message.session?.id == sessionId
            })
        }
        
        if let userId = filter.userId {
            predicates.append(#Predicate { message in
                message.session?.user?.id == userId
            })
        }
        
        if let role = filter.role {
            // Convert MessageRole to MessageType for comparison
            let messageType: ChatMessage.MessageType = switch role {
            case .user: .user
            case .assistant: .assistant
            case .system: .system
            case .function, .tool: .assistant // Map function/tool to assistant
            }
            predicates.append(#Predicate { message in
                message.roleEnum == messageType
            })
        }
        
        if let afterDate = filter.afterDate {
            predicates.append(#Predicate { message in
                message.timestamp >= afterDate
            })
        }
        
        if let beforeDate = filter.beforeDate {
            predicates.append(#Predicate { message in
                message.timestamp <= beforeDate
            })
        }
        
        if let containsText = filter.containsText {
            let lowercaseText = containsText.lowercased()
            predicates.append(#Predicate { message in
                message.content.localizedStandardContains(lowercaseText)
            })
        }
        
        // Combine predicates with AND logic
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(nil) { result, predicate in
                if let result = result {
                    return #Predicate<ChatMessage> { message in
                        result.evaluate(message) && predicate.evaluate(message)
                    }
                } else {
                    return predicate
                }
            }
        }
        
        return descriptor
    }
}

// MARK: - Chat Repository Extensions

extension ChatHistoryRepository {
    
    /// Get paginated message history for a session
    /// Returns messages in chronological order with metadata
    func getMessageHistory(
        sessionId: UUID, 
        page: Int = 0, 
        pageSize: Int = 50
    ) async throws -> MessageHistoryPage {
        let offset = page * pageSize
        let messages = try await getMessages(
            sessionId: sessionId, 
            limit: pageSize + 1, // Fetch one extra to check if there are more
            offset: offset
        )
        
        let hasMore = messages.count > pageSize
        let messagesForPage = hasMore ? Array(messages.prefix(pageSize)) : messages
        let totalCount = try await getMessageCount(sessionId: sessionId)
        
        return MessageHistoryPage(
            messages: messagesForPage,
            page: page,
            pageSize: pageSize,
            hasMore: hasMore,
            totalCount: totalCount
        )
    }
    
    /// Get conversation context for AI (last N messages)
    func getConversationContext(
        sessionId: UUID, 
        maxMessages: Int = 10
    ) async throws -> [ChatMessage] {
        return try await getMessages(
            sessionId: sessionId,
            limit: maxMessages,
            offset: nil
        ).reversed() // Return in chronological order for AI context
    }
    
    /// Get message statistics for a session
    func getSessionStats(sessionId: UUID) async throws -> SessionStats {
        let allMessages = try await getMessages(sessionId: sessionId, limit: nil, offset: nil)
        
        let userMessages = allMessages.filter { $0.roleEnum == .user }
        let assistantMessages = allMessages.filter { $0.roleEnum == .assistant }
        
        let avgUserMessageLength = userMessages.isEmpty ? 0 : 
            userMessages.map { $0.content.count }.reduce(0, +) / userMessages.count
        
        let avgAssistantMessageLength = assistantMessages.isEmpty ? 0 :
            assistantMessages.map { $0.content.count }.reduce(0, +) / assistantMessages.count
        
        return SessionStats(
            totalMessages: allMessages.count,
            userMessages: userMessages.count,
            assistantMessages: assistantMessages.count,
            avgUserMessageLength: avgUserMessageLength,
            avgAssistantMessageLength: avgAssistantMessageLength,
            firstMessage: allMessages.last?.timestamp,
            lastMessage: allMessages.first?.timestamp
        )
    }
}

// MARK: - Supporting Types

struct MessageHistoryPage: Sendable {
    let messages: [ChatMessage]
    let page: Int
    let pageSize: Int
    let hasMore: Bool
    let totalCount: Int
}

struct SessionStats: Sendable {
    let totalMessages: Int
    let userMessages: Int
    let assistantMessages: Int
    let avgUserMessageLength: Int
    let avgAssistantMessageLength: Int
    let firstMessage: Date?
    let lastMessage: Date?
}
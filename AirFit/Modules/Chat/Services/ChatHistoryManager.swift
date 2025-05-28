import Foundation
import SwiftData

@MainActor
final class ChatHistoryManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Session Management
    func createSession(for user: User) async throws -> ChatSession {
        let session = ChatSession(user: user)
        modelContext.insert(session)
        try modelContext.save()
        return session
    }

    func archiveSession(_ session: ChatSession) async throws {
        session.isActive = false
        session.archivedAt = Date()
        try modelContext.save()
    }

    func getRecentSessions(for user: User, limit: Int) async throws -> [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(
            predicate: #Predicate { $0.user?.id == user.id },
            sortBy: [SortDescriptor(\.lastMessageDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Message Search
    func searchMessages(query: String, user: User) async throws -> [ChatMessage] {
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { message in
                message.content.localizedStandardContains(query) &&
                message.session?.user?.id == user.id
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Export
    func exportSession(_ session: ChatSession, format: ExportFormat) async throws -> URL {
        guard let sessionId = session.id else { throw ChatError.noActiveSession }
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { $0.session?.id == sessionId },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let messages = try modelContext.fetch(descriptor)
        return try await ChatExporter().export(
            session: session,
            messages: messages,
            format: format
        )
    }
}

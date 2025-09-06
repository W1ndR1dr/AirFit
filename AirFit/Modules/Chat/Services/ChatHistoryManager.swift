import Foundation
import SwiftData

@MainActor
final class ChatHistoryManager: ObservableObject, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "chat-history-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }

    private let modelContext: ModelContext

    @Published private(set) var sessions: [ChatSession] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        sessions.removeAll()
        error = nil
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        let canAccessData = (try? modelContext.fetch(FetchDescriptor<ChatSession>())) != nil

        return ServiceHealth(
            status: canAccessData ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: canAccessData ? nil : "Cannot access chat data",
            metadata: [
                "sessionCount": "\(sessions.count)",
                "hasError": "\(error != nil)"
            ]
        )
    }

    func loadSessions(for user: User) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let descriptor = FetchDescriptor<ChatSession>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let allSessions = try modelContext.fetch(descriptor)
            sessions = allSessions.filter { $0.user?.id == user.id }
        } catch {
            self.error = error
            AppLogger.error("Failed to load chat sessions", error: error, category: .chat)
        }
    }

    func deleteSession(_ session: ChatSession) async {
        do {
            // Delete all messages in the session first
            let messageDescriptor = FetchDescriptor<ChatMessage>()
            let allMessages = try modelContext.fetch(messageDescriptor)
            let sessionMessages = allMessages.filter { $0.session?.id == session.id }

            for message in sessionMessages {
                modelContext.delete(message)
            }

            // Delete the session
            modelContext.delete(session)
            try modelContext.save()

            // Update local array
            sessions.removeAll { $0.id == session.id }
        } catch {
            self.error = error
            AppLogger.error("Failed to delete session", error: error, category: .chat)
        }
    }

    func exportSession(_ session: ChatSession, format: ChatExporter.ExportFormat) async throws -> URL {
        let messageDescriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let allMessages = try modelContext.fetch(messageDescriptor)
        let sessionMessages = allMessages.filter { $0.session?.id == session.id }

        let exporter = ChatExporter()
        return try await exporter.export(
            session: session,
            messages: sessionMessages,
            format: format
        )
    }

    func searchSessions(query: String) -> [ChatSession] {
        return sessions.filter { session in
            session.title?.localizedStandardContains(query) == true
        }
    }
}

import Foundation
import SwiftData

@MainActor
final class ChatHistoryManager: ObservableObject {
    private let modelContext: ModelContext
    
    @Published private(set) var sessions: [ChatSession] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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

import Foundation
import SwiftData

@MainActor
final class SwiftDataChatWriteRepository: ChatWriteRepositoryProtocol {
    private let context: ModelContext
    
    init(modelContext: ModelContext) {
        self.context = modelContext
    }
    
    // MARK: - Chat Session Operations
    
    func createSession(for user: User, title: String?) throws -> ChatSession {
        let session = ChatSession(user: user, title: title)
        context.insert(session)
        try context.save()
        return session
    }
    
    func saveSession(_ session: ChatSession) throws {
        try context.save()
    }
    
    func deleteSession(_ session: ChatSession) throws {
        context.delete(session)
        try context.save()
    }
    
    func updateSession(_ session: ChatSession, title: String) throws {
        session.title = title
        try context.save()
    }
    
    // MARK: - Message Operations
    
    func addMessage(_ message: ChatMessage, to session: ChatSession) throws {
        session.messages.append(message)
        context.insert(message)
        try context.save()
    }
    
    func saveMessage(_ message: ChatMessage) throws {
        try context.save()
    }
    
    func deleteMessage(_ message: ChatMessage) throws {
        context.delete(message)
        try context.save()
    }
    
    func deleteMessages(in session: ChatSession) throws {
        for message in session.messages {
            context.delete(message)
        }
        session.messages.removeAll()
        try context.save()
    }
    
    // MARK: - Bulk Operations
    
    func saveSessions(_ sessions: [ChatSession]) throws {
        for session in sessions {
            context.insert(session)
        }
        try context.save()
    }
    
    func saveMessages(_ messages: [ChatMessage]) throws {
        for message in messages {
            context.insert(message)
        }
        try context.save()
    }
    
    // MARK: - Session Management
    
    func setActiveSession(_ session: ChatSession, for user: User) throws {
        // Clear any existing active session
        user.currentChatSession = session
        try context.save()
    }
    
    func clearActiveSession(for user: User) throws {
        user.currentChatSession = nil
        try context.save()
    }
    
    // MARK: - Message Status
    
    func markMessageAsRead(_ message: ChatMessage) throws {
        message.isRead = true
        try context.save()
    }
    
    func markAllMessagesAsRead(in session: ChatSession) throws {
        for message in session.messages {
            message.isRead = true
        }
        try context.save()
    }
}
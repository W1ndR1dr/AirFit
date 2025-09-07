import Foundation

@MainActor
protocol ChatWriteRepositoryProtocol: Sendable {
    // MARK: - Chat Session Operations
    func createSession(for user: User, title: String?) throws -> ChatSession
    func saveSession(_ session: ChatSession) throws
    func deleteSession(_ session: ChatSession) throws
    func updateSession(_ session: ChatSession, title: String) throws
    
    // MARK: - Message Operations
    func addMessage(_ message: ChatMessage, to session: ChatSession) throws
    func saveMessage(_ message: ChatMessage) throws
    func deleteMessage(_ message: ChatMessage) throws
    func deleteMessages(in session: ChatSession) throws
    
    // MARK: - Bulk Operations
    func saveSessions(_ sessions: [ChatSession]) throws
    func saveMessages(_ messages: [ChatMessage]) throws
    
    // MARK: - Session Management
    func setActiveSession(_ session: ChatSession, for user: User) throws
    func clearActiveSession(for user: User) throws
    
    // MARK: - Message Status
    func markMessageAsRead(_ message: ChatMessage) throws
    func markAllMessagesAsRead(in session: ChatSession) throws
}
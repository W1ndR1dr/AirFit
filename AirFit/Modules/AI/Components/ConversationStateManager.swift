import Foundation

/// Manages conversation state and context for AI interactions
/// Single responsibility: Track and manage conversation state
actor ConversationStateManager {
    // MARK: - Types
    
    struct ConversationState {
        let id: UUID
        let userId: UUID
        let startTime: Date
        var messageCount: Int
        var lastInteraction: Date
        var activeMode: PersonaMode
        var contextWindow: Int
        
        var isStale: Bool {
            Date().timeIntervalSince(lastInteraction) > 1800 // 30 minutes
        }
    }
    
    // MARK: - Properties
    
    private var sessions: [UUID: ConversationState] = [:]
    private let maxSessions = 10
    private let defaultContextWindow = 20
    
    // MARK: - Session Management
    
    func createSession(
        userId: UUID,
        mode: PersonaMode,
        contextWindow: Int? = nil
    ) -> UUID {
        let sessionId = UUID()
        
        let state = ConversationState(
            id: sessionId,
            userId: userId,
            startTime: Date(),
            messageCount: 0,
            lastInteraction: Date(),
            activeMode: mode,
            contextWindow: contextWindow ?? defaultContextWindow
        )
        
        sessions[sessionId] = state
        
        // Clean up old sessions if needed
        if sessions.count > maxSessions {
            removeOldestSession()
        }
        
        AppLogger.info("Created conversation session: \(sessionId)", category: .ai)
        return sessionId
    }
    
    func getSession(_ id: UUID) -> ConversationState? {
        sessions[id]
    }
    
    func updateSession(_ id: UUID, messageProcessed: Bool = true) {
        guard var state = sessions[id] else { return }
        
        state.lastInteraction = Date()
        if messageProcessed {
            state.messageCount += 1
        }
        
        sessions[id] = state
    }
    
    func updateMode(_ id: UUID, mode: PersonaMode) {
        guard var state = sessions[id] else { return }
        state.activeMode = mode
        sessions[id] = state
        
        AppLogger.debug("Updated session \(id) mode to: \(mode)", category: .ai)
    }
    
    func endSession(_ id: UUID) {
        sessions.removeValue(forKey: id)
        AppLogger.info("Ended conversation session: \(id)", category: .ai)
    }
    
    // MARK: - Context Management
    
    func getOptimalHistoryLimit(for sessionId: UUID, messageType: MessageType) -> Int {
        guard let state = sessions[sessionId] else {
            return messageType.contextLimit
        }
        
        // Stale conversations need more context to rebuild understanding
        if state.isStale {
            return min(state.contextWindow, 30)
        }
        
        // Use message type limits but respect session window
        return min(messageType.contextLimit, state.contextWindow)
    }
    
    func shouldResetContext(for sessionId: UUID) -> Bool {
        guard let state = sessions[sessionId] else { return true }
        
        // Reset if conversation is very stale (>2 hours)
        return Date().timeIntervalSince(state.lastInteraction) > 7200
    }
    
    // MARK: - Cleanup
    
    private func removeOldestSession() {
        let sortedSessions = sessions.values.sorted { $0.lastInteraction < $1.lastInteraction }
        
        if let oldest = sortedSessions.first {
            sessions.removeValue(forKey: oldest.id)
            AppLogger.debug("Removed oldest session: \(oldest.id)", category: .ai)
        }
    }
    
    func cleanupStaleSessions() {
        let staleIds = sessions.compactMap { key, value in
            value.isStale ? key : nil
        }
        
        for id in staleIds {
            sessions.removeValue(forKey: id)
        }
        
        if !staleIds.isEmpty {
            AppLogger.info("Cleaned up \(staleIds.count) stale sessions", category: .ai)
        }
    }
    
    // MARK: - Analytics
    
    func getActiveSessionCount() -> Int {
        sessions.count
    }
    
    func getSessionMetrics() -> [String: Any] {
        let activeSessions = sessions.values.filter { !$0.isStale }
        let avgMessageCount = activeSessions.reduce(0) { $0 + $1.messageCount } / max(activeSessions.count, 1)
        
        return [
            "totalSessions": sessions.count,
            "activeSessions": activeSessions.count,
            "averageMessages": avgMessageCount,
            "modes": Dictionary(grouping: sessions.values, by: \.activeMode).mapValues(\.count)
        ]
    }
}
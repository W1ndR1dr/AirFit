import Foundation
import SwiftData

/// A conversation session with the AI coach.
///
/// Stores the full message history for multi-turn Gemini conversations.
/// Each conversation belongs to a specific provider (gemini or claude).
@Model
final class Conversation {
    var id: UUID
    var provider: String  // "gemini" or "claude"
    var createdAt: Date
    var lastMessageAt: Date

    /// Messages stored as JSON-encoded data (SwiftData limitation for arrays)
    var messagesData: Data?

    /// Pending memory markers extracted from AI responses, not yet synced to server
    var pendingMemoryMarkersData: Data?

    init(provider: String = "gemini") {
        self.id = UUID()
        self.provider = provider
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.messagesData = nil
        self.pendingMemoryMarkersData = nil
    }

    // MARK: - Messages

    /// Get decoded messages array
    var messages: [ChatMessage] {
        get {
            guard let data = messagesData else { return [] }
            return (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
        }
        set {
            messagesData = try? JSONEncoder().encode(newValue)
            lastMessageAt = Date()
        }
    }

    /// Add a message to the conversation
    func addMessage(_ message: ChatMessage) {
        var current = messages
        current.append(message)
        messages = current
    }

    /// Get messages formatted for Gemini API (ConversationMessage format)
    var geminiMessages: [ConversationMessage] {
        messages.map { msg in
            ConversationMessage(
                role: msg.isUser ? "user" : "model",
                content: msg.content,
                timestamp: msg.timestamp
            )
        }
    }

    // MARK: - Pending Memory Markers

    /// Get pending memory markers not yet synced to server
    var pendingMemoryMarkers: [MemoryMarker] {
        get {
            guard let data = pendingMemoryMarkersData else { return [] }
            return (try? JSONDecoder().decode([MemoryMarker].self, from: data)) ?? []
        }
        set {
            pendingMemoryMarkersData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Add pending memory markers extracted from an AI response
    func addPendingMarkers(_ markers: [MemoryMarker]) {
        var current = pendingMemoryMarkers
        current.append(contentsOf: markers)
        pendingMemoryMarkers = current
    }

    /// Clear pending markers after successful sync
    func clearPendingMarkers() {
        pendingMemoryMarkers = []
    }
}

// MARK: - Chat Message

/// A single message in a conversation.
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date

    /// Raw content before memory marker stripping (for sync)
    let rawContent: String?

    init(content: String, isUser: Bool, rawContent: String? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.rawContent = rawContent
    }
}

// MARK: - Memory Marker

/// A memory marker extracted from an AI response.
///
/// These are stored locally until synced to the server for profile evolution.
struct MemoryMarker: Codable {
    let type: String  // "remember", "callback", "tone", "thread"
    let content: String
    let timestamp: Date

    init(type: String, content: String) {
        self.type = type
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Predicates

extension Conversation {
    /// Predicate for conversations with a specific provider
    static func provider(_ provider: String) -> Predicate<Conversation> {
        #Predicate { $0.provider == provider }
    }

    /// Predicate for conversations within the last N days
    static func recent(days: Int) -> Predicate<Conversation> {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return #Predicate { $0.lastMessageAt >= cutoff }
    }
}

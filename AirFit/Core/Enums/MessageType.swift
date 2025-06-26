import Foundation

/// Represents the type of user message for AI conversation optimization
public enum MessageType: String, Codable, CaseIterable, Sendable {
    case conversation = "conversation"
    case command = "command"

    /// Display name for UI purposes
    public var displayName: String {
        switch self {
        case .conversation: return "Conversation"
        case .command: return "Quick Command"
        }
    }

    /// Whether this message type requires full conversation history for context
    /// Commands need minimal context (5 messages), conversations need full context (20 messages)
    public var requiresHistory: Bool {
        switch self {
        case .conversation: return true
        case .command: return false
        }
    }

    /// Maximum number of previous messages to include for context
    public var contextLimit: Int {
        switch self {
        case .conversation: return 20
        case .command: return 5
        }
    }

    /// Description of message type for debugging and logging
    public var description: String {
        switch self {
        case .conversation:
            return "Full conversation requiring comprehensive context and history"
        case .command:
            return "Quick command requiring minimal context for immediate action"
        }
    }
}

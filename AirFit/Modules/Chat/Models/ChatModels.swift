import Foundation

// MARK: - Quick Suggestion
struct QuickSuggestion: Identifiable, Sendable {
    let id = UUID()
    let text: String
    let autoSend: Bool
}

// MARK: - Contextual Action
struct ContextualAction: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let icon: String?
}

// MARK: - Chat Error
enum ChatError: LocalizedError, Equatable, Sendable {
    case noActiveSession
    case exportFailed(String)
    case voiceRecognitionUnavailable

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active chat session"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .voiceRecognitionUnavailable:
            return "Voice recognition is not available"
        }
    }
}
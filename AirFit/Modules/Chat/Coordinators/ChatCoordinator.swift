import SwiftUI

// MARK: - Navigation Destinations
enum ChatDestination: Hashable {
    case messageDetail(messageId: String)
    case searchResults
    case sessionSettings
    case progressView
}

// MARK: - Sheet Types
enum ChatSheet: Identifiable {
    case sessionHistory
    case exportChat
    case voiceSettings
    case imageAttachment

    var id: String {
        switch self {
        case .sessionHistory: return "history"
        case .exportChat: return "export"
        case .voiceSettings: return "voice"
        case .imageAttachment: return "image"
        }
    }
}

// MARK: - Alert Types (for future use)
enum ChatAlert: Identifiable {
    case deleteMessage(messageId: String)
    case clearHistory
    
    var id: String {
        switch self {
        case .deleteMessage(let id): return "delete_\(id)"
        case .clearHistory: return "clear"
        }
    }
}

@MainActor
@Observable
final class ChatCoordinator: BaseCoordinator<ChatDestination, ChatSheet, ChatAlert> {
    // MARK: - Additional State
    var activePopover: ChatPopover?
    var scrollToMessageId: String?

    // MARK: - Popover Types
    enum ChatPopover: Identifiable {
        case contextMenu(messageId: String)
        case quickActions
        case emojiPicker

        var id: String {
            switch self {
            case .contextMenu(let id): return "context_\(id)"
            case .quickActions: return "actions"
            case .emojiPicker: return "emoji"
            }
        }
    }

    // MARK: - Additional Methods
    func showPopover(_ popover: ChatPopover) {
        activePopover = popover
    }

    func scrollTo(messageId: String) {
        scrollToMessageId = messageId
    }

    override func dismiss() {
        super.dismiss()
        activePopover = nil
    }
}

import SwiftUI
import Combine

@MainActor
final class ChatCoordinator: ObservableObject {
    // MARK: - Navigation State
    @Published var navigationPath = NavigationPath()
    @Published var activeSheet: ChatSheet?
    @Published var activePopover: ChatPopover?
    @Published var scrollToMessageId: String?

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

    // MARK: - Navigation Methods
    func navigateTo(_ destination: ChatDestination) {
        navigationPath.append(destination)
    }

    func showSheet(_ sheet: ChatSheet) {
        activeSheet = sheet
    }

    func showPopover(_ popover: ChatPopover) {
        activePopover = popover
    }

    func scrollTo(messageId: String) {
        scrollToMessageId = messageId
    }

    func dismiss() {
        activeSheet = nil
        activePopover = nil
    }
}

// MARK: - Navigation Destinations
enum ChatDestination: Hashable {
    case messageDetail(messageId: String)
    case searchResults
    case sessionSettings
}

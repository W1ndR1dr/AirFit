import SwiftData
import Foundation

@Model
final class ChatSession: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var title: String?
    var createdAt: Date
    var lastMessageDate: Date?
    var isActive: Bool
    var archivedAt: Date?
    var messageCount: Int

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []

    var user: User?

    // MARK: - Computed Properties
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }

        // Generate title from first message or date
        if let firstMessage = messages.first {
            let preview = String(firstMessage.content.prefix(50))
            return preview.isEmpty ? formattedDate : preview
        }

        return formattedDate
    }

    var formattedDate: String {
        return Formatters.mediumDateTime.string(from: createdAt)
    }

    var hasUnreadMessages: Bool {
        messages.contains { !$0.isRead }
    }

    var lastMessage: ChatMessage? {
        messages.max { $0.timestamp < $1.timestamp }
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        title: String? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.lastMessageDate = Date()
        self.isActive = true
        self.messageCount = 0
        self.user = user
    }

    // MARK: - Methods
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        message.session = self
        messageCount = messages.count
        lastMessageDate = message.timestamp
    }

    func archive() {
        isActive = false
        archivedAt = Date()
    }

    func reactivate() {
        isActive = true
        archivedAt = nil
    }

    func generateTitle() {
        guard title == nil || title?.isEmpty == true else { return }

        // Use first user message as title base
        if let firstUserMessage = messages.first(where: { $0.role == "user" }) {
            let preview = firstUserMessage.content
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            title = String(preview.prefix(60))
            if preview.count > 60 {
                title = (title ?? "") + "..."
            }
        }
    }
}

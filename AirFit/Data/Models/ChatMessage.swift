import SwiftData
import Foundation

@Model
final class ChatMessage: @unchecked Sendable {
    // MARK: - Types
    enum MessageType: String, Codable, CaseIterable {
        case user
        case assistant
        case system
    }

    // MARK: - Properties
    var id: UUID
    var timestamp: Date
    var role: String // "user", "assistant", "system"
    @Attribute(.externalStorage)
    var content: String
    var isRead: Bool
    var isEdited: Bool
    var editedAt: Date?

    // Metadata - individual properties instead of dictionary
    var modelUsed: String?
    var tokenCount: Int?
    var processingTimeMs: Int?
    var errorMessage: String?
    var functionCallName: String?
    var functionCallArgs: String?

    // MARK: - Relationships
    var session: ChatSession?

    @Relationship(deleteRule: .cascade, inverse: \ChatAttachment.message)
    var attachments: [ChatAttachment] = []

    // MARK: - Computed Properties
    var roleEnum: MessageType {
        MessageType(rawValue: role) ?? .user
    }

    var hasAttachments: Bool {
        !attachments.isEmpty
    }

    var formattedTime: String {
        if Calendar.current.isDateInToday(timestamp) {
            return Formatters.time.string(from: timestamp)
        } else {
            return Formatters.mediumDateTime.string(from: timestamp)
        }
    }

    var isUserMessage: Bool {
        role == "user"
    }

    var isAssistantMessage: Bool {
        role == "assistant"
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        role: String,
        content: String,
        session: ChatSession? = nil
    ) {
        self.id = id
        self.timestamp = Date()
        self.role = role
        self.content = content
        self.isRead = role == "user" // User messages are automatically read
        self.isEdited = false
        self.session = session
    }

    // Convenience initializer with role enum
    init(
        session: ChatSession,
        content: String,
        role: MessageType,
        attachments: [ChatAttachment] = []
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.role = role.rawValue
        self.content = content
        self.isRead = role == .user
        self.isEdited = false
        self.session = session
        self.attachments = attachments
    }

    // MARK: - Methods
    func markAsRead() {
        isRead = true
    }

    func edit(newContent: String) {
        content = newContent
        isEdited = true
        editedAt = Date()
    }

    func addAttachment(_ attachment: ChatAttachment) {
        attachments.append(attachment)
        attachment.message = self
    }

    func recordMetadata(model: String, tokens: Int, processingTime: TimeInterval) {
        self.modelUsed = model
        self.tokenCount = tokens
        self.processingTimeMs = Int(processingTime * 1_000)
    }

    func recordError(_ error: String) {
        self.errorMessage = error
    }

    func recordFunctionCall(name: String, args: String) {
        self.functionCallName = name
        self.functionCallArgs = args
    }
}

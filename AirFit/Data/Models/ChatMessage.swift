import SwiftData
import Foundation

@Model
final class ChatMessage: Sendable {
    // MARK: - Properties
    var id: UUID
    var timestamp: Date
    var role: String // "user", "assistant", "system"
    @Attribute(.externalStorage) var content: String
    var isRead: Bool
    var isEdited: Bool
    var editedAt: Date?
    
    // Metadata
    var modelUsed: String?
    var tokenCount: Int?
    var processingTimeMs: Int?
    
    // MARK: - Relationships
    var session: ChatSession?
    
    @Relationship(deleteRule: .cascade, inverse: \ChatAttachment.message)
    var attachments: [ChatAttachment] = []
    
    // MARK: - Computed Properties
    var hasAttachments: Bool {
        !attachments.isEmpty
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(timestamp) {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        }
        
        return formatter.string(from: timestamp)
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
        self.processingTimeMs = Int(processingTime * 1000)
    }
}

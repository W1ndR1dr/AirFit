import Foundation

enum MessageFeedback: Equatable {
    case none
    case positive
    case negative(reason: String?)
}

struct Message: Identifiable, Equatable {
    let id: UUID
    var content: String  // Mutable for editing
    let isUser: Bool
    let timestamp: Date
    var feedback: MessageFeedback  // For AI messages

    init(content: String, isUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.feedback = .none
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.feedback == rhs.feedback
    }
}

import Foundation
import SwiftData

@Model
final class ConversationSession {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var startedAt: Date
    var completedAt: Date?
    var currentNodeId: String?
    var isComplete: Bool
    @Relationship(deleteRule: .cascade) var responses: [ConversationResponse]
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        currentNodeId: String? = nil,
        isComplete: Bool = false,
        responses: [ConversationResponse] = []
    ) {
        self.id = id
        self.userId = userId
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.currentNodeId = currentNodeId
        self.isComplete = isComplete
        self.responses = responses
    }
    
    // Additional properties used by the conversation flow
    var extractedInsights: Data?
    var responseType: String = ""
    var processingTime: TimeInterval = 0.0
    var completionPercentage: Double = 0.0
}

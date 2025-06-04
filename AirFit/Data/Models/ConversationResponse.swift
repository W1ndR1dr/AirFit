import Foundation
import SwiftData

@Model
final class ConversationResponse {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var nodeId: String
    var responseData: Data
    var timestamp: Date
    var isValid: Bool
    var responseType: String = ""
    var processingTime: TimeInterval = 0.0
    @Relationship(inverse: \ConversationSession.responses) var session: ConversationSession?
    
    init(
        id: UUID = UUID(),
        sessionId: UUID,
        nodeId: String,
        responseData: Data,
        timestamp: Date = Date(),
        isValid: Bool = true
    ) {
        self.id = id
        self.sessionId = sessionId
        self.nodeId = nodeId
        self.responseData = responseData
        self.timestamp = timestamp
        self.isValid = isValid
    }
}

// MARK: - Supporting Types

enum ResponseValue: Codable, Sendable {
    case text(String)
    case choice(String)
    case multiChoice([String])
    case slider(Double)
    case voice(transcription: String, audioData: Data?)
}

// MARK: - Extensions

extension ConversationResponse {
    func getValue() throws -> ResponseValue {
        return try JSONDecoder().decode(ResponseValue.self, from: responseData)
    }
    
    func setValue(_ value: ResponseValue) throws {
        self.responseData = try JSONEncoder().encode(value)
    }
}
import SwiftData
import Foundation

@Model
final class CoachMessage: Sendable {
    // MARK: - Properties
    var id: UUID
    var timestamp: Date
    var role: String
    @Attribute(.externalStorage) var content: String
    var conversationID: UUID?
    
    // AI Metadata
    var modelUsed: String?
    var promptTokens: Int?
    var completionTokens: Int?
    var totalTokens: Int?
    var temperature: Double?
    var responseTimeMs: Int?
    
    // Function Calling
    var functionCallData: Data?
    var functionResultData: Data?
    
    // User Feedback
    var userRating: Int? // 1-5
    var userFeedback: String?
    var wasHelpful: Bool?
    
    // MARK: - Relationships
    var user: User?
    
    // MARK: - Computed Properties
    var messageRole: MessageRole? {
        MessageRole(rawValue: role)
    }
    
    var functionCall: FunctionCall? {
        guard let data = functionCallData else { return nil }
        return try? JSONDecoder().decode(FunctionCall.self, from: data)
    }
    
    var functionResult: FunctionResult? {
        guard let data = functionResultData else { return nil }
        return try? JSONDecoder().decode(FunctionResult.self, from: data)
    }
    
    var estimatedCost: Double? {
        guard let total = totalTokens,
              let model = modelUsed else { return nil }
        
        // Rough cost estimates per 1K tokens
        let costPer1K: Double = switch model {
        case "gpt-4": 0.03
        case "gpt-3.5-turbo": 0.002
        case "claude-3": 0.025
        default: 0.01
        }
        
        return Double(total) / 1000.0 * costPer1K
    }
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        role: MessageRole,
        content: String,
        conversationID: UUID? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.role = role.rawValue
        self.content = content
        self.conversationID = conversationID
        self.user = user
    }
    
    // MARK: - Methods
    func recordAIMetadata(
        model: String,
        promptTokens: Int,
        completionTokens: Int,
        temperature: Double,
        responseTime: TimeInterval
    ) {
        self.modelUsed = model
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = promptTokens + completionTokens
        self.temperature = temperature
        self.responseTimeMs = Int(responseTime * 1000)
    }
    
    func recordUserFeedback(rating: Int? = nil, feedback: String? = nil, helpful: Bool? = nil) {
        if let rating = rating { self.userRating = rating }
        if let feedback = feedback { self.userFeedback = feedback }
        if let helpful = helpful { self.wasHelpful = helpful }
    }
}

// MARK: - Supporting Types
enum MessageRole: String, Codable, Sendable {
    case system = "system"
    case user = "user"
    case assistant = "assistant"
    case function = "function"
    case tool = "tool"
}

struct FunctionCall: Codable, Sendable {
    let name: String
    let arguments: [String: AnyCodable]
    
    init(name: String, arguments: [String: Any]) {
        self.name = name
        self.arguments = arguments.compactMapValues { AnyCodable($0) }
    }
}

struct FunctionResult: Codable, Sendable {
    let success: Bool
    let result: AnyCodable?
    let error: String?
    
    init(success: Bool, result: Any? = nil, error: String? = nil) {
        self.success = success
        self.result = result.map { AnyCodable($0) }
        self.error = error
    }
}

// MARK: - AnyCodable Helper
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode AnyCodable")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode AnyCodable"))
        }
    }
}

import SwiftData
import Foundation

@Model
final class CoachMessage: @unchecked Sendable {
    // MARK: - Database Performance Optimization
    // CRITICAL: iOS 18 SwiftData indexing for query performance
    // Individual indexes for timestamp (sorting), role (filtering), conversationID (conversation queries)
    // Composite index for the most common query pattern: (user+conversation+timestamp)
    #Index<CoachMessage>([\.timestamp], [\.role], [\.conversationID], [\.messageTypeRawValue], [\.conversationID, \.timestamp])
    
    // MARK: - Properties
    var id: UUID
    
    // Indexed for all temporal queries and sorting operations
    var timestamp: Date
    
    // Indexed for filtering user vs assistant messages
    var role: String
    
    @Attribute(.externalStorage)
    var content: String
    
    // Indexed for conversation-specific queries
    var conversationID: UUID?
    
    // FUTURE: Message type classification for performance optimization
    // Commands need minimal history (5 messages), conversations need full history (20 messages)
    // Using raw value storage for SwiftData compatibility with enum indexing
    private var messageTypeRawValue: String = MessageType.conversation.rawValue
    
    // MARK: - Message Type Accessor
    var messageType: MessageType {
        get { MessageType(rawValue: messageTypeRawValue) ?? .conversation }
        set { messageTypeRawValue = newValue.rawValue }
    }

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
    // User relationship enables composite index optimization for (user.id, conversationID, timestamp)
    var user: User?

    // MARK: - Computed Properties
    var messageRole: MessageRole? {
        MessageRole(rawValue: role)
    }
    
    // FUTURE: Convenience property for message classification
    var isCommand: Bool {
        messageType == .command
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

        return Double(total) / 1_000.0 * costPer1K
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        role: MessageRole,
        content: String,
        conversationID: UUID? = nil,
        user: User? = nil,
        messageType: MessageType = .conversation
    ) {
        self.id = id
        self.timestamp = timestamp
        self.role = role.rawValue
        self.content = content
        self.conversationID = conversationID
        self.user = user
        self.messageTypeRawValue = messageType.rawValue
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
        self.responseTimeMs = Int(responseTime * 1_000)
    }

    func recordUserFeedback(rating: Int? = nil, feedback: String? = nil, helpful: Bool? = nil) {
        if let rating = rating { self.userRating = rating }
        if let feedback = feedback { self.userFeedback = feedback }
        if let helpful = helpful { self.wasHelpful = helpful }
    }
}

// MARK: - Supporting Types
enum MessageRole: String, Codable, Sendable {
    case system
    case user
    case assistant
    case function
    case tool
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
struct AnyCodable: Codable, @unchecked Sendable {
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
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: [], debugDescription: "Unable to encode AnyCodable")
            )
        }
    }
}

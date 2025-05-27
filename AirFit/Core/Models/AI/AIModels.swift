import Foundation

// MARK: - Core AI Types

enum MessageRole: String, Codable, Sendable {
    case system
    case user
    case assistant
    case function
    case tool
}

struct ChatMessage: Codable, Sendable {
    let id: UUID
    let role: MessageRole
    let content: String
    let name: String?
    let functionCall: FunctionCall?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        name: String? = nil,
        functionCall: FunctionCall? = nil,
        timestamp: Date = .init()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.name = name
        self.functionCall = functionCall
        self.timestamp = timestamp
    }
}

// MARK: - Function Calling

struct FunctionCall: Codable, Sendable {
    let name: String
    let arguments: [String: AnyCodable]

    init(name: String, arguments: [String: Any] = [:]) {
        self.name = name
        self.arguments = arguments.mapValues { AnyCodable($0) }
    }
}

struct FunctionDefinition: Codable, Sendable {
    let name: String
    let description: String
    let parameters: FunctionParameters
}

struct FunctionParameters: Codable, Sendable {
    let type: String = "object"
    let properties: [String: ParameterDefinition]
    let required: [String]
}

struct ParameterDefinition: Codable, Sendable {
    let type: String
    let description: String
    let enumValues: [String]?
    let minimum: Double?
    let maximum: Double?
    let items: Box<ParameterDefinition>?

    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
        case minimum, maximum, items
    }
}

// Box type to handle recursive definitions
final class Box<T: Codable>: Codable {
    let value: T

    init(_ value: T) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        value = try T(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

// MARK: - AI Request/Response

struct AIRequest: Sendable {
    let id: UUID = UUID()
    let systemPrompt: String
    let messages: [ChatMessage]
    let functions: [FunctionDefinition]?
    let temperature: Double
    let maxTokens: Int?
    let stream: Bool
    let user: String

    init(
        systemPrompt: String,
        messages: [ChatMessage],
        functions: [FunctionDefinition]? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil,
        stream: Bool = true,
        user: String
    ) {
        self.systemPrompt = systemPrompt
        self.messages = messages
        self.functions = functions
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.stream = stream
        self.user = user
    }
}

enum AIResponse: Sendable {
    case text(String)
    case textDelta(String)
    case functionCall(FunctionCall)
    case error(AIError)
    case done(usage: TokenUsage?)
}

struct TokenUsage: Codable, Sendable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
}

enum AIError: LocalizedError, Sendable {
    case networkError(String)
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case invalidResponse(String)
    case modelOverloaded
    case contextLengthExceeded
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .rateLimitExceeded(let retryAfter):
            if let retry = retryAfter {
                return "Rate limit exceeded. Try again in \(Int(retry)) seconds."
            }
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .modelOverloaded:
            return "AI service is currently overloaded. Please try again."
        case .contextLengthExceeded:
            return "Conversation is too long. Starting a new context."
        case .unauthorized:
            return "AI service authorization failed."
        }
    }
}

// MARK: - AnyCodable for flexible JSON handling

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode value"
            )
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
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Unable to encode value"
                )
            )
        }
    }
}

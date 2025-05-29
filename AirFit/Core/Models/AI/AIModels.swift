import Foundation

// MARK: - Core AI Types

enum AIMessageRole: String, Codable, Sendable {
    case system
    case user
    case assistant
    case function
    case tool
}

struct AIChatMessage: Codable, Sendable {
    let id: UUID
    let role: AIMessageRole
    let content: String
    let name: String?
    let functionCall: AIFunctionCall?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: AIMessageRole,
        content: String,
        name: String? = nil,
        functionCall: AIFunctionCall? = nil,
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

struct AIFunctionCall: Codable, Sendable {
    let name: String
    let arguments: [String: AIAnyCodable]

    init(name: String, arguments: [String: Any] = [:]) {
        self.name = name
        self.arguments = arguments.mapValues { AIAnyCodable($0) }
    }
}

struct AIFunctionDefinition: Codable, Sendable {
    let name: String
    let description: String
    let parameters: AIFunctionParameters
}

struct AIFunctionParameters: Codable, Sendable {
    let type: String
    let properties: [String: AIParameterDefinition]
    let required: [String]

    init(properties: [String: AIParameterDefinition], required: [String] = []) {
        self.type = "object"
        self.properties = properties
        self.required = required
    }
}

struct AIParameterDefinition: Codable, Sendable {
    let type: String
    let description: String
    let enumValues: [String]?
    let minimum: Double?
    let maximum: Double?
    let items: AIBox<AIParameterDefinition>?

    enum CodingKeys: String, CodingKey {
        case type, description
        case enumValues = "enum"
        case minimum, maximum, items
    }

    // MARK: - Convenience Initializers

    /// String parameter with enum values
    init(type: String, description: String, enumValues: [String]) {
        self.type = type
        self.description = description
        self.enumValues = enumValues
        self.minimum = nil
        self.maximum = nil
        self.items = nil
    }

    /// Numeric parameter with min/max constraints
    init(type: String, description: String, minimum: Double? = nil, maximum: Double? = nil) {
        self.type = type
        self.description = description
        self.enumValues = nil
        self.minimum = minimum
        self.maximum = maximum
        self.items = nil
    }

    /// Array parameter with item definition
    init(type: String, description: String, items: AIBox<AIParameterDefinition>) {
        self.type = type
        self.description = description
        self.enumValues = nil
        self.minimum = nil
        self.maximum = nil
        self.items = items
    }

    /// Simple parameter (string, boolean, etc.)
    init(type: String, description: String) {
        self.type = type
        self.description = description
        self.enumValues = nil
        self.minimum = nil
        self.maximum = nil
        self.items = nil
    }
}

/// Box type to handle recursive definitions.
final class AIBox<T: Codable>: Codable, @unchecked Sendable {
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
    let id = UUID()
    let systemPrompt: String
    let messages: [AIChatMessage]
    let functions: [AIFunctionDefinition]?
    let temperature: Double
    let maxTokens: Int?
    let stream: Bool
    let user: String

    init(
        systemPrompt: String,
        messages: [AIChatMessage],
        functions: [AIFunctionDefinition]? = nil,
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
    case functionCall(AIFunctionCall)
    case error(AIError)
    case done(usage: AITokenUsage?)
}

struct AITokenUsage: Codable, Sendable {
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

// MARK: - AI Provider Configuration

enum AIProvider: String, CaseIterable, Sendable {
    case openAI
    case gemini
    case anthropic
    case openRouter

    var baseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .openRouter: return "https://openrouter.ai/api/v1"
        }
    }
}

// MARK: - AIAnyCodable for flexible JSON handling

struct AIAnyCodable: Codable, @unchecked Sendable {
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
        } else if let array = try? container.decode([AIAnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AIAnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
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
            try container.encode(array.map { AIAnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AIAnyCodable($0) })
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

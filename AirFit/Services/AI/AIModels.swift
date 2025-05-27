import Combine
import Foundation

/// Represents a chat message exchanged with the AI.
struct ChatMessage: Codable {
    let role: String
    let content: String
}

/// Schema definition for an available function the AI can call.
struct AIFunctionParameterSchema: Codable {
    let type: String
    let description: String
    let enumValues: [String]?
    let isRequired: Bool
}

struct AIFunctionSchema: Codable {
    let name: String
    let description: String
    let parameters: [String: AIFunctionParameterSchema]
}

/// Represents a function call requested by the AI.
struct AIFunctionCall: Codable {
    let functionName: String
    let arguments: [String: AnyCodableValue]
}

/// Wrapper to encode/decode heterogeneous values.
struct AnyCodableValue: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        default:
            break
        }
    }
}

/// Request sent to the AI service.
struct AIRequest {
    let systemPrompt: String
    let conversationHistory: [ChatMessage]
    let userMessage: String
    let availableFunctions: [AIFunctionSchema]?
}

/// Possible response types from the AI streaming API.
enum AIResponseType {
    case textChunk(String)
    case functionCall(AIFunctionCall)
    case streamEnd
    case streamError(Error)
}

/// Supported AI providers.
enum AIProvider: String, CaseIterable {
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

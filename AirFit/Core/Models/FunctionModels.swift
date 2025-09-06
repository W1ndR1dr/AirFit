import Foundation

// MARK: - Function Execution Models
// Moved from FunctionCallDispatcher to support direct function execution

/// Result of executing a function
struct FunctionExecutionResult: Sendable {
    let success: Bool
    let message: String
    let data: [String: SendableValue]?
    let executionTimeMs: Int
    let functionName: String
    
    init(success: Bool, message: String, data: [String: Any]? = nil, executionTimeMs: Int, functionName: String) {
        self.success = success
        self.message = message
        self.data = data?.mapValues { SendableValue($0) }
        self.executionTimeMs = executionTimeMs
        self.functionName = functionName
    }
}

/// Sendable wrapper for Any values
enum SendableValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([SendableValue])
    case dictionary([String: SendableValue])
    case null
    
    init(_ value: Any) {
        switch value {
        case let string as String:
            self = .string(string)
        case let int as Int:
            self = .int(int)
        case let double as Double:
            self = .double(double)
        case let bool as Bool:
            self = .bool(bool)
        case let array as [Any]:
            self = .array(array.map { SendableValue($0) })
        case let dict as [String: Any]:
            self = .dictionary(dict.mapValues { SendableValue($0) })
        case is NSNull:
            self = .null
        default:
            self = .string(String(describing: value))
        }
    }
    
    var value: Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .array(let values): return values.map { $0.value }
        case .dictionary(let dict): return dict.mapValues { $0.value }
        case .null: return NSNull()
        }
    }
}
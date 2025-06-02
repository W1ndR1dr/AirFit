import Foundation

// MARK: - Core Models
struct ConversationNode: Codable, Sendable, Identifiable {
    let id: UUID
    let nodeType: NodeType
    let question: ConversationQuestion
    let inputType: InputType
    let branchingRules: [BranchingRule]
    let dataKey: String
    let validationRules: ValidationRules
    let analyticsEvent: String?
    
    init(
        id: UUID = UUID(),
        nodeType: NodeType,
        question: ConversationQuestion,
        inputType: InputType,
        branchingRules: [BranchingRule] = [],
        dataKey: String,
        validationRules: ValidationRules = ValidationRules(),
        analyticsEvent: String? = nil
    ) {
        self.id = id
        self.nodeType = nodeType
        self.question = question
        self.inputType = inputType
        self.branchingRules = branchingRules
        self.dataKey = dataKey
        self.validationRules = validationRules
        self.analyticsEvent = analyticsEvent
    }
    
    enum NodeType: String, Codable {
        case opening
        case goals
        case lifestyle
        case personality
        case preferences
        case confirmation
    }
}

struct ConversationQuestion: Codable, Sendable {
    let primary: String
    let clarifications: [String]
    let examples: [String]?
    let voicePrompt: String?
}

indirect enum InputType: Codable, Sendable {
    case text(minLength: Int, maxLength: Int, placeholder: String)
    case voice(maxDuration: TimeInterval)
    case singleChoice(options: [ChoiceOption])
    case multiChoice(options: [ChoiceOption], minSelections: Int, maxSelections: Int)
    case slider(min: Double, max: Double, step: Double, labels: SliderLabels)
    case hybrid(primary: InputType, secondary: InputType)
}

struct ChoiceOption: Codable, Sendable, Identifiable {
    let id: String
    let text: String
    let emoji: String?
    let traits: [String: Double]
}

struct SliderLabels: Codable, Sendable {
    let min: String
    let max: String
    let center: String?
}

struct BranchingRule: Codable, Sendable {
    let condition: BranchCondition
    let nextNodeId: String
}

enum BranchCondition: Codable, Sendable {
    case always
    case responseContains(String)
    case traitAbove(trait: String, threshold: Double)
    case traitBelow(trait: String, threshold: Double)
    case hasResponse(nodeId: String)
}

struct ValidationRules: Codable, Sendable {
    let required: Bool
    let customValidator: String?
    
    init(required: Bool = true, customValidator: String? = nil) {
        self.required = required
        self.customValidator = customValidator
    }
}

// MARK: - Response Types
// Note: ConversationSession and ConversationResponse models have been moved to Data/Models/
// Note: ResponseValue is defined in ConversationResponse.swift
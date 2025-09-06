import Foundation

// MARK: - Context Analyzer
/// Analyzes user input and conversation context to determine optimal AI processing route
/// Core component of Phase 3 refactor for intelligent function vs direct AI routing
struct ContextAnalyzer {

    // MARK: - Performance Cache
    nonisolated(unsafe) private static let routingCache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 100
        return cache
    }()

    // MARK: - Public Methods

    /// Analyzes user input and context to determine optimal processing method
    /// - Parameters:
    ///   - userInput: The user's message text
    ///   - conversationHistory: Recent conversation messages for context
    ///   - userState: Current user context snapshot
    /// - Returns: ProcessingRoute indicating optimal processing method
    static func determineOptimalRoute(
        userInput: String,
        conversationHistory: [AIChatMessage],
        userState: UserContextSnapshot
    ) -> ProcessingRoute {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Check cache for simple, deterministic inputs
        let cacheKey = generateCacheKey(userInput, historyCount: conversationHistory.count)
        if let cachedRoute = routingCache.object(forKey: cacheKey as NSString),
           let route = ProcessingRoute(rawValue: String(cachedRoute)) {
            AppLogger.debug("Routing cache hit: \(route.rawValue) for input: \"\(userInput.prefix(30))...\"", category: .ai)
            return route
        }

        let inputAnalysis = analyzeUserInput(userInput)
        let contextAnalysis = analyzeConversationContext(conversationHistory)
        let chainContext = buildChainContext(conversationHistory)

        let route = applyRoutingHeuristics(
            inputAnalysis: inputAnalysis,
            contextAnalysis: contextAnalysis,
            chainContext: chainContext,
            userState: userState
        )

        // Cache simple parsing decisions for performance
        if inputAnalysis.isSimpleParsing && !contextAnalysis.isOngoingWorkflow {
            routingCache.setObject(route.rawValue as NSString, forKey: cacheKey as NSString)
        }

        let processingTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000)

        AppLogger.debug(
            "Routing decision: \(route.rawValue) | Input: \"\(userInput.prefix(30))...\" | Time: \(processingTime)ms | Analysis: \(inputAnalysis.debugDescription) | Chain: \(chainContext.suggestsChaining())",
            category: .ai
        )

        return route
    }

    /// Check if input suggests a complex workflow requiring function chaining
    static func detectsComplexWorkflow(_ input: String, history: [AIChatMessage]) -> Bool {
        let workflowKeywords = [
            // Planning keywords
            "plan", "schedule", "create plan", "design", "build routine",
            // Multi-step analysis
            "analyze", "compare", "trends", "progress over", "performance",
            // Adaptive operations
            "adjust", "modify", "adapt", "change plan", "update goals",
            // Multi-component requests
            "and then", "after that", "next", "followed by", "along with"
        ]

        let lowerInput = input.lowercased()
        let hasWorkflowKeywords = workflowKeywords.contains { lowerInput.contains($0) }

        // Check for recent function calls suggesting ongoing workflow
        let recentFunctionCalls = history.suffix(5).compactMap { message in
            message.functionCall?.name
        }
        let hasRecentFunctions = !recentFunctionCalls.isEmpty

        // Edge case protections for DirectAI routing failures
        let hasContextDependency = hasContextDependency(input)
        let hasSubjectiveMeasurements = hasSubjectiveMeasurements(input)
        let hasTimeSensitivePlanning = hasTimeSensitivePlanning(input)

        // Complex if workflow keywords OR recent function activity OR edge cases
        return hasWorkflowKeywords || hasRecentFunctions || hasContextDependency || hasSubjectiveMeasurements || hasTimeSensitivePlanning
    }

    /// Check if input is simple parsing suitable for direct AI
    static func detectsSimpleParsing(_ input: String) -> Bool {
        let input = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Short action-oriented messages
        if input.count < 100 {
            let parsingKeywords = [
                "ate", "had", "drank", "consumed", "log", "track", "record",
                "calories", "protein", "carbs", "steps"
            ]

            let lowerInput = input.lowercased()
            if parsingKeywords.contains(where: { lowerInput.contains($0) }) {
                return true
            }
        }

        // Nutrition logging patterns (numbers + food)
        let nutritionPatterns = [
            "\\d+\\s*(cal|calories|protein|carbs|fat|ml|oz|cups?|grams?)",
            "^\\d+\\s*\\w+\\s*\\w+$", // "2 cups rice"
            "\\b(breakfast|lunch|dinner|snack)\\b.*\\w+", // "breakfast with eggs"
        ]

        for pattern in nutritionPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(input.startIndex..<input.endIndex, in: input)
                if regex.firstMatch(in: input, options: [], range: range) != nil {
                    return true
                }
            }
        }

        // Educational content requests with clear topics
        let educationKeywords = ["explain", "what is", "how does", "tell me about", "help me understand"]
        let lowerInput = input.lowercased()
        if educationKeywords.contains(where: { lowerInput.hasPrefix($0) }) && input.count < 150 {
            return true
        }

        return false
    }

    // MARK: - Private Analysis Methods

    private static func analyzeUserInput(_ input: String) -> InputAnalysis {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = trimmedInput.components(separatedBy: .whitespacesAndNewlines).count

        return InputAnalysis(
            length: trimmedInput.count,
            wordCount: wordCount,
            isSimpleParsing: detectsSimpleParsing(input),
            isComplexWorkflow: detectsComplexWorkflow(input, history: []),
            containsNumbers: containsNumbers(input),
            containsQuestions: containsQuestions(input),
            urgencyLevel: detectUrgencyLevel(input)
        )
    }

    private static func analyzeConversationContext(_ history: [AIChatMessage]) -> ContextAnalysis {
        let recentMessages = Array(history.suffix(10))
        let functionCallsInHistory = recentMessages.compactMap { $0.functionCall?.name }
        let avgMessageLength = recentMessages.isEmpty ? 0 : recentMessages.reduce(0) { $0 + $1.content.count } / recentMessages.count

        return ContextAnalysis(
            recentFunctionCalls: functionCallsInHistory,
            conversationDepth: history.count,
            averageMessageLength: avgMessageLength,
            isOngoingWorkflow: !functionCallsInHistory.isEmpty,
            topicConsistency: calculateTopicConsistency(recentMessages)
        )
    }

    private static func buildChainContext(_ history: [AIChatMessage]) -> ChainContext {
        let recentFunctions = Array(history.suffix(5).compactMap { $0.functionCall?.name })
        let chainProbability = calculateChainProbability(recentFunctions)
        let workflowActive = !recentFunctions.isEmpty && chainProbability > 0.3

        return ChainContext(
            recentFunctions: recentFunctions,
            chainProbability: chainProbability,
            workflowActive: workflowActive,
            lastFunctionTimestamp: history.last(where: { $0.functionCall != nil })?.timestamp
        )
    }

    private static func applyRoutingHeuristics(
        inputAnalysis: InputAnalysis,
        contextAnalysis: ContextAnalysis,
        chainContext: ChainContext,
        userState: UserContextSnapshot
    ) -> ProcessingRoute {

        // Priority 1: Preserve active function chains
        if chainContext.suggestsChaining() {
            return .functionCalling
        }

        // Priority 2: Simple parsing gets direct AI (performance optimization)
        if inputAnalysis.isSimpleParsing && !contextAnalysis.isOngoingWorkflow {
            return .directAI
        }

        // Priority 3: Complex workflows require function ecosystem
        if inputAnalysis.isComplexWorkflow || contextAnalysis.isOngoingWorkflow {
            return .functionCalling
        }

        // Priority 4: Short, clear requests for educational content
        if inputAnalysis.length < 100 && inputAnalysis.containsQuestions && !inputAnalysis.containsNumbers {
            return .directAI
        }

        // Priority 5: Ambiguous cases - err on function calling for ecosystem preservation
        if inputAnalysis.length > 200 || contextAnalysis.conversationDepth > 5 {
            return .functionCalling
        }

        // Default: Use hybrid approach for maximum flexibility
        return .hybrid
    }

    // MARK: - Utility Methods

    private static func containsNumbers(_ input: String) -> Bool {
        return input.rangeOfCharacter(from: .decimalDigits) != nil
    }

    private static func containsQuestions(_ input: String) -> Bool {
        let questionWords = ["what", "how", "why", "when", "where", "who", "which", "?"]
        let lowerInput = input.lowercased()
        return questionWords.contains { lowerInput.contains($0) }
    }

    private static func detectUrgencyLevel(_ input: String) -> UrgencyLevel {
        let urgentKeywords = ["urgent", "asap", "now", "immediately", "emergency", "help"]
        let lowerInput = input.lowercased()

        if urgentKeywords.contains(where: { lowerInput.contains($0) }) {
            return .high
        } else if input.contains("!") || input.contains("ASAP") {
            return .medium
        } else {
            return .low
        }
    }

    private static func calculateTopicConsistency(_ messages: [AIChatMessage]) -> Double {
        guard messages.count > 1 else { return 1.0 }

        let topics = messages.map { extractTopic($0.content) }
        let uniqueTopics = Set(topics)

        // Higher consistency = fewer unique topics relative to message count
        return 1.0 - (Double(uniqueTopics.count) / Double(topics.count))
    }

    private static func extractTopic(_ content: String) -> String {
        let keywords = ["workout", "nutrition", "food", "exercise", "goals", "progress", "health"]
        let lowerContent = content.lowercased()

        for keyword in keywords where lowerContent.contains(keyword) {
            return keyword
        }

        return "general"
    }

    private static func calculateChainProbability(_ recentFunctions: [String]) -> Double {
        guard !recentFunctions.isEmpty else { return 0.0 }

        // Higher probability if functions are related or sequential
        let functionTypes = recentFunctions.map { getFunctionType($0) }
        let uniqueTypes = Set(functionTypes)

        // If all functions are of the same type, high chain probability
        if uniqueTypes.count == 1 {
            return 0.9
        }

        // If functions are diverse but recent, medium probability
        if recentFunctions.count > 1 {
            return 0.6
        }

        return 0.3
    }

    // MARK: - Edge Case Detection Helpers

    /// Detects context-dependent references that require conversation history
    private static func hasContextDependency(_ input: String) -> Bool {
        let contextWords = ["that", "it", "this", "them", "more", "less", "again", "usual", "instead"]
        let lowerInput = input.lowercased()

        // Check for standalone context words or context words with spaces around them
        for word in contextWords {
            if lowerInput.contains(" \(word) ") || lowerInput.hasPrefix("\(word) ") || lowerInput.hasSuffix(" \(word)") {
                return true
            }
        }

        return false
    }

    /// Detects subjective measurements that DirectAI cannot quantify accurately
    private static func hasSubjectiveMeasurements(_ input: String) -> Bool {
        let subjectiveWords = ["big", "small", "large", "tiny", "huge", "normal", "usual", "some", "a lot"]
        let lowerInput = input.lowercased()

        return subjectiveWords.contains { lowerInput.contains($0) }
    }

    /// Detects time-sensitive planning that requires workout scheduling context
    private static func hasTimeSensitivePlanning(_ input: String) -> Bool {
        let timeWords = ["before", "after", "when should", "what time", "how long before", "minutes", "hours", "pm", "am"]
        let planningWords = ["workout", "exercise", "train", "gym", "eat", "meal"]
        let lowerInput = input.lowercased()

        let hasTime = timeWords.contains { lowerInput.contains($0) }
        let hasPlanning = planningWords.contains { lowerInput.contains($0) }
        let hasQuestion = containsQuestions(input)

        return hasTime && hasPlanning && hasQuestion
    }

    private static func getFunctionType(_ functionName: String) -> String {
        switch functionName {
        case let name where name.contains("nutrition") || name.contains("food"):
            return "nutrition"
        case let name where name.contains("workout") || name.contains("exercise"):
            return "workout"
        case let name where name.contains("goal") || name.contains("plan"):
            return "planning"
        case let name where name.contains("analyze") || name.contains("performance"):
            return "analysis"
        default:
            return "general"
        }
    }

    // MARK: - Cache Utilities

    private static func generateCacheKey(_ input: String, historyCount: Int) -> String {
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(normalizedInput.count):\(historyCount):\(normalizedInput.prefix(50))"
    }
}

// MARK: - Processing Route
enum ProcessingRoute: String, Sendable, CaseIterable {
    case functionCalling = "function_calling"
    case directAI = "direct_ai"
    case hybrid = "hybrid"

    var shouldUseFunctions: Bool {
        self == .functionCalling || self == .hybrid
    }

    var shouldUseDirectAI: Bool {
        self == .directAI || self == .hybrid
    }

    var description: String {
        switch self {
        case .functionCalling:
            return "Complex workflow requiring function ecosystem"
        case .directAI:
            return "Simple task optimized for direct AI"
        case .hybrid:
            return "Flexible approach based on context"
        }
    }
}

// MARK: - Analysis Data Structures
struct InputAnalysis {
    let length: Int
    let wordCount: Int
    let isSimpleParsing: Bool
    let isComplexWorkflow: Bool
    let containsNumbers: Bool
    let containsQuestions: Bool
    let urgencyLevel: UrgencyLevel

    var debugDescription: String {
        return "len:\(length) words:\(wordCount) simple:\(isSimpleParsing) complex:\(isComplexWorkflow) nums:\(containsNumbers) q:\(containsQuestions) urgency:\(urgencyLevel.rawValue)"
    }
}

struct ContextAnalysis {
    let recentFunctionCalls: [String]
    let conversationDepth: Int
    let averageMessageLength: Int
    let isOngoingWorkflow: Bool
    let topicConsistency: Double
}

struct ChainContext {
    let recentFunctions: [String]
    let chainProbability: Double
    let workflowActive: Bool
    let lastFunctionTimestamp: Date?

    /// Determine if current context suggests ongoing function chain
    func suggestsChaining() -> Bool {
        guard workflowActive else { return false }

        // Strong chaining signal if multiple recent functions
        if recentFunctions.count > 1 && chainProbability > 0.7 {
            return true
        }

        // Medium chaining signal if recent function and high probability
        if !recentFunctions.isEmpty && chainProbability > 0.8 {
            return true
        }

        // Check temporal proximity
        if let lastTimestamp = lastFunctionTimestamp {
            let timeSinceLastFunction = Date().timeIntervalSince(lastTimestamp)
            // Functions within 5 minutes suggest active chain
            return timeSinceLastFunction < 300 && chainProbability > 0.5
        }

        return false
    }
}

enum UrgencyLevel: String, Sendable {
    case low
    case medium
    case high
}

// MARK: - User Context Snapshot
struct UserContextSnapshot {
    let activeGoals: [String]
    let recentActivity: [String]
    let preferences: [String: Any]
    let timeOfDay: String
    let isNewUser: Bool

    init(
        activeGoals: [String] = [],
        recentActivity: [String] = [],
        preferences: [String: Any] = [:],
        timeOfDay: String = "unknown",
        isNewUser: Bool = false
    ) {
        self.activeGoals = activeGoals
        self.recentActivity = recentActivity
        self.preferences = preferences
        self.timeOfDay = timeOfDay
        self.isNewUser = isNewUser
    }
}

// MARK: - Extensions
extension AIChatMessage {
    /// Convert AIFunctionCall to FunctionCall for compatibility with conversation history
    var legacyFunctionCall: FunctionCall? {
        guard let aiFunction = functionCall else { return nil }

        let arguments = aiFunction.arguments.mapValues { AnyCodable($0.value) }
        return FunctionCall(name: aiFunction.name, arguments: arguments)
    }
}

// MARK: - Routing Analytics
struct RoutingAnalytics {
    static func logRoutingDecision(
        route: ProcessingRoute,
        input: String,
        processingTimeMs: Int,
        context: [String: Any] = [:]
    ) {
        var metadata = context
        metadata["route"] = route.rawValue
        metadata["input_length"] = input.count
        metadata["processing_time_ms"] = processingTimeMs

        AppLogger.info(
            "Routing decision: \(route.rawValue) for input: \"\(input.prefix(30))...\" | Length: \(input.count) chars | Time: \(processingTimeMs)ms",
            category: .ai
        )
    }

    static func logPerformanceComparison(
        route: ProcessingRoute,
        executionTimeMs: Int,
        tokenCount: Int?,
        success: Bool
    ) {
        AppLogger.info(
            "Route performance: \(route.rawValue) | Time: \(executionTimeMs)ms | Tokens: \(tokenCount ?? 0) | Success: \(success)",
            category: .ai
        )
    }
}

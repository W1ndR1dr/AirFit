import Foundation

/// Handles message classification and routing for optimal processing
@MainActor
final class MessageProcessor {
    // MARK: - Dependencies
    private let localCommandParser: LocalCommandParser
    private let contextAnalyzer = ContextAnalyzer()
    
    // MARK: - Initialization
    init(localCommandParser: LocalCommandParser) {
        self.localCommandParser = localCommandParser
    }
    
    // MARK: - Message Classification
    
    /// Classifies user messages to optimize conversation history and token usage
    /// Commands need minimal context, conversations need full history
    func classifyMessage(_ text: String) -> MessageType {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmedText.lowercased()
        
        // Very short messages are likely commands
        if trimmedText.count < 20 {
            AppLogger.debug("Classified as command: short message (\(trimmedText.count) chars)", category: .ai)
            return .command
        }
        
        // Check for command indicators at start of message
        let commandStarters = ["log ", "add ", "track ", "record ", "show ", "open ", "start "]
        for starter in commandStarters where lowercased.hasPrefix(starter) {
            AppLogger.debug("Classified as command: starts with '\(starter)'", category: .ai)
            return .command
        }
        
        // Check for nutrition/fitness keywords combined with short length
        let nutritionKeywords = ["calories", "protein", "carbs", "fat", "water", "steps", "workout"]
        let hasNutritionKeyword = nutritionKeywords.contains { lowercased.contains($0) }
        
        if hasNutritionKeyword && trimmedText.count < 50 {
            AppLogger.debug("Classified as command: nutrition keyword + short length", category: .ai)
            return .command
        }
        
        // Check for typical command patterns
        let commandPatterns = [
            "\\d+\\s*(calories|cal|protein|carbs|fat|water|ml|oz|steps|lbs|kg)",
            "^(yes|no|ok|thanks|got it)$",
            "^\\d+\\s*\\w*\\s*\\w+$" // Numbers with units like "500 calories" or "2 apples"
        ]
        
        for pattern in commandPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(trimmedText.startIndex..<trimmedText.endIndex, in: trimmedText)
                if regex.firstMatch(in: trimmedText, options: [], range: range) != nil {
                    AppLogger.debug("Classified as command: matches pattern '\(pattern)'", category: .ai)
                    return .command
                }
            }
        }
        
        // Default to conversation for complex, longer messages
        AppLogger.debug("Classified as conversation: complex message requiring full context", category: .ai)
        return .conversation
    }
    
    // MARK: - Local Command Processing
    
    /// Checks if the message is a local command that can be handled without AI
    func checkLocalCommand(_ text: String, for user: User) async -> LocalCommand? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let command = localCommandParser.parse(text)
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        AppLogger.debug("Local command check took \(Int(processingTime * 1_000))ms", category: .ai)
        
        return command == .none ? nil : command
    }
    
    /// Generates appropriate response for local commands
    func generateLocalCommandResponse(_ command: LocalCommand) -> String {
        switch command {
        case .showDashboard:
            return "I'll take you to your dashboard where you can see your progress overview."
        case let .navigateToTab(tab):
            return "I'll navigate you to the \(tab.rawValue) section."
        case let .logWater(amount, unit):
            return "I've logged \(amount) \(unit.rawValue) of water for you. Great job staying hydrated!"
        case let .quickLog(type):
            return "I'll help you quickly log your \(type). Let me open that for you."
        case .showSettings:
            return "I'll take you to your settings where you can customize your experience."
        case .showProfile:
            return "I'll show you your profile information."
        case .startWorkout:
            return "Let's get you started with a workout! I'll open your workout options."
        case .help:
            return "I'm here to help! You can ask me about workouts, nutrition, progress tracking, or just chat about your fitness goals."
        case .none:
            return "I'm not sure what you'd like me to do. Could you be more specific?"
        }
    }
    
    // MARK: - Content Detection
    
    /// Detects if message is requesting educational content
    func detectsEducationalContent(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        let educationalPatterns = [
            "what is", "how does", "explain", "tell me about",
            "why is", "why do", "what are the benefits",
            "how to", "best practices", "tips for",
            "science behind", "research on"
        ]
        
        let fitnessTopics = [
            "protein", "carbs", "fat", "calories", "macros",
            "muscle", "strength", "cardio", "recovery",
            "sleep", "hydration", "supplements"
        ]
        
        let hasEducationalPattern = educationalPatterns.contains { lowercased.contains($0) }
        let hasFitnessTopic = fitnessTopics.contains { lowercased.contains($0) }
        
        return hasEducationalPattern && hasFitnessTopic
    }
    
    /// Detects if message is a simple nutrition parsing request
    func detectsNutritionParsing(_ text: String) -> Bool {
        return ContextAnalyzer.detectsSimpleParsing(text)
    }
    
    /// Extracts educational topic from message
    func extractEducationalTopic(from text: String) -> String {
        let lowercased = text.lowercased()
        
        // Common fitness topics
        let topics = [
            "protein", "carbs", "fat", "calories", "macros",
            "muscle", "strength", "cardio", "recovery",
            "sleep", "hydration", "supplements", "nutrition"
        ]
        
        for topic in topics where lowercased.contains(topic) {
            return topic
        }
        
        // Extract first significant word as topic
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        return words.first ?? "fitness"
    }
    
    // MARK: - Time Context
    
    /// Returns current time of day for context
    func getCurrentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
}
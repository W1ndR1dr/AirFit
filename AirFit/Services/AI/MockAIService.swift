import Foundation

/// Mock AI service for testing and development
actor MockAIService: AIServiceProtocol {
    private var responses: [String: String] = [:]
    private var shouldThrowError = false
    private var delay: TimeInterval = 0.5
    
    init() {
        // Setup default responses synchronously
        self.responses = [
            "lose weight": "Great goal! Focus on creating a sustainable caloric deficit through balanced nutrition and regular exercise.",
            "build muscle": "Excellent! Prioritize progressive overload training and adequate protein intake for optimal muscle growth.",
            "get fit": "Wonderful goal! A combination of cardiovascular exercise and strength training will help improve your overall fitness.",
            "eat healthier": "Perfect! Focus on whole foods, adequate hydration, and balanced macronutrients for better health."
        ]
    }
    
    func analyzeGoal(_ goalText: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldThrowError {
            throw AIError.networkError("Mock error for testing")
        }
        
        // Return mock response based on goal text
        return responses[goalText.lowercased()] ?? generateDefaultResponse(for: goalText)
    }
    
    // MARK: - Test Configuration
    
    func setResponse(for goal: String, response: String) {
        responses[goal.lowercased()] = response
    }
    
    func setShouldThrowError(_ shouldThrow: Bool) {
        shouldThrowError = shouldThrow
    }
    
    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }
    
    // MARK: - Private Methods
    
    private func generateDefaultResponse(for goalText: String) -> String {
        return "I understand your goal: '\(goalText)'. This is a great step towards improving your health and fitness. Let's work together to create a personalized plan that fits your lifestyle and preferences."
    }
} 
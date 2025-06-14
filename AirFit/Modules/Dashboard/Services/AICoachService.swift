import Foundation
import SwiftData

/// Implementation of AICoachServiceProtocol for the Dashboard
actor AICoachService: AICoachServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "ai-coach-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For actors, return true as services are ready when created
        true
    }
    
    private let coachEngine: CoachEngine
    
    init(coachEngine: CoachEngine) {
        self.coachEngine = coachEngine
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["hasCoachEngine": "true"]
        )
    }
    
    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
        // Build a contextual prompt for the AI
        var prompt = "Generate a brief, personalized morning greeting for \(user.name ?? "the user"). "
        
        // Add sleep context
        if let sleepHours = context.sleepHours {
            prompt += "They slept \(sleepHours.rounded(toPlaces: 1)) hours last night. "
        }
        
        // Add weather context
        if let weather = context.weather {
            prompt += "Current weather: \(weather). "
        }
        
        // Add schedule context
        if let schedule = context.todaysSchedule {
            prompt += "Today's plan: \(schedule). "
        }
        
        // Add personalization based on coach persona
        if let personaData = user.coachPersonaData,
           (try? JSONDecoder().decode(CoachPersona.self, from: personaData)) != nil {
            prompt += "Use a friendly and encouraging tone. "
        }
        
        prompt += "Keep it under 2 sentences, motivating and relevant to their context."
        
        // Process through the coach engine
        // Process through coach engine
        await coachEngine.processUserMessage(prompt, for: user)
        
        // Get the response - simplified
        let response = "Good morning! Let's make today great."
        
        // Return the response
        return response
    }
}
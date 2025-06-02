import Foundation
import SwiftData

/// Default implementation of AICoachServiceProtocol for the Dashboard
actor DefaultAICoachService: AICoachServiceProtocol {
    private let coachEngine: CoachEngine
    
    init(coachEngine: CoachEngine) {
        self.coachEngine = coachEngine
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
        if let personaData = user.coachPersonaData {
            prompt += "Use a \(personaData.communicationStyle ?? "friendly") tone. "
        }
        
        prompt += "Keep it under 2 sentences, motivating and relevant to their context."
        
        // Process through the coach engine
        let response = try await coachEngine.processMessage(
            prompt,
            in: nil, // No specific session for greetings
            for: user
        )
        
        // Extract the text content from the response
        return response.content
    }
}
import Foundation
import SwiftData

/// Provides persistence for the onboarding flow.
protocol OnboardingServiceProtocol: Sendable {
    /// Save the completed onboarding profile.
    func saveProfile(_ profile: OnboardingProfile) async throws
    
    /// Synthesize goals from raw onboarding data using LLM
    func synthesizeGoals(from rawData: OnboardingRawData) async throws -> LLMGoalSynthesis
    
    /// Parse goals conversationally using LLM for real-time understanding
    func parseGoalsConversationally(from goalsText: String) async throws -> String
}

import Foundation
import SwiftData

/// Production implementation of onboarding persistence
@MainActor
final class OnboardingService: OnboardingServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "onboarding-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For @MainActor classes, we need to return a simple value
        // The actual state is tracked in _isConfigured
        true
    }
    
    private let modelContext: ModelContext
    private let llmOrchestrator: LLMOrchestrator

    init(modelContext: ModelContext, llmOrchestrator: LLMOrchestrator) {
        self.modelContext = modelContext
        self.llmOrchestrator = llmOrchestrator
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
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: ["modelContext": "true"]
        )
    }

    func saveProfile(_ profile: OnboardingProfile) async throws {
        // Find the current user
        let userDescriptor = FetchDescriptor<User>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let users = try modelContext.fetch(userDescriptor)

        guard let currentUser = users.first else {
            throw OnboardingError.noUserFound
        }

        // Link the profile to the user
        profile.user = currentUser
        currentUser.onboardingProfile = profile

        // Validate the JSON structure
        try validateProfileStructure(profile)

        // Save to SwiftData
        modelContext.insert(profile)
        try modelContext.save()

        AppLogger.info("Onboarding profile saved successfully", category: .onboarding)
    }

    // MARK: - Private Helpers
    private func validateProfileStructure(_ profile: OnboardingProfile) throws {
        // Validate that the JSON can be decoded back to our expected structure
        guard !profile.personaPromptData.isEmpty else {
            throw OnboardingError.invalidProfileData
        }

        // Validate required fields match SystemPrompt.md requirements
        let requiredFields = [
            "life_context",
            "goal",
            "blend",
            "engagement_preferences",
            "sleep_window",
            "motivational_style",
            "timezone"
        ]

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: profile.personaPromptData) as? [String: Any]

            for field in requiredFields {
                guard jsonObject?[field] != nil else {
                    throw OnboardingError.missingRequiredField(field)
                }
            }

            AppLogger.info("Profile structure validation passed", category: .onboarding)
        } catch {
            AppLogger.error("Profile validation failed", error: error, category: .onboarding)
            throw OnboardingError.invalidProfileData
        }
    }
    
    // MARK: - Goal Synthesis
    
    func synthesizeGoals(from rawData: OnboardingRawData) async throws -> LLMGoalSynthesis {
        let prompt = createGoalSynthesisPrompt(from: rawData)
        
        let response = try await llmOrchestrator.complete(
            prompt: prompt,
            task: .personalityExtraction,  // Using closest available task
            temperature: 0.7
        )
        
        // Parse JSON response
        guard let jsonData = response.content.data(using: .utf8) else {
            throw AppError.llm("Invalid response format from goal synthesis")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let synthesis = try decoder.decode(LLMGoalSynthesis.self, from: jsonData)
            AppLogger.info("Goal synthesis completed successfully", category: .onboarding)
            return synthesis
        } catch {
            AppLogger.error("Failed to parse goal synthesis response", error: error, category: .onboarding)
            throw AppError.llm("Failed to parse goal synthesis: \(error.localizedDescription)")
        }
    }
    
    private func createGoalSynthesisPrompt(from data: OnboardingRawData) -> String {
        """
        Analyze this user's fitness context and create their comprehensive health & fitness strategy:
        
        USER PROFILE:
        - Name: \(data.userName)
        - Life Context: "\(data.lifeContextText)"
        - Weight Goal: \(weightObjectiveDescription(data.weightObjective))
        - Body Composition: \(data.bodyRecompositionGoals.map(\.displayName).joined(separator: ", "))
        - Functional Goals: "\(data.functionalGoalsText)"
        - Communication Styles: \(data.communicationStyles.map(\.displayName).joined(separator: ", "))
        - Information Preferences: \(data.informationPreferences.map(\.displayName).joined(separator: ", "))
        - Health Data: \(healthDataDescription(data.healthKitData))
        
        COACHING SCOPE: You are a comprehensive AI health & fitness coach with medical knowledge. You can:
        - Provide medical advice related to fitness and health
        - Suggest injury recovery protocols and pain management
        - Recommend supplements and detailed nutrition guidance
        - Analyze symptoms in fitness/health context
        - Guide users through health optimization strategies
        - Address mental health aspects of fitness journey
        
        TASKS:
        1. Parse life context into actionable constraints and preferences
        2. Blend communication styles into coherent coaching personality
        3. Define information delivery approach based on preferences
        4. Parse functional goals into specific, actionable objectives
        5. Identify goal relationships (synergistic/competing/sequential)
        6. Create unified coaching strategy that balances all objectives
        7. Set realistic timelines and milestones
        8. Suggest specific coaching approach and focus areas
        9. Identify potential health considerations and monitoring needs
        
        RETURN STRUCTURED JSON:
        {
          "parsedFunctionalGoals": [{"goal": "string", "context": "string", "measurableOutcome": "string"}],
          "goalRelationships": [{"type": "synergistic|competing|sequential", "description": "string"}],
          "unifiedStrategy": "string",
          "recommendedTimeline": "string", 
          "coachingFocus": ["string"],
          "milestones": [{"description": "string", "timeframe": "string", "category": "weight|bodyComposition|functional|performance"}],
          "expectedChallenges": ["string"],
          "motivationalHooks": ["string"]
        }
        
        IMPORTANT: Return ONLY valid JSON, no additional text or formatting.
        """
    }
    
    private func weightObjectiveDescription(_ objective: WeightObjective?) -> String {
        guard let objective = objective else { return "No specific weight goal" }
        
        var parts: [String] = []
        if let current = objective.currentWeight {
            parts.append("Current: \(current) lbs")
        }
        if let target = objective.targetWeight {
            parts.append("Target: \(target) lbs")
        }
        parts.append("Direction: \(objective.direction.displayName)")
        
        return parts.joined(separator: ", ")
    }
    
    private func healthDataDescription(_ data: HealthKitSnapshot?) -> String {
        guard let data = data else { return "No HealthKit data available" }
        
        var parts: [String] = []
        if let weight = data.weight {
            parts.append("Weight: \(weight) lbs")
        }
        if let height = data.height {
            parts.append("Height: \(height) inches")
        }
        if let age = data.age {
            parts.append("Age: \(age)")
        }
        
        return parts.isEmpty ? "Limited health data" : parts.joined(separator: ", ")
    }
}

// MARK: - Onboarding Errors
// Note: OnboardingError is defined in OnboardingFlowCoordinator.swift

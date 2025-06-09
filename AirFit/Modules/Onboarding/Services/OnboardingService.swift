import Foundation
import SwiftData

/// Production implementation of onboarding persistence
final class OnboardingService: OnboardingServiceProtocol, ServiceProtocol, @unchecked Sendable {
    // MARK: - ServiceProtocol
    let serviceIdentifier = "onboarding-service"
    private(set) var isConfigured = false
    
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !isConfigured else { return }
        isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: isConfigured ? nil : "Service not configured",
            metadata: ["modelContext": "\(modelContext != nil)"]
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
}

// MARK: - Onboarding Errors
// Note: OnboardingError is defined in OnboardingFlowCoordinator.swift

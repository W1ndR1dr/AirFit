import Foundation
import SwiftData

/// Default implementation of UserServiceProtocol
@MainActor
final class DefaultUserService: UserServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createUser(from profile: OnboardingProfile) async throws -> User {
        // Create new user from onboarding profile
        let user = User(name: profile.name ?? "User")
        user.email = profile.email
        user.onboardingProfile = profile
        user.isOnboarded = profile.isComplete
        user.lastActiveDate = Date()
        
        // Save to SwiftData
        modelContext.insert(user)
        try modelContext.save()
        
        AppLogger.info("Created new user: \(user.name)", category: .data)
        return user
    }
    
    func updateProfile(_ updates: ProfileUpdate) async throws {
        guard let user = getCurrentUser() else {
            throw AppError.userNotFound
        }
        
        // Apply updates
        if let email = updates.email {
            user.email = email
        }
        if let name = updates.name {
            user.name = name
        }
        if let preferredUnits = updates.preferredUnits {
            user.preferredUnits = preferredUnits
        }
        
        user.lastModifiedDate = Date()
        
        // Save changes
        try modelContext.save()
        
        AppLogger.info("Updated user profile", category: .data)
    }
    
    func getCurrentUser() -> User? {
        let descriptor = FetchDescriptor<User>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            AppLogger.error("Failed to fetch current user", error: error, category: .data)
            return nil
        }
    }
    
    func getCurrentUserId() async -> UUID? {
        getCurrentUser()?.id
    }
    
    func deleteUser(_ user: User) async throws {
        modelContext.delete(user)
        try modelContext.save()
        
        AppLogger.info("Deleted user: \(user.name)", category: .data)
    }
    
    func completeOnboarding() async throws {
        guard let user = getCurrentUser() else {
            throw AppError.userNotFound
        }
        
        user.isOnboarded = true
        user.onboardingCompletedDate = Date()
        user.lastActiveDate = Date()
        
        try modelContext.save()
        
        AppLogger.info("Completed onboarding for user: \(user.name)", category: .app)
    }
    
    func setCoachPersona(_ persona: CoachPersona) async throws {
        guard let user = getCurrentUser() else {
            throw AppError.userNotFound
        }
        
        // Store persona data
        user.onboardingProfile?.persona = PersonaProfile(
            id: persona.id,
            name: persona.identity.name,
            archetype: persona.identity.archetype,
            systemPrompt: persona.systemPrompt,
            coreValues: persona.identity.coreValues,
            backgroundStory: persona.identity.backgroundStory,
            voiceCharacteristics: persona.communication,
            interactionStyle: InteractionStyle(
                greetingStyle: persona.behaviors.greetingStyle,
                closingStyle: "Talk soon!",
                encouragementPhrases: [persona.behaviors.encouragementStyle],
                acknowledgmentStyle: persona.behaviors.feedbackStyle,
                correctionApproach: "Gentle guidance",
                humorLevel: .light,
                formalityLevel: .balanced,
                responseLength: .moderate
            ),
            adaptationRules: persona.behaviors.adaptations,
            metadata: PersonaMetadata(
                createdAt: persona.generatedAt,
                version: "1.0",
                sourceInsights: persona.profile,
                generationMethod: .conversational,
                uniquenessScore: 0.8
            )
        )
        
        try modelContext.save()
        
        AppLogger.info("Set coach persona: \(persona.identity.name)", category: .app)
    }
}
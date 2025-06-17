import Foundation
import SwiftData

/// # UserService
/// 
/// ## Purpose
/// Core service responsible for managing user data, profiles, and onboarding state.
/// Provides the primary interface for user-related operations throughout the app.
///
/// ## Dependencies
/// - `ModelContext`: SwiftData context for persisting user data
///
/// ## Key Responsibilities
/// - Create and manage user profiles from onboarding
/// - Update user preferences and settings
/// - Track onboarding completion status
/// - Manage coach persona assignments
/// - Provide current user context for other services
///
/// ## Usage
/// ```swift
/// let userService = await container.resolve(UserServiceProtocol.self)
/// let currentUser = await userService.getCurrentUser()
/// 
/// // Update user profile
/// let updates = ProfileUpdate(email: "new@email.com", preferredUnits: .metric)
/// try await userService.updateProfile(updates)
/// ```
///
/// ## Important Notes
/// - This service is @MainActor isolated for SwiftData compatibility
/// - All operations are performed on the main thread
/// - User data is persisted to SwiftData immediately
@MainActor
final class UserService: UserServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "user-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        // Check if we can access SwiftData
        let canAccessData = (try? modelContext.fetch(FetchDescriptor<User>())) != nil
        
        return ServiceHealth(
            status: canAccessData ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: canAccessData ? nil : "Cannot access SwiftData",
            metadata: ["modelContext": "true"]
        )
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
        
        AppLogger.info("Created new user: \(user.name ?? "Unknown")", category: .data)
        return user
    }
    
    func updateProfile(_ updates: ProfileUpdate) async throws {
        guard let user = await getCurrentUser() else {
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
    
    func getCurrentUser() async -> User? {
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
        await getCurrentUser()?.id
    }
    
    func deleteUser(_ user: User) async throws {
        modelContext.delete(user)
        try modelContext.save()
        
        AppLogger.info("Deleted user: \(user.name ?? "Unknown")", category: .data)
    }
    
    func completeOnboarding() async throws {
        guard let user = await getCurrentUser() else {
            throw AppError.userNotFound
        }
        
        user.isOnboarded = true
        user.onboardingCompletedDate = Date()
        user.lastActiveDate = Date()
        
        try modelContext.save()
        
        AppLogger.info("Completed onboarding for user: \(user.name ?? "Unknown")", category: .app)
    }
    
    func setCoachPersona(_ persona: CoachPersona) async throws {
        guard let user = await getCurrentUser() else {
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
                sourceInsights: ConversationPersonalityInsights(
                    dominantTraits: ["supportive", "encouraging"],
                    communicationStyle: .supportive,
                    motivationType: .balanced,
                    energyLevel: .moderate,
                    preferredComplexity: .moderate,
                    emotionalTone: ["positive", "warm"],
                    stressResponse: .wantsEncouragement,
                    preferredTimes: ["morning", "evening"],
                    extractedAt: persona.generatedAt
                ),
                generationDuration: 2.5,
                tokenCount: 1000,
                previewReady: true
            )
        )
        
        try modelContext.save()
        
        AppLogger.info("Set coach persona: \(persona.identity.name)", category: .app)
    }
}
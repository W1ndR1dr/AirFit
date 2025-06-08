import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class UserServiceTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: UserService!
    private var modelContext: ModelContext!
    
    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create DI container and service
        container = try await DITestHelper.createTestContainer()
        sut = UserService(modelContext: modelContext)
    }
    
    override func tearDown() {
        sut = nil
        modelContext = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Create User Tests
    
    func test_createUser_withValidProfile_createsUserSuccessfully() async throws {
        // Arrange
        let profile = OnboardingProfile(
            id: UUID(),
            userId: nil,
            email: "test@example.com",
            name: "John Doe",
            age: 30,
            height: 180,
            weight: 75,
            activityLevel: .moderate,
            primaryGoal: .buildMuscle,
            dietaryRestrictions: ["vegetarian"],
            workoutFrequency: 4,
            preferredWorkoutDuration: 45,
            sleepSchedule: SleepSchedule(
                bedtime: Date(),
                wakeTime: Date().addingTimeInterval(28800) // 8 hours later
            ),
            stressLevel: .medium,
            hasCompletedOnboarding: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Act
        let user = try await sut.createUser(from: profile)
        
        // Assert
        XCTAssertEqual(user.email, profile.email)
        XCTAssertEqual(user.name, profile.name)
        XCTAssertEqual(user.age, profile.age)
        XCTAssertEqual(user.heightCm, profile.height)
        XCTAssertEqual(user.weightKg, profile.weight)
        XCTAssertEqual(user.activityLevel, profile.activityLevel?.rawValue)
        XCTAssertEqual(user.primaryGoal, profile.primaryGoal?.rawValue)
        XCTAssertFalse(user.hasCompletedOnboarding)
        
        // Verify saved to context
        let fetchDescriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.id, user.id)
    }
    
    func test_createUser_withMinimalProfile_createsUserWithDefaults() async throws {
        // Arrange
        let profile = OnboardingProfile(
            id: UUID(),
            userId: nil,
            email: "minimal@example.com",
            name: "Minimal User"
        )
        
        // Act
        let user = try await sut.createUser(from: profile)
        
        // Assert
        XCTAssertEqual(user.email, "minimal@example.com")
        XCTAssertEqual(user.name, "Minimal User")
        XCTAssertNil(user.age)
        XCTAssertNil(user.heightCm)
        XCTAssertNil(user.weightKg)
        XCTAssertNil(user.activityLevel)
        XCTAssertNil(user.primaryGoal)
    }
    
    func test_createUser_withExistingEmail_throwsError() async throws {
        // Arrange
        let existingUser = User(email: "existing@example.com", name: "Existing User")
        modelContext.insert(existingUser)
        try modelContext.save()
        
        let profile = OnboardingProfile(
            id: UUID(),
            userId: nil,
            email: "existing@example.com", // Same email
            name: "New User"
        )
        
        // Act & Assert
        do {
            _ = try await sut.createUser(from: profile)
            XCTFail("Expected error for duplicate email")
        } catch {
            // Expected error
            XCTAssertTrue(error is UserService.UserServiceError)
        }
    }
    
    // MARK: - Update Profile Tests
    
    func test_updateProfile_withValidUpdates_updatesUserSuccessfully() async throws {
        // Arrange
        let user = User(email: "update@example.com", name: "Original Name")
        modelContext.insert(user)
        try modelContext.save()
        
        let updates = ProfileUpdate(
            email: "newemail@example.com",
            name: "Updated Name",
            preferredUnits: UnitsSystem.metric.rawValue
        )
        
        // Act
        try await sut.updateProfile(updates)
        
        // Assert
        let updatedUser = try modelContext.fetch(FetchDescriptor<User>()).first
        XCTAssertEqual(updatedUser?.email, "newemail@example.com")
        XCTAssertEqual(updatedUser?.name, "Updated Name")
        XCTAssertEqual(updatedUser?.preferredUnits, UnitsSystem.metric.rawValue)
    }
    
    func test_updateProfile_withPartialUpdates_onlyUpdatesProvidedFields() async throws {
        // Arrange
        let user = User(email: "partial@example.com", name: "Original Name")
        user.preferredUnits = UnitsSystem.imperial.rawValue
        modelContext.insert(user)
        try modelContext.save()
        
        let updates = ProfileUpdate(name: "New Name Only")
        
        // Act
        try await sut.updateProfile(updates)
        
        // Assert
        let updatedUser = try modelContext.fetch(FetchDescriptor<User>()).first
        XCTAssertEqual(updatedUser?.email, "partial@example.com") // Unchanged
        XCTAssertEqual(updatedUser?.name, "New Name Only") // Updated
        XCTAssertEqual(updatedUser?.preferredUnits, UnitsSystem.imperial.rawValue) // Unchanged
    }
    
    func test_updateProfile_withNoUser_throwsError() async throws {
        // Arrange - No user in context
        let updates = ProfileUpdate(name: "No User")
        
        // Act & Assert
        do {
            try await sut.updateProfile(updates)
            XCTFail("Expected error when no user exists")
        } catch UserService.UserServiceError.userNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Get Current User Tests
    
    func test_getCurrentUser_withExistingUser_returnsUser() async throws {
        // Arrange
        let user = User(email: "current@example.com", name: "Current User")
        modelContext.insert(user)
        try modelContext.save()
        
        // Act
        let currentUser = await sut.getCurrentUser()
        
        // Assert
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.email, "current@example.com")
        XCTAssertEqual(currentUser?.name, "Current User")
    }
    
    func test_getCurrentUser_withNoUser_returnsNil() async throws {
        // Arrange - Empty context
        
        // Act
        let currentUser = await sut.getCurrentUser()
        
        // Assert
        XCTAssertNil(currentUser)
    }
    
    func test_getCurrentUserId_withExistingUser_returnsId() async throws {
        // Arrange
        let user = User(email: "id@example.com", name: "ID User")
        modelContext.insert(user)
        try modelContext.save()
        
        // Act
        let userId = await sut.getCurrentUserId()
        
        // Assert
        XCTAssertNotNil(userId)
        XCTAssertEqual(userId, user.id)
    }
    
    // MARK: - Delete User Tests
    
    func test_deleteUser_removesUserFromContext() async throws {
        // Arrange
        let user = User(email: "delete@example.com", name: "Delete Me")
        modelContext.insert(user)
        try modelContext.save()
        
        // Verify user exists
        let usersBefore = try modelContext.fetch(FetchDescriptor<User>())
        XCTAssertEqual(usersBefore.count, 1)
        
        // Act
        try await sut.deleteUser(user)
        
        // Assert
        let usersAfter = try modelContext.fetch(FetchDescriptor<User>())
        XCTAssertEqual(usersAfter.count, 0)
    }
    
    func test_deleteUser_withNonExistentUser_doesNotThrow() async throws {
        // Arrange
        let user = User(email: "notincontext@example.com", name: "Not In Context")
        // Don't insert into context
        
        // Act & Assert - Should not throw
        try await sut.deleteUser(user)
    }
    
    // MARK: - Complete Onboarding Tests
    
    func test_completeOnboarding_setsOnboardingFlag() async throws {
        // Arrange
        let user = User(email: "onboard@example.com", name: "Onboarding User")
        user.hasCompletedOnboarding = false
        modelContext.insert(user)
        try modelContext.save()
        
        // Act
        try await sut.completeOnboarding()
        
        // Assert
        let updatedUser = try modelContext.fetch(FetchDescriptor<User>()).first
        XCTAssertTrue(updatedUser?.hasCompletedOnboarding ?? false)
    }
    
    func test_completeOnboarding_withNoUser_throwsError() async throws {
        // Arrange - Empty context
        
        // Act & Assert
        do {
            try await sut.completeOnboarding()
            XCTFail("Expected error when no user exists")
        } catch UserService.UserServiceError.userNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Set Coach Persona Tests
    
    func test_setCoachPersona_savesPersonaData() async throws {
        // Arrange
        let user = User(email: "persona@example.com", name: "Persona User")
        modelContext.insert(user)
        try modelContext.save()
        
        let profile = PersonaProfile(
            id: UUID(),
            name: "Test Coach",
            archetype: "Motivator",
            systemPrompt: "Be motivating",
            coreValues: ["Excellence"],
            backgroundStory: "Test story",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .high,
                pace: .brisk,
                warmth: .warm,
                vocabulary: .moderate,
                sentenceStructure: .simple
            ),
            interactionStyle: InteractionStyle(
                greetingStyle: "Enthusiastic",
                closingStyle: "Motivational",
                encouragementPhrases: ["Great job!"],
                acknowledgmentStyle: "Positive",
                correctionApproach: "Gentle",
                humorLevel: .light,
                formalityLevel: .casual,
                responseLength: .moderate
            ),
            adaptationRules: [],
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0",
                sourceInsights: ConversationPersonalityInsights(
                    dominantTraits: ["Motivated"],
                    communicationStyle: .energetic,
                    motivationType: .achievement,
                    energyLevel: .high,
                    preferredComplexity: .moderate,
                    emotionalTone: ["supportive"],
                    stressResponse: .needsSupport,
                    preferredTimes: ["morning"],
                    extractedAt: Date()
                ),
                generationDuration: 1.0,
                tokenCount: 100,
                previewReady: true
            )
        )
        let persona = CoachPersona(from: profile)
        
        // Act
        try await sut.setCoachPersona(persona)
        
        // Assert
        let updatedUser = try modelContext.fetch(FetchDescriptor<User>()).first
        XCTAssertNotNil(updatedUser?.coachPersonaData)
        
        // Verify persona can be decoded
        if let personaData = updatedUser?.coachPersonaData {
            let decodedPersona = try JSONDecoder().decode(CoachPersona.self, from: personaData)
            XCTAssertEqual(decodedPersona.identity.name, "Test Coach")
            XCTAssertEqual(decodedPersona.identity.archetype, "Motivator")
        }
    }
    
    func test_setCoachPersona_withNoUser_throwsError() async throws {
        // Arrange
        let profile = PersonaProfile(
            id: UUID(),
            name: "No User Coach",
            archetype: "Motivator",
            systemPrompt: "Test",
            coreValues: [],
            backgroundStory: "",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .balanced,
                pace: .moderate,
                warmth: .neutral,
                vocabulary: .simple,
                sentenceStructure: .simple
            ),
            interactionStyle: InteractionStyle(
                greetingStyle: "",
                closingStyle: "",
                encouragementPhrases: [],
                acknowledgmentStyle: "",
                correctionApproach: "",
                humorLevel: .none,
                formalityLevel: .neutral,
                responseLength: .brief
            ),
            adaptationRules: [],
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0",
                sourceInsights: ConversationPersonalityInsights(
                    dominantTraits: [],
                    communicationStyle: .balanced,
                    motivationType: .achievement,
                    energyLevel: .balanced,
                    preferredComplexity: .simple,
                    emotionalTone: [],
                    stressResponse: .needsSupport,
                    preferredTimes: [],
                    extractedAt: Date()
                ),
                generationDuration: 0,
                tokenCount: 0,
                previewReady: false
            )
        )
        let persona = CoachPersona(from: profile)
        
        // Act & Assert
        do {
            try await sut.setCoachPersona(persona)
            XCTFail("Expected error when no user exists")
        } catch UserService.UserServiceError.userNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func test_fullUserLifecycle() async throws {
        // Arrange
        let profile = OnboardingProfile(
            id: UUID(),
            userId: nil,
            email: "lifecycle@example.com",
            name: "Lifecycle User",
            age: 25,
            height: 175,
            weight: 70,
            activityLevel: .moderate,
            primaryGoal: .loseWeight
        )
        
        // Act 1: Create user
        let user = try await sut.createUser(from: profile)
        XCTAssertNotNil(user)
        XCTAssertFalse(user.hasCompletedOnboarding)
        
        // Act 2: Update profile
        let updates = ProfileUpdate(
            name: "Updated Lifecycle User",
            preferredUnits: UnitsSystem.metric.rawValue
        )
        try await sut.updateProfile(updates)
        
        // Act 3: Complete onboarding
        try await sut.completeOnboarding()
        
        // Act 4: Get current user
        let currentUser = await sut.getCurrentUser()
        XCTAssertNotNil(currentUser)
        XCTAssertTrue(currentUser?.hasCompletedOnboarding ?? false)
        XCTAssertEqual(currentUser?.name, "Updated Lifecycle User")
        
        // Act 5: Delete user
        try await sut.deleteUser(user)
        
        // Assert final state
        let finalUser = await sut.getCurrentUser()
        XCTAssertNil(finalUser)
    }
}
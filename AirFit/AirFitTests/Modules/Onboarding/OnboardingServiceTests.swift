import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class OnboardingServiceTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var modelContext: ModelContext!
    private var sut: OnboardingService!
    private var testUser: User!

    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create service
        sut = OnboardingService(modelContext: modelContext)

        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
    }

    override func tearDown() async throws {
        sut = nil
        testUser = nil
        modelContext = nil
        container = nil
        try super.tearDown()
    }

    // MARK: - Profile Saving Tests
    
    func test_saveProfile_givenValidProfile_shouldPersistSuccessfully() async throws {
        // Arrange
        let profileData = createValidProfileData()
        let profile = OnboardingProfile(
            personaPromptData: profileData,
            communicationPreferencesData: profileData,
            rawFullProfileData: profileData
        )

        // Act
        try await sut.saveProfile(profile)

        // Assert
        let profiles = try modelContext.fetch(FetchDescriptor<OnboardingProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.user?.id, testUser.id)
        XCTAssertEqual(testUser.onboardingProfile?.id, profile.id)
    }

    func test_saveProfile_givenNoUser_shouldThrowError() async throws {
        // Arrange
        try modelContext.delete(model: User.self)
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }

        let profileData = createValidProfileData()
        let profile = OnboardingProfile(
            personaPromptData: profileData,
            communicationPreferencesData: profileData,
            rawFullProfileData: profileData
        )

        // Act & Assert
        do {
            try await sut.saveProfile(profile)
            XCTFail("Expected OnboardingError.noUserFound")
        } catch OnboardingError.noUserFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_saveProfile_givenInvalidJSON_shouldThrowError() async {
        // Arrange
        let invalidData = Data("invalid json".utf8)
        let profile = OnboardingProfile(
            personaPromptData: invalidData,
            communicationPreferencesData: invalidData,
            rawFullProfileData: invalidData
        )

        // Act & Assert
        do {
            try await sut.saveProfile(profile)
            XCTFail("Expected OnboardingError.invalidProfileData")
        } catch OnboardingError.invalidProfileData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_saveProfile_givenMissingRequiredField_shouldThrowError() async throws {
        // Arrange
        let incompleteProfile = [
            "life_context": ["is_desk_job": true],
            "goal": ["family": "performance"]
            // Missing required fields: blend, engagement_preferences, etc.
        ]
        let data = try JSONSerialization.data(withJSONObject: incompleteProfile)
        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )

        // Act & Assert
        do {
            try await sut.saveProfile(profile)
            XCTFail("Expected OnboardingError.missingRequiredField or invalidProfileData")
        } catch OnboardingError.missingRequiredField(let field) {
            let requiredFields = ["blend", "engagement_preferences", "sleep_window", "motivational_style", "timezone"]
            XCTAssertTrue(requiredFields.contains(field))
        } catch OnboardingError.invalidProfileData {
            // This is also acceptable since the validation catches missing fields
            // and re-throws as invalidProfileData
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_saveProfile_givenMultipleUsers_shouldLinkToMostRecent() async throws {
        // Arrange
        let olderUser = User(email: "older@example.com", name: "Older User")
        olderUser.createdAt = Date().addingTimeInterval(-3_600) // 1 hour ago
        modelContext.insert(olderUser)
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save context: \(error)")
        }

        let profileData = createValidProfileData()
        let profile = OnboardingProfile(
            personaPromptData: profileData,
            communicationPreferencesData: profileData,
            rawFullProfileData: profileData
        )

        // Act
        try await sut.saveProfile(profile)

        // Assert - Should link to most recent user (testUser)
        let profiles = try modelContext.fetch(FetchDescriptor<OnboardingProfile>())
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.user?.id, testUser.id)
        XCTAssertNotEqual(profiles.first?.user?.id, olderUser.id)
    }

    // MARK: - Error Handling Tests
    
    func test_onboardingError_localizedDescriptions() {
        // Test error descriptions exist (they use NSLocalizedString)
        XCTAssertNotNil(OnboardingError.noUserFound.errorDescription)
        XCTAssertNotNil(OnboardingError.invalidProfileData.errorDescription)
        XCTAssertNotNil(OnboardingError.missingRequiredField("test").errorDescription)

        // Test that error descriptions are not empty
        XCTAssertFalse(OnboardingError.noUserFound.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(OnboardingError.invalidProfileData.errorDescription?.isEmpty ?? true)
        XCTAssertFalse(OnboardingError.missingRequiredField("blend").errorDescription?.isEmpty ?? true)
    }

    // MARK: - Helper Methods
    private func createValidProfileData() -> Data {
        let validProfile = [
            "life_context": [
                "is_desk_job": true,
                "is_physically_active_work": false,
                "travels_frequently": false,
                "has_children_or_family_care": false,
                "schedule_type": "predictable",
                "workout_window_preference": "morning"
            ],
            "goal": [
                "family": "performance",
                "raw_text": "Get stronger"
            ],
            "blend": [
                "authoritative_direct": 0.25,
                "encouraging_empathetic": 0.25,
                "analytical_insightful": 0.25,
                "playfully_provocative": 0.25
            ],
            "engagement_preferences": [
                "tracking_style": "guidance_on_demand",
                "check_in_frequency": "daily",
                "auto_recovery_suggestions": true
            ],
            "sleep_window": [
                "bed_time": "22:30",
                "wake_time": "06:30"
            ],
            "motivational_style": [
                "celebration_style": "enthusiastic_celebratory",
                "absence_response": "respect_space"
            ],
            "timezone": "UTC",
            "baseline_mode_enabled": true
        ] as [String: Any]

        do {
            return try JSONSerialization.data(withJSONObject: validProfile)
        } catch {
            fatalError("Failed to create test data: \(error)")
        }
    }
}

// MARK: - Validation Tests
@MainActor
final class OnboardingServiceValidationTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var modelContext: ModelContext!
    private var sut: OnboardingService!
    private var testUser: User!

    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create service
        sut = OnboardingService(modelContext: modelContext)

        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
    }

    override func tearDown() async throws {
        sut = nil
        testUser = nil
        modelContext = nil
        container = nil
        try super.tearDown()
    }

    func test_validateProfileStructure_givenValidProfile_shouldPass() async throws {
        // Arrange
        let profileData = createValidProfileData()
        let profile = OnboardingProfile(
            personaPromptData: profileData,
            communicationPreferencesData: profileData,
            rawFullProfileData: profileData
        )

        // Act & Assert - Should not throw
        try await sut.saveProfile(profile)
    }

    func test_validateProfileStructure_givenAllRequiredFields_shouldPass() async throws {
        // Arrange
        let completeProfile = [
            "life_context": [
                "is_desk_job": true,
                "is_physically_active_work": false,
                "travels_frequently": false,
                "has_children_or_family_care": true,
                "schedule_type": "predictable",
                "workout_window_preference": "morning"
            ],
            "goal": [
                "family": "performance",
                "raw_text": "Run a marathon"
            ],
            "blend": [
                "authoritative_direct": 0.3,
                "encouraging_empathetic": 0.4,
                "analytical_insightful": 0.2,
                "playfully_provocative": 0.1
            ],
            "engagement_preferences": [
                "tracking_style": "guidance_on_demand",
                "check_in_frequency": "daily",
                "auto_recovery_suggestions": true
            ],
            "sleep_window": [
                "bed_time": "23:00",
                "wake_time": "07:00"
            ],
            "motivational_style": [
                "celebration_style": "enthusiastic_celebratory",
                "absence_response": "respect_space"
            ],
            "timezone": "America/New_York",
            "baseline_mode_enabled": true
        ] as [String: Any]

        let data = try JSONSerialization.data(withJSONObject: completeProfile)
        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )

        // Act & Assert - Should not throw
        try await sut.saveProfile(profile)

        let profiles = try modelContext.fetch(FetchDescriptor<OnboardingProfile>())
        XCTAssertEqual(profiles.count, 1)
    }

    func test_saveProfile_givenEmptyData_shouldThrowError() async {
        // Arrange
        let emptyData = Data()
        let profile = OnboardingProfile(
            personaPromptData: emptyData,
            communicationPreferencesData: emptyData,
            rawFullProfileData: emptyData
        )

        // Act & Assert
        do {
            try await sut.saveProfile(profile)
            XCTFail("Expected OnboardingError.invalidProfileData")
        } catch OnboardingError.invalidProfileData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Helper Methods
    private func createValidProfileData() -> Data {
        let validProfile = [
            "life_context": [
                "is_desk_job": true,
                "is_physically_active_work": false,
                "travels_frequently": false,
                "has_children_or_family_care": false,
                "schedule_type": "predictable",
                "workout_window_preference": "morning"
            ],
            "goal": [
                "family": "performance",
                "raw_text": "Get stronger"
            ],
            "blend": [
                "authoritative_direct": 0.25,
                "encouraging_empathetic": 0.25,
                "analytical_insightful": 0.25,
                "playfully_provocative": 0.25
            ],
            "engagement_preferences": [
                "tracking_style": "guidance_on_demand",
                "check_in_frequency": "daily",
                "auto_recovery_suggestions": true
            ],
            "sleep_window": [
                "bed_time": "22:30",
                "wake_time": "06:30"
            ],
            "motivational_style": [
                "celebration_style": "enthusiastic_celebratory",
                "absence_response": "respect_space"
            ],
            "timezone": "UTC",
            "baseline_mode_enabled": true
        ] as [String: Any]

        do {
            return try JSONSerialization.data(withJSONObject: validProfile)
        } catch {
            fatalError("Failed to create test data: \(error)")
        }
    }
}

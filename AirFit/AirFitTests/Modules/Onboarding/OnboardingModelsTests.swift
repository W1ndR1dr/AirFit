import XCTest
@testable import AirFit

final class OnboardingModelsTests: XCTestCase {
    // MARK: - PersonaMode Tests
    
    func test_personaMode_allCasesHaveDescriptions() {
        // Arrange
        let modes: [PersonaMode] = [.supportiveCoach, .directTrainer, .analyticalAdvisor, .motivationalBuddy]
        
        // Act & Assert
        for mode in modes {
            XCTAssertFalse(mode.description.isEmpty, "PersonaMode \(mode) should have a description")
        }
    }
    
    func test_personaMode_allCasesHaveUniqueRawValues() {
        // Arrange
        let modes: [PersonaMode] = [.supportiveCoach, .directTrainer, .analyticalAdvisor, .motivationalBuddy]
        let rawValues = modes.map { $0.rawValue }
        
        // Assert
        XCTAssertEqual(rawValues.count, Set(rawValues).count, "All PersonaMode raw values should be unique")
    }
    
    // MARK: - UserProfileJsonBlob Tests
    
    func test_userProfileJsonBlob_encoding_shouldUseSnakeCaseKeys() throws {
        // Arrange
        let blob = UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(family: .healthWellbeing, rawText: "Get healthier"),
            personaMode: .supportiveCoach,
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: "America/Los_Angeles",
            baselineModeEnabled: true
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        // Act
        let data = try encoder.encode(blob)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Assert
        XCTAssertNotNil(json?["life_context"])
        XCTAssertNotNil(json?["goal"])
        XCTAssertNotNil(json?["persona_mode"])
        XCTAssertNotNil(json?["engagement_preferences"])
        XCTAssertNotNil(json?["sleep_window"])
        XCTAssertNotNil(json?["motivational_style"])
        XCTAssertNotNil(json?["timezone"])
        XCTAssertNotNil(json?["baseline_mode_enabled"])
    }
    
    func test_userProfileJsonBlob_decoding_handlesSnakeCaseKeys() throws {
        // Arrange
        let json: [String: Any] = [
            "life_context": [:],
            "goal": ["family": "healthWellbeing", "raw_text": "Get healthier"],
            "persona_mode": "supportiveCoach",
            "engagement_preferences": [:],
            "sleep_window": [:],
            "motivational_style": [:],
            "timezone": "UTC",
            "baseline_mode_enabled": false
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Act
        let blob = try decoder.decode(UserProfileJsonBlob.self, from: data)
        
        // Assert
        XCTAssertEqual(blob.personaMode, .supportiveCoach)
        XCTAssertEqual(blob.timezone, "UTC")
        XCTAssertEqual(blob.baselineModeEnabled, false)
    }
    
    // MARK: - OnboardingProfile Tests
    
    func test_onboardingProfile_initialization() {
        // Arrange
        let data = Data()
        
        // Act
        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )
        
        // Assert
        XCTAssertNotNil(profile.id)
        XCTAssertNotNil(profile.personaPromptData)
        XCTAssertNotNil(profile.communicationPreferencesData)
        XCTAssertNotNil(profile.rawFullProfileData)
        XCTAssertFalse(profile.isComplete)
        XCTAssertNil(profile.user)
    }
    
    // MARK: - LifeContext Tests
    
    func test_lifeContext_workoutWindow_allCasesExist() {
        // Arrange
        let windows: [LifeContext.WorkoutWindow] = [.earlyBird, .midDay, .nightOwl, .varies]
        
        // Assert
        XCTAssertEqual(windows.count, 4, "Should have 4 workout windows")
    }
    
    func test_lifeContext_scheduleType_allCasesExist() {
        // Arrange
        let types: [LifeContext.ScheduleType] = [.predictable, .unpredictableChaotic]
        
        // Assert
        XCTAssertEqual(types.count, 2, "Should have 2 schedule types")
    }
    
    // MARK: - Goal Tests
    
    func test_goal_family_allCasesHaveDescriptions() {
        // Arrange
        let families: [Goal.GoalFamily] = Goal.GoalFamily.allCases
        
        // Act & Assert
        for family in families {
            XCTAssertFalse(family.displayName.isEmpty, "Goal family \(family) should have a display name")
        }
    }
}
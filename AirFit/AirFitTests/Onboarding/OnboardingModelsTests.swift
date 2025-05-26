import XCTest
@testable import AirFit

final class OnboardingModelsTests: XCTestCase {
    func test_blend_isValid_whenSumEqualsOne_shouldReturnTrue() {
        // Arrange
        let blend = Blend(authoritativeDirect: 0.2, encouragingEmpathetic: 0.3, analyticalInsightful: 0.3, playfullyProvocative: 0.2)

        // Assert
        XCTAssertTrue(blend.isValid)
    }

    func test_blend_isValid_whenSumNotEqual_shouldReturnFalse() {
        // Arrange
        let blend = Blend(authoritativeDirect: 0.5, encouragingEmpathetic: 0.5, analyticalInsightful: 0.1, playfullyProvocative: 0.1)

        // Assert
        XCTAssertFalse(blend.isValid)
    }

    func test_blend_normalize_whenValuesDontSumToOne_shouldNormalize() {
        // Arrange
        var blend = Blend(authoritativeDirect: 0.5, encouragingEmpathetic: 0.2, analyticalInsightful: 0.2, playfullyProvocative: 0.1)

        // Act
        blend.normalize()

        // Assert
        let total = blend.authoritativeDirect + blend.encouragingEmpathetic + blend.analyticalInsightful + blend.playfullyProvocative
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
        XCTAssertTrue(blend.isValid)
    }

    func test_userProfileJsonBlobEncoding_shouldUseSnakeCaseKeys() throws {
        // Arrange
        let blob = UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(),
            blend: Blend(),
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
        XCTAssertNotNil(json?["blend"])
        XCTAssertNotNil(json?["engagement_preferences"])
        XCTAssertNotNil(json?["sleep_window"])
        XCTAssertNotNil(json?["motivational_style"])
        XCTAssertNotNil(json?["timezone"])
        XCTAssertNotNil(json?["baseline_mode_enabled"])
    }
}

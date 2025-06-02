import XCTest
@testable import AirFit

final class SettingsModelsTests: XCTestCase {
    
    // MARK: - MeasurementSystem Tests
    
    func test_measurementSystem_displayName_shouldReturnCorrectValues() {
        XCTAssertEqual(MeasurementSystem.imperial.displayName, "Imperial (US)")
        XCTAssertEqual(MeasurementSystem.metric.displayName, "Metric")
    }
    
    func test_measurementSystem_description_shouldReturnCorrectValues() {
        XCTAssertEqual(MeasurementSystem.imperial.description, "Pounds, feet, miles, Fahrenheit")
        XCTAssertEqual(MeasurementSystem.metric.description, "Kilograms, meters, kilometers, Celsius")
    }
    
    // MARK: - AppearanceMode Tests
    
    func test_appearanceMode_displayName_shouldReturnCorrectValues() {
        XCTAssertEqual(AppearanceMode.light.displayName, "Light")
        XCTAssertEqual(AppearanceMode.dark.displayName, "Dark")
        XCTAssertEqual(AppearanceMode.system.displayName, "System")
    }
    
    // MARK: - NotificationPreferences Tests
    
    func test_notificationPreferences_defaultValues_shouldBeTrue() {
        let prefs = NotificationPreferences()
        
        XCTAssertTrue(prefs.systemEnabled)
        XCTAssertTrue(prefs.workoutReminders)
        XCTAssertTrue(prefs.mealReminders)
        XCTAssertTrue(prefs.dailyCheckins)
        XCTAssertTrue(prefs.achievementAlerts)
        XCTAssertTrue(prefs.coachMessages)
    }
    
    // MARK: - QuietHours Tests
    
    func test_quietHours_defaultValues_shouldBeCorrect() {
        let quietHours = QuietHours()
        
        XCTAssertFalse(quietHours.enabled)
        
        // Check that default times are set (10 PM and 7 AM)
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: quietHours.startTime)
        let endHour = calendar.component(.hour, from: quietHours.endTime)
        
        XCTAssertEqual(startHour, 22) // 10 PM
        XCTAssertEqual(endHour, 7) // 7 AM
    }
    
    // MARK: - DataExport Tests
    
    func test_dataExport_initialization_shouldSetProperties() {
        let export = DataExport(
            date: Date(),
            size: 1024,
            format: .json
        )
        
        XCTAssertNotNil(export.id)
        XCTAssertEqual(export.size, 1024)
        XCTAssertEqual(export.format, .json)
    }
    
    // MARK: - PersonaEvolutionTracker Tests
    
    func test_personaEvolutionTracker_initialization_shouldSetDefaults() {
        let user = User(name: "Test")
        let tracker = PersonaEvolutionTracker(user: user)
        
        XCTAssertEqual(tracker.adaptationLevel, 0)
        XCTAssertTrue(tracker.recentAdaptations.isEmpty)
        XCTAssertNotNil(tracker.lastUpdateDate)
    }
    
    // MARK: - PreviewScenario Tests
    
    func test_previewScenario_randomScenario_shouldReturnValidScenario() {
        let scenario = PreviewScenario.randomScenario()
        
        let validScenarios: [PreviewScenario] = [
            .morningGreeting,
            .workoutMotivation,
            .nutritionGuidance,
            .recoveryCheck,
            .goalSetting
        ]
        
        XCTAssertTrue(validScenarios.contains(scenario))
    }
    
    // MARK: - SettingsError Tests
    
    func test_settingsError_errorDescription_shouldReturnCorrectMessages() {
        let errors: [(SettingsError, String)] = [
            (.missingAPIKey(.openAI), "Please add an API key for OpenAI"),
            (.invalidAPIKey, "Invalid API key format"),
            (.apiKeyTestFailed, "API key validation failed. Please check your key."),
            (.biometricsNotAvailable, "Biometric authentication is not available on this device"),
            (.exportFailed("Test reason"), "Export failed: Test reason"),
            (.personaNotConfigured, "Coach persona not configured. Please complete onboarding."),
            (.personaAdjustmentFailed("Test error"), "Failed to adjust persona: Test error")
        ]
        
        for (error, expectedMessage) in errors {
            XCTAssertEqual(error.errorDescription, expectedMessage)
        }
    }
    
    // MARK: - SettingsDestination Tests
    
    func test_settingsDestination_allCases_shouldBeHashable() {
        let destinations: [SettingsDestination] = [
            .aiPersona,
            .apiConfiguration,
            .notifications,
            .privacy,
            .appearance,
            .units,
            .dataManagement,
            .about,
            .debug
        ]
        
        // Test that all destinations can be used in a Set (proving Hashable conformance)
        let destinationSet = Set(destinations)
        XCTAssertEqual(destinationSet.count, destinations.count)
    }
}
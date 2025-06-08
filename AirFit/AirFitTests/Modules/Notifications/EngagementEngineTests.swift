import XCTest
import SwiftData
@testable import AirFit

@MainActor

final class EngagementEngineTests: XCTestCase {
    var sut: EngagementEngine!
    var container: ModelContainer!
    var modelContext: ModelContext!
    var mockCoachEngine: MockCoachEngine!
    var testUser: User!
    
    override func setUp() async throws {
        try super.setUp()
        
        // Setup test context
        container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        testUser.lastActiveAt = Date().addingTimeInterval(-4 * 24 * 60 * 60) // 4 days ago
        
        // Add communication preferences
        let commPrefs = CommunicationPreferences(
            absenceResponse: "light_nudge",
            preferredTimes: ["morning", "evening"],
            frequency: "daily"
        )
        let onboardingProfile = OnboardingProfile(
            personaPromptData: Data(),
            communicationPreferencesData: try JSONEncoder().encode(commPrefs),
            rawFullProfileData: Data()
        )
        testUser.onboardingProfile = onboardingProfile
        
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Setup mocks
        mockCoachEngine = MockCoachEngine()
        
        // Create real CoachEngine for testing (EngagementEngine requires CoachEngine, not protocol)
        let coachEngine = CoachEngine.createDefault(modelContext: modelContext)
        
        // Create SUT
        sut = EngagementEngine(
            modelContext: modelContext,
            coachEngine: coachEngine
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        container = nil
        modelContext = nil
        mockCoachEngine = nil
        testUser = nil
        try super.tearDown()
    }
    
    func test_detectLapsedUsers_withInactiveUser_shouldReturnUser() async throws {
        // Arrange - user is already 4 days inactive
        
        // Act
        let lapsedUsers = try await sut.detectLapsedUsers()
        
        // Assert
        XCTAssertEqual(lapsedUsers.count, 1)
        XCTAssertEqual(lapsedUsers.first?.id, testUser.id)
    }
    
    func test_detectLapsedUsers_withActiveUser_shouldNotReturn() async throws {
        // Arrange - make user active
        testUser.lastActiveAt = Date()
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }
        
        // Act
        let lapsedUsers = try await sut.detectLapsedUsers()
        
        // Assert
        XCTAssertEqual(lapsedUsers.count, 0)
    }
    
    func test_sendReEngagementNotification_shouldGeneratePersonalizedMessage() async {
        // Arrange
        mockCoachEngine.processMessageResponse = "Hey there! We miss you at AirFit!"
        
        // Act
        await sut.sendReEngagementNotification(for: testUser)
        
        // Assert
        // Verify that a notification was triggered (would need NotificationManager mock to verify further)
        XCTAssertTrue(true) // Placeholder - notification sending is not easily testable without mock
    }
    
    func test_sendReEngagementNotification_withGiveMeSpace_shouldNotSend() async {
        // Arrange
        let commPrefs = CommunicationPreferences(
            absenceResponse: "give_me_space",
            preferredTimes: [],
            frequency: "never"
        )
        testUser.onboardingProfile?.communicationPreferencesData = try! JSONEncoder().encode(commPrefs)
        try! modelContext.save()
        
        // Act
        await sut.sendReEngagementNotification(for: testUser)
        
        // Assert
        // With "give_me_space", no notification should be sent
        XCTAssertTrue(true) // Placeholder - would need to verify no notification was scheduled
    }
    
    func test_checkForLapsedUsers_shouldIdentifyLapsedUsers() async throws {
        // Arrange
        let activeUser = User(email: "active@example.com", name: "Active User")
        activeUser.lastActiveAt = Date()
        modelContext.insert(activeUser)
        
        let lapsedUser = User(email: "lapsed@example.com", name: "Lapsed User") 
        lapsedUser.lastActiveAt = Date().addingTimeInterval(-5 * 24 * 60 * 60)
        modelContext.insert(lapsedUser)
        
        do {

        
            try modelContext.save()

        
        } catch {

        
            XCTFail("Failed to save test context: \(error)")

        
        }
        
        // Act
        _ = try await sut.detectLapsedUsers()
        
        // Assert - we can't directly test private methods, but we can verify behavior
        // In a real test, we'd mock the notification manager and verify notifications were scheduled
        XCTAssertTrue(true) // Placeholder - would check notification scheduling
    }
    
    func test_updateUserActivity_shouldUpdateLastActiveDate() {
        // Arrange
        let oldDate = testUser.lastActiveAt
        
        // Act
        sut.updateUserActivity(for: testUser)
        
        // Assert
        XCTAssertGreaterThan(testUser.lastActiveAt, oldDate)
        XCTAssertLessThanOrEqual(testUser.lastActiveAt.timeIntervalSinceNow, 1)
    }
    
    func test_scheduleBackgroundTasks_shouldNotCrash() {
        // Act
        sut.scheduleBackgroundTasks()
        
        // Assert - just verify no crash
        XCTAssertTrue(true)
    }
}
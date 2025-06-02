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
        try await super.setUp()
        
        // Setup test context
        container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        
        // Create test user
        testUser = User(name: "Test User")
        testUser.lastActiveAt = Date().addingTimeInterval(-4 * 24 * 60 * 60) // 4 days ago
        
        // Add communication preferences
        let commPrefs = CommunicationPreferences(
            absenceResponse: "light_nudge",
            preferredTimes: ["morning", "evening"],
            frequency: "daily"
        )
        let onboardingProfile = OnboardingProfile()
        onboardingProfile.communicationPreferencesData = try JSONEncoder().encode(commPrefs)
        testUser.onboardingProfile = onboardingProfile
        
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Setup mocks
        mockCoachEngine = MockCoachEngine()
        
        // Create SUT
        sut = EngagementEngine(
            modelContext: modelContext,
            coachEngine: mockCoachEngine
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        container = nil
        modelContext = nil
        mockCoachEngine = nil
        testUser = nil
        try await super.tearDown()
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
        try modelContext.save()
        
        // Act
        let lapsedUsers = try await sut.detectLapsedUsers()
        
        // Assert
        XCTAssertEqual(lapsedUsers.count, 0)
    }
    
    func test_sendReEngagementNotification_shouldGeneratePersonalizedMessage() async {
        // Arrange
        mockCoachEngine.stubReEngagementMessage = "Hey there!|We miss you at AirFit!"
        
        // Act
        await sut.sendReEngagementNotification(for: testUser)
        
        // Assert
        XCTAssertTrue(mockCoachEngine.didCallGenerateReEngagementMessage)
        // Note: We can't easily verify re-engagement attempts increment without exposing internals
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
        XCTAssertFalse(mockCoachEngine.didCallGenerateReEngagementMessage)
    }
    
    func test_analyzeEngagementMetrics_shouldCalculateCorrectly() async throws {
        // Arrange
        let activeUser = User(name: "Active User")
        activeUser.lastActiveAt = Date()
        modelContext.insert(activeUser)
        
        let lapsedUser = User(name: "Lapsed User") 
        lapsedUser.lastActiveAt = Date().addingTimeInterval(-5 * 24 * 60 * 60)
        modelContext.insert(lapsedUser)
        
        try modelContext.save()
        
        // Act
        let metrics = try await sut.analyzeEngagementMetrics()
        
        // Assert
        XCTAssertEqual(metrics.totalUsers, 3) // test user + 2 new
        XCTAssertEqual(metrics.activeUsers, 1)
        XCTAssertEqual(metrics.lapsedUsers, 2)
        XCTAssertEqual(metrics.engagementRate, 1.0/3.0, accuracy: 0.01)
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

// MARK: - Mock CoachEngine
class MockCoachEngine: CoachEngine {
    var didCallGenerateReEngagementMessage = false
    var stubReEngagementMessage = "Default message"
    
    var didCallGenerateMorningGreeting = false
    var stubMorningGreeting = "Good morning!"
    
    var didCallGenerateWorkoutReminder = false
    var stubWorkoutReminder = ("Workout time!", "Let's get moving!")
    
    var didCallGenerateMealReminder = false
    var stubMealReminder = ("Meal time!", "Don't forget to eat!")
    
    override func generateReEngagementMessage(_ context: ReEngagementContext) async throws -> String {
        didCallGenerateReEngagementMessage = true
        return stubReEngagementMessage
    }
    
    override func generateMorningGreeting(for user: User) async throws -> String {
        didCallGenerateMorningGreeting = true
        return stubMorningGreeting
    }
    
    override func generateWorkoutReminder(workoutType: String, userName: String) async throws -> (title: String, body: String) {
        didCallGenerateWorkoutReminder = true
        return stubWorkoutReminder
    }
    
    override func generateMealReminder(mealType: MealType, userName: String) async throws -> (title: String, body: String) {
        didCallGenerateMealReminder = true
        return stubMealReminder
    }
}
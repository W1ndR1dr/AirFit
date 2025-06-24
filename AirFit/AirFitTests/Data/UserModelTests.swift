import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class UserModelTests: XCTestCase {
    var container: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        do {
            container = try ModelContainer.createTestContainer()
            modelContext = container.mainContext
        } catch {
            XCTFail("Failed to create test container: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        modelContext = nil
        super.tearDown()
    }

    func test_createUser_withDefaultValues_shouldInitializeCorrectly() throws {
        // Arrange & Act
        let user = User()
        modelContext.insert(user)
        try modelContext.save()

        // Assert
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.preferredUnits, "imperial")
        XCTAssertTrue(user.foodEntries.isEmpty)
        XCTAssertTrue(user.workouts.isEmpty)
        XCTAssertTrue(user.dailyLogs.isEmpty)
        XCTAssertEqual(user.daysActive, 0)
        XCTAssertFalse(user.isInactive)
    }

    func test_createUser_withCustomValues_shouldSetCorrectly() throws {
        // Arrange
        let user = User(
            email: "test@example.com",
            name: "Test User",
            preferredUnits: "metric"
        )

        // Act
        modelContext.insert(user)
        try modelContext.save()

        // Assert
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.preferredUnits, "metric")
        XCTAssertTrue(user.isMetric)
    }

    func test_userRelationships_whenDeleted_shouldCascadeDelete() throws {
        // Arrange
        let user = User(name: "Test User")
        modelContext.insert(user)

        let foodEntry = FoodEntry(user: user)
        modelContext.insert(foodEntry)

        let workout = Workout(name: "Test Workout", user: user)
        modelContext.insert(workout)

        try modelContext.save()

        // Verify setup
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<User>()), 1)
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<FoodEntry>()), 1)
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<Workout>()), 1)

        // Act
        modelContext.delete(user)
        try modelContext.save()

        // Assert - cascade delete should remove related entities
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<User>()), 0)
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<FoodEntry>()), 0)
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<Workout>()), 0)
    }

    func test_getTodaysLog_withMultipleLogs_shouldReturnToday() throws {
        // Arrange
        let user = User(name: "Test User")
        modelContext.insert(user)

        let todayLog = DailyLog(date: Date(), user: user)
        modelContext.insert(todayLog)

        let yesterdayLog = DailyLog(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            user: user
        )
        modelContext.insert(yesterdayLog)

        try modelContext.save()

        // Act
        let result = user.getTodaysLog()

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.date, Calendar.current.startOfDay(for: Date()))
    }

    func test_getRecentMeals_shouldReturnSortedMeals() throws {
        // Arrange
        let user = User(name: "Test User")
        modelContext.insert(user)

        // Create meals for different days
        let today = FoodEntry(loggedAt: Date(), mealType: .lunch, user: user)
        modelContext.insert(today)

        let yesterday = FoodEntry(
            loggedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            mealType: .dinner,
            user: user
        )
        modelContext.insert(yesterday)

        let oldMeal = FoodEntry(
            loggedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            mealType: .breakfast,
            user: user
        )
        modelContext.insert(oldMeal)

        try modelContext.save()

        // Act
        let recentMeals = user.getRecentMeals(days: 7)

        // Assert
        XCTAssertEqual(recentMeals.count, 2)
        XCTAssertEqual(recentMeals[0].id, today.id) // Most recent first
        XCTAssertEqual(recentMeals[1].id, yesterday.id)
    }
}

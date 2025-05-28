import XCTest
import SwiftData
@testable import AirFit

final class UserModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    @MainActor
    override func setUp() async throws {
        await MainActor.run {
            super.setUp()
        }
        container = try ModelContainer.createTestContainer()
        context = container.mainContext
    }

    @MainActor
    override func tearDown() async throws {
        container = nil
        context = nil
        await MainActor.run {
            super.tearDown()
        }
    }

    @MainActor
    func test_createUser_withDefaultValues_shouldInitializeCorrectly() throws {
        // Arrange & Act
        let user = User()
        context.insert(user)
        try context.save()

        // Assert
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.preferredUnits, "imperial")
        XCTAssertTrue(user.foodEntries.isEmpty)
        XCTAssertTrue(user.workouts.isEmpty)
        XCTAssertTrue(user.dailyLogs.isEmpty)
        XCTAssertEqual(user.daysActive, 0)
        XCTAssertFalse(user.isInactive)
    }

    @MainActor
    func test_createUser_withCustomValues_shouldSetCorrectly() throws {
        // Arrange
        let user = User(
            email: "test@example.com",
            name: "Test User",
            preferredUnits: "metric"
        )

        // Act
        context.insert(user)
        try context.save()

        // Assert
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.preferredUnits, "metric")
        XCTAssertTrue(user.isMetric)
    }

    @MainActor
    func test_userRelationships_whenDeleted_shouldCascadeDelete() throws {
        // Arrange
        let user = User(name: "Test User")
        context.insert(user)

        let foodEntry = FoodEntry(user: user)
        context.insert(foodEntry)

        let workout = Workout(name: "Test Workout", user: user)
        context.insert(workout)

        try context.save()

        // Verify setup
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<User>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<FoodEntry>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Workout>()), 1)

        // Act
        context.delete(user)
        try context.save()

        // Assert - cascade delete should remove related entities
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<User>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<FoodEntry>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Workout>()), 0)
    }

    @MainActor
    func test_getTodaysLog_withMultipleLogs_shouldReturnToday() throws {
        // Arrange
        let user = User(name: "Test User")
        context.insert(user)

        let todayLog = DailyLog(date: Date(), user: user)
        context.insert(todayLog)

        let yesterdayLog = DailyLog(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            user: user
        )
        context.insert(yesterdayLog)

        try context.save()

        // Act
        let result = user.getTodaysLog()

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.date, Calendar.current.startOfDay(for: Date()))
    }

    @MainActor
    func test_getRecentMeals_shouldReturnSortedMeals() throws {
        // Arrange
        let user = User(name: "Test User")
        context.insert(user)

        // Create meals for different days
        let today = FoodEntry(loggedAt: Date(), mealType: .lunch, user: user)
        context.insert(today)

        let yesterday = FoodEntry(
            loggedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            mealType: .dinner,
            user: user
        )
        context.insert(yesterday)

        let oldMeal = FoodEntry(
            loggedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            mealType: .breakfast,
            user: user
        )
        context.insert(oldMeal)

        try context.save()

        // Act
        let recentMeals = user.getRecentMeals(days: 7)

        // Assert
        XCTAssertEqual(recentMeals.count, 2)
        XCTAssertEqual(recentMeals[0].id, today.id) // Most recent first
        XCTAssertEqual(recentMeals[1].id, yesterday.id)
    }
}

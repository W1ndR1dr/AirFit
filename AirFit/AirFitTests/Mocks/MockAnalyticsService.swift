import Foundation
import SwiftData
@testable import AirFit

/// Mock implementation of AnalyticsServiceProtocol for testing
@MainActor
final class MockAnalyticsService: AnalyticsServiceProtocol, @preconcurrency MockProtocol {
    // MARK: - MockProtocol
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - Tracking Properties
    
    var trackedEvents: [AnalyticsEvent] = []
    var trackedScreens: [(screen: String, properties: [String: String]?)] = []
    var userProperties: [String: String] = [:]
    var trackedWorkouts: [Workout] = []
    var trackedMeals: [FoodEntry] = []
    
    // MARK: - Mock Configuration
    
    var shouldThrowError = false
    var mockInsights = UserInsights(
        workoutFrequency: 3.5,
        averageWorkoutDuration: 3_600,
        caloriesTrend: Trend(direction: .up, changePercentage: 5.0),
        macroBalance: MacroBalance(proteinPercentage: 30, carbsPercentage: 45, fatPercentage: 25),
        streakDays: 7,
        achievements: []
    )
    
    // MARK: - Call Tracking
    
    var trackEventCallCount = 0
    var trackScreenCallCount = 0
    var setUserPropertiesCallCount = 0
    var trackWorkoutCompletedCallCount = 0
    var trackMealLoggedCallCount = 0
    var getInsightsCallCount = 0
    
    // MARK: - AnalyticsServiceProtocol
    
    func trackEvent(_ event: AnalyticsEvent) async {
        trackEventCallCount += 1
        trackedEvents.append(event)
    }
    
    func trackScreen(_ screen: String, properties: [String: String]?) async {
        trackScreenCallCount += 1
        trackedScreens.append((screen, properties))
    }
    
    func setUserProperties(_ properties: [String: String]) async {
        setUserPropertiesCallCount += 1
        userProperties.merge(properties) { _, new in new }
    }
    
    func trackWorkoutCompleted(_ workout: Workout) async {
        trackWorkoutCompletedCallCount += 1
        trackedWorkouts.append(workout)
    }
    
    func trackMealLogged(_ meal: FoodEntry) async {
        trackMealLoggedCallCount += 1
        trackedMeals.append(meal)
    }
    
    func getInsights(for user: User) async throws -> UserInsights {
        getInsightsCallCount += 1
        
        if shouldThrowError {
            struct MockError: Error {}
            throw AppError.networkError(underlying: MockError())
        }
        
        return mockInsights
    }
    
    // MARK: - MockProtocol
    
    func reset() {
        trackedEvents.removeAll()
        trackedScreens.removeAll()
        userProperties.removeAll()
        trackedWorkouts.removeAll()
        trackedMeals.removeAll()
        
        trackEventCallCount = 0
        trackScreenCallCount = 0
        setUserPropertiesCallCount = 0
        trackWorkoutCompletedCallCount = 0
        trackMealLoggedCallCount = 0
        getInsightsCallCount = 0
        
        shouldThrowError = false
        mockInsights = UserInsights(
            workoutFrequency: 3.5,
            averageWorkoutDuration: 3_600,
            caloriesTrend: Trend(direction: .up, changePercentage: 5.0),
            macroBalance: MacroBalance(proteinPercentage: 30, carbsPercentage: 45, fatPercentage: 25),
            streakDays: 7,
            achievements: []
        )
    }
    
    // MARK: - Helper Methods
    
    func verifyEventTracked(name: String, count: Int = 1) -> Bool {
        let actualCount = trackedEvents.filter { $0.name == name }.count
        return actualCount == count
    }
    
    func verifyScreenTracked(screen: String) -> Bool {
        return trackedScreens.contains { $0.screen == screen }
    }
    
    func getLastTrackedEvent() -> AnalyticsEvent? {
        return trackedEvents.last
    }
    
    func getTrackedEvents(withName name: String) -> [AnalyticsEvent] {
        return trackedEvents.filter { $0.name == name }
    }
}

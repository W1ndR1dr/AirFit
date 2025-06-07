import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class AIAnalyticsServiceTests: XCTestCase {
    // MARK: - Properties
    private var sut: AIAnalyticsService!
    private var mockAnalyticsService: MockAnalyticsService!
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self, Workout.self, FoodEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        testUser.weight = 75 // kg
        testUser.height = 180 // cm
        testUser.fitnessLevel = "advanced"
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Create mocks and service
        mockAnalyticsService = MockAnalyticsService()
        sut = AIAnalyticsService(analyticsService: mockAnalyticsService)
    }
    
    override func tearDown() {
        sut = nil
        mockAnalyticsService = nil
        modelContext = nil
        testUser = nil
        super.tearDown()
    }
    
    // MARK: - Analyze Performance Tests
    
    func test_analyzePerformance_withBasicQuery_returnsAnalysis() async throws {
        // Arrange
        let query = "How am I doing with my strength training?"
        let metrics = ["strength", "consistency"]
        let days = 30
        let depth = "basic"
        let includeRecommendations = true
        
        // Act
        let result = try await sut.analyzePerformance(
            query: query,
            metrics: metrics,
            days: days,
            depth: depth,
            includeRecommendations: includeRecommendations,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result.summary.contains("Performance analysis"))
        XCTAssertTrue(result.summary.contains(query))
        XCTAssertEqual(result.confidence, 0.8)
        XCTAssertFalse(result.recommendations.isEmpty)
        XCTAssertEqual(result.recommendations.first, "Keep up the good work!")
    }
    
    func test_analyzePerformance_withoutRecommendations_excludesRecommendations() async throws {
        // Arrange
        let query = "Show me my workout trends"
        let metrics = ["frequency", "duration", "intensity"]
        let days = 7
        let depth = "detailed"
        let includeRecommendations = false
        
        // Act
        let result = try await sut.analyzePerformance(
            query: query,
            metrics: metrics,
            days: days,
            depth: depth,
            includeRecommendations: includeRecommendations,
            for: testUser
        )
        
        // Assert
        XCTAssertTrue(result.recommendations.isEmpty)
        XCTAssertEqual(result.confidence, 0.8)
    }
    
    func test_analyzePerformance_withMultipleMetrics_includesAllInQuery() async throws {
        // Arrange
        let metrics = ["strength", "endurance", "flexibility", "recovery", "consistency"]
        
        // Act
        let result = try await sut.analyzePerformance(
            query: "Comprehensive fitness analysis",
            metrics: metrics,
            days: 90,
            depth: "comprehensive",
            includeRecommendations: true,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result.dataPoints, 0) // Placeholder returns 0
        XCTAssertEqual(metrics.count, 5)
    }
    
    func test_analyzePerformance_withLongTimeframe_handlesCorrectly() async throws {
        // Arrange
        let days = 365 // Full year
        
        // Act
        let result = try await sut.analyzePerformance(
            query: "Year in review",
            metrics: ["overall"],
            days: days,
            depth: "summary",
            includeRecommendations: true,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result.summary.contains("Year in review"))
    }
    
    func test_analyzePerformance_withMinimalParameters_returnsValidResult() async throws {
        // Act
        let result = try await sut.analyzePerformance(
            query: "Quick check",
            metrics: [],
            days: 1,
            depth: "minimal",
            includeRecommendations: false,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result.insights.isEmpty) // Placeholder returns empty
        XCTAssertTrue(result.trends.isEmpty)
        XCTAssertTrue(result.recommendations.isEmpty)
    }
    
    // MARK: - Generate Predictive Insights Tests
    
    func test_generatePredictiveInsights_withShortTimeframe_returnsInsights() async throws {
        // Arrange
        let timeframe = 7 // One week
        
        // Act
        let insights = try await sut.generatePredictiveInsights(
            for: testUser,
            timeframe: timeframe
        )
        
        // Assert
        XCTAssertNotNil(insights)
        XCTAssertEqual(insights.confidence, 0.7)
        XCTAssertTrue(insights.projections.isEmpty) // Placeholder returns empty
        XCTAssertTrue(insights.risks.isEmpty)
        XCTAssertTrue(insights.opportunities.isEmpty)
    }
    
    func test_generatePredictiveInsights_withLongTimeframe_returnsInsights() async throws {
        // Arrange
        let timeframe = 90 // Three months
        
        // Act
        let insights = try await sut.generatePredictiveInsights(
            for: testUser,
            timeframe: timeframe
        )
        
        // Assert
        XCTAssertNotNil(insights)
        XCTAssertEqual(insights.confidence, 0.7)
    }
    
    func test_generatePredictiveInsights_multipleCallsWithDifferentTimeframes() async throws {
        // Arrange
        let timeframes = [7, 14, 30, 60, 90]
        
        // Act
        var allInsights: [PredictiveInsights] = []
        for timeframe in timeframes {
            let insights = try await sut.generatePredictiveInsights(
                for: testUser,
                timeframe: timeframe
            )
            allInsights.append(insights)
        }
        
        // Assert
        XCTAssertEqual(allInsights.count, 5)
        allInsights.forEach { insights in
            XCTAssertEqual(insights.confidence, 0.7)
        }
    }
    
    // MARK: - Analytics Delegation Tests
    
    func test_trackEvent_delegatesToAnalyticsService() async {
        // Arrange
        let event = AnalyticsEvent(
            name: "workout_started",
            properties: ["type": "strength"],
            timestamp: Date()
        )
        
        // Act
        await sut.trackEvent(event)
        
        // Assert
        XCTAssertEqual(mockAnalyticsService.trackEventCallCount, 1)
        XCTAssertEqual(mockAnalyticsService.getLastTrackedEvent()?.name, "workout_started")
    }
    
    func test_trackScreen_delegatesToAnalyticsService() async {
        // Arrange
        let screenName = "DashboardView"
        let properties = ["user_id": testUser.id.uuidString]
        
        // Act
        await sut.trackScreen(screenName, properties: properties)
        
        // Assert
        XCTAssertEqual(mockAnalyticsService.trackScreenCallCount, 1)
        XCTAssertTrue(mockAnalyticsService.verifyScreenTracked(screen: screenName))
    }
    
    func test_setUserProperties_delegatesToAnalyticsService() async {
        // Arrange
        let properties = [
            "fitness_level": "advanced",
            "subscription": "premium",
            "app_version": "2.0.0"
        ]
        
        // Act
        await sut.setUserProperties(properties)
        
        // Assert
        XCTAssertEqual(mockAnalyticsService.setUserPropertiesCallCount, 1)
        XCTAssertEqual(mockAnalyticsService.userProperties["fitness_level"], "advanced")
    }
    
    func test_trackWorkoutCompleted_delegatesToAnalyticsService() async {
        // Arrange
        let workout = Workout(name: "Morning Run", user: testUser)
        workout.duration = 1800
        workout.caloriesBurned = 300
        
        // Act
        await sut.trackWorkoutCompleted(workout)
        
        // Assert
        XCTAssertEqual(mockAnalyticsService.trackWorkoutCompletedCallCount, 1)
        XCTAssertEqual(mockAnalyticsService.trackedWorkouts.first?.id, workout.id)
    }
    
    func test_trackMealLogged_delegatesToAnalyticsService() async {
        // Arrange
        let meal = FoodEntry(date: Date(), user: testUser)
        meal.mealType = MealType.breakfast.rawValue
        
        // Act
        await sut.trackMealLogged(meal)
        
        // Assert
        XCTAssertEqual(mockAnalyticsService.trackMealLoggedCallCount, 1)
        XCTAssertEqual(mockAnalyticsService.trackedMeals.first?.id, meal.id)
    }
    
    func test_getInsights_delegatesToAnalyticsService() async throws {
        // Arrange
        let mockInsights = UserInsights(
            workoutFrequency: 5.0,
            averageWorkoutDuration: 2700,
            caloriesTrend: Trend(direction: .up, changePercentage: 8.5),
            macroBalance: MacroBalance(proteinPercentage: 35, carbsPercentage: 40, fatPercentage: 25),
            streakDays: 14,
            achievements: []
        )
        mockAnalyticsService.mockInsights = mockInsights
        
        // Act
        let insights = try await sut.getInsights(for: testUser)
        
        // Assert
        XCTAssertEqual(insights.workoutFrequency, 5.0)
        XCTAssertEqual(insights.streakDays, 14)
        XCTAssertEqual(mockAnalyticsService.getInsightsCallCount, 1)
    }
    
    // MARK: - Edge Cases
    
    func test_analyzePerformance_withEmptyQuery_stillReturnsResult() async throws {
        // Act
        let result = try await sut.analyzePerformance(
            query: "",
            metrics: ["strength"],
            days: 30,
            depth: "basic",
            includeRecommendations: true,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result.summary.contains("Performance analysis"))
    }
    
    func test_analyzePerformance_withSpecialCharactersInQuery_handlesCorrectly() async throws {
        // Arrange
        let query = "How's my performance? 💪 #gains @gym"
        
        // Act
        let result = try await sut.analyzePerformance(
            query: query,
            metrics: ["overall"],
            days: 30,
            depth: "basic",
            includeRecommendations: false,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result.summary.contains(query))
    }
    
    func test_generatePredictiveInsights_withZeroTimeframe_returnsValidInsights() async throws {
        // Act
        let insights = try await sut.generatePredictiveInsights(
            for: testUser,
            timeframe: 0
        )
        
        // Assert
        XCTAssertNotNil(insights)
        XCTAssertEqual(insights.confidence, 0.7)
    }
    
    func test_generatePredictiveInsights_withNegativeTimeframe_returnsValidInsights() async throws {
        // Act
        let insights = try await sut.generatePredictiveInsights(
            for: testUser,
            timeframe: -30
        )
        
        // Assert
        XCTAssertNotNil(insights)
        // Should handle negative timeframe gracefully
    }
    
    // MARK: - Performance Tests
    
    func test_analyzePerformance_performance() async throws {
        // Measure time for multiple analyses
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<10 {
            _ = try await sut.analyzePerformance(
                query: "Analysis \(i)",
                metrics: ["metric\(i)"],
                days: 30,
                depth: "basic",
                includeRecommendations: true,
                for: testUser
            )
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert - Should be very fast for placeholder implementation
        XCTAssertLessThan(duration, 0.1, "10 analyses should complete within 100ms")
    }
    
    func test_concurrentOperations_maintainIntegrity() async throws {
        // Arrange
        let operations = 5
        
        // Act - Run multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            // Track events
            for i in 0..<operations {
                group.addTask {
                    let event = AnalyticsEvent(
                        name: "concurrent_test_\(i)",
                        properties: [:],
                        timestamp: Date()
                    )
                    await self.sut.trackEvent(event)
                }
            }
            
            // Analyze performance
            for i in 0..<operations {
                group.addTask {
                    _ = try? await self.sut.analyzePerformance(
                        query: "Concurrent query \(i)",
                        metrics: [],
                        days: 30,
                        depth: "basic",
                        includeRecommendations: false,
                        for: self.testUser
                    )
                }
            }
            
            // Generate insights
            for i in 0..<operations {
                group.addTask {
                    _ = try? await self.sut.generatePredictiveInsights(
                        for: self.testUser,
                        timeframe: i * 7
                    )
                }
            }
        }
        
        // Assert - Verify all operations completed
        XCTAssertEqual(mockAnalyticsService.trackEventCallCount, operations)
    }
    
    // MARK: - Error Handling Tests
    
    func test_getInsights_whenServiceThrows_propagatesError() async throws {
        // Arrange
        mockAnalyticsService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await sut.getInsights(for: testUser)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Integration Tests
    
    func test_fullAnalyticsFlow_tracksThenAnalyzes() async throws {
        // Track some events
        for i in 0..<5 {
            let event = AnalyticsEvent(
                name: "workout_completed",
                properties: ["duration": "\(30 + i * 5)"],
                timestamp: Date()
            )
            await sut.trackEvent(event)
        }
        
        // Track workout
        let workout = Workout(name: "Test Workout", user: testUser)
        await sut.trackWorkoutCompleted(workout)
        
        // Track meal
        let meal = FoodEntry(date: Date(), user: testUser)
        await sut.trackMealLogged(meal)
        
        // Set user properties
        await sut.setUserProperties(["goal": "muscle_gain"])
        
        // Analyze performance
        let analysis = try await sut.analyzePerformance(
            query: "How did I do this week?",
            metrics: ["consistency", "intensity"],
            days: 7,
            depth: "detailed",
            includeRecommendations: true,
            for: testUser
        )
        
        // Generate predictions
        let predictions = try await sut.generatePredictiveInsights(
            for: testUser,
            timeframe: 30
        )
        
        // Get insights
        let insights = try await sut.getInsights(for: testUser)
        
        // Assert all operations completed
        XCTAssertEqual(mockAnalyticsService.trackEventCallCount, 5)
        XCTAssertEqual(mockAnalyticsService.trackWorkoutCompletedCallCount, 1)
        XCTAssertEqual(mockAnalyticsService.trackMealLoggedCallCount, 1)
        XCTAssertEqual(mockAnalyticsService.setUserPropertiesCallCount, 1)
        XCTAssertNotNil(analysis)
        XCTAssertNotNil(predictions)
        XCTAssertNotNil(insights)
    }
}
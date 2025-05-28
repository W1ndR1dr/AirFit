import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var container: ModelContainer!
    var modelContext: ModelContext!
    var mockHealthKitService: MockHealthKitService!
    var mockAICoachService: MockAICoachService!
    var mockNutritionService: MockNutritionService!

    override func setUp() async throws {
        container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext

        mockHealthKitService = MockHealthKitService()
        mockAICoachService = MockAICoachService()
        mockNutritionService = MockNutritionService()
    }

    override func tearDown() async throws {
        container = nil
        modelContext = nil
        mockHealthKitService = nil
        mockAICoachService = nil
        mockNutritionService = nil
    }

    private func createTestUser() -> User {
        let user = User(name: "Tester")
        modelContext.insert(user)
        try! modelContext.save()
        return user
    }

    private func createSUT(with user: User) -> DashboardViewModel {
        return DashboardViewModel(
            user: user,
            modelContext: modelContext,
            healthKitService: mockHealthKitService,
            aiCoachService: mockAICoachService,
            nutritionService: mockNutritionService
        )
    }

    // MARK: - Async Test Helper
    private func waitForLoadingToComplete(_ viewModel: DashboardViewModel, timeout: TimeInterval = 2.0) async throws {
        let startTime = Date()
        while viewModel.isLoading {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timeout waiting for loading to complete")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    // MARK: - Test Helper to Force Greeting Refresh
    private func forceGreetingRefresh(_ viewModel: DashboardViewModel) {
        #if DEBUG
        viewModel.resetGreetingState()
        #endif
    }

    func test_initialState_defaults() {
        let user = createTestUser()
        let sut = createSUT(with: user)
        
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(sut.morningGreeting, "Good morning!")
        XCTAssertNil(sut.greetingContext)
        XCTAssertNil(sut.currentEnergyLevel)
        XCTAssertTrue(sut.suggestedActions.isEmpty)
    }

    func test_loadDashboardData_loadsDashboardData() async throws {
        let user = createTestUser()
        let sut = createSUT(with: user)
        
        // Arrange mock values
        mockHealthKitService.mockContext = HealthContext(
            lastNightSleepDurationHours: 7,
            sleepQuality: 4,
            currentWeatherCondition: "Sunny",
            currentTemperatureCelsius: 22,
            yesterdayEnergyLevel: 3,
            currentHeartRate: 60,
            hrv: 50,
            steps: 1_000
        )
        mockHealthKitService.recoveryResult = RecoveryScore(score: 85, components: [])
        mockHealthKitService.performanceResult = PerformanceInsight(
            summary: "Great",
            trend: .up,
            keyMetric: "VO2Max",
            value: 50
        )
        var summary = NutritionSummary()
        summary.calories = 500
        mockNutritionService.mockSummary = summary
        mockAICoachService.mockGreeting = "Hi Tester"

        // Force greeting refresh for testing
        forceGreetingRefresh(sut)
        
        // Act - Call loadDashboardData directly for deterministic testing
        await sut.loadDashboardData()

        // Assert
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.morningGreeting, "Hi Tester")
        XCTAssertEqual(sut.nutritionSummary.calories, 500)
        XCTAssertEqual(sut.recoveryScore?.score, 85)
        XCTAssertEqual(sut.performanceInsight?.trend, .up)
        mockHealthKitService.verify("getCurrentContext", called: 1)
        mockAICoachService.verify("generateMorningGreeting", called: 1)
        mockNutritionService.verify("getTodaysSummary", called: 1)
    }

    func test_onAppear_triggersDataLoad() async throws {
        let user = createTestUser()
        let sut = createSUT(with: user)
        
        // Arrange mock values
        mockHealthKitService.mockContext = HealthContext(
            lastNightSleepDurationHours: 7,
            sleepQuality: 4,
            currentWeatherCondition: "Sunny",
            currentTemperatureCelsius: 22,
            yesterdayEnergyLevel: 3,
            currentHeartRate: 60,
            hrv: 50,
            steps: 1_000
        )
        var summary = NutritionSummary()
        summary.calories = 500
        mockNutritionService.mockSummary = summary
        mockAICoachService.mockGreeting = "Hi Tester"

        // Act
        sut.onAppear()
        
        // Wait for async loading to complete
        try await waitForLoadingToComplete(sut)

        // Assert
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.morningGreeting, "Hi Tester")
        XCTAssertEqual(sut.nutritionSummary.calories, 500)
    }

    func test_aiFailure_usesFallbackGreeting() async throws {
        let user = createTestUser()
        
        // Arrange failing AI service
        final class FailingAI: AICoachServiceProtocol {
            func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
                struct TestError: Error {}
                throw TestError()
            }
        }
        let sut = DashboardViewModel(
            user: user,
            modelContext: modelContext,
            healthKitService: mockHealthKitService,
            aiCoachService: FailingAI(),
            nutritionService: mockNutritionService
        )

        // Determine expected fallback
        let hour = Calendar.current.component(.hour, from: Date())
        let name = user.name ?? "there"
        let expected: String
        switch hour {
        case 5..<12:
            expected = "Good morning, \(name)! Ready to make today count?"
        case 12..<17:
            expected = "Good afternoon, \(name)! How's your day going?"
        case 17..<22:
            expected = "Good evening, \(name)! Time to wind down."
        default:
            expected = "Hello, \(name)! Still up?"
        }

        // Act - Call loadDashboardData directly for deterministic testing
        await sut.loadDashboardData()

        // Assert
        XCTAssertEqual(sut.morningGreeting, expected)
    }

    func test_logEnergyLevel_createsNewLog() async throws {
        let user = createTestUser()
        let sut = createSUT(with: user)
        
        // Act
        await sut.logEnergyLevel(4)

        // Assert
        let logs = try modelContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.subjectiveEnergyLevel, 4)
        XCTAssertEqual(sut.currentEnergyLevel, 4)
        XCTAssertFalse(sut.isLoggingEnergy)
    }

    func test_logEnergyLevel_updatesExistingLog() async throws {
        let user = createTestUser()
        let sut = createSUT(with: user)
        
        let existing = DailyLog(date: Date(), user: user)
        existing.subjectiveEnergyLevel = 2
        modelContext.insert(existing)
        try modelContext.save()

        await sut.logEnergyLevel(5)

        let logs = try modelContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.subjectiveEnergyLevel, 5)
        XCTAssertEqual(sut.currentEnergyLevel, 5)
    }

    func test_loadNutritionData_withProfile_fetchesTargets() async throws {
        let user = createTestUser()
        let sut = createSUT(with: user)
        
        // Arrange
        let blob = UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(),
            blend: Blend(),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle(),
            timezone: "UTC",
            baselineModeEnabled: true
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(blob)
        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )
        user.onboardingProfile = profile
        modelContext.insert(profile)
        try modelContext.save()

        let targets = NutritionTargets(
            calories: 2_500,
            protein: NutritionTargets.default.protein,
            carbs: NutritionTargets.default.carbs,
            fat: NutritionTargets.default.fat,
            fiber: NutritionTargets.default.fiber,
            water: NutritionTargets.default.water
        )
        mockNutritionService.mockTargets = targets

        // Force greeting refresh for testing
        forceGreetingRefresh(sut)
        
        // Act - Call loadDashboardData directly for deterministic testing
        await sut.loadDashboardData()

        // Assert
        XCTAssertEqual(sut.nutritionTargets.calories, 2_500)
        mockNutritionService.verify("getTargets", called: 1)
    }

    func test_loadHealthInsights_errorDoesNotCrash() async throws {
        let user = createTestUser()
        
        final class ErrorHealthService: HealthKitServiceProtocol {
            func getCurrentContext() async throws -> HealthContext {
                HealthContext(
                    lastNightSleepDurationHours: nil,
                    sleepQuality: nil,
                    currentWeatherCondition: nil,
                    currentTemperatureCelsius: nil,
                    yesterdayEnergyLevel: nil,
                    currentHeartRate: nil,
                    hrv: nil,
                    steps: nil
                )
            }
            struct TestError: Error {}
            func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
                throw TestError()
            }
            func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
                throw TestError()
            }
        }
        let sut = DashboardViewModel(
            user: user,
            modelContext: modelContext,
            healthKitService: ErrorHealthService(),
            aiCoachService: mockAICoachService,
            nutritionService: mockNutritionService
        )

        // Act - Call loadDashboardData directly for deterministic testing
        await sut.loadDashboardData()

        // Assert - Should not crash and should handle errors gracefully
        XCTAssertNil(sut.recoveryScore)
        XCTAssertNil(sut.performanceInsight)
        XCTAssertFalse(sut.isLoading)
    }
}

import XCTest
import SwiftData
@testable import AirFit

@MainActor

final class DashboardViewModelTests: XCTestCase {
    var diContainer: DIContainer!
    var factory: DIViewModelFactory!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        diContainer = try await DITestHelper.createTestContainer()
        factory = DIViewModelFactory(container: diContainer)
        modelContainer = try await diContainer.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
    }

    override func tearDown() async throws {
        diContainer = nil
        factory = nil
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }

    private func createTestUser() -> User {
        let user = User(name: "Tester")
        modelContext.insert(user)
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save test user: \(error)")
        }
        return user
    }

    private func createSUT(with user: User) async throws -> DashboardViewModel {
        return try await factory.makeDashboardViewModel(user: user)
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

    @MainActor

    func test_initialState_defaults() async throws {
        let user = createTestUser()
        let sut = try await createSUT(with: user)

        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(sut.morningGreeting, "Good morning!")
        XCTAssertNil(sut.greetingContext)
        XCTAssertNil(sut.currentEnergyLevel)
        XCTAssertTrue(sut.suggestedActions.isEmpty)
    }

    @MainActor

    func test_loadDashboardData_loadsDashboardData() async throws {
        let user = createTestUser()
        let sut = try await createSUT(with: user)
        
        // Get mocks from container
        let mockHealthKitService = try await diContainer.resolve(HealthKitService.self) as! MockHealthKitService
        let mockNutritionService = try await diContainer.resolve(DashboardNutritionService.self) as! MockDashboardNutritionService

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
        mockHealthKitService.recoveryResult = RecoveryScore(score: 85, status: .good, factors: ["Good sleep", "Low stress"])
        mockHealthKitService.performanceResult = PerformanceInsight(
            trend: .improving,
            metric: "VO2Max",
            value: "50",
            insight: "Great performance"
        )
        let summary = NutritionSummary(calories: 500)
        mockNutritionService.mockSummary = summary
        let mockAICoachService = try await diContainer.resolve(AICoachServiceProtocol.self) as! MockAICoachService
        mockAICoachService.mockGreeting = "Hi Tester"

        // Force greeting refresh for testing
        forceGreetingRefresh(sut)

        // Act - Call loadDashboardData directly for deterministic testing
        await sut.loadDashboardData()
        
        // Carmack Fix: Test the outcome, not the implementation
        // If the data is loaded correctly, the services were called
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
        XCTAssertEqual(sut.morningGreeting, "Hi Tester", "Greeting should be set from mock")
        XCTAssertEqual(sut.nutritionSummary.calories, 500, "Nutrition data should be loaded")
        XCTAssertEqual(sut.recoveryScore?.score, 85, "Recovery score should be loaded")
        XCTAssertEqual(sut.performanceInsight?.trend, .improving, "Performance insight should be loaded")
        
        // The fact that these values are set proves the services were called
        // This is more reliable than mock verification in async contexts
    }

    @MainActor

    func test_onAppear_triggersDataLoad() async throws {
        let user = createTestUser()
        let sut = try await createSUT(with: user)
        
        // Get mocks from container
        let mockHealthKitService = try await diContainer.resolve(HealthKitService.self) as! MockHealthKitService
        let mockNutritionService = try await diContainer.resolve(DashboardNutritionService.self) as! MockDashboardNutritionService
        let mockAICoachService = try await diContainer.resolve(AICoachServiceProtocol.self) as! MockAICoachService

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
        let summary = NutritionSummary(calories: 500)
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

    @MainActor

    func test_aiFailure_usesFallbackGreeting() async throws {
        let user = createTestUser()
        
        // Get mocks from container
        let mockHealthKitService = try await diContainer.resolve(HealthKitService.self) as! MockHealthKitService
        let mockNutritionService = try await diContainer.resolve(DashboardNutritionService.self) as! MockDashboardNutritionService

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

    @MainActor

    func test_logEnergyLevel_createsNewLog() async throws {
        let user = createTestUser()
        let sut = try await createSUT(with: user)

        // Act
        await sut.logEnergyLevel(4)

        // Assert
        let logs = try modelContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.subjectiveEnergyLevel, 4)
        XCTAssertEqual(sut.currentEnergyLevel, 4)
        XCTAssertFalse(sut.isLoggingEnergy)
    }

    @MainActor

    func test_logEnergyLevel_updatesExistingLog() async throws {
        let user = createTestUser()
        let sut = try await createSUT(with: user)

        let existing = DailyLog(date: Date(), user: user)
        existing.subjectiveEnergyLevel = 2
        modelContext.insert(existing)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }

        await sut.logEnergyLevel(5)

        let logs = try modelContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.subjectiveEnergyLevel, 5)
        XCTAssertEqual(sut.currentEnergyLevel, 5)
    }

    @MainActor

    func test_loadNutritionData_withProfile_fetchesTargets() async throws {
        let user = createTestUser()
        let sut = try await createSUT(with: user)

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
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }

        let mockNutritionService = try await diContainer.resolve(DashboardNutritionService.self) as! MockDashboardNutritionService
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

        // Carmack Fix: Test the outcome, not the implementation
        // If the targets are loaded correctly, getTargets was called
        XCTAssertEqual(sut.nutritionTargets.calories, 2_500, "Nutrition targets should be loaded from profile")
        XCTAssertFalse(sut.isLoading, "Loading should be complete")
        
        // The fact that custom targets are set proves getTargets was called
        // This is more reliable than mock verification in async contexts
    }

    @MainActor

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
        let mockAICoachService = try await diContainer.resolve(AICoachServiceProtocol.self) as! MockAICoachService
        let mockNutritionService = try await diContainer.resolve(DashboardNutritionService.self) as! MockDashboardNutritionService
        
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

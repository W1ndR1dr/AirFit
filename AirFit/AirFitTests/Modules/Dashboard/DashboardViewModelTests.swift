import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var sut: DashboardViewModel!
    var mockHealthKitService: MockHealthKitService!
    var mockAICoachService: MockAICoachService!
    var mockNutritionService: MockNutritionService!
    var modelContext: ModelContext!
    var testUser: User!

    override func setUp() async throws {
        try await super.setUp()
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        testUser = User(name: "Tester")
        modelContext.insert(testUser)
        try modelContext.save()

        mockHealthKitService = MockHealthKitService()
        mockAICoachService = MockAICoachService()
        mockNutritionService = MockNutritionService()

        sut = DashboardViewModel(
            user: testUser,
            modelContext: modelContext,
            healthKitService: mockHealthKitService,
            aiCoachService: mockAICoachService,
            nutritionService: mockNutritionService
        )
    }

    func test_initialState_defaults() {
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(sut.morningGreeting, "Good morning!")
        XCTAssertNil(sut.greetingContext)
        XCTAssertNil(sut.currentEnergyLevel)
        XCTAssertTrue(sut.suggestedActions.isEmpty)
    }

    func test_onAppear_loadsDashboardData() async {
        // Arrange mock values
        mockHealthKitService.mockContext = HealthContext(
            lastNightSleepDurationHours: 7,
            sleepQuality: 4,
            currentWeatherCondition: "Sunny",
            currentTemperatureCelsius: 22,
            yesterdayEnergyLevel: 3,
            currentHeartRate: 60,
            hrv: 50,
            steps: 1000
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

        // Act
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000) // allow tasks

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

    func test_onAppear_aiFailure_usesFallbackGreeting() async {
        // Arrange failing AI service
        final class FailingAI: AICoachServiceProtocol {
            func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
                struct TestError: Error {}
                throw TestError()
            }
        }
        sut = DashboardViewModel(
            user: testUser,
            modelContext: modelContext,
            healthKitService: mockHealthKitService,
            aiCoachService: FailingAI(),
            nutritionService: mockNutritionService
        )

        // Determine expected fallback
        let hour = Calendar.current.component(.hour, from: Date())
        let name = testUser.name ?? "there"
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

        // Act
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.morningGreeting, expected)
    }

    func test_logEnergyLevel_createsNewLog() async throws {
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
        let existing = DailyLog(date: Date(), user: testUser)
        existing.subjectiveEnergyLevel = 2
        modelContext.insert(existing)
        try modelContext.save()

        await sut.logEnergyLevel(5)

        let logs = try modelContext.fetch(FetchDescriptor<DailyLog>())
        XCTAssertEqual(logs.count, 1)
        XCTAssertEqual(logs.first?.subjectiveEnergyLevel, 5)
        XCTAssertEqual(sut.currentEnergyLevel, 5)
    }

    func test_loadNutritionData_withProfile_fetchesTargets() async {
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
        let data = try! encoder.encode(blob)
        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )
        testUser.onboardingProfile = profile
        modelContext.insert(profile)
        try modelContext.save()

        var targets = NutritionTargets.default
        targets.calories = 2500
        mockNutritionService.mockTargets = targets

        // Act
        sut.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.nutritionTargets.calories, 2500)
        mockNutritionService.verify("getTargets", called: 1)
    }

    func test_loadHealthInsights_errorDoesNotCrash() async {
        final class ErrorHealthService: HealthKitServiceProtocol {
            func getCurrentContext() async throws -> HealthContext { HealthContext(lastNightSleepDurationHours: nil, sleepQuality: nil, currentWeatherCondition: nil, currentTemperatureCelsius: nil, yesterdayEnergyLevel: nil, currentHeartRate: nil, hrv: nil, steps: nil) }
            struct TestError: Error {}
            func calculateRecoveryScore(for user: User) async throws -> RecoveryScore { throw TestError() }
            func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight { throw TestError() }
        }
        sut = DashboardViewModel(
            user: testUser,
            modelContext: modelContext,
            healthKitService: ErrorHealthService(),
            aiCoachService: mockAICoachService,
            nutritionService: mockNutritionService
        )

        sut.onAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(sut.recoveryScore)
        XCTAssertNil(sut.performanceInsight)
    }
}

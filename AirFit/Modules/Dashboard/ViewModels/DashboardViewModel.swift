import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    // MARK: - State Properties
    private(set) var isLoading = true
    private(set) var error: Error?

    // Morning Greeting
    private(set) var morningGreeting = "Good morning!"
    private(set) var greetingContext: GreetingContext?

    // Energy Logging
    private(set) var currentEnergyLevel: Int?
    private(set) var isLoggingEnergy = false

    // Nutrition Data
    private(set) var nutritionSummary = NutritionSummary()
    private(set) var nutritionTargets = NutritionTargets.default

    // Health Insights
    private(set) var recoveryScore: RecoveryScore?
    private(set) var performanceInsight: PerformanceInsight?

    // Quick Actions
    private(set) var suggestedActions: [QuickAction] = []

    // MARK: - Dependencies
    private let user: User
    private let modelContext: ModelContext
    private let healthKitService: HealthKitServiceProtocol
    private let aiCoachService: AICoachServiceProtocol
    private let nutritionService: NutritionServiceProtocol

    // MARK: - Private State
    private var refreshTask: Task<Void, Never>?
    private var lastGreetingDate: Date?

    // MARK: - Initialization
    init(
        user: User,
        modelContext: ModelContext,
        healthKitService: HealthKitServiceProtocol,
        aiCoachService: AICoachServiceProtocol,
        nutritionService: NutritionServiceProtocol
    ) {
        self.user = user
        self.modelContext = modelContext
        self.healthKitService = healthKitService
        self.aiCoachService = aiCoachService
        self.nutritionService = nutritionService
    }

    // MARK: - Public Methods
    func onAppear() {
        refreshDashboard()
    }

    func onDisappear() {
        refreshTask?.cancel()
    }

    func refreshDashboard() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.loadDashboardData()
        }
    }

    func logEnergyLevel(_ level: Int) async {
        guard !isLoggingEnergy else { return }

        isLoggingEnergy = true
        defer { isLoggingEnergy = false }

        do {
            // Get or create today's log
            let today = Calendar.current.startOfDay(for: Date())
            var descriptor = FetchDescriptor<DailyLog>()
            descriptor.predicate = #Predicate { log in
                log.user == user && log.date == today
            }

            let logs = try modelContext.fetch(descriptor)
            let dailyLog: DailyLog

            if let existingLog = logs.first {
                dailyLog = existingLog
            } else {
                dailyLog = DailyLog(date: today, user: user)
                modelContext.insert(dailyLog)
            }

            // Update energy level
            dailyLog.subjectiveEnergyLevel = level
            dailyLog.checkedIn = true
            try modelContext.save()

            // Update local state
            currentEnergyLevel = level

            // Haptic feedback
            await HapticManager.shared.impact(.light)

            // Log analytics
            AppLogger.info("Energy level logged: \(level)", category: .data)

        } catch {
            self.error = error
            AppLogger.error("Failed to log energy", error: error, category: .data)
        }
    }

    // MARK: - Private Methods
    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadMorningGreeting() }
            group.addTask { await self.loadEnergyLevel() }
            group.addTask { await self.loadNutritionData() }
            group.addTask { await self.loadHealthInsights() }
            group.addTask { await self.loadQuickActions() }
        }
    }

    private func loadMorningGreeting() async {
        let calendar = Calendar.current
        let shouldRefresh = lastGreetingDate.map { date in
            !calendar.isDateInToday(date)
        } ?? true

        guard shouldRefresh else { return }

        do {
            let healthContext = try await healthKitService.getCurrentContext()
            let context = GreetingContext(
                userName: user.name ?? "there",
                sleepHours: healthContext.lastNightSleepDurationHours,
                sleepQuality: healthContext.sleepQuality,
                weather: healthContext.currentWeatherCondition,
                temperature: healthContext.currentTemperatureCelsius,
                dayOfWeek: Date().formatted(.dateTime.weekday(.wide)),
                energyYesterday: healthContext.yesterdayEnergyLevel
            )

            let greeting = try await aiCoachService.generateMorningGreeting(
                for: user,
                context: context
            )

            self.morningGreeting = greeting
            self.greetingContext = context
            self.lastGreetingDate = Date()

        } catch {
            self.morningGreeting = generateFallbackGreeting()
            AppLogger.error("Failed to generate AI greeting", error: error, category: .ai)
        }
    }

    private func loadEnergyLevel() async {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            var descriptor = FetchDescriptor<DailyLog>()
            descriptor.predicate = #Predicate { log in
                log.user == user && log.date == today
            }

            let logs = try modelContext.fetch(descriptor)
            currentEnergyLevel = logs.first?.subjectiveEnergyLevel

        } catch {
            AppLogger.error("Failed to load energy level", error: error, category: .data)
        }
    }

    private func loadNutritionData() async {
        do {
            let summary = try await nutritionService.getTodaysSummary(for: user)
            self.nutritionSummary = summary

            if let profile = user.onboardingProfile,
               let targets = try? await nutritionService.getTargets(from: profile) {
                self.nutritionTargets = targets
            }

        } catch {
            AppLogger.error("Failed to load nutrition data", error: error, category: .data)
        }
    }

    private func loadHealthInsights() async {
        do {
            let recovery = try await healthKitService.calculateRecoveryScore(for: user)
            self.recoveryScore = recovery

            let performance = try await healthKitService.getPerformanceInsight(
                for: user,
                days: 7
            )
            self.performanceInsight = performance

        } catch {
            AppLogger.error("Failed to load health insights", error: error, category: .health)
        }
    }

    private func loadQuickActions() async {
        var actions: [QuickAction] = []

        let hour = Calendar.current.component(.hour, from: Date())
        if (11...13).contains(hour) && nutritionSummary.meals[.lunch] == nil {
            actions.append(.logMeal(type: .lunch))
        }

        if !hasWorkoutToday() {
            actions.append(.startWorkout)
        }

        if nutritionSummary.waterLiters < 2.0 {
            actions.append(.logWater)
        }

        self.suggestedActions = actions
    }

    private func generateFallbackGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = user.name ?? "there"

        switch hour {
        case 5..<12:
            return "Good morning, \(name)! Ready to make today count?"
        case 12..<17:
            return "Good afternoon, \(name)! How's your day going?"
        case 17..<22:
            return "Good evening, \(name)! Time to wind down."
        default:
            return "Hello, \(name)! Still up?"
        }
    }

    private func hasWorkoutToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return user.workouts.contains { workout in
            if let completed = workout.completedDate {
                return Calendar.current.isDate(completed, inSameDayAs: today)
            }
            return false
        }
    }
}

// MARK: - Supporting Types
struct NutritionSummary: Equatable, Sendable {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var waterLiters: Double = 0
    var meals: [MealType: FoodEntry] = [:]
}

struct NutritionTargets: Equatable, Sendable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let water: Double

    static let `default` = NutritionTargets(
        calories: 2000,
        protein: 150,
        carbs: 250,
        fat: 70,
        fiber: 30,
        water: 2.5
    )
}

struct GreetingContext: Sendable {
    let userName: String
    let sleepHours: Double?
    let sleepQuality: Int?
    let weather: String?
    let temperature: Double?
    let dayOfWeek: String
    let energyYesterday: Int?
}

struct RecoveryScore: Equatable, Sendable {
    let score: Int
    let components: [Component]

    struct Component: Sendable {
        let name: String
        let value: Double
        let weight: Double
    }

    var trend: Trend {
        .steady
    }

    enum Trend {
        case improving, steady, declining
    }
}

struct PerformanceInsight: Equatable, Sendable {
    let summary: String
    let trend: Trend
    let keyMetric: String
    let value: Double

    enum Trend {
        case up, steady, down
    }
}

enum QuickAction: Identifiable, Sendable {
    case logMeal(type: MealType)
    case startWorkout
    case logWater
    case checkIn

    var id: String {
        switch self {
        case .logMeal(let type): return "logMeal_\(type.rawValue)"
        case .startWorkout: return "startWorkout"
        case .logWater: return "logWater"
        case .checkIn: return "checkIn"
        }
    }

    var title: String {
        switch self {
        case .logMeal(let type): return "Log \(type.displayName)"
        case .startWorkout: return "Start Workout"
        case .logWater: return "Log Water"
        case .checkIn: return "Daily Check-in"
        }
    }

    var systemImage: String {
        switch self {
        case .logMeal: return "fork.knife"
        case .startWorkout: return "figure.run"
        case .logWater: return "drop.fill"
        case .checkIn: return "checkmark.circle"
        }
    }
}


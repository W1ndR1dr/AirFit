import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class DashboardViewModel: ErrorHandling {
    // MARK: - State Properties
    private(set) var isLoading = true
    var error: AppError?
    var isShowingError = false

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
    private let nutritionService: DashboardNutritionServiceProtocol

    // MARK: - Private State
    private var refreshTask: Task<Void, Never>?
    private var lastGreetingDate: Date?
    #if DEBUG
    private var forceGreetingRefresh = false
    #endif

    // MARK: - Initialization
    init(
        user: User,
        modelContext: ModelContext,
        healthKitService: HealthKitServiceProtocol,
        aiCoachService: AICoachServiceProtocol,
        nutritionService: DashboardNutritionServiceProtocol
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

    func loadDashboardData() async {
        await _loadDashboardData()
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
                log.date == today
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
            HapticService.play(.dataUpdated)
            // Log analytics
            AppLogger.info("Energy level logged: \(level)", category: .data)

        } catch {
            handleError(error)
        }
    }

    // MARK: - Test Support
    #if DEBUG
    func resetGreetingState() {
        forceGreetingRefresh = true
    }
    #endif

    // MARK: - Private Methods
    private func _loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        // Execute loading operations sequentially to avoid race conditions
        await loadMorningGreeting()
        await loadEnergyLevel()
        await loadNutritionData()
        await loadHealthInsights()
        await loadQuickActions(for: Date())
    }

    private func loadMorningGreeting() async {
        #if DEBUG
        // Always execute during testing - no guard
        #else
        // Always refresh if no previous greeting date, or if it's a new day
        let shouldRefresh = lastGreetingDate.map { date in
            !Calendar.current.isDateInToday(date)
        } ?? true

        guard shouldRefresh else { return }
        #endif

        do {
            let healthContext = try await healthKitService.getCurrentContext()
            let context = GreetingContext(
                userName: user.name ?? "there",
                sleepHours: healthContext.lastNightSleepDurationHours,
                sleepQuality: healthContext.sleepQuality.map { String($0) },
                weather: healthContext.currentWeatherCondition,
                temperature: healthContext.currentTemperatureCelsius,
                energyYesterday: healthContext.yesterdayEnergyLevel.map { String($0) },
                dayOfWeek: Date().formatted(.dateTime.weekday(.wide))
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
                log.date == today
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

            // Always try to get targets if profile exists
            if let profile = user.onboardingProfile {
                do {
                    let targets = try await nutritionService.getTargets(from: profile)
                    self.nutritionTargets = targets
                } catch {
                    AppLogger.error("Failed to load nutrition targets", error: error, category: .data)
                    // Keep default targets on error
                }
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

    func loadQuickActions(for date: Date = Date()) async {
        var actions: [QuickAction] = []

        let hour = Calendar.current.component(.hour, from: date)
        // Add lunch logging if it's lunch time
        if (11...13).contains(hour) {
            actions.append(QuickAction(
                title: "Log Lunch",
                subtitle: "Track your midday meal",
                systemImage: "sun.max.fill",
                color: "orange",
                action: .logMeal(type: .lunch)
            ))
        }

        if !hasWorkoutToday() {
            actions.append(QuickAction(
                title: "Start Workout",
                subtitle: "Begin your training session",
                systemImage: "figure.strengthtraining.traditional",
                color: "blue",
                action: .startWorkout
            ))
        }

        if nutritionSummary.waterLiters < 2.0 {
            actions.append(QuickAction(
                title: "Log Water",
                subtitle: "Track your hydration",
                systemImage: "drop.fill",
                color: "cyan",
                action: .logWater
            ))
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

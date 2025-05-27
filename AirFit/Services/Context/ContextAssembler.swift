import Foundation
import SwiftData

/// Aggregates health and environmental data into `HealthContextSnapshot` instances.
@MainActor
final class ContextAssembler {
    private let healthKitManager: HealthKitManaging
    // Future: private let weatherService: WeatherServiceProtocol

    init(healthKitManager: HealthKitManaging = HealthKitManager.shared) {
        self.healthKitManager = healthKitManager
    }

    /// Creates a `HealthContextSnapshot` using data from HealthKit and SwiftData models.
    /// - Parameter modelContext: The `ModelContext` used to fetch app data.
    func assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot {
        async let activityMetrics = fetchActivityMetrics()
        async let heartMetrics = fetchHeartHealthMetrics()
        async let bodyMetrics = fetchBodyMetrics()
        async let sleepSession = fetchSleepSession()

        // Subjective data does not need to block concurrent HealthKit fetches
        async let subjective = fetchSubjectiveData(using: modelContext)

        // Mock data until services are implemented
        let environment = createMockEnvironmentContext()
        let appContext = await createMockAppContext(using: modelContext)

        // Await all HealthKit calls
        let (activity, heartHealth, body, sleep, subjectiveData) = await (
            activityMetrics,
            heartMetrics,
            bodyMetrics,
            sleepSession,
            subjective
        )

        let trends = calculateTrends(
            activity: activity,
            body: body,
            sleep: sleep,
            context: modelContext
        )

        return HealthContextSnapshot(
            subjectiveData: subjectiveData,
            environment: environment,
            activity: activity ?? ActivityMetrics(),
            sleep: SleepAnalysis(lastNight: sleep),
            heartHealth: heartHealth ?? HeartHealthMetrics(),
            body: body ?? BodyMetrics(),
            appContext: appContext,
            trends: trends
        )
    }

    // MARK: - Private Helpers
    private func fetchActivityMetrics() async -> ActivityMetrics? {
        do {
            return try await healthKitManager.fetchTodayActivityMetrics()
        } catch {
            AppLogger.error("Failed to fetch activity metrics", error: error, category: .health)
            return nil
        }
    }

    private func fetchHeartHealthMetrics() async -> HeartHealthMetrics? {
        do {
            return try await healthKitManager.fetchHeartHealthMetrics()
        } catch {
            AppLogger.error("Failed to fetch heart health metrics", error: error, category: .health)
            return nil
        }
    }

    private func fetchBodyMetrics() async -> BodyMetrics? {
        do {
            return try await healthKitManager.fetchLatestBodyMetrics()
        } catch {
            AppLogger.error("Failed to fetch body metrics", error: error, category: .health)
            return nil
        }
    }

    private func fetchSleepSession() async -> SleepAnalysis.SleepSession? {
        do {
            return try await healthKitManager.fetchLastNightSleep()
        } catch {
            AppLogger.error("Failed to fetch last night sleep data", error: error, category: .health)
            return nil
        }
    }

    private func fetchSubjectiveData(using context: ModelContext) async -> SubjectiveData {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<DailyLog> { log in
            log.date == todayStart
        }
        var descriptor = FetchDescriptor<DailyLog>(predicate: predicate)
        descriptor.fetchLimit = 1

        do {
            if let log = try context.fetch(descriptor).first {
                return SubjectiveData(
                    energyLevel: log.subjectiveEnergyLevel,
                    mood: nil, // Mood tracking TBD
                    stress: log.stressLevel,
                    motivation: nil,
                    soreness: nil,
                    notes: log.notes
                )
            }
        } catch {
            AppLogger.error("Failed to fetch today's DailyLog", error: error, category: .data)
        }
        return SubjectiveData()
    }

    private func createMockEnvironmentContext() -> EnvironmentContext {
        EnvironmentContext(
            weatherCondition: "Clear",
            temperature: Measurement(value: 21, unit: .celsius),
            humidity: 55,
            airQualityIndex: 42,
            timeOfDay: .init(from: Date())
        )
    }

    private func createMockAppContext(using context: ModelContext) async -> AppSpecificContext {
        var lastMealTime: Date?
        var lastMealSummary: String?
        var activeWorkoutName: String?
        var upcomingWorkout: String?

        do {
            var mealDescriptor = FetchDescriptor<FoodEntry>(
                sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
            )
            mealDescriptor.fetchLimit = 1
            if let meal = try context.fetch(mealDescriptor).first {
                lastMealTime = meal.loggedAt
                let itemCount = meal.items.count
                let mealName = meal.mealTypeEnum?.displayName ?? "Meal"
                lastMealSummary = "\(mealName), \(itemCount) item\(itemCount == 1 ? "" : "s")"
            }

            var upcomingDescriptor = FetchDescriptor<Workout>(
                predicate: #Predicate<Workout> { workout in
                    workout.completedDate == nil && workout.plannedDate != nil && workout.plannedDate! > Date()
                },
                sortBy: [SortDescriptor(\.plannedDate, order: .forward)]
            )
            upcomingDescriptor.fetchLimit = 1
            if let nextWorkout = try context.fetch(upcomingDescriptor).first {
                upcomingWorkout = nextWorkout.name
            }

            var activeDescriptor = FetchDescriptor<Workout>(
                predicate: #Predicate<Workout> { workout in
                    workout.completedDate == nil && workout.plannedDate != nil && workout.plannedDate! <= Date()
                },
                sortBy: [SortDescriptor(\.plannedDate, order: .reverse)]
            )
            activeDescriptor.fetchLimit = 1
            if let active = try context.fetch(activeDescriptor).first {
                activeWorkoutName = active.name
            }
        } catch {
            AppLogger.error("Failed to assemble app context", error: error, category: .data)
        }

        return AppSpecificContext(
            activeWorkoutName: activeWorkoutName,
            lastMealTime: lastMealTime,
            lastMealSummary: lastMealSummary,
            waterIntakeToday: nil,
            lastCoachInteraction: nil,
            upcomingWorkout: upcomingWorkout,
            currentStreak: nil
        )
    }

    private func calculateTrends(
        activity: ActivityMetrics?,
        body: BodyMetrics?,
        sleep: SleepAnalysis.SleepSession?,
        context: ModelContext
    ) -> HealthTrends {
        var weeklyChange: Double?

        do {
            var descriptor = FetchDescriptor<DailyLog>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchLimit = 14
            let logs = try context.fetch(descriptor)
            let recent = logs.prefix(7).compactMap(\.steps)
            let previous = logs.dropFirst(7).prefix(7).compactMap(\.steps)

            if !recent.isEmpty, !previous.isEmpty {
                let recentAvg = Double(recent.reduce(0, +)) / Double(recent.count)
                let previousAvg = Double(previous.reduce(0, +)) / Double(previous.count)
                if previousAvg > 0 {
                    weeklyChange = ((recentAvg - previousAvg) / previousAvg) * 100
                }
            }
        } catch {
            AppLogger.error("Failed to calculate trends", error: error, category: .data)
        }

        return HealthTrends(weeklyActivityChange: weeklyChange)
    }
}

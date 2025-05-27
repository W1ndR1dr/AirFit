import Foundation
import SwiftData

/// Aggregates health and environmental data into `HealthContextSnapshot` instances.
@MainActor
final class ContextAssembler {
    private let healthKitManager: HealthKitManager
    // Future: private let weatherService: WeatherServiceProtocol

    init(healthKitManager: HealthKitManager = .shared) {
        self.healthKitManager = healthKitManager
    }

    /// Creates a `HealthContextSnapshot` using data from HealthKit and SwiftData models.
    /// - Parameter modelContext: The `ModelContext` used to fetch app data.
    func assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot {
        async let activityMetrics = fetchActivityMetrics()
        async let heartMetrics = fetchHeartHealthMetrics()
        async let bodyMetrics = fetchBodyMetrics()
        async let sleepSession = fetchSleepSession()
        async let subjectiveData = fetchSubjectiveData(using: modelContext)

        let environment = EnvironmentContext() // Placeholder for future WeatherService
        let appContext = AppSpecificContext()  // Placeholder for future app specific data

        let (activity, heartHealth, body, sleep, subjective) = await (
            activityMetrics,
            heartMetrics,
            bodyMetrics,
            sleepSession,
            subjectiveData
        )

        return HealthContextSnapshot(
            subjectiveData: subjective,
            environment: environment,
            activity: activity ?? ActivityMetrics(),
            sleep: SleepAnalysis(lastNight: sleep),
            heartHealth: heartHealth ?? HeartHealthMetrics(),
            body: body ?? BodyMetrics(),
            appContext: appContext
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
}

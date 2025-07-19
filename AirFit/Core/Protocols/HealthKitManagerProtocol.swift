import Foundation
import HealthKit

@MainActor
protocol HealthKitManaging: AnyObject, Sendable {
    var authorizationStatus: HealthKitManager.AuthorizationStatus { get }
    func refreshAuthorizationStatus()
    func requestAuthorization() async throws
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics
    func fetchLatestBodyMetrics() async throws -> BodyMetrics
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession?

    // New HealthKit integration methods
    func getWorkoutData(from startDate: Date, to endDate: Date) async -> [WorkoutData]
    func fetchRecentWorkouts(limit: Int) async throws -> [WorkoutData]
    func saveFoodEntry(_ entry: FoodEntry) async throws -> [String]
    func getNutritionData(for date: Date) async throws -> HealthKitNutritionSummary
    func saveWorkout(_ workout: Workout) async throws -> String
    func deleteWorkout(healthKitID: String) async throws

    // Body metrics methods
    func saveBodyMass(weightKg: Double, date: Date) async throws
    func saveBodyFatPercentage(percentage: Double, date: Date) async throws
    func saveLeanBodyMass(massKg: Double, date: Date) async throws
    func fetchBodyMetricsHistory(from startDate: Date, to endDate: Date) async throws -> [BodyMetrics]
    func observeBodyMetrics(handler: @escaping @Sendable () -> Void) async throws
    func removeObserver(_ observer: Any)
    
    // New APIs for RecoveryInference integration
    func fetchDailyBiometrics(from startDate: Date, to endDate: Date) async throws -> [DailyBiometrics]
    func fetchHistoricalWorkouts(from startDate: Date, to endDate: Date) async throws -> [WorkoutData]
    func observeHealthKitChanges(handler: @escaping @Sendable () -> Void) -> Any
    func stopObserving(token: Any)
}

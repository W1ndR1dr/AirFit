import Foundation

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
    func saveFoodEntry(_ entry: FoodEntry) async throws -> [String]
    func saveWaterIntake(amountML: Double, date: Date) async throws -> String?
    func getNutritionData(for date: Date) async throws -> HealthKitNutritionSummary
    func saveWorkout(_ workout: Workout) async throws -> String
    func deleteWorkout(healthKitID: String) async throws
}

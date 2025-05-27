protocol HealthKitManaging: AnyObject {
    var authorizationStatus: HealthKitManager.AuthorizationStatus { get }
    func refreshAuthorizationStatus()
    func requestAuthorization() async throws
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics
    func fetchLatestBodyMetrics() async throws -> BodyMetrics
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession?
}

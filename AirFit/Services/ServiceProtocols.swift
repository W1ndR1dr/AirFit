import Foundation
import Combine

// MARK: - Base Service Protocol
@MainActor
protocol ServiceProtocol: AnyObject {
    var isConfigured: Bool { get }
    var serviceIdentifier: String { get }
    
    func configure() async throws
    func reset() async
    func healthCheck() async -> ServiceHealth
}

// MARK: - AI Service Protocol
protocol AIServiceProtocol: ServiceProtocol {
    var isConfigured: Bool { get }
    var activeProvider: AIProvider { get }
    var availableModels: [AIModel] { get }
    
    func configure(
        provider: AIProvider,
        apiKey: String,
        model: String?
    ) async throws
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error>
    
    func validateConfiguration() async throws -> Bool
    
    func checkHealth() async -> ServiceHealth
    
    func estimateTokenCount(for text: String) -> Int
}

// MARK: - Weather Service Protocol
protocol WeatherServiceProtocol: ServiceProtocol {
    func getCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> WeatherData
    
    func getForecast(
        latitude: Double,
        longitude: Double,
        days: Int
    ) async throws -> WeatherForecast
    
    func getCachedWeather(
        latitude: Double,
        longitude: Double
    ) -> WeatherData?
}

// MARK: - API Key Management Protocol
protocol APIKeyManagementProtocol: AnyObject {
    func saveAPIKey(
        _ key: String,
        for provider: AIProvider
    ) async throws
    
    func getAPIKey(
        for provider: AIProvider
    ) async throws -> String
    
    func deleteAPIKey(
        for provider: AIProvider
    ) async throws
    
    func hasAPIKey(
        for provider: AIProvider
    ) async -> Bool
    
    func getAllConfiguredProviders() async -> [AIProvider]
}

// MARK: - Network Management Protocol
protocol NetworkManagementProtocol: AnyObject {
    var isReachable: Bool { get }
    var currentNetworkType: NetworkType { get }
    
    func performRequest<T: Decodable>(
        _ request: URLRequest,
        expecting: T.Type
    ) async throws -> T
    
    func performStreamingRequest(
        _ request: URLRequest
    ) -> AsyncThrowingStream<Data, Error>
    
    func downloadData(
        from url: URL
    ) async throws -> Data
    
    func uploadData(
        _ data: Data,
        to url: URL
    ) async throws -> URLResponse
}

// MARK: - Service Health
struct ServiceHealth: Sendable {
    enum Status: String, Sendable {
        case healthy
        case degraded
        case unhealthy
        case unknown
    }
    
    let status: Status
    let lastCheckTime: Date
    let responseTime: TimeInterval?
    let errorMessage: String?
    let metadata: [String: String]
    
    var isOperational: Bool {
        status == .healthy || status == .degraded
    }
}

// MARK: - Network Type
enum NetworkType: String, Sendable {
    case wifi
    case cellular
    case ethernet
    case unknown
    case none
}

// MARK: - Service Errors
enum ServiceError: LocalizedError {
    case notConfigured
    case invalidConfiguration(String)
    case networkUnavailable
    case authenticationFailed(String)
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case invalidResponse(String)
    case streamingError(String)
    case timeout
    case cancelled
    case providerError(code: String, message: String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service is not configured"
        case .invalidConfiguration(let detail):
            return "Invalid configuration: \(detail)"
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Retry after \(Int(retryAfter)) seconds"
            }
            return "Rate limit exceeded"
        case .invalidResponse(let detail):
            return "Invalid response: \(detail)"
        case .streamingError(let detail):
            return "Streaming error: \(detail)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .providerError(let code, let message):
            return "Provider error [\(code)]: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - User Service Protocol
protocol UserServiceProtocol: AnyObject {
    func createUser(from profile: OnboardingProfile) async throws -> User
    func updateProfile(_ updates: ProfileUpdate) async throws
    func getCurrentUser() -> User?
    func deleteUser(_ user: User) async throws
}

// MARK: - Workout Service Protocol
protocol WorkoutServiceProtocol: AnyObject {
    func startWorkout(type: WorkoutType, user: User) async throws -> Workout
    func pauseWorkout(_ workout: Workout) async throws
    func resumeWorkout(_ workout: Workout) async throws
    func endWorkout(_ workout: Workout) async throws
    func logExercise(_ exercise: Exercise, in workout: Workout) async throws
    func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout]
    func getWorkoutTemplates() async throws -> [WorkoutTemplate]
    func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws
}

// MARK: - Analytics Service Protocol
protocol AnalyticsServiceProtocol: AnyObject {
    func trackEvent(_ event: AnalyticsEvent) async
    func trackScreen(_ screen: String, properties: [String: Any]?) async
    func setUserProperties(_ properties: [String: Any]) async
    func trackWorkoutCompleted(_ workout: Workout) async
    func trackMealLogged(_ meal: FoodEntry) async
    func trackGoalProgress(_ goal: Goal, progress: Double) async
    func getInsights(for user: User) async throws -> UserInsights
}

// MARK: - Goal Service Protocol
protocol GoalServiceProtocol: AnyObject {
    func createGoal(
        _ goalData: GoalCreationData,
        for user: User
    ) async throws -> Goal
    
    func updateGoal(
        _ goal: Goal,
        updates: GoalUpdate
    ) async throws
    
    func deleteGoal(_ goal: Goal) async throws
    
    func getActiveGoals(for user: User) async throws -> [Goal]
    
    func trackProgress(
        for goal: Goal,
        value: Double
    ) async throws
    
    func checkGoalCompletion(_ goal: Goal) async -> Bool
}

// MARK: - Supporting Types
struct AnalyticsEvent: Sendable {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
}

struct UserInsights: Sendable {
    let workoutFrequency: Double
    let averageWorkoutDuration: TimeInterval
    let caloriesTrend: Trend
    let macroBalance: MacroBalance
    let streakDays: Int
    let achievements: [Achievement]
}

struct Trend: Sendable {
    enum Direction: String, Sendable {
        case up
        case down
        case stable
    }
    
    let direction: Direction
    let changePercentage: Double
}

struct MacroBalance: Sendable {
    let proteinPercentage: Double
    let carbsPercentage: Double
    let fatPercentage: Double
}

struct Achievement: Sendable {
    let id: String
    let title: String
    let description: String
    let unlockedAt: Date
    let icon: String
}

struct Goal: Sendable, Identifiable {
    let id: UUID
    let type: GoalType
    let target: Double
    let currentValue: Double
    let deadline: Date?
    let createdAt: Date
    let updatedAt: Date
}

enum GoalType: String, Sendable, CaseIterable {
    case weightLoss
    case muscleGain
    case stepCount
    case workoutFrequency
    case calorieIntake
    case waterIntake
    case custom
}

struct GoalCreationData: Sendable {
    let type: GoalType
    let target: Double
    let deadline: Date?
    let description: String?
}

struct GoalUpdate: Sendable {
    let target: Double?
    let deadline: Date?
    let description: String?
}

// MARK: - Weather Types
struct WeatherData: Sendable {
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Double
    let windSpeed: Double
    let location: String
    let timestamp: Date
}

struct WeatherForecast: Sendable {
    let daily: [DailyForecast]
    let location: String
}

struct DailyForecast: Sendable {
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let condition: WeatherCondition
    let precipitationChance: Double
}

enum WeatherCondition: String, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case thunderstorm
    case fog
}

// MARK: - Workout Types
enum WorkoutType: String, Sendable, CaseIterable {
    case strength
    case cardio
    case flexibility
    case sports
    case custom
}
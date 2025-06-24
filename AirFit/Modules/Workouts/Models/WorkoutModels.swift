import Foundation

// MARK: - Weekly Workout Stats
struct WeeklyWorkoutStats: Sendable {
    var totalWorkouts: Int = 0
    var totalDuration: TimeInterval = 0
    var totalCalories: Double = 0
    var muscleGroupDistribution: [String: Int] = [:]
}


// MARK: - Coach Engine Protocol
protocol CoachEngineProtocol: AnyObject, Sendable {
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String
    func processUserMessage(_ text: String, for user: User) async
}

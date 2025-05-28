@testable import AirFit
import Foundation

@MainActor
final class MockCoachEngine: CoachEngineProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]

    var mockAnalysis: String = "Great workout!"
    private(set) var didGenerateAnalysis = false

    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        recordInvocation(#function, arguments: request)
        didGenerateAnalysis = true
        return mockAnalysis
    }
}

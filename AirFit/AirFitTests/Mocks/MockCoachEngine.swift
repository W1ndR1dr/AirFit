@testable import AirFit
import Foundation

@MainActor
final class MockCoachEngine: CoachEngineProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]

    var mockAnalysis: String = "Great workout!"
    private(set) var didGenerateAnalysis = false
    var shouldThrowError = false
    var shouldDelay = false

    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        recordInvocation(#function, arguments: request)
        didGenerateAnalysis = true
        
        if shouldThrowError {
            throw MockError.testError
        }
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        return mockAnalysis
    }
}

enum MockError: Error {
    case testError
}

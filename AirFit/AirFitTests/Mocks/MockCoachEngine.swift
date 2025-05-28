@testable import AirFit
import Foundation

@MainActor
final class MockCoachEngine: CoachEngineProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

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
    
    // Reset method for test cleanup
    func reset() {
        didGenerateAnalysis = false
        shouldThrowError = false
        shouldDelay = false
        mockAnalysis = "Great workout!"
        invocations.removeAll()
        stubbedResults.removeAll()
    }
}

enum MockError: Error {
    case testError
}

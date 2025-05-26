@testable import AirFit
import Foundation

@MainActor
final class MockAIService: AIServiceProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]

    var analyzeGoalResult: Result<String, Error> = .failure(MockError.notSet)
    private(set) var analyzeGoalCalled = false

    func analyzeGoal(_ goalText: String) async throws -> String {
        recordInvocation(#function, arguments: goalText)
        analyzeGoalCalled = true

        switch analyzeGoalResult {
        case .success(let analysis):
            return analysis
        case .failure(let error):
            throw error
        }
    }

    enum MockError: Error {
        case notSet
    }
}

extension UserProfileJsonBlob {
    static var mock: UserProfileJsonBlob {
        UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(),
            blend: Blend(),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle()
        )
    }
}

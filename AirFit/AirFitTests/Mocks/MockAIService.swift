@testable import AirFit
import Foundation

@MainActor
final class MockAIService: AIServiceProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]

    var analyzeGoalResult: Result<StructuredGoal, Error> = .failure(MockError.notSet)
    private(set) var analyzeGoalCalled = false

    func analyzeGoal(_ goalText: String) async throws -> StructuredGoal {
        recordInvocation(#function, arguments: goalText)
        analyzeGoalCalled = true

        switch analyzeGoalResult {
        case .success(let goal):
            return goal
        case .failure(let error):
            throw error
        }
    }

    enum MockError: Error {
        case notSet
    }
}

extension StructuredGoal {
    static var mock: StructuredGoal {
        StructuredGoal(
            goalType: "weight_loss",
            primaryMetric: "weight",
            timeframe: "3 months",
            specificTarget: "10 lbs",
            whyImportant: "Health and fitness"
        )
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

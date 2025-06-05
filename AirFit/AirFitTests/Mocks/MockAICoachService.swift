@testable import AirFit
import Foundation
import SwiftData

@MainActor
final class MockAICoachService: AICoachServiceProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    var mockGreeting: String = "Hello"

    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
        recordInvocation(#function, arguments: user, context)
        return mockGreeting
    }
}
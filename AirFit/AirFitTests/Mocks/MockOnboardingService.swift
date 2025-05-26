@testable import AirFit
import Foundation

@MainActor
final class MockOnboardingService: OnboardingServiceProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]

    var saveProfileCalled = false
    var saveProfileError: Error?

    func saveProfile(_ profile: OnboardingProfile) async throws {
        recordInvocation(#function, arguments: profile)
        saveProfileCalled = true
        if let error = saveProfileError {
            throw error
        }
    }
}

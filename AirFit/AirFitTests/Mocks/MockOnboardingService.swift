@testable import AirFit
import Foundation

@MainActor
final class MockOnboardingService: OnboardingServiceProtocol, @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

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

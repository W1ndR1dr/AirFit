@testable import AirFit
import Foundation
import SwiftData

final class MockUserService: UserServiceProtocol, MockProtocol, @unchecked Sendable {
    private let lock = NSLock()
    let mockLock = NSLock()
    
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]

    var createUserResult: Result<User, Error>?
    var updateProfileResult: Result<Void, Error> = .success(())
    var getCurrentUserResult: User?

    func createUser(from profile: OnboardingProfile) async throws -> User {
        recordInvocation(#function, arguments: profile)
        
        if let result = createUserResult {
            switch result {
            case .success(let user):
                return user
            case .failure(let error):
                throw error
            }
        }
        
        // Default behavior: create user from profile
        let user = User(
            email: profile.email ?? "test@example.com",
            name: profile.name ?? "Test User"
        )
        return user
    }

    func updateProfile(_ updates: ProfileUpdate) async throws {
        recordInvocation(#function, arguments: updates)
        if case .failure(let error) = updateProfileResult {
            throw error
        }
    }

    func getCurrentUser() -> User? {
        recordInvocation(#function)
        return getCurrentUserResult
    }
    
    func getCurrentUserId() async -> UUID? {
        recordInvocation(#function)
        return getCurrentUserResult?.id
    }

    func deleteUser(_ user: User) async throws {
        recordInvocation(#function, arguments: user)
    }
    
    func completeOnboarding() async throws {
        recordInvocation(#function)
        if case .failure(let error) = updateProfileResult {
            throw error
        }
    }
    
    func setCoachPersona(_ persona: CoachPersona) async throws {
        recordInvocation(#function, arguments: persona)
        if case .failure(let error) = updateProfileResult {
            throw error
        }
    }
}


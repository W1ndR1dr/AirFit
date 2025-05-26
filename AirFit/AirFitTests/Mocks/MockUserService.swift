import Foundation
@testable import AirFit

@MainActor
final class MockUserService: UserServiceProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    
    // Stubbed responses
    var createUserResult: Result<User, Error> = .success(User.mock)
    var updateProfileResult: Result<Void, Error> = .success(())
    var getCurrentUserResult: User? = User.mock
    
    func createUser(from profile: OnboardingProfile) async throws -> User {
        recordInvocation(#function, arguments: profile)
        
        switch createUserResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
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
}

// Test data extensions
extension User {
    static var mock: User {
        User(
            id: UUID(),
            name: "Test User",
            email: "test@example.com",
            profile: UserProfile.mock
        )
    }
}

extension UserProfile {
    static var mock: UserProfile {
        UserProfile(
            age: 30,
            weight: 70,
            height: 175,
            biologicalSex: .male,
            activityLevel: .moderate,
            goal: .maintainWeight
        )
    }
} 
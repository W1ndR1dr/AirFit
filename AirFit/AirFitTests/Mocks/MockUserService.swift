@testable import AirFit
import Foundation
import SwiftData

final class MockUserService: UserServiceProtocol, MockProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _invocations: [String: [Any]] = [:]
    private var _stubbedResults: [String: Any] = [:]
    
    var invocations: [String: [Any]] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _invocations
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _invocations = newValue
        }
    }
    
    var stubbedResults: [String: Any] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _stubbedResults
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _stubbedResults = newValue
        }
    }

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

    func deleteUser(_ user: User) async throws {
        recordInvocation(#function, arguments: user)
    }
}

extension User {
    static var mock: User {
        User(id: UUID(), email: "test@example.com", name: "Test User", preferredUnits: "imperial")
    }
}

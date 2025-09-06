import Foundation
import SwiftData

/// Represents changes that can be applied to a user profile.
struct ProfileUpdate: Sendable {
    var email: String?
    var name: String?
    var preferredUnits: String?
}

/// Service interface for managing `User` models.
protocol UserServiceProtocol: AnyObject, Sendable {
    func createUser(from profile: OnboardingProfile) async throws -> User
    func updateProfile(_ updates: ProfileUpdate) async throws
    func getCurrentUser() async -> User?
    func getCurrentUserId() async -> UUID?
    func deleteUser(_ user: User) async throws
    func completeOnboarding() async throws
    func setCoachPersona(_ persona: CoachPersona) async throws
}

import Foundation
import SwiftData

/// Read-only repository for User data access
/// Eliminates direct SwiftData dependencies in ViewModels
@MainActor
final class UserReadRepository: UserReadRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - ReadRepositoryProtocol
    
    func find(filter: UserFilter) async throws -> [User] {
        let descriptor = createFetchDescriptor(for: filter)
        return try modelContext.fetch(descriptor)
    }
    
    func findFirst(filter: UserFilter) async throws -> User? {
        var descriptor = createFetchDescriptor(for: filter)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    func count(filter: UserFilter) async throws -> Int {
        let descriptor = createFetchDescriptor(for: filter)
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - UserReadRepositoryProtocol
    
    func findActiveUser() async throws -> User? {
        let filter = UserFilter(isActive: true)
        return try await findFirst(filter: filter)
    }
    
    func findUser(id: UUID) async throws -> User? {
        let filter = UserFilter(ids: [id])
        return try await findFirst(filter: filter)
    }
    
    func hasCompletedOnboarding(userId: UUID) async throws -> Bool {
        guard let user = try await findUser(id: userId) else {
            return false
        }
        return user.hasCompletedOnboarding
    }
    
    func getUserProfile(userId: UUID) async throws -> UserProfile? {
        guard let user = try await findUser(id: userId) else {
            return nil
        }
        
        return UserProfile(
            id: user.id,
            name: user.name,
            email: user.email,
            createdAt: user.createdAt,
            lastActiveDate: user.lastActiveDate,
            hasCompletedOnboarding: user.hasCompletedOnboarding
        )
    }
    
    // MARK: - Private Helpers
    
    private func createFetchDescriptor(for filter: UserFilter) -> FetchDescriptor<User> {
        var descriptor = FetchDescriptor<User>(
            sortBy: [SortDescriptor(\.lastActiveDate, order: .reverse)]
        )
        
        // Build predicates based on filter
        var predicates: [Predicate<User>] = []
        
        if let isActive = filter.isActive {
            if isActive {
                // Consider user active if lastActiveDate is recent (within 30 days)
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                predicates.append(#Predicate { user in
                    user.lastActiveDate >= thirtyDaysAgo
                })
            }
        }
        
        if let hasCompletedOnboarding = filter.hasCompletedOnboarding {
            predicates.append(#Predicate { user in
                user.hasCompletedOnboarding == hasCompletedOnboarding
            })
        }
        
        if let ids = filter.ids, !ids.isEmpty {
            predicates.append(#Predicate { user in
                ids.contains(user.id)
            })
        }
        
        // Combine predicates with AND logic
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(nil) { result, predicate in
                if let result = result {
                    return #Predicate<User> { user in
                        result.evaluate(user) && predicate.evaluate(user)
                    }
                } else {
                    return predicate
                }
            }
        }
        
        return descriptor
    }
}

// MARK: - Repository Error Handling

extension UserReadRepository {
    enum RepositoryError: Error, LocalizedError {
        case userNotFound(UUID)
        case multipleUsersFound
        case dataCorruption(String)
        
        var errorDescription: String? {
            switch self {
            case .userNotFound(let id):
                return "User with ID \(id) not found"
            case .multipleUsersFound:
                return "Multiple active users found when expecting one"
            case .dataCorruption(let details):
                return "Data corruption detected: \(details)"
            }
        }
    }
    
    /// Safe method to get the single active user
    /// Throws if no user or multiple users found
    func getActiveUserOrThrow() async throws -> User {
        let users = try await find(filter: UserFilter(isActive: true))
        
        guard !users.isEmpty else {
            throw RepositoryError.userNotFound(UUID())
        }
        
        guard users.count == 1 else {
            AppLogger.warning("Multiple active users found: \(users.count)", category: .data)
            throw RepositoryError.multipleUsersFound
        }
        
        return users[0]
    }
}
import Foundation
import SwiftData
import Observation

/// Global application state manager
@MainActor
@Observable
final class AppState {
    // MARK: - State Properties
    private(set) var isLoading = true
    private(set) var currentUser: User?
    private(set) var hasCompletedOnboarding = false
    private(set) var error: Error?

    // MARK: - Dependencies
    private let modelContext: ModelContext

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadUserState()
        }
    }

    // MARK: - Public Methods
    func loadUserState() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch the current user
            let userDescriptor = FetchDescriptor<User>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let users = try modelContext.fetch(userDescriptor)
            currentUser = users.first

            // Check onboarding completion
            if let user = currentUser {
                hasCompletedOnboarding = user.onboardingProfile != nil
                user.updateActivity()
                try modelContext.save()
                AppLogger.info("User state loaded - onboarding: \(hasCompletedOnboarding)", category: .app)
            } else {
                hasCompletedOnboarding = false
                AppLogger.info("No existing user found", category: .app)
            }
        } catch {
            self.error = error
            AppLogger.error("Failed to load user state", error: error, category: .app)
        }
    }

    func createNewUser() async throws {
        let user = User()
        modelContext.insert(user)
        try modelContext.save()
        currentUser = user
        hasCompletedOnboarding = false
        AppLogger.info("New user created", category: .app)
    }

    func completeOnboarding() async {
        await loadUserState()
    }

    func clearError() {
        error = nil
    }
}

// MARK: - App State Extensions
extension AppState {
    var shouldShowOnboarding: Bool {
        !isLoading && currentUser != nil && !hasCompletedOnboarding
    }

    var shouldCreateUser: Bool {
        !isLoading && currentUser == nil
    }

    var shouldShowDashboard: Bool {
        !isLoading && currentUser != nil && hasCompletedOnboarding
    }
}

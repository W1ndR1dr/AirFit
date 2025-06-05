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
    private let isUITesting: Bool
    private let healthKitAuthManager: HealthKitAuthManager

    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        healthKitAuthManager: HealthKitAuthManager = HealthKitAuthManager()
    ) {
        self.modelContext = modelContext
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        self.healthKitAuthManager = healthKitAuthManager

        if isUITesting {
            setupUITestingState()
        } else {
            Task {
                await loadUserState()
            }
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
        isLoading = false
        AppLogger.info("New user created", category: .app)
    }

    func completeOnboarding() async {
        await loadUserState()
    }

    func clearError() {
        error = nil
    }

    @discardableResult
    func requestHealthKitAuthorization() async -> Bool {
        await healthKitAuthManager.requestAuthorizationIfNeeded()
    }

    private func setupUITestingState() {
        // For UI testing, create a mock user and set up onboarding state
        isLoading = false

        if ProcessInfo.processInfo.arguments.contains("--reset-onboarding") {
            // Create a user but don't complete onboarding
            let user = User()
            modelContext.insert(user)
            try? modelContext.save()
            currentUser = user
            hasCompletedOnboarding = false
            AppLogger.info("UI Testing: User created for onboarding flow", category: .app)
        } else {
            // Default UI testing state
            hasCompletedOnboarding = false
            AppLogger.info("UI Testing: Default state configured", category: .app)
        }
    }
}

// MARK: - App State Extensions
extension AppState {
    var shouldShowOnboarding: Bool {
        !isLoading && currentUser != nil && !hasCompletedOnboarding
    }

    var healthKitStatus: HealthKitAuthorizationStatus {
        healthKitAuthManager.authorizationStatus
    }

    var shouldCreateUser: Bool {
        !isLoading && currentUser == nil
    }

    var shouldShowDashboard: Bool {
        !isLoading && currentUser != nil && hasCompletedOnboarding
    }
}

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
    private(set) var needsAPISetup = true
    private(set) var error: Error?

    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let isUITesting: Bool
    private let healthKitAuthManager: HealthKitAuthManager
    let apiKeyManager: APIKeyManagementProtocol?

    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        healthKitAuthManager: HealthKitAuthManager,
        apiKeyManager: APIKeyManagementProtocol? = nil
    ) {
        self.modelContext = modelContext
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        self.healthKitAuthManager = healthKitAuthManager
        self.apiKeyManager = apiKeyManager

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
            // Check API configuration status FIRST
            if let apiKeyManager = apiKeyManager {
                let configuredProviders = await apiKeyManager.getAllConfiguredProviders()
                needsAPISetup = configuredProviders.isEmpty

                // Debug: Log which providers are configured
                for provider in configuredProviders {
                    AppLogger.info("Found configured API key for: \(provider.displayName)", category: .app)
                }

                AppLogger.info("API setup check - configured providers: \(configuredProviders.count), needs setup: \(needsAPISetup)", category: .app)

                // For testing: uncomment the next line to force API setup screen
                // needsAPISetup = true
            } else {
                // If no API key manager, assume we need setup
                needsAPISetup = true
                AppLogger.warning("No API key manager available, assuming API setup needed", category: .app)
            }

            // Fetch the current user
            let userDescriptor = FetchDescriptor<User>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let users = try modelContext.fetch(userDescriptor)
            currentUser = users.first

            // Check onboarding completion
            if let user = currentUser {
                // Use isOnboarded flag as the source of truth
                hasCompletedOnboarding = user.isOnboarded
                user.updateActivity()
                try modelContext.save()
                AppLogger.info("User state loaded - onboarding: \(hasCompletedOnboarding), API setup needed: \(needsAPISetup)", category: .app)
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

    func completeAPISetup() {
        needsAPISetup = false
        AppLogger.info("API setup completed", category: .app)
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
    var shouldShowAPISetup: Bool {
        !isLoading && needsAPISetup
    }

    var shouldShowOnboarding: Bool {
        !isLoading && !needsAPISetup && currentUser != nil && !hasCompletedOnboarding
    }

    var healthKitStatus: AirFit.HealthKitAuthorizationStatus {
        healthKitAuthManager.authorizationStatus
    }

    var shouldCreateUser: Bool {
        !isLoading && !needsAPISetup && currentUser == nil
    }

    var shouldShowDashboard: Bool {
        !isLoading && !needsAPISetup && currentUser != nil && hasCompletedOnboarding
    }
}

import Foundation
import SwiftData

/// Implementation of AICoachServiceProtocol for the Dashboard
actor AICoachService: AICoachServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "ai-coach-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For actors, return true as services are ready when created
        true
    }

    private let coachEngine: CoachEngine

    init(coachEngine: CoachEngine) {
        self.coachEngine = coachEngine
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["hasCoachEngine": "true"]
        )
    }

    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
        // For now, we'll use the dashboard content generation which includes greetings
        // In the future, we could implement a dedicated greeting method in CoachEngine
        let dashboardContent = try await coachEngine.generateDashboardContent(for: user)

        // Return the primary insight as the greeting
        return dashboardContent.primaryInsight
    }

    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        // Delegate to the real AI implementation in CoachEngine
        return try await coachEngine.generateDashboardContent(for: user)
    }
}

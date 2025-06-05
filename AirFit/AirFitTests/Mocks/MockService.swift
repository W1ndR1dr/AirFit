import Foundation
@testable import AirFit

// MARK: - MockService (Generic ServiceProtocol Implementation)
@MainActor
final class MockService: ServiceProtocol, MockProtocol {
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // ServiceProtocol conformance
    var isConfigured: Bool = true
    let serviceIdentifier: String
    
    // Stubbed responses
    var stubbedConfigureError: Error?
    var stubbedHealthCheckResult: ServiceHealth = ServiceHealth(
        status: .healthy,
        lastCheckTime: Date(),
        responseTime: 0.1,
        errorMessage: nil,
        metadata: [:]
    )
    
    init(serviceIdentifier: String = "MockService") {
        self.serviceIdentifier = serviceIdentifier
    }
    
    func configure() async throws {
        recordInvocation("configure")
        
        if let error = stubbedConfigureError {
            isConfigured = false
            throw error
        }
        
        isConfigured = true
    }
    
    func reset() async {
        recordInvocation("reset")
        isConfigured = false
    }
    
    func healthCheck() async -> ServiceHealth {
        recordInvocation("healthCheck")
        return stubbedHealthCheckResult
    }
    
    // Helper methods for testing
    func stubConfigureError(with error: Error) {
        stubbedConfigureError = error
    }
    
    func stubHealthCheck(with health: ServiceHealth) {
        stubbedHealthCheckResult = health
    }
    
    func stubHealthCheckStatus(_ status: ServiceHealth.Status, message: String? = nil) {
        stubbedHealthCheckResult = ServiceHealth(
            status: status,
            lastCheckTime: Date(),
            responseTime: status == .healthy ? 0.1 : nil,
            errorMessage: message,
            metadata: [:]
        )
    }
    
    // Verify helpers
    func verifyConfigure(called times: Int = 1) {
        verify("configure", called: times)
    }
    
    func verifyReset(called times: Int = 1) {
        verify("reset", called: times)
    }
    
    func verifyHealthCheck(called times: Int = 1) {
        verify("healthCheck", called: times)
    }
}
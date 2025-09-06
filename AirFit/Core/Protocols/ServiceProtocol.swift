import Foundation

// MARK: - Base Service Protocol
protocol ServiceProtocol: AnyObject, Sendable {
    var isConfigured: Bool { get }
    var serviceIdentifier: String { get }

    func configure() async throws
    func reset() async
    func healthCheck() async -> ServiceHealth
}

// MARK: - Service Health
struct ServiceHealth: Sendable {
    enum Status: String, Sendable {
        case healthy
        case degraded
        case unhealthy
        case unknown
    }

    let status: Status
    let lastCheckTime: Date
    let responseTime: TimeInterval?
    let errorMessage: String?
    let metadata: [String: String]

    var isOperational: Bool {
        status == .healthy || status == .degraded
    }
}

import Foundation

// MARK: - AI Service Protocol
@MainActor
protocol AIServiceProtocol: ServiceProtocol {
    var isConfigured: Bool { get }
    var activeProvider: AIProvider { get }
    var availableModels: [AIModel] { get }
    
    func configure(
        provider: AIProvider,
        apiKey: String,
        model: String?
    ) async throws
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error>
    
    func validateConfiguration() async throws -> Bool
    
    func checkHealth() async -> ServiceHealth
    
    func estimateTokenCount(for text: String) -> Int
}
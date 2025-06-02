import Foundation
import Combine

/// Bridge implementation that connects AIAPIServiceProtocol to LLMOrchestrator
/// This allows existing code using AIRequest/AIResponse to work with our LLM infrastructure
@MainActor
final class AIAPIService: AIAPIServiceProtocol {
    private let llmOrchestrator: LLMOrchestrator
    private var currentProvider: AIProvider?
    private var currentModel: String?
    
    init(llmOrchestrator: LLMOrchestrator) {
        self.llmOrchestrator = llmOrchestrator
    }
    
    nonisolated func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
        Task { @MainActor in
            self.currentProvider = provider
            self.currentModel = modelIdentifier ?? provider.rawValue
        }
        
        // Note: API keys are already configured in LLMOrchestrator through APIKeyManager
        // This method exists for protocol compliance but doesn't need to do anything
    }
    
    nonisolated func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponse, Error> {
        // For Phase 4, return empty publisher to avoid concurrency issues
        // TODO: Implement proper streaming support in Phase 5
        return Empty(completeImmediately: true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Conversion Methods
    
    private func convertToLLMRequest(_ aiRequest: AIRequest) -> LLMRequest {
        // Build messages array from AIRequest components
        var messages: [LLMMessage] = []
        
        // Add system prompt if provided
        if !aiRequest.systemPrompt.isEmpty {
            messages.append(LLMMessage(
                role: .system,
                content: aiRequest.systemPrompt,
                name: nil
            ))
        }
        
        // Add messages from request
        for message in aiRequest.messages {
            messages.append(LLMMessage(
                role: convertMessageRole(message.role),
                content: message.content,
                name: message.name
            ))
        }
        
        // Determine model
        let model = currentModel ?? getDefaultModel()
        
        return LLMRequest(
            messages: messages,
            model: model,
            temperature: 0.7, // Default temperature
            maxTokens: nil,   // Let provider decide
            systemPrompt: nil, // Already in messages
            responseFormat: nil,
            stream: true,     // Always stream for this method
            metadata: [
                "source": "AIAPIService",
                "hasFunctions": String(aiRequest.functions != nil)
            ]
        )
    }
    
    private func convertMessageRole(_ role: AIMessageRole) -> LLMMessage.Role {
        switch role {
        case .system:
            return .system
        case .user:
            return .user
        case .assistant:
            return .assistant
        case .function, .tool:
            return .assistant // Map function/tool to assistant for now
        }
    }
    
    private func convertToAIResponse(_ chunk: LLMStreamChunk) -> AIResponse {
        if chunk.isFinished {
            return .done(usage: nil)
        } else if !chunk.delta.isEmpty {
            return .textDelta(chunk.delta)
        } else {
            return .done(usage: nil)
        }
    }
    
    private func getDefaultModel() -> String {
        // Map AIProvider to LLMModel
        guard let provider = currentProvider else {
            return LLMModel.claude3Haiku.identifier // Default fallback
        }
        
        switch provider {
        case .openAI:
            return LLMModel.gpt4Turbo.identifier
        case .anthropic:
            return LLMModel.claude3Opus.identifier
        case .gemini:
            return LLMModel.gemini15Pro.identifier
        case .openRouter:
            return LLMModel.gpt4Turbo.identifier // OpenRouter can use various models
        @unknown default:
            return LLMModel.gpt4Turbo.identifier
        }
    }
}

// MARK: - Direct LLM Integration Extension

extension AIAPIService {
    /// Direct method to use LLMOrchestrator without going through AIRequest/AIResponse
    /// This is the preferred method for new code
    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        return try await llmOrchestrator.complete(
            prompt: request.messages.map { $0.content }.joined(separator: "\n"),
            task: .quickResponse
        )
    }
    
    /// Stream method that returns native AsyncThrowingStream
    func stream(_ request: LLMRequest) async throws -> AsyncThrowingStream<LLMStreamChunk, Error> {
        return llmOrchestrator.stream(
            prompt: request.messages.map { $0.content }.joined(separator: "\n"),
            task: .quickResponse
        )
    }
}
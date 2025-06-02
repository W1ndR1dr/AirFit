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
        // Convert AIRequest to LLMRequest
        let llmRequest = convertToLLMRequest(request)
        
        // Create a PassthroughSubject to bridge async stream to Combine
        let subject = PassthroughSubject<AIResponse, Error>()
        
        Task {
            do {
                let stream = try await llmOrchestrator.stream(prompt: llmRequest)
                
                for try await chunk in stream {
                    let aiResponse = convertToAIResponse(chunk)
                    subject.send(aiResponse)
                }
                
                // Send stream end
                subject.send(.streamEnd)
                subject.send(completion: .finished)
            } catch {
                subject.send(.streamError(error))
                subject.send(completion: .failure(error))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Conversion Methods
    
    private func convertToLLMRequest(_ aiRequest: AIRequest) -> LLMRequest {
        // Build messages array from AIRequest components
        var messages: [LLMMessage] = []
        
        // Add system prompt if provided
        if let systemPrompt = aiRequest.systemPrompt, !systemPrompt.isEmpty {
            messages.append(LLMMessage(
                role: .system,
                content: systemPrompt,
                name: nil
            ))
        }
        
        // Add conversation history
        for message in aiRequest.conversationHistory {
            messages.append(LLMMessage(
                role: convertMessageRole(message.role),
                content: message.content,
                name: nil
            ))
        }
        
        // Add current user message
        messages.append(LLMMessage(
            role: .user,
            content: aiRequest.userMessage.content,
            name: nil
        ))
        
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
                "hasAvailableFunctions": aiRequest.availableFunctions != nil
            ]
        )
    }
    
    private func convertMessageRole(_ role: MessageRole) -> LLMMessage.Role {
        switch role {
        case .system:
            return .system
        case .user:
            return .user
        case .assistant:
            return .assistant
        }
    }
    
    private func convertToAIResponse(_ chunk: LLMStreamChunk) -> AIResponse {
        if chunk.isFinished {
            return .streamEnd
        } else if !chunk.delta.isEmpty {
            return .textChunk(chunk.delta)
        } else {
            return .streamEnd
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
        case .googleGemini:
            return LLMModel.gemini15Pro.identifier
        case .openRouter:
            return LLMModel.gpt4Turbo.identifier // OpenRouter can use various models
        }
    }
}

// MARK: - Direct LLM Integration Extension

extension AIAPIService {
    /// Direct method to use LLMOrchestrator without going through AIRequest/AIResponse
    /// This is the preferred method for new code
    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        return try await llmOrchestrator.complete(request)
    }
    
    /// Stream method that returns native AsyncThrowingStream
    func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        return llmOrchestrator.stream(request)
    }
}
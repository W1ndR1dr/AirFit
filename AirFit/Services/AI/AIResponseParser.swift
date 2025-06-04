import Foundation

actor AIResponseParser {
    
    // MARK: - Properties
    private var buffers: [UUID: ResponseBuffer] = [:]
    
    // MARK: - Parse Stream Data
    func parseStreamData(
        _ data: Data,
        provider: AIProvider
    ) async throws -> [AIResponse] {
        
        switch provider {
        case .openAI, .openRouter:
            return try parseOpenAIStream(data)
            
        case .anthropic:
            return try parseAnthropicStream(data)
            
        case .gemini:
            return try parseGeminiStream(data)
        }
    }
    
    // MARK: - OpenAI/OpenRouter Parsing
    private func parseOpenAIStream(_ data: Data) throws -> [AIResponse] {
        guard let string = String(data: data, encoding: .utf8) else {
            throw ServiceError.invalidResponse("Invalid UTF-8 data")
        }
        
        // Skip empty data or [DONE] marker
        if string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        
        if string.contains("[DONE]") {
            return [.done(usage: nil)]
        }
        
        // Parse JSON
        guard let jsonData = string
            .replacingOccurrences(of: "data: ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .data(using: .utf8) else {
            return []
        }
        
        do {
            let response = try JSONDecoder().decode(OpenAIStreamResponse.self, from: jsonData)
            return parseOpenAIResponse(response)
        } catch {
            AppLogger.error("Failed to parse OpenAI response", error: error, category: .services)
            return []
        }
    }
    
    private func parseOpenAIResponse(_ response: OpenAIStreamResponse) -> [AIResponse] {
        var results: [AIResponse] = []
        
        for choice in response.choices {
            // Text content
            if let content = choice.delta.content {
                results.append(.textDelta(content))
            }
            
            // Tool calls
            if let toolCalls = choice.delta.toolCalls {
                for toolCall in toolCalls {
                    if let function = toolCall.function,
                       let name = function.name,
                       let arguments = function.arguments {
                        // Parse arguments to create AIFunctionCall
                        if let argsData = arguments.data(using: .utf8),
                           let argsDict = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
                            results.append(.functionCall(AIFunctionCall(name: name, arguments: argsDict)))
                        } else {
                            results.append(.functionCall(AIFunctionCall(name: name, arguments: [:])))
                        }
                    }
                }
            }
            
            // Stream end
            if let finishReason = choice.finishReason,
               finishReason == "stop" || finishReason == "tool_calls" {
                results.append(.done(usage: nil))
            }
        }
        
        return results
    }
    
    // MARK: - Anthropic Parsing
    private func parseAnthropicStream(_ data: Data) throws -> [AIResponse] {
        guard let string = String(data: data, encoding: .utf8) else {
            throw ServiceError.invalidResponse("Invalid UTF-8 data")
        }
        
        var results: [AIResponse] = []
        let lines = string.components(separatedBy: .newlines)
        
        var eventType: String?
        var eventData: String?
        
        for line in lines {
            if line.hasPrefix("event: ") {
                eventType = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                eventData = String(line.dropFirst(6))
                
                // Process event when we have both type and data
                if let type = eventType, let data = eventData {
                    if let response = parseAnthropicEvent(type: type, data: data) {
                        results.append(response)
                    }
                    
                    // Reset for next event
                    eventType = nil
                    eventData = nil
                }
            }
        }
        
        return results
    }
    
    private func parseAnthropicEvent(type: String, data: String) -> AIResponse? {
        guard let jsonData = data.data(using: .utf8) else { return nil }
        
        do {
            switch type {
            case "content_block_delta":
                let delta = try JSONDecoder().decode(AnthropicContentDelta.self, from: jsonData)
                if delta.delta.type == "text_delta",
                   let text = delta.delta.text {
                    return .textDelta(text)
                }
                
            case "message_delta":
                let delta = try JSONDecoder().decode(AnthropicMessageDelta.self, from: jsonData)
                if delta.delta.stopReason != nil {
                    return .done(usage: nil)
                }
                
            case "message_stop":
                return .done(usage: nil)
                
            case "error":
                let error = try JSONDecoder().decode(AnthropicError.self, from: jsonData)
                AppLogger.error("Anthropic API error: \(error.error.message)", category: .services)
                return nil
                
            default:
                break
            }
        } catch {
            AppLogger.error("Failed to parse Anthropic event", error: error, category: .services)
        }
        
        return nil
    }
    
    // MARK: - Gemini Parsing
    private func parseGeminiStream(_ data: Data) throws -> [AIResponse] {
        guard let string = String(data: data, encoding: .utf8) else {
            throw ServiceError.invalidResponse("Invalid UTF-8 data")
        }
        
        // Remove "data: " prefix
        let jsonString = string.replacingOccurrences(of: "data: ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !jsonString.isEmpty,
              let jsonData = jsonString.data(using: .utf8) else {
            return []
        }
        
        do {
            let response = try JSONDecoder().decode(GeminiStreamResponse.self, from: jsonData)
            return parseGeminiResponse(response)
        } catch {
            AppLogger.error("Failed to parse Gemini response", error: error, category: .services)
            return []
        }
    }
    
    private func parseGeminiResponse(_ response: GeminiStreamResponse) -> [AIResponse] {
        var results: [AIResponse] = []
        
        for candidate in response.candidates {
            // Text content
            for part in candidate.content.parts {
                if let text = part.text {
                    results.append(.textDelta(text))
                }
                
                // Function call
                if let functionCall = part.functionCall {
                    // Parse arguments to create AIFunctionCall
                    if let args = functionCall.args,
                       let argsData = args.data(using: .utf8),
                       let argsDict = try? JSONSerialization.jsonObject(with: argsData) as? [String: Any] {
                        results.append(.functionCall(AIFunctionCall(name: functionCall.name, arguments: argsDict)))
                    } else {
                        results.append(.functionCall(AIFunctionCall(name: functionCall.name, arguments: [:])))
                    }
                }
            }
            
            // Check finish reason
            if let finishReason = candidate.finishReason,
               finishReason == "STOP" || finishReason == "MAX_TOKENS" {
                results.append(.done(usage: nil))
            }
        }
        
        return results
    }
    
    // MARK: - Buffer Management
    private struct ResponseBuffer {
        var text: String = ""
        var functionCalls: [String: PartialFunctionCall] = [:]
        
        struct PartialFunctionCall {
            var name: String?
            var arguments: String = ""
        }
    }
}

// MARK: - Response Models

// OpenAI/OpenRouter
private struct OpenAIStreamResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let delta: Delta
        let finishReason: String?
        
        struct Delta: Decodable {
            let role: String?
            let content: String?
            let toolCalls: [ToolCall]?
            
            struct ToolCall: Decodable {
                let id: String?
                let type: String?
                let function: FunctionCall?
                
                struct FunctionCall: Decodable {
                    let name: String?
                    let arguments: String?
                }
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case delta
            case finishReason = "finish_reason"
        }
    }
}

// Anthropic
private struct AnthropicContentDelta: Decodable {
    let delta: Delta
    
    struct Delta: Decodable {
        let type: String
        let text: String?
    }
}

private struct AnthropicMessageDelta: Decodable {
    let delta: Delta
    
    struct Delta: Decodable {
        let stopReason: String?
        
        private enum CodingKeys: String, CodingKey {
            case stopReason = "stop_reason"
        }
    }
}

private struct AnthropicError: Decodable {
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let type: String
        let message: String
    }
}

// Gemini
struct GeminiStreamResponse: Decodable {
    let candidates: [Candidate]
    
    struct Candidate: Decodable {
        let content: Content
        let finishReason: String?
        
        struct Content: Decodable {
            let parts: [Part]
            
            struct Part: Decodable {
                let text: String?
                let functionCall: FunctionCall?
                
                struct FunctionCall: Decodable {
                    let name: String
                    let args: String?
                }
            }
        }
    }
}
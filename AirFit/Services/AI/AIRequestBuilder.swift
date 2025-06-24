import Foundation

actor AIRequestBuilder: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "ai-request-builder"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready
    
    func buildRequest(
        for aiRequest: AIRequest,
        provider: AIProvider,
        model: String,
        apiKey: String
    ) async throws -> URLRequest {
        
        let endpoint = endpoint(for: provider, model: model)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addCommonHeaders()
        request.timeoutInterval = 60 // 60 seconds for AI requests
        
        // Add authentication
        switch provider {
        case .openAI:
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
        case .anthropic:
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            
        case .gemini:
            request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        }
        
        // Build request body
        let body = try await buildRequestBody(
            for: aiRequest,
            provider: provider,
            model: model
        )
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return request
    }
    
    private func endpoint(for provider: AIProvider, model: String) -> URL {
        switch provider {
        case .openAI:
            return provider.baseURL.appendingPathComponent("chat/completions")
            
        case .anthropic:
            return provider.baseURL.appendingPathComponent("messages")
            
        case .gemini:
            let url = provider.baseURL
                .appendingPathComponent("v1beta")
                .appendingPathComponent("models")
                .appendingPathComponent("\(model):streamGenerateContent")
            
            // Add SSE query parameter
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "alt", value: "sse")]
            return components.url!
            
        }
    }
    
    private func buildRequestBody(
        for request: AIRequest,
        provider: AIProvider,
        model: String
    ) async throws -> [String: Any] {
        
        switch provider {
        case .openAI:
            return buildOpenAIRequestBody(request: request, model: model)
            
        case .anthropic:
            return buildAnthropicRequestBody(request: request, model: model)
            
        case .gemini:
            return buildGeminiRequestBody(request: request, model: model)
        }
    }
    
    private func buildOpenAIRequestBody(
        request: AIRequest,
        model: String
    ) -> [String: Any] {
        var messages: [[String: Any]] = []
        
        // Add all messages
        for message in request.messages {
            var msgDict: [String: Any] = [
                "role": message.role.rawValue,
                "content": message.content
            ]
            if let name = message.name {
                msgDict["name"] = name
            }
            messages.append(msgDict)
        }
        
        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": request.stream,
            "temperature": request.temperature,
            "max_tokens": request.maxTokens ?? 2_048
        ]
        
        // Add functions if available
        if let functions = request.functions {
            body["tools"] = functions.map { function in
                [
                    "type": "function",
                    "function": [
                        "name": function.name,
                        "description": function.description,
                        "parameters": function.parameters
                    ]
                ]
            }
            body["tool_choice"] = "auto"
        }
        
        return body
    }
    
    private func buildAnthropicRequestBody(
        request: AIRequest,
        model: String
    ) -> [String: Any] {
        var messages: [[String: Any]] = []
        var systemPrompt: String?
        
        // Extract system prompt and convert messages
        for message in request.messages {
            if message.role == .system {
                systemPrompt = message.content
            } else {
                messages.append([
                    "role": message.role == .assistant ? "assistant" : "user",
                    "content": message.content
                ])
            }
        }
        
        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": request.stream,
            "max_tokens": request.maxTokens ?? 2_048
        ]
        
        let systemToUse = systemPrompt ?? request.systemPrompt
        if !systemToUse.isEmpty {
            body["system"] = systemToUse
        }
        
        body["temperature"] = request.temperature
        
        // Add tools if available
        if let functions = request.functions {
            body["tools"] = functions.map { function in
                [
                    "name": function.name,
                    "description": function.description,
                    "input_schema": function.parameters
                ]
            }
        }
        
        return body
    }
    
    private func buildGeminiRequestBody(
        request: AIRequest,
        model: String
    ) -> [String: Any] {
        var contents: [[String: Any]] = []
        var systemInstruction: String?
        
        // Convert messages to Gemini format
        for message in request.messages {
            if message.role == .system {
                systemInstruction = message.content
            } else {
                contents.append([
                    "role": message.role == .assistant ? "model" : "user",
                    "parts": [["text": message.content]]
                ])
            }
        }
        
        var body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": request.temperature,
                "maxOutputTokens": request.maxTokens ?? 2_048,
                "topP": 0.95,
                "topK": 20
            ]
        ]
        
        let systemToUse = systemInstruction ?? request.systemPrompt
        if !systemToUse.isEmpty {
            body["systemInstruction"] = [
                "parts": [["text": systemToUse]]
            ]
        }
        
        // Add tools if available
        if let functions = request.functions {
            body["tools"] = [[
                "functionDeclarations": functions.map { function in
                    [
                        "name": function.name,
                        "description": function.description,
                        "parameters": function.parameters
                    ]
                }
            ]]
        }
        
        // Add grounding (Google Search) if requested
        if request.enableGrounding == true {
            var tools = body["tools"] as? [[String: Any]] ?? []
            tools.append([
                "googleSearchRetrieval": [
                    "dynamicRetrievalConfig": [
                        "mode": "MODE_DYNAMIC",
                        "dynamicThreshold": 0.3
                    ]
                ]
            ])
            body["tools"] = tools
        }
        
        return body
    }
}

// MARK: - Function Schema Helper

extension AIRequest {
    struct FunctionSchema: Codable {
        let name: String
        let description: String
        let parameters: [String: Any]
        
        enum CodingKeys: String, CodingKey {
            case name, description, parameters
        }
        
        init(name: String, description: String, parameters: [String: Any]) {
            self.name = name
            self.description = description
            self.parameters = parameters
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            description = try container.decode(String.self, forKey: .description)
            // For decoding, we'll need custom handling of the parameters dictionary
            parameters = [:]
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(description, forKey: .description)
            // For encoding, we'll need custom handling of the parameters dictionary
        }
    }
}

// MARK: - ServiceProtocol Extension

extension AIRequestBuilder {
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
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: [
                "providersSupported": "openai,anthropic,gemini"
            ]
        )
    }
}

import Foundation
@testable import AirFit

/// Test data generators for service layer testing
enum TestDataGenerators {
    
    // MARK: - AI Request Generators
    
    static func makeAIRequest(
        systemPrompt: String = "You are a helpful assistant",
        userMessage: String = "Hello, how are you?",
        temperature: Double = 0.7,
        maxTokens: Int? = 2048,
        stream: Bool = true,
        functions: [AIFunctionDefinition]? = nil
    ) -> AIRequest {
        AIRequest(
            systemPrompt: systemPrompt,
            messages: [
                AIChatMessage(role: .system, content: systemPrompt),
                AIChatMessage(role: .user, content: userMessage)
            ],
            functions: functions,
            temperature: temperature,
            maxTokens: maxTokens,
            stream: stream,
            user: "test-user"
        )
    }
    
    static func makeConversationRequest(
        messages: [(role: AIMessageRole, content: String)],
        functions: [AIFunctionDefinition]? = nil
    ) -> AIRequest {
        let chatMessages = messages.map { AIChatMessage(role: $0.role, content: $0.content) }
        
        return AIRequest(
            systemPrompt: "You are a helpful AI assistant",
            messages: chatMessages,
            functions: functions,
            temperature: 0.7,
            maxTokens: nil,
            stream: true,
            user: "test-user"
        )
    }
    
    // MARK: - AI Function Definition Generators
    
    static func makeAIFunctionDefinition(
        name: String,
        description: String,
        properties: [String: AIParameterDefinition] = [:],
        required: [String] = []
    ) -> AIFunctionDefinition {
        AIFunctionDefinition(
            name: name,
            description: description,
            parameters: AIFunctionParameters(
                properties: properties,
                required: required
            )
        )
    }
    
    // MARK: - AI Response Generators
    
    static func makeStreamingResponses(text: String, chunkSize: Int = 10) -> [AIResponse] {
        var responses: [AIResponse] = []
        
        let words = text.split(separator: " ")
        var currentChunk = ""
        
        for word in words {
            currentChunk += word + " "
            if currentChunk.count >= chunkSize {
                responses.append(.textDelta(currentChunk))
                currentChunk = ""
            }
        }
        
        if !currentChunk.isEmpty {
            responses.append(.textDelta(currentChunk))
        }
        
        responses.append(.done(usage: AITokenUsage(
            promptTokens: text.count / 4,
            completionTokens: text.count / 4,
            totalTokens: text.count / 2
        )))
        
        return responses
    }
    
    static func makeFunctionCallResponse(
        functionName: String,
        arguments: [String: Any]
    ) -> [AIResponse] {
        let functionCall = AIFunctionCall(name: functionName, arguments: arguments)
        
        return [
            .functionCall(functionCall),
            .done(usage: AITokenUsage(promptTokens: 50, completionTokens: 25, totalTokens: 75))
        ]
    }
    
    // MARK: - Weather Data Generators
    
    static func makeWeatherData(
        temperature: Double = 72.0,
        condition: WeatherCondition = .partlyCloudy,
        location: String = "New York",
        humidity: Double = 65.0,
        windSpeed: Double = 10.0
    ) -> ServiceWeatherData {
        ServiceWeatherData(
            temperature: temperature,
            condition: condition,
            humidity: humidity,
            windSpeed: windSpeed,
            location: location,
            timestamp: Date()
        )
    }
    
    static func makeWeatherForecast(
        location: String = "New York",
        days: Int = 5,
        baseTemp: Double = 70.0
    ) -> WeatherForecast {
        var dailyForecasts: [DailyForecast] = []
        for dayOffset in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!
            let highTemp = baseTemp + Double(dayOffset * 2)
            let lowTemp = baseTemp - 10 + Double(dayOffset)
            let condition: WeatherCondition = dayOffset % 3 == 0 ? .rain : .partlyCloudy
            let precipChance = dayOffset % 3 == 0 ? 80.0 : 20.0
            
            let forecast = DailyForecast(
                date: date,
                highTemperature: highTemp,
                lowTemperature: lowTemp,
                condition: condition,
                precipitationChance: precipChance
            )
            dailyForecasts.append(forecast)
        }
        
        return WeatherForecast(
            daily: dailyForecasts,
            location: location
        )
    }
    
    // MARK: - Network Response Generators
    
    static func makeHTTPURLResponse(
        statusCode: Int = 200,
        headers: [String: String]? = nil
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.example.com")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
    }
    
    static func makeSSEData(_ content: String, event: String? = nil) -> Data {
        var sseString = ""
        if let event = event {
            sseString += "event: \(event)\n"
        }
        sseString += "data: \(content)\n\n"
        return sseString.data(using: .utf8)!
    }
    
    // MARK: - OpenAI Response Generators
    
    static func makeOpenAIStreamData(content: String? = nil, functionCall: (name: String, args: String)? = nil, done: Bool = false) -> Data {
        if done {
            return "data: [DONE]\n\n".data(using: .utf8)!
        }
        
        var response: [String: Any] = [
            "choices": [[
                "delta": [:] as [String: Any],
                "index": 0
            ]]
        ]
        
        if let content = content {
            if var choices = response["choices"] as? [[String: Any]],
               !choices.isEmpty {
                choices[0]["delta"] = ["content": content]
                response["choices"] = choices
            }
        }
        
        if let (name, args) = functionCall {
            if var choices = response["choices"] as? [[String: Any]],
               !choices.isEmpty {
                choices[0]["delta"] = [
                    "tool_calls": [[
                        "function": [
                            "name": name,
                            "arguments": args
                        ]
                    ]]
                ]
                response["choices"] = choices
            }
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return "data: \(jsonString)\n\n".data(using: .utf8)!
    }
    
    // MARK: - Anthropic Response Generators
    
    static func makeAnthropicStreamData(
        event: String,
        content: String? = nil,
        stopReason: String? = nil
    ) -> Data {
        var data: [String: Any] = [:]
        
        switch event {
        case "content_block_delta":
            data = [
                "delta": [
                    "type": "text_delta",
                    "text": content ?? ""
                ]
            ]
        case "message_delta":
            if let reason = stopReason {
                data = [
                    "delta": [
                        "stop_reason": reason
                    ]
                ]
            } else {
                data = [
                    "delta": [:]
                ]
            }
        case "message_stop":
            data = [:]
        default:
            break
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: data)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        return "event: \(event)\ndata: \(jsonString)\n\n".data(using: .utf8)!
    }
    
    // MARK: - Gemini Response Generators
    
    static func makeGeminiStreamData(
        text: String? = nil,
        functionCall: (name: String, args: [String: Any])? = nil,
        finishReason: String? = nil
    ) -> Data {
        var parts: [[String: Any]] = []
        
        if let text = text {
            parts.append(["text": text])
        }
        
        if let (name, args) = functionCall {
            parts.append([
                "functionCall": [
                    "name": name,
                    "args": args
                ]
            ])
        }
        
        let response: [String: Any] = [
            "candidates": [[
                "content": ["parts": parts],
                "finishReason": finishReason as Any
            ]]
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: response)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return "data: \(jsonString)\n\n".data(using: .utf8)!
    }
    
    // MARK: - Error Response Generators
    
    static func makeErrorResponse(
        provider: AIProvider,
        code: String,
        message: String
    ) -> Data {
        let errorData: [String: Any]
        
        switch provider {
        case .openAI:
            errorData = [
                "error": [
                    "type": code,
                    "message": message
                ]
            ]
        case .anthropic:
            errorData = [
                "error": [
                    "type": code,
                    "message": message
                ]
            ]
        case .gemini:
            errorData = [
                "error": [
                    "code": code,
                    "message": message
                ]
            ]
        }
        
        return try! JSONSerialization.data(withJSONObject: errorData)
    }
    
    // MARK: - Service Health Generators
    
    static func makeServiceHealth(
        status: ServiceHealth.Status = .healthy,
        responseTime: TimeInterval? = 0.1,
        errorMessage: String? = nil
    ) -> ServiceHealth {
        ServiceHealth(
            status: status,
            lastCheckTime: Date(),
            responseTime: responseTime,
            errorMessage: errorMessage,
            metadata: ["test": "true"]
        )
    }
    
    // MARK: - User Profile Generators
    
    static func makeOnboardingProfile(
        name: String = "Test User"
    ) -> OnboardingProfile {
        let profile = OnboardingProfile(
            personaPromptData: Data(),
            communicationPreferencesData: Data(),
            rawFullProfileData: Data()
        )
        profile.name = name
        profile.isComplete = true
        return profile
    }
}

// MARK: - Legacy Test Support
// These extensions help migrate old tests that use deprecated FunctionSchema

extension AIRequest {
    /// Helper for tests that still use old FunctionSchema format
    static func createTestRequest(
        systemPrompt: String = "You are a helpful assistant",
        userMessage: String = "Hello",
        temperature: Double = 0.7,
        maxTokens: Int? = 2048,
        stream: Bool = true,
        functionSchemas: [FunctionSchema]? = nil
    ) -> AIRequest {
        let functions = functionSchemas?.map { schema in
            AIFunctionDefinition(
                name: schema.name,
                description: schema.description,
                parameters: AIFunctionParameters(properties: [:], required: [])
            )
        }
        
        return TestDataGenerators.makeAIRequest(
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            temperature: temperature,
            maxTokens: maxTokens,
            stream: stream,
            functions: functions
        )
    }
}

// MARK: - Function Schema Helper (Legacy)
// Note: This is a test-only type for backward compatibility

struct FunctionSchema: Codable {
    let name: String
    let description: String
    let parameters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name, description, parameters
    }
    
    init(name: String, description: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        parameters = [:] // Simplified for testing
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        // Simplified encoding for testing
    }
}
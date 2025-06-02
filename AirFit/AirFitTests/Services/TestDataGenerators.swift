import Foundation
@testable import AirFit

/// Test data generators for service layer testing
enum TestDataGenerators {
    
    // MARK: - AI Request Generators
    
    static func makeAIRequest(
        systemPrompt: String = "You are a helpful assistant",
        userMessage: String = "Hello, how are you?",
        model: String? = nil,
        temperature: Double? = 0.7,
        maxTokens: Int? = 2048,
        stream: Bool = true,
        functions: [FunctionSchema]? = nil
    ) -> AIRequest {
        AIRequest(
            messages: [
                AIMessage(role: .system, content: systemPrompt, name: nil),
                AIMessage(role: .user, content: userMessage, name: nil)
            ],
            model: model,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens,
            temperature: temperature,
            stream: stream,
            functions: functions
        )
    }
    
    static func makeConversationRequest(
        messages: [(role: AIMessageRole, content: String)],
        functions: [FunctionSchema]? = nil
    ) -> AIRequest {
        let aiMessages = messages.map { AIMessage(role: $0.role, content: $0.content, name: nil) }
        
        return AIRequest(
            messages: aiMessages,
            model: nil,
            systemPrompt: "You are a helpful AI assistant",
            maxTokens: nil,
            temperature: nil,
            stream: true,
            functions: functions
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
        
        responses.append(.done(usage: AIUsage(
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
        let jsonData = try! JSONSerialization.data(withJSONObject: arguments)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        return [
            .functionCall(name: functionName, arguments: jsonString),
            .done(usage: AIUsage(promptTokens: 50, completionTokens: 25, totalTokens: 75))
        ]
    }
    
    // MARK: - Weather Data Generators
    
    static func makeWeatherData(
        temperature: Double = 72.0,
        condition: WeatherCondition = .partlyCloudy,
        location: String = "New York",
        humidity: Double = 65.0,
        windSpeed: Double = 10.0
    ) -> WeatherData {
        WeatherData(
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
        let dailyForecasts = (0..<days).map { dayOffset in
            DailyForecast(
                date: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!,
                highTemperature: baseTemp + Double(dayOffset * 2),
                lowTemperature: baseTemp - 10 + Double(dayOffset),
                condition: dayOffset % 3 == 0 ? .rain : .partlyCloudy,
                precipitationChance: dayOffset % 3 == 0 ? 80.0 : 20.0
            )
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
            (response["choices"] as! [[String: Any]])[0]["delta"] = ["content": content]
        }
        
        if let (name, args) = functionCall {
            (response["choices"] as! [[String: Any]])[0]["delta"] = [
                "tool_calls": [[
                    "function": [
                        "name": name,
                        "arguments": args
                    ]
                ]]
            ]
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
            data = [
                "delta": [
                    "stop_reason": stopReason ?? NSNull()
                ]
            ]
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
                "finishReason": finishReason ?? NSNull()
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
        case .openAI, .openRouter:
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
        case .googleGemini:
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
        name: String = "Test User",
        age: Int = 30,
        fitnessLevel: FitnessLevel = .intermediate
    ) -> OnboardingProfile {
        OnboardingProfile(
            name: name,
            age: age,
            gender: .male,
            height: 175,
            weight: 75,
            fitnessLevel: fitnessLevel,
            primaryGoal: .generalFitness,
            workoutFrequency: 3,
            dietaryRestrictions: [],
            healthConditions: [],
            preferredWorkoutTime: .morning,
            equipmentAccess: [.gym, .home]
        )
    }
}

// MARK: - Function Schema Helper

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
        parameters = [:] // Simplified for testing
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        // Simplified encoding for testing
    }
}
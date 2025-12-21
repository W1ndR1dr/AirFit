import Foundation
import SwiftData
import UIKit

/// Direct Gemini API client for iOS.
///
/// Calls Gemini 3 Flash Preview directly from the device using the user's API key.
/// Supports text chat, streaming responses, multimodal image analysis, and function calling.
///
/// ## Function Calling (Tool Use)
/// When tools are enabled, Gemini can request data queries (workouts, nutrition, etc.)
/// which are executed via the AirFit server's /tools/execute endpoint.
/// This enables "Tier 3" deep queries without pre-loading all context.
actor GeminiService {
    // MARK: - Singleton

    static let shared = GeminiService()

    // MARK: - Configuration

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-3-flash-preview"
    private let keychainManager = KeychainManager.shared

    /// Maximum function call iterations to prevent infinite loops
    private let maxToolIterations = 5

    // MARK: - Context Caching State

    /// Current cached context name (e.g., "cachedContents/abc123")
    private var cachedContentName: String?

    /// When the cache expires (default TTL is 1 hour)
    private var cacheExpiry: Date?

    /// Hash of the content that was cached (to detect when we need to refresh)
    private var cachedContentHash: Int?

    /// Whether caching is available (may fail on free tier due to rate limits)
    private var cachingAvailable = true

    // MARK: - Types

    struct GeminiError: LocalizedError {
        let message: String
        let code: Int?

        var errorDescription: String? { message }

        static let noAPIKey = GeminiError(message: "No Gemini API key configured. Add your key in Settings.", code: nil)
        static let invalidResponse = GeminiError(message: "Invalid response from Gemini API", code: nil)
        static let emptyResponse = GeminiError(message: "Empty response from Gemini API", code: nil)
    }

    // MARK: - Connection Test

    /// Test if the API key is valid by making a minimal API call.
    /// Returns true if the key works, false otherwise.
    func testConnection() async -> Bool {
        guard let apiKey = await keychainManager.getGeminiAPIKey() else {
            return false
        }

        // Use the models list endpoint - minimal quota usage
        let url = URL(string: "\(baseURL)/models?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }

    // MARK: - Chat (Non-Streaming)

    /// Send a chat message and get a complete response.
    ///
    /// - Parameters:
    ///   - message: The user's message
    ///   - history: Previous conversation messages for context
    ///   - systemPrompt: System instructions for the AI
    ///   - dataContext: Rich context data (health, nutrition, workouts)
    ///   - thinkingLevel: How much reasoning depth to use (default: medium)
    /// - Returns: The AI's response text
    func chat(
        message: String,
        history: [ConversationMessage] = [],
        systemPrompt: String,
        dataContext: String? = nil,
        thinkingLevel: ThinkingLevel = .medium
    ) async throws -> String {
        guard let apiKey = await keychainManager.getGeminiAPIKey() else {
            throw GeminiError.noAPIKey
        }

        let url = URL(string: "\(baseURL)/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        // Build the full system instruction (persona + context)
        var fullSystemPrompt = systemPrompt
        if let context = dataContext, !context.isEmpty {
            fullSystemPrompt += "\n\n--- CURRENT CONTEXT ---\n\(context)"
        }

        // Build request body (no tools for simple chat)
        let body = GeminiRequest(
            systemInstruction: GeminiContent(parts: [GeminiPart(text: fullSystemPrompt)]),
            contents: buildContents(message: message, history: history),
            generationConfig: GeminiGenerationConfig(
                maxOutputTokens: 8192,
                temperature: 0.9,
                thinkingConfig: thinkingLevel.config
            ),
            tools: nil
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
            throw GeminiError(message: errorMessage, code: httpResponse.statusCode)
        }

        // Parse response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }

        return text
    }

    // MARK: - Streaming Chat

    /// Send a chat message and receive streaming response chunks.
    ///
    /// - Parameters:
    ///   - message: The user's message
    ///   - history: Previous conversation messages
    ///   - systemPrompt: System instructions
    ///   - dataContext: Rich context data
    ///   - thinkingLevel: How much reasoning depth to use (default: medium)
    /// - Returns: AsyncThrowingStream of text chunks
    func streamChat(
        message: String,
        history: [ConversationMessage] = [],
        systemPrompt: String,
        dataContext: String? = nil,
        thinkingLevel: ThinkingLevel = .medium
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let apiKey = await keychainManager.getGeminiAPIKey() else {
                        continuation.finish(throwing: GeminiError.noAPIKey)
                        return
                    }

                    let url = URL(string: "\(baseURL)/models/\(model):streamGenerateContent?alt=sse")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

                    var fullSystemPrompt = systemPrompt
                    if let context = dataContext, !context.isEmpty {
                        fullSystemPrompt += "\n\n--- CURRENT CONTEXT ---\n\(context)"
                    }

                    let body = GeminiRequest(
                        systemInstruction: GeminiContent(parts: [GeminiPart(text: fullSystemPrompt)]),
                        contents: buildContents(message: message, history: history),
                        generationConfig: GeminiGenerationConfig(
                            maxOutputTokens: 8192,
                            temperature: 0.9,
                            thinkingConfig: thinkingLevel.config
                        ),
                        tools: nil  // Streaming doesn't support function calling
                    )

                    request.httpBody = try JSONEncoder().encode(body)

                    // Use URLSession bytes for streaming
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        continuation.finish(throwing: GeminiError(message: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode))
                        return
                    }

                    // Parse SSE stream
                    for try await line in bytes.lines {
                        // SSE format: data: {json}
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        guard let jsonData = jsonString.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(GeminiStreamChunk.self, from: jsonData),
                              let text = chunk.candidates?.first?.content?.parts?.first?.text else {
                            continue
                        }

                        continuation.yield(text)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Image Analysis

    /// Analyze an image (e.g., food photo for nutrition estimation).
    ///
    /// - Parameters:
    ///   - imageData: JPEG or PNG image data
    ///   - prompt: What to analyze in the image
    ///   - systemPrompt: System instructions
    ///   - thinkingLevel: How much reasoning depth to use (default: medium)
    /// - Returns: The AI's analysis
    func analyzeImage(
        imageData: Data,
        prompt: String,
        systemPrompt: String,
        thinkingLevel: ThinkingLevel = .medium
    ) async throws -> String {
        guard let apiKey = await keychainManager.getGeminiAPIKey() else {
            throw GeminiError.noAPIKey
        }

        let url = URL(string: "\(baseURL)/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        // Determine MIME type (assume JPEG if we can't tell)
        let mimeType = detectMimeType(from: imageData)

        // Build multimodal content
        let imagePart = GeminiPart(
            text: nil,
            inlineData: GeminiInlineData(
                mimeType: mimeType,
                data: imageData.base64EncodedString()
            )
        )
        let textPart = GeminiPart(text: prompt)

        let body = GeminiRequest(
            systemInstruction: GeminiContent(parts: [GeminiPart(text: systemPrompt)]),
            contents: [GeminiContent(role: "user", parts: [imagePart, textPart])],
            generationConfig: GeminiGenerationConfig(
                maxOutputTokens: 4096,
                temperature: 0.7,
                thinkingConfig: thinkingLevel.config
            ),
            tools: nil  // Image analysis doesn't use function calling
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
            throw GeminiError(message: errorMessage, code: httpResponse.statusCode)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }

        return text
    }

    /// Compress and prepare an image for API upload.
    ///
    /// Gemini accepts up to 20MB per request. This ensures images are reasonably sized.
    func prepareImage(_ image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        // Resize if needed
        let resized: UIImage
        if max(image.size.width, image.size.height) > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resized = image
        }

        // Compress as JPEG
        return resized.jpegData(compressionQuality: 0.8)
    }

    // MARK: - Nutrition Parsing

    /// Parse food text into nutrition data.
    /// Used for direct Gemini mode (no server needed).
    ///
    /// - Parameter foodText: Description of food (e.g., "2 eggs and toast with butter")
    /// - Returns: Parsed nutrition result with macros
    func parseNutrition(_ foodText: String) async throws -> NutritionParseResult {
        let systemPrompt = """
        You are a nutrition parser. Given a food description, return ONLY a JSON object with:
        - name: cleaned, properly formatted food name
        - calories: estimated total calories (integer)
        - protein: grams of protein (integer)
        - carbs: grams of carbohydrates (integer)
        - fat: grams of fat (integer)
        - confidence: "high", "medium", or "low"

        Rules:
        - If quantities given (e.g., "2 eggs"), calculate totals for that quantity
        - If ambiguous, use typical serving sizes
        - Round all numbers to integers
        - Return ONLY valid JSON, no markdown, no explanation, no code blocks
        """

        // Use low thinking for simple parsing tasks
        let response = try await chat(
            message: "Parse this food: \(foodText)",
            history: [],
            systemPrompt: systemPrompt,
            thinkingLevel: .low
        )

        // Clean the response (remove any markdown code blocks if present)
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to extract JSON if wrapped in other text
        if let startIndex = cleanedResponse.firstIndex(of: "{"),
           let endIndex = cleanedResponse.lastIndex(of: "}") {
            cleanedResponse = String(cleanedResponse[startIndex...endIndex])
        }

        guard let jsonData = cleanedResponse.data(using: .utf8) else {
            throw GeminiError(message: "Failed to parse nutrition response as UTF-8", code: nil)
        }

        do {
            return try JSONDecoder().decode(NutritionParseResult.self, from: jsonData)
        } catch {
            throw GeminiError(message: "Failed to parse nutrition JSON: \(error.localizedDescription)", code: nil)
        }
    }

    // MARK: - Context Caching

    /// Create or refresh a context cache for the given system prompt and context.
    ///
    /// Gemini 3 context caching reduces latency and cost by pre-processing
    /// the system instructions. The cache persists for 1 hour by default.
    ///
    /// - Parameters:
    ///   - systemPrompt: The AI persona/instructions
    ///   - dataContext: Rich context data (health, nutrition, profile)
    /// - Returns: Cache name if successful, nil if caching unavailable/failed
    func createContextCache(
        systemPrompt: String,
        dataContext: String?
    ) async -> String? {
        // Skip if caching disabled due to previous failures
        guard cachingAvailable else { return nil }

        guard let apiKey = await keychainManager.getGeminiAPIKey() else { return nil }

        // Build the full content to cache
        var fullContent = systemPrompt
        if let context = dataContext, !context.isEmpty {
            fullContent += "\n\n--- CURRENT CONTEXT ---\n\(context)"
        }

        // Check if we already have a valid cache for this content
        let contentHash = fullContent.hashValue
        if let existingCache = cachedContentName,
           let expiry = cacheExpiry,
           expiry > Date(),
           cachedContentHash == contentHash {
            // Cache is still valid for the same content
            return existingCache
        }

        // Create new cache
        let url = URL(string: "\(baseURL)/cachedContents")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let cacheRequest = CachedContentRequest(
            model: "models/\(model)",
            systemInstruction: CachedContentParts(parts: [CachedContentPart(text: fullContent)]),
            ttl: "3600s"  // 1 hour TTL
        )

        do {
            request.httpBody = try JSONEncoder().encode(cacheRequest)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // Parse the cache name from response
                    let cacheResponse = try JSONDecoder().decode(CachedContentResponse.self, from: data)

                    // Store cache info
                    cachedContentName = cacheResponse.name
                    cacheExpiry = Date().addingTimeInterval(3600)  // 1 hour from now
                    cachedContentHash = contentHash

                    print("[GeminiService] Context cache created: \(cacheResponse.name)")
                    return cacheResponse.name

                } else if httpResponse.statusCode == 429 {
                    // Rate limited - disable caching for this session
                    print("[GeminiService] Context caching rate limited, disabling for session")
                    cachingAvailable = false
                    return nil

                } else {
                    // Other error - log but don't disable caching
                    let errorMsg = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
                    print("[GeminiService] Cache creation failed: \(errorMsg)")
                    return nil
                }
            }
        } catch {
            print("[GeminiService] Cache creation error: \(error.localizedDescription)")
        }

        return nil
    }

    /// Check if current cache is valid for the given content.
    func isCacheValid(for systemPrompt: String, dataContext: String?) -> Bool {
        guard let expiry = cacheExpiry, expiry > Date() else { return false }

        var fullContent = systemPrompt
        if let context = dataContext, !context.isEmpty {
            fullContent += "\n\n--- CURRENT CONTEXT ---\n\(context)"
        }

        return cachedContentHash == fullContent.hashValue
    }

    /// Invalidate the current cache (e.g., when context changes significantly).
    func invalidateCache() {
        cachedContentName = nil
        cacheExpiry = nil
        cachedContentHash = nil
    }

    /// Chat using cached context for improved latency.
    ///
    /// If a valid cache exists, uses it. Otherwise falls back to regular chat.
    /// Optionally creates a new cache for future calls.
    ///
    /// - Parameters:
    ///   - message: The user's message
    ///   - history: Previous conversation messages
    ///   - systemPrompt: System instructions (will use cache if available)
    ///   - dataContext: Rich context data
    ///   - thinkingLevel: Reasoning depth
    ///   - createCacheIfNeeded: Whether to create a cache if none exists
    /// - Returns: The AI's response text
    func chatWithCache(
        message: String,
        history: [ConversationMessage] = [],
        systemPrompt: String,
        dataContext: String? = nil,
        thinkingLevel: ThinkingLevel = .medium,
        createCacheIfNeeded: Bool = true
    ) async throws -> String {
        guard let apiKey = await keychainManager.getGeminiAPIKey() else {
            throw GeminiError.noAPIKey
        }

        // Try to get or create cache
        var cacheName: String?
        if isCacheValid(for: systemPrompt, dataContext: dataContext) {
            cacheName = cachedContentName
        } else if createCacheIfNeeded {
            cacheName = await createContextCache(systemPrompt: systemPrompt, dataContext: dataContext)
        }

        let url = URL(string: "\(baseURL)/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        // If we have a cache, use it (no systemInstruction needed)
        // Otherwise, fall back to regular approach
        let body: GeminiRequest
        if let cache = cacheName {
            body = GeminiRequest(
                systemInstruction: nil,  // Using cached content instead
                contents: buildContents(message: message, history: history),
                generationConfig: GeminiGenerationConfig(
                    maxOutputTokens: 8192,
                    temperature: 0.9,
                    thinkingConfig: thinkingLevel.config
                ),
                tools: nil,
                cachedContent: cache
            )
        } else {
            // No cache - use regular approach
            var fullSystemPrompt = systemPrompt
            if let context = dataContext, !context.isEmpty {
                fullSystemPrompt += "\n\n--- CURRENT CONTEXT ---\n\(context)"
            }

            body = GeminiRequest(
                systemInstruction: GeminiContent(parts: [GeminiPart(text: fullSystemPrompt)]),
                contents: buildContents(message: message, history: history),
                generationConfig: GeminiGenerationConfig(
                    maxOutputTokens: 8192,
                    temperature: 0.9,
                    thinkingConfig: thinkingLevel.config
                ),
                tools: nil,
                cachedContent: nil
            )
        }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
            throw GeminiError(message: errorMessage, code: httpResponse.statusCode)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.emptyResponse
        }

        return text
    }

    // MARK: - Chat with Function Calling

    /// AirFit tool definitions for Gemini function calling.
    /// These match the schemas from the server's /tools/schemas endpoint.
    private var airfitTools: [GeminiTool] {
        let declarations = [
            GeminiFunctionDeclaration(
                name: "query_workouts",
                description: "Query workout history from Hevy. Use when user asks about specific exercises, training history, volume, or PRs.",
                parameters: GeminiFunctionParameters(
                    properties: [
                        "exercise": GeminiFunctionProperty(type: "string", description: "Filter by exercise name (e.g., 'bench press', 'squat')"),
                        "muscle_group": GeminiFunctionProperty(type: "string", description: "Filter by muscle group (e.g., 'chest', 'back', 'legs')"),
                        "days": GeminiFunctionProperty(type: "integer", description: "Number of days to query (1-90, default 14)")
                    ]
                )
            ),
            GeminiFunctionDeclaration(
                name: "query_nutrition",
                description: "Query nutrition history. Use when user asks about eating patterns, macro trends, or compliance.",
                parameters: GeminiFunctionParameters(
                    properties: [
                        "days": GeminiFunctionProperty(type: "integer", description: "Number of days to query (1-30, default 7)"),
                        "include_meals": GeminiFunctionProperty(type: "boolean", description: "Include individual meal entries (default false)")
                    ]
                )
            ),
            GeminiFunctionDeclaration(
                name: "query_body_comp",
                description: "Query body composition trends. Use when user asks about weight, body fat, or lean mass progress.",
                parameters: GeminiFunctionParameters(
                    properties: [
                        "days": GeminiFunctionProperty(type: "integer", description: "Number of days to query (30-365, default 90)")
                    ]
                )
            ),
            GeminiFunctionDeclaration(
                name: "query_recovery",
                description: "Query recovery metrics. Use when user mentions sleep, HRV, fatigue, or readiness.",
                parameters: GeminiFunctionParameters(
                    properties: [
                        "days": GeminiFunctionProperty(type: "integer", description: "Number of days to query (7-30, default 14)")
                    ]
                )
            ),
            GeminiFunctionDeclaration(
                name: "query_insights",
                description: "Query AI-generated insights. Use when user asks about patterns, correlations, or 'what have you noticed'.",
                parameters: GeminiFunctionParameters(
                    properties: [
                        "category": GeminiFunctionProperty(
                            type: "string",
                            description: "Filter by insight category",
                            enumValues: ["correlation", "trend", "anomaly", "milestone", "nudge"]
                        ),
                        "limit": GeminiFunctionProperty(type: "integer", description: "Max insights to return (1-10, default 5)")
                    ]
                )
            )
        ]

        return [GeminiTool(functionDeclarations: declarations)]
    }

    /// Send a chat message with function calling enabled.
    ///
    /// This enables Tier 3 "deep queries" - Gemini can request detailed data
    /// by calling tools, which are executed via the AirFit server.
    ///
    /// - Parameters:
    ///   - message: The user's message
    ///   - history: Previous conversation messages
    ///   - systemPrompt: System instructions
    ///   - dataContext: Tier 1/2 context data
    ///   - serverURL: AirFit server URL for tool execution
    ///   - thinkingLevel: How much reasoning depth to use (default: high for complex queries)
    /// - Returns: The AI's response text
    func chatWithTools(
        message: String,
        history: [ConversationMessage] = [],
        systemPrompt: String,
        dataContext: String? = nil,
        serverURL: URL,
        thinkingLevel: ThinkingLevel = .high
    ) async throws -> String {
        guard let apiKey = await keychainManager.getGeminiAPIKey() else {
            throw GeminiError.noAPIKey
        }

        let url = URL(string: "\(baseURL)/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        // Build system prompt with context
        var fullSystemPrompt = systemPrompt
        if let context = dataContext, !context.isEmpty {
            fullSystemPrompt += "\n\n--- CURRENT CONTEXT ---\n\(context)"
        }

        // Initialize conversation contents
        var contents = buildContents(message: message, history: history)

        // Function calling loop
        for _ in 0..<maxToolIterations {
            let body = GeminiRequest(
                systemInstruction: GeminiContent(parts: [GeminiPart(text: fullSystemPrompt)]),
                contents: contents,
                generationConfig: GeminiGenerationConfig(
                    maxOutputTokens: 8192,
                    temperature: 0.9,
                    thinkingConfig: thinkingLevel.config
                ),
                tools: airfitTools
            )

            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMessage = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
                throw GeminiError(message: errorMessage, code: httpResponse.statusCode)
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            guard let candidate = geminiResponse.candidates?.first,
                  let parts = candidate.content?.parts else {
                throw GeminiError.emptyResponse
            }

            // Check if response contains a function call
            if let functionCall = parts.first(where: { $0.functionCall != nil })?.functionCall {
                // Execute the tool via server
                let toolResult = try await executeToolOnServer(
                    name: functionCall.name,
                    args: functionCall.args ?? [:],
                    serverURL: serverURL
                )

                // Add the assistant's function call to contents
                contents.append(GeminiContent(
                    role: "model",
                    parts: parts
                ))

                // Add the function response
                let functionResponse = GeminiFunctionResponse(
                    name: functionCall.name,
                    response: GeminiFunctionResponseContent(content: toolResult)
                )
                contents.append(GeminiContent(
                    role: "function",
                    parts: [GeminiPart(functionResponse: functionResponse)]
                ))

                // Continue loop for next iteration
                continue
            }

            // No function call - extract text response
            if let text = parts.first(where: { $0.text != nil })?.text {
                return text
            }

            throw GeminiError.emptyResponse
        }

        throw GeminiError(message: "Max tool iterations reached", code: nil)
    }

    /// Tool arguments wrapper that is Sendable.
    ///
    /// Wraps function call arguments in a Sendable container for cross-actor passing.
    struct ToolArguments: @unchecked Sendable {
        let arguments: [String: Any]

        init(_ dict: [String: Any]) {
            self.arguments = dict
        }

        subscript(key: String) -> Any? {
            arguments[key]
        }
    }

    /// Tool executor type for local function calling.
    ///
    /// The executor runs on MainActor and has access to SwiftData context.
    typealias ToolExecutor = @MainActor @Sendable (String, ToolArguments) async -> String

    /// Send a chat message with function calling enabled (LOCAL execution).
    ///
    /// This is the **offline-first** version that executes tools locally using
    /// SwiftData, HealthKit, and cached Hevy data. No server required.
    ///
    /// - Parameters:
    ///   - message: The user's message
    ///   - history: Previous conversation messages
    ///   - systemPrompt: System instructions
    ///   - dataContext: Tier 1/2 context data
    ///   - toolExecutor: Closure that executes tools on MainActor with SwiftData access
    ///   - thinkingLevel: How much reasoning depth to use (default: high for complex queries)
    /// - Returns: The AI's response text
    func chatWithToolsLocal(
        message: String,
        history: [ConversationMessage] = [],
        systemPrompt: String,
        dataContext: String? = nil,
        toolExecutor: @escaping ToolExecutor,
        thinkingLevel: ThinkingLevel = .high
    ) async throws -> String {
        guard let apiKey = await keychainManager.getGeminiAPIKey() else {
            throw GeminiError.noAPIKey
        }

        let url = URL(string: "\(baseURL)/models/\(model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        // Build system prompt with context
        var fullSystemPrompt = systemPrompt
        if let context = dataContext, !context.isEmpty {
            fullSystemPrompt += "\n\n--- CURRENT CONTEXT ---\n\(context)"
        }

        // Initialize conversation contents
        let contents = buildContents(message: message, history: history)

        // Capture tools for use in loop (avoid repeated actor access)
        let tools = airfitTools

        // Mutable contents for function calling loop
        var mutableContents = contents

        // Function calling loop with LOCAL execution
        for _ in 0..<maxToolIterations {
            let body = GeminiRequest(
                systemInstruction: GeminiContent(parts: [GeminiPart(text: fullSystemPrompt)]),
                contents: mutableContents,
                generationConfig: GeminiGenerationConfig(
                    maxOutputTokens: 8192,
                    temperature: 0.9,
                    thinkingConfig: thinkingLevel.config
                ),
                tools: tools
            )

            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let errorMessage = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
                throw GeminiError(message: errorMessage, code: httpResponse.statusCode)
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            guard let candidate = geminiResponse.candidates?.first,
                  let parts = candidate.content?.parts else {
                throw GeminiError.emptyResponse
            }

            // Check if response contains a function call
            if let functionCall = parts.first(where: { $0.functionCall != nil })?.functionCall {
                // Convert args for tool executor (wrapped in Sendable container)
                var argsDict: [String: Any] = [:]
                for (key, value) in functionCall.args ?? [:] {
                    argsDict[key] = value.value
                }
                let arguments = ToolArguments(argsDict)

                // Execute the tool via the provided executor (runs on MainActor)
                let toolResult = await toolExecutor(functionCall.name, arguments)

                // Add the assistant's function call to contents
                mutableContents.append(GeminiContent(
                    role: "model",
                    parts: parts
                ))

                // Add the function response
                let functionResponse = GeminiFunctionResponse(
                    name: functionCall.name,
                    response: GeminiFunctionResponseContent(content: toolResult)
                )
                mutableContents.append(GeminiContent(
                    role: "function",
                    parts: [GeminiPart(functionResponse: functionResponse)]
                ))

                // Continue loop for next iteration
                continue
            }

            // No function call - extract text response
            if let text = parts.first(where: { $0.text != nil })?.text {
                return text
            }

            throw GeminiError.emptyResponse
        }

        throw GeminiError(message: "Max tool iterations reached", code: nil)
    }

    /// Execute a tool on the AirFit server.
    private func executeToolOnServer(
        name: String,
        args: [String: AnyCodable],
        serverURL: URL
    ) async throws -> String {
        let executeURL = serverURL.appendingPathComponent("tools/execute")

        var request = URLRequest(url: executeURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Convert AnyCodable args to regular dict for JSON encoding
        var arguments: [String: Any] = [:]
        for (key, value) in args {
            arguments[key] = value.value
        }

        let body: [String: Any] = [
            "name": name,
            "arguments": arguments
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw GeminiError(message: "Tool execution failed: HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode)
        }

        struct ToolResponse: Decodable {
            let success: Bool
            let content: String
            let error: String?
        }

        let toolResponse = try JSONDecoder().decode(ToolResponse.self, from: data)

        if !toolResponse.success, let error = toolResponse.error {
            return "Tool error: \(error)"
        }

        return toolResponse.content
    }

    // MARK: - Helpers

    private func buildContents(message: String, history: [ConversationMessage]) -> [GeminiContent] {
        var contents: [GeminiContent] = []

        // Add conversation history
        for msg in history {
            let role = msg.role == "user" ? "user" : "model"
            contents.append(GeminiContent(role: role, parts: [GeminiPart(text: msg.content)]))
        }

        // Add current message
        contents.append(GeminiContent(role: "user", parts: [GeminiPart(text: message)]))

        return contents
    }

    private func detectMimeType(from data: Data) -> String {
        guard data.count >= 4 else { return "image/jpeg" }

        let bytes = [UInt8](data.prefix(4))

        // PNG magic bytes: 89 50 4E 47
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "image/png"
        }

        // JPEG magic bytes: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return "image/jpeg"
        }

        // WebP magic bytes: 52 49 46 46 (RIFF)
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 {
            return "image/webp"
        }

        return "image/jpeg"  // Default to JPEG
    }

    private func parseErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            struct Error: Decodable {
                let message: String
            }
            let error: Error
        }

        return try? JSONDecoder().decode(ErrorResponse.self, from: data).error.message
    }
}

// MARK: - Request/Response Types

private struct GeminiRequest: Encodable {
    let systemInstruction: GeminiContent?
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    let tools: [GeminiTool]?
    let cachedContent: String?  // Reference to cached context (e.g., "cachedContents/abc123")

    init(
        systemInstruction: GeminiContent?,
        contents: [GeminiContent],
        generationConfig: GeminiGenerationConfig?,
        tools: [GeminiTool]?,
        cachedContent: String? = nil
    ) {
        self.systemInstruction = systemInstruction
        self.contents = contents
        self.generationConfig = generationConfig
        self.tools = tools
        self.cachedContent = cachedContent
    }

    enum CodingKeys: String, CodingKey {
        case systemInstruction = "system_instruction"
        case contents
        case generationConfig
        case tools
        case cachedContent = "cached_content"
    }
}

private struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]?

    init(parts: [GeminiPart]) {
        self.role = nil
        self.parts = parts
    }

    init(role: String, parts: [GeminiPart]) {
        self.role = role
        self.parts = parts
    }
}

private struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiInlineData?
    let functionCall: GeminiFunctionCall?
    let functionResponse: GeminiFunctionResponse?

    init(text: String) {
        self.text = text
        self.inlineData = nil
        self.functionCall = nil
        self.functionResponse = nil
    }

    init(text: String?, inlineData: GeminiInlineData?) {
        self.text = text
        self.inlineData = inlineData
        self.functionCall = nil
        self.functionResponse = nil
    }

    init(functionResponse: GeminiFunctionResponse) {
        self.text = nil
        self.inlineData = nil
        self.functionCall = nil
        self.functionResponse = functionResponse
    }

    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
        case functionCall = "functionCall"
        case functionResponse = "functionResponse"
    }
}

private struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String  // Base64 encoded

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

private struct GeminiGenerationConfig: Encodable {
    let maxOutputTokens: Int
    let temperature: Double
    let thinkingConfig: ThinkingConfig?

    enum CodingKeys: String, CodingKey {
        case maxOutputTokens
        case temperature
        case thinkingConfig = "thinking_config"
    }
}

/// Configuration for Gemini 3's thinking/reasoning depth.
/// Higher budgets allow more thorough reasoning at the cost of latency.
private struct ThinkingConfig: Encodable {
    let thinkingBudget: Int

    enum CodingKeys: String, CodingKey {
        case thinkingBudget = "thinking_budget"
    }

    /// Disabled thinking - fastest responses
    static let disabled = ThinkingConfig(thinkingBudget: 0)
    /// Minimal thinking for simple tasks
    static let low = ThinkingConfig(thinkingBudget: 1024)
    /// Balanced reasoning for general use
    static let medium = ThinkingConfig(thinkingBudget: 4096)
    /// Deep reasoning for complex queries
    static let high = ThinkingConfig(thinkingBudget: 16384)
}

/// User-facing thinking level setting.
/// Maps to ThinkingConfig token budgets internally.
enum ThinkingLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    /// Display label for UI
    var label: String {
        switch self {
        case .low: return "Fast"
        case .medium: return "Balanced"
        case .high: return "Deep"
        }
    }

    /// Description for settings
    var description: String {
        switch self {
        case .low: return "Quick responses, less reasoning"
        case .medium: return "Balanced speed and thoughtfulness"
        case .high: return "Thorough analysis, may take longer"
        }
    }

    /// Convert to internal ThinkingConfig (internal use only)
    fileprivate var config: ThinkingConfig {
        switch self {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
}

// MARK: - Function Calling Types

private struct GeminiFunctionDeclaration: Encodable {
    let name: String
    let description: String
    let parameters: GeminiFunctionParameters
}

private struct GeminiFunctionParameters: Encodable {
    let type: String
    let properties: [String: GeminiFunctionProperty]
    let required: [String]

    init(properties: [String: GeminiFunctionProperty] = [:], required: [String] = []) {
        self.type = "object"
        self.properties = properties
        self.required = required
    }
}

private struct GeminiFunctionProperty: Encodable {
    let type: String
    let description: String?
    let `enum`: [String]?

    init(type: String, description: String? = nil, enumValues: [String]? = nil) {
        self.type = type
        self.description = description
        self.enum = enumValues
    }
}

private struct GeminiTool: Encodable {
    let functionDeclarations: [GeminiFunctionDeclaration]

    enum CodingKeys: String, CodingKey {
        case functionDeclarations = "function_declarations"
    }
}

private struct GeminiFunctionCall: Codable {
    let name: String
    let args: [String: AnyCodable]?
}

private struct GeminiFunctionResponse: Codable {
    let name: String
    let response: GeminiFunctionResponseContent
}

private struct GeminiFunctionResponseContent: Codable {
    let content: String
}

/// Wrapper for any JSON value (for function call args)
private struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            try container.encodeNil()
        }
    }
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent?
}

private struct GeminiStreamChunk: Decodable {
    let candidates: [GeminiCandidate]?
}

// MARK: - Conversation Message (shared type)

/// A single message in a conversation, used for maintaining history.
struct ConversationMessage: Codable {
    let role: String  // "user" or "model"
    let content: String
    let timestamp: Date

    init(role: String, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Nutrition Parse Result

/// Result from Gemini nutrition parsing
struct NutritionParseResult: Codable {
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let confidence: String  // "high", "medium", "low"

    /// Convert to the format NutritionView expects
    var asNutritionEntry: (name: String, calories: Int, protein: Int, carbs: Int, fat: Int, confidence: String) {
        (name, calories, protein, carbs, fat, confidence)
    }
}

// MARK: - Context Caching Types

/// Request to create a cached content resource
private struct CachedContentRequest: Encodable {
    let model: String
    let systemInstruction: CachedContentParts
    let ttl: String  // Duration string like "3600s"

    enum CodingKeys: String, CodingKey {
        case model
        case systemInstruction = "system_instruction"
        case ttl
    }
}

private struct CachedContentParts: Encodable {
    let parts: [CachedContentPart]
}

private struct CachedContentPart: Encodable {
    let text: String
}

/// Response from creating a cached content resource
private struct CachedContentResponse: Decodable {
    let name: String  // e.g., "cachedContents/abc123"
    let model: String?
    let createTime: String?
    let updateTime: String?
    let expireTime: String?

    enum CodingKeys: String, CodingKey {
        case name
        case model
        case createTime
        case updateTime
        case expireTime
    }
}

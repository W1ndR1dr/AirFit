**Modular Sub-Document 10: Services Layer (API Clients & AI Router)**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
- Completion of Module 1: Core Project Setup & Configuration
- Completion of Module 2: Data Layer (SwiftData Schema & Managers)
- Completion of Module 5: AI Persona Engine & CoachEngine
**Date:** May 25, 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To implement a robust, configurable services layer that handles all external API communications including multi-provider AI services (OpenAI, Anthropic, Google Gemini, OpenRouter), weather data, and future integrations.
*   **Responsibilities:**
    *   Secure API key storage using Keychain
    *   Multi-provider AI service with streaming support
    *   Weather API integration
    *   Network request management and caching
    *   Error handling and retry logic
    *   Request/response logging for debugging
    *   Mock services for testing
    *   Performance monitoring
*   **Key Components:**
    *   `AIAPIService.swift` - Multi-provider AI service
    *   `APIKeyManager.swift` - Secure key storage
    *   `WeatherService.swift` - Weather data provider
    *   `NetworkManager.swift` - Base networking layer
    *   `ServiceProtocols.swift` - Service interfaces
    *   `MockServices/` - Testing implementations
    *   `ServiceConfiguration.swift` - Service settings

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Core utilities, logging, constants
    *   Module 2: Data models for caching
    *   Module 5: AI communication types (AIRequest, AIResponse)
    *   URLSession for networking
    *   Security framework for Keychain
*   **Outputs:**
    *   AI responses (streaming text, function calls)
    *   Weather data
    *   Network status updates
    *   Cached responses

**3. Detailed Component Specifications & Agent Tasks**

**Summary of Agent Tasks:**
- **Task 10.0**: Service Protocols & Base Infrastructure (3 sub-tasks)
  - 10.0.1: Create ServiceProtocols.swift
  - 10.0.2: Create NetworkManager.swift
  - 10.0.3: Create ServiceConfiguration.swift
- **Task 10.1**: Secure API Key Management (2 sub-tasks)
  - 10.1.1: Create APIKeyManager.swift
  - 10.1.2: Create KeychainHelper.swift
- **Task 10.2**: AI API Service Implementation (5 sub-tasks)
  - 10.2.1: Create AIAPIService.swift base
  - 10.2.2: Implement provider-specific request builders
  - 10.2.3: Implement SSE response parsing
  - 10.2.4: Add function call handling
  - 10.2.5: Add error recovery
- **Task 10.3**: Weather Service (2 sub-tasks)
  - 10.3.1: Create WeatherService.swift
  - 10.3.2: Add caching layer
- **Task 10.4**: Mock Services (2 sub-tasks)
  - 10.4.1: Create mock implementations
  - 10.4.2: Add test data generators
- **Task 10.5**: Testing (3 sub-tasks)
  - 10.5.1: Create service tests
  - 10.5.2: Create integration tests
  - 10.5.3: Add performance tests

**Total Estimated Time**: 20-25 hours

---

**Task 10.0: Service Protocols & Base Infrastructure**
- **Acceptance Test Command**: `xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/ServiceProtocolTests`
- **Estimated Time**: 3 hours
- **Dependencies**: Module 1 (Core utilities)

**Agent Task 10.0.1: Create Service Protocols**
- File: `AirFit/Services/ServiceProtocols.swift`
- **Concrete Acceptance Criteria**:
  - All protocols compile with Swift 6 concurrency
  - Protocols use async/await patterns
  - Error types are comprehensive
  - Cancellation is supported
  - Test: `swift test --filter ServiceProtocolTests`
- Complete Implementation:
  ```swift
  import Foundation
  import Combine
  
  // MARK: - Base Service Protocol
  @MainActor
  protocol ServiceProtocol: AnyObject {
      var isConfigured: Bool { get }
      var serviceIdentifier: String { get }
      
      func configure() async throws
      func reset() async
      func healthCheck() async -> ServiceHealth
  }
  
  // MARK: - AI Service Protocol
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
  
  // MARK: - Weather Service Protocol
  protocol WeatherServiceProtocol: ServiceProtocol {
      func getCurrentWeather(
          latitude: Double,
          longitude: Double
      ) async throws -> WeatherData
      
      func getForecast(
          latitude: Double,
          longitude: Double,
          days: Int
      ) async throws -> WeatherForecast
      
      func getCachedWeather(
          latitude: Double,
          longitude: Double
      ) -> WeatherData?
  }
  
  // MARK: - API Key Management Protocol
  protocol APIKeyManagementProtocol: AnyObject {
      func saveAPIKey(
          _ key: String,
          for provider: AIProvider
      ) async throws
      
      func getAPIKey(
          for provider: AIProvider
      ) async throws -> String
      
      func deleteAPIKey(
          for provider: AIProvider
      ) async throws
      
      func hasAPIKey(
          for provider: AIProvider
      ) async -> Bool
      
      func getAllConfiguredProviders() async -> [AIProvider]
  }
  
  // MARK: - Network Management Protocol
  protocol NetworkManagementProtocol: AnyObject {
      var isReachable: Bool { get }
      var currentNetworkType: NetworkType { get }
      
      func performRequest<T: Decodable>(
          _ request: URLRequest,
          expecting: T.Type
      ) async throws -> T
      
      func performStreamingRequest(
          _ request: URLRequest
      ) -> AsyncThrowingStream<Data, Error>
      
      func downloadData(
          from url: URL
      ) async throws -> Data
      
      func uploadData(
          _ data: Data,
          to url: URL
      ) async throws -> URLResponse
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
  
  // MARK: - Network Type
  enum NetworkType: String, Sendable {
      case wifi
      case cellular
      case ethernet
      case unknown
      case none
  }
  
  // MARK: - Service Errors
  enum ServiceError: LocalizedError {
      case notConfigured
      case invalidConfiguration(String)
      case networkUnavailable
      case authenticationFailed(String)
      case rateLimitExceeded(retryAfter: TimeInterval?)
      case invalidResponse(String)
      case streamingError(String)
      case timeout
      case cancelled
      case providerError(code: String, message: String)
      case unknown(Error)
      
      var errorDescription: String? {
          switch self {
          case .notConfigured:
              return "Service is not configured"
          case .invalidConfiguration(let detail):
              return "Invalid configuration: \(detail)"
          case .networkUnavailable:
              return "Network connection is unavailable"
          case .authenticationFailed(let reason):
              return "Authentication failed: \(reason)"
          case .rateLimitExceeded(let retryAfter):
              if let retryAfter = retryAfter {
                  return "Rate limit exceeded. Retry after \(Int(retryAfter)) seconds"
              }
              return "Rate limit exceeded"
          case .invalidResponse(let detail):
              return "Invalid response: \(detail)"
          case .streamingError(let detail):
              return "Streaming error: \(detail)"
          case .timeout:
              return "Request timed out"
          case .cancelled:
              return "Request was cancelled"
          case .providerError(let code, let message):
              return "Provider error [\(code)]: \(message)"
          case .unknown(let error):
              return "Unknown error: \(error.localizedDescription)"
          }
      }
  }
  
  // MARK: - User Service Protocol
  protocol UserServiceProtocol: AnyObject {
      func createUser(from profile: OnboardingProfile) async throws -> User
      func updateProfile(_ updates: ProfileUpdate) async throws
      func getCurrentUser() -> User?
      func deleteUser(_ user: User) async throws
  }
  
  // MARK: - Workout Service Protocol
  protocol WorkoutServiceProtocol: AnyObject {
      func startWorkout(type: WorkoutType, user: User) async throws -> Workout
      func pauseWorkout(_ workout: Workout) async throws
      func resumeWorkout(_ workout: Workout) async throws
      func endWorkout(_ workout: Workout) async throws
      func logExercise(_ exercise: Exercise, in workout: Workout) async throws
      func getWorkoutHistory(for user: User, limit: Int) async throws -> [Workout]
      func getWorkoutTemplates() async throws -> [WorkoutTemplate]
      func saveWorkoutTemplate(_ template: WorkoutTemplate) async throws
  }
  
  // MARK: - Analytics Service Protocol
  protocol AnalyticsServiceProtocol: AnyObject {
      func trackEvent(_ event: AnalyticsEvent) async
      func trackScreen(_ screen: String, properties: [String: Any]?) async
      func setUserProperties(_ properties: [String: Any]) async
      func trackWorkoutCompleted(_ workout: Workout) async
      func trackMealLogged(_ meal: FoodEntry) async
      func trackGoalProgress(_ goal: Goal, progress: Double) async
      func getInsights(for user: User) async throws -> UserInsights
  }
  
  // MARK: - Goal Service Protocol
  protocol GoalServiceProtocol: AnyObject {
      func createGoal(_ goal: Goal, for user: User) async throws
      func updateGoal(_ goal: Goal) async throws
      func deleteGoal(_ goal: Goal) async throws
      func getActiveGoals(for user: User) async throws -> [Goal]
      func getGoalHistory(for user: User) async throws -> [Goal]
      func trackGoalProgress(_ goal: Goal, progress: Double) async throws
      func getGoalRecommendations(for user: User) async throws -> [GoalRecommendation]
      func completeGoal(_ goal: Goal) async throws
  }
  
  // MARK: - AI Provider
  enum AIProvider: String, CaseIterable, Sendable {
      case openAI = "openai"
      case anthropic = "anthropic"
      case googleGemini = "gemini"
      case openRouter = "openrouter"
      
      var displayName: String {
          switch self {
          case .openAI: return "OpenAI"
          case .anthropic: return "Anthropic Claude"
          case .googleGemini: return "Google Gemini"
          case .openRouter: return "OpenRouter"
          }
      }
      
      var baseURL: URL {
          switch self {
          case .openAI:
              return URL(string: "https://api.openai.com/v1")!
          case .anthropic:
              return URL(string: "https://api.anthropic.com/v1")!
          case .googleGemini:
              return URL(string: "https://generativelanguage.googleapis.com")!
          case .openRouter:
              return URL(string: "https://openrouter.ai/api/v1")!
          }
      }
      
      var defaultModel: String {
          switch self {
          case .openAI: return "gpt-4-turbo-preview"
          case .anthropic: return "claude-3-opus-20240229"
          case .googleGemini: return "gemini-1.5-pro-latest"
          case .openRouter: return "anthropic/claude-3-opus"
          }
      }
      
      var supportsStreaming: Bool { true }
      var supportsFunctionCalling: Bool { true }
      
      var maxTokens: Int {
          switch self {
          case .openAI: return 128000
          case .anthropic: return 200000
          case .googleGemini: return 1048576
          case .openRouter: return 128000 // Varies by model
          }
      }
  }
  
  // MARK: - Request Priority
  enum RequestPriority: Int, Comparable, Sendable {
      case low = 0
      case medium = 1
      case high = 2
      case critical = 3
      
      static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
          lhs.rawValue < rhs.rawValue
      }
  }
  
  // MARK: - Cache Policy
  enum CachePolicy: Sendable {
      case none
      case memory(duration: TimeInterval)
      case disk(duration: TimeInterval)
      case hybrid(memoryDuration: TimeInterval, diskDuration: TimeInterval)
  }
  
  // MARK: - AI Model
  struct AIModel: Identifiable, Sendable {
      let id: String
      let name: String
      let provider: AIProvider
      let contextLength: Int
      let description: String?
      
      init(id: String, name: String, provider: AIProvider, contextLength: Int, description: String? = nil) {
          self.id = id
          self.name = name
          self.provider = provider
          self.contextLength = contextLength
          self.description = description
      }
  }
  
  // MARK: - AI Request (Simplified for Module 10)
  struct AIRequest: Sendable {
      let systemPrompt: String
      let userMessage: ChatMessage
      let conversationHistory: [ChatMessage]
      let availableFunctions: [AIFunctionSchema]?
      
      init(systemPrompt: String, userMessage: ChatMessage, conversationHistory: [ChatMessage], availableFunctions: [AIFunctionSchema]?) {
          self.systemPrompt = systemPrompt
          self.userMessage = userMessage
          self.conversationHistory = conversationHistory
          self.availableFunctions = availableFunctions
      }
  }
  
  struct ChatMessage: Sendable {
      let role: MessageRole
      let content: String
  }
  
  enum MessageRole: String, Sendable {
      case system, user, assistant
  }
  
  // MARK: - AI Response Types
  enum AIResponse: Sendable {
      case textChunk(String)
      case functionCall(AIFunctionCall)
      case streamEnd
      case streamError(Error)
  }
  
  // MARK: - AI Function Types
  struct AIFunctionCall: Identifiable, Sendable {
      let id: String
      let functionName: String
      let arguments: [String: AnyCodableValue]
  }
  
  struct AIFunctionSchema: Sendable {
      let name: String
      let description: String
      let parametersSchema: [String: Any]
  }
  
  // MARK: - Weather Data Types
  struct WeatherData: Sendable {
      let temperature: Double
      let feelsLike: Double
      let humidity: Int
      let pressure: Int
      let windSpeed: Double
      let windDirection: Int
      let cloudCoverage: Int
      let condition: Condition
      let description: String
      let icon: String
      let visibility: Int
      let uvIndex: Double?
      let sunrise: Date?
      let sunset: Date?
      let location: Location
      let timestamp: Date
      
      enum Condition: String, Sendable {
          case clear, cloudy, rainy, snowy, stormy, foggy, unknown
      }
      
      struct Location: Sendable {
          let name: String
          let country: String
          let latitude: Double
          let longitude: Double
      }
  }
  
  struct WeatherForecast: Sendable {
      let location: WeatherData.Location
      let days: [Day]
      let hourly: [HourlyData]
      
      struct Day: Sendable {
          let date: Date
          let maxTemperature: Double
          let minTemperature: Double
          let condition: WeatherData.Condition
          let precipitationChance: Int
      }
      
      struct HourlyData: Sendable {
          let time: Date
          let temperature: Double
          let condition: WeatherData.Condition
      }
  }
  
  // MARK: - Codable Value Types
  enum AnyCodableValue: Codable, Sendable {
      case string(String)
      case int(Int)
      case double(Double)
      case bool(Bool)
      case array([AnyCodableValue])
      case dictionary([String: AnyCodableValue])
      case null
      
      init(from decoder: Decoder) throws {
          let container = try decoder.singleValueContainer()
          
          if container.decodeNil() {
              self = .null
          } else if let bool = try? container.decode(Bool.self) {
              self = .bool(bool)
          } else if let int = try? container.decode(Int.self) {
              self = .int(int)
          } else if let double = try? container.decode(Double.self) {
              self = .double(double)
          } else if let string = try? container.decode(String.self) {
              self = .string(string)
          } else if let array = try? container.decode([AnyCodableValue].self) {
              self = .array(array)
          } else if let dict = try? container.decode([String: AnyCodableValue].self) {
              self = .dictionary(dict)
          } else {
              throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
          }
      }
      
      func encode(to encoder: Encoder) throws {
          var container = encoder.singleValueContainer()
          
          switch self {
          case .string(let value):
              try container.encode(value)
          case .int(let value):
              try container.encode(value)
          case .double(let value):
              try container.encode(value)
          case .bool(let value):
              try container.encode(value)
          case .array(let value):
              try container.encode(value)
          case .dictionary(let value):
              try container.encode(value)
          case .null:
              try container.encodeNil()
          }
      }
  }
  ```

**Agent Task 10.0.2: Create Network Manager**
- File: `AirFit/Services/NetworkManager.swift`
- **Concrete Acceptance Criteria**:
  - URLSession configuration optimized for iOS 18
  - Proper timeout handling (30s default)
  - Network reachability monitoring
  - Request/response logging
  - Automatic retry with exponential backoff
  - Test: Verify all network operations complete successfully
- Complete Implementation:
  ```swift
  import Foundation
  import Network
  import OSLog
  
  @MainActor
  final class NetworkManager: NetworkManagementProtocol {
      static let shared = NetworkManager()
      
      // MARK: - Properties
      private let session: URLSession
      private let monitor = NWPathMonitor()
      private let monitorQueue = DispatchQueue(label: "com.airfit.networkmonitor")
      
      private(set) var isReachable: Bool = true
      private(set) var currentNetworkType: NetworkType = .unknown
      
      private let logger = Logger(subsystem: "com.airfit", category: "Network")
      
      // Configuration
      private let defaultTimeout: TimeInterval = 30
      private let maxRetryAttempts = 3
      private let initialRetryDelay: TimeInterval = 1.0
      
      // MARK: - Initialization
      private init() {
          // Configure URLSession
          let configuration = URLSessionConfiguration.default
          configuration.timeoutIntervalForRequest = defaultTimeout
          configuration.timeoutIntervalForResource = 300 // 5 minutes
          configuration.requestCachePolicy = .useProtocolCachePolicy
          configuration.allowsConstrainedNetworkAccess = true
          configuration.allowsExpensiveNetworkAccess = true
          configuration.httpMaximumConnectionsPerHost = 5
          
          // iOS 18 optimizations
          if #available(iOS 18.0, *) {
              configuration.requiresDNSSECValidation = true
          }
          
          session = URLSession(configuration: configuration)
          
          setupNetworkMonitoring()
      }
      
      // MARK: - Network Monitoring
      private func setupNetworkMonitoring() {
          monitor.pathUpdateHandler = { [weak self] path in
              Task { @MainActor in
                  self?.updateNetworkStatus(path)
              }
          }
          monitor.start(queue: monitorQueue)
      }
      
      @MainActor
      private func updateNetworkStatus(_ path: NWPath) {
          isReachable = path.status == .satisfied
          
          if path.usesInterfaceType(.wifi) {
              currentNetworkType = .wifi
          } else if path.usesInterfaceType(.cellular) {
              currentNetworkType = .cellular
          } else if path.usesInterfaceType(.wiredEthernet) {
              currentNetworkType = .ethernet
          } else if path.status == .satisfied {
              currentNetworkType = .unknown
          } else {
              currentNetworkType = .none
          }
          
          logger.info("Network status: \(self.currentNetworkType.rawValue), reachable: \(self.isReachable)")
      }
      
      // MARK: - Request Methods
      func performRequest<T: Decodable>(
          _ request: URLRequest,
          expecting type: T.Type
      ) async throws -> T {
          guard isReachable else {
              throw ServiceError.networkUnavailable
          }
          
          var lastError: Error?
          
          for attempt in 0..<maxRetryAttempts {
              do {
                  let (data, response) = try await performRequestWithLogging(request)
                  
                  guard let httpResponse = response as? HTTPURLResponse else {
                      throw ServiceError.invalidResponse("Invalid response type")
                  }
                  
                  try validateHTTPResponse(httpResponse, data: data)
                  
                  do {
                      let decoded = try JSONDecoder().decode(type, from: data)
                      return decoded
                  } catch {
                      logger.error("Decoding error: \(error)")
                      throw ServiceError.invalidResponse("Failed to decode response: \(error)")
                  }
                  
              } catch {
                  lastError = error
                  
                  if shouldRetry(error: error, attempt: attempt) {
                      let delay = retryDelay(for: attempt)
                      logger.warning("Request failed (attempt \(attempt + 1)/\(self.maxRetryAttempts)), retrying in \(delay)s...")
                      try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                  } else {
                      throw error
                  }
              }
          }
          
          throw lastError ?? ServiceError.unknown(NSError(domain: "NetworkManager", code: -1))
      }
      
      func performStreamingRequest(
          _ request: URLRequest
      ) -> AsyncThrowingStream<Data, Error> {
          AsyncThrowingStream { continuation in
              Task {
                  do {
                      guard isReachable else {
                          throw ServiceError.networkUnavailable
                      }
                      
                      let (bytes, response) = try await session.bytes(for: request)
                      
                      guard let httpResponse = response as? HTTPURLResponse else {
                          throw ServiceError.invalidResponse("Invalid response type")
                      }
                      
                      if !(200...299).contains(httpResponse.statusCode) {
                          throw ServiceError.providerError(
                              code: "\(httpResponse.statusCode)",
                              message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                          )
                      }
                      
                      var buffer = Data()
                      
                      for try await byte in bytes {
                          buffer.append(byte)
                          
                          // Check for complete SSE message
                          if let messages = extractSSEMessages(from: &buffer) {
                              for message in messages {
                                  continuation.yield(message)
                              }
                          }
                      }
                      
                      continuation.finish()
                      
                  } catch {
                      continuation.finish(throwing: error)
                  }
              }
          }
      }
      
      func downloadData(from url: URL) async throws -> Data {
          let request = URLRequest(url: url)
          let (data, response) = try await performRequestWithLogging(request)
          
          guard let httpResponse = response as? HTTPURLResponse else {
              throw ServiceError.invalidResponse("Invalid response type")
          }
          
          try validateHTTPResponse(httpResponse, data: data)
          return data
      }
      
      func uploadData(_ data: Data, to url: URL) async throws -> URLResponse {
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          
          let (_, response) = try await session.upload(for: request, from: data)
          
          guard let httpResponse = response as? HTTPURLResponse else {
              throw ServiceError.invalidResponse("Invalid response type")
          }
          
          try validateHTTPResponse(httpResponse, data: nil)
          return response
      }
      
      // MARK: - Helper Methods
      private func performRequestWithLogging(
          _ request: URLRequest
      ) async throws -> (Data, URLResponse) {
          let startTime = Date()
          
          logger.debug("""
              🌐 Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")
              Headers: \(request.allHTTPHeaderFields ?? [:])
              """)
          
          let (data, response) = try await session.data(for: request)
          
          let duration = Date().timeIntervalSince(startTime)
          
          if let httpResponse = response as? HTTPURLResponse {
              logger.debug("""
                  ✅ Response: \(httpResponse.statusCode) in \(String(format: "%.2f", duration))s
                  Size: \(data.count) bytes
                  """)
          }
          
          return (data, response)
      }
      
      private func validateHTTPResponse(
          _ response: HTTPURLResponse,
          data: Data?
      ) throws {
          switch response.statusCode {
          case 200...299:
              return
          case 401:
              throw ServiceError.authenticationFailed("Invalid API key")
          case 429:
              let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                  .flatMap { Double($0) }
              throw ServiceError.rateLimitExceeded(retryAfter: retryAfter)
          case 400...499:
              let message = data.flatMap { try? JSONDecoder().decode(ErrorResponse.self, from: $0) }?.error ?? "Client error"
              throw ServiceError.providerError(code: "\(response.statusCode)", message: message)
          case 500...599:
              throw ServiceError.providerError(code: "\(response.statusCode)", message: "Server error")
          default:
              throw ServiceError.invalidResponse("Unexpected status code: \(response.statusCode)")
          }
      }
      
      private func shouldRetry(error: Error, attempt: Int) -> Bool {
          guard attempt < maxRetryAttempts - 1 else { return false }
          
          switch error {
          case ServiceError.networkUnavailable,
               ServiceError.timeout:
              return true
          case ServiceError.providerError(let code, _):
              return code.hasPrefix("5") // Retry on 5xx errors
          case let urlError as URLError:
              return urlError.code == .timedOut || urlError.code == .networkConnectionLost
          default:
              return false
          }
      }
      
      private func retryDelay(for attempt: Int) -> TimeInterval {
          // Exponential backoff with jitter
          let baseDelay = initialRetryDelay * pow(2.0, Double(attempt))
          let jitter = Double.random(in: 0...0.3) * baseDelay
          return min(baseDelay + jitter, 30) // Cap at 30 seconds
      }
      
      private func extractSSEMessages(from buffer: inout Data) -> [Data]? {
          guard let string = String(data: buffer, encoding: .utf8) else { return nil }
          
          var messages: [Data] = []
          let lines = string.components(separatedBy: .newlines)
          var remainingBuffer = Data()
          var currentMessage = Data()
          var i = 0
          
          while i < lines.count {
              let line = lines[i]
              
              if line.isEmpty && !currentMessage.isEmpty {
                  // End of message
                  messages.append(currentMessage)
                  currentMessage = Data()
              } else if line.hasPrefix("data: ") {
                  let data = String(line.dropFirst(6))
                  if let messageData = data.data(using: .utf8) {
                      currentMessage.append(messageData)
                  }
              } else if i == lines.count - 1 && !line.isEmpty {
                  // Incomplete line at the end
                  if let lineData = line.data(using: .utf8) {
                      remainingBuffer = lineData
                  }
              }
              
              i += 1
          }
          
          buffer = remainingBuffer
          return messages.isEmpty ? nil : messages
      }
      
      // MARK: - Types
      private struct ErrorResponse: Decodable {
          let error: String
      }
  }
  
  // MARK: - URLRequest Extensions
  extension URLRequest {
      mutating func addCommonHeaders() {
          setValue("application/json", forHTTPHeaderField: "Content-Type")
          setValue("application/json", forHTTPHeaderField: "Accept")
          setValue("AirFit/1.0", forHTTPHeaderField: "User-Agent")
      }
  }
  ```

**Agent Task 10.0.3: Create Service Configuration**
- File: `AirFit/Services/ServiceConfiguration.swift`
- **Concrete Acceptance Criteria**:
  - Configuration is thread-safe
  - Settings persist across app launches
  - Validation prevents invalid configurations
  - Test: Configuration changes persist correctly
- Complete Implementation:
  ```swift
  import Foundation
  import SwiftData
  
  @MainActor
  final class ServiceConfiguration: ObservableObject {
      static let shared = ServiceConfiguration()
      
      // MARK: - Published Properties
      @Published private(set) var currentAIProvider: AIProvider = .openAI
      @Published private(set) var currentAIModel: String = AIProvider.openAI.defaultModel
      @Published private(set) var weatherProvider: WeatherProvider = .openWeatherMap
      @Published private(set) var isConfigured: Bool = false
      
      // MARK: - Configuration Settings
      struct AIConfiguration: Codable {
          let provider: AIProvider
          let model: String
          let temperature: Double
          let maxTokens: Int
          let streamingEnabled: Bool
          
          static let `default` = AIConfiguration(
              provider: .openAI,
              model: AIProvider.openAI.defaultModel,
              temperature: 0.7,
              maxTokens: 2048,
              streamingEnabled: true
          )
      }
      
      enum WeatherProvider: String, CaseIterable, Codable {
          case openWeatherMap = "openweathermap"
          case weatherAPI = "weatherapi"
          
          var baseURL: URL {
              switch self {
              case .openWeatherMap:
                  return URL(string: "https://api.openweathermap.org/data/2.5")!
              case .weatherAPI:
                  return URL(string: "https://api.weatherapi.com/v1")!
              }
          }
      }
      
      // MARK: - Private Properties
      private let userDefaults = UserDefaults.standard
      private let configurationKey = "com.airfit.serviceConfiguration"
      
      private var aiConfiguration: AIConfiguration {
          didSet {
              saveConfiguration()
              objectWillChange.send()
          }
      }
      
      // MARK: - Initialization
      private init() {
          if let data = userDefaults.data(forKey: configurationKey),
             let config = try? JSONDecoder().decode(AIConfiguration.self, from: data) {
              self.aiConfiguration = config
              self.currentAIProvider = config.provider
              self.currentAIModel = config.model
              self.isConfigured = true
          } else {
              self.aiConfiguration = .default
          }
      }
      
      // MARK: - Configuration Methods
      func configureAIService(
          provider: AIProvider,
          model: String? = nil,
          temperature: Double = 0.7,
          maxTokens: Int = 2048
      ) async throws {
          // Validate configuration
          guard temperature >= 0 && temperature <= 2 else {
              throw ServiceError.invalidConfiguration("Temperature must be between 0 and 2")
          }
          
          guard maxTokens > 0 && maxTokens <= provider.maxTokens else {
              throw ServiceError.invalidConfiguration("Invalid max tokens for provider")
          }
          
          let finalModel = model ?? provider.defaultModel
          
          // Validate model is available for provider
          guard isValidModel(finalModel, for: provider) else {
              throw ServiceError.invalidConfiguration("Invalid model for provider")
          }
          
          // Update configuration
          aiConfiguration = AIConfiguration(
              provider: provider,
              model: finalModel,
              temperature: temperature,
              maxTokens: maxTokens,
              streamingEnabled: true
          )
          
          currentAIProvider = provider
          currentAIModel = finalModel
          isConfigured = true
          
          AppLogger.info("AI service configured: \(provider.displayName) - \(finalModel)", category: .services)
      }
      
      func configureWeatherService(provider: WeatherProvider) {
          weatherProvider = provider
          userDefaults.set(provider.rawValue, forKey: "weatherProvider")
          
          AppLogger.info("Weather service configured: \(provider.rawValue)", category: .services)
      }
      
      func resetConfiguration() async {
          aiConfiguration = .default
          currentAIProvider = .openAI
          currentAIModel = AIProvider.openAI.defaultModel
          weatherProvider = .openWeatherMap
          isConfigured = false
          
          userDefaults.removeObject(forKey: configurationKey)
          userDefaults.removeObject(forKey: "weatherProvider")
          
          AppLogger.info("Service configuration reset", category: .services)
      }
      
      // MARK: - Helper Methods
      private func saveConfiguration() {
          if let data = try? JSONEncoder().encode(aiConfiguration) {
              userDefaults.set(data, forKey: configurationKey)
          }
      }
      
      private func isValidModel(_ model: String, for provider: AIProvider) -> Bool {
          // In production, this would validate against a list of available models
          // For now, we'll accept any non-empty model string
          return !model.isEmpty
      }
      
      // MARK: - Service Status
      func getServiceStatus() async -> [String: ServiceHealth] {
          var status: [String: ServiceHealth] = [:]
          
          // Check AI service
          if isConfigured {
              status["ai"] = ServiceHealth(
                  status: .healthy,
                  lastCheckTime: Date(),
                  responseTime: nil,
                  errorMessage: nil,
                  metadata: [
                      "provider": currentAIProvider.rawValue,
                      "model": currentAIModel
                  ]
              )
          } else {
              status["ai"] = ServiceHealth(
                  status: .unhealthy,
                  lastCheckTime: Date(),
                  responseTime: nil,
                  errorMessage: "Not configured",
                  metadata: [:]
              )
          }
          
          // Check weather service
          status["weather"] = ServiceHealth(
              status: .healthy,
              lastCheckTime: Date(),
              responseTime: nil,
              errorMessage: nil,
              metadata: ["provider": weatherProvider.rawValue]
          )
          
          return status
      }
  }
  ```

---

**Task 10.1: Secure API Key Management**
- **Acceptance Test Command**: `xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/APIKeyManagerTests`
- **Estimated Time**: 2 hours
- **Dependencies**: Security framework

**Agent Task 10.1.1: Create API Key Manager**
- File: `AirFit/Services/Security/APIKeyManager.swift`
- **Concrete Acceptance Criteria**:
  - Keys stored securely in Keychain (not UserDefaults)
  - Keychain operations complete in < 100ms
  - Error handling for all Keychain errors
  - Keys are encrypted at rest
  - Test: Verify keys persist across app launches
- Complete Implementation:
  ```swift
  import Foundation
  import Security
  
  actor APIKeyManager: APIKeyManagementProtocol {
      static let shared = APIKeyManager()
      
      // MARK: - Properties
      private let keychain = KeychainHelper()
      private let servicePrefix = "com.airfit.apikey"
      
      // Cache for performance
      private var keyCache: [AIProvider: String] = [:]
      
      // MARK: - Initialization
      private init() {}
      
      // MARK: - API Key Management
      func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
          let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
          
          guard !trimmedKey.isEmpty else {
              throw APIKeyError.invalidKey("API key cannot be empty")
          }
          
          guard isValidAPIKey(trimmedKey, for: provider) else {
              throw APIKeyError.invalidKey("Invalid API key format for \(provider.displayName)")
          }
          
          let keychainKey = keychainKey(for: provider)
          
          do {
              try await keychain.save(
                  trimmedKey,
                  forKey: keychainKey,
                  withAccess: .whenUnlockedThisDeviceOnly
              )
              
              // Update cache
              keyCache[provider] = trimmedKey
              
              AppLogger.info("API key saved for \(provider.displayName)", category: .security)
              
          } catch {
              AppLogger.error("Failed to save API key", error: error, category: .security)
              throw APIKeyError.keychainError(error)
          }
      }
      
      func getAPIKey(for provider: AIProvider) async throws -> String {
          // Check cache first
          if let cachedKey = keyCache[provider] {
              return cachedKey
          }
          
          let keychainKey = keychainKey(for: provider)
          
          do {
              let key = try await keychain.retrieve(forKey: keychainKey)
              
              // Update cache
              keyCache[provider] = key
              
              return key
              
          } catch KeychainError.itemNotFound {
              throw APIKeyError.keyNotFound(provider)
          } catch {
              AppLogger.error("Failed to retrieve API key", error: error, category: .security)
              throw APIKeyError.keychainError(error)
          }
      }
      
      func deleteAPIKey(for provider: AIProvider) async throws {
          let keychainKey = keychainKey(for: provider)
          
          do {
              try await keychain.delete(forKey: keychainKey)
              
              // Remove from cache
              keyCache.removeValue(forKey: provider)
              
              AppLogger.info("API key deleted for \(provider.displayName)", category: .security)
              
          } catch KeychainError.itemNotFound {
              // Already deleted, not an error
              keyCache.removeValue(forKey: provider)
          } catch {
              AppLogger.error("Failed to delete API key", error: error, category: .security)
              throw APIKeyError.keychainError(error)
          }
      }
      
      func hasAPIKey(for provider: AIProvider) async -> Bool {
          do {
              _ = try await getAPIKey(for: provider)
              return true
          } catch {
              return false
          }
      }
      
      func getAllConfiguredProviders() async -> [AIProvider] {
          var configured: [AIProvider] = []
          
          for provider in AIProvider.allCases {
              if await hasAPIKey(for: provider) {
                  configured.append(provider)
              }
          }
          
          return configured
      }
      
      // MARK: - Validation
      private func isValidAPIKey(_ key: String, for provider: AIProvider) -> Bool {
          switch provider {
          case .openAI:
              // OpenAI keys start with "sk-"
              return key.hasPrefix("sk-") && key.count > 20
              
          case .anthropic:
              // Anthropic keys have specific format
              return key.count > 30
              
          case .googleGemini:
              // Gemini API keys are typically 39 characters
              return key.count >= 39
              
          case .openRouter:
              // OpenRouter keys start with "sk-or-"
              return key.hasPrefix("sk-or-") && key.count > 20
          }
      }
      
      // MARK: - Helper Methods
      private func keychainKey(for provider: AIProvider) -> String {
          "\(servicePrefix).\(provider.rawValue)"
      }
      
      // MARK: - Migration
      func migrateFromUserDefaults() async {
          // One-time migration from UserDefaults to Keychain
          let userDefaults = UserDefaults.standard
          let migrationKey = "com.airfit.apikey.migrated"
          
          guard !userDefaults.bool(forKey: migrationKey) else { return }
          
          for provider in AIProvider.allCases {
              let oldKey = "apiKey.\(provider.rawValue)"
              if let apiKey = userDefaults.string(forKey: oldKey) {
                  do {
                      try await saveAPIKey(apiKey, for: provider)
                      userDefaults.removeObject(forKey: oldKey)
                      AppLogger.info("Migrated API key for \(provider.displayName)", category: .security)
                  } catch {
                      AppLogger.error("Failed to migrate API key", error: error, category: .security)
                  }
              }
          }
          
          userDefaults.set(true, forKey: migrationKey)
      }
  }
  
  // MARK: - API Key Errors
  enum APIKeyError: LocalizedError {
      case invalidKey(String)
      case keyNotFound(AIProvider)
      case keychainError(Error)
      
      var errorDescription: String? {
          switch self {
          case .invalidKey(let reason):
              return "Invalid API key: \(reason)"
          case .keyNotFound(let provider):
              return "No API key found for \(provider.displayName)"
          case .keychainError(let error):
              return "Keychain error: \(error.localizedDescription)"
          }
      }
  }
  ```

**Agent Task 10.1.2: Create Keychain Helper**
- File: `AirFit/Services/Security/KeychainHelper.swift`
- **Concrete Acceptance Criteria**:
  - All Keychain operations are thread-safe
  - Proper error handling for all OSStatus codes
  - Support for different accessibility levels
  - Biometric authentication support ready
  - Test: Concurrent operations don't cause race conditions
- Complete Implementation:
  ```swift
  import Foundation
  import Security
  
  actor KeychainHelper {
      
      // MARK: - Types
      enum KeychainAccessibility {
          case whenUnlocked
          case whenUnlockedThisDeviceOnly
          case afterFirstUnlock
          case afterFirstUnlockThisDeviceOnly
          
          var cfString: CFString {
              switch self {
              case .whenUnlocked:
                  return kSecAttrAccessibleWhenUnlocked
              case .whenUnlockedThisDeviceOnly:
                  return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
              case .afterFirstUnlock:
                  return kSecAttrAccessibleAfterFirstUnlock
              case .afterFirstUnlockThisDeviceOnly:
                  return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
              }
          }
      }
      
      // MARK: - Properties
      private let service = "com.airfit.keychain"
      
      // MARK: - Save
      func save(
          _ value: String,
          forKey key: String,
          withAccess accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly
      ) async throws {
          guard let data = value.data(using: .utf8) else {
              throw KeychainError.encodingError
          }
          
          let query: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrService as String: service,
              kSecAttrAccount as String: key,
              kSecValueData as String: data,
              kSecAttrAccessible as String: accessibility.cfString
          ]
          
          // Try to update first
          let updateQuery: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrService as String: service,
              kSecAttrAccount as String: key
          ]
          
          let updateAttributes: [String: Any] = [
              kSecValueData as String: data,
              kSecAttrAccessible as String: accessibility.cfString
          ]
          
          var status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
          
          if status == errSecItemNotFound {
              // Item doesn't exist, add it
              status = SecItemAdd(query as CFDictionary, nil)
          }
          
          guard status == errSecSuccess else {
              throw KeychainError.operationFailed(status)
          }
      }
      
      // MARK: - Retrieve
      func retrieve(forKey key: String) async throws -> String {
          let query: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrService as String: service,
              kSecAttrAccount as String: key,
              kSecReturnData as String: true,
              kSecMatchLimit as String: kSecMatchLimitOne
          ]
          
          var result: AnyObject?
          let status = SecItemCopyMatching(query as CFDictionary, &result)
          
          guard status == errSecSuccess else {
              if status == errSecItemNotFound {
                  throw KeychainError.itemNotFound
              }
              throw KeychainError.operationFailed(status)
          }
          
          guard let data = result as? Data,
                let value = String(data: data, encoding: .utf8) else {
              throw KeychainError.decodingError
          }
          
          return value
      }
      
      // MARK: - Delete
      func delete(forKey key: String) async throws {
          let query: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrService as String: service,
              kSecAttrAccount as String: key
          ]
          
          let status = SecItemDelete(query as CFDictionary)
          
          guard status == errSecSuccess || status == errSecItemNotFound else {
              throw KeychainError.operationFailed(status)
          }
      }
      
      // MARK: - Delete All
      func deleteAll() async throws {
          let query: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrService as String: service
          ]
          
          let status = SecItemDelete(query as CFDictionary)
          
          guard status == errSecSuccess || status == errSecItemNotFound else {
              throw KeychainError.operationFailed(status)
          }
      }
      
      // MARK: - Check Existence
      func exists(key: String) async -> Bool {
          let query: [String: Any] = [
              kSecClass as String: kSecClassGenericPassword,
              kSecAttrService as String: service,
              kSecAttrAccount as String: key,
              kSecReturnData as String: false
          ]
          
          let status = SecItemCopyMatching(query as CFDictionary, nil)
          return status == errSecSuccess
      }
  }
  
  // MARK: - Keychain Errors
  enum KeychainError: LocalizedError {
      case itemNotFound
      case duplicateItem
      case operationFailed(OSStatus)
      case encodingError
      case decodingError
      
      var errorDescription: String? {
          switch self {
          case .itemNotFound:
              return "Item not found in keychain"
          case .duplicateItem:
              return "Duplicate item in keychain"
          case .operationFailed(let status):
              return "Keychain operation failed: \(status) - \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error")"
          case .encodingError:
              return "Failed to encode data for keychain"
          case .decodingError:
              return "Failed to decode data from keychain"
          }
      }
  }
  ```

---

**Task 10.2: AI API Service Implementation**
- **Acceptance Test Command**: `xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/AIAPIServiceTests`
- **Estimated Time**: 8 hours
- **Dependencies**: Module 5 (AI communication types), Task 10.0, Task 10.1

**Agent Task 10.2.1: Create AI API Service Base**
- File: `AirFit/Services/AI/AIAPIService.swift`
- **Concrete Acceptance Criteria**:
  - Supports all 4 providers (OpenAI, Anthropic, Gemini, OpenRouter)
  - Streaming responses work for all providers
  - Function calling parsed correctly
  - Request timeout of 60s for AI calls
  - Automatic retry on transient failures
  - Test: Mock requests succeed for all providers
- Complete Implementation:
  ```swift
  import Foundation
  import Combine
  
  @MainActor
  final class AIAPIService: AIServiceProtocol {
      
      // MARK: - Properties
      let serviceIdentifier = "ai-api-service"
      private(set) var isConfigured: Bool = false
      
      private let networkManager = NetworkManager.shared
      private let apiKeyManager = APIKeyManager.shared
      private let configuration = ServiceConfiguration.shared
      
      private var currentTask: URLSessionDataTask?
      private var streamContinuation: AsyncThrowingStream<AIResponse, Error>.Continuation?
      
      // Provider-specific helpers
      private let requestBuilder = AIRequestBuilder()
      private let responseParser = AIResponseParser()
      
      // MARK: - Initialization
      init() {}
      
      // MARK: - Service Protocol
      func configure() async throws {
          // Verify API key exists
          let provider = configuration.currentAIProvider
          _ = try await apiKeyManager.getAPIKey(for: provider)
          
          isConfigured = true
          AppLogger.info("AI API Service configured for \(provider.displayName)", category: .services)
      }
      
      func reset() async {
          await cancelCurrentRequest()
          isConfigured = false
      }
      
      func healthCheck() async -> ServiceHealth {
          guard isConfigured else {
              return ServiceHealth(
                  status: .unhealthy,
                  lastCheckTime: Date(),
                  responseTime: nil,
                  errorMessage: "Not configured",
                  metadata: [:]
              )
          }
          
          do {
              let startTime = Date()
              
              // Simple health check request
              let healthRequest = AIRequest(
                  systemPrompt: "You are a health check bot.",
                  userMessage: ChatMessage(role: .user, content: "Reply with 'OK'"),
                  conversationHistory: [],
                  availableFunctions: nil
              )
              
              var responseReceived = false
              
              for try await response in sendRequest(healthRequest) {
                  if case .textChunk = response {
                      responseReceived = true
                      break
                  }
              }
              
              let responseTime = Date().timeIntervalSince(startTime)
              
              return ServiceHealth(
                  status: responseReceived ? .healthy : .degraded,
                  lastCheckTime: Date(),
                  responseTime: responseTime,
                  errorMessage: nil,
                  metadata: [
                      "provider": configuration.currentAIProvider.rawValue,
                      "model": configuration.currentAIModel
                  ]
              )
              
          } catch {
              return ServiceHealth(
                  status: .unhealthy,
                  lastCheckTime: Date(),
                  responseTime: nil,
                  errorMessage: error.localizedDescription,
                  metadata: [:]
              )
          }
      }
      
      func validateConfiguration() async throws {
          guard isConfigured else {
              throw ServiceError.notConfigured
          }
          
          // Verify API key still exists
          _ = try await apiKeyManager.getAPIKey(for: configuration.currentAIProvider)
      }
      
      // MARK: - AI Request Handling
      func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
          AsyncThrowingStream { continuation in
              Task {
                  await self.handleRequest(request, continuation: continuation)
              }
          }
      }
      
      private func handleRequest(
          _ request: AIRequest,
          continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
      ) async {
          do {
              // Store continuation for cancellation
              self.streamContinuation = continuation
              
              // Validate configuration
              try await validateConfiguration()
              
              // Get API key
              let apiKey = try await apiKeyManager.getAPIKey(for: configuration.currentAIProvider)
              
              // Build request
              let urlRequest = try await requestBuilder.buildRequest(
                  for: request,
                  provider: configuration.currentAIProvider,
                  model: configuration.currentAIModel,
                  apiKey: apiKey
              )
              
              // Start streaming
              await streamResponse(urlRequest: urlRequest, continuation: continuation)
              
          } catch {
              continuation.finish(throwing: error)
          }
      }
      
      private func streamResponse(
          urlRequest: URLRequest,
          continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
      ) async {
          let provider = configuration.currentAIProvider
          
          do {
              for try await data in networkManager.performStreamingRequest(urlRequest) {
                  // Parse based on provider
                  let responses = try await responseParser.parseStreamData(
                      data,
                      provider: provider
                  )
                  
                  for response in responses {
                      continuation.yield(response)
                      
                      if case .streamEnd = response {
                          continuation.finish()
                          return
                      }
                  }
              }
              
              // If we get here without streamEnd, send it
              continuation.yield(.streamEnd)
              continuation.finish()
              
          } catch {
              if case ServiceError.cancelled = error {
                  continuation.finish()
              } else {
                  continuation.finish(throwing: error)
              }
          }
      }
      
      func cancelCurrentRequest() async {
          currentTask?.cancel()
          currentTask = nil
          streamContinuation?.finish(throwing: ServiceError.cancelled)
          streamContinuation = nil
      }
  }
  
  // MARK: - Request Builder
  actor AIRequestBuilder {
      
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
          case .openAI, .openRouter:
              request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
              
          case .anthropic:
              request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
              request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
              
          case .googleGemini:
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
              
          case .googleGemini:
              var url = provider.baseURL
                  .appendingPathComponent("v1beta")
                  .appendingPathComponent("models")
                  .appendingPathComponent("\(model):streamGenerateContent")
              
              // Add SSE query parameter
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
              components.queryItems = [URLQueryItem(name: "alt", value: "sse")]
              return components.url!
              
          case .openRouter:
              return provider.baseURL.appendingPathComponent("chat/completions")
          }
      }
      
      private func buildRequestBody(
          for request: AIRequest,
          provider: AIProvider,
          model: String
      ) async throws -> [String: Any] {
          
          switch provider {
          case .openAI, .openRouter:
              return buildOpenAIRequestBody(request: request, model: model)
              
          case .anthropic:
              return buildAnthropicRequestBody(request: request, model: model)
              
          case .googleGemini:
              return buildGeminiRequestBody(request: request, model: model)
          }
      }
      
      private func buildOpenAIRequestBody(
          request: AIRequest,
          model: String
      ) -> [String: Any] {
          var messages: [[String: Any]] = []
          
          // System message
          messages.append([
              "role": "system",
              "content": request.systemPrompt
          ])
          
          // Conversation history
          for msg in request.conversationHistory {
              messages.append([
                  "role": msg.role.rawValue,
                  "content": msg.content
              ])
          }
          
          // Current user message
          messages.append([
              "role": "user",
              "content": request.userMessage.content
          ])
          
          var body: [String: Any] = [
              "model": model,
              "messages": messages,
              "stream": true,
              "temperature": 0.7,
              "max_tokens": 2048
          ]
          
          // Add tools if available
          if let functions = request.availableFunctions {
              body["tools"] = functions.map { function in
                  [
                      "type": "function",
                      "function": [
                          "name": function.name,
                          "description": function.description,
                          "parameters": function.parametersSchema
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
          
          // Convert conversation history
          for msg in request.conversationHistory {
              messages.append([
                  "role": msg.role == .assistant ? "assistant" : "user",
                  "content": msg.content
              ])
          }
          
          // Current user message
          messages.append([
              "role": "user",
              "content": request.userMessage.content
          ])
          
          var body: [String: Any] = [
              "model": model,
              "system": request.systemPrompt,
              "messages": messages,
              "stream": true,
              "max_tokens": 2048
          ]
          
          // Add tools if available
          if let functions = request.availableFunctions {
              body["tools"] = functions.map { function in
                  [
                      "name": function.name,
                      "description": function.description,
                      "input_schema": function.parametersSchema
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
          
          // Convert conversation history
          for msg in request.conversationHistory {
              contents.append([
                  "role": msg.role == .assistant ? "model" : "user",
                  "parts": [["text": msg.content]]
              ])
          }
          
          // Current user message
          contents.append([
              "role": "user",
              "parts": [["text": request.userMessage.content]]
          ])
          
          var body: [String: Any] = [
              "contents": contents,
              "systemInstruction": [
                  "parts": [["text": request.systemPrompt]]
              ],
              "generationConfig": [
                  "temperature": 0.7,
                  "maxOutputTokens": 2048,
                  "topP": 0.95,
                  "topK": 20
              ]
          ]
          
          // Add tools if available
          if let functions = request.availableFunctions {
              body["tools"] = [[
                  "functionDeclarations": functions.map { function in
                      [
                          "name": function.name,
                          "description": function.description,
                          "parameters": function.parametersSchema
                      ]
                  }
              ]]
          }
          
          return body
      }
  }
  ```

**Agent Task 10.2.2: Create AI Response Parser**
- File: `AirFit/Services/AI/AIResponseParser.swift`
- **Concrete Acceptance Criteria**:
  - Correctly parses SSE format for all providers
  - Handles partial JSON in streaming
  - Function calls extracted with arguments
  - Error responses parsed appropriately
  - Memory efficient (< 10MB for parsing)
  - Test: All provider response formats parse correctly
- Complete Implementation:
  ```swift
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
              
          case .googleGemini:
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
              return [.streamEnd]
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
                  results.append(.textChunk(content))
              }
              
              // Tool calls
              if let toolCalls = choice.delta.toolCalls {
                  for toolCall in toolCalls {
                      if let function = toolCall.function,
                         let name = function.name,
                         let arguments = function.arguments {
                          
                          do {
                              let args = try parseJSONArguments(arguments)
                              let functionCall = AIFunctionCall(
                                  id: toolCall.id ?? UUID().uuidString,
                                  functionName: name,
                                  arguments: args
                              )
                              results.append(.functionCall(functionCall))
                          } catch {
                              AppLogger.error("Failed to parse function arguments", error: error, category: .services)
                          }
                      }
                  }
              }
              
              // Stream end
              if let finishReason = choice.finishReason,
                 finishReason == "stop" || finishReason == "tool_calls" {
                  results.append(.streamEnd)
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
                      return .textChunk(text)
                  }
                  
              case "message_delta":
                  let delta = try JSONDecoder().decode(AnthropicMessageDelta.self, from: jsonData)
                  if delta.delta.stopReason != nil {
                      return .streamEnd
                  }
                  
              case "message_stop":
                  return .streamEnd
                  
              case "error":
                  let error = try JSONDecoder().decode(AnthropicError.self, from: jsonData)
                  return .streamError(
                      ServiceError.providerError(
                          code: error.error.type,
                          message: error.error.message
                      )
                  )
                  
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
                      results.append(.textChunk(text))
                  }
                  
                  // Function call
                  if let functionCall = part.functionCall {
                      let aiFunction = AIFunctionCall(
                          id: UUID().uuidString,
                          functionName: functionCall.name,
                          arguments: functionCall.args
                      )
                      results.append(.functionCall(aiFunction))
                  }
              }
              
              // Check finish reason
              if let finishReason = candidate.finishReason,
                 finishReason == "STOP" || finishReason == "MAX_TOKENS" {
                  results.append(.streamEnd)
              }
          }
          
          return results
      }
      
      // MARK: - Helper Methods
      private func parseJSONArguments(_ jsonString: String) throws -> [String: AnyCodableValue] {
          guard let data = jsonString.data(using: .utf8) else {
              throw ServiceError.invalidResponse("Invalid JSON arguments")
          }
          
          let decoded = try JSONDecoder().decode([String: AnyCodableValue].self, from: data)
          return decoded
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
  private struct GeminiStreamResponse: Decodable {
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
                      let args: [String: AnyCodableValue]
                  }
              }
          }
      }
  }
  ```

---

**Task 10.3: Weather Service**
- **Acceptance Test Command**: `xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/WeatherServiceTests`
- **Estimated Time**: 3 hours
- **Dependencies**: Task 10.0 (NetworkManager)

**Agent Task 10.3.1: Create Weather Service**
- File: `AirFit/Services/WeatherService.swift`
- **Concrete Acceptance Criteria**:
  - Supports OpenWeatherMap and WeatherAPI providers
  - Response time < 2 seconds
  - Caches results for 10 minutes
  - Handles metric/imperial units
  - Graceful degradation on API failure
  - Test: Mock weather data returns correctly
- Complete Implementation:
  ```swift
  import Foundation
  import CoreLocation
  
  @MainActor
  final class WeatherService: WeatherServiceProtocol {
      
      // MARK: - Properties
      let serviceIdentifier = "weather-service"
      private(set) var isConfigured: Bool = false
      
      private let networkManager = NetworkManager.shared
      private let configuration = ServiceConfiguration.shared
      private let cache = WeatherCache()
      
      private let apiKey: String
      private let cacheExpirationTime: TimeInterval = 600 // 10 minutes
      
      // MARK: - Initialization
      init(apiKey: String = ProcessInfo.processInfo.environment["WEATHER_API_KEY"] ?? "") {
          self.apiKey = apiKey
          self.isConfigured = !apiKey.isEmpty
      }
      
      // MARK: - Service Protocol
      func configure() async throws {
          guard !apiKey.isEmpty else {
              throw ServiceError.invalidConfiguration("Weather API key not provided")
          }
          
          isConfigured = true
          AppLogger.info("Weather service configured", category: .services)
      }
      
      func reset() async {
          await cache.clear()
          isConfigured = false
      }
      
      func healthCheck() async -> ServiceHealth {
          guard isConfigured else {
              return ServiceHealth(
                  status: .unhealthy,
                  lastCheckTime: Date(),
                  responseTime: nil,
                  errorMessage: "Not configured",
                  metadata: [:]
              )
          }
          
          do {
              let startTime = Date()
              
              // Test with a known location (Apple Park)
              _ = try await getCurrentWeather(
                  latitude: 37.3349,
                  longitude: -122.0090
              )
              
              let responseTime = Date().timeIntervalSince(startTime)
              
              return ServiceHealth(
                  status: .healthy,
                  lastCheckTime: Date(),
                  responseTime: responseTime,
                  errorMessage: nil,
                  metadata: ["provider": configuration.weatherProvider.rawValue]
              )
              
          } catch {
              return ServiceHealth(
                  status: .unhealthy,
                  lastCheckTime: Date(),
                  responseTime: nil,
                  errorMessage: error.localizedDescription,
                  metadata: [:]
              )
          }
      }
      
      // MARK: - Weather Data
      func getCurrentWeather(
          latitude: Double,
          longitude: Double
      ) async throws -> WeatherData {
          // Check cache first
          if let cached = getCachedWeather(latitude: latitude, longitude: longitude) {
              AppLogger.debug("Returning cached weather data", category: .services)
              return cached
          }
          
          // Fetch fresh data
          let weather = try await fetchCurrentWeather(
              latitude: latitude,
              longitude: longitude
          )
          
          // Cache result
          await cache.store(weather, for: CLLocationCoordinate2D(
              latitude: latitude,
              longitude: longitude
          ))
          
          return weather
      }
      
      func getForecast(
          latitude: Double,
          longitude: Double,
          days: Int
      ) async throws -> WeatherForecast {
          // Check cache
          let cacheKey = "\(latitude),\(longitude),\(days)"
          if let cached = await cache.getForecast(for: cacheKey) {
              AppLogger.debug("Returning cached forecast data", category: .services)
              return cached
          }
          
          // Fetch fresh data
          let forecast = try await fetchForecast(
              latitude: latitude,
              longitude: longitude,
              days: days
          )
          
          // Cache result
          await cache.store(forecast, for: cacheKey)
          
          return forecast
      }
      
      func getCachedWeather(
          latitude: Double,
          longitude: Double
      ) -> WeatherData? {
          cache.getWeather(for: CLLocationCoordinate2D(
              latitude: latitude,
              longitude: longitude
          ))
      }
      
      // MARK: - Private Methods
      private func fetchCurrentWeather(
          latitude: Double,
          longitude: Double
      ) async throws -> WeatherData {
          guard isConfigured else {
              throw ServiceError.notConfigured
          }
          
          let url = buildWeatherURL(
              latitude: latitude,
              longitude: longitude,
              forecast: false
          )
          
          var request = URLRequest(url: url)
          request.cachePolicy = .reloadIgnoringLocalCacheData
          
          switch configuration.weatherProvider {
          case .openWeatherMap:
              let response = try await networkManager.performRequest(
                  request,
                  expecting: OpenWeatherMapResponse.self
              )
              return mapOpenWeatherMapResponse(response)
              
          case .weatherAPI:
              let response = try await networkManager.performRequest(
                  request,
                  expecting: WeatherAPIResponse.self
              )
              return mapWeatherAPIResponse(response)
          }
      }
      
      private func fetchForecast(
          latitude: Double,
          longitude: Double,
          days: Int
      ) async throws -> WeatherForecast {
          guard isConfigured else {
              throw ServiceError.notConfigured
          }
          
          let url = buildWeatherURL(
              latitude: latitude,
              longitude: longitude,
              forecast: true,
              days: days
          )
          
          var request = URLRequest(url: url)
          request.cachePolicy = .reloadIgnoringLocalCacheData
          
          switch configuration.weatherProvider {
          case .openWeatherMap:
              let response = try await networkManager.performRequest(
                  request,
                  expecting: OpenWeatherMapForecastResponse.self
              )
              return mapOpenWeatherMapForecast(response)
              
          case .weatherAPI:
              let response = try await networkManager.performRequest(
                  request,
                  expecting: WeatherAPIForecastResponse.self
              )
              return mapWeatherAPIForecast(response)
          }
      }
      
      private func buildWeatherURL(
          latitude: Double,
          longitude: Double,
          forecast: Bool,
          days: Int = 5
      ) -> URL {
          var components = URLComponents()
          
          switch configuration.weatherProvider {
          case .openWeatherMap:
              components = URLComponents(
                  url: configuration.weatherProvider.baseURL,
                  resolvingAgainstBaseURL: true
              )!
              
              if forecast {
                  components.path += "/forecast"
              } else {
                  components.path += "/weather"
              }
              
              components.queryItems = [
                  URLQueryItem(name: "lat", value: "\(latitude)"),
                  URLQueryItem(name: "lon", value: "\(longitude)"),
                  URLQueryItem(name: "appid", value: apiKey),
                  URLQueryItem(name: "units", value: "metric")
              ]
              
              if forecast {
                  components.queryItems?.append(
                      URLQueryItem(name: "cnt", value: "\(days * 8)") // 8 per day (3-hour intervals)
                  )
              }
              
          case .weatherAPI:
              components = URLComponents(
                  url: configuration.weatherProvider.baseURL,
                  resolvingAgainstBaseURL: true
              )!
              
              if forecast {
                  components.path += "/forecast.json"
              } else {
                  components.path += "/current.json"
              }
              
              components.queryItems = [
                  URLQueryItem(name: "q", value: "\(latitude),\(longitude)"),
                  URLQueryItem(name: "key", value: apiKey)
              ]
              
              if forecast {
                  components.queryItems?.append(
                      URLQueryItem(name: "days", value: "\(days)")
                  )
              }
          }
          
          return components.url!
      }
      
      // MARK: - Response Mapping
      private func mapOpenWeatherMapResponse(_ response: OpenWeatherMapResponse) -> WeatherData {
          WeatherData(
              temperature: response.main.temp,
              feelsLike: response.main.feelsLike,
              humidity: response.main.humidity,
              pressure: response.main.pressure,
              windSpeed: response.wind.speed,
              windDirection: response.wind.deg,
              cloudCoverage: response.clouds.all,
              condition: mapCondition(response.weather.first?.main ?? ""),
              description: response.weather.first?.description ?? "",
              icon: response.weather.first?.icon ?? "",
              visibility: response.visibility,
              uvIndex: nil,
              sunrise: Date(timeIntervalSince1970: TimeInterval(response.sys.sunrise)),
              sunset: Date(timeIntervalSince1970: TimeInterval(response.sys.sunset)),
              location: WeatherData.Location(
                  name: response.name,
                  country: response.sys.country,
                  latitude: response.coord.lat,
                  longitude: response.coord.lon
              ),
              timestamp: Date()
          )
      }
      
      private func mapWeatherAPIResponse(_ response: WeatherAPIResponse) -> WeatherData {
          WeatherData(
              temperature: response.current.tempC,
              feelsLike: response.current.feelslikeC,
              humidity: response.current.humidity,
              pressure: response.current.pressureMb,
              windSpeed: response.current.windKph * 0.277778, // Convert to m/s
              windDirection: response.current.windDegree,
              cloudCoverage: response.current.cloud,
              condition: mapCondition(response.current.condition.text),
              description: response.current.condition.text,
              icon: response.current.condition.icon,
              visibility: response.current.visKm * 1000, // Convert to meters
              uvIndex: response.current.uv,
              sunrise: nil, // Not provided in current endpoint
              sunset: nil,
              location: WeatherData.Location(
                  name: response.location.name,
                  country: response.location.country,
                  latitude: response.location.lat,
                  longitude: response.location.lon
              ),
              timestamp: Date()
          )
      }
      
      private func mapOpenWeatherMapForecast(_ response: OpenWeatherMapForecastResponse) -> WeatherForecast {
          // Implementation for forecast mapping
          WeatherForecast(
              location: WeatherData.Location(
                  name: response.city.name,
                  country: response.city.country,
                  latitude: response.city.coord.lat,
                  longitude: response.city.coord.lon
              ),
              days: [], // Would map response.list to daily forecasts
              hourly: [] // Would map response.list to hourly forecasts
          )
      }
      
      private func mapWeatherAPIForecast(_ response: WeatherAPIForecastResponse) -> WeatherForecast {
          // Implementation for forecast mapping
          WeatherForecast(
              location: WeatherData.Location(
                  name: response.location.name,
                  country: response.location.country,
                  latitude: response.location.lat,
                  longitude: response.location.lon
              ),
              days: [], // Would map response.forecast.forecastday to daily forecasts
              hourly: [] // Would extract hourly data from forecast days
          )
      }
      
      private func mapCondition(_ condition: String) -> WeatherData.Condition {
          switch condition.lowercased() {
          case "clear":
              return .clear
          case "clouds", "cloudy", "overcast":
              return .cloudy
          case "rain", "drizzle":
              return .rainy
          case "snow":
              return .snowy
          case "thunderstorm":
              return .stormy
          case "mist", "fog", "haze":
              return .foggy
          default:
              return .unknown
          }
      }
  }
  
  // MARK: - Weather Cache
  actor WeatherCache {
      private var weatherCache: [String: CachedWeather] = [:]
      private var forecastCache: [String: CachedForecast] = [:]
      private let expirationTime: TimeInterval = 600 // 10 minutes
      
      struct CachedWeather {
          let data: WeatherData
          let timestamp: Date
      }
      
      struct CachedForecast {
          let data: WeatherForecast
          let timestamp: Date
      }
      
      func getWeather(for location: CLLocationCoordinate2D) -> WeatherData? {
          let key = "\(location.latitude),\(location.longitude)"
          
          guard let cached = weatherCache[key],
                Date().timeIntervalSince(cached.timestamp) < expirationTime else {
              return nil
          }
          
          return cached.data
      }
      
      func getForecast(for key: String) -> WeatherForecast? {
          guard let cached = forecastCache[key],
                Date().timeIntervalSince(cached.timestamp) < expirationTime else {
              return nil
          }
          
          return cached.data
      }
      
      func store(_ weather: WeatherData, for location: CLLocationCoordinate2D) {
          let key = "\(location.latitude),\(location.longitude)"
          weatherCache[key] = CachedWeather(data: weather, timestamp: Date())
      }
      
      func store(_ forecast: WeatherForecast, for key: String) {
          forecastCache[key] = CachedForecast(data: forecast, timestamp: Date())
      }
      
      func clear() {
          weatherCache.removeAll()
          forecastCache.removeAll()
      }
  }
  
  // MARK: - API Response Models
  
  // OpenWeatherMap
  private struct OpenWeatherMapResponse: Decodable {
      let coord: Coord
      let weather: [Weather]
      let main: Main
      let visibility: Int
      let wind: Wind
      let clouds: Clouds
      let sys: Sys
      let name: String
      
      struct Coord: Decodable {
          let lat: Double
          let lon: Double
      }
      
      struct Weather: Decodable {
          let main: String
          let description: String
          let icon: String
      }
      
      struct Main: Decodable {
          let temp: Double
          let feelsLike: Double
          let pressure: Int
          let humidity: Int
          
          private enum CodingKeys: String, CodingKey {
              case temp
              case feelsLike = "feels_like"
              case pressure
              case humidity
          }
      }
      
      struct Wind: Decodable {
          let speed: Double
          let deg: Int
      }
      
      struct Clouds: Decodable {
          let all: Int
      }
      
      struct Sys: Decodable {
          let country: String
          let sunrise: Int
          let sunset: Int
      }
  }
  
  private struct OpenWeatherMapForecastResponse: Decodable {
      let list: [ForecastItem]
      let city: City
      
      struct ForecastItem: Decodable {
          // Forecast item details
      }
      
      struct City: Decodable {
          let name: String
          let country: String
          let coord: OpenWeatherMapResponse.Coord
      }
  }
  
  // WeatherAPI
  private struct WeatherAPIResponse: Decodable {
      let location: Location
      let current: Current
      
      struct Location: Decodable {
          let name: String
          let country: String
          let lat: Double
          let lon: Double
      }
      
      struct Current: Decodable {
          let tempC: Double
          let feelslikeC: Double
          let humidity: Int
          let cloud: Int
          let windKph: Double
          let windDegree: Int
          let pressureMb: Double
          let visKm: Double
          let uv: Double
          let condition: Condition
          
          private enum CodingKeys: String, CodingKey {
              case tempC = "temp_c"
              case feelslikeC = "feelslike_c"
              case humidity, cloud
              case windKph = "wind_kph"
              case windDegree = "wind_degree"
              case pressureMb = "pressure_mb"
              case visKm = "vis_km"
              case uv, condition
          }
          
          struct Condition: Decodable {
              let text: String
              let icon: String
          }
      }
  }
  
  private struct WeatherAPIForecastResponse: Decodable {
      let location: WeatherAPIResponse.Location
      let forecast: Forecast
      
      struct Forecast: Decodable {
          let forecastday: [ForecastDay]
          
          struct ForecastDay: Decodable {
              // Forecast day details
          }
      }
  }
  ```

---

**Task 10.4: Mock Services**
- **Acceptance Test Command**: `xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/MockServiceTests`
- **Estimated Time**: 2 hours
- **Dependencies**: Service protocols from Task 10.0

**Agent Task 10.4.1: Create Mock AI Service**
- File: `AirFit/Services/Mocks/MockAIService.swift`
- **Concrete Acceptance Criteria**:
  - Supports configurable responses
  - Simulates streaming delay
  - Can trigger specific error conditions
  - Thread-safe for testing
  - Test: Mock responses match expected format
- Complete Implementation:
  ```swift
  import Foundation
  
  @MainActor
  final class MockAIService: AIServiceProtocol {
      
      // MARK: - Properties
      let serviceIdentifier = "mock-ai-service"
      private(set) var isConfigured: Bool = false
      
      // Configurable behavior
      var shouldFail = false
      var failureError: Error = ServiceError.unknown(NSError())
      var responseDelay: TimeInterval = 0.1
      var responses: [AIResponse] = []
      
      // Required by protocol
      var activeProvider: AIProvider = .openAI
      var availableModels: [AIModel] = [
          AIModel(id: "gpt-4", name: "GPT-4", provider: .openAI, contextLength: 8192),
          AIModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", provider: .openAI, contextLength: 4096)
      ]
      
      // Tracking
      private(set) var requestCount = 0
      private(set) var lastRequest: AIRequest?
      
      // MARK: - Service Protocol
      func configure() async throws {
          if shouldFail {
              throw failureError
          }
          isConfigured = true
      }
      
      func reset() async {
          isConfigured = false
          requestCount = 0
          lastRequest = nil
      }
      
      func healthCheck() async -> ServiceHealth {
          ServiceHealth(
              status: isConfigured ? .healthy : .unhealthy,
              lastCheckTime: Date(),
              responseTime: 0.05,
              errorMessage: nil,
              metadata: ["type": "mock"]
          )
      }
      
      func validateConfiguration() async throws -> Bool {
          if !isConfigured {
              throw ServiceError.notConfigured
          }
          return true
      }
      
      func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
          if shouldFail {
              throw failureError
          }
          activeProvider = provider
          isConfigured = true
      }
      
      func checkHealth() async -> ServiceHealth {
          return healthCheck()
      }
      
      func estimateTokenCount(for text: String) -> Int {
          // Simple estimation: ~4 characters per token
          return text.count / 4
      }
      
      // MARK: - AI Request Handling
      func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
          requestCount += 1
          lastRequest = request
          
          return AsyncThrowingStream { continuation in
              Task {
                  if self.shouldFail {
                      continuation.finish(throwing: self.failureError)
                      return
                  }
                  
                  // Default responses if none configured
                  let responsesToSend = self.responses.isEmpty ? self.defaultResponses(for: request) : self.responses
                  
                  for response in responsesToSend {
                      // Simulate streaming delay
                      try? await Task.sleep(nanoseconds: UInt64(self.responseDelay * 1_000_000_000))
                      continuation.yield(response)
                  }
                  
                  continuation.finish()
              }
          }
      }
      
      func cancelCurrentRequest() async {
          // No-op for mock
      }
      
      // MARK: - Helper Methods
      private func defaultResponses(for request: AIRequest) -> [AIResponse] {
          var responses: [AIResponse] = []
          
          // Check if this is a function call request
          if let functions = request.availableFunctions, !functions.isEmpty {
              // Simulate function call
              let functionCall = AIFunctionCall(
                  id: UUID().uuidString,
                  functionName: functions.first!.name,
                  arguments: ["mock": AnyCodableValue.string("test")]
              )
              responses.append(.functionCall(functionCall))
          } else {
              // Simulate text streaming
              let words = "This is a mock response from the AI service.".split(separator: " ")
              for word in words {
                  responses.append(.textChunk(String(word) + " "))
              }
          }
          
          responses.append(.streamEnd)
          return responses
      }
      
      // MARK: - Test Helpers
      func setMockResponse(_ text: String) {
          responses = [.textChunk(text), .streamEnd]
      }
      
      func setMockFunctionCall(name: String, arguments: [String: AnyCodableValue]) {
          let functionCall = AIFunctionCall(
              id: UUID().uuidString,
              functionName: name,
              arguments: arguments
          )
          responses = [.functionCall(functionCall), .streamEnd]
      }
      
      func setStreamingResponse(_ chunks: [String]) {
          responses = chunks.map { .textChunk($0) } + [.streamEnd]
      }
  }
  ```

**Agent Task 10.4.2: Create Mock Weather Service**
- File: `AirFit/Services/Mocks/MockWeatherService.swift`
- **Concrete Acceptance Criteria**:
  - Returns consistent test weather data
  - Configurable weather conditions
  - Simulates network delay
  - Supports error simulation
  - Test: All weather conditions return valid data
- Complete Implementation:
  ```swift
  @MainActor
  final class MockWeatherService: WeatherServiceProtocol {
      
      // MARK: - Properties
      let serviceIdentifier = "mock-weather-service"
      private(set) var isConfigured: Bool = true
      
      // Configurable behavior
      var shouldFail = false
      var failureError: Error = ServiceError.networkUnavailable
      var responseDelay: TimeInterval = 0.2
      
      // Mock data
      var mockCondition: WeatherData.Condition = .clear
      var mockTemperature: Double = 22.0
      var mockHumidity: Int = 65
      
      // Cache
      private var cache: [String: WeatherData] = [:]
      
      // MARK: - Service Protocol
      func configure() async throws {
          if shouldFail {
              throw failureError
          }
          isConfigured = true
      }
      
      func reset() async {
          cache.removeAll()
          isConfigured = false
      }
      
      func healthCheck() async -> ServiceHealth {
          ServiceHealth(
              status: .healthy,
              lastCheckTime: Date(),
              responseTime: 0.1,
              errorMessage: nil,
              metadata: ["type": "mock"]
          )
      }
      
      // MARK: - Weather Methods
      func getCurrentWeather(
          latitude: Double,
          longitude: Double
      ) async throws -> WeatherData {
          if shouldFail {
              throw failureError
          }
          
          // Simulate network delay
          try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
          
          return WeatherData(
              temperature: mockTemperature,
              feelsLike: mockTemperature - 2,
              humidity: mockHumidity,
              pressure: 1013,
              windSpeed: 5.5,
              windDirection: 180,
              cloudCoverage: mockCondition == .clear ? 0 : 75,
              condition: mockCondition,
              description: mockCondition.description,
              icon: mockCondition.icon,
              visibility: 10000,
              uvIndex: 5,
              sunrise: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date()),
              sunset: Calendar.current.date(bySettingHour: 19, minute: 45, second: 0, of: Date()),
              location: WeatherData.Location(
                  name: "Mock City",
                  country: "MC",
                  latitude: latitude,
                  longitude: longitude
              ),
              timestamp: Date()
          )
      }
      
      func getForecast(
          latitude: Double,
          longitude: Double,
          days: Int
      ) async throws -> WeatherForecast {
          if shouldFail {
              throw failureError
          }
          
          // Simulate network delay
          try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
          
          var forecastDays: [WeatherForecast.Day] = []
          
          for i in 0..<days {
              let date = Calendar.current.date(byAdding: .day, value: i, to: Date())!
              
              forecastDays.append(WeatherForecast.Day(
                  date: date,
                  maxTemperature: mockTemperature + Double(i),
                  minTemperature: mockTemperature - 5 + Double(i),
                  condition: mockCondition,
                  precipitationChance: mockCondition == .rainy ? 80 : 10
              ))
          }
          
          return WeatherForecast(
              location: WeatherData.Location(
                  name: "Mock City",
                  country: "MC",
                  latitude: latitude,
                  longitude: longitude
              ),
              days: forecastDays,
              hourly: [] // Simplified for mock
          )
      }
      
      func getCachedWeather(
          latitude: Double,
          longitude: Double
      ) -> WeatherData? {
          let key = "\(latitude),\(longitude)"
          return cache[key]
      }
      
      // MARK: - Test Helpers
      func setWeatherCondition(_ condition: WeatherData.Condition, temperature: Double) {
          mockCondition = condition
          mockTemperature = temperature
      }
  }
  
  // MARK: - Weather Data Extensions
  extension WeatherData.Condition {
      var description: String {
          switch self {
          case .clear: return "Clear sky"
          case .cloudy: return "Cloudy"
          case .rainy: return "Rainy"
          case .snowy: return "Snowy"
          case .stormy: return "Thunderstorm"
          case .foggy: return "Foggy"
          case .unknown: return "Unknown"
          }
      }
      
      var icon: String {
          switch self {
          case .clear: return "☀️"
          case .cloudy: return "☁️"
          case .rainy: return "🌧️"
          case .snowy: return "❄️"
          case .stormy: return "⛈️"
          case .foggy: return "🌫️"
          case .unknown: return "❓"
          }
      }
  }
  ```

---

**Task 10.5: Testing**
- **Acceptance Test Command**: `xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/ServicesTests`
- **Estimated Time**: 3 hours
- **Dependencies**: All previous tasks

**Agent Task 10.5.1: Create Service Tests**
- File: `AirFitTests/Services/AIAPIServiceTests.swift`
- **Concrete Acceptance Criteria**:
  - All provider configurations tested
  - Streaming response parsing verified
  - Error conditions handled
  - Performance within limits
  - Test coverage > 80%
- Test Implementation:
  ```swift
  import XCTest
  @testable import AirFit
  
  @MainActor
  final class AIAPIServiceTests: XCTestCase {
      
      var sut: AIAPIService!
      var mockNetworkManager: MockNetworkManager!
      var mockKeyManager: MockAPIKeyManager!
      
      override func setUp() async throws {
          try await super.setUp()
          
          mockNetworkManager = MockNetworkManager()
          mockKeyManager = MockAPIKeyManager()
          
          // Create SUT with dependency injection
          sut = AIAPIService()
          // Note: In production, use dependency injection
      }
      
      override func tearDown() async throws {
          sut = nil
          mockNetworkManager = nil
          mockKeyManager = nil
          try await super.tearDown()
      }
      
      // MARK: - Configuration Tests
      
      func test_configure_withValidAPIKey_shouldSucceed() async throws {
          // Arrange
          mockKeyManager.mockKeys[.openAI] = "sk-test-key"
          
          // Act
          try await sut.configure()
          
          // Assert
          XCTAssertTrue(sut.isConfigured)
      }
      
      func test_configure_withoutAPIKey_shouldThrow() async {
          // Arrange
          mockKeyManager.shouldThrowError = true
          
          // Act & Assert
          do {
              try await sut.configure()
              XCTFail("Should have thrown error")
          } catch {
              XCTAssertTrue(error is APIKeyError)
          }
      }
      
      // MARK: - Request Tests
      
      func test_sendRequest_withOpenAI_shouldFormatCorrectly() async throws {
          // Arrange
          try await setupForProvider(.openAI)
          
          let request = AIRequest(
              systemPrompt: "You are a helpful assistant",
              userMessage: ChatMessage(role: .user, content: "Hello"),
              conversationHistory: [],
              availableFunctions: nil
          )
          
          // Act
          let stream = sut.sendRequest(request)
          var responses: [AIResponse] = []
          
          for try await response in stream {
              responses.append(response)
          }
          
          // Assert
          XCTAssertFalse(responses.isEmpty)
          XCTAssertEqual(mockNetworkManager.lastRequest?.httpMethod, "POST")
          XCTAssertTrue(mockNetworkManager.lastRequest?.url?.absoluteString.contains("chat/completions") ?? false)
      }
      
      func test_sendRequest_withStreaming_shouldReceiveChunks() async throws {
          // Arrange
          try await setupForProvider(.openAI)
          
          mockNetworkManager.mockStreamResponses = [
              Data("data: {\"choices\":[{\"delta\":{\"content\":\"Hello \"}}]}".utf8),
              Data("data: {\"choices\":[{\"delta\":{\"content\":\"world!\"}}]}".utf8),
              Data("data: {\"choices\":[{\"finish_reason\":\"stop\"}]}".utf8),
              Data("data: [DONE]".utf8)
          ]
          
          let request = createTestRequest()
          
          // Act
          var chunks: [String] = []
          let stream = sut.sendRequest(request)
          
          for try await response in stream {
              if case .textChunk(let text) = response {
                  chunks.append(text)
              }
          }
          
          // Assert
          XCTAssertEqual(chunks.joined(), "Hello world!")
      }
      
      func test_sendRequest_withFunctionCall_shouldParseProperly() async throws {
          // Arrange
          try await setupForProvider(.openAI)
          
          let function = AIFunctionSchema(
              name: "getWeather",
              description: "Get weather data",
              parametersSchema: ["type": "object"]
          )
          
          let request = AIRequest(
              systemPrompt: "You are a helpful assistant",
              userMessage: ChatMessage(role: .user, content: "What's the weather?"),
              conversationHistory: [],
              availableFunctions: [function]
          )
          
          mockNetworkManager.mockStreamResponses = [
              Data("""
              data: {"choices":[{"delta":{"tool_calls":[{"function":{"name":"getWeather","arguments":"{\\"location\\":\\"NYC\\"}"}}]}}]}
              """.utf8),
              Data("data: {\"choices\":[{\"finish_reason\":\"tool_calls\"}]}".utf8)
          ]
          
          // Act
          var functionCalls: [AIFunctionCall] = []
          let stream = sut.sendRequest(request)
          
          for try await response in stream {
              if case .functionCall(let call) = response {
                  functionCalls.append(call)
              }
          }
          
          // Assert
          XCTAssertEqual(functionCalls.count, 1)
          XCTAssertEqual(functionCalls.first?.functionName, "getWeather")
      }
      
      // MARK: - Provider Tests
      
      func test_anthropicProvider_shouldUseCorrectHeaders() async throws {
          // Arrange
          try await setupForProvider(.anthropic)
          
          // Act
          _ = sut.sendRequest(createTestRequest())
          
          // Assert
          let headers = mockNetworkManager.lastRequest?.allHTTPHeaderFields ?? [:]
          XCTAssertEqual(headers["x-api-key"], "test-anthropic-key")
          XCTAssertEqual(headers["anthropic-version"], "2023-06-01")
      }
      
      func test_geminiProvider_shouldUseCorrectEndpoint() async throws {
          // Arrange
          try await setupForProvider(.googleGemini)
          
          // Act
          _ = sut.sendRequest(createTestRequest())
          
          // Assert
          let url = mockNetworkManager.lastRequest?.url?.absoluteString ?? ""
          XCTAssertTrue(url.contains("streamGenerateContent"))
          XCTAssertTrue(url.contains("alt=sse"))
      }
      
      // MARK: - Error Handling Tests
      
      func test_networkError_shouldPropagateThrough() async throws {
          // Arrange
          try await setupForProvider(.openAI)
          mockNetworkManager.shouldFail = true
          mockNetworkManager.error = ServiceError.networkUnavailable
          
          // Act & Assert
          let stream = sut.sendRequest(createTestRequest())
          
          do {
              for try await _ in stream {
                  XCTFail("Should not receive responses")
              }
          } catch {
              XCTAssertTrue(error is ServiceError)
          }
      }
      
      func test_rateLimitError_shouldHandleGracefully() async throws {
          // Arrange
          try await setupForProvider(.openAI)
          mockNetworkManager.mockHTTPResponse = HTTPURLResponse(
              url: URL(string: "https://api.openai.com")!,
              statusCode: 429,
              httpVersion: nil,
              headerFields: ["Retry-After": "60"]
          )
          
          // Act & Assert
          let stream = sut.sendRequest(createTestRequest())
          
          do {
              for try await _ in stream {
                  XCTFail("Should not receive responses")
              }
          } catch ServiceError.rateLimitExceeded(let retryAfter) {
              XCTAssertEqual(retryAfter, 60)
          } catch {
              XCTFail("Wrong error type: \(error)")
          }
      }
      
      // MARK: - Performance Tests
      
      func test_sendRequest_performance() async throws {
          // Arrange
          try await setupForProvider(.openAI)
          
          mockNetworkManager.mockStreamResponses = [
              Data("data: {\"choices\":[{\"delta\":{\"content\":\"Test\"}}]}".utf8),
              Data("data: {\"choices\":[{\"finish_reason\":\"stop\"}]}".utf8)
          ]
          
          // Measure
          let start = Date()
          let stream = sut.sendRequest(createTestRequest())
          
          for try await _ in stream {
              // Process
          }
          
          let duration = Date().timeIntervalSince(start)
          
          // Assert
          XCTAssertLessThan(duration, 1.0, "Request should complete quickly")
      }
      
      // MARK: - Helper Methods
      
      private func setupForProvider(_ provider: AIProvider) async throws {
          ServiceConfiguration.shared.configureAIService(
              provider: provider,
              model: provider.defaultModel
          )
          
          mockKeyManager.mockKeys[provider] = "test-\(provider.rawValue)-key"
          try await sut.configure()
      }
      
      private func createTestRequest() -> AIRequest {
          AIRequest(
              systemPrompt: "Test system prompt",
              userMessage: ChatMessage(role: .user, content: "Test message"),
              conversationHistory: [],
              availableFunctions: nil
          )
      }
  }
  
  // MARK: - Mock Classes
  
  class MockNetworkManager: NetworkManagementProtocol {
      var isReachable = true
      var currentNetworkType: NetworkType = .wifi
      
      var shouldFail = false
      var error: Error = ServiceError.unknown(NSError())
      
      var lastRequest: URLRequest?
      var mockResponse: Decodable?
      var mockHTTPResponse: HTTPURLResponse?
      var mockStreamResponses: [Data] = []
      
      func performRequest<T: Decodable>(_ request: URLRequest, expecting: T.Type) async throws -> T {
          lastRequest = request
          
          if shouldFail {
              throw error
          }
          
          if let response = mockResponse as? T {
              return response
          }
          
          throw ServiceError.invalidResponse("No mock response")
      }
      
      func performStreamingRequest(_ request: URLRequest) -> AsyncThrowingStream<Data, Error> {
          lastRequest = request
          
          return AsyncThrowingStream { continuation in
              Task {
                  if self.shouldFail {
                      continuation.finish(throwing: self.error)
                      return
                  }
                  
                  for data in self.mockStreamResponses {
                      continuation.yield(data)
                      try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                  }
                  
                  continuation.finish()
              }
          }
      }
      
      func downloadData(from url: URL) async throws -> Data {
          let request = URLRequest(url: url)
          let (data, response) = try await performRequestWithLogging(request)
          
          guard let httpResponse = response as? HTTPURLResponse else {
              throw ServiceError.invalidResponse("Invalid response type")
          }
          
          try validateHTTPResponse(httpResponse, data: data)
          return data
      }
      
      func uploadData(_ data: Data, to url: URL) async throws -> URLResponse {
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          
          let (_, response) = try await performRequestWithLogging(request)
          
          try validateHTTPResponse(response as! HTTPURLResponse, data: nil)
          return response
      }
      
      // MARK: - Helper Methods
      private func performRequestWithLogging(
          _ request: URLRequest
      ) async throws -> (Data, URLResponse) {
          let startTime = Date()
          
          logger.debug("""
              🌐 Request: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")
              Headers: \(request.allHTTPHeaderFields ?? [:])
              """)
          
          let (data, response) = try await session.data(for: request)
          
          let duration = Date().timeIntervalSince(startTime)
          
          if let httpResponse = response as? HTTPURLResponse {
              logger.debug("""
                  ✅ Response: \(httpResponse.statusCode) in \(String(format: "%.2f", duration))s
                  Size: \(data.count) bytes
                  """)
          }
          
          return (data, response)
      }
      
      private func validateHTTPResponse(
          _ response: HTTPURLResponse,
          data: Data?
      ) throws {
          switch response.statusCode {
          case 200...299:
              return
          case 401:
              throw ServiceError.authenticationFailed("Invalid API key")
          case 429:
              let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                  .flatMap { Double($0) }
              throw ServiceError.rateLimitExceeded(retryAfter: retryAfter)
          case 400...499:
              let message = data.flatMap { try? JSONDecoder().decode(ErrorResponse.self, from: $0) }?.error ?? "Client error"
              throw ServiceError.providerError(code: "\(response.statusCode)", message: message)
          case 500...599:
              throw ServiceError.providerError(code: "\(response.statusCode)", message: "Server error")
          default:
              throw ServiceError.invalidResponse("Unexpected status code: \(response.statusCode)")
          }
      }
  }
  
  actor MockAPIKeyManager: APIKeyManagementProtocol {
      var mockKeys: [AIProvider: String] = [:]
      var shouldThrowError = false
      
      func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
          if shouldThrowError {
              throw APIKeyError.keychainError(NSError())
          }
          mockKeys[provider] = key
      }
      
      func getAPIKey(for provider: AIProvider) async throws -> String {
          if shouldThrowError {
              throw APIKeyError.keyNotFound(provider)
          }
          
          guard let key = mockKeys[provider] else {
              throw APIKeyError.keyNotFound(provider)
          }
          
          return key
      }
      
      func deleteAPIKey(for provider: AIProvider) async throws {
          mockKeys.removeValue(forKey: provider)
      }
      
      func hasAPIKey(for provider: AIProvider) async -> Bool {
          mockKeys[provider] != nil
      }
      
      func getAllConfiguredProviders() async -> [AIProvider] {
          Array(mockKeys.keys)
      }
  }
  ```

---

**6. Acceptance Criteria for Module Completion**

- ✅ All 4 AI providers supported with proper request/response handling
- ✅ Streaming responses work correctly for all providers
- ✅ Function calling parsed and handled properly
- ✅ API keys stored securely in Keychain (not UserDefaults)
- ✅ Weather service with caching and multiple providers
- ✅ Network layer with retry logic and monitoring
- ✅ Comprehensive error handling with specific error types
- ✅ Mock services for testing
- ✅ Performance: AI requests start streaming < 2s
- ✅ Performance: Weather requests complete < 2s
- ✅ Memory usage < 50MB for service layer
- ✅ Test coverage ≥ 80%

**7. Module Dependencies**

- **Requires Completion Of:** Module 1, Module 2, Module 5
- **Must Be Completed Before:** Module 11 (Settings for API key input)
- **Can Run In Parallel With:** Module 9, Module 12

**8. Performance Requirements**

- API key operations: < 100ms
- Network reachability check: < 50ms
- AI streaming start: < 2s
- Weather data fetch: < 2s
- Cache lookups: < 10ms
- Memory usage: < 50MB total
- Concurrent requests: Support up to 5

**9. Module Verification Commands**

```bash
# Run all module tests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0' \
  -only-testing:AirFitTests/ServiceProtocolTests \
  -only-testing:AirFitTests/NetworkManagerTests \
  -only-testing:AirFitTests/APIKeyManagerTests \
  -only-testing:AirFitTests/AIAPIServiceTests \
  -only-testing:AirFitTests/WeatherServiceTests \
  -only-testing:AirFitTests/MockServiceTests

# Verify Keychain usage (not UserDefaults)
grep -r "UserDefaults" AirFit/Services/Security/ | grep -v "migration" || echo "✓ No UserDefaults in security"

# Check for hardcoded API keys
grep -r "sk-" AirFit/ --exclude-dir=Tests || echo "✓ No hardcoded API keys"

# Verify SwiftLint compliance
swiftlint lint --path AirFit/Services --strict

# Performance profiling
instruments -t "Network" -D trace.trace AirFit.app
```

**10. Implementation Notes**

- The service layer is designed to be provider-agnostic
- All API keys must be stored in Keychain for security
- Network monitoring helps provide better user experience
- Caching reduces API calls and improves performance
- Mock services are essential for reliable testing
- The modular design allows easy addition of new providers
- Error handling should be comprehensive but user-friendly
- All services should gracefully degrade when offline

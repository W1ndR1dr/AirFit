**Modular Sub-Document 5: AI Persona Engine & CoachEngine (Core AI Logic)**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `User`, `OnboardingProfile`, `CoachMessage`.
    *   Completion of Modular Sub-Document 4: HealthKit & Context Aggregation Module – `HealthContextSnapshot`, `ContextAssembler`.
    *   (Implicit) Modular Sub-Document 10 (Services Layer) will eventually provide the full `AIServiceProtocol` implementation. For now, a mock or stubbed version of `AIServiceProtocol` is needed.
**Date:** May 25, 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To implement the core AI coaching intelligence that powers AirFit's personalized fitness experience, managing all AI-driven interactions through a sophisticated persona engine that adapts to each user's unique profile, health context, and communication preferences.
*   **Responsibilities:**
    *   Dynamic persona-driven prompt construction
    *   Real-time health context integration
    *   Streaming AI response handling
    *   Function calling orchestration
    *   Local command preprocessing
    *   Conversation history management
    *   Error handling and fallback responses
    *   Token optimization and context pruning
    *   Multi-model routing support
    *   Performance monitoring and analytics
*   **Key Components:**
    *   `CoachEngine.swift` - Central AI orchestration engine
    *   `PersonaEngine.swift` - Dynamic persona prompt builder
    *   `FunctionCallDispatcher.swift` - Function execution coordinator
    *   `LocalCommandParser.swift` - Offline command processor
    *   `AIServiceProtocols.swift` - Service interfaces
    *   `ConversationManager.swift` - History and context management
    *   `PromptTemplates.swift` - System prompt templates

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Logging, constants, utilities
    *   Module 2: SwiftData models (User, OnboardingProfile, CoachMessage)
    *   Module 4: HealthContext and aggregation
    *   System Prompt specifications
    *   Function definitions from architecture spec
*   **Outputs:**
    *   Complete AI coaching functionality
    *   Conversation persistence
    *   Function execution framework
    *   Streaming response infrastructure

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 5.0: Define AI Communication Models**

**Agent Task 5.0.1: Create AI Communication Types**
- File: `AirFit/Core/Models/AI/AIModels.swift`
- Complete Implementation:
  ```swift
  import Foundation
  
  // MARK: - Core AI Types
  
  enum MessageRole: String, Codable, Sendable {
      case system
      case user
      case assistant
      case function
      case tool
  }
  
  struct ChatMessage: Codable, Sendable {
      let id: UUID
      let role: MessageRole
      let content: String
      let name: String? // For function/tool messages
      let functionCall: FunctionCall?
      let timestamp: Date
      
      init(
          id: UUID = UUID(),
          role: MessageRole,
          content: String,
          name: String? = nil,
          functionCall: FunctionCall? = nil,
          timestamp: Date = Date()
      ) {
          self.id = id
          self.role = role
          self.content = content
          self.name = name
          self.functionCall = functionCall
          self.timestamp = timestamp
      }
  }
  
  // MARK: - Function Calling
  
  struct FunctionCall: Codable, Sendable {
      let name: String
      let arguments: [String: AnyCodable]
      
      init(name: String, arguments: [String: Any] = [:]) {
          self.name = name
          self.arguments = arguments.mapValues { AnyCodable($0) }
      }
  }
  
  struct FunctionDefinition: Codable, Sendable {
      let name: String
      let description: String
      let parameters: FunctionParameters
  }
  
  struct FunctionParameters: Codable, Sendable {
      let type: String = "object"
      let properties: [String: ParameterDefinition]
      let required: [String]
  }
  
  struct ParameterDefinition: Codable, Sendable {
      let type: String
      let description: String
      let enumValues: [String]?
      let minimum: Double?
      let maximum: Double?
      let items: Box<ParameterDefinition>? // For array types
      
      enum CodingKeys: String, CodingKey {
          case type, description
          case enumValues = "enum"
          case minimum, maximum, items
      }
  }
  
  // Box type to handle recursive definitions
  final class Box<T: Codable>: Codable {
      let value: T
      
      init(_ value: T) {
          self.value = value
      }
      
      init(from decoder: Decoder) throws {
          value = try T(from: decoder)
      }
      
      func encode(to encoder: Encoder) throws {
          try value.encode(to: encoder)
      }
  }
  
  // MARK: - AI Request/Response
  
  struct AIRequest: Sendable {
      let id: UUID = UUID()
      let systemPrompt: String
      let messages: [ChatMessage]
      let functions: [FunctionDefinition]?
      let temperature: Double
      let maxTokens: Int?
      let stream: Bool
      let user: String // User identifier for rate limiting
      
      init(
          systemPrompt: String,
          messages: [ChatMessage],
          functions: [FunctionDefinition]? = nil,
          temperature: Double = 0.7,
          maxTokens: Int? = nil,
          stream: Bool = true,
          user: String
      ) {
          self.systemPrompt = systemPrompt
          self.messages = messages
          self.functions = functions
          self.temperature = temperature
          self.maxTokens = maxTokens
          self.stream = stream
          self.user = user
      }
  }
  
  enum AIResponse: Sendable {
      case text(String)
      case textDelta(String)
      case functionCall(FunctionCall)
      case error(AIError)
      case done(usage: TokenUsage?)
  }
  
  struct TokenUsage: Codable, Sendable {
      let promptTokens: Int
      let completionTokens: Int
      let totalTokens: Int
  }
  
  enum AIError: LocalizedError, Sendable {
      case networkError(String)
      case rateLimitExceeded(retryAfter: TimeInterval?)
      case invalidResponse(String)
      case modelOverloaded
      case contextLengthExceeded
      case unauthorized
      
      var errorDescription: String? {
          switch self {
          case .networkError(let message):
              return "Network error: \(message)"
          case .rateLimitExceeded(let retryAfter):
              if let retry = retryAfter {
                  return "Rate limit exceeded. Try again in \(Int(retry)) seconds."
              }
              return "Rate limit exceeded. Please try again later."
          case .invalidResponse(let message):
              return "Invalid response: \(message)"
          case .modelOverloaded:
              return "AI service is currently overloaded. Please try again."
          case .contextLengthExceeded:
              return "Conversation is too long. Starting a new context."
          case .unauthorized:
              return "AI service authorization failed."
          }
      }
  }
  
  // MARK: - AnyCodable for flexible JSON handling
  
  struct AnyCodable: Codable {
      let value: Any
      
      init(_ value: Any) {
          self.value = value
      }
      
      init(from decoder: Decoder) throws {
          let container = try decoder.singleValueContainer()
          
          if container.decodeNil() {
              self.value = NSNull()
          } else if let bool = try? container.decode(Bool.self) {
              self.value = bool
          } else if let int = try? container.decode(Int.self) {
              self.value = int
          } else if let double = try? container.decode(Double.self) {
              self.value = double
          } else if let string = try? container.decode(String.self) {
              self.value = string
          } else if let array = try? container.decode([AnyCodable].self) {
              self.value = array.map { $0.value }
          } else if let dictionary = try? container.decode([String: AnyCodable].self) {
              self.value = dictionary.mapValues { $0.value }
          } else {
              throw DecodingError.dataCorruptedError(
                  in: container,
                  debugDescription: "Unable to decode value"
              )
          }
      }
      
      func encode(to encoder: Encoder) throws {
          var container = encoder.singleValueContainer()
          
          switch value {
          case is NSNull:
              try container.encodeNil()
          case let bool as Bool:
              try container.encode(bool)
          case let int as Int:
              try container.encode(int)
          case let double as Double:
              try container.encode(double)
          case let string as String:
              try container.encode(string)
          case let array as [Any]:
              try container.encode(array.map { AnyCodable($0) })
          case let dictionary as [String: Any]:
              try container.encode(dictionary.mapValues { AnyCodable($0) })
          default:
              throw EncodingError.invalidValue(
                  value,
                  EncodingError.Context(
                      codingPath: encoder.codingPath,
                      debugDescription: "Unable to encode value"
                  )
              )
          }
      }
  }
  ```

---

**Task 5.1: Implement Local Command Parser**

**Agent Task 5.1.1: Create LocalCommandParser**
- File: `AirFit/Modules/AI/Parsing/LocalCommandParser.swift`
- Complete Implementation:
  ```swift
  import Foundation
  import RegexBuilder
  
  enum LocalCommand: Equatable {
      case showDashboard
      case navigateToTab(AppTab)
      case logWater(amount: Double, unit: WaterUnit)
      case quickLog(type: QuickLogType)
      case showSettings
      case showProfile
      case startWorkout
      case help
      case none
      
      enum WaterUnit: String {
          case ounces = "oz"
          case milliliters = "ml"
          case liters = "l"
          case cups = "cup"
          
          var toMilliliters: Double {
              switch self {
              case .ounces: return 29.5735
              case .milliliters: return 1.0
              case .liters: return 1000.0
              case .cups: return 236.588
              }
          }
      }
      
      enum QuickLogType {
          case meal(MealType)
          case mood
          case energy
          case weight
      }
  }
  
  @MainActor
  final class LocalCommandParser {
      // MARK: - Properties
      private let waterPattern: Regex<(Substring, Substring?, Substring?)>
      private let navigationCommands: [String: LocalCommand]
      private let quickLogPatterns: [(pattern: String, command: LocalCommand)]
      
      // MARK: - Initialization
      init() {
          // Initialize water logging pattern
          waterPattern = Regex {
              "log"
              ZeroOrMore(.whitespace)
              Optionally {
                  TryCapture {
                      OneOrMore(.digit)
                      Optionally {
                          "."
                          OneOrMore(.digit)
                      }
                  } transform: { Double($0) }
              }
              ZeroOrMore(.whitespace)
              Optionally {
                  TryCapture {
                      ChoiceOf {
                          "oz"
                          "ounces"
                          "ml"
                          "milliliters"
                          "l"
                          "liters"
                          "cup"
                          "cups"
                      }
                  } transform: { String($0) }
              }
              ZeroOrMore(.whitespace)
              "water"
          }
          .ignoresCase()
          
          // Navigation shortcuts
          navigationCommands = [
              "dashboard": .showDashboard,
              "home": .showDashboard,
              "settings": .showSettings,
              "profile": .showProfile,
              "start workout": .startWorkout,
              "workout": .startWorkout,
              "help": .help,
              "?": .help
          ]
          
          // Quick log patterns
          quickLogPatterns = [
              ("log breakfast", .quickLog(type: .meal(.breakfast))),
              ("log lunch", .quickLog(type: .meal(.lunch))),
              ("log dinner", .quickLog(type: .meal(.dinner))),
              ("log snack", .quickLog(type: .meal(.snack))),
              ("log mood", .quickLog(type: .mood)),
              ("log energy", .quickLog(type: .energy)),
              ("log weight", .quickLog(type: .weight))
          ]
      }
      
      // MARK: - Public Methods
      func parse(_ input: String) -> LocalCommand {
          let normalizedInput = input
              .trimmingCharacters(in: .whitespacesAndNewlines)
              .lowercased()
          
          // Check water logging
          if let waterCommand = parseWaterCommand(normalizedInput) {
              return waterCommand
          }
          
          // Check navigation commands
          for (pattern, command) in navigationCommands {
              if normalizedInput.contains(pattern) {
                  return command
              }
          }
          
          // Check quick log commands
          for (pattern, command) in quickLogPatterns {
              if normalizedInput.contains(pattern) {
                  return command
              }
          }
          
          // Check for tab navigation
          if let tabCommand = parseTabNavigation(normalizedInput) {
              return tabCommand
          }
          
          return .none
      }
      
      // MARK: - Private Methods
      private func parseWaterCommand(_ input: String) -> LocalCommand? {
          guard let match = try? waterPattern.firstMatch(in: input) else {
              return nil
          }
          
          let amount = match.1 ?? 8.0 // Default to 8oz
          let unitString = match.2?.lowercased() ?? "oz"
          
          let unit: LocalCommand.WaterUnit = {
              switch unitString {
              case "ml", "milliliters": return .milliliters
              case "l", "liters": return .liters
              case "cup", "cups": return .cups
              default: return .ounces
              }
          }()
          
          return .logWater(amount: amount, unit: unit)
      }
      
      private func parseTabNavigation(_ input: String) -> LocalCommand? {
          let tabPatterns: [(pattern: String, tab: AppTab)] = [
              ("food|nutrition|meal", .food),
              ("workout|exercise|gym", .workouts),
              ("coach|chat|ai", .coach),
              ("setting|preference", .settings)
          ]
          
          for (pattern, tab) in tabPatterns {
              if input.range(of: pattern, options: .regularExpression) != nil {
                  return .navigateToTab(tab)
              }
          }
          
          return nil
      }
  }
  
  // MARK: - Command Execution
  extension LocalCommand {
      var requiresNavigation: Bool {
          switch self {
          case .showDashboard, .navigateToTab, .showSettings, 
               .showProfile, .startWorkout:
              return true
          default:
              return false
          }
      }
      
      var analyticsName: String {
          switch self {
          case .showDashboard: return "show_dashboard"
          case .navigateToTab(let tab): return "navigate_\(tab)"
          case .logWater: return "log_water"
          case .quickLog(let type): return "quick_log_\(type)"
          case .showSettings: return "show_settings"
          case .showProfile: return "show_profile"
          case .startWorkout: return "start_workout"
          case .help: return "help"
          case .none: return "none"
          }
      }
  }
  ```

---

**Task 5.2: Implement Persona Engine**

**Agent Task 5.2.1: Create PersonaEngine**
- File: `AirFit/Modules/AI/PersonaEngine.swift`
- Complete Implementation:
  ```swift
  import Foundation
  
  @MainActor
  final class PersonaEngine {
      // MARK: - Properties
      private let systemPromptTemplate: String
      
      // MARK: - Initialization
      init() {
          // Load system prompt template from SystemPrompt.md content
          self.systemPromptTemplate = """
          ## I. CORE IDENTITY & PRIME DIRECTIVE
          You are "AirFit Coach," a bespoke AI fitness and wellness coach. Your sole purpose is to embody and enact the unique coaching persona defined by the user, leveraging their comprehensive health data to provide insightful, motivational, and actionable guidance.
          
          **Critical Rule: You MUST always interact as this specific coach persona. Never break character. Never mention you are an AI or a language model. Your responses should feel as if they are coming from a dedicated, human coach who deeply understands the user.**
          
          ## II. USER-DEFINED PERSONA BLUEPRINT (INJECTED VIA API)
          This JSON object is the absolute and non-negotiable source of truth for YOUR personality, communication style, and coaching approach for THIS user. Internalize and consistently apply these characteristics in every interaction.
          
          {{USER_PROFILE_JSON}}
          
          ## III. DYNAMIC CONTEXT (INJECTED PER INTERACTION VIA API)
          For each user message, you will receive the following to inform your response:
          
          HealthContextSnapshot:
          {{HEALTH_CONTEXT_JSON}}
          
          ConversationHistory:
          {{CONVERSATION_HISTORY_JSON}}
          
          CurrentDateTimeUTC:
          {{CURRENT_DATETIME_UTC}}
          
          UserTimeZone:
          {{USER_TIMEZONE}}
          
          ## IV. HIGH-VALUE FUNCTION CALLING CAPABILITIES
          You can request the execution of specific in-app functions when your intelligent analysis indicates it's the most effective way to assist the user.
          
          If you decide a function call is necessary, your response MUST be ONLY the following JSON object structure:
          
          {
            "action": "function_call",
            "function_name": "NameOfTheFunctionToCall",
            "parameters": {
              "paramName1": "value1",
              "paramName2": "value2"
            }
          }
          
          Available Functions:
          {{AVAILABLE_FUNCTIONS_JSON}}
          
          ## V. CORE BEHAVIORAL & COMMUNICATION GUIDELINES
          1. Persona Primacy: Your persona is paramount. Every word must align.
          2. Contextual Synthesis: Seamlessly weave health data into responses.
          3. Goal-Oriented: Always keep the user's goal in mind.
          4. Proactive (Within Persona): Offer advice based on your style blend.
          5. Empathy and Safety: Advise medical consultation for health concerns.
          6. Clarity and Conciseness: Be clear and appropriately detailed.
          7. Positive Framing: Use empowering language per your persona.
          8. Respect Boundaries: Honor sleep windows and preferences.
          9. Markdown for Readability: Use formatting sparingly but effectively.
          
          ## VI. RESPONSE GENERATION
          Your primary output is conversational text. Strive for responses that are natural, engaging, and consistently reflect the unique AI persona you are embodying for this user.
          """
      }
      
      // MARK: - Public Methods
      func buildSystemPrompt(
          userProfile: PersonaProfile,
          healthContext: HealthContextSnapshot,
          conversationHistory: [ChatMessage],
          availableFunctions: [FunctionDefinition]
      ) throws -> String {
          // Prepare JSON representations
          let userProfileJSON = try JSONEncoder.airFitEncoder.encodeToString(userProfile)
          let healthContextJSON = try JSONEncoder.airFitEncoder.encodeToString(healthContext)
          let conversationJSON = try JSONEncoder.airFitEncoder.encodeToString(
              conversationHistory.suffix(20) // Last 20 messages for context
          )
          let functionsJSON = try JSONEncoder.airFitEncoder.encodeToString(availableFunctions)
          
          // Get current time info
          let now = Date()
          let formatter = ISO8601DateFormatter()
          let utcString = formatter.string(from: now)
          
          // Build the prompt
          let prompt = systemPromptTemplate
              .replacingOccurrences(of: "{{USER_PROFILE_JSON}}", with: userProfileJSON)
              .replacingOccurrences(of: "{{HEALTH_CONTEXT_JSON}}", with: healthContextJSON)
              .replacingOccurrences(of: "{{CONVERSATION_HISTORY_JSON}}", with: conversationJSON)
              .replacingOccurrences(of: "{{CURRENT_DATETIME_UTC}}", with: utcString)
              .replacingOccurrences(of: "{{USER_TIMEZONE}}", with: userProfile.timezone ?? "UTC")
              .replacingOccurrences(of: "{{AVAILABLE_FUNCTIONS_JSON}}", with: functionsJSON)
          
          // Validate prompt length
          let estimatedTokens = prompt.count / 4 // Rough estimate
          if estimatedTokens > 8000 { // Leave room for response
              AppLogger.warning("System prompt may be too long: ~\(estimatedTokens) tokens", category: .ai)
          }
          
          return prompt
      }
      
      func adjustPersonaForContext(
          baseProfile: PersonaProfile,
          healthContext: HealthContextSnapshot
      ) -> PersonaProfile {
          var adjusted = baseProfile
          
          // Adjust based on user's current state
          if let energy = healthContext.subjectiveData.energyLevel, energy <= 2 {
              // User is low energy - be more gentle
              if var blend = adjusted.coachingStyle.blend {
                  blend.encouragingEmpathetic = min(
                      (blend.encouragingEmpathetic ?? 0) + 20,
                      100
                  )
                  blend.authoritativeDirect = max(
                      (blend.authoritativeDirect ?? 0) - 10,
                      0
                  )
                  adjusted.coachingStyle.blend = blend
              }
          }
          
          // Adjust for time of day
          switch healthContext.environment.timeOfDay {
          case .earlyMorning, .morning:
              // More energetic in morning
              break
          case .evening, .night:
              // More calm in evening
              if var blend = adjusted.coachingStyle.blend {
                  blend.playfullyProvocative = max(
                      (blend.playfullyProvocative ?? 0) - 10,
                      0
                  )
                  adjusted.coachingStyle.blend = blend
              }
          default:
              break
          }
          
          return adjusted
      }
  }
  
  // MARK: - JSON Encoder Extension
  extension JSONEncoder {
      static let airFitEncoder: JSONEncoder = {
          let encoder = JSONEncoder()
          encoder.outputFormatting = [.sortedKeys]
          encoder.dateEncodingStrategy = .iso8601
          return encoder
      }()
      
      func encodeToString<T: Encodable>(_ value: T) throws -> String {
          let data = try encode(value)
          guard let string = String(data: data, encoding: .utf8) else {
              throw EncodingError.invalidValue(
                  value,
                  EncodingError.Context(
                      codingPath: [],
                      debugDescription: "Failed to convert data to UTF-8 string"
                  )
              )
          }
          return string
      }
  }
  ```

---

**Task 5.3: Implement Coach Engine**

**Agent Task 5.3.1: Create CoachEngine**
- File: `AirFit/Modules/AI/CoachEngine.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  import Observation
  
  @MainActor
  @Observable
  final class CoachEngine {
      // MARK: - State Properties
      private(set) var isProcessing = false
      private(set) var currentResponse = ""
      private(set) var error: Error?
      private(set) var activeConversationId: UUID?
      
      // MARK: - Dependencies
      private let modelContext: ModelContext
      private let aiService: AIServiceProtocol
      private let personaEngine: PersonaEngine
      private let contextAssembler: ContextAssembler
      private let functionDispatcher: FunctionCallDispatcher
      private let localCommandParser: LocalCommandParser
      private let conversationManager: ConversationManager
      
      // MARK: - Private State
      private var responseBuffer = ""
      private var activeTask: Task<Void, Never>?
      
      // MARK: - Initialization
      init(
          modelContext: ModelContext,
          aiService: AIServiceProtocol,
          personaEngine: PersonaEngine,
          contextAssembler: ContextAssembler,
          functionDispatcher: FunctionCallDispatcher,
          localCommandParser: LocalCommandParser,
          conversationManager: ConversationManager
      ) {
          self.modelContext = modelContext
          self.aiService = aiService
          self.personaEngine = personaEngine
          self.contextAssembler = contextAssembler
          self.functionDispatcher = functionDispatcher
          self.localCommandParser = localCommandParser
          self.conversationManager = conversationManager
      }
      
      // MARK: - Public Methods
      func processUserMessage(_ text: String, for user: User) async {
          // Cancel any existing processing
          activeTask?.cancel()
          
          // Reset state
          error = nil
          currentResponse = ""
          responseBuffer = ""
          
          // Create conversation if needed
          if activeConversationId == nil {
              activeConversationId = UUID()
          }
          
          activeTask = Task {
              await processMessageInternal(text, for: user)
          }
      }
      
      func clearConversation() {
          activeConversationId = UUID()
          currentResponse = ""
          error = nil
      }
      
      // MARK: - Private Methods
      private func processMessageInternal(_ text: String, for user: User) async {
          isProcessing = true
          defer { isProcessing = false }
          
          // Save user message
          let userMessage = try? await conversationManager.saveUserMessage(
              text,
              for: user,
              conversationId: activeConversationId!
          )
          
          // Check for local commands first
          let localCommand = localCommandParser.parse(text)
          if localCommand != .none {
              await handleLocalCommand(localCommand, for: user)
              return
          }
          
          // Process with AI
          do {
              try await processAIRequest(text, for: user)
          } catch {
              self.error = error
              await handleError(error, for: user)
          }
      }
      
      private func processAIRequest(_ text: String, for user: User) async throws {
          // Get user profile
          guard let profile = user.onboardingProfile,
                let personaData = profile.personaProfile else {
              throw CoachEngineError.missingProfile
          }
          
          // Assemble context
          let healthContext = try await contextAssembler.assembleSnapshot(for: user)
          
          // Get conversation history
          let history = try await conversationManager.getRecentMessages(
              for: user,
              conversationId: activeConversationId!,
              limit: 20
          )
          
          // Adjust persona for context
          let adjustedPersona = personaEngine.adjustPersonaForContext(
              baseProfile: personaData,
              healthContext: healthContext
          )
          
          // Build system prompt
          let systemPrompt = try personaEngine.buildSystemPrompt(
              userProfile: adjustedPersona,
              healthContext: healthContext,
              conversationHistory: history,
              availableFunctions: FunctionRegistry.availableFunctions
          )
          
          // Create AI request
          let request = AIRequest(
              systemPrompt: systemPrompt,
              messages: history + [ChatMessage(role: .user, content: text)],
              functions: FunctionRegistry.availableFunctions,
              temperature: 0.7,
              stream: true,
              user: user.id.uuidString
          )
          
          // Process streaming response
          let stream = try await aiService.streamCompletion(request)
          
          var assistantMessage: CoachMessage?
          var functionCall: FunctionCall?
          
          for try await response in stream {
              guard !Task.isCancelled else { break }
              
              switch response {
              case .textDelta(let delta):
                  responseBuffer += delta
                  currentResponse = responseBuffer
                  
                  // Create or update assistant message
                  if assistantMessage == nil {
                      assistantMessage = try await conversationManager.createAssistantMessage(
                          responseBuffer,
                          for: user,
                          conversationId: activeConversationId!
                      )
                  } else {
                      assistantMessage?.content = responseBuffer
                  }
                  
              case .text(let fullText):
                  responseBuffer = fullText
                  currentResponse = fullText
                  
              case .functionCall(let call):
                  functionCall = call
                  
              case .done(let usage):
                  // Save final message
                  if let message = assistantMessage {
                      message.content = responseBuffer
                      message.totalTokens = usage?.totalTokens
                      try modelContext.save()
                  }
                  
                  // Handle function call if present
                  if let call = functionCall {
                      await handleFunctionCall(call, for: user)
                  }
                  
                  // Log usage
                  if let usage = usage {
                      AppLogger.info(
                          "AI completion: \(usage.totalTokens) tokens",
                          category: .ai
                      )
                  }
                  
              case .error(let aiError):
                  throw aiError
              }
          }
      }
      
      private func handleLocalCommand(_ command: LocalCommand, for user: User) async {
          // Log analytics
          AppLogger.info("Local command: \(command.analyticsName)", category: .ai)
          
          // Create a system message for the command
          let message: String
          
          switch command {
          case .logWater(let amount, let unit):
              let ml = amount * unit.toMilliliters
              message = "I've logged \(amount) \(unit.rawValue) of water for you. 💧"
              
              // TODO: Actually log water to the data layer
              NotificationCenter.default.post(
                  name: .logWater,
                  object: nil,
                  userInfo: ["amount": ml]
              )
              
          case .showDashboard, .navigateToTab, .showSettings, .showProfile, .startWorkout:
              message = "I'll take you there right away!"
              
              // Post navigation notification
              NotificationCenter.default.post(
                  name: .executeLocalCommand,
                  object: nil,
                  userInfo: ["command": command]
              )
              
          case .quickLog(let type):
              message = "Opening quick log for \(type)..."
              
              NotificationCenter.default.post(
                  name: .executeLocalCommand,
                  object: nil,
                  userInfo: ["command": command]
              )
              
          case .help:
              message = """
              Here are some quick commands you can use:
              • "log water" or "log 16oz water"
              • "show dashboard" or "home"
              • "start workout"
              • "log breakfast/lunch/dinner/snack"
              • "settings" or "profile"
              
              Or just chat with me naturally about your fitness goals!
              """
              
          case .none:
              return
          }
          
          // Save system response
          currentResponse = message
          try? await conversationManager.createAssistantMessage(
              message,
              for: user,
              conversationId: activeConversationId!,
              isLocalCommand: true
          )
      }
      
      private func handleFunctionCall(_ call: FunctionCall, for user: User) async {
          AppLogger.info("Function call: \(call.name)", category: .ai)
          
          do {
              // Dispatch function
              let result = try await functionDispatcher.execute(
                  call,
                  for: user,
                  context: FunctionContext(
                      modelContext: modelContext,
                      conversationId: activeConversationId!
                  )
              )
              
              // Create function result message
              let resultMessage = ChatMessage(
                  role: .function,
                  content: result.message,
                  name: call.name
              )
              
              // Get updated context for follow-up
              let healthContext = try await contextAssembler.assembleSnapshot(for: user)
              let history = try await conversationManager.getRecentMessages(
                  for: user,
                  conversationId: activeConversationId!,
                  limit: 20
              )
              
              // Request follow-up response from AI
              let followUpRequest = AIRequest(
                  systemPrompt: try personaEngine.buildSystemPrompt(
                      userProfile: user.onboardingProfile!.personaProfile!,
                      healthContext: healthContext,
                      conversationHistory: history + [resultMessage],
                      availableFunctions: FunctionRegistry.availableFunctions
                  ),
                  messages: history + [resultMessage],
                  temperature: 0.7,
                  stream: true,
                  user: user.id.uuidString
              )
              
              // Process follow-up
              responseBuffer = ""
              try await processAIRequest("", for: user)
              
          } catch {
              AppLogger.error("Function execution failed", error: error, category: .ai)
              currentResponse = "I encountered an issue with that request. Let me try a different approach."
          }
      }
      
      private func handleError(_ error: Error, for user: User) async {
          let errorMessage: String
          
          if let aiError = error as? AIError {
              errorMessage = aiError.localizedDescription
          } else if error is CancellationError {
              return // Don't show error for cancellation
          } else {
              errorMessage = "I'm having trouble connecting right now. Please try again in a moment."
          }
          
          currentResponse = errorMessage
          
          // Save error as system message
          try? await conversationManager.createAssistantMessage(
              errorMessage,
              for: user,
              conversationId: activeConversationId!,
              isError: true
          )
      }
  }
  
  // MARK: - Errors
  enum CoachEngineError: LocalizedError {
      case missingProfile
      case invalidContext
      
      var errorDescription: String? {
          switch self {
          case .missingProfile:
              return "Please complete your profile setup first"
          case .invalidContext:
              return "Unable to gather current context"
          }
      }
  }
  
  // MARK: - Notification Names
  extension Notification.Name {
      static let executeLocalCommand = Notification.Name("executeLocalCommand")
      static let logWater = Notification.Name("logWater")
  }
  ```

---

**Task 5.4: Implement Function Call System**

**Agent Task 5.4.1: Create Function Registry**
- File: `AirFit/Modules/AI/Functions/FunctionRegistry.swift`
- Implementation:
  ```swift
  import Foundation
  
  enum FunctionRegistry {
      static let availableFunctions: [FunctionDefinition] = [
          // Workout Planning
          FunctionDefinition(
              name: "generatePersonalizedWorkoutPlan",
              description: "Creates a new, tailored workout plan considering user goals, context, and feedback",
              parameters: FunctionParameters(
                  properties: [
                      "goalFocus": ParameterDefinition(
                          type: "string",
                          description: "Primary goal of the workout plan",
                          enumValues: ["strength", "endurance", "hypertrophy", "active_recovery", "general_fitness"]
                      ),
                      "durationMinutes": ParameterDefinition(
                          type: "integer",
                          description: "Target workout duration in minutes",
                          minimum: 15,
                          maximum: 120
                      ),
                      "intensityPreference": ParameterDefinition(
                          type: "string",
                          description: "Desired workout intensity",
                          enumValues: ["light", "moderate", "high", "variable"]
                      ),
                      "targetMuscleGroups": ParameterDefinition(
                          type: "array",
                          description: "Specific muscle groups to target",
                          items: Box(ParameterDefinition(
                              type: "string",
                              description: "Muscle group",
                              enumValues: ["chest", "back", "shoulders", "arms", "legs", "core", "full_body"]
                          ))
                      ),
                      "constraints": ParameterDefinition(
                          type: "string",
                          description: "Any limitations or special requirements"
                      )
                  ],
                  required: ["goalFocus"]
              )
          ),
          
          // Nutrition Logging
          FunctionDefinition(
              name: "parseAndLogComplexNutrition",
              description: "Parses detailed free-form natural language meal descriptions into structured data for logging",
              parameters: FunctionParameters(
                  properties: [
                      "naturalLanguageInput": ParameterDefinition(
                          type: "string",
                          description: "User's full description of the meal"
                      ),
                      "mealType": ParameterDefinition(
                          type: "string",
                          description: "Type of meal",
                          enumValues: ["breakfast", "lunch", "dinner", "snack", "pre_workout", "post_workout"]
                      ),
                      "timestamp": ParameterDefinition(
                          type: "string",
                          description: "ISO 8601 datetime when the meal was consumed"
                      )
                  ],
                  required: ["naturalLanguageInput"]
              )
          ),
          
          // Performance Analysis
          FunctionDefinition(
              name: "analyzePerformanceTrends",
              description: "Analyzes user's performance data to identify trends and insights",
              parameters: FunctionParameters(
                  properties: [
                      "analysisQuery": ParameterDefinition(
                          type: "string",
                          description: "Natural language description of what to analyze"
                      ),
                      "metricsRequired": ParameterDefinition(
                          type: "array",
                          description: "Specific metrics needed for analysis",
                          items: Box(ParameterDefinition(type: "string", description: "Metric name"))
                      ),
                      "timePeriodDays": ParameterDefinition(
                          type: "integer",
                          description: "Number of days to analyze",
                          minimum: 7,
                          maximum: 365
                      )
                  ],
                  required: ["analysisQuery"]
              )
          ),
          
          // Plan Adaptation
          FunctionDefinition(
              name: "adaptPlanBasedOnFeedback",
              description: "Modifies existing plans based on user's subjective state or feedback",
              parameters: FunctionParameters(
                  properties: [
                      "userFeedback": ParameterDefinition(
                          type: "string",
                          description: "User's feedback about their current state or plan"
                      ),
                      "adaptationType": ParameterDefinition(
                          type: "string",
                          description: "Type of adaptation needed",
                          enumValues: ["reduce_intensity", "increase_intensity", "change_focus", "add_variety", "recovery_focus"]
                      ),
                      "specificConcern": ParameterDefinition(
                          type: "string",
                          description: "Specific issue to address (e.g., 'shoulder pain', 'too tired')"
                      )
                  ],
                  required: ["userFeedback"]
              )
          ),
          
          // Goal Setting
          FunctionDefinition(
              name: "assistGoalSettingOrRefinement",
              description: "Helps user define or refine SMART fitness goals",
              parameters: FunctionParameters(
                  properties: [
                      "currentGoal": ParameterDefinition(
                          type: "string",
                          description: "User's existing goal if any"
                      ),
                      "aspirations": ParameterDefinition(
                          type: "string",
                          description: "What the user wants to achieve"
                      ),
                      "timeframe": ParameterDefinition(
                          type: "string",
                          description: "Desired timeframe for the goal"
                      ),
                      "constraints": ParameterDefinition(
                          type: "array",
                          description: "Any limitations to consider",
                          items: Box(ParameterDefinition(type: "string", description: "Constraint"))
                      )
                  ],
                  required: ["aspirations"]
              )
          ),
          
          // Educational Content
          FunctionDefinition(
              name: "generateEducationalInsight",
              description: "Provides personalized educational content on fitness/health topics",
              parameters: FunctionParameters(
                  properties: [
                      "topic": ParameterDefinition(
                          type: "string",
                          description: "Educational topic",
                          enumValues: [
                              "progressive_overload",
                              "nutrition_timing",
                              "recovery_science",
                              "sleep_optimization",
                              "hrv_training",
                              "mobility_flexibility",
                              "supplement_science"
                          ]
                      ),
                      "userContext": ParameterDefinition(
                          type: "string",
                          description: "Why this topic is relevant to the user now"
                      ),
                      "depth": ParameterDefinition(
                          type: "string",
                          description: "Level of detail desired",
                          enumValues: ["quick_tip", "detailed_explanation", "scientific_deep_dive"]
                      )
                  ],
                  required: ["topic", "userContext"]
              )
          )
      ]
  }
  ```

**Agent Task 5.4.2: Create Function Dispatcher**
- File: `AirFit/Modules/AI/Functions/FunctionCallDispatcher.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  struct FunctionContext {
      let modelContext: ModelContext
      let conversationId: UUID
  }
  
  struct FunctionResult {
      let success: Bool
      let message: String
      let data: [String: Any]?
  }
  
  @MainActor
  final class FunctionCallDispatcher {
      // MARK: - Dependencies
      private let workoutService: WorkoutServiceProtocol
      private let nutritionService: NutritionServiceProtocol
      private let analyticsService: AnalyticsServiceProtocol
      private let goalService: GoalServiceProtocol
      
      // MARK: - Initialization
      init(
          workoutService: WorkoutServiceProtocol,
          nutritionService: NutritionServiceProtocol,
          analyticsService: AnalyticsServiceProtocol,
          goalService: GoalServiceProtocol
      ) {
          self.workoutService = workoutService
          self.nutritionService = nutritionService
          self.analyticsService = analyticsService
          self.goalService = goalService
      }
      
      // MARK: - Public Methods
      func execute(
          _ call: FunctionCall,
          for user: User,
          context: FunctionContext
      ) async throws -> FunctionResult {
          AppLogger.info("Executing function: \(call.name)", category: .ai)
          
          switch call.name {
          case "generatePersonalizedWorkoutPlan":
              return try await generateWorkoutPlan(call.arguments, for: user, context: context)
              
          case "parseAndLogComplexNutrition":
              return try await parseAndLogNutrition(call.arguments, for: user, context: context)
              
          case "analyzePerformanceTrends":
              return try await analyzePerformance(call.arguments, for: user, context: context)
              
          case "adaptPlanBasedOnFeedback":
              return try await adaptPlan(call.arguments, for: user, context: context)
              
          case "assistGoalSettingOrRefinement":
              return try await assistGoalSetting(call.arguments, for: user, context: context)
              
          case "generateEducationalInsight":
              return try await generateEducationalContent(call.arguments, for: user, context: context)
              
          default:
              throw FunctionError.unknownFunction(call.name)
          }
      }
      
      // MARK: - Function Implementations
      private func generateWorkoutPlan(
          _ args: [String: AnyCodable],
          for user: User,
          context: FunctionContext
      ) async throws -> FunctionResult {
          let goalFocus = args["goalFocus"]?.value as? String ?? "general_fitness"
          let duration = args["durationMinutes"]?.value as? Int ?? 45
          let intensity = args["intensityPreference"]?.value as? String ?? "moderate"
          let muscleGroups = args["targetMuscleGroups"]?.value as? [String] ?? ["full_body"]
          let constraints = args["constraints"]?.value as? String
          
          let plan = try await workoutService.generatePlan(
              for: user,
              goal: goalFocus,
              duration: duration,
              intensity: intensity,
              targetMuscles: muscleGroups,
              constraints: constraints
          )
          
          return FunctionResult(
              success: true,
              message: "Created a \(duration)-minute \(goalFocus) workout plan targeting \(muscleGroups.joined(separator: ", "))",
              data: [
                  "planId": plan.id.uuidString,
                  "exercises": plan.exercises.count,
                  "estimatedCalories": plan.estimatedCalories ?? 0
              ]
          )
      }
      
      private func parseAndLogNutrition(
          _ args: [String: AnyCodable],
          for user: User,
          context: FunctionContext
      ) async throws -> FunctionResult {
          let input = args["naturalLanguageInput"]?.value as? String ?? ""
          let mealTypeString = args["mealType"]?.value as? String
          let timestamp = args["timestamp"]?.value as? String
          
          let mealType = mealTypeString.flatMap { MealType(rawValue: $0) } ?? .snack
          let date = timestamp.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
          
          let entry = try await nutritionService.parseAndLogMeal(
              input,
              type: mealType,
              date: date,
              for: user
          )
          
          return FunctionResult(
              success: true,
              message: "Logged \(entry.items.count) items for \(mealType.displayName): \(Int(entry.totalCalories)) calories",
              data: [
                  "entryId": entry.id.uuidString,
                  "calories": entry.totalCalories,
                  "protein": entry.totalProtein,
                  "carbs": entry.totalCarbs,
                  "fat": entry.totalFat
              ]
          )
      }
      
      private func analyzePerformance(
          _ args: [String: AnyCodable],
          for user: User,
          context: FunctionContext
      ) async throws -> FunctionResult {
          let query = args["analysisQuery"]?.value as? String ?? ""
          let metrics = args["metricsRequired"]?.value as? [String] ?? []
          let days = args["timePeriodDays"]?.value as? Int ?? 30
          
          let analysis = try await analyticsService.analyzePerformance(
              query: query,
              metrics: metrics,
              days: days,
              for: user
          )
          
          return FunctionResult(
              success: true,
              message: analysis.summary,
              data: [
                  "insights": analysis.insights,
                  "trends": analysis.trends,
                  "recommendations": analysis.recommendations
              ]
          )
      }
      
      private func adaptPlan(
          _ args: [String: AnyCodable],
          for user: User,
          context: FunctionContext
      ) async throws -> FunctionResult {
          let feedback = args["userFeedback"]?.value as? String ?? ""
          let adaptationType = args["adaptationType"]?.value as? String
          let concern = args["specificConcern"]?.value as? String
          
          // Find active workout plan
          guard let activePlan = user.workouts
              .filter({ $0.plannedDate != nil && $0.completedDate == nil })
              .sorted(by: { $0.plannedDate! < $1.plannedDate! })
              .first else {
              throw FunctionError.noActivePlan
          }
          
          let adapted = try await workoutService.adaptPlan(
              activePlan,
              feedback: feedback,
              adaptationType: adaptationType,
              concern: concern
          )
          
          return FunctionResult(
              success: true,
              message: "Adapted your workout based on your feedback. \(adapted.summary)",
              data: [
                  "planId": adapted.planId.uuidString,
                  "changes": adapted.changes
              ]
          )
      }
      
      private func assistGoalSetting(
          _ args: [String: AnyCodable],
          for user: User,
          context: FunctionContext
      ) async throws -> FunctionResult {
          let currentGoal = args["currentGoal"]?.value as? String
          let aspirations = args["aspirations"]?.value as? String ?? ""
          let timeframe = args["timeframe"]?.value as? String
          let constraints = args["constraints"]?.value as? [String] ?? []
          
          let goal = try await goalService.createOrRefineGoal(
              current: currentGoal,
              aspirations: aspirations,
              timeframe: timeframe,
              constraints: constraints,
              for: user
          )
          
          return FunctionResult(
              success: true,
              message: "Created SMART goal: \(goal.title)",
              data: [
                  "goalId": goal.id.uuidString,
                  "title": goal.title,
                  "targetDate": goal.targetDate?.ISO8601Format() ?? "",
                  "metrics": goal.metrics
              ]
          )
      }
      
      private func generateEducationalContent(
          _ args: [String: AnyCodable],
          for user: User,
          context: FunctionContext
      ) async throws -> FunctionResult {
          let topic = args["topic"]?.value as? String ?? "general_fitness"
          let userContext = args["userContext"]?.value as? String ?? ""
          let depth = args["depth"]?.value as? String ?? "detailed_explanation"
          
          // This would typically call an educational content service
          // For now, return a structured response
          let content = EducationalContent(
              topic: topic,
              userRelevance: userContext,
              mainPoints: [
                  "Key concept explanation",
                  "How it applies to your situation",
                  "Practical implementation tips"
              ],
              actionItems: [
                  "Specific action based on the topic",
                  "How to track progress"
              ]
          )
          
          return FunctionResult(
              success: true,
              message: "Here's what you need to know about \(topic)",
              data: [
                  "topic": topic,
                  "content": content.mainPoints,
                  "actions": content.actionItems
              ]
          )
      }
  }
  
  // MARK: - Errors
  enum FunctionError: LocalizedError {
      case unknownFunction(String)
      case invalidArguments
      case noActivePlan
      case serviceUnavailable
      
      var errorDescription: String? {
          switch self {
          case .unknownFunction(let name):
              return "Unknown function: \(name)"
          case .invalidArguments:
              return "Invalid function arguments"
          case .noActivePlan:
              return "No active plan found to adapt"
          case .serviceUnavailable:
              return "Service temporarily unavailable"
          }
      }
  }
  
  // MARK: - Supporting Types
  struct EducationalContent {
      let topic: String
      let userRelevance: String
      let mainPoints: [String]
      let actionItems: [String]
  }
  ```

---

**Task 5.5: Service Protocols and Implementation**

**Agent Task 5.5.1: Create AI Service Protocol**
- File: `AirFit/Services/AI/AIServiceProtocol.swift`
- Implementation:
  ```swift
  import Foundation
  
  protocol AIServiceProtocol: Sendable {
      func streamCompletion(_ request: AIRequest) async throws -> AsyncThrowingStream<AIResponse, Error>
  }
  
  // Mock implementation for testing
  actor MockAIService: AIServiceProtocol {
      private var mockResponses: [AIResponse] = []
      private var shouldError = false
      
      func setMockResponses(_ responses: [AIResponse]) {
          self.mockResponses = responses
      }
      
      func setShouldError(_ error: Bool) {
          self.shouldError = error
      }
      
      func streamCompletion(_ request: AIRequest) async throws -> AsyncThrowingStream<AIResponse, Error> {
          AsyncThrowingStream { continuation in
              Task {
                  if shouldError {
                      continuation.finish(throwing: AIError.networkError("Mock error"))
                      return
                  }
                  
                  // Default mock response if none set
                  let responses = mockResponses.isEmpty ? [
                      .textDelta("Hello! "),
                      .textDelta("I'm your AI fitness coach. "),
                      .textDelta("How can I help you today?"),
                      .done(usage: TokenUsage(promptTokens: 100, completionTokens: 20, totalTokens: 120))
                  ] : mockResponses
                  
                  for response in responses {
                      try await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
                      continuation.yield(response)
                  }
                  
                  continuation.finish()
              }
          }
      }
  }
  ```

**Agent Task 5.5.2: Create Conversation Manager**
- File: `AirFit/Modules/AI/ConversationManager.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @MainActor
  final class ConversationManager {
      private let modelContext: ModelContext
      
      init(modelContext: ModelContext) {
          self.modelContext = modelContext
      }
      
      func saveUserMessage(
          _ content: String,
          for user: User,
          conversationId: UUID
      ) async throws -> CoachMessage {
          let message = CoachMessage(
              role: .user,
              content: content,
              conversationID: conversationId,
              user: user
          )
          
          modelContext.insert(message)
          try modelContext.save()
          
          return message
      }
      
      func createAssistantMessage(
          _ content: String,
          for user: User,
          conversationId: UUID,
          functionCall: FunctionCall? = nil,
          isLocalCommand: Bool = false,
          isError: Bool = false
      ) async throws -> CoachMessage {
          let message = CoachMessage(
              role: .assistant,
              content: content,
              conversationID: conversationId,
              user: user
          )
          
          if let call = functionCall {
              message.functionCallData = try? JSONEncoder().encode(call)
          }
          
          if isLocalCommand {
              message.modelUsed = "local"
          }
          
          if isError {
              message.wasHelpful = false
          }
          
          modelContext.insert(message)
          try modelContext.save()
          
          return message
      }
      
      func getRecentMessages(
          for user: User,
          conversationId: UUID,
          limit: Int = 20
      ) async throws -> [ChatMessage] {
          var descriptor = FetchDescriptor<CoachMessage>()
          descriptor.predicate = #Predicate { message in
              message.user == user && message.conversationID == conversationId
          }
          descriptor.sortBy = [SortDescriptor(\.timestamp)]
          descriptor.fetchLimit = limit
          
          let messages = try modelContext.fetch(descriptor)
          
          return messages.map { message in
              ChatMessage(
                  role: MessageRole(rawValue: message.role) ?? .user,
                  content: message.content,
                  timestamp: message.timestamp
              )
          }
      }
      
      func pruneOldConversations(
          for user: User,
          keepLast: Int = 5
      ) async throws {
          // Get all conversation IDs
          var descriptor = FetchDescriptor<CoachMessage>()
          descriptor.predicate = #Predicate { message in
              message.user == user
          }
          
          let messages = try modelContext.fetch(descriptor)
          let conversationIds = Set(messages.compactMap { $0.conversationID })
          
          // Keep only the most recent conversations
          let sortedIds = conversationIds.sorted { id1, id2 in
              let date1 = messages.first { $0.conversationID == id1 }?.timestamp ?? Date.distantPast
              let date2 = messages.first { $0.conversationID == id2 }?.timestamp ?? Date.distantPast
              return date1 > date2
          }
          
          let idsToDelete = sortedIds.dropFirst(keepLast)
          
          // Delete old messages
          for id in idsToDelete {
              let deleteDescriptor = FetchDescriptor<CoachMessage>()
              descriptor.predicate = #Predicate { message in
                  message.conversationID == id
              }
              
              let messagesToDelete = try modelContext.fetch(deleteDescriptor)
              for message in messagesToDelete {
                  modelContext.delete(message)
              }
          }
          
          try modelContext.save()
      }
  }
  ```

---

**4. Testing Requirements**

### Unit Tests

**Agent Task 5.12.1: Create CoachEngine Tests**
- File: `AirFitTests/AI/CoachEngineTests.swift`
- Required Test Cases:
  ```swift
  @MainActor
  final class CoachEngineTests: XCTestCase {
      var sut: CoachEngine!
      var mockAIService: MockAIService!
      var modelContext: ModelContext!
      var testUser: User!
      
      override func setUp() async throws {
          try await super.setUp()
          
          modelContext = try SwiftDataTestHelper.createTestContext(
              for: User.self, OnboardingProfile.self, CoachMessage.self
          )
          
          // Create test user with profile
          testUser = User(name: "Test User")
          let profile = try OnboardingProfile(
              user: testUser,
              personaProfile: TestData.mockPersonaProfile,
              communicationPreferences: TestData.mockCommunicationPrefs
          )
          modelContext.insert(testUser)
          try modelContext.save()
          
          // Setup mocks and SUT
          mockAIService = MockAIService()
          
          sut = CoachEngine(
              modelContext: modelContext,
              aiService: mockAIService,
              personaEngine: PersonaEngine(),
              contextAssembler: MockContextAssembler(),
              functionDispatcher: MockFunctionDispatcher(),
              localCommandParser: LocalCommandParser(),
              conversationManager: ConversationManager(modelContext: modelContext)
          )
      }
      
      func test_processUserMessage_withLocalCommand_shouldNotCallAI() async {
          // Act
          await sut.processUserMessage("log 16oz water", for: testUser)
          
          // Assert
          XCTAssertFalse(sut.isProcessing)
          XCTAssertTrue(sut.currentResponse.contains("logged"))
          // Verify AI service was not called
      }
      
      func test_processUserMessage_withAIRequest_shouldStreamResponse() async throws {
          // Arrange
          await mockAIService.setMockResponses([
              .textDelta("Hello "),
              .textDelta("there!"),
              .done(usage: TokenUsage(promptTokens: 10, completionTokens: 2, totalTokens: 12))
          ])
          
          // Act
          await sut.processUserMessage("How should I train today?", for: testUser)
          
          // Allow processing
          try await Task.sleep(nanoseconds: 500_000_000)
          
          // Assert
          XCTAssertEqual(sut.currentResponse, "Hello there!")
          XCTAssertFalse(sut.isProcessing)
          
          // Verify message saved
          let messages = try modelContext.fetch(FetchDescriptor<CoachMessage>())
          XCTAssertEqual(messages.count, 2) // User + Assistant
      }
      
      func test_functionCall_shouldExecuteAndFollowUp() async throws {
          // Arrange
          await mockAIService.setMockResponses([
              .functionCall(FunctionCall(
                  name: "generatePersonalizedWorkoutPlan",
                  arguments: ["goalFocus": "strength"]
              )),
              .done(usage: nil),
              .textDelta("I've created a strength workout for you!"),
              .done(usage: nil)
          ])
          
          // Act
          await sut.processUserMessage("Create a workout plan", for: testUser)
          
          // Allow processing
          try await Task.sleep(nanoseconds: 500_000_000)
          
          // Assert
          XCTAssertTrue(sut.currentResponse.contains("strength workout"))
      }
  }
  ```

### Integration Tests

**Agent Task 5.12.2: Create Local Command Parser Tests**
- File: `AirFitTests/AI/LocalCommandParserTests.swift`
- Test Cases:
  ```swift
  final class LocalCommandParserTests: XCTestCase {
      var sut: LocalCommandParser!
      
      override func setUp() {
          super.setUp()
          sut = LocalCommandParser()
      }
      
      func test_parseWaterCommands() {
          // Test various water logging formats
          XCTAssertEqual(
              sut.parse("log 16oz water"),
              .logWater(amount: 16, unit: .ounces)
          )
          
          XCTAssertEqual(
              sut.parse("log 500ml water"),
              .logWater(amount: 500, unit: .milliliters)
          )
          
          XCTAssertEqual(
              sut.parse("log water"),
              .logWater(amount: 8, unit: .ounces) // Default
          )
      }
      
      func test_parseNavigationCommands() {
          XCTAssertEqual(sut.parse("dashboard"), .showDashboard)
          XCTAssertEqual(sut.parse("show settings"), .showSettings)
          XCTAssertEqual(sut.parse("start workout"), .startWorkout)
      }
      
      func test_parseQuickLogCommands() {
          XCTAssertEqual(
              sut.parse("log breakfast"),
              .quickLog(type: .meal(.breakfast))
          )
      }
      
      func test_unrecognizedCommand_shouldReturnNone() {
          XCTAssertEqual(sut.parse("random text"), .none)
      }
  }
  ```

---

**5. Acceptance Criteria for Module Completion**

- ✅ Complete AI communication models with Sendable conformance
- ✅ Local command parser handles common commands without AI
- ✅ Persona engine builds dynamic prompts from user profile
- ✅ Coach engine orchestrates all AI interactions
- ✅ Streaming responses handled efficiently
- ✅ Function calling system with full dispatcher
- ✅ Conversation history managed in SwiftData
- ✅ Error handling with user-friendly messages
- ✅ Token usage tracking and optimization
- ✅ All components use Swift 6 concurrency
- ✅ Comprehensive test coverage ≥ 80%
- ✅ Mock implementations for testing
- ✅ Performance: Response starts < 500ms
- ✅ Memory efficient with large conversations

**6. Module Dependencies**

- **Requires Completion Of:** Modules 1, 2, 4
- **Must Be Completed Before:** Module 11 (Chat Interface)
- **Can Run In Parallel With:** Module 7 (Settings), Module 8 (Meal Logging)

**7. Performance Requirements**

- First token latency: < 500ms
- Token generation: > 20 tokens/second
- Context assembly: < 200ms
- Function execution: < 1 second
- Memory usage: < 50MB per conversation

---

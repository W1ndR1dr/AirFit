**Modular Sub-Document 5: AI Persona Engine & CoachEngine (Core AI Logic)**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `User`, `OnboardingProfile`, `CoachMessage`.
    *   Completion of Modular Sub-Document 4: HealthKit & Context Aggregation Module – `HealthContextSnapshot`, `ContextAssembler`.
    *   (Implicit) Modular Sub-Document 10 (Services Layer - AI-Router) will eventually provide the full `AIRouterService`. For now, a mock or stubbed version of `AIRouterService` is needed.
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To implement the `CoachEngine`, the central component responsible for managing all AI-driven chat interactions. This includes constructing prompts for the LLM by combining the user's persona, real-time health context, and conversation history; interacting with the `AIRouterService` to get LLM responses; handling both text and function call responses from the LLM; and persisting conversation history.
*   **Responsibilities:**
    *   Implementing a lightweight local pre-parser for simple chat commands to conserve LLM resources.
    *   Retrieving the user's `OnboardingProfile` (containing `persona_profile.json` data) and conversation history.
    *   Fetching the latest `HealthContextSnapshot` via the `ContextAssembler`.
    *   Dynamically constructing the comprehensive system prompt and user messages for the LLM.
    *   Orchestrating requests to the `AIRouterService`.
    *   Processing streaming text responses from the LLM for display in the UI.
    *   Processing function call requests from the LLM, validating them, and dispatching them to appropriate application modules/services for execution.
    *   (Potentially) Sending the results of function executions back to the LLM for it to formulate a final textual response.
    *   Saving all `CoachMessage` entities (user messages, assistant responses, function call details) to SwiftData.
*   **Key Components within this Module:**
    *   `CoachEngine.swift` (Class) located in `AirFit/Modules/AI/` or `AirFit/BusinessLogic/`.
    *   `LocalCommandParser.swift` (Struct or Class) located in `AirFit/Modules/AI/Parsing/`.
    *   (Supporting) `AIRequest.swift` and `AIResponse.swift` (Structs/Enums for `AIRouterService` interaction, may live in `Services/AI/` or `Core/Models/`).

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Master Architecture Specification (v1.2) – System Prompt Template, definitions of High-Value Functions.
    *   Modular Sub-Document 1: `AppLogger`, `AppConstants`.
    *   Modular Sub-Document 2: `User`, `OnboardingProfile`, `CoachMessage` SwiftData models.
    *   Modular Sub-Document 4: `ContextAssembler` service and `HealthContextSnapshot` struct.
    *   (For function call dispatch) Interfaces/protocols of other modules/services that will execute these functions (e.g., `WorkoutGenerator`, `NutritionLogOrchestrator` – these will be defined in their respective modules).
    *   (Mocked or Basic) `AIRouterService` protocol and a stub implementation.
*   **Outputs:**
    *   A `CoachEngine` capable of managing AI chat interactions.
    *   Saved `CoachMessage` entities in SwiftData representing the conversation.
    *   Mechanism for dispatching recognized High-Value Function calls.

**3. Detailed Component Specifications & Agent Tasks**

*(AI Agent Tasks: These tasks involve creating the core logic for AI interaction, including prompt engineering, service interaction, and data handling.)*

---

**Task 5.0: Define AI Service Interaction Structures**
    *   **Agent Task 5.0.1:**
        *   Instruction: "Create a new Swift file named `AIComms.swift` in `AirFit/Services/AI/` (or `AirFit/Core/Models/` if preferred for DTOs)."
        *   Details: Define structs for requests to and responses from the `AIRouterService`.
            ```swift
            // AirFit/Services/AI/AIComms.swift
            import Foundation

            // Represents a single message in a conversation history
            struct ChatMessage: Codable {
                let role: String // "user", "assistant", "system", "tool" (matches MessageRole enum if defined)
                let content: String
                // Optional: let name: String? (for tool/function name if role is "tool")
                // Optional: let toolCallId: String? (if function calling involves IDs)
            }

            // Request sent to the AIRouterService
            struct AIRequest {
                let systemPrompt: String // The master system prompt including persona, context etc.
                let conversationHistory: [ChatMessage] // Recent messages
                let userMessage: String // The new message from the user
                let availableFunctions: [AIFunctionSchema]? // Schemas of functions the LLM can call
            }
            
            // Schema for defining an available function to the LLM
            struct AIFunctionSchema: Codable {
                let name: String
                let description: String
                let parameters: [String: AIFunctionParameterSchema] // Key: param name
            }

            struct AIFunctionParameterSchema: Codable {
                let type: String // e.g., "string", "integer", "boolean", "array", "object"
                let description: String
                let enumValues: [String]? // Optional: if the parameter must be one of a set of values
                let isRequired: Bool
            }

            // Represents a function call requested by the LLM
            struct AIFunctionCall: Codable {
                let functionName: String
                let arguments: [String: AnyCodableValue] // Arguments as a dictionary; AnyCodableValue for flexibility
            }
            
            // Wrapper to handle different types in JSON arguments for function calls
            struct AnyCodableValue: Codable {
                let value: Any

                init<T>(_ value: T?) {
                    self.value = value ?? ()
                }

                // ... (Agent to implement Codable conformance: init(from decoder), encode(to encoder)
                // This will involve checking types like String, Int, Double, Bool, Array, Dictionary)
                // For simplicity, agent can start with String values and expand.
                // A more robust solution might involve a library or more complex generic handling.
                // For now, a basic implementation focusing on expected primitive types is okay.
                // Example for init(from decoder):
                // if let string = try? container.decode(String.self) { self.value = string }
                // else if let int = try? container.decode(Int.self) { self.value = int } ...
                // Example for encode(to encoder):
                // if let string = value as? String { try container.encode(string) } ...
            }


            // Response from the AIRouterService
            enum AIResponseType {
                case textChunk(String)
                case functionCall(AIFunctionCall)
                case streamEnd
                case streamError(Error)
            }
            ```
        *   Acceptance Criteria: `AIComms.swift` created with `ChatMessage`, `AIRequest`, `AIFunctionSchema`, `AIFunctionParameterSchema`, `AIFunctionCall`, `AnyCodableValue` (with basic Codable), and `AIResponseType` defined and compiling.

---

**Task 5.1: Implement LocalCommandParser**
    *   **Agent Task 5.1.1:**
        *   Instruction: "Create a new Swift file named `LocalCommandParser.swift` in `AirFit/Modules/AI/Parsing/`."
        *   Details:
            *   Define a struct or class `LocalCommandParser`.
            *   Implement a method `parse(userInput: String) -> LocalCommandAction?`.
            *   `LocalCommandAction` should be an enum representing actions the app can take without an LLM (e.g., `.showDashboardHint`, `.logWater(amount: Double?)`, `.showSettingsScreen(screenName: String)`).
            *   The parser should use simple keyword spotting or regex for now. It should be lightweight and high-confidence.
            *   Examples to parse:
                *   "show dashboard" -> `.showDashboardHint`
                *   "log 8oz water" / "log water" -> `.logWater(amount: 8.0)` (extract amount if present)
            ```swift
            // AirFit/Modules/AI/Parsing/LocalCommandParser.swift
            import Foundation

            enum LocalCommandAction {
                case showDashboardHint
                case logWater(amount: Double?, unit: String?) // unit can be oz, ml
                case navigateToScreen(screenIdentifier: String) // e.g., "settings_main"
                // Add more simple commands as needed
                case noCommandDetected
            }

            struct LocalCommandParser {
                func parse(userInput: String) -> LocalCommandAction {
                    let lowercasedInput = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                    // Example parsing logic (agent to make this more robust with regex if capable, or simple contains)
                    if lowercasedInput == "show dashboard" || lowercasedInput == "go to dashboard" {
                        return .showDashboardHint
                    }

                    // "log X oz/ml water" or "log water"
                    let waterRegex = try! NSRegularExpression(pattern: #"log\s*(?:(\d*\.?\d+)\s*(oz|ml|liter|litre))?\s*water"#, options: .caseInsensitive)
                    if let match = waterRegex.firstMatch(in: lowercasedInput, options: [], range: NSRange(location: 0, length: lowercasedInput.utf16.count)) {
                        var amount: Double? = nil
                        var unit: String? = nil
                        if let amountRange = Range(match.range(at: 1), in: lowercasedInput) {
                            amount = Double(lowercasedInput[amountRange])
                        }
                        if let unitRange = Range(match.range(at: 2), in: lowercasedInput) {
                            unit = String(lowercasedInput[unitRange])
                        }
                        return .logWater(amount: amount, unit: unit)
                    }
                    
                    if lowercasedInput.contains("settings") {
                        return .navigateToScreen(screenIdentifier: "settings_main") // Example
                    }

                    return .noCommandDetected
                }
            }
            ```
        *   Acceptance Criteria: `LocalCommandParser.swift` implemented with basic parsing logic and `LocalCommandAction` enum.

---

**Task 5.2: Implement CoachEngine Core Structure**
    *   **Agent Task 5.2.1:**
        *   Instruction: "Create `CoachEngine.swift` in `AirFit/Modules/AI/` (or `AirFit/BusinessLogic/`). Define the `CoachEngine` class."
        *   Details:
            *   Make it an `ObservableObject` to publish conversation updates if chat UI directly observes it, or it can use callbacks/delegates.
            *   Dependencies (passed in constructor or via a dependency injection mechanism):
                *   `modelContext: ModelContext` (from SwiftUI Environment or passed in)
                *   `contextAssembler: ContextAssembler`
                *   `aiRouterService: AIRouterServiceProtocol` (Define `AIRouterServiceProtocol` and use a mock for now)
                *   `localCommandParser: LocalCommandParser`
            *   `@Published var currentConversation: [CoachMessage] = []` (or fetched on demand).
            *   `@Published var isReceivingAIResponse: Bool = false`
        *   Acceptance Criteria: `CoachEngine.swift` class structure created with dependencies and published properties.
    *   **Agent Task 5.2.2 (Define AIRouterServiceProtocol & Mock):**
        *   Instruction: "Create `AIRouterServiceProtocol.swift` in `AirFit/Services/AI/`. Define a protocol and a basic mock implementation."
        *   Details:
            ```swift
            // AirFit/Services/AI/AIRouterServiceProtocol.swift
            import Foundation
            import Combine // For streaming responses

            protocol AIRouterServiceProtocol {
                // Use a Combine Publisher or an AsyncThrowingStream for streaming
                func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponseType, Error>
                // Alternatively:
                // func getStreamingResponse(for request: AIRequest) async throws -> AsyncThrowingStream<AIResponseType, Error>
            }

            // Create MockAIRouterService.swift in Tests/Mocks/ or a similar location
            class MockAIRouterService: AIRouterServiceProtocol {
                var mockTextResponse: String = "This is a mock streamed response from the AI."
                var mockFunctionCall: AIFunctionCall? = nil // Example: AIFunctionCall(functionName: "generatePersonalizedWorkoutPlan", arguments: ["goalFocus": AnyCodableValue("strength")])

                func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponseType, Error> {
                    // Simulate streaming
                    let subject = PassthroughSubject<AIResponseType, Error>()
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        if let functionCall = self.mockFunctionCall {
                            subject.send(.functionCall(functionCall))
                            // Reset for next call if needed
                            // self.mockFunctionCall = nil 
                        } else {
                            // Simulate text chunks
                            let words = self.mockTextResponse.split(separator: " ")
                            for (index, word) in words.enumerated() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                                    subject.send(.textChunk(String(word) + " "))
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(words.count) * 0.1 + 0.1) {
                                subject.send(.streamEnd)
                                subject.send(completion: .finished)
                            }
                        }
                        // If not a function call and not text, then just send streamEnd and finish.
                        // Or, if it's a function call, it may or may not be followed by streamEnd depending on LLM behavior.
                        // For this mock, let's assume a function call is a single event, then streamEnd.
                        if self.mockFunctionCall != nil {
                             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Ensure it's after the function call
                                subject.send(.streamEnd)
                                subject.send(completion: .finished)
                            }
                        }
                    }
                    return subject.eraseToAnyPublisher()
                }
            }
            ```
        *   Acceptance Criteria: Protocol and mock service defined.

---

**Task 5.3: Implement Message Handling in CoachEngine**
    *   **Agent Task 5.3.1 (User Message Processing):**
        *   Instruction: "Implement `func processUserMessage(text: String, forUser user: User)` in `CoachEngine.swift`."
        *   Details:
            1.  Save the user's message as a `CoachMessage` (role: "user", content: text) to SwiftData, associated with the `user`. Add it to `@Published currentConversation`.
            2.  Call `localCommandParser.parse(userInput: text)`.
            3.  If a local command is detected (not `.noCommandDetected`):
                *   Handle the local command (e.g., log it, post a notification for UI to react). For now, `AppLogger.log("Local command detected: \(action)")`. Actual execution of these local commands (like UI navigation) will be handled by UI observing these states/events.
                *   Do NOT proceed to call the LLM.
            4.  If no local command:
                *   Set `isReceivingAIResponse = true`.
                *   Call a new private method `private func executeAICall(forUser user: User, latestUserMessageText: String)`.
        *   Acceptance Criteria: User messages are saved, local parser is called, and AI call is triggered conditionally.
    *   **Agent Task 5.3.2 (AI Call Execution):**
        *   Instruction: "Implement `private func executeAICall(forUser user: User, latestUserMessageText: String)` in `CoachEngine.swift`."
        *   Details:
            1.  Fetch `user.onboardingProfile`. If nil, handle error (log, maybe respond with "Please complete onboarding").
            2.  Decode `persona_profile.json` data from `onboardingProfile.personaPromptData`.
            3.  Call `contextAssembler.assembleSnapshot(modelContext: modelContext)` to get `HealthContextSnapshot`.
            4.  Fetch recent `conversationHistory` from SwiftData for the user (e.g., last 10-20 messages, convert to `[ChatMessage]`).
            5.  Construct the master `systemPrompt` string by injecting `persona_profile.json` data and `HealthContextSnapshot` data into the System Prompt Template (from Master Architecture Spec). This will be a complex string assembly.
            6.  Define `AvailableHighValueFunctions` (from Master Architecture Spec) as an array of `AIFunctionSchema`. (Agent to create schema instances for each function like `generatePersonalizedWorkoutPlan`, etc., with descriptions and parameter schemas).
            7.  Create an `AIRequest` object with `systemPrompt`, `conversationHistory`, `latestUserMessageText`, and `availableFunctions`.
            8.  Call `aiRouterService.getStreamingResponse(for: request)` and handle the publisher/stream.
        *   Acceptance Criteria: `AIRequest` is correctly constructed with all necessary components. Call to `aiRouterService` is made.
    *   **Agent Task 5.3.3 (Handling AI Response Stream):**
        *   Instruction: "In `executeAICall` (or a helper method it calls), subscribe to and process the response stream from `aiRouterService`."
        *   Details:
            *   Maintain a temporary string buffer for accumulating text chunks.
            *   Maintain a temporary `AIFunctionCall` object if a function call is being assembled.
            *   When `.textChunk(String)` is received: Append to buffer. Update a temporary "assistant thinking" `CoachMessage` in `@Published currentConversation` (or create new one and update its content).
            *   When `.functionCall(AIFunctionCall)` is received: Store the `AIFunctionCall`. Log it. Call `private func handleFunctionCall(_ functionCall: AIFunctionCall, forUser user: User, currentSystemPrompt: String, currentHistory: [ChatMessage])`.
            *   When `.streamEnd` is received:
                *   Finalize the assistant's text `CoachMessage` (if text was received) with full content from buffer, save to SwiftData.
                *   Set `isReceivingAIResponse = false`.
            *   When `.streamError(Error)` is received: Log error. Display an error message to user (e.g., create an error `CoachMessage`). Set `isReceivingAIResponse = false`.
        *   Acceptance Criteria: Stream processing logic correctly handles text, function calls, end, and errors. Updates conversation and state.
    *   **Agent Task 5.3.4 (Function Call Handling):**
        *   Instruction: "Implement `private func handleFunctionCall(_ functionCall: AIFunctionCall, forUser user: User, currentSystemPrompt: String, currentHistory: [ChatMessage]) async` in `CoachEngine.swift`."
        *   Details:
            1.  Log the requested function call and its arguments.
            2.  Save metadata about the `requestedFunctionCallData` to the current assistant's `CoachMessage` or a new one.
            3.  **(Dispatch - Stubbed for now)** Use a `switch functionCall.functionName` to determine which function to "execute."
                *   For now, for each case (e.g., "generatePersonalizedWorkoutPlan"):
                    *   Log: `"Simulating execution of \(functionCall.functionName) with args: \(functionCall.arguments)"`.
                    *   Prepare a mock/stubbed JSON result string representing what the actual function execution might return (e.g., `{"status": "success", "planSummary": "New strength plan created focusing on upper body."}`).
                    *   Save this `functionCallResultData` to the `CoachMessage`.
                *   **(Future Task in respective modules)** Actual execution will involve calling methods on other services (e.g., `WorkoutGenerator.generatePlan(params)`).
            4.  **(Optional: Send result back to LLM for textual summary)**
                *   Create a new `ChatMessage` with `role: "tool"` (or "function"), `content: mockResultJsonString`, and `name: functionCall.functionName`.
                *   Append this "tool" message to the `currentHistory`.
                *   Make a new call to `aiRouterService.getStreamingResponse()` using the `currentSystemPrompt`, updated `currentHistory` (which now includes the user message, the initial assistant message that requested the function call, and the tool message with the result), and the *original user message that triggered the sequence*. The LLM should then generate a natural language summary based on the function's result.
                *   Handle this subsequent stream (it should primarily be text).
            5.  If not sending result back to LLM for summarization, the `CoachEngine` might craft a simple message itself, or the UI might react directly to the function call result. (For now, assume we might want to send result back to LLM).
        *   Acceptance Criteria: Method logs function calls, (stubs) dispatches them, and (optionally, stubbed) handles sending results back to LLM.

---

**Task 5.4: Prompt Construction Utilities**
    *   **Agent Task 5.4.1:**
        *   Instruction: "Create helper methods or a struct `PromptBuilder.swift` in `AirFit/Modules/AI/` for constructing the system prompt."
        *   Details:
            *   A method `func buildSystemPrompt(personaProfileJSON: String, healthContextJSON: String, functionSchemasJSON: String) -> String`.
            *   This method will take the JSON string representations of the persona, health context, and function schemas.
            *   It will then inject these JSON strings into the master "System Prompt Template (v0.1+)" string (defined in Master Architecture Spec / previous discussions). This requires careful string interpolation or template filling. Ensure JSON is properly escaped if injected into a larger JSON structure or handled correctly by the LLM.
            *   The System Prompt Template should be stored as a constant.
        *   Acceptance Criteria: `PromptBuilder` can correctly assemble the full system prompt string.

---

**Task 5.5: Final Review & Commit**
    *   **Agent Task 5.5.1:**
        *   Instruction: "Review `CoachEngine.swift`, `LocalCommandParser.swift`, `AIComms.swift`, and any prompt building utilities for correctness, adherence to design, error handling, asynchronous operations, and interaction with (mocked) services and SwiftData."
        *   Acceptance Criteria: All components function as intended for the core loop of receiving a message, (conditionally) processing with AI, and handling responses including text and (stubbed) function calls.
    *   **Agent Task 5.5.2:**
        *   Instruction: "Stage all new and modified files related to this module."
        *   Acceptance Criteria: `git status` shows all relevant files staged.
    *   **Agent Task 5.5.3:**
        *   Instruction: "Commit the staged changes with a descriptive message."
        *   Details: Commit message: "Feat: Implement CoachEngine core logic for AI interactions and function calling".
        *   Acceptance Criteria: Git history shows the new commit. Project builds successfully.

**Task 5.6: Add Unit Tests**
    *   **Agent Task 5.6.1 (CoachEngine Unit Tests):**
        *   Instruction: "Create `CoachEngineTests.swift` in `AirFitTests/`."
        *   Details: Utilize mocks for `AIRouterServiceProtocol` and verify message processing and streaming handling as per `TESTING_GUIDELINES.md`.
        *   Acceptance Criteria: Tests compile and pass.
    *   **Agent Task 5.6.2 (LocalCommandParser Unit Tests):**
        *   Instruction: "Create `LocalCommandParserTests.swift` in `AirFitTests/`."
        *   Details: Test parsing of commands for expected actions.
        *   Acceptance Criteria: Tests compile and pass.

---

**4. Acceptance Criteria for Module Completion**

*   `CoachEngine` can process user messages, utilizing `LocalCommandParser` for simple commands.
*   `CoachEngine` correctly assembles comprehensive prompts (system prompt with persona, context, functions; conversation history; user message) for the `AIRouterService`.
*   `CoachEngine` successfully interacts with a (mocked) `AIRouterService` to send requests and receive streaming responses.
*   Streaming text responses are correctly processed and can be relayed for UI display.
*   Function call requests from the AI are correctly identified, and their (stubbed) handling is initiated.
*   Conversation history (`CoachMessage` entities with relevant metadata) is saved to SwiftData.
*   The module is well-structured, uses `AppLogger`, and adheres to coding conventions.
*   All code passes SwiftLint checks.
*   Unit tests for `CoachEngine` and `LocalCommandParser` are implemented and pass.

**5. Code Style Reminders for this Module**

*   The `CoachEngine` will be complex; break down its logic into smaller, well-named private methods.
*   Pay close attention to asynchronous operations (`async/await`, Combine publishers/streams) and error handling.
*   Ensure efficient fetching and minimal retention of `conversationHistory` to manage prompt token limits.
*   String assembly for the system prompt needs to be robust. Consider using a templating approach if the string becomes very complex.
*   The definition of `AvailableHighValueFunctions` schemas must be precise and match what the LLM expects and what the app can actually execute.

---

This module is arguably the most complex so far, as it's the "brain." The interactions with the (currently mocked) `AIRouterService` and the eventual dispatch of function calls are key. Iterative refinement with the AI agent will be necessary, especially for the prompt construction and response stream handling.

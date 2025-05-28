Okay, this is a significant undertaking, and you're absolutely right to think about it in terms of a "recipe" for AI agents. Structuring this for AI-driven development requires extreme clarity, modularity, and an understanding of dependencies.

Given you don't code, I'll aim for a level of detail that is conceptually clear but also provides enough specificity that an AI code generation agent (like a sophisticated version of Codex) could interpret it. I'll also highlight parallel vs. sequential tasks.

**Important Caveats for AI Agent-Driven Development:**

*   **Agent Capabilities:** The success heavily relies on the capabilities of these AI agents. They need to understand context, maintain consistency across files, handle complex instructions, and ideally, be ableto test their own code.
*   **Human Oversight & Iteration:** Even with advanced AI, human oversight, review, and iterative refinement will be ESSENTIAL. You'll act as the "product owner" and "QA lead."
*   **Prompt Engineering for Agents:** Each task for an agent will require careful "prompt engineering" – providing clear instructions, context, and expected outputs.
*   **State Management Between Agents/Tasks:** This is a huge challenge. How does Agent B know what Agent A did perfectly? This often requires a robust version control system (like Git) and potentially a shared understanding of the evolving codebase or very well-defined interfaces between modules.
*   **Code Style & Linting:** We can *specify* a code style, but enforcement will require tools (linters, formatters) that the agents (or a subsequent automated step) would use.

Let's structure this:

**I. AirFit App - Master Architecture Specification (v1.3)**
    **(This Document - The Overview)**

**II. Modular Sub-Documents (Examples of how to break it down - these would be separate, detailed files)**
    0.  Foundational Testing Strategy & Module Test Retrofit
    1.  Core Project Setup & Configuration
    2.  Data Layer (SwiftData Schema & Managers)
    3.  Onboarding Module (UI & Logic for "Persona Blueprint Flow")
    4.  HealthKit & Context Aggregation Module
    5.  AI Persona Engine & CoachEngine (Core AI Logic)
    6.  Dashboard Module (UI & Logic)
    7.  Workout Logging Module (iOS & WatchOS)
    8.  Food Tracking Module (Voice-First AI-Powered Nutrition)
    9.  Notifications & Engagement Engine
    10. Services Layer (API Clients, Multi-Provider AI Support)
    11. Settings Module (UI & Logic)
    12. Testing & Quality Assurance Framework
    13. Chat Interface Module (AI Coach Interaction)

---

**I. AirFit App - Master Architecture Specification (v1.3)**

**Version:** 1.3
**Status:** Updated
**Last Updated:** December 2024
**Purpose:** This document defines the overall software architecture for the AirFit application. It outlines the major components, their responsibilities, interactions, and the foundational principles guiding development. This master document serves as the central reference for all modular sub-documents containing detailed tasks for AI development agents.

**1. Guiding Architectural Principles**

*   **Modularity & Separation of Concerns:** The system will be built as a collection of loosely coupled modules, each with a distinct responsibility. This facilitates parallel development, testability, and maintainability.
*   **Scalability & Maintainability:** Design choices should support future growth in features and user load without requiring major architectural overhauls. Clean code and clear interfaces are paramount.
*   **Testability:** All modules and components must be designed with testability in mind. Unit tests, integration tests, and UI tests will be integral to the development process.
*   **Platform Best Practices:** Adherence to Apple's Human Interface Guidelines and platform-specific (iOS, WatchOS) best practices for Swift, SwiftUI, SwiftData, HealthKit, etc.
*   **Security & Privacy by Design:** Security and privacy considerations are embedded in the architecture from the ground up, not as an afterthought.
*   **Clarity for AI Agents:** All specifications must be explicit, unambiguous, and provide sufficient context for AI code generation agents.
*   **Chat-First Interface:** The primary user interaction paradigm is through natural language chat with the AI coach.
*   **Testing-First Development:** Module 0 establishes comprehensive testing patterns that all subsequent modules must follow.

**2. Technology Stack (Apple Ecosystem)**

*   **Programming Language:** Swift 6+ (latest stable version)
*   **UI Framework:** SwiftUI (for both iOS and WatchOS)
*   **Target Platforms:** iOS 18+, watchOS 11+
*   **Data Persistence:** SwiftData
*   **Health Data:** HealthKit, WorkoutKit
*   **Networking:** URLSession, Async/Await
*   **On-Device Transcription:** WhisperKit (for superior voice transcription accuracy)
*   **AI Model Interaction:** Multi-provider support via secure backend service
    *   Supported providers: OpenAI (GPT-4), Anthropic (Claude), Google (Gemini), OpenRouter
    *   Primary recommendation: GPT-4 for complex interactions, Gemini 1.5 Flash for quick responses
*   **Version Control:** Git (essential for iterative development and agent collaboration)
*   **Dependency Management:** Swift Package Manager (SPM)
*   **Additional iOS 18 Features:** Live Activities, Enhanced Notifications, App Intents

**3. Overall System Architecture (Layered Approach)**

As defined in the Design Spec v1.2:

*   **Presentation Layer (SwiftUI):**
    *   Responsible for rendering all UI elements, capturing user input, and displaying data.
    *   Views will be lightweight and primarily driven by state from ViewModels or direct SwiftData queries.
    *   Chat interface serves as the primary interaction paradigm.
    *   **Code Style:** Follow Apple's Swift API Design Guidelines. Use clear, descriptive names for views, variables, and functions. Prefer composition over inheritance for views. Utilize previews extensively for UI development.
*   **Business Logic Layer (BLL):**
    *   Contains the core application logic, orchestrates data flow between the Presentation and Data/Service layers.
    *   Key Components: `CoachEngine`, `WorkoutGenerator`, `OnboardingManager`, `NutritionLogOrchestrator`, `ChatViewModel`, local parsers for simple commands.
    *   **Code Style:** Logic should be encapsulated in classes or structs with clear responsibilities. Use protocols to define contracts between components. Emphasize immutability where possible.
*   **Service Layer:**
    *   Manages all interactions with external systems and platform services.
    *   Key Components: `HealthKitManager`, `WeatherServiceAPIClient`, `AIServiceProtocol` (multi-provider), `VoiceInputManager` (WhisperKit), `NotificationManager`, `EngagementEngine`, `ExerciseDatabase`.
    *   **Exercise Database**: Offline-first exercise library powered by Free Exercise DB (Unlicense, 800+ exercises) with SwiftData storage, real-time search, and comprehensive categorization by muscle groups, equipment, and difficulty.
    *   **Code Style:** Each service should implement a clearly defined protocol. Handle errors gracefully using Swift's error handling mechanisms (try/catch, Result types). All network requests must be asynchronous.
*   **Data Layer (SwiftData):**
    *   The single source of truth for all persisted application data.
    *   Includes SwiftData Models (as defined in v1.1 and updated for Persona Blueprint Flow v3.1), and potentially manager classes for complex queries or data migrations if needed.
    *   **Code Style:** Model definitions should be clear and directly reflect the schema. Use `@Attribute` and `@Relationship` property wrappers as intended.

**4. Core Modules & Their Interactions (High-Level Overview)**

*(Each of these would become a detailed sub-document with specific tasks)*

*   **A. Module 0: Foundational Testing Strategy (Sequential - Prerequisite)**
    *   Establishes comprehensive testing patterns and requirements.
    *   Defines test-first development approach for all subsequent modules.
    *   Creates testing utilities and mock service protocols.

*   **B. Module 1: Core Project Setup & Configuration (Sequential - Foundational)**
    *   Initialize Git repository.
    *   Setup Xcode project structure (folders for Layers, Modules, Shared Utilities).
    *   Define global constants, theme (colors, fonts for SwiftUI), and utility extensions.
    *   Integrate basic logging framework.
    *   Setup SwiftLint and SwiftFormat with a defined configuration file to enforce code style.

*   **C. Module 2: Data Layer (Sequential - Foundational)**
    *   Define all SwiftData `@Model` classes (User, OnboardingProfile, FoodEntry, Workout, CoachMessage, ChatSession, etc.) precisely as per schema.
    *   Implement any necessary custom initializers or helper methods within models.
    *   (Later) Implement data migration strategies if schema evolves.

*   **D. Module 3: Onboarding Module (Parallel with E, F after C is complete)**
    *   Implement SwiftUI views for each screen of the "Persona Blueprint Flow v3.1".
    *   Develop `OnboardingViewModel` or manager to handle state, navigation, and data collection during onboarding.
    *   Logic to process user inputs, make LLM Call 1 (Goal Analysis), and construct the `persona_profile.json`.
    *   Save `OnboardingProfile` to SwiftData upon completion.

*   **E. Module 4: HealthKit & Context Aggregation (Parallel with D, F after C is complete)**
    *   Implement `HealthKitManager` service to request permissions, fetch, and (where appropriate) save HealthKit data (sleep, workouts, RHR, HRV, etc.).
    *   Develop `ContextAssembler` service to gather data from HealthKit, in-app logs (e.g., `DailyLog`), and device sensors (e.g., weather via `WeatherServiceAPIClient`) to create the `HealthContextSnapshot`.

*   **F. Module 5: AI Persona Engine & CoachEngine (Parallel with D, E after C and basic Services in K are sketched)**
    *   Develop `CoachEngine` class responsible for orchestrating AI chat interactions.
    *   Implement local pre-parser for simple commands.
    *   Logic for constructing prompts (injecting `persona_profile.json`, `HealthContextSnapshot`, `conversationHistory`, `AvailableHighValueFunctions` into the master system prompt template).
    *   Interaction with `AIServiceProtocol` (multi-provider support).
    *   Handling text responses and function call requests from the LLM.
    *   Saving `CoachMessage` entities.

*   **G. Module 6: Dashboard Module (Sequential after D, E, F are partially functional)**
    *   SwiftUI views for the Dashboard (`LazyVGrid`, `MorningGreetingCard`, `NutritionCard`, etc.).
    *   `DashboardViewModel` to fetch and prepare data for display, including triggering AI for the Morning Greeting.

*   **H. Module 7: Workout Logging (iOS & WatchOS) (Parallel with I, J)**
    *   **WatchOS App:** Target for WatchOS, SwiftUI views for active workout, set logging, HealthKit integration via `WorkoutKit`.
    *   **iOS Views:** Workout history, workout summary view (displaying AI-generated summary).
    *   Logic for AI Post-Workout Analysis (triggered by `CoachEngine` or a dedicated manager).

*   **I. Module 8: Food Tracking (Voice-First) (Parallel with H, J)**
    *   SwiftUI views for nutrition logging, displaying macro rings (data from `NutritionCard` on Dashboard might share logic).
    *   Voice input capture UI with WhisperKit integration.
    *   Integration with `VoiceInputManager` (WhisperKit).
    *   Orchestration logic (`NutritionLogOrchestrator`): deciding if local parsing is sufficient or if `parseAndLogComplexNutrition` function call to `CoachEngine` is needed.
    *   UI for confirming/editing LLM-parsed food items.

*   **J. Module 9: Notifications & Engagement Engine (Parallel with H, I, late stage)**
    *   Implement `UNUserNotificationCenter` delegate methods.
    *   Develop `EngagementEngine` for lapse detection (background task) and triggering AI-generated notifications via `CoachEngine`.
    *   Logic for actionable notifications.
    *   iOS 18 Live Activities support for active workouts.

*   **K. Module 10: Services Layer (Sequential for AI, parallel for others)**
    *   Full implementation of `AIServiceProtocol` with multi-provider support.
    *   Provider-specific implementations (OpenAI, Anthropic, Gemini, OpenRouter).
    *   Handle authentication, request formatting, response parsing (streaming text, function call structures).
    *   Weather service, API key management (Keychain), network monitoring.

*   **L. Module 11: Settings Module (Parallel with H, I, J, late stage)**
    *   SwiftUI views for various settings screens (e.g., review/refine persona, notification preferences, units, HealthKit permissions, privacy info, export data).
    *   AI provider selection and API key management UI.
    *   ViewModels to manage and save settings.

*   **M. Module 12: Testing & Quality Assurance Framework (Continuous & Parallel throughout)**
    *   Setup XCTest targets for unit and UI tests.
    *   Define strategy for mocking services and data for testing.
    *   AI agents should be tasked to write unit tests for their generated code (business logic, view models).
    *   (Human task) Define key user flows for UI testing.

*   **N. Module 13: Chat Interface Module (Critical - after F, K are functional)**
    *   Primary user interaction interface.
    *   Real-time streaming chat UI with AI responses.
    *   Voice input integration with WhisperKit.
    *   Rich message rendering (text, charts, suggestions, actions).
    *   Chat history management and search.
    *   Context-aware quick suggestions.

**5. Data Flow Examples (Illustrative)**

*   **User Sends Voice Message in Chat:**
    1.  SwiftUI ChatView -> `VoiceInputManager` (WhisperKit)
    2.  WhisperKit -> Transcription with fitness-specific post-processing
    3.  Transcribed text -> `ChatViewModel` -> `CoachEngine`
    4.  `CoachEngine` -> `ContextAssembler` (gets `HealthContextSnapshot`)
    5.  `CoachEngine` -> SwiftData (gets `OnboardingProfile`, `conversationHistory`)
    6.  `CoachEngine` -> Constructs prompt -> `AIServiceProtocol`
    7.  `AIServiceProtocol` -> Selected AI Provider (streaming response)
    8.  AI Provider -> `AIServiceProtocol` (response: text or function call)
    9.  `AIServiceProtocol` -> `CoachEngine` -> `ChatViewModel`
    10. If text: Stream to ChatView in real-time, Save `ChatMessage`
    11. If function call: Execute relevant function -> Update UI -> Save result

**6. Code Style and Conventions (To be enforced via SwiftLint/Format and Agent Instructions)**

*   **Language:** Swift 6+ (latest stable).
*   **Style Guide:** Apple's Swift API Design Guidelines. Additions:
    *   **Naming:** Descriptive (e.g., `UserProfileView`, `fetchWeatherData()`). PascalCase for types, camelCase for functions/variables.
    *   **Comments:** Explain *why*, not *what*, if code isn't self-explanatory. Use `MARK:` for organizing code.
    *   **Error Handling:** Prefer `Result` type for asynchronous operations that can fail. Use `do-catch` for throwing functions. Avoid force unwrapping (`!`) and force casting (`as!`).
    *   **Immutability:** Prefer `let` over `var`. Use immutable data structures where practical.
    *   **SwiftUI:** Create small, reusable views. Use `@State`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Query` appropriately. Previews are mandatory for all views.
    *   **Concurrency:** Use `async/await` for asynchronous code. Use Actors for managing shared mutable state if necessary.
    *   **Testing:** Minimum 80% code coverage for business logic. All public methods must have tests.
*   **Project Structure:**
    *   Organize files by feature/module first, then by type (e.g., `AirFit/Modules/Onboarding/Views/WelcomeView.swift`, `AirFit/Modules/Onboarding/ViewModels/OnboardingViewModel.swift`).
    *   Shared utilities in a `Shared` or `Common` group.
*   **Agent Instructions for Code Generation:**
    *   "Generate Swift code for a SwiftUI view named `[ViewName]` with the following elements and functionality..."
    *   "Implement a service class `[ServiceName]` conforming to `[ProtocolName]` with methods to..."
    *   "Write unit tests for `[ClassName.methodName]` covering the following scenarios..."
    *   "Ensure all generated code adheres to the project's SwiftLint configuration."

**7. Sequencing and Parallelization Strategy for AI Agents**

*   **Phase 1: Foundation (Mostly Sequential)**
    1.  Task 0: Foundational Testing Strategy (Agent 1)
    2.  Task 1: Core Project Setup & Configuration (Agent 1)
    3.  Task 2: Data Layer Module (SwiftData Models) (Agent 1 or 2)
    4.  Task 10 (Partial): Mock Services Interfaces (`AIServiceProtocol` mock, `HealthKitManager` mock) (Agent 2)
*   **Phase 2: Core Modules - Iteration 1 (Parallel)**
    1.  Task 3: Onboarding Module (UI views, basic ViewModel) (Agent 1)
    2.  Task 4: HealthKit & Context Aggregation (Basic `HealthKitManager` setup, `ContextAssembler` skeleton) (Agent 2)
    3.  Task 5: AI Persona Engine & CoachEngine (Basic prompt construction, interaction with mock `AIServiceProtocol`) (Agent 3)
*   **Phase 3: Feature Prototyping & Integration - Iteration 1 (Parallel, with dependencies)**
    1.  Task 6: Dashboard Module (Basic UI, connect to mock data or early `ContextAssembler`) (Agent 1, depends on 3, 4 partial)
    2.  Task 7 (iOS part): Workout Logging (Basic UI for history, connect to mock data) (Agent 2)
    3.  Task 8: Food Tracking (Basic UI, voice capture stub) (Agent 3)
*   **Phase 4: Service Implementation & Deepening AI (Sequential parts, then Parallel)**
    1.  Task 10 (Full): Implement actual API clients (Weather, WhisperKit integration) (Agent 1)
    2.  Task 10: Multi-provider AI service implementation (Agent 2, or specialized backend agent)
    3.  Refine Task 5: `CoachEngine` full logic, function call handling (Agent 3, depends on 10)
    4.  Task 13: Chat Interface Module (Agent 4, depends on 5, 10)
*   **Phase 5: Full Feature Implementation & WatchOS (Parallel)**
    1.  Complete Tasks 3, 4, 6, 7 (iOS), 8 with real data and AI integration. (Multiple agents)
    2.  Task 7 (WatchOS part): Develop WatchOS app. (Specialized Agent/Team)
    3.  Task 9: Notifications & Engagement Engine with Live Activities. (Agent)
    4.  Task 11: Settings Module. (Agent)
*   **Continuous Task 12: Testing (All Agents, Human QA)**

**8. Modularity & Sub-Documents Strategy**

This Master Architecture document provides the high-level blueprint. For each major Module/Task (e.g., "Module 3: Onboarding," "Module 4: HealthKit"), a **separate, highly detailed sub-document** has been created.

**Each Modular Sub-Document contains:**

1.  **Module Overview:** Purpose, responsibilities, key components within the module.
2.  **Dependencies:** Which other modules/tasks it depends on (inputs) and which depend on it (outputs).
3.  **Detailed Component Specifications:**
    *   For UI Views: Mockups/wireframes (from Design Spec), list of UI elements, expected user interactions, state variables, data bindings.
    *   For ViewModels/Managers: Properties, methods (with signatures: parameters, return types), logic to be implemented, error handling.
    *   For Services: Protocol definition, method signatures, expected behavior, interaction with external APIs/SDKs.
    *   For Data Models: (Reference to central Data Layer spec).
4.  **Specific Agent Tasks (Numbered List):**
    *   Clear, actionable, and scoped tasks for AI agents with complete production-ready code.
    *   No TODOs or placeholders - all code is shippable.
    *   Concrete acceptance criteria with specific metrics.
    *   Test commands for verification.
5.  **Acceptance Criteria for each task/component:** How to verify it's done correctly.
6.  **Performance Requirements:** Specific metrics for response times, memory usage, etc.
7.  **Time Estimates:** Realistic hour estimates for implementation.

---

This Master Architecture provides the skeleton. The detailed modular sub-documents contain production-ready implementations that AI agents can execute with minimal human intervention. The focus on chat-first interaction, multi-provider AI support, and iOS 18 features ensures a modern, flexible architecture.

# Codex Agent Analysis - Wave 1: Architecture Discovery

## Agent 1: Initialization Flow Analysis
**Goal**: Trace the complete app initialization flow and identify bottlenecks

**Prompt**:
```
Analyze the AirFit iOS app initialization flow starting from AirFitApp.swift. Create a detailed report that includes:

1. Complete initialization sequence from app launch to first screen display
2. All async operations during initialization with their dependencies
3. The exact flow: AirFitApp -> DIContainer setup -> ContentView -> AppState creation
4. Identify any circular dependencies or potential deadlocks
5. Document all actor boundaries crossed during initialization
6. Create a sequence diagram showing the initialization flow
7. Identify why the app might show a black screen during launch
8. List all services that must be initialized before the UI appears

Focus on files: AirFitApp.swift, ContentView.swift, AppState.swift, DIBootstrapper.swift, DIContainer.swift

Output a markdown report with code snippets and clear explanations.
```

## Agent 2: Actor & Concurrency Architecture Analysis
**Goal**: Understand the concurrency design decisions and current state

**Prompt**:
```
Analyze the concurrency architecture in the AirFit iOS app. Create a comprehensive report covering:

1. Map all @MainActor annotations in the codebase
2. Identify all actor types and their isolation boundaries
3. Document the ServiceProtocol hierarchy and why protocols are marked @MainActor
4. Analyze Swift 6 concurrency compliance and Sendable conformances
5. Identify actor isolation conflicts and potential race conditions
6. Explain the rationale behind current concurrency decisions
7. List all async/await boundaries and their implications
8. Document any @unchecked Sendable usage and why it exists

Include analysis of: all Protocol files, all Service implementations, ViewModels, and the DI system.

Output a report with clear categorization of concurrency patterns and potential issues.
```

## Agent 3: Dependency Injection System Deep Dive
**Goal**: Fully understand the DI container and registration patterns

**Prompt**:
```
Analyze the dependency injection system in AirFit. Create a detailed report covering:

1. Complete analysis of DIContainer.swift implementation
2. All service registrations in DIBootstrapper.swift
3. Dependency graph - which services depend on which
4. Async vs sync resolution patterns and their implications
5. How ViewModels are created via DIViewModelFactory
6. Environment injection patterns for SwiftUI
7. Identify circular dependency risks
8. Document the lifecycle of singleton vs transient services
9. Analyze DIContainer.shared usage and timing

Map the complete dependency tree and identify potential issues.

Output a report with visual dependency graphs where helpful.
```

## Agent 4: Service Layer Architecture Analysis
**Goal**: Understand all services, their responsibilities, and interactions

**Prompt**:
```
Analyze the service layer architecture in AirFit. Document:

1. Complete inventory of all services (AI, Weather, HealthKit, etc.)
2. ServiceProtocol requirements and why they exist
3. Which services are @MainActor vs actors vs classes
4. Service initialization order and dependencies
5. API key management flow and its integration points
6. HealthKit integration patterns and data flow
7. AI service variations (AIService, DemoAIService, OfflineAIService) and their purposes
8. Network layer patterns and error handling

Focus on: Services/ directory, Core/Protocols/, and their implementations.

Create a service catalog with clear documentation of each service's purpose and dependencies.
```

## Agent 5: AI Integration & Demo Mode Analysis
**Goal**: Understand the AI system design and demo mode complexity

**Prompt**:
```
Analyze the AI integration in AirFit, specifically:

1. The complete AI service hierarchy and protocol requirements
2. LLMOrchestrator design and its role
3. Why DemoAIService and OfflineAIService exist
4. API key configuration flow and fallback logic
5. How AI services are selected during initialization
6. The UserDefaults "isUsingDemoMode" flag and its implications
7. InitialAPISetupView and its integration with the app flow
8. Cost tracking and provider selection logic
9. Why removing demo mode is complex

Document the current state and identify simplification opportunities.

Output a report explaining the AI system architecture and its initialization challenges.
```

---

## Wave 2 Prompts (After Wave 1 Analysis)

Based on Wave 1 findings, we'll create 5 more targeted prompts to:
1. Deep dive into specific problem areas identified
2. Analyze error handling and edge cases
3. Investigate SwiftData and HealthKit integration patterns
4. Examine the onboarding flow and persona generation
5. Profile performance bottlenecks and memory management

## Expected Outputs

Each agent should produce:
- A focused markdown report (2-4 pages)
- Code snippets with line numbers
- Identified problems with severity ratings
- Specific recommendations
- Questions that need human input

## Consolidation Plan

After both waves:
1. Synthesize findings into a master architecture document
2. Create a prioritized issue list
3. Design a migration plan with clear phases
4. Establish new architectural guidelines
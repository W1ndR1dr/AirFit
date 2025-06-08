# Codex Agent Prompts - Wave 1: Architecture & Structure

## Instructions for Execution
1. Send each agent the AGENTS.md content as their system prompt
2. Then send their specific analysis prompt below
3. Each agent should output to the specified deliverable file

---

## Agent 1: High-Level Architecture Analysis

**Deliverable**: `Docs/Research Reports/Architecture_Overview_Analysis.md`

```
Analyze the overall architecture of the AirFit iOS application. Start with the directory structure and work your way through understanding the architectural patterns. Document:

1. Project Structure Analysis:
   - Map the complete directory structure and explain the purpose of each major folder
   - Identify the architectural pattern (MVVM, MVVM-C, etc.) and how it's implemented
   - Document the module organization and boundaries

2. Layer Architecture:
   - Core Layer: Protocols, DI, Extensions, Models, Theme, Utilities
   - Data Layer: SwiftData models and persistence strategy  
   - Service Layer: All services and their responsibilities  
   - Module Layer: Feature modules and their organization
   - Application Layer: App initialization and routing

3. Key Architectural Decisions:
   - SwiftUI vs UIKit usage
   - SwiftData vs Core Data choice
   - Dependency injection pattern
   - Navigation/coordination pattern
   - Error handling strategy

4. Module Dependencies:
   - Which modules depend on which
   - Circular dependency analysis
   - Clean architecture compliance

Output a comprehensive architectural overview with diagrams where helpful.
```

---

## Agent 2: Initialization & App Lifecycle Analysis

**Deliverable**: `Docs/Research Reports/App_Lifecycle_Analysis.md`

```
Trace the complete application lifecycle from launch to full initialization. Document:

1. App Launch Sequence:
   - AirFitApp.swift entry point and @main attribute
   - SwiftUI App protocol implementation
   - ModelContainer initialization
   - DIContainer creation and setup

2. Initialization Flow:
   - Step-by-step trace from AirFitApp → ContentView → AppState
   - All async operations during startup
   - Environment injection (.withDIContainer) pattern
   - DIContainer.shared lifecycle and timing

3. View Routing Logic:
   - How ContentView decides which view to show
   - AppState properties that control navigation
   - The role of shouldShowAPISetup, shouldShowOnboarding, etc.

4. Initialization Dependencies:
   - What must be initialized before UI appears
   - Service initialization order
   - Potential blocking operations

5. State Management:
   - AppState design and responsibilities
   - How global state is managed
   - State persistence across app launches

Include code snippets and sequence diagrams showing the complete flow.
```

---

## Agent 3: Dependency Injection System Deep Dive

**Deliverable**: `Docs/Research Reports/DI_System_Complete_Analysis.md`

```
Perform a comprehensive analysis of the dependency injection system. Document:

1. DIContainer Implementation:
   - Complete analysis of DIContainer.swift
   - Registration system (register vs registerSingleton)
   - Resolution mechanism (async resolve)
   - Lifetime management (singleton, scoped, transient)
   - Thread safety and Sendable conformance

2. DIBootstrapper Analysis:
   - All service registrations in createAppContainer()
   - Registration order and dependencies
   - Factory closures and their contexts
   - Mock container for testing

3. Dependency Graph:
   - Create a complete dependency tree
   - Identify initialization order requirements
   - Find circular dependency risks
   - Document service interdependencies

4. Environment Injection:
   - How .withDIContainer() works
   - DIContainerEnvironmentKey pattern
   - @Environment(\.diContainer) usage

5. ViewModelFactory Pattern:
   - DIViewModelFactory implementation
   - How ViewModels are created
   - Dependencies passed to ViewModels

Include visual dependency graphs and identify potential issues.
```

---

## Agent 4: Concurrency & Actor Model Analysis

**Deliverable**: `Docs/Research Reports/Concurrency_Model_Analysis.md`

```
Map the complete concurrency architecture and actor isolation patterns. Document:

1. Actor Isolation Inventory:
   - Find ALL @MainActor annotations (classes, structs, protocols, methods)
   - Find ALL actor declarations
   - Document isolation boundaries
   - Identify @unchecked Sendable usage

2. Protocol Hierarchies:
   - Why ServiceProtocol is @MainActor
   - AIServiceProtocol hierarchy
   - How protocol isolation affects implementations
   - Conflicts between protocol requirements and implementations

3. Service Concurrency Models:
   - Which services are @MainActor classes
   - Which are actors
   - Which are regular classes with Sendable
   - Rationale for each choice

4. Async/Await Patterns:
   - All async boundaries in the codebase
   - Task creation patterns
   - Actor isolation crossings
   - MainActor.run usage

5. Swift 6 Compliance:
   - Sendable conformance patterns
   - Concurrency warnings/errors
   - Future migration considerations

Create a comprehensive concurrency map showing isolation domains.
```

---

## Agent 5: Service Layer Architecture Catalog

**Deliverable**: `Docs/Research Reports/Service_Layer_Complete_Catalog.md`

```
Create a comprehensive catalog of all services in the application. For each service document:

1. Service Inventory:
   - List EVERY service (protocol and implementation)
   - File locations
   - Conformances
   - Dependencies
   - Purpose and responsibilities

2. Service Categories:
   - AI Services (AIService, DemoAIService, OfflineAIService)
   - Health Services (HealthKitManager, etc.)
   - Network Services (NetworkClient, APIClients)
   - User Services (UserService, PersonaService)
   - Utility Services (Weather, Analytics, etc.)

3. Service Patterns:
   - ServiceProtocol conformance pattern
   - configure(), reset(), healthCheck() methods
   - Error handling patterns
   - Initialization requirements

4. API Integration:
   - How services integrate with external APIs
   - API key management
   - Network request patterns
   - Response parsing

5. Service Communication:
   - How services communicate with each other
   - Event/notification patterns
   - Shared state management

Create a service catalog table with all details.
```
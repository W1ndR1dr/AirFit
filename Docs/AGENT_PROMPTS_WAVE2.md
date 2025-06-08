# Codex Agent Prompts - Wave 2: Feature Modules & Business Logic

## Instructions for Execution
1. Send each agent the AGENTS.md content as their system prompt
2. Then send their specific analysis prompt below
3. Each agent should output to the specified deliverable file

---

## Agent 6: Onboarding Module Complete Analysis

**Deliverable**: `Docs/Research Reports/Onboarding_Module_Analysis.md`

```
Analyze the complete onboarding module implementation. Document:

1. Onboarding Flow:
   - All views in the onboarding sequence
   - Navigation between screens
   - Data collection at each step
   - Persona generation process

2. Components:
   - Views: All onboarding views and their purposes
   - ViewModels: OnboardingViewModel design
   - Services: OnboardingService, PersonaService
   - Models: OnboardingProfile, PersonaModels

3. Conversation System:
   - ConversationManager implementation
   - Message handling and persistence
   - AI integration for responses
   - Conversation flow control

4. Persona Generation:
   - How user inputs create a persona
   - AI persona synthesis (<3s requirement)
   - Persona preview and selection
   - Storage and usage

5. Integration Points:
   - How onboarding integrates with AppState
   - HealthKit authorization timing
   - API key setup flow
   - Transition to main app

Document the complete user journey with code references.
```

---

## Agent 7: AI System & LLM Integration Analysis

**Deliverable**: `Docs/Research Reports/AI_System_Complete_Analysis.md`

```
Analyze the complete AI system architecture and LLM integration. Document:

1. AI Service Architecture:
   - Why there are 3 implementations (AIService, DemoAIService, OfflineAIService)
   - Service selection logic in DIBootstrapper
   - Fallback patterns and demo mode

2. LLM Orchestration:
   - LLMOrchestrator design and responsibilities
   - Provider management (OpenAI, Anthropic, Gemini)
   - Model selection and switching
   - Cost tracking implementation

3. AI Integration Points:
   - Conversation responses
   - Nutrition parsing
   - Workout recommendations
   - Goal setting
   - Analytics insights

4. Function Calling System:
   - FunctionCallDispatcher
   - Available functions
   - Function execution flow
   - Response handling

5. Prompt Engineering:
   - System prompts structure
   - Context assembly
   - Token optimization
   - Response streaming

Document the complete AI pipeline from request to response.
```

---

## Agent 8: Data Layer & SwiftData Analysis

**Deliverable**: `Docs/Research Reports/Data_Layer_Analysis.md`

```
Analyze the complete data persistence layer using SwiftData. Document:

1. Data Models:
   - All SwiftData models and their relationships
   - Schema design and migrations
   - Model constraints and validation
   - Sendable conformance

2. Data Architecture:
   - ModelContainer setup and configuration
   - ModelContext usage patterns
   - Query patterns and performance
   - Transaction management

3. Data Flow:
   - How data flows from UI to persistence
   - Update patterns
   - Deletion cascades
   - Data integrity

4. HealthKit Integration:
   - Dual storage pattern (SwiftData + HealthKit)
   - Sync mechanisms
   - Data priority (HealthKit first)
   - Conflict resolution

5. Performance Considerations:
   - Query optimization
   - Batch operations
   - Memory management
   - Background processing

Include entity relationship diagrams and data flow charts.
```

---

## Agent 9: UI/UX Implementation Analysis

**Deliverable**: `Docs/Research Reports/UI_Implementation_Analysis.md`

```
Analyze the UI implementation patterns and user experience design. Document:

1. SwiftUI Patterns:
   - View composition strategies
   - State management (@State, @Binding, @Environment)
   - Custom view modifiers
   - Reusable components

2. Design System:
   - Theme implementation (Colors, Fonts, Spacing)
   - Design tokens usage
   - Accessibility support
   - Dark mode support

3. Navigation Patterns:
   - Navigation architecture
   - Coordinator pattern implementation
   - Deep linking support
   - Tab/modal navigation

4. Animation & Performance:
   - Animation patterns
   - Transition implementations
   - Performance optimizations
   - 120fps target achievement

5. Key UI Flows:
   - Dashboard design
   - Food tracking interface
   - Chat interface
   - Settings organization

Document UI patterns with visual examples where relevant.
```

---

## Agent 10: Testing & Quality Assurance Analysis

**Deliverable**: `Docs/Research Reports/Testing_Architecture_Analysis.md`

```
Analyze the testing architecture and quality assurance patterns. Document:

1. Test Structure:
   - Test target organization
   - Test file naming and location
   - Test categories (unit, integration, UI)
   - Coverage analysis

2. Testing Patterns:
   - Mock implementations
   - Test data builders
   - AAA pattern usage
   - Async test patterns

3. Mock Strategy:
   - All mocks in AirFitTests/Mocks
   - Mock protocol conformance
   - Verification capabilities
   - Stubbing patterns

4. SwiftData Testing:
   - In-memory container setup
   - Test data management
   - Query testing
   - Migration testing

5. Quality Metrics:
   - Current coverage levels
   - Performance benchmarks
   - Code quality standards
   - SwiftLint configuration

Identify testing gaps and improvement opportunities.
```
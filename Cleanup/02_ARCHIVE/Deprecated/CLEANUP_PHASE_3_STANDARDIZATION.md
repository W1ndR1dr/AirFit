# Phase 3: Architectural Standardization (Days 6-9)

## ⚠️ IMPORTANT: This Document Has Been Revised!

**Please use [CLEANUP_PHASE_3_STANDARDIZATION_REVISED.md](CLEANUP_PHASE_3_STANDARDIZATION_REVISED.md) instead.**

The revised version:
- ✅ Preserves our critical implementations (PersonaSynthesis, LLMOrchestrator)
- ✅ Focuses only on necessary changes (ChatViewModel migration, API key consolidation)
- ✅ Avoids unnecessary renaming that would break working code
- ✅ Extends AppError instead of creating duplicate error types
- ✅ Respects legitimate Combine usage in services

## Overview (Original - See Revised for Updates)
This phase enforces consistent naming conventions, consolidates duplicate types, and establishes clear module boundaries.

## Day 6: Naming Convention Enforcement

### Task 6.1: Create Naming Standards Document (1 hour)

**Create**: `/AirFit/Docs/NAMING_CONVENTIONS.md`

```markdown
# AirFit Naming Conventions

## File Naming
- Protocols: `[Name]Protocol.swift` (e.g., `UserServiceProtocol.swift`)
- Services: `[Name]Service.swift` or `Default[Name]Service.swift`
- Managers: `[Name]Manager.swift`
- ViewModels: `[Name]ViewModel.swift`
- Views: `[Name]View.swift`
- Models: Singular form (e.g., `User.swift`, not `Users.swift`)

## Type Naming
- Protocols: `[Name]Protocol` suffix (NOT `Providing`, `Management`, etc.)
- Service Implementations: `Default[Name]Service` or `[Provider][Name]Service`
- Mock Implementations: `Mock[Name]` prefix
- Error Types: `[Module]Error` (e.g., `AIError`, `NetworkError`)
- Result Types: `[Action]Result` (e.g., `LoginResult`, `WorkoutPlanResult`)

## Method Naming
- Async methods: verb + noun (e.g., `fetchUser`, `saveWorkout`)
- Boolean methods: `is/has/can` prefix (e.g., `isConfigured`, `hasAPIKey`)
- Factory methods: `make` prefix (e.g., `makeViewModel`, `makeCoordinator`)

## Property Naming
- Boolean properties: `is/has` prefix
- Private properties: no underscore prefix (Swift convention)
- Computed properties: noun form (avoid `get` prefix)
```

### Task 6.2: Protocol Renaming (3 hours)

**Files to Update**:

1. Rename `NetworkManagementProtocol` to `NetworkManagerProtocol`
2. Rename `APIKeyManagementProtocol` to `APIKeyManagerProtocol` (keep the better one)
3. Rename `LLMProvider` to `LLMProviderProtocol`

**Script to help**:
```bash
#!/bin/bash
# rename_protocols.sh

# Rename NetworkManagementProtocol
find AirFit -name "*.swift" -type f -exec sed -i '' 's/NetworkManagementProtocol/NetworkManagerProtocol/g' {} +

# Rename LLMProvider to LLMProviderProtocol
find AirFit -name "*.swift" -type f -exec sed -i '' 's/: LLMProvider/: LLMProviderProtocol/g' {} +
find AirFit -name "*.swift" -type f -exec sed -i '' 's/protocol LLMProvider/protocol LLMProviderProtocol/g' {} +
```

### Task 6.3: Service Naming Standardization (2 hours)

**Rename Services**:
- `ProductionAIService` → `DefaultAIService`
- `SimpleMockAIService` → `MockAIService` (in tests)
- `DefaultAPIKeyManager` → `DefaultAPIKeyService`

### Task 6.4: Create SwiftLint Custom Rules (2 hours)

**Update**: `.swiftlint.yml`

```yaml
custom_rules:
  protocol_naming:
    name: "Protocol Naming"
    regex: "protocol\\s+\\w+(?<!Protocol)\\s*[:{]"
    message: "Protocols should end with 'Protocol' suffix"
    severity: error
    
  service_naming:
    name: "Service Naming"
    regex: "class\\s+\\w*Service(?!Protocol)\\w*\\s*:.*ServiceProtocol"
    match_kinds:
      - identifier
    message: "Service implementations should follow Default[Name]Service pattern"
    severity: warning
    
  force_cast:
    name: "Force Cast"
    regex: "as\\s*!"
    message: "Force casts are not allowed. Use safe casting."
    severity: error
    
  mock_in_production:
    name: "Mock in Production"
    regex: "Mock\\w+\\(\\)"
    message: "Mock implementations should not be used in production code"
    severity: error
    excluded:
      - "**/*Tests/**"
      - "**/*Preview*"
```

## Day 7: Type Consolidation

### Task 7.1: Consolidate Error Types (3 hours)

**Create**: `/AirFit/Core/Enums/UnifiedErrors.swift`

```swift
import Foundation

/// Unified error type for all services
enum AirFitError: LocalizedError {
    // Network errors
    case networkError(String)
    case timeout
    case noInternetConnection
    
    // Service errors
    case serviceUnavailable(String)
    case notConfigured(String)
    case configurationError(String)
    
    // AI errors
    case aiProviderError(provider: String, message: String)
    case rateLimitExceeded(provider: String)
    case invalidAPIKey(provider: String)
    
    // Data errors
    case dataNotFound(type: String)
    case invalidData(String)
    case saveFailed(String)
    
    // Auth errors
    case unauthorized
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .timeout:
            return "Request timed out"
        case .noInternetConnection:
            return "No internet connection"
        case .serviceUnavailable(let service):
            return "\(service) is currently unavailable"
        case .notConfigured(let service):
            return "\(service) is not configured"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .aiProviderError(let provider, let message):
            return "\(provider) error: \(message)"
        case .rateLimitExceeded(let provider):
            return "\(provider) rate limit exceeded"
        case .invalidAPIKey(let provider):
            return "Invalid API key for \(provider)"
        case .dataNotFound(let type):
            return "\(type) not found"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .invalidCredentials:
            return "Invalid credentials"
        }
    }
}

/// Migration helpers
extension ServiceError {
    func toAirFitError() -> AirFitError {
        switch self {
        case .networkError(let message):
            return .networkError(message)
        case .timeout:
            return .timeout
        case .notConfigured:
            return .notConfigured("Service")
        default:
            return .serviceUnavailable("Unknown service error")
        }
    }
}

extension AIError {
    func toAirFitError() -> AirFitError {
        switch self {
        case .providerError(let message):
            return .aiProviderError(provider: "Unknown", message: message)
        case .rateLimitExceeded:
            return .rateLimitExceeded(provider: "Unknown")
        case .invalidAPIKey:
            return .invalidAPIKey(provider: "Unknown")
        default:
            return .serviceUnavailable("AI service error")
        }
    }
}
```

### Task 7.2: Merge Personality Insights Types (2 hours)

**Update**: `/AirFit/Modules/Onboarding/Models/PersonalityInsights.swift`

```swift
import Foundation

/// Unified personality insights used throughout the app
struct PersonalityInsights: Codable {
    // Core personality traits
    let motivationalStyle: MotivationalStyle
    let communicationPreference: CommunicationStyle
    let accountabilityNeeds: AccountabilityLevel
    
    // Derived insights (for AI persona generation)
    var conversationInsights: ConversationPersonalityInsights {
        ConversationPersonalityInsights(
            dominantTraits: deriveDominantTraits(),
            communicationStyle: communicationPreference.toAICommunicationStyle(),
            motivationalDrivers: motivationalStyle.toMotivationalDrivers(),
            preferredTone: derivePreferredTone()
        )
    }
    
    // Helper methods for conversion
    private func deriveDominantTraits() -> [String] {
        var traits: [String] = []
        
        switch motivationalStyle {
        case .gentle:
            traits.append(contentsOf: ["supportive", "patient", "encouraging"])
        case .balanced:
            traits.append(contentsOf: ["adaptable", "steady", "consistent"])
        case .intense:
            traits.append(contentsOf: ["driven", "challenging", "direct"])
        }
        
        switch accountabilityNeeds {
        case .minimal:
            traits.append("autonomous")
        case .moderate:
            traits.append("collaborative")
        case .high:
            traits.append("structured")
        }
        
        return traits
    }
    
    private func derivePreferredTone() -> String {
        switch (motivationalStyle, communicationPreference) {
        case (.gentle, .concise):
            return "warm_efficient"
        case (.gentle, .detailed):
            return "nurturing_thorough"
        case (.intense, .concise):
            return "direct_focused"
        case (.intense, .detailed):
            return "comprehensive_challenging"
        default:
            return "balanced_adaptive"
        }
    }
}

// Extension for backward compatibility
extension ConversationPersonalityInsights {
    init(from insights: PersonalityInsights) {
        self = insights.conversationInsights
    }
}
```

### Task 7.3: Consolidate AI Message Types (2 hours)

Create unified message types that work across the system:

**Update**: `/AirFit/Core/Models/AI/AIModels.swift`

```swift
import Foundation

/// Unified message type for all AI interactions
struct AIMessage: Codable, Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let metadata: MessageMetadata?
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        metadata: MessageMetadata? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
    case function
}

struct MessageMetadata: Codable {
    let functionCall: FunctionCall?
    let tokens: TokenUsage?
    let provider: String?
    let model: String?
}

// Migration helpers
extension AIChatMessage {
    func toUnifiedMessage() -> AIMessage {
        AIMessage(
            role: .user,
            content: self.content,
            timestamp: self.timestamp
        )
    }
}

extension LLMMessage {
    func toUnifiedMessage() -> AIMessage {
        AIMessage(
            role: MessageRole(rawValue: self.role) ?? .user,
            content: self.content
        )
    }
}
```

## Day 8: Module Boundary Enforcement

### Task 8.1: Create Module Interfaces (4 hours)

**Create**: `/AirFit/Core/Protocols/ModuleInterfaces.swift`

```swift
import Foundation

// MARK: - Module Communication Interfaces

/// Interface for AI module functionality exposed to other modules
protocol AIModuleInterface {
    func processMessage(_ message: String, context: ConversationContext) async throws -> String
    func analyzeWorkout(_ workout: Workout) async throws -> WorkoutAnalysis
    func generateNutritionInsights(_ entries: [FoodEntry]) async throws -> NutritionInsights
    func createPersona(from insights: PersonalityInsights) async throws -> CoachPersona
}

/// Interface for chat module functionality
protocol ChatModuleInterface {
    func startNewSession(with persona: CoachPersona) async throws -> ChatSession
    func sendMessage(_ message: String, in session: ChatSession) async throws
    func exportSession(_ session: ChatSession) async throws -> URL
}

/// Interface for nutrition module functionality
protocol NutritionModuleInterface {
    func logFood(_ description: String, mealType: MealType) async throws -> FoodEntry
    func getDailySummary(for date: Date) async throws -> NutritionSummary
    func trackWater(amount: Double) async throws
}

// MARK: - Module Coordinators

/// Base coordinator interface
protocol ModuleCoordinator {
    associatedtype ModuleInterface
    var interface: ModuleInterface { get }
    func start()
}

/// Updated module coordinators to expose interfaces
extension AICoordinator: ModuleCoordinator {
    typealias ModuleInterface = AIModuleInterface
}

extension ChatCoordinator: ModuleCoordinator {
    typealias ModuleInterface = ChatModuleInterface
}

extension FoodTrackingCoordinator: ModuleCoordinator {
    typealias ModuleInterface = NutritionModuleInterface
}
```

### Task 8.2: Remove Direct Module Dependencies (3 hours)

Update modules to use interfaces instead of direct dependencies:

**Example Update** in `/AirFit/Modules/Chat/ViewModels/ChatViewModel.swift`:

```swift
// Before
private let coachEngine: CoachEngine

// After
private let aiModule: AIModuleInterface

// Update initialization
init(aiModule: AIModuleInterface, chatSession: ChatSession) {
    self.aiModule = aiModule
    self.chatSession = chatSession
}

// Update method calls
private func processMessage(_ message: String) async throws {
    let response = try await aiModule.processMessage(
        message,
        context: buildContext()
    )
    // Handle response
}
```

### Task 8.3: Create Module Registry (2 hours)

**Create**: `/AirFit/Core/Services/ModuleRegistry.swift`

```swift
import Foundation

/// Central registry for module interfaces
@MainActor
final class ModuleRegistry {
    static let shared = ModuleRegistry()
    
    private var modules: [String: Any] = [:]
    
    private init() {}
    
    func register<T>(_ module: T, for type: T.Type) {
        let key = String(describing: type)
        modules[key] = module
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return modules[key] as? T
    }
    
    func reset() {
        modules.removeAll()
    }
}

// Usage in app startup
extension ModuleRegistry {
    func configureModules(with container: DependencyContainer) {
        // Register AI module
        let aiCoordinator = AICoordinator(/* dependencies */)
        register(aiCoordinator.interface, for: AIModuleInterface.self)
        
        // Register other modules...
    }
}
```

## Day 9: Service Adapter Standardization

### Task 9.1: Create Service Adapter Protocol (2 hours)

**Create**: `/AirFit/Core/Protocols/ServiceAdapterProtocol.swift`

```swift
import Foundation

/// Base protocol for module-specific service adapters
protocol ServiceAdapterProtocol {
    associatedtype ServiceType
    var underlyingService: ServiceType { get }
    init(service: ServiceType)
}

/// Example implementation for Dashboard
struct DashboardAIServiceAdapter: ServiceAdapterProtocol {
    let underlyingService: AIServiceProtocol
    
    init(service: AIServiceProtocol) {
        self.underlyingService = service
    }
    
    // Dashboard-specific AI methods
    func generateMorningGreeting(for user: User) async throws -> String {
        let context = ConversationContext(
            messages: [],
            systemPrompt: "Generate a personalized morning greeting",
            temperature: 0.8
        )
        return try await underlyingService.sendMessage("", withContext: context)
    }
}
```

### Task 9.2: Standardize Existing Adapters (3 hours)

Update all module service adapters to follow the pattern:
- `DefaultAICoachService` → `DashboardAIServiceAdapter`
- `DefaultDashboardNutritionService` → `DashboardNutritionAdapter`
- `DefaultHealthKitService` → `DashboardHealthKitAdapter`
- `FoodVoiceAdapter` → Ensure it follows the pattern

### Task 9.3: Document Service Adapter Pattern (1 hour)

**Create**: `/AirFit/Docs/SERVICE_ADAPTER_PATTERN.md`

Document when and how to use service adapters vs direct service access.

## Verification Checklist

After Day 6:
- [ ] All protocols end with "Protocol"
- [ ] All services follow naming convention
- [ ] SwiftLint custom rules catching violations
- [ ] No force casts in codebase

After Day 7:
- [ ] Single error type hierarchy
- [ ] Personality insights types consolidated
- [ ] AI message types unified
- [ ] Migration helpers in place

After Day 8:
- [ ] Module interfaces defined
- [ ] No direct module-to-module dependencies
- [ ] Module registry configured
- [ ] All modules use interfaces

After Day 9:
- [ ] Service adapter pattern standardized
- [ ] All adapters follow consistent pattern
- [ ] Documentation complete
- [ ] Clean architecture boundaries

## Testing Strategy

```bash
# Run architecture tests
swift test --filter ArchitectureTests

# Check for naming violations
swiftlint analyze --strict

# Verify module boundaries
./Scripts/check_module_boundaries.sh

# Run integration tests
swift test --filter IntegrationTests
```

## Migration Risks

1. **Breaking Changes**: Renaming protocols will break existing code
2. **Module Interfaces**: Need careful design to avoid over-abstraction
3. **Service Adapters**: Don't over-engineer, only create when needed

## Next Phase Preview

Phase 4 will focus on:
- Dependency injection overhaul
- Service lifecycle management
- Performance optimization
- Final cleanup and validation
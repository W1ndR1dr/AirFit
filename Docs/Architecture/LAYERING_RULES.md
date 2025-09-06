# AirFit Layering Rules

## Overview

This document defines the strict architectural rules that govern dependencies between layers in the AirFit iOS application. These rules ensure maintainability, testability, and clear separation of concerns.

## Layer Definitions

### 1. Application Layer (`AirFit/Application/`)
**Purpose**: Application lifecycle, bootstrapping, and global configuration

**Responsibilities**:
- App entry point and lifecycle management
- Dependency injection container initialization
- ModelContainer setup and error recovery
- Global state and environment management

**Key Components**:
- `AirFitApp.swift` - Main application entry point
- `ContentView.swift` - Root content view
- `MainTabView.swift` - Primary navigation structure
- `NavigationState.swift` - Global navigation state

### 2. Module Layer (`AirFit/Modules/`)
**Purpose**: Feature-specific UI and presentation logic

**Responsibilities**:
- User interface presentation
- User interaction handling
- Local state management (ViewModels)
- Feature-specific navigation
- View composition and layout

**Key Modules**:
- `Dashboard/` - Main dashboard and insights
- `Chat/` - AI conversation interface
- `Settings/` - Application configuration
- `FoodTracking/` - Nutrition logging
- `Workouts/` - Exercise planning and logging

### 3. Service Layer (`AirFit/Services/`)
**Purpose**: Business logic and external system integration

**Responsibilities**:
- Business rule implementation
- External API communication
- Cross-cutting concerns (analytics, monitoring)
- Data transformation and validation
- System integration (HealthKit, Watch, etc.)

**Key Services**:
- `AI/` - Artificial intelligence services
- `Health/` - HealthKit integration
- `Security/` - Authentication and encryption
- `Analytics/` - Usage tracking and metrics
- `Goals/` - Goal management logic

### 4. Data Layer (`AirFit/Data/`)
**Purpose**: Data persistence, retrieval, and repository implementation

**Responsibilities**:
- Data model definitions (SwiftData entities)
- Repository pattern implementations
- Database migrations and schema management
- Data validation and constraints
- Caching strategies

**Key Components**:
- `Models/` - SwiftData entity definitions
- `Repositories/` - Data access abstractions
- `Managers/` - Specialized data management
- `Migrations/` - Database schema evolution

### 5. Core Layer (`AirFit/Core/`)
**Purpose**: Foundational utilities, protocols, and shared components

**Responsibilities**:
- Dependency injection framework
- Protocol definitions and contracts
- Shared utilities and extensions
- Common UI components
- Configuration and constants

**Key Components**:
- `DI/` - Dependency injection container
- `Protocols/` - Service and component contracts
- `Views/` - Reusable UI components
- `Theme/` - Design system and styling
- `Models/` - Shared data structures

## Dependency Rules

### ✅ Allowed Dependencies

| From Layer | To Layer | Examples | Justification |
|------------|----------|----------|---------------|
| Application | Core | `DIContainer`, `GradientManager` | App needs foundational services |
| Application | Data | `ModelContainer` creation | Direct data setup required |
| Module | Service | `AIServiceProtocol`, `HealthKitServiceProtocol` | UI needs business logic |
| Module | Data | `DashboardRepositoryProtocol` | ViewModels need data access |
| Module | Core | `BaseScreen`, `AppFonts` | UI needs shared components |
| Service | Data | Repository protocols | Services need data persistence |
| Service | Core | `ServiceProtocol`, utilities | Services use core infrastructure |
| Data | Core | `ServiceProtocol`, models | Data layer uses core contracts |

### ❌ Forbidden Dependencies

| From Layer | To Layer | Why Forbidden | Violation Impact |
|------------|----------|---------------|-----------------|
| Core | Any Upper Layer | Core must be foundational | Creates circular dependencies |
| Data | Service | Data should be passive | Violates repository pattern |
| Data | Module | Data should not know about UI | Breaks separation of concerns |
| Service | Module | Services should be UI-agnostic | Creates tight coupling |
| Module | Module | Modules should be independent | Reduces reusability |

### Import Rules by Layer

#### Application Layer
```swift
// ✅ Allowed imports
import SwiftUI
import SwiftData
// Internal: Core layer only
// Framework: Standard iOS frameworks only

// ❌ Forbidden imports
import AirFit.Modules.*     // Should not directly import modules
import AirFit.Services.*    // Should use DI container
```

#### Module Layer
```swift
// ✅ Allowed imports
import SwiftUI
import Observation
// Internal: Core protocols, Service protocols, Data protocols

// ❌ Forbidden imports
import HealthKit           // Use HealthKitServiceProtocol instead
import Foundation.URLSession // Use NetworkServiceProtocol instead
// Other modules: Modules/Chat, Modules/Dashboard, etc.
```

#### Service Layer
```swift
// ✅ Allowed imports
import Foundation
import HealthKit          // External frameworks as needed
import Combine
// Internal: Core protocols, Data protocols

// ❌ Forbidden imports
import SwiftUI           // Services should be UI-agnostic
// Modules: Should not import any module
```

#### Data Layer
```swift
// ✅ Allowed imports
import Foundation
import SwiftData
// Internal: Core protocols and models only

// ❌ Forbidden imports
import SwiftUI           // Data should be UI-agnostic
// Services: Should not import service layer
// Modules: Should not import UI modules
```

#### Core Layer
```swift
// ✅ Allowed imports
import Foundation
import SwiftUI           // Only for UI components in Core/Views
import Observation

// ❌ Forbidden imports
// Any internal AirFit imports from upper layers
```

## Architecture Patterns

### Dependency Injection Pattern

**Correct Pattern**:
```swift
// In Module ViewModels
final class DashboardViewModel: ViewModelProtocol {
    private let aiService: AIServiceProtocol          // ✅ Protocol dependency
    private let repository: DashboardRepositoryProtocol // ✅ Repository abstraction
    
    init(aiService: AIServiceProtocol, 
         repository: DashboardRepositoryProtocol) {
        self.aiService = aiService
        self.repository = repository
    }
}
```

**Incorrect Pattern**:
```swift
// ❌ Don't do this
final class DashboardViewModel {
    private let aiService = AIService()               // ❌ Concrete dependency
    private let healthKit = HealthKitManager()        // ❌ Direct instantiation
}
```

### Repository Pattern

**Correct Pattern**:
```swift
// In ViewModels
class DashboardViewModel {
    private let repository: DashboardRepositoryProtocol  // ✅ Protocol abstraction
    
    func loadData() async {
        let data = try await repository.getDashboardData() // ✅ Clean data access
    }
}
```

**Incorrect Pattern**:
```swift
// ❌ Don't do this
class DashboardViewModel {
    @Environment(\.modelContext) private var context    // ❌ Direct SwiftData access
    
    func loadData() {
        let request = FetchDescriptor<User>()            // ❌ Database queries in VM
        let users = try context.fetch(request)
    }
}
```

### Service Abstraction Pattern

**Correct Pattern**:
```swift
// Module using service
class ChatViewModel {
    private let aiService: AIServiceProtocol             // ✅ Protocol dependency
    
    func sendMessage(_ text: String) async {
        let response = try await aiService.generateResponse(text) // ✅ Clean abstraction
    }
}
```

**Incorrect Pattern**:
```swift
// ❌ Don't do this
class ChatViewModel {
    private let openAI = OpenAIProvider()                // ❌ Direct provider access
    private let anthropic = AnthropicProvider()          // ❌ Multiple concrete deps
}
```

## Code Examples

### Layer Boundary Enforcement

#### ✅ Good Examples

**1. ViewModel with Proper Dependencies**:
```swift
@MainActor
@Observable
final class DashboardViewModel: ViewModelProtocol {
    // ✅ Protocol dependencies from allowed layers
    private let dashboardRepository: DashboardRepositoryProtocol  // Data layer
    private let healthKitService: HealthKitServiceProtocol        // Service layer  
    private let aiCoachService: AICoachServiceProtocol            // Service layer
    
    init(dashboardRepository: DashboardRepositoryProtocol,
         healthKitService: HealthKitServiceProtocol,
         aiCoachService: AICoachServiceProtocol) {
        // Dependency injection ensures proper abstractions
    }
}
```

**2. Service with Repository Access**:
```swift
final class NutritionService: NutritionServiceProtocol {
    // ✅ Service can access data through protocols
    private let repository: FoodTrackingRepositoryProtocol
    private let calculator: NutritionCalculatorProtocol
    
    func calculateDailyNutrition(userId: UUID, date: Date) async throws -> NutritionSummary {
        let entries = try await repository.getFoodEntries(userId: userId, date: date)
        return try await calculator.calculateSummary(from: entries)
    }
}
```

**3. Repository with Core Dependencies**:
```swift
final class SwiftDataDashboardRepository: DashboardRepositoryProtocol {
    // ✅ Data layer uses Core protocols and SwiftData
    private let modelContext: ModelContext
    
    func getDashboardData(userId: UUID) async throws -> DashboardData {
        // Direct SwiftData access is appropriate at this layer
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == userId })
        let user = try modelContext.fetch(descriptor).first
        // ... implementation
    }
}
```

#### ❌ Bad Examples

**1. ViewModel with Layer Violations**:
```swift
// ❌ BAD: Multiple layer violations
@Observable
final class BadDashboardViewModel {
    @Environment(\.modelContext) private var context     // ❌ Direct data access
    private let healthKit = HealthKitManager()            // ❌ Concrete service dependency
    private let openAI = OpenAIProvider()                // ❌ Bypassing service layer
    
    func loadData() {
        // ❌ Database queries in ViewModel
        let descriptor = FetchDescriptor<User>()
        let users = try! context.fetch(descriptor)
        
        // ❌ Direct external API calls
        let response = try! openAI.generateText(prompt: "...")
    }
}
```

**2. Service with UI Dependencies**:
```swift
// ❌ BAD: Service depending on UI layer
import SwiftUI  // ❌ Services should not import SwiftUI

final class BadAIService: AIServiceProtocol {
    // ❌ Should not reference UI state
    @State private var isLoading = false
    
    // ❌ Should not handle UI concerns
    func generateResponseWithUI(_ prompt: String) -> some View {
        VStack {
            if isLoading {
                ProgressView()
            }
            // ... UI code in service layer
        }
    }
}
```

**3. Core Layer with Upper Dependencies**:
```swift
// ❌ BAD: Core importing from upper layers
import AirFit.Services  // ❌ Core should not depend on Services

protocol BadCoreProtocol {
    // ❌ Core should not reference service implementations
    func configure(aiService: AIService) async throws
}
```

## Enforcement Strategies

### 1. Code Review Checklist

**Import Analysis**:
- [ ] Check all `import` statements against layer rules
- [ ] Verify protocol usage over concrete types
- [ ] Ensure no circular dependencies

**Dependency Analysis**:
- [ ] ViewModels use service protocols, not implementations
- [ ] Services access data through repository protocols
- [ ] No direct SwiftData/CoreData access in ViewModels

### 2. Static Analysis Rules

**SwiftLint Custom Rules** (potential):
```yaml
custom_rules:
  no_swiftdata_in_viewmodels:
    name: "No SwiftData in ViewModels"
    regex: '@Environment\(\.modelContext\)'
    match_kinds:
      - identifier
    message: "ViewModels should use repository protocols, not direct SwiftData access"
    severity: error
```

### 3. Architecture Testing

**Dependency Tests**:
```swift
class ArchitectureTests: XCTestCase {
    func testViewModelsDependOnProtocolsOnly() {
        // Verify ViewModels only inject protocol types
        // Implementation would use reflection or AST parsing
    }
    
    func testServiceLayerIsUIAgnostic() {
        // Verify services don't import SwiftUI
    }
    
    func testCoreLayerIsFoundational() {
        // Verify Core doesn't depend on upper layers
    }
}
```

## Migration Guidelines

### Converting Layer Violations

**1. ViewModel with Direct SwiftData Access → Repository Pattern**:
```swift
// Before: ❌ Layer violation
class ViewModel {
    @Environment(\.modelContext) private var context
    
    func loadUsers() {
        let users = try! context.fetch(FetchDescriptor<User>())
    }
}

// After: ✅ Proper layering
class ViewModel {
    private let repository: UserRepositoryProtocol
    
    func loadUsers() async throws {
        let users = try await repository.getUsers()
    }
}
```

**2. Service with Concrete Dependencies → Protocol Injection**:
```swift
// Before: ❌ Tight coupling
class NutritionService {
    private let healthKit = HealthKitManager()
    
    func getMetrics() {
        healthKit.fetchNutrition()
    }
}

// After: ✅ Loose coupling
class NutritionService: NutritionServiceProtocol {
    private let healthKit: HealthKitServiceProtocol
    
    init(healthKit: HealthKitServiceProtocol) {
        self.healthKit = healthKit
    }
    
    func getMetrics() async throws {
        try await healthKit.fetchNutrition()
    }
}
```

## Monitoring and Metrics

### Key Indicators

1. **Import Analysis**: Count of cross-layer imports
2. **Protocol Usage**: Percentage of dependencies using protocols vs. concrete types
3. **Layer Isolation**: Number of direct instantiations vs. DI usage
4. **Circular Dependencies**: Detection of reference cycles

### Health Thresholds

- **Protocol Usage**: >90% of dependencies should use protocols
- **Cross-Layer Imports**: <5% violation rate acceptable
- **Direct Instantiations**: <10% in ViewModels (emergency cases only)

---

*Last updated: 2025-09-06*  
*Enforcement level: Strict (violations should fail code review)*
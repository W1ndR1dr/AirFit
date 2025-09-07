# AirFit Dependency Map

## Overview

This document provides a comprehensive view of the AirFit iOS application's dependency structure, module relationships, and architectural boundaries.

## Architecture Layers

AirFit follows a clean architecture pattern with the following layers:

```
┌─────────────────────────────────────────────────────┐
│                 Application Layer                    │
│              (AirFitApp, ContentView)               │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   UI/Module Layer                    │
│        (Modules/Dashboard, Chat, Settings, etc.)    │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                  Service Layer                       │
│    (Services/AI, Health, Analytics, Security, etc.) │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   Data Layer                         │
│       (Data/Repositories, Models, Managers)         │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   Core Layer                         │
│       (Core/DI, Protocols, Models, Views)           │
└─────────────────────────────────────────────────────┘
```

## Module Dependency Matrix

### Application Layer
- **Dependencies**: Core/DI, Core/Theme, Core/Views
- **Responsible for**: App lifecycle, DI container bootstrapping, ModelContainer management

### Module Layer

#### Dashboard Module
```
Modules/Dashboard/
├── ViewModels/DashboardViewModel
│   ├── → DashboardRepositoryProtocol (Data)
│   ├── → HealthKitServiceProtocol (Services)
│   ├── → AICoachServiceProtocol (Services)
│   └── → NutritionServiceProtocol (Services)
├── Views/
│   ├── → Core/Views (UI components)
│   └── → Core/Theme (styling)
└── Services/
    └── → NutritionGoalService (Services)
```

#### Chat Module
```
Modules/Chat/
├── ViewModels/ChatViewModel
│   ├── → AIServiceProtocol (Services)
│   ├── → ConversationManager (Services)
│   └── → ChatHistoryRepository (Data)
└── Views/
    ├── → Core/Views (UI components)
    └── → Core/Models (data types)
```

#### Food Tracking Module
```
Modules/FoodTracking/
├── Views/
│   ├── → NutritionService (Services)
│   ├── → VoiceInputManager (Services)
│   └── → FoodTrackingRepository (Data)
└── Services/
    └── → NutritionImportService
```

#### Settings Module
```
Modules/Settings/
├── ViewModels/
│   ├── → APIKeyManager (Services)
│   ├── → HealthKitManager (Services)
│   └── → AIService (Services)
└── Views/
    └── → Core/Views
```

### Service Layer

#### AI Services
```
Services/AI/
├── AIService
│   ├── → LLMProviders/* (internal)
│   ├── → NetworkClient (Services)
│   └── → APIKeyManager (Services)
├── CoachEngine
│   ├── → AIService
│   ├── → ContextAssembler (Services)
│   └── → ConversationManager
└── PersonaService
    ├── → AIServiceProtocol
    ├── → PersonaSynthesizer
    └── → ModelContext (Data)
```

#### Health Services
```
Services/Health/
├── HealthKitManager
│   └── → HealthKit (Framework)
├── HealthKitProvider
│   └── → HealthKitManager
└── HealthKitSleepAnalyzer
    └── → HealthKitManager
```

#### Nutrition Services
```
Services/Nutrition/
└── NutritionCalculator
    └── → HealthKitManaging (Health)
```

### Data Layer

#### Repositories
```
Data/Repositories/
├── Dashboard/
│   ├── DashboardRepositoryProtocol
│   └── SwiftDataDashboardRepository → ModelContext
├── FoodTracking/
│   ├── FoodTrackingRepositoryProtocol
│   └── SwiftDataFoodTrackingRepository → ModelContext
├── ChatHistoryRepository → ModelContext
├── UserReadRepository → ModelContext
└── WorkoutReadRepository → ModelContext
```

#### Data Models
```
Data/Models/
├── User, DailyLog, FoodEntry, etc. (SwiftData models)
└── CoachMessage, ChatSession, etc.
```

### Core Layer

#### Dependency Injection
```
Core/DI/
├── DIContainer (container implementation)
├── DIBootstrapper (service registration)
└── DIViewModelFactory (ViewModel creation)
```

#### Protocols
```
Core/Protocols/
├── ServiceProtocol (base service contract)
├── ViewModelProtocol (base ViewModel contract)
├── AIServiceProtocol, HealthKitServiceProtocol, etc.
└── Repository protocols (abstraction layer)
```

## Dependency Flow Rules

### ✅ Allowed Dependencies

1. **Application → Core**: App can use DI container and core utilities
2. **Modules → Services**: ViewModels can inject and use service protocols
3. **Modules → Data**: ViewModels can inject repository protocols
4. **Modules → Core**: Views can use core components and themes
5. **Services → Data**: Services can access repositories via protocols
6. **Services → Core**: Services can use core protocols and utilities
7. **Data → Core**: Repositories can use core models and protocols

### ❌ Forbidden Dependencies

1. **Core → Any Upper Layer**: Core must not depend on Services, Data, Modules, or Application
2. **Data → Services**: Repositories should not directly use services
3. **Services → Modules**: Services should not depend on UI modules
4. **Cross-Module**: Modules should not directly depend on other modules

## Key Abstraction Points

### Protocol-Based Boundaries

1. **Service Protocols** (`Core/Protocols/*ServiceProtocol.swift`)
   - Abstract service implementations from consumers
   - Enable dependency injection and testing
   - Examples: `AIServiceProtocol`, `HealthKitServiceProtocol`

2. **Repository Protocols** (`Data/Repositories/*RepositoryProtocol.swift`)
   - Abstract data access from ViewModels
   - Provide clean boundary between UI and persistence
   - Examples: `DashboardRepositoryProtocol`, `ChatHistoryRepositoryProtocol`

3. **ViewModel Protocols** (`Core/Protocols/ViewModelProtocol.swift`)
   - Standardize ViewModel contracts
   - Enable consistent error handling and loading states

### Dependency Injection Points

1. **DIBootstrapper** - Central service registration
2. **DIViewModelFactory** - ViewModel creation with dependencies
3. **Service Resolution** - Lazy resolution via protocols

## Module Responsibilities

### Application Layer
- App lifecycle management
- DI container initialization
- ModelContainer setup and error recovery
- Global error handling

### Module Layer
- User interface presentation
- User interaction handling
- ViewModel-based state management
- Navigation coordination

### Service Layer
- Business logic implementation
- External API integration
- Cross-cutting concerns (analytics, logging)
- Health and fitness data processing

### Data Layer
- Data persistence and retrieval
- Repository pattern implementation
- Database migrations and schema management
- Data model definitions

### Core Layer
- Dependency injection framework
- Shared protocols and contracts
- Common utilities and extensions
- Reusable UI components and themes

## Critical Dependencies

### High-Impact Services
1. **AIService** - Used by Chat, Dashboard, Settings modules
2. **HealthKitManager** - Used by Dashboard, Nutrition, Analytics services
3. **DIContainer** - Used by Application and all service-consuming components

### Data Flow Bottlenecks
1. **ModelContext** - Single source of SwiftData access
2. **APIKeyManager** - Required for all AI operations
3. **ContextAssembler** - Aggregates data for AI context

## Testing Strategy

### Protocol-Based Mocking
- All major dependencies use protocols
- Test doubles in `AirFitTests/TestDoubles/`
- Dependency injection enables clean unit testing

### Layer Isolation
- Each layer can be tested independently
- Repository protocols isolate ViewModels from data concerns
- Service protocols isolate ViewModels from external dependencies

## Architecture Health Metrics

### Good Patterns Observed
✅ Consistent use of protocols for abstraction  
✅ Clear separation of concerns across layers  
✅ Dependency injection throughout the application  
✅ Repository pattern isolates data access  
✅ Service layer provides clean business logic boundary  

### Areas for Monitoring
⚠️ Service layer complexity (AIService has many responsibilities)  
⚠️ ViewModel dependency counts (some VMs have 4+ services)  
⚠️ Cross-module communication patterns  
⚠️ Core layer growth (ensure it stays foundational)  

---

*Last updated: 2025-09-06*  
*Analysis performed on branch: claude/T16-dependency-map-refresh*
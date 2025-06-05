# Phase 2: Service Migration & WeatherKit Integration

## Overview
Complete service migration, implement Apple's WeatherKit, create missing default services, and decompose the 2350-line CoachEngine.

## Current Reality
- **Mock directory moved**: ✅ But mocks still referenced in production
- **WeatherKit**: 0% - Only TODO comments exist
- **CoachEngine**: Still 2350 lines, no decomposition
- **Default services**: Some created, but gaps remain

## Task 1: Complete Mock Service Migration (2 hours)

### 1.1: Update Test Mocks
**File**: `/AirFit/AirFitTests/Mocks/MockAIAPIService.swift`

Remove AIAPIServiceProtocol reference:
```swift
// Change from:
final class MockAIAPIService: AIAPIServiceProtocol {

// To:
final class MockAIService: AIServiceProtocol {
    // Update all methods to match new protocol
}
```

### 1.2: Remove SimpleMockAIService from Production
After creating OfflineAIService in Phase 1:
- Delete `/AirFit/Services/AI/SimpleMockAIService.swift`
- Update preview contexts to use proper preview services

## Task 2: Implement Apple WeatherKit (6 hours)

### 2.1: Add WeatherKit Capability
**In Xcode**:
1. Select project → Signing & Capabilities
2. Add WeatherKit capability
3. Enable in Apple Developer portal

### 2.2: Create WeatherKit Service
**Create**: `/AirFit/Services/Weather/WeatherKitService.swift`

```swift
import Foundation
import WeatherKit
import CoreLocation

@MainActor
final class WeatherKitService: WeatherServiceProtocol {
    let serviceIdentifier = "weatherkit-service"
    private(set) var isConfigured = false
    
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    
    func configure() async throws {
        // WeatherKit requires no API keys!
        isConfigured = true
        AppLogger.info("WeatherKit configured", category: .services)
    }
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let weather = try await weatherService.weather(for: location)
        
        return ServiceWeatherData(
            temperature: weather.currentWeather.temperature.value,
            condition: mapCondition(weather.currentWeather.condition),
            humidity: weather.currentWeather.humidity,
            windSpeed: weather.currentWeather.wind.speed.value,
            location: "Current Location",
            timestamp: Date()
        )
    }
    
    private func mapCondition(_ condition: WeatherCondition) -> ServiceWeatherCondition {
        // Map Apple's conditions to our internal enum
        switch condition {
        case .clear: return .clear
        case .cloudy, .mostlyCloudy: return .cloudy
        case .partlyCloudy: return .partlyCloudy
        case .rain, .drizzle: return .rain
        case .snow: return .snow
        case .thunderstorms: return .thunderstorm
        default: return .partlyCloudy
        }
    }
}
```

### 2.3: Remove Old Weather Service
- Delete `/AirFit/Services/WeatherService.swift` (467 lines of API code)
- Update DependencyContainer to use WeatherKitService

## Task 3: Create Missing Default Services (3 hours)

### 3.1: DefaultWorkoutService
**Create**: `/AirFit/Services/Workout/DefaultWorkoutService.swift`

```swift
actor DefaultWorkoutService: WorkoutServiceProtocol {
    let serviceIdentifier = "default-workout-service"
    private(set) var isConfigured = false
    
    @MainActor private let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }
    
    func configure() async throws {
        isConfigured = true
    }
    
    func createWorkout(_ workout: Workout) async throws {
        await dataManager.create(workout)
    }
    
    func getRecentWorkouts(limit: Int) async throws -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try await dataManager.fetch(descriptor, limit: limit)
    }
    
    // Implement remaining protocol methods...
}
```

### 3.2: Consolidate Service Creation
Update ServiceRegistry to use all default implementations consistently.

## Task 4: Decompose CoachEngine (8 hours)

### 4.1: Extract Message Processing
**Create**: `/AirFit/Modules/AI/Components/MessageProcessor.swift`

Move ~500 lines of message handling logic:
```swift
actor MessageProcessor {
    private let aiService: AIServiceProtocol
    private let contextBuilder: ContextBuilder
    
    func processMessage(
        _ message: String,
        mode: PersonaMode,
        context: ConversationContext
    ) async throws -> String {
        // Extract from CoachEngine lines 600-1100
    }
}
```

### 4.2: Extract Conversation State Management
**Create**: `/AirFit/Modules/AI/Components/ConversationStateManager.swift`

Move ~400 lines of state management:
```swift
actor ConversationStateManager {
    private var sessions: [UUID: ConversationState] = [:]
    
    func createSession(userId: UUID, mode: PersonaMode) -> ConversationState {
        // Extract session management logic
    }
    
    func updateSession(_ sessionId: UUID, with message: Message) {
        // Extract state updates
    }
}
```

### 4.3: Extract System Prompt Builder
**Create**: `/AirFit/Modules/AI/Components/SystemPromptBuilder.swift`

Move ~300 lines of prompt construction:
```swift
struct SystemPromptBuilder {
    func buildPrompt(
        for mode: PersonaMode,
        user: User,
        context: HealthContextSnapshot
    ) -> String {
        // Extract prompt building logic
    }
}
```

### 4.4: Refactor CoachEngine
Reduce to ~500 lines by using extracted components:
```swift
actor CoachEngine {
    private let messageProcessor: MessageProcessor
    private let stateManager: ConversationStateManager
    private let promptBuilder: SystemPromptBuilder
    private let functionDispatcher: FunctionCallDispatcher
    
    // Simplified orchestration logic only
}
```

## Task 5: Fix Service Singletons (2 hours)

### 5.1: NetworkManager
Convert from singleton to proper service:
```swift
// Remove: static let shared = NetworkManager()
// Add proper initialization in ServiceRegistry
```

### 5.2: WorkoutSyncService
Same treatment - remove singleton pattern.

## Verification

```bash
# Check for remaining mocks in production
grep -r "Mock.*Service" AirFit/ | grep -v "AirFitTests" | grep -v "Preview"

# Verify WeatherKit integration
xcodebuild test -scheme "AirFit" -testPlan "WeatherTests"

# Check CoachEngine size
wc -l AirFit/Modules/AI/CoachEngine.swift
```

## Time Estimate: 2-3 days

More realistic than original "1 day" estimate given the scope.

## Success Criteria
- [ ] No mock services in production code
- [ ] WeatherKit fully integrated (no API keys!)
- [ ] All default services implemented
- [ ] CoachEngine under 600 lines
- [ ] No singleton services
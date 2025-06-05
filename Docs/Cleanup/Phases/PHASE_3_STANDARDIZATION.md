# Phase 3: Pattern Standardization

## Overview
Migrate 21 ObservableObject classes to modern @Observable pattern, consolidate 3 API key protocols, and standardize error handling.

## Current Reality (Validated)
- **21 ObservableObject classes** found (not 13)
- **3 API key protocols** exist (not 2): APIKeyManagerProtocol, APIKeyManagementProtocol, APIKeyManaging
- **ChatViewModel**: 344 lines with complex Combine usage
- **Error handling**: AppError already well-structured with 9 cases
- **Most services**: Already use async/await (good news!)

## Task 1: ObservableObject Migration (10 days)

### 1.1: Complete Class List (21 Classes)
**ViewModels & Coordinators (13)**:
1. ChatCoordinator
2. ChatViewModel (344 lines) ⭐ Most complex
3. ChatHistoryManager
4. DashboardCoordinator
5. PreviewGenerator
6. CameraManager (in PhotoInputView)
7. FoodVoiceAdapter
8. NotificationsCoordinator
9. ConversationCoordinator
10. VoiceRecorder (in VoiceInputView)
11. ConversationFlowManager
12. OnboardingProgressManager
13. OnboardingOrchestrator

**Services (8)**:
14. NetworkManager (317 lines) ⭐ Complex
15. ExerciseDatabase (393 lines) ⭐ Complex
16. LiveActivityManager
17. NotificationContentGenerator
18. WhisperModelManager
19. AppState
20. HealthKitAuthManager
21. LocationManager

### 1.2: Migration Strategy (Revised)
Given the complexity, use a risk-based approach:

**Week 1 - Low Risk (3 days)**:
Simple coordinators and managers with minimal state:
- DashboardCoordinator
- NotificationsCoordinator
- ConversationCoordinator
- LiveActivityManager
- NotificationContentGenerator

**Week 1 - Medium Risk (2 days)**:
Managers with moderate complexity:
- ChatHistoryManager
- OnboardingProgressManager
- ConversationFlowManager
- PreviewGenerator
- HealthKitAuthManager

**Week 2 - High Risk (3 days)**:
Complex services with significant state:
- NetworkManager (has Combine publishers)
- ExerciseDatabase (has search functionality)
- WhisperModelManager (has download progress)
- AppState (app-wide state management)

**Week 2 - Critical (2 days)**:
User-facing components requiring careful testing:
- ChatViewModel (streaming, voice, function calls)
- FoodVoiceAdapter (audio recording)
- VoiceRecorder (AVAudioRecorder integration)
- CameraManager (camera session management)

### 1.3: Migration Pattern Examples

**Simple Migration** (DashboardCoordinator):
```swift
// BEFORE
final class DashboardCoordinator: ObservableObject {
    @Published var selectedTab = 0
    @Published var showProfile = false
}

// AFTER
@MainActor
@Observable
final class DashboardCoordinator {
    var selectedTab = 0
    var showProfile = false
}
```

**Complex Migration** (ChatViewModel simplified):
```swift
// BEFORE
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isLoading = false
    private var streamCancellable: AnyCancellable?
    
    private func streamResponse() {
        streamCancellable = aiService
            .streamMessage(prompt)
            .sink(
                receiveCompletion: { /* ... */ },
                receiveValue: { /* ... */ }
            )
    }
}

// AFTER
@MainActor
@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    private(set) var isLoading = false
    private var streamTask: Task<Void, Never>?
    
    private func streamResponse() async {
        streamTask = Task {
            do {
                let stream = try await aiService.streamMessage(prompt, withContext: context)
                for try await chunk in stream {
                    // Process chunk
                }
            } catch {
                // Handle error
            }
        }
    }
}
```

### 1.4: Testing Strategy
For each migrated class:
1. Create snapshot of current behavior
2. Migrate to @Observable
3. Run comparison tests
4. Check SwiftUI preview functionality
5. Profile for performance regression

## Task 2: API Protocol Consolidation (2 days)

### 2.1: Current State (3 Protocols!)
```swift
// Protocol 1: APIKeyManagerProtocol (13 files)
protocol APIKeyManagerProtocol {
    func getAPIKey(for provider: String) async -> String?
    func setAPIKey(_ key: String?, for provider: String) async
}

// Protocol 2: APIKeyManagementProtocol (16 files)
protocol APIKeyManagementProtocol: AnyObject, Sendable {
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws
    func getAPIKey(for provider: AIProvider) async throws -> String
    func deleteAPIKey(for provider: AIProvider) async throws
    func hasAPIKey(for provider: AIProvider) async -> Bool
    func getAllConfiguredProviders() async -> [AIProvider]
}

// Protocol 3: APIKeyManaging (found in LLMOrchestrator)
// Appears to be a type alias or another variant
```

### 2.2: Consolidation Plan
1. **Analyze usage patterns** in all 29+ files
2. **Create unified protocol** with all needed functionality:
```swift
protocol APIKeyManagerProtocol: AnyObject, Sendable {
    // Core functionality
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws
    func getAPIKey(for provider: AIProvider) async throws -> String
    func deleteAPIKey(for provider: AIProvider) async throws
    func hasAPIKey(for provider: AIProvider) async -> Bool
    func getAllConfiguredProviders() async -> [AIProvider]
    
    // Legacy support during migration
    func getAPIKey(for providerString: String) async -> String?
    func setAPIKey(_ key: String?, for provider: String) async
}
```

3. **Update DefaultAPIKeyManager** to implement unified protocol
4. **Migrate files in dependency order**:
   - Start with leaf nodes (views, view models)
   - Then services
   - Finally core components (LLMOrchestrator)

### 2.3: Migration Script
```bash
#!/bin/bash
# Find all files using each protocol
echo "=== APIKeyManagerProtocol usage ==="
grep -l "APIKeyManagerProtocol" -r AirFit/ | grep -v "\.md"

echo -e "\n=== APIKeyManagementProtocol usage ==="
grep -l "APIKeyManagementProtocol" -r AirFit/ | grep -v "\.md"

echo -e "\n=== APIKeyManaging usage ==="
grep -l "APIKeyManaging" -r AirFit/ | grep -v "\.md"

# After consolidation, verify
echo -e "\n=== Remaining protocol references ==="
grep -r "APIKey.*Protocol" AirFit/ | grep -v "APIKeyManagerProtocol" | grep -v "\.md"
```

## Task 3: Error Standardization (1 day)

### 3.1: Current AppError State
Already has good foundation with 9 cases:
- authenticationError, networkError, dataError, configurationError
- validationError, notFound, permissionDenied, serverError, unknown

### 3.2: Add Missing Cases
```swift
extension AppError {
    // AI-specific errors
    case aiProviderNotConfigured(AIProvider)
    case aiResponseInvalid(reason: String)
    case aiServiceOffline
    case aiTokenLimitExceeded(used: Int, limit: Int)
    
    // Service errors
    case serviceNotConfigured(String)
    case serviceHealthCheckFailed(String, ServiceHealth)
    
    // Sync errors
    case syncConflict(localVersion: Int, remoteVersion: Int)
    case offlineDataStale(lastSync: Date)
}
```

### 3.3: Error Recovery
Enhance existing `recoverySuggestion`:
```swift
extension AppError {
    var recoveryAction: ErrorRecoveryAction? {
        switch self {
        case .aiProviderNotConfigured:
            return .goToSettings(screen: .apiConfiguration)
        case .networkError:
            return .retry(after: 2.0)
        case .aiServiceOffline:
            return .useOfflineMode
        case .syncConflict:
            return .resolveConflict
        default:
            return nil
        }
    }
}

enum ErrorRecoveryAction {
    case retry(after: TimeInterval)
    case goToSettings(screen: SettingsScreen)
    case useOfflineMode
    case resolveConflict
    case contactSupport
}
```

## Task 4: Fix Broken Tests (1 day)

### 4.1: Update Mock References
Many tests reference deleted services:
- Update `MockAIAPIService` to use `AIServiceProtocol`
- Fix `ServicePerformanceTests` references to `EnhancedAIAPIService`
- Update mock locations in test files

### 4.2: Create Test Migration Guide
Document patterns for updating tests after ObservableObject migration.

## Time Estimate: 14 days (2-3 weeks)

### Breakdown:
- ObservableObject migration: 10 days
- API protocol consolidation: 2 days
- Error standardization: 1 day
- Test fixes: 1 day

This is realistic given:
- 21 classes to migrate (not 13)
- Some classes are 300-400 lines with complex state
- 3 protocols to consolidate across 29+ files
- Need careful testing to avoid regressions

## Success Criteria
- [ ] All 21 classes migrated to @Observable
- [ ] Single APIKeyManagerProtocol used everywhere
- [ ] No broken tests
- [ ] No performance regressions
- [ ] All SwiftUI previews working
- [ ] Memory usage unchanged or improved

## Risk Mitigation
1. **Create migration branches** for each batch of classes
2. **Extensive testing** after each migration
3. **Performance profiling** for complex classes
4. **Keep Combine** where it makes sense (don't force everything to async/await)
5. **Fallback plan**: Can revert individual class migrations if issues arise

## Notes for Success
- ChatViewModel is the riskiest migration - save for last
- NetworkManager and ExerciseDatabase need careful handling
- Some Combine usage (like debouncing) might be worth keeping
- Watch for SwiftUI update cycles with @Observable
- Test voice/camera features thoroughly after migration
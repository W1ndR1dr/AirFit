# Phase 3: Integration & Testing - Enhanced Implementation Guide

## 🎯 Phase Overview
Integrate the conversational foundation and AI synthesis into a cohesive system. This phase focuses on connecting all components, migrating from the old system, and ensuring production readiness.

## 🚀 Implementation Strategy
- **Approach**: End-to-end integration with comprehensive testing
- **Context Limit**: 10-15 subtasks per session
- **Validation**: Integration tests after each batch
- **Commits**: Feature-complete commits with full test coverage

## 📦 Deliverables Checklist
- [ ] Full onboarding flow integration
- [ ] Migration from 4-persona system
- [ ] A/B testing framework
- [ ] Performance optimization (<5s persona generation)
- [ ] Error handling and recovery
- [ ] Analytics integration
- [ ] Comprehensive test suite
- [ ] Production monitoring

## 🏗️ Implementation Batches

### Batch 3.1: Core Integration (Tasks 1-5)
**Estimated Time**: 6 hours
**Context Requirements**: Phase 1 & 2 components, existing app architecture

#### Task 3.1.1: Create Integration Orchestrator
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/OnboardingOrchestrator.swift
- AirFit/Modules/Onboarding/Services/OnboardingState.swift

# Acceptance Criteria:
- Coordinates conversation flow and persona synthesis
- Manages state transitions
- Handles async operations
- Error recovery mechanisms

# Test Command:
swift test --filter OnboardingOrchestratorTests
```

**Implementation**:
```swift
// OnboardingOrchestrator.swift
import Foundation
import SwiftData

@MainActor
final class OnboardingOrchestrator: ObservableObject {
    // MARK: - Dependencies
    private let conversationManager: ConversationFlowManager
    private let personaExtractor: PersonalityExtractor
    private let personaSynthesizer: PersonaSynthesizer
    private let userService: UserServiceProtocol
    private let analytics: ConversationAnalytics
    
    // MARK: - State
    @Published private(set) var state: OnboardingState = .notStarted
    @Published private(set) var progress: OnboardingProgress = .init()
    @Published private(set) var error: OnboardingError?
    
    // MARK: - Initialization
    init(
        conversationManager: ConversationFlowManager,
        personaExtractor: PersonalityExtractor,
        personaSynthesizer: PersonaSynthesizer,
        userService: UserServiceProtocol,
        analytics: ConversationAnalytics
    ) {
        self.conversationManager = conversationManager
        self.personaExtractor = personaExtractor
        self.personaSynthesizer = personaSynthesizer
        self.userService = userService
        self.analytics = analytics
    }
    
    // MARK: - Public Methods
    func startOnboarding() async throws {
        state = .conversationInProgress
        analytics.trackOnboardingStarted()
        
        do {
            // Start conversation flow
            let session = try await conversationManager.startNewSession()
            progress.conversationStarted = true
            
            // Monitor progress
            startProgressMonitoring()
            
        } catch {
            handleError(.conversationStartFailed(error))
            throw error
        }
    }
    
    func submitResponse(_ response: ConversationResponse) async throws {
        do {
            // Process response
            let nextNode = try await conversationManager.processResponse(response)
            
            // Update progress
            progress.nodesCompleted += 1
            progress.completionPercentage = conversationManager.completionPercentage
            
            // Check if ready for synthesis
            if conversationManager.isReadyForSynthesis {
                await transitionToSynthesis()
            }
            
        } catch {
            handleError(.responseProcessingFailed(error))
            throw error
        }
    }
    
    func completeOnboarding() async throws {
        guard case .reviewingPersona(let persona) = state else {
            throw OnboardingError.invalidStateTransition
        }
        
        state = .saving
        
        do {
            // Save persona to user profile
            try await userService.updateCoachPersona(persona)
            
            // Mark onboarding complete
            try await userService.setOnboardingComplete(true)
            
            // Track completion
            analytics.trackOnboardingCompleted(
                duration: progress.duration,
                personaId: persona.id
            )
            
            state = .completed
            
        } catch {
            handleError(.saveFailed(error))
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func transitionToSynthesis() async {
        state = .synthesizingPersona
        progress.synthesisStarted = true
        
        do {
            // Extract personality from conversation
            let responses = conversationManager.getAllResponses()
            let personality = try await personaExtractor.extractPersonality(
                from: responses,
                metadata: conversationManager.metadata
            )
            
            progress.extractionComplete = true
            
            // Synthesize coach persona
            let userGoals = conversationManager.extractedGoals
            let lifeContext = conversationManager.extractedContext
            let preferences = conversationManager.extractedPreferences
            
            let persona = try await personaSynthesizer.synthesizeCoachPersona(
                personality: personality,
                goals: userGoals,
                context: lifeContext,
                preferences: preferences
            )
            
            progress.synthesisComplete = true
            state = .reviewingPersona(persona)
            
        } catch {
            handleError(.synthesisFailed(error))
        }
    }
    
    private func handleError(_ error: OnboardingError) {
        self.error = error
        state = .error(error)
        analytics.trackError(error)
    }
}

// OnboardingState.swift
enum OnboardingState: Equatable {
    case notStarted
    case conversationInProgress
    case synthesizingPersona
    case reviewingPersona(CoachPersona)
    case adjustingPersona(CoachPersona)
    case saving
    case completed
    case error(OnboardingError)
}

struct OnboardingProgress {
    var conversationStarted = false
    var nodesCompleted = 0
    var totalNodes = 12 // Configurable
    var completionPercentage: Double = 0
    var synthesisStarted = false
    var extractionComplete = false
    var synthesisComplete = false
    var startTime = Date()
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

enum OnboardingError: LocalizedError {
    case conversationStartFailed(Error)
    case responseProcessingFailed(Error)
    case synthesisFailed(Error)
    case saveFailed(Error)
    case invalidStateTransition
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .conversationStartFailed(let error):
            return "Failed to start conversation: \(error.localizedDescription)"
        case .responseProcessingFailed(let error):
            return "Failed to process response: \(error.localizedDescription)"
        case .synthesisFailed(let error):
            return "Failed to create your coach: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .invalidStateTransition:
            return "Invalid operation for current state"
        case .timeout:
            return "Operation timed out"
        }
    }
}
```

#### Task 3.1.2: Update OnboardingViewModel for Integration
```bash
# Files to modify:
- AirFit/Modules/Onboarding/ViewModels/OnboardingViewModel.swift

# Acceptance Criteria:
- Integrate with OnboardingOrchestrator
- Handle all state transitions
- Provide UI-ready data
- Maintain backward compatibility

# Test Command:
swift test --filter OnboardingViewModelTests
```

#### Task 3.1.3: Create Unified Onboarding Flow View
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/UnifiedOnboardingView.swift
- AirFit/Modules/Onboarding/Views/OnboardingStateView.swift

# Acceptance Criteria:
- Single entry point for onboarding
- Smooth transitions between states
- Loading and error states
- Accessibility support

# Test Command:
xcodebuild test -scheme "AirFit" -only-testing:AirFitUITests/OnboardingFlow
```

#### Task 3.1.4: Implement Error Recovery
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/OnboardingRecovery.swift

# Acceptance Criteria:
- Resume interrupted conversations
- Retry failed synthesis
- Graceful degradation
- Clear user communication

# Test Command:
swift test --filter OnboardingRecoveryTests
```

#### Task 3.1.5: Add Progress Persistence
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/OnboardingProgressManager.swift

# Acceptance Criteria:
- Save progress at each step
- Resume from any point
- Clean up completed sessions
- Handle version migrations

# Test Command:
swift test --filter OnboardingProgressTests
```

### Checkpoint 3.1
```bash
# Integration test
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/OnboardingIntegration

# Manual flow test
# Complete full onboarding with various paths

# Commit
git add -A
git commit -m "feat(onboarding): implement core integration orchestrator

- Add OnboardingOrchestrator for flow coordination
- Update ViewModel with state management
- Create unified onboarding view
- Implement error recovery mechanisms
- Add progress persistence

Part of persona refactor Phase 3"
```

### Batch 3.2: Migration System (Tasks 6-10)
**Estimated Time**: 8 hours
**Context Requirements**: Existing user data, old persona system

#### Task 3.2.6: Create Migration Coordinator
```bash
# Files to create:
- AirFit/Services/Migration/PersonaMigrationCoordinator.swift
- AirFit/Services/Migration/MigrationModels.swift

# Acceptance Criteria:
- Detect users with old personas
- Plan migration strategy
- Track migration progress
- Rollback capability

# Test Command:
swift test --filter PersonaMigrationTests
```

**Implementation**:
```swift
// PersonaMigrationCoordinator.swift
import Foundation
import SwiftData

actor PersonaMigrationCoordinator {
    private let userService: UserServiceProtocol
    private let personaSynthesizer: PersonaSynthesizer
    private let analytics: AnalyticsProtocol
    
    func needsMigration(for user: User) -> Bool {
        // Check if user has old 4-persona system data
        if let coachStyle = user.settings?.coachingStyle {
            return coachStyle.usesFourPersonaSystem
        }
        return false
    }
    
    func planMigration(for user: User) async throws -> MigrationPlan {
        guard needsMigration(for: user) else {
            throw MigrationError.noMigrationNeeded
        }
        
        let currentData = try extractCurrentPersonaData(user)
        let strategy = determineMigrationStrategy(currentData)
        
        return MigrationPlan(
            userId: user.id,
            strategy: strategy,
            estimatedDuration: strategy.estimatedDuration,
            dataToMigrate: currentData,
            requiresUserInput: strategy.requiresUserInput
        )
    }
    
    func executeMigration(_ plan: MigrationPlan) async throws -> MigrationResult {
        let startTime = Date()
        
        do {
            analytics.track("migration_started", properties: [
                "strategy": plan.strategy.rawValue,
                "user_id": plan.userId.uuidString
            ])
            
            let result = try await performMigration(plan)
            
            analytics.track("migration_completed", properties: [
                "duration": Date().timeIntervalSince(startTime),
                "success": true
            ])
            
            return result
            
        } catch {
            analytics.track("migration_failed", properties: [
                "error": error.localizedDescription,
                "duration": Date().timeIntervalSince(startTime)
            ])
            throw error
        }
    }
    
    private func performMigration(_ plan: MigrationPlan) async throws -> MigrationResult {
        switch plan.strategy {
        case .automatic:
            return try await performAutomaticMigration(plan)
        case .guided:
            return try await performGuidedMigration(plan)
        case .fresh:
            return MigrationResult(
                success: true,
                newPersonaId: nil,
                requiresOnboarding: true
            )
        }
    }
    
    private func performAutomaticMigration(_ plan: MigrationPlan) async throws -> MigrationResult {
        // Extract personality from historical data
        let historicalData = try await gatherHistoricalData(plan.userId)
        let personality = try await inferPersonality(from: historicalData)
        
        // Generate new persona
        let persona = try await personaSynthesizer.synthesizeFromLegacy(
            personality: personality,
            legacyData: plan.dataToMigrate
        )
        
        // Save new persona
        try await userService.updateCoachPersona(persona)
        
        return MigrationResult(
            success: true,
            newPersonaId: persona.id,
            requiresOnboarding: false
        )
    }
}

// MigrationModels.swift
struct MigrationPlan {
    let userId: UUID
    let strategy: MigrationStrategy
    let estimatedDuration: TimeInterval
    let dataToMigrate: LegacyPersonaData
    let requiresUserInput: Bool
}

enum MigrationStrategy: String {
    case automatic // Full data available for conversion
    case guided    // Need some user input
    case fresh     // Start from scratch
    
    var estimatedDuration: TimeInterval {
        switch self {
        case .automatic: return 30  // seconds
        case .guided: return 300    // 5 minutes
        case .fresh: return 600     // 10 minutes
        }
    }
    
    var requiresUserInput: Bool {
        switch self {
        case .automatic: return false
        case .guided, .fresh: return true
        }
    }
}

struct LegacyPersonaData {
    let styleBlend: [String: Double]
    let preferences: [String: Any]
    let historicalInteractions: Int
    let lastActiveDate: Date
}

struct MigrationResult {
    let success: Bool
    let newPersonaId: UUID?
    let requiresOnboarding: Bool
    let migrationDuration: TimeInterval?
    let dataLoss: DataLossReport?
}

struct DataLossReport {
    let lostFeatures: [String]
    let preservedFeatures: [String]
    let recommendations: [String]
}
```

#### Task 3.2.7: Create Legacy Data Extractor
```bash
# Files to create:
- AirFit/Services/Migration/LegacyDataExtractor.swift

# Acceptance Criteria:
- Extract all relevant data from old system
- Convert to new format
- Identify data gaps
- Generate migration report

# Test Command:
swift test --filter LegacyDataExtractorTests
```

#### Task 3.2.8: Create Migration UI Flow
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/MigrationView.swift
- AirFit/Modules/Onboarding/Views/MigrationOptionsView.swift

# Acceptance Criteria:
- Explain changes to users
- Offer migration options
- Show progress
- Handle migration results

# Test Command:
xcodebuild test -scheme "AirFit" -only-testing:AirFitUITests/Migration
```

#### Task 3.2.9: Implement Rollback System
```bash
# Files to create:
- AirFit/Services/Migration/MigrationRollback.swift

# Acceptance Criteria:
- Backup original data
- Restore on failure
- Version tracking
- Audit trail

# Test Command:
swift test --filter MigrationRollbackTests
```

#### Task 3.2.10: Add Migration Analytics
```bash
# Files to create:
- AirFit/Services/Migration/MigrationAnalytics.swift

# Acceptance Criteria:
- Track migration success rates
- Monitor performance
- Identify failure patterns
- User satisfaction metrics

# Test Command:
swift test --filter MigrationAnalyticsTests
```

### Checkpoint 3.2
```bash
# Test migration scenarios
swift test --filter MigrationIntegrationTests

# Manual test with test data
# Test automatic, guided, and fresh migrations

# Commit
git commit -m "feat(migration): implement persona system migration

- Add migration coordinator and planning
- Create legacy data extraction
- Implement migration UI flow
- Add rollback capabilities
- Track migration analytics

Part of persona refactor Phase 3"
```

### Batch 3.3: A/B Testing Framework (Tasks 11-15)
**Estimated Time**: 6 hours
**Context Requirements**: Analytics system, feature flags

#### Task 3.3.11: Create A/B Test Framework
```bash
# Files to create:
- AirFit/Services/ABTesting/ABTestManager.swift
- AirFit/Services/ABTesting/ABTestModels.swift

# Acceptance Criteria:
- Define test variants
- Random assignment
- Consistent bucketing
- Result tracking

# Test Command:
swift test --filter ABTestManagerTests
```

**Implementation**:
```swift
// ABTestManager.swift
import Foundation

@MainActor
final class ABTestManager: ObservableObject {
    static let shared = ABTestManager()
    
    @Published private(set) var activeTests: [ABTest] = []
    private var assignments: [String: ABTestAssignment] = [:]
    private let storage = UserDefaults.standard
    private let analytics: AnalyticsProtocol
    
    private init(analytics: AnalyticsProtocol = Analytics.shared) {
        self.analytics = analytics
        loadAssignments()
        configureTests()
    }
    
    func variant(for testId: String) -> ABTestVariant {
        if let assignment = assignments[testId] {
            return assignment.variant
        }
        
        guard let test = activeTests.first(where: { $0.id == testId }) else {
            return .control
        }
        
        let variant = assignVariant(for: test)
        saveAssignment(testId: testId, variant: variant)
        
        return variant
    }
    
    func track(event: String, properties: [String: Any] = [:]) {
        var enrichedProperties = properties
        
        // Add all active test assignments
        for (testId, assignment) in assignments {
            enrichedProperties["ab_\(testId)"] = assignment.variant.rawValue
        }
        
        analytics.track(event, properties: enrichedProperties)
    }
    
    func completeTest(_ testId: String, success: Bool) {
        guard let assignment = assignments[testId] else { return }
        
        analytics.track("ab_test_completed", properties: [
            "test_id": testId,
            "variant": assignment.variant.rawValue,
            "success": success,
            "duration": Date().timeIntervalSince(assignment.assignedAt)
        ])
    }
    
    private func configureTests() {
        activeTests = [
            ABTest(
                id: "onboarding_flow",
                name: "Conversational vs Traditional Onboarding",
                variants: [
                    .control: ABTestVariantConfig(
                        name: "Traditional Form",
                        percentage: 50
                    ),
                    .treatment: ABTestVariantConfig(
                        name: "Conversational Flow",
                        percentage: 50
                    )
                ],
                metrics: [
                    "completion_rate",
                    "time_to_complete",
                    "user_satisfaction",
                    "d7_retention"
                ]
            ),
            ABTest(
                id: "persona_preview",
                name: "Persona Preview Timing",
                variants: [
                    .control: ABTestVariantConfig(
                        name: "Preview After All Questions",
                        percentage: 33
                    ),
                    .treatment: ABTestVariantConfig(
                        name: "Progressive Preview",
                        percentage: 33
                    ),
                    .treatment2: ABTestVariantConfig(
                        name: "Real-time Preview",
                        percentage: 34
                    )
                ],
                metrics: [
                    "preview_engagement",
                    "adjustment_rate",
                    "satisfaction_score"
                ]
            )
        ]
    }
    
    private func assignVariant(for test: ABTest) -> ABTestVariant {
        let random = Double.random(in: 0...100)
        var cumulative: Double = 0
        
        for (variant, config) in test.variants {
            cumulative += config.percentage
            if random <= cumulative {
                return variant
            }
        }
        
        return .control
    }
}

// ABTestModels.swift
struct ABTest {
    let id: String
    let name: String
    let variants: [ABTestVariant: ABTestVariantConfig]
    let metrics: [String]
    let startDate: Date
    let endDate: Date?
    
    init(
        id: String,
        name: String,
        variants: [ABTestVariant: ABTestVariantConfig],
        metrics: [String],
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.variants = variants
        self.metrics = metrics
        self.startDate = startDate
        self.endDate = endDate
    }
}

enum ABTestVariant: String, CaseIterable {
    case control
    case treatment
    case treatment2
}

struct ABTestVariantConfig {
    let name: String
    let percentage: Double
    let configuration: [String: Any]
    
    init(name: String, percentage: Double, configuration: [String: Any] = [:]) {
        self.name = name
        self.percentage = percentage
        self.configuration = configuration
    }
}

struct ABTestAssignment: Codable {
    let testId: String
    let variant: ABTestVariant
    let assignedAt: Date
}
```

#### Task 3.3.12: Create Onboarding A/B Tests
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/OnboardingABTests.swift

# Acceptance Criteria:
- Define onboarding test variants
- Implement variant-specific flows
- Track key metrics
- Statistical significance

# Test Command:
swift test --filter OnboardingABTestsTests
```

#### Task 3.3.13: Implement Metrics Collection
```bash
# Files to create:
- AirFit/Services/ABTesting/ABTestMetrics.swift

# Acceptance Criteria:
- Automatic metric collection
- Real-time dashboards
- Statistical analysis
- Export capabilities

# Test Command:
swift test --filter ABTestMetricsTests
```

#### Task 3.3.14: Create Test Result Analysis
```bash
# Files to create:
- AirFit/Services/ABTesting/ABTestAnalysis.swift

# Acceptance Criteria:
- Calculate significance
- Generate reports
- Make recommendations
- Auto-graduation logic

# Test Command:
swift test --filter ABTestAnalysisTests
```

#### Task 3.3.15: Add Feature Flag Integration
```bash
# Files to create:
- AirFit/Services/ABTesting/FeatureFlagBridge.swift

# Acceptance Criteria:
- Connect to feature flags
- Override capabilities
- Emergency shutoff
- Gradual rollout

# Test Command:
swift test --filter FeatureFlagBridgeTests
```

### Checkpoint 3.3
```bash
# Test A/B framework
swift test --filter ABTestingTests

# Verify metrics collection
swift test --filter MetricsIntegrationTests

# Commit
git commit -m "feat(ab-testing): implement A/B testing framework

- Create flexible A/B test manager
- Add onboarding flow tests
- Implement metrics collection
- Add statistical analysis
- Integrate with feature flags

Part of persona refactor Phase 3"
```

### Batch 3.4: Performance & Polish (Tasks 16-20)
**Estimated Time**: 6 hours
**Context Requirements**: Complete integration, profiling tools

#### Task 3.4.16: Optimize Persona Generation Performance
```bash
# Files to modify:
- AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift
- AirFit/Services/AI/LLMOrchestrator.swift

# Acceptance Criteria:
- < 5 second total generation time
- Parallel API calls where possible
- Response caching
- Progress indicators

# Test Command:
swift test --filter PersonaSynthesisPerformanceTests
```

#### Task 3.4.17: Implement Response Caching
```bash
# Files to create:
- AirFit/Services/Cache/PersonaCache.swift
- AirFit/Services/Cache/ConversationCache.swift

# Acceptance Criteria:
- Cache synthesized personas
- Cache partial results
- Invalidation logic
- Memory management

# Test Command:
swift test --filter CachingTests
```

#### Task 3.4.18: Add Production Monitoring
```bash
# Files to create:
- AirFit/Services/Monitoring/OnboardingMonitor.swift
- AirFit/Services/Monitoring/PerformanceTracker.swift

# Acceptance Criteria:
- Track key performance indicators
- Alert on anomalies
- User experience metrics
- API health monitoring

# Test Command:
swift test --filter MonitoringTests
```

#### Task 3.4.19: Create Stress Testing Suite
```bash
# Files to create:
- AirFitTests/Performance/OnboardingStressTests.swift
- AirFitTests/Performance/PersonaSynthesisStressTests.swift

# Acceptance Criteria:
- Test with 1000+ concurrent users
- API failure scenarios
- Network interruptions
- Memory pressure

# Test Command:
swift test --filter StressTests
```

#### Task 3.4.20: Final Integration Polish
```bash
# Files to modify:
- Various UI files for animations and transitions
- Error messages and recovery flows

# Acceptance Criteria:
- Smooth animations
- Helpful error messages
- Loading states
- Accessibility audit

# Test Command:
xcodebuild test -scheme "AirFit" -only-testing:AirFitUITests
```

### Checkpoint 3.4
```bash
# Performance profiling
instruments -t "Time Profiler" build/AirFit.app

# Full integration test suite
xcodebuild test -scheme "AirFit"

# Commit
git commit -m "feat(performance): optimize and polish integration

- Optimize persona generation to <5s
- Implement intelligent caching
- Add production monitoring
- Create stress testing suite
- Polish UI and error handling

Part of persona refactor Phase 3"
```

## 🧪 Validation Criteria

### Integration Test Coverage
- End-to-end flows: > 90%
- Error scenarios: > 85%
- Performance tests: > 80%
- Migration paths: 100%

### Performance Benchmarks
- [ ] Onboarding completion: < 10 minutes
- [ ] Persona generation: < 5 seconds
- [ ] UI responsiveness: 60 FPS
- [ ] Memory usage: < 150MB
- [ ] API error rate: < 0.1%

### A/B Test Metrics
- [ ] Test assignment accuracy: 100%
- [ ] Metric collection rate: > 99%
- [ ] Statistical power: > 80%
- [ ] No performance impact

## 🎮 Cursor Workflow

### For Each Batch
1. **Load context**:
   ```
   Open Phase3_IntegrationTesting_ENHANCED.md
   @codebase Show Phase 1 and 2 implementations
   ```

2. **Generate implementations**:
   ```
   Implement Task 3.1.1 according to specification
   Include comprehensive error handling
   Add performance tracking
   ```

3. **Test immediately**:
   ```
   Run integration tests for this component
   Check performance benchmarks
   ```

4. **Polish and optimize**:
   ```
   Profile with Instruments
   Optimize any bottlenecks
   Add telemetry
   ```

## 📊 Progress Tracking

```markdown
## Phase 3 Progress
- [x] Planning & Documentation
- [ ] Batch 3.1: Core Integration (0/5)
- [ ] Batch 3.2: Migration System (0/5)
- [ ] Batch 3.3: A/B Testing (0/5)
- [ ] Batch 3.4: Performance & Polish (0/5)
- [ ] Full System Testing
- [ ] Production Readiness Review
- [ ] Documentation Update
```

## 🚦 Success Criteria

1. **Integration**: Seamless flow from conversation to persona
2. **Migration**: 100% of users can transition smoothly
3. **Performance**: All operations within benchmarks
4. **Testing**: > 90% code coverage, all scenarios tested
5. **Production**: Monitoring, rollback, and recovery ready

## 💡 Implementation Tips

### Integration Testing
```swift
// Use XCTestExpectation for async flows
func testFullOnboardingFlow() async throws {
    let orchestrator = OnboardingOrchestrator(/* dependencies */)
    
    let completionExpectation = expectation(description: "Onboarding completes")
    
    // Start flow
    try await orchestrator.startOnboarding()
    
    // Simulate user responses
    for response in mockResponses {
        try await orchestrator.submitResponse(response)
    }
    
    // Wait for completion
    await fulfillment(of: [completionExpectation], timeout: 30)
    
    // Verify persona generated
    XCTAssertNotNil(orchestrator.generatedPersona)
}
```

### Performance Profiling
```bash
# Profile specific test
xcodebuild test -scheme "AirFit" \
  -only-testing:AirFitTests/Performance \
  -enableCodeCoverage YES \
  -enableAddressSanitizer YES
```

### Migration Safety
1. Always backup before migration
2. Test with production-like data
3. Have rollback ready
4. Monitor closely after release
5. Gradual rollout recommended

---

*"Integration is where theory meets reality. Test everything, assume nothing."*
# Phase 1: Conversational Foundation - Enhanced Implementation Guide

## 🎯 Phase Overview
Build the conversational interview engine that powers AI-native onboarding. This enhanced guide is optimized for context-limited, AI-driven implementation.

## 🚀 Implementation Strategy
- **Approach**: Vertical slices with immediate validation
- **Context Limit**: 10-15 subtasks per session
- **Validation**: Test after every 5 subtasks
- **Commits**: Atomic commits with clear messages

## 📦 Deliverables Checklist
- [ ] ConversationNode data model
- [ ] ConversationFlowManager 
- [ ] Input modality views (text, voice, slider, cards)
- [ ] Response analysis system
- [ ] Conversation state persistence
- [ ] Basic UI flow with navigation
- [ ] Unit tests (>80% coverage)
- [ ] Integration tests for full flow

## 🏗️ Implementation Batches

### Batch 1.1: Core Data Models (Tasks 1-5)
**Estimated Time**: 4 hours
**Context Requirements**: SwiftData models, existing User model

#### Task 1.1.1: Create Conversation Models
```bash
# Files to create:
- AirFit/Modules/Onboarding/Models/ConversationModels.swift
- AirFit/Modules/Onboarding/Models/PersonalityInsights.swift

# Acceptance Criteria:
- All models compile with Swift 6
- Models are Codable and Sendable
- Comprehensive enum cases for all dimensions

# Test Command:
swift build --target AirFit
```

**Implementation**:
```swift
// ConversationModels.swift
import Foundation
import SwiftData

// MARK: - Core Models
struct ConversationNode: Codable, Sendable, Identifiable {
    let id: UUID
    let nodeType: NodeType
    let question: ConversationQuestion
    let inputType: InputType
    let branchingRules: [BranchingRule]
    let dataKey: String // Key in user profile JSON
    let validationRules: ValidationRules
    let analyticsEvent: String?
    
    enum NodeType: String, Codable {
        case opening
        case goals
        case lifestyle
        case personality
        case preferences
        case confirmation
    }
}

struct ConversationQuestion: Codable, Sendable {
    let primary: String
    let clarifications: [String]
    let examples: [String]?
    let voicePrompt: String?
}

enum InputType: Codable, Sendable {
    case text(minLength: Int, maxLength: Int, placeholder: String)
    case voice(maxDuration: TimeInterval)
    case singleChoice(options: [ChoiceOption])
    case multiChoice(options: [ChoiceOption], minSelections: Int, maxSelections: Int)
    case slider(min: Double, max: Double, step: Double, labels: SliderLabels)
    case hybrid(primary: InputType, secondary: InputType)
}

struct ChoiceOption: Codable, Sendable, Identifiable {
    let id: String
    let text: String
    let emoji: String?
    let traits: [String: Double] // Trait implications
}

// MARK: - Personality Insights
struct PersonalityInsights: Codable, Sendable {
    var traits: [PersonalityDimension: Double]
    var communicationStyle: CommunicationProfile
    var motivationalDrivers: Set<MotivationalDriver>
    var stressResponses: [StressTrigger: CopingStyle]
    var confidenceScores: [PersonalityDimension: Double]
    var lastUpdated: Date
}

enum PersonalityDimension: String, Codable, CaseIterable {
    case authorityPreference
    case socialOrientation  
    case structureNeed
    case intensityPreference
    case dataOrientation
    case emotionalSupport
}

// MARK: - Conversation State
@Model
final class ConversationSession {
    var id: UUID
    var userId: UUID
    var startedAt: Date
    var completedAt: Date?
    var currentNodeId: String
    var responses: [ConversationResponse]
    var extractedInsights: Data? // PersonalityInsights as JSON
    var completionPercentage: Double
    
    init() {
        self.id = UUID()
        self.userId = UUID() // Will be set properly
        self.startedAt = Date()
        self.currentNodeId = "opening"
        self.responses = []
        self.completionPercentage = 0
    }
}

@Model
final class ConversationResponse {
    var nodeId: String
    var responseType: String
    var responseData: Data // JSON encoded response
    var timestamp: Date
    var processingTime: TimeInterval
    
    init(nodeId: String, responseType: String, responseData: Data) {
        self.nodeId = nodeId
        self.responseType = responseType
        self.responseData = responseData
        self.timestamp = Date()
        self.processingTime = 0
    }
}
```

#### Task 1.1.2: Create Conversation Flow Manager
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/ConversationFlowManager.swift

# Acceptance Criteria:
- Manages conversation state and navigation
- Supports branching logic
- Handles response validation
- Thread-safe with @MainActor

# Test Command:
swift test --filter ConversationFlowManagerTests
```

#### Task 1.1.3: Create Response Analyzer Protocol
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/ResponseAnalyzer.swift
- AirFit/Modules/Onboarding/Services/ResponseAnalyzerImpl.swift

# Acceptance Criteria:
- Extracts personality traits from responses
- Calculates confidence scores
- Updates PersonalityInsights incrementally
- Async/await API for AI integration

# Test Command:
swift test --filter ResponseAnalyzerTests
```

#### Task 1.1.4: Create Conversation State Persistence
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/ConversationPersistence.swift

# Acceptance Criteria:
- Save/restore conversation progress
- Handle interruptions gracefully
- SwiftData integration
- Automatic cleanup of old sessions

# Test Command:
swift test --filter ConversationPersistenceTests
```

#### Task 1.1.5: Create Analytics Tracker
```bash
# Files to create:
- AirFit/Modules/Onboarding/Services/ConversationAnalytics.swift

# Acceptance Criteria:
- Track node completion times
- Monitor drop-off points
- Measure response quality
- Privacy-compliant implementation

# Test Command:
swift test --filter ConversationAnalyticsTests
```

### Checkpoint 1.1
```bash
# Run all tests
swift test

# Check SwiftLint
swiftlint --strict --path AirFit/Modules/Onboarding

# Commit
git add -A
git commit -m "feat(onboarding): implement conversation foundation models and services

- Add ConversationNode and PersonalityInsights models
- Implement ConversationFlowManager for state management  
- Create ResponseAnalyzer for trait extraction
- Add conversation persistence with SwiftData
- Implement analytics tracking

Part of persona refactor Phase 1"
```

### Batch 1.2: UI Components (Tasks 6-10)
**Estimated Time**: 4 hours
**Context Requirements**: Existing UI patterns, theme system

#### Task 1.2.6: Create Conversational Input View
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/ConversationalInputView.swift
- AirFit/Modules/Onboarding/Views/InputModalities/

# Acceptance Criteria:
- Smooth transitions between input types
- Accessibility support
- Haptic feedback
- Theme integration
```

#### Task 1.2.7: Create Text Input Component
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/InputModalities/TextInputView.swift
- AirFit/Modules/Onboarding/Views/InputModalities/SmartSuggestions.swift
```

#### Task 1.2.8: Create Voice Input Component
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/InputModalities/VoiceInputView.swift
- AirFit/Modules/Onboarding/Views/InputModalities/VoiceVisualizer.swift
```

#### Task 1.2.9: Create Choice Input Components
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/InputModalities/ChoiceCardsView.swift
- AirFit/Modules/Onboarding/Views/InputModalities/ContextualSlider.swift
```

#### Task 1.2.10: Create Progress Indicator
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/ConversationProgress.swift
```

### Checkpoint 1.2
```bash
# Run UI tests
xcodebuild test -scheme "AirFit" -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Generate preview screenshots
# (Manual step in Xcode)

# Commit
git commit -m "feat(onboarding): implement conversational UI components"
```

### Batch 1.3: Flow Implementation (Tasks 11-15)
**Estimated Time**: 6 hours
**Context Requirements**: AI service protocols, navigation patterns

#### Task 1.3.11: Create Conversation Coordinator
```bash
# Files to create:
- AirFit/Modules/Onboarding/ConversationCoordinator.swift
```

#### Task 1.3.12: Create Conversation View Model
```bash
# Files to create:
- AirFit/Modules/Onboarding/ViewModels/ConversationViewModel.swift
```

#### Task 1.3.13: Create Main Conversation View
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/ConversationView.swift
```

#### Task 1.3.14: Implement Basic Question Flow
```bash
# Files to create:
- AirFit/Modules/Onboarding/Data/ConversationFlowData.swift
```

#### Task 1.3.15: Connect to AI Service
```bash
# Files to modify:
- AirFit/Modules/Onboarding/Services/ResponseAnalyzerImpl.swift
```

### Checkpoint 1.3
```bash
# Full integration test
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/Onboarding

# Manual flow test
# Launch app and complete onboarding flow

# Commit
git commit -m "feat(onboarding): complete conversational flow implementation"
```

## 🧪 Validation Criteria

### Unit Test Coverage
- Models: 100%
- ViewModels: > 90%
- Services: > 85%
- Views: > 70%

### Integration Tests
- [ ] Complete conversation flow (happy path)
- [ ] Interruption and resume
- [ ] Branching logic
- [ ] Error handling
- [ ] Performance (< 100ms response time)

### Manual Testing Checklist
- [ ] All input types work correctly
- [ ] Smooth animations and transitions
- [ ] VoiceOver accessibility
- [ ] Dynamic Type support
- [ ] Dark mode support
- [ ] iPad layout

## 🎮 Cursor Workflow

1. **Start each batch**:
   - Open this document
   - Use Cmd+K to reference the task
   - Generate complete implementation
   - Run tests immediately

2. **For multi-file changes**:
   - Use Cursor Composer (Cmd+K)
   - Reference @codebase for patterns
   - Generate all related files together

3. **Testing**:
   - Use integrated terminal
   - Run tests after each task
   - Fix issues before moving on

4. **Context management**:
   - Complete one batch at a time
   - Clear context between batches
   - Reference this document for continuity

## 📊 Progress Tracking

```markdown
## Phase 1 Progress
- [x] Planning & Documentation
- [ ] Batch 1.1: Core Data Models (0/5)
- [ ] Batch 1.2: UI Components (0/5)  
- [ ] Batch 1.3: Flow Implementation (0/5)
- [ ] Integration Testing
- [ ] Performance Optimization
- [ ] Documentation Update
```

## 🚦 Success Criteria

1. **Functionality**: Users can complete conversational onboarding
2. **Performance**: All interactions < 100ms response time
3. **Quality**: > 85% test coverage, zero SwiftLint violations
4. **UX**: Smooth, natural conversation flow
5. **Architecture**: Clean, maintainable, extensible code

---

*Remember: Each task should be atomic, testable, and add visible value. No abstractions without implementations.*
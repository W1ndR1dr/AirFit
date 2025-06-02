# Phase 2: AI-Driven Persona Synthesis - Enhanced Implementation Guide

## 🎯 Phase Overview
Build the AI synthesis engine that transforms conversational data into rich, unique coach personas. This phase focuses on LLM integration, prompt engineering, and real-time preview generation.

## 🚀 Implementation Strategy
- **Approach**: Provider abstraction first, then synthesis
- **Context Limit**: 10-15 subtasks per session
- **Validation**: Integration tests with real APIs
- **Commits**: Feature-based commits

## 📦 Deliverables Checklist
- [ ] LLM provider abstraction (Anthropic, OpenAI, Google)
- [ ] Personality extraction pipeline
- [ ] Persona synthesis engine
- [ ] System prompt generator (2000+ tokens)
- [ ] Real-time preview system
- [ ] User adjustment interface
- [ ] Provider fallback logic
- [ ] Cost optimization system

## 🏗️ Implementation Batches

### Batch 2.1: LLM Provider Foundation (Tasks 1-5)
**Estimated Time**: 6 hours
**Context Requirements**: Existing AIService protocols, API key management

#### Task 2.1.1: Create LLM Provider Protocol
```bash
# Files to create:
- AirFit/Services/AI/LLMProviders/LLMProvider.swift
- AirFit/Services/AI/LLMProviders/LLMModels.swift

# Acceptance Criteria:
- Protocol supports streaming and batch completion
- Comprehensive error types
- Usage tracking included
- Thread-safe with actor isolation

# Test Command:
swift build --target AirFit
```

**Implementation**:
```swift
// LLMProvider.swift
import Foundation

// MARK: - Core Protocol
protocol LLMProvider: Actor {
    var identifier: LLMProviderIdentifier { get }
    var capabilities: LLMCapabilities { get }
    var costPerKToken: (input: Double, output: Double) { get }
    
    func complete(_ request: LLMRequest) async throws -> LLMResponse
    func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error>
    func validateAPIKey(_ key: String) async throws -> Bool
}

// MARK: - Models
struct LLMProviderIdentifier: Hashable {
    let name: String
    let version: String
}

struct LLMCapabilities {
    let maxContextTokens: Int
    let supportsJSON: Bool
    let supportsStreaming: Bool
    let supportsSystemPrompt: Bool
    let supportsFunctionCalling: Bool
    let supportsVision: Bool
}

struct LLMRequest {
    let messages: [LLMMessage]
    let model: String
    let temperature: Double
    let maxTokens: Int?
    let systemPrompt: String?
    let responseFormat: ResponseFormat?
    let stream: Bool
    let metadata: [String: Any]
    
    enum ResponseFormat {
        case text
        case json(schema: String)
    }
}

struct LLMMessage {
    let role: Role
    let content: String
    let name: String?
    
    enum Role: String {
        case system
        case user
        case assistant
    }
}

struct LLMResponse {
    let content: String
    let model: String
    let usage: TokenUsage
    let finishReason: FinishReason
    let metadata: [String: Any]
    
    struct TokenUsage {
        let promptTokens: Int
        let completionTokens: Int
        var totalTokens: Int { promptTokens + completionTokens }
    }
    
    enum FinishReason: String {
        case stop
        case length
        case contentFilter = "content_filter"
        case toolCalls = "tool_calls"
    }
}

struct LLMStreamChunk {
    let delta: String
    let isFinished: Bool
    let usage: LLMResponse.TokenUsage?
}

// MARK: - Errors
enum LLMError: LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case contextLengthExceeded(max: Int, requested: Int)
    case invalidResponse(String)
    case networkError(Error)
    case serverError(statusCode: Int, message: String?)
    case timeout
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .rateLimitExceeded(let retryAfter):
            if let retry = retryAfter {
                return "Rate limit exceeded. Retry after \(Int(retry)) seconds"
            }
            return "Rate limit exceeded"
        case .contextLengthExceeded(let max, let requested):
            return "Context length exceeded: \(requested) tokens (max: \(max))"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown")"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request cancelled"
        }
    }
}
```

#### Task 2.1.2: Implement Anthropic Provider
```bash
# Files to create:
- AirFit/Services/AI/LLMProviders/AnthropicProvider.swift
- AirFit/Services/AI/LLMProviders/AnthropicModels.swift

# Acceptance Criteria:
- Full Claude API implementation
- Streaming support
- Proper error handling
- Token counting
- Request/response logging

# Test Command:
swift test --filter AnthropicProviderTests
```

#### Task 2.1.3: Implement OpenAI Provider
```bash
# Files to create:
- AirFit/Services/AI/LLMProviders/OpenAIProvider.swift
- AirFit/Services/AI/LLMProviders/OpenAIModels.swift

# Acceptance Criteria:
- GPT-4 and GPT-3.5 support
- Function calling support
- Streaming implementation
- Cost tracking

# Test Command:
swift test --filter OpenAIProviderTests
```

#### Task 2.1.4: Implement Google Gemini Provider
```bash
# Files to create:
- AirFit/Services/AI/LLMProviders/GeminiProvider.swift
- AirFit/Services/AI/LLMProviders/GeminiModels.swift

# Acceptance Criteria:
- Gemini Pro API support
- Safety settings configuration
- Multi-modal ready (future)

# Test Command:
swift test --filter GeminiProviderTests
```

#### Task 2.1.5: Create Provider Orchestrator
```bash
# Files to create:
- AirFit/Services/AI/LLMOrchestrator.swift
- AirFit/Services/AI/ProviderSelectionStrategy.swift

# Acceptance Criteria:
- Intelligent provider selection
- Fallback chain implementation
- Cost optimization logic
- Health monitoring

# Test Command:
swift test --filter LLMOrchestratorTests
```

### Checkpoint 2.1
```bash
# Integration test with real APIs
swift test --filter LLMProviderIntegrationTests

# Check API key management
swift test --filter APIKeyValidationTests

# Commit
git add -A
git commit -m "feat(ai): implement multi-provider LLM abstraction

- Add LLMProvider protocol with streaming support
- Implement Anthropic Claude provider
- Implement OpenAI GPT provider
- Implement Google Gemini provider
- Add intelligent orchestration and fallback

Part of persona refactor Phase 2"
```

### Batch 2.2: Personality Extraction (Tasks 6-10)
**Estimated Time**: 8 hours
**Context Requirements**: LLM providers, conversation models from Phase 1

#### Task 2.2.6: Create Personality Extractor
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/PersonalityExtractor.swift
- AirFit/Modules/AI/PersonaSynthesis/PersonalityModels.swift

# Acceptance Criteria:
- Extract traits from conversation responses
- Confidence scoring for each trait
- Evidence collection from responses
- Multi-dimensional personality model
```

**Implementation**:
```swift
// PersonalityExtractor.swift
import Foundation

actor PersonalityExtractor {
    private let llm: LLMOrchestrator
    
    init(llm: LLMOrchestrator) {
        self.llm = llm
    }
    
    func extractPersonality(
        from exchanges: [ConversationExchange],
        metadata: ConversationMetadata
    ) async throws -> PersonalityProfile {
        
        // Extract different aspects in parallel
        async let traits = extractTraits(from: exchanges)
        async let communication = extractCommunicationStyle(from: exchanges)
        async let motivators = extractMotivators(from: exchanges)
        async let stressResponse = extractStressResponse(from: exchanges)
        
        let profile = PersonalityProfile(
            traits: try await traits,
            communicationStyle: try await communication,
            motivationalDrivers: try await motivators,
            stressResponse: try await stressResponse,
            metadata: metadata
        )
        
        // Validate coherence
        try validateProfile(profile)
        
        return profile
    }
    
    private func extractTraits(from exchanges: [ConversationExchange]) async throws -> PersonalityTraits {
        let prompt = """
        Analyze these conversation responses to extract personality traits for fitness coaching:
        
        CONVERSATION DATA:
        \(formatExchanges(exchanges))
        
        ANALYSIS INSTRUCTIONS:
        Extract personality scores (-1.0 to +1.0) for these dimensions:
        
        1. Authority Response
           -1.0 = Highly rebellious, dislikes being told what to do
           +1.0 = Highly compliant, prefers clear direction
           
        2. Motivation Style  
           -1.0 = Purely internal motivation, dislikes external validation
           +1.0 = Thrives on external validation and recognition
           
        3. Structure Need
           -1.0 = Prefers complete flexibility and spontaneity
           +1.0 = Needs rigid structure and detailed plans
           
        4. Emotional Support
           -1.0 = Prefers tough love and direct feedback
           +1.0 = Needs encouragement and emotional validation
           
        5. Data Orientation
           -1.0 = Intuitive, dislikes numbers and tracking
           +1.0 = Data-driven, loves metrics and analysis
           
        6. Social Orientation
           -1.0 = Highly independent, prefers solo activities
           +1.0 = Highly social, thrives in group settings
           
        7. Risk Tolerance
           -1.0 = Very cautious, safety-focused
           +1.0 = Adventurous, loves trying new things
           
        8. Energy Consistency
           -1.0 = Highly variable energy, mood-dependent
           +1.0 = Consistent energy and motivation
        
        For each dimension provide:
        - score: The numerical score
        - confidence: How confident you are (0.0-1.0)
        - evidence: Specific quotes or behaviors supporting this score
        - implications: How this affects coaching approach
        
        Output as JSON matching PersonalityTraits schema.
        """
        
        let response = try await llm.complete(
            prompt: prompt,
            task: .personalityExtraction,
            model: .claude3Sonnet // Good balance of quality/speed
        )
        
        return try JSONDecoder().decode(PersonalityTraits.self, from: response.data)
    }
}

// PersonalityModels.swift
struct PersonalityProfile: Codable {
    let id: UUID
    let traits: PersonalityTraits
    let communicationStyle: CommunicationProfile
    let motivationalDrivers: Set<MotivationalDriver>
    let stressResponse: StressResponseProfile
    let confidence: Double
    let extractedAt: Date
    
    var dominantTraits: [PersonalityDimension] {
        traits.dimensions
            .sorted { abs($0.value.score) > abs($1.value.score) }
            .prefix(3)
            .map { $0.key }
    }
}

struct PersonalityTraits: Codable {
    let dimensions: [PersonalityDimension: DimensionScore]
    let overallNarrative: String
    let coachingImplications: [String]
}

enum PersonalityDimension: String, Codable, CaseIterable {
    case authorityResponse
    case motivationStyle
    case structureNeed
    case emotionalSupport
    case dataOrientation
    case socialOrientation
    case riskTolerance
    case energyConsistency
}

struct DimensionScore: Codable {
    let score: Double // -1.0 to 1.0
    let confidence: Double // 0.0 to 1.0
    let evidence: [String]
    let implications: String
}
```

#### Task 2.2.7: Create Communication Style Analyzer
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/CommunicationAnalyzer.swift

# Acceptance Criteria:
- Analyze tone preferences
- Detect formality level
- Identify humor tolerance
- Extract language patterns
```

#### Task 2.2.8: Create Motivational Driver Detector
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/MotivationAnalyzer.swift

# Acceptance Criteria:
- Identify primary motivators
- Detect celebration preferences
- Analyze goal orientation
- Find accountability needs
```

#### Task 2.2.9: Create Scenario Response Analyzer
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/ScenarioAnalyzer.swift

# Acceptance Criteria:
- Process scenario choices
- Extract behavioral patterns
- Build preference profile
```

#### Task 2.2.10: Create Profile Validator
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/ProfileValidator.swift

# Acceptance Criteria:
- Check profile coherence
- Identify contradictions
- Ensure completeness
- Calculate confidence scores
```

### Checkpoint 2.2
```bash
# Test personality extraction
swift test --filter PersonalityExtractionTests

# Run with sample data
swift test --filter PersonalityExtractorIntegrationTests

# Commit
git commit -m "feat(ai): implement personality extraction pipeline"
```

### Batch 2.3: Persona Synthesis (Tasks 11-15)
**Estimated Time**: 8 hours
**Context Requirements**: Personality models, LLM orchestrator

#### Task 2.3.11: Create Persona Synthesizer
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/PersonaSynthesizer.swift
- AirFit/Modules/AI/PersonaSynthesis/CoachPersona.swift

# Acceptance Criteria:
- Generate unique coach from personality data
- 2000+ token rich personas
- Coherent personality with quirks
- Memorable and authentic
```

**Implementation**:
```swift
// PersonaSynthesizer.swift
actor PersonaSynthesizer {
    private let llm: LLMOrchestrator
    
    func synthesizeCoach(
        from profile: PersonalityProfile,
        goals: UserGoals,
        context: LifeContext
    ) async throws -> CoachPersona {
        
        // Multi-stage synthesis
        let identity = try await generateIdentity(profile: profile)
        let communication = try await generateCommunicationStyle(
            profile: profile,
            identity: identity
        )
        let philosophy = try await generatePhilosophy(
            profile: profile,
            goals: goals,
            identity: identity
        )
        let behaviors = try await generateBehaviors(
            profile: profile,
            context: context,
            identity: identity
        )
        let quirks = try await generateQuirks(
            identity: identity,
            communication: communication
        )
        
        return CoachPersona(
            id: UUID(),
            identity: identity,
            communication: communication,
            philosophy: philosophy,
            behaviors: behaviors,
            quirks: quirks,
            profile: profile,
            generatedAt: Date()
        )
    }
    
    private func generateIdentity(profile: PersonalityProfile) async throws -> CoachIdentity {
        let prompt = buildIdentityPrompt(profile: profile)
        
        let response = try await llm.complete(
            prompt: prompt,
            task: .personaSynthesis,
            model: .claude3Opus // Highest quality for identity
        )
        
        return try parseIdentity(from: response.content)
    }
    
    private func buildIdentityPrompt(profile: PersonalityProfile) -> String {
        """
        Create a unique fitness coach identity based on this personality profile:
        
        PERSONALITY TRAITS:
        \(formatTraits(profile.traits))
        
        COMMUNICATION PREFERENCE: \(profile.communicationStyle.summary)
        MOTIVATIONAL DRIVERS: \(profile.motivationalDrivers.map { $0.rawValue }.joined(separator: ", "))
        
        Generate a coach with:
        
        1. NAME & BACKGROUND (100-150 words)
        - A memorable, appropriate name
        - Brief professional background that explains their coaching style
        - Personal fitness journey that shapes their approach
        - What makes them uniquely qualified
        
        2. CORE PERSONALITY (150-200 words)
        - 3-4 defining personality traits with specific examples
        - How these traits manifest in coaching
        - What makes them different from generic coaches
        - Their coaching superpower
        
        3. PERSONAL MISSION (50-75 words)
        - What drives them as a coach
        - Their vision for client success
        - Their non-negotiable coaching principles
        
        Make them feel like a real person with depth, flaws, and authenticity.
        Avoid clichés and generic fitness coach tropes.
        """
    }
}

// CoachPersona.swift
struct CoachPersona: Codable, Identifiable {
    let id: UUID
    let identity: CoachIdentity
    let communication: CommunicationStyle
    let philosophy: CoachingPhilosophy
    let behaviors: BehavioralPatterns
    let quirks: PersonalityQuirks
    let profile: PersonalityProfile
    let generatedAt: Date
    
    var uniquenessScore: Double {
        // Calculate based on trait combinations
        // and distance from common patterns
        calculateUniqueness()
    }
}

struct CoachIdentity: Codable {
    let name: String
    let background: String
    let coreTraits: [CoreTrait]
    let mission: String
    let superpower: String
    
    struct CoreTrait: Codable {
        let name: String
        let description: String
        let example: String
    }
}
```

#### Task 2.3.12: Create Communication Style Generator
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/CommunicationGenerator.swift

# Acceptance Criteria:
- Generate unique speaking patterns
- Create catchphrases
- Define feedback style
- Set energy and tone
```

#### Task 2.3.13: Create Philosophy Generator
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/PhilosophyGenerator.swift

# Acceptance Criteria:
- Generate coaching philosophy
- Create motivational approach
- Define success metrics
- Build trust-building style
```

#### Task 2.3.14: Create Behavior Pattern Generator
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/BehaviorGenerator.swift

# Acceptance Criteria:
- Morning check-in style
- Workout introduction patterns
- Progress celebration methods
- Setback handling approach
```

#### Task 2.3.15: Create System Prompt Builder
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/SystemPromptBuilder.swift

# Acceptance Criteria:
- Convert persona to system prompt
- Optimize for 2000-2500 tokens
- Preserve personality richness
- Include adaptation rules
```

### Checkpoint 2.3
```bash
# Test full synthesis pipeline
swift test --filter PersonaSynthesisTests

# Generate sample personas
swift test --filter PersonaSynthesisSampleTests

# Commit
git commit -m "feat(ai): implement coach persona synthesis engine"
```

### Batch 2.4: Preview & Adjustments (Tasks 16-20)
**Estimated Time**: 6 hours
**Context Requirements**: Synthesis engine, UI components

#### Task 2.4.16: Create Preview Generator
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/PreviewGenerator.swift
- AirFit/Modules/Onboarding/Views/CoachPreviewView.swift

# Acceptance Criteria:
- Real-time preview during synthesis
- Stage-based messaging
- Smooth UI updates
- Loading states
```

#### Task 2.4.17: Create Preview UI Components
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/PersonaSynthesisView.swift
- AirFit/Modules/Onboarding/Views/PersonaPreviewCard.swift

# Acceptance Criteria:
- Animated synthesis visualization
- Trait display
- Message preview
- Progress indication
```

#### Task 2.4.18: Create Adjustment Interface
```bash
# Files to create:
- AirFit/Modules/Onboarding/Views/PersonaAdjustmentView.swift
- AirFit/Modules/AI/PersonaSynthesis/PersonaAdjuster.swift

# Acceptance Criteria:
- Quick adjustment chips
- Natural language input
- Preview updates
- Validation logic
```

#### Task 2.4.19: Create Adjustment Engine
```bash
# Files to create:
- AirFit/Modules/AI/PersonaSynthesis/AdjustmentEngine.swift

# Acceptance Criteria:
- Process natural language adjustments
- Maintain persona coherence
- Apply targeted changes
- Preserve core identity
```

#### Task 2.4.20: Integration & Polish
```bash
# Files to modify:
- AirFit/Modules/Onboarding/ViewModels/OnboardingViewModel.swift
- AirFit/Modules/Onboarding/ConversationCoordinator.swift

# Acceptance Criteria:
- Connect synthesis to conversation flow
- Save generated persona
- Handle errors gracefully
- Complete onboarding transition
```

### Checkpoint 2.4
```bash
# Full integration test
xcodebuild test -scheme "AirFit" -only-testing:AirFitTests/PersonaSynthesis

# UI test for preview flow
xcodebuild test -scheme "AirFit" -only-testing:AirFitUITests/PersonaSynthesisFlow

# Commit
git commit -m "feat(ai): complete persona preview and adjustment system"
```

## 🧪 Validation Criteria

### Unit Test Coverage
- LLM Providers: > 90%
- Personality Extraction: > 85%
- Persona Synthesis: > 85%
- System Prompt Generation: > 90%

### Integration Tests
- [ ] End-to-end synthesis with real APIs
- [ ] Provider fallback scenarios
- [ ] Error handling and recovery
- [ ] Cost tracking accuracy
- [ ] Performance benchmarks

### Manual Testing
- [ ] Generate 10 unique personas
- [ ] Test all adjustment options
- [ ] Verify preview accuracy
- [ ] Check persona coherence
- [ ] Validate token counts

## 🎮 Cursor Workflow

### For Each Batch
1. **Load context**:
   ```
   Open Phase2_PersonaSynthesis_ENHANCED.md
   @codebase Show existing AI service implementations
   ```

2. **Generate implementations**:
   ```
   Implement Task 2.1.1 according to the specification
   Include comprehensive error handling and logging
   ```

3. **Test immediately**:
   ```
   Run the test command for this task
   Fix any issues before proceeding
   ```

4. **Commit at checkpoints**:
   ```
   Use the provided commit message
   Push to feature branch
   ```

## 📊 Progress Tracking

```markdown
## Phase 2 Progress
- [x] Planning & Documentation
- [ ] Batch 2.1: LLM Providers (0/5)
- [ ] Batch 2.2: Personality Extraction (0/5)
- [ ] Batch 2.3: Persona Synthesis (0/5)
- [ ] Batch 2.4: Preview & Adjustments (0/5)
- [ ] Integration Testing
- [ ] Performance Optimization
- [ ] Documentation Update
```

## 🚦 Success Criteria

1. **Functionality**: Complete persona generation from conversation data
2. **Quality**: Rich, unique personas that feel authentic
3. **Performance**: < 5 second total synthesis time
4. **Reliability**: Graceful fallbacks for API failures
5. **Cost**: < $0.50 per persona generation

## 💡 Implementation Tips

### API Key Setup
```bash
# Add to .env.local (git ignored)
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GOOGLE_AI_API_KEY=...

# Or use Xcode scheme environment variables
```

### Testing with Real APIs
```swift
// Use XCTestExpectation for async tests
func testRealAPICall() async throws {
    guard ProcessInfo.processInfo.environment["RUN_INTEGRATION_TESTS"] == "true" else {
        throw XCTSkip("Skipping integration test")
    }
    
    // Test with real API
}
```

### Prompt Engineering Tips
1. Be specific about output format
2. Provide examples for consistency
3. Use temperature 0.3-0.5 for extraction
4. Use temperature 0.7-0.8 for creative generation
5. Always validate JSON responses

---

*"The best persona is one that feels like it was crafted just for you, because it was." - Design Philosophy*
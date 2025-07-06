# AI System Implementation Plan (Revised)

**Date**: 2025-01-04  
**Status**: Pre-MVP Implementation Required  
**Priority**: HIGH - Disconnect between implementations

## Executive Summary - Revised Findings

After thorough code inspection, the situation is more nuanced than initially assessed:

1. **Good Infrastructure Exists**: CoachEngine has real AI implementations for dashboard, notifications, and other features
2. **Integration Issue**: AICoachService (used by Dashboard) has hardcoded implementations instead of using CoachEngine
3. **Structured Output Ready**: Schemas exist but aren't being used in the right places
4. **Method Exists**: `generateNotificationContent` exists in CoachEngine (I was wrong about it being missing)

## Actual State of AI Implementation

### ✅ What's Actually Implemented
- **CoachEngine.generateDashboardContent()**: Real AI with context assembly (lines 1584-1739)
- **CoachEngine.generateNotificationContent()**: Exists with persona integration (lines 1374-1418)
- **Structured Output Schemas**: Dashboard schema defined in NutritionSchemas.swift
- **DirectAIProcessor**: Using structured outputs for nutrition (working well)
- **PersonaSynthesizer**: Quality implementation with progress tracking

### 🚨 The Real Problems
1. **AICoachService Disconnect**: Still returns hardcoded strings instead of calling CoachEngine
2. **Manual JSON Parsing**: Dashboard AI uses manual parsing instead of structured outputs
3. **Two Implementations**: AICoachService and CoachEngine both exist but aren't connected
4. **No Structured Output Usage**: Despite having schemas, not using them for dashboard/goals

## Corrected Implementation Plan

### Phase 1: Connect Existing Implementations (2-3 days)

#### 1.1 Fix AICoachService → CoachEngine Connection (Day 1)
```swift
// Current AICoachService (BAD):
func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
    switch hour {
        case 5..<12: return "Good morning!" // HARDCODED!
    }
}

// Fixed AICoachService (GOOD):
func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
    // Delegate to the real implementation
    return try await coachEngine.generateDashboardContent(for: user)
}
```

**Tasks**:
- [ ] Update AICoachService to delegate to CoachEngine methods
- [ ] Remove all hardcoded responses from AICoachService
- [ ] Ensure proper error handling and fallbacks
- [ ] Test integration between services

#### 1.2 Migrate to Structured Outputs (Day 2)
**Current Issue**: CoachEngine uses manual JSON parsing despite schemas existing

```swift
// Current (lines 1714-1719):
if let data = fullResponse.data(using: .utf8),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
    primaryInsight = json["primaryInsight"] as? String ?? primaryInsight
}

// Target:
let response = try await directAIProcessor.executeStructuredAIRequest(
    prompt: prompt,
    schema: NutritionSchemas.dashboardContent,
    config: dashboardConfig,
    userId: user.id.uuidString
)
```

**Tasks**:
- [ ] Update CoachEngine.generateDashboardContent to use structured output
- [ ] Update goal-related methods to use structured output schemas
- [ ] Create schemas for notification content
- [ ] Remove all manual JSON parsing

#### 1.3 Add Telemetry & Transparency (Day 3)
**Tasks**:
- [ ] Add success/failure tracking to all AI operations
- [ ] Implement user-visible indicators for AI vs fallback content
- [ ] Add latency tracking for dashboard generation
- [ ] Create alerts for high failure rates

### Phase 2: Enhance Existing Features (Week 2)

#### 2.1 Dashboard Context Enhancement
The current implementation already assembles good context, but we can improve:
- [ ] Add goal progress context
- [ ] Include recovery metrics
- [ ] Add weather integration
- [ ] Implement trend analysis

#### 2.2 Notification Personalization
- [ ] Expand notification context types
- [ ] Add time-of-day personalization
- [ ] Implement notification effectiveness tracking
- [ ] A/B test different message styles

#### 2.3 Performance Optimization
- [ ] Profile context assembly performance
- [ ] Add caching for expensive operations
- [ ] Implement incremental context updates
- [ ] Optimize HealthKit queries

### Phase 3: New AI Features (Week 3+)

#### 3.1 Predictive Insights
- [ ] Implement goal completion predictions
- [ ] Add injury risk analysis
- [ ] Create optimal workout timing suggestions
- [ ] Build energy level predictions

#### 3.2 Adaptive Learning
- [ ] Track user engagement with AI content
- [ ] Adjust tone based on user responses
- [ ] Learn optimal notification timing
- [ ] Personalize content length preferences

## Technical Details

### Service Architecture Fix
```swift
// AICoachService.swift - Complete rewrite needed
actor AICoachService: AICoachServiceProtocol, ServiceProtocol {
    private let coachEngine: CoachEngine
    
    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        // Simply delegate to the real implementation
        return try await coachEngine.generateDashboardContent(for: user)
    }
    
    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
        // Use the AI-powered greeting from coach engine
        let notificationContext = MorningContext(
            userName: context.userName,
            sleepQuality: context.sleepQuality.flatMap { Int($0) }.map { 
                SleepQuality(rawValue: $0) ?? .fair 
            },
            sleepDuration: context.sleepHours.map { $0 * 3600 },
            weather: nil, // TODO: Add weather
            plannedWorkout: nil, // TODO: Add from user data
            currentStreak: 0, // TODO: Calculate
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            motivationalStyle: MotivationalStyle() // TODO: Extract from user
        )
        
        return try await coachEngine.generateNotificationContent(
            type: .morningGreeting,
            context: notificationContext
        )
    }
}
```

### Structured Output Integration
```swift
// Update CoachEngine dashboard generation
private func generateDashboardWithStructuredOutput(
    context: String,
    persona: PersonaProfile,
    user: User
) async throws -> AIDashboardContent {
    let request = AIRequest(
        systemPrompt: persona.systemPrompt,
        messages: [AIChatMessage(role: .user, content: context)],
        temperature: 0.7,
        maxTokens: 500,
        user: user.id.uuidString,
        responseFormat: .structuredJson(schema: NutritionSchemas.dashboardContent)
    )
    
    var structuredData: Data?
    for try await response in aiService.sendRequest(request) {
        switch response {
        case .structuredData(let data):
            structuredData = data
        case .error(let error):
            throw error
        case .done:
            break
        default:
            break
        }
    }
    
    guard let data = structuredData else {
        throw CoachEngineError.aiServiceUnavailable
    }
    
    // Parse with confidence - structured output guarantees format
    let result = try JSONDecoder().decode(DashboardAIResponse.self, from: data)
    
    return AIDashboardContent(
        primaryInsight: result.primaryInsight,
        nutritionData: nutritionData, // Already calculated
        muscleGroupVolumes: muscleVolumes, // Already calculated
        guidance: result.guidance,
        celebration: result.celebration
    )
}
```

## Immediate Action Items

1. **Today**: Start fixing AICoachService → CoachEngine connection
2. **Tomorrow**: Implement structured output for dashboard
3. **This Week**: Complete Phase 1 to have all AI features actually working

## Success Metrics (Revised)

### Week 1
- [ ] AICoachService delegates all methods to CoachEngine
- [ ] Dashboard shows real AI content (not time-based strings)
- [ ] Structured outputs used for dashboard and goals
- [ ] Zero hardcoded responses in production

### Week 2  
- [ ] AI content generation latency <2s
- [ ] Fallback usage <10% (with proper error tracking)
- [ ] User can distinguish AI vs template content
- [ ] Dashboard references actual user data

### Week 3
- [ ] Predictive insights implemented
- [ ] Adaptive learning tracking user preferences
- [ ] 90%+ user satisfaction with AI content

## Key Insight

The infrastructure is mostly there - we just need to connect the pieces properly. CoachEngine has real implementations, but AICoachService is bypassing them with hardcoded responses. This is a integration problem, not a missing feature problem.

**Priority #1**: Delete the hardcoded implementations and wire up the real AI.
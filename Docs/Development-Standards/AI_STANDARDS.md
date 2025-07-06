# AI System Standards

**Last Updated**: 2025-01-04  
**Status**: Active  
**Priority**: 🚨 Critical - AI is core to the app experience

## Table of Contents
1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Architecture Patterns](#architecture-patterns)
4. [Structured Output Standards](#structured-output-standards)
5. [Service Integration](#service-integration)
6. [Error Handling & Fallbacks](#error-handling--fallbacks)
7. [Performance Guidelines](#performance-guidelines)
8. [User Trust & Transparency](#user-trust--transparency)
9. [Anti-Patterns](#anti-patterns)
10. [Quick Reference](#quick-reference)

## Overview

This document defines how AI services are implemented, integrated, and presented in AirFit. Our AI system is not a feature - it's the core of the user experience, providing personalized coaching, intelligent insights, and adaptive guidance.

**Key Achievement**: 99.9% parsing reliability with structured outputs, <2s response times, transparent fallback handling.

## Core Principles

1. **Authenticity Over Everything** - Never show fake AI responses
2. **Structured Output First** - Use schemas for guaranteed parsing
3. **Context-Aware** - Every AI call includes relevant user context
4. **Graceful Degradation** - Clear fallbacks with user transparency
5. **Performance Conscious** - Cache appropriately, batch when possible
6. **Multi-Provider Support** - Seamless fallback between providers
7. **User Trust** - Always indicate AI vs template content

## Architecture Patterns

### AI Service Hierarchy

```
┌─────────────────────────────────────────────────┐
│                  CoachEngine                     │ ← Main AI interface
├─────────────────────────────────────────────────┤
│         DirectAIProcessor  │  StreamingHandler   │ ← Specialized processors
├─────────────────────────────────────────────────┤
│                  AIService                       │ ← Provider abstraction
├─────────────────────────────────────────────────┤
│              LLMOrchestrator                     │ ← Multi-provider management
├─────────────────────────────────────────────────┤
│  OpenAIProvider │ AnthropicProvider │ GeminiProvider │ ← Provider implementations
└─────────────────────────────────────────────────┘
```

### Service Integration Pattern

```swift
// ✅ CORRECT: Delegate to CoachEngine
actor AICoachService: AICoachServiceProtocol {
    private let coachEngine: CoachEngine
    
    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        // Delegate to the real implementation
        return try await coachEngine.generateDashboardContent(for: user)
    }
}

// ❌ WRONG: Hardcoded responses
func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
    return AIDashboardContent(
        primaryInsight: "Good morning!" // NO! This is fake AI
    )
}
```

## Structured Output Standards

### Always Use Structured Output for:
- Dashboard content generation
- Goal analysis and updates  
- Nutrition parsing
- Notification content
- Any JSON response parsing

### Schema Definition Pattern

```swift
extension StructuredOutputSchema {
    static let dashboardContent = StructuredOutputSchema.fromJSON(
        name: "dashboard_content",
        description: "Generate personalized dashboard insights",
        schema: [
            "type": "object",
            "properties": [
                "primary_insight": [
                    "type": "string",
                    "description": "Main personalized message (2-3 sentences)"
                ],
                "guidance": [
                    "type": "string", 
                    "description": "Actionable next step"
                ]
            ],
            "required": ["primary_insight"],
            "additionalProperties": false
        ],
        strict: true // Always use strict mode
    )!
}
```

### Using Structured Output

```swift
// ✅ CORRECT: Structured output with schema
let request = AIRequest(
    systemPrompt: persona.systemPrompt,
    messages: [AIChatMessage(role: .user, content: prompt)],
    temperature: 0.7,
    maxTokens: 500,
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

// Parse with confidence - schema guarantees format
let result = try JSONDecoder().decode(DashboardResponse.self, from: structuredData!)

// ❌ WRONG: Manual JSON parsing
if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
    let insight = json["primaryInsight"] as? String ?? "Default" // Fragile!
}
```

## Service Integration

### Context Assembly for AI

```swift
// ✅ CORRECT: Rich context for AI
private func buildDashboardContext(for user: User) async -> String {
    let health = await contextAssembler.assembleSnapshot()
    let goals = try? await goalService.getGoalsContext(for: user.id)
    let nutrition = await nutritionService.getTodaysSummary(for: user)
    
    return """
    User: \(user.name ?? "User")
    Steps today: \(health.activity.steps ?? 0)
    Sleep quality: \(health.sleep.lastNight?.quality ?? "unknown")
    Active goals: \(goals?.activeGoals.count ?? 0)
    Calories consumed: \(nutrition.calories)/\(nutrition.target)
    Recent workout: \(health.appContext.workoutContext?.recentWorkouts.first?.name ?? "none")
    """
}

// ❌ WRONG: Minimal context
let context = "Generate content for \(user.name)"
```

### Persona Integration

```swift
// ✅ CORRECT: Use user's persona for consistency
let persona = try await personaService.getActivePersona(for: user.id)
let systemPrompt = persona.systemPrompt + """

Task: Generate dashboard content.
Voice: Match your established personality.
Length: 2-3 sentences maximum.
"""

// ❌ WRONG: Generic system prompt
let systemPrompt = "You are a fitness coach."
```

## Error Handling & Fallbacks

### Retry Logic Pattern

```swift
// ✅ CORRECT: Retry with exponential backoff
func generateWithRetry<T>(_ operation: () async throws -> T) async throws -> T {
    let delays: [Duration] = [.seconds(1), .seconds(2), .seconds(4)]
    var lastError: Error?
    
    for (attempt, delay) in delays.enumerated() {
        do {
            return try await operation()
        } catch {
            lastError = error
            AppLogger.warning("AI attempt \(attempt + 1) failed: \(error)", category: .ai)
            if attempt < delays.count - 1 {
                try await Task.sleep(for: delay)
            }
        }
    }
    
    throw lastError ?? AppError.llm("AI generation failed")
}
```

### Transparent Fallbacks

```swift
// ✅ CORRECT: Clear indication of fallback
struct AIResponse {
    let content: String
    let source: ContentSource
    
    enum ContentSource {
        case ai(model: String)
        case template(reason: String)
        case cached
    }
}

// In UI:
if response.source == .template {
    Text(response.content)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
                .help("AI unavailable - showing template")
        }
}
```

## Performance Guidelines

### Caching Strategy

```swift
// ✅ CORRECT: Cache expensive AI operations
actor AIResponseCache {
    private var cache: [CacheKey: CachedResponse] = [:]
    
    func get(for key: CacheKey) async -> AIResponse? {
        guard let cached = cache[key],
              cached.expiresAt > Date() else { return nil }
        
        AppLogger.debug("AI cache hit for \(key)", category: .ai)
        return cached.response
    }
    
    func set(_ response: AIResponse, for key: CacheKey, ttl: TimeInterval) {
        cache[key] = CachedResponse(
            response: response,
            expiresAt: Date().addingTimeInterval(ttl)
        )
    }
}

// Cache TTLs by feature:
// - Dashboard content: 5 minutes
// - Nutrition parsing: 1 hour (same food)
// - Goal analysis: 30 minutes
// - Notifications: No cache (always fresh)
```

### Parallel AI Operations

```swift
// ✅ CORRECT: Parallel when independent
async let dashboardContent = generateDashboardContent()
async let notificationContent = generateNotificationContent()
async let goalProgress = analyzeGoalProgress()

let (dashboard, notification, goals) = try await (
    dashboardContent, notificationContent, goalProgress
)

// ❌ WRONG: Sequential when could be parallel
let dashboard = try await generateDashboardContent()
let notification = try await generateNotificationContent()
let goals = try await analyzeGoalProgress()
```

## User Trust & Transparency

### AI Status Indicators

```swift
// ✅ CORRECT: Show AI processing state
@MainActor
@Observable
final class DashboardViewModel {
    enum ContentState {
        case loading
        case ai(content: AIDashboardContent, model: String)
        case template(content: AIDashboardContent, reason: String)
        case error(Error)
    }
    
    private(set) var contentState: ContentState = .loading
}

// In View:
switch viewModel.contentState {
case .loading:
    ProgressView("Generating insights...")
case .ai(let content, let model):
    DashboardContentView(content: content)
        .badge("AI: \(model)")
case .template(let content, let reason):
    DashboardContentView(content: content)
        .badge("Template")
        .help(reason)
case .error:
    ErrorView()
}
```

### Telemetry & Monitoring

```swift
// ✅ CORRECT: Track AI performance
struct AITelemetry {
    static func track(
        feature: String,
        success: Bool,
        latencyMs: Int,
        provider: String,
        fallbackUsed: Bool,
        structuredOutput: Bool
    ) {
        AppLogger.info("AI Operation", metadata: [
            "feature": feature,
            "success": success,
            "latency_ms": latencyMs,
            "provider": provider,
            "fallback_used": fallbackUsed,
            "structured_output": structuredOutput
        ], category: .ai)
        
        // Alert on high failure rates
        if !success {
            incrementFailureCount(for: feature)
        }
    }
}
```

## Anti-Patterns

### ❌ Fake AI Responses
```swift
// ❌ NEVER DO THIS
func generateInsight() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12: return "Good morning!"
    case 12..<17: return "Good afternoon!"
    default: return "Hello!"
    }
}

// ✅ CORRECT: Real AI or honest fallback
func generateInsight() async throws -> String {
    do {
        return try await aiService.generate(...)
    } catch {
        throw AppError.llm("Unable to generate insight")
    }
}
```

### ❌ Silent AI Failures
```swift
// ❌ WRONG: User doesn't know it failed
func getContent() async -> String {
    do {
        return try await aiService.generate(...)
    } catch {
        return "Welcome back!" // Silent fallback
    }
}

// ✅ CORRECT: Transparent failure handling
func getContent() async -> ContentResult {
    do {
        let aiContent = try await aiService.generate(...)
        return .ai(aiContent)
    } catch {
        AppLogger.error("AI generation failed", error: error)
        return .template("Welcome back!", reason: "AI temporarily unavailable")
    }
}
```

### ❌ Ignoring Structured Output
```swift
// ❌ WRONG: Manual parsing when schema exists
let response = try await aiService.sendRequest(request)
if response.contains("calories") { ... } // Fragile!

// ✅ CORRECT: Use structured output
let request = AIRequest(
    responseFormat: .structuredJson(schema: NutritionSchemas.mealAnalysis)
)
```

## Quick Reference

### Do's ✅
- Always use structured output for JSON responses
- Include rich context in every AI call
- Use user's persona for consistent voice
- Implement retry logic with backoff
- Cache expensive operations appropriately
- Show clear indicators for AI vs template
- Track success/failure metrics
- Handle errors transparently

### Don'ts ❌
- Never show fake AI responses
- Don't parse JSON manually when schemas exist
- Don't fail silently - inform the user
- Don't make sequential calls that could be parallel
- Don't ignore persona voice consistency
- Don't skip context assembly
- Don't hide AI processing state

### Performance Targets
- **Response Time**: <2s for all AI operations
- **Structured Output Success**: >99%
- **Fallback Rate**: <10% in normal operation
- **Cache Hit Rate**: >60% for eligible operations

### Code Review Checklist
- [ ] Uses structured output for JSON responses
- [ ] Includes appropriate user context
- [ ] Uses persona for voice consistency
- [ ] Has retry logic for failures
- [ ] Shows transparent fallback handling
- [ ] Tracks telemetry data
- [ ] Respects performance guidelines
- [ ] No fake AI responses

## Integration with Other Standards

- **Service Layer**: Follow `SERVICE_LAYER_STANDARDS.md` for actor patterns
- **Error Handling**: Use AppError from `ERROR_HANDLING_STANDARDS.md`
- **Concurrency**: Apply patterns from `CONCURRENCY_STANDARDS.md`
- **UI Feedback**: Show states per `UI_STANDARDS.md`
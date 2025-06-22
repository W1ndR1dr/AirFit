# AirFit Onboarding: LLM-First Implementation Plan

**Status**: Ready for Implementation  
**Priority**: Critical Path  
**Philosophy**: LLM as Intelligence Layer Throughout

## Executive Summary

Transform onboarding from a hardcoded form-filling experience into an intelligent conversation where the LLM drives every decision, prompt, and suggestion based on holistic understanding of the user.

## Core Principle: LLM-First Architecture

**Current Problem**: Hardcoded if/then logic throughout onboarding
**Solution**: LLM interprets data and drives the experience at every screen

### What Changes

| Current (Hardcoded) | New (LLM-Driven) |
|-------------------|-----------------|
| `if steps > 12000` then "You're crushing it!" | LLM analyzes full health context → generates insight |
| Pre-select goals based on weight > 200 | LLM understands user holistically → suggests relevant goals |
| Fixed placeholders for text input | LLM creates contextual prompts based on what it knows |
| Simple threshold-based defaults | LLM makes nuanced suggestions from patterns |

## Implementation Plan

### Phase 1: Core Infrastructure (Day 1)

#### 1.1 Create LLM Context Builder
```swift
struct OnboardingLLMContext: Codable, Sendable {
    let healthKitData: HealthKitSnapshot?
    let currentScreenContext: ScreenContext
    let previousResponses: [String: Any]
    let requestType: LLMRequestType
}

enum LLMRequestType {
    case generatePrompt(for: OnboardingScreen)
    case suggestDefaults(for: OnboardingScreen) 
    case interpretResponse(text: String, context: OnboardingScreen)
    case synthesizePersona
}
```

#### 1.2 Create Onboarding LLM Service
```swift
actor OnboardingLLMService: ServiceProtocol {
    func generateScreenContent(
        for screen: OnboardingScreen,
        context: OnboardingLLMContext
    ) async throws -> ScreenContent
    
    func interpretUserInput(
        _ input: String,
        screen: OnboardingScreen,
        context: OnboardingLLMContext
    ) async throws -> InterpretedInput
    
    func synthesizePersona(
        from context: OnboardingLLMContext
    ) async throws -> PersonaSynthesis
}
```

### Phase 2: Screen-by-Screen LLM Integration (Days 2-3)

#### 2.1 HealthKit Screen (Post-Authorization)
**LLM Request**: "Here's the user's health data: [full HealthKit snapshot]. Generate a conversational insight that shows we understand their current state."

**Expected LLM Response**:
- Personalized observation about their data
- NOT hardcoded thresholds
- Examples:
  - "I notice your sleep has been inconsistent lately - averaging 5.2 hours with big weekend variations"
  - "Your activity pattern shows bursts of high intensity followed by quiet periods - shift work perhaps?"

#### 2.2 Life Context Screen
**LLM Request**: "Based on their health data showing [context], generate a personalized prompt to understand their lifestyle."

**Remove**: All hardcoded prompts based on step count thresholds
**Add**: Dynamic LLM-generated prompts that feel insightful

#### 2.3 Goals Screen
**LLM Request**: "User described their life as: '[life context]'. Their health data shows [snapshot]. Generate smart goal suggestions and interpret their free-text response."

**Remove**: Hardcoded placeholders based on weight/activity
**Add**: LLM interprets natural language and suggests relevant goals

#### 2.4 Weight Objectives Screen
**LLM Request**: "User wants to go from [current] to [target] weight. Given their full context, provide encouragement and identify any considerations."

**Remove**: Hardcoded messages based on pound thresholds
**Add**: Contextual, nuanced encouragement

#### 2.5 Body Composition Screen
**LLM Request**: "Based on everything we know, which body composition goals make sense? Pre-select intelligently."

**Remove**: Hardcoded pre-selection based on simple if/else
**Add**: LLM-driven smart defaults

#### 2.6 Communication Style Screen
**LLM Request**: "Given this person's responses and data patterns, suggest communication styles that would resonate."

**Remove**: Hardcoded style suggestions based on activity level
**Add**: Nuanced personality matching

### Phase 3: Final Synthesis (Day 4)

#### 3.1 Comprehensive Persona Generation
**LLM Request**: Full context → Complete persona synthesis with:
- Unified coaching strategy
- Personalized system prompt
- Relationship between goals
- Anticipated challenges
- Motivational approach

### Phase 4: Testing & Refinement (Day 5)

#### 4.1 Prompt Engineering
- Test each LLM integration point
- Refine prompts for consistency
- Ensure graceful fallbacks
- Validate response quality

#### 4.2 Performance Optimization
- Cache LLM responses where appropriate
- Implement timeout handling
- Add loading states
- Ensure <3s response times

## Technical Implementation Details

### Remove These Files/Functions
1. `OnboardingContext.swift` - Delete entirely (all hardcoded logic)
2. Hardcoded prompts in all view files
3. Pre-selection logic in ViewModels
4. Threshold-based decision making

### Add These Components
1. `OnboardingLLMService.swift` - Central LLM integration
2. `OnboardingPrompts.swift` - LLM prompt templates
3. `OnboardingFallbacks.swift` - Graceful degradation
4. Enhanced error handling for LLM failures

### LLM Prompt Templates

```swift
struct OnboardingPrompts {
    static func lifeContextPrompt(healthData: HealthKitSnapshot) -> String {
        """
        Analyze this health data and generate a conversational, 
        insightful prompt to understand their lifestyle:
        
        Health Data: \(healthData)
        
        Requirements:
        - Sound like a knowledgeable friend noticing patterns
        - Be specific to what you see in their data
        - Invite them to share context
        - Max 2 sentences
        """
    }
    
    static func goalSuggestionPrompt(
        lifeContext: String, 
        healthData: HealthKitSnapshot
    ) -> String {
        """
        Based on:
        - Life context: "\(lifeContext)"
        - Health data: \(healthData)
        
        Suggest 3-5 relevant fitness goals.
        Return as JSON array of goal objects with rationale.
        """
    }
}
```

## Success Metrics

### Technical
- Zero hardcoded thresholds or if/then logic
- All prompts dynamically generated
- All suggestions LLM-driven
- <3s LLM response time

### User Experience  
- Prompts feel remarkably insightful
- Suggestions feel personalized
- Natural conversation flow
- High completion rate (>90%)

## Risk Mitigation

### LLM Failures
- Implement graceful fallbacks (but not hardcoded logic)
- Cache successful responses
- Queue and retry failed requests
- Clear user communication about delays

### Response Quality
- Structured prompt engineering
- Response validation
- Consistency checking
- User feedback loops

## Migration Strategy

1. **Parallel Implementation**: Build new LLM-driven system alongside current
2. **Component Replacement**: Replace one screen at a time
3. **A/B Testing**: Compare completion rates and satisfaction
4. **Full Cutover**: Remove all hardcoded logic

## Key Principles

1. **No Hardcoded Logic**: Every decision goes through LLM
2. **Holistic Understanding**: LLM sees full context, not isolated data points
3. **Natural Language**: Let users express themselves freely
4. **Smart Interpretation**: LLM understands intent, not just keywords
5. **Graceful Degradation**: System works even if LLM fails (with reduced magic)

## Next Steps

1. Review and approve this plan
2. Create OnboardingLLMService
3. Implement first screen (Life Context) as proof of concept
4. Iterate based on results
5. Roll out to all screens

---

**Bottom Line**: Every interaction should feel like the app truly understands the user because the LLM is making intelligent decisions based on complete context, not following hardcoded rules.
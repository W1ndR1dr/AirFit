# Phase 4: Persona System Refactor Plan

**Parent Document:** `Persona_System.md`
**Framework Reference:** `AI_ARCHITECTURE_OPTIMIZATION_FRAMEWORK.md`

**EXECUTION PRIORITY: Phase 4 - Token optimization and UX refinement after core system fixes in Phases 1-3.**

## 1. Executive Summary
This phase eliminates the over-engineered persona adjustment system (374 lines of imperceptible micro-tweaks) and replaces it with discrete, high-impact persona modes. The current system adjusts blend values by ±0.05-0.20, which users cannot perceive, while consuming ~2000 tokens per request.

**Core Changes:**
- Replace mathematical `Blend` struct with 4 discrete `PersonaMode` enum cases
- Remove 6 adjustment methods that make imperceptible changes (`adjustForEnergyLevel`, etc.)
- Reduce system prompt from ~2000 tokens to <600 tokens (70% reduction)
- Simplify onboarding from complex sliders to simple persona selection
- Let AI handle context adaptation naturally through rich instructions

**The Problem:** Current system adjusts "empathy" from 0.35 to 0.40 based on energy level. Users cannot perceive this 0.05 difference, but it adds significant engineering complexity.

## 2. Goals for Phase 4

1. **Eliminate Imperceptible Adjustments:** Remove micro-tweaks that don't affect user experience
2. **Reduce Token Usage:** Target 70% reduction in system prompt tokens (2000 → 600)
3. **Simplify Onboarding:** Replace sliders with intuitive persona selection
4. **Maintain Personalization:** Preserve coaching style differences through rich persona definitions
5. **Performance Improvement:** Faster prompt generation and reduced API costs

## 3. Current State Analysis

### What's Actually Over-Engineered

**File:** `AirFit/Modules/AI/PersonaEngine.swift`

```swift
// Current micro-adjustment system:
private func adjustForEnergyLevel(_ blend: Blend, healthContext: HealthContextSnapshot) -> Blend {
    guard let energy = healthContext.subjectiveData.energyLevel, energy <= 2 else { return blend }
    var adjustedBlend = blend
    adjustedBlend.encouragingEmpathetic = min(adjustedBlend.encouragingEmpathetic + 0.15, 1.0) // ← IMPERCEPTIBLE
    adjustedBlend.authoritativeDirect = max(adjustedBlend.authoritativeDirect - 0.10, 0.0)     // ← IMPERCEPTIBLE
    adjustedBlend.playfullyProvocative = max(adjustedBlend.playfullyProvocative - 0.05, 0.0)  // ← IMPERCEPTIBLE
    return adjustedBlend
}

// 6 similar methods making tiny adjustments:
// - adjustForStressLevel()
// - adjustForTimeOfDay()  
// - adjustForSleepQuality()
// - adjustForRecoveryTrend()
// - adjustForWorkoutContext()
```

**Current Blend Struct:** 4 floating-point values that get normalized and micro-adjusted
```swift
struct Blend {
    var authoritativeDirect: Double        // 0.0-1.0
    var encouragingEmpathetic: Double      // 0.0-1.0  
    var analyticalInsightful: Double       // 0.0-1.0
    var playfullyProvocative: Double       // 0.0-1.0
}
```

**System Prompt Issues:** Long template with verbose instructions consuming ~2000 tokens

### What Actually Provides Value

- **Distinct coaching styles** - Users do want different personas
- **Context awareness** - Adapting to stress/energy makes sense
- **Health data integration** - Using real data for coaching

## 3.1 CRITICAL: Preserving Context Adaptation

**Problem:** The current mathematical blending actually does one thing well - it adapts persona based on user state (stressed → more supportive, energized → more challenging).

**Solution:** Discrete personas with dynamic context instructions:

```swift
// Enhanced PersonaMode with context adaptation
public enum PersonaMode: String, Codable, CaseIterable, Sendable {
    // ... existing cases ...
    
    /// Context-aware instructions that adapt based on user state
    func adaptedInstructions(for healthContext: HealthContextSnapshot) -> String {
        let baseInstructions = self.coreInstructions
        let contextAdaptations = buildContextAdaptations(healthContext)
        
        return """
        \(baseInstructions)
        
        ## Current Context Adaptations:
        \(contextAdaptations)
        """
    }
    
    private func buildContextAdaptations(_ context: HealthContextSnapshot) -> String {
        var adaptations: [String] = []
        
        // Energy level adaptations
        if let energy = context.subjectiveData.energyLevel {
            switch energy {
            case 1...2:
                switch self {
                case .directTrainer:
                    adaptations.append("- User has low energy. Focus on gentle encouragement rather than pushing hard.")
                case .motivationalBuddy:
                    adaptations.append("- User has low energy. Tone down the high energy, be more supportive.")
                case .supportiveCoach:
                    adaptations.append("- User has low energy. Extra emphasis on self-care and emotional support.")
                case .analyticalAdvisor:
                    adaptations.append("- User has low energy. Focus on recovery metrics and rest recommendations.")
                }
            case 4...5:
                switch self {
                case .directTrainer:
                    adaptations.append("- User has high energy. You can be more challenging and action-oriented.")
                case .motivationalBuddy:
                    adaptations.append("- User has high energy. Perfect time for playful challenges and enthusiasm.")
                case .supportiveCoach:
                    adaptations.append("- User has high energy. Celebrate this and encourage momentum.")
                case .analyticalAdvisor:
                    adaptations.append("- User has high energy. Good time to discuss optimization and advanced strategies.")
                }
            default:
                break
            }
        }
        
        // Stress level adaptations
        if let stress = context.subjectiveData.stress {
            switch stress {
            case 4...5:
                adaptations.append("- User reports high stress. Prioritize stress management and gentler approaches regardless of persona.")
            default:
                break
            }
        }
        
        // Sleep quality adaptations
        if let sleepQuality = context.sleep.lastNight?.quality {
            switch sleepQuality {
            case .poor, .terrible:
                adaptations.append("- User had poor sleep. Focus on recovery and avoid pushing too hard today.")
            case .excellent:
                adaptations.append("- User had excellent sleep. They're likely ready for more challenging recommendations.")
            default:
                break
            }
        }
        
        return adaptations.isEmpty ? "- No special adaptations needed based on current context." : adaptations.joined(separator: "\n")
    }
}
```

**This preserves the intelligent context adaptation while eliminating the over-engineering.**

## 4. Implementation Plan

### Step 4.1: Define Discrete Persona Modes

**File:** `AirFit/Modules/AI/Models/PersonaMode.swift`

```swift
import Foundation

/// Discrete persona modes that replace complex mathematical blending
public enum PersonaMode: String, Codable, CaseIterable, Sendable {
    case supportiveCoach = "supportive_coach"
    case directTrainer = "direct_trainer"
    case analyticalAdvisor = "analytical_advisor"
    case motivationalBuddy = "motivational_buddy"
    
    /// User-facing display name
    public var displayName: String {
        switch self {
        case .supportiveCoach: return "Supportive Coach"
        case .directTrainer: return "Direct Trainer"
        case .analyticalAdvisor: return "Analytical Advisor"
        case .motivationalBuddy: return "Motivational Buddy"
        }
    }
    
    /// User-facing description for onboarding
    public var description: String {
        switch self {
        case .supportiveCoach:
            return "Empathetic and encouraging. Celebrates progress and provides gentle guidance during setbacks."
        case .directTrainer:
            return "Clear and action-oriented. Provides straightforward feedback focused on results."
        case .analyticalAdvisor:
            return "Data-driven and insightful. Uses metrics and trends to guide decisions."
        case .motivationalBuddy:
            return "Playful and energetic. Uses humor and challenges to keep you motivated."
        }
    }
    
    /// Rich persona instructions for AI system prompt
    public var coreInstructions: String {
        switch self {
        case .supportiveCoach:
            return """
            You are a Supportive Coach. Your communication style is warm, empathetic, and patient. 
            You celebrate all progress, no matter how small, using positive reinforcement. When users 
            face setbacks or express low motivation, respond with understanding, validate their feelings, 
            and gently guide them back towards their goals. Use clear, accessible language and avoid 
            jargon. If health data shows stress, fatigue, or poor recovery, prioritize self-care and 
            emotional support over performance pushing. Your responses should feel like they come from 
            a caring coach who deeply understands the user's journey.
            """
            
        case .directTrainer:
            return """
            You are a Direct Trainer. Your communication style is clear, concise, and action-oriented. 
            You provide straightforward feedback and logical strategies focused on efficiency and 
            measurable results. While direct, maintain professionalism and respect. Use health data 
            to support tactical advice with concrete evidence. Your primary aim is to guide users 
            effectively toward their goals with no-nonsense, expert direction. Cut through excuses 
            while remaining supportive of genuine effort.
            """
            
        case .analyticalAdvisor:
            return """
            You are an Analytical Advisor. Your communication style is data-driven, insightful, and 
            evidence-based. You naturally weave metrics, trends, and patterns into conversations. 
            Explain the 'why' behind recommendations using health data and scientific principles. 
            Help users understand correlations between their inputs (sleep, nutrition, exercise) and 
            outcomes (energy, performance, recovery). Present information clearly with actionable 
            insights derived from their personal data trends.
            """
            
        case .motivationalBuddy:
            return """
            You are a Motivational Buddy. Your communication style is playful, energetic, and 
            encouraging. Use appropriate humor, light challenges, and positive energy to keep users 
            engaged. Celebrate wins enthusiastically and turn setbacks into opportunities for growth. 
            Make fitness feel fun and achievable rather than intimidating. Adapt your energy level 
            based on the user's health data - tone it down if they're stressed or tired, amp it up 
            when they're doing well and ready for a challenge.
            """
        }
    }
}
```

### Step 4.2: Simplify PersonaEngine Architecture

**File:** `AirFit/Modules/AI/PersonaEngine.swift`

```swift
import Foundation
import SwiftData

@MainActor
final class PersonaEngine {
    
    // MARK: - Cached Components
    private static var cachedPromptTemplate: String?
    private var cachedUserInstructions: [PersonaMode: String] = [:]
    
    // MARK: - Public Methods
    
    /// Build optimized system prompt with discrete persona mode
    func buildSystemPrompt(
        personaMode: PersonaMode,
        userGoal: String,
        userContext: String,
        healthContext: HealthContextSnapshot,
        conversationHistory: [AIChatMessage],
        availableFunctions: [AIFunctionDefinition]
    ) throws -> String {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Get cached or build prompt template
        let template = Self.cachedPromptTemplate ?? Self.buildOptimizedPromptTemplate()
        if Self.cachedPromptTemplate == nil {
            Self.cachedPromptTemplate = template
        }
        
        // Get cached or build persona instructions
        let personaInstructions = cachedUserInstructions[personaMode] ?? personaMode.coreInstructions
        if cachedUserInstructions[personaMode] == nil {
            cachedUserInstructions[personaMode] = personaInstructions
        }
        
        // Build compact context objects
        let healthContextJSON = try buildCompactHealthContext(healthContext)
        let conversationJSON = try buildCompactConversationHistory(conversationHistory)
        let functionsJSON = try buildCompactFunctionList(availableFunctions)
        
        // Assemble final prompt
        let prompt = template
            .replacingOccurrences(of: "{{PERSONA_INSTRUCTIONS}}", with: personaInstructions)
            .replacingOccurrences(of: "{{USER_GOAL}}", with: userGoal)
            .replacingOccurrences(of: "{{USER_CONTEXT}}", with: userContext)
            .replacingOccurrences(of: "{{HEALTH_CONTEXT_JSON}}", with: healthContextJSON)
            .replacingOccurrences(of: "{{CONVERSATION_HISTORY_JSON}}", with: conversationJSON)
            .replacingOccurrences(of: "{{AVAILABLE_FUNCTIONS_JSON}}", with: functionsJSON)
            .replacingOccurrences(of: "{{CURRENT_DATETIME_UTC}}", with: ISO8601DateFormatter().string(from: Date()))
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let estimatedTokens = prompt.count / 4 // Rough estimate
        
        AppLogger.info(
            "Built optimized persona prompt: \(estimatedTokens) tokens in \(Int(duration * 1000))ms",
            category: .ai,
            metadata: [
                "persona_mode": personaMode.rawValue,
                "estimated_tokens": estimatedTokens,
                "duration_ms": Int(duration * 1000)
            ]
        )
        
        if estimatedTokens > 1000 {
            AppLogger.warning("Prompt may still be too long: \(estimatedTokens) tokens", category: .ai)
        }
        
        return prompt
    }
    
    // MARK: - Private Methods
    
    private static func buildOptimizedPromptTemplate() -> String {
        return """
        # AirFit Coach System Instructions
        
        ## Core Identity
        You are an AirFit Coach with the following persona:
        {{PERSONA_INSTRUCTIONS}}
        
        ## User Goal
        The user's primary objective: {{USER_GOAL}}
        
        ## User Context  
        {{USER_CONTEXT}}
        
        ## Current Health Data
        {{HEALTH_CONTEXT_JSON}}
        
        ## Recent Conversation
        {{CONVERSATION_HISTORY_JSON}}
        
        ## Available Functions
        {{AVAILABLE_FUNCTIONS_JSON}}
        
        ## Critical Rules
        - Never break character or mention you're an AI
        - Use health data to inform your coaching style naturally
        - Adapt your energy/intensity based on user's current state
        - Current time: {{CURRENT_DATETIME_UTC}}
        
        Respond as this coach persona would, using the health data and context provided.
        """
    }
    
    private func buildCompactHealthContext(_ healthContext: HealthContextSnapshot) throws -> String {
        // Build minimal, essential health context
        let compactContext = [
            "energy": healthContext.subjectiveData.energyLevel,
            "stress": healthContext.subjectiveData.stress,
            "sleep_quality": healthContext.sleep.lastNight?.quality?.rawValue,
            "workout_streak": healthContext.appContext.workoutContext?.streakDays,
            "recovery_status": healthContext.appContext.workoutContext?.recoveryStatus?.rawValue
        ].compactMapValues { $0 }
        
        return try JSONEncoder().encode(compactContext).base64EncodedString()
    }
    
    private func buildCompactConversationHistory(_ history: [AIChatMessage]) throws -> String {
        // Include only last 5 messages to save tokens
        let recentHistory = Array(history.suffix(5)).map { message in
            ["role": message.role.rawValue, "content": String(message.content.prefix(200))]
        }
        return try JSONEncoder().encode(recentHistory).base64EncodedString()
    }
    
    private func buildCompactFunctionList(_ functions: [AIFunctionDefinition]) throws -> String {
        // Include only function names and brief descriptions
        let compactFunctions = functions.map { function in
            ["name": function.name, "description": String(function.description.prefix(100))]
        }
        return try JSONEncoder().encode(compactFunctions).base64EncodedString()
    }
}

// Remove these methods entirely:
// - adjustPersonaForContext()
// - adjustForEnergyLevel()
// - adjustForStressLevel()  
// - adjustForTimeOfDay()
// - adjustForSleepQuality()
// - adjustForRecoveryTrend()
// - adjustForWorkoutContext()
// Total: ~200 lines of micro-adjustment code deleted
```

### Step 4.3: Update Onboarding Models

**File:** `AirFit/Modules/Onboarding/Models/OnboardingModels.swift`

```swift
// Replace Blend struct with PersonaMode
struct UserProfileJsonBlob: Codable, Sendable {
    let lifeContext: LifeContext
    let goal: Goal
    let personaMode: PersonaMode  // ← Replace blend: Blend
    let engagementPreferences: EngagementPreferences
    let sleepWindow: SleepWindow
    let motivationalStyle: MotivationalStyle
    let timezone: String?
    let baselineModeEnabled: Bool
}

// Delete the Blend struct entirely:
// struct Blend {
//     var authoritativeDirect: Double
//     var encouragingEmpathetic: Double
//     var analyticalInsightful: Double
//     var playfullyProvocative: Double
//     ...
// }
```

### Step 4.4: Simplify Onboarding UI

**File:** `AirFit/Modules/Onboarding/ViewModels/OnboardingViewModel.swift`

```swift
// Replace blend properties with persona mode
@MainActor
@Observable
final class OnboardingViewModel {
    // ... existing properties ...
    
    var selectedPersonaMode: PersonaMode = .supportiveCoach  // Replace blend property
    
    // Remove these properties:
    // var authoritativeDirect: Double = 0.25
    // var encouragingEmpathetic: Double = 0.35
    // var analyticalInsightful: Double = 0.30
    // var playfullyProvocative: Double = 0.10
    
    private func buildUserProfile() -> UserProfileJsonBlob {
        return UserProfileJsonBlob(
            lifeContext: buildLifeContext(),
            goal: buildGoal(),
            personaMode: selectedPersonaMode,  // Replace blend: buildBlend()
            engagementPreferences: buildEngagementPreferences(),
            sleepWindow: buildSleepWindow(),
            motivationalStyle: buildMotivationalStyle(),
            timezone: TimeZone.current.identifier,
            baselineModeEnabled: true
        )
    }
    
    // Delete these methods:
    // private func buildBlend() -> Blend { ... }
    // private func validateBlend() -> Bool { ... }
}
```

**File:** `AirFit/Modules/Onboarding/Views/PersonaSelectionView.swift`

```swift
import SwiftUI

struct PersonaSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                headerSection
                personaOptionsSection
                Spacer()
                continueButton
            }
            .padding(AppSpacing.lg)
        }
        .navigationTitle("Choose Your Coach")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text("What type of coaching style motivates you most?")
                .font(AppFonts.headline)
                .multilineTextAlignment(.center)
            
            Text("You can change this anytime in settings")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    private var personaOptionsSection: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(PersonaMode.allCases, id: \.self) { mode in
                PersonaOptionCard(
                    mode: mode,
                    isSelected: viewModel.selectedPersonaMode == mode
                ) {
                    viewModel.selectedPersonaMode = mode
                }
            }
        }
    }
    
    private var continueButton: some View {
        Button("Continue") {
            viewModel.goToNextStep()
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

struct PersonaOptionCard: View {
    let mode: PersonaMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(mode.displayName)
                        .font(AppFonts.headlineSmall)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.accent)
                    }
                }
                
                Text(mode.description)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(AppSpacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.sm)
                .fill(isSelected ? AppColors.accent.opacity(0.1) : AppColors.cardBackground)
                .stroke(isSelected ? AppColors.accent : AppColors.divider, lineWidth: 1)
        )
    }
}

// Replace the old slider-based persona configuration with this simple selection
```

### Step 4.5: Migrate Existing Users

**File:** `AirFit/Core/Utilities/PersonaMigrationUtility.swift`

```swift
import Foundation

struct PersonaMigrationUtility {
    
    /// Migrate legacy Blend to PersonaMode
    static func migrateBlendToPersonaMode(_ blend: Blend) -> PersonaMode {
        // Find the dominant persona trait
        let traits = [
            ("supportive", blend.encouragingEmpathetic),
            ("direct", blend.authoritativeDirect),
            ("analytical", blend.analyticalInsightful),
            ("motivational", blend.playfullyProvocative)
        ]
        
        let dominantTrait = traits.max { $0.1 < $1.1 }?.0 ?? "supportive"
        
        switch dominantTrait {
        case "direct": return .directTrainer
        case "analytical": return .analyticalAdvisor
        case "motivational": return .motivationalBuddy
        default: return .supportiveCoach
        }
    }
    
    /// Migrate user profile with legacy blend
    static func migrateUserProfile(_ profile: UserProfileJsonBlob) -> UserProfileJsonBlob {
        // If profile already has PersonaMode, return as-is
        // If it has legacy Blend, convert it
        
        // This would need to handle the actual migration logic
        // based on how the data is stored
        return profile
    }
}
```

## 5. Testing Strategy

### Performance Validation

**File:** `AirFitTests/AI/PersonaEnginePerformanceTests.swift`

```swift
class PersonaEnginePerformanceTests: XCTestCase {
    
    func test_promptGeneration_tokenReduction() throws {
        let engine = PersonaEngine()
        
        let prompt = try engine.buildSystemPrompt(
            personaMode: .supportiveCoach,
            userGoal: "Lose 15 pounds and feel more energetic",
            userContext: "Busy parent with unpredictable schedule",
            healthContext: createTestHealthContext(),
            conversationHistory: [],
            availableFunctions: []
        )
        
        let estimatedTokens = prompt.count / 4
        XCTAssertLessThan(estimatedTokens, 600, "Prompt should be under 600 tokens")
    }
    
    func test_promptGeneration_performance() throws {
        let engine = PersonaEngine()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<100 {
            _ = try engine.buildSystemPrompt(
                personaMode: .directTrainer,
                userGoal: "Build muscle",
                userContext: "Experienced lifter",
                healthContext: createTestHealthContext(),
                conversationHistory: [],
                availableFunctions: []
            )
        }
        
        let averageTime = (CFAbsoluteTimeGetCurrent() - startTime) / 100
        XCTAssertLessThan(averageTime, 0.001, "Should generate prompts in <1ms average")
    }
}
```

### User Experience Validation

**File:** `AirFitTests/Onboarding/PersonaSelectionTests.swift`

```swift
class PersonaSelectionTests: XCTestCase {
    
    func test_personaSelection_updatesViewModel() {
        let viewModel = OnboardingViewModel()
        
        viewModel.selectedPersonaMode = .analyticalAdvisor
        
        XCTAssertEqual(viewModel.selectedPersonaMode, .analyticalAdvisor)
        
        let profile = viewModel.buildUserProfile()
        XCTAssertEqual(profile.personaMode, .analyticalAdvisor)
    }
}
```

## 6. Success Metrics & Rollout

### Key Performance Indicators

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| **Token Usage** | ~2000 tokens/request | <600 tokens/request | System prompt analysis |
| **Code Complexity** | 374 lines of adjustments | <100 lines total | Line count |  
| **Prompt Generation Time** | Variable | <1ms average | Performance tests |
| **User Onboarding Time** | Complex sliders | Simple selection | User analytics |

### Rollout Strategy

**Phase 4a: Backend Migration (No User Impact)**
1. Implement PersonaMode enum and new PersonaEngine
2. Add migration utility for existing users  
3. Deploy alongside existing system (feature flag controlled)
4. Validate prompt quality and token usage in staging

**Phase 4b: Onboarding Simplification (Low Risk)**
1. Deploy new persona selection UI for new users only
2. A/B test: 30% get new selection, 70% get old sliders
3. Monitor completion rates and user satisfaction
4. Full migration after validation

**Phase 4c: Remove Legacy Code (Medium Risk)**
1. Migrate all existing users to PersonaMode
2. Remove Blend struct and adjustment methods
3. Switch all users to new PersonaEngine
4. Monitor for any persona experience degradation

### Success Validation

**User-Visible Improvements:**
- Simpler onboarding with clear persona choices
- Consistent coaching personality across sessions
- Faster response times due to reduced token usage
- No perceptible difference in coaching quality

## 7. Expected Outcomes

### Immediate Benefits
- **70% token reduction** (2000 → 600 tokens per request)
- **80% code reduction** (374 → ~80 lines in PersonaEngine)
- **Simpler onboarding** with intuitive persona selection
- **Faster prompt generation** with caching

### Long-term Benefits
- **Lower API costs** due to reduced token usage
- **Easier maintenance** without complex adjustment logic
- **Better user experience** with clearer persona choices
- **Foundation for future improvements** with simpler architecture

This phase eliminates genuine over-engineering while preserving the personalization that users value. The discrete personas will be just as effective as the complex mathematical blending, but much simpler to understand and maintain. 
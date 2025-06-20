# Onboarding Enhancement: Multi-Goal Intelligent System

**Status**: Design Phase  
**Priority**: High  
**Target**: MVP Perfect Implementation  
**UI Standards**: Implementing future patterns from `Docs/o3uiconsult.md`

## Executive Summary

Create a world-class onboarding experience that feels like a thoughtful conversation with a knowledgeable friend, not a configuration wizard. Every interaction should feel intentional, beautiful, and effortless.

**Vision**: Text-forward cinematic onboarding that gracefully handles API setup, intelligently uses HealthKit data, and synthesizes a personalized AI coach through natural conversation.

**Target Users**: Private use for family and friends - comprehensive AI health/fitness coach with medical guidance capabilities.

**Core Innovation**: Provider-aware API setup → Smart HealthKit prefilling → Conversational goal discovery → Visible AI synthesis = Thoughtfully personalized coach.

## CRITICAL ANALYSIS: Current State vs Vision Gap

### **🚨 FUNDAMENTAL PROBLEM: Form-Thinking vs Conversational Magic**

**Current Reality**: We've built sophisticated infrastructure but are using it like a fancy form builder instead of embracing LLM-powered conversational intelligence.

### **Architecture Overview**

**Two Sophisticated Onboarding Paths Coexist:**
1. **Legacy Mode** (structured screens, 9 screens) ← **Current Production Default**
2. **Conversational Mode** (AI-driven conversation flow) ← **Experimental/Advanced** [EXISTS BUT UNUSED]

### **🔥 CRITICAL ISSUES IDENTIFIED (June 14, 2025 Analysis)**

#### **1. Mutually Exclusive Selection Hell**
**Problem**: Everything is radio buttons when it should be inclusive
- **Goals**: "Pick ONE primary goal" instead of "I want to lose weight AND build muscle"
- **Coaching Style**: "Pick ONE persona" instead of "I like encouragement BUT also want data"
- **Sleep Patterns**: "Either consistent OR weekend-different" (why not both?)
- **Motivational Style**: "Subtle OR enthusiastic" (why not context-dependent?)

#### **2. Corporate-Speak Instead of Conversational Magic**
**Current Prompts (Boring & Rigid)**:
```
"Understanding your daily rhythm helps your coach provide relevant support. Tap what generally applies:"
```

**Should Be (Friendly & Conversational)**:
```
"Help me understand your day-to-day life so I can be the most helpful coach possible! 
What sounds like you? (Pick as many as you want)"
```

#### **3. Missing LLM-First Data Collection**
- **Weight**: Should be "What are your weight goals?" → LLM parses intent
- **Goals**: Should be "Tell me about your fitness aspirations" → LLM extracts structure  
- **Lifestyle**: Should be "Describe your daily rhythm" → LLM maps to coaching approach

#### **4. Placeholder Content Everywhere**
- Life Snapshot has corporate placeholder text
- Missing prompts throughout onboarding
- Generally sloppy, unfinished presentation

#### **5. Technical Issues Preventing Flow**
- **App crashes on "Begin"** - missing AI API key setup
- **No HealthKit authorization** early in flow  
- **Weight data isn't actually fetched** from HealthKit
- **Sleep data isn't prefilled** from HealthKit

#### **6. No Magic - Just Configuration**
**Current Experience**: "Fill out this 9-screen form to configure your fitness app"
**Should Be**: "Tell me about your fitness goals and I'll become the perfect coach for you"

### Current Onboarding Flow (Phase 4 Production)

```
Opening → Life Snapshot → Core Aspiration → Coaching Style → 
Engagement Preferences → Sleep & Boundaries → Motivational Accents → 
Generating Coach → Coach Profile Ready
```

### Current Goal System - More Sophisticated Than Initially Analyzed

**Goal.GoalFamily (5 well-designed starting points):**
- `strengthTone` - "Enhance Strength & Physical Tone"
- `endurance` - "Improve Cardiovascular Endurance"  
- `performance` - "Optimize Athletic Performance"
- `healthWellbeing` - "Cultivate Lasting Health & Wellbeing"
- `recoveryRehab` - "Support Injury Recovery & Pain-Free Movement"

**Key Discovery**: These are **starting points, not constraints**. The system uses:
- **Goal Family** for initial categorization
- **Raw Text** for user elaboration and specifics
- **Deep AI Integration** throughout coaching (goals referenced in all AI services)
- **Context Adaptation** that modifies coaching based on real-time health data

### Current PersonaMode System (Brilliant Architecture)

**Discrete Persona Approach** (4 personas):
- `supportiveCoach` - Encouraging, empathetic approach
- `directTrainer` - No-nonsense, results-focused
- `analyticalAdvisor` - Data-driven, educational
- `motivationalBuddy` - Energetic, social approach

**Intelligent Context Adaptation**: Each persona adapts real-time based on:
- Energy levels, stress, sleep quality, time of day
- Recovery status, workout streaks, health metrics
- User's current life context and goals

### Enhancement Opportunities (Refined Analysis)

**Current Strengths to Preserve:**
- ✅ Clean discrete persona architecture (vs complex mathematical blending)
- ✅ Real-time health data context adaptation
- ✅ Goals deeply integrated throughout AI coaching
- ✅ Dual onboarding paths (structured + conversational)
- ✅ Sub-5 second persona generation performance
- ✅ Progressive disclosure UX philosophy

**Refined Enhancement Areas:**
- 🎯 Graduate conversational mode from experimental to primary
- 🎯 Add goal milestone tracking and time-bound objectives
- 🎯 Enhanced goal sub-categorization (while keeping families)
- 🎯 Post-onboarding persona refinement capabilities
- 🎯 Expanded context adaptation rules with richer HealthKit data

## **🎯 SOLUTION: Smart Guided Conversations (Not Open-Ended Overwhelm)**

### **The Real Issue: Tone & Constraints, Not Structure**

**Key Insight**: Users CAN handle multiple choice, but not when it feels like medical intake. The problem isn't the format - it's the rigid constraints and corporate tone.

### **Strategy: Conversational Multi-Choice + Smart Defaults**

**✅ What Works**: Guided selection with friendly tone
**❌ What Doesn't**: Mutually exclusive radio buttons with corporate prompts  
**🎯 Sweet Spot**: "Pick as many as you want" + conversational language + smart defaults

### **Immediate Fix Strategy**

#### **1. Fix the Tone (Immediate Impact)**
Replace all placeholder text with friendly, conversational prompts that feel like talking to a knowledgeable friend, not filling out paperwork.

#### **2. Remove False Constraints (Medium Impact)**
- Convert radio buttons to checkboxes where it makes sense
- Add "something else" options everywhere  
- Let people combine coaching styles: "encouraging BUT data-driven"

#### **3. Smart Defaults + Customization (High Impact)**
- Use HealthKit data to prefill and ask "Does this look right?"
- LLM suggests combinations based on previous choices
- Progressive disclosure - start simple, get detailed if they want

### **Conversational Rewrite Examples**

#### **Life Snapshot (Before vs After)**
**❌ Current (Corporate)**:
```
"Understanding your daily rhythm helps your coach provide relevant support. Tap what generally applies:"
[Radio buttons - pick ONE]
```

**✅ Enhanced (Conversational)**:
```
"Help me understand your day-to-day life so I can be the most helpful coach possible! 
What sounds like you? (Pick as many as you want)"

✓ I'm stuck at a desk most of the day
✓ I'm on my feet a lot for work  
✓ I travel constantly (ugh, airport food!)
✓ I've got kids/family keeping me busy
✓ My schedule changes week to week
✓ Something else entirely → [text field: "Like what?"]
```

#### **Coaching Style (Before vs After)**
**❌ Current (Mutually Exclusive)**:
```
"Select your preferred coaching style:"
○ Supportive Coach
○ Direct Trainer  
○ Analytical Advisor
○ Motivational Buddy
```

**✅ Enhanced (Mix & Match)**:
```
"How do you like to be coached? I can be a combination of styles! 
(Pick all that sound good)"

✓ Encouraging and supportive ("You've got this!")
✓ Direct and no-nonsense ("Here's what needs to happen")
✓ Data-driven and analytical ("Let's look at the numbers")  
✓ Energetic and motivational ("Let's crush these goals!")
✓ Patient with setbacks ("Progress isn't always linear")
✓ Educational and explanatory ("Here's why this works")
✓ A little playful and fun ("Fitness doesn't have to be serious!")

[Skip: "Surprise me - figure out what works!"]
```

### **Refined Philosophy: "Gather Rich Context, Let LLM Do The Heavy Lifting"**

**Elegant guided conversations + sophisticated LLM synthesis:**
- **Keep**: Progressive disclosure + smart defaults + conversational tone
- **Fix**: Remove false constraints + add personality + use HealthKit data  
- **Enhance**: LLM synthesizes mixed preferences into coherent coaching approach

### Refined Goal Architecture

**Three Categories of Goals:**

#### **1. Weight Objectives (Data-Driven)**
```swift
struct WeightObjective: Codable, Sendable {
    let currentWeight: Double?        // From HealthKit
    let targetWeight: Double?         // User input
    let timeframe: TimeInterval?      // When they want to achieve it
    
    // Direction is calculated algorithmically
    var direction: WeightDirection {
        guard let current = currentWeight, let target = targetWeight else { return .maintain }
        return current < target ? .gain : current > target ? .lose : .maintain
    }
}
```

#### **2. Body Recomposition Goals (Structured)**
```swift
enum BodyRecompositionGoal: String, Codable, CaseIterable {
    case loseFat = "lose_fat"
    case gainMuscle = "gain_muscle" 
    case getToned = "get_toned"
    case improveDefinition = "improve_definition"
    case bodyRecomposition = "body_recomposition"  // Both lose fat + gain muscle
    
    var displayName: String {
        switch self {
        case .loseFat: return "Lose Body Fat"
        case .gainMuscle: return "Build Muscle Mass"
        case .getToned: return "Get More Toned"
        case .improveDefinition: return "Improve Muscle Definition"
        case .bodyRecomposition: return "Lose Fat While Building Muscle"
        }
    }
}
```

#### **3. Functional Goals (Free Text + LLM Magic)**
```swift
struct FunctionalGoals: Codable, Sendable {
    let rawText: String               // "Keep up with my kids", "Improve tennis game"
    let extractedGoals: [String]?     // LLM-parsed specific goals
    let context: String?              // LLM-inferred context and approach
}
```

### LLM-Centric Data Collection

**Streamlined Onboarding Raw Data:**
```swift
struct OnboardingRawData: Codable, Sendable {
    // Basic info
    let userName: String
    let lifeContextText: String                     // Free-form life situation description
    
    // Weight objectives (data-driven)
    let weightObjective: WeightObjective?
    
    // Body composition goals (structured multi-select)
    let bodyRecompositionGoals: [BodyRecompositionGoal]
    
    // Functional goals (free text - let LLM parse)
    let functionalGoalsText: String                 // "I want to keep up with my kids and improve my tennis game"
    
    // Communication preferences (mix & match)
    let communicationStyles: [CommunicationStyle]   // Multiple selections allowed
    let informationPreferences: [InformationStyle] // Multiple selections allowed
    
    // Rich health context
    let healthKitData: HealthKitSnapshot?
    let manualHealthData: ManualHealthData?         // Fallback if HealthKit unavailable
}

enum CommunicationStyle: String, Codable, CaseIterable {
    case encouraging = "encouraging_supportive"
    case direct = "direct_no_nonsense"  
    case analytical = "data_driven_analytical"
    case motivational = "energetic_motivational"
    case patient = "patient_understanding"
    case challenging = "challenging_pushing"
    case educational = "educational_explanatory"
    case playful = "playful_humorous"
}

enum InformationStyle: String, Codable, CaseIterable {
    case detailed = "detailed_explanations"
    case keyMetrics = "key_metrics_only"
    case celebrations = "progress_celebrations"
    case educational = "educational_content"
    case quickCheckins = "quick_check_ins"
    case inDepthAnalysis = "in_depth_analysis"
    case essentials = "just_essentials"
}

struct ManualHealthData: Codable, Sendable {
    let weight: Double?
    let height: Double?
    let age: Int?
    let sleepSchedule: SleepSchedule?
}
```

## Enhanced Onboarding Flow Design

### Executive Vision: Text-Forward Cinematic Onboarding

We're creating an onboarding experience that feels like a thoughtful conversation, not a configuration wizard. Drawing from Adaline.ai's cinematic UI principles, every screen has a single focal point, transitions convey progress through gradient evolution, and the typography-first design creates calm confidence.

**Core Principles:**
- **API Key First**: Without it, nothing works - make it feel essential, not technical
- **HealthKit as Context**: Use existing data to make the conversation smarter
- **Progressive Disclosure**: Start simple, get detailed only if needed
- **LLM Intelligence**: Let AI handle complexity while keeping UI minimal
- **Gradient as Navigation**: Each screen advances the gradient, creating journey sense

### Streamlined, LLM-Centric Flow

**Revised Flow Structure:**
```
API Key Setup (Pre-Onboarding) → Opening → HealthKit Authorization → 
Life Context → Goals (Progressive) → Communication Preferences → 
LLM Synthesis → Coach Profile Ready
```

**Note**: API Key Setup happens BEFORE onboarding begins via `InitialAPISetupView`. The onboarding flow itself starts with the Opening screen.

### Design Philosophy: Text-Forward Beautiful Minimalism

Drawing from cinematic UI principles (`Docs/o3uiconsult.md` - Adaline.ai analysis):
- **Ultra-clean typography**: Large display text, wide tracking, sparse copy
- **Motion as information**: Transitions convey progress, not decoration
- **Single focal points**: One primary element per screen builds trust
- **Gradient evolution**: Subtle shifts between screens create journey sense
- **No avatars or imagery**: Pure text and color create focus
- **Calm pastels**: Soothing gradients that evolve with user progress

### Critical Sequencing Decision: API Key as Prerequisite

Without the API key, the entire LLM-powered experience fails. The app requires API setup before onboarding can begin, handled by `InitialAPISetupView` as a separate pre-onboarding step.

**Why This Order Works:**
1. **API Key Setup** (Pre-requisite): Handled by `InitialAPISetupView` before onboarding
2. **Opening**: Welcome screen begins the actual onboarding journey
3. **HealthKit**: Provides rich context before any questions
4. **Life Context**: Natural conversation enriched by health data
5. **Goals**: Progressive from free-text to structured options
6. **Preferences**: Quick multi-select for coaching style
7. **Synthesis**: Visible AI magic creates anticipation

### Screen-by-Screen Design (Text-Forward Minimalism)

#### Screen 0: Pre-Onboarding API Setup (Separate Flow)
```swift
// ContentView handles the flow:
if appState.shouldShowAPISetup {  // needsAPISetup == true
    InitialAPISetupView {  // Separate API setup screen
        appState.completeAPISetup()
        // Recreate DI container with new API key
    }
} else if appState.shouldShowOnboarding {
    OnboardingFlowViewDI()  // Actual onboarding starts here
}
```

**Important**: `InitialAPISetupView` is NOT part of the onboarding flow. It's a prerequisite handled by AppState before onboarding can begin. This screen should also follow the o3uiconsult.md UI patterns:
- Text directly on gradient background
- CascadeText for "Let's connect your AI coach"
- Minimal design with provider selection (radio buttons)
- Real-time validation with visual feedback
- GlassSheet only for the text input field (if contrast requires)

#### Screen 1: Opening (First Onboarding Screen)
```
[Soft gradient background - peachRose]
[CascadeText animation - 0.6s total]

"Welcome to AirFit"

[Minimal subtitle after cascade completes]
"Your personal AI fitness coach"

[Single button - appears with subtle fade after 0.8s]
"Let's begin"

[Micro-interaction: button subtly pulses every 3s]
[Tap feedback: HapticService.impact(.light)]
```

**Note**: API Key setup has already been completed via `InitialAPISetupView` before reaching this screen.

#### Screen 2: HealthKit Authorization
```
[Gradient advance to coralSunset - 0.8s cross-fade]
[CascadeText]

"Let's connect your AI coach"

[Provider selection - minimal radio group]
"Choose your AI provider"

[○] Claude (Anthropic)
[●] Gemini (Google) - PRE-SELECTED
[○] GPT-4 (OpenAI)

[Dynamic helper text based on selection]
Gemini: "Free tier available • Fast responses"
Claude: "Best for natural conversation"
GPT-4: "Most versatile • Requires subscription"

[Input field appears with subtle slide-in after selection]
[Paste your Gemini API key]

[Helper links - small, understated]
"How do I get a key?" • "Why do I need this?"

// Real-time validation states:
// Empty: Normal border
// Typing: Subtle pulse on border
// Valid format: Green checkmark appears in field
// Invalid format: Red X with helpful message

// Connection test flow:
"Connecting to Gemini..." [subtle loading dots]
"✓ Connected successfully" [gradient border glow]

// Error states:
"That doesn't look like a Gemini key"
"Connection failed - check your key"
"This looks like a Claude key - switch providers?"

[Continue button - disabled until connected]
[Text changes: "Continue" → "Continue with Gemini"]
```

#### Screen 3: Life Context (Conversational)
```
[Gradient advance to oceanBreeze]
[CascadeText]

"Now, let's sync your health data"

[Subtle explanation - appears after 1s]
"This helps me understand your baseline"

[Single button]
"Connect Apple Health"

// HealthKit permission dialog appears
// Request only essential permissions:
// - Activity (steps, workouts)
// - Body measurements (weight, height)
// - Sleep analysis
// - Heart (resting heart rate)

// After authorization:
[Data animates in with staggered timing]
"Great! Here's what I found:"

[Actual data in clean typography]
"Weight: 180 lbs • Height: 5'10""
"Sleep: 7.5 hrs avg • Steps: 12,000 daily"
"Resting HR: 62 bpm • 3 workouts this week"

// Or if minimal data:
"Let's start with the basics"
"Weight: 180 lbs"

// Or if no data:
"No problem, we'll figure it out together"

[Continue button appears after data display]
```

#### Screen 4: Goals - Progressive Approach
```
[Gradient advance to lavenderDream]
[CascadeText]

"Tell me about your daily life"

[Large text area with generous padding]
[Placeholder text in light gray:]
"I work from home, have two kids..."

[Voice input button - subtle mic icon]
[Tap to toggle voice input]

// Smart prompting based on HealthKit:
If low step count:
"I noticed you're not moving much - tell me about your work"

If irregular sleep:
"Your sleep varies a lot - what's your schedule like?"

If frequent workouts:
"You're pretty active! Tell me about your routine"

[Character count: 0/500 - very subtle]

[Skip option - small, bottom of screen]
"Skip for now"

// Voice input UX:
[Mic button] → [Recording indicator + waveform]
"Listening..." → "Processing..." → [Text appears]
```
**LLM extracts:** Schedule patterns, constraints, equipment access, lifestyle factors, timing preferences, stress indicators

#### Screen 5: Communication Style (Mix & Match)
```
[Gradient advance to mintBreeze]
[CascadeText]

"What would you like to achieve?"

[Text input with smart placeholder based on HealthKit:]
High BMI: "Lose weight, feel healthier..."
Low activity: "Get more active, build strength..."
Good baseline: "Take my fitness to the next level..."

// After user types (AI parsing in background):
[Smooth transition to checkboxes]

"I heard: lose 20 pounds. What else?"

□ Build muscle definition
□ Improve cardio endurance
□ Have more energy
□ Sleep better
□ Reduce stress
□ Something else: [text field]

[Selected items get gradient accent]
[Real-time validation: warn if goals conflict]

"Note: Building muscle while losing weight 
requires a careful approach - I'll help!"

[Continue - shows selected count]
"Continue with 3 goals"
```

#### Screen 6: LLM Synthesis (Make the Magic Visible)
```
[Gradient advance to sunsetGlow]
[CascadeText]

"How do you like to be coached?"

[Subtitle fades in]
"I can adapt - pick what resonates"

[Elegant checkbox list with descriptions]
□ Encouraging
  "Celebrate wins, stay positive"
  
□ Direct  
  "No fluff, just what needs doing"
  
□ Data-focused
  "Numbers, trends, and insights"
  
□ High energy
  "Let's go! Maximum motivation"
  
□ Patient
  "Progress isn't always linear"
  
□ Educational
  "Understand the why behind everything"

[Smart defaults based on goals:]
Weight loss: Pre-check Encouraging + Patient
Performance: Pre-check Direct + Data-focused

[Bottom option]
"Surprise me - adapt as we go"

[Visual feedback: selected items glow softly]
```

#### Screen 7: Coach Profile Ready
```
[Gradient cycles through 3-4 colors rapidly]
[Background subtly pulses with "thinking" effect]

"Creating your personalized coach..."

[Processing steps appear with timing]
0.5s: "Analyzing your health data..."
1.5s: "Understanding your lifestyle..."
2.5s: "Designing your program..."
3.5s: "Personalizing communication style..."

[Each line fades up and glows briefly]

// Error handling:
If synthesis fails:
"Taking a bit longer than expected..."
[Retry automatically once]
[If still fails: "Let's continue - I'll personalize as we go"]

[Success screen - 4s after start]
[Gradient settles on user's "home" color]

"Your AI coach is ready"

[Generated summary - concise, powerful]
"I'm your analytical yet encouraging coach, 
focused on helping you lose weight while 
building strength. I'll adapt to your busy 
schedule and celebrate every victory."

[Two buttons]
"Let's get started" (primary)
"Tell me more" (secondary)
```

### Implementation Excellence (Zero Technical Debt)

#### Typography System
```swift
enum OnboardingTypography {
    static let hero = Font.system(size: 34, weight: .medium, design: .rounded)
        .tracking(0.5)
    static let subtitle = Font.system(size: 20, weight: .regular, design: .rounded)
        .tracking(0.2)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let helper = Font.system(size: 15, weight: .regular, design: .rounded)
        .opacity(0.7)
    static let input = Font.system(size: 20, weight: .regular, design: .default)
}
```

#### Animation Timings
```swift
enum OnboardingMotion {
    static let cascadeTotal: TimeInterval = 0.6
    static let cascadePerChar: TimeInterval = 0.012
    static let screenTransition: TimeInterval = 0.55
    static let gradientCrossfade: TimeInterval = 0.8
    static let elementFadeIn: TimeInterval = 0.3
    static let buttonPulse: TimeInterval = 3.0
    static let synthesisCycle: TimeInterval = 0.7
}
```

#### Gradient Evolution
- Each screen advances gradient by one token
- Synthesis screen cycles through 3-4 gradients rapidly
- Creates sense of journey and progression
- Final gradient becomes the user's "home" gradient

#### Minimal Chrome
- No cards except where contrast requires (API key input)
- Text sits directly on gradient background
- Single primary button per screen
- Progress shown through gradient evolution, not progress bars
- Skip options are small, understated links

#### Transitions (from o3 principles)
```swift
struct OnboardingTransition: NavigationTransition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .opacity(phase == .identity ? 1 : 0)
            .scaleEffect(phase == .identity ? 1 : 0.94)
            .blur(radius: phase == .identity ? 0 : 4)
            .animation(.easeInOut(duration: 0.55), value: phase)
    }
}
```

### Data Collection Philosophy

#### What We Explicitly Collect
1. **API Key + Provider** - Required for AI functionality
2. **HealthKit Permissions** - Baseline health metrics
3. **Life Context** - 1-2 sentences of free text
4. **Primary Goals** - Free text + smart suggestions
5. **Coaching Style** - 2-3 preferences from 6 options

#### What the LLM Infers
```swift
struct LLMInferences {
    // From life context:
    let schedule: WorkSchedule           // "work from home" → flexible
    let constraints: [String]            // "two kids" → time-limited
    let equipment: EquipmentAccess       // "apartment" → minimal
    
    // From goals + health data:
    let program: FitnessProgram         // Weight loss + low activity → gradual
    let milestones: [Milestone]         // Realistic based on starting point
    let risks: [HealthRisk]             // BMI + age + activity → considerations
    
    // From communication preferences:
    let tone: CoachingTone              // Encouraging + patient → supportive
    let detailLevel: DetailLevel        // Data-focused → comprehensive
    let motivationalStyle: Style        // High energy → enthusiastic
}
```

#### Quality Over Speed
We prioritize thoughtful responses over rushed configuration:
- Let users take their time with life context
- Encourage reflection on goals
- No timers or progress bars
- Focus on getting it right, not getting it done

### Component Usage Clarification

**From Current UI Standards (`UI_STANDARDS.md`):**
- CascadeText - Use for all headings
- BaseScreen - Use for gradient backgrounds
- GradientManager - Use for gradient evolution
- MotionToken - Use for animation timings

**From Future UI Transformation (`o3uiconsult.md`):**
- GlassSheet (not GlassCard) - 4pt blur, use sparingly
- ChapterTransition - 0.55s navigation transitions
- Text directly on gradients - No cards unless contrast < 4.5:1
- StoryScroll - For multi-section screens (optional)

**Do NOT Use:**
- StandardCard - Deprecated
- GlassCard - Being replaced with GlassSheet
- Any card-based layouts unless absolutely necessary

### Visual Design System

#### Color Palette
```swift
struct OnboardingColors {
    // Text hierarchy
    static let primaryText = Color.primary
    static let secondaryText = Color.primary.opacity(0.7)
    static let tertiaryText = Color.primary.opacity(0.5)
    static let placeholderText = Color.primary.opacity(0.3)
    
    // Interactive elements  
    static let inputBackground = Color.white.opacity(0.1)
    static let inputBorder = Color.primary.opacity(0.2)
    static let inputBorderFocused = GradientManager.shared.accent
    
    // Feedback states
    static let successGreen = Color(hex: "34C759")
    static let errorRed = Color(hex: "FF3B30")
    static let warningOrange = Color(hex: "FF9500")
    
    // Special effects
    static let glowColor = GradientManager.shared.accent.opacity(0.3)
    static let pulseColor = Color.white.opacity(0.8)
}
```

#### Component Library
```swift
// Reusable onboarding components
struct OnboardingButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(OnboardingTypography.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(backgroundGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: shadowColor, radius: 8, y: 4)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct OnboardingTextField: View {
    @Binding var text: String
    let placeholder: String
    let validation: (String) -> Bool
    
    var body: some View {
        // Elegant input with real-time validation
    }
}

struct OnboardingCheckbox: View {
    @Binding var isSelected: Bool
    let label: String
    let description: String?
    
    var body: some View {
        // Beautiful checkbox with optional description
    }
}
```

#### Motion & Timing
- CascadeText: 0.60s total, 0.012s per character stagger
- Screen transitions: 0.55s ease-in-out with slight scale
- Gradient advances: 0.8s cross-fade
- Input field animations: 0.3s for focus states
- Success feedback: 0.2s for checkmark appearance

#### Spacing & Layout
- Top padding: 120pt (accounts for Dynamic Island)
- Horizontal padding: 24pt
- Vertical spacing between elements: 32pt
- Button height: 56pt with 16pt corner radius
- Input field height: 56pt with 12pt corner radius

### API Key Setup - Production Implementation

#### State Machine
```swift
@MainActor
class APIKeySetupViewModel: ObservableObject {
    @Published var state: SetupState = .selectingProvider
    @Published var selectedProvider: AIProvider = .gemini
    @Published var apiKey: String = ""
    @Published var isValidFormat: Bool = false
    @Published var connectionStatus: ConnectionStatus = .none
    
    enum SetupState {
        case selectingProvider
        case enteringKey
        case validating
        case connected
        case error(LocalizedError)
    }
    
    enum ConnectionStatus {
        case none
        case checking
        case success
        case failure(reason: String)
    }
    
    // Real-time validation
    func validateKeyFormat(_ key: String) {
        isValidFormat = selectedProvider.keyValidationRule(key)
        
        // Smart provider detection
        if !isValidFormat {
            if let detectedProvider = detectProvider(from: key) {
                suggestedProvider = detectedProvider
            }
        }
    }
    
    // Test connection with actual LLM provider
    func testConnection() async {
        state = .validating
        connectionStatus = .checking
        
        do {
            // Save temporarily for validation
            try await apiKeyManager.saveAPIKey(apiKey, for: selectedProvider)
            
            // Test with actual provider
            let orchestrator = try await container.resolve(LLMOrchestrator.self)
            try await orchestrator.configure()
            
            // Quick test request
            let response = try await orchestrator.complete(
                prompt: "Say 'connected' if you can read this",
                task: .quickResponse,
                model: selectedProvider.defaultModel
            )
            
            if response.content.lowercased().contains("connected") {
                state = .connected
                connectionStatus = .success
            } else {
                throw AppError.llm("Invalid response from provider")
            }
        } catch {
            // Clean up invalid key
            try? await apiKeyManager.deleteAPIKey(for: selectedProvider)
            
            state = .error(error)
            connectionStatus = .failure(reason: error.localizedDescription)
        }
    }
}
```

#### Provider-Specific Details
```swift
extension AIProvider {
    var onboardingDescription: String {
        switch self {
        case .anthropic:
            return "Claude - Best for conversational AI"
        case .openAI:
            return "GPT-4 - Versatile and powerful"
        case .gemini:
            return "Gemini - Fast & free tier available"
        }
    }
    
    var keyValidationRule: (String) -> Bool {
        switch self {
        case .anthropic:
            return { $0.hasPrefix("sk-ant-") && $0.count > 40 }
        case .openAI:
            return { $0.hasPrefix("sk-") && $0.count > 40 }
        case .gemini:
            return { $0.count > 30 }
        }
    }
}
```

#### Connection Test Flow
1. User selects provider (default: Gemini)
2. User pastes key → Provider-specific format validation
3. If format valid → Show "Connecting to [Provider]..." 
4. Use LLMOrchestrator to validate with specific provider
5. On success → Gradient border + "✓ Connected successfully"
6. On failure → Red tint + provider-specific error message

#### Error Messages (User-Friendly)
- Invalid format: "That doesn't look like a valid [Provider] API key"
- Connection failed: "Couldn't connect to [Provider]. Check your key and try again"
- Rate limited: "This key has reached its [Provider] limit"
- Network error: "Connection issue. Please check your internet"
- Wrong provider: "This looks like a [DetectedProvider] key. Switch providers?"

### LLM Goal Synthesis (Background)
```
After user completes goal inputs, LLM processes:

INPUT:
- Life Context: "Work from home, two kids under 10, travel 2x/month, prefer 6am workouts"
- Weight: Current 180lbs → Target 165lbs (6 months)
- Body Comp: [Lose Fat, Build Muscle] 
- Functional: "Keep up with my kids (ages 6,8) and improve tennis game"
- Communication: [Encouraging, Analytical, Educational]
- Information: [Key metrics, Educational content, Progress celebrations]
- Health Data: [HealthKit snapshot]

LLM SYNTHESIS OUTPUT:
- Parsed life constraints: ["Home-based workouts", "Travel-friendly routines", "Early morning availability", "Child-centered motivation"]
- Communication blend: "Encouraging tone with data-driven explanations and educational context"
- Information delivery: "Key progress metrics with educational context and milestone celebrations"
- Parsed functional goals: ["Parental energy/stamina", "Tennis performance", "Overall fitness"]
- Goal relationships: "Weight loss + muscle building = body recomposition focus"
- Unified strategy: "Efficient home/hotel workouts focusing on functional strength and cardiovascular endurance"
- Timeline: "12-week body recomp cycles, tennis skills parallel track"
- Coaching focus: ["Energy optimization", "Efficient 30-min workouts", "Travel adaptability", "Parent-specific motivation"]
```

### LLM Goal Synthesis Prompt

#### **Comprehensive Goal Analysis Prompt**
```swift
"""
Analyze this user's fitness context and create their comprehensive health & fitness strategy:

USER PROFILE:
- Name: {userName}
- Life Context: "{lifeContextText}"
- Weight Goal: {weightObjective}
- Body Composition: {bodyRecompositionGoals}
- Functional Goals: "{functionalGoalsText}"
- Communication Styles: {communicationStyles}
- Information Preferences: {informationPreferences}
- Health Data: {healthKitSnapshot}

COACHING SCOPE: You are a comprehensive AI health & fitness coach with medical knowledge. You can:
- Provide medical advice related to fitness and health
- Suggest injury recovery protocols and pain management
- Recommend supplements and detailed nutrition guidance
- Analyze symptoms in fitness/health context
- Guide users through health optimization strategies
- Address mental health aspects of fitness journey

TASKS:
1. Parse life context into actionable constraints and preferences
2. Blend communication styles into coherent coaching personality
3. Define information delivery approach based on preferences
4. Parse functional goals into specific, actionable objectives
5. Identify goal relationships (synergistic/competing/sequential)
6. Create unified coaching strategy that balances all objectives
7. Set realistic timelines and milestones
8. Suggest specific coaching approach and focus areas
9. Identify potential health considerations and monitoring needs

RETURN STRUCTURED JSON:
{
  "parsedLifeConstraints": ["string"],
  "communicationBlend": "string description of blended style",
  "informationDelivery": "string description of content approach",
  "parsedFunctionalGoals": [{"goal": "string", "context": "string", "measurable": "string"}],
  "goalRelationships": [{"type": "synergistic|competing|sequential", "description": "string"}],
  "unifiedStrategy": "string",
  "recommendedTimeline": "string", 
  "coachingFocus": ["string"],
  "healthMonitoring": ["string - health aspects to monitor"],
  "milestones": [{"description": "string", "timeframe": "string"}],
  "expectedChallenges": ["string"],
  "motivationalHooks": ["string"],
  "adaptivePersonaPrompt": "string - comprehensive system prompt incorporating all synthesis"
}

DISCLAIMER: Include appropriate medical disclaimer in persona prompt about AI-generated advice and encouraging professional consultation for serious health concerns.
"""
```

#### **Adaptive Goal Management**
```swift
"""
Analyze this user's fitness progress and suggest goal adjustments:

CURRENT SYNTHESIS:
{currentGoalSynthesis}

PROGRESS DATA:
- Weight: {progressData.weightChange} 
- Workouts completed: {progressData.workoutsCompleted}/{progressData.workoutsPlanned}
- Consistency: {progressData.consistencyScore}%
- User feedback: "{recentFeedback}"

LIFE CONTEXT CHANGES:
{detectedLifeChanges}

ENGAGEMENT PATTERNS:
{userEngagementAnalysis}

RESPONSE FORMAT: If adjustments needed, return JSON:
{
  "adjustmentsNeeded": true,
  "confidenceScore": 0.8,
  "recommendations": [
    {
      "type": "timeline|intensity|focus|newGoal|communication",
      "reason": "Clear explanation based on data", 
      "suggestion": "Specific change to make",
      "userMessage": "How to present this change to user",
      "urgency": "low|medium|high"
    }
  ],
  "notificationStrategy": {
    "shouldSend": true,
    "tone": "celebratory|encouraging|checking-in|motivational",
    "timing": "immediate|next-interaction|weekly-check",
    "content": "specific message to send"
  }
}

If no adjustments needed, return: {"adjustmentsNeeded": false, "confidenceScore": 0.9}
"""
```

## Adaptive Intelligence Implementation Strategy

### Overview: Conservative, User-Controlled Learning System

The adaptive intelligence system uses objective triggers and user-initiated adjustments to improve coaching over time, avoiding brittle conversational analysis while maintaining safety and user control.

### Core Architecture

#### **1. Conservative Trigger System (Robust & Objective)**
```swift
enum RobustAdaptiveTrigger {
    // Objective data changes (unambiguous)
    case healthKitSignificantChange(HealthKitDelta)  // Weight change >5lbs, sleep shift >1hr
    case progressMilestone(achieved: Bool, goal: String)  // Clear goal completion/failure
    case engagementDrop(daysInactive: Int)           // 7+ days without interaction
    
    // Time-based (predictable costs)
    case weeklyReview                                // Every Sunday - scheduled analysis
    case monthlyGoalCheck                           // Comprehensive monthly review
    
    // User-initiated (explicit intent)
    case userRequestedReview                        // "Review my goals" button
    case userReportedLifeChange                     // "My situation changed" flow
    case userPersonaAdjustmentRequest               // Settings-based persona changes
}

struct AdaptiveReviewContext {
    let trigger: RobustAdaptiveTrigger
    let daysSinceLastReview: Int
    let progressData: ProgressSnapshot
    let healthKitDeltas: HealthKitDelta             // Objective data only
    let engagementMetrics: SimpleEngagementAnalysis // Basic usage patterns
}
```

#### **2. User-Initiated Persona Adjustment System**
```swift
struct PersonaAdjustmentProcessor {
    func processAdjustmentRequest(_ request: String, user: User) async -> AdjustmentResult {
        // Stage 1: Simple safety screening (no medical restrictions)
        let safetyCheck = await screenForSafetyViolations(request)
        guard safetyCheck.isSafe else {
            return .rejected(reason: safetyCheck.violation)
        }
        
        // Stage 2: Generate adjusted persona
        let adjustment = await generatePersonaAdjustment(request, currentPersona: user.persona)
        
        return .success(adjustment)
    }
    
    private func screenForSafetyViolations(_ request: String) async -> SafetyResult {
        let safetyPrompt = """
        Screen this user request for safety violations:
        
        Request: "{request}"
        
        Reject if request asks for:
        - Non-fitness/health related functionality
        - Inappropriate content or behavior
        - Breaking out of comprehensive health coach role
        
        Medical/health advice is ALLOWED and encouraged.
        
        Return: SAFE or UNSAFE with brief reason
        """
    }
}

enum AdjustmentType {
    case communicationTone          // "Be more encouraging"
    case dataEmphasis              // "Less focus on numbers"
    case medicalGuidance           // "Help me understand symptoms"
    case injuryManagement          // "Guide me through recovery"
    case nutritionAdvice           // "More detailed meal guidance"
    case supplementRecommendations // "Suggest supplements"
    case motivationalApproach      // "More patient with setbacks"
    case explanationDetail         // "Simpler explanations"
}
```

#### **3. Predictable Cost Management**
```swift
struct PredictableAdaptiveSystem {
    // Weekly review - scheduled and budgeted
    func weeklyGoalReview(user: User) async {
        let context = buildWeeklyContext(user)
        let analysis = await performScheduledAnalysis(context)
        // Cost: ~800 tokens per user per week (predictable)
    }
    
    // Monthly deep dive - comprehensive review
    func monthlyStrategyReview(user: User) async {
        let context = buildMonthlyContext(user)
        let analysis = await performComprehensiveAnalysis(context)
        // Cost: ~1500 tokens per user per month (budgeted)
    }
    
    // User-initiated adjustments - as needed
    func processPersonaAdjustment(_ request: String, user: User) async {
        // Cost: ~600 tokens per adjustment (user-controlled frequency)
    }
}
```

### Simplified Implementation Strategy

#### **MVP Approach: Conservative & User-Controlled**
Focus on reliable, objective triggers and user-initiated adjustments rather than complex conversational analysis.

**Core Components:**

1. **Settings-Based Persona Adjustment**
```swift
// Settings menu integration for persona modifications
struct PersonaAdjustmentView: View {
    @State private var adjustmentRequest: String = ""
    
    var body: some View {
        VStack {
            Text("Adjust Your AI Coach")
                .font(.headline)
            
            Text("Describe what you'd like to change about your coach's approach:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $adjustmentRequest)
                .frame(minHeight: 100)
                .placeholder("I'd like my coach to be more encouraging, provide more medical guidance, focus less on data...")
            
            Button("Request Adjustment") {
                submitAdjustmentRequest()
            }
            .disabled(adjustmentRequest.isEmpty)
        }
    }
}
```

2. **Scheduled Reviews (Predictable Costs)**
```swift
class ScheduledReviewManager {
    // Sunday weekly reviews - users expect these
    func performWeeklyReview(user: User) async {
        let weeklyContext = buildWeeklyProgressContext(user)
        let suggestions = await generateWeeklySuggestions(weeklyContext)
        await presentSuggestionsToUser(suggestions, user: user)
    }
    
    // Monthly goal strategy reviews
    func performMonthlyGoalReview(user: User) async {
        let monthlyContext = buildComprehensiveContext(user)
        let strategicRecommendations = await generateStrategicRecommendations(monthlyContext)
        await requestUserApprovalForChanges(strategicRecommendations, user: user)
    }
}
```

3. **Objective Trigger Detection**
```swift
class ObjectiveTriggerDetector {
    func detectSignificantChanges(user: User) async -> [RobustAdaptiveTrigger] {
        var triggers: [RobustAdaptiveTrigger] = []
        
        // HealthKit changes (clear thresholds)
        if let weightChange = await detectWeightChange(user), abs(weightChange) >= 5.0 {
            triggers.append(.healthKitSignificantChange(.weightChange(weightChange)))
        }
        
        // Engagement patterns (simple metrics)
        let daysInactive = await getDaysInactive(user)
        if daysInactive >= 7 {
            triggers.append(.engagementDrop(daysInactive: daysInactive))
        }
        
        // Progress milestones (clear goal completion/failure)
        if let milestone = await checkProgressMilestones(user) {
            triggers.append(.progressMilestone(achieved: milestone.achieved, goal: milestone.goalName))
        }
        
        return triggers
    }
}
```

### Benefits of Conservative Approach

#### **1. Predictable & Reliable**
- **90% of adaptations:** Scheduled reviews (weekly/monthly) with known costs
- **10% of adaptations:** User-initiated changes with explicit intent
- **No false positives:** Only objective, unambiguous triggers
- **User control:** All major changes require explicit user approval

#### **2. Cost Management**
```swift
struct AdaptiveCostTracker {
    // Predictable weekly costs
    let weeklyReviewCost = 800    // tokens per user
    let monthlyReviewCost = 1500  // tokens per user
    
    // User-controlled costs
    let personaAdjustmentCost = 600  // tokens per adjustment
    
    func estimateMonthlyBudget(users: Int) -> Int {
        let scheduledCosts = users * (weeklyReviewCost * 4 + monthlyReviewCost)
        let estimatedAdjustments = users * 2  // Average 2 persona adjustments per user per month
        let adjustmentCosts = estimatedAdjustments * personaAdjustmentCost
        
        return scheduledCosts + adjustmentCosts
    }
}
```

#### **3. User Agency & Transparency**
- Users know exactly when reviews happen (Sundays, monthly)
- Clear persona adjustment interface in Settings
- Explicit approval required for all strategy changes
- Full rollback capability for any modification

### Monitoring & Quality Assurance

#### **1. Effectiveness Tracking**
```swift
struct AdaptationEffectivenessTracker {
    func measureImpact(of change: AdaptiveChange, after period: TimeInterval) async -> EffectivenessScore {
        let beforeMetrics = change.beforeState.engagementMetrics
        let afterMetrics = await getCurrentEngagementMetrics(change.userId)
        
        return EffectivenessScore(
            engagementDelta: afterMetrics.engagement - beforeMetrics.engagement,
            satisfactionDelta: afterMetrics.satisfaction - beforeMetrics.satisfaction,
            progressDelta: afterMetrics.progress - beforeMetrics.progress,
            confidenceInMeasurement: calculateConfidence(period)
        )
    }
}
```

#### **2. Anomaly Detection**
```swift
struct AdaptationAnomalyDetector {
    func detectAnomalies(in recommendations: [AdaptiveRecommendation]) -> [AnomalyAlert] {
        var alerts: [AnomalyAlert] = []
        
        // Check for conflicting recommendations
        if hasConflictingGoalChanges(recommendations) {
            alerts.append(.conflictingGoals(recommendations))
        }
        
        // Check for too-aggressive changes
        if hasTooAggressiveChanges(recommendations) {
            alerts.append(.aggressiveChanges(recommendations))
        }
        
        // Check for pattern breaks
        if breaksEstablishedPatterns(recommendations) {
            alerts.append(.patternBreak(recommendations))
        }
        
        return alerts
    }
}
```

### Technical Implementation Details

#### **Prompt Engineering for Structured Output**
```swift
let adaptiveAnalysisPrompt = """
Analyze this user's fitness journey and suggest improvements:

{contextData}

CRITICAL INSTRUCTIONS:
1. Only suggest changes you are highly confident about (>0.8 confidence)
2. Explain your reasoning clearly
3. Consider user's established preferences and patterns
4. Suggest no more than 2 major changes at once

RESPONSE FORMAT (REQUIRED):
{
  "confidenceScore": 0.85,
  "reasoning": "Based on 3 weeks of consistent progress...",
  "recommendations": [
    {
      "type": "timeline|intensity|focus|communication|notification",
      "description": "Specific change to make",
      "reason": "Why this change is beneficial",
      "riskLevel": "low|medium|high",
      "expectedImpact": "What we expect to happen",
      "userMessage": "How to explain this to the user"
    }
  ],
  "uncertaintyAreas": ["areas where more data is needed"],
  "suggestedMonitoring": ["metrics to watch after change"]
}
"""
```

This adaptive intelligence system provides a careful, user-controlled approach to evolving the AI coach while maintaining safety and transparency. The gradual implementation allows us to build confidence in the system before enabling more autonomous behavior.

### Intelligent Adaptation System

#### HealthKit-Driven Personalization
```swift
struct HealthKitInsights {
    let activityLevel: ActivityLevel     // Sedentary → Very Active
    let sleepQuality: SleepQuality       // Poor → Excellent
    let consistency: WorkoutConsistency   // Sporadic → Daily
    let recentTrends: HealthTrends       // Improving/Stable/Declining
    
    var suggestedGoals: [String] {
        switch (activityLevel, sleepQuality) {
        case (.sedentary, .poor):
            return ["Start moving more", "Improve sleep quality"]
        case (.active, .poor):
            return ["Maintain activity", "Optimize recovery"]
        case (.veryActive, .excellent):
            return ["Performance optimization", "New challenges"]
        default:
            return ["Balanced fitness", "Overall health"]
        }
    }
    
    var contextPrompts: [String] {
        // Personalized prompts based on data
        var prompts: [String] = []
        
        if activityLevel == .sedentary {
            prompts.append("I see you're not moving much - tell me about your work")
        }
        
        if sleepQuality == .poor {
            prompts.append("Your sleep seems irregular - what's your schedule like?")
        }
        
        if consistency == .daily {
            prompts.append("You're crushing it! What motivates you?")
        }
        
        return prompts
    }
}
```

#### Progressive Enhancement
```
Rich Data → Skip basic questions → Focus on nuance
Some Data → Prefill known info → Ask about gaps  
No Data → Full conversational flow → Build from scratch
```

#### Minimal Data Scenario (New to HealthKit)
```
"Let's get some baseline information"

// Collect basic metrics manually
// Explain benefits of HealthKit integration
// Offer to set up tracking post-onboarding
```

#### Partial Data Scenario (Some HealthKit Usage)
```
"I found some of your health data"
"Weight: 180 lbs • Let me know about your activity level"

// Use what's available
// Ask only for missing pieces
// Smooth experience regardless of data availability
```

## Implementation Strategy (Pre-MVP: Build Perfect Version)

Since we're **pre-MVP with zero users**, we'll implement the complete, perfected system from day one. No phases, no gradual rollouts - just build it right.

### Complete Implementation Scope

**Data Structures:**
- ✅ Create all new goal data structures: `WeightObjective`, `BodyRecompositionGoal`, `FunctionalGoals`
- ✅ Create `OnboardingRawData` structure for LLM input
- ✅ Create `LLMGoalSynthesis` structure for LLM output
- ✅ Remove old `Goal.GoalFamily` approach entirely

**Enhanced Onboarding Flow:**
- ✅ Replace current Core Aspiration screen with 3 new goal screens
- ✅ Implement Weight Goals screen with HealthKit integration
- ✅ Implement Body Composition Goals multi-select screen
- ✅ Implement Functional Goals free-text + voice input screen
- ✅ Add LLM Goal Synthesis step before PersonaMode selection

**LLM Integration:**
- ✅ Implement comprehensive goal analysis prompt
- ✅ Create goal synthesis service with structured JSON response parsing
- ✅ Update PersonaMode to use LLM-synthesized goal strategy
- ✅ Implement adaptive goal management for ongoing coaching

**Advanced Features (Day One):**
- ✅ Goal progress correlation analysis
- ✅ Seasonal/lifecycle goal awareness  
- ✅ Post-onboarding goal review and adjustment
- ✅ Predictive goal suggestions

### MVP Perfect Implementation Benefits

**User Experience:**
- Perfect multi-goal intelligence from first user
- No migration complexity or legacy support
- Sophisticated goal understanding from day one

**Technical Benefits:**
- Clean, purpose-built architecture
- No backward compatibility constraints
- Optimal performance from launch

**Business Benefits:**
- Differentiated onboarding experience
- Advanced AI coaching from MVP
- No need for user re-onboarding later

## Technical Considerations

### Enhanced Data Structures (LLM-Centric Approach)

```swift
// New goal-specific structures
struct WeightObjective: Codable, Sendable {
    let currentWeight: Double?        // From HealthKit
    let targetWeight: Double?         // User input
    let timeframe: TimeInterval?      // When they want to achieve it
    
    var direction: WeightDirection {
        guard let current = currentWeight, let target = targetWeight else { return .maintain }
        return current < target ? .gain : current > target ? .lose : .maintain
    }
}

enum WeightDirection: String, Codable {
    case gain, lose, maintain
}

enum BodyRecompositionGoal: String, Codable, CaseIterable {
    case loseFat = "lose_fat"
    case gainMuscle = "gain_muscle" 
    case getToned = "get_toned"
    case improveDefinition = "improve_definition"
    case bodyRecomposition = "body_recomposition"
}

struct FunctionalGoals: Codable, Sendable {
    let rawText: String               // Free text input
    let extractedGoals: [ExtractedGoal]?     // LLM-parsed goals
    let synthesizedStrategy: String?  // LLM-generated strategy
}

struct ExtractedGoal: Codable, Sendable {
    let goal: String
    let context: String
    let measurableOutcome: String
}

// LLM input/output structures
struct OnboardingRawData: Codable, Sendable {
    let userName: String
    let lifeContext: LifeContext
    let weightObjective: WeightObjective?
    let bodyRecompositionGoals: [BodyRecompositionGoal]
    let functionalGoalsText: String
    let preferredPersonaMode: PersonaMode?
    let engagementPreferences: EngagementPreferences
    let motivationalStyle: MotivationalStyle
    let healthKitData: HealthKitSnapshot?
    let additionalContext: String
}

struct LLMGoalSynthesis: Codable, Sendable {
    let parsedFunctionalGoals: [ExtractedGoal]
    let goalRelationships: [GoalRelationship]
    let unifiedStrategy: String
    let recommendedTimeline: String
    let suggestedPersonaMode: PersonaMode?
    let coachingFocus: [String]
    let milestones: [SynthesizedMilestone]
    let expectedChallenges: [String]
    let motivationalHooks: [String]
}

struct GoalRelationship: Codable, Sendable {
    let type: RelationshipType
    let description: String
    
    enum RelationshipType: String, Codable {
        case synergistic, competing, sequential
    }
}

struct SynthesizedMilestone: Codable, Sendable {
    let description: String
    let timeframe: String
    let category: MilestoneCategory
    
    enum MilestoneCategory: String, Codable {
        case weight, bodyComposition, functional, performance
    }
}
```

### Enhanced PersonaMode Integration

```swift
// Enhance existing PersonaMode with LLM goal synthesis
extension PersonaMode {
    func adaptedInstructions(
        for healthContext: HealthContextSnapshot,
        goalSynthesis: LLMGoalSynthesis
    ) -> String {
        let baseInstructions = self.coreInstructions
        let contextAdaptations = buildContextAdaptations(healthContext)
        
        return """
        \(baseInstructions)
        
        ## User's Fitness Journey:
        \(goalSynthesis.unifiedStrategy)
        
        Focus Areas: \(goalSynthesis.coachingFocus.joined(separator: ", "))
        Current Milestone: \(goalSynthesis.milestones.first?.description ?? "Building foundation")
        Motivational Approach: \(goalSynthesis.motivationalHooks.joined(separator: ", "))
        
        ## Current Context Adaptations:
        \(contextAdaptations)
        """
    }
}
```

## Success Metrics

### User Experience
- **Completion Rate**: Maintain 90%+ onboarding completion
- **User Satisfaction**: "This felt personalized to my real goals"
- **Engagement**: Higher long-term app usage due to goal relevance

### Goal Intelligence
- **Goal Accuracy**: Users feel their goals are understood
- **Goal Evolution**: Successful goal adjustments over time
- **Balance Achievement**: Progress across multiple goal areas

### Technical Performance
- **Onboarding Speed**: < 5 minutes total time
- **LLM Efficiency**: Goal synthesis < 3 seconds
- **Data Quality**: Rich goal context for coaching decisions

## Risks & Mitigations

### Risk: Overwhelming Users
**Mitigation**: Progressive disclosure, start with simple categories, allow elaboration

### Risk: Analysis Paralysis  
**Mitigation**: Intelligent defaults, "you can always adjust later" messaging

### Risk: Goal Conflicts Confusion
**Mitigation**: LLM explains relationships clearly, suggests unified strategies

### Risk: Technical Complexity
**Mitigation**: Gradual rollout, maintain backward compatibility, feature flags

## Key Insights & Next Steps

### Key Design Decisions

1. **Free-Form Life Context**: Let users naturally describe their situations instead of rigid categories
2. **Mix & Match Communication Styles**: Users can blend personality traits (encouraging + analytical + challenging)
3. **LLM Handles Complexity**: AI synthesizes mixed preferences rather than forcing discrete choices
4. **Weight = Data + Algorithm**: Weight goals driven by HealthKit data + user targets, not subjective categories
5. **Body Composition = Structured Choices**: Clear, multi-selectable options that avoid overwhelming users
6. **Functional Goals = Free Text + LLM Magic**: Let users express complex goals naturally, LLM parses and synthesizes
7. **Conservative Adaptive Intelligence**: Objective triggers and user-initiated changes, no brittle conversational analysis
8. **Comprehensive Health Coach**: Medical advice allowed - full health/fitness advisor, not just workout planner
9. **User-Controlled Persona Evolution**: Settings-based adjustments with safety screening

## **🚀 IMMEDIATE ACTION PLAN**

### **Priority 1: Fix Critical Issues (This Week)**

1. **Fix App Crash** - Onboarding crashes on "Begin" (API key is already set up via InitialAPISetupView)
2. **Rewrite ALL Prompts** - Replace corporate-speak with conversational, friendly tone
3. **Remove Mutually Exclusive Constraints** - Convert radio buttons to multi-select where logical
4. **Add HealthKit Prefilling** - Weight/sleep data with "Does this look right?" confirmation
5. **Test Complete Flow** - Ensure crash-free: InitialAPISetupView → Onboarding → Dashboard

### **Priority 2: Enhanced UX (Next Week)**

1. **Smart Defaults + Progressive Disclosure** - Start simple, get detailed if they want
2. **"Something Else" Options** - Always give users escape hatch for custom input  
3. **LLM Synthesis Integration** - Let AI handle complex preference combinations
4. **Conversational Flow Polish** - Make every screen feel like talking to a friend

### **Success Criteria**

- **Maintain** 85-90% onboarding completion rate (slight decrease acceptable for much higher value)
- **Achieve** conversational, magical feeling vs corporate form-filling
- **Fix** all technical crashes and missing integrations
- **Enable** users to express complex, nuanced preferences naturally

---

## Conversational Tone Guidelines

### Voice & Personality
- **Tone**: Calm, confident, supportive without being overly enthusiastic
- **Language**: Natural, conversational, like a knowledgeable friend
- **Brevity**: Say more with less - every word should earn its place
- **Personality**: Warm but not saccharine, professional but not corporate

### Example Prompts (Text-Forward Style)

#### API Key Setup
```
// Not this:
"To enable AI-powered coaching capabilities, please provide your API key"

// This:
"Let's connect your AI coach"
```

#### Goal Collection
```
// Not this:
"Please select your primary fitness objectives from the following options"

// This:
"What would you like to achieve?"
```

#### Communication Preferences
```
// Not this:
"Configure your preferred coaching communication style"

// This:
"How do you like to be coached?"
```

### Writing Principles
1. **Questions over statements** - Engage, don't instruct
2. **Active over passive** - "Let's connect" not "Connection required"
3. **Specific over vague** - "7.5 hours sleep" not "good sleep patterns"
4. **Progress over process** - Show what's happening, not how it works

## **📝 CONVERSATIONAL PROMPT REWRITES**

### **Current Localizable.strings Issues**

All current prompts suffer from corporate-speak and need complete rewrite:

#### **❌ Current (Boring & Corporate)**
```
"onboarding.lifeSnapshot.prompt" = "Understanding your daily rhythm helps your coach provide relevant support. Tap what generally applies:";
"onboarding.coreAspiration.prompt" = "What is the primary aspiration you want your AirFit Coach to help you achieve?";
"onboarding.coaching.prompt" = "Define your ideal coaching interaction style. Adjust each element to create your preferred blend.";
```

#### **✅ Enhanced (Conversational & Friendly)**
```
"onboarding.lifeSnapshot.prompt" = "Help me understand your day-to-day life so I can be the most helpful coach possible! What sounds like you? (Pick as many as you want)";
"onboarding.coreAspiration.prompt" = "What are you hoping to achieve with your fitness journey? Dream big - I'm here to help make it happen!";
"onboarding.coaching.prompt" = "How do you like to be coached? I can be a combination of styles! (Pick all that sound good)";
```

### **Specific Rewrite Requirements**

1. **Tone**: Friendly, encouraging, slightly playful
2. **Language**: "You" not "users", "I" not "the system"  
3. **Permissions**: "Pick as many as you want" not "select one"
4. **Escape Hatches**: Always include "Something else" or "Surprise me" options
5. **Examples**: Use parenthetical examples that are relatable and human
- **Achieve** sophisticated multi-goal coaching with health/medical guidance
- **Preserve** sub-5 second persona generation performance
- **Enable** user-controlled persona evolution and reliable adaptive intelligence
- **Deliver** comprehensive health coach experience for private family/friends use

---

## Prerequisites & Development Standards

### Required Reading Before Implementation

**Core Development Standards:**
- `Docs/Development-Standards/README.md` - Documentation overview and philosophy
- `Docs/Development-Standards/SERVICE_LAYER_STANDARDS.md` - ServiceProtocol patterns and actor isolation
- `Docs/Development-Standards/UI_STANDARDS.md` - Current UI standards (being refined)
- `Docs/o3uiconsult.md` - Future UI transformation plan (ChapterTransition, GlassSheet, etc.)

**Architecture References:**
- `CLAUDE.md` - Project overview, commands, architecture patterns, and coding standards
- `Docs/Research Reports/LLM_Centric_Architecture_Strategy.md` - AI integration patterns and best practices

**Key Principles:**
- Swift 6 compliance with proper async/await patterns
- 100% ServiceProtocol conformance for all services
- GlassCard + CascadeText design system (no legacy components)
- Zero errors, zero warnings build requirement
- Actor boundaries: Services are actors, ViewModels are @MainActor

### Code Files That Will Be Modified

#### **Core Data Models (New)**
```
AirFit/Core/Models/
├── OnboardingModels.swift           # New enhanced structures
├── GoalModels.swift                 # WeightObjective, BodyRecompositionGoal, FunctionalGoals
└── AdaptiveModels.swift             # Adaptive intelligence data structures
```

#### **Onboarding Flow (Major Changes)**
```
AirFit/Modules/Onboarding/
├── Views/
│   ├── LifeContextView.swift        # New free-form life context screen
│   ├── WeightGoalsView.swift        # New data-driven weight goals
│   ├── BodyCompositionView.swift    # New multi-select body goals
│   ├── FunctionalGoalsView.swift    # New free-text functional goals
│   ├── CommunicationStyleView.swift # Enhanced mix-match styles
│   └── InformationPreferencesView.swift # Enhanced mix-match preferences
├── Services/
│   ├── OnboardingService.swift      # Enhanced with LLM synthesis
│   ├── GoalSynthesisService.swift   # New LLM goal analysis service
│   └── PersonaService.swift         # Enhanced with adaptive capabilities
└── ViewModels/
    └── OnboardingViewModel.swift    # Updated for new flow
```

#### **Persona & AI Integration (Enhancements)**
```
AirFit/Modules/AI/
├── PersonaEngine.swift              # Enhanced with LLM synthesis integration
├── Models/
│   ├── PersonaModels.swift          # Enhanced with adaptive capabilities
│   └── GoalSynthesisModels.swift    # New LLM synthesis structures
└── Services/
    └── AdaptiveIntelligenceService.swift # New conservative adaptive system
```

#### **Settings Integration (New)**
```
AirFit/Modules/Settings/
├── Views/
│   └── PersonaAdjustmentView.swift  # New settings-based persona adjustment
└── ViewModels/
    └── PersonaAdjustmentViewModel.swift # New adjustment processing
```

#### **Core Services (Enhancements)**
```
AirFit/Services/AI/
├── AIService.swift                  # Enhanced with structured output support
├── LLMOrchestrator.swift           # Enhanced with goal synthesis prompts
└── ContextSerializer.swift         # Enhanced context management
```

#### **Supporting Components**
```
AirFit/Core/Views/
└── InputModalities/
    ├── ChoiceCardsView.swift        # Enhanced for mix-match selection
    └── TextInputView.swift          # Enhanced for free-form context
```

## Migration Strategy & Integration

### Transition from Current System

**Phase 1: Parallel Implementation**
- Implement new onboarding flow alongside existing system
- Use feature flag to control which users see new flow
- Maintain 100% backwards compatibility with existing personas

**Phase 2: Data Structure Evolution**
- Create new goal models while preserving existing Goal.GoalFamily
- Implement conversion utilities between old and new formats
- Ensure existing user data remains functional

**Phase 3: Gradual Migration**
- A/B test new onboarding with family/friends users
- Monitor completion rates and user satisfaction
- Collect feedback and iterate on UX

**Phase 4: Full Replacement**
- Replace legacy onboarding flow with enhanced version
- Migrate existing user data to new goal structures
- Remove legacy components and clean up codebase

### Integration Points with Existing Systems

#### **PersonaMode Integration**
```swift
// Existing PersonaMode.adaptedInstructions() will be enhanced
extension PersonaMode {
    func adaptedInstructions(
        for healthContext: HealthContextSnapshot,
        goalSynthesis: LLMGoalSynthesis  // New parameter
    ) -> String {
        // Existing real-time adaptation + new goal synthesis
    }
}
```

#### **AI Services Integration**
- All existing AI services (AIWorkoutService, AIGoalService, etc.) automatically benefit
- PersonaEngine generates enhanced system prompts with goal synthesis
- No breaking changes to existing service interfaces

#### **HealthKit Integration**
- Leverage existing HealthKitManager for weight/sleep data prefill
- Enhance with additional metrics for goal synthesis
- Maintain existing privacy and authorization patterns

#### **Analytics Integration**
- Extend existing ConversationAnalytics for enhanced onboarding metrics
- Track goal synthesis quality and user satisfaction
- Monitor adaptive intelligence effectiveness

## Testing Strategy

### Unit Testing Priorities

**Goal Synthesis Testing:**
```swift
class GoalSynthesisServiceTests: XCTestCase {
    func testLLMGoalSynthesis_ValidInput_ReturnsStructuredOutput()
    func testGoalRelationshipDetection_ConflictingGoals_IdentifiesCorrectly()
    func testPersonaPromptGeneration_MixedStyles_CreatesCoherentBlend()
    func testSafetyScreening_VariousInputs_RejectsOnlyInappropriate()
}
```

**Persona Adjustment Testing:**
```swift
class PersonaAdjustmentTests: XCTestCase {
    func testPersonaAdjustment_ValidRequest_ModifiesCorrectly()
    func testSafetyScreening_MedicalAdviceRequest_Allows()
    func testSafetyScreening_InappropriateRequest_Rejects()
    func testAdjustmentHistory_MultipleChanges_TracksCorrectly()
}
```

**Onboarding Flow Testing:**
```swift
class EnhancedOnboardingTests: XCTestCase {
    func testOnboardingCompletion_NewFlow_MaintainsCompletionRate()
    func testGoalCollection_FreeFormInput_ExtractsCorrectly()
    func testHealthKitIntegration_DataPrefill_WorksReliably()
    func testBackwardsCompatibility_ExistingUsers_NoBreaking()
}
```

### Integration Testing

**End-to-End Onboarding:**
- Complete onboarding flow with various user personas
- Goal synthesis with different complexity levels
- HealthKit integration with various data availability scenarios
- Persona adaptation over time with simulated usage patterns

**Performance Testing:**
- LLM goal synthesis latency (target: <3 seconds)
- Onboarding completion time (target: <6 minutes)
- Memory usage during synthesis process
- Concurrent user handling

### User Acceptance Testing

**Family/Friends Beta:**
- Deploy to small group of family/friends users
- Collect detailed feedback on onboarding experience
- Monitor completion rates and drop-off points
- Test persona adjustment feature adoption

## Error Handling & Fallback Strategies

### Edge Cases & Production Resilience

#### Intelligent Fallbacks
```swift
enum OnboardingPath {
    case fullExperience    // API key + HealthKit + LLM synthesis
    case healthKitOnly     // No API key, use HealthKit + templates  
    case manualSetup       // No API key or HealthKit
    case demoMode          // Explore with sample data
}

// Path detection:
func determineOptimalPath() -> OnboardingPath {
    if hasAPIKey {
        return .fullExperience
    } else if healthKitAvailable {
        return .healthKitOnly  // Can still provide value!
    } else if userWantsToExplore {
        return .demoMode
    } else {
        return .manualSetup
    }
}
```

#### Smart Recovery
```swift
// Network timeout during API validation
"Taking longer than expected..."
[Show inline retry button after 5s]
[Auto-retry once in background]

// LLM synthesis fails
"Let me try a different approach..."
[Fallback to simpler prompt]
[If still fails: use template-based coach]

// HealthKit has no data
"No problem! Let's start fresh"
[Collect 3 basic metrics manually]
[Skip complex prefilling]
```

#### HealthKit Authorization Denied
```swift
// User denies HealthKit access
// Gracefully continue with manual entry:

"No problem, let's get some basics"

// Collect minimal manual data:
- Current weight (optional)
- Activity level (low/moderate/high)
- Sleep patterns (good/fair/poor)
```

#### Network Issues During Onboarding
```swift
enum OnboardingNetworkStrategy {
    case offline       // Cache all inputs, sync later
    case degraded      // Skip LLM synthesis, use defaults
    case retry         // Offer retry with clear messaging
}

// User-facing message:
"Connection issue - we'll sync your coach when you're back online"
```

### LLM Service Failures

**Goal Synthesis Fallback:**
```swift
class GoalSynthesisService {
    func synthesizeGoals(_ data: OnboardingRawData) async throws -> LLMGoalSynthesis {
        do {
            return try await performLLMSynthesis(data)
        } catch {
            // Fallback to rule-based synthesis
            return await generateFallbackSynthesis(data)
        }
    }
    
    private func generateFallbackSynthesis(_ data: OnboardingRawData) async -> LLMGoalSynthesis {
        // Use existing PersonaMode logic + basic goal categorization
        // Ensure user can complete onboarding even if LLM fails
    }
}
```

**Persona Adjustment Fallback:**
```swift
class PersonaAdjustmentProcessor {
    func processAdjustmentRequest(_ request: String, user: User) async -> AdjustmentResult {
        do {
            return try await performLLMAdjustment(request, user: user)
        } catch {
            // Offer pre-defined adjustment options as fallback
            return .fallbackToPresets(availableAdjustments)
        }
    }
}
```

### Network & Connectivity Issues

**Offline Graceful Degradation:**
- Cache last successful persona synthesis for offline use
- Allow onboarding completion without LLM synthesis (fallback mode)
- Queue persona adjustments for retry when connectivity returns
- Provide clear user feedback about offline limitations

### Data Validation & Recovery

**Structured Output Validation:**
```swift
struct LLMResponseValidator {
    func validateGoalSynthesis(_ response: String) -> ValidationResult {
        // JSON schema validation
        // Required field checking
        // Logical consistency validation
        // Confidence score validation
    }
    
    func recoverFromInvalidResponse(_ invalidResponse: String) -> LLMGoalSynthesis? {
        // Attempt partial parsing
        // Use available fields with defaults for missing ones
        // Log for improvement of prompts
    }
}
```

## Performance Considerations

### Token Usage Optimization

**Goal Synthesis Efficiency:**
- Target: <1000 tokens for complete goal synthesis
- Optimize prompts for conciseness while maintaining quality
- Cache synthesis results to avoid re-computation
- Batch multiple synthesis requests when possible

**Adaptive Intelligence Budget:**
```swift
struct TokenBudgetManager {
    let monthlyBudgetPerUser = 5000  // tokens
    
    func allocateTokens() -> TokenAllocation {
        TokenAllocation(
            onboardingSynthesis: 1000,    // One-time
            weeklyReviews: 800 * 4,       // 3200 monthly
            monthlyReview: 1500,          // 1500 monthly
            personaAdjustments: 300       // Buffer for user adjustments
        )
    }
}
```

### Response Time Targets

**Onboarding Performance:**
- Goal synthesis: <3 seconds
- Complete onboarding: <6 minutes total
- Screen transitions: <0.5 seconds
- HealthKit data prefill: <2 seconds

**Adaptive Intelligence Performance:**
- Weekly review generation: <5 seconds
- Persona adjustment processing: <3 seconds
- Trigger detection: <1 second (background)

### Memory & Processing Efficiency

**Context Management:**
```swift
struct ContextOptimizer {
    func optimizeContextForLLM(_ fullContext: UserContext) -> OptimizedContext {
        // Prioritize recent and relevant data
        // Compress historical patterns into summaries
        // Remove redundant information
        // Target: <2000 characters for context
    }
}
```

## Analytics & Measurement Framework

### Onboarding Success Metrics

**Completion Tracking:**
```swift
struct OnboardingAnalytics {
    func trackScreenCompletion(_ screen: OnboardingScreen, user: User) {
        // Track drop-off points in new flow
        // Compare to legacy onboarding completion rates
        // Identify problematic screens or UX issues
    }
    
    func trackGoalSynthesisQuality(_ synthesis: LLMGoalSynthesis, userFeedback: UserFeedback?) {
        // Measure user satisfaction with goal understanding
        // Track synthesis accuracy over time
        // Identify prompt improvement opportunities
    }
}
```

**Target Metrics:**
- Onboarding completion rate: 85-90% (vs. current 90%+)
- Goal synthesis satisfaction: >8/10 user rating
- Time to completion: <6 minutes average
- Drop-off point identification: <5% on any single screen

### Adaptive Intelligence Effectiveness

**Persona Adjustment Tracking:**
```swift
struct AdaptiveAnalytics {
    func trackPersonaAdjustment(_ adjustment: PersonaAdjustment, effectiveness: EffectivenessScore) {
        // Measure user satisfaction after adjustments
        // Track adjustment frequency and patterns
        // Identify most valuable adjustment types
    }
    
    func trackScheduledReviewValue(_ review: ScheduledReview, userEngagement: EngagementMetrics) {
        // Measure engagement lift from reviews
        // Track suggestion acceptance rates
        // Optimize review frequency and content
    }
}
```

### Long-term Quality Metrics

**Goal Achievement Tracking:**
- Progress toward synthesized goals over time
- Goal adjustment frequency and success
- Correlation between goal complexity and achievement
- User retention and engagement patterns

**System Health Monitoring:**
- LLM response quality and consistency
- Token usage efficiency trends
- Error rates and fallback usage
- Performance degradation alerts

## Risk Mitigation & Quality Assurance

### Technical Risks

**LLM Reliability:**
- Risk: Inconsistent or poor quality goal synthesis
- Mitigation: Comprehensive fallback systems, response validation, prompt optimization
- Monitoring: Track synthesis quality scores and user feedback

**Performance Degradation:**
- Risk: Slow LLM responses impact onboarding completion
- Mitigation: Aggressive caching, timeout handling, progress indicators
- Monitoring: Real-time latency tracking and alerting

### User Experience Risks

**Complexity Overwhelm:**
- Risk: Enhanced onboarding becomes too complex despite simplification efforts
- Mitigation: Progressive disclosure, clear skip options, family/friends testing
- Monitoring: Completion rate tracking and user feedback collection

**Persona Adjustment Confusion:**
- Risk: Users don't understand or misuse persona adjustment features
- Mitigation: Clear UI/UX, helpful examples, guided adjustment flows
- Monitoring: Feature adoption rates and support request patterns

### Data & Privacy Considerations

**Enhanced Data Collection:**
- Risk: More comprehensive data collection raises privacy concerns
- Mitigation: Clear privacy explanations, granular permissions, local processing where possible
- Monitoring: User consent rates and data usage patterns

**LLM Data Handling:**
- Risk: Sensitive health data sent to external LLM services
- Mitigation: Data minimization, secure transmission, provider evaluation
- Monitoring: Audit trails and compliance checking

## Implementation Roadmap (Zero Technical Debt)

### Phase 1: Core Infrastructure (Day 1-2)
```swift
// Priority order:
1. OnboardingCoordinator with state machine
2. GradientManager integration for screen transitions  
3. APIKeySetupViewModel with provider detection
4. HealthKitOnboardingService for smart prefilling
5. OnboardingAnalytics for funnel tracking
```

### Phase 2: Screen Implementation (Day 3-4)
```swift
// Build in sequence:
1. OpeningView with CascadeText
2. APIKeySetupView with real-time validation
3. HealthKitAuthView with data preview
4. LifeContextView with voice input
5. GoalsView with progressive disclosure
6. CommunicationStyleView with smart defaults
7. SynthesisView with visual processing
```

### Phase 3: Intelligence Layer (Day 5)
```swift
// LLM Integration:
1. OnboardingContextBuilder
2. PersonaSynthesisService enhancements
3. Fallback template system
4. Retry/error recovery logic
```

### Phase 4: Polish & Excellence (Day 6)
```swift
// Final touches:
1. Micro-interactions and haptics
2. Accessibility compliance
3. Performance optimization
4. Edge case handling
5. Analytics verification
```

### Design Decisions Made
- **Text-forward**: No avatars, minimal imagery, typography focus
- **Provider selection**: Simple radio buttons, default to Gemini (free tier)
- **API key first**: Critical path requirement, provider-aware validation
- **Gradient navigation**: Each screen advances the journey
- **Progressive disclosure**: Start simple, elaborate as needed
- **Conversational tone**: Natural, calm, confident
- **HealthKit early**: Enrich context before questions

### Key Technical Requirements
- SwiftUI NavigationTransition for cinematic screen changes
- Gradient manager for coordinated color evolution  
- Provider selection with smart defaults (Gemini for free tier)
- Provider-specific API key validation
- LLMOrchestrator integration for connection testing
- LLM synthesis with structured JSON output
- Fallback flows for offline/error scenarios
- Sub-3 second target for all operations

---

## Success Metrics

### User Experience
- **Completion rate**: > 95% (quality over speed)
- **Drop-off rate**: < 5% at any screen
- **API key success rate**: > 95% on first attempt
- **User satisfaction**: > 9/10
- **Feeling rushed**: 0% (users set their own pace)

### Technical Performance  
- **Screen transitions**: < 0.5s
- **API validation**: < 2s
- **LLM synthesis**: < 3s
- **Total memory**: < 50MB
- **Battery impact**: Negligible

### Business Outcomes
- **Onboarding completion**: > 95%
- **Coach satisfaction**: > 90%
- **Day 1 retention**: > 80%
- **API key retention**: > 98%

---

**Status**: Production-Ready Design  
**Last Updated**: 2025-06-15  
**Approach**: Text-Forward Cinematic Excellence  
**Vision**: World-class onboarding that feels like magic, not configuration

**Bottom Line**: Every user should feel like they just experienced something special - a thoughtful conversation that resulted in a perfectly personalized AI coach. No friction, no confusion, just elegant simplicity.
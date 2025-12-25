import Foundation
import SwiftData

// MARK: - Macro Targets

/// Macro targets for a specific day type (training vs rest).
/// Used for nutrition coaching and compliance tracking.
struct MacroTargets: Codable, Equatable {
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?

    var isEmpty: Bool {
        calories == nil && protein == nil && carbs == nil && fat == nil
    }

    /// Format as single-line summary
    func formatted() -> String {
        var parts: [String] = []
        if let c = calories { parts.append("\(c) kcal") }
        if let p = protein { parts.append("\(p)g P") }
        if let c = carbs { parts.append("\(c)g C") }
        if let f = fat { parts.append("\(f)g F") }
        return parts.joined(separator: " | ")
    }
}

// MARK: - Insight Entry

/// Timestamped insight for audit trail.
struct InsightEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var content: String
    var timestamp: Date
    var category: String?  // "nutrition", "training", "recovery", etc.
}

// MARK: - Coaching Directives

/// Explicit coaching preferences that can't be discovered through conversation.
///
/// The profile extraction system discovers WHO the user IS (facts, goals, preferences).
/// But HOW they want to be coached requires explicit permission:
/// - "Roast me" = permission to mock failures
/// - "No unsolicited advice" = boundary on proactivity
/// - "Deep dives" = preference for evidence vs brevity
///
/// These are calibrated once and injected into the system prompt.
struct CoachingDirectives: Codable, Equatable {

    // MARK: - Tone & Energy

    enum Tone: String, Codable {
        case broEnergy = "bro"        // Old friend, casual, informal
        case professional = "pro"     // Direct, efficient, focused
        case supportive = "hype"      // Cheerleader, encouraging
        case analytical = "data"      // Numbers-driven, precise
    }
    var tone: Tone = .broEnergy

    // MARK: - Roast Tolerance

    enum RoastTolerance: String, Codable {
        case roastMe = "roast"        // Give me hell when I deserve it
        case lightJokes = "light"     // Occasional humor is fine
        case keepItKind = "kind"      // Positive reinforcement only
    }
    var roastTolerance: RoastTolerance = .lightJokes

    // MARK: - Advice Style

    var onlyAdviseWhenAsked: Bool = false   // "Don't suggest unless I ask"
    var proactiveSuggestions: Bool = true    // "Share ideas whenever"
    var callMeOut: Bool = true               // "Tell me when I'm wrong"

    // MARK: - Explanation Depth

    enum ExplanationDepth: String, Codable {
        case deepDives = "deep"       // Give me the science
        case quickHits = "quick"      // Just tell me what to do
        case contextual = "context"   // Read the room
    }
    var explanationDepth: ExplanationDepth = .contextual

    // MARK: - Personality Level

    enum PersonalityLevel: String, Codable {
        case unhinged = "wild"        // Wild takes, personality is a feature
        case spicy = "spicy"          // Some flair, mostly focused
        case clean = "clean"          // Professional, no frills
    }
    var personalityLevel: PersonalityLevel = .spicy

    // MARK: - System Prompt Generation

    /// Generate the coaching directives section for the system prompt.
    func toSystemPromptSection() -> String {
        var parts: [String] = []

        // Tone
        switch tone {
        case .broEnergy:
            parts.append("• Bro energy - talk like we've known each other for years")
        case .professional:
            parts.append("• Professional and direct - efficient, focused, no fluff")
        case .supportive:
            parts.append("• Supportive cheerleader - encouraging, positive energy")
        case .analytical:
            parts.append("• Data-driven analyst - numbers, precision, analysis")
        }

        // Roast tolerance
        switch roastTolerance {
        case .roastMe:
            parts.append("• Feel free to roast - bros give each other shit for kicks")
        case .lightJokes:
            parts.append("• Light humor is welcome - keep it playful")
        case .keepItKind:
            parts.append("• Keep it positive - constructive feedback only")
        }

        // Advice style
        if onlyAdviseWhenAsked {
            parts.append("• Only offer suggestions when asked - respect the boundary")
        }
        if proactiveSuggestions {
            parts.append("• Proactive suggestions welcome - share ideas freely")
        }
        if callMeOut {
            parts.append("• Call me out when I'm wrong - honest feedback matters")
        }

        // Explanation depth
        switch explanationDepth {
        case .deepDives:
            parts.append("• Go deep - evidence, science, thorough explanations")
        case .quickHits:
            parts.append("• Keep it brief - just tell me what to do")
        case .contextual:
            parts.append("• Match the moment - deep dives when relevant, quick hits when simple")
        }

        // Personality level
        switch personalityLevel {
        case .unhinged:
            parts.append("• Personality is a feature - wild takes, unhinged energy welcome")
        case .spicy:
            parts.append("• Some personality - flair and focus in balance")
        case .clean:
            parts.append("• Clean and professional - no frills, just the work")
        }

        guard !parts.isEmpty else { return "" }
        return "--- COACHING STYLE ---\n" + parts.joined(separator: "\n")
    }
}

// MARK: - Local Profile

/// Local user profile stored on device.
///
/// This is the **source of truth** for user profile data. The device owns the profile,
/// and AI providers (Claude/Gemini) are interchangeable reasoning engines.
///
/// Matches server's `UserProfile` dataclass for full feature parity across modes.
@Model
final class LocalProfile {
    var id: UUID = UUID()

    // MARK: - Identity (discovered through onboarding)

    var name: String?
    var age: Int?
    var heightInches: Int?
    var heightString: String?  // "5'10"" or "178cm" for display
    var occupation: String?

    // MARK: - Current State

    var currentWeight: Double?
    var bodyFatPct: Double?
    var goalPhase: String?  // "cut", "bulk", "maintain", "recomp"

    // MARK: - Phase Tracking (NEW)

    /// Context for current phase: "Ski season prep, target 175 by Jan"
    var phaseContext: String?

    /// When the current phase began
    var phaseStarted: Date?

    // MARK: - Goals & Targets

    var goals: [String]?
    var targetWeight: Double?      // Goal weight in lbs
    var targetBodyFatPct: Double?  // Goal body fat %
    var proteinTarget: Int?
    var calorieTargetTraining: Int?
    var calorieTargetRest: Int?

    // MARK: - Nutrition (NEW)

    /// Full macro targets for training days (stored as JSON)
    var trainingDayMacrosData: Data?

    /// Full macro targets for rest days (stored as JSON)
    var restDayMacrosData: Data?

    /// Nutrition guidelines: ["protein timing post-workout", "minimize added sugars"]
    var nutritionGuidelines: [String]?

    // MARK: - Training

    var trainingDaysPerWeek: Int?
    var trainingStyle: String?  // "strength", "hypertrophy", "mixed", etc.
    var favoriteExercises: [String]?
    var favoriteActivities: [String]?  // ["powerlifting", "hiking", "skiing"]

    // MARK: - Life Context (NEW)

    /// Life situation details: ["surgeon schedule", "on-call disrupts sleep", "father of 2"]
    var lifeContext: [String]?

    /// Constraints: ["no barbells at home gym", "knee injury limiting squats"]
    var constraints: [String]?

    /// Preferences: ["prefers morning workouts", "hates cardio", "loves data"]
    var preferences: [String]?

    /// General context notes
    var context: [String]?

    // MARK: - Observed Patterns (NEW)

    /// AI-discovered patterns: ["better sleep correlates with PM workouts"]
    var patterns: [String]?

    /// Hevy-specific quirks: ["names sessions creatively", "supersets on push days"]
    var hevyQuirks: [String]?

    // MARK: - Personality & Communication

    /// Generated personality prompt (e.g., "You are Brian's AI fitness coach...")
    var personalityNotes: String?

    /// Observed communication style (e.g., "bro energy", "data-driven", "gentle")
    var communicationStyle: String?

    /// Things to remember about the user
    var relationshipNotes: String?

    /// Explicit coaching directives from calibration (stored as JSON)
    var coachingDirectivesData: Data?

    // MARK: - Synthesized Coaching Persona (Prose-First)

    /// The LLM-synthesized coaching persona (prose).
    ///
    /// This is what actually goes into the system prompt. Instead of hardcoded
    /// enum→text mappings, we let the LLM write its own coaching approach
    /// based on all available signals (profile, calibration, memories, patterns).
    ///
    /// Example:
    /// "With Brian, I lean into the dark surgeon humor - the guy spends his days
    /// literally inside people's bodies, so nothing phases him. When he's grinding
    /// through a cut, I might crack a joke about his protein being 'surgically precise'..."
    var coachingPersona: String?

    /// When the coaching persona was last generated.
    /// Used to trigger periodic regeneration (weekly refresh).
    var coachingPersonaGeneratedAt: Date?

    // MARK: - Insight History (NEW)

    /// Timestamped insights for audit trail (stored as JSON)
    var insightHistoryData: Data?

    // MARK: - Summary

    /// Stored summary for display: "Surgeon. Father. Chasing 15%."
    var storedSummary: String?

    // MARK: - Timestamps

    var lastServerSync: Date?
    var lastLocalUpdate: Date?

    /// Last time personality was regenerated
    var lastPersonalityUpdate: Date?

    // MARK: - Onboarding State

    var onboardingComplete: Bool = false
    var onboardingPhase: String?

    // MARK: - Initialization

    init() {
        self.id = UUID()
        self.lastLocalUpdate = Date()
    }

    // MARK: - Computed Properties

    /// Whether this profile has meaningful data (not just an empty shell)
    var hasProfile: Bool {
        // Profile is "real" if it has a name or any goals set
        (name != nil && !name!.isEmpty) || !(goals ?? []).isEmpty
    }

    /// One-line summary for display
    var summary: String {
        if let stored = storedSummary, !stored.isEmpty {
            return stored
        }
        var parts: [String] = []
        if let name = name { parts.append(name) }
        if let phase = goalPhase { parts.append("(\(phase))") }
        if let weight = currentWeight { parts.append("\(Int(weight)) lbs") }
        return parts.joined(separator: " ")
    }

    /// Training day macros (decoded from JSON)
    var trainingDayMacros: MacroTargets? {
        get {
            guard let data = trainingDayMacrosData else { return nil }
            return try? JSONDecoder().decode(MacroTargets.self, from: data)
        }
        set {
            trainingDayMacrosData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Rest day macros (decoded from JSON)
    var restDayMacros: MacroTargets? {
        get {
            guard let data = restDayMacrosData else { return nil }
            return try? JSONDecoder().decode(MacroTargets.self, from: data)
        }
        set {
            restDayMacrosData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Insight history (decoded from JSON)
    var insightHistory: [InsightEntry] {
        get {
            guard let data = insightHistoryData else { return [] }
            return (try? JSONDecoder().decode([InsightEntry].self, from: data)) ?? []
        }
        set {
            insightHistoryData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Coaching directives from calibration (decoded from JSON)
    var coachingDirectives: CoachingDirectives? {
        get {
            guard let data = coachingDirectivesData else { return nil }
            return try? JSONDecoder().decode(CoachingDirectives.self, from: data)
        }
        set {
            coachingDirectivesData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Add an insight to history
    func addInsight(_ content: String, category: String? = nil) {
        var history = insightHistory
        history.append(InsightEntry(content: content, timestamp: Date(), category: category))
        // Keep last 50 insights
        if history.count > 50 {
            history = Array(history.suffix(50))
        }
        insightHistory = history
    }

    /// Build system prompt section from profile data.
    ///
    /// Generates a rich context section matching server's `to_system_prompt()`.
    /// This is injected into the AI system prompt to personalize responses.
    ///
    /// **Prose-First Architecture**:
    /// 1. Use `coachingPersona` (LLM-synthesized prose) if available - this is the gold standard
    /// 2. Fall back to `personalityNotes` or hardcoded directives if no persona yet
    ///
    /// The synthesized persona incorporates ALL signals (profile, calibration, memories, patterns)
    /// into natural prose that reads like a friend describing their coaching approach.
    func toSystemPromptSection() -> String {
        var parts: [String] = []

        // ─────────────────────────────────────────────────────────────
        // 1. COACHING APPROACH (prose-first!)
        // ─────────────────────────────────────────────────────────────
        if let persona = coachingPersona, !persona.isEmpty {
            // Synthesized persona is the gold standard - it incorporates everything
            parts.append("--- YOUR COACHING APPROACH ---")
            parts.append(persona)
        } else if let personality = personalityNotes, !personality.isEmpty {
            // Fallback to manually written personality notes
            parts.append(personality)
        } else if let style = communicationStyle, !style.isEmpty {
            // Basic fallback
            parts.append("Communicate with \(style) energy.")
        }

        // 2. Coaching directives (only as fallback if no synthesized persona)
        // When we have a coachingPersona, the directives are already incorporated
        if coachingPersona == nil || coachingPersona?.isEmpty == true {
            if let directives = coachingDirectives {
                let directivesSection = directives.toSystemPromptSection()
                if !directivesSection.isEmpty {
                    parts.append("\n" + directivesSection)
                }
            }
        }

        // 3. About the user
        var aboutParts: [String] = []
        if let name = name { aboutParts.append("Name: \(name)") }
        if let age = age { aboutParts.append("Age: \(age)") }
        if let height = heightString ?? formatHeight() {
            aboutParts.append("Height: \(height)")
        }
        if let occupation = occupation { aboutParts.append("Occupation: \(occupation)") }
        if !aboutParts.isEmpty {
            parts.append("\n--- ABOUT THE USER ---\n" + aboutParts.joined(separator: "\n"))
        }

        // 3. Current state
        var stateParts: [String] = []
        if let weight = currentWeight { stateParts.append("Weight: \(Int(weight)) lbs") }
        if let bf = bodyFatPct { stateParts.append("Body fat: \(String(format: "%.1f", bf))%") }
        if !stateParts.isEmpty {
            parts.append("\n--- CURRENT STATE ---\n" + stateParts.joined(separator: "\n"))
        }

        // 4. Goals & Phase
        var goalParts: [String] = []
        if let phase = goalPhase {
            var phaseStr = "Current phase: \(phase.uppercased())"
            if let context = phaseContext { phaseStr += " (\(context))" }
            goalParts.append(phaseStr)
        }
        if let goals = goals, !goals.isEmpty {
            goalParts.append(contentsOf: goals.map { "• \($0)" })
        }
        if let tw = targetWeight { goalParts.append("Target weight: \(Int(tw)) lbs") }
        if let tbf = targetBodyFatPct { goalParts.append("Target body fat: \(String(format: "%.1f", tbf))%") }
        if !goalParts.isEmpty {
            parts.append("\n--- GOALS & PHASE ---\n" + goalParts.joined(separator: "\n"))
        }

        // 5. Training
        var trainingParts: [String] = []
        if let days = trainingDaysPerWeek { trainingParts.append("Frequency: \(days) days/week") }
        if let style = trainingStyle { trainingParts.append("Style: \(style)") }
        if let activities = favoriteActivities, !activities.isEmpty {
            trainingParts.append("Favorite activities: \(activities.joined(separator: ", "))")
        }
        if let exercises = favoriteExercises, !exercises.isEmpty {
            trainingParts.append("Favorite exercises: \(exercises.joined(separator: ", "))")
        }
        if !trainingParts.isEmpty {
            parts.append("\n--- TRAINING ---\n" + trainingParts.joined(separator: "\n"))
        }

        // 6. Nutrition targets (rich version with full macros)
        var nutritionParts: [String] = []
        if let t = trainingDayMacros, !t.isEmpty {
            nutritionParts.append("Training days: \(t.formatted())")
        } else if let calTraining = calorieTargetTraining {
            var line = "Training days: \(calTraining) kcal"
            if let p = proteinTarget { line += " | \(p)g P" }
            nutritionParts.append(line)
        }
        if let r = restDayMacros, !r.isEmpty {
            nutritionParts.append("Rest days: \(r.formatted())")
        } else if let calRest = calorieTargetRest {
            var line = "Rest days: \(calRest) kcal"
            if let p = proteinTarget { line += " | \(p)g P" }
            nutritionParts.append(line)
        }
        if let guidelines = nutritionGuidelines, !guidelines.isEmpty {
            nutritionParts.append(contentsOf: guidelines.map { "• \($0)" })
        }
        if !nutritionParts.isEmpty {
            parts.append("\n--- NUTRITION TARGETS ---\n" + nutritionParts.joined(separator: "\n"))
        }

        // 7. Life context
        if let lc = lifeContext, !lc.isEmpty {
            parts.append("\n--- LIFE CONTEXT ---\n" + lc.map { "• \($0)" }.joined(separator: "\n"))
        }

        // 8. Constraints
        if let c = constraints, !c.isEmpty {
            parts.append("\n--- CONSTRAINTS ---\n" + c.map { "• \($0)" }.joined(separator: "\n"))
        }

        // 9. Relationship notes
        if let rn = relationshipNotes, !rn.isEmpty {
            parts.append("\n--- RELATIONSHIP ---\n" + rn)
        }

        // 10. Preferences
        if let p = preferences, !p.isEmpty {
            parts.append("\n--- PREFERENCES ---\n" + p.map { "• \($0)" }.joined(separator: "\n"))
        }

        // 11. Observed patterns
        if let pat = patterns, !pat.isEmpty {
            parts.append("\n--- OBSERVED PATTERNS ---\n" + pat.map { "• \($0)" }.joined(separator: "\n"))
        }

        // 12. Hevy quirks
        if let hq = hevyQuirks, !hq.isEmpty {
            parts.append("\n--- HEVY INTEGRATION ---\n" + hq.map { "• \($0)" }.joined(separator: "\n"))
        }

        return parts.joined(separator: "\n")
    }

    /// Format height from inches to display string
    private func formatHeight() -> String? {
        guard let inches = heightInches else { return nil }
        let feet = inches / 12
        let remainingInches = inches % 12
        return "\(feet)'\(remainingInches)\""
    }
}

// MARK: - Local Memory Storage

/// Individual memory marker stored locally.
///
/// Memory markers are extracted from AI responses and stored for injection
/// into future conversations, creating continuity and relationship depth.
@Model
final class LocalMemory {
    var id: UUID = UUID()

    /// Type of memory: "remember", "callback", "tone", "thread"
    var type: String

    /// The actual content to remember
    var content: String

    /// When this memory was created
    var createdAt: Date

    /// Whether this has been synced to the server
    var syncedToServer: Bool = false

    /// Associated conversation ID (if any)
    var conversationId: UUID?

    init(type: String, content: String, conversationId: UUID? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.createdAt = Date()
        self.conversationId = conversationId
    }
}

// MARK: - Memory Type Helpers

extension LocalMemory {
    /// Memory type categories
    enum MemoryType: String, CaseIterable {
        case remember   // General things to remember
        case callback   // Inside jokes, phrases that landed well
        case tone       // Communication style observations
        case thread     // Topics to follow up on

        var displayName: String {
            switch self {
            case .remember: return "Remember"
            case .callback: return "Callback"
            case .tone: return "Tone"
            case .thread: return "Thread"
            }
        }
    }

    var memoryType: MemoryType? {
        MemoryType(rawValue: type)
    }
}

// MARK: - Query Helpers

extension LocalMemory {
    /// Get all unsynced memories
    static var unsynced: Predicate<LocalMemory> {
        #Predicate<LocalMemory> { $0.syncedToServer == false }
    }

    /// Get recent memories (last 30 days)
    static var recent: Predicate<LocalMemory> {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return #Predicate<LocalMemory> { $0.createdAt >= cutoff }
    }

    /// Get callbacks for injection
    static var callbacks: Predicate<LocalMemory> {
        #Predicate<LocalMemory> { $0.type == "callback" }
    }

    /// Get active threads (topics to follow up on)
    static var threads: Predicate<LocalMemory> {
        #Predicate<LocalMemory> { $0.type == "thread" }
    }
}

// MARK: - Profile Query Helpers

extension LocalProfile {
    /// Get the current (most recently updated) profile
    static func current(in context: ModelContext) -> LocalProfile? {
        let descriptor = FetchDescriptor<LocalProfile>(
            sortBy: [SortDescriptor(\.lastLocalUpdate, order: .reverse)]
        )
        return try? context.fetch(descriptor).first
    }

    /// Get or create the profile
    ///
    /// Creates an EMPTY profile for new users. All personalization comes from:
    /// - Onboarding interview (discovers WHO they are)
    /// - Coaching calibration (captures HOW they want coaching)
    /// - Persona synthesis (LLM writes prose coaching approach)
    ///
    /// NO hardcoded user data - each user's experience is truly personal.
    static func getOrCreate(in context: ModelContext) -> LocalProfile {
        if let existing = current(in: context) {
            return existing
        }
        // Create empty profile - personalization comes from onboarding
        let new = LocalProfile()
        new.onboardingComplete = false  // Forces onboarding flow
        context.insert(new)
        try? context.save()
        return new
    }

    // MARK: - Test Seed (DISABLED for TestFlight)
    // This seed function is commented out to ensure TestFlight users get native persona generation.
    // The AI-native PersonalitySynthesisService now generates personas from onboarding conversation.
    //
    // To re-enable for development, uncomment the function below.
    /*
    /// Seed a test profile with demo data.
    ///
    /// ⚠️ FOR DEVELOPMENT/TESTING ONLY - not called in production.
    /// Use the /profile/import endpoint or Settings > Import Profile instead.
    ///
    /// Captures the "vibes" from Claude Desktop coaching personality:
    /// - Bro energy, old friend informality
    /// - Funny, sharp, wild, unhinged
    /// - Evidence-based when worthwhile
    /// - Roasting encouraged
    static func seedTestProfile() -> LocalProfile {
        let profile = LocalProfile()

        // MARK: - Identity
        profile.name = "Brian"
        profile.age = 36
        profile.heightString = "5'11\""
        profile.heightInches = 71

        // MARK: - Current State (as of late Nov 2025)
        profile.currentWeight = 180
        profile.bodyFatPct = 23

        // MARK: - Goals & Phase
        profile.goalPhase = "cut"
        profile.phaseContext = "Targeting ≤15% BF; building toward 175-180 lb lean tissue"
        profile.phaseStarted = Date()
        profile.targetBodyFatPct = 15
        profile.targetWeight = 177  // Mid-range of 175-180

        profile.goals = [
            "Reach ≤15% body fat",
            "Build toward 175-180 lb lean tissue",
            "Maintain strength during cut",
            "Stay athletic for skiing, biking, and kid-wrestling"
        ]

        // MARK: - Training
        profile.trainingDaysPerWeek = 5  // avg 4-6
        profile.trainingStyle = "strength/hypertrophy"

        profile.favoriteActivities = [
            "Skiing",
            "Mountain biking",
            "Windsurfing",
            "Running",
            "Hiking",
            "Wrestling the kids"
        ]

        // MARK: - Nutrition Targets
        // Training days: 2600 kcal; ≥175g P; 320-340g C; ≤65-70g F
        profile.calorieTargetTraining = 2600
        profile.trainingDayMacros = MacroTargets(
            calories: 2600,
            protein: 175,
            carbs: 330,  // midpoint of 320-340
            fat: 67      // midpoint of 65-70
        )

        // Rest days: 2200 kcal; ≥175g P; 240-260g C; ≤55-60g F
        profile.calorieTargetRest = 2200
        profile.restDayMacros = MacroTargets(
            calories: 2200,
            protein: 175,
            carbs: 250,  // midpoint of 240-260
            fat: 57      // midpoint of 55-60
        )

        profile.proteinTarget = 175

        profile.nutritionGuidelines = [
            "High-protein, carb-forward, fat-capped",
            "No food suggestions unless asked",
            "Zero junk volume philosophy applies to nutrition too"
        ]

        // MARK: - Life Context
        profile.lifeContext = [
            "Father - kids are a favorite workout partner",
            "Active lifestyle with varied outdoor sports",
            "Logs workouts with HEVY app"
        ]

        // MARK: - Constraints
        profile.constraints = [
            "Zero junk volume - every set counts",
            "No meal recs unless specifically asked"
        ]

        // MARK: - Preferences
        profile.preferences = [
            "Evidence-based approach when worthwhile",
            "Keep novelty; progression coherent",
            "Fun, funny, effective coaching"
        ]

        // MARK: - HEVY Quirks
        profile.hevyQuirks = [
            "DB lifts logged as TOTAL (e.g. 120lb DB bench = 60lb DBs × 2)",
            "Summaries can show both single-arm and total weight"
        ]

        // MARK: - Communication Style
        profile.communicationStyle = "bro energy"

        // MARK: - THE PERSONALITY (the vibes!)
        profile.personalityNotes = """
        You are Brian's AI fitness coach with the personality of an old friend who happens to be exceptionally talented at coaching.

        PERSONALITY:
        • Bro energy and informality - talk like we've known each other for years
        • Funny, sharp, wild and unhinged - personality is a feature, not a bug
        • Feel free to roast whenever - bros give each other shit for kicks
        • Exceptionally talented, gifted, informed, and hardworking under the humor

        STYLE:
        • Responses can be as long/short as seems appropriate
        • Evidence-based when truly worthwhile (not for simple requests)
        • Zero junk volume - in training AND in conversation
        • Keep novelty; progression coherent
        • Fun, funny, effective > dry and clinical

        RELATIONSHIP:
        • We're building toward ≤15% BF from current ~23%
        • 4-6 gym days/week is the rhythm
        • Skiing, biking, windsurfing, hiking, kid-wrestling = the why
        • HEVY logs the work, you bring the insight
        """

        profile.relationshipNotes = "Responds well to roasting. Data-driven but appreciates humor. Can take a joke and dish it back. Ski season is always a motivator."

        // MARK: - Coaching Directives (the vibes!)
        var directives = CoachingDirectives()
        directives.tone = .broEnergy
        directives.roastTolerance = .roastMe
        directives.onlyAdviseWhenAsked = true  // No meal recs unless asked
        directives.proactiveSuggestions = false
        directives.callMeOut = true
        directives.explanationDepth = .contextual
        directives.personalityLevel = .unhinged
        profile.coachingDirectives = directives

        // MARK: - Summary
        profile.storedSummary = "Brian. 36. Chasing 15%. Dad strength loading."

        // MARK: - State
        profile.onboardingComplete = true
        profile.lastLocalUpdate = Date()
        profile.lastPersonalityUpdate = Date()

        return profile
    }
    */
}

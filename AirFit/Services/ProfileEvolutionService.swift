import Foundation
import SwiftData

/// Extracts profile updates from AI conversations and generates personality.
///
/// This service is the heart of the device-first profile architecture.
/// It works with ANY AI provider (Gemini, Claude, or server-routed) by:
/// 1. Analyzing conversations for new profile information
/// 2. Updating LocalProfile with discovered facts
/// 3. Generating rich personality prompts when sufficient data accumulates
///
/// Runs asynchronously after each conversation turn (non-blocking).
/// Uses @MainActor since it works with SwiftData ModelContext.
@MainActor
final class ProfileEvolutionService {
    static let shared = ProfileEvolutionService()

    private let geminiService = GeminiService()

    // Track extraction batching (for free tier users)
    private var messagesSinceLastExtraction = 0
    private var lastExtractionTime: Date?

    // MARK: - Extraction Prompt (ported from server/profile.py:313-369)

    static let extractSystemPrompt = """
    You analyze conversations to extract user profile information.

    Given a conversation, extract ANY new information about the user. Be thorough - capture everything that would help personalize their coaching experience.

    EXTRACT THESE CATEGORIES:

    1. IDENTITY: name, age, height, occupation
    2. GOALS: specific goals with timelines
    3. PHASE: current phase (cut/bulk/maintain/recomp) and context (why now?)
    4. TRAINING: style, frequency, preferences, equipment access, injuries
    5. NUTRITION: current approach, restrictions, targets if mentioned
    6. CONSTRAINTS: time, schedule, family, work
    7. LIFE CONTEXT: job demands, family situation, what disrupts them
    8. COMMUNICATION: preferred style (bro energy, professional, analytical, etc.)
    9. RELATIONSHIP NOTES: quirks, personality traits, things to remember about them as a person

    RESPOND ONLY WITH JSON:
    {
      "identity": {
        "name": "string or null",
        "age": "number or null",
        "height": "string or null",
        "occupation": "string or null"
      },
      "current_state": {
        "weight_lbs": "number or null",
        "body_fat_pct": "number or null"
      },
      "phase": {
        "current_phase": "cut/bulk/maintain/recomp or null",
        "phase_context": "why now, timeline, trigger - or null"
      },
      "new_goals": ["specific goal"],
      "new_constraints": ["constraint"],
      "new_preferences": ["preference"],
      "new_context": ["context"],
      "new_life_context": ["life situation detail"],
      "new_relationship_notes": ["personality quirk or thing to remember"],
      "training": {
        "days_per_week": "number or null",
        "style": ["solo training", "prefers dumbbells"],
        "favorite_activities": ["activity"]
      },
      "nutrition_targets": {
        "calories": "number or null",
        "protein": "number or null",
        "carbs": "number or null",
        "fat": "number or null"
      },
      "communication_style": "bro energy/professional/analytical/encouraging - or null",
      "insights": ["specific insight extracted"]
    }

    GUIDELINES:
    - Use null for unknown fields, empty arrays for no new items
    - Be specific: "surgeon with unpredictable on-call schedule" not "busy job"
    - Capture personality: "uses dark humor", "data-driven", "can take a roast"
    - Note motivations: "ski season in January" not just "wants to lose weight"
    - Infer the phase from context if not stated explicitly
    """

    // MARK: - Personality Synthesis Prompt (ported from server/profile.py:511-538)

    static let personalitySynthesisPrompt = """
    You are generating a personality profile for an AI fitness coach to use as its system prompt.

    Based on everything learned about this user, write a PERSONALITY section that will make the AI coach feel like a real person who knows them.

    This should capture:
    1. The right tone and energy level to use with them
    2. What they appreciate in communication (science? humor? directness?)
    3. Key things to remember about them as a person
    4. How to push/encourage them appropriately

    FORMAT (copy this structure exactly):
    ```
    You are [NAME]'s AI fitness coach with the personality of [relationship metaphor].

    PERSONALITY:
    - [tone/energy point]
    - [humor/seriousness preference]
    - [what they respond to]
    - [knowledge style preference]

    STYLE:
    - [communication approach]
    - [when to go deep vs keep it brief]
    - [how to handle struggles]
    - [how to celebrate wins]
    ```

    Make it feel REAL and PERSONAL. This isn't a generic template - it's crafted for THIS person based on what we learned.
    """

    // MARK: - Tier Detection

    enum GeminiTier {
        case free      // 5 RPM, 20 RPD - need batching
        case paid      // 1000 RPM, 10K RPD - extract every message

        static var current: GeminiTier {
            UserDefaults.standard.bool(forKey: "geminiPaidTier") ? .paid : .free
        }
    }

    /// How often to extract based on tier
    private var extractionFrequency: Int {
        switch GeminiTier.current {
        case .paid: return 1  // Every message
        case .free: return 5  // Every 5 messages (conserve quota)
        }
    }

    // MARK: - Public API

    /// Extract profile updates from a conversation turn.
    ///
    /// Called asynchronously after every chat message (non-blocking).
    /// Respects tier limits - batches for free tier users.
    func extractAndUpdateProfile(
        userMessage: String,
        aiResponse: String,
        modelContext: ModelContext
    ) async {
        messagesSinceLastExtraction += 1

        // Skip if not time to extract (free tier batching)
        guard shouldExtract() else { return }

        let profile = LocalProfile.getOrCreate(in: modelContext)

        // Build context of what we already know
        var knownParts: [String] = []
        if let goals = profile.goals, !goals.isEmpty {
            knownParts.append("Known goals: \(goals.joined(separator: ", "))")
        }
        if let constraints = profile.constraints, !constraints.isEmpty {
            knownParts.append("Known constraints: \(constraints.joined(separator: ", "))")
        }
        if let lc = profile.lifeContext, !lc.isEmpty {
            knownParts.append("Known life context: \(lc.joined(separator: ", "))")
        }
        let knownStr = knownParts.isEmpty ? "No existing profile yet." : knownParts.joined(separator: "\n")

        let prompt = """
        Current profile:
        \(knownStr)

        New conversation:
        User: \(userMessage)
        AI: \(aiResponse)

        Extract any NEW information about the user (not already in profile).
        """

        do {
            let result = try await geminiService.chat(
                message: prompt,
                history: [],
                systemPrompt: Self.extractSystemPrompt
            )

            // Parse JSON and update profile
            if let extracted = parseExtraction(result) {
                applyExtraction(extracted, to: profile)
                profile.lastLocalUpdate = Date()
                try? modelContext.save()
                print("[ProfileEvolutionService] Updated profile from conversation")
            }

            // Reset counter
            messagesSinceLastExtraction = 0
            lastExtractionTime = Date()

        } catch {
            print("[ProfileEvolutionService] Extraction failed: \(error)")
        }
    }

    /// Generate personality notes from accumulated profile data.
    ///
    /// Called periodically or when sufficient new data accumulates.
    /// Returns the generated personality string, or nil if insufficient data.
    func generatePersonality(modelContext: ModelContext) async -> String? {
        let profile = LocalProfile.getOrCreate(in: modelContext)

        // Build context from what we know
        var contextParts: [String] = []
        if let name = profile.name { contextParts.append("Name: \(name)") }
        if let age = profile.age { contextParts.append("Age: \(age)") }
        if let occupation = profile.occupation { contextParts.append("Occupation: \(occupation)") }
        if let goals = profile.goals, !goals.isEmpty {
            contextParts.append("Goals: \(goals.joined(separator: ", "))")
        }
        if let phase = profile.goalPhase {
            contextParts.append("Current phase: \(phase)")
            if let context = profile.phaseContext { contextParts.append("Phase context: \(context)") }
        }
        if let lc = profile.lifeContext, !lc.isEmpty {
            contextParts.append("Life context: \(lc.joined(separator: ", "))")
        }
        if let constraints = profile.constraints, !constraints.isEmpty {
            contextParts.append("Constraints: \(constraints.joined(separator: ", "))")
        }
        if let rn = profile.relationshipNotes, !rn.isEmpty {
            contextParts.append("Personality notes: \(rn)")
        }
        if let style = profile.communicationStyle {
            contextParts.append("Communication style: \(style)")
        }
        if let preferences = profile.preferences, !preferences.isEmpty {
            contextParts.append("Preferences: \(preferences.joined(separator: ", "))")
        }

        // Need at least some data to generate personality
        guard contextParts.count >= 3 else { return nil }

        let prompt = """
        Here's what we know about this user:

        \(contextParts.joined(separator: "\n"))

        Generate their personality profile.
        """

        do {
            let result = try await geminiService.chat(
                message: prompt,
                history: [],
                systemPrompt: Self.personalitySynthesisPrompt
            )

            // Clean up response (remove markdown code fences)
            var text = result.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.hasPrefix("```") {
                // Remove opening fence
                if let firstNewline = text.firstIndex(of: "\n") {
                    text = String(text[text.index(after: firstNewline)...])
                }
                // Remove closing fence
                if text.hasSuffix("```") {
                    text = String(text.dropLast(3))
                }
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Update profile with new personality
            profile.personalityNotes = text
            profile.lastPersonalityUpdate = Date()
            try? modelContext.save()

            print("[ProfileEvolutionService] Generated personality prompt (\(text.count) chars)")
            return text

        } catch {
            print("[ProfileEvolutionService] Personality generation failed: \(error)")
            return nil
        }
    }

    /// Check if personality needs regeneration.
    ///
    /// Triggers regeneration if:
    /// - No personality exists
    /// - Personality is stale (>7 days)
    /// - Significant profile changes since last generation
    func shouldRegeneratePersonality(modelContext: ModelContext) -> Bool {
        let profile = LocalProfile.getOrCreate(in: modelContext)

        // No personality yet
        guard let _ = profile.personalityNotes else { return true }

        // Stale (>7 days)
        if let lastUpdate = profile.lastPersonalityUpdate {
            let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdate, to: Date()).day ?? 0
            if daysSinceUpdate >= 7 { return true }
        } else {
            return true
        }

        // Profile updated significantly since personality was generated
        if let profileUpdate = profile.lastLocalUpdate,
           let personalityUpdate = profile.lastPersonalityUpdate,
           profileUpdate > personalityUpdate {
            // Check if enough time passed since profile update (debounce)
            let hoursSinceProfileUpdate = Calendar.current.dateComponents([.hour], from: profileUpdate, to: Date()).hour ?? 0
            if hoursSinceProfileUpdate >= 24 { return true }
        }

        return false
    }

    // MARK: - Private Helpers

    private func shouldExtract() -> Bool {
        // Always extract if first message or enough messages accumulated
        if messagesSinceLastExtraction >= extractionFrequency { return true }

        // For paid tier, also check time-based (at least 1 min between extractions)
        if GeminiTier.current == .paid, let last = lastExtractionTime {
            return Date().timeIntervalSince(last) >= 60
        }

        return false
    }

    // MARK: - Extraction Types

    private struct ExtractionResult: Codable {
        let identity: IdentityInfo?
        let current_state: CurrentState?
        let phase: PhaseInfo?
        let new_goals: [String]?
        let new_constraints: [String]?
        let new_preferences: [String]?
        let new_context: [String]?
        let new_life_context: [String]?
        let new_relationship_notes: [String]?
        let training: TrainingInfo?
        let nutrition_targets: NutritionInfo?
        let communication_style: String?
        let insights: [String]?

        struct IdentityInfo: Codable {
            let name: String?
            let age: Int?
            let height: String?
            let occupation: String?
        }

        struct CurrentState: Codable {
            let weight_lbs: Double?
            let body_fat_pct: Double?
        }

        struct PhaseInfo: Codable {
            let current_phase: String?
            let phase_context: String?
        }

        struct TrainingInfo: Codable {
            let days_per_week: Int?
            let style: [String]?
            let favorite_activities: [String]?
        }

        struct NutritionInfo: Codable {
            let calories: Int?
            let protein: Int?
            let carbs: Int?
            let fat: Int?
        }
    }

    private func parseExtraction(_ response: String) -> ExtractionResult? {
        var cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON object boundaries
        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[start...end])
        }

        guard let data = cleaned.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ExtractionResult.self, from: data)
    }

    private func applyExtraction(_ extraction: ExtractionResult, to profile: LocalProfile) {
        var changes: [String] = []

        // Identity
        if let id = extraction.identity {
            if let name = id.name, profile.name == nil {
                profile.name = name
                changes.append("name")
            }
            if let age = id.age, profile.age == nil {
                profile.age = age
                changes.append("age")
            }
            if let height = id.height, profile.heightString == nil {
                profile.heightString = height
                changes.append("height")
            }
            if let occupation = id.occupation, profile.occupation == nil {
                profile.occupation = occupation
                changes.append("occupation")
            }
        }

        // Current state
        if let state = extraction.current_state {
            if let weight = state.weight_lbs {
                profile.currentWeight = weight
                changes.append("weight")
            }
            if let bf = state.body_fat_pct {
                profile.bodyFatPct = bf
                changes.append("body_fat")
            }
        }

        // Phase
        if let phase = extraction.phase {
            if let p = phase.current_phase {
                profile.goalPhase = p
                changes.append("phase")
            }
            if let ctx = phase.phase_context {
                profile.phaseContext = ctx
                changes.append("phase_context")
            }
        }

        // Training
        if let training = extraction.training {
            if let days = training.days_per_week {
                profile.trainingDaysPerWeek = days
                changes.append("training_days")
            }
            if let activities = training.favorite_activities {
                appendUnique(activities, to: &profile.favoriteActivities)
                if !activities.isEmpty { changes.append("activities") }
            }
        }

        // Nutrition targets
        if let nutrition = extraction.nutrition_targets {
            var macros = profile.trainingDayMacros ?? MacroTargets()
            if let cal = nutrition.calories { macros.calories = cal }
            if let p = nutrition.protein { macros.protein = p }
            if let c = nutrition.carbs { macros.carbs = c }
            if let f = nutrition.fat { macros.fat = f }
            if !macros.isEmpty {
                profile.trainingDayMacros = macros
                changes.append("nutrition")
            }
        }

        // Append to arrays (avoiding duplicates)
        appendUnique(extraction.new_goals, to: &profile.goals)
        appendUnique(extraction.new_constraints, to: &profile.constraints)
        appendUnique(extraction.new_preferences, to: &profile.preferences)
        appendUnique(extraction.new_life_context, to: &profile.lifeContext)
        appendUnique(extraction.new_context, to: &profile.context)

        // Relationship notes (concatenate)
        if let notes = extraction.new_relationship_notes, !notes.isEmpty {
            let newNotes = notes.joined(separator: ". ")
            if let existing = profile.relationshipNotes, !existing.isEmpty {
                profile.relationshipNotes = existing + ". " + newNotes
            } else {
                profile.relationshipNotes = newNotes
            }
            changes.append("relationship")
        }

        // Communication style
        if let style = extraction.communication_style {
            profile.communicationStyle = style
            changes.append("style")
        }

        // Add insights to history
        if let insights = extraction.insights {
            for insight in insights {
                profile.addInsight(insight)
            }
        }

        if !changes.isEmpty {
            print("[ProfileEvolutionService] Applied: \(changes.joined(separator: ", "))")
        }
    }

    private func appendUnique(_ new: [String]?, to existing: inout [String]?) {
        guard let new = new, !new.isEmpty else { return }
        var list = existing ?? []
        for item in new where !list.contains(item) {
            list.append(item)
        }
        existing = list
    }
}

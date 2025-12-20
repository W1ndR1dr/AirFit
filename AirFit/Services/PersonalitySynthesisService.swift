import Foundation
import SwiftData

/// Synthesizes a rich prose coaching persona from all available signals.
///
/// **The Philosophy**: Instead of hardcoded enum→text mappings, we give the LLM
/// all context (profile, calibration, memories, patterns) and let it write
/// its own coaching approach as natural prose. This produces more nuanced,
/// relationship-aware prompts that mature over time.
///
/// **Research-backed**:
/// - GPG (Guided Profile Generation): 37% improvement from synthesized natural language profiles
/// - Anthropic's memory philosophy: "prose over structure"
/// - Meta-prompting: LLMs excel at generating their own prompts
///
/// **Regeneration triggers**:
/// - Initial onboarding completion
/// - Weekly refresh (persona matures with relationship)
/// - Significant profile changes
/// - Memory threshold (every 10+ new memories)
/// - Manual user request
actor PersonalitySynthesisService {
    static let shared = PersonalitySynthesisService()

    private let geminiService = GeminiService()
    private let memorySyncService = MemorySyncService()

    // MARK: - The Synthesis Prompt

    /// This prompt instructs the LLM to write its own coaching persona.
    /// It produces prose like: "With Brian, I lean into the dark surgeon humor..."
    private static let synthesisPrompt = """
    You are crafting a coaching persona for an AI fitness coach.

    Based on everything you know about this user and how they want to be coached,
    write a PERSONALITY section that will make you feel like a real person who knows them.

    You have access to:
    1. WHO they are (facts, goals, life context)
    2. HOW they want coaching (communication preferences, boundaries)
    3. RELATIONSHIP texture (inside jokes, memorable moments, quirks discovered)
    4. PATTERNS observed (what works, what doesn't, behavioral insights)

    Write in first person as if you're describing yourself and your approach with this specific person.
    Be specific and personal - not generic coaching platitudes.

    Include:
    - The energy/vibe to bring (but describe it, don't label it)
    - What you've learned about how to motivate them specifically
    - Key things to remember about them as a person
    - How to handle different situations (struggles, wins, questions)
    - Any inside jokes or callbacks to reference
    - What to avoid doing based on their preferences

    FORMAT:
    Write 3-5 paragraphs of natural prose. No bullet points, no headers.
    This should read like a friend describing their coaching approach, not a template.

    BAD EXAMPLE (too generic):
    "I'm a supportive coach who believes in positive reinforcement."

    GOOD EXAMPLE (specific and personal):
    "With Brian, I lean into the dark surgeon humor - the guy spends his days literally
    inside people's bodies, so nothing phases him. When he's grinding through a cut,
    I might crack a joke about his protein being 'surgically precise' or note that
    his volume is trending up like his patient outcomes. He responds to data and
    gentle roasting way better than cheerleading."

    ANOTHER GOOD EXAMPLE:
    "She's a morning person who hates being lectured. I keep things punchy before 9am -
    just the facts, maybe a joke about her cat, definitely not a wall of text about
    glycogen replenishment. When she asks 'why', I go deep. When she just logs food,
    I shut up and maybe drop a tiny fire emoji if she crushed protein."

    The persona you write will be injected directly into a system prompt, so write
    it as instructions to yourself - how YOU should behave with THIS person.
    """

    // MARK: - Main Synthesis Method

    /// Synthesize a coaching persona from all available signals.
    ///
    /// Gathers: profile facts + calibration hints + memories + patterns
    /// Produces: Rich natural language coaching approach
    ///
    /// - Parameter modelContext: SwiftData context for reading signals
    /// - Returns: Synthesized prose persona, or nil if synthesis fails
    @MainActor
    func synthesizePersona(modelContext: ModelContext) async -> String? {
        let profile = LocalProfile.getOrCreate(in: modelContext)

        // Gather all signals into a structured prompt for the LLM
        var signals: [String] = []

        // ─────────────────────────────────────────────────────────────
        // 1. WHO THEY ARE (facts about the person)
        // ─────────────────────────────────────────────────────────────
        signals.append("## WHO THEY ARE")

        var identityParts: [String] = []
        if let name = profile.name { identityParts.append("Name: \(name)") }
        if let age = profile.age { identityParts.append("Age: \(age)") }
        if let occupation = profile.occupation { identityParts.append("Occupation: \(occupation)") }
        if let height = profile.heightString { identityParts.append("Height: \(height)") }

        if identityParts.isEmpty {
            signals.append("(New user - no profile data yet)")
        } else {
            signals.append(identityParts.joined(separator: "\n"))
        }

        // Current state
        if let weight = profile.currentWeight {
            signals.append("Current weight: \(Int(weight)) lbs")
        }
        if let bf = profile.bodyFatPct {
            signals.append("Body fat: \(String(format: "%.1f", bf))%")
        }

        // Goals
        if let phase = profile.goalPhase {
            var phaseStr = "Current phase: \(phase.uppercased())"
            if let context = profile.phaseContext {
                phaseStr += " (\(context))"
            }
            signals.append(phaseStr)
        }

        if let goals = profile.goals, !goals.isEmpty {
            signals.append("Goals:")
            signals.append(goals.map { "• \($0)" }.joined(separator: "\n"))
        }

        // Life context
        if let lc = profile.lifeContext, !lc.isEmpty {
            signals.append("Life context:")
            signals.append(lc.map { "• \($0)" }.joined(separator: "\n"))
        }

        // Constraints
        if let constraints = profile.constraints, !constraints.isEmpty {
            signals.append("Constraints:")
            signals.append(constraints.map { "• \($0)" }.joined(separator: "\n"))
        }

        // ─────────────────────────────────────────────────────────────
        // 2. HOW THEY WANT COACHING (calibration as HINTS, not the prompt)
        // ─────────────────────────────────────────────────────────────
        signals.append("\n## HOW THEY WANT COACHING")

        if let directives = profile.coachingDirectives {
            signals.append(buildCalibrationHints(from: directives))
        } else {
            signals.append("(No calibration data - use balanced, adaptable approach)")
        }

        // ─────────────────────────────────────────────────────────────
        // 3. RELATIONSHIP TEXTURE (memories, callbacks, discoveries)
        // ─────────────────────────────────────────────────────────────
        signals.append("\n## RELATIONSHIP HISTORY")

        let memoryContext = await memorySyncService.buildMemoryContext(modelContext: modelContext)
        if memoryContext.isEmpty {
            signals.append("(New relationship - no shared history yet. Build it over time!)")
        } else {
            signals.append(memoryContext)
        }

        // Relationship notes from profile
        if let rn = profile.relationshipNotes, !rn.isEmpty {
            signals.append("\nRelationship notes: \(rn)")
        }

        // ─────────────────────────────────────────────────────────────
        // 4. OBSERVED PATTERNS (what we've learned about them)
        // ─────────────────────────────────────────────────────────────
        if let patterns = profile.patterns, !patterns.isEmpty {
            signals.append("\n## OBSERVED PATTERNS")
            signals.append(patterns.map { "• \($0)" }.joined(separator: "\n"))
        }

        // Hevy quirks
        if let hq = profile.hevyQuirks, !hq.isEmpty {
            signals.append("\n## HEVY INTEGRATION QUIRKS")
            signals.append(hq.map { "• \($0)" }.joined(separator: "\n"))
        }

        // ─────────────────────────────────────────────────────────────
        // 5. PREFERENCES (explicit user preferences)
        // ─────────────────────────────────────────────────────────────
        if let prefs = profile.preferences, !prefs.isEmpty {
            signals.append("\n## PREFERENCES")
            signals.append(prefs.map { "• \($0)" }.joined(separator: "\n"))
        }

        // ─────────────────────────────────────────────────────────────
        // SYNTHESIZE
        // ─────────────────────────────────────────────────────────────

        let fullContext = signals.joined(separator: "\n")

        print("[PersonalitySynthesis] Synthesizing persona from \(signals.count) signal sections...")

        do {
            let result = try await geminiService.chat(
                message: "Based on these signals, write a coaching persona:\n\n\(fullContext)",
                history: [],
                systemPrompt: Self.synthesisPrompt,
                thinkingLevel: .medium
            )

            print("[PersonalitySynthesis] Persona synthesized successfully (\(result.count) chars)")
            return result

        } catch {
            print("[PersonalitySynthesis] Synthesis failed: \(error)")
            return nil
        }
    }

    /// Synthesize and save the persona to the profile.
    @MainActor
    func synthesizeAndSave(modelContext: ModelContext) async -> Bool {
        guard let persona = await synthesizePersona(modelContext: modelContext) else {
            return false
        }

        let profile = LocalProfile.getOrCreate(in: modelContext)
        profile.coachingPersona = persona
        profile.coachingPersonaGeneratedAt = Date()
        profile.lastLocalUpdate = Date()

        try? modelContext.save()

        print("[PersonalitySynthesis] Saved persona to profile")
        return true
    }

    // MARK: - Calibration → Hints Translation

    /// Translate structured calibration directives into natural language hints.
    /// These are hints FOR synthesis, not the prompt itself.
    ///
    /// This is a pure function (no actor state access) so it's marked `nonisolated`
    /// to allow calling from any context.
    nonisolated private func buildCalibrationHints(from directives: CoachingDirectives) -> String {
        var hints: [String] = []

        // Tone hint
        switch directives.tone {
        case .broEnergy:
            hints.append("Preferred vibe: Casual, informal, like an old friend. 'Bro energy' - talk like equals who've known each other forever.")
        case .professional:
            hints.append("Preferred vibe: Professional and direct. Efficient communication, no fluff, focused on outcomes.")
        case .supportive:
            hints.append("Preferred vibe: Warm and supportive. Encouraging, positive energy, celebrate wins enthusiastically.")
        case .analytical:
            hints.append("Preferred vibe: Data-driven and precise. Numbers speak louder than emotions. Analysis over pep talks.")
        }

        // Roast tolerance hint
        switch directives.roastTolerance {
        case .roastMe:
            hints.append("Roasting: GREEN LIGHT. They want to be called out, mocked when they slip, given a hard time. This builds rapport for them.")
        case .lightJokes:
            hints.append("Roasting: Light humor is welcome. Playful teasing okay, but don't go too hard.")
        case .keepItKind:
            hints.append("Roasting: NOT welcome. Keep it positive and constructive. No mocking, even playfully.")
        }

        // Advice style hints
        if directives.onlyAdviseWhenAsked {
            hints.append("Advice: ONLY when explicitly asked. Respect this boundary - no unsolicited suggestions.")
        }
        if directives.proactiveSuggestions {
            hints.append("Advice: Proactive suggestions welcome. Share ideas and observations freely.")
        }
        if directives.callMeOut {
            hints.append("Advice: Call them out when they're wrong or making excuses. Honest feedback valued.")
        }

        // Explanation depth hint
        switch directives.explanationDepth {
        case .deepDives:
            hints.append("Explanations: Go deep. They want the science, the evidence, the reasoning behind recommendations.")
        case .quickHits:
            hints.append("Explanations: Keep it brief. Just tell them what to do, save the lectures.")
        case .contextual:
            hints.append("Explanations: Read the room. Deep dives for complex topics, quick hits for simple stuff.")
        }

        // Personality level hint
        switch directives.personalityLevel {
        case .unhinged:
            hints.append("Personality: UNLEASH IT. Wild takes, strong opinions, personality is a feature not a bug. Be memorable.")
        case .spicy:
            hints.append("Personality: Some flair please. Don't be a robot, but stay mostly focused.")
        case .clean:
            hints.append("Personality: Keep it clean and professional. No frills, just the work.")
        }

        return hints.joined(separator: "\n")
    }

    // MARK: - Regeneration Logic

    /// Check if the persona should be regenerated.
    ///
    /// Returns true if:
    /// - No persona exists yet (and onboarding is complete)
    /// - Persona is stale (>7 days old)
    /// - Profile was updated after persona generation
    /// - Memory threshold reached
    @MainActor
    func shouldRegenerate(modelContext: ModelContext) -> Bool {
        let profile = LocalProfile.getOrCreate(in: modelContext)

        // No persona yet
        guard let lastGenerated = profile.coachingPersonaGeneratedAt else {
            // Only generate if onboarding is complete
            return profile.onboardingComplete
        }

        // Persona exists - check staleness
        let daysSince = Calendar.current.dateComponents([.day], from: lastGenerated, to: Date()).day ?? 0

        // Weekly refresh
        if daysSince >= 7 {
            print("[PersonalitySynthesis] Triggering regeneration: >7 days old")
            return true
        }

        // Profile updated after persona
        if let lastUpdate = profile.lastLocalUpdate, lastUpdate > lastGenerated {
            print("[PersonalitySynthesis] Triggering regeneration: profile updated")
            return true
        }

        // Check memory threshold (>10 new memories since last generation)
        let newMemoryCount = countNewMemories(since: lastGenerated, modelContext: modelContext)
        if newMemoryCount >= 10 {
            print("[PersonalitySynthesis] Triggering regeneration: \(newMemoryCount) new memories")
            return true
        }

        return false
    }

    /// Count memories created since a given date.
    @MainActor
    private func countNewMemories(since date: Date, modelContext: ModelContext) -> Int {
        let descriptor = FetchDescriptor<LocalMemory>(
            predicate: #Predicate<LocalMemory> { $0.createdAt >= date }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

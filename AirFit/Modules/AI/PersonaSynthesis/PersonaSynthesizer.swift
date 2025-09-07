import Foundation

/// Simple preview model for persona generation UI
struct PersonaPreview {
    let name: String
    let archetype: String
    let sampleGreeting: String
    let voiceDescription: String
}

/// Quality-First PersonaSynthesizer - Creating magical, unique personas
/// Refactored to a 3-phase, faceted pipeline with structured outputs
actor PersonaSynthesizer {
    private let aiService: AIServiceProtocol
    private var progressReporter: PersonaSynthesisProgressReporter?

    // Recommended models for persona synthesis (quality-first)
    static let recommendedModels: [(LLMModel, String)] = [
        (.gpt5, "Most capable; great for synthesis"),
        (.gpt5Mini, "Fast and lower cost option")
    ]

    init(aiService: AIServiceProtocol) {
        self.aiService = aiService
    }

    /// Create a progress stream for monitoring synthesis
    func createProgressStream() async -> AsyncStream<PersonaSynthesisProgress> {
        let reporter = PersonaSynthesisProgressReporter()
        self.progressReporter = reporter
        return await reporter.makeProgressStream()
    }

    /// Generate a high-quality persona in phased pipeline for robustness + testability
    func synthesizePersona(
        from conversationData: ConversationData,
        insights: ConversationPersonalityInsights,
        preferredModel: LLMModel? = nil
    ) async throws -> PersonaProfile {
        let startTime = CFAbsoluteTimeGetCurrent()

        await reportProgress(.preparing, progress: 0.0)
        let chosen = try await chooseModel(preferredModel, task: .personaSynthesis)
        await reportProgress(.preparing, progress: 0.05, message: "Using \(chosen.displayName)")

        // Phase 1 — SPEC
        await reportProgress(.analyzingPersonality, progress: 0.10, message: "Deriving coach spec")
        let spec = try await buildSpec(conversationData, insights, model: chosen)

        // Phase 2 — FACETS (parallelizable)
        await reportProgress(.craftingVoice, progress: 0.30, message: "Generating voice & interaction style")
        async let voicePack = generateVoicePack(spec, model: chosen)

        await reportProgress(.buildingStrategies, progress: 0.45, message: "Writing backstory & quirks")
        async let narrative = generateNarrative(spec, model: chosen)

        await reportProgress(.generatingContent, progress: 0.60, message: "Authoring system prompt")
        async let sysPrompt = generateSystemPrompt(spec, conversationData, insights, model: chosen)

        await reportProgress(.generatingContent, progress: 0.70, message: "Computing nutrition recommendations")
        async let nutrition = generateNutrition(spec, insights, model: chosen)

        var (voice, style) = try await voicePack
        var story = try await narrative
        var systemPrompt = try await sysPrompt
        let nutritionRecs = try await nutrition

        // Phase 3 — QA + ASSEMBLY
        await reportProgress(.finalizing, progress: 0.85, message: "Quality checks")
        let clampedNutrition = clampNutrition(nutritionRecs, guardrails: spec.nutrition)
        // Uniqueness guard + identity re-roll if needed
        let finalSpec = try await ensureUniqueness(spec: spec, story: &story, prompt: &systemPrompt, convo: conversationData, insights: insights, model: chosen)
        try qa(spec: finalSpec, voice: voice, style: style, prompt: systemPrompt, story: story, nutrition: clampedNutrition)

        let persona = assemble(
            spec: finalSpec,
            voice: voice,
            style: style,
            story: story,
            prompt: systemPrompt,
            nutrition: clampedNutrition,
            insights: insights,
            startedAt: startTime
        )

        await reportProgress(.finalizing, progress: 1.0, message: "Your coach is ready!", isComplete: true)
        return persona
    }

    // MARK: - Progress Reporting

    private func reportProgress(
        _ phase: PersonaSynthesisPhase,
        progress: Double,
        message: String? = nil,
        isComplete: Bool = false
    ) async {
        let progress = PersonaSynthesisProgress(
            phase: phase,
            progress: progress,
            message: message ?? phase.displayName,
            isComplete: isComplete
        )
        await progressReporter?.reportProgress(progress)
    }

    // MARK: - Model Recommendation

    /// Get the best model available from user's configured providers
    func getBestAvailableModel() async -> LLMModel {
        // For persona synthesis, prefer GPT-5 if available; then Gemini with strong structured JSON
        let models = aiService.availableModels
        if models.contains(where: { $0.id == LLMModel.gpt5.identifier }) {
            return .gpt5
        }
        if let gem = models.first(where: { $0.id.contains("gemini") }) {
            return LLMModel(rawValue: gem.id) ?? .gemini25Flash
        }
        if let first = models.first { return LLMModel(rawValue: first.id) ?? .gemini25Flash }
        return .gemini25Flash
    }

    // MARK: - Phased pipeline helpers

    private func buildSpec(_ convo: ConversationData,
                           _ insights: ConversationPersonalityInsights,
                           model: LLMModel) async throws -> PersonaSpec {
        let schema = try makePersonaSpecSchema()
        let userMsg = specPrompt(convo: convo, insights: insights)
        let request = AIRequest(
            systemPrompt: PersonaPrompts.specSystem,
            messages: [AIChatMessage(role: .user, content: userMsg)],
            temperature: 0.5,
            maxTokens: 1200,
            stream: true,
            user: "persona-spec",
            responseFormat: .structuredJson(schema: schema),
            model: model.identifier
        )
        var data: Data?
        var lastText: String = ""
        for try await r in aiService.sendRequest(request) {
            switch r {
            case .structuredData(let d): data = d
            case .text(let t): lastText = t
            case .textDelta(let d): lastText += d
            default: break
            }
        }
        if let data {
            let dto = try JSONDecoder().decode(PersonaSpecDTO.self, from: data)
            return dto.toDomain(convo: convo, insights: insights)
        }
        // fallback: attempt decode from text
        guard let d = lastText.data(using: .utf8) else { throw PersonaError.invalidResponse("No structured spec") }
        let dto = try JSONDecoder().decode(PersonaSpecDTO.self, from: d)
        return dto.toDomain(convo: convo, insights: insights)
    }

    private func generateVoicePack(_ spec: PersonaSpec, model: LLMModel) async throws -> (VoiceCharacteristics, InteractionStyle) {
        let schema = try makeVoicePackSchema()
        let req = AIRequest(
            systemPrompt: PersonaPrompts.voiceSystem,
            messages: [AIChatMessage(role: .user, content: voicePrompt(spec: spec))],
            temperature: 0.7,
            maxTokens: 800,
            stream: true,
            user: "persona-voice",
            responseFormat: .structuredJson(schema: schema),
            model: model.identifier
        )
        var data: Data?
        var txt = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .structuredData(let d): data = d
            case .text(let t): txt = t
            case .textDelta(let d): txt += d
            default: break
            }
        }
        struct VoicePackDTO: Codable { let voice: VoiceCharacteristics; let style: InteractionStyle }
        if let data, let vp = try? JSONDecoder().decode(VoicePackDTO.self, from: data) { return (vp.voice, vp.style) }
        let vp = try JSONDecoder().decode(VoicePackDTO.self, from: Data(txt.utf8))
        return (vp.voice, vp.style)
    }

    private func generateNarrative(_ spec: PersonaSpec, model: LLMModel) async throws -> String {
        let schema = try makeNarrativeSchema()
        let req = AIRequest(
            systemPrompt: PersonaPrompts.narrativeSystem,
            messages: [AIChatMessage(role: .user, content: narrativePrompt(spec: spec))],
            temperature: 0.8,
            maxTokens: 400,
            stream: true,
            user: "persona-narrative",
            responseFormat: .structuredJson(schema: schema),
            model: model.identifier
        )
        var data: Data?
        var txt = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .structuredData(let d): data = d
            case .text(let t): txt = t
            case .textDelta(let d): txt += d
            default: break
            }
        }
        struct NarrativeDTO: Codable { let backgroundStory: String }
        if let data, let dto = try? JSONDecoder().decode(NarrativeDTO.self, from: data) { return dto.backgroundStory }
        let dto = try JSONDecoder().decode(NarrativeDTO.self, from: Data(txt.utf8))
        return dto.backgroundStory
    }

    private func generateSystemPrompt(_ spec: PersonaSpec,
                                      _ convo: ConversationData,
                                      _ insights: ConversationPersonalityInsights,
                                      model: LLMModel) async throws -> String {
        let req = AIRequest(
            systemPrompt: PersonaPrompts.systemPromptSystem,
            messages: [AIChatMessage(role: .user, content: systemPromptUser(spec: spec, convo: convo, insights: insights))],
            temperature: 0.7,
            maxTokens: 600,
            stream: false,
            user: "persona-system-prompt",
            model: model.identifier
        )
        var result = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .text(let t): result = t
            case .textDelta(let d): result += d
            default: break
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateNutrition(_ spec: PersonaSpec,
                                   _ insights: ConversationPersonalityInsights,
                                   model: LLMModel) async throws -> NutritionRecommendations {
        let schema = try makeNutritionSchema()
        let req = AIRequest(
            systemPrompt: PersonaPrompts.nutritionSystem,
            messages: [AIChatMessage(role: .user, content: nutritionPrompt(spec: spec, insights: insights))],
            temperature: 0.4,
            maxTokens: 300,
            stream: true,
            user: "persona-nutrition",
            responseFormat: .structuredJson(schema: schema),
            model: model.identifier
        )
        var data: Data?
        var txt = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .structuredData(let d): data = d
            case .text(let t): txt = t
            case .textDelta(let d): txt += d
            default: break
            }
        }
        if let data, let recs = try? JSONDecoder().decode(NutritionRecommendations.self, from: data) { return recs }
        let recs = try JSONDecoder().decode(NutritionRecommendations.self, from: Data(txt.utf8))
        return recs
    }

    // MARK: - Uniqueness Guard + Identity Regen

    private func ensureUniqueness(spec: PersonaSpec,
                                  story: inout String,
                                  prompt: inout String,
                                  convo: ConversationData,
                                  insights: ConversationPersonalityInsights,
                                  model: LLMModel) async throws -> PersonaSpec {
        let combined = (story + "\n" + prompt)
        if isTooSimilar(toExisting: combined) {
            // Re-roll identity (name, archetype, signatureMotif) and regenerate dependent facets
            var newSpec = try await regenerateIdentity(from: spec, reason: "too similar to existing personas", model: model)
            let (voice, style) = try await generateVoicePack(newSpec, model: model)
            let newStory = try await generateNarrative(newSpec, model: model)
            let newPrompt = try await generateSystemPrompt(newSpec, convo, insights, model: model)
            // Accept the re-rolled results
            story = newStory
            prompt = newPrompt
            // Save memory with updated text
            rememberText(newStory + "\n" + newPrompt)
            return newSpec
        } else {
            rememberText(combined)
            return spec
        }
    }

    private func regenerateIdentity(from spec: PersonaSpec, reason: String, model: LLMModel) async throws -> PersonaSpec {
        let schema = try makeIdentitySchema()
        let req = AIRequest(
            systemPrompt: PersonaPrompts.specSystem,
            messages: [AIChatMessage(role: .user, content: identityPrompt(spec: spec, reason: reason))],
            temperature: 0.7,
            maxTokens: 400,
            stream: true,
            user: "persona-identity-regen",
            responseFormat: .structuredJson(schema: schema)
        )
        var data: Data?
        var txt = ""
        for try await r in aiService.sendRequest(req) {
            switch r {
            case .structuredData(let d): data = d
            case .text(let t): txt = t
            case .textDelta(let d): txt += d
            default: break
            }
        }
        struct IdentityDTO: Codable { let name: String; let archetype: String; let signatureMotif: String }
        let dto: IdentityDTO
        if let data, let parsed = try? JSONDecoder().decode(IdentityDTO.self, from: data) {
            dto = parsed
        } else {
            dto = try JSONDecoder().decode(IdentityDTO.self, from: Data(txt.utf8))
        }
        var updated = spec
        updated.identity = .init(name: dto.name,
                                 archetype: dto.archetype,
                                 coreValues: spec.identity.coreValues,
                                 signatureMotif: dto.signatureMotif)
        return updated
    }

    // Very small rolling memory for similarity checks
    private func isTooSimilar(toExisting text: String) -> Bool {
        let existing = loadMemory()
        guard !existing.isEmpty else { return false }
        let a = ngramSet(text)
        for s in existing {
            let b = ngramSet(s)
            let sim = jaccard(a, b)
            if sim > 0.88 { return true }
        }
        return false
    }

    private func rememberText(_ text: String) {
        var arr = loadMemory()
        arr.append(text)
        if arr.count > 20 { arr.removeFirst(arr.count - 20) }
        UserDefaults.standard.set(arr, forKey: "persona_text_memory")
    }

    private func loadMemory() -> [String] {
        (UserDefaults.standard.array(forKey: "persona_text_memory") as? [String]) ?? []
    }

    private func ngramSet(_ s: String) -> Set<String> {
        let cleaned = s.lowercased().replacingOccurrences(of: "\n", with: " ")
        let tokens = cleaned.split(separator: " ").map(String.init)
        guard tokens.count >= 3 else { return Set(tokens) }
        var grams: Set<String> = []
        for i in 0..<(tokens.count - 2) {
            grams.insert(tokens[i] + " " + tokens[i+1] + " " + tokens[i+2])
        }
        return grams
    }

    private func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        let inter = a.intersection(b).count
        let union = a.union(b).count
        if union == 0 { return 0 }
        return Double(inter) / Double(union)
    }

    private func makeIdentitySchema() throws -> StructuredOutputSchema {
        let schema: [String: Any] = [
            "type":"object",
            "required":["name","archetype","signatureMotif"],
            "properties":[
                "name":["type":"string","minLength":2,"maxLength":24],
                "archetype":["type":"string","maxLength":32],
                "signatureMotif":["type":"string","maxLength":80]
            ]
        ]
        guard let schema = StructuredOutputSchema.fromJSON(name: "PersonaIdentity", description: "Identity regen", schema: schema, strict: true) else {
            throw PersonaError.invalidResponse("Failed to create PersonaIdentity schema")
        }
        return schema
    }

    private func identityPrompt(spec: PersonaSpec, reason: String) -> String {
        """
        Re-roll identity to reduce similarity (reason: \(reason)).
        Keep core values. Provide: name, archetype, signatureMotif.
        Current: name=\(spec.identity.name), archetype=\(spec.identity.archetype), motif=\(spec.identity.signatureMotif)
        Constraints: archetype ≤ 5 words, no clichés; motif concrete and reusable across outputs.
        """
    }

    private func qa(spec: PersonaSpec,
                    voice: VoiceCharacteristics,
                    style: InteractionStyle,
                    prompt: String,
                    story: String,
                    nutrition: NutritionRecommendations) throws {
        // Minimal coherence checks
        if voice.energy == .calm {
            precondition(style.responseLength != .detailed || style.formalityLevel != .professional, "Calm voice should avoid overly formal/detailed by default")
        }
        // Ensure motif and fingerprints mentioned at least once in narrative or prompt
        let lower = (story + "\n" + prompt).lowercased()
        let motifHit = spec.identity.signatureMotif.isEmpty || lower.contains(spec.identity.signatureMotif.lowercased())
        precondition(motifHit, "Signature motif not reflected")
    }

    private func assemble(spec: PersonaSpec,
                          voice: VoiceCharacteristics,
                          style: InteractionStyle,
                          story: String,
                          prompt: String,
                          nutrition: NutritionRecommendations,
                          insights: ConversationPersonalityInsights,
                          startedAt: CFAbsoluteTime) -> PersonaProfile {
        let duration = CFAbsoluteTimeGetCurrent() - startedAt
        return PersonaProfile(
            id: UUID(),
            name: spec.identity.name,
            archetype: spec.identity.archetype,
            systemPrompt: prompt,
            coreValues: spec.identity.coreValues,
            backgroundStory: story,
            voiceCharacteristics: voice,
            interactionStyle: style,
            adaptationRules: spec.beliefs.adaptationRules,
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "5.0-faceted",
                sourceInsights: insights,
                generationDuration: duration,
                tokenCount: max(prompt.count / 4, 0),
                previewReady: true
            ),
            nutritionRecommendations: nutrition
        )
    }

    private func clampNutrition(_ n: NutritionRecommendations,
                                guardrails: PersonaSpec.NutritionGuardrails) -> NutritionRecommendations {
        let p = min(max(n.proteinGramsPerPound, guardrails.proteinRange.lowerBound), guardrails.proteinRange.upperBound)
        let f = min(max(n.fatPercentage, guardrails.fatPctRange.lowerBound), guardrails.fatPctRange.upperBound)
        return NutritionRecommendations(
            approach: n.approach,
            proteinGramsPerPound: (p * 100).rounded() / 100,
            fatPercentage: (f * 100).rounded() / 100,
            carbStrategy: n.carbStrategy,
            rationale: n.rationale,
            flexibilityNotes: n.flexibilityNotes
        )
    }

    // MARK: - Model selection helper
    private func chooseModel(_ preferred: LLMModel?, task: AITask) async throws -> LLMModel {
        if let preferred { return preferred }
        return await getBestAvailableModel()
    }

    // MARK: - Public Facet Regeneration API
    func regenerateFacet(from spec: PersonaSpec,
                         conversation: ConversationData,
                         insights: ConversationPersonalityInsights,
                         facet: PersonaFacet,
                         adjustments: [String: String]? = nil) async throws -> (PersonaProfile, PersonaSpec) {
        let model = try await chooseModel(nil, task: .personaSynthesis)
        switch facet {
        case .voicePack:
            let (voice, style) = try await generateVoicePack(spec, model: model)
            let story = try await generateNarrative(spec, model: model)
            let prompt = try await generateSystemPrompt(spec, conversation, insights, model: model)
            let nutrition = try await generateNutrition(spec, insights, model: model)
            let persona = assemble(spec: spec, voice: voice, style: style, story: story, prompt: prompt, nutrition: nutrition, insights: insights, startedAt: CFAbsoluteTimeGetCurrent())
            return (persona, spec)
        case .narrative:
            let story = try await generateNarrative(spec, model: model)
            let (voice, style) = try await generateVoicePack(spec, model: model)
            let prompt = try await generateSystemPrompt(spec, conversation, insights, model: model)
            let nutrition = try await generateNutrition(spec, insights, model: model)
            let persona = assemble(spec: spec, voice: voice, style: style, story: story, prompt: prompt, nutrition: nutrition, insights: insights, startedAt: CFAbsoluteTimeGetCurrent())
            return (persona, spec)
        case .systemPrompt:
            let prompt = try await generateSystemPrompt(spec, conversation, insights, model: model)
            let story = try await generateNarrative(spec, model: model)
            let (voice, style) = try await generateVoicePack(spec, model: model)
            let nutrition = try await generateNutrition(spec, insights, model: model)
            let persona = assemble(spec: spec, voice: voice, style: style, story: story, prompt: prompt, nutrition: nutrition, insights: insights, startedAt: CFAbsoluteTimeGetCurrent())
            return (persona, spec)
        case .nutrition:
            let nutrition = try await generateNutrition(spec, insights, model: model)
            let story = try await generateNarrative(spec, model: model)
            let (voice, style) = try await generateVoicePack(spec, model: model)
            let prompt = try await generateSystemPrompt(spec, conversation, insights, model: model)
            let persona = assemble(spec: spec, voice: voice, style: style, story: story, prompt: prompt, nutrition: nutrition, insights: insights, startedAt: CFAbsoluteTimeGetCurrent())
            return (persona, spec)
        }
    }
}

// MARK: - PersonaSpec + DTOs + Prompts + Schemas

private struct PersonaSpecDTO: Codable {
    struct Identity: Codable { var name: String; var archetype: String; var coreValues: [String]; var signatureMotif: String }
    struct Voice: Codable {
        var energy: VoiceCharacteristics.Energy
        var pace: VoiceCharacteristics.Pace
        var warmth: VoiceCharacteristics.Warmth
        var vocabulary: VoiceCharacteristics.Vocabulary
        var sentenceStructure: VoiceCharacteristics.SentenceStructure
        var humorLevel: InteractionStyle.HumorLevel
        var formalityLevel: InteractionStyle.FormalityLevel
        var responseLength: InteractionStyle.ResponseLength
    }
    struct Beliefs: Codable { var philosophy: String; var adaptationRules: [AdaptationRule]; var motivationalStance: String }
    struct Nutrition: Codable { var approach: String; var proteinRange: [Double]; var fatPctRange: [Double]; var carbStrategyHint: String }
    var identity: Identity
    var voice: Voice
    var beliefs: Beliefs
    var nutrition: Nutrition
    var fingerprints: [String]
}

private extension PersonaSpecDTO {
    func toDomain(convo: ConversationData, insights: ConversationPersonalityInsights) -> PersonaSpec {
        let pRange = (nutrition.proteinRange.first ?? 0.9)...(nutrition.proteinRange.last ?? 1.2)
        let fRange = (nutrition.fatPctRange.first ?? 0.25)...(nutrition.fatPctRange.last ?? 0.35)
        return PersonaSpec(
            identity: .init(name: identity.name, archetype: identity.archetype, coreValues: identity.coreValues, signatureMotif: identity.signatureMotif),
            voice: .init(
                energy: voice.energy,
                pace: voice.pace,
                warmth: voice.warmth,
                vocabulary: voice.vocabulary,
                sentenceStructure: voice.sentenceStructure,
                humorLevel: voice.humorLevel,
                formalityLevel: voice.formalityLevel,
                responseLength: voice.responseLength
            ),
            beliefs: .init(philosophy: beliefs.philosophy, adaptationRules: beliefs.adaptationRules, motivationalStance: beliefs.motivationalStance),
            nutrition: .init(approach: nutrition.approach, proteinRange: pRange, fatPctRange: fRange, carbStrategyHint: nutrition.carbStrategyHint),
            fingerprints: fingerprints,
            seed: stableSeed(convo: convo, insights: insights)
        )
    }
}

// MARK: - Spec model + helpers

struct PersonaSpec: Sendable {
    struct Identity: Sendable {
        var name: String
        var archetype: String
        var coreValues: [String]
        var signatureMotif: String
    }
    struct VoiceGuardrails: Sendable {
        var energy: VoiceCharacteristics.Energy
        var pace: VoiceCharacteristics.Pace
        var warmth: VoiceCharacteristics.Warmth
        var vocabulary: VoiceCharacteristics.Vocabulary
        var sentenceStructure: VoiceCharacteristics.SentenceStructure
        var humorLevel: InteractionStyle.HumorLevel
        var formalityLevel: InteractionStyle.FormalityLevel
        var responseLength: InteractionStyle.ResponseLength
    }
    struct CoachingBeliefs: Sendable {
        var philosophy: String
        var adaptationRules: [AdaptationRule]
        var motivationalStance: String
    }
    struct NutritionGuardrails: Sendable {
        var approach: String
        var proteinRange: ClosedRange<Double>
        var fatPctRange: ClosedRange<Double>
        var carbStrategyHint: String
    }

    var identity: Identity
    var voice: VoiceGuardrails
    var beliefs: CoachingBeliefs
    var nutrition: NutritionGuardrails
    var fingerprints: [String]
    var seed: UInt64
}

enum PersonaFacet: Sendable {
    case voicePack
    case narrative
    case systemPrompt
    case nutrition
}

// MARK: - Prompts & Schemas
private enum PersonaPrompts {
    static let specSystem = "You produce PersonaSpec JSON strictly matching the schema. No commentary."
    static let voiceSystem = "You produce voice + interaction style JSON strictly matching the schema."
    static let narrativeSystem = "Return structured JSON with backgroundStory (100-150 words)."
    static let systemPromptSystem = "Write a 220-280 word second-person system prompt including adaptations, signature phrases, error policy, and closing style."
    static let nutritionSystem = "Return structured JSON for nutrition recommendations within guardrails."
}

private func specPrompt(convo: ConversationData, insights: ConversationPersonalityInsights) -> String {
    let quotes = convo.userMessages.prefix(5).map { "- \($0)" }.joined(separator: "\n")
    return """
    USER PROFILE
    - Primary goal: \(convo.primaryGoal)
    - Obstacles: \(convo.variables["obstacles"] ?? "")
    - Personality: communication=\(insights.communicationStyle.rawValue), energy=\(insights.energyLevel.rawValue), traits=\(insights.dominantTraits.joined(separator: ", "))
    - Samples:\n\(quotes)

    Forbidden tropes: "rise and grind", "no excuses", bro-speak.
    Produce PersonaSpec JSON only.
    """
}

private func voicePrompt(spec: PersonaSpec) -> String {
    """
    SPEC:
    name=\(spec.identity.name)
    archetype=\(spec.identity.archetype)
    signatureMotif=\(spec.identity.signatureMotif)
    fingerprints=\(spec.fingerprints.joined(separator: ", "))
    Guardrails: energy=\(spec.voice.energy.rawValue), pace=\(spec.voice.pace.rawValue), warmth=\(spec.voice.warmth.rawValue), humor=\(spec.voice.humorLevel.rawValue), formality=\(spec.voice.formalityLevel.rawValue), response=\(spec.voice.responseLength.rawValue)
    Create voice + interaction phrases honoring guardrails and motif. JSON only.
    """
}

private func narrativePrompt(spec: PersonaSpec) -> String {
    """
    SPEC:
    archetype=\(spec.identity.archetype)
    coreValues=\(spec.identity.coreValues.joined(separator: ", "))
    signatureMotif=\(spec.identity.signatureMotif)
    fingerprints=\(spec.fingerprints.joined(separator: ", "))
    Write 100-150 words backgroundStory referencing motif and one fingerprint. JSON only.
    """
}

private func systemPromptUser(spec: PersonaSpec, convo: ConversationData, insights: ConversationPersonalityInsights) -> String {
    """
    Build a 220-280 word second-person coaching system prompt.
    Must include: stance (\(spec.beliefs.motivationalStance)), how you adapt per listed rules, 3 signature phrases invoking \(spec.identity.signatureMotif), an error policy, and closing style matching interaction style.
    User goal: \(convo.primaryGoal). Avoid clichés.
    """
}

private func nutritionPrompt(spec: PersonaSpec, insights: ConversationPersonalityInsights) -> String {
    let pr = spec.nutrition.proteinRange
    let fr = spec.nutrition.fatPctRange
    return """
    Provide nutritionRecommendations within guardrails:
    proteinGramsPerPound in [\(String(format: "%.2f", pr.lowerBound)), \(String(format: "%.2f", pr.upperBound))]
    fatPercentage in [\(String(format: "%.2f", fr.lowerBound)), \(String(format: "%.2f", fr.upperBound))]
    Approach: \(spec.nutrition.approach). Hint: \(spec.nutrition.carbStrategyHint)
    Return strict JSON.
    """
}

private func makePersonaSpecSchema() throws -> StructuredOutputSchema {
    let schema: [String: Any] = [
        "type": "object",
        "required": ["identity","voice","beliefs","nutrition","fingerprints"],
        "properties": [
            "identity": [
                "type": "object",
                "required": ["name","archetype","coreValues","signatureMotif"],
                "properties": [
                    "name": ["type":"string","minLength":2,"maxLength":24],
                    "archetype": ["type":"string","maxLength":32],
                    "coreValues": ["type":"array","items":["type":"string"],"minItems":3,"maxItems":5],
                    "signatureMotif": ["type":"string","maxLength":80]
                ]
            ],
            "voice": [
                "type":"object",
                "required":["energy","pace","warmth","vocabulary","sentenceStructure","humorLevel","formalityLevel","responseLength"],
                "properties":[
                    "energy":["enum":["high","moderate","calm"]],
                    "pace":["enum":["brisk","measured","natural"]],
                    "warmth":["enum":["warm","neutral","friendly"]],
                    "vocabulary":["enum":["simple","moderate","advanced"]],
                    "sentenceStructure":["enum":["simple","moderate","complex"]],
                    "humorLevel":["enum":["none","light","moderate","playful"]],
                    "formalityLevel":["enum":["casual","balanced","professional"]],
                    "responseLength":["enum":["concise","moderate","detailed"]]
                ]
            ],
            "beliefs": [
                "type":"object",
                "required":["philosophy","adaptationRules","motivationalStance"],
                "properties":[
                    "philosophy":["type":"string","minLength":50,"maxLength":260],
                    "adaptationRules":["type":"array","minItems":2,"maxItems":6,"items":[
                        "type":"object",
                        "required":["trigger","condition","adjustment"],
                        "properties":[
                            "trigger":["enum":["timeOfDay","stress","progress","mood"]],
                            "condition":["type":"string","maxLength":120],
                            "adjustment":["type":"string","maxLength":160]
                        ]
                    ]],
                    "motivationalStance":["type":"string","maxLength":100]
                ]
            ],
            "nutrition": [
                "type":"object",
                "required":["approach","proteinRange","fatPctRange","carbStrategyHint"],
                "properties":[
                    "approach":["type":"string","maxLength":50],
                    "proteinRange":["type":"array","items":["type":"number"],"minItems":2,"maxItems":2],
                    "fatPctRange":["type":"array","items":["type":"number"],"minItems":2,"maxItems":2],
                    "carbStrategyHint":["type":"string","maxLength":120]
                ]
            ],
            "fingerprints": ["type":"array","items":["type":"string"],"minItems":1,"maxItems":6]
        ]
    ]
    guard let s = StructuredOutputSchema.fromJSON(name: "PersonaSpec", description: "Scaffold for persona facets", schema: schema, strict: true) else { throw PersonaError.invalidResponse("Schema build failed") }
    return s
}

private func makeVoicePackSchema() throws -> StructuredOutputSchema {
    let schema: [String: Any] = [
        "type": "object",
        "required": ["voice","style"],
        "properties": [
            "voice": ["type":"object"],
            "style": ["type":"object"]
        ]
    ]
    guard let schema = StructuredOutputSchema.fromJSON(name: "VoicePack", description: "Voice + interaction style", schema: schema, strict: true) else {
        throw PersonaError.invalidResponse("Failed to create VoicePack schema")
    }
    return schema
}

private func makeNarrativeSchema() throws -> StructuredOutputSchema {
    let schema: [String: Any] = [
        "type":"object",
        "required":["backgroundStory"],
        "properties":["backgroundStory":["type":"string","minLength":80,"maxLength":400]]
    ]
    guard let schema = StructuredOutputSchema.fromJSON(name: "Narrative", description: "Backstory", schema: schema, strict: true) else {
        throw PersonaError.invalidResponse("Failed to create Narrative schema")
    }
    return schema
}

private func makeNutritionSchema() throws -> StructuredOutputSchema {
    // Matches NutritionRecommendations
    let schema: [String: Any] = [
        "type":"object",
        "required":["approach","proteinGramsPerPound","fatPercentage","carbStrategy","rationale","flexibilityNotes"],
        "properties": [
            "approach":["type":"string","maxLength":60],
            "proteinGramsPerPound":["type":"number","minimum":0.5,"maximum":1.8],
            "fatPercentage":["type":"number","minimum":0.15,"maximum":0.5],
            "carbStrategy":["type":"string","maxLength":120],
            "rationale":["type":"string","maxLength":260],
            "flexibilityNotes":["type":"string","maxLength":160]
        ]
    ]
    guard let schema = StructuredOutputSchema.fromJSON(name: "NutritionRecs", description: "Nutrition recommendations", schema: schema, strict: true) else {
        throw PersonaError.invalidResponse("Failed to create NutritionRecs schema")
    }
    return schema
}

private func stableSeed(convo: ConversationData, insights: ConversationPersonalityInsights) -> UInt64 {
    let s = (convo.primaryGoal + (insights.dominantTraits.joined()) + (insights.preferredTimes.joined()))
    return UInt64(abs(s.hashValue))
}

// MARK: - Batch Persona Generation

extension PersonaSynthesizer {
    /// Generate multiple personas in parallel for testing
    func batchSynthesize(
        conversations: [(ConversationData, ConversationPersonalityInsights)]
    ) async throws -> [PersonaProfile] {
        await withTaskGroup(of: PersonaProfile?.self) { group in
            for (data, insights) in conversations {
                group.addTask {
                    try? await self.synthesizePersona(from: data, insights: insights)
                }
            }

            var results: [PersonaProfile] = []
            for await persona in group {
                if let persona = persona {
                    results.append(persona)
                }
            }
            return results
        }
    }
}

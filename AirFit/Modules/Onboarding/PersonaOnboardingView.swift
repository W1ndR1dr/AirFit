import SwiftUI

struct PersonaOnboardingView: View {
    @Environment(\.diContainer) private var container

    enum Step { case welcome, generating, confirm }
    @State private var step: Step = .welcome
    @State private var isGenerating = false
    @State private var progressMessage = ""
    @State private var progressValue: Double = 0
    @State private var error: String?
    @State private var personaName: String = "Your Coach"
    @State private var personaArchetype: String = "Supportive"
    @State private var modelOptions: [LLMModel] = []
    @State private var selectedModel: LLMModel?
    @State private var sampleLines: [String] = []
    @State private var generationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 24) {
            switch step {
            case .welcome:
                VStack(spacing: 16) {
                    Text("Meet Your AI Coach")
                        .font(.system(size: 28, weight: .bold))
                    Text("We’ll create a personalized coaching voice just for you.")
                        .foregroundStyle(.secondary)

                    // Optional model chooser (shows when options available)
                    if !modelOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                ForEach(modelOptions, id: \.identifier) { model in
                                    let isSelected = model.identifier == selectedModel?.identifier
                                    Button(action: { selectedModel = model }) {
                                        Text(model.displayName)
                                            .font(.system(size: 13, weight: .medium))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    Button(action: { Task { await startGeneration() } }) {
                        Text("Generate Persona")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

            case .generating:
                VStack(spacing: 12) {
                    ProgressView(value: progressValue)
                        .tint(.accentColor)
                    Text(progressMessage.isEmpty ? "Creating your coach…" : progressMessage)
                        .foregroundStyle(.secondary)
                    if let error = error {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") { Task { await startGeneration() } }
                        Button("Continue with Basic Coach") { continueWithFallbackPersona() }
                    }
                    HStack(spacing: 12) {
                        Button("Cancel") { cancelGeneration() }
                        Button("Continue without AI") { continueWithFallbackPersona() }
                    }
                }

            case .confirm:
                VStack(spacing: 12) {
                    Text("Your Coach Is Ready")
                        .font(.system(size: 24, weight: .bold))
                    Text("\(personaName) — \(personaArchetype)")
                        .foregroundStyle(.secondary)
                    if !sampleLines.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(sampleLines, id: \.self) { line in
                                Text("\u{201C}\(line)\u{201D}")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button(action: { completeOnboarding() }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .task {
            await loadModelOptions()
        }
    }

    private func defaultInsights() -> ConversationPersonalityInsights {
        ConversationPersonalityInsights(
            dominantTraits: ["Supportive", "Analytical", "Structured"],
            communicationStyle: .supportive,
            motivationType: .balanced,
            energyLevel: .moderate,
            preferredComplexity: .moderate,
            emotionalTone: ["supportive", "professional"],
            stressResponse: .wantsEncouragement,
            preferredTimes: ["morning", "evening"],
            extractedAt: Date()
        )
    }

    private func defaultConversation() -> ConversationData {
        ConversationData(messages: [
            ConversationMessage(role: .user, content: "I want to get fitter and feel better.", timestamp: Date())
        ], variables: [
            "userName": "there",
            "primary_goal": "improve fitness"
        ])
    }

    private func startGeneration() async {
        guard !isGenerating else { return }
        isGenerating = true
        error = nil
        progressValue = 0
        progressMessage = "Initializing…"
        step = .generating

        generationTask?.cancel()
        generationTask = Task { @MainActor in }
        generationTask = Task {
        do {
            let personaSynthesizer = try await container.resolve(PersonaSynthesizer.self)
            let personaService = try await container.resolve(PersonaService.self)
            let userService = try await container.resolve(UserServiceProtocol.self)
            let aiService = try await container.resolve(AIServiceProtocol.self)

            // Progress stream (best-effort)
            let stream = await personaSynthesizer.createProgressStream()
            Task { @MainActor in
                for await p in stream {
                    progressValue = p.progress
                    progressMessage = p.message ?? ""
                }
            }

            // If AI is not configured, fallback to a simple persona
            if !(aiService.isConfigured) {
                personaName = "Coach"
                personaArchetype = "Supportive"
                sampleLines = makeSampleLines(name: personaName, archetype: personaArchetype)
                step = .confirm
                isGenerating = false
                return
            }

            // Generate persona
            let convo = defaultConversation()
            let insights = defaultInsights()
            let persona = try await personaSynthesizer.synthesizePersona(
                from: convo,
                insights: insights,
                preferredModel: selectedModel
            )

            // Save persona and mark onboarding complete
            if let userId = await userService.getCurrentUserId() {
                try await personaService.savePersona(persona, for: userId)
            }
            personaName = persona.name
            personaArchetype = persona.archetype
            sampleLines = makeSampleLines(name: personaName, archetype: personaArchetype)
            step = .confirm
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
        }
    }

    private func completeOnboarding() {
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    private func loadModelOptions() async {
        do {
            let aiService = try await container.resolve(AIServiceProtocol.self)
            // Try to narrow to preferred models
            var opts: [LLMModel] = []
            // Prefer GPT-5, GPT-5 Mini if available
            if aiService.availableModels.contains(where: { $0.id == LLMModel.gpt5.identifier }) {
                opts.append(.gpt5)
            }
            if aiService.availableModels.contains(where: { $0.id == LLMModel.gpt5Mini.identifier }) {
                opts.append(.gpt5Mini)
            }
            // Add Gemini Thinking if available
            if aiService.availableModels.contains(where: { $0.id == LLMModel.gemini25FlashThinking.identifier }) {
                opts.append(.gemini25FlashThinking)
            }

            await MainActor.run {
                self.modelOptions = opts
                if self.selectedModel == nil {
                    self.selectedModel = opts.first
                }
            }
        } catch {
            // Ignore; fallback to defaults
        }
    }

    private func makeSampleLines(name: String, archetype: String) -> [String] {
        [
            "Let's set one small goal for today.",
            "I'm here with \(archetype.lowercased()) energy — ready when you are."
        ]
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        isGenerating = false
        error = nil
        progressValue = 0
        progressMessage = ""
        step = .welcome
    }

    private func continueWithFallbackPersona() {
        personaName = "Coach"
        personaArchetype = "Supportive"
        sampleLines = makeSampleLines(name: personaName, archetype: personaArchetype)
        step = .confirm
        isGenerating = false
    }
}

import SwiftUI
import Charts

struct AIPersonaSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showPersonaRefinement = false
    @State private var previewText = "Let's crush today's workout! I see you're feeling energized - perfect timing for that strength session we planned."
    @State private var isGeneratingPreview = false

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Title header
                    HStack {
                        CascadeText("AI Coach Persona")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)

                    VStack(spacing: AppSpacing.xl) {
                        personaOverview
                        personaTraits
                        evolutionInsights
                        communicationPreferences
                        personaActions
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPersonaRefinement) {
            // Shows conversational refinement flow for synthesized personas
            ConversationalPersonaRefinement(
                user: viewModel.currentUser,
                currentPersona: viewModel.coachPersona
            )
        }
    }

    private var personaOverview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Your Coach")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    // Coach Identity
                    if let persona = viewModel.coachPersona {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(persona.identity.name)
                                    .font(.title2.bold())

                                Text(persona.identity.archetype)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                // Uniqueness Score
                                HStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                    Text("Uniqueness: \(Int(persona.uniquenessScore * 100))%")
                                        .font(.caption)
                                }
                                .foregroundStyle(Color.accentColor)
                            }

                            Spacer()

                            // Coach Avatar
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Text(persona.identity.name.prefix(2).uppercased())
                                        .font(.title.bold())
                                        .foregroundStyle(.white)
                                }
                        }

                        Divider()

                        // Core Philosophy
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Label("Core Philosophy", systemImage: "quote.bubble")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(persona.coachingPhilosophy.core)
                                .font(.callout)
                                .italic()
                        }
                    } else {
                        // No persona configured
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text("No Coach Persona Configured")
                                .font(.headline)

                            Text("Complete onboarding to generate your personalized AI coach")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }

                    if viewModel.coachPersona != nil {
                        Divider()

                        // Live Preview
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Label("Live Preview", systemImage: "waveform")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if isGeneratingPreview {
                                    TextLoadingView(message: "Generating", style: .subtle)
                                }
                            }

                            Text(previewText)
                                .font(.callout)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                }
            }
        }
    }

    private var personaTraits: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Personality Traits")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
                if let persona = viewModel.coachPersona {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppSpacing.md) {
                        ForEach(persona.dominantTraits, id: \.name) { trait in
                            TraitCard(trait: trait)
                        }
                    }
                } else {
                    Text("No traits available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
    }

    private var evolutionInsights: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Persona Evolution")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    // Evolution Status
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Adaptation Level")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("\(viewModel.personaEvolution.adaptationLevel)/5")
                                .font(.title3.bold())
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                            Text("Last Updated")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(viewModel.personaEvolution.lastUpdateDate.formatted(.relative(presentation: .named)))
                                .font(.caption)
                        }
                    }

                    Divider()

                    // Recent Adaptations
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Recent Adaptations")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if viewModel.personaEvolution.recentAdaptations.isEmpty {
                            Text("No recent adaptations")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(viewModel.personaEvolution.recentAdaptations, id: \.id) { adaptation in
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: adaptation.icon)
                                        .font(.caption)
                                        .foregroundStyle(Color.accentColor)

                                    Text(adaptation.description)
                                        .font(.caption)

                                    Spacer()

                                    Text(adaptation.date.formatted(.relative(presentation: .named)))
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var communicationPreferences: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Communication Style")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
                VStack(spacing: AppSpacing.md) {
                    if let persona = viewModel.coachPersona {
                        CommunicationRow(
                            title: "Tone",
                            value: persona.communicationStyle.tone.displayName,
                            icon: "speaker.wave.2"
                        )

                        CommunicationRow(
                            title: "Energy Level",
                            value: persona.communicationStyle.energyLevel.displayName,
                            icon: "bolt"
                        )

                        CommunicationRow(
                            title: "Detail Level",
                            value: persona.communicationStyle.detailLevel.displayName,
                            icon: "doc.text"
                        )

                        CommunicationRow(
                            title: "Humor Style",
                            value: String(describing: persona.communicationStyle.humorStyle),
                            icon: "face.smiling"
                        )
                    } else {
                        Text("No communication style configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
        }
    }

    private var personaActions: some View {
        VStack(spacing: AppSpacing.md) {
            Button(action: {
                showPersonaRefinement = true
            }, label: {
                Label("Refine Through Conversation", systemImage: "bubble.left.and.bubble.right")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            })
            .disabled(viewModel.coachPersona == nil)

            Button {
                generateNewPreview()
            } label: {
                Label("Generate New Preview", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            }
            .disabled(isGeneratingPreview || viewModel.coachPersona == nil)

            // Natural Language Adjustment
            NavigationLink(destination: NaturalLanguagePersonaAdjustment(viewModel: viewModel)) {
                Label("Adjust with Natural Language", systemImage: "text.quote")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            }
            .disabled(viewModel.coachPersona == nil)
        }
    }

    private func generateNewPreview() {
        guard viewModel.coachPersona != nil else { return }

        isGeneratingPreview = true

        Task {
            do {
                // Generate preview using actual coach persona
                let preview = try await viewModel.generatePersonaPreview(
                    scenario: PreviewScenario.randomScenario()
                )

                await MainActor.run {
                    withAnimation {
                        previewText = preview
                    }
                    isGeneratingPreview = false
                    HapticService.play(.success)
                }
            } catch {
                await MainActor.run {
                    isGeneratingPreview = false
                    previewText = "Let's make today count! Ready to push your limits?"
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct TraitCard: View {
    let trait: PersonalityTrait

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: trait.icon)
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)

                Text(trait.name)
                    .font(.subheadline.bold())
            }

            Text(trait.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}

struct CommunicationRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Natural Language Adjustment View
struct NaturalLanguagePersonaAdjustment: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var adjustmentText = ""
    @State private var isProcessing = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Instructions
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label("Natural Language Adjustments", systemImage: "text.quote")
                        .font(.headline)

                    Text("Describe how you'd like your coach to change. For example:")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("• \"Be more encouraging and less intense\"")
                        Text("• \"Use more data and analytics in your feedback\"")
                        Text("• \"Add more humor but keep it professional\"")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            // Input Field
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Your Adjustment")
                        .font(.subheadline.bold())

                    TextField("Describe the change...", text: $adjustmentText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                        .overlay(alignment: .bottomTrailing) {
                            WhisperVoiceButton(text: $adjustmentText)
                                .padding(8)
                        }
                }
            }

            // Apply Button
            Button {
                applyAdjustment()
            } label: {
                if isProcessing {
                    TextLoadingView(message: "Processing", style: .subtle)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor.opacity(0.5))
                        )
                } else {
                    Label("Apply Adjustment", systemImage: "wand.and.stars")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .disabled(adjustmentText.isEmpty || isProcessing)

            Spacer()
        }
        .padding()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func applyAdjustment() {
        isProcessing = true

        Task {
            do {
                try await viewModel.applyNaturalLanguageAdjustment(adjustmentText)

                await MainActor.run {
                    isProcessing = false
                    adjustmentText = ""
                    HapticService.play(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Show error alert
                    viewModel.showAlert(.error(message: error.localizedDescription))
                }
            }
        }
    }
}

// MARK: - Conversational Persona Refinement
struct ConversationalPersonaRefinement: View {
    let user: User
    let currentPersona: CoachPersona?
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [RefinementMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var showSuggestions = true
    @FocusState private var isInputFocused: Bool

    private let suggestions = [
        "Be more encouraging and supportive",
        "Use simpler language, less jargon",
        "Add more humor to our conversations",
        "Be more data-driven in your feedback",
        "Push me harder during workouts"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: AppSpacing.md) {
                            // Initial message
                            RefinementMessageBubble(
                                message: RefinementMessage(
                                    id: UUID(),
                                    content: "Hi! I'm here to help refine how I communicate with you. Tell me what you'd like to change about my coaching style, personality, or the way I interact with you.",
                                    isUser: false,
                                    timestamp: Date()
                                ),
                                currentPersona: currentPersona
                            )

                            // Conversation messages
                            ForEach(messages) { message in
                                RefinementMessageBubble(
                                    message: message,
                                    currentPersona: currentPersona
                                )
                            }

                            // Typing indicator
                            if isTyping {
                                HStack {
                                    TypingIndicator()
                                        .padding(.horizontal)
                                    Spacer()
                                }
                            }

                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo("bottom")
                        }
                    }
                }

                Divider()

                // Suggestions
                if showSuggestions && messages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(action: { sendMessage(suggestion) }, label: {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, AppSpacing.md)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(.ultraThinMaterial)
                                        )
                                        .clipShape(Capsule())
                                })
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, AppSpacing.sm)
                    }

                    Divider()
                }

                // Input area
                HStack(spacing: AppSpacing.md) {
                    TextField("Type your refinement request...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit {
                            sendMessage(inputText)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            WhisperVoiceButton(text: $inputText)
                                .padding(8)
                        }

                    Button {
                        sendMessage(inputText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(inputText.isEmpty ? Color.secondary : Color.accentColor)
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding()
                .glassEffect()
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                isInputFocused = true
            }
        }
    }

    private func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Add user message
        let userMessage = RefinementMessage(
            id: UUID(),
            content: text,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        inputText = ""
        showSuggestions = false

        // Generate AI response
        isTyping = true

        Task {
            await MainActor.run {
                let response = generateResponse(for: text)
                let aiMessage = RefinementMessage(
                    id: UUID(),
                    content: response,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
                isTyping = false
                HapticService.play(.dataUpdated)
            }
        }
    }

    private func generateResponse(for input: String) -> String {
        // Simulate intelligent responses based on input
        if input.lowercased().contains("encouraging") {
            return "Great! I'll be more encouraging and celebratory of your achievements. I'll focus on positive reinforcement and cheer you on throughout your fitness journey. Is there anything specific you'd like me to be encouraging about?"
        } else if input.lowercased().contains("humor") {
            return "You got it! I'll add more humor and keep things light while still being helpful. I'll throw in some fitness puns and keep our conversations fun. Any particular style of humor you enjoy?"
        } else if input.lowercased().contains("data") || input.lowercased().contains("analytics") {
            return "Understood! I'll provide more detailed metrics, progress analytics, and data-driven insights. I'll include specific numbers, trends, and comparisons to help you track your progress. What metrics matter most to you?"
        } else if input.lowercased().contains("simple") || input.lowercased().contains("jargon") {
            return "Perfect! I'll use clearer, everyday language and avoid technical fitness terms unless necessary. I'll make sure my explanations are easy to understand. Let me know if I ever use a term that's unclear!"
        } else {
            return "I understand! I'll adjust my coaching style based on your feedback. These changes will help me be a better coach for you. Is there anything else you'd like me to adjust?"
        }
    }

    private func applyRefinements() {
        // In a real implementation, this would process the conversation
        // and update the persona accordingly
        HapticService.play(.success)
    }
}

struct RefinementMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct RefinementMessageBubble: View {
    let message: RefinementMessage
    let currentPersona: CoachPersona?

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: AppSpacing.xs) {
                Text(message.content)
                    .font(.callout)
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        message.isUser ? Color.accentColor : Color.primary.opacity(0.05)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    )

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.6).repeatForever()) {
                animationPhase = 2
            }
        }
    }
}

// MARK: - Display Name Extensions
extension CommunicationTone {
    var displayName: String {
        switch self {
        case .formal: return "Formal"
        case .casual: return "Casual"
        case .balanced: return "Balanced"
        case .energetic: return "Energetic"
        }
    }
}

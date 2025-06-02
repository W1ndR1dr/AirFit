import SwiftUI
import Charts

struct AIPersonaSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showPersonaRefinement = false
    @State private var previewText = "Let's crush today's workout! I see you're feeling energized - perfect timing for that strength session we planned."
    @State private var isGeneratingPreview = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                personaOverview
                personaTraits
                evolutionInsights
                communicationPreferences
                personaActions
            }
            .padding()
        }
        .navigationTitle("AI Coach Persona")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPersonaRefinement) {
            // Shows conversational refinement flow for synthesized personas
            ConversationalPersonaRefinement(
                user: viewModel.user,
                currentPersona: viewModel.coachPersona
            )
        }
    }
    
    private var personaOverview: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Your Coach", icon: "person.fill")
            
            Card {
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
                                .foregroundStyle(.accent)
                            }
                            
                            Spacer()
                            
                            // Coach Avatar
                            Circle()
                                .fill(LinearGradient(
                                    colors: persona.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Text(persona.initials)
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
                                    ProgressView()
                                        .controlSize(.small)
                                }
                            }
                            
                            Text(previewText)
                                .font(.callout)
                                .padding()
                                .background(Color.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                        .strokeBorder(Color.accent.opacity(0.3), lineWidth: 1)
                                }
                        }
                    }
                }
            }
        }
    }
    
    private var personaTraits: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Personality Traits", icon: "brain")
            
            Card {
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Persona Evolution", icon: "chart.line.uptrend.xyaxis")
            
            Card {
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
                                        .foregroundStyle(.accent)
                                    
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
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Communication Style", icon: "bubble.left.and.bubble.right.fill")
            
            Card {
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
                            value: persona.communicationStyle.humorStyle.displayName,
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
            Button(action: { showPersonaRefinement = true }) {
                Label("Refine Through Conversation", systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primaryProminent)
            .disabled(viewModel.coachPersona == nil)
            
            Button(action: generateNewPreview) {
                Label("Generate New Preview", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondary)
            .disabled(isGeneratingPreview || viewModel.coachPersona == nil)
            
            // Natural Language Adjustment
            NavigationLink(destination: NaturalLanguagePersonaAdjustment(viewModel: viewModel)) {
                Label("Adjust with Natural Language", systemImage: "text.quote")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
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
                    HapticManager.impact(.light)
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
                    .foregroundStyle(.accent)
                
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
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSm))
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
    @ObservedObject var viewModel: SettingsViewModel
    @State private var adjustmentText = ""
    @State private var isProcessing = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Instructions
            Card {
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
            Card {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Your Adjustment")
                        .font(.subheadline.bold())
                    
                    TextField("Describe the change...", text: $adjustmentText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                }
            }
            
            // Apply Button
            Button(action: applyAdjustment) {
                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Apply Adjustment", systemImage: "wand.and.stars")
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.primaryProminent)
            .disabled(adjustmentText.isEmpty || isProcessing)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Adjust Persona")
        .navigationBarTitleDisplayMode(.inline)
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
                    HapticManager.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Show error alert
                    viewModel.coordinator.showAlert(.error(message: error.localizedDescription))
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
                                Button(action: { sendMessage(suggestion) }) {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, AppSpacing.md)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(Color.secondaryBackground)
                                        .clipShape(Capsule())
                                }
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
                    
                    Button(action: { sendMessage(inputText) }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.isEmpty ? .secondary : .accent)
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding()
                .background(Color.secondaryBackground)
            }
            .navigationTitle("Refine Your Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { 
                        applyRefinements()
                        dismiss() 
                    }
                    .disabled(messages.isEmpty)
                }
            }
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
        
        // Simulate AI response
        isTyping = true
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
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
                HapticManager.impact(.light)
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
        HapticManager.success()
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
                        message.isUser ? Color.accent : Color.secondaryBackground
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
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
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

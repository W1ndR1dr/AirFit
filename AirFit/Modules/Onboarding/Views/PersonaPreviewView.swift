import SwiftUI
import SwiftData

struct PersonaPreviewView: View {
    let persona: PersonaProfile
    let coordinator: OnboardingFlowCoordinator
    
    @State private var showingAdjustmentSheet = false
    @State private var adjustmentText = ""
    @State private var selectedSampleIndex = 0
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    private let sampleMessages = [
        "Good morning! Ready to crush your fitness goals today? 🔥",
        "Great job on that workout! You're getting stronger every day.",
        "Remember, progress isn't always linear. Every step forward counts!",
        "Let's adjust your plan based on how you're feeling today.",
        "You've been consistent this week - that's what builds real results!"
    ]
    
    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Coach Card
                    coachCard
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, AppSpacing.md)
                    
                    // Sample Messages
                    sampleMessagesSection
                        .padding(.horizontal, AppSpacing.screenPadding)
                    
                    // Action Buttons
                    actionButtons
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(MotionToken.standardSpring.delay(0.1)) {
                    animateIn = true
                }
            }
        }
        .sheet(isPresented: $showingAdjustmentSheet) {
            PreviewPersonaAdjustmentSheet(
                adjustmentText: $adjustmentText,
                onSubmit: {
                    Task {
                        await coordinator.adjustPersona(adjustmentText)
                        adjustmentText = ""
                    }
                }
            )
        }
    }
    
    // MARK: - Components
    
    private var coachCard: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Meet Your Coach")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(.secondary)
                        
                        if animateIn {
                            CascadeText(persona.name)
                                .font(.system(size: 36, weight: .light, design: .rounded))
                        }
                    }
                
                Spacer()
                
                    // Coach Avatar with gradient
                    ZStack {
                        Circle()
                            .fill(gradientManager.currentGradient(for: colorScheme))
                            .frame(width: 80, height: 80)
                        
                        Text(persona.name.prefix(1))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .opacity(animateIn ? 1 : 0)
                }
            
                // Archetype Badge with gradient
                HStack {
                    Label(persona.archetype, systemImage: "star.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            Capsule()
                                .fill(gradientManager.currentGradient(for: colorScheme))
                        )
                    
                    Spacer()
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
            
                // Personality Traits
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Personality")
                        .font(.system(size: 18, weight: .medium))
                    
                    FlowLayout(spacing: AppSpacing.xs) {
                        ForEach(persona.coreValues, id: \.self) { value in
                            TraitChip(text: value)
                        }
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
                .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
            
                // Communication Style
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Communication Style")
                        .font(.system(size: 18, weight: .medium))
                    
                    HStack(spacing: AppSpacing.sm) {
                        StyleIndicator(
                            label: "Energy",
                            value: persona.voiceCharacteristics.energy.rawValue.capitalized,
                            icon: "bolt.fill"
                        )
                        
                        StyleIndicator(
                            label: "Warmth",
                            value: persona.voiceCharacteristics.warmth.rawValue.capitalized,
                            icon: "heart.fill"
                        )
                        
                        StyleIndicator(
                            label: "Formality",
                            value: persona.interactionStyle.formalityLevel.rawValue.capitalized,
                            icon: "text.bubble.fill"
                        )
                    }
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
            }
        }
    }
    
    private var sampleMessagesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Sample Messages")
                .font(.system(size: 18, weight: .medium))
            
            // Message carousel with glass morphism
            TabView(selection: $selectedSampleIndex) {
                ForEach(0..<generateSampleMessages().count, id: \.self) { index in
                    PreviewMessageBubble(
                        message: generateSampleMessages()[index],
                        isFromCoach: true
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 120)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            // Accept button
            Button {
                HapticService.impact(.light)
                Task {
                    await coordinator.acceptPersona()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Accept \(persona.name)")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? .clear, 
                        radius: 8, x: 0, y: 4)
            }
            
            HStack(spacing: AppSpacing.sm) {
                // Adjust button
                Button {
                    HapticService.impact(.light)
                    showingAdjustmentSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .medium))
                        Text("Adjust")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                
                // Regenerate button
                Button {
                    HapticService.impact(.light)
                    Task {
                        await coordinator.regeneratePersona()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Regenerate")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(MotionToken.standardSpring.delay(0.5), value: animateIn)
    }
    
    // MARK: - Helper Methods
    
    private func generateSampleMessages() -> [String] {
        // In production, these would be generated based on the persona
        return [
            "\(persona.name) here! \(sampleMessages[0])",
            personalizedMessage(sampleMessages[1]),
            personalizedMessage(sampleMessages[2]),
            personalizedMessage(sampleMessages[3]),
            personalizedMessage(sampleMessages[4])
        ]
    }
    
    private func personalizedMessage(_ base: String) -> String {
        // Add persona-specific flavor to messages
        var message = base
        
        // Add greeting style
        if persona.interactionStyle.formalityLevel == .casual {
            message = "Hey! " + message
        }
        
        // Add encouragement style
        if let encouragement = persona.interactionStyle.encouragementPhrases.randomElement() {
            message += " " + encouragement
        }
        
        return message
    }
}

// MARK: - Supporting Views

struct PreviewPersonaAdjustmentSheet: View {
    @Binding var adjustmentText: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            BaseScreen {
                VStack(spacing: AppSpacing.md) {
                    Text("What would you like to adjust?")
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .padding(.top, AppSpacing.md)
                
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Examples:")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(.secondary)
                            
                            ForEach([
                                "Be more motivational and energetic",
                                "Use a more casual, friendly tone",
                                "Be more direct and concise",
                                "Add more humor and playfulness"
                            ], id: \.self) { example in
                                Button(action: {
                                    adjustmentText = example
                                    HapticService.selection()
                                }) {
                                    HStack {
                                        Image(systemName: "lightbulb")
                                            .font(.caption)
                                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                                        Text(example)
                                            .font(.system(size: 15, weight: .light))
                                        Spacer()
                                    }
                                    .padding(AppSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Your adjustment:")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(.secondary)
                            
                            TextField("Describe how you'd like to adjust your coach...", text: $adjustmentText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(AppSpacing.sm)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                
                    Spacer()
                    
                    Button {
                        HapticService.impact(.light)
                        onSubmit()
                        dismiss()
                    } label: {
                        Text("Apply Adjustment")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? .clear, 
                                    radius: 8, x: 0, y: 4)
                    }
                    .disabled(adjustmentText.isEmpty)
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.bottom, AppSpacing.lg)
                }
            }
            .navigationTitle("Adjust Your Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TraitChip: View {
    let text: String
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(.primary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            )
    }
}

struct StyleIndicator: View {
    let label: String
    let value: String
    let icon: String
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}

struct PreviewMessageBubble: View {
    let message: String
    let isFromCoach: Bool
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if !isFromCoach { Spacer() }
            
            Text(message)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(isFromCoach ? .primary : .white)
                .padding(AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isFromCoach ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(gradientManager.currentGradient(for: colorScheme)))
                )
            
            if isFromCoach { Spacer() }
        }
        .padding(.horizontal)
    }
}

// Simple flow layout for trait chips
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangement(proposal: proposal, subviews: subviews)
        return CGSize(width: result.maxX, height: result.maxY)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            if let position = result.positions[index] {
                subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                            proposal: ProposedViewSize(result.sizes[index]))
            }
        }
    }
    
    private func arrangement(proposal: ProposedViewSize, subviews: Subviews) -> (maxX: CGFloat, maxY: CGFloat, positions: [Int: CGPoint], sizes: [CGSize]) {
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        var positions: [Int: CGPoint] = [:]
        var sizes: [CGSize] = []
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)
            
            if currentX + size.width > (proposal.width ?? .infinity), currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions[index] = CGPoint(x: currentX, y: currentY)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxX = max(maxX, currentX - spacing)
            maxY = max(maxY, currentY + lineHeight)
        }
        
        return (maxX, maxY, positions, sizes)
    }
}

// MARK: - Preview

private final class PreviewUserService: UserServiceProtocol {
    func getCurrentUser() -> User? {
        nil
    }
    
    func getCurrentUserId() async -> UUID? {
        nil
    }
    
    func createUser(from profile: OnboardingProfile) async throws -> User {
        User(email: profile.email, name: profile.name)
    }
    
    func updateProfile(_ updates: ProfileUpdate) async throws {
        // No-op for preview
    }
    
    func completeOnboarding() async throws {
        // No-op for preview
    }
    
    func setCoachPersona(_ persona: CoachPersona) async throws {
        // No-op for preview
    }
    
    func deleteUser(_ user: User) async throws {
        // No-op for preview
    }
}

private final class PreviewAPIKeyManager: APIKeyManagementProtocol {
    func getAPIKey(for provider: AIProvider) async throws -> String {
        return "preview-key"
    }
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        // No-op for preview
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        // No-op for preview
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        return true
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        return [.openAI, .anthropic, .gemini]
    }
}

#Preview {
    NavigationStack {
        PersonaPreviewView(
            persona: PersonaProfile(
                id: UUID(),
                name: "Coach Alex",
                archetype: "The Motivator",
                systemPrompt: "You are an energetic and supportive fitness coach...",
                coreValues: ["Encouragement", "Progress", "Balance", "Consistency"],
                backgroundStory: "Former athlete turned coach...",
                voiceCharacteristics: VoiceCharacteristics(
                    energy: .high,
                    pace: .brisk,
                    warmth: .warm,
                    vocabulary: .moderate,
                    sentenceStructure: .moderate
                ),
                interactionStyle: InteractionStyle(
                    greetingStyle: "Hey there!",
                    closingStyle: "Keep crushing it!",
                    encouragementPhrases: ["You've got this!", "Amazing work!", "Keep it up!"],
                    acknowledgmentStyle: "Great job recognizing that",
                    correctionApproach: "Let's adjust this slightly",
                    humorLevel: .light,
                    formalityLevel: .casual,
                    responseLength: .moderate
                ),
                adaptationRules: [],
                metadata: PersonaMetadata(
                    createdAt: Date(),
                    version: "1.0",
                    sourceInsights: ConversationPersonalityInsights(
                        dominantTraits: ["energetic", "supportive"],
                        communicationStyle: .conversational,
                        motivationType: .achievement,
                        energyLevel: .high,
                        preferredComplexity: .moderate,
                        emotionalTone: ["positive", "encouraging"],
                        stressResponse: .needsSupport,
                        preferredTimes: ["morning", "evening"],
                        extractedAt: Date()
                    ),
                    generationDuration: 3.5,
                    tokenCount: 450,
                    previewReady: true
                )
            ),
            coordinator: OnboardingFlowCoordinator(
                conversationManager: ConversationFlowManager(
                    flowDefinition: ConversationFlowData.defaultFlow(),
                    modelContext: DataManager.previewContainer.mainContext
                ),
                personaService: PersonaService(
                    personaSynthesizer: OptimizedPersonaSynthesizer(
                        llmOrchestrator: LLMOrchestrator(apiKeyManager: PreviewAPIKeyManager()),
                        cache: AIResponseCache()
                    ),
                    llmOrchestrator: LLMOrchestrator(apiKeyManager: PreviewAPIKeyManager()),
                    modelContext: DataManager.previewContainer.mainContext
                ),
                userService: PreviewUserService(),
                modelContext: DataManager.previewContainer.mainContext
            )
        )
    }
}
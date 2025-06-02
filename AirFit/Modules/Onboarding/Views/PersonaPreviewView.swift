import SwiftUI

struct PersonaPreviewView: View {
    let persona: PersonaProfile
    let coordinator: OnboardingFlowCoordinator
    
    @State private var showingAdjustmentSheet = false
    @State private var adjustmentText = ""
    @State private var selectedSampleIndex = 0
    
    private let sampleMessages = [
        "Good morning! Ready to crush your fitness goals today? 🔥",
        "Great job on that workout! You're getting stronger every day.",
        "Remember, progress isn't always linear. Every step forward counts!",
        "Let's adjust your plan based on how you're feeling today.",
        "You've been consistent this week - that's what builds real results!"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Coach Card
                coachCard
                    .padding(.horizontal)
                    .padding(.top)
                
                // Sample Messages
                sampleMessagesSection
                    .padding(.horizontal)
                
                // Action Buttons
                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAdjustmentSheet) {
            PersonaAdjustmentSheet(
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
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meet Your Coach")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(persona.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Coach Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accent, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text(persona.name.prefix(1))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Archetype Badge
            HStack {
                Label(persona.archetype, systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.accent.opacity(0.9))
                    )
                
                Spacer()
            }
            
            // Personality Traits
            VStack(alignment: .leading, spacing: 12) {
                Text("Personality")
                    .font(.headline)
                
                FlowLayout(spacing: 8) {
                    ForEach(persona.coreValues, id: \.self) { value in
                        TraitChip(text: value)
                    }
                }
            }
            
            // Communication Style
            VStack(alignment: .leading, spacing: 12) {
                Text("Communication Style")
                    .font(.headline)
                
                HStack(spacing: 16) {
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
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
    
    private var sampleMessagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sample Messages")
                .font(.headline)
            
            // Message carousel
            TabView(selection: $selectedSampleIndex) {
                ForEach(0..<generateSampleMessages().count, id: \.self) { index in
                    MessageBubble(
                        message: generateSampleMessages()[index],
                        isFromCoach: true
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 120)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Accept button
            Button(action: {
                Task {
                    await coordinator.acceptPersona()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Accept \(persona.name)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(16)
            }
            
            HStack(spacing: 12) {
                // Adjust button
                Button(action: {
                    showingAdjustmentSheet = true
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Adjust")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accent, lineWidth: 1.5)
                    )
                }
                
                // Regenerate button
                Button(action: {
                    Task {
                        await coordinator.regeneratePersona()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
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

struct PersonaAdjustmentSheet: View {
    @Binding var adjustmentText: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("What would you like to adjust?")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Examples:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ForEach([
                        "Be more motivational and energetic",
                        "Use a more casual, friendly tone",
                        "Be more direct and concise",
                        "Add more humor and playfulness"
                    ], id: \.self) { example in
                        Button(action: {
                            adjustmentText = example
                        }) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .font(.caption)
                                Text(example)
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your adjustment:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Describe how you'd like to adjust your coach...", text: $adjustmentText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    onSubmit()
                    dismiss()
                }) {
                    Text("Apply Adjustment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .disabled(adjustmentText.isEmpty)
                .padding(.horizontal)
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
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.accent.opacity(0.1))
            )
    }
}

struct StyleIndicator: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.05))
        )
    }
}

struct MessageBubble: View {
    let message: String
    let isFromCoach: Bool
    
    var body: some View {
        HStack {
            if !isFromCoach { Spacer() }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(isFromCoach ? .primary : .white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isFromCoach ? Color.secondary.opacity(0.1) : Color.accentColor)
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
                    sourceInsights: PersonalityInsights(
                        traits: [:],
                        motivationalDrivers: [],
                        communicationProfile: CommunicationProfile(
                            preferredTone: .casual,
                            detailLevel: .moderate,
                            feedbackStyle: .positive,
                            interactionFrequency: .regular
                        ),
                        stressResponses: [:],
                        timePreferences: TimePreferences(),
                        coachingPreferences: CoachingPreferences(
                            preferredIntensity: .moderate,
                            accountabilityLevel: .high,
                            motivationStyle: .positive,
                            feedbackTiming: .immediate
                        ),
                        inferredDemographics: nil,
                        extractedAt: Date()
                    ),
                    generationDuration: 3.5,
                    tokenCount: 450,
                    previewReady: true
                )
            ),
            coordinator: OnboardingFlowCoordinator(
                conversationManager: ConversationFlowManager(),
                personaService: PersonaService(
                    personaSynthesizer: PersonaSynthesizer(llmOrchestrator: LLMOrchestrator()),
                    llmOrchestrator: LLMOrchestrator(),
                    modelContext: DataManager.previewContainer.mainContext
                ),
                userService: MockUserService(),
                modelContext: DataManager.previewContainer.mainContext
            )
        )
    }
}
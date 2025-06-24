import SwiftUI

/// Turn-based onboarding - simple, clean, effective
struct OnboardingView: View {
    @ObservedObject var intelligence: OnboardingIntelligence
    @State private var phase = Phase.healthPermission
    @State private var userInput = ""
    @State private var conversationCount = 0
    @State private var hasSelectedModel = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.diContainer) private var diContainer: DIContainer
    
    enum Phase {
        case healthPermission
        case conversation
        case generating
        case confirmation
    }
    
    var body: some View {
        BaseScreen {
            Group {
                switch phase {
                case .healthPermission:
                    HealthPermissionView(
                        onAccept: {
                            Task {
                                // Move to conversation immediately
                                await MainActor.run {
                                    phase = .conversation
                                }
                                // Then analyze health data in background
                                await intelligence.startHealthAnalysis()
                            }
                        },
                        onSkip: {
                            phase = .conversation
                        }
                    )
                    
                case .conversation:
                    ConversationView(
                        prompt: intelligence.currentPrompt,
                        suggestions: intelligence.contextualSuggestions,
                        input: $userInput,
                        onSubmit: {
                            Task {
                                await intelligence.analyzeConversation(userInput)
                                conversationCount += 1
                                userInput = ""
                                
                                // Conversation flow logic with clear boundaries
                                if conversationCount < 3 {
                                    // Early phase: Always continue gathering context
                                    if let followUp = intelligence.followUpQuestion {
                                        intelligence.currentPrompt = followUp
                                    } else {
                                        // Generate a follow-up if none provided
                                        intelligence.currentPrompt = "Tell me more about your fitness journey."
                                    }
                                } else if conversationCount >= 10 {
                                    // Hard limit reached: Generate persona regardless of context quality
                                    phase = .generating
                                } else if intelligence.contextQuality.overall >= 0.8 {
                                    // Sufficient context: Ready to generate
                                    phase = .generating
                                } else if let followUp = intelligence.followUpQuestion {
                                    // Still gathering: Use AI-generated follow-up
                                    intelligence.currentPrompt = followUp
                                } else {
                                    // No follow-up but context insufficient: Force generation
                                    phase = .generating
                                }
                            }
                        }
                    )
                    
                case .generating:
                    GeneratingView()
                        .task {
                            await intelligence.generatePersona()
                            phase = .confirmation
                        }
                    
                case .confirmation:
                    ConfirmationView(
                        plan: intelligence.coachingPlan,
                        onAccept: completeOnboarding,
                        onRefine: {
                            // Update prompt for refinement
                            intelligence.currentPrompt = "Is there anything else you'd like me to know? Any specific concerns, preferences, or goals I should consider when crafting your coaching experience?"
                            phase = .conversation
                            userInput = ""
                        }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: phase)
        }
        .onAppear {
            gradientManager.setGradient(.morningTwilight, animated: false)
        }
    }
    
    private func completeOnboarding() {
        guard let plan = intelligence.coachingPlan else { return }
        
        Task {
            do {
                let userService = try await diContainer.resolve(UserServiceProtocol.self)
                let personaService = try await diContainer.resolve(PersonaService.self)
                
                // Create profile
                let encoder = JSONEncoder()
                let personaData = try encoder.encode(plan.generatedPersona.systemPrompt)
                let prefsData = try encoder.encode(plan.engagementPreferences)
                let fullData = try encoder.encode(plan)
                
                let profile = OnboardingProfile(
                    personaPromptData: personaData,
                    communicationPreferencesData: prefsData,
                    rawFullProfileData: fullData
                )
                profile.persona = plan.generatedPersona
                profile.isComplete = true
                
                // Save user and persona
                let user = try await userService.createUser(from: profile)
                try await personaService.savePersona(plan.generatedPersona, for: user.id)
                
                // Clear cached session on successful completion
                await intelligence.clearSession()
                
                // Notify completion
                await MainActor.run {
                    NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
                }
            } catch {
                AppLogger.error("Failed to save onboarding", error: error, category: .onboarding)
            }
        }
    }
}

// MARK: - Health Permission

private struct HealthPermissionView: View {
    let onAccept: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            CascadeText("Connect your\nhealth data?")
                .font(.system(size: 38, weight: .thin, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("I'll understand your fitness baseline instantly")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: onAccept) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Connect Health")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Material.regular)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                Button(action: onSkip) {
                    Text("Skip for now")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Conversation

private struct ConversationView: View {
    let prompt: String
    let suggestions: [String]
    @Binding var input: String
    let onSubmit: () -> Void
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            ScrollView {
                VStack(spacing: 40) {
                    CascadeText(prompt)
                        .font(.system(size: 32, weight: .thin, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Text input
                    VStack(spacing: 16) {
                        TextEditor(text: $input)
                            .frame(minHeight: 100, maxHeight: 200)
                            .padding(4)
                            .scrollContentBackground(.hidden)
                            .focused($isInputFocused)
                            .padding(12)
                            .background(Material.regular)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        // Suggestions only if input is empty
                        if input.isEmpty && !suggestions.isEmpty {
                            VStack(spacing: 12) {
                                Text("Or tap one:")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .opacity(0)
                                    .cascadeIn(delay: 0.2)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                                        Button {
                                            input = suggestion
                                            onSubmit()
                                        } label: {
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .fontWeight(.light)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(Material.thin)
                                                .clipShape(Capsule())
                                        }
                                        .opacity(0)
                                        .cascadeIn(delay: 0.3 + Double(index) * 0.05)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Submit button
            Button(action: onSubmit) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(input.isEmpty ? Color.clear : Color.accentColor)
                    .foregroundColor(input.isEmpty ? .accentColor : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        if input.isEmpty {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.accentColor, lineWidth: 1)
                        }
                    }
            }
            .disabled(input.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }
}

// MARK: - Generating

private struct GeneratingView: View {
    @State private var dots = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Creating your\npersonal coach\(dots)")
                .font(.system(size: 32, weight: .thin, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .cascadeIn()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                Task { @MainActor in
                    dots = dots.count < 3 ? dots + "." : ""
                }
            }
        }
    }
}

// MARK: - Confirmation

private struct ConfirmationView: View {
    let plan: CoachingPlan?
    let onAccept: () -> Void
    let onRefine: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            CascadeText("Meet your coach:")
                .font(.system(size: 34, weight: .thin, design: .rounded))
                .foregroundStyle(.primary)
            
            if let plan = plan {
                VStack(spacing: 24) {
                    Text(plan.understandingSummary)
                        .font(.system(size: 17, weight: .light))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("I'm \(plan.generatedPersona.name), your \(plan.generatedPersona.archetype)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .opacity(0)
                                .cascadeIn(delay: 0.2)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(plan.coachingApproach.enumerated()), id: \.offset) { index, point in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .opacity(0)
                                            .cascadeIn(delay: Double(index) * 0.1 + 0.3)
                                        Text(point)
                                            .font(.subheadline)
                                            .fontWeight(.light)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .opacity(0)
                                            .cascadeIn(delay: Double(index) * 0.1 + 0.3)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: 300)
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Let's start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                Button(action: onRefine) {
                    Text("Add more details")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

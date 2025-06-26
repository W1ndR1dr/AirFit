import SwiftUI

/// Turn-based onboarding - simple, clean, effective
struct OnboardingView: View {
    @ObservedObject var intelligence: OnboardingIntelligence
    @State private var phase = Phase.healthPermission
    @State private var userInput = ""
    @State private var conversationCount = 0
    @State private var hasSelectedModel = false
    @State private var error: Error?
    @State private var isRetrying = false
    @State private var fullConversation: [(text: String, isUser: Bool)] = []
    @State private var lastPrompt = ""
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.diContainer) private var diContainer: DIContainer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Phase: Int {
        case healthPermission = 0
        case conversation = 1
        case insightsConfirmation = 2
        case generating = 3
        case confirmation = 4
    }

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressIndicator(currentPhase: phase)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                if let error = error {
                    ErrorRecoveryView(
                        error: error,
                        isRetrying: isRetrying,
                        onRetry: retryLastAction,
                        onSkip: skipToFallback
                    )
                } else {
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
                            intelligence: intelligence,
                            prompt: intelligence.currentPrompt,
                            suggestions: intelligence.contextualSuggestions,
                            conversationHistory: fullConversation,
                            input: $userInput,
                            onSubmit: {
                                Task {
                                    // Add current Q&A to conversation history
                                    fullConversation.append((text: intelligence.currentPrompt, isUser: false))
                                    fullConversation.append((text: userInput, isUser: true))

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
                                        // Hard limit reached: Show insights confirmation
                                        phase = .insightsConfirmation
                                    } else if intelligence.contextQuality.overall >= 0.8 {
                                        // Sufficient context: Show insights confirmation
                                        phase = .insightsConfirmation
                                    } else if let followUp = intelligence.followUpQuestion {
                                        // Still gathering: Use AI-generated follow-up
                                        intelligence.currentPrompt = followUp
                                    } else {
                                        // No follow-up but context insufficient: Show what we have
                                        phase = .insightsConfirmation
                                    }
                                }
                            }
                        )

                    case .insightsConfirmation:
                        InsightsConfirmationView(
                            insights: intelligence.extractedInsights,
                            onConfirm: {
                                phase = .generating
                            },
                            onRefine: {
                                // Go back to conversation with a clarifying prompt
                                intelligence.currentPrompt = "Thanks for clarifying! What else should I know about your fitness goals and preferences?"
                                phase = .conversation
                            }
                        )

                    case .generating:
                        GeneratingView(intelligence: intelligence)
                            .task {
                                await intelligence.generatePersona()
                                if intelligence.coachingPlan != nil {
                                    phase = .confirmation
                                } else {
                                    // Fallback if generation returns no plan
                                    await MainActor.run {
                                        self.error = AppError.llm("Failed to generate coaching plan")
                                    }
                                }
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
            }
        }
        .animation(reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.3), value: phase)
        .onAppear {
            gradientManager.setGradient(.morningTwilight, animated: false)
        }
    }

    private func completeOnboarding() {
        guard let plan = intelligence.coachingPlan else { return }

        Task {
            do {
                async let userService = diContainer.resolve(UserServiceProtocol.self)
                async let personaService = diContainer.resolve(PersonaService.self)
                
                let (userServiceResolved, personaServiceResolved) = try await (userService, personaService)

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
                let user = try await userServiceResolved.createUser(from: profile)
                try await personaServiceResolved.savePersona(plan.generatedPersona, for: user.id)

                // Clear cached session on successful completion
                await intelligence.clearSession()

                // Notify completion
                await MainActor.run {
                    NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
                }
            } catch {
                AppLogger.error("Failed to save onboarding", error: error, category: .onboarding)
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    private func retryLastAction() {
        isRetrying = true
        error = nil

        Task {
            // Retry based on current phase
            switch phase {
            case .healthPermission:
                // Health permission doesn't fail in a way that needs retry
                isRetrying = false
            case .conversation:
                // Re-analyze last conversation
                if let lastInput = intelligence.conversationHistory.last {
                    await intelligence.analyzeConversation(lastInput)
                }
                isRetrying = false
            case .insightsConfirmation:
                // Extract insights again
                if let lastInput = intelligence.conversationHistory.last {
                    await intelligence.analyzeConversation(lastInput)
                }
                isRetrying = false
            case .generating:
                // Retry persona generation
                await intelligence.generatePersona()
                if intelligence.coachingPlan != nil {
                    phase = .confirmation
                }
                isRetrying = false
            case .confirmation:
                // Retry saving
                completeOnboarding()
                isRetrying = false
            }
        }
    }

    private func skipToFallback() {
        error = nil

        // Force fallback persona generation
        Task {
            intelligence.coachingPlan = intelligence.createFallbackPlan()
            phase = .confirmation
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

            Text("I'll analyze your health data to understand your fitness baseline")
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
    @ObservedObject var intelligence: OnboardingIntelligence
    let prompt: String
    let suggestions: [String]
    let conversationHistory: [(text: String, isUser: Bool)]
    @Binding var input: String
    let onSubmit: () -> Void
    @FocusState private var isInputFocused: Bool
    @State private var isFirstMessage = true
    @State private var inputAtBottom = false
    @State private var thinkingDots = ""
    @Namespace private var inputNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            // Conversation history
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Show conversation history
                        ForEach(Array(conversationHistory.enumerated()), id: \.offset) { index, item in
                            MessageBubble(
                                text: item.text,
                                isUser: item.isUser,
                                delay: Double(index) * 0.1
                            )
                            .id(index)
                        }

                        // Current prompt
                        if !prompt.isEmpty {
                            MessageBubble(
                                text: prompt,
                                isUser: false,
                                delay: Double(conversationHistory.count) * 0.1
                            )
                            .id("current")
                        }

                        // AI thinking indicator
                        if intelligence.isAnalyzing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.secondary)

                                Text("AI is thinking\(thinkingDots)")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundStyle(.secondary)

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                        }

                        // Spacer for input area
                        Color.clear
                            .frame(height: inputAtBottom ? 200 : 400)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                }
                .onChange(of: conversationHistory.count) {
                    withAnimation {
                        proxy.scrollTo("current", anchor: .bottom)
                    }
                }
            }

            // Input area
            VStack(spacing: 0) {
                if !inputAtBottom {
                    Spacer()
                }

                VStack(spacing: 16) {
                    // Suggestions
                    if input.isEmpty && !suggestions.isEmpty {
                        FlowLayout(spacing: 12, verticalSpacing: 12) {
                            ForEach(Array(suggestions.prefix(4).enumerated()), id: \.offset) { index, suggestion in
                                Button {
                                    input = suggestion
                                    onSubmit()
                                } label: {
                                    Text(suggestion)
                                        .suggestionChipStyle()
                                }
                                .opacity(0)
                                .cascadeIn(delay: 0.3 + Double(index) * 0.05)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Input field and button
                    HStack(spacing: 12) {
                        TextEditor(text: $input)
                            .frame(minHeight: 44, maxHeight: 100)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .scrollContentBackground(.hidden)
                            .focused($isInputFocused)
                            .background(Material.regular)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        Button(action: {
                            onSubmit()
                            // Animate to bottom after first message
                            if isFirstMessage && conversationHistory.isEmpty {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    inputAtBottom = true
                                    isFirstMessage = false
                                }
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(input.isEmpty || intelligence.isAnalyzing ? .secondary : Color.accentColor)
                                .animation(.easeInOut(duration: 0.2), value: input.isEmpty || intelligence.isAnalyzing)
                        }
                        .disabled(input.isEmpty || intelligence.isAnalyzing)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(
                    Material.thin
                )
            }
            .matchedGeometryEffect(id: "input", in: inputNamespace)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isInputFocused = true
            }

            // Start thinking dots animation
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                Task { @MainActor in
                    if intelligence.isAnalyzing {
                        thinkingDots = thinkingDots.count < 3 ? thinkingDots + "." : ""
                    } else {
                        thinkingDots = ""
                    }
                }
            }
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let text: String
    let isUser: Bool
    let delay: Double
    @State private var isVisible = false

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(text)
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundStyle(isUser ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    isUser ?
                        AnyView(LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )) :
                        AnyView(Color.gray.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            if !isUser { Spacer(minLength: 60) }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Generating

private struct GeneratingView: View {
    @ObservedObject var intelligence: OnboardingIntelligence
    @State private var dots = ""
    @State private var completedPhases: Set<PersonaSynthesisPhase> = []
    @State private var gradientTimer: Timer?
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentProgress: PersonaSynthesisProgress? {
        intelligence.personaSynthesisProgress
    }

    private var progressValue: Double {
        currentProgress?.progress ?? 0.0
    }

    private var currentPhase: String {
        currentProgress?.message ?? "Preparing synthesis..."
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(progressValue > 0.5 ? 1.2 : 1.0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 2).repeatForever(autoreverses: true), value: progressValue)

                Image(systemName: "brain")
                    .font(.system(size: 64))
                    .foregroundStyle(gradientManager.accent.gradient)
                    .symbolEffect(.pulse.byLayer, isActive: !reduceMotion)
                    .scaleEffect(1 + progressValue * 0.2)
            }

            VStack(spacing: 16) {
                Text("Creating your coach\(dots)")
                    .font(.system(size: 32, weight: .thin, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .cascadeIn()

                Text(currentPhase)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(currentPhase)
            }

            // Progress phases with checkmarks
            VStack(alignment: .leading, spacing: 12) {
                ForEach(PersonaSynthesisPhase.allCases, id: \.self) { phase in
                    HStack(spacing: 12) {
                        if let current = currentProgress?.phase {
                            if phase.rawValue < current.rawValue || currentProgress?.isComplete == true {
                                // Completed phase
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 20))
                            } else if phase == current {
                                // Current phase
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                // Future phase
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary.opacity(0.5))
                                    .font(.system(size: 20))
                            }
                        } else {
                            // No progress yet
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary.opacity(0.5))
                                .font(.system(size: 20))
                        }

                        Text(phase.displayName)
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(
                                (currentProgress?.phase == phase) ? .primary : .secondary
                            )
                    }
                    .opacity(0)
                    .cascadeIn(delay: Double(PersonaSynthesisPhase.allCases.firstIndex(of: phase) ?? 0) * 0.1)
                }
            }
            .padding(.horizontal, 40)

            // Progress bar
            if progressValue > 0 {
                VStack(spacing: 8) {
                    ProgressView(value: progressValue)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(gradientManager.accent)
                        .scaleEffect(y: 2)
                        .padding(.horizontal, 60)

                    Text("\(Int(progressValue * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            Spacer()
        }
        .onAppear {
            // Start dots animation
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                Task { @MainActor in
                    dots = dots.count < 3 ? dots + "." : ""
                }
            }

            // Start gradient evolution - advance every 3 seconds
            gradientManager.setGradient(.earlyTwilight, animated: true)
            gradientTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                Task { @MainActor in
                    gradientManager.advance(style: .sunrise)
                }
            }
        }
        .onDisappear {
            gradientTimer?.invalidate()
        }
        .onChange(of: currentProgress?.isComplete) { _, isComplete in
            if isComplete == true {
                gradientTimer?.invalidate()
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
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Error Recovery

private struct ErrorRecoveryView: View {
    let error: Error
    let isRetrying: Bool
    let onRetry: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.orange.gradient)
                .symbolEffect(.pulse)

            VStack(spacing: 16) {
                Text("Oops, something went wrong")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(.primary)

                Text(error.localizedDescription)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack {
                        if isRetrying {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Try Again")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isRetrying)

                Button(action: onSkip) {
                    Text("Continue without AI")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundStyle(.primary)
                }
                .disabled(isRetrying)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Progress Indicator

private struct OnboardingProgressIndicator: View {
    let currentPhase: OnboardingView.Phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let phases: [(OnboardingView.Phase, String, String)] = [
        (.healthPermission, "heart.fill", "Health"),
        (.conversation, "bubble.left.and.bubble.right.fill", "Chat"),
        (.insightsConfirmation, "brain.filled.head.profile", "Insights"),
        (.generating, "sparkles", "Create"),
        (.confirmation, "checkmark.circle.fill", "Done")
    ]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(phases, id: \.0) { phase, icon, label in
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(phaseColor(phase))
                        .symbolEffect(.bounce, isActive: !reduceMotion && currentPhase == phase)

                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(phaseColor(phase))
                }
                .opacity(phaseOpacity(phase))

                if phase != .confirmation {
                    Rectangle()
                        .fill(phaseLineColor(phase))
                        .frame(height: 2)
                        .opacity(0.5)
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func phaseColor(_ phase: OnboardingView.Phase) -> Color {
        if phase.rawValue < currentPhase.rawValue {
            return .green
        } else if phase == currentPhase {
            return .accentColor
        } else {
            return .secondary
        }
    }

    private func phaseOpacity(_ phase: OnboardingView.Phase) -> Double {
        if phase.rawValue <= currentPhase.rawValue {
            return 1.0
        } else {
            return 0.5
        }
    }

    private func phaseLineColor(_ phase: OnboardingView.Phase) -> Color {
        if phase.rawValue < currentPhase.rawValue {
            return .green
        } else {
            return .secondary
        }
    }
}

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

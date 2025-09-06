import SwiftUI
import WatchConnectivity

/// Simplified onboarding view with state machine
struct OnboardingView: View {
    @Environment(\.diContainer) private var diContainer: DIContainer
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @StateObject private var stateMachine = OnboardingStateMachine()
    @State private var intelligence: OnboardingIntelligence?
    @State private var userInput = ""
    @State private var hasSelectedModel = false
    @State private var initError: Error?
    @State private var dotsTimer: Timer?

    var body: some View {
        BaseScreen {
            if let intelligence = intelligence {
                // Main onboarding content
                onboardingContent(intelligence: intelligence)
            } else if let error = initError {
                // Error state
                errorView(error: error)
            } else {
                // Initial loading (should be very brief)
                ProgressView()
                    .task {
                        await loadIntelligence()
                    }
            }
        }
        .animation(reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.3), value: stateMachine.currentState)
        .onDisappear {
            // Clean up timer when view disappears
            dotsTimer?.invalidate()
            dotsTimer = nil
        }
        .onAppear {
            gradientManager.setGradient(.morningTwilight, animated: false)
        }
    }
    
    @ViewBuilder
    private func onboardingContent(intelligence: OnboardingIntelligence) -> some View {
        VStack(spacing: 0) {
            // Progress indicator
            OnboardingProgressIndicator(progress: stateMachine.progressPercentage)
                .padding(.top, 8)
                .padding(.bottom, 16)

            if case .error(let error, _) = stateMachine.currentState {
                ErrorRecoveryView(
                    error: error,
                    isRetrying: stateMachine.isTransitioning,
                    onRetry: { stateMachine.send(.retry) },
                    onSkip: { stateMachine.send(.reset) }
                )
            } else {
                switch stateMachine.currentState {
                case .healthPermission:
                    HealthPermissionView(
                        onAccept: {
                            // Load user's selected model if not already done
                            if !hasSelectedModel {
                                loadUserSelectedModel()
                            }
                            stateMachine.send(.acceptHealthPermission)
                        },
                        onSkip: {
                            stateMachine.send(.skipHealthPermission)
                        }
                    )
                    
                case .healthDataLoading:
                    HealthDataLoadingView(
                        intelligence: intelligence,
                        onContinue: {
                            stateMachine.send(.healthDataLoaded)
                        },
                        onSkip: {
                            stateMachine.send(.skipHealthData)
                        }
                    )

                case .whisperSetup:
                    WhisperSetupView(
                        onContinue: {
                            stateMachine.send(.whisperSetupComplete)
                        },
                        onSkip: {
                            stateMachine.send(.skipWhisperSetup)
                        }
                    )

                case .profileSetup:
                    ProfileSetupView(
                        onComplete: { birthDate, biologicalSex in
                            stateMachine.send(.profileComplete(birthDate: birthDate, biologicalSex: biologicalSex))
                        },
                        onSkip: {
                            stateMachine.send(.skipProfile)
                        }
                    )

                case .conversation:
                    ConversationView(
                        intelligence: intelligence,
                        prompt: stateMachine.getCurrentPrompt(),
                        suggestions: stateMachine.getSuggestions(),
                        conversationHistory: stateMachine.conversationHistory,
                        input: $userInput,
                        onSubmit: {
                            let input = userInput
                            userInput = ""
                            stateMachine.send(.submitConversation(input))
                        }
                    )

                case .insightsConfirmation:
                    InsightsConfirmationView(
                        insights: stateMachine.getInsights(),
                        onConfirm: {
                            stateMachine.send(.confirmInsights)
                        },
                        onRefine: {
                            stateMachine.send(.refineInsights)
                        }
                    )

                case .generating(let progress):
                    GeneratingView(intelligence: intelligence)
                        .onAppear {
                            // Generation is handled by the state machine
                        }

                case .confirmation:
                    ConfirmationView(
                        plan: stateMachine.getCoachingPlan(),
                        onAccept: {
                            stateMachine.send(.acceptPlan)
                        },
                        onRefine: {
                            stateMachine.send(.refinePlan)
                        }
                    )
                    
                case .watchSetup:
                    WatchSetupView(
                        onSetupWatch: {
                            stateMachine.send(.watchSetupComplete)
                            completeOnboarding()
                        },
                        onSkip: {
                            stateMachine.send(.skipWatchSetup)
                            completeOnboarding()
                        }
                    )
                    
                case .completed:
                    // Should never reach here, handled by completeOnboarding
                    EmptyView()
                    
                case .error:
                    // Error is handled above
                    EmptyView()
                }
            }
        }
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text("Failed to initialize onboarding")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                Task {
                    await loadIntelligence()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func loadIntelligence() async {
        do {
            intelligence = try await diContainer.resolve(OnboardingIntelligence.self)
            stateMachine.configure(with: intelligence!)
            initError = nil
        } catch {
            self.initError = error
            AppLogger.error("Failed to resolve OnboardingIntelligence", error: error, category: .app)
        }
    }
    
    private func completeOnboarding() {
        guard let intelligence = intelligence,
              let plan = intelligence.coachingPlan else { return }

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

                // Add profile data if collected
                let (birthDate, biologicalSex) = intelligence.getProfileData()
                profile.birthDate = birthDate
                profile.biologicalSex = biologicalSex

                // Save user and persona
                let user = try await userServiceResolved.createUser(from: profile)
                try await personaServiceResolved.savePersona(plan.generatedPersona, for: user.id)
                
                // CRITICAL: Mark onboarding as complete
                try await userServiceResolved.completeOnboarding()

                // Clear cached session on successful completion
                await intelligence.clearSession()

                // Notify completion
                await MainActor.run {
                    NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
                }
            } catch {
                AppLogger.error("Failed to save onboarding", error: error, category: .onboarding)
                AppLogger.error("Failed to complete onboarding", error: error, category: .onboarding)
            }
        }
    }

    // Legacy error handling methods removed - now handled by state machine

    private func loadUserSelectedModel() {
        // Get the selected provider and model from UserDefaults
        if let providerString = UserDefaults.standard.string(forKey: "default_ai_provider"),
           let provider = AIProvider(rawValue: providerString),
           let modelId = UserDefaults.standard.string(forKey: "default_ai_model") {

            // Set the preferred model in OnboardingIntelligence
            intelligence?.setPreferredModel(provider: provider, modelId: modelId)
            hasSelectedModel = true

            AppLogger.info("Loaded user-selected model: \(provider.displayName) - \(modelId)", category: .onboarding)
        } else {
            // If no model selected, the intelligence will use getBestAvailableModel
            AppLogger.info("No user-selected model found, will use best available", category: .onboarding)
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
    @State private var dotsTimer: Timer?
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
                            .overlay(alignment: .bottomTrailing) {
                                WhisperVoiceButton(text: $input)
                                    .padding(12)
                            }

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
            dotsTimer?.invalidate()
            dotsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                Task { @MainActor in
                    if intelligence.isAnalyzing {
                        thinkingDots = thinkingDots.count < 3 ? thinkingDots + "." : ""
                    } else {
                        thinkingDots = ""
                    }
                }
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            dotsTimer?.invalidate()
            dotsTimer = nil
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

// ErrorRecoveryView moved to separate file


extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
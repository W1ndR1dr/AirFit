import SwiftUI

// MARK: - Onboarding Interview View

struct OnboardingInterviewView: View {
    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var profileProgress = ProfileProgress()
    @State private var showingCompletion = false
    @State private var sessionId: String?
    @FocusState private var isInputFocused: Bool

    let onComplete: () -> Void
    let onSkip: () -> Void

    private let apiClient = APIClient()

    struct ProfileProgress {
        var hasName = false
        var hasGoals = false
        var hasTraining = false
        var hasStyle = false

        var currentStage: Int {
            if !hasName { return 0 }
            if !hasGoals { return 1 }
            if !hasTraining { return 2 }
            if !hasStyle { return 3 }
            return 4
        }

        var isReadyToFinalize: Bool {
            hasName && hasGoals
        }

        mutating func update(from completeness: APIClient.ProfileCompleteness) {
            hasName = completeness.has_name
            hasGoals = completeness.has_goals
            hasTraining = completeness.has_training
            hasStyle = completeness.has_style
        }
    }

    var body: some View {
        ZStack {
            BreathingMeshBackground(scrollProgress: 2.0)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Progress bar
                OnboardingProgressBar(currentStage: profileProgress.currentStage)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                // Chat area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                OnboardingMessageBubble(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .id("typing")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: isLoading) { _, loading in
                        if loading {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                inputBar

                // Bottom actions
                bottomActions
            }

            // Completion overlay
            if showingCompletion {
                OnboardingCompletionView(onContinue: onComplete)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingCompletion)
        .task {
            await startInterview()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack {
            // Centered title
            Text("Getting to Know You")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            // Close button aligned left
            HStack {
                Button(action: onSkip) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface.opacity(0.8))
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .focused($isInputFocused)
                .lineLimit(1...5)
                .submitLabel(.send)
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sendMessage()
                    }
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Theme.textMuted
                            : Theme.accent
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.background.opacity(0.8))
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack {
            Button("Skip for now") {
                onSkip()
            }
            .font(.subheadline)
            .foregroundStyle(Theme.textMuted)

            Spacer()

            if profileProgress.isReadyToFinalize && !isLoading {
                Button(action: finalizeOnboarding) {
                    HStack(spacing: 6) {
                        Text("I'm ready!")
                        Image(systemName: "checkmark")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(AirFitButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
        .animation(.spring(duration: 0.3), value: profileProgress.isReadyToFinalize)
    }

    // MARK: - Actions

    private func startInterview() async {
        // Clear any existing session to start fresh
        do {
            try await apiClient.clearChatSession()
        } catch {
            print("Failed to clear session: \(error)")
        }

        // Send initial greeting
        isLoading = true

        do {
            // Send empty message to get AI's opening greeting
            let response = try await apiClient.sendOnboardingMessage("")
            sessionId = response.session_id

            let aiMessage = Message(content: response.response, isUser: false)
            messages.append(aiMessage)

            // Update profile progress
            if let completeness = response.profile_completeness {
                profileProgress.update(from: completeness)
            }
        } catch {
            // Fallback greeting if server fails
            let fallbackMessage = Message(
                content: "Hey! I'm excited to be your fitness coach. What should I call you, and what brings you here today?",
                isUser: false
            )
            messages.append(fallbackMessage)
        }

        isLoading = false
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = Message(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        Task {
            do {
                let response = try await apiClient.sendOnboardingMessage(text, sessionId: sessionId)
                sessionId = response.session_id

                let aiMessage = Message(content: response.response, isUser: false)

                await MainActor.run {
                    messages.append(aiMessage)

                    // Update profile progress
                    if let completeness = response.profile_completeness {
                        profileProgress.update(from: completeness)
                    }

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = Message(
                        content: "Sorry, I had trouble processing that. Could you try again?",
                        isUser: false
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }

    private func finalizeOnboarding() {
        isLoading = true

        Task {
            do {
                // Finalize onboarding on server
                let _ = try await apiClient.finalizeOnboarding()

                await MainActor.run {
                    isLoading = false
                    showingCompletion = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Still show completion even if finalize fails
                    showingCompletion = true
                }
            }
        }
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStage: Int

    private let stages = ["Intro", "Goals", "Context", "Style"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                HStack(spacing: 4) {
                    Circle()
                        .fill(index <= currentStage ? Theme.accent : Theme.textMuted.opacity(0.3))
                        .frame(width: 8, height: 8)

                    Text(stage)
                        .font(.system(size: 11, weight: index == currentStage ? .semibold : .regular))
                        .foregroundStyle(index <= currentStage ? Theme.accent : Theme.textMuted)
                }

                if index < stages.count - 1 {
                    Rectangle()
                        .fill(index < currentStage ? Theme.accent : Theme.textMuted.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Theme.surface.opacity(0.6))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: currentStage)
    }
}

// MARK: - Message Bubble

struct OnboardingMessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }

            Text(message.content)
                .font(.bodyMedium)
                .foregroundStyle(message.isUser ? .white : Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.isUser
                        ? AnyShapeStyle(Theme.accentGradient)
                        : AnyShapeStyle(Theme.surface)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Theme.textMuted)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    OnboardingInterviewView(onComplete: {}, onSkip: {})
}

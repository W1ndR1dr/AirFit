import SwiftUI

// MARK: - Onboarding Interview View

/// Conversational onboarding that feels like meeting a cool new coach.
/// Progress is LLM-driven - the AI extracts profile info and milestones update automatically.
/// Routes to Claude (server) or Gemini based on user's provider selection.
struct OnboardingInterviewView: View {
    @AppStorage("aiProvider") private var aiProvider: String = "claude"

    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var profileProgress = ProfileProgress()
    @State private var showingCompletion = false
    @State private var sessionId: String?
    @State private var conversationHistory: [ConversationMessage] = []
    @State private var isVoiceInputActive = false
    @State private var showVoiceOverlay = false
    @State private var speechManager = SpeechTranscriptionManager()
    @FocusState private var isInputFocused: Bool

    let onComplete: () -> Void
    let onSkip: () -> Void

    private let apiClient = APIClient()

    /// Whether to use Gemini directly (no server)
    private var useGemini: Bool {
        aiProvider == "gemini"
    }

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
                // Header - light, friendly
                headerView

                // Progress indicator - shows what the AI has learned
                OnboardingMilestones(progress: profileProgress)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                // Chat area - matches Coach tab design
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(messages) { message in
                                OnboardingMessageCard(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                thinkingIndicator
                                    .id("thinking")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 140)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.airfit) {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: isLoading) { _, loading in
                        if loading {
                            withAnimation(.airfit) {
                                proxy.scrollTo("thinking", anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area - matches Coach tab
                inputBar
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
        .fullScreenCover(isPresented: $showVoiceOverlay) {
            VoiceInputOverlay(
                speechManager: speechManager,
                onComplete: { transcript in
                    inputText = transcript
                    showVoiceOverlay = false
                    isVoiceInputActive = false
                    sendMessage()
                },
                onCancel: {
                    showVoiceOverlay = false
                    isVoiceInputActive = false
                }
            )
            .background(ClearBackgroundView())
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Skip/close button
            Button(action: onSkip) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            // Friendly title
            Text("Let's Chat")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            // Ready button (appears when enough info gathered)
            if profileProgress.isReadyToFinalize && !isLoading {
                Button(action: finalizeOnboarding) {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accentGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(AirFitButtonStyle())
                .transition(.scale.combined(with: .opacity))
            } else {
                // Invisible placeholder for layout balance
                Color.clear
                    .frame(width: 60, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(.spring(duration: 0.3), value: profileProgress.isReadyToFinalize)
    }

    // MARK: - Thinking Indicator (matches Coach tab)

    private var thinkingIndicator: some View {
        HStack(spacing: 12) {
            StreamingWave()

            Text("Thinking")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)

            Spacer()
        }
        .padding(.vertical, 16)
    }

    // MARK: - Input Bar (matches Coach tab)

    private var inputBar: some View {
        HStack(spacing: 12) {
            // Text field with voice input
            HStack(spacing: 8) {
                TextField("Say something...", text: $inputText, axis: .vertical)
                    .font(.bodyMedium)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .submitLabel(.send)
                    .onSubmit {
                        if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            sendMessage()
                        }
                    }

                // Voice input button
                VoiceInputButton(isRecording: isVoiceInputActive) {
                    startVoiceInput()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Theme.textMuted.opacity(0.2), lineWidth: 1)
            )

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        canSend
                            ? AnyShapeStyle(Theme.accentGradient)
                            : AnyShapeStyle(Theme.textMuted)
                    )
            }
            .buttonStyle(AirFitButtonStyle())
            .disabled(!canSend)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    // MARK: - Actions

    private func startInterview() async {
        isLoading = true

        if useGemini {
            // Gemini mode - use direct API
            await startGeminiInterview()
        } else {
            // Server mode - use existing flow
            await startServerInterview()
        }

        isLoading = false
    }

    private func startServerInterview() async {
        // Clear any existing session to start fresh
        do {
            try await apiClient.clearChatSession()
        } catch {
            print("Failed to clear session: \(error)")
        }

        do {
            // Send empty message to get AI's opening greeting
            let response = try await apiClient.sendOnboardingMessage("")
            sessionId = response.session_id

            let aiMessage = Message(content: response.response, isUser: false)
            withAnimation(.airfit) {
                messages.append(aiMessage)
            }

            // Update profile progress
            if let completeness = response.profile_completeness {
                profileProgress.update(from: completeness)
            }
        } catch {
            // Fallback greeting if server fails
            let fallbackMessage = Message(
                content: "Hey! I'm pumped to be your coach. What should I call you, and what's the main thing you're working on right now?",
                isUser: false
            )
            withAnimation(.airfit) {
                messages.append(fallbackMessage)
            }
        }
    }

    private func startGeminiInterview() async {
        do {
            let rawGreeting = try await GeminiService.shared.chat(
                message: "Start the conversation with a friendly greeting. Ask for my name and what fitness goals I'm working on.",
                history: [],
                systemPrompt: geminiOnboardingPrompt,
                thinkingLevel: .high  // High effort for persona generation
            )

            // Parse to strip any JSON tags
            let (cleanGreeting, progress) = parseGeminiResponse(rawGreeting)

            let aiMessage = Message(content: cleanGreeting, isUser: false)
            conversationHistory.append(ConversationMessage(role: "model", content: cleanGreeting))

            withAnimation(.airfit) {
                messages.append(aiMessage)
            }

            // Update progress if present
            if let progress = progress {
                withAnimation(.spring(duration: 0.4)) {
                    profileProgress.hasName = progress.hasName
                    profileProgress.hasGoals = progress.hasGoals
                    profileProgress.hasTraining = progress.hasTraining
                    profileProgress.hasStyle = progress.hasStyle
                }
            }
        } catch {
            // Fallback greeting
            let fallbackMessage = Message(
                content: "Hey! I'm excited to be your coach. What should I call you, and what are you working on fitness-wise?",
                isUser: false
            )
            conversationHistory.append(ConversationMessage(role: "model", content: fallbackMessage.content))
            withAnimation(.airfit) {
                messages.append(fallbackMessage)
            }
        }
    }

    private var geminiOnboardingPrompt: String {
        """
        You are AirFit, a friendly and motivating fitness coach meeting a new user for the first time.

        Your goal is to have a natural conversation to learn about them:
        - Their name
        - Their fitness goals (weight loss, muscle gain, general health, performance, etc.)
        - Their current training experience and preferences
        - Their preferred coaching style (tough love, gentle encouragement, data-focused, etc.)

        Be warm, conversational, and enthusiastic. Ask follow-up questions naturally.
        Keep responses concise (2-4 sentences). Don't be robotic or list-like.

        After each response, on a NEW LINE, output a JSON object with what you've learned:
        {"hasName": true/false, "hasGoals": true/false, "hasTraining": true/false, "hasStyle": true/false}

        Only set a field to true when the user has CLEARLY provided that information.
        """
    }

    // MARK: - Voice Input

    private func startVoiceInput() {
        Task {
            do {
                isVoiceInputActive = true
                try await speechManager.startListening()
                showVoiceOverlay = true
            } catch {
                isVoiceInputActive = false
                print("Failed to start voice input: \(error)")
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Dismiss keyboard
        isInputFocused = false

        // Add user message
        let userMessage = Message(content: text, isUser: true)
        withAnimation(.airfit) {
            messages.append(userMessage)
        }
        inputText = ""
        isLoading = true

        Task {
            if useGemini {
                await sendGeminiMessage(text)
            } else {
                await sendServerMessage(text)
            }
        }
    }

    private func sendServerMessage(_ text: String) async {
        do {
            let response = try await apiClient.sendOnboardingMessage(text, sessionId: sessionId)
            sessionId = response.session_id

            let aiMessage = Message(content: response.response, isUser: false)

            await MainActor.run {
                withAnimation(.airfit) {
                    messages.append(aiMessage)
                }

                // Update profile progress (LLM-driven milestones)
                if let completeness = response.profile_completeness {
                    withAnimation(.spring(duration: 0.4)) {
                        profileProgress.update(from: completeness)
                    }
                }

                isLoading = false
            }
        } catch {
            await MainActor.run {
                let errorMessage = Message(
                    content: "Hmm, lost the connection for a sec. Mind trying that again?",
                    isUser: false
                )
                withAnimation(.airfit) {
                    messages.append(errorMessage)
                }
                isLoading = false
            }
        }
    }

    private func sendGeminiMessage(_ text: String) async {
        // Add user message to history
        conversationHistory.append(ConversationMessage(role: "user", content: text))

        do {
            let response = try await GeminiService.shared.chat(
                message: text,
                history: conversationHistory,
                systemPrompt: geminiOnboardingPrompt,
                thinkingLevel: .high  // High effort for persona generation
            )

            // Parse the response - extract JSON progress if present
            let (cleanResponse, progress) = parseGeminiResponse(response)

            // Add to history
            conversationHistory.append(ConversationMessage(role: "model", content: cleanResponse))

            let aiMessage = Message(content: cleanResponse, isUser: false)

            await MainActor.run {
                withAnimation(.airfit) {
                    messages.append(aiMessage)
                }

                // Update profile progress from parsed JSON
                if let progress = progress {
                    withAnimation(.spring(duration: 0.4)) {
                        profileProgress.hasName = progress.hasName
                        profileProgress.hasGoals = progress.hasGoals
                        profileProgress.hasTraining = progress.hasTraining
                        profileProgress.hasStyle = progress.hasStyle
                    }
                }

                isLoading = false
            }
        } catch {
            await MainActor.run {
                let errorMessage = Message(
                    content: "Hmm, having trouble connecting. Mind trying that again?",
                    isUser: false
                )
                withAnimation(.airfit) {
                    messages.append(errorMessage)
                }
                isLoading = false
            }
        }
    }

    /// Parse Gemini response to extract the conversational text and JSON progress
    private func parseGeminiResponse(_ response: String) -> (String, GeminiProgress?) {
        // Look for JSON at the end of the response
        let lines = response.components(separatedBy: "\n")
        var textLines: [String] = []
        var progress: GeminiProgress?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
                // Try to parse as JSON
                if let data = trimmed.data(using: .utf8),
                   let parsed = try? JSONDecoder().decode(GeminiProgress.self, from: data) {
                    progress = parsed
                    continue
                }
            }
            textLines.append(line)
        }

        let cleanText = textLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (cleanText, progress)
    }

    struct GeminiProgress: Decodable {
        let hasName: Bool
        let hasGoals: Bool
        let hasTraining: Bool
        let hasStyle: Bool
    }

    private func finalizeOnboarding() {
        isLoading = true

        Task {
            if useGemini {
                // Gemini mode - no server to finalize, just complete locally
                await MainActor.run {
                    isLoading = false
                    showingCompletion = true
                }
            } else {
                // Server mode - finalize on server
                do {
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
}

// MARK: - Milestone Progress (LLM-driven)

/// Shows what the AI has learned so far - smooth progress bar with status text.
struct OnboardingMilestones: View {
    let progress: OnboardingInterviewView.ProfileProgress

    private var completedCount: Int {
        var count = 0
        if progress.hasName { count += 1 }
        if progress.hasGoals { count += 1 }
        if progress.hasTraining { count += 1 }
        if progress.hasStyle { count += 1 }
        return count
    }

    private var progressFraction: CGFloat {
        CGFloat(completedCount) / 4.0
    }

    private var statusText: String {
        switch completedCount {
        case 0: return "Getting to know you..."
        case 1: return "Learning your goals..."
        case 2: return "Understanding your training..."
        case 3: return "Almost there..."
        default: return "Ready to go!"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // Status text
            HStack {
                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                Text("\(completedCount)/4")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textMuted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Theme.textMuted.opacity(0.2))
                        .frame(height: 6)

                    // Fill
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Theme.accentGradient)
                        .frame(width: geo.size.width * progressFraction, height: 6)
                        .animation(.spring(duration: 0.4), value: progressFraction)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Message Card (matches PremiumMessageView)

struct OnboardingMessageCard: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with role indicator
            HStack(spacing: 8) {
                if message.isUser {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                    Text("You")
                        .font(.labelMedium)
                        .tracking(0.5)
                        .foregroundStyle(Theme.textMuted)
                } else {
                    BreathingDot()
                    Text("Coach")
                        .font(.labelMedium)
                        .tracking(0.5)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
            }

            // Message content
            Text(message.content)
                .font(.bodyMedium)
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(message.isUser ? AnyShapeStyle(Theme.accent.opacity(0.08)) : AnyShapeStyle(.ultraThinMaterial))
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    message.isUser ? Theme.accent.opacity(0.15) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    OnboardingInterviewView(onComplete: {}, onSkip: {})
}

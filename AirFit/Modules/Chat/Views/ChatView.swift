import SwiftUI
import Combine

// MARK: - Chat Container with DI
struct Chat: View {
    let user: User
    @State private var viewModel: ChatViewModel?
    @Environment(\.diContainer) private var container

    var body: some View {
        Group {
            if let viewModel = viewModel {
                ChatView(viewModel: viewModel, user: user)
            } else {
                TextLoadingView.connectingToCoach()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeChatViewModel(user: user)
                    }
            }
        }
    }
}

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    let user: User
    @State private var coordinator = ChatCoordinator()
    @FocusState private var isComposerFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    // iOS 26 Liquid Glass morphing namespace for messages
    @Namespace private var messageMorphing

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            BaseScreen {
                VStack(spacing: 0) {
                    // Gradient header with coach name
                    if animateIn {
                        VStack(spacing: AppSpacing.xs) {
                            GradientText("AI Coach", style: .primary)
                                .font(.system(size: 24, weight: .light, design: .rounded))

                            GradientText("Your Personal Fitness Guide", style: .subtle)
                                .font(.system(size: 14, weight: .light))
                        }
                        .padding(.vertical, AppSpacing.xs)
                        .frame(maxWidth: .infinity)
                        .glassEffect(.thin)
                    }

                    messagesScrollView

                    if !viewModel.quickSuggestions.isEmpty {
                        suggestionsBar
                    }

                    // Glass morphism composer
                    MessageComposer(
                        text: $viewModel.composerText,
                        attachments: $viewModel.attachments,
                        isRecording: viewModel.isRecording,
                        waveform: viewModel.voiceWaveform,
                        onSend: { Task { await viewModel.sendMessage() } },
                        onVoiceToggle: { Task { await viewModel.toggleVoiceRecording() } }
                    )
                    .focused($isComposerFocused)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .glassEffect()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: ChatDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(item: $coordinator.activeSheet) { sheet in
                sheetView(for: sheet)
            }
            .task {
                await viewModel.loadOrCreateSession()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom()
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Messages List
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                messagesList
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear { scrollProxy = proxy }
                    .onChange(of: coordinator.scrollToMessageId) { _, messageId in
                        if let id = messageId {
                            withAnimation(MotionToken.standardSpring) {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var messagesList: some View {
        LazyVStack(spacing: 16) {
            // Welcome message if no messages
            if viewModel.messages.isEmpty && animateIn {
                welcomeMessage
            }

            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                messageRow(message: message, index: index)
            }

            if viewModel.isStreaming {
                if !viewModel.streamingText.isEmpty {
                    StreamingAssistantText(text: viewModel.streamingText)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    HStack {
                        Spacer()
                        Button {
                            Task { await viewModel.stopStreaming() }
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .padding(.horizontal, AppSpacing.screenPadding)
                    }
                } else {
                    typingIndicator
                }
            }
        }
        .padding(.vertical, 20)
        // Auto-scroll as streaming text updates
        .onChange(of: viewModel.streamingText) { _, _ in
            scrollToBottom()
        }
    }

    @ViewBuilder
    private var welcomeMessage: some View {
        GlassCard {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(gradientIcon)
                    .accessibilityHidden(true)

                GradientText("Welcome! How can I help you today?", style: .primary)
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .multilineTextAlignment(.center)

                GradientText("I'm your personalized AI coach, here to support your fitness journey.", style: .subtle)
                    .font(.system(size: 14, weight: .light))
                    .multilineTextAlignment(.center)
            }
            .padding(AppSpacing.md)
        }
        .padding(AppSpacing.screenPadding)
        .transition(.scale.combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome message")
        .accessibilityValue("Welcome! How can I help you today? I'm your personalized AI coach, here to support your fitness journey.")
    }

    @ViewBuilder
    private func messageRow(message: ChatMessage, index: Int) -> some View {
        TextStreamMessage(
            message: message,
            isStreaming: viewModel.isStreaming && message == viewModel.messages.last,
            messageMorphing: messageMorphing,
            onAction: { action in
                handleMessageAction(action, message: message)
            }
        )
        .id(message.id)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .opacity(animateIn ? 1 : 0)
        .animation(
            .snappy(duration: 0.3).delay(Double(index) * 0.05),
            value: animateIn
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to show message actions")
    }

    @ViewBuilder
    private var typingIndicator: some View {
        HStack {
            ChatTypingIndicator()
                .padding(.leading, AppSpacing.sm)
            Spacer()
        }
        .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .leading)))
        .accessibilityLabel("AI is typing")
        .accessibilityValue("Generating response")
    }

    private var gradientIcon: LinearGradient {
        LinearGradient(
            colors: gradientManager.active.colors(for: colorScheme),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Suggestions Bar
    private var suggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(viewModel.quickSuggestions) { suggestion in
                    SuggestionChip(
                        suggestion: suggestion,
                        onTap: {
                            HapticService.selection()
                            viewModel.selectSuggestion(suggestion)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.vertical, AppSpacing.xs)
        }
        .glassEffect()
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu(content: {
                Button(action: {
                    HapticService.selection()
                    coordinator.showSheet(.sessionHistory)
                }, label: {
                    Label("Chat History", systemImage: "clock")
                })

                Button(action: {
                    HapticService.selection()
                    coordinator.navigateTo(.searchResults)
                }, label: {
                    Label("Search", systemImage: "magnifyingglass")
                })

                Button(action: {
                    HapticService.selection()
                    coordinator.showSheet(.exportChat)
                }, label: {
                    Label("Export Chat", systemImage: "square.and.arrow.up")
                })

                Divider()

                Button(action: {
                    HapticService.selection()
                    startNewSession()
                }, label: {
                    Label("New Session", systemImage: "plus.bubble")
                })
            }, label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            })
        }
    }

    // MARK: - Navigation
    @ViewBuilder
    private func destinationView(for destination: ChatDestination) -> some View {
        switch destination {
        case .messageDetail(let messageId):
            MessageDetailView(messageId: messageId)
        case .searchResults:
            ChatSearchView(viewModel: viewModel)
        case .sessionSettings:
            SessionSettingsView(session: viewModel.currentSession)
        case .progressView:
            TextLoadingView(message: "Loading progress")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: ChatSheet) -> some View {
        switch sheet {
        case .sessionHistory:
            ChatHistoryView(user: viewModel.user)
        case .exportChat:
            ChatExportView(viewModel: viewModel)
        case .voiceSettings:
            // Note: Voice settings temporarily unavailable with stub implementation
            VStack {
                Image(systemName: "mic.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Voice settings temporarily unavailable")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Using stub implementation for demo purposes")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        case .imageAttachment:
            ImagePickerView { image in
                viewModel.attachments.append(
                    ChatAttachment(type: .image, filename: UUID().uuidString + ".png", data: image.pngData() ?? Data())
                )
            }
        }
    }

    // MARK: - Actions
    private func handleMessageAction(_ action: MessageAction, message: ChatMessage) {
        switch action {
        case .copy:
            viewModel.copyMessage(message)
        case .delete:
            Task { await viewModel.deleteMessage(message) }
        case .regenerate:
            Task { await viewModel.regenerateResponse(for: message) }
        case .showDetails:
            coordinator.navigateTo(.messageDetail(messageId: message.id.uuidString))
        case .scheduleWorkout:
            // Handle workout scheduling
            Task { await viewModel.scheduleWorkout(from: message) }
        case .viewProgress:
            // Handle progress viewing
            coordinator.navigateTo(.progressView)
        case .setReminder:
            // Handle reminder setting
            Task { await viewModel.setReminder(from: message) }
        }
    }

    private func startNewSession() {
        Task {
            viewModel.currentSession?.isActive = false
            await viewModel.loadOrCreateSession()
        }
    }

    private func scrollToBottom() {
        if let last = viewModel.messages.last {
            withAnimation { scrollProxy?.scrollTo(last.id, anchor: .bottom) }
        }
    }
}

// MARK: - Streaming Assistant Text
private struct StreamingAssistantText: View {
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                // Assistant indicator - same as TextStreamMessage
                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                    
                    Text("AI Coach")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                }
                
                // Message content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(text)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Subtle progress indicator
                    HStack {
                        TextLoadingView(message: "Coach is thinking", style: .subtle)
                        
                        Text("Generating response...")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(.tertiary)
                            .opacity(0.7)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
        }
    }
}

// MARK: - Mock Services
private final class ChatMockCoachEngine: CoachEngineProtocol, @unchecked Sendable {
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        return "Great workout! You completed \(request.workout.exercises.count) exercises. Keep up the excellent work!"
    }

    func processUserMessage(_ text: String, for user: User) async {
        // Mock implementation - no-op for preview
    }
}

// MARK: - Placeholder Types

private struct SuggestionChip: View {
    let suggestion: QuickSuggestion
    let onTap: () -> Void
    @State private var isPressed = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            Text(suggestion.text)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.primary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .glassEffect(in: .capsule)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isPressed ? 2 : 1
                                )
                        )
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.standardSpring) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

private struct ChatTypingIndicator: View {
    @State private var animationPhase: CGFloat = 0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationScale(for: index))
                    .opacity(animationOpacity(for: index))
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            Capsule()
                .glassEffect(in: .capsule)
        )
        .onAppear {
            withAnimation(
                .smooth(duration: 1.4)
                    .repeatForever(autoreverses: false)
            ) {
                animationPhase = 3
            }
        }
    }

    private func animationScale(for index: Int) -> CGFloat {
        let phase = animationPhase - CGFloat(index) * 0.3
        let normalizedPhase = (phase.truncatingRemainder(dividingBy: 3) + 3).truncatingRemainder(dividingBy: 3)

        if normalizedPhase < 1 {
            return 1 + normalizedPhase * 0.3
        } else if normalizedPhase < 2 {
            return 1.3 - (normalizedPhase - 1) * 0.3
        } else {
            return 1
        }
    }

    private func animationOpacity(for index: Int) -> Double {
        let scale = animationScale(for: index)
        return scale > 1 ? 1 : 0.6
    }
}

private struct MessageDetailView: View {
    let messageId: String
    var body: some View { Text("Message \(messageId)") }
}

private struct ChatSearchView: View {
    let viewModel: ChatViewModel
    var body: some View { Text("Search") }
}

private struct SessionSettingsView: View {
    let session: ChatSession?
    var body: some View { Text("Session Settings") }
}

private struct ChatHistoryView: View {
    let user: User
    var body: some View { Text("History") }
}

private struct ChatExportView: View {
    let viewModel: ChatViewModel
    var body: some View { Text("Export") }
}


private struct ImagePickerView: View {
    var onPick: (UIImage) -> Void
    var body: some View { Text("Image Picker") }
}

// MARK: - Text Stream Message Component

struct TextStreamMessage: View {
    let message: ChatMessage
    let isStreaming: Bool
    let messageMorphing: Namespace.ID
    let onAction: (MessageAction) -> Void
    
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                // Role indicator
                roleIndicator
                
                // Message content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    messageContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
        }
        .glassEffect(
            message.roleEnum == .user ? .thin : .regular,
            in: .rect(cornerRadius: 16)
        )
        .glassEffectID("message-\(message.id)", in: messageMorphing)
        .contextMenu {
            messageContextMenu
        }
        .onAppear {
            withAnimation(.snappy(duration: 0.3)) {
                animateIn = true
            }
        }
    }
    
    @ViewBuilder
    private var roleIndicator: some View {
        if message.roleEnum == .user {
            // User messages: indented with subtle opacity
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                
                Text("You")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .opacity(0.7)
            }
        } else {
            // Assistant messages: full width with accent dot
            HStack(spacing: 6) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                
                Text("AI Coach")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        if isStreaming {
            StreamingTextContent(
                text: message.content,
                isUser: message.roleEnum == .user
            )
        } else {
            Text(message.content)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(message.roleEnum == .user ? .secondary : .primary)
                .multilineTextAlignment(.leading)
                .opacity(message.roleEnum == .user ? 0.8 : 1.0)
        }
        
        // Timestamp
        HStack {
            Spacer()
            Text(formatTimestamp(message.timestamp))
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(.tertiary)
                .opacity(0.6)
        }
        .padding(.top, AppSpacing.xs)
    }
    
    @ViewBuilder
    private var messageContextMenu: some View {
        Button(action: { onAction(.copy) }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if message.roleEnum == .assistant {
            Button(action: { onAction(.regenerate) }) {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }
        
        Button(role: .destructive, action: { onAction(.delete) }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return date.formatted(.dateTime.hour().minute())
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday " + date.formatted(.dateTime.hour().minute())
        } else {
            return date.formatted(.dateTime.month().day().hour().minute())
        }
    }
}

// MARK: - Streaming Text Content

struct StreamingTextContent: View {
    let text: String
    let isUser: Bool
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    var body: some View {
        Text(displayedText)
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(isUser ? .secondary : .primary)
            .multilineTextAlignment(.leading)
            .opacity(isUser ? 0.8 : 1.0)
            .task {
                await streamText()
            }
    }
    
    private func streamText() async {
        displayedText = ""
        currentIndex = 0
        
        let characters = Array(text)
        for (index, character) in characters.enumerated() {
            displayedText.append(character)
            currentIndex = index
            
            // Variable delay for natural streaming
            let delay = character == " " ? 15 : 25
            try? await Task.sleep(for: .milliseconds(delay))
        }
    }
}

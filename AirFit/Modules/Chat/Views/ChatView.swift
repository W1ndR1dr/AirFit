import SwiftUI
import SwiftData
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
                ProgressView()
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

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            BaseScreen {
                VStack(spacing: 0) {
                    // Gradient header with coach name
                    if animateIn {
                        VStack(spacing: AppSpacing.xs) {
                            CascadeText("AI Coach")
                                .font(.system(size: 24, weight: .light, design: .rounded))
                            
                            Text("Your Personal Fitness Guide")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
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
                    .background(.ultraThinMaterial)
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
        LazyVStack(spacing: AppSpacing.sm) {
            // Welcome message if no messages
            if viewModel.messages.isEmpty && animateIn {
                welcomeMessage
            }
            
            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                messageRow(message: message, index: index)
            }

            if viewModel.isStreaming {
                typingIndicator
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.screenPadding)
    }
    
    @ViewBuilder
    private var welcomeMessage: some View {
        GlassCard {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(gradientIcon)
                    .accessibilityHidden(true)
                
                CascadeText("Welcome! How can I help you today?")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("I'm your personalized AI coach, here to support your fitness journey.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.secondary)
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
        MessageBubbleView(
            message: message,
            isStreaming: viewModel.isStreaming && message == viewModel.messages.last,
            onAction: { action in
                handleMessageAction(action, message: message)
            }
        )
        .id(message.id)
        .transition(.asymmetric(
            insertion: .push(from: message.role == "user" ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity
        ))
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
        .animation(
            MotionToken.standardSpring.delay(Double(index) * 0.05),
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
            Spacer()
        }
        .padding(.leading, AppSpacing.md)
        .transition(.scale.combined(with: .opacity))
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
        .background(.ultraThinMaterial)
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
            ProgressView("Loading Progress...")
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
            if let modelManager = viewModel.voiceManager.modelManager as? WhisperModelManager {
                VoiceSettingsView(modelManager: modelManager)
            } else {
                Text("Voice settings unavailable")
            }
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
                        .fill(.ultraThinMaterial)
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
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.4)
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

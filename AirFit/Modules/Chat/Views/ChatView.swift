import SwiftUI
import SwiftData
import Combine

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var coordinator: ChatCoordinator
    @FocusState private var isComposerFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?

    init(user: User, modelContext: ModelContext) {
        let coordinator = ChatCoordinator()
        // Create simple mock services for now
        let mockCoachEngine = ChatMockCoachEngine()
        let mockAIService = MockAIService()
        
        let viewModel = ChatViewModel(
            modelContext: modelContext,
            user: user,
            coachEngine: mockCoachEngine,
            aiService: mockAIService,
            coordinator: coordinator
        )
        _viewModel = StateObject(wrappedValue: viewModel)
        _coordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            VStack(spacing: 0) {
                messagesScrollView

                if !viewModel.quickSuggestions.isEmpty {
                    suggestionsBar
                }

                MessageComposer(
                    text: $viewModel.composerText,
                    attachments: $viewModel.attachments,
                    isRecording: viewModel.isRecording,
                    waveform: viewModel.voiceWaveform,
                    onSend: { Task { await viewModel.sendMessage() } },
                    onVoiceToggle: { Task { await viewModel.toggleVoiceRecording() } }
                )
                .focused($isComposerFocused)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(AppColors.backgroundPrimary)
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
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
        }
    }

    // MARK: - Messages List
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isStreaming: viewModel.isStreaming && message == viewModel.messages.last,
                            onAction: { action in
                                handleMessageAction(action, message: message)
                            }
                        )
                        .id(message.id)
                        .transition(.opacity)
                    }

                    if viewModel.isStreaming {
                        HStack {
                            ChatTypingIndicator()
                            Spacer()
                        }
                        .padding(.leading, AppSpacing.medium)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { scrollProxy = proxy }
            .onChange(of: coordinator.scrollToMessageId) { _, messageId in
                if let id = messageId {
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
        .background(AppColors.backgroundSecondary)
    }

    // MARK: - Suggestions Bar
    private var suggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
                ForEach(viewModel.quickSuggestions) { suggestion in
                    SuggestionChip(
                        suggestion: suggestion,
                        onTap: { viewModel.selectSuggestion(suggestion) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, AppSpacing.small)
        }
        .background(AppColors.backgroundSecondary)
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu(content: {
                Button(action: { coordinator.showSheet(.sessionHistory) }) {
                    Label("Chat History", systemImage: "clock")
                }

                Button(action: { coordinator.navigateTo(.searchResults) }) {
                    Label("Search", systemImage: "magnifyingglass")
                }

                Button(action: { coordinator.showSheet(.exportChat) }) {
                    Label("Export Chat", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(action: startNewSession) {
                    Label("New Session", systemImage: "plus.bubble")
                }
            }, label: {
                Image(systemName: "ellipsis.circle")
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
    private func sheetView(for sheet: ChatCoordinator.ChatSheet) -> some View {
        switch sheet {
        case .sessionHistory:
            ChatHistoryView(user: viewModel.user)
        case .exportChat:
            ChatExportView(viewModel: viewModel)
        case .voiceSettings:
            VoiceSettingsView()
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

    var body: some View {
        Button(action: onTap) {
            Text(suggestion.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(AppColors.accent.opacity(0.2)))
        }
    }
}

private struct ChatTypingIndicator: View {
    var body: some View {
        ProgressView()
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

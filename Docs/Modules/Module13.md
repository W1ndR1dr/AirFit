**Modular Sub-Document 13: Chat Interface Module (AI Coach Interaction)**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
- Completion of Module 1: Core Project Setup & Configuration
- Completion of Module 2: Data Layer (SwiftData Schema & Managers)
- Completion of Module 4: AI Coach Engine
- Completion of Module 10: Services Layer - AI API Client
- Completion of Module 11: Settings Module
**Date:** December 2024
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To provide an intuitive, responsive chat interface for users to interact with their AI fitness coach, featuring real-time streaming responses, context-aware suggestions, superior voice input via Whisper, and rich message rendering.
*   **Responsibilities:**
    *   Real-time chat UI with streaming AI responses
    *   Message history management with SwiftData
    *   Voice input integration with WhisperKit for superior transcription
    *   Rich message rendering (text, charts, suggestions)
    *   Context-aware quick actions and suggestions
    *   Multi-modal input (text, voice, images)
    *   Chat session management and persistence
    *   Export and search functionality
    *   Fitness-specific transcription post-processing
*   **Key Components:**
    *   `ChatCoordinator.swift` - Navigation and flow management
    *   `ChatViewModel.swift` - Business logic and state management
    *   `ChatView.swift` - Main chat interface
    *   `MessageComposer.swift` - Input interface with voice support
    *   `MessageBubbleView.swift` - Message rendering
    *   `ChatHistoryManager.swift` - Session and history management
    *   `VoiceInputManager.swift` - Speech recognition handler
    *   `ChatSuggestionsEngine.swift` - Context-aware suggestions

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Core utilities, theme system
    *   Module 2: Message and chat session models
    *   Module 4: AI Coach Engine for responses
    *   Module 10: AI API Service for streaming
    *   Module 11: User preferences and settings
    *   System frameworks: AVFoundation
    *   External packages: WhisperKit (for voice transcription)
*   **Outputs:**
    *   Persisted chat messages
    *   Chat session analytics
    *   Exported conversation history
    *   High-quality voice transcriptions with fitness-specific accuracy

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 13.0: Chat Infrastructure**

**Agent Task 13.0.0: Configure WhisperKit Package**
- File: `Package.swift` (or Xcode project)
- Configuration:
  ```swift
  // Add to Package.swift dependencies
  .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0")
  
  // Add to target dependencies
  .product(name: "WhisperKit", package: "WhisperKit")
  ```
- Info.plist additions:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>AirFit uses your microphone to transcribe voice messages to your AI coach using advanced on-device speech recognition.</string>
  ```
- Model Download Strategy:
  - **Default Model**: Use `base` model (74MB) for initial implementation
  - **Model Selection Logic**: 
    ```swift
    // Determine model based on device capabilities
    func selectOptimalModel() -> String {
      let deviceMemory = ProcessInfo.processInfo.physicalMemory
      let deviceModel = UIDevice.current.model
      
      if deviceMemory >= 8_000_000_000 { // 8GB+ RAM
        return "large-v3" // Best accuracy for high-end devices
      } else if deviceMemory >= 6_000_000_000 { // 6GB+ RAM
        return "medium" // Good balance
      } else {
        return "base" // Fast and memory-efficient
      }
    }
    ```
  - **Download on First Use**: Show progress UI during download
  - **Cache Location**: `Library/Application Support/WhisperModels/`
  - **Model Files Structure**:
    ```
    Library/Application Support/WhisperModels/whisper-large-v3-mlx/
    ├── config.json
    └── weights.npz
    ```
  - **Download Error Handling**: Implement retry with exponential backoff
  - **Offline Fallback**: Keep base model as mandatory, others optional

**Agent Task 13.0.1: Create Chat Coordinator**
- File: `AirFit/Modules/Chat/ChatCoordinator.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import Observation
  
  @MainActor
  @Observable
  final class ChatCoordinator {
      // MARK: - Navigation State
      var navigationPath = NavigationPath()
      var activeSheet: ChatSheet?
      var activePopover: ChatPopover?
      var scrollToMessageId: String?
      
      // MARK: - Sheet Types
      enum ChatSheet: Identifiable {
          case sessionHistory
          case exportChat
          case voiceSettings
          case imageAttachment
          
          var id: String {
              switch self {
              case .sessionHistory: return "history"
              case .exportChat: return "export"
              case .voiceSettings: return "voice"
              case .imageAttachment: return "image"
              }
          }
      }
      
      // MARK: - Popover Types
      enum ChatPopover: Identifiable {
          case contextMenu(messageId: String)
          case quickActions
          case emojiPicker
          
          var id: String {
              switch self {
              case .contextMenu(let id): return "context_\(id)"
              case .quickActions: return "actions"
              case .emojiPicker: return "emoji"
              }
          }
      }
      
      // MARK: - Navigation Methods
      func navigateTo(_ destination: ChatDestination) {
          navigationPath.append(destination)
      }
      
      func showSheet(_ sheet: ChatSheet) {
          activeSheet = sheet
      }
      
      func showPopover(_ popover: ChatPopover) {
          activePopover = popover
      }
      
      func scrollTo(messageId: String) {
          scrollToMessageId = messageId
      }
      
      func dismiss() {
          activeSheet = nil
          activePopover = nil
      }
  }
  
  // MARK: - Navigation Destinations
  enum ChatDestination: Hashable {
      case messageDetail(messageId: String)
      case searchResults
      case sessionSettings
  }
  ```

**Agent Task 13.0.2: Create Chat View Model**
- File: `AirFit/Modules/Chat/ViewModels/ChatViewModel.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  import Observation
  import Speech
  
  @MainActor
  @Observable
  final class ChatViewModel {
      // MARK: - Dependencies
      private let modelContext: ModelContext
      private let user: User
      private let coachEngine: CoachEngine
      private let aiService: AIServiceProtocol
      private let voiceManager: VoiceInputManager
      private let suggestionsEngine: ChatSuggestionsEngine
      private let coordinator: ChatCoordinator
      
      // MARK: - Published State
      private(set) var messages: [ChatMessage] = []
      private(set) var currentSession: ChatSession?
      private(set) var isLoading = false
      private(set) var isStreaming = false
      private(set) var error: Error?
      
      // Composer State
      var composerText = ""
      var isRecording = false
      var voiceWaveform: [Float] = []
      var attachments: [ChatAttachment] = []
      
      // Suggestions
      private(set) var quickSuggestions: [QuickSuggestion] = []
      private(set) var contextualActions: [ContextualAction] = []
      
      // Stream State
      private var streamBuffer = ""
      private var streamTask: Task<Void, Never>?
      
      // MARK: - Initialization
      init(
          modelContext: ModelContext,
          user: User,
          coachEngine: CoachEngine,
          aiService: AIServiceProtocol,
          coordinator: ChatCoordinator
      ) {
          self.modelContext = modelContext
          self.user = user
          self.coachEngine = coachEngine
          self.aiService = aiService
          self.coordinator = coordinator
          self.voiceManager = VoiceInputManager()
          self.suggestionsEngine = ChatSuggestionsEngine(user: user)
          
          setupVoiceManager()
      }
      
      // MARK: - Session Management
      func loadOrCreateSession() async {
          do {
              // Try to load active session
              let descriptor = FetchDescriptor<ChatSession>(
                  predicate: #Predicate { $0.isActive && $0.user?.id == user.id }
              )
              
              if let existingSession = try modelContext.fetch(descriptor).first {
                  currentSession = existingSession
                  await loadMessages(for: existingSession)
              } else {
                  // Create new session
                  let newSession = ChatSession(user: user)
                  modelContext.insert(newSession)
                  try modelContext.save()
                  currentSession = newSession
              }
              
              // Load suggestions
              await refreshSuggestions()
              
          } catch {
              self.error = error
              AppLogger.error("Failed to load chat session", error: error, category: .chat)
          }
      }
      
      private func loadMessages(for session: ChatSession) async {
          guard let sessionId = session.id else { return }
          
          do {
              let descriptor = FetchDescriptor<ChatMessage>(
                  predicate: #Predicate { $0.session?.id == sessionId },
                  sortBy: [SortDescriptor(\.timestamp)]
              )
              
              messages = try modelContext.fetch(descriptor)
          } catch {
              AppLogger.error("Failed to load messages", error: error, category: .chat)
          }
      }
      
      // MARK: - Message Sending
      func sendMessage() async {
          guard !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
          guard let session = currentSession else { return }
          
          // Create user message
          let userMessage = ChatMessage(
              session: session,
              content: composerText,
              role: .user,
              attachments: attachments
          )
          
          modelContext.insert(userMessage)
          messages.append(userMessage)
          
          // Clear composer
          let messageText = composerText
          composerText = ""
          attachments = []
          
          // Save immediately
          do {
              try modelContext.save()
          } catch {
              AppLogger.error("Failed to save user message", error: error, category: .chat)
          }
          
          // Generate AI response
          await generateAIResponse(for: messageText, session: session)
      }
      
      private func generateAIResponse(for userInput: String, session: ChatSession) async {
          isStreaming = true
          streamBuffer = ""
          
          // Create assistant message placeholder
          let assistantMessage = ChatMessage(
              session: session,
              content: "",
              role: .assistant
          )
          
          modelContext.insert(assistantMessage)
          messages.append(assistantMessage)
          
          do {
              // Build context
              let context = try await coachEngine.buildContext(
                  input: userInput,
                  user: user,
                  recentMessages: Array(messages.suffix(10))
              )
              
              // Stream response
              streamTask = Task {
                  do {
                      for try await chunk in aiService.streamResponse(context: context) {
                          guard !Task.isCancelled else { break }
                          
                          switch chunk {
                          case .text(let text):
                              streamBuffer += text
                              assistantMessage.content = streamBuffer
                              
                          case .functionCall(let name, let args):
                              // Handle function calls
                              await handleFunctionCall(name: name, arguments: args, message: assistantMessage)
                              
                          case .done:
                              // Finalize message
                              assistantMessage.content = streamBuffer
                              assistantMessage.metadata["tokens"] = streamBuffer.split(separator: " ").count
                              try? modelContext.save()
                              
                              // Refresh suggestions based on response
                              await refreshSuggestions()
                          }
                      }
                  } catch {
                      assistantMessage.content = "I apologize, but I encountered an error. Please try again."
                      assistantMessage.metadata["error"] = error.localizedDescription
                      self.error = error
                  }
                  
                  isStreaming = false
                  streamBuffer = ""
              }
              
          } catch {
              isStreaming = false
              self.error = error
              assistantMessage.content = "Failed to generate response. Please check your settings."
          }
      }
      
      // MARK: - Voice Input
      private func setupVoiceManager() {
          voiceManager.onTranscription = { [weak self] text in
              Task { @MainActor in
                  self?.composerText += text
              }
          }
          
          voiceManager.onWaveformUpdate = { [weak self] levels in
              Task { @MainActor in
                  self?.voiceWaveform = levels
              }
          }
          
          voiceManager.onError = { [weak self] error in
              Task { @MainActor in
                  self?.error = error
                  self?.isRecording = false
              }
          }
      }
      
      func toggleVoiceRecording() async {
          if isRecording {
              // Stop recording and get transcription
              if let transcription = await voiceManager.stopRecording() {
                  // Append transcription to composer text
                  composerText += transcription
                  
                  // Haptic feedback for successful transcription
                  await HapticManager.shared.notification(.success)
              }
              isRecording = false
          } else {
              do {
                  try await voiceManager.startRecording()
                  isRecording = true
                  
                  // Haptic feedback
                  await HapticManager.shared.impact(.medium)
              } catch {
                  self.error = error
                  await HapticManager.shared.notification(.error)
              }
          }
      }
      
      // MARK: - Suggestions
      private func refreshSuggestions() async {
          // Get context-aware suggestions
          let suggestions = await suggestionsEngine.generateSuggestions(
              messages: messages,
              userContext: user
          )
          
          quickSuggestions = suggestions.quick
          contextualActions = suggestions.contextual
      }
      
      func selectSuggestion(_ suggestion: QuickSuggestion) {
          composerText = suggestion.text
          
          // Auto-send if configured
          if suggestion.autoSend {
              Task {
                  await sendMessage()
              }
          }
      }
      
      // MARK: - Message Actions
      func deleteMessage(_ message: ChatMessage) async {
          messages.removeAll { $0.id == message.id }
          modelContext.delete(message)
          
          do {
              try modelContext.save()
          } catch {
              self.error = error
          }
      }
      
      func copyMessage(_ message: ChatMessage) {
          UIPasteboard.general.string = message.content
          
          // Show confirmation
          Task {
              await HapticManager.shared.notification(.success)
          }
      }
      
      func regenerateResponse(for message: ChatMessage) async {
          guard message.role == .assistant,
                let index = messages.firstIndex(where: { $0.id == message.id }),
                index > 0 else { return }
          
          // Get the user message before this one
          let userMessage = messages[index - 1]
          
          // Delete current response
          await deleteMessage(message)
          
          // Generate new response
          if let session = currentSession {
              await generateAIResponse(for: userMessage.content, session: session)
          }
      }
      
      // MARK: - Search
      func searchMessages(query: String) async -> [ChatMessage] {
          do {
              let descriptor = FetchDescriptor<ChatMessage>(
                  predicate: #Predicate { message in
                      message.content.localizedStandardContains(query) &&
                      message.session?.user?.id == user.id
                  },
                  sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
              )
              
              return try modelContext.fetch(descriptor)
          } catch {
              AppLogger.error("Search failed", error: error, category: .chat)
              return []
          }
      }
      
      // MARK: - Export
      func exportChat() async throws -> URL {
          guard let session = currentSession else {
              throw ChatError.noActiveSession
          }
          
          let exporter = ChatExporter()
          return try await exporter.export(
              session: session,
              messages: messages,
              format: .markdown
          )
      }
      
      // MARK: - Function Calls
      private func handleFunctionCall(name: String, arguments: [String: Any], message: ChatMessage) async {
          // Handle coach engine function calls
          switch name {
          case "showWorkout":
              if let workoutId = arguments["id"] as? String {
                  message.metadata["actionType"] = "navigation"
                  message.metadata["actionTarget"] = "workout/\(workoutId)"
              }
              
          case "updateGoal":
              if let goal = arguments["goal"] as? String {
                  // Update user goal
                  user.goals.append(Goal(description: goal, createdAt: Date()))
                  try? modelContext.save()
              }
              
          case "scheduleReminder":
              if let time = arguments["time"] as? String {
                  message.metadata["actionType"] = "reminder"
                  message.metadata["reminderTime"] = time
              }
              
          default:
              AppLogger.warning("Unknown function call: \(name)", category: .chat)
          }
      }
  }
  
  // MARK: - Supporting Types
  enum ChatError: LocalizedError {
      case noActiveSession
      case exportFailed(String)
      case voiceRecognitionUnavailable
      
      var errorDescription: String? {
          switch self {
          case .noActiveSession:
              return "No active chat session"
          case .exportFailed(let reason):
              return "Export failed: \(reason)"
          case .voiceRecognitionUnavailable:
              return "Voice recognition is not available"
          }
      }
  }
  ```

---

**Task 13.1: Chat UI Implementation**

**Agent Task 13.1.1: Create Main Chat View**
- File: `AirFit/Modules/Chat/Views/ChatView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct ChatView: View {
      @StateObject private var viewModel: ChatViewModel
      @StateObject private var coordinator: ChatCoordinator
      @FocusState private var isComposerFocused: Bool
      @State private var scrollProxy: ScrollViewProxy?
      
      init(user: User, modelContext: ModelContext) {
          let coordinator = ChatCoordinator()
          let viewModel = ChatViewModel(
              modelContext: modelContext,
              user: user,
              coachEngine: CoachEngine.shared,
              aiService: AIServiceManager.shared,
              coordinator: coordinator
          )
          
          _viewModel = StateObject(wrappedValue: viewModel)
          _coordinator = StateObject(wrappedValue: coordinator)
      }
      
      var body: some View {
          NavigationStack(path: $coordinator.navigationPath) {
              VStack(spacing: 0) {
                  // Messages
                  messagesScrollView
                  
                  // Suggestions bar
                  if !viewModel.quickSuggestions.isEmpty {
                      suggestionsBar
                  }
                  
                  // Composer
                  MessageComposer(
                      text: $viewModel.composerText,
                      attachments: $viewModel.attachments,
                      isRecording: viewModel.isRecording,
                      waveform: viewModel.voiceWaveform,
                      onSend: {
                          Task { await viewModel.sendMessage() }
                      },
                      onVoiceToggle: {
                          Task { await viewModel.toggleVoiceRecording() }
                      }
                  )
                  .focused($isComposerFocused)
                  .padding(.horizontal)
                  .padding(.vertical, 8)
                  .background(Color.backgroundPrimary)
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
                  LazyVStack(spacing: AppSpacing.md) {
                      ForEach(viewModel.messages) { message in
                          MessageBubbleView(
                              message: message,
                              isStreaming: viewModel.isStreaming && message == viewModel.messages.last,
                              onAction: { action in
                                  handleMessageAction(action, message: message)
                              }
                          )
                          .id(message.id)
                          .transition(.asymmetric(
                              insertion: .push(from: .bottom).combined(with: .opacity),
                              removal: .push(from: .top).combined(with: .opacity)
                          ))
                      }
                      
                      if viewModel.isStreaming {
                          HStack {
                              TypingIndicator()
                              Spacer()
                          }
                          .padding(.leading, AppSpacing.md)
                      }
                  }
                  .padding()
              }
              .scrollDismissesKeyboard(.interactively)
              .onAppear {
                  scrollProxy = proxy
              }
              .onChange(of: coordinator.scrollToMessageId) { _, messageId in
                  if let id = messageId {
                      withAnimation {
                          proxy.scrollTo(id, anchor: .center)
                      }
                  }
              }
          }
      }
      
      // MARK: - Suggestions Bar
      private var suggestionsBar: some View {
          ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: AppSpacing.sm) {
                  ForEach(viewModel.quickSuggestions) { suggestion in
                      SuggestionChip(
                          suggestion: suggestion,
                          onTap: { viewModel.selectSuggestion(suggestion) }
                      )
                  }
              }
              .padding(.horizontal)
              .padding(.vertical, AppSpacing.sm)
          }
          .background(Color.backgroundSecondary)
      }
      
      // MARK: - Toolbar
      @ToolbarContentBuilder
      private var toolbarContent: some ToolbarContent {
          ToolbarItem(placement: .navigationBarTrailing) {
              Menu {
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
              } label: {
                  Image(systemName: "ellipsis.circle")
              }
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
                      ChatAttachment(type: .image, data: image.pngData())
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
              coordinator.navigateTo(.messageDetail(messageId: message.id?.uuidString ?? ""))
          }
      }
      
      private func startNewSession() {
          // End current session and start new
          Task {
              viewModel.currentSession?.isActive = false
              try? viewModel.modelContext.save()
              await viewModel.loadOrCreateSession()
          }
      }
      
      private func scrollToBottom() {
          if let lastMessage = viewModel.messages.last {
              withAnimation {
                  scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
              }
          }
      }
  }
  ```

**Agent Task 13.1.2: Create Message Bubble View**
- File: `AirFit/Modules/Chat/Views/MessageBubbleView.swift`
- Implementation:
  ```swift
  import SwiftUI
  import Charts
  
  struct MessageBubbleView: View {
      let message: ChatMessage
      let isStreaming: Bool
      let onAction: (MessageAction) -> Void
      
      @State private var showActions = false
      
      var body: some View {
          HStack(alignment: .bottom, spacing: AppSpacing.sm) {
              if message.role == .user {
                  Spacer(minLength: 60)
              }
              
              VStack(alignment: message.role == .user ? .trailing : .leading, spacing: AppSpacing.xs) {
                  // Message bubble
                  bubble
                  
                  // Timestamp and status
                  HStack(spacing: AppSpacing.xs) {
                      if message.role == .user && isStreaming {
                          ProgressView()
                              .controlSize(.mini)
                      }
                      
                      Text(message.timestamp.formatted(.relative(presentation: .named)))
                          .font(.caption2)
                          .foregroundStyle(.secondary)
                  }
              }
              
              if message.role == .assistant {
                  Spacer(minLength: 60)
              }
          }
      }
      
      private var bubble: some View {
          VStack(alignment: .leading, spacing: AppSpacing.sm) {
              // Attachments
              if !message.attachments.isEmpty {
                  attachmentsView
              }
              
              // Message content
              if !message.content.isEmpty {
                  MessageContent(
                      text: message.content,
                      isStreaming: isStreaming,
                      role: message.role
                  )
              }
              
              // Rich content (charts, buttons, etc)
              if let metadata = message.metadata,
                 let actionType = metadata["actionType"] as? String {
                  richContentView(for: actionType, metadata: metadata)
              }
          }
          .padding()
          .background(bubbleBackground)
          .clipShape(ChatBubbleShape(role: message.role))
          .contextMenu {
              messageActions
          }
      }
      
      private var bubbleBackground: some View {
          Group {
              if message.role == .user {
                  Color.accentColor.opacity(0.2)
              } else {
                  Color.cardBackground
              }
          }
      }
      
      @ViewBuilder
      private var attachmentsView: some View {
          ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: AppSpacing.sm) {
                  ForEach(message.attachments) { attachment in
                      AttachmentThumbnail(attachment: attachment)
                  }
              }
          }
      }
      
      @ViewBuilder
      private func richContentView(for actionType: String, metadata: [String: Any]) -> some View {
          switch actionType {
          case "navigation":
              if let target = metadata["actionTarget"] as? String {
                  NavigationLinkCard(
                      title: "View Details",
                      destination: target,
                      icon: "arrow.right.circle.fill"
                  )
              }
              
          case "chart":
              if let chartData = metadata["chartData"] as? [String: Any] {
                  MiniChart(data: chartData)
              }
              
          case "reminder":
              if let time = metadata["reminderTime"] as? String {
                  ReminderCard(time: time)
              }
              
          default:
              EmptyView()
          }
      }
      
      @ViewBuilder
      private var messageActions: some View {
          Button(action: { onAction(.copy) }) {
              Label("Copy", systemImage: "doc.on.doc")
          }
          
          if message.role == .assistant {
              Button(action: { onAction(.regenerate) }) {
                  Label("Regenerate", systemImage: "arrow.clockwise")
              }
          }
          
          Button(action: { onAction(.showDetails) }) {
              Label("Details", systemImage: "info.circle")
          }
          
          Divider()
          
          Button(role: .destructive, action: { onAction(.delete) }) {
              Label("Delete", systemImage: "trash")
          }
      }
  }
  
  // MARK: - Supporting Views
  struct ChatBubbleShape: Shape {
      let role: ChatMessage.Role
      
      func path(in rect: CGRect) -> Path {
          let radius: CGFloat = 18
          let tailSize: CGFloat = 8
          
          var path = Path()
          
          if role == .user {
              // User bubble (right side with tail)
              path.move(to: CGPoint(x: radius, y: 0))
              path.addLine(to: CGPoint(x: rect.width - radius - tailSize, y: 0))
              path.addArc(
                  center: CGPoint(x: rect.width - radius - tailSize, y: radius),
                  radius: radius,
                  startAngle: .degrees(-90),
                  endAngle: .degrees(0),
                  clockwise: false
              )
              
              // Tail
              path.addLine(to: CGPoint(x: rect.width - tailSize, y: rect.height - radius))
              path.addQuadCurve(
                  to: CGPoint(x: rect.width, y: rect.height),
                  control: CGPoint(x: rect.width - tailSize, y: rect.height)
              )
              path.addLine(to: CGPoint(x: rect.width - tailSize - radius, y: rect.height))
              
              path.addArc(
                  center: CGPoint(x: rect.width - tailSize - radius, y: rect.height - radius),
                  radius: radius,
                  startAngle: .degrees(90),
                  endAngle: .degrees(180),
                  clockwise: false
              )
              
          } else {
              // Assistant bubble (left side with tail)
              path.move(to: CGPoint(x: radius + tailSize, y: 0))
              path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
              path.addArc(
                  center: CGPoint(x: rect.width - radius, y: radius),
                  radius: radius,
                  startAngle: .degrees(-90),
                  endAngle: .degrees(0),
                  clockwise: false
              )
              
              path.addLine(to: CGPoint(x: rect.width, y: rect.height - radius))
              path.addArc(
                  center: CGPoint(x: rect.width - radius, y: rect.height - radius),
                  radius: radius,
                  startAngle: .degrees(0),
                  endAngle: .degrees(90),
                  clockwise: false
              )
              
              path.addLine(to: CGPoint(x: radius + tailSize, y: rect.height))
              
              // Tail
              path.addArc(
                  center: CGPoint(x: radius + tailSize, y: rect.height - radius),
                  radius: radius,
                  startAngle: .degrees(90),
                  endAngle: .degrees(180),
                  clockwise: false
              )
              
              path.addLine(to: CGPoint(x: tailSize, y: rect.height - radius))
              path.addQuadCurve(
                  to: CGPoint(x: 0, y: rect.height),
                  control: CGPoint(x: tailSize, y: rect.height)
              )
          }
          
          // Complete the path
          let startX = role == .user ? radius : radius + tailSize
          path.addLine(to: CGPoint(x: startX, y: radius))
          path.addArc(
              center: CGPoint(x: startX, y: radius),
              radius: radius,
              startAngle: .degrees(180),
              endAngle: .degrees(270),
              clockwise: false
          )
          
          return path
      }
  }
  
  enum MessageAction {
      case copy
      case delete
      case regenerate
      case showDetails
  }
  ```

---

**Task 13.2: Message Composer**

**Agent Task 13.2.1: Create Message Composer**
- File: `AirFit/Modules/Chat/Views/MessageComposer.swift`
- Implementation:
  ```swift
  import SwiftUI
  import PhotosUI
  
  struct MessageComposer: View {
      @Binding var text: String
      @Binding var attachments: [ChatAttachment]
      let isRecording: Bool
      let waveform: [Float]
      let onSend: () -> Void
      let onVoiceToggle: () -> Void
      
      @State private var showAttachmentPicker = false
      @State private var selectedPhoto: PhotosPickerItem?
      @FocusState private var isTextFieldFocused: Bool
      
      private var canSend: Bool {
          !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
      }
      
      var body: some View {
          VStack(spacing: 0) {
              // Attachments preview
              if !attachments.isEmpty {
                  attachmentsPreview
                      .padding(.bottom, AppSpacing.sm)
              }
              
              // Input bar
              HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                  // Attachment button
                  Menu {
                      Button(action: { showAttachmentPicker = true }) {
                          Label("Photo", systemImage: "photo")
                      }
                      
                      Button(action: { /* Camera */ }) {
                          Label("Camera", systemImage: "camera")
                      }
                      
                      Button(action: { /* Document */ }) {
                          Label("Document", systemImage: "doc")
                      }
                  } label: {
                      Image(systemName: "plus.circle.fill")
                          .font(.title2)
                          .foregroundStyle(.tint)
                  }
                  
                  // Text field or recording view
                  if isRecording {
                      recordingView
                  } else {
                      textInputView
                  }
                  
                  // Voice/Send button
                  Button(action: canSend ? onSend : onVoiceToggle) {
                      Image(systemName: canSend ? "arrow.up.circle.fill" : "mic.circle.fill")
                          .font(.title2)
                          .foregroundStyle(canSend ? .tint : .secondary)
                          .animation(.easeInOut(duration: 0.2), value: canSend)
                  }
                  .disabled(isRecording && !canSend)
              }
              .padding(.horizontal, AppSpacing.md)
              .padding(.vertical, AppSpacing.sm)
              .background(
                  Capsule()
                      .fill(Color.secondaryBackground)
                      .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
              )
          }
          .photosPicker(
              isPresented: $showAttachmentPicker,
              selection: $selectedPhoto,
              matching: .images
          )
          .onChange(of: selectedPhoto) { _, newValue in
              if let item = newValue {
                  Task {
                      if let data = try? await item.loadTransferable(type: Data.self) {
                          attachments.append(
                              ChatAttachment(type: .image, data: data)
                          )
                      }
                  }
              }
          }
      }
      
      private var textInputView: some View {
          TextField("Message your coach...", text: $text, axis: .vertical)
              .textFieldStyle(.plain)
              .lineLimit(1...5)
              .focused($isTextFieldFocused)
              .onSubmit {
                  if canSend {
                      onSend()
                  }
              }
      }
      
      private var recordingView: some View {
          HStack(spacing: AppSpacing.sm) {
              // Cancel button
              Button(action: onVoiceToggle) {
                  Image(systemName: "xmark.circle.fill")
                      .foregroundStyle(.secondary)
              }
              
              // Waveform
              WaveformView(levels: waveform)
                  .frame(height: 30)
              
              // Recording indicator
              RecordingIndicator()
          }
      }
      
      private var attachmentsPreview: some View {
          ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: AppSpacing.sm) {
                  ForEach(attachments) { attachment in
                      AttachmentPreview(attachment: attachment) {
                          attachments.removeAll { $0.id == attachment.id }
                      }
                  }
              }
              .padding(.horizontal)
          }
      }
  }
  
  // MARK: - Supporting Views
  struct WaveformView: View {
      let levels: [Float]
      
      var body: some View {
          GeometryReader { geometry in
              HStack(spacing: 2) {
                  ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                      RoundedRectangle(cornerRadius: 2)
                          .fill(Color.accentColor)
                          .frame(
                              width: 3,
                              height: CGFloat(level) * geometry.size.height
                          )
                          .animation(
                              .easeInOut(duration: 0.1),
                              value: level
                          )
                  }
              }
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
      }
  }
  
  struct RecordingIndicator: View {
      @State private var isAnimating = false
      
      var body: some View {
          Circle()
              .fill(Color.red)
              .frame(width: 12, height: 12)
              .scaleEffect(isAnimating ? 1.2 : 1.0)
              .opacity(isAnimating ? 0.6 : 1.0)
              .animation(
                  .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                  value: isAnimating
              )
              .onAppear { isAnimating = true }
      }
  }
  ```

---

**Task 13.3: Voice Input Manager with Whisper Integration**

**Agent Task 13.3.1: Create Voice Input Manager**
- File: `AirFit/Modules/Chat/Services/VoiceInputManager.swift`
- Implementation:
  ```swift
  import Foundation
  import AVFoundation
  import WhisperKit
  
  @MainActor
  final class VoiceInputManager: NSObject, ObservableObject {
      // MARK: - Properties
      private var whisperKit: WhisperKit?
      private var audioRecorder: AVAudioRecorder?
      private var audioEngine: AVAudioEngine
      private var inputNode: AVAudioInputNode
      
      // Recording state
      private var recordingURL: URL?
      private var recordingStartTime: Date?
      private var isProcessing = false
      
      // Real-time audio analysis
      private var audioBuffer: [Float] = []
      private var waveformTimer: Timer?
      private var waveformBuffer: [Float] = []
      
      // Callbacks
      var onTranscription: ((String) -> Void)?
      var onPartialTranscription: ((String) -> Void)?
      var onWaveformUpdate: (([Float]) -> Void)?
      var onError: ((Error) -> Void)?
      
      // Configuration
      private var modelName: String = "base"
      private let maxRecordingDuration: TimeInterval = 60.0
      
      // MARK: - Initialization
      override init() {
          self.audioEngine = AVAudioEngine()
          self.inputNode = audioEngine.inputNode
          super.init()
          
          Task {
              await setupWhisper()
          }
      }
      
      private func setupWhisper() async {
          do {
              // Determine optimal model based on device
              modelName = selectOptimalModel()
              
              // Initialize WhisperKit with MLX model
              // This will automatically download from mlx-community/whisper-{model}-mlx if needed
              self.whisperKit = try await WhisperKit(
                  WhisperKitConfig(
                      model: modelName,
                      modelRepo: "mlx-community/whisper-\(modelName)-mlx",
                      modelFolder: "whisper-\(modelName)-mlx",
                      computeOptions: WhisperKitConfig.ComputeOptions(
                          melCompute: .cpuAndGPU,
                          audioEncoderCompute: .cpuAndGPU,
                          textDecoderCompute: .cpuAndGPU,
                          prefillCompute: .cpuAndGPU
                      ),
                      verbose: false,
                      logLevel: .error,
                      prewarm: true,  // Prewarm model for faster first inference
                      load: true,     // Load model immediately
                      download: true  // Allow automatic download
                  )
              )
              
              AppLogger.info("WhisperKit initialized with \(modelName) model", category: .voice)
          } catch {
              AppLogger.error("Failed to initialize WhisperKit", error: error, category: .voice)
              
              // Fallback to tiny model if initialization fails
              if modelName != "tiny" {
                  modelName = "tiny"
                  await setupWhisper()
              } else {
                  onError?(VoiceInputError.whisperInitializationFailed)
              }
          }
      }
      
      private func selectOptimalModel() -> String {
          let deviceMemory = ProcessInfo.processInfo.physicalMemory
          
          // Use research report's recommendations
          if deviceMemory >= 8_000_000_000 { // 8GB+ RAM (iPhone 15 Pro, iPad Pro)
              return "large-v3"
          } else if deviceMemory >= 6_000_000_000 { // 6GB+ RAM (iPhone 14 Pro)
              return "medium"
          } else if deviceMemory >= 4_000_000_000 { // 4GB+ RAM
              return "base"
          } else {
              return "tiny" // For older devices
          }
      }
      
      // MARK: - Authorization
      func requestMicrophoneAccess() async -> Bool {
          await withCheckedContinuation { continuation in
              AVAudioSession.sharedInstance().requestRecordPermission { granted in
                  continuation.resume(returning: granted)
              }
          }
      }
      
      // MARK: - Recording Control
      func startRecording() async throws {
          guard await requestMicrophoneAccess() else {
              throw VoiceInputError.notAuthorized
          }
          
          guard whisperKit != nil else {
              throw VoiceInputError.whisperNotReady
          }
          
          // Configure audio session for recording
          let session = AVAudioSession.sharedInstance()
          try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
          try session.setActive(true)
          
          // Create recording URL
          recordingURL = FileManager.default.temporaryDirectory
              .appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
          
          // Configure audio settings for Whisper compatibility
          let settings: [String: Any] = [
              AVFormatIDKey: Int(kAudioFormatLinearPCM),
              AVSampleRateKey: 16000.0, // Whisper expects 16kHz
              AVNumberOfChannelsKey: 1, // Mono
              AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
              AVLinearPCMBitDepthKey: 16,
              AVLinearPCMIsFloatKey: false,
              AVLinearPCMIsBigEndianKey: false
          ]
          
          // Initialize recorder
          audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
          audioRecorder?.delegate = self
          audioRecorder?.isMeteringEnabled = true
          
          // Start recording
          recordingStartTime = Date()
          audioRecorder?.record()
          
          // Start real-time audio analysis
          startAudioAnalysis()
          
          // Start waveform updates
          startWaveformTimer()
      }
      
      func stopRecording() async -> String? {
          guard let recorder = audioRecorder, recorder.isRecording else { return nil }
          
          // Stop recording
          recorder.stop()
          audioRecorder = nil
          
          // Stop audio analysis
          stopAudioAnalysis()
          stopWaveformTimer()
          
          // Process the recorded audio with Whisper
          guard let url = recordingURL else { return nil }
          
          isProcessing = true
          defer { isProcessing = false }
          
          do {
              let transcription = try await transcribeAudio(at: url)
              
              // Clean up recording file
              try? FileManager.default.removeItem(at: url)
              recordingURL = nil
              
              return transcription
          } catch {
              onError?(error)
              return nil
          }
      }
      
      // MARK: - Whisper Transcription
      private func transcribeAudio(at url: URL) async throws -> String {
          guard let whisper = whisperKit else {
              throw VoiceInputError.whisperNotReady
          }
          
          // Transcribe with WhisperKit
          // The method signature follows WhisperKit's actual API
          let transcriptionResult = try await whisper.transcribe(
              audioPath: url.path,
              decodeOptions: DecodingOptions(
                  verbose: false,
                  task: .transcribe,
                  language: "en", // Force English for fitness context
                  temperature: 0.0, // More deterministic output
                  temperatureIncrementOnFallback: 0.2,
                  temperatureFallbackCount: 5,
                  sampleLength: 224, // Optimal for MLX implementation
                  topK: 5,
                  usePrefillPrompt: true,
                  usePrefillCache: true,
                  skipSpecialTokens: true,
                  withoutTimestamps: true,
                  wordTimestamps: false,
                  clipTimestamps: "0",
                  suppressBlank: true,
                  supressTokens: nil,
                  compressionRatioThreshold: 2.4,
                  logprobThreshold: -1.0,
                  noSpeechThreshold: 0.6
              )
          )
          
          // Extract text from result
          guard let segments = transcriptionResult else {
              throw VoiceInputError.transcriptionFailed
          }
          
          // Combine all segments into final text
          let fullText = segments.map { $0.text }.joined(separator: " ")
          
          // Post-process transcription for fitness context
          let processedText = postProcessTranscription(fullText)
          
          return processedText
      }
      
      // MARK: - Streaming Transcription (Experimental)
      func startStreamingTranscription() async throws {
          guard whisperKit != nil else {
              throw VoiceInputError.whisperNotReady
          }
          
          // Configure audio session
          let session = AVAudioSession.sharedInstance()
          try session.setCategory(.playAndRecord, mode: .default)
          try session.setActive(true)
          
          // Configure audio format for streaming
          let format = AVAudioFormat(
              commonFormat: .pcmFormatFloat32,
              sampleRate: 16000.0,
              channels: 1,
              interleaved: false
          )!
          
          // Install tap for streaming audio
          let bufferSize: AVAudioFrameCount = 8192
          inputNode.installTap(
              onBus: 0,
              bufferSize: bufferSize,
              format: format
          ) { [weak self] buffer, _ in
              self?.processStreamingBuffer(buffer)
          }
          
          // Start audio engine
          audioEngine.prepare()
          try audioEngine.start()
          
          startWaveformTimer()
      }
      
      private func processStreamingBuffer(_ buffer: AVAudioPCMBuffer) {
          // Add to audio buffer for chunked processing
          guard let channelData = buffer.floatChannelData else { return }
          
          let channelDataValue = channelData.pointee
          let channelDataArray = Array(UnsafeBufferPointer(
              start: channelDataValue,
              count: Int(buffer.frameLength)
          ))
          
          audioBuffer.append(contentsOf: channelDataArray)
          
          // Process chunks of ~1 second
          if audioBuffer.count >= 16000 {
              let chunk = Array(audioBuffer.prefix(16000))
              audioBuffer.removeFirst(16000)
              
              Task {
                  await processAudioChunk(chunk)
              }
          }
          
          // Update waveform
          analyzeAudioBuffer(buffer)
      }
      
      private func processAudioChunk(_ audioData: [Float]) async {
          guard let whisper = whisperKit else { return }
          
          do {
              // Convert to format expected by Whisper
              let result = try await whisper.transcribe(
                  audioArray: audioData,
                  decodeOptions: DecodingOptions(
                      language: "en",
                      temperature: 0.0,
                      withoutTimestamps: true
                  )
              )
              
              if !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  let processed = postProcessTranscription(result.text)
                  onPartialTranscription?(processed)
              }
          } catch {
              // Ignore chunk errors in streaming mode
              AppLogger.debug("Streaming chunk error: \(error)", category: .voice)
          }
      }
      
      func stopStreamingTranscription() async {
          audioEngine.stop()
          inputNode.removeTap(onBus: 0)
          stopWaveformTimer()
          audioBuffer.removeAll()
          
          try? AVAudioSession.sharedInstance().setActive(false)
      }
      
      // MARK: - Audio Analysis
      private func startAudioAnalysis() {
          // Timer for updating audio levels
          Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
              self?.updateAudioLevels()
          }
      }
      
      private func stopAudioAnalysis() {
          // Clean up analysis resources
      }
      
      private func updateAudioLevels() {
          guard let recorder = audioRecorder else { return }
          
          recorder.updateMeters()
          let level = recorder.averagePower(forChannel: 0)
          let normalizedLevel = pow(10, level / 20) // Convert dB to linear
          
          Task { @MainActor in
              waveformBuffer.append(normalizedLevel)
              if waveformBuffer.count > 50 {
                  waveformBuffer.removeFirst()
              }
          }
      }
      
      private func analyzeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
          guard let channelData = buffer.floatChannelData else { return }
          
          let channelDataValue = channelData.pointee
          let channelDataArray = stride(
              from: 0,
              to: Int(buffer.frameLength),
              by: buffer.stride
          ).map { channelDataValue[$0] }
          
          // Calculate RMS for waveform
          let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
          let normalizedLevel = min(rms * 10, 1.0)
          
          Task { @MainActor in
              waveformBuffer.append(normalizedLevel)
              if waveformBuffer.count > 50 {
                  waveformBuffer.removeFirst()
              }
          }
      }
      
      // MARK: - Waveform Updates
      private func startWaveformTimer() {
          waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
              Task { @MainActor in
                  guard let self = self else { return }
                  self.onWaveformUpdate?(self.waveformBuffer)
              }
          }
      }
      
      private func stopWaveformTimer() {
          waveformTimer?.invalidate()
          waveformTimer = nil
          waveformBuffer.removeAll()
          onWaveformUpdate?([])
      }
      
      // MARK: - Post-Processing
      private func postProcessTranscription(_ text: String) -> String {
          var processed = text.trimmingCharacters(in: .whitespacesAndNewlines)
          
          // Fitness-specific corrections
          let corrections: [String: String] = [
              "sets": "sets",
              "reps": "reps",
              "cardio": "cardio",
              "hiit": "HIIT",
              "amrap": "AMRAP",
              "emom": "EMOM",
              "pr": "PR",
              "one rm": "1RM",
              "tabata": "Tabata"
          ]
          
          for (pattern, replacement) in corrections {
              processed = processed.replacingOccurrences(
                  of: pattern,
                  with: replacement,
                  options: [.caseInsensitive]
              )
          }
          
          // Ensure proper sentence capitalization
          if !processed.isEmpty {
              processed = processed.prefix(1).uppercased() + processed.dropFirst()
          }
          
          return processed
      }
      
      // MARK: - Cleanup
      deinit {
          audioRecorder?.stop()
          audioEngine.stop()
          waveformTimer?.invalidate()
      }
  }
  
  // MARK: - Audio Recorder Delegate
  extension VoiceInputManager: AVAudioRecorderDelegate {
      nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
          Task { @MainActor in
              if !flag {
                  onError?(VoiceInputError.recordingFailed)
              }
          }
      }
      
      nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
          Task { @MainActor in
              if let error = error {
                  onError?(error)
              }
          }
      }
  }
  
  // MARK: - Error Types
  enum VoiceInputError: LocalizedError {
      case notAuthorized
      case whisperInitializationFailed
      case whisperNotReady
      case recordingFailed
      case transcriptionFailed
      case audioEngineError
      
      var errorDescription: String? {
          switch self {
          case .notAuthorized:
              return "Microphone access not authorized"
          case .whisperInitializationFailed:
              return "Failed to initialize Whisper model"
          case .whisperNotReady:
              return "Whisper is not ready for transcription"
          case .recordingFailed:
              return "Audio recording failed"
          case .transcriptionFailed:
              return "Failed to transcribe audio"
          case .audioEngineError:
              return "Audio engine error occurred"
          }
      }
  }
  
  // MARK: - Whisper Model Size
  enum WhisperModelSize: String {
      case tiny = "tiny"
      case base = "base"
      case small = "small"
      case medium = "medium"
      case large = "large"
      
      var downloadSize: String {
          switch self {
          case .tiny: return "39 MB"
          case .base: return "74 MB"
          case .small: return "244 MB"
          case .medium: return "769 MB"
          case .large: return "1550 MB"
          }
      }
  }
  ```

**Agent Task 13.3.2: Create Whisper Model Manager**
- File: `AirFit/Core/Services/WhisperModelManager.swift`
- Implementation:
  ```swift
  import Foundation
  import WhisperKit
  
  @MainActor
  @Observable
  final class WhisperModelManager {
      // MARK: - Singleton
      static let shared = WhisperModelManager()
      
      // MARK: - Model Configuration
      static let modelConfigurations: [WhisperModel] = [
          WhisperModel(
              id: "tiny",
              displayName: "Tiny (39 MB)",
              size: "39 MB",
              sizeBytes: 39_000_000,
              accuracy: "Good",
              speed: "Fastest",
              languages: "English + 98 more",
              requiredMemory: 200_000_000,
              huggingFaceRepo: "mlx-community/whisper-tiny-mlx"
          ),
          WhisperModel(
              id: "base",
              displayName: "Base (74 MB)",
              size: "74 MB",
              sizeBytes: 74_000_000,
              accuracy: "Better",
              speed: "Very Fast",
              languages: "English + 98 more",
              requiredMemory: 500_000_000,
              huggingFaceRepo: "mlx-community/whisper-base-mlx"
          ),
          WhisperModel(
              id: "small",
              displayName: "Small",
              size: "244 MB",
              sizeBytes: 244_000_000,
              accuracy: "Good",
              speed: "Moderate",
              languages: "Multi",
              requiredMemory: 3_000_000_000,
              huggingFaceRepo: "mlx-community/whisper-small-mlx"
          ),
          WhisperModel(
              id: "medium",
              displayName: "Medium",
              size: "769 MB",
              sizeBytes: 769_000_000,
              accuracy: "Very Good",
              speed: "Slower",
              languages: "Multi",
              requiredMemory: 4_000_000_000,
              huggingFaceRepo: "mlx-community/whisper-medium-mlx"
          ),
          WhisperModel(
              id: "large-v3",
              displayName: "Large v3",
              size: "1.55 GB",
              sizeBytes: 1_550_000_000,
              accuracy: "Best",
              speed: "Slowest",
              languages: "Multi",
              requiredMemory: 6_000_000_000,
              huggingFaceRepo: "mlx-community/whisper-large-v3-mlx"
          ),
          WhisperModel(
              id: "large-v3-turbo",
              displayName: "Large v3 Turbo",
              size: "1.55 GB",
              sizeBytes: 1_550_000_000,
              accuracy: "Excellent",
              speed: "Fast",
              languages: "Multi",
              requiredMemory: 6_000_000_000,
              huggingFaceRepo: "mlx-community/whisper-large-v3-turbo"
          )
      ]
      
      // MARK: - Initialization
      private init() {  // Changed to private for singleton
          // Setup model storage directory
          let appSupport = FileManager.default.urls(
              for: .applicationSupportDirectory,
              in: .userDomainMask
          ).first!
          self.modelStorageURL = appSupport.appendingPathComponent("WhisperModels")
          
          // Create directory if needed
          try? FileManager.default.createDirectory(
              at: modelStorageURL,
              withIntermediateDirectories: true
          )
          
          // Load model information
          loadModelInfo()
      }
      
      // MARK: - Model Management
      private func loadModelInfo() {
          // Get available models based on device capabilities
          let deviceMemory = ProcessInfo.processInfo.physicalMemory
          availableModels = Self.modelConfigurations.filter { model in
              model.requiredMemory <= deviceMemory
          }
          
          // Check which models are downloaded
          updateDownloadedModels()
          
          // Set default active model
          if downloadedModels.contains("base") {
              activeModel = "base"
          } else if let firstDownloaded = downloadedModels.first {
              activeModel = firstDownloaded
          }
      }
      
      private func updateDownloadedModels() {
          downloadedModels.removeAll()
          
          for model in availableModels {
              let modelPath = modelStorageURL.appendingPathComponent(model.id)
              if FileManager.default.fileExists(atPath: modelPath.path) {
                  // Verify model files exist
                  let configPath = modelPath.appendingPathComponent("config.json")
                  let weightsPath = modelPath.appendingPathComponent("weights.npz")
                  
                  if FileManager.default.fileExists(atPath: configPath.path) &&
                     FileManager.default.fileExists(atPath: weightsPath.path) {
                      downloadedModels.insert(model.id)
                  }
              }
          }
      }
      
      // MARK: - Download Management
      func downloadModel(_ modelId: String) async throws {
          guard let model = availableModels.first(where: { $0.id == modelId }) else {
              throw ModelError.modelNotFound
          }
          
          // Check available storage
          guard hasEnoughStorage(for: model) else {
              throw ModelError.insufficientStorage
          }
          
          isDownloading[modelId] = true
          downloadProgress[modelId] = 0.0
          
          do {
              // Use WhisperKit's built-in download functionality
              let modelPath = modelStorageURL.appendingPathComponent(modelId)
              
              // Download via WhisperKit (it handles HuggingFace downloads)
              _ = try await WhisperKit(
                  WhisperKitConfig(
                      model: modelId,
                      modelRepo: model.huggingFaceRepo,
                      modelFolder: modelId,
                      download: true,
                      verbose: false,
                      logLevel: .error
                  )
              )
              
              // Move downloaded model to our storage location
              if let whisperKitCache = locateWhisperKitCache(for: modelId) {
                  try FileManager.default.moveItem(
                      at: whisperKitCache,
                      to: modelPath
                  )
              }
              
              downloadedModels.insert(modelId)
              isDownloading[modelId] = false
              downloadProgress[modelId] = 1.0
              
          } catch {
              isDownloading[modelId] = false
              downloadProgress[modelId] = 0.0
              throw error
          }
      }
      
      func deleteModel(_ modelId: String) throws {
          let modelPath = modelStorageURL.appendingPathComponent(modelId)
          
          if FileManager.default.fileExists(atPath: modelPath.path) {
              try FileManager.default.removeItem(at: modelPath)
              downloadedModels.remove(modelId)
              
              // If we deleted the active model, switch to another
              if activeModel == modelId {
                  activeModel = downloadedModels.first ?? "base"
              }
          }
      }
      
      // MARK: - Storage Management
      private func hasEnoughStorage(for model: WhisperModel) -> Bool {
          do {
              let attributes = try FileManager.default.attributesOfFileSystem(
                  forPath: NSHomeDirectory()
              )
              
              if let freeSpace = attributes[.systemFreeSize] as? Int64 {
                  // Require 2x the model size for safety
                  return freeSpace > Int64(model.sizeBytes * 2)
              }
          } catch {
              AppLogger.error("Failed to check storage", error: error, category: .voice)
          }
          
          return false
      }
      
      private func locateWhisperKitCache(for modelId: String) -> URL? {
          // WhisperKit typically downloads to Library/Caches/WhisperKit/
          let caches = FileManager.default.urls(
              for: .cachesDirectory,
              in: .userDomainMask
          ).first
          
          return caches?.appendingPathComponent("WhisperKit/\(modelId)")
      }
      
      // MARK: - Model Selection
      func selectOptimalModel() -> String {
          let deviceMemory = ProcessInfo.processInfo.physicalMemory
          
          // First, try to use the largest downloaded model that fits
          let sortedModels = downloadedModels.sorted { modelA, modelB in
              let configA = Self.modelConfigurations.first { $0.id == modelA }
              let configB = Self.modelConfigurations.first { $0.id == modelB }
              return (configA?.sizeBytes ?? 0) > (configB?.sizeBytes ?? 0)
          }
          
          for modelId in sortedModels {
              if let config = Self.modelConfigurations.first(where: { $0.id == modelId }),
                 config.requiredMemory <= deviceMemory {
                  return modelId
              }
          }
          
          // If no downloaded models fit, return the default recommendation
          if deviceMemory >= 8_000_000_000 {
              return "large-v3"
          } else if deviceMemory >= 6_000_000_000 {
              return "medium"
          } else if deviceMemory >= 4_000_000_000 {
              return "base"
          } else {
              return "tiny"
          }
      }
      
      // MARK: - Model Information
      func modelPath(for modelId: String) -> URL? {
          let path = modelStorageURL.appendingPathComponent(modelId)
          return FileManager.default.fileExists(atPath: path.path) ? path : nil
      }
  }
  
  // MARK: - Supporting Types
  struct WhisperModel: Identifiable {
      let id: String
      let displayName: String
      let size: String
      let sizeBytes: Int
      let accuracy: String
      let speed: String
      let languages: String
      let requiredMemory: Int
      let huggingFaceRepo: String
  }
  
  enum ModelError: LocalizedError {
      case modelNotFound
      case insufficientStorage
      case downloadFailed(String)
      
      var errorDescription: String? {
          switch self {
          case .modelNotFound:
              return "Model not found"
          case .insufficientStorage:
              return "Not enough storage space for model"
          case .downloadFailed(let reason):
              return "Download failed: \(reason)"
          }
      }
  }
  ```

---

**Task 13.4: Chat History & Export**

**Agent Task 13.4.1: Create Chat History Manager**
- File: `AirFit/Modules/Chat/Services/ChatHistoryManager.swift`
- Implementation:
  ```swift
  import Foundation
  import SwiftData
  
  @MainActor
  final class ChatHistoryManager {
      private let modelContext: ModelContext
      
      init(modelContext: ModelContext) {
          self.modelContext = modelContext
      }
      
      // MARK: - Session Management
      func loadSessions(for user: User, limit: Int = 50) async throws -> [ChatSession] {
          let descriptor = FetchDescriptor<ChatSession>(
              predicate: #Predicate { $0.user?.id == user.id },
              sortBy: [SortDescriptor(\.lastMessageDate, order: .reverse)]
          )
          descriptor.fetchLimit = limit
          
          return try modelContext.fetch(descriptor)
      }
      
      func createSession(for user: User, title: String? = nil) throws -> ChatSession {
          let session = ChatSession(user: user)
          session.title = title ?? generateSessionTitle()
          modelContext.insert(session)
          try modelContext.save()
          return session
      }
      
      func deleteSession(_ session: ChatSession) throws {
          // Delete all messages first
          if let sessionId = session.id {
              let messageDescriptor = FetchDescriptor<ChatMessage>(
                  predicate: #Predicate { $0.session?.id == sessionId }
              )
              let messages = try modelContext.fetch(messageDescriptor)
              messages.forEach { modelContext.delete($0) }
          }
          
          // Delete session
          modelContext.delete(session)
          try modelContext.save()
      }
      
      func archiveSession(_ session: ChatSession) throws {
          session.isActive = false
          session.archivedAt = Date()
          try modelContext.save()
      }
      
      // MARK: - Message Management
      func loadMessages(
          for session: ChatSession,
          offset: Int = 0,
          limit: Int = 50
      ) async throws -> [ChatMessage] {
          guard let sessionId = session.id else { return [] }
          
          let descriptor = FetchDescriptor<ChatMessage>(
              predicate: #Predicate { $0.session?.id == sessionId },
              sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
          )
          descriptor.fetchLimit = limit
          descriptor.fetchOffset = offset
          
          let messages = try modelContext.fetch(descriptor)
          return messages.reversed() // Return in chronological order
      }
      
      func searchMessages(
          query: String,
          in user: User,
          limit: Int = 50
      ) async throws -> [ChatMessage] {
          let descriptor = FetchDescriptor<ChatMessage>(
              predicate: #Predicate { message in
                  message.content.localizedStandardContains(query) &&
                  message.session?.user?.id == user.id
              },
              sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
          )
          descriptor.fetchLimit = limit
          
          return try modelContext.fetch(descriptor)
      }
      
      // MARK: - Analytics
      func getSessionStats(for user: User) async throws -> ChatStats {
          let sessions = try await loadSessions(for: user, limit: 1000)
          
          let totalMessages = sessions.reduce(0) { $0 + $1.messageCount }
          let avgMessagesPerSession = sessions.isEmpty ? 0 : totalMessages / sessions.count
          
          let activeSession = sessions.first { $0.isActive }
          let lastMessageDate = sessions.first?.lastMessageDate
          
          return ChatStats(
              totalSessions: sessions.count,
              totalMessages: totalMessages,
              avgMessagesPerSession: avgMessagesPerSession,
              activeSessionId: activeSession?.id,
              lastMessageDate: lastMessageDate
          )
      }
      
      // MARK: - Helpers
      private func generateSessionTitle() -> String {
          let formatter = DateFormatter()
          formatter.dateFormat = "MMM d, h:mm a"
          return "Chat - \(formatter.string(from: Date()))"
      }
  }
  
  // MARK: - Supporting Types
  struct ChatStats {
      let totalSessions: Int
      let totalMessages: Int
      let avgMessagesPerSession: Int
      let activeSessionId: UUID?
      let lastMessageDate: Date?
  }
  ```

**Agent Task 13.4.2: Create Chat Exporter**
- File: `AirFit/Modules/Chat/Services/ChatExporter.swift`
- Implementation:
  ```swift
  import Foundation
  import UniformTypeIdentifiers
  
  struct ChatExporter {
      enum ExportFormat {
          case json
          case markdown
          case txt
          
          var fileExtension: String {
              switch self {
              case .json: return "json"
              case .markdown: return "md"
              case .txt: return "txt"
              }
          }
          
          var utType: UTType {
              switch self {
              case .json: return .json
              case .markdown: return .text
              case .txt: return .plainText
              }
          }
      }
      
      func export(
          session: ChatSession,
          messages: [ChatMessage],
          format: ExportFormat = .markdown
      ) async throws -> URL {
          let content: String
          
          switch format {
          case .json:
              content = try exportAsJSON(session: session, messages: messages)
          case .markdown:
              content = exportAsMarkdown(session: session, messages: messages)
          case .txt:
              content = exportAsText(session: session, messages: messages)
          }
          
          // Create temporary file
          let fileName = "AirFit_Chat_\(session.title ?? "Export")_\(Date().ISO8601Format()).\(format.fileExtension)"
          let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
          
          try content.write(to: tempURL, atomically: true, encoding: .utf8)
          
          return tempURL
      }
      
      private func exportAsJSON(session: ChatSession, messages: [ChatMessage]) throws -> String {
          let exportData = ChatExportData(
              session: SessionExportData(
                  id: session.id?.uuidString ?? "",
                  title: session.title ?? "Untitled",
                  createdAt: session.createdAt.ISO8601Format(),
                  messageCount: session.messageCount
              ),
              messages: messages.map { message in
                  MessageExportData(
                      id: message.id?.uuidString ?? "",
                      content: message.content,
                      role: message.role.rawValue,
                      timestamp: message.timestamp.ISO8601Format(),
                      attachments: message.attachments.map { attachment in
                          AttachmentExportData(
                              type: attachment.type.rawValue,
                              mimeType: attachment.mimeType ?? "unknown"
                          )
                      }
                  )
              }
          )
          
          let encoder = JSONEncoder()
          encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
          let data = try encoder.encode(exportData)
          
          return String(data: data, encoding: .utf8) ?? ""
      }
      
      private func exportAsMarkdown(session: ChatSession, messages: [ChatMessage]) -> String {
          var markdown = """
          # AirFit Chat Export
          
          **Session:** \(session.title ?? "Untitled")
          **Date:** \(session.createdAt.formatted())
          **Messages:** \(messages.count)
          
          ---
          
          """
          
          let formatter = DateFormatter()
          formatter.dateStyle = .none
          formatter.timeStyle = .short
          
          for message in messages {
              let role = message.role == .user ? "You" : "AI Coach"
              let time = formatter.string(from: message.timestamp)
              
              markdown += """
              
              **\(role)** _(\(time))_
              \(message.content)
              
              """
              
              if !message.attachments.isEmpty {
                  markdown += "_[Attachments: \(message.attachments.count)]_\n"
              }
          }
          
          return markdown
      }
      
      private func exportAsText(session: ChatSession, messages: [ChatMessage]) -> String {
          var text = """
          AirFit Chat Export
          Session: \(session.title ?? "Untitled")
          Date: \(session.createdAt.formatted())
          Messages: \(messages.count)
          
          =====================================
          
          """
          
          let formatter = DateFormatter()
          formatter.dateStyle = .none
          formatter.timeStyle = .short
          
          for message in messages {
              let role = message.role == .user ? "You" : "AI Coach"
              let time = formatter.string(from: message.timestamp)
              
              text += """
              
              [\(time)] \(role):
              \(message.content)
              
              """
          }
          
          return text
      }
  }
  
  // MARK: - Export Data Structures
  struct ChatExportData: Codable {
      let session: SessionExportData
      let messages: [MessageExportData]
  }
  
  struct SessionExportData: Codable {
      let id: String
      let title: String
      let createdAt: String
      let messageCount: Int
  }
  
  struct MessageExportData: Codable {
      let id: String
      let content: String
      let role: String
      let timestamp: String
      let attachments: [AttachmentExportData]
  }
  
  struct AttachmentExportData: Codable {
      let type: String
      let mimeType: String
  }
  ```

**Agent Task 13.4.3: Create Voice Settings View**
- File: `AirFit/Modules/Chat/Views/VoiceSettingsView.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct VoiceSettingsView: View {
      @StateObject private var modelManager = WhisperModelManager()
      @Environment(\.dismiss) private var dismiss
      @State private var showDeleteConfirmation: String?
      @State private var downloadError: Error?
      
      var body: some View {
          NavigationStack {
              List {
                  // Current Model Section
                  Section {
                      HStack {
                          Label("Active Model", systemImage: "waveform")
                          Spacer()
                          Text(modelManager.activeModel)
                              .foregroundStyle(.secondary)
                      }
                      
                      if let activeConfig = modelManager.availableModels.first(where: { $0.id == modelManager.activeModel }) {
                          VStack(alignment: .leading, spacing: 4) {
                              Text("Accuracy: \(activeConfig.accuracy)")
                              Text("Speed: \(activeConfig.speed)")
                              Text("Size: \(activeConfig.size)")
                          }
                          .font(.caption)
                          .foregroundStyle(.secondary)
                      }
                  } header: {
                      Text("Current Voice Model")
                  } footer: {
                      Text("The active model is used for voice transcription. Larger models provide better accuracy but use more storage and memory.")
                  }
                  
                  // Available Models Section
                  Section {
                      ForEach(modelManager.availableModels) { model in
                          ModelRow(
                              model: model,
                              isDownloaded: modelManager.downloadedModels.contains(model.id),
                              isActive: modelManager.activeModel == model.id,
                              isDownloading: modelManager.isDownloading[model.id] ?? false,
                              downloadProgress: modelManager.downloadProgress[model.id] ?? 0,
                              onDownload: {
                                  Task {
                                      do {
                                          try await modelManager.downloadModel(model.id)
                                      } catch {
                                          downloadError = error
                                      }
                                  }
                              },
                              onDelete: {
                                  showDeleteConfirmation = model.id
                              },
                              onActivate: {
                                  modelManager.activeModel = model.id
                              }
                          )
                      }
                  } header: {
                      Text("Available Models")
                  } footer: {
                      Text("Download additional models for better accuracy or different languages. Models are stored locally and work offline.")
                  }
                  
                  // Storage Info Section
                  Section {
                      StorageInfoView(modelManager: modelManager)
                  } header: {
                      Text("Storage")
                  }
                  
                  // Advanced Settings Section
                  Section {
                      Toggle("Auto-Select Best Model", isOn: .constant(true))
                          .disabled(true)
                      
                      Toggle("Download Over Cellular", isOn: .constant(false))
                      
                      Button("Clear Model Cache", role: .destructive) {
                          // Clear unused models
                      }
                  } header: {
                      Text("Advanced")
                  }
              }
              .navigationTitle("Voice Settings")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .confirmationAction) {
                      Button("Done") {
                          dismiss()
                      }
                  }
              }
              .alert("Delete Model?", isPresented: .init(
                  get: { showDeleteConfirmation != nil },
                  set: { if !$0 { showDeleteConfirmation = nil } }
              )) {
                  Button("Cancel", role: .cancel) {
                      showDeleteConfirmation = nil
                  }
                  Button("Delete", role: .destructive) {
                      if let modelId = showDeleteConfirmation {
                          try? modelManager.deleteModel(modelId)
                          showDeleteConfirmation = nil
                      }
                  }
              } message: {
                  Text("This will remove the model from your device. You can download it again later.")
              }
              .alert("Download Error", isPresented: .init(
                  get: { downloadError != nil },
                  set: { if !$0 { downloadError = nil } }
              )) {
                  Button("OK") {
                      downloadError = nil
                  }
              } message: {
                  if let error = downloadError {
                      Text(error.localizedDescription)
                  }
              }
          }
      }
  }
  
  // MARK: - Model Row
  struct ModelRow: View {
      let model: WhisperModel
      let isDownloaded: Bool
      let isActive: Bool
      let isDownloading: Bool
      let downloadProgress: Double
      let onDownload: () -> Void
      let onDelete: () -> Void
      let onActivate: () -> Void
      
      var body: some View {
          VStack(alignment: .leading, spacing: 8) {
              // Model Info
              HStack {
                  VStack(alignment: .leading, spacing: 2) {
                      Text(model.displayName)
                          .font(.headline)
                      
                      HStack(spacing: 12) {
                          Label(model.accuracy, systemImage: "chart.line.uptrend.xyaxis")
                          Label(model.speed, systemImage: "speedometer")
                          Label(model.size, systemImage: "internaldrive")
                      }
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                  
                  Spacer()
                  
                  // Action Button
                  if isDownloading {
                      ProgressView(value: downloadProgress)
                          .progressViewStyle(CircularProgressViewStyle())
                          .frame(width: 30, height: 30)
                  } else if isDownloaded {
                      if isActive {
                          Image(systemName: "checkmark.circle.fill")
                              .foregroundStyle(.green)
                              .font(.title2)
                      } else {
                          Menu {
                              Button("Use This Model") {
                                  onActivate()
                              }
                              
                              Button("Delete", role: .destructive) {
                                  onDelete()
                              }
                          } label: {
                              Image(systemName: "ellipsis.circle")
                                  .font(.title2)
                          }
                      }
                  } else {
                      Button(action: onDownload) {
                          Image(systemName: "arrow.down.circle")
                              .font(.title2)
                      }
                  }
              }
              
              // Download Progress
              if isDownloading {
                  VStack(alignment: .leading, spacing: 4) {
                      ProgressView(value: downloadProgress)
                      
                      HStack {
                          Text("Downloading...")
                          Spacer()
                          Text("\(Int(downloadProgress * 100))%")
                      }
                      .font(.caption2)
                      .foregroundStyle(.secondary)
                  }
              }
          }
          .padding(.vertical, 4)
      }
  }
  
  // MARK: - Storage Info
  struct StorageInfoView: View {
      @ObservedObject var modelManager: WhisperModelManager
      
      private var totalModelSize: Int {
          modelManager.downloadedModels.compactMap { modelId in
              modelManager.availableModels.first { $0.id == modelId }?.sizeBytes
          }.reduce(0, +)
      }
      
      var body: some View {
          VStack(alignment: .leading, spacing: 8) {
              HStack {
                  Text("Models Downloaded")
                  Spacer()
                  Text("\(modelManager.downloadedModels.count)")
                      .foregroundStyle(.secondary)
              }
              
              HStack {
                  Text("Total Size")
                  Spacer()
                  Text(formatBytes(totalModelSize))
                      .foregroundStyle(.secondary)
              }
              
              if let deviceStorage = getDeviceStorage() {
                  HStack {
                      Text("Available Storage")
                      Spacer()
                      Text(formatBytes(deviceStorage.available))
                          .foregroundStyle(.secondary)
                  }
              }
          }
          .font(.system(.body, design: .rounded))
      }
      
      private func formatBytes(_ bytes: Int) -> String {
          let formatter = ByteCountFormatter()
          formatter.countStyle = .file
          return formatter.string(fromByteCount: Int64(bytes))
      }
      
      private func getDeviceStorage() -> (available: Int, total: Int)? {
          do {
              let attributes = try FileManager.default.attributesOfFileSystem(
                  forPath: NSHomeDirectory()
              )
              
              if let free = attributes[.systemFreeSize] as? Int64,
                 let total = attributes[.systemSize] as? Int64 {
                  return (available: Int(free), total: Int(total))
              }
          } catch {
              return nil
          }
      }
  }
  ```

---

**Task 13.5: Testing**

**Agent Task 13.5.1: Create Chat View Model Tests**
- File: `AirFitTests/Chat/ChatViewModelTests.swift`
- Test Implementation:
  ```swift
  @MainActor
  final class ChatViewModelTests: XCTestCase {
      var sut: ChatViewModel!
      var mockCoachEngine: MockCoachEngine!
      var mockAIService: MockAIService!
      var modelContext: ModelContext!
      var testUser: User!
      
      override func setUp() async throws {
          try await super.setUp()
          
          // Setup test context
          modelContext = try SwiftDataTestHelper.createTestContext(
              for: User.self, ChatSession.self, ChatMessage.self
          )
          
          // Create test user
          testUser = User(name: "Test User")
          modelContext.insert(testUser)
          try modelContext.save()
          
          // Setup mocks
          mockCoachEngine = MockCoachEngine()
          mockAIService = MockAIService()
          
          // Create SUT
          sut = ChatViewModel(
              modelContext: modelContext,
              user: testUser,
              coachEngine: mockCoachEngine,
              aiService: mockAIService,
              coordinator: ChatCoordinator()
          )
      }
      
      func test_loadOrCreateSession_withNoExistingSession_createsNew() async {
          // Act
          await sut.loadOrCreateSession()
          
          // Assert
          XCTAssertNotNil(sut.currentSession)
          XCTAssertTrue(sut.currentSession?.isActive ?? false)
          XCTAssertEqual(sut.currentSession?.user?.id, testUser.id)
      }
      
      func test_sendMessage_createsUserAndAssistantMessages() async {
          // Arrange
          await sut.loadOrCreateSession()
          sut.composerText = "Test message"
          mockAIService.mockStreamResponse = [
              .text("Hello "),
              .text("there!"),
              .done
          ]
          
          // Act
          await sut.sendMessage()
          
          // Wait for streaming to complete
          try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
          
          // Assert
          XCTAssertEqual(sut.messages.count, 2)
          XCTAssertEqual(sut.messages[0].role, .user)
          XCTAssertEqual(sut.messages[0].content, "Test message")
          XCTAssertEqual(sut.messages[1].role, .assistant)
          XCTAssertEqual(sut.messages[1].content, "Hello there!")
          XCTAssertTrue(sut.composerText.isEmpty)
      }
      
      func test_voiceRecording_updatesComposerText() async {
          // Arrange
          let mockVoiceManager = MockVoiceInputManager()
          sut.voiceManager = mockVoiceManager
          
          // Act
          await sut.toggleVoiceRecording()
          
          // Simulate transcription
          mockVoiceManager.simulateTranscription("Voice input test")
          
          // Assert
          XCTAssertTrue(sut.isRecording)
          XCTAssertEqual(sut.composerText, "Voice input test")
      }
      
      func test_deleteMessage_removesFromList() async {
          // Arrange
          await sut.loadOrCreateSession()
          let message = ChatMessage(
              session: sut.currentSession!,
              content: "Test",
              role: .user
          )
          modelContext.insert(message)
          sut.messages = [message]
          
          // Act
          await sut.deleteMessage(message)
          
          // Assert
          XCTAssertTrue(sut.messages.isEmpty)
      }
      
      func test_searchMessages_returnsMatchingResults() async {
          // Arrange
          await sut.loadOrCreateSession()
          let message1 = ChatMessage(
              session: sut.currentSession!,
              content: "Workout plan",
              role: .user
          )
          let message2 = ChatMessage(
              session: sut.currentSession!,
              content: "Nutrition advice",
              role: .assistant
          )
          modelContext.insert(message1)
          modelContext.insert(message2)
          try? modelContext.save()
          
          // Act
          let results = await sut.searchMessages(query: "workout")
          
          // Assert
          XCTAssertEqual(results.count, 1)
          XCTAssertEqual(results.first?.content, "Workout plan")
      }
  }
  ```

---

**5. Acceptance Criteria for Module Completion**

- ✅ Real-time chat interface with streaming AI responses
- ✅ Voice input with Whisper-powered transcription and waveform visualization
- ✅ Superior transcription accuracy for fitness terminology (sets, reps, HIIT, etc.)
- ✅ On-device voice processing for privacy and offline capability
- ✅ Rich message rendering (text, attachments, charts, actions)
- ✅ Message history persistence with SwiftData
- ✅ Context-aware suggestions based on conversation
- ✅ Chat session management (create, archive, delete)
- ✅ Search functionality across all messages
- ✅ Export conversations in multiple formats
- ✅ Smooth animations and transitions
- ✅ Proper error handling for network/AI failures
- ✅ Whisper model download and caching
- ✅ Accessibility support throughout
- ✅ Performance: Message send < 100ms, stream start < 500ms, transcription < 2s
- ✅ Test coverage ≥ 80%

**6. Module Dependencies**

- **Requires Completion Of:** Modules 1, 2, 4, 10, 11
- **Must Be Completed Before:** Final app assembly
- **Can Run In Parallel With:** Module 14 (if applicable)

**7. Performance Requirements**

- Message send latency: < 100ms
- Stream response start: < 500ms
- Voice transcription performance (based on MLX implementation):
  - Tiny model: < 0.5s for 30s audio, ~39MB memory
  - Base model: < 2s for 30s audio, ~74MB memory
  - Small model: < 3s for 30s audio, ~244MB memory
  - Medium model: < 5s for 30s audio, ~769MB memory
  - Large-v3 model: < 8s for 30s audio, ~1.5GB memory
  - Large-v3-turbo: < 4s for 30s audio, ~1.5GB memory (2x faster than large-v3)
- Whisper model initialization:
  - First load (cold start): 2-5s depending on model size
  - Subsequent loads (warm): < 500ms
  - With prewarm enabled: < 300ms after first initialization
- Real-time waveform updates at 60fps during recording
- Smooth scrolling at 60fps with 1000+ messages
- Memory usage:
  - Chat session overhead: < 50MB
  - Model memory (FP16 precision):
    - Tiny: ~20MB loaded
    - Base: ~40MB loaded
    - Small: ~125MB loaded
    - Medium: ~400MB loaded
    - Large-v3: ~800MB loaded
- Model download:
  - Progressive download with resume capability
  - Show accurate progress (bytes downloaded / total bytes)
  - Support background download on iOS 17+
  - Verify integrity with checksums
- Audio processing:
  - 16kHz mono PCM format for optimal Whisper performance
  - Log-mel spectrogram computation using Accelerate framework
  - Chunk processing for streaming: 1-second buffers minimum

**8. Verification Commands**

```bash
# Run module tests
swift test --filter ChatTests

# Build and verify
xcodebuild -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# UI Test for chat flow
xcodebuild test -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:AirFitUITests/ChatFlowTests
```

---

**9. Implementation Time Estimate**

- Task 13.0 (Infrastructure): 3-4 hours
- Task 13.1 (Chat UI): 6-8 hours
- Task 13.2 (Composer): 4-5 hours
- Task 13.3 (Voice): 4-5 hours
- Task 13.4 (History/Export): 3-4 hours
- Task 13.5 (Testing): 3-4 hours
- **Total: 23-30 hours**

This module provides a complete, production-ready chat interface that serves as the primary interaction point between users and their AI fitness coach. The implementation includes all modern chat features users expect, with particular attention to real-time performance and a delightful user experience.

**Whisper Integration Benefits:**
- **Superior Accuracy**: Whisper provides significantly better transcription accuracy than iOS Speech Recognition, especially for fitness terminology, accented speech, and noisy gym environments
- **Privacy**: All transcription happens on-device, ensuring user privacy with no cloud processing required
- **Offline Capability**: Once the model is downloaded, voice input works without internet connection
- **Fitness-Optimized**: Post-processing specifically handles fitness terms (HIIT, AMRAP, 1RM, Tabata, etc.)
- **Multiple Languages**: Whisper supports 99+ languages with automatic detection capability
- **Streaming Support**: Experimental streaming transcription for real-time feedback
- **Metal Optimization**: MLX implementation leverages Apple's Metal GPU for efficient processing
- **Model Flexibility**: Choose from 6 model sizes based on device capabilities and user preferences
- **Distilled Models**: Support for turbo variants that offer faster performance with minimal quality loss

**Implementation Notes:**
- **Model Selection Strategy**:
  - Default to base model (74MB) for best balance of speed/accuracy/size
  - Auto-upgrade to larger models on high-end devices (8GB+ RAM)
  - Allow manual model selection in settings for power users
  - Keep tiny model as fallback for low-memory devices
- **Download & Storage**:
  - Use WhisperKit's built-in HuggingFace download functionality
  - Store models in Application Support (not Caches) to prevent OS deletion
  - Implement download resume for large models (especially large-v3 at 1.5GB)
  - Show clear progress UI with size/time estimates
- **Performance Optimization**:
  - Enable model prewarming for faster first inference
  - Use FP16 precision (default in MLX) for memory efficiency
  - Consider 4-bit quantization for real-time applications
  - Implement audio chunking for long recordings (30s max per chunk)
- **Error Handling**:
  - Graceful fallback from large to smaller models on initialization failure
  - Retry logic with exponential backoff for downloads
  - Clear error messages for storage/memory issues
  - Offline detection with appropriate user messaging
- **Audio Configuration**:
  - Record at 16kHz mono (Whisper's expected format)
  - Use AVAudioRecorder with LinearPCM format
  - Implement voice activity detection to avoid transcribing silence
  - Consider noise reduction preprocessing for gym environments
- **Future Considerations**:
  - Monitor for ANE (Apple Neural Engine) support in MLX updates
  - Consider Core ML conversion for ANE utilization if critical
  - Watch for new distilled models (e.g., large-v3-turbo improvements)
  - Implement speaker diarization if multi-person coaching is added

**Alternative Approaches (Not Recommended but Available):**
- **Core ML Conversion**: Possible but requires manual encoder/decoder implementation
- **whisper.cpp**: CPU-only, significantly slower than MLX GPU implementation  
- **Python Bridge**: Adds complexity and app size, not recommended for production
- **Cloud API**: Defeats privacy benefits and requires internet connection

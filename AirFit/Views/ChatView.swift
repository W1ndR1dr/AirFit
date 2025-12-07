import SwiftUI
import HealthKit

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var serverStatus: ServerStatus = .checking
    @State private var healthContext: HealthContext?
    @State private var healthAuthorized = false

    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()

    enum ServerStatus {
        case checking, connected, disconnected
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status banners
                serverStatusBanner
                healthContextBanner

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }

                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .padding(.horizontal)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                inputArea
            }
            .navigationTitle("AirFit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshHealthData() }
                    } label: {
                        Image(systemName: "heart.circle")
                            .foregroundColor(healthAuthorized ? .pink : .gray)
                    }
                }
            }
        }
        .task {
            await initialize()
        }
    }

    // MARK: - Health Context Banner

    private var healthContextBanner: some View {
        Group {
            if let context = healthContext {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        HealthPill(icon: "figure.walk", value: "\(context.steps)", label: "steps")
                        HealthPill(icon: "flame", value: "\(context.activeCalories)", label: "cal")
                        if let sleep = context.sleepHours {
                            HealthPill(icon: "moon.fill", value: String(format: "%.1f", sleep), label: "hrs")
                        }
                        if let hr = context.restingHeartRate {
                            HealthPill(icon: "heart.fill", value: "\(hr)", label: "bpm")
                        }
                        if !context.recentWorkouts.isEmpty {
                            HealthPill(icon: "dumbbell.fill", value: "\(context.recentWorkouts.count)", label: "workouts")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))
            }
        }
    }

    private var serverStatusBanner: some View {
        Group {
            switch serverStatus {
            case .checking:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Connecting...")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))

            case .disconnected:
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Server offline")
                        .font(.caption)
                    Button("Retry") {
                        Task { await checkServer() }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.2))

            case .connected:
                EmptyView()
            }
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isLoading
        && serverStatus == .connected
    }

    // MARK: - Actions

    private func initialize() async {
        // Check server
        await checkServer()

        // Request HealthKit authorization
        healthAuthorized = await healthKit.requestAuthorization()

        // Fetch initial health data
        if healthAuthorized {
            await refreshHealthData()
        }
    }

    private func checkServer() async {
        serverStatus = .checking
        let isHealthy = await apiClient.checkHealth()
        serverStatus = isHealthy ? .connected : .disconnected
    }

    private func refreshHealthData() async {
        guard healthAuthorized else { return }
        healthContext = await healthKit.getTodayContext()
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = Message(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""

        // Refresh health data before sending
        if healthAuthorized {
            await refreshHealthData()
        }

        // Get AI response with health context
        isLoading = true
        do {
            let response = try await apiClient.sendMessage(
                text,
                healthContext: healthContext?.toDictionary()
            )
            let aiMessage = Message(content: response, isUser: false)
            messages.append(aiMessage)
        } catch {
            let errorMessage = Message(
                content: "Error: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
        }
        isLoading = false
    }
}

// MARK: - Health Pill Component

struct HealthPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : Color(.systemGray5))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ChatView()
}

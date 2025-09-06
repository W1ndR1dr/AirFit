import SwiftUI
import AVFoundation

/// Premium unified voice transcription button with MLX Whisper backend
/// Features full-width waveform visualization and smooth animations
public struct WhisperVoiceButton: View {
    // MARK: - Properties

    @Binding var text: String
    let placeholder: String?

    // MARK: - State

    @State private var recordingState: RecordingState = .idle
    @State private var waveformLevels: [Float] = []
    @State private var showingPermissionAlert = false
    @State private var showingModelDownload = false
    @State private var animateIn = false
    @State private var recordingStartTime: Date?
    @State private var recordingDuration: TimeInterval = 0
    @State private var transcribedText: String = ""
    @State private var streamingCharacterIndex: Int = 0

    // Services
    @State private var voiceManager = VoiceInputManager()
    @EnvironmentObject private var whisperManager: WhisperModelManager
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    // Constants
    private let maxWaveformSamples = 50
    private let characterStreamDelay: TimeInterval = 0.005

    // MARK: - Types

    enum RecordingState: Equatable {
        case idle
        case recording
        case processing
        case streaming(progress: Double)

        var isActive: Bool {
            switch self {
            case .idle:
                return false
            default:
                return true
            }
        }
    }

    // MARK: - Initialization

    public init(text: Binding<String>, placeholder: String? = nil) {
        self._text = text
        self.placeholder = placeholder
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main button when idle
            if case .idle = recordingState {
                idleButton
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
            }

            // Full-width recording overlay
            if recordingState.isActive {
                activeOverlay
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(MotionToken.premium, value: recordingState)
        .task {
            await setupVoiceManager()
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.1)) {
                animateIn = true
            }
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in Settings to use voice transcription.")
        }
        .sheet(isPresented: $showingModelDownload) {
            VoiceInputDownloadView(
                state: getVoiceInputState(),
                onCancel: {
                    showingModelDownload = false
                }
            )
            .environmentObject(whisperManager)
        }
        .onChange(of: recordingState) { _, newState in
            if case .recording = newState {
                recordingStartTime = Date()
                startRecordingTimer()
            } else {
                recordingStartTime = nil
                recordingDuration = 0
            }
        }
    }

    // MARK: - Components

    private var idleButton: some View {
        Button(action: {
            Task {
                await handleTap()
            }
        }) {
            ZStack {
                // Background
                Circle()
                    .fill(idleButtonBackground)
                    .frame(width: 36, height: 36)

                // Icon
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .scaleEffect(animateIn ? 1.0 : 0.5)
                    .opacity(animateIn ? 1.0 : 0)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var activeOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                // Content
                HStack(spacing: AppSpacing.sm) {
                    // Recording indicator
                    if case .recording = recordingState {
                        RecordingIndicator()
                            .frame(width: 8, height: 8)
                            .transition(.scale)
                    }

                    // Waveform or processing indicator
                    Group {
                        switch recordingState {
                        case .recording:
                            VoiceWaveformView(
                                levels: waveformLevels,
                                config: waveformConfig
                            )
                            .frame(height: 24)
                            .transition(.opacity)

                        case .processing:
                            processingView
                                .transition(.opacity)

                        case .streaming:
                            streamingTextView
                                .transition(.opacity)

                        case .idle:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Duration or stop button
                    if case .recording = recordingState {
                        HStack(spacing: AppSpacing.xs) {
                            Text(formatDuration(recordingDuration))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary.opacity(0.8))

                            Button(action: {
                                Task {
                                    await stopRecording()
                                }
                            }) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.red)
                            }
                            .buttonStyle(ScaleButtonStyle(scale: 0.9))
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
            }
            .frame(width: geometry.size.width, height: 44)
        }
        .frame(height: 44)
    }

    private var processingView: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(gradientManager.currentGradient(for: colorScheme))
                    .frame(width: 6, height: 6)
                    .scaleEffect(animateIn ? 1.0 : 0.5)
                    .animation(
                        Animation.smooth(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animateIn
                    )
            }

            Text("Processing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var streamingTextView: some View {
        Text(transcribedText.prefix(streamingCharacterIndex))
            .font(.system(size: 14))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                streamText()
            }
    }

    // MARK: - Computed Properties

    private var idleButtonBackground: some ShapeStyle {
        LinearGradient(
            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.15) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var waveformConfig: VoiceWaveformView.Configuration {
        var config = VoiceWaveformView.Configuration()
        config.barWidth = 3
        config.barSpacing = 2
        config.minimumHeight = 4
        config.heightMultiplier = 0.7
        config.useGradientOpacity = true
        config.animateEntrance = true
        config.levelAnimation = .bouncy(extraBounce: 0.2)
        return config
    }

    // MARK: - Voice Manager Setup

    private func setupVoiceManager() async {
        await voiceManager.initialize()

        // Setup callbacks
        voiceManager.onWaveformUpdate = { levels in
            updateWaveform(levels)
        }

        voiceManager.onTranscription = { transcription in
            Task { @MainActor in
                await handleTranscription(transcription)
            }
        }

        voiceManager.onError = { error in
            Task { @MainActor in
                await handleError(error)
            }
        }
    }

    // MARK: - Actions

    private func handleTap() async {
        // Check Whisper model status
        switch whisperManager.modelState {
        case .notDownloaded, .error:
            HapticService.notification(.warning)
            showingModelDownload = true
            return

        case .downloading:
            HapticService.notification(.warning)
            showingModelDownload = true
            return

        case .downloaded, .loading:
            // Model is being prepared, wait
            HapticService.impact(.light)
            return

        case .ready:
            // Good to go
            break
        }

        // Start recording
        await startRecording()
    }

    private func startRecording() async {
        do {
            HapticService.impact(.medium)
            recordingState = .recording
            waveformLevels = Array(repeating: 0.0, count: maxWaveformSamples)

            try await voiceManager.startRecording()

        } catch {
            await handleError(error)
        }
    }

    private func stopRecording() async {
        HapticService.impact(.light)
        recordingState = .processing

        let transcription = await voiceManager.stopRecording()

        if let transcription = transcription {
            await handleTranscription(transcription)
        } else {
            recordingState = .idle
        }
    }


    private func handleTranscription(_ transcription: String) async {
        guard !transcription.isEmpty else {
            recordingState = .idle
            return
        }

        transcribedText = transcription
        streamingCharacterIndex = 0
        recordingState = .streaming(progress: 0)

        // Start streaming animation
        streamText()
    }

    private func handleError(_ error: Error) async {
        AppLogger.error("Voice input error", error: error, category: .ui)
        recordingState = .idle

        if case VoiceInputError.notAuthorized = error {
            showingPermissionAlert = true
        }

        HapticService.notification(.error)
    }

    // MARK: - Helper Methods

    private func getVoiceInputState() -> VoiceInputState {
        switch whisperManager.modelState {
        case .notDownloaded:
            return .idle
        case .downloading(let progress):
            return .downloadingModel(progress: progress, modelName: whisperManager.currentModelSize.displayName)
        case .downloaded, .loading:
            return .preparingModel
        case .ready:
            return .ready
        case .error(_):
            return .error(.whisperInitializationFailed)
        }
    }

    private func updateWaveform(_ newLevels: [Float]) {
        // Smooth update with rolling buffer
        waveformLevels.removeFirst(newLevels.count)
        waveformLevels.append(contentsOf: newLevels)
    }

    private func streamText() {
        Task { @MainActor in
            for i in 0...transcribedText.count {
                streamingCharacterIndex = i
                recordingState = .streaming(progress: Double(i) / Double(transcribedText.count))

                try? await Task.sleep(for: .seconds(characterStreamDelay))
            }

            // Append to text field
            let currentText = text
            text = currentText.isEmpty ? transcribedText : "\(currentText) \(transcribedText)"

            HapticService.impact(.light)

            // Reset state
            transcribedText = ""
            streamingCharacterIndex = 0
            recordingState = .idle
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startRecordingTimer() {
        Task { @MainActor in
            while case .recording = recordingState {
                if let startTime = recordingStartTime {
                    recordingDuration = Date().timeIntervalSince(startTime)
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}

// MARK: - Motion Tokens

private extension MotionToken {
    static let premium = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.95) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.smooth(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Recording Indicator

private struct RecordingIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.red)
            .opacity(isAnimating ? 0.3 : 1.0)
            .animation(
                Animation.smooth(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Preview

#Preview("Whisper Voice Button") {
    VStack(spacing: 40) {
        // With TextField
        TextField("Type or speak...", text: .constant(""))
            .textFieldStyle(.roundedBorder)
            .overlay(alignment: .bottomTrailing) {
                WhisperVoiceButton(text: .constant(""))
                    .padding(8)
            }
            .padding()

        // With TextEditor
        TextEditor(text: .constant(""))
            .frame(height: 100)
            .overlay(alignment: .bottomTrailing) {
                WhisperVoiceButton(text: .constant(""))
                    .padding(8)
            }
            .padding()
    }
    .environmentObject(WhisperModelManager())
    .environmentObject(GradientManager())
}

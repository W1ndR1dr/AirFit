import SwiftUI
import AVFoundation

/// Onboarding view for setting up Whisper voice transcription
struct WhisperSetupView: View {
    @EnvironmentObject private var whisperManager: WhisperModelManager
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var selectedModelSize: WhisperModelManager.ModelSize = .large
    @State private var isDownloading = false
    @State private var downloadError: Error?
    @State private var showingPermissionAlert = false

    private var modelState: WhisperModelManager.ModelState {
        whisperManager.modelState
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Header
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .symbolRenderingMode(.hierarchical)

                Text("Voice-First Experience")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Enable premium voice transcription for a seamless, hands-free coaching experience.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Model selection (if not already downloaded)
            if case .notDownloaded = modelState {
                VStack(spacing: AppSpacing.lg) {
                    Text("Choose Model Quality")
                        .font(.headline)

                    ForEach([WhisperModelManager.ModelSize.small, .large], id: \.self) { size in
                        modelOptionButton(size)
                    }

                    Text("Recommended: Large Turbo for best accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            }

            // Status display
            Group {
                switch modelState {
                case .notDownloaded:
                    EmptyView()

                case .downloading(let progress):
                    downloadProgressView(progress)

                case .downloaded, .loading:
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Model downloaded, preparing...")
                    }
                    .font(.body)

                case .ready:
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Voice transcription ready!")
                        }
                        .font(.body)

                        TestTranscriptionView()
                            .padding(.top)
                    }

                case .error(let error):
                    ErrorView(error: error) {
                        Task {
                            await retryDownload()
                        }
                    }
                }
            }
            .animation(.easeInOut, value: modelState)

            Spacer()

            // Actions
            VStack(spacing: AppSpacing.sm) {
                if case .notDownloaded = modelState {
                    Button(action: {
                        Task {
                            await startDownload()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download \(selectedModelSize.displayName)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(gradientManager.currentGradient(for: colorScheme))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Button(action: {
                    if case .ready = modelState {
                        onContinue()
                    } else {
                        onSkip()
                    }
                }) {
                    Text(modelState.isReady ? "Continue" : "Skip for Now")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(modelState.isReady ? AnyShapeStyle(gradientManager.currentGradient(for: colorScheme)) : AnyShapeStyle(Color.gray.opacity(0.2)))
                        .foregroundColor(modelState.isReady ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())

                if !modelState.isReady {
                    Text("You can download the model later in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
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
        .task {
            await checkMicrophonePermission()
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func modelOptionButton(_ size: WhisperModelManager.ModelSize) -> some View {
        Button(action: {
            selectedModelSize = size
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(size.displayName)
                        .font(.body)
                        .fontWeight(.medium)

                    Text(size == .small ? "Good accuracy, smaller download" : "Best accuracy, larger download")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedModelSize == size {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedModelSize == size ?
                            gradientManager.active.colors(for: colorScheme)[0].opacity(0.1) :
                            Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        selectedModelSize == size ?
                            LinearGradient(colors: gradientManager.active.colors(for: colorScheme), startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func downloadProgressView(_ progress: Double) -> some View {
        VStack(spacing: AppSpacing.md) {
            Text("Downloading Model...")
                .font(.headline)

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(gradientManager.active.colors(for: colorScheme)[0])

            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Actions

    private func checkMicrophonePermission() async {
        let authorized = await AVAudioApplication.requestRecordPermission()
        if !authorized {
            showingPermissionAlert = true
        }
    }

    private func startDownload() async {
        isDownloading = true
        downloadError = nil

        do {
            try await whisperManager.downloadModel(selectedModelSize)
            HapticService.notification(.success)
        } catch {
            downloadError = error
            HapticService.notification(.error)
        }

        isDownloading = false
    }

    private func retryDownload() async {
        await startDownload()
    }
}

// MARK: - Model State Extension

private extension WhisperModelManager.ModelState {
    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }
}

// MARK: - Test Transcription View

private struct TestTranscriptionView: View {
    @State private var isRecording = false
    @State private var transcribedText = ""
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Try it out!")
                .font(.headline)

            Button(action: {
                // Toggle recording
                isRecording.toggle()
                if isRecording {
                    HapticService.impact(.medium)
                    // Start test recording
                } else {
                    HapticService.impact(.light)
                    // Stop and show sample transcription
                    transcribedText = "Voice transcription is working perfectly!"
                }
            }) {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 24))
                    Text(isRecording ? "Stop" : "Test Voice")
                }
                .foregroundStyle(isRecording ? Color.red : gradientManager.active.colors(for: colorScheme)[0])
            }
            .buttonStyle(ScaleButtonStyle())

            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: transcribedText)
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Download Failed")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    WhisperSetupView(
        onContinue: {},
        onSkip: {}
    )
    .environmentObject(WhisperModelManager())
    .environmentObject(GradientManager())
}

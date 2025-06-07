import SwiftUI
import SwiftData
import AVFoundation

/// Full screen voice logging interface with real-time waveform visualisation.
struct FoodVoiceInputView: View {
    @State var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pulseAnimation = false
    @State private var audioLevel: Float = 0

    private let audioLevelTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                instructionsSection

                Spacer()

                microphoneButton

                waveformSection

                transcriptionSection

                Spacer()

                statusSection
            }
            .padding()
            .background(AppColors.backgroundPrimary)
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onReceive(audioLevelTimer) { _ in
                updateAudioLevel()
            }
            .voiceInputDownloadOverlay(
                state: $viewModel.voiceInputState,
                onCancel: {
                    // Cancel download and dismiss view
                    dismiss()
                }
            )
            .task {
                // Initialize voice input when view appears
                await viewModel.initializeVoiceInput()
            }
        }
    }

    // MARK: - Sections
    private var instructionsSection: some View {
        VStack(spacing: AppSpacing.small) {
            Text("Tell me what you ate")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Hold the button and describe your meal")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                ExampleText("\"I had a chicken salad with ranch dressing\"")
                ExampleText("\"Two eggs, toast, and orange juice\"")
                ExampleText("\"Large pepperoni pizza, about 3 slices\"")
            }
            .padding()
            .background(AppColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius))
            .padding(.top)
        }
    }

    private var microphoneButton: some View {
        ZStack {
            if viewModel.isRecording {
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )

                Circle()
                    .fill(AppColors.accent.opacity(0.1))
                    .frame(width: 240, height: 240)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .delay(0.2)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            }

            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : AppColors.accent)
                        .frame(width: 120, height: 120)

                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)

                    if viewModel.isRecording {
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 4)
                            .frame(width: 120 + CGFloat(audioLevel * 40), height: 120 + CGFloat(audioLevel * 40))
                            .animation(.easeOut(duration: 0.1), value: audioLevel)
                    }
                }
            }
            .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
            .onLongPressGesture(
                minimumDuration: 0.01,
                maximumDistance: .infinity,
                pressing: { isPressing in
                    handlePressing(isPressing)
                },
                perform: {}
            )
        }
        .frame(height: 300)
        .onAppear {
            if viewModel.isRecording {
                pulseAnimation = true
            }
        }
    }

    private var waveformSection: some View {
        Group {
            if viewModel.isRecording {
                VoiceWaveformView(levels: viewModel.voiceWaveform)
                    .frame(height: 40)
                    .padding(.vertical, AppSpacing.small)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.voiceWaveform)
    }

    private var transcriptionSection: some View {
        Group {
            if !viewModel.transcribedText.isEmpty {
                VStack(spacing: AppSpacing.small) {
                    HStack {
                        Text("Transcript")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if viewModel.transcriptionConfidence > 0 {
                            ConfidenceIndicator(confidence: viewModel.transcriptionConfidence)
                        }

                        Spacer()
                    }

                    Text(viewModel.transcribedText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius))
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.transcribedText)
    }

    private var statusSection: some View {
        HStack(spacing: AppSpacing.small) {
            if viewModel.isRecording {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse)
                Text("Listening...")
                    .foregroundStyle(.red)
            } else if viewModel.isProcessingAI {
                ProgressView()
                    .controlSize(.small)
                Text("Processing...")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Hold button to record")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .frame(height: 44)
    }

    // MARK: - Interaction
    private func handlePressing(_ isPressing: Bool) {
        if isPressing && !viewModel.isRecording {
            Task {
                await viewModel.startRecording()
                withAnimation {
                    pulseAnimation = true
                }
            }
            HapticManager.impact(.medium)
        } else if !isPressing && viewModel.isRecording {
            Task {
                await viewModel.stopRecording()
                withAnimation {
                    pulseAnimation = false
                }
            }
            HapticManager.impact(.light)
        }
    }

    private func updateAudioLevel() {
        if viewModel.isRecording {
            audioLevel = viewModel.voiceWaveform.max() ?? 0
        } else {
            audioLevel = 0
        }
    }
}

// MARK: - Supporting Views
private struct ExampleText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack {
            Image(systemName: "quote.opening")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }
    }
}

private struct ConfidenceIndicator: View {
    let confidence: Float

    private var color: Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.6 { return .yellow }
        return .orange
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(confidence * 3) ? color : Color.gray.opacity(0.3))
                    .frame(width: 3, height: 8)
            }
        }
    }
}

private struct VoiceWaveformView: View {
    let levels: [Float]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.accent)
                        .frame(width: 3, height: CGFloat(level) * geometry.size.height)
                        .animation(.easeInOut(duration: 0.1), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#if DEBUG
struct VoiceInputView_Previews: PreviewProvider {
    static var previews: some View {
        // Simplified preview without dependencies
        Text("VoiceInputView Preview")
            .navigationTitle("Voice Input")
    }
}
#endif

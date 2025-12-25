import SwiftUI

// MARK: - Voice Input Overlay

/// Full-screen overlay for voice input with waveform visualization
/// Appears when user taps the microphone button in any text field
struct VoiceInputOverlay: View {
    @Bindable var speechManager: WhisperTranscriptionService
    let onComplete: (String) -> Void
    let onCancel: () -> Void

    @State private var showContent = false
    @State private var showModelRequired = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tap outside to cancel
                    Task { await cancel() }
                }

            VStack(spacing: 32) {
                Spacer()

                // Waveform visualization
                CircularWaveformView(
                    audioLevel: speechManager.audioLevel,
                    isSpeechDetected: speechManager.isSpeechDetected
                )
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)

                // Transcript preview
                VStack(spacing: 12) {
                    if speechManager.transcript.isEmpty {
                        Text(speechManager.isSpeechDetected ? "Listening..." : "Say something...")
                            .font(.headlineMedium)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        Text(speechManager.transcript)
                            .font(.headlineLarge)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(.horizontal, 32)
                            .contentTransition(.opacity)
                            .animation(.bloomSubtle, value: speechManager.transcript)
                    }

                    // Status indicator
                    HStack(spacing: 8) {
                        if speechManager.isSpeechDetected {
                            Circle()
                                .fill(Theme.success)
                                .frame(width: 8, height: 8)
                            Text("Hearing you...")
                                .font(.caption)
                                .foregroundStyle(Theme.success)
                        } else if speechManager.isRecording {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 8, height: 8)
                                .opacity(0.6)
                            Text("Waiting for speech...")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .animation(.bloomSubtle, value: speechManager.isSpeechDetected)
                }
                .frame(minHeight: 80)
                .padding(.top, 24)

                Spacer()

                // Action buttons
                HStack(spacing: 40) {
                    // Cancel button
                    Button {
                        Task { await cancel() }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.surface)
                                    .frame(width: 56, height: 56)

                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Text("Cancel")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .buttonStyle(BloomButtonStyle())

                    // Done/Send button
                    Button {
                        Task { await complete() }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 72, height: 72)
                                    .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 4)

                                Image(systemName: speechManager.transcript.isEmpty ? "mic.fill" : "checkmark")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            Text(speechManager.transcript.isEmpty ? "Recording" : "Done")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .buttonStyle(BloomButtonStyle())
                    .disabled(speechManager.transcript.isEmpty)

                    // Stop/Restart button
                    Button {
                        Task {
                            if speechManager.isRecording {
                                await speechManager.stopListening()
                            } else {
                                try? await speechManager.startListening()
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.surface)
                                    .frame(width: 56, height: 56)

                                Image(systemName: speechManager.isRecording ? "stop.fill" : "arrow.clockwise")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(speechManager.isRecording ? Theme.error : Theme.textSecondary)
                            }
                            Text(speechManager.isRecording ? "Stop" : "Retry")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .buttonStyle(BloomButtonStyle())
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.bloom) {
                showContent = true
            }
        }
    }

    private func complete() async {
        await speechManager.stopListening()
        let transcript = speechManager.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !transcript.isEmpty {
            withAnimation(.bloom) {
                showContent = false
            }
            try? await Task.sleep(for: .milliseconds(200))
            onComplete(transcript)
        }
    }

    private func cancel() async {
        await speechManager.cancel()
        withAnimation(.bloom) {
            showContent = false
        }
        try? await Task.sleep(for: .milliseconds(200))
        onCancel()
    }
}

// MARK: - Inline Voice Input View

/// Smaller inline voice input that appears within the text field area
struct InlineVoiceInputView: View {
    @Bindable var speechManager: WhisperTranscriptionService
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            FullWidthWaveformView(
                audioLevels: speechManager.audioLevels,
                isSpeechDetected: speechManager.isSpeechDetected,
                minHeight: 6,
                maxHeight: 26,
                barWidth: 3,
                spacing: 3
            )
            .padding(.horizontal, 8)

            HStack(spacing: 12) {
                Text(statusText)
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.opacity)
                    .animation(.bloomSubtle, value: statusText)

                Spacer()

                Button {
                    Task {
                        await speechManager.cancel()
                        onCancel()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Theme.surface.opacity(0.8), in: Circle())
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await speechManager.stopListening()
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Theme.accent, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusText: String {
        if speechManager.isPolishing {
            return "Transcribing..."
        }
        if speechManager.isSpeechDetected {
            return "Listening..."
        }
        return "Waiting for speech..."
    }
}

// MARK: - Voice Input Button

/// Microphone button that can be placed inside text fields
struct VoiceInputButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background glow when recording
                if isRecording {
                    Circle()
                        .fill(Theme.accent.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .blur(radius: 4)
                }

                // Button background
                Circle()
                    .fill(isRecording ? Theme.accent : Theme.textMuted.opacity(0.15))
                    .frame(width: 28, height: 28)

                // Microphone icon
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isRecording ? .white : Theme.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(BloomButtonStyle())
        .animation(.bloomSubtle, value: isRecording)
    }
}

// MARK: - Preview

#Preview("Voice Input Overlay") {
    VoiceInputOverlay(
        speechManager: WhisperTranscriptionService.shared,
        onComplete: { text in print("Complete: \(text)") },
        onCancel: { print("Cancelled") }
    )
}

#Preview("Inline Voice Input") {
    VStack {
        Spacer()
        InlineVoiceInputView(
            speechManager: WhisperTranscriptionService.shared,
            onCancel: { print("Cancelled") }
        )
        .padding()
    }
    .background(Theme.background)
}

#Preview("Voice Button") {
    HStack(spacing: 20) {
        VoiceInputButton(isRecording: false) {}
        VoiceInputButton(isRecording: true) {}
    }
    .padding()
    .background(Theme.surface)
}

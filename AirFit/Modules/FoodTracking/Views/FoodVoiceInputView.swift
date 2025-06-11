import SwiftUI
import SwiftData
import AVFoundation

/// Full screen voice logging interface with real-time waveform visualisation.
struct FoodVoiceInputView: View {
    @State var viewModel: FoodTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var animateIn = false
    @State private var audioLevel: Float = 0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private let audioLevelTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            BaseScreen {
                VStack(spacing: 0) {
                    instructionsSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                        .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                    Spacer()

                    microphoneButton
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                    waveformSection

                    transcriptionSection

                    Spacer()

                    statusSection
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.vertical, AppSpacing.md)
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topLeading) {
                Button(action: {
                    HapticService.selection()
                    dismiss()
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    .padding(AppSpacing.screenPadding)
                }
                .opacity(animateIn ? 1 : 0)
            }
            .onReceive(audioLevelTimer) { _ in
                updateAudioLevel()
            }
            .voiceInputDownloadOverlay(
                state: $viewModel.voiceInputState,
                onCancel: {
                    HapticService.impact(.light)
                    dismiss()
                }
            )
            .task {
                await viewModel.initializeVoiceInput()
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
    }

    // MARK: - Sections
    private var instructionsSection: some View {
        VStack(spacing: AppSpacing.md) {
            CascadeText("Tell me what you ate")
                .font(.system(size: 32, weight: .light, design: .rounded))

            Text("Hold the button and describe your meal")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ExampleText("\"I had a chicken salad with ranch dressing\"")
                    ExampleText("\"Two eggs, toast, and orange juice\"")
                    ExampleText("\"Large pepperoni pizza, about 3 slices\"")
                }
            }
            .padding(.top, AppSpacing.xs)
        }
    }

    private var microphoneButton: some View {
        ZStack {
            // Use MicRippleView for recording visualization
            MicRippleView(
                isRecording: viewModel.isRecording,
                size: 300
            )
            
            // Main button
            ZStack {
                Circle()
                    .fill(viewModel.isRecording ? 
                        LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        gradientManager.currentGradient(for: colorScheme)
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: viewModel.isRecording ? .red.opacity(0.3) : (gradientManager.active == .peachRose ? Color.pink.opacity(0.3) : Color.blue.opacity(0.3)), radius: 20, x: 0, y: 10)

                Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white)
                    .scaleEffect(viewModel.isRecording ? 0.9 : 1.0)
                    .animation(MotionToken.standardSpring, value: viewModel.isRecording)
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
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Text("Transcript")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(.secondary)

                        if viewModel.transcriptionConfidence > 0 {
                            ConfidenceIndicator(confidence: viewModel.transcriptionConfidence)
                        }

                        Spacer()
                    }

                    GlassCard {
                        Text(viewModel.transcribedText)
                            .font(.system(size: 16, weight: .light))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.primary)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(MotionToken.standardSpring, value: viewModel.transcribedText)
    }

    private var statusSection: some View {
        HStack(spacing: AppSpacing.sm) {
            if viewModel.isRecording {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse)
                Text("Listening...")
                    .foregroundStyle(.red)
            } else if viewModel.isProcessingAI {
                ProgressView()
                    .controlSize(.small)
                    .tint(gradientManager.active == .peachRose ? Color.pink : Color.blue)
                Text("Processing...")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Hold button to record")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 14, weight: .light))
        .frame(height: 44)
    }

    // MARK: - Interaction
    private func handlePressing(_ isPressing: Bool) {
        if isPressing && !viewModel.isRecording {
            HapticService.impact(.medium)
            Task {
                await viewModel.startRecording()
            }
        } else if !isPressing && viewModel.isRecording {
            HapticService.impact(.light)
            Task {
                await viewModel.stopRecording()
            }
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
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "quote.opening")
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
            Text(text)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(.secondary)
                .italic()
        }
    }
}

private struct ConfidenceIndicator: View {
    let confidence: Float
    @State private var animateIn = false

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
                    .scaleEffect(animateIn ? 1 : 0)
                    .animation(
                        MotionToken.standardSpring.delay(Double(index) * 0.05),
                        value: animateIn
                    )
            }
        }
        .onAppear {
            animateIn = true
        }
    }
}

private struct VoiceWaveformView: View {
    let levels: [Float]
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(gradientManager.currentGradient(for: colorScheme))
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

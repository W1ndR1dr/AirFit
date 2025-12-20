import SwiftUI

// MARK: - Voice-Enabled Text Field

/// A text field with integrated voice input capability
/// Features a mic icon that triggers a beautiful waveform overlay for speech-to-text
struct VoiceTextField: View {
    // MARK: - Properties

    let placeholder: String
    @Binding var text: String

    /// Whether to allow multi-line input
    var axis: Axis = .horizontal

    /// Line limit for multi-line input
    var lineLimit: ClosedRange<Int> = 1...1

    /// Whether voice input is enabled
    var voiceEnabled: Bool = true

    /// Use inline waveform (vs fullscreen overlay)
    var useInlineMode: Bool = false

    /// Corner radius style
    var cornerRadius: CGFloat = 24

    /// Use material background instead of solid
    var useMaterial: Bool = false

    /// Focus state binding
    var focusState: FocusState<Bool>.Binding?

    /// Submit action
    var onSubmit: (() -> Void)?

    /// Submit label
    var submitLabel: SubmitLabel = .send

    // MARK: - State

    @State private var isVoiceInputActive = false
    @State private var showOverlay = false
    @FocusState private var internalFocus: Bool

    @State private var speechManager = SpeechTranscriptionManager()

    // MARK: - Body

    var body: some View {
        ZStack {
            if isVoiceInputActive && useInlineMode {
                // Inline voice input replaces the text field
                InlineVoiceInputView(
                    speechManager: speechManager,
                    onComplete: { transcript in
                        text = transcript
                        isVoiceInputActive = false
                        onSubmit?()
                    },
                    onCancel: {
                        isVoiceInputActive = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Normal text field with mic button
                textFieldContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.bloomSubtle, value: isVoiceInputActive)
        .fullScreenCover(isPresented: $showOverlay) {
            VoiceInputOverlay(
                speechManager: speechManager,
                onComplete: { transcript in
                    text = transcript
                    showOverlay = false
                    onSubmit?()
                },
                onCancel: {
                    showOverlay = false
                }
            )
            .background(ClearBackgroundView())
        }
    }

    // MARK: - Text Field Content

    @ViewBuilder
    private var textFieldContent: some View {
        HStack(spacing: 8) {
            // Text field
            Group {
                if axis == .vertical {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(lineLimit)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.bodyMedium)
            .textFieldStyle(.plain)
            .focused(focusState ?? $internalFocus)
            .submitLabel(submitLabel)
            .onSubmit {
                onSubmit?()
            }

            // Voice input button
            if voiceEnabled {
                VoiceInputButton(isRecording: isVoiceInputActive) {
                    startVoiceInput()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundView)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Theme.textMuted.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var backgroundView: some View {
        if useMaterial {
            Rectangle().fill(.ultraThinMaterial)
        } else {
            Rectangle().fill(Theme.surface)
        }
    }

    // MARK: - Voice Input

    private func startVoiceInput() {
        Task {
            // Setup completion handler
            speechManager.onTranscriptionComplete = { transcript in
                Task { @MainActor in
                    if !transcript.isEmpty {
                        text = transcript
                    }
                    isVoiceInputActive = false
                    if useInlineMode {
                        // Auto-submit after voice input in inline mode
                        onSubmit?()
                    }
                }
            }

            do {
                try await speechManager.startListening()

                if useInlineMode {
                    isVoiceInputActive = true
                } else {
                    showOverlay = true
                }
            } catch {
                print("Failed to start voice input: \(error)")
            }
        }
    }
}

// MARK: - Clear Background for Overlay

struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        Task { @MainActor in
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - View Modifier Alternative

/// Modifier to add voice input capability to any TextField
struct VoiceInputModifier: ViewModifier {
    @Binding var text: String
    var useInlineMode: Bool = false
    var onSubmit: (() -> Void)?

    @State private var showOverlay = false
    @State private var speechManager = SpeechTranscriptionManager()

    func body(content: Content) -> some View {
        HStack(spacing: 8) {
            content

            VoiceInputButton(isRecording: showOverlay) {
                startVoiceInput()
            }
        }
        .fullScreenCover(isPresented: $showOverlay) {
            VoiceInputOverlay(
                speechManager: speechManager,
                onComplete: { transcript in
                    text = transcript
                    showOverlay = false
                    onSubmit?()
                },
                onCancel: {
                    showOverlay = false
                }
            )
            .background(ClearBackgroundView())
        }
    }

    private func startVoiceInput() {
        Task {
            do {
                try await speechManager.startListening()
                showOverlay = true
            } catch {
                print("Failed to start voice input: \(error)")
            }
        }
    }
}

extension View {
    /// Add voice input capability to a TextField
    func withVoiceInput(
        text: Binding<String>,
        useInlineMode: Bool = false,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        modifier(VoiceInputModifier(
            text: text,
            useInlineMode: useInlineMode,
            onSubmit: onSubmit
        ))
    }
}

// MARK: - Chat-Style Voice TextField

/// Pre-styled voice text field matching the chat input style
struct ChatVoiceTextField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        VoiceTextField(
            placeholder: placeholder,
            text: $text,
            axis: .vertical,
            lineLimit: 1...5,
            voiceEnabled: true,
            useInlineMode: false,
            cornerRadius: 24,
            useMaterial: false,
            focusState: $isFocused,
            onSubmit: onSubmit,
            submitLabel: .send
        )
    }
}

/// Pre-styled voice text field for nutrition logging
struct NutritionVoiceTextField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        VoiceTextField(
            placeholder: placeholder,
            text: $text,
            axis: .vertical,
            lineLimit: 1...3,
            voiceEnabled: true,
            useInlineMode: false,
            cornerRadius: 24,
            useMaterial: false,
            focusState: $isFocused,
            onSubmit: onSubmit,
            submitLabel: .done
        )
    }
}

// MARK: - Preview

#Preview("Voice TextField") {
    VStack(spacing: 20) {
        VoiceTextField(
            placeholder: "Message...",
            text: .constant(""),
            axis: .vertical,
            lineLimit: 1...3
        )

        VoiceTextField(
            placeholder: "Log food...",
            text: .constant("Two eggs and toast"),
            cornerRadius: 24
        )

        VoiceTextField(
            placeholder: "Ask about this insight...",
            text: .constant(""),
            useMaterial: true
        )
    }
    .padding()
    .background(Theme.background)
}

#Preview("Chat Style") {
    VStack {
        Spacer()
        ChatVoiceTextField(
            placeholder: "Message your coach...",
            text: .constant("")
        )
        .padding()
    }
    .background(Theme.background)
}

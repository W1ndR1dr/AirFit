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
    @State private var animateIn = false
    @State private var recordingStartTime: Date?
    @State private var recordingDuration: TimeInterval = 0
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if !attachments.isEmpty {
                attachmentsPreview
                    .padding(.bottom, AppSpacing.xs)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                if !isRecording {
                    attachmentMenu
                        .scaleEffect(animateIn ? 1 : 0.8)
                        .opacity(animateIn ? 1 : 0)
                        .transition(.scale.combined(with: .opacity))
                }

                if isRecording {
                    recordingView
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                } else {
                    textInputView
                        .transition(.opacity)
                }

                actionButton
                    .animation(MotionToken.standardSpring, value: isRecording)
                    .animation(MotionToken.standardSpring, value: canSend)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .glassEffect(in: .rect(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 1)
            )
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.2)) {
                animateIn = true
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                recordingStartTime = Date()
                startRecordingTimer()
            } else {
                recordingStartTime = nil
                recordingDuration = 0
            }
        }
        .photosPicker(
            isPresented: $showAttachmentPicker,
            selection: $selectedPhoto,
            matching: .images
        )
        .onChange(of: selectedPhoto) { _, item in
            if let item {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        attachments.append(
                            ChatAttachment(
                                type: .image,
                                filename: UUID().uuidString + ".jpg",
                                data: data
                            )
                        )
                    }
                }
            }
        }
    }

    // Extracted to simplify type-checking of the main body
    @ViewBuilder
    private var actionButton: some View {
        // Unify foreground style types to avoid complex conditional inference
        let iconStyle: AnyShapeStyle = {
            if canSend {
                return AnyShapeStyle(gradientManager.currentGradient(for: colorScheme))
            } else {
                return AnyShapeStyle(Color.secondary)
            }
        }()

        Button(action: {
            HapticService.impact(.light)
            if isRecording {
                onVoiceToggle()
            } else {
                canSend ? onSend() : onVoiceToggle()
            }
        }) {
            ZStack {
                if isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.red)
                } else {
                    Circle()
                        .glassEffect(in: .circle)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().strokeBorder(
                                Color.white.opacity(0.2),
                                lineWidth: 0.5
                            )
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
                    Image(systemName: canSend ? "arrow.up" : "mic")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconStyle)
                }
            }
        }
    }

    private var attachmentMenu: some View {
        Button(action: {
            HapticService.selection()
            showAttachmentPicker = true
        }, label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)
        })
    }

    private var textInputView: some View {
        TextField("Message your coach…", text: $text, axis: .vertical)
            .font(.system(size: 16, weight: .regular))
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .focused($isTextFieldFocused)
            .onSubmit {
                if canSend {
                    HapticService.impact(.light)
                    onSend()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                WhisperVoiceButton(text: $text)
                    .padding(4)
            }
            .opacity(animateIn ? 1 : 0)
            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)
    }

    private var recordingView: some View {
        HStack(spacing: AppSpacing.sm) {
            // Minimal recording indicator
            RecordingIndicator()
                .frame(width: 12, height: 12)

            // Clean waveform visualization
            VoiceWaveformView(levels: waveform, config: .chat)
                .frame(height: 24)

            // Recording time
            Text(formatDuration(recordingDuration))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .opacity(0.8)
        }
        .padding(.horizontal, AppSpacing.xs)
    }

    private var attachmentsPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(attachments) { attachment in
                    AttachmentPreview(attachment: attachment) {
                        withAnimation(MotionToken.standardSpring) {
                            attachments.removeAll { $0.id == attachment.id }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.sm)
        }
    }

    // MARK: - Helper Methods

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startRecordingTimer() {
        Task { @MainActor in
            while self.isRecording {
                if let startTime = self.recordingStartTime {
                    self.recordingDuration = Date().timeIntervalSince(startTime)
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}


private struct RecordingIndicator: View {
    @State private var isAnimating = false
    @State private var opacity: Double = 1.0

    var body: some View {
        Circle()
            .fill(Color.red)
            .overlay(
                Circle()
                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.8 : 1.0)
                    .opacity(isAnimating ? 0 : 0.8)
            )
            .opacity(opacity)
            .onAppear {
                // Gentle pulsing
                withAnimation(
                    .smooth(duration: 0.8)
                        .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.6
                }

                // Expanding ring
                withAnimation(
                    .snappy(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

private struct AttachmentPreview: View {
    let attachment: ChatAttachment
    let onRemove: () -> Void
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if attachment.isImage, let image = UIImage(data: attachment.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .glassEffect(in: .rect(cornerRadius: 8))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: attachment.attachmentType?.systemImage ?? "doc")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                    )
            }

            Button(action: {
                HapticService.impact(.light)
                onRemove()
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            })
            .offset(x: 4, y: -4)
        }
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }
}

#if DEBUG
struct MessageComposer_Previews: PreviewProvider {
    static var previews: some View {
        MessageComposer(
            text: .constant(""),
            attachments: .constant([]),
            isRecording: false,
            waveform: [],
            onSend: {},
            onVoiceToggle: {}
        )
        .padding()
        .background(Color.clear)
    }
}
#endif

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
                attachmentMenu
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)

                if isRecording {
                    recordingView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    textInputView
                }

                Button(action: {
                    HapticService.impact(.light)
                    canSend ? onSend() : onVoiceToggle()
                }) {
                    Image(systemName: canSend ? "arrow.up.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(
                            canSend ? AnyShapeStyle(gradientManager.currentGradient(for: colorScheme)) : AnyShapeStyle(Color.secondary)
                        )
                        .animation(MotionToken.standardSpring, value: canSend)
                        .scaleEffect(canSend ? 1.1 : 1.0)
                }
                .disabled(isRecording && !canSend)
                .scaleEffect(animateIn ? 1 : 0.8)
                .opacity(animateIn ? 1 : 0)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.2)) {
                animateIn = true
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

    private var attachmentMenu: some View {
        Menu(content: {
            Button(action: { 
                HapticService.selection()
                showAttachmentPicker = true 
            }) {
                Label("Photo", systemImage: "photo")
            }
        }, label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
        })
    }

    private var textInputView: some View {
        TextField("Message your coach...", text: $text, axis: .vertical)
            .font(.system(size: 16, weight: .light))
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .focused($isTextFieldFocused)
            .onSubmit { 
                if canSend { 
                    HapticService.impact(.light)
                    onSend() 
                } 
            }
            .opacity(animateIn ? 1 : 0)
            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)
    }

    private var recordingView: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: {
                HapticService.impact(.light)
                onVoiceToggle()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.secondary)
            }

            VoiceWaveformView(levels: waveform)
                .frame(height: 30)

            RecordingIndicator()
        }
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
}

private struct VoiceWaveformView: View {
    let levels: [Float]
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(gradientManager.currentGradient(for: colorScheme))
                        .frame(width: 3, height: CGFloat(level) * geometry.size.height)
                        .opacity(0.6 + Double(level) * 0.4)
                        .animation(
                            MotionToken.standardSpring.delay(Double(index) * 0.01),
                            value: level
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct RecordingIndicator: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(pulseScale)
                .opacity(isAnimating ? 0 : 0.5)
            
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .onAppear { 
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
                pulseScale = 2.0
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
                    .fill(.ultraThinMaterial)
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
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            }
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

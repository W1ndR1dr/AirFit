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
            if !attachments.isEmpty {
                attachmentsPreview
                    .padding(.bottom, AppSpacing.small)
            }

            HStack(alignment: .bottom, spacing: AppSpacing.small) {
                attachmentMenu

                if isRecording {
                    recordingView
                } else {
                    textInputView
                }

                Button(action: canSend ? onSend : onVoiceToggle) {
                    Image(systemName: canSend ? "arrow.up.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? .accent : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: canSend)
                }
                .disabled(isRecording && !canSend)
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(
                Capsule()
                    .fill(AppColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            )
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
        Menu {
            Button(action: { showAttachmentPicker = true }) {
                Label("Photo", systemImage: "photo")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.accent)
        }
    }

    private var textInputView: some View {
        TextField("Message your coach...", text: $text, axis: .vertical)
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .focused($isTextFieldFocused)
            .onSubmit { if canSend { onSend() } }
    }

    private var recordingView: some View {
        HStack(spacing: AppSpacing.small) {
            Button(action: onVoiceToggle) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }

            VoiceWaveformView(levels: waveform)
                .frame(height: 30)

            RecordingIndicator()
        }
    }

    private var attachmentsPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.small) {
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

private struct VoiceWaveformView: View {
    let levels: [Float]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.accentColor)
                        .frame(width: 3, height: CGFloat(level) * geometry.size.height)
                        .animation(.easeInOut(duration: 0.1), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct RecordingIndicator: View {
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

private struct AttachmentPreview: View {
    let attachment: ChatAttachment
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if attachment.isImage, let image = UIImage(data: attachment.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.backgroundSecondary)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: attachment.attachmentType?.systemImage ?? "doc")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    )
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .offset(x: 4, y: -4)
        }
    }
}

#if DEBUG
#Preview {
    struct Wrapper: View {
        @State var text = ""
        @State var attachments: [ChatAttachment] = []
        var body: some View {
            MessageComposer(
                text: $text,
                attachments: $attachments,
                isRecording: false,
                waveform: [],
                onSend: {},
                onVoiceToggle: {}
            )
        }
    }
    return Wrapper()
        .padding()
        .background(Color.backgroundPrimary)
}
#endif

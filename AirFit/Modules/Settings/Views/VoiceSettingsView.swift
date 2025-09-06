import SwiftUI
import AVFoundation

/// Settings screen for managing voice transcription and Whisper models
struct VoiceSettingsView: View {
    @EnvironmentObject private var whisperManager: WhisperModelManager
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedModelSize: WhisperModelManager.ModelSize = .large
    @State private var showingDeleteConfirmation = false
    @State private var showingTestView = false
    @State private var downloadError: Error?
    @State private var testTranscription = ""

    private var modelState: WhisperModelManager.ModelState {
        whisperManager.modelState
    }

    private var storageUsed: String {
        let bytes = whisperManager.calculateStorageUsed()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    var body: some View {
        NavigationStack {
            List {
                // Current Status Section
                Section {
                    HStack {
                        Label("Status", systemImage: "info.circle.fill")
                            .foregroundStyle(.secondary)

                        Spacer()

                        statusView
                    }

                    if case .ready = modelState {
                        HStack {
                            Label("Model", systemImage: "cube.box.fill")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(whisperManager.currentModelSize.displayName)
                                .foregroundStyle(.primary)
                        }

                        HStack {
                            Label("Storage", systemImage: "internaldrive.fill")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(storageUsed)
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    Text("Voice Transcription")
                }

                // Model Management Section
                Section {
                    if case .notDownloaded = modelState {
                        // Model selection
                        ForEach(WhisperModelManager.ModelSize.allCases, id: \.self) { size in
                            modelOptionRow(size)
                        }

                        // Download button
                        Button(action: {
                            Task {
                                await downloadModel()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Download \(selectedModelSize.displayName)")
                                Spacer()
                            }
                            .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                        }
                    } else if case .downloading(let progress) = modelState {
                        // Download progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Downloading...")
                                Spacer()
                                Text("\(Int(progress * 100))%")
                            }
                            .font(.subheadline)

                            ProgressView(value: progress)
                                .tint(gradientManager.active.colors(for: colorScheme)[0])
                        }
                        .padding(.vertical, 4)

                        // Cancel button
                        Button(action: {
                            Task {
                                await cancelDownload()
                            }
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Cancel Download")
                                Spacer()
                            }
                            .foregroundStyle(.red)
                        }
                    } else if case .ready = modelState {
                        // Delete model button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Model")
                                Spacer()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Model Management")
                } footer: {
                    modelFooterText
                }

                // Test Section
                if case .ready = modelState {
                    Section {
                        Button(action: {
                            showingTestView = true
                        }) {
                            HStack {
                                Image(systemName: "mic.circle.fill")
                                Text("Test Voice Transcription")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.primary)
                        }

                        if !testTranscription.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last transcription:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(testTranscription)
                                    .font(.body)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    } header: {
                        Text("Testing")
                    }
                }

                // Advanced Settings
                Section {
                    // Language selection (future feature)
                    HStack {
                        Label("Language", systemImage: "globe")
                        Spacer()
                        Text("English")
                            .foregroundStyle(.secondary)
                    }
                    .opacity(0.5)

                    // Auto-punctuation toggle (future feature)
                    Toggle(isOn: .constant(true)) {
                        Label("Auto-punctuation", systemImage: "text.quote")
                    }
                    .disabled(true)
                    .opacity(0.5)
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("More options coming soon")
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert("Delete Model?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteModel()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will free up \(storageUsed) of storage. You can download the model again later.")
        }
        .sheet(isPresented: $showingTestView) {
            TestTranscriptionSheet(onTranscription: { text in
                testTranscription = text
            })
            .environmentObject(whisperManager)
            .environmentObject(gradientManager)
        }
        .alert("Download Error", isPresented: .constant(downloadError != nil)) {
            Button("OK") {
                downloadError = nil
            }
        } message: {
            if let error = downloadError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private var statusView: some View {
        switch modelState {
        case .notDownloaded:
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle")
                Text("Not Downloaded")
            }
            .foregroundStyle(.orange)
            .font(.subheadline)

        case .downloading:
            HStack(spacing: 4) {
                TextLoadingView(message: "Downloading", style: .subtle)
                Text("Downloading...")
            }
            .foregroundStyle(.blue)
            .font(.subheadline)

        case .downloaded, .loading:
            HStack(spacing: 4) {
                TextLoadingView(message: "Loading", style: .subtle)
                Text("Loading...")
            }
            .foregroundStyle(.orange)
            .font(.subheadline)

        case .ready:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text("Ready")
            }
            .foregroundStyle(.green)
            .font(.subheadline)

        case .error:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Error")
            }
            .foregroundStyle(.red)
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private func modelOptionRow(_ size: WhisperModelManager.ModelSize) -> some View {
        Button(action: {
            selectedModelSize = size
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(size.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(modelDescription(for: size))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedModelSize == size {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(gradientManager.currentGradient(for: colorScheme))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var modelFooterText: Text {
        switch modelState {
        case .notDownloaded:
            return Text("Models are downloaded on-demand and stored locally for offline use.")
        case .downloading:
            return Text("Download will continue in background. You can close this screen.")
        case .ready:
            return Text("Model is ready for voice transcription. Works completely offline.")
        default:
            return Text("")
        }
    }

    // MARK: - Actions

    private func downloadModel() async {
        downloadError = nil

        do {
            try await whisperManager.downloadModel(selectedModelSize)
            HapticService.notification(.success)
        } catch {
            downloadError = error
            HapticService.notification(.error)
        }
    }

    private func cancelDownload() async {
        whisperManager.cancelDownload()
        HapticService.notification(.warning)
    }

    private func deleteModel() async {
        do {
            try await whisperManager.deleteModel(selectedModelSize)
            HapticService.notification(.success)
        } catch {
            downloadError = error
            HapticService.notification(.error)
        }
    }

    private func modelDescription(for size: WhisperModelManager.ModelSize) -> String {
        switch size {
        case .tiny:
            return "Fastest, lower accuracy (~39MB)"
        case .base:
            return "Balanced speed and accuracy (~74MB)"
        case .small:
            return "Good accuracy (~244MB)"
        case .medium:
            return "Better accuracy (~769MB)"
        case .large:
            return "Best accuracy, Q4 quantized (~400MB)"
        }
    }
}

// MARK: - Test Transcription Sheet

private struct TestTranscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    let onTranscription: (String) -> Void

    @State private var transcribedText = ""
    @State private var isShowingResult = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                // Voice button
                VStack(spacing: 20) {
                    Text("Tap and speak to test")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    // Using our WhisperVoiceButton
                    TextField("Your transcription will appear here", text: $transcribedText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .overlay(alignment: .bottomTrailing) {
                            WhisperVoiceButton(text: $transcribedText)
                                .padding(8)
                        }
                        .padding(.horizontal)
                }

                if !transcribedText.isEmpty {
                    VStack(spacing: 16) {
                        Text("Transcription successful!")
                            .font(.headline)
                            .foregroundStyle(.green)

                        Button("Save Test") {
                            onTranscription(transcribedText)
                            dismiss()
                        }
                        .buttonStyle(.softPrimary)
                    }
                    .transition(.opacity)
                }

                Spacer()
            }
            .navigationTitle("Test Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(!transcribedText.isEmpty)
        .animation(.easeInOut, value: transcribedText)
    }
}

// MARK: - Preview

#Preview {
    VoiceSettingsView()
        .environmentObject(WhisperModelManager())
        .environmentObject(GradientManager())
}

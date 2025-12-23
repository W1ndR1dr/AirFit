import SwiftUI

/// Sheet shown when user tries to use voice input without models downloaded
struct ModelRequiredSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var modelManager = ModelManager.shared
    @AppStorage("speechWifiOnly") private var wifiOnly = true

    /// Called when download completes and user can proceed
    var onReady: (() -> Void)?

    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var showTechDetails = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Icon with privacy shield
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.12))
                        .frame(width: 100, height: 100)

                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accent)

                    // Privacy badge
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.success)
                        .background(
                            Circle()
                                .fill(Theme.background)
                                .frame(width: 28, height: 28)
                        )
                        .offset(x: 35, y: 35)
                }

                // Title & Description
                VStack(spacing: 12) {
                    Text("Private Voice Input")
                        .font(.headlineLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Text("Enable on-device speech recognition. Your voice is processed entirely on your phone and never sent to the cloud.")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Device optimization info
                if let recommendation = modelManager.recommendation {
                    VStack(spacing: 16) {
                        // Device tagline with info button
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Theme.success)
                            Text(recommendation.deviceTagline)
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()

                            // Info button for power users
                            Button {
                                showTechDetails = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                        .padding()
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))

                        // Single model - just show download status
                        if let model = recommendation.requiredModels.first {
                            SimpleDownloadRow(
                                progress: modelManager.downloadProgress[model.id],
                                size: model.formattedSize
                            )
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Download info - friendly format
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(Theme.textMuted)
                            Text("One-time download:")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                            Text(recommendation.formattedRequiredSize)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.textSecondary)

                            if wifiOnly {
                                Text("• Wi-Fi only")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Error message
                if let error = modelManager.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.error)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.error)
                    }
                    .padding()
                    .background(Theme.error.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Actions
                VStack(spacing: 12) {
                    if downloadComplete {
                        Button {
                            dismiss()
                            onReady?()
                        } label: {
                            Label("Ready to Go", systemImage: "checkmark.circle.fill")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.success, in: RoundedRectangle(cornerRadius: 16))
                        }
                    } else if isDownloading {
                        Button {
                            Task {
                                await modelManager.cancelAllDownloads()
                                isDownloading = false
                            }
                        } label: {
                            Text("Cancel")
                                .font(.bodyLarge)
                                .foregroundStyle(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button {
                            startDownload()
                        } label: {
                            Label("Set Up Now", systemImage: "arrow.down.circle.fill")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Maybe Later")
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .sheet(isPresented: $showTechDetails) {
                TechDetailsSheet(recommendation: modelManager.recommendation)
            }
        }
        .task {
            await modelManager.load()
        }
        .onChange(of: modelManager.isDownloading) { _, newValue in
            if !newValue && isDownloading {
                // Download finished
                Task {
                    await checkDownloadComplete()
                }
            }
        }
    }

    private func startDownload() {
        isDownloading = true
        Task {
            await modelManager.downloadRecommendedModels(wifiOnly: wifiOnly)
            await checkDownloadComplete()
        }
    }

    @MainActor
    private func checkDownloadComplete() async {
        let hasModels = await modelManager.hasRequiredModels()
        if hasModels {
            downloadComplete = true
            isDownloading = false
        }
    }
}

// MARK: - Simple Download Row

private struct SimpleDownloadRow: View {
    let progress: Double?
    let size: String

    private var isComplete: Bool {
        (progress ?? 0) >= 1.0
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "arrow.down.circle")
                    .foregroundStyle(isComplete ? Theme.success : Theme.accent)

                Text(isComplete ? "Ready" : "Downloading...")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text(size)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            if let progress, !isComplete {
                ProgressView(value: progress)
                    .tint(Theme.accent)
            }
        }
    }
}

// MARK: - Normie-Friendly Model Row

private struct NormieModelRow: View {
    let model: ModelDescriptor
    let progress: Double?
    let details: ModelDownloadProgress?

    @State private var showCheckmark = false
    @State private var displayProgress: Double = 0

    private var isComplete: Bool {
        (progress ?? 0) >= 1.0
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Purpose icon (changes to checkmark when complete)
                ZStack {
                    Circle()
                        .fill(isComplete ? Theme.success.opacity(0.12) : Theme.accent.opacity(0.12))
                        .frame(width: 36, height: 36)

                    if showCheckmark {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.success)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: model.purpose.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCheckmark)

                // Name and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Text(model.purpose.description)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                // Status indicator
                if progress != nil {
                    if isComplete {
                        Text("Ready")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.success)
                            .transition(.opacity)
                    } else {
                        Text("\(Int(displayProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.accent)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                }
            }

            // Progress bar (only shown during download)
            if progress != nil, !isComplete {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.textMuted.opacity(0.2))
                            .frame(height: 4)

                        // Progress fill - uses smoothed displayProgress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * displayProgress, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.leading, 48) // Align with text
            }
        }
        .onChange(of: progress) { _, newProgress in
            guard let newProgress else { return }
            // Smoothly animate to new progress value
            withAnimation(.easeInOut(duration: 0.4)) {
                displayProgress = newProgress
            }
        }
        .onChange(of: isComplete) { _, newValue in
            if newValue {
                // Trigger checkmark animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showCheckmark = true
                    displayProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Tech Details Sheet (for power users)

private struct TechDetailsSheet: View {
    let recommendation: ModelRecommendation?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let rec = recommendation {
                        // Device section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Device Analysis", systemImage: "cpu")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(label: "Model", value: rec.deviceInfo.identifier)
                                DetailRow(label: "Marketing Name", value: rec.deviceInfo.marketingName)
                                DetailRow(label: "RAM", value: "\(rec.deviceInfo.ramGB) GB")
                                DetailRow(label: "Performance Tier", value: rec.canRunHighQuality ? "High" : "Standard")
                            }
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Model selection rationale
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Model Selection", systemImage: "brain.head.profile")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            Text(rec.optimizationExplanation)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(rec.requiredModels) { model in
                                    TechModelDetail(model: model)
                                }
                            }
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Two-stage pipeline explanation
                        VStack(alignment: .leading, spacing: 12) {
                            Label("How It Works", systemImage: "arrow.triangle.2.circlepath")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            Text("AirFit uses a two-stage transcription pipeline for the best experience:")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            VStack(alignment: .leading, spacing: 12) {
                                PipelineStep(
                                    number: 1,
                                    title: "Live Preview",
                                    description: "Small, fast model runs continuously while you speak, showing words in real-time (~200ms latency)."
                                )

                                PipelineStep(
                                    number: 2,
                                    title: "Final Polish",
                                    description: "When you stop speaking, a larger model processes the full audio for maximum accuracy and proper punctuation."
                                )
                            }
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // WhisperKit info
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Technology", systemImage: "hammer.fill")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Powered by WhisperKit")
                                    .font(.bodyMedium)
                                    .foregroundStyle(Theme.textPrimary)

                                Text("WhisperKit is an optimized CoreML implementation of OpenAI's Whisper speech recognition model, designed specifically for Apple Silicon. All processing happens on-device using the Neural Engine.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)

                                Link(destination: URL(string: "https://github.com/argmaxinc/WhisperKit")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.right.square")
                                        Text("View on GitHub")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(Theme.accent)
                                }
                            }
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Technical Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Theme.textPrimary)
                .fontDesign(.monospaced)
        }
    }
}

private struct TechModelDetail: View {
    let model: ModelDescriptor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: model.purpose.icon)
                    .foregroundStyle(Theme.accent)
                Text(model.displayName)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(model.formattedSize)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Folder: \(model.folderName)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
                    .fontDesign(.monospaced)

                Text("WhisperKit ID: \(model.whisperKitModel)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
                    .fontDesign(.monospaced)

                Text("Min RAM: \(model.minRAMGB) GB")
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}

private struct PipelineStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 24, height: 24)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ModelRequiredSheet()
}

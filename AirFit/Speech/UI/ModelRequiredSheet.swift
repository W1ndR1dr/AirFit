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
    @State private var showCellularConfirmation = false

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
                    Text("Private Voice Dictation")
                        .font(.headlineLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Text("Your voice stays on your phone. We run one on-device model for fast, private transcription.")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Device optimization info
                if let recommendation = modelManager.recommendation {
                    let mode = modelManager.currentQualityMode()
                    let model = recommendation.model(for: mode)
                    VStack(spacing: 16) {
                        // Device tagline with info button
                        VStack(alignment: .leading, spacing: 8) {
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

                            HStack(spacing: 8) {
                                Image(systemName: mode.iconName)
                                    .foregroundStyle(Theme.accent)
                                Text(mode.displayName)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .padding()
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))

                        // Single model - just show download status
                        let isInstalled = modelManager.installedModels.contains { $0.descriptor.id == model.id }
                        SimpleDownloadRow(
                            title: model.displayName,
                            progress: modelManager.downloadProgress[model.id],
                            size: model.formattedSize,
                            isInstalled: isInstalled
                        )
                        .padding()
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))

                        // Download info - friendly format
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundStyle(Theme.textMuted)
                            Text("One-time download:")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                            Text(model.formattedSize)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.textSecondary)

                            if wifiOnly {
                                Text("• Wi-Fi only")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }

                        Text("Change quality mode in Settings → Speech Recognition.")
                            .font(.caption2)
                            .foregroundStyle(Theme.textMuted)
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
                            Label("Ready to Dictate", systemImage: "checkmark.circle.fill")
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
                            Label("Download Model", systemImage: "arrow.down.circle.fill")
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
                TechDetailsSheet(
                    recommendation: modelManager.recommendation,
                    selectedMode: modelManager.currentQualityMode()
                )
            }
            .confirmationDialog(
                "Download Over Cellular?",
                isPresented: $showCellularConfirmation
            ) {
                Button("Download Anyway") {
                    isDownloading = true
                    Task {
                        await modelManager.downloadRecommendedModels()
                        await checkDownloadComplete()
                    }
                }
                Button("Wait for Wi-Fi", role: .cancel) {}
            } message: {
                if let model = modelManager.recommendation?.model(for: modelManager.currentQualityMode()) {
                    Text("You're not connected to Wi-Fi. Downloading will use \(model.formattedSize) of cellular data.")
                }
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
        let result = modelManager.attemptDownloadRecommendedModels(wifiOnly: wifiOnly)
        switch result {
        case .started:
            isDownloading = true
        case .needsCellularConfirmation:
            showCellularConfirmation = true
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
    let title: String
    let progress: Double?
    let size: String
    let isInstalled: Bool

    private var isComplete: Bool {
        isInstalled || (progress ?? 0) >= 1.0
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "arrow.down.circle")
                    .foregroundStyle(isComplete ? Theme.success : Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

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

    private var statusText: String {
        if isComplete {
            return "Ready"
        }
        return progress == nil ? "Not installed" : "Downloading..."
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
    let selectedMode: ModelRecommendation.QualityMode
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
                                TechModelDetail(model: rec.model(for: selectedMode))
                            }
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Single-pass explanation
                        VStack(alignment: .leading, spacing: 12) {
                            Label("How It Works", systemImage: "waveform")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            Text("AirFit records your voice, then transcribes the full clip in a single pass for accuracy and punctuation.")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            VStack(alignment: .leading, spacing: 8) {
                                DetailBullet(
                                    title: "Single-pass transcription",
                                    description: "One model handles the full clip to keep results consistent."
                                )
                                DetailBullet(
                                    title: "On-device processing",
                                    description: "No audio leaves your phone."
                                )
                                DetailBullet(
                                    title: "Optimized per device",
                                    description: "Auto mode chooses the best balance for your hardware."
                                )
                            }
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Quality modes
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Quality Modes", systemImage: "slider.horizontal.3")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            Text("Pick your preferred balance of accuracy, speed, and heat.")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(ModelRecommendation.QualityMode.allCases, id: \.rawValue) { mode in
                                    let model = rec.model(for: mode)
                                    QualityModeDetail(
                                        mode: mode,
                                        model: model,
                                        isSelected: mode == selectedMode
                                    )
                                }
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

                                Text("WhisperKit runs CoreML-optimized Whisper models on-device. Audio never leaves your phone, and the Neural Engine is used when available.")
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

                        // MLX options (Mac reference)
                        VStack(alignment: .leading, spacing: 12) {
                            Label("MLX Options (Mac)", systemImage: "laptopcomputer")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            Text("For Mac apps or desktop workflows, MLX offers optimized Whisper variants. AirFit on iPhone uses CoreML via WhisperKit.")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            VStack(alignment: .leading, spacing: 8) {
                                MLXOptionRow(
                                    title: "mlx-community/whisper-large-v3-turbo",
                                    description: "Fastest top-tier accuracy on Apple silicon."
                                )
                                MLXOptionRow(
                                    title: "mlx-community/whisper-large-v3-mlx",
                                    description: "Best quality, higher memory use."
                                )
                                MLXOptionRow(
                                    title: "mlx-community/whisper-medium.en-mlx",
                                    description: "Balanced speed and quality."
                                )
                            }
                            .padding()
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))

                            Link(destination: URL(string: "https://github.com/ml-explore/mlx-examples")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.square")
                                    Text("MLX Whisper examples")
                                }
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                            }
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

private struct DetailBullet: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

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

private struct MLXOptionRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.textPrimary)
                .fontDesign(.monospaced)

            Text(description)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

private struct QualityModeDetail: View {
    let mode: ModelRecommendation.QualityMode
    let model: ModelDescriptor
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: mode.iconName)
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? Theme.accent : Theme.textMuted)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(mode.displayName)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.textPrimary)

                    if isSelected {
                        Text("Selected")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent, in: Capsule())
                    }
                }

                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                Text("\(model.displayName) • \(model.formattedSize)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textMuted)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ModelRequiredSheet()
}

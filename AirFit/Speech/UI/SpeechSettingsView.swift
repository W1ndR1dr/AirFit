import SwiftUI

/// Settings screen for managing WhisperKit speech recognition models
struct SpeechSettingsView: View {
    @State private var modelManager = ModelManager.shared
    @AppStorage("speechWifiOnly") private var wifiOnly = true
    @AppStorage("speechQualityMode") private var qualityModeRaw = ModelRecommendation.QualityMode.auto.rawValue
    @AppStorage("speechBatteryMode") private var legacyBatteryMode = false

    @State private var showDeleteConfirmation = false
    @State private var modelToDelete: ModelDescriptor?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                deviceSection
                installedModelsSection
                availableModelsSection
                settingsSection
            }
            .padding()
        }
        .navigationTitle("Speech Recognition")
        .background(Theme.background)
        .task {
            await modelManager.load()
            migrateLegacyQualityModeIfNeeded()
        }
        .confirmationDialog(
            "Delete Model?",
            isPresented: $showDeleteConfirmation,
            presenting: modelToDelete
        ) { model in
            Button("Delete \(model.displayName)", role: .destructive) {
                Task {
                    await modelManager.deleteModel(model)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { model in
            Text("This will free \(model.formattedSize) of storage.")
        }
    }

    // MARK: - Device Section

    private var deviceSection: some View {
        SettingsSectionCard(title: "Your Device") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "iphone")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(modelManager.recommendation?.deviceInfo.marketingName ?? "Detecting...")
                            .font(.headlineMedium)
                            .foregroundStyle(Theme.textPrimary)

                        Text("\(modelManager.recommendation?.deviceInfo.ramGB ?? 0) GB RAM")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Spacer()

                    qualityModeBadge
                }
            }
        }
    }

    // MARK: - Installed Models Section

    private var installedModelsSection: some View {
        SettingsSectionCard(title: "Installed Models") {
            if modelManager.installedModels.isEmpty {
                HStack {
                    Image(systemName: "square.stack.3d.up.slash")
                        .foregroundStyle(Theme.textMuted)
                    Text("No models installed")
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(modelManager.installedModels, id: \.descriptor.id) { installed in
                        InstalledModelRow(
                            model: installed.descriptor,
                            size: ByteCountFormatter.string(fromByteCount: installed.actualSizeBytes, countStyle: .file),
                            isRecommended: isRecommended(installed.descriptor),
                            onDelete: {
                                modelToDelete = installed.descriptor
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Available Models Section

    private var availableModelsSection: some View {
        SettingsSectionCard(title: "Available Models") {
            VStack(spacing: 12) {
                ForEach(ModelCatalog.allModels) { model in
                    let isInstalled = modelManager.installedModels.contains { $0.descriptor.id == model.id }
                    let isDownloading = modelManager.downloadProgress[model.id] != nil
                    let progress = modelManager.downloadProgress[model.id] ?? 0

                    if !isInstalled {
                        AvailableModelRow(
                            model: model,
                            isRecommended: isRecommended(model),
                            isDownloading: isDownloading,
                            progress: progress,
                            progressDetails: modelManager.downloadDetails[model.id],
                            onDownload: {
                                Task {
                                    await modelManager.downloadModel(model, wifiOnly: wifiOnly)
                                }
                            },
                            onCancel: {
                                Task {
                                    await modelManager.cancelDownload(model.id)
                                }
                            }
                        )
                    }
                }

                if modelManager.installedModels.count == ModelCatalog.allModels.count {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.success)
                        Text("All models installed")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textMuted)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        SettingsSectionCard(title: "Settings") {
            VStack(spacing: 16) {
                // Wi-Fi Only Toggle
                Toggle(isOn: $wifiOnly) {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wi-Fi Only Downloads")
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Save cellular data")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                }
                .tint(Theme.accent)

                Divider()

                qualityModePicker
            }
        }
    }

    // MARK: - Helpers

    private var qualityMode: ModelRecommendation.QualityMode {
        ModelRecommendation.QualityMode(rawValue: qualityModeRaw) ?? .auto
    }

    private var qualityModeBadge: some View {
        let mode = qualityMode
        let badgeColor = badgeColor(for: mode)
        return Label(badgeText(for: mode), systemImage: mode.iconName)
            .font(.caption)
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.12), in: Capsule())
    }

    private var qualityModePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Theme.accent)
                Text("Quality Mode")
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
            }

            VStack(spacing: 10) {
                ForEach(ModelRecommendation.QualityMode.allCases, id: \.rawValue) { mode in
                    let model = modelManager.recommendation?.model(for: mode)
                    Button {
                        qualityModeRaw = mode.rawValue
                    } label: {
                        QualityModeRow(
                            mode: mode,
                            model: model,
                            isSelected: qualityMode == mode
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func isRecommended(_ model: ModelDescriptor) -> Bool {
        guard let rec = modelManager.recommendation else { return false }
        let required = rec.modelsRequired(for: modelManager.currentQualityMode())
        return required.contains(where: { $0.id == model.id })
    }

    private func migrateLegacyQualityModeIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "speechQualityMode") == nil else { return }
        qualityModeRaw = legacyBatteryMode ? ModelRecommendation.QualityMode.batterySaver.rawValue
            : ModelRecommendation.QualityMode.auto.rawValue
    }

    private func badgeText(for mode: ModelRecommendation.QualityMode) -> String {
        mode.displayName
    }

    private func badgeColor(for mode: ModelRecommendation.QualityMode) -> Color {
        switch mode {
        case .auto: return Theme.accent
        case .highQuality: return Theme.accent
        case .batterySaver: return Theme.secondary
        case .fast: return Theme.textMuted
        }
    }
}

// MARK: - Section Card

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                .tracking(1)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Installed Model Row

private struct InstalledModelRow: View {
    let model: ModelDescriptor
    let size: String
    let isRecommended: Bool
    let onDelete: () -> Void

    @State private var showingTooltip = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .font(.headlineMedium)
                        .foregroundStyle(Theme.textPrimary)

                    if isRecommended {
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent, in: Capsule())
                    }

                    // Info button for tooltip
                    Button {
                        showingTooltip = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Text(model.subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 8) {
                    if let badge = model.languageBadge {
                        Text(badge)
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.12), in: Capsule())
                    }

                    Text(size)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(Theme.error.opacity(0.8))
            }
        }
        .padding(.vertical, 6)
        .alert("About \(model.displayName)", isPresented: $showingTooltip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.description)
        }
    }
}

// MARK: - Available Model Row

private struct AvailableModelRow: View {
    let model: ModelDescriptor
    let isRecommended: Bool
    let isDownloading: Bool
    let progress: Double
    let progressDetails: ModelDownloadProgress?
    let onDownload: () -> Void
    let onCancel: () -> Void

    @State private var showingTooltip = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.headlineMedium)
                            .foregroundStyle(Theme.textPrimary)

                        if isRecommended {
                            Text("Recommended")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent, in: Capsule())
                        }

                        // Info button for tooltip
                        Button {
                            showingTooltip = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }

                    Text(model.subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)

                    HStack(spacing: 8) {
                        if let badge = model.languageBadge {
                            Text(badge)
                                .font(.caption2)
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.12), in: Capsule())
                        }

                        Text(model.formattedSize)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Spacer()

                if isDownloading {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.textMuted)
                    }
                } else {
                    Button {
                        onDownload()
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }

            if isDownloading {
                VStack(spacing: 4) {
                    ProgressView(value: progress)
                        .tint(Theme.accent)

                    if let details = progressDetails {
                        Text(details.formattedProgress)
                            .font(.caption2)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .alert("About \(model.displayName)", isPresented: $showingTooltip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.description)
        }
    }
}

// MARK: - Quality Mode Row

private struct QualityModeRow: View {
    let mode: ModelRecommendation.QualityMode
    let model: ModelDescriptor?
    let isSelected: Bool

    @State private var showingTooltip = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isSelected ? Theme.accent : Theme.textMuted)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(mode.displayName)
                        .font(.headlineMedium)
                        .foregroundStyle(Theme.textPrimary)

                    if mode == .auto {
                        Text(mode.subtitle)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.12), in: Capsule())
                    }

                    // Info button for tooltip
                    Button {
                        showingTooltip = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                if mode != .auto {
                    Text(mode.subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Text(mode.description)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(2)

                if let model {
                    HStack(spacing: 6) {
                        if let badge = model.languageBadge {
                            Text(badge)
                                .font(.caption2)
                                .foregroundStyle(Theme.accent)
                        }
                        Text(model.formattedSize)
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Theme.accent.opacity(0.10) : Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.textMuted.opacity(0.12), lineWidth: 1.5)
        )
        .alert("About \(mode.displayName) Mode", isPresented: $showingTooltip) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mode.tooltip)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SpeechSettingsView()
    }
}

import SwiftUI

/// Settings screen for managing WhisperKit speech recognition models
struct SpeechSettingsView: View {
    @State private var modelManager = ModelManager.shared
    @AppStorage("speechWifiOnly") private var wifiOnly = true
    @AppStorage("speechBatteryMode") private var batteryMode = false

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

                    if modelManager.canRunHighQuality {
                        Label("High Quality", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.accent.opacity(0.12), in: Capsule())
                    } else {
                        Label("Balanced", systemImage: "leaf.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.secondary.opacity(0.12), in: Capsule())
                    }
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

                // Battery Saver Mode
                Toggle(isOn: $batteryMode) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Theme.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Battery Saver Mode")
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Text("Uses lighter model for cooler operation")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                }
                .tint(Theme.accent)
                .disabled(!modelManager.canRunHighQuality)
            }
        }
    }

    // MARK: - Helpers

    private func isRecommended(_ model: ModelDescriptor) -> Bool {
        guard let rec = modelManager.recommendation else { return false }
        return rec.requiredModels.contains(where: { $0.id == model.id })
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

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textPrimary)

                    if isRecommended {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                    }
                }

                HStack(spacing: 8) {
                    Label(model.purpose.displayName, systemImage: purposeIcon)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)

                    Text("•")
                        .foregroundStyle(Theme.textMuted)

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
                    .foregroundStyle(Theme.error)
            }
        }
        .padding(.vertical, 4)
    }

    private var purposeIcon: String {
        model.purpose == .realtime ? "bolt.fill" : "sparkles"
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

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.bodyMedium)
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
                    }

                    HStack(spacing: 8) {
                        Label(model.purpose.displayName, systemImage: purposeIcon)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)

                        Text("•")
                            .foregroundStyle(Theme.textMuted)

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
        .padding(.vertical, 4)
    }

    private var purposeIcon: String {
        model.purpose == .realtime ? "bolt.fill" : "sparkles"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SpeechSettingsView()
    }
}

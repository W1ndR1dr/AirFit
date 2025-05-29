import SwiftUI

struct VoiceSettingsView: View {
    @ObservedObject var modelManager = WhisperModelManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var downloadError: Error?
    @State private var showDeleteConfirmation: String?
    @AppStorage("voice.autoSelectModel") private var autoSelectModel = true
    @AppStorage("voice.downloadCellular") private var downloadCellular = false

    var body: some View {
        NavigationStack {
            List {
                currentModelSection
                availableModelsSection
                storageInfoSection
                advancedSettingsSection
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Model?", isPresented: .init(
                get: { showDeleteConfirmation != nil },
                set: { if !$0 { showDeleteConfirmation = nil } }
            )) {
                Button("Cancel", role: .cancel) { showDeleteConfirmation = nil }
                Button("Delete", role: .destructive) {
                    if let id = showDeleteConfirmation {
                        try? modelManager.deleteModel(id)
                        showDeleteConfirmation = nil
                    }
                }
            } message: {
                Text("This will remove the model from your device. You can download it again later.")
            }
            .alert("Download Error", isPresented: .init(
                get: { downloadError != nil },
                set: { if !$0 { downloadError = nil } }
            )) {
                Button("OK") { downloadError = nil }
            } message: {
                if let error = downloadError {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Sections
    private var currentModelSection: some View {
        Section {
            HStack {
                Label("Active Model", systemImage: "waveform")
                Spacer()
                Text(modelManager.activeModel)
                    .foregroundStyle(.secondary)
            }
            if let active = modelManager.availableModels.first(where: { $0.id == modelManager.activeModel }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accuracy: \(active.accuracy)")
                    Text("Speed: \(active.speed)")
                    Text("Size: \(active.size)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Current Voice Model")
        } footer: {
            Text("The active model is used for voice transcription. Larger models provide better accuracy but use more storage and memory.")
        }
    }

    private var availableModelsSection: some View {
        Section {
            ForEach(modelManager.availableModels) { model in
                ModelRow(
                    model: model,
                    isDownloaded: modelManager.downloadedModels.contains(model.id),
                    isActive: modelManager.activeModel == model.id,
                    isDownloading: modelManager.isDownloading[model.id] ?? false,
                    downloadProgress: modelManager.downloadProgress[model.id] ?? 0,
                    onDownload: {
                        Task {
                            do {
                                try await modelManager.downloadModel(model.id)
                            } catch {
                                downloadError = error
                            }
                        }
                    },
                    onDelete: { showDeleteConfirmation = model.id },
                    onActivate: { modelManager.activeModel = model.id }
                )
            }
        } header: {
            Text("Available Models")
        } footer: {
            Text("Download additional models for better accuracy or different languages. Models are stored locally and work offline.")
        }
    }

    private var storageInfoSection: some View {
        Section {
            StorageInfoView(modelManager: modelManager)
        } header: {
            Text("Storage")
        }
    }

    private var advancedSettingsSection: some View {
        Section {
            Toggle("Auto-Select Best Model", isOn: $autoSelectModel)
            Toggle("Download Over Cellular", isOn: $downloadCellular)
            Button("Clear Model Cache", role: .destructive) {
                Task {
                    do {
                        try modelManager.clearUnusedModels()
                    } catch {
                        AppLogger.error("Failed to clear model cache", error: error, category: .storage)
                    }
                }
            }
        } header: {
            Text("Advanced")
        }
    }
}

// MARK: - Model Row
private struct ModelRow: View {
    let model: WhisperModelManager.WhisperModel
    let isDownloaded: Bool
    let isActive: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    let onDelete: () -> Void
    let onActivate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.headline)
                    HStack(spacing: 12) {
                        Label(model.accuracy, systemImage: "chart.line.uptrend.xyaxis")
                        Label(model.speed, systemImage: "speedometer")
                        Label(model.size, systemImage: "internaldrive")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if isDownloading {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 30, height: 30)
                } else if isDownloaded {
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                    } else {
                        Menu {
                            Button("Use This Model") { onActivate() }
                            Button("Delete", role: .destructive) { onDelete() }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                        }
                    }
                } else {
                    Button(action: onDownload) {
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                    }
                }
            }
            if isDownloading {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: downloadProgress)
                    HStack {
                        Text("Downloading...")
                        Spacer()
                        Text("\(Int(downloadProgress * 100))%")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Storage Info
private struct StorageInfoView: View {
    @ObservedObject var modelManager: WhisperModelManager

    private var totalModelSize: Int {
        modelManager.downloadedModels.compactMap { id in
            modelManager.availableModels.first { $0.id == id }?.sizeBytes
        }.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Models Downloaded")
                Spacer()
                Text("\(modelManager.downloadedModels.count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Total Size")
                Spacer()
                Text(formatBytes(totalModelSize))
                    .foregroundStyle(.secondary)
            }
            if let deviceStorage = getDeviceStorage() {
                HStack {
                    Text("Available Storage")
                    Spacer()
                    Text(formatBytes(deviceStorage.available))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.system(.body, design: .rounded))
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func getDeviceStorage() -> (available: Int, total: Int)? {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let free = attributes[.systemFreeSize] as? Int64,
               let total = attributes[.systemSize] as? Int64 {
                return (available: Int(free), total: Int(total))
            }
        } catch {
            return nil
        }
        return nil
    }
}

import SwiftUI

struct DataManagementView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showExportProgress = false
    @State private var exportURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                exportSection
                exportHistory
                deleteSection
            }
            .padding()
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showExportProgress) {
            DataExportProgressSheet(viewModel: viewModel, exportURL: $exportURL)
        }
        .sheet(item: $exportURL) { url in
            ShareSheet(items: [url])
        }
    }
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Export Your Data", icon: "square.and.arrow.up")
            
            Card {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Export all your AirFit data including workouts, meals, and health metrics in a portable JSON format.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    
                    Button(action: startExport) {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private var exportHistory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Export History", icon: "clock.arrow.circlepath")
            
            if viewModel.exportHistory.isEmpty {
                Card {
                    Text("No previous exports")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
            } else {
                ForEach(viewModel.exportHistory) { export in
                    Card {
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(export.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.callout)
                                
                                Text(ByteCountFormatter().string(fromByteCount: export.size))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "doc.zipper")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "Delete Data", icon: "trash")
            
            Card(style: .destructive) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Delete All Data")
                                .font(.headline)
                                .foregroundStyle(.red)
                            
                            Text("Permanently delete all your AirFit data. This cannot be undone.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    
                    Button(role: .destructive, action: confirmDelete) {
                        Text("Delete Everything")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
    }
    
    private func startExport() {
        showExportProgress = true
        
        Task {
            do {
                let url = try await viewModel.exportUserData()
                await MainActor.run {
                    showExportProgress = false
                    exportURL = url
                    HapticManager.success()
                }
            } catch {
                await MainActor.run {
                    showExportProgress = false
                    viewModel.coordinator.showAlert(.error(message: error.localizedDescription))
                }
            }
        }
    }
    
    private func confirmDelete() {
        viewModel.coordinator.showAlert(.confirmDelete {
            Task {
                try await viewModel.deleteAllData()
            }
        })
    }
}

// MARK: - Data Export Progress Sheet
struct DataExportProgressSheet: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var exportURL: URL?
    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var currentStep = "Preparing export..."
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    VStack {
                        Text("\(Int(progress * 100))%")
                            .font(.title2.bold())
                        Text("Complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(spacing: AppSpacing.sm) {
                    Text("Exporting Your Data")
                        .font(.headline)
                    
                    Text(currentStep)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Export Progress")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            simulateProgress()
        }
    }
    
    private func simulateProgress() {
        Task {
            // Simulate progress steps
            let steps = [
                (0.2, "Gathering user profile..."),
                (0.4, "Exporting workouts..."),
                (0.6, "Exporting nutrition data..."),
                (0.8, "Exporting chat history..."),
                (1.0, "Finalizing export...")
            ]
            
            for (progressValue, step) in steps {
                await MainActor.run {
                    currentStep = step
                    withAnimation {
                        progress = progressValue
                    }
                }
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Export should be done by now
            await MainActor.run {
                dismiss()
            }
        }
    }
}

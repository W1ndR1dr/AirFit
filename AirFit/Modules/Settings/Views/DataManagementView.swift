import SwiftUI

struct DataManagementView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showExportProgress = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        BaseScreen {
            ScrollView {
                VStack(spacing: 0) {
                    // Title header
                    HStack {
                        CascadeText("Data Management")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.lg)

                    VStack(spacing: AppSpacing.xl) {
                        exportSection
                        exportHistory
                        deleteSection
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportProgress) {
            DataExportProgressSheet(viewModel: viewModel, exportURL: $exportURL)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Export Your Data")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Export all your AirFit data including workouts, meals, and health metrics in a portable JSON format.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Button {
                        startExport()
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var exportHistory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Export History")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            if viewModel.exportHistory.isEmpty {
                GlassCard {
                    Text("No previous exports")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
            } else {
                ForEach(viewModel.exportHistory) { export in
                    GlassCard {
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
            HStack {
                Text("Delete Data")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary.opacity(0.8))
                Spacer()
            }

            GlassCard {
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

                    Button {
                        confirmDelete()
                    } label: {
                        Text("Delete Everything")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
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
                    showShareSheet = true
                    HapticService.notification(.success)
                }
            } catch {
                await MainActor.run {
                    showExportProgress = false
                    viewModel.showAlert(.error(message: error.localizedDescription))
                }
            }
        }
    }

    private func confirmDelete() {
        viewModel.showAlert(.confirmDelete {
            Task {
                try await viewModel.deleteAllData()
            }
        })
    }
}

// MARK: - Data Export Progress Sheet
struct DataExportProgressSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Binding var exportURL: URL?
    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var currentStep = "Preparing export..."

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Spacer()

                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
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

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
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

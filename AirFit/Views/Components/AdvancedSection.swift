import SwiftUI

/// Collapsed section for advanced settings, version info, and danger zone.
/// Keeps the main view clean while still providing access to power features.
struct AdvancedSection: View {
    @Binding var isExpanded: Bool
    let serverStatus: ServerInfo?  // Defined in ProfileView.swift
    let onClearHistory: () -> Void
    let onResetProfile: () -> Void
    var onExportProfile: (() -> Void)?
    var onImportProfile: (() -> Void)?
    var onRestartOnboarding: (() -> Void)?

    @State private var showClearHistoryConfirm = false
    @State private var showResetProfileConfirm = false
    @State private var showRestartOnboardingConfirm = false
    @State private var showOnboardingRestarted = false

    // Developer mode toggle (persisted)
    @AppStorage("developerModeEnabled") private var developerModeEnabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button - subtle, centered
            Button {
                withAnimation(.bloom) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Spacer()

                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)

                    Text("Settings & Advanced")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textMuted)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted.opacity(0.6))

                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .background(Theme.textMuted.opacity(0.2))
                        .padding(.horizontal, 16)

                    VStack(spacing: 16) {
                        // Server Configuration (if connected)
                        if let status = serverStatus {
                            serverInfoRow(status)
                        }

                        // Health Permissions
                        permissionsRow

                        // Version Info
                        versionRow

                        // Developer Mode Toggle
                        developerModeRow

                        // Profile Backup
                        if onExportProfile != nil || onImportProfile != nil {
                            profileBackupSection
                        }

                        // Danger Zone
                        dangerZone
                    }
                    .padding(16)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .confirmationDialog(
            "Clear Chat History",
            isPresented: $showClearHistoryConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                onClearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear your conversation history. Your profile and settings will be preserved.")
        }
        .confirmationDialog(
            "Reset Profile",
            isPresented: $showResetProfileConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                onResetProfile()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will erase everything the AI has learned about you. This cannot be undone.")
        }
        .confirmationDialog(
            "Restart Onboarding",
            isPresented: $showRestartOnboardingConfirm,
            titleVisibility: .visible
        ) {
            Button("Restart Setup", role: .destructive) {
                onRestartOnboarding?()
                showOnboardingRestarted = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will take you back through the initial setup flow. Your profile data will be preserved.")
        }
        .alert("Onboarding Restarted", isPresented: $showOnboardingRestarted) {
            Button("OK") {}
        } message: {
            Text("Close and reopen the app to start the setup flow.")
        }
    }

    // MARK: - Server Info Row

    @ViewBuilder
    private func serverInfoRow(_ status: ServerInfo) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 24)

                Text("Server")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.success)
                        .frame(width: 6, height: 6)
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            if !status.availableProviders.isEmpty {
                HStack {
                    Text("Providers:")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                    Text(status.availableProviders.joined(separator: ", "))
                        .font(.caption.monospaced())
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Theme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Permissions Row

    private var permissionsRow: some View {
        Button {
            if let url = URL(string: "x-apple-health://") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.error)
                    .frame(width: 24)

                Text("Health Data Access")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(12)
            .background(Theme.background.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Version Row

    private var versionRow: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundStyle(Theme.textMuted)
                .frame(width: 24)

            Text("Version")
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Text("\(appVersion) (\(buildNumber))")
                .font(.caption.monospaced())
                .foregroundStyle(Theme.textMuted)
        }
        .padding(12)
        .background(Theme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Developer Mode

    private var developerModeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $developerModeEnabled) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(Theme.accent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Developer Mode")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Seeds demo data for testing")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .tint(Theme.accent)
            .sensoryFeedback(.impact(weight: .light), trigger: developerModeEnabled)
        }
        .padding(12)
        .background(Theme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Profile Backup

    private var profileBackupSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Profile Backup")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
            }

            HStack(spacing: 12) {
                // Export button
                if let onExport = onExportProfile {
                    Button {
                        onExport()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline)
                            Text("Export")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }

                // Import button
                if let onImport = onImportProfile {
                    Button {
                        onImport()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.subheadline)
                            Text("Import")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(spacing: 12) {
            // Restart Onboarding (less destructive - at top)
            if onRestartOnboarding != nil {
                Button {
                    showRestartOnboardingConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)

                        Text("Restart Onboarding")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()
                    }
                    .padding(12)
                    .background(Theme.background.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            // Clear Chat History
            Button {
                showClearHistoryConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundStyle(Theme.warning)
                        .frame(width: 24)

                    Text("Clear Chat History")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()
                }
                .padding(12)
                .background(Theme.background.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            // Reset Profile
            Button {
                showResetProfileConfirm = true
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.error)
                        .frame(width: 24)

                    Text("Reset Profile")
                        .font(.subheadline)
                        .foregroundStyle(Theme.error)

                    Spacer()
                }
                .padding(12)
                .background(Theme.error.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Version Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var expanded = true

        var body: some View {
            AdvancedSection(
                isExpanded: $expanded,
                serverStatus: nil,
                onClearHistory: {},
                onResetProfile: {}
            )
            .padding()
            .background(Theme.background)
        }
    }

    return PreviewWrapper()
}

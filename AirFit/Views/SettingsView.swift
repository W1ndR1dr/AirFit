import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // Server state
    @State private var serverStatus: ServerInfo?
    @State private var isLoadingSettings = true

    // Confirmation dialogs
    @State private var showClearChatConfirm = false
    @State private var showClearProfileConfirm = false

    // Appearance
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private let apiClient = APIClient()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Appearance
                SettingsSection(title: "Appearance") {
                    Picker("Appearance", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Server Status
                SettingsSection(title: "Server") {
                    HStack {
                        Text("Status")
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if isLoadingSettings {
                            ProgressView()
                                .tint(Theme.accent)
                        } else if serverStatus != nil {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Theme.success)
                                    .frame(width: 8, height: 8)
                                Text("Connected")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.success)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Theme.error)
                                    .frame(width: 8, height: 8)
                                Text("Disconnected")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.error)
                            }
                        }
                    }

                    if let status = serverStatus {
                        HStack {
                            Text("Host")
                                .font(.body)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(status.host)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                }

                // AI Provider Section
                if let status = serverStatus {
                    SettingsSection(title: "AI Provider") {
                        HStack {
                            Text("Active")
                                .font(.body)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(status.activeProvider.capitalized)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.accent)
                        }

                        ForEach(status.availableProviders, id: \.self) { provider in
                            HStack {
                                Text(provider.capitalized)
                                    .font(.body)
                                    .foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundStyle(Theme.success)
                            }
                        }
                    }

                    // Session Section
                    if let sessionId = status.sessionId {
                        SettingsSection(title: "Session") {
                            HStack {
                                Text("ID")
                                    .font(.body)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(String(sessionId.prefix(8)) + "...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(Theme.textMuted)
                            }

                            if let messageCount = status.messageCount {
                                HStack {
                                    Text("Messages")
                                        .font(.body)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text("\(messageCount)")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }

                            Button {
                                showClearChatConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                    Text("Clear Chat History")
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(Theme.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.error.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(AirFitButtonStyle())
                        }
                    }
                }

                // App Info Section
                SettingsSection(title: "About") {
                    HStack {
                        Text("Version")
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }

                    HStack {
                        Text("Build")
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                // Danger Zone
                SettingsSection(title: "Danger Zone") {
                    Button {
                        showClearProfileConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("Clear All Profile Data")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(Theme.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.error.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(AirFitButtonStyle())

                    Text("This will erase everything the AI has learned about you.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Clear chat history?",
            isPresented: $showClearChatConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                Task { await clearSession() }
            }
        } message: {
            Text("This will start a fresh conversation with the AI coach.")
        }
        .confirmationDialog(
            "Clear all learned data?",
            isPresented: $showClearProfileConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Everything", role: .destructive) {
                Task { await clearProfile() }
            }
        } message: {
            Text("The AI will start fresh and learn about you again through conversation.")
        }
        .task {
            await loadStatus()
        }
        .refreshable {
            await loadStatus()
        }
    }

    // MARK: - Actions

    private func loadStatus() async {
        isLoadingSettings = true
        do {
            serverStatus = try await apiClient.getServerStatus()
        } catch {
            serverStatus = nil
        }
        withAnimation(.easeOut(duration: 0.2)) {
            isLoadingSettings = false
        }
    }

    private func clearSession() async {
        do {
            try await apiClient.clearSession()
            await loadStatus()
        } catch {
            print("Failed to clear session: \(error)")
        }
    }

    private func clearProfile() async {
        do {
            try await apiClient.clearProfile()
            NotificationCenter.default.post(name: .profileReset, object: nil)
            dismiss()
        } catch {
            print("Failed to clear profile: \(error)")
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 12) {
                content()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

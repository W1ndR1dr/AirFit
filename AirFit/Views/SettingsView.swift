import SwiftUI

struct SettingsView: View {
    @State private var serverStatus: ServerInfo?
    @State private var isLoading = true
    @State private var showClearConfirm = false

    private let apiClient = APIClient()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Server Status Section
                SettingsSection(title: "SERVER", icon: "server.rack", color: Theme.tertiary) {
                    HStack {
                        Text("Status")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(Theme.accent)
                        } else if serverStatus != nil {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Theme.success)
                                    .frame(width: 8, height: 8)
                                Text("Connected")
                                    .font(.labelMedium)
                                    .foregroundStyle(Theme.success)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Theme.error)
                                    .frame(width: 8, height: 8)
                                Text("Disconnected")
                                    .font(.labelMedium)
                                    .foregroundStyle(Theme.error)
                            }
                        }
                    }

                    if let status = serverStatus {
                        HStack {
                            Text("Host")
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(status.host)
                                .font(.labelMedium)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                }

                // LLM Provider Section
                if let status = serverStatus {
                    SettingsSection(title: "AI PROVIDER", icon: "brain", color: Theme.accent) {
                        HStack {
                            Text("Active")
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(status.activeProvider.capitalized)
                                .font(.labelLarge)
                                .foregroundStyle(Theme.accent)
                        }

                        ForEach(status.availableProviders, id: \.self) { provider in
                            HStack {
                                Text(provider.capitalized)
                                    .font(.bodyMedium)
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
                        SettingsSection(title: "SESSION", icon: "number", color: Theme.protein) {
                            HStack {
                                Text("ID")
                                    .font(.bodyMedium)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(String(sessionId.prefix(8)) + "...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(Theme.textMuted)
                            }

                            if let messageCount = status.messageCount {
                                HStack {
                                    Text("Messages")
                                        .font(.bodyMedium)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text("\(messageCount)")
                                        .font(.labelLarge)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }

                            Button {
                                showClearConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                    Text("Clear Chat History")
                                        .font(.labelMedium)
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
                SettingsSection(title: "ABOUT", icon: "info.circle", color: Theme.secondary) {
                    HStack {
                        Text("Version")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .font(.labelMedium)
                            .foregroundStyle(Theme.textMuted)
                    }

                    HStack {
                        Text("Build")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .font(.labelMedium)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Settings")
        .refreshable {
            await loadStatus()
        }
        .confirmationDialog(
            "Clear chat history?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                Task { await clearSession() }
            }
        } message: {
            Text("This will start a fresh conversation with the AI coach.")
        }
        .task {
            await loadStatus()
        }
    }

    private func loadStatus() async {
        isLoading = true
        do {
            serverStatus = try await apiClient.getServerStatus()
        } catch {
            serverStatus = nil
        }
        withAnimation(.airfit) {
            isLoading = false
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
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }

            // Content
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

// MARK: - Server Info Model

struct ServerInfo {
    let host: String
    let activeProvider: String
    let availableProviders: [String]
    let sessionId: String?
    let messageCount: Int?
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

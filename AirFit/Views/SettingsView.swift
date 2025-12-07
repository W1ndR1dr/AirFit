import SwiftUI

struct SettingsView: View {
    @State private var serverStatus: ServerInfo?
    @State private var isLoading = true
    @State private var showClearConfirm = false

    private let apiClient = APIClient()

    var body: some View {
        NavigationStack {
            List {
                // Server Status Section
                Section("Server") {
                    HStack {
                        Label("Status", systemImage: "server.rack")
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else if serverStatus != nil {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .labelStyle(.titleOnly)
                        } else {
                            Label("Disconnected", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .labelStyle(.titleOnly)
                        }
                    }

                    if let status = serverStatus {
                        HStack {
                            Label("Host", systemImage: "network")
                            Spacer()
                            Text(status.host)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // LLM Provider Section
                if let status = serverStatus {
                    Section("AI Provider") {
                        HStack {
                            Label("Active", systemImage: "brain")
                            Spacer()
                            Text(status.activeProvider.capitalized)
                                .foregroundColor(.secondary)
                        }

                        ForEach(status.availableProviders, id: \.self) { provider in
                            HStack {
                                Text(provider.capitalized)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    if let sessionId = status.sessionId {
                        Section("Session") {
                            HStack {
                                Label("ID", systemImage: "number")
                                Spacer()
                                Text(String(sessionId.prefix(8)) + "...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            if let messageCount = status.messageCount {
                                HStack {
                                    Label("Messages", systemImage: "message")
                                    Spacer()
                                    Text("\(messageCount)")
                                        .foregroundColor(.secondary)
                                }
                            }

                            Button(role: .destructive) {
                                showClearConfirm = true
                            } label: {
                                Label("Clear Chat History", systemImage: "trash")
                            }
                        }
                    }
                }

                // App Info Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
            }
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
        isLoading = false
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

// MARK: - Server Info Model

struct ServerInfo {
    let host: String
    let activeProvider: String
    let availableProviders: [String]
    let sessionId: String?
    let messageCount: Int?
}

#Preview {
    SettingsView()
}

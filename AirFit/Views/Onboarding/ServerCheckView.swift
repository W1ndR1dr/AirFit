import SwiftUI

// MARK: - Server Check View

struct ServerCheckView: View {
    @State private var status: ConnectionStatus = .checking
    @State private var providerName: String?
    @State private var retryCount = 0

    let onSuccess: () -> Void
    let onSkip: () -> Void

    enum ConnectionStatus {
        case checking
        case connected
        case failed
    }

    private let apiClient = APIClient()

    var body: some View {
        ZStack {
            BreathingMeshBackground(scrollProgress: 2.0)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Status indicator
                Group {
                    switch status {
                    case .checking:
                        checkingView

                    case .connected:
                        connectedView

                    case .failed:
                        failedView
                    }
                }

                Spacer()

                // Skip button (always available)
                if status == .failed {
                    VStack(spacing: 16) {
                        Button(action: retryConnection) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGradient)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(AirFitButtonStyle())

                        Button(action: onSkip) {
                            Text("Continue Anyway")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textMuted)
                        }
                    }
                    .padding(.horizontal, 24)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 20)
                    }
                }
            }
        }
        .task {
            await checkConnection()
        }
    }

    // MARK: - Status Views

    private var checkingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(2)
                .tint(Theme.accent)

            Text("Connecting to your coach...")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private var connectedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.success)
                .transition(.scale.combined(with: .opacity))

            VStack(spacing: 8) {
                Text("Connected!")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)

                if let provider = providerName {
                    Text("Powered by \(provider)")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
    }

    private var failedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 72))
                .foregroundStyle(Theme.warning)

            VStack(spacing: 16) {
                Text("Couldn't reach the server")
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    troubleshootingItem("Make sure the server is running")
                    troubleshootingItem("Check you're on the same network")
                    troubleshootingItem("Verify the server IP address")
                }
                .padding(.horizontal, 32)
            }
        }
    }

    private func troubleshootingItem(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Theme.textMuted)

            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            Spacer()
        }
    }

    // MARK: - Actions

    private func checkConnection() async {
        withAnimation {
            status = .checking
        }

        // Give local network permission time to fully propagate
        // (permission was granted on previous screen, but iOS networking stack needs a moment)
        try? await Task.sleep(for: .seconds(1.0))

        let healthy = await apiClient.checkHealth()

        if healthy {
            // Try to get provider info
            do {
                let serverStatus = try await apiClient.getStatus()
                providerName = serverStatus.providers.first?.capitalized
            } catch {
                providerName = nil
            }

            withAnimation(.spring(duration: 0.4)) {
                status = .connected
            }

            // Auto-advance after showing success
            try? await Task.sleep(for: .seconds(1.5))
            onSuccess()
        } else {
            withAnimation {
                status = .failed
            }
        }
    }

    private func retryConnection() {
        retryCount += 1
        Task {
            await checkConnection()
        }
    }
}

#Preview("Checking") {
    ServerCheckView(onSuccess: {}, onSkip: {})
}

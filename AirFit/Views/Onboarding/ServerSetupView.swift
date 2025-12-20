import SwiftUI

// MARK: - Server Setup View

struct ServerSetupView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var isAnimating = false
    @State private var serverURL: String = ""
    @State private var isTesting = false
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var showScanner = false
    @FocusState private var isURLFieldFocused: Bool

    enum ConnectionStatus {
        case idle, testing, success, failed
    }

    var body: some View {
        ZStack {
            BreathingMeshBackground(scrollProgress: 1.5)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.1))
                            .frame(width: 120, height: 120)

                        Image(systemName: "server.rack")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.accent)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.8)

                    Spacer()
                        .frame(height: 40)

                    // Title & Description
                    VStack(spacing: 16) {
                        Text("Connect to Your Server")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("AirFit needs to connect to your AI coach server.\n\nScan the QR code or enter the server address manually.")
                            .font(.bodyMedium)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                    Spacer()
                        .frame(height: 40)

                    // Connection UI
                    VStack(spacing: 20) {
                        // QR Code Button (Primary)
                        Button(action: { showScanner = true }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Scan QR Code")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accentGradient)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(AirFitButtonStyle())

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Theme.textMuted.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                            Rectangle()
                                .fill(Theme.textMuted.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)

                        // Manual Entry
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server Address")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)

                            HStack(spacing: 12) {
                                TextField(ServerConfiguration.placeholder, text: $serverURL)
                                    .font(.system(.body, design: .monospaced))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                    .focused($isURLFieldFocused)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                connectionStatus == .failed ? Theme.error :
                                                    connectionStatus == .success ? Theme.success :
                                                    isURLFieldFocused ? Theme.accent : Theme.textMuted.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )

                                // Test button
                                Button(action: testConnection) {
                                    Group {
                                        if isTesting {
                                            ProgressView()
                                                .tint(Theme.accent)
                                        } else {
                                            Image(systemName: connectionStatus == .success ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                                                .foregroundStyle(connectionStatus == .success ? Theme.success : Theme.accent)
                                        }
                                    }
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.surface)
                                    .clipShape(Circle())
                                }
                                .disabled(serverURL.isEmpty || isTesting)
                            }

                            // Status message
                            if connectionStatus == .failed {
                                Text("Could not connect. Check the address and try again.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.error)
                            } else if connectionStatus == .success {
                                Text("Connected successfully!")
                                    .font(.caption)
                                    .foregroundStyle(Theme.success)
                            }
                        }

                        // Continue button (when connected)
                        if connectionStatus == .success {
                            Button(action: saveAndContinue) {
                                HStack {
                                    Text("Continue")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accentGradient)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(AirFitButtonStyle())
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)

                    Spacer()
                        .frame(height: 40)

                    // Skip for development
                    #if DEBUG
                    Button(action: onSkip) {
                        Text("Skip (Development)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.bottom, 20)
                    #endif
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 20)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
            // Pre-fill if already configured
            if ServerConfiguration.shared.isConfigured {
                serverURL = ServerConfiguration.shared.currentURL
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            QRScannerView { scannedURL in
                serverURL = scannedURL
                // Auto-test the scanned URL
                Task {
                    await MainActor.run {
                        testConnection()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: connectionStatus)
    }

    // MARK: - Actions

    private func testConnection() {
        guard !serverURL.isEmpty else { return }

        // Ensure URL has scheme
        var urlToTest = serverURL
        if !urlToTest.hasPrefix("http://") && !urlToTest.hasPrefix("https://") {
            urlToTest = "http://\(urlToTest)"
            serverURL = urlToTest
        }

        isTesting = true
        connectionStatus = .testing

        Task {
            // Temporarily set the URL to test it
            let originalURL = ServerConfiguration.shared.currentURL
            let success = ServerConfiguration.shared.setServer(urlToTest)

            if success {
                let connected = await ServerConfiguration.shared.testConnection()

                await MainActor.run {
                    if connected {
                        connectionStatus = .success
                        // Haptic success
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } else {
                        connectionStatus = .failed
                        // Restore original if test failed
                        if !originalURL.isEmpty {
                            ServerConfiguration.shared.setServer(originalURL)
                        } else {
                            ServerConfiguration.shared.clearServer()
                        }
                        // Haptic error
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                    isTesting = false
                }
            } else {
                await MainActor.run {
                    connectionStatus = .failed
                    isTesting = false
                }
            }
        }
    }

    private func saveAndContinue() {
        // URL is already saved from successful test
        onComplete()
    }
}

#Preview {
    ServerSetupView(onComplete: {}, onSkip: {})
}

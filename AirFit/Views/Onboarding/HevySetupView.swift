import SwiftUI

// MARK: - Hevy Setup View

/// Onboarding/Settings view for configuring Hevy workout sync.
///
/// Hevy is a popular workout tracking app. By connecting the API key,
/// AirFit can pull workout history, PRs, and volume trends for context-aware coaching.
struct HevySetupView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var isAnimating = false
    @State private var apiKey: String = ""
    @State private var isTesting = false
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var errorMessage: String?
    @FocusState private var isKeyFieldFocused: Bool

    private let keychainManager = KeychainManager.shared

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
                            .fill(Theme.secondary.opacity(0.1))
                            .frame(width: 120, height: 120)

                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.secondary)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.8)

                    Spacer()
                        .frame(height: 40)

                    // Title & Description
                    VStack(spacing: 16) {
                        Text("Connect Hevy")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Sync your workout history for smarter coaching.\n\nAirFit uses your PRs, volume, and training patterns to personalize guidance.")
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

                    // Setup UI
                    VStack(spacing: 20) {
                        // Get API Key Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("To get your Hevy API key:")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)

                            VStack(alignment: .leading, spacing: 8) {
                                instructionRow(number: 1, text: "Open the Hevy app")
                                instructionRow(number: 2, text: "Go to Settings → Account")
                                instructionRow(number: 3, text: "Tap \"API Access\"")
                                instructionRow(number: 4, text: "Copy your API key")
                            }
                        }
                        .padding(16)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Theme.textMuted.opacity(0.3))
                                .frame(height: 1)
                            Text("paste it here")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                            Rectangle()
                                .fill(Theme.textMuted.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)

                        // API Key Entry
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)

                            HStack(spacing: 12) {
                                SecureField("Paste your Hevy API key", text: $apiKey)
                                    .font(.system(.body, design: .monospaced))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($isKeyFieldFocused)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(
                                                connectionStatus == .failed ? Theme.error :
                                                    connectionStatus == .success ? Theme.success :
                                                    isKeyFieldFocused ? Theme.secondary : Theme.textMuted.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )

                                // Test button
                                Button(action: testAPIKey) {
                                    Group {
                                        if isTesting {
                                            ProgressView()
                                                .tint(Theme.secondary)
                                        } else {
                                            Image(systemName: connectionStatus == .success ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                                                .foregroundStyle(connectionStatus == .success ? Theme.success : Theme.secondary)
                                        }
                                    }
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(Theme.surface)
                                    .clipShape(Circle())
                                }
                                .disabled(apiKey.isEmpty || isTesting)
                            }

                            // Status message
                            if connectionStatus == .failed {
                                Text(errorMessage ?? "Invalid API key. Please check and try again.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.error)
                            } else if connectionStatus == .success {
                                Text("Connected! Found your workout history.")
                                    .font(.caption)
                                    .foregroundStyle(Theme.success)
                            }
                        }

                        // Continue button (when verified)
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
                                .background(
                                    LinearGradient(
                                        colors: [Theme.secondary, Theme.tertiary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                            }
                            .buttonStyle(AirFitButtonStyle())
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Privacy note
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(Theme.textMuted)
                            Text("Your API key is stored securely in Keychain on your device.")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)

                    Spacer()
                        .frame(height: 40)

                    // Skip option
                    Button(action: onSkip) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.bottom, 20)
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
            Task {
                if let existingKey = await keychainManager.getHevyAPIKey() {
                    await MainActor.run {
                        apiKey = existingKey
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: connectionStatus)
    }

    // MARK: - Helpers

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Theme.secondary)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Actions

    private func testAPIKey() {
        guard !apiKey.isEmpty else { return }

        isTesting = true
        connectionStatus = .testing
        errorMessage = nil

        Task {
            do {
                // Save temporarily to test
                try await keychainManager.setHevyAPIKey(apiKey)

                // Test by fetching workouts
                let success = await HevyService.shared.testConnection()

                await MainActor.run {
                    if success {
                        connectionStatus = .success
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } else {
                        connectionStatus = .failed
                        errorMessage = "Could not verify API key. Please check it's correct."
                        Task {
                            try? await keychainManager.deleteHevyAPIKey()
                        }
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .failed
                    errorMessage = "Failed to save API key."
                    isTesting = false
                }
            }
        }
    }

    private func saveAndContinue() {
        // Key is already saved from successful test
        onComplete()
    }
}

#Preview {
    HevySetupView(onComplete: {}, onSkip: {})
}

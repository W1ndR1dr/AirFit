import SwiftUI

/// Compact status display showing current AI mode and connection state.
/// Lives at the top of the "You" tab for at-a-glance status.
struct CoachStatusCard: View {
    let mode: AIMode
    let isClaudeReady: Bool
    let isGeminiReady: Bool
    let isCheckingConnection: Bool
    let onChangeMode: () -> Void
    // Note: ServerInfo is defined in ProfileView.swift

    var body: some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                Text("Coach Status")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                statusIndicator
            }

            Divider()
                .background(Theme.textMuted.opacity(0.2))

            // Mode row
            HStack {
                Image(systemName: mode.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(modeColor)

                Text(modeLabel)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                connectionBadges
            }

            // Change Mode button
            Button(action: onChangeMode) {
                Text("Change Mode")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        if isCheckingConnection {
            ProgressView()
                .scaleEffect(0.8)
        } else if overallReady {
            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.success)
                    .frame(width: 8, height: 8)
                Text("Ready")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.success)
            }
        } else {
            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.warning)
                    .frame(width: 8, height: 8)
                Text("Setup needed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.warning)
            }
        }
    }

    // MARK: - Connection Badges

    @ViewBuilder
    private var connectionBadges: some View {
        HStack(spacing: 8) {
            if mode == .claude || mode == .both {
                ConnectionBadge(
                    label: "Claude",
                    isConnected: isClaudeReady,
                    isChecking: isCheckingConnection
                )
            }

            if mode == .gemini || mode == .both {
                ConnectionBadge(
                    label: "Gemini",
                    isConnected: isGeminiReady,
                    isChecking: isCheckingConnection
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var modeLabel: String {
        switch mode {
        case .claude: return "Claude Only"
        case .both: return "Hybrid"
        case .gemini: return "Gemini Only"
        }
    }

    private var modeColor: Color {
        switch mode {
        case .claude: return Theme.tertiary
        case .both: return Theme.secondary
        case .gemini: return Theme.accent
        }
    }

    private var overallReady: Bool {
        switch mode {
        case .claude: return isClaudeReady
        case .gemini: return isGeminiReady
        case .both: return isClaudeReady && isGeminiReady
        }
    }
}

// MARK: - Connection Badge

struct ConnectionBadge: View {
    let label: String
    let isConnected: Bool
    let isChecking: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isChecking {
                ProgressView()
                    .scaleEffect(0.6)
            } else {
                Circle()
                    .fill(isConnected ? Theme.success : Theme.error)
                    .frame(width: 6, height: 6)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.background.opacity(0.5))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        CoachStatusCard(
            mode: .both,
            isClaudeReady: true,
            isGeminiReady: true,
            isCheckingConnection: false,
            onChangeMode: {}
        )

        CoachStatusCard(
            mode: .claude,
            isClaudeReady: false,
            isGeminiReady: false,
            isCheckingConnection: true,
            onChangeMode: {}
        )
    }
    .padding()
    .background(Theme.background)
}

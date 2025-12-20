import SwiftUI

/// Three-option AI mode selector with inline configuration.
/// Replaces the old Claude/Gemini binary toggle.
struct AIModeSelector: View {
    @Binding var selectedMode: AIMode
    let isClaudeReady: Bool
    let isGeminiReady: Bool
    let serverStatus: ServerInfo?  // Defined in ProfileView.swift
    let onServerSetup: () -> Void
    let onGeminiSetup: () -> Void

    @Namespace private var modeAnimation

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("AI Mode")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            // Mode cards
            VStack(spacing: 12) {
                ForEach(AIMode.allCases, id: \.self) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        isReady: isModeReady(mode),
                        namespace: modeAnimation,
                        onSelect: {
                            withAnimation(.bloom) {
                                selectedMode = mode
                            }
                        }
                    )
                }
            }

            // Inline configuration (if selected mode needs setup)
            if !isModeReady(selectedMode) {
                configurationPrompt
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Configuration Prompt

    @ViewBuilder
    private var configurationPrompt: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Theme.textMuted.opacity(0.2))

            if selectedMode == .claude && !isClaudeReady {
                ConfigurationCard(
                    icon: "server.rack",
                    title: "Connect to Server",
                    message: "Scan QR code or enter your server address",
                    buttonLabel: "Set Up Server",
                    buttonColor: Theme.tertiary,
                    action: onServerSetup
                )
            }

            if selectedMode == .gemini && !isGeminiReady {
                ConfigurationCard(
                    icon: "key.fill",
                    title: "Add API Key",
                    message: "Get a free API key from Google AI Studio",
                    buttonLabel: "Add Gemini Key",
                    buttonColor: Theme.accent,
                    action: onGeminiSetup
                )
            }

            if selectedMode == .both {
                if !isClaudeReady {
                    ConfigurationCard(
                        icon: "server.rack",
                        title: "Connect to Server",
                        message: "Required for private conversations",
                        buttonLabel: "Set Up Server",
                        buttonColor: Theme.tertiary,
                        action: onServerSetup
                    )
                }
                if !isGeminiReady {
                    ConfigurationCard(
                        icon: "key.fill",
                        title: "Add Gemini Key",
                        message: "Required for photo features",
                        buttonLabel: "Add Gemini Key",
                        buttonColor: Theme.accent,
                        action: onGeminiSetup
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func isModeReady(_ mode: AIMode) -> Bool {
        switch mode {
        case .claude: return isClaudeReady
        case .gemini: return isGeminiReady
        case .both: return isClaudeReady && isGeminiReady
        }
    }
}

// MARK: - Mode Card

struct ModeCard: View {
    let mode: AIMode
    let isSelected: Bool
    let isReady: Bool
    let namespace: Namespace.ID
    let onSelect: () -> Void

    @State private var showingInfo = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? modeColor.opacity(0.2) : Theme.background)
                        .frame(width: 40, height: 40)

                    Image(systemName: mode.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? modeColor : Theme.textMuted)
                }

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(mode.displayName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)

                        // Info button
                        Button {
                            showingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textMuted.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                // Status / Selection
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(modeColor)
                            .frame(width: 24, height: 24)
                            .matchedGeometryEffect(id: "selection", in: namespace)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    Circle()
                        .stroke(Theme.textMuted.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? modeColor.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? modeColor.opacity(0.3) : Theme.textMuted.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .sheet(isPresented: $showingInfo) {
            ModeInfoSheet(mode: mode, color: modeColor)
        }
    }

    private var modeColor: Color {
        switch mode {
        case .claude: return Theme.tertiary
        case .both: return Theme.secondary
        case .gemini: return Theme.accent
        }
    }
}

// MARK: - Mode Info Sheet

struct ModeInfoSheet: View {
    let mode: AIMode
    let color: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: mode.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(color)
                }
                .padding(.top, 20)

                // Title
                Text(mode.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                // Detailed description
                Text(mode.detailedDescription)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Privacy indicator
                privacyIndicator

                Spacer()
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var privacyIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: privacyIcon)
                .font(.title3)
                .foregroundStyle(privacyColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(privacyLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(privacySubtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()
        }
        .padding(16)
        .background(privacyColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private var privacyIcon: String {
        switch mode {
        case .claude: return "lock.shield.fill"
        case .both: return "checkmark.shield.fill"
        case .gemini: return "globe"
        }
    }

    private var privacyColor: Color {
        switch mode {
        case .claude: return Theme.success
        case .both: return Theme.secondary
        case .gemini: return Theme.warning
        }
    }

    private var privacyLabel: String {
        switch mode {
        case .claude: return "Maximum Privacy"
        case .both: return "Balanced Privacy"
        case .gemini: return "Convenience First"
        }
    }

    private var privacySubtitle: String {
        switch mode {
        case .claude: return "All data stays on your server"
        case .both: return "Chat private, photos to Google"
        case .gemini: return "All data goes to Google"
        }
    }
}

// MARK: - Configuration Card

struct ConfigurationCard: View {
    let icon: String
    let title: String
    let message: String
    let buttonLabel: String
    let buttonColor: Color
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(buttonColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            Button(action: action) {
                Text(buttonLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(buttonColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.background.opacity(0.5))
        )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var mode: AIMode = .both

        var body: some View {
            VStack {
                AIModeSelector(
                    selectedMode: $mode,
                    isClaudeReady: true,
                    isGeminiReady: false,
                    serverStatus: nil,
                    onServerSetup: {},
                    onGeminiSetup: {}
                )
            }
            .padding()
            .background(Theme.background)
        }
    }

    return PreviewWrapper()
}

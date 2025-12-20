import SwiftUI

/// Modal sheet for configuring AI coach settings.
/// Provides a proper flow: select mode → (privacy for Hybrid) → confirm.
struct CoachConfigurationSheet: View {
    // Current persisted values
    @Binding var currentMode: String
    @Binding var thinkingLevelRaw: String

    // Privacy settings (for Hybrid/Gemini)
    @Binding var shareNutrition: Bool
    @Binding var shareWorkouts: Bool
    @Binding var shareHealth: Bool
    @Binding var shareProfile: Bool

    // Connection status
    let isClaudeReady: Bool
    let isGeminiReady: Bool
    let serverStatus: ServerInfo?

    // Setup actions
    let onServerSetup: () -> Void
    let onGeminiSetup: () -> Void
    let onDismiss: () -> Void

    // Internal state for "pending" selection before confirm
    @State private var pendingMode: AIMode?
    @State private var showPrivacyOptions = false

    /// The mode being previewed (pending or current)
    private var displayMode: AIMode {
        pendingMode ?? AIMode(rawValue: currentMode) ?? .claude
    }

    /// Whether there's an uncommitted change
    private var hasUnsavedChange: Bool {
        guard let pending = pendingMode else { return false }
        return pending.rawValue != currentMode
    }

    /// Whether the pending mode requires Gemini
    private var pendingNeedsGemini: Bool {
        displayMode == .gemini || displayMode == .both
    }

    /// Whether the pending mode requires Claude/server
    private var pendingNeedsClaude: Bool {
        displayMode == .claude || displayMode == .both
    }

    /// Whether confirm is allowed
    private var canConfirm: Bool {
        guard hasUnsavedChange else { return false }

        switch displayMode {
        case .claude:
            return isClaudeReady
        case .gemini:
            return isGeminiReady
        case .both:
            return isClaudeReady && isGeminiReady
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status Header
                    currentStatusHeader

                    // Mode Selection
                    modeSelectionSection

                    // Privacy Options (shown for Hybrid when selected)
                    if showPrivacyOptions && (displayMode == .both || displayMode == .gemini) {
                        privacySection
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                    }

                    // Thinking Level (for Gemini modes, always visible when applicable)
                    if displayMode == .gemini || displayMode == .both {
                        thinkingSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Coach Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(Theme.textMuted)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if hasUnsavedChange {
                        Button("Confirm") {
                            confirmSelection()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(canConfirm ? Theme.accent : Theme.textMuted)
                        .disabled(!canConfirm)
                    } else {
                        Button("Done") {
                            onDismiss()
                        }
                        .foregroundStyle(Theme.accent)
                    }
                }
            }
            .animation(.bloom, value: displayMode)
            .animation(.bloom, value: showPrivacyOptions)
        }
    }

    // MARK: - Current Status Header

    private var currentStatusHeader: some View {
        VStack(spacing: 12) {
            // Connection indicators
            HStack(spacing: 16) {
                // Claude status
                HStack(spacing: 6) {
                    Circle()
                        .fill(isClaudeReady ? Theme.success : Theme.error)
                        .frame(width: 8, height: 8)
                    Text("Server")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                // Gemini status
                HStack(spacing: 6) {
                    Circle()
                        .fill(isGeminiReady ? Theme.success : Theme.error)
                        .frame(width: 8, height: 8)
                    Text("Gemini")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()
            }

            // Setup buttons if needed
            if !isClaudeReady || !isGeminiReady {
                HStack(spacing: 12) {
                    if !isClaudeReady {
                        Button {
                            onServerSetup()
                        } label: {
                            Label("Setup Server", systemImage: "server.rack")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    if !isGeminiReady {
                        Button {
                            onGeminiSetup()
                        } label: {
                            Label("Setup Gemini", systemImage: "key.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Mode")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 12) {
                ForEach(AIMode.allCases, id: \.self) { mode in
                    ModeOptionCard(
                        mode: mode,
                        isSelected: displayMode == mode,
                        isCurrentlyActive: mode.rawValue == currentMode,
                        isAvailable: isModeAvailable(mode),
                        onSelect: {
                            selectMode(mode)
                        }
                    )
                }
            }
        }
    }

    private func isModeAvailable(_ mode: AIMode) -> Bool {
        switch mode {
        case .claude: return isClaudeReady
        case .gemini: return isGeminiReady
        case .both: return isClaudeReady && isGeminiReady
        }
    }

    private func selectMode(_ mode: AIMode) {
        withAnimation(.bloom) {
            pendingMode = mode

            // Show privacy options when selecting Hybrid
            if mode == .both {
                showPrivacyOptions = true
            }
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Privacy Settings")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                if displayMode == .both {
                    Text("For Gemini features")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Text(displayMode == .both
                ? "Choose what data Gemini can access for photo analysis and quick features."
                : "Choose what data to share with Gemini's API.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 12) {
                PrivacyToggle(
                    title: "Nutrition Data",
                    subtitle: "Foods, calories, macros",
                    riskLevel: .low,
                    isOn: $shareNutrition
                )

                PrivacyToggle(
                    title: "Workout Data",
                    subtitle: "Exercises, PRs, volume",
                    riskLevel: .low,
                    isOn: $shareWorkouts
                )

                PrivacyToggle(
                    title: "Health Metrics",
                    subtitle: "Weight, sleep, heart rate",
                    riskLevel: .medium,
                    isOn: $shareHealth
                )

                PrivacyToggle(
                    title: "Personal Profile",
                    subtitle: "Name, goals, memories",
                    riskLevel: .high,
                    isOn: $shareProfile
                )
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Thinking Section

    private var thinkingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Thinking")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Menu {
                    Text("Controls how deeply Gemini reasons.")
                    Text("")
                    Text("• Fast: Quick responses")
                    Text("• Balanced: Everyday use")
                    Text("• Deep: Complex analysis")
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.textMuted)
                }
            }

            let thinkingLevel = ThinkingLevel(rawValue: thinkingLevelRaw) ?? .medium

            Picker("Thinking Level", selection: Binding(
                get: { thinkingLevel },
                set: { thinkingLevelRaw = $0.rawValue }
            )) {
                ForEach(ThinkingLevel.allCases, id: \.self) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text(thinkingLevel.description)
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func confirmSelection() {
        guard let pending = pendingMode else { return }

        withAnimation(.bloom) {
            currentMode = pending.rawValue
            pendingMode = nil
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onDismiss()
    }
}

// MARK: - Mode Option Card

private struct ModeOptionCard: View {
    let mode: AIMode
    let isSelected: Bool
    let isCurrentlyActive: Bool
    let isAvailable: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.accent.opacity(0.15) : Theme.surface)
                        .frame(width: 44, height: 44)

                    Image(systemName: mode.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(mode.displayName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)

                        if isCurrentlyActive {
                            Text("CURRENT")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                // Status indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                } else if !isAvailable {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.warning)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Theme.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(isAvailable ? 1 : 0.6)
    }
}

#Preview {
    CoachConfigurationSheet(
        currentMode: .constant("claude"),
        thinkingLevelRaw: .constant("medium"),
        shareNutrition: .constant(true),
        shareWorkouts: .constant(true),
        shareHealth: .constant(false),
        shareProfile: .constant(false),
        isClaudeReady: true,
        isGeminiReady: true,
        serverStatus: nil,
        onServerSetup: {},
        onGeminiSetup: {},
        onDismiss: {}
    )
}

import SwiftUI

/// Onboarding step where user selects their AI coach mode.
/// This determines privacy level and which setup steps come next.
struct CoachSelectionView: View {
    @AppStorage("aiProvider") private var aiProvider: String = "gemini"
    @State private var selectedMode: CoachMode = .gemini
    @State private var showingInfo: CoachMode?

    let onComplete: (CoachMode) -> Void

    enum CoachMode: String, CaseIterable {
        case gemini = "gemini"
        case hybrid = "both"
        case claude = "claude"

        var title: String {
            switch self {
            case .gemini: return "Gemini"
            case .hybrid: return "Hybrid"
            case .claude: return "Claude"
            }
        }

        var subtitle: String {
            switch self {
            case .gemini: return "Easiest Setup"
            case .hybrid: return "Best of Both"
            case .claude: return "Maximum Privacy"
            }
        }

        var description: String {
            switch self {
            case .gemini:
                return "Just add an API key and go. Full features including photo analysis. Data goes to Google."
            case .hybrid:
                return "Chat stays on your server (private). Photos use Gemini for vision features."
            case .claude:
                return "Everything routes through your personal server. Complete privacy—nothing leaves your network."
            }
        }

        var icon: String {
            switch self {
            case .gemini: return "sparkles"
            case .hybrid: return "arrow.triangle.branch"
            case .claude: return "lock.shield.fill"
            }
        }

        var privacyBadge: String {
            switch self {
            case .gemini: return "Cloud"
            case .hybrid: return "Mixed"
            case .claude: return "Private"
            }
        }

        var color: Color {
            switch self {
            case .gemini: return Theme.accent
            case .hybrid: return Theme.secondary
            case .claude: return Theme.tertiary
            }
        }

        var detailedInfo: String {
            switch self {
            case .gemini:
                return """
                All conversations and photos go through Google's Gemini API.

                ✓ No server required
                ✓ Full photo/food logging features
                ✓ Free tier available

                Note: Google may use your data to improve their models unless you opt out.
                """
            case .hybrid:
                return """
                Text chats route through your private Claude server. Photo features use Gemini.

                ✓ Chat conversations stay private
                ✓ Full photo/food logging features
                ✓ Best balance of privacy + functionality

                Requires: Server for Claude + Gemini API key
                """
            case .claude:
                return """
                Everything stays on your personal server running the Claude CLI.

                ✓ Complete privacy
                ✓ No data leaves your network
                ✓ Full control

                Requires: A running server with Claude CLI
                Note: Photo features limited without Gemini
                """
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.accent)

                        Text("Choose Your Coach")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)

                        Text("Pick how you want your AI to work.\nYou can change this anytime in settings.")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Mode Cards
                    VStack(spacing: 16) {
                        ForEach(CoachMode.allCases, id: \.self) { mode in
                            CoachModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                onSelect: { selectedMode = mode },
                                onInfo: { showingInfo = mode }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 100)
                }
            }

            // Bottom Button
            VStack {
                Spacer()

                Button {
                    aiProvider = selectedMode.rawValue
                    onComplete(selectedMode)
                } label: {
                    HStack {
                        Text("Continue with \(selectedMode.title)")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedMode.color)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(item: $showingInfo) { mode in
            CoachInfoSheet(mode: mode)
        }
    }
}

// MARK: - Coach Mode Card

struct CoachModeCard: View {
    let mode: CoachSelectionView.CoachMode
    let isSelected: Bool
    let onSelect: () -> Void
    let onInfo: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? mode.color.opacity(0.2) : Theme.surface)
                        .frame(width: 52, height: 52)

                    Image(systemName: mode.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? mode.color : Theme.textMuted)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mode.title)
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)

                        Text(mode.privacyBadge)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(mode.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(mode.color.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Text(mode.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                        .lineLimit(2)
                }

                Spacer()

                // Selection + Info
                VStack(spacing: 8) {
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(mode.color)
                                .frame(width: 26, height: 26)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    } else {
                        Circle()
                            .stroke(Theme.textMuted.opacity(0.3), lineWidth: 2)
                            .frame(width: 26, height: 26)
                    }

                    Button(action: onInfo) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.textMuted.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? mode.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Info Sheet

struct CoachInfoSheet: View {
    let mode: CoachSelectionView.CoachMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(mode.color.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: mode.icon)
                            .font(.system(size: 32))
                            .foregroundStyle(mode.color)
                    }
                    .padding(.top, 20)

                    // Title
                    VStack(spacing: 8) {
                        Text(mode.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)

                        Text(mode.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(mode.color)
                    }

                    // Detailed Info
                    Text(mode.detailedInfo)
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 24)

                    Spacer()
                }
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
}

// Make CoachMode identifiable for sheet presentation
extension CoachSelectionView.CoachMode: Identifiable {
    var id: String { rawValue }
}

#Preview {
    CoachSelectionView { mode in
        print("Selected: \(mode)")
    }
}

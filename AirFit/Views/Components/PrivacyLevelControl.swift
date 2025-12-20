import SwiftUI

/// Simplified privacy control for Gemini data sharing.
/// Single toggle by default, expands to detailed controls.
struct PrivacyLevelControl: View {
    @Binding var shareNutrition: Bool
    @Binding var shareWorkouts: Bool
    @Binding var shareHealth: Bool
    @Binding var shareProfile: Bool

    @State private var showDetails = false

    /// Quick privacy preset based on current state
    private var currentPreset: PrivacyPreset {
        if !shareNutrition && !shareWorkouts && !shareHealth && !shareProfile {
            return .maximum
        } else if shareNutrition && shareWorkouts && !shareHealth && !shareProfile {
            return .balanced
        } else if shareNutrition && shareWorkouts && shareHealth && shareProfile {
            return .shareAll
        } else {
            return .custom
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Privacy")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                privacyBadge
            }

            // Main toggle
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: sharingEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share fitness context with Gemini")
                            .font(.body)
                            .foregroundStyle(Theme.textPrimary)

                        Text("Better coaching with your workout and nutrition data")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .tint(Theme.secondary)
            }

            // Expand button
            Button {
                withAnimation(.bloom) {
                    showDetails.toggle()
                }
            } label: {
                HStack {
                    Text(showDetails ? "Hide details" : "Customize what's shared...")
                        .font(.subheadline)
                        .foregroundStyle(Theme.accent)

                    Spacer()

                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                }
            }
            .buttonStyle(.plain)

            // Detailed toggles (expanded)
            if showDetails {
                VStack(spacing: 12) {
                    Divider()
                        .background(Theme.textMuted.opacity(0.2))

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

    // MARK: - Privacy Badge

    @ViewBuilder
    private var privacyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: currentPreset.icon)
                .font(.caption)
            Text(currentPreset.label)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(currentPreset.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(currentPreset.color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Computed Binding

    private var sharingEnabled: Binding<Bool> {
        Binding(
            get: { shareNutrition || shareWorkouts },
            set: { enabled in
                if enabled {
                    // Enable default safe options
                    shareNutrition = true
                    shareWorkouts = true
                } else {
                    // Disable all
                    shareNutrition = false
                    shareWorkouts = false
                    shareHealth = false
                    shareProfile = false
                }
            }
        )
    }
}

// MARK: - Privacy Preset

enum PrivacyPreset {
    case maximum
    case balanced
    case shareAll
    case custom

    var label: String {
        switch self {
        case .maximum: return "Maximum"
        case .balanced: return "Balanced"
        case .shareAll: return "Open"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .maximum: return "lock.shield.fill"
        case .balanced: return "checkmark.shield.fill"
        case .shareAll: return "globe"
        case .custom: return "slider.horizontal.3"
        }
    }

    var color: Color {
        switch self {
        case .maximum: return Theme.tertiary
        case .balanced: return Theme.secondary
        case .shareAll: return Theme.warning
        case .custom: return Theme.accent
        }
    }
}

// MARK: - Risk Level

enum RiskLevel {
    case low, medium, high

    var color: Color {
        switch self {
        case .low: return Theme.success
        case .medium: return Theme.warning
        case .high: return Theme.error
        }
    }

    var label: String {
        switch self {
        case .low: return "Low risk"
        case .medium: return "Medium"
        case .high: return "Sensitive"
        }
    }
}

// MARK: - Privacy Toggle

struct PrivacyToggle: View {
    let title: String
    let subtitle: String
    let riskLevel: RiskLevel
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)

                    Text(riskLevel.label)
                        .font(.caption2)
                        .foregroundStyle(riskLevel.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(riskLevel.color.opacity(0.1))
                        .clipShape(Capsule())
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(riskLevel.color)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var nutrition = true
        @State private var workouts = true
        @State private var health = false
        @State private var profile = false

        var body: some View {
            PrivacyLevelControl(
                shareNutrition: $nutrition,
                shareWorkouts: $workouts,
                shareHealth: $health,
                shareProfile: $profile
            )
            .padding()
            .background(Theme.background)
        }
    }

    return PreviewWrapper()
}

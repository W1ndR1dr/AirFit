import SwiftUI

/// Card displaying context-aware quick action buttons.
struct QuickActionsCard: View {
    let suggestedActions: [QuickAction]
    let onActionTap: (QuickAction) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    private let actionColumns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Quick Actions")
                    .font(AppFonts.headline)
                    .foregroundStyle(.primary)

                LazyVGrid(columns: actionColumns, spacing: AppSpacing.small) {
                    ForEach(suggestedActions) { action in
                        QuickActionButton(action: action) {
                            onActionTap(action)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: AppSpacing.xSmall) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.15) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: action.systemImage)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(action.title)
                    .font(AppFonts.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(action.title)
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        HapticService.impact(.light)
        onTap()
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    QuickActionsCard(
        suggestedActions: [
            QuickAction(title: "Start Workout", subtitle: "Let's get moving!", systemImage: "figure.run", color: "blue", action: .startWorkout),
            QuickAction(title: "Log Water", subtitle: "Stay hydrated", systemImage: "drop.fill", color: "cyan", action: .logWater),
            QuickAction(title: "Check In", subtitle: "How are you feeling?", systemImage: "checkmark.circle", color: "green", action: .checkIn)
        ],
        onActionTap: { _ in }
    )
    .padding()
}

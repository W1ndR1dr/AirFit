import SwiftUI

/// Card displaying context-aware quick action buttons.
struct QuickActionsCard: View {
    let suggestedActions: [QuickAction]
    let onActionTap: (QuickAction) -> Void

    private let actionColumns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Quick Actions")
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.textPrimary)

            LazyVGrid(columns: actionColumns, spacing: AppSpacing.small) {
                ForEach(suggestedActions) { action in
                    QuickActionButton(action: action) {
                        onActionTap(action)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(AppConstants.Layout.defaultCornerRadius)
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: AppSpacing.xSmall) {
                Image(systemName: action.systemImage)
                    .font(.title2)
                    .foregroundStyle(AppColors.accentColor)
                    .frame(width: 44, height: 44)
                    .background(AppColors.accentColor.opacity(0.1))
                    .clipShape(Circle())
                Text(action.title)
                    .font(AppFonts.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(action.title)
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        HapticManager.impact(.light)
        onTap()
    }
}

#Preview {
    QuickActionsCard(
        suggestedActions: [.logMeal(type: .lunch), .startWorkout, .logWater],
        onActionTap: { _ in }
    )
    .padding()
    .previewLayout(.sizeThatFits)
}

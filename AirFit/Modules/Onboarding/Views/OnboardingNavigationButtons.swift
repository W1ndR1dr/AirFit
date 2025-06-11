import SwiftUI

// MARK: - OnboardingNavigationButtons
struct OnboardingNavigationButtons: View {
    let backAction: () -> Void
    let nextAction: () -> Void
    let isNextEnabled: Bool
    let nextTitle: String

    init(
        backAction: @escaping () -> Void,
        nextAction: @escaping () -> Void,
        isNextEnabled: Bool = true,
        nextTitle: String = "action.next"
    ) {
        self.backAction = backAction
        self.nextAction = nextAction
        self.isNextEnabled = isNextEnabled
        self.nextTitle = nextTitle
    }

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            StandardButton(
                "action.back",
                style: .secondary,
                isFullWidth: true,
                action: backAction
            )
            .accessibilityIdentifier("onboarding.back.button")

            StandardButton(
                LocalizedStringKey(nextTitle),
                style: .primary,
                isFullWidth: true,
                isEnabled: isNextEnabled,
                action: nextAction
            )
            .accessibilityIdentifier("onboarding.next.button")
        }
        .padding(.horizontal, AppSpacing.large)
    }
}

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
            Button(action: backAction) {
                Text(LocalizedStringKey("action.back"))
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .accessibilityIdentifier("onboarding.back.button")

            Button(action: nextAction) {
                Text(LocalizedStringKey(nextTitle))
                    .font(AppFonts.bodyBold)
                    .foregroundColor(isNextEnabled ? AppColors.textOnAccent : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isNextEnabled ? AppColors.accentColor : AppColors.dividerColor)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .disabled(!isNextEnabled)
            .accessibilityIdentifier("onboarding.next.button")
        }
        .padding(.horizontal, AppSpacing.large)
    }
}

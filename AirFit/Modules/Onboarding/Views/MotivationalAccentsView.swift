import SwiftUI
import Observation

// MARK: - MotivationalAccentsView
struct MotivationalAccentsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(LocalizedStringKey("onboarding.motivation.prompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)
                        .accessibilityIdentifier("onboarding.motivation.prompt")

                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text(LocalizedStringKey("onboarding.motivation.celebrationPrompt"))
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        ForEach(MotivationalStyle.CelebrationStyle.allCases, id: \..self) { style in
                            radioOption(
                                title: style.displayName,
                                description: style.description,
                                isSelected: viewModel.motivationalStyle.celebrationStyle == style,
                                action: { viewModel.motivationalStyle.celebrationStyle = style },
                                id: "onboarding.motivation.celebration.\(style.rawValue)"
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.large)

                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        Text(LocalizedStringKey("onboarding.motivation.absencePrompt"))
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        ForEach(MotivationalStyle.AbsenceResponse.allCases, id: \..self) { style in
                            radioOption(
                                title: style.displayName,
                                description: style.description,
                                isSelected: viewModel.motivationalStyle.absenceResponse == style,
                                action: { viewModel.motivationalStyle.absenceResponse = style },
                                id: "onboarding.motivation.absence.\(style.rawValue)"
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.large)
                }
            }

            NavigationButtons(
                backAction: viewModel.navigateToPreviousScreen,
                nextAction: viewModel.navigateToNextScreen
            )
        }
        .accessibilityIdentifier("onboarding.motivationalAccents")
    }

    // MARK: - Helpers
    private func radioOption(title: String, description: String, isSelected: Bool, action: @escaping () -> Void, id: String) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(AppColors.accentColor)
                    Text(title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                }
                Text(description)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.xSmall)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

// MARK: - NavigationButtons
private struct NavigationButtons: View {
    var backAction: () -> Void
    var nextAction: () -> Void

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
                Text(LocalizedStringKey("action.next"))
                    .font(AppFonts.bodyBold)
                    .foregroundColor(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accentColor)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .accessibilityIdentifier("onboarding.next.button")
        }
        .padding(.horizontal, AppSpacing.large)
    }
}


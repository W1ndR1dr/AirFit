import SwiftUI
import Observation

// MARK: - CoachingStyleView
struct CoachingStyleView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(LocalizedStringKey("onboarding.coaching.prompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)
                        .accessibilityIdentifier("onboarding.coaching.prompt")

                    sliderView(
                        title: "AUTHORITATIVE & DIRECT",
                        value: $viewModel.blend.authoritativeDirect,
                        description: "Provides clear, firm direction. Expects commitment.",
                        id: "onboarding.blend.authoritative"
                    )

                    sliderView(
                        title: "ENCOURAGING & EMPATHETIC",
                        value: $viewModel.blend.encouragingEmpathetic,
                        description: "Offers motivation and understanding, celebrates effort.",
                        id: "onboarding.blend.encouraging"
                    )

                    sliderView(
                        title: "ANALYTICAL & INSIGHTFUL",
                        value: $viewModel.blend.analyticalInsightful,
                        description: "Focuses on metrics, trends, and evidence-based advice.",
                        id: "onboarding.blend.analytical"
                    )

                    sliderView(
                        title: "PLAYFULLY PROVOCATIVE",
                        value: $viewModel.blend.playfullyProvocative,
                        description: "Uses light humor and challenges to motivate when appropriate.",
                        id: "onboarding.blend.playful"
                    )
                }
            }

            NavigationButtons(
                backAction: viewModel.navigateToPreviousScreen,
                nextAction: {
                    viewModel.validateBlend()
                    viewModel.navigateToNextScreen()
                }
            )
        }
        .accessibilityIdentifier("onboarding.coachingStyle")
    }

    private func sliderView(
        title: LocalizedStringKey,
        value: Binding<Double>,
        description: LocalizedStringKey,
        id: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            HStack {
                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(AppFonts.captionBold)
                    .foregroundColor(AppColors.textSecondary)
            }

            Slider(value: value, in: 0...1)
                .tint(AppColors.accentColor)
                .accessibilityIdentifier("\(id).slider")

            Text(description)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.large)
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

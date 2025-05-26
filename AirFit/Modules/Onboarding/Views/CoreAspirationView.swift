import SwiftUI
import Observation

// MARK: - CoreAspirationView
struct CoreAspirationView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible())]

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(LocalizedStringKey("onboarding.coreAspiration.prompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)
                        .accessibilityIdentifier("onboarding.goal.prompt")

                    LazyVGrid(columns: columns, spacing: AppSpacing.medium) {
                        ForEach(Goal.GoalFamily.allCases, id: \.self) { family in
                            goalCard(family: family)
                        }
                    }
                    .padding(.horizontal, AppSpacing.large)

                    Text(LocalizedStringKey("onboarding.coreAspiration.freeformPrompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)

                    HStack(alignment: .center, spacing: AppSpacing.small) {
                        TextField("", text: $viewModel.goal.rawText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("onboarding.goal.text")

                        Button(
                            action: {
                                if viewModel.isTranscribing {
                                    viewModel.stopVoiceCapture()
                                } else {
                                    viewModel.startVoiceCapture()
                                }
                            }
                        ) {
                            Image(systemName: viewModel.isTranscribing ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.accentColor)
                        }
                        .accessibilityIdentifier("onboarding.goal.voice")
                    }
                    .padding(.horizontal, AppSpacing.large)
                }
            }

            NavigationButtons(
                backAction: viewModel.navigateToPreviousScreen,
                nextAction: handleNext
            )
        }
        .accessibilityIdentifier("onboarding.coreAspiration")
    }

    private func handleNext() {
        Task {
            await viewModel.analyzeGoalText()
            viewModel.navigateToNextScreen()
        }
    }

    private func goalCard(family: Goal.GoalFamily) -> some View {
        Button(
            action: { viewModel.goal.family = family }
        ) {
            HStack {
                Text(family.displayName)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if viewModel.goal.family == family {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.accentColor)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.cardBackground)
            .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                    .stroke(viewModel.goal.family == family ? AppColors.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.goal.\(family.rawValue)")
    }
}

// MARK: - NavigationButtons
private struct NavigationButtons: View {
    var backAction: () -> Void
    var nextAction: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(
                action: backAction
            ) {
                Text(LocalizedStringKey("action.back"))
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .accessibilityIdentifier("onboarding.back.button")

            Button(
                action: nextAction
            ) {
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

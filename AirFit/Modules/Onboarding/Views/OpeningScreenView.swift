import SwiftUI
import Observation

struct OpeningScreenView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var animateIn = false

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()

            VStack(spacing: AppSpacing.medium) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppColors.primaryGradient)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .opacity(animateIn ? 1 : 0)

                Text("AirFit")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .opacity(animateIn ? 1 : 0)
            }

            VStack(spacing: AppSpacing.small) {
                Text("Let's design your AirFit Coach")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Est. 3-4 minutes to create your personalized experience")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)

            Spacer()

            VStack(spacing: AppSpacing.medium) {
                Button(
                    action: {
                        viewModel.navigateToNextScreen()
                    }
                ) {
                    Text("Begin")
                        .font(AppFonts.bodyBold)
                        .foregroundColor(AppColors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accentColor)
                        .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                }
                .accessibilityIdentifier("onboarding.begin.button")

                Button(
                    action: {
                        AppLogger.info("Onboarding skipped", category: .onboarding)
                    }
                ) {
                    Text("Maybe Later")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)
                }
                .accessibilityIdentifier("onboarding.skip.button")
            }
            .padding(.horizontal, AppSpacing.large)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
        }
        .padding(AppSpacing.medium)
        .onAppear {
            withAnimation(
                .easeOut(duration: 0.8).delay(0.2)
            ) {
                animateIn = true
            }
        }
    }
}

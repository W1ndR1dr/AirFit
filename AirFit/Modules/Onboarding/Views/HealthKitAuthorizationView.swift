import SwiftUI
import Observation

/// Placeholder view for HealthKit authorization during onboarding.
struct HealthKitAuthorizationView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()

            // Explanation text
            VStack(spacing: AppSpacing.small) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primaryGradient)
                Text("Connect HealthKit")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary)
                Text("Allow AirFit to read your activity, workout and sleep data.")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Authorization button
            Button(
                action: { Task { await viewModel.requestHealthKitAuthorization() } },
                label: {
                    Text("Authorize HealthKit")
                        .font(AppFonts.bodyBold)
                        .foregroundColor(AppColors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accentColor)
                        .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                }
            )
            .accessibilityIdentifier("onboarding.healthkit.authorize")

            Spacer()

            if viewModel.healthKitAuthorizationStatus == .denied {
                Text("Permission denied. You can enable access in Settings.")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview {
    HealthKitAuthorizationView(viewModel: OnboardingViewModel(
        aiService: MockAIService(),
        onboardingService: MockOnboardingService(),
        modelContext: try! ModelContainer(for: OnboardingProfile.self).mainContext
    ))
}

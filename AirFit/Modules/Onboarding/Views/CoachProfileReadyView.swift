import SwiftUI
import Observation

// MARK: - CoachProfileReadyView
struct CoachProfileReadyView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.successColor)
                    .padding(.top, AppSpacing.large)

                Text(LocalizedStringKey("onboarding.profileReady.title"))
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.large)

                Text(LocalizedStringKey("onboarding.profileReady.intro"))
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.large)

                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    summaryRow(title: "Your Primary Aspiration", text: aspirationText)
                    summaryRow(title: "Your Coach's Style", text: styleText)
                    summaryRow(title: "Engagement & Updates", text: engagementText)
                    summaryRow(title: "Communication Boundaries", text: boundariesText)
                    summaryRow(title: "Acknowledging Success", text: celebrationText)
                }
                .padding(.horizontal, AppSpacing.large)

                Toggle(
                    LocalizedStringKey("onboarding.profileReady.baselineToggle"),
                    isOn: $viewModel.baselineModeEnabled
                )
                .toggleStyle(SwitchToggleStyle(tint: AppColors.accentColor))
                .padding(.horizontal, AppSpacing.large)

                VStack(spacing: AppSpacing.medium) {
                    Button(action: {
                        AppLogger.info("Onboarding completed", category: .onboarding)
                    }) {
                        Text(LocalizedStringKey("onboarding.profileReady.begin"))
                            .font(AppFonts.bodyBold)
                            .foregroundColor(AppColors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.accentColor)
                            .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                    }
                    .accessibilityIdentifier("onboarding.beginCoach.button")

                    Button(action: {
                        viewModel.navigateToPreviousScreen()
                    }) {
                        Text(LocalizedStringKey("onboarding.profileReady.review"))
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                    }
                    .accessibilityIdentifier("onboarding.reviewProfile.button")
                }
                .padding(.horizontal, AppSpacing.large)
                .padding(.bottom, AppSpacing.large)
            }
        }
        .accessibilityIdentifier("onboarding.coachProfileReady")
    }

    // MARK: - Computed Text
    private var aspirationText: String {
        let text = viewModel.goal.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? viewModel.goal.family.displayName : text
    }

    private var styleText: String {
        let pairs: [(Double, String, String)] = [
            (viewModel.blend.authoritativeDirect, "Authoritative & Direct", "clear"),
            (viewModel.blend.encouragingEmpathetic, "Encouraging & Empathetic", "motivational"),
            (viewModel.blend.analyticalInsightful, "Analytical & Insightful", "analytical"),
            (viewModel.blend.playfullyProvocative, "Playfully Provocative", "playful")
        ]
        let sorted = pairs.sorted { $0.0 > $1.0 }
        let dominant = sorted.first!
        let secondary = sorted.dropFirst().first!
        return "Expect a primarily \(dominant.1) approach, with elements of \(secondary.1). Your coach will be \(dominant.2) and \(secondary.2)."
    }

    private var engagementText: String {
        let depth = viewModel.engagementPreferences.informationDepth.displayName
        let freq = viewModel.engagementPreferences.updateFrequency.displayName.lowercased()
        let recovery = viewModel.engagementPreferences.autoRecoveryLogicPreference ? "suggested automatically" : "adjusted only when you decide"
        return "Your coach will focus on \(depth) and provide updates \(freq). Workout adaptations will be \(recovery)."
    }

    private var boundariesText: String {
        "Quiet hours are respected between \(viewModel.sleepWindow.bedTime) - \(viewModel.sleepWindow.wakeTime) (\(viewModel.timezone)). If you're inactive, your coach will \(viewModel.motivationalStyle.absenceResponse.description.lowercased())."
    }

    private var celebrationText: String {
        "Achievements will be met with a \(viewModel.motivationalStyle.celebrationStyle.displayName.lowercased())."
    }

    // MARK: - Helper
    private func summaryRow(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(text)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

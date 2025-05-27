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
                                    Button(
                    action: {
                        Task {
                            do {
                                try await viewModel.completeOnboarding()
                            } catch {
                                AppLogger.error("Failed to complete onboarding", error: error, category: .onboarding)
                            }
                        }
                    },
                    label: {
                        Text(LocalizedStringKey("onboarding.profileReady.begin"))
                            .font(AppFonts.bodyBold)
                            .foregroundColor(AppColors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.accentColor)
                            .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                    }
                )
                    .accessibilityIdentifier("onboarding.beginCoach.button")

                    Button(
                        action: {
                            viewModel.navigateToPreviousScreen()
                        },
                        label: {
                            Text(LocalizedStringKey("onboarding.profileReady.review"))
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                        }
                    )
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
        struct StylePair {
            let value: Double
            let name: String
            let descriptor: String
        }

        let pairs = [
            StylePair(value: viewModel.blend.authoritativeDirect,
                     name: "Authoritative & Direct",
                     descriptor: "clear"),
            StylePair(value: viewModel.blend.encouragingEmpathetic,
                     name: "Encouraging & Empathetic",
                     descriptor: "motivational"),
            StylePair(value: viewModel.blend.analyticalInsightful,
                     name: "Analytical & Insightful",
                     descriptor: "analytical"),
            StylePair(value: viewModel.blend.playfullyProvocative,
                     name: "Playfully Provocative",
                     descriptor: "playful")
        ]
        let sorted = pairs.sorted { $0.value > $1.value }
        let dominant = sorted.first!
        let secondary = sorted.dropFirst().first!
        return "Expect a primarily \(dominant.name) approach, " +
               "with elements of \(secondary.name). " +
               "Your coach will be \(dominant.descriptor) and \(secondary.descriptor)."
    }

    private var engagementText: String {
        let depth = viewModel.engagementPreferences.informationDepth.displayName
        let freq = viewModel.engagementPreferences.updateFrequency.displayName.lowercased()
        let recovery = viewModel.engagementPreferences.autoRecoveryLogicPreference ?
            "suggested automatically" : "adjusted only when you decide"
        return "Your coach will focus on \(depth) and provide updates \(freq). " +
               "Workout adaptations will be \(recovery)."
    }

    private var boundariesText: String {
        "Quiet hours are respected between \(viewModel.sleepWindow.bedTime) - " +
        "\(viewModel.sleepWindow.wakeTime) (\(viewModel.timezone)). " +
        "If you're inactive, your coach will \(viewModel.motivationalStyle.absenceResponse.description.lowercased())."
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

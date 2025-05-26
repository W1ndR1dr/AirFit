import SwiftUI
import Observation

// MARK: - SleepAndBoundariesView
struct SleepAndBoundariesView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var bedMinutes: Double
    @State private var wakeMinutes: Double

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        _bedMinutes = State(initialValue: Self.minutes(from: viewModel.sleepWindow.bedTime))
        _wakeMinutes = State(initialValue: Self.minutes(from: viewModel.sleepWindow.wakeTime))
    }

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(LocalizedStringKey("onboarding.sleep.prompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)
                        .accessibilityIdentifier("onboarding.sleep.prompt")

                    timeSlider(
                        title: LocalizedStringKey("onboarding.sleep.bedtime"),
                        minutes: $bedMinutes,
                        id: "onboarding.sleep.bedtime"
                    )
                    .onChange(of: bedMinutes) { newValue in
                        viewModel.sleepWindow.bedTime = Self.hhmm(from: newValue)
                    }

                    timeSlider(
                        title: LocalizedStringKey("onboarding.sleep.waketime"),
                        minutes: $wakeMinutes,
                        id: "onboarding.sleep.waketime"
                    )
                    .onChange(of: wakeMinutes) { newValue in
                        viewModel.sleepWindow.wakeTime = Self.hhmm(from: newValue)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text(LocalizedStringKey("onboarding.sleep.rhythmPrompt"))
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        ForEach(SleepWindow.SleepConsistency.allCases, id: \..self) { option in
                            radioOption(
                                title: option.displayName,
                                isSelected: viewModel.sleepWindow.consistency == option,
                                action: { viewModel.sleepWindow.consistency = option },
                                id: "onboarding.sleep.consistency.\(option.rawValue)"
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.large)

                    Text("Timezone: \(viewModel.timezone)")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.large)
                }
            }

            NavigationButtons(
                backAction: viewModel.navigateToPreviousScreen,
                nextAction: viewModel.navigateToNextScreen
            )
        }
        .accessibilityIdentifier("onboarding.sleepBoundaries")
    }

    // MARK: - Helpers
    private func timeSlider(title: LocalizedStringKey, minutes: Binding<Double>, id: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            HStack {
                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text(displayTime(minutes.wrappedValue))
                    .font(AppFonts.captionBold)
                    .foregroundColor(AppColors.textSecondary)
            }

            Slider(value: minutes, in: 0...1439, step: 15)
                .tint(AppColors.accentColor)
                .accessibilityIdentifier("\(id).slider")
        }
        .padding(.horizontal, AppSpacing.large)
    }

    private func radioOption(title: String, isSelected: Bool, action: @escaping () -> Void, id: String) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(AppColors.accentColor)
                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.vertical, AppSpacing.xSmall)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    private func displayTime(_ minutes: Double) -> String {
        let total = Int(minutes) % (24 * 60)
        let hour = total / 60
        let minute = total % 60
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func minutes(from hhmm: String) -> Double {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2,
              let h = Double(parts[0]),
              let m = Double(parts[1]) else { return 0 }
        return h * 60 + m
    }

    private static func hhmm(from minutes: Double) -> String {
        let total = Int(minutes) % (24 * 60)
        let h = total / 60
        let m = total % 60
        return String(format: "%02d:%02d", h, m)
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


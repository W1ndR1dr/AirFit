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
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text(LocalizedStringKey("onboarding.sleep.prompt"))
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                            .accessibilityIdentifier("onboarding.sleep.prompt")
                        if viewModel.hasHealthKitIntegration {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(AppColors.accentColor)
                                    .font(.caption)
                                Text("Pre-filled from HealthKit when available")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.large)

                    timeSlider(
                        title: LocalizedStringKey("onboarding.sleep.bedtime"),
                        minutes: $bedMinutes,
                        id: "onboarding.sleep.bedtime"
                    )
                    .onChange(of: bedMinutes) { _, newValue in
                        viewModel.sleepWindow.bedTime = Self.hhmm(from: newValue)
                    }

                    timeSlider(
                        title: LocalizedStringKey("onboarding.sleep.waketime"),
                        minutes: $wakeMinutes,
                        id: "onboarding.sleep.waketime"
                    )
                    .onChange(of: wakeMinutes) { _, newValue in
                        viewModel.sleepWindow.wakeTime = Self.hhmm(from: newValue)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text(LocalizedStringKey("onboarding.sleep.rhythmPrompt"))
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        ForEach(SleepWindow.SleepConsistency.allCases, id: \.self) { option in
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

            OnboardingNavigationButtons(
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
                    .accessibilityLabel("Time: \(displayTime(minutes.wrappedValue))")
            }

            Slider(value: minutes, in: 0...1_439, step: 15)
                .tint(AppColors.accentColor)
                .accessibilityIdentifier("\(id).slider")
                .accessibilityHint("Adjust time by dragging the slider")
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

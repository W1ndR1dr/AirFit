import SwiftUI
import Observation

// MARK: - LifeSnapshotView
struct LifeSnapshotView: View {
    @Bindable var viewModel: OnboardingViewModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text(LocalizedStringKey("onboarding.lifeSnapshot.prompt"))
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.large)
                        .accessibilityIdentifier("onboarding.life.prompt")

                    LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.medium) {
                        checkbox(
                            text: LocalizedStringKey("onboarding.life.deskJob"),
                            binding: $viewModel.lifeContext.isDeskJob,
                            id: "onboarding.life.desk_job"
                        )
                        checkbox(
                            text: LocalizedStringKey("onboarding.life.activeWork"),
                            binding: $viewModel.lifeContext.isPhysicallyActiveWork,
                            id: "onboarding.life.active_work"
                        )
                        checkbox(
                            text: LocalizedStringKey("onboarding.life.travel"),
                            binding: $viewModel.lifeContext.travelsFrequently,
                            id: "onboarding.life.travel"
                        )
                        checkbox(
                            text: LocalizedStringKey("onboarding.life.familyCare"),
                            binding: $viewModel.lifeContext.hasChildrenOrFamilyCare,
                            id: "onboarding.life.family_care"
                        )
                        checkbox(
                            text: LifeContext.ScheduleType.predictable.displayName,
                            binding: Binding(
                                get: { viewModel.lifeContext.scheduleType == .predictable },
                                set: { if $0 { viewModel.lifeContext.scheduleType = .predictable } }
                            ),
                            id: "onboarding.life.schedule_predictable"
                        )
                        checkbox(
                            text: LifeContext.ScheduleType.unpredictableChaotic.displayName,
                            binding: Binding(
                                get: { viewModel.lifeContext.scheduleType == .unpredictableChaotic },
                                set: { if $0 { viewModel.lifeContext.scheduleType = .unpredictableChaotic } }
                            ),
                            id: "onboarding.life.schedule_unpredictable"
                        )
                    }
                    .padding(.horizontal, AppSpacing.large)

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text(LocalizedStringKey("onboarding.lifeSnapshot.workoutPrompt"))
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                        ForEach(LifeContext.WorkoutWindow.allCases, id: \.self) { option in
                            workoutOption(option)
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
        .accessibilityIdentifier("onboarding.lifeSnapshot")
    }

    private func checkbox(text: LocalizedStringKey, binding: Binding<Bool>, id: String) -> some View {
        Toggle(isOn: binding) {
            Text(text)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .toggleStyle(CheckboxToggleStyle())
        .accessibilityIdentifier(id)
    }

    private func workoutOption(_ option: LifeContext.WorkoutWindow) -> some View {
        Button(
            action: { viewModel.lifeContext.workoutWindowPreference = option },
            label: {
            HStack {
                Image(systemName: workoutOptionIcon(for: option))
                    .foregroundColor(AppColors.accentColor)
                Text(option.displayName)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.vertical, AppSpacing.xSmall)
            }
        )
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.life.workout_\(option.rawValue)")
    }

    private func workoutOptionIcon(for option: LifeContext.WorkoutWindow) -> String {
        viewModel.lifeContext.workoutWindowPreference == option ? "largecircle.fill.circle" : "circle"
    }
}

// MARK: - CheckboxToggleStyle
private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(
            action: { configuration.isOn.toggle() },
            label: {
            HStack(alignment: .center, spacing: AppSpacing.xSmall) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(AppColors.accentColor)
                configuration.label
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.xSmall)
            }
        )
        .buttonStyle(.plain)
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
